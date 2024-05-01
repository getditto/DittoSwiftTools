///
//  HeartbeatVM.swift
//  DittoSwiftTools
//
//  Created by Brian Plattenburg on 4/30/24.
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.

/// A system to provide custom `HealthMetric`s via the HeartbeatTool for remote monitoring
public protocol HealthMetricProvider {

    /// The unique name of this health metric. Used as the key when storing this into the list of health metrics.
    var metricName: String { get }

    /// Used to return the current state of this metric.The Heartbeat tool will call this on its configured interval
    /// to get a snapshot of the current state of this health metric.
    func getCurrentState() -> HealthMetric
}
