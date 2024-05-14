//
//  PermissionsHealth.swift
//
//
//  Created by Walker Erekson on 2/26/24.
//

import SwiftUI
import Combine

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
                            Image(systemName: checkBluetoothState(state: bluetoothManager.authorizationStatusDescription) ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .foregroundColor(checkBluetoothState(state: bluetoothManager.authorizationStatusDescription) ? .green : .gray)
                                .font(.title)
                        }
                        Divider()
                        Text("Permission: \(bluetoothManager.authorizationStatusDescription)")
                        if !checkBluetoothState(state: bluetoothManager.authorizationStatusDescription) {
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
                            Image(systemName: checkBluetoothState(state: bluetoothManager.managerStateDescription) ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .foregroundColor(checkBluetoothState(state: bluetoothManager.managerStateDescription) ? .green : .gray)
                                .font(.title)
                        }
                        Divider()
                        Text("Bluetooth: \(bluetoothManager.managerStateDescription)")
                        if !checkBluetoothState(state: bluetoothManager.managerStateDescription) {
                            Divider()
                            if(bluetoothManager.managerStateDescription == "Unauthorized") {
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


