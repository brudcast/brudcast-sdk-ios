import XCTest
import Brudcast
@testable import BrudcastInApp

enum Fixtures {
    static func design(format: String = "modal", schemaVersion: Int = 1, blocks: [[String: Any]]? = nil) -> [String: Any] {
        [
            "schemaVersion": schemaVersion,
            "format": format,
            "layout": [
                "position": "center",
                "dismissible": true,
                "overlay": ["color": "#000000", "opacity": 0.5],
                "background": ["color": "#FFFFFF", "imageUrl": NSNull()],
                "cornerRadius": 16,
                "padding": 24,
                "darkMode": ["backgroundColor": "#111111"],
                "autoDismissSeconds": NSNull(),
                "bannerAction": NSNull(),
            ] as [String: Any],
            "blocks": blocks ?? [
                ["id": "img", "type": "image", "url": "https://cdn.example.com/a.png", "aspectRatio": 1.6, "alt": "A gift", "cornerRadius": NSNull()],
                ["id": "t", "type": "text", "role": "title", "text": "Hi Ada", "style": ["size": NSNull(), "weight": "bold", "align": "center", "color": NSNull(), "darkColor": NSNull()]],
                ["id": "cta", "type": "button", "label": "Upgrade", "action": ["type": "deeplink", "value": "myapp://upgrade", "target": NSNull()], "style": ["variant": "primary"]],
                ["id": "later", "type": "button", "label": "Not now", "action": ["type": "dismiss", "value": NSNull(), "target": NSNull()], "style": ["variant": "text"]],
            ],
        ]
    }

    static func message(
        id: String = "m1",
        format: String = "modal",
        design: [String: Any]? = nil,
        trigger: [String: Any] = ["type": "on_session"],
        maxImpressions: Int = 1,
        impressionCount: Int = 0,
        priority: String = "normal",
        startsAt: String? = nil,
        endsAt: String? = nil,
        test: Bool = false
    ) -> [String: Any] {
        var object: [String: Any] = [
            "id": id,
            "kind": "campaign",
            "campaignId": "c1",
            "test": test,
            "format": format,
            "design": design ?? Self.design(format: format),
            "trigger": trigger,
            "displayRules": ["maxImpressions": maxImpressions, "delaySeconds": 0, "priority": priority],
            "inbox": ["addToInbox": false, "title": "", "preview": "", "thumbnailUrl": NSNull(), "expiresInDays": 30],
            "display": format != "inbox_only",
            "inboxEntry": false,
            "read": false,
            "impressionCount": impressionCount,
            "createdAt": "2026-10-16T10:00:00.000Z",
        ]
        object["startsAt"] = startsAt ?? NSNull()
        object["endsAt"] = endsAt ?? NSNull()
        return object
    }
}

final class InAppDesignTests: XCTestCase {
    func testParsesEveryBlockOfAModal() throws {
        let design = try InAppDesign.parse(Fixtures.design())
        XCTAssertEqual(design.format, .modal)
        XCTAssertEqual(design.blocks.count, 4)
        XCTAssertEqual(design.title, "Hi Ada")
        XCTAssertEqual(design.imageURLs, [URL(string: "https://cdn.example.com/a.png")!])
        guard case .button(_, _, let action, _) = design.blocks[2] else { return XCTFail("Expected a button") }
        XCTAssertEqual(action, InAppAction(type: .deeplink, value: "myapp://upgrade", opensInApp: false))
        XCTAssertEqual(design.layout.darkBackgroundColor, "#111111")
    }

    func testRefusesANewerSchemaVersion() {
        XCTAssertThrowsError(try InAppDesign.parse(Fixtures.design(schemaVersion: 2))) { error in
            XCTAssertEqual(error as? InAppDesignError, .unsupportedVersion(2))
        }
    }

    func testRefusesAnUnknownBlockRatherThanDrawingPartOfIt() {
        let design = Fixtures.design(blocks: [["id": "x", "type": "video", "url": "https://x"]])
        XCTAssertThrowsError(try InAppDesign.parse(design)) { error in
            XCTAssertEqual(error as? InAppDesignError, .unknownBlock("video"))
        }
    }

    func testRefusesAButtonWithoutAUsableAction() {
        let design = Fixtures.design(blocks: [["id": "b", "type": "button", "label": "Go", "action": ["type": "url", "value": ""]]])
        XCTAssertThrowsError(try InAppDesign.parse(design))
    }

    func testUrlActionsOpenInAppUnlessTheBrowserIsAsked() {
        XCTAssertEqual(InAppAction.parse(["type": "url", "value": "https://a.co", "target": "in_app"])?.opensInApp, true)
        XCTAssertEqual(InAppAction.parse(["type": "url", "value": "https://a.co", "target": "browser"])?.opensInApp, false)
    }

