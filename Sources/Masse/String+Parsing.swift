extension String {
    func between(beginString: String, endString: String) -> String? {
        // why is it still such a pain to grab a range out of string in swift...
        // I know I could use `NSRange` and then convert it, but that feels like cheating
        guard self.starts(with: beginString) && self.suffix(endString.count) == endString else {
            return nil
        }
        let beginPosition = self.index(self.startIndex, offsetBy: beginString.count)
        let endPosition = self.index(self.endIndex, offsetBy: -endString.count)
        return String(self[beginPosition..<endPosition])
    }
}
