func arguments(for originalArguments: [String]) -> [String] {
    // Main Entry Point
    // calling swift on the commandline inserts a lot of additional arguments.
    // we're only interested in everything behind the --
    // If we have a '--' then we're in script mode, otherwise we're in executable mode
    // then all arguments count
    if let idx = originalArguments.firstIndex(where: { $0 == "--" }) {
        return Array(originalArguments[(idx + 1)..<originalArguments.endIndex])
    } else {
        return originalArguments
    }
}
