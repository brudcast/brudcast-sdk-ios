import XCTest
@testable import Brudcast

final class EventQueueTests: XCTestCase {
    private var clock = Date(timeIntervalSince1970: 1_800_000_000)

    private func makeQueue(storage: BrudcastStorage? = nil) -> EventQueue {
        EventQueue(storage: storage, now: { [unowned self] in self.clock })
    }

    private func event(_ type: String = "custom", channel: String = BrudcastEvent.coreChannel, at date: Date? = nil) -> BrudcastEvent {
        BrudcastEvent(type: type, name: "tapped", occurredAt: date ?? clock, channel: channel)
    }

    func testSignalsAFlushOnceTwentyEventsWait() {
        let queue = makeQueue()
        for _ in 0..<19 {
            XCTAssertFalse(queue.enqueue(event()))
        }
        XCTAssertTrue(queue.enqueue(event()))
    }

    func testBatchesHoldAtMostOneHundredEventsOfOneChannel() {
        let queue = makeQueue()
        queue.enqueue(event(channel: "push"))
        for _ in 0..<150 {
            queue.enqueue(event())
        }
        let first = queue.nextBatch()
        XCTAssertEqual(first?.count, 1)
        XCTAssertEqual(first?.first?.channel, "push")
        queue.complete(first!, outcome: .sent)

        let second = queue.nextBatch()
        XCTAssertEqual(second?.count, 100)
        XCTAssertTrue(second!.allSatisfy { $0.channel == BrudcastEvent.coreChannel })
    }

    func testOnlyOneBatchIsOutAtATime() {
        let queue = makeQueue()
        queue.enqueue(event())
        XCTAssertNotNil(queue.nextBatch())
        XCTAssertNil(queue.nextBatch())
    }

    func testSentAndRejectedBatchesLeaveTheQueue() {
        let queue = makeQueue()
        queue.enqueue(event())
        queue.complete(queue.nextBatch()!, outcome: .sent)
        XCTAssertEqual(queue.waitingCount, 0)

        queue.enqueue(event())
        queue.complete(queue.nextBatch()!, outcome: .rejected)
        XCTAssertEqual(queue.waitingCount, 0)
    }

    func testRetryBacksOffExponentiallyUpToFiveMinutes() {
        let queue = makeQueue()
        queue.enqueue(event())

        queue.complete(queue.nextBatch()!, outcome: .retry)
        XCTAssertEqual(queue.retryAfter, clock.addingTimeInterval(2))
        XCTAssertNil(queue.nextBatch())

        clock = clock.addingTimeInterval(2)
        queue.complete(queue.nextBatch()!, outcome: .retry)
        XCTAssertEqual(queue.retryAfter, clock.addingTimeInterval(4))

        for _ in 0..<10 {
            clock = queue.retryAfter!
            queue.complete(queue.nextBatch()!, outcome: .retry)
        }
        XCTAssertEqual(queue.retryAfter, clock.addingTimeInterval(300))
        XCTAssertEqual(queue.waitingCount, 1)
    }

    func testUnauthorizedKeepsTheBatchWithoutBackingOff() {
        let queue = makeQueue()
        queue.enqueue(event())
        queue.complete(queue.nextBatch()!, outcome: .unauthorized)
        XCTAssertEqual(queue.waitingCount, 1)
        XCTAssertNotNil(queue.nextBatch())
    }

    func testEventsOlderThanSevenDaysAreDropped() {
        let queue = makeQueue()
        queue.enqueue(event(at: clock.addingTimeInterval(-8 * 24 * 3_600)))
        queue.enqueue(event())
        XCTAssertEqual(queue.nextBatch()?.count, 1)
    }

    func testTheQueueSurvivesARestart() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let storage = BrudcastStorage(defaults: defaults, directory: directory)

        let queue = makeQueue(storage: storage)
        let original = BrudcastEvent(type: "click", messageId: "m1", buttonId: "cta", properties: ["plan": "pro", "seats": 3], occurredAt: clock, channel: "in_app")
        queue.enqueue(original)

        let restored = makeQueue(storage: storage)
        XCTAssertEqual(restored.pending, [original])
    }

    func testTheApiObjectOmitsTheChannel() {
        let object = event(channel: "push").apiObject
        XCTAssertNil(object["channel"])
        XCTAssertEqual(object["type"] as? String, "custom")
        XCTAssertEqual(object["occurredAt"] as? String, "2027-01-15T08:00:00.000Z")
    }
}
