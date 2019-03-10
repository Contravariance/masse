import XCTest
@testable import Masse

import Foundation

final class MasseTests: XCTestCase {
    func testArguments() {
        XCTAssertEqual(arguments(for: ["a", "b", "--", "c"]), ["c"])
        XCTAssertEqual(arguments(for: ["a", "b", "c"]), ["a", "b", "c"])
    }


    static var allTests = [
        ("testArguments", testArguments),
    ]
}
