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
        var pos = 0
        for line in contents.components(separatedBy: .newlines) {
            if hasReachedSeparator {
                noteLines.append(line)
                let remainder = String(contents[contents.index(contents.startIndex, offsetBy: pos)..<contents.endIndex])
                print(remainder)
                let parser = MiniMarkdownParser()
                overflowKey.map { result[$0] = parser.parseHTML(remainder) }
                break
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
            pos += line.count + 1
        }
        return result
    }
}
