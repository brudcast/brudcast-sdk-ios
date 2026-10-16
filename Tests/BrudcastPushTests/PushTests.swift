import XCTest
@testable import BrudcastPush
@testable import BrudcastNotificationService

final class PushPayloadTests: XCTestCase {
    private let payload: [AnyHashable: Any] = [
        "aps": ["alert": ["title": "Sale", "body": "20% off today"], "mutable-content": 1],
        "bc_mid": "pm_1",
        "bc_cid": "c_1",
        "bc_app": "app_1",
        "click_url": "myapp://sale",
        "fcm_options": ["image": "https://cdn.example.com/sale.png"],
        "gcm.message_id": "0:123",
        "coupon": "SAVE20",
    ]

    func testReadsABrudcastNotification() throws {
        let notification = try XCTUnwrap(BrudcastPushNotification(userInfo: payload))
        XCTAssertEqual(notification.messageId, "pm_1")
        XCTAssertEqual(notification.campaignId, "c_1")
        XCTAssertEqual(notification.applicationId, "app_1")
        XCTAssertEqual(notification.title, "Sale")
        XCTAssertEqual(notification.body, "20% off today")
        XCTAssertEqual(notification.clickURL, URL(string: "myapp://sale"))
        XCTAssertEqual(notification.data, ["coupon": "SAVE20"])
    }

    func testLeavesOtherNotificationsToTheHost() {
        XCTAssertNil(BrudcastPushNotification(userInfo: ["aps": ["alert": "Hi"], "gcm.message_id": "1"]))
        XCTAssertFalse(BrudcastPush.shared.isBrudcastNotification(["aps": ["alert": "Hi"]]))
        XCTAssertTrue(BrudcastPush.shared.isBrudcastNotification(payload))
    }

    func testTheReceivedEventIdIsTheSameWhereverTheDeliveryIsRecorded() {
        let id = BrudcastSharedEvents.receivedEventId(messageId: "pm_1")
        XCTAssertEqual(id, BrudcastSharedEvents.receivedEventId(messageId: "pm_1"))
        XCTAssertNotEqual(id, BrudcastSharedEvents.receivedEventId(messageId: "pm_2"))
        XCTAssertNotNil(UUID(uuidString: id))
    }

    func testFindsTheImageFcmAttached() {
        XCTAssertEqual(BrudcastNotificationServiceExtension.imageURL(in: payload), URL(string: "https://cdn.example.com/sale.png"))
        XCTAssertNil(BrudcastNotificationServiceExtension.imageURL(in: ["fcm_options": ["image": "http://insecure.example.com/a.png"]]))
    }
}
