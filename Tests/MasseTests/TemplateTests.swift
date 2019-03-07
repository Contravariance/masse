import XCTest
@testable import Masse

final class TemplateTests: XCTestCase {
    func testTemplateParser() {
        let template = """
 <html>
 <body>
 {{BEGIN name="klaus"}}
 <h1>this is the headline</h1>
 {{END}}
 """
        let parsed = TemplateBlockParser(contents: template)
        let (_, sections) = parsed.retrieve()
        XCTAssertEqual(sections["klaus"], "<h1>this is the headline</h1>")
    }
    
    func testVariableParser() {
        let variables = ["klaus": "1", "jochen": "mathias"]
        let sections = ["section1": "<h1>test</h1>"]
        let context: [String: [[String: String]]] = [:]
        let template = """
 <html>
 <body>
 {{SECTION name="section1"}}
 another example of #{jochen}#
 <h1>this is the headline</h1>
 goobye
 #{klaus}#
 """
        let parser = TemplateVariablesParser(contents: template, sections: sections, variables: variables, context: context)
        let output = parser.retrieve()
        XCTAssertEqual(output, """
<html>
<body>
<h1>test</h1>
another example of mathias
<h1>this is the headline</h1>
goobye
1
""")
    }
    
    func testLoopParser() {
        let variables = ["klaus": "1"]
        let context = ["entries": [
            ["name": "hans", "age": "55"],
            ["name": "hanz", "age": "35"],
            ]]
        let template = """
 <html>
 {{LOOP from="entries" to="entry"}}
 <b>#{index}# of #{entry.name}# with age #{entry.age}# in #{klaus}#</b>
 {{ENDLOOP}}
 </html>
 """
        let parser = TemplateVariablesParser(contents: template, sections: [:], variables: variables, context: context)
        XCTAssertEqual(parser.retrieve(), """
<html>
<b>1 of hans with age 55 in 1</b>

<b>2 of hanz with age 35 in 1</b>

</html>
""")
    }
    
    func testCastEntryParser() {
        // private let keys = ["nr", "title", "date", "file", "duration", "author", "description"] notes
        let entry = """
 - nr: 101
 - title: A long history of silence
 - date: [something parseable]
 - file: something.mp3
 - duration: 00:33:22
 - length: 404
 - author: Bas Broek / Benedikt Terhechte
 - description: This is a long description with a really long description and another long description.
 ---
 # These are the show notes
 - name: url
 - name: url

 - name: url

 # New notes
 - name: url
 """
        let parser = ConfigEntryParser(contents: entry, keys: Keys.PodcastEntry.allCases.map { $0.rawValue }, overflowKey: Keys.PodcastEntry.notes.rawValue)
        let dict = parser.retrieve()
        XCTAssertEqual(dict["nr"], "101")
        XCTAssertEqual(dict["title"], "A long history of silence")
        XCTAssertEqual(dict["file"], "something.mp3")
        XCTAssertEqual(dict["duration"], "00:33:22")
        XCTAssertEqual(dict["length"], "404")
        XCTAssertEqual(dict["notes"], "<h1>These are the show notes</h1><ul><li>name: url</li><li>name: url</li></ul><ul><li>name: url</li></ul><h1>New notes</h1><ul><li>name: url</li></ul>")
    }
    
    
    static var allTests = [
        ("testTemplateParser", testTemplateParser),
        ("testVariableParser", testVariableParser),
        ("testLoopParser", testLoopParser),
        ("testCastEntryParser", testCastEntryParser),
        ]
}

