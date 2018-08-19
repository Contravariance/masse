/// Detect blocks within the template file.
/// Blocks have the following syntax:
/// ```
/// <html>
/// {{BEGIN name="meta"}}
/// <meta name="#{name}#" content="#{value}#">
/// {{END}}
/// <body></body>
/// ```
/// I.e. {{BEGIN name="..."}} [something] {{END}}
///
/// Parsing is not recursive, i.e. blocks in blocks are not supported
struct TemplateBlockParser {
    private let beginMarkerStart = "{{BEGIN name=\""
    private let beginMarkerEnd = "\"}}"
    private let endMarkerStart = "{{END}}"
    private let contents: String
    
    private var currentName: String?
    private var currentLines: [String] = []
    
    private var cleanedContents: [String] = []
    private var sections: [String: String] = [:]
    
    init(contents: String) {
        self.contents = contents
        parse()
    }
    
    func retrieve() -> (String, [String: String]) {
        return (cleanedContents.joined(separator: "\n"), sections)
    }
    
    private mutating func parse() {
        for line in contents.components(separatedBy: .newlines) {
            if let name = line.between(beginString: beginMarkerStart, endString: beginMarkerEnd) {
                currentName = name
            } else if line.starts(with: endMarkerStart) {
                takeSection()
            } else if currentName != nil {
                currentLines.append(line)
                cleanedContents.append(line)
            } else {
                cleanedContents.append(line)
            }
        }
    }

    private mutating func takeSection() {
        guard let name = currentName else { return }
        sections[name] = currentLines.joined(separator: "\n")
        currentName = nil
        currentLines.removeAll()
    }
}
