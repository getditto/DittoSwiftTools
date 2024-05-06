///
//  HealthMetric.swift
//  DittoSwiftTools
//
//  Created by Brian Plattenburg on 5/1/24.
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.

import Foundation

public struct HealthMetric {
    public let isHealthy: Bool
    public let details: [String: String]

    public init(isHealthy: Bool, details: [String: String]) {
        self.isHealthy = isHealthy
        self.details = details
    }
}
