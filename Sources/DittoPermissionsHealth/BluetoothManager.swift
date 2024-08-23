//
//  BluetoothManager.swift
//  
//
//  Created by Brian Plattenburg on 5/1/24.
//

import Combine
import CoreBluetooth
import DittoHealthMetrics
import Foundation

public class BluetoothManager: NSObject, ObservableObject {
    private var centralManager: CBCentralManager!

    @Published var authorizationStatus: CBManagerAuthorization = CBCentralManager.authorization
    @Published var managerState: CBManagerState = .unknown

    public override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    var authorizationStatusDescription: String {
        switch authorizationStatus {
        case .notDetermined:
            return "Not Determined"
        case .restricted:
            return "Restricted"
        case .denied:
            return "Denied"
        case .allowedAlways:
            return "Allowed Always"
        @unknown default:
            return "Unknown"
        }
    }

    var managerStateDescription: String {
        switch managerState {
        case .unknown:
            return "Unknown"
        case .resetting:
            return "Resetting"
        case .unsupported:
#if targetEnvironment(simulator)
            return "Unsupported (Simulator)"
#else
            return "Unsupported"
#endif
        case .unauthorized:
            return "Unauthorized"
        case .poweredOff:
            return "Off"
        case .poweredOn:
            return "On"
        @unknown default:
            return "Unknown"
        }
    }

    var isHealthy: Bool {
#if targetEnvironment(simulator)
        authorizationStatus == .allowedAlways // The simulator always reports Unsupported but should still be considered healthy
#else
        managerState == .poweredOn && authorizationStatus == .allowedAlways
#endif
    }

    var healthDetails: [String: String] {
        ["Authorization Status": authorizationStatusDescription,
         "Current State": managerStateDescription]
    }
}

extension BluetoothManager: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        self.managerState = central.state
        self.authorizationStatus = CBCentralManager.authorization
    }
}

extension BluetoothManager: HealthMetricProvider {
    public var metricName: String {
        DittoPermissionsHealthConstants.bluetoothManagerHealthMetricName
    }
    
    public func getCurrentState() -> DittoHealthMetrics.HealthMetric {
        HealthMetric(isHealthy: isHealthy, details: healthDetails)
    }
}
