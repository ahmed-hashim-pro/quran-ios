import SystemDependencies
import XCTest

final class DefaultNetworkConnectionTests: XCTestCase {
    func test_isOnWiFi_answersARightAwayQuestionOnceTheFirstPathArrives() async {
        let connection = DefaultNetworkConnection()
        let answered = expectation(description: "Answered")

        Task {
            _ = await connection.isOnWiFi()
            answered.fulfill()
        }

        await fulfillment(of: [answered], timeout: 5)
    }
}
