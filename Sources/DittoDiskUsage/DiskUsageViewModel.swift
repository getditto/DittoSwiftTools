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
    let unhealthySizeInBytes: Int

    var isHealthy: Bool {
        totalSizeInBytes <= unhealthySizeInBytes
    }

    var details: [String: String] {
        var detailsMap: [String: String] = [
            DittoDiskUsageConstants.rootPath: rootPath, // TODO: is this valuable?
            DittoDiskUsageConstants.totalSize: totalSize,
            DittoDiskUsageConstants.lastUpdated: lastUpdated
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

public class DiskUsageViewModel: ObservableObject {

    @Published var diskUsage: DiskUsageState?
    var cancellable: Cancellable?

    var unhealthySizeInBytes: Int = DittoDiskUsageConstants.twoGigabytesInBytes

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
        guard let formattedSize = DiskUsageViewModel.byteCountFormatter.string(for: bytes) else { return DittoDiskUsageConstants.error }
        return formattedSize
    }

    public init(ditto: Ditto) {
        self.ditto = ditto
        cancellable = ditto.diskUsage
            .diskUsagePublisher()
            .map { diskUsage in
                let children = diskUsage.childItems
                    .map { (child: DiskUsageItem) in
                        DiskUsage(
                            relativePath: child.path,
                            sizeInBytes: child.sizeInBytes,
                            size: DiskUsageViewModel.byteCountFormatter.string(for: child.sizeInBytes) ?? DittoDiskUsageConstants.error
                        )
                    }
                    .sorted { $0.relativePath < $1.relativePath }

                return DiskUsageState(
                    rootPath: diskUsage.path,
                    totalSizeInBytes: diskUsage.sizeInBytes,
                    totalSize: DiskUsageViewModel.byteCountFormatter.string(for: diskUsage.sizeInBytes) ?? DittoDiskUsageConstants.error,
                    children: children,
                    lastUpdated: DiskUsageViewModel.dateFormatter.string(from: Date()),
                    unhealthySizeInBytes: self.unhealthySizeInBytes
                )
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.diskUsage, on: self)
    }
}

extension DiskUsageViewModel: HealthMetricProvider {
    var metricName: String {
        DittoDiskUsageConstants.healthMetricName
    }
    
    func getCurrentState() -> DittoHealthMetrics.HealthMetric {
        diskUsage?.healthMetric ?? HealthMetric(isHealthy: true, details: [DittoDiskUsageConstants.healthMetricName: DittoDiskUsageConstants.noData])
    }
}