    func testBannersNeverSitInTheCentre() throws {
        var raw = Fixtures.design(format: "banner", blocks: [["id": "t", "type": "text", "role": "title", "text": "Sale"]])
        var layout = raw["layout"] as! [String: Any]
        layout["position"] = "center"
        raw["layout"] = layout
        XCTAssertEqual(try InAppDesign.parse(raw).layout.position, .top)
    }

    func testClampsOutOfRangeValues() throws {
        let raw = Fixtures.design(blocks: [["id": "s", "type": "spacer", "height": 900], ["id": "i", "type": "image", "url": "https://a.co/i.png", "aspectRatio": 99]])
        let design = try InAppDesign.parse(raw)
        XCTAssertEqual(design.blocks[0], .spacer(id: "s", height: 120))
        guard case .image(_, _, let ratio, _, _) = design.blocks[1] else { return XCTFail("Expected an image") }
        XCTAssertEqual(ratio, 4)
    }

    func testAnUnsupportedDesignStillYieldsAMessageToReport() throws {
        let message = try XCTUnwrap(InAppMessage.parse(Fixtures.message(design: Fixtures.design(schemaVersion: 3))))
        XCTAssertNil(message.design)
        XCTAssertEqual(message.designState, .unsupported(.unsupportedVersion(3)))
    }
}

final class TriggerMatcherTests: XCTestCase {
    private func trigger(_ filters: [[String: Any]]) -> InAppTrigger {
        InAppTrigger.parse(["type": "event", "eventName": "checkout_started", "filters": filters])!
    }

    func testMatchesTheTypeAndName() {
        let event = trigger([])
        XCTAssertTrue(TriggerMatcher.matches(event, .event(name: "checkout_started", properties: [:])))
        XCTAssertFalse(TriggerMatcher.matches(event, .event(name: "checkout_done", properties: [:])))
        XCTAssertFalse(TriggerMatcher.matches(event, .screen(name: "checkout_started", properties: [:])))
        XCTAssertFalse(TriggerMatcher.matches(event, .session))
        XCTAssertTrue(TriggerMatcher.matches(.onSession, .session))
    }

    func testAppliesEveryOperator() {
        let props: BrudcastProperties = ["plan": "pro", "total": 120, "first": true]
        XCTAssertTrue(TriggerMatcher.matches(trigger([["property": "plan", "operator": "eq", "value": "pro"]]), .event(name: "checkout_started", properties: props)))
        XCTAssertFalse(TriggerMatcher.matches(trigger([["property": "plan", "operator": "neq", "value": "pro"]]), .event(name: "checkout_started", properties: props)))
        XCTAssertTrue(TriggerMatcher.matches(trigger([["property": "total", "operator": "gt", "value": 100]]), .event(name: "checkout_started", properties: props)))
        XCTAssertFalse(TriggerMatcher.matches(trigger([["property": "total", "operator": "lt", "value": 100]]), .event(name: "checkout_started", properties: props)))
        XCTAssertTrue(TriggerMatcher.matches(trigger([["property": "first", "operator": "exists", "value": NSNull()]]), .event(name: "checkout_started", properties: props)))
        XCTAssertFalse(TriggerMatcher.matches(trigger([["property": "coupon", "operator": "exists", "value": NSNull()]]), .event(name: "checkout_started", properties: props)))
    }

    func testComparesNumbersGivenAsStrings() {
        XCTAssertTrue(TriggerMatcher.matches(trigger([["property": "total", "operator": "eq", "value": 120]]), .event(name: "checkout_started", properties: ["total": "120"])))
        XCTAssertTrue(TriggerMatcher.matches(trigger([["property": "first", "operator": "eq", "value": "true"]]), .event(name: "checkout_started", properties: ["first": true])))
    }

    func testAMissingPropertyIsNotEqualToAnything() {
        XCTAssertTrue(TriggerMatcher.matches(trigger([["property": "plan", "operator": "neq", "value": "pro"]]), .event(name: "checkout_started", properties: [:])))
        XCTAssertFalse(TriggerMatcher.matches(trigger([["property": "plan", "operator": "eq", "value": "pro"]]), .event(name: "checkout_started", properties: [:])))
    }

    func testRefusesAnUnknownOperator() {
        XCTAssertNil(InAppTrigger.parse(["type": "event", "eventName": "x", "filters": [["property": "a", "operator": "contains", "value": "b"]]]))
    }
}

final class MessageStoreTests: XCTestCase {
    private var clock = Date(timeIntervalSince1970: 1_800_000_000)

    private func store() -> MessageStore {
        MessageStore(storage: nil, now: { [unowned self] in self.clock })
    }

