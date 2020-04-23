import XCTest
@testable import SwiftiumTestingKit

final class SwiftiumTestingKitTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(SwiftiumTestingKit().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
