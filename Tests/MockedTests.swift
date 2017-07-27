import XCTest
import UIKit

class MockedTests: XCTestCase {
    var subject: AppsAPIClient!
    let session = MockURLSession()

    override func setUp() {
        super.setUp()

        subject = AppsAPIClient()
        subject.teapot.session = session
    }

    func test_GET_RequestsTheURL() {
        let expect = self.expectation(description: "test")
        subject.getFeaturedApps { (user, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(user)
            expect.fulfill()
        }
        self.waitForExpectations(timeout: 100)
    }
}

class MockURLSession: URLSession {
    var request: URLRequest?

    override func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        self.request = request
        return super.dataTask(with: request, completionHandler: completionHandler)
    }
}
