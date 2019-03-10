extension String {
    func between(beginString: String, endString: String) -> String? {
        // why is it still such a pain to grab a range out of string in swift...
        // I know I could use `NSRange` and then convert it, but that feels like cheating
        guard self.starts(with: beginString) && self.suffix(endString.count) == endString else {
            return nil
        }
        let beginPosition = self.index(self.startIndex, offsetBy: beginString.count).encodedOffset
        let endPosition = self.index(self.endIndex, offsetBy: -endString.count).encodedOffset
        return between(beginPosition: beginPosition, endPosition: endPosition)
    }

    func between(beginPosition: Int, endPosition: Int) -> String {
        let beginIndex = self.index(self.startIndex, offsetBy: beginPosition)
        let endIndex = self.index(self.startIndex, offsetBy: endPosition)
        return String(self[beginIndex..<endIndex])
    }

    /// Split into lines by `\n` however keep empty lines as empty strings
    func splitWithBreaks() -> [Substring] {
        var results: [Substring] = []
        var (lowerIndex, upperIndex) = (startIndex, startIndex)
        while upperIndex < endIndex {
            if self[upperIndex] == "\n" {
                let transformedIndex = lowerIndex
                results.append(self[transformedIndex..<upperIndex])
                lowerIndex = self.index(after: upperIndex)
            }
            upperIndex = index(after: upperIndex)
        }

        if lowerIndex < endIndex {
            results.append(self[lowerIndex..<endIndex])
        }
        return results
    }
}
