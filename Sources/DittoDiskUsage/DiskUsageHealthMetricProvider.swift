//
//  File.swift
//  
//
//  Created by Brian Plattenburg on 5/14/24.
//

import Foundation
import DittoSwift
import DittoHealthMetrics

// TODO: Can I extend this directly? this is the snapshot not the monitoring tool?
extension DittoSwift.DiskUsage: DittoHealthMetrics.HealthMetricProvider {
    public var metricName: String {
        DittoDiskUsageConstants.diskUsageHealthMetricName
    }
    
    public func getCurrentState() -> DittoHealthMetrics.HealthMetric {
        <#code#>
    }
}
