import XCTest
@testable import Masse

import Foundation

final class MinimarkdownTests: XCTestCase {
    func testHTMLElements() {
        XCTAssertEqual(MiniMarkdownParser.Element.footnote(identifier: "a", contents: "Hello").html, "<div><strong><a name='a'>[a]:</a></strong> Hello</div>")
        XCTAssertEqual(MiniMarkdownParser.Element.headline(level: 2, title: "Hello").html, "<h2>Hello</h2>")
        XCTAssertEqual(MiniMarkdownParser.Element.list(entries: [(index: 1, contents: "Hello"),
                                                     (index: 2, contents: "World")]).html,
                       "<ul><li>Hello</li><li>World</li></ul>")
        XCTAssertEqual(MiniMarkdownParser.Element.paragraph(contents: ["hello", "world", "joe"]).html, "<p>hello<br/>world<br/>joe</p>")
    }

    func testHTMLRefs1() {
        XCTAssertEqual(
            convertHTMLRefs("this is a [url](http://heise.de)")
            ,
            "this is a <a href='http://heise.de'>url</a>"
        )
    }

    func testHTMLRefs2() {
        XCTAssertEqual(
            convertHTMLRefs("this is a [url](http://heise.de) with more")
            ,
            "this is a <a href='http://heise.de'>url</a> with more"
        )
    }

    func testHTMLRefs3() {
        XCTAssertEqual(
            convertHTMLRefs("oh [these](a) are [two](b) [urls](c)")
            ,
            "oh <a href='a'>these</a> are <a href='b'>two</a> <a href='c'>urls</a>"
        )
    }

    func testHTMLRefs4() {
        XCTAssertEqual(
            convertHTMLRefs("pure content")
            ,
            "pure content"
        )
    }

    func testHTMLRefs5() {
        XCTAssertEqual(
            convertHTMLRefs("[hui](test)")
            ,
            "<a href='test'>hui</a>"
        )
    }

    func testHTMLRefs6() {
        XCTAssertEqual(
            convertHTMLRefs("[hui](test)[huihui](testtest)")
            ,
            "<a href='test'>hui</a><a href='testtest'>huihui</a>"
        )
    }

    func testHTMLRefs7() {
        XCTAssertEqual(
            convertHTMLRefs("![hello](/img.jpg)")
            ,
            "<img src='/img.jpg' alt='hello' />"
        )
    }

    func testHTMLRefs8() {
        XCTAssertEqual(
            convertHTMLRefs("an ![hello](/img.jpg) image")
             ,
            "an <img src='/img.jpg' alt='hello' /> image"
        )
    }

    func testHTMLRefs9() {
        XCTAssertEqual(
            convertHTMLRefs("the [^on] is on")
            ,
            "the <a href='#on'>[on]</a> is on"
        )
    }

    func testSplitWithBreaks() {
        let content = "a\n\nb\nc\nd\n\ne"
        let parsed = content.splitWithBreaks()
        XCTAssertEqual(parsed, ["a", "", "b", "c", "d", "", "e"])
    }

    func testSplitWithBreaksNoBreaks() {
        let content = "# test"
        let parsed = content.splitWithBreaks()
        XCTAssertEqual(parsed, ["# test"])
    }

    func testMarkdownTitle1() {
        XCTAssertEqual(convertMarkdown("# test"), "<h1>test</h1>")
    }

    func testMarkdownTitle2() {
        XCTAssertEqual(convertMarkdown("## test"), "<h2>test</h2>")
    }

    func testMarkdownList() {
        XCTAssertEqual(convertMarkdown("- a\n- b"), "<ul><li>a</li><li>b</li></ul>")
    }

    func testMarkdownParagraphs1() {
        XCTAssertEqual(MiniMarkdownParser().parseHTML("ab\ncd\n\nef"),
        "<p>ab<br/>cd</p><p>ef</p>")
    }

    func testMarkdownParagraphs2() {
        XCTAssertEqual(MiniMarkdownParser().parseHTML("ab\n\ncd\n\nef"),
            "<p>ab</p><p>cd</p><p>ef</p>")
    }

    func testMarkdown() {
        let content = """
# First Headline
![paragraph](paragraph), paragrahp
paragraph

paragraph [paragraph](paragraph)
paragraph

## Second headline [^1]

- List 1
- List 2
- list 3

### Third headline

longer pargraph

[^1] Footnote 1. Done.
"""
        let expected = "<h1>First Headline</h1><p><img src='paragraph' alt='paragraph' />, paragrahp<br/>paragraph</p><p>paragraph <a href='paragraph'>paragraph</a><br/>paragraph</p><h2>Second headline <a href='#1'>[1]</a></h2><ul><li>List 1</li><li>List 2</li><li>list 3</li></ul><h3>Third headline</h3><p>longer pargraph</p><div><strong><a name='1'>[1]:</a></strong> Footnote 1. Done.</div>"
        XCTAssertEqual(expected, MiniMarkdownParser().parseHTML(content))
    }

    private func convertHTMLRefs(_ content: String) -> String {
        let html = MiniMarkdownParser.Element.paragraph(contents: [])
            .convertRefs(content[content.startIndex..<content.endIndex])
        return html
    }

    private func convertMarkdown(_ content: String) -> String {
        let p = MiniMarkdownParser()
        let elements = p.parse(content)
        return elements[0].html
    }

    static var allTests = [
        ("testHTMLElements", testHTMLElements),
        ("testHTMLRefs1", testHTMLRefs1),
        ("testHTMLRefs2", testHTMLRefs2),
        ("testHTMLRefs3", testHTMLRefs3),
        ("testHTMLRefs4", testHTMLRefs4),
        ("testHTMLRefs5", testHTMLRefs5),
        ("testHTMLRefs6", testHTMLRefs6),
        ("testHTMLRefs7", testHTMLRefs7),
        ("testHTMLRefs8", testHTMLRefs8),
        ("testHTMLRefs9", testHTMLRefs9),
        ("testSplitWithBreaks", testSplitWithBreaks),
        ("testSplitWithBreaksNoBreaks", testSplitWithBreaksNoBreaks),
        ("testMarkdownTitle1", testMarkdownTitle1),
        ("testMarkdownTitle2", testMarkdownTitle2),
        ("testMarkdownList", testMarkdownList),
        ("testMarkdownParagraphs1", testMarkdownParagraphs1),
        ("testMarkdownParagraphs2", testMarkdownParagraphs2),
        ]
}