    func testReportsAddedAndWithdrawnMessages() {
        let store = store()
        store.replace(raw: [Fixtures.message(id: "a"), Fixtures.message(id: "b")], frequencyCap: nil, userId: "u1")
        let change = store.replace(raw: [Fixtures.message(id: "b"), Fixtures.message(id: "c")], frequencyCap: nil, userId: "u1")
        XCTAssertEqual(change.added.map(\.id), ["c"])
        XCTAssertEqual(change.removed, ["a"])
    }

    func testForgetsEverythingWhenTheUserChanges() {
        let store = store()
        store.replace(raw: [Fixtures.message(id: "a")], frequencyCap: nil, userId: "u1")
        XCTAssertEqual(store.markDelivered(["a"]), ["a"])
        store.replace(raw: [Fixtures.message(id: "a")], frequencyCap: nil, userId: "u2")
        XCTAssertEqual(store.markDelivered(["a"]), ["a"])
    }

    func testDeliveredIsReportedOnce() {
        let store = store()
        XCTAssertEqual(store.markDelivered(["a", "b"]), ["a", "b"])
        XCTAssertEqual(store.markDelivered(["a", "c"]), ["c"])
    }

    func testStopsAtMaxImpressionsCountingLocalOnesTheServiceHasNotSeen() throws {
        let store = store()
        store.replace(raw: [Fixtures.message(id: "a", maxImpressions: 2, impressionCount: 1)], frequencyCap: nil, userId: "u1")
        let message = try XCTUnwrap(store.message("a"))
        XCTAssertTrue(store.isEligible(message, serverNow: clock))
        store.recordImpression("a")
        XCTAssertFalse(store.isEligible(message, serverNow: clock))
    }

    func testRespectsTheLiveWindow() throws {
        let store = store()
        store.replace(raw: [
            Fixtures.message(id: "future", startsAt: "2030-01-01T00:00:00.000Z"),
            Fixtures.message(id: "past", endsAt: "2020-01-01T00:00:00.000Z"),
            Fixtures.message(id: "live", startsAt: "2020-01-01T00:00:00.000Z", endsAt: "2030-01-01T00:00:00.000Z"),
        ], frequencyCap: nil, userId: "u1")
        XCTAssertFalse(store.isEligible(store.message("future")!, serverNow: clock))
        XCTAssertFalse(store.isEligible(store.message("past")!, serverNow: clock))
        XCTAssertTrue(store.isEligible(store.message("live")!, serverNow: clock))
    }

    func testAppliesTheFrequencyCapAcrossMessages() {
        let store = store()
        let cap: [String: Any] = ["count": 2, "hours": 24, "impressionsInWindow": 1]
        store.replace(raw: [Fixtures.message(id: "a"), Fixtures.message(id: "b")], frequencyCap: cap, userId: "u1")
        XCTAssertTrue(store.isEligible(store.message("b")!, serverNow: clock))
        store.recordImpression("a")
        XCTAssertFalse(store.isEligible(store.message("b")!, serverNow: clock))
    }

    func testTestMessagesBypassTheLimits() {
        let store = store()
        store.replace(raw: [Fixtures.message(id: "t", impressionCount: 5, test: true)], frequencyCap: ["count": 1, "hours": 24, "impressionsInWindow": 9], userId: "u1")
        XCTAssertTrue(store.isEligible(store.message("t")!, serverNow: clock))
    }

    func testNeverShowsInboxOnlyOrUnsupportedMessages() {
        let store = store()
        store.replace(raw: [
            Fixtures.message(id: "inbox", format: "inbox_only"),
            Fixtures.message(id: "new", design: Fixtures.design(schemaVersion: 9)),
        ], frequencyCap: nil, userId: "u1")
        XCTAssertFalse(store.isEligible(store.message("inbox")!, serverNow: clock))
        XCTAssertFalse(store.isEligible(store.message("new")!, serverNow: clock))
    }
}

final class ServerSentEventParserTests: XCTestCase {
    func testSplitsEventsAcrossChunks() {
        var parser = ServerSentEventParser()
        XCTAssertEqual(parser.feed(Data("retry: 5000\n\n: ping\n\nevent: message.added\nda".utf8)), [])
        let events = parser.feed(Data("ta: {\"type\":\"message.added\"}\r\n\r\nevent: sync\ndata: {}\n\n".utf8))
        XCTAssertEqual(events, [
            ServerSentEvent(event: "message.added", data: #"{"type":"message.added"}"#),
            ServerSentEvent(event: "sync", data: "{}"),
        ])
        XCTAssertEqual(parser.retryMilliseconds, 5_000)
    }

    func testJoinsMultilineData() {
        var parser = ServerSentEventParser()
        XCTAssertEqual(parser.feed(Data("data: a\ndata: b\n\n".utf8)), [ServerSentEvent(event: "message", data: "a\nb")])
    }
}
