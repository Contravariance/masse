/// Takes a site configuration and generates
struct Site {
    private let configuration: Configuration
    private var context: [String: [[String: String]]] = [:]
    private var sections: [String: String] = [:]
    private var variables: [String: String] = [:]
    private var entries: [PodcastEntry] = []
    private var templates: [Template] = []
    private var entriesTemplate: Template?
    
    init(configuration: Configuration) {
        self.configuration = configuration
    }
    
    mutating func build() throws {
        try parseEntries()
        try parseTemplates()
        makeRenderState()
        try renderPages()
        try renderEntries()
    }
    
    /// Goes through all the posts
    private mutating func parseEntries() throws {
        for file in try FileManager.default.contentsOfDirectory(atPath: configuration.podcastEntriesFolder) {
            let url = URL(fileURLWithPath: "\(configuration.podcastEntriesFolder)/\(file)")
            guard url.pathExtension == "bacf" else { continue }
            let parsed = try ConfigEntryParser(url: url, keys: Keys.PodcastEntry.allCases.map { $0.rawValue }, overflowKey: Keys.PodcastEntry.notes.rawValue)
            let entry = PodcastEntry(meta: parsed.retrieve(), filename: file, folder: configuration.mp3FilesFolder)
            entries.append(entry)
        }
    }
    
    /// Goes through all .html files beginning with a _ and collect their sections.
    /// then, write them all into non _ files
    private mutating func parseTemplates() throws {
        for file in try FileManager.default.contentsOfDirectory(atPath: configuration.templateFolder) {
            guard file.starts(with: "_") else { continue }
            let path = "\(configuration.templateFolder)/\(file)"
            var isDirectory = ObjCBool(false)
            guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) else { continue }
            guard isDirectory.boolValue == false else { continue }
            let url = URL(fileURLWithPath: path)
            guard url.pathExtension == "html" || url.pathExtension == "rss" else { continue }
            let template = try Template(path: url)
            if file == configuration.entriesTemplate {
                entriesTemplate = template
            } else {
                templates.append(template)
            }
        }
    }
    
    private mutating func makeRenderState() {
        for page in templates {
            sections.merge(page.sections) { a, _ -> String in
                failedExecution("Duplicate section named \(a) in \(page.path)")
            }
        }
        context["entries"] = entries.sorted(by: { post1, post2 -> Bool in
            return post1.date > post2.date
        }).map { $0.meta }
        variables.merge(configuration.meta) { a, _ -> String in
            failedExecution("Duplicate variables key \(a)")
        }
        variables["buildDate"] = PodcastEntry.podcastDateFormatter.string(from: Date())
    }
    
    private func renderPages() throws {
        for page in templates {
            try page.renderOut(variables: variables, sections: sections, context: context)
        }
    }
    
    private func renderEntries() throws {
        let template = entriesTemplate.expect("Entries Template file \(configuration.entriesTemplate) not found")
        for entry in entries {
            var customVariables = variables
            customVariables.merge(entry.meta) { a, _ -> String in
                failedExecution("variables key \(a) also exists in entry \(entry.filename)")
            }
            let outFile = URL(fileURLWithPath: configuration.podcastTargetFolder)
                .appendingPathComponent(entry.filename)
                .deletingPathExtension()
                .appendingPathExtension("html")
            log("Writing \(entry.filename) to \(outFile)")
            try template.renderOut(variables: customVariables, sections: sections, context: context, to: outFile)
        }
    }
}
