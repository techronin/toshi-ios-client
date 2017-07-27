import XCTest
import UIKit

class Tests: XCTestCase {

    func testExample() {
        let expect = self.expectation(description: "get ethereum rate")
        EthereumAPIClient.shared.getRate { decimal in
            XCTAssertNotNil(decimal)
            expect.fulfill()

         }

        self.waitForExpectations(timeout: 100)

    }
}
