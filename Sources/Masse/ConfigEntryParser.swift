struct ConfigEntryParser {
    private let metaPrefix = "- "
    private let metaSeparator = ": "
    private let separator = "---"
    private let contents: String
    private let keys: [String]
    private let overflowKey: String?
    
    init(contents: String, keys: [String], overflowKey: String? = nil) {
        self.contents = contents
        self.keys = keys
        self.overflowKey = overflowKey
    }
    
    init(url: URL, keys: [String], overflowKey: String? = nil) throws {
        let contents = try String(contentsOf: url)
        self.init(contents: contents, keys: keys, overflowKey: overflowKey)
    }
    
    func retrieve() -> [String: String] {
        var hasReachedSeparator = false
        var result: [String: String] = [:]
        var noteLines: [String] = []
        for line in contents.components(separatedBy: .newlines) {
            if hasReachedSeparator {
                noteLines.append(line)
            } else {
                for key in keys {
                    let start = "\(metaPrefix)\(key)\(metaSeparator)"
                    if line.starts(with: start),
                        let range = line.range(of: metaSeparator) {
                        result[key] = String(line[range.upperBound..<line.endIndex])
                    }
                }
                if line == separator && overflowKey != nil {
                    hasReachedSeparator = true
                }
            }
        }
        overflowKey.map { result[$0] = parsedNotes(noteLines).reduce("") { $0 + "\($1)\n" } }
        return result
    }

    func parsedNotes(_ noteLines: [String]) -> [String] {
        let titleKey = "# "
        let entryKey = "- "
        let entrySeparator = ": "
        var result = ["<div>"]

        func listEntry(forLine line: String) -> String {
            guard let urlStart = line.range(of: entrySeparator)?.upperBound else { fatalError() }
            let url = String(line[urlStart..<line.endIndex])
            let name = line.between(beginString: metaPrefix, endString: "\(entrySeparator)\(url)")!
            return "<li><a href=\"\(url)\">\(name)</a></li>"
        }

        func title(forLine line: String) -> String {
            precondition(line.starts(with: titleKey))
            return "<h3>\(line.dropFirst(2))</h3>"
        }

        var wasPreviousLineTopic = false
        var wasPreviousLineEntry = false

        noteLines.forEach {
            if $0.starts(with: entryKey) { // li entry
                if wasPreviousLineTopic == false && wasPreviousLineEntry == false {
                    result.append("    <ul>")
                }
                result.append("      \(listEntry(forLine: $0))")
                wasPreviousLineEntry = true
            } else if wasPreviousLineEntry {
                result.append("    </ul>")
                wasPreviousLineEntry = false
            }
            if $0.starts(with: titleKey) {
                if let lastLine = result.last, lastLine.isEmpty, let popped = result.popLast() {
                    result.append("  </p>")
                    result.append(popped)
                }
                result.append("  <p>")
                result.append("    \(title(forLine: $0))")
                result.append("    <ul>")
                wasPreviousLineTopic = true
            } else {
                wasPreviousLineTopic = false
            }
            if $0.isEmpty { result.append("") }
        }
        result.append("    </ul>")
        result.append("  </p>")
        result.append("</div>")
        return result
    }
}
