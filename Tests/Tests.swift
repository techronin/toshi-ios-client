import XCTest
import UIKit

class Tests: XCTestCase {

    func testExample() {
        let expect = self.expectation(description: "request login with email")
        EthereumAPIClient.shared.getRate { decimal in
            XCTAssertNotNil(decimal)
            expect.fulfill()

         }

        self.waitForExpectations(timeout: 100)

    }
}
