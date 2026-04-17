import OSLog

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.adamsardo.Couch"

    static let couch = Logger(subsystem: subsystem, category: "couch")
    static let session = Logger(subsystem: subsystem, category: "session")
    static let debrief = Logger(subsystem: subsystem, category: "debrief")
    static let llm = Logger(subsystem: subsystem, category: "llm")
}
