//
//  Copyright © 2021 DittoLive Incorporated. All rights reserved.
//

import Foundation
import MessageUI
import UIKit

private struct LogConfig {
    static let logsDirectoryName = "debug-logs"
    static let logFileName = "logs.txt"
    static let zippedLogFileName = "logs.zip"

    /// Directory into which debug logs are to be stored. We use a dedicated
    /// directory to keep logs grouped (in the event that we begin generating
    /// more than one log - either from multiple sub-systems or due to log
    /// rotation).
    static var logsDirectory: URL! = {
        let directory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return directory.appendingPathComponent(logsDirectoryName, isDirectory: true)
    }()

    /// URL within `logsDirectory` for our latest debug logs to stream.
    static var logFileURL: URL! = {
        return Self.logsDirectory.appendingPathComponent(LogConfig.logFileName)
    }()

    /// A temporary location into which we can store zipped logs before sharing
    /// them via a share sheet.
    static var zippedLogsURL: URL! = {
        let directory = FileManager.default.temporaryDirectory
        return directory.appendingPathComponent(LogConfig.zippedLogFileName)
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

    // MARK: - Properties

    /// The log file URL which should be passed to the DittoLogger.
    public var logFileURL: URL? {
        // Lazily ensure our directory exists
        do {
            try FileManager().createDirectory(at: LogConfig.logsDirectory,
                                              withIntermediateDirectories: true)
        } catch let error {
            print("Failed to create logs directory: \(error)")
            return nil
        }

        return LogConfig.logFileURL
    }

    // MARK: - Functions

    /// Zips all contents in our log directory, placing an updated zip file at URL returned.
    public func createLogsZip() -> URL? {
        try? FileManager().removeItem(at: LogConfig.zippedLogsURL)

        let coordinator = NSFileCoordinator()
        var nsError: NSError?

        // Runs synchronously, so no need to co-ordinate multiple callers
        coordinator.coordinate(readingItemAt: LogConfig.logsDirectory,
                               options: [.forUploading], error: &nsError) { tempURL in
            do {
                try FileManager().moveItem(at: tempURL, to: LogConfig.zippedLogsURL)
            } catch let error {
                print("Failed to move zipped logs into location: \(error)")
            }
        }

        if let error = nsError {
            print("Failed to zip logs: \(error)")
            return nil
        }

        return LogConfig.zippedLogsURL
    }
}
