import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(xcodebuild_to_summarytableTests.allTests),
    ]
}
#endif
