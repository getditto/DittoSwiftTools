//
//  Copyright © 2021 DittoLive Incorporated. All rights reserved.
//
import DittoSwift

private struct Config {
    static let logsDirectoryName = "debug-logs"
    static let logFileName = "logs.txt"
    static let zippedLogFileName = "ditto.jsonl.gz"

    /// Directory into which debug logs are to be stored. We use a dedicated
    /// directory to keep logs grouped (in the event that we begin generating
    /// more than one log - either from multiple sub-systems or due to log
    /// rotation).
    static var logsDirectory: URL! = {
        let directory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return directory.appendingPathComponent(logsDirectoryName, isDirectory: true)
    }()

    /// A temporary location into which we can store zipped logs before sharing
    /// them via a share sheet.
    static var zippedLogsURL: URL! = {
        let directory = FileManager.default.temporaryDirectory
        return directory.appendingPathComponent(Config.zippedLogFileName)
    }()
}

/// LogManager acts as a thin interface over our stored log files and
/// offers functionality to share zipped logs with an iOS share sheet.
struct LogManager {

    // MARK: - Singleton

    public static let shared = LogManager()

    // MARK: - Initialization

    private init() {
        // Private singleton constructor
    }

    // MARK: - Functions

    /// Zips all contents in our log directory, placing an updated zip file at URL returned.
    public func exportLogs() async throws -> URL {
        try? FileManager().removeItem(at: Config.zippedLogsURL)
        try await DittoLogger.export(to: Config.zippedLogsURL)
        return Config.zippedLogsURL
    }
}
