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

    func testNonFiniteNumbersNeverReachJsonSerialization() throws {
        let object: [String: Any] = ["nan": BrudcastValue.number(.nan).jsonObject, "inf": BrudcastValue.number(.infinity).jsonObject]
        XCTAssertTrue(JSONSerialization.isValidJSONObject(object))
        let properties: BrudcastProperties = ["ok": 1, "nan": .number(.nan), "inf": .number(-.infinity)]
        XCTAssertEqual(properties.droppingNonFiniteNumbers(), ["ok": 1])
    }

    func testAnUnencodableBodyFailsWithoutRetrying() {
        let client = BrudcastApiClient(baseURL: URL(string: "https://example.com/sdk/v1")!, publishableKey: "bpk_test")
        let done = expectation(description: "completion")
        client.send(.post, "/events", body: ["n": Double.nan]) { result in
            guard case .failure(let error) = result else { return XCTFail("Expected a failure") }
            XCTAssertEqual(error.code, "encoding")
            XCTAssertFalse(error.isRetryable)
            done.fulfill()
        }
        wait(for: [done], timeout: 1)
    }

    func testTellsARefusedKeyFromARefusedUserHash() {
        let hashRefused = BrudcastApiError(statusCode: 401, code: nil, message: "The user hash does not match this user")
        let keyRefused = BrudcastApiError(statusCode: 401, code: nil, message: "Unknown or disabled publishable key")
        XCTAssertFalse(BrudcastCore.isKeyRejection(hashRefused, hadIdentity: true))
        XCTAssertTrue(BrudcastCore.isKeyRejection(keyRefused, hadIdentity: true))
        XCTAssertTrue(BrudcastCore.isKeyRejection(hashRefused, hadIdentity: false))
        XCTAssertFalse(BrudcastCore.isKeyRejection(BrudcastApiError(statusCode: 401, code: "identity_rejected", message: "publishable key"), hadIdentity: true))
        XCTAssertTrue(BrudcastCore.isKeyRejection(BrudcastApiError(statusCode: 401, code: "key_rejected", message: ""), hadIdentity: true))
    }

    func testAnUnreadableKeychainNeverReplacesTheStoredDeviceId() {
        let storage = makeStorage()
        var writes: [String] = []
        let temporary = DeviceIdentifier.load(storage: storage, read: { .unavailable(errSecInteractionNotAllowed) }, write: { writes.append($0); return errSecSuccess })
        XCTAssertFalse(temporary.isEmpty)
        XCTAssertTrue(writes.isEmpty)
        XCTAssertNil(storage.string("brudcast.device_id"))

        let kept = DeviceIdentifier.load(storage: storage, read: { .found("kept-id") }, write: { writes.append($0); return errSecSuccess })
        XCTAssertEqual(kept, "kept-id")
        XCTAssertTrue(writes.isEmpty)
    }

    func testAMissingDeviceIdIsCreatedOnceAndFallsBackWithoutAKeychain() {
        let storage = makeStorage()
        let created = DeviceIdentifier.load(storage: storage, read: { .missing }, write: { _ in errSecMissingEntitlement })
        XCTAssertEqual(storage.string("brudcast.device_id"), created)
        XCTAssertEqual(DeviceIdentifier.load(storage: storage, read: { .missing }, write: { _ in errSecMissingEntitlement }), created)

        var stored: String?
        XCTAssertEqual(DeviceIdentifier.load(storage: storage, read: { .missing }, write: { stored = $0; return errSecSuccess }), created)
        XCTAssertEqual(stored, created)
        XCTAssertNil(storage.string("brudcast.device_id"))
    }

    private func makeStorage() -> BrudcastStorage {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        addTeardownBlock { try? FileManager.default.removeItem(at: directory) }
        return BrudcastStorage(defaults: UserDefaults(suiteName: UUID().uuidString)!, directory: directory)
    }

    func testDropsEmptyTraits() {
        let traits = BrudcastTraits(email: "a@b.co", firstName: "  ").jsonObject
        XCTAssertEqual(traits.count, 1)
        XCTAssertEqual(traits["email"] as? String, "a@b.co")
    }

    func testActionsAreVerifiedUnlessMarkedOtherwise() {
        XCTAssertTrue(BrudcastAction(kind: .deeplink, value: "shop://cart", source: .push(messageId: "m1")).verified)
        XCTAssertFalse(BrudcastAction(kind: .deeplink, value: "shop://cart", source: .push(messageId: "m1"), verified: false).verified)
    }

    func testEnvironmentsPointAtTheSdkApi() {
        XCTAssertEqual(BrudcastEnvironment.production.baseURL.absoluteString, "https://in-app-delivery-service.brudcast.com/sdk/v1")
        XCTAssertEqual(BrudcastEnvironment.local(port: 8191).baseURL.absoluteString, "http://localhost:8191/sdk/v1")
    }
}
