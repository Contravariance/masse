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
    
    init(meta: [String: String], filename: String, folder: String) {
        self.meta = meta
        self.filename = filename
        let dateString = meta[Keys.PodcastEntry.date.rawValue].expect("Need \(Keys.PodcastEntry.date.rawValue) entry in podcast entry \(filename)")
        date = PodcastEntry.dateFormatter.date(from: dateString).expect("Invalid formatted date \(dateString) in post \(filename)")
        
        // insert the podcast-format date into the meta
        self.meta["podcastDate"] = PodcastEntry.podcastDateFormatter.string(from: date)
        
        // calculate the duration
        guard let mp3Filename = meta[Keys.PodcastEntry.file.rawValue] else {
            return
        }
        let url = URL(fileURLWithPath: "\(folder)/\(mp3Filename)")
        guard let data = try? Data(contentsOf: url) else {
            print("Could not read mp3 file `\(url)`")
            return
        }
        self.meta[Keys.PodcastEntry.length.rawValue] = "\(data.count)"
        let stream = InputStream(data: data)
        do {
            stream.open()
            let calculator = try MP3DurationCalculator(inputStream: stream)
            let duration = try calculator.calculateDuration()
            self.meta[Keys.PodcastEntry.duration.rawValue] = duration.description
        } catch let error {
            print("Could not caculate duration of MP3: \(mp3Filename)\n\t\(error)")
        }
    }
}
