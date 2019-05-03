import Foundation

internal struct MiniMarkdownParser {
    internal enum Element {
        case list(entries: [(index: Int, contents: Substring)])
        case paragraph(contents: [Substring])
        case headline(level: Int, title: Substring)
        case footnote(identifier: Substring, contents: Substring)

        internal var html: String {
            var buffer = ""
            switch self {
            case .list(entries: let entries):
                buffer.append("<ul>")
                entries.forEach { entry in
                    buffer.append("<li>\(convertRefs(convertEmphasis(entry.contents)))</li>")
                }
                buffer.append("</ul>")
            case .paragraph(contents: let contents):
                buffer.append("<p>")
                buffer.append(contents.map { convertRefs(convertEmphasis($0)) }.joined(separator: "<br/>"))
                buffer.append("</p>")
            case .headline(level: let level, title: let title):
                buffer.append("<h\(level)>\(convertRefs(convertEmphasis(title)))</h\(level)>")
            case .footnote(identifier: let identifier, contents: let contents):
                buffer.append("<div><strong><a name='\(identifier)'>[\(identifier)]:</a></strong> \(contents)</div>")
            }
            return buffer
        }

        internal func convertRefs(_ input: String) -> String {
            enum RefType { case image, link }
            var buffer = ""
            var refType = RefType.link
            var currentIndex = input.startIndex
            while let (textStartIndex, content) = findNext(in: input, character: "[", from: currentIndex) {

                if textStartIndex > input.startIndex && input[input.index(before: textStartIndex)] == "!" {
                    refType = .image
                    buffer.append(String(content.dropLast()))
                } else {
                    buffer.append(String(content))
                }

                let next = input.index(after: textStartIndex)
                if input[next] == "^" {
                    guard let (index, text) = findNext(in: input, character: "]", from: input.index(after: next)) else { continue }
                    buffer.append("<a href='#\(text)'>[\(text)]</a>")
                    currentIndex = input.index(after: index)
                    continue
                }

                guard let (textEndIndex, text) = findNext(in: input, character: "]", from: input.index(after: textStartIndex))
                    else {
                        currentIndex = input.index(after: textStartIndex)
                        continue
                }

                guard let (urlStartIndex, _) = findNext(in: input, character: "(", from: textEndIndex)
                    else {
                        currentIndex = input.index(after: textEndIndex)
                        continue

                }

                guard let (urlEndIndex, url) = findNext(in: input, character: ")", from: input.index(after: urlStartIndex))
                    else {
                        currentIndex = input.index(after: urlStartIndex)
                        continue
                }

                currentIndex = input.index(after: urlEndIndex)

                switch refType {
                case .link: buffer.append("<a href='\(url)'>\(text)</a>")
                case .image: buffer.append("<img src='\(url)' alt='\(text)' />")
                }
            }

            if currentIndex < input.endIndex {
                buffer.append(String(input[currentIndex..<input.endIndex]))
            }
            return buffer
        }
        
        internal func convertEmphasis(_ input: Substring) -> String {
            var buffer = ""
            var currentIndex = input.startIndex
            while let (textStartIndex, content) = findNext(in: input, character: "*", from: currentIndex) {
                buffer.append(String(content))
                for index in input.suffix(from: input.index(after: textStartIndex)).indices {
                    if input[index] == " " {
                        buffer.append(String(input[textStartIndex..<index]))
                        currentIndex = index
                        break
                    }
                    if input[index] == "*" {
                        buffer.append("<strong>")
                        buffer.append(String(input[input.index(after: textStartIndex)..<index]))
                        buffer.append("</strong>")
                        currentIndex = input.index(after: index)
                        break
                    }
                }
            }
            if currentIndex < input.endIndex {
                buffer.append(String(input[currentIndex..<input.endIndex]))
            }
            return buffer
        }

        func findNext<T: StringProtocol>(in string: T, character: Character, from: T.Index) -> (T.Index, T.SubSequence)? {
            let substring = string[from..<string.endIndex]
            guard let index = substring.firstIndex(of: character) else { return nil }
            return (index, substring[substring.startIndex..<index])
        }
    }

    /// The simplest possible markdown parser
    /// Limitations:
    /// - Headlines, lists, paragraphs, images, links, and footnotes
    /// - Only Unix newlines supported
    /// - Only '###' headlines are supported
    /// - Only "- " lists are supported
    /// - Only one space between '#' and content is supported (i.e. '## hello world' not '##    hello')
    /// - Only *bold* is supported, not ***bolder*** or __emph__
    /// - All markdown has to start and end in the same line
    func parse(_ markdown: String) -> [Element] {
        var elements: [Element] = []
        var lineCollector: [Substring] = []
        enum CurrenMode { case list, paragraph }
        var currentMode = CurrenMode.paragraph
        func processCollector() {
            guard !lineCollector.isEmpty else { return }
            switch currentMode {
            case .list:
                elements.append(.list(entries: lineCollector.enumerated().map { $0 }))
            case .paragraph:
                elements.append(.paragraph(contents: lineCollector))
            }
            lineCollector = []
        }
        for line in markdown.split(separator: "\n", omittingEmptySubsequences: false) {
            let headlineIndex = line.firstIndex(where: { $0 != "#" }) ?? line.startIndex
            let headlineLevel = headlineIndex.utf16Offset(in: line) - line.startIndex.utf16Offset(in: line)
            let isList = line.starts(with: "- ")
            let isFootnote = line.starts(with: "[^")
            let isParagraphEnd = line.isEmpty
            if isParagraphEnd {
                processCollector()
            } else if headlineLevel > 0 {
                elements.append(.headline(level: headlineLevel,
                                          title: line[line.index(after: headlineIndex)..<line.endIndex]))
            } else if isFootnote {
                let identifier = line.dropFirst(2).prefix(while: { $0 != "]" })
                let contents = line.drop(while: { $0 != "]" }).drop(while: { $0 != " " }).dropFirst()
                elements.append(.footnote(identifier: identifier, contents: contents))
            } else if isList {
                if currentMode == .paragraph { processCollector() }
                lineCollector.append(line.dropFirst(2))
                currentMode = .list
            } else {
                if currentMode == .list { processCollector() }
                lineCollector.append(line)
                currentMode = .paragraph
            }
        }
        processCollector()
        return elements
    }

    func parseHTML(_ markdown: String) -> String {
        return parse(markdown).map {$0.html}.joined()
    }
}
