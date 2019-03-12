import XCTest
@testable import Masse

final class MP3DurationTests: XCTestCase {
    var paths: [String: String] = [
        // Generated with `ffmpeg -i filename`
        "Tests/MasseTests/Resources/ID3v1.mp3": "00:06:38",
        "Tests/MasseTests/Resources/Truncated.mp3": "00:03:26",
        "Tests/MasseTests/Resources/VBR9.mp3": "00:06:38"
    ]
    override func setUp() {
        let filemanager = FileManager.default
        let folder = filemanager.currentDirectoryPath
        var newPaths: [String: String] = [:]
        // Preflight-Check to make sure the mp3s exist
        for path in paths.keys {
            let fullPath = "\(folder)/\(path)"
            guard filemanager.fileExists(atPath: fullPath) else {
                return longAwfulErrorMessage()
            }
            newPaths[fullPath] = paths[path]
        }
        paths = newPaths
    }
    
    func testMp3Durations() {
        for (path, staticDuration) in paths {
            let url = URL(fileURLWithPath: path)
            do {
                let mp3Duration = try MP3DurationCalculator(url: url)
                let duration = try mp3Duration.calculateDuration()
                let durationString = duration.description
                XCTAssertEqual(durationString, staticDuration)
            } catch let error {
                XCTFail("\(path) \(error)")
            }
        }
    }
    
    static var allTests = [
        ("testMp3Durations", testMp3Durations),
        ]
    
    private func longAwfulErrorMessage() {
        let message = """


Hi!

Either your Repository is borked, or (FAR MORE LIKELY)
you're trying to run the tests from within Xcode.

Thing is, this doesn't fly: The *package manager from the future*, SPM, doesn't even
support loading `resources` for tests. You can do so with a collection of awful hacks,
but apparently it is not possible yet. Because, why would you want to load resources
during tests, right? Yeah right.

Anyway, the `masse` tests need to be run from the terminal via

```
swift test
```

because that way, I can mangle the resources in. Since the Xcode project is auto-generated,
this doesn't work. We could add the generated Xcode project to the repo, but that would lead
to other issues.

More info for the curious investigator:

- https://forums.swift.org/t/swift-pm-bundles-and-resources/13981
- https://stackoverflow.com/questions/47177036/use-resources-in-unit-tests-with-swift-package-manager
- https://bugs.swift.org/browse/SR-2866
- https://github.com/vadimeisenbergibm/SwiftResourceHandlingExample

"""
        print(message)
        XCTFail(message)
    }
}
