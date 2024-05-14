//
//  File.swift
//  
//
//  Created by Brian Plattenburg on 5/14/24.
//

import Foundation
import Combine
import DittoSwift
import DittoHealthMetrics

struct DiskUsage: Hashable {
    let relativePath: String
    let sizeInBytes: Int
    let size: String
}

struct DiskUsageState {
    let rootPath: String
    let totalSizeInBytes: Int
    let totalSize: String
    let children: [DiskUsage]
    let lastUpdated: String
    let error: String?

    var isHealthy: Bool {
        totalSizeInBytes <= DittoDiskUsageConstants.twoGigabytesInBytes
    }

    var details: [String: String] {
        // TODO: strings to constants
        var detailsMap: [String: String] = [
            "Root Path": rootPath, // TODO: is this valuable?
            "Total Size": totalSize,
            "Last Updated": lastUpdated
        ]
        for child in children {
            detailsMap[child.relativePath] = child.size
        }
        return detailsMap
    }

    var healthMetric: HealthMetric {
        HealthMetric(isHealthy: isHealthy, details: details)
    }
}

class DiskUsageViewModel: ObservableObject {

    @Published var diskUsage: DiskUsageState?
    var cancellable: Cancellable?

    /// Convenience property for Ditto instance.
    private var ditto: Ditto

    /// Formats file sizes like:
    /// - 248 bytes
    /// - 58 KB
    /// - 4.2 MB
    private static let byteCountFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter
    }()

    /// Formats times like: 12:38:45 PM
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter
    }()

    /// Uses `byteCountFormatter` to create a human-readable string.
    private func formatBytes(bytes: Int) -> String {
        guard let formattedSize = DiskUsageViewModel.byteCountFormatter.string(for: bytes) else { return "error" }
        return formattedSize
    }

    init(ditto: Ditto) {
        self.ditto = ditto
        cancellable = ditto.diskUsage
            .diskUsagePublisher()
            .map { diskUsage in
                let children = diskUsage.childItems
                    .map { (child: DiskUsageItem) in
                        DiskUsage(
                            relativePath: child.path,
                            sizeInBytes: child.sizeInBytes,
                            size: DiskUsageViewModel.byteCountFormatter.string(for: child.sizeInBytes) ?? "error"
                        )
                    }
                    .sorted { $0.relativePath < $1.relativePath }

                return DiskUsageState(
                    rootPath: diskUsage.path,
                    totalSizeInBytes: diskUsage.sizeInBytes,
                    totalSize: DiskUsageViewModel.byteCountFormatter.string(for: diskUsage.sizeInBytes) ?? "error",
                    children: children,
                    lastUpdated: DiskUsageViewModel.dateFormatter.string(from: Date()),
                    error: nil
                )
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.diskUsage, on: self)
    }
}

extension DiskUsageViewModel: HealthMetricProvider {
    var metricName: String {
        DittoDiskUsageConstants.diskUsageHealthMetricName
    }
    
    func getCurrentState() -> DittoHealthMetrics.HealthMetric {
        <#code#>
    }
}
