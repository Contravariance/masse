enum Keys {
    enum Configuration: String, CaseIterable {
    case templateFolder, podcastEntriesFolder, podcastTargetFolder, podcastTitle, entriesTemplate, podcastLink, podcastDescription, podcastKeywords, iTunesOwner, iTunesEmail, linkiTunes, linkOvercast, linkTwitter, linkPocketCasts, podcastAuthor

    }
    enum PodcastEntry: String, CaseIterable {
        case nr, title, date, file, duration, length, author, description, notes
    }
}

extension Optional {
    func expect(_ error: String) -> Wrapped {
        guard let contents = self else {
            failedExecution(error)
        }
        return contents
    }
}
