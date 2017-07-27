import XCTest
import UIKit
import Teapot

class MockedTests: XCTestCase {
    var subject: AppsAPIClient!
    let session = MockURLSession()

    override func setUp() {
        super.setUp()

        let mockTeapot = Teapot(baseURL: URL(string: "https://token-id-service-development.herokuapp.com")!)
        mockTeapot.session = session
        subject = AppsAPIClient(mockTeapot: mockTeapot)
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
