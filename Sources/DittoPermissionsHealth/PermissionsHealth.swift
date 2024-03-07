//
//  SwiftUIView.swift
//
//
//  Created by Walker Erekson on 2/26/24.
//

import SwiftUI
import CoreBluetooth
import Combine

@available(iOS 13.0, *)
class BluetoothManager: NSObject, ObservableObject {
    private var centralManager: CBCentralManager!
    private var cancellables = Set<AnyCancellable>()

    @Published var authorizationStatus: CBManagerAuthorization = .notDetermined
    @Published var managerState: CBManagerState = .unknown

    override init() {
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
}

@available(iOS 13.0, *)
extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        // This delegate method is called when there's a change in the manager's state.
        // We don't need to do anything here since we're observing the state using Combine.
    }
}



@available(iOS 14.0, *)
public struct PermissionsHealth: View {
    @ObservedObject var bluetoothManager = BluetoothManager()
    @ObservedObject var networkManager = NetworkManager()
    
    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                
                ZStack {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Bluetooth Permission")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Spacer()
                            Image(systemName: checkBluetoothState(state: authorizationStatusDescription) ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .foregroundColor(checkBluetoothState(state: authorizationStatusDescription) ? .green : .gray)
                                .font(.title)
                        }
                        Divider()
                        Text("Permission: \(authorizationStatusDescription)")
                        if !checkBluetoothState(state: authorizationStatusDescription) {
                            Divider()
                            Button(action: {
                                openBluetoothSettings()
                            }) {
                                Text("Authorize Bluetooth")
                                    .foregroundColor(.white)
                                    .padding(7)
                                    .background(Color.blue)
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 5) 
                }
                .padding()
                ZStack {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Bluetooth Status")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Spacer()
                            Image(systemName: checkBluetoothState(state: managerStateDescription) ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .foregroundColor(checkBluetoothState(state: managerStateDescription) ? .green : .gray)
                                .font(.title)
                        }
                        Divider()
                        Text("Bluetooth: \(managerStateDescription)")
                        if !checkBluetoothState(state: managerStateDescription) {
                            Divider()
                            if(managerStateDescription == "Unauthorized") {
                                Text("*See Bluetooth Authorization")
                            } else {
                                Button(action: {
                                    openBluetoothSettings()
                                }) {
                                    Text("Enable Bluetooth")
                                        .foregroundColor(.white)
                                        .padding(7)
                                        .background(Color.blue)
                                        .cornerRadius(10)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                }
                .padding()
                ZStack {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Wi-fi Status")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Spacer()
                            Image(systemName: networkManager.isWifiEnabled ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .foregroundColor(networkManager.isWifiEnabled ? .green : .gray)
                                .font(.title)
                        }
                        Divider()
                        Text("Wi-Fi: \(networkManager.isWifiEnabled ? "Enabled" : "Disabled")")
                        if !networkManager.isWifiEnabled {
                            Divider()
                            Button(action: {
                                openWifiSettings()
                            }) {
                                Text("Enable Wi-fi")
                                    .foregroundColor(.white)
                                    .padding(7)
                                    .background(Color.blue)
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                }
                .padding()
            }
        }
    }

    private var authorizationStatusDescription: String {
        switch bluetoothManager.authorizationStatus {
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

    private var managerStateDescription: String {
        switch bluetoothManager.managerState {
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
    
    func openBluetoothSettings() {
        if let url = URL(string: "App-Prefs:root=Bluetooth") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    func openWifiSettings() {
        if let url = URL(string: "App-Prefs:root=WIFI") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    func checkBluetoothState(state: String) -> Bool {
        switch state {
        case "Allowed Always":
            return true
        case "On":
            return true
        default:
            return false
        }
    }
}


