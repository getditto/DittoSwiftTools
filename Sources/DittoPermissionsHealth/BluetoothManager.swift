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

@available(iOS 13.0, *)
public class BluetoothManager: NSObject, ObservableObject {
    private var centralManager: CBCentralManager!
    private var cancellables = Set<AnyCancellable>()

    @Published var authorizationStatus: CBManagerAuthorization = .notDetermined
    @Published var managerState: CBManagerState = .unknown

    public override init() {
        super.init()

        centralManager = CBCentralManager(delegate: self, queue: nil)

        // Watch for changes in authorization status
        centralManager.publisher(for: \.authorization)
            .sink { [weak self] authorization in
                self?.authorizationStatus = authorization
            }
            .store(in: &cancellables)

        // Watch for changes in manager state
        centralManager.publisher(for: \.state)
            .sink { [weak self] state in
                self?.managerState = state
            }
            .store(in: &cancellables)
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
            return "Unsupported"
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
        managerState == .poweredOn && authorizationStatus == .allowedAlways
    }

    var healthDetails: [String: String] {
        ["Authorization Status": authorizationStatusDescription,
         "Current State": managerStateDescription]
    }
}

@available(iOS 13.0, *)
extension BluetoothManager: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        // This delegate method is called when there's a change in the manager's state.
        // We don't need to do anything here since we're observing the state using Combine.
    }
}

@available(iOS 13.0, *)
extension BluetoothManager: HealthMetricProvider {
    public var metricName: String {
        DittoPermissionsHealthConstants.bluetoothManagerHealthMetricName
    }
    
    public func getCurrentState() -> DittoHealthMetrics.HealthMetric {
        HealthMetric(isHealthy: isHealthy, details: healthDetails)
    }
}
