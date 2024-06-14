//
//  DiskUsageViewModel.swift
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

    /// For health metric reporting, we only consider the size of `ditto_replication` and `ditto_store`
    var healthCheckSize: Int {
        var total: Int = 0
        if let dittoStore = children.first(where: { self.shortRelativePath(child: $0) == DittoDiskUsageConstants.dittoStorePath }) {
            total += dittoStore.sizeInBytes
        }
        if let dittoReplication = children.first(where: { self.shortRelativePath(child: $0) == DittoDiskUsageConstants.dittoReplicationPath }) {
            total += dittoReplication.sizeInBytes
        }
        return total
    }

    var isHealthy: Bool {
        healthCheckSize <= unhealthySizeInBytes
    }

    var details: [String: String] {
        var detailsMap: [String: String] = [
            DittoDiskUsageConstants.rootPath: rootPath,
            DittoDiskUsageConstants.totalSize: totalSize,
            DittoDiskUsageConstants.lastUpdated: lastUpdated
        ]
        for child in children {
            detailsMap[shortRelativePath(child: child)] = child.size
        }
        return detailsMap
    }

    var healthMetric: HealthMetric {
        HealthMetric(isHealthy: isHealthy, details: details)
    }

    private func shortRelativePath(child: DiskUsage) -> String {
        let prefixCount = rootPath.count + 1 // drop the root path and the "/"
        return String(child.relativePath.dropFirst(prefixCount))
    }
}

public class DiskUsageViewModel: ObservableObject {

    @Published var diskUsage: DiskUsageState?
    var cancellable: Cancellable?

    /// The size over which disk usage is considered unhealthy when used as a `HealthMetric` with the heartbeat tool (this only considers `ditto_store` and `ditto_replication`). Defaults to 500MB
    public var unhealthySizeInBytes: Int = DittoDiskUsageConstants.fiveHundredMegabytesInBytes

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
    public var metricName: String {
        DittoDiskUsageConstants.healthMetricName
    }
    
    public func getCurrentState() -> DittoHealthMetrics.HealthMetric {
        diskUsage?.healthMetric ?? HealthMetric(isHealthy: true, details: [DittoDiskUsageConstants.healthMetricName: DittoDiskUsageConstants.noData])
    }
}
