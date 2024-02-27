//
//  SwiftUIView.swift
//  
//
//  Created by Walker Erekson on 2/26/24.
//

import SwiftUI

@available(iOS 13.0, *)
public struct PermissionsHealth: View {
    
    public init() {}
    
    @State private var bluetoothAlwaysUsageDescription: String?
    @State private var bluetoothPeripheralUsageDescription: String?
    @State private var localNetworkUsageDescription: String?
    @State private var bonjourServices: [String]?
    
    @ObservedObject var networkManager = NetworkManager()

    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                ZStack {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Permissions")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Image(systemName: permissionsEnabled ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .foregroundColor(permissionsEnabled ? .green : .gray)
                                .font(.title)
                        }
                        Divider()
                        Text("Bluetooth Always Usage: \(bluetoothAlwaysUsageDescription != nil ? "Enabled" : "Disabled")")
                        Text("Bluetooth Peripheral Usage: \(bluetoothPeripheralUsageDescription != nil ? "Enabled" : "Disabled")")
                        Text("Local Network Usage: \(localNetworkUsageDescription != nil ? "Enabled" : "Disabled")")
                        Text("Bonjour Services: \(bonjourServices != nil ? "Enabled" : "Disabled")")
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10) // Adjust as needed for the roundness of the corners
                    .shadow(radius: 5) // Adjust the radius for the intensity of the shadow
                }
                .padding()
                
                ZStack {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Bluetooth Status")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Spacer()
                            Image(systemName: networkManager.isBluetoothEnabled ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .foregroundColor(networkManager.isBluetoothEnabled ? .green : .gray)
                                .font(.title)
                        }
                        Divider()
                        Text("Bluetooth: \(networkManager.isBluetoothEnabled ? "Enabled" : "Disabled")")
                        if !networkManager.isBluetoothEnabled {
                            Divider()
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
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10) // Adjust as needed for the roundness of the corners
                    .shadow(radius: 5) // Adjust the radius for the intensity of the shadow
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
                                openBluetoothSettings()
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
                    .cornerRadius(10) // Adjust as needed for the roundness of the corners
                    .shadow(radius: 5) // Adjust the radius for the intensity of the shadow
                }
                .padding()
            }
        }
        .padding()
        .onAppear {
            if let infoDict = Bundle.main.infoDictionary {
                bluetoothAlwaysUsageDescription = infoDict["NSBluetoothAlwaysUsageDescription"] as? String
                bluetoothPeripheralUsageDescription = infoDict["NSBluetoothPeripheralUsageDescription"] as? String
                localNetworkUsageDescription = infoDict["NSLocalNetworkUsageDescription"] as? String
                bonjourServices = infoDict["NSBonjourServices"] as? [String]
            }
        }
    }
    
    var permissionsEnabled: Bool {
        return bluetoothAlwaysUsageDescription != nil &&
               bluetoothPeripheralUsageDescription != nil &&
               localNetworkUsageDescription != nil &&
               bonjourServices != nil
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
}
