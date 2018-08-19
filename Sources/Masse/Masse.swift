@_exported import Foundation

struct Masse {
    static func run() {
        let args = arguments(for: ProcessInfo.processInfo.arguments)
        guard args.count == 1 else {
            syntax()
        }
        let path = args.first.expect("Expecting config file path")
        let configurationURL = URL(fileURLWithPath: path)
        do {
            let configuration = try Configuration(path: configurationURL)
            var site = Site(configuration: configuration)
            try site.build()
        } catch let err {
            failedExecution("\(err)")
        }
    }
}
