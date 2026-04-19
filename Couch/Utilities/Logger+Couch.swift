import OSLog

extension Logger {
    nonisolated private static let subsystem = Bundle.main.bundleIdentifier ?? "com.adamsardo.Couch"

    nonisolated static let couch = Logger(subsystem: subsystem, category: "couch")
    nonisolated static let session = Logger(subsystem: subsystem, category: "session")
    nonisolated static let debrief = Logger(subsystem: subsystem, category: "debrief")
    nonisolated static let llm = Logger(subsystem: subsystem, category: "llm")
}
