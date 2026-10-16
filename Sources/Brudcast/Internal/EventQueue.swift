import Foundation

/// The persistent queue of events waiting to be sent.
///
/// The queue does no I/O on the network and owns no thread: the core drives it from its serial
/// queue, asks it for the next batch, and reports how sending went.
final class EventQueue {
    enum Outcome {
        case sent
        case rejected
        case retry
        case unauthorized
    }

    static let maxBatch = 100
    static let flushThreshold = 20
    static let maxStored = 1_000
    static let maxAge: TimeInterval = 7 * 24 * 3_600
    static let baseBackoff: TimeInterval = 2
    static let maxBackoff: TimeInterval = 300

    private static let fileName = "events.json"

    private let storage: BrudcastStorage?
    private let now: () -> Date
    private(set) var pending: [BrudcastEvent]
    private(set) var inFlight: Set<String> = []
    private var failures = 0
    private(set) var retryAfter: Date?

    init(storage: BrudcastStorage?, now: @escaping () -> Date = Date.init) {
        self.storage = storage
        self.now = now
        let stored = storage?.readJSON(Self.fileName) as? [Any] ?? []
        pending = stored.compactMap(BrudcastEvent.from(stored:))
        dropExpired()
    }

    /// Adds an event.
    ///
    /// - Parameter event: The event.
    /// - Returns: True when enough events are waiting that a flush should start now.
    @discardableResult
    func enqueue(_ event: BrudcastEvent) -> Bool {
        pending.append(event)
        if pending.count > Self.maxStored {
            let overflow = pending.count - Self.maxStored
            BrudcastLogger.shared.warning("Event queue is full, dropping the \(overflow) oldest events")
            pending.removeFirst(overflow)
        }
        persist()
        return pending.count - inFlight.count >= Self.flushThreshold
    }

    /// Takes the next batch to send: the oldest waiting events of one channel, up to 100.
    ///
    /// - Returns: The batch, or nil when nothing is waiting, a batch is already out, or the queue is
    ///   backing off.
    func nextBatch() -> [BrudcastEvent]? {
        guard inFlight.isEmpty else { return nil }
        if let retryAfter = retryAfter, retryAfter > now() {
            return nil
        }
        dropExpired()
        guard let first = pending.first else { return nil }
        let batch = Array(pending.filter { $0.channel == first.channel }.prefix(Self.maxBatch))
        inFlight = Set(batch.map(\.id))
        return batch
    }

    /// Records how sending a batch went.
    ///
    /// - Parameters:
    ///   - batch: The batch `nextBatch` returned.
    ///   - outcome: Sent and rejected batches leave the queue; retried and unauthorized ones stay.
    func complete(_ batch: [BrudcastEvent], outcome: Outcome) {
        let ids = Set(batch.map(\.id))
        inFlight.subtract(ids)
        switch outcome {
        case .sent:
            failures = 0
            retryAfter = nil
            pending.removeAll { ids.contains($0.id) }
        case .rejected:
            failures = 0
            retryAfter = nil
            BrudcastLogger.shared.warning("The service rejected \(batch.count) events; they are dropped")
            pending.removeAll { ids.contains($0.id) }
        case .retry:
            failures += 1
            let delay = min(Self.maxBackoff, Self.baseBackoff * pow(2, Double(failures - 1)))
            retryAfter = now().addingTimeInterval(delay)
        case .unauthorized:
            retryAfter = nil
        }
        persist()
    }

    /// Removes every waiting event.
    func clear() {
        pending.removeAll()
        inFlight.removeAll()
        failures = 0
        retryAfter = nil
        persist()
    }

    var waitingCount: Int {
        pending.count
    }

    private func dropExpired() {
        let cutoff = now().addingTimeInterval(-Self.maxAge)
        let before = pending.count
        pending.removeAll { $0.occurredAt < cutoff && !inFlight.contains($0.id) }
        if pending.count != before {
            persist()
        }
    }

    private func persist() {
        storage?.writeJSON(pending.map(\.storedObject), to: Self.fileName)
    }
}
