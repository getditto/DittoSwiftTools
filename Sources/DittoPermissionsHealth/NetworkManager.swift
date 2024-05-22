//
//  NetworkManager.swift
//  
//
//  Created by Walker Erekson on 2/26/24.
//

import Combine
import DittoHealthMetrics
import Network

public class NetworkManager: NSObject, ObservableObject {
    @Published var isWifiEnabled = false

    private var pathMonitor: NWPathMonitor!
    
    public override init() {
        super.init()
        
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
}

extension NetworkManager: HealthMetricProvider {
    public var metricName: String {
        DittoPermissionsHealthConstants.networkManagerHealthMetricName
    }
    
    public func getCurrentState() -> DittoHealthMetrics.HealthMetric {
        HealthMetric(isHealthy: isWifiEnabled, details: [:]) // A future release may add more details here
    }
}
