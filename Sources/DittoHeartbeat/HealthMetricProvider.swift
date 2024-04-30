///
//  HeartbeatVM.swift
//  DittoSwiftTools
//
//  Created by Brian Plattenburg on 4/30/24.
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.

public protocol HealthMetricProvider {
    var metricName: String { get }
    func getCurrentState() -> HealthMetric
}
