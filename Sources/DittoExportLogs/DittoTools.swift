//
//  DittoTools.swift
//  DittoSwiftTools
//
//  Copyright © 2025 DittoLive Incorporated. All rights reserved.
//

import Foundation
import DittoSwift

/// Public utilities for Ditto diagnostic tools
public enum DittoTools {

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
    ///     try await DittoTools.uploadLogsToPortal(ditto: ditto)
    ///     print("Log upload request sent successfully")
    /// } catch {
    ///     print("Failed to request log upload: \(error)")
    /// }
    /// ```
    public static func uploadLogsToPortal(ditto: Ditto) async throws {
        let peerKey = ditto.presence.graph.localPeer.peerKeyString

        // Format current time as ISO-8601 with timezone offset (matching Kotlin format)
        // Format: yyyy-MM-dd'T'HH:mm:ss±HH:mm (e.g., "2025-11-03T15:32:35-07:00")
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withColonSeparatorInTimeZone]
        let currentTime = formatter.string(from: Date())

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
