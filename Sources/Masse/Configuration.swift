struct Configuration {
    /// The folder that houses the _ templates
    var templateFolder = ""
    /// The folder where all the posts are
    var podcastEntriesFolder = ""
    /// The folder where the posts are written to
    var podcastTargetFolder = ""
    /// The title of the podcast
    var podcastTitle = ""
    /// The template to use for each entry
    var entriesTemplate = ""
    /// The folder where the mp3 files are
    var mp3FilesFolder = ""
    /// The remaining meta
    var meta: [String: String] = [:]
    
    init(path: URL) throws {
        let parsed = try ConfigEntryParser(url: path, keys: Keys.Configuration.allCases.map { $0.rawValue }).retrieve()
        let entries: [(WritableKeyPath<Configuration, String>, Keys.Configuration)] = [
            (\Configuration.templateFolder, .templateFolder),
            (\Configuration.podcastEntriesFolder, .podcastEntriesFolder),
            (\Configuration.podcastTargetFolder, .podcastTargetFolder),
            (\Configuration.podcastTitle, .podcastTitle),
            (\Configuration.mp3FilesFolder, .mp3FilesFolder),
            (\Configuration.entriesTemplate, .entriesTemplate)]
        for (keyPath, key) in entries {
            self[keyPath: keyPath] = parsed[key.rawValue].expect("Need \(key.rawValue) entry in configuration")
        }
        meta = parsed
    }
}
