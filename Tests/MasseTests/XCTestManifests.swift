import XCTest

#if !os(macOS)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(MasseTests.allTests),
        testCase(TemplateTests.allTests),
        testCase(MiniMarkdownTests.allTests)
    ]
}
#endif
