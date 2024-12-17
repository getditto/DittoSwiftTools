// 
//  DittoService+PersistenceDirectory.swift
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.
//

import Foundation


extension DittoService {
    
    /// Generates the persistence directory URL for Ditto's data storage.
    ///
    /// This method calculates the appropriate directory path where Ditto will store its persistent data.
    /// The directory structure can include an app-specific subdirectory and, optionally, an isolated
    /// subdirectory for unique storage contexts.
    ///
    /// - Parameters:
    ///   - appID: An optional string representing the application identifier. If provided, it will be used
    ///     as a subdirectory within the main persistence directory. Defaults to an empty string.
    ///   - useIsolatedDirectories: A Boolean flag indicating whether to create an isolated subdirectory
    ///     for unique storage. Defaults to `false`.
    /// - Returns: A `URL` pointing to the calculated persistence directory.
    /// - Throws: `DittoServiceError.initializationFailed` if the directory cannot be located or created.
    static func persistenceDirectoryURL(appID: String? = "", useIsolatedDirectories: Bool = false) throws -> URL {
        do {
            // Determine the base directory for persistent storage
            #if os(tvOS)
                // Use caches directory for tvOS due to limited persistent storage
                let persistenceDirectory: FileManager.SearchPathDirectory = .cachesDirectory
            #else
                // Use document directory for other platforms for long-term persistence
                let persistenceDirectory: FileManager.SearchPathDirectory = .documentDirectory
            #endif

            // Get the root directory URL for the chosen persistence directory
            var rootDirectoryURL = try FileManager.default.url(
                for: persistenceDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            ).appendingPathComponent("ditto") // Append the "ditto" subdirectory

            // Add an app-specific subdirectory if appID is provided and not empty
            if let appID = appID, !appID.isEmpty {
                rootDirectoryURL = rootDirectoryURL.appendingPathComponent(appID)
            }

            // Append a unique UUID subdirectory if isolated directories are requested
            if useIsolatedDirectories {
                rootDirectoryURL = rootDirectoryURL.appendingPathComponent(UUID().uuidString)
            }

            // Return the fully constructed URL
            return rootDirectoryURL
        } catch {
            // Throw a specific error if directory creation or access fails
            throw DittoServiceError.initializationFailed("Failed to get persistence directory: \(error.localizedDescription)")
        }
    }
}
