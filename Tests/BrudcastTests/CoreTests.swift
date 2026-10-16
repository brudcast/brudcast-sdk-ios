import XCTest
@testable import Brudcast

final class CoreTests: XCTestCase {
    func testParsesASessionResponse() throws {
        let payload: [String: Any] = [
            "session": ["token": "jwt", "expiresAt": "2030-01-01T00:15:00.000Z"],
            "user": ["id": "u1", "externalId": "4812", "verified": true, "optedOut": false],
            "messages": [],
            "frequencyCap": NSNull(),
            "serverTime": BrudcastDates.format(Date()),
        ]
        let session = try XCTUnwrap(BrudcastCore.parseSession(payload))
        XCTAssertEqual(session.token, "jwt")
        XCTAssertEqual(session.userId, "u1")
        XCTAssertEqual(session.externalId, "4812")
        XCTAssertTrue(session.verified)
        XCTAssertEqual(session.serverTimeOffset, 0, accuracy: 1)
    }

    func testRefusesAnIncompleteSessionResponse() {
        XCTAssertNil(BrudcastCore.parseSession(["user": ["id": "u1"]]))
    }

    func testUnwrapsTheEnvelope() throws {
        let body = #"{"status":true,"data":{"accepted":2}}"#.data(using: .utf8)
        let data = try BrudcastApiClient.decode(status: 202, data: body).get()
        XCTAssertEqual(data["accepted"] as? Int, 2)
    }

    func testReadsTheErrorMessageAndCode() {
        let body = #"{"status":false,"message":"Push is not linked","code":"PUSH_NOT_LINKED"}"#.data(using: .utf8)
        guard case .failure(let error) = BrudcastApiClient.decode(status: 409, data: body) else {
            return XCTFail("Expected a failure")
        }
        XCTAssertEqual(error.statusCode, 409)
        XCTAssertEqual(error.code, "PUSH_NOT_LINKED")
        XCTAssertEqual(error.message, "Push is not linked")
        XCTAssertFalse(error.isRetryable)
    }

    func testRetriesOnlyTransientStatuses() {
        XCTAssertTrue(BrudcastApiError(statusCode: nil, code: nil, message: "").isRetryable)
        XCTAssertTrue(BrudcastApiError(statusCode: 429, code: nil, message: "").isRetryable)
        XCTAssertTrue(BrudcastApiError(statusCode: 503, code: nil, message: "").isRetryable)
        XCTAssertFalse(BrudcastApiError(statusCode: 422, code: nil, message: "").isRetryable)
    }

    func testValidatesEventNamesLikeTheService() {
        XCTAssertTrue(BrudcastCore.isValidEventName("checkout_started"))
        XCTAssertTrue(BrudcastCore.isValidEventName("cart:item.added-v2"))
        XCTAssertFalse(BrudcastCore.isValidEventName("1st_open"))
        XCTAssertFalse(BrudcastCore.isValidEventName("has space"))
        XCTAssertFalse(BrudcastCore.isValidEventName(String(repeating: "a", count: 65)))
    }

    func testConvertsJsonValues() {
        XCTAssertEqual(BrudcastValue.from(NSNumber(value: true)), .bool(true))
        XCTAssertEqual(BrudcastValue.from(NSNumber(value: 3)), .number(3))
        XCTAssertEqual(BrudcastValue.from("x"), .string("x"))
        XCTAssertEqual(BrudcastValue.from(NSNull()), .null)
        XCTAssertNil(BrudcastValue.from([1, 2]))
    }

    func testWritesWholeNumbersAsIntegers() throws {
        let data = try JSONSerialization.data(withJSONObject: ["n": BrudcastValue.number(3).jsonObject, "d": BrudcastValue.number(1.5).jsonObject], options: [.sortedKeys])
        XCTAssertEqual(String(data: data, encoding: .utf8), #"{"d":1.5,"n":3}"#)
    }

    func testDropsEmptyTraits() {
        let traits = BrudcastTraits(email: "a@b.co", firstName: "  ").jsonObject
        XCTAssertEqual(traits.count, 1)
        XCTAssertEqual(traits["email"] as? String, "a@b.co")
    }

    func testEnvironmentsPointAtTheSdkApi() {
        XCTAssertEqual(BrudcastEnvironment.production.baseURL.absoluteString, "https://in-app-delivery-service.brudcast.com/sdk/v1")
        XCTAssertEqual(BrudcastEnvironment.local(port: 8191).baseURL.absoluteString, "http://localhost:8191/sdk/v1")
    }
}
