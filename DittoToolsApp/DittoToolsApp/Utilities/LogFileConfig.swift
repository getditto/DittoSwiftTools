//
//  LogFileConfig.swift
//
//
//  Created by Erik Everson on 2/2/24.
//

import Foundation

struct LogFileConfig {
    static let logsDirectoryName = "debug-logs"
    static let logFileName = "logs.txt"
    static let zippedLogFileName = "logs.zip"
    static var logsDirectory: URL! = {
        let directory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return directory.appendingPathComponent(logsDirectoryName, isDirectory: true)
    }()
    static var logFileURL: URL! = {
        return Self.logsDirectory.appendingPathComponent(logFileName)
    }()
    static var zippedLogsURL: URL! = {
        let directory = FileManager.default.temporaryDirectory
        return directory.appendingPathComponent(zippedLogFileName)
    }()

    public static func createLogFileURL() -> URL? {
        do {
            try FileManager().createDirectory(at: self.logsDirectory,
                                              withIntermediateDirectories: true)
        } catch let error {
            assertionFailure("Failed to create logs directory: \(error)")
            return nil
        }
        return self.logFileURL
    }
}
