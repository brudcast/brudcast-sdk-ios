import XCTest
@testable import Brudcast

final class DecisionTests: XCTestCase {
    func testKeepsTheFirstAnswer() {
        var answers: [BrudcastActionResult] = []
        let decision = BrudcastDecision(fallback: BrudcastActionResult.useDefault, timeoutMessage: "late") { answers.append($0) }
        decision.decide(.handled)
        decision.decide(.useDefault)
        XCTAssertEqual(answers, [.handled])
    }

    func testUsesTheFallbackAfterTheTimeout() {
        let answered = expectation(description: "fallback")
        var answers: [BrudcastActionResult] = []
        let decision = BrudcastDecision(fallback: BrudcastActionResult.useDefault, timeout: 0.05, timeoutMessage: "late") {
            answers.append($0)
            answered.fulfill()
        }
        wait(for: [answered], timeout: 1)
        decision.decide(.handled)
        XCTAssertEqual(answers, [.useDefault])
    }
}
