//
//  LogUploader.swift
//  DittoSwiftTools
//
//  Copyright © 2025 DittoLive Incorporated. All rights reserved.
//

import Foundation
import DittoSwift

/// Public utilities for uploading logs to Ditto Portal
public enum LogUploader {

    /// ISO-8601 date formatter with timezone offset for log upload timestamps.
    /// Format: yyyy-MM-dd'T'HH:mm:ss±HH:mm (e.g., "2025-11-03T15:32:35-07:00")
    /// Reused across calls for performance optimization.
    private static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withColonSeparatorInTimeZone]
        return formatter
    }()

    /// Triggers a request for the local device to export its logs to the Ditto Portal.
    ///
    /// This function updates the small peer info document in the local store, which is observed
    /// by the Ditto log collector service. The logs will be uploaded to the Portal associated
    /// with the app ID configured in the Ditto instance.
    ///
    /// This is an async function and should be called from a Task or async context. It performs a
    /// database write operation.
    ///
    /// - Parameter ditto: The active Ditto instance.
    /// - Throws: `DittoError` if the database write operation fails.
    ///
    /// # Example
    /// ```swift
    /// do {
    ///     try await LogUploader.uploadLogsToPortal(ditto: ditto)
    ///     print("Log upload request sent successfully")
    /// } catch {
    ///     print("Failed to request log upload: \(error)")
    /// }
    /// ```
    public static func uploadLogsToPortal(ditto: Ditto) async throws {
        let peerKey = ditto.presence.graph.localPeer.peerKeyString
        let currentTime = iso8601Formatter.string(from: Date())

        let query = """
            UPDATE __small_peer_info
            SET log_requests.device_logs.requested_at = :currentTime
            WHERE _id = :peerKey
            """

        try await ditto.store.execute(
            query: query,
            arguments: [
                "currentTime": currentTime,
                "peerKey": peerKey
            ]
        )
    }
}
