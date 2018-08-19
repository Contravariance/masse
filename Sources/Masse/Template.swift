struct Template {
    let path: URL
    let contents: String
    let cleanedContents: String
    let sections: [String: String]
    
    init(path: URL) throws {
        self.path = path
        self.contents = try String(contentsOf: path)
        let parser = TemplateBlockParser(contents: self.contents)
        (self.cleanedContents, self.sections) = parser.retrieve()
    }
    
    func renderOut(variables: [String: String], sections: [String: String], context: [String: [[String: String]]], to file: URL? = nil) throws {
        let parser = TemplateVariablesParser(contents: cleanedContents, sections: sections, variables: variables, context: context)
        let rendered = parser.retrieve()
        let finalOutFile = file ?? outfile()
        log("Writing \(path) to \(finalOutFile)")
        try rendered.write(to: finalOutFile, atomically: true, encoding: .utf8)
    }
    
    private func outfile() -> URL {
        // the first char of the filename is a _
        let filename = path.lastPathComponent.dropFirst()
        return path.deletingLastPathComponent().appendingPathComponent(String(filename))
    }
}
