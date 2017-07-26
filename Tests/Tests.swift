import XCTest
import UIKit

class Tests: XCTestCase {

    func testExample() {
        AppsAPIClient.shared.getTopRatedApps { apps, error in
            XCTAssertTrue(true)

        }


    }
}
