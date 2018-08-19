/// Replaces sections and variables within a template
/// sections are lines with the following syntax
/// ```
/// {{SECTION name="meta"}}
/// ```
/// variables are parts of a line with the following syntax:
/// ```
/// His name is #{name}#, he is #{age}# years old
/// ```
/// Loops look like this:
/// ```
/// {{LOOP from="posts" to="post" limit="0"}}
/// <h1>#{post.name} #{index}</h1>
/// {{ENDLOOP}}
/// ```
struct TemplateVariablesParser {
    private let variableStart = "#{"
    private let variableEnd = "}#"
    private let sectionStart = "{{SECTION name=\""
    private let sectionEnd = "\"}}"
    private let beginLoopStart = "{{LOOP "
    private let beginLoopEnd = "}}"
    private let endLoop = "{{ENDLOOP}}"
    private let sectionMap: [String: String]
    private let variablesMap: [String: String]
    private let contextMap: [String: [[String: String]]]
    private let contents: String
    
    struct Loop {
        let from: String
        let to: String
        let limit: Int
        var contents: String
    }
    
    init(contents: String, sections: [String: String], variables: [String: String], context: [String: [[String: String]]]) {
        self.sectionMap = sections
        self.variablesMap = variables
        self.contents = contents
        self.contextMap = context
    }
    
    func retrieve() -> String {
        return parse(contents, variables: variablesMap).joined(separator: "\n")
    }
    
    private func parse(_ section: String, variables: [String: String]) -> [String] {
        var lines: [String] = []
        var currentLoop: Loop?
        for line in section.components(separatedBy: .newlines) {
            if let loop = currentLoop, line == endLoop {
                lines.append(contentsOf: applyLoop(loop))
                currentLoop = nil
            } else if currentLoop != nil {
                currentLoop?.contents.append("\(line)\n")
            } else if let beginLoop = isLoopLine(line: line) {
                currentLoop = beginLoop
            } else {
                lines.append(lineWithVariablesSubstituted(line: lineOrSectionReplacement(line: line, variables: variables), variables: variables))
            }
        }
        return lines
    }
    
    private func applyLoop(_ loop: Loop) -> [String] {
        guard let items = contextMap[loop.from] else {
            log("No context for loop with \(loop.from)")
            return []
        }
        var lines: [String] = []
        let amount = loop.limit > 0 ? loop.limit : items.count
        for idx in 0..<min(amount, items.count) {
            var variables = variablesMap
            variables["index"] = String(idx + 1)
            for (key, value) in items[idx] {
                variables["\(loop.to).\(key)"] = value
            }
            lines.append(contentsOf: parse(loop.contents, variables: variables))
        }
        return lines
    }
    
    private func isLoopLine(line: String) -> Loop? {
        guard let (inner, _, _) = nameBetweenIdentifiers(line: line, begin: beginLoopStart, end: beginLoopEnd) else {
            return nil
        }
        let keyValueSequence = inner.components(separatedBy: .whitespaces)
            .map({ $0.replacingOccurrences(of: "\"", with: "").split(separator: "=") })
            .map { ($0[0], $0[1]) }
        let dict: [Substring: Substring] = Dictionary(uniqueKeysWithValues: keyValueSequence)
        guard let fromValue = dict["from"], let toValue = dict["to"] else {
            log("Not enough parameters for loop dictionary in: \(dict)")
            return nil
        }
        let limitValue = (dict["limit"].map { Int($0) ?? 0 }) ?? 0
        return Loop(from: String(fromValue), to: String(toValue), limit: limitValue, contents: "")
    }
    
    private func lineWithVariablesSubstituted(line: String, variables: [String: String]) -> String {
        var internalLine = line
        while true {
            guard let (name, start, end) = nameBetweenIdentifiers(line: internalLine, begin: variableStart, end: variableEnd) else {
                break
            }
            guard let variable = variables[name] else {
                log("Unknown variable \(name)")
                break
            }
            internalLine.replaceSubrange(start..<end, with: variable)
        }
        return internalLine
    }
    
    private func lineOrSectionReplacement(line: String, variables: [String: String]) -> String {
        guard let (name, _, _) = nameBetweenIdentifiers(line: line, begin: sectionStart, end: sectionEnd) else {
            return line
        }
        guard let section = sectionMap[name] else {
            log("Unknown section: \(name)")
            return ""
        }
        // there may be variables in the section
        return parse(section, variables: variables).joined(separator: "\n")
    }
    
    private func nameBetweenIdentifiers(line: String, begin: String, end: String) -> (String, String.Index, String.Index)? {
        guard let startRange = line.range(of: begin),
            let endRange = line.range(of: end) else {
                return nil
        }
        return (String(line[startRange.upperBound..<endRange.lowerBound]), startRange.lowerBound, endRange.upperBound)
    }
}
