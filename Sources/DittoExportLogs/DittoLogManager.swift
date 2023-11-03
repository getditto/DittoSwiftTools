//
//  DittoLogManager.swift
//  
//
//  Created by Walker Erekson on 1/13/23.
//

import Foundation

private struct Config {
    static let logsDirectoryName = "debug-logs"
    static let logFileName = "logs.txt"
    static let zippedLogFileName = "DittoLogs.zip"

    static var logsDirectory: URL! = {
        let directory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return directory.appendingPathComponent(logsDirectoryName, isDirectory: true)
    }()

    static var logFileURL: URL! = {
        return Self.logsDirectory.appendingPathComponent(Config.logFileName)
    }()

    static var zippedLogsURL: URL! = {
        let directory = FileManager.default.temporaryDirectory
        return directory.appendingPathComponent(Config.zippedLogFileName)
    }()
}

public struct DittoLogManager {
    public static let shared = DittoLogManager()

    private init() {}

    public var logFileURL: URL? {
        do {
            try FileManager().createDirectory(at: Config.logsDirectory,
                                              withIntermediateDirectories: true)
        } catch let error {
            assertionFailure("Failed to create logs directory: \(error)")
            return nil
        }

        return Config.logFileURL
    }

    public func createLogsZip() -> URL? {
        try? FileManager().removeItem(at: Config.zippedLogsURL)

        let coordinator = NSFileCoordinator()
        var nsError: NSError?

        // Runs synchronously, so no need to co-ordinate multiple callers
        coordinator.coordinate(readingItemAt: Config.logsDirectory,
                               options: [.forUploading], error: &nsError) { tempURL in
            do {
                try FileManager().moveItem(at: tempURL, to: Config.zippedLogsURL)
            } catch let error {
                assertionFailure("Failed to move zipped logs into location: \(error)")
            }
        }

        if let error = nsError {
            assertionFailure("Failed to zip logs: \(error)")
            return nil
        }

        return Config.zippedLogsURL
    }
}
