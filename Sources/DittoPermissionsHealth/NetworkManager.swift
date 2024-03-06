//
//  File.swift
//  
//
//  Created by Walker Erekson on 2/26/24.
//

import CoreBluetooth
import Network

@available(iOS 13.0, *)
class NetworkManager: NSObject, ObservableObject, CBCentralManagerDelegate {
    @Published var isBluetoothEnabled = false
    @Published var isWifiEnabled = false
    
    private var centralManager: CBCentralManager!
    private var pathMonitor: NWPathMonitor!
    
    override init() {
        super.init()
        
        // Initialize CBCentralManager with self as delegate
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
        // Check Wi-Fi status
        pathMonitor = NWPathMonitor()
        pathMonitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                self.isWifiEnabled = path.usesInterfaceType(.wifi)
            }
        }
        let queue = DispatchQueue(label: "NetworkMonitor")
        pathMonitor.start(queue: queue)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        // Update isBluetoothEnabled when Bluetooth state changes
        isBluetoothEnabled = central.state == .poweredOn
    }
}
