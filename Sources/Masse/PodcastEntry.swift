struct PodcastEntry {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    static let podcastDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        // Wed, 08 Aug 2018 19:00:00 GMT
        formatter.dateFormat = "EEE, dd LLL yyyy HH:mm:ss z"
        return formatter
    }()
    
    var meta: [String: String]
    let date: Date
    let filename: String
    
    init(meta: [String: String], filename: String) {
        self.meta = meta
        self.filename = filename
        let dateString = meta[Keys.PodcastEntry.date.rawValue].expect("Need \(Keys.PodcastEntry.date.rawValue) entry in podcast entry \(filename)")
        date = PodcastEntry.dateFormatter.date(from: dateString).expect("Invalid formatted date \(dateString) in post \(filename)")
        // insert the podcast-format date into the meta
        self.meta["podcastDate"] = PodcastEntry.podcastDateFormatter.string(from: date)
    }
}
