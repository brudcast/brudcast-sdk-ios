import XCTest

/// Walks the sample through what a customer's app does against a real Brudcast stack: sign in
/// through the customer's backend, receive an in-app message that backend sends through the API,
/// act on it, shop through to a placed order, and sign out.
///
/// It needs a running stack, a sample backend (see the README), and `Config/Local.xcconfig` pointing
/// the app at both, so it runs only when `BRUDCAST_E2E=1` reaches the test runner:
///
/// ```sh
/// TEST_RUNNER_BRUDCAST_E2E=1 xcodebuild test -project BrudcastSample.xcodeproj \
///   -scheme BrudcastSample -destination 'platform=iOS Simulator,name=iPhone 17'
/// ```
final class CustomerFlowUITests: XCTestCase {
    private let timeout: TimeInterval = 20

    override func setUpWithError() throws {
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment["BRUDCAST_E2E"] == "1",
            "Set TEST_RUNNER_BRUDCAST_E2E=1 to run against a live Brudcast stack"
        )
        continueAfterFailure = false
    }

    func testSignInReceiveActOnShopAndSignOut() throws {
        let app = XCUIApplication()
        app.launch()
        signOutIfNeeded(app)
        let userId = "ios-e2e-\(Int(Date().timeIntervalSince1970))"

        let userField = app.textFields["userIdField"]
        XCTAssertTrue(userField.waitForExistence(timeout: timeout), "Configure SAMPLE_BACKEND_URL in Local.xcconfig")
        userField.tap()
        userField.typeText(userId)
        let emailField = app.textFields["emailField"]
        emailField.tap()
        emailField.typeText("\(userId)@example.com")
        app.buttons["signInButton"].tap()

        let sendWelcome = app.buttons["sendWelcomeButton"]
        expect(sendWelcome, "the home screen after sign-in through the backend")
        attachScreenshot(of: app, named: "Home")
        sendWelcome.tap()
        expect(app.staticTexts["Welcome, \(userId)"], "the welcome message the backend sent")
        attachScreenshot(of: app, named: "Welcome message")
        app.buttons["Get started"].tap()

        app.tabBars.buttons["Shop"].tap()
        let sneakers = app.staticTexts["Canvas sneakers"]
        expect(sneakers, "the products")
        attachScreenshot(of: app, named: "Shop")
        sneakers.tap()
        let buy = app.buttons["buyButton"]
        reveal(buy, in: app, "the buy button")
        buy.tap()
        let placeOrder = app.buttons["placeOrderButton"]
        reveal(placeOrder, in: app, "checkout")
        placeOrder.tap()
        expect(app.staticTexts["Order placed. order_completed was tracked."], "the placed order")
        attachScreenshot(of: app, named: "Order placed")

        app.tabBars.buttons["Account"].tap()
        let action = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "deeplink brudcast-sample://welcome")).firstMatch
        reveal(action, in: app, "the action in the activity log")
        attachScreenshot(of: app, named: "Activity log")
        let signOut = app.buttons["signOutButton"]
        reveal(signOut, in: app, "the sign-out button")
        signOut.tap()
        expect(app.buttons["signInButton"], "the sign-in screen after sign-out")
        attachScreenshot(of: app, named: "Signed out")
    }

    private func signOutIfNeeded(_ app: XCUIApplication) {
        let accountTab = app.tabBars.buttons["Account"]
        guard accountTab.waitForExistence(timeout: 3) else { return }
        accountTab.tap()
        let signOut = app.buttons["signOutButton"]
        reveal(signOut, in: app, "the sign-out button")
        signOut.tap()
    }

    private func expect(_ element: XCUIElement, _ what: String) {
        XCTAssertTrue(element.waitForExistence(timeout: timeout), "Expected \(what)")
    }

    private func reveal(_ element: XCUIElement, in app: XCUIApplication, _ what: String) {
        if element.waitForExistence(timeout: 3), element.isHittable { return }
        for upward in [true, false] {
            for _ in 0..<8 {
                if element.exists, element.isHittable { return }
                if upward { app.swipeUp() } else { app.swipeDown() }
            }
        }
        XCTAssertTrue(element.waitForExistence(timeout: timeout), "Expected \(what)")
    }

    private func attachScreenshot(of app: XCUIApplication, named name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
