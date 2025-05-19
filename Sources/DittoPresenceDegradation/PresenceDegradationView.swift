//
//  SwiftUIView.swift
//  
//
//  Created by Walker Erekson on 2/13/24.
//

import SwiftUI
import DittoSwift

public struct PresenceDegradationView: View {
    @StateObject var vm: PresenceDegradationVM
    var callback: ((Int, [String: Peer]?, Settings?) -> Void)?

    public init(ditto: Ditto, callback: ((Int, [String: Peer]?, Settings?) -> Void)?) {
        self._vm = StateObject(wrappedValue: PresenceDegradationVM(ditto: ditto))
        self.callback = callback
    }

    public var body: some View {
        Group {
            if vm.isNewSessionView {
                NewSessionView(
                    expectedPeers: $vm.expectedPeers,
                    apiEnabled: $vm.apiEnabled,
                    isPresented: $vm.isNewSessionView,
                    sessionStartTime: $vm.sessionStartTime
                ) {
                    vm.startNewSession()
                }
            } else {
                Content(vm: vm)
            }
        }
        .onReceive(vm.$expectedPeers.combineLatest(vm.$remotePeers, vm.$settings, vm.$apiEnabled)) { expectedPeers, remotePeers, settings, apiEnabled in
            if apiEnabled {
                callback?(Int(expectedPeers) ?? 0, remotePeers, settings)
            }
        }
    }

    struct Content: View {
        @ObservedObject var vm: PresenceDegradationVM

        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    StatusBanner(isHealthy: isHealthyMesh)

                    Group {
                        Text("Session Info")
                            .font(.headline)
                        Label("Expected Minimum Peers: \(Int(vm.expectedPeers) ?? 0)", systemImage: "person.3.fill")
                        Label("Report API: \(vm.apiEnabled ? "Enabled" : "Disabled")", systemImage: "externaldrive.badge.checkmark")
                        Label("Session Started: \(vm.sessionStartTime ?? "--")", systemImage: "clock")
                    }

                    Divider()

                    Text("Local Device")
                        .font(.title3.bold())
                    if let localPeer = vm.localPeer {
                        DeviceCard(peer: localPeer, isLocal: true)
                    }

                    Divider()

                    Text("Remote Devices (\(connectedPeerCount)/\(vm.remotePeers?.count ?? 0))")
                        .font(.title3.bold())

                    ForEach(vm.remotePeers?.values.sorted(by: { $0.name < $1.name }) ?? []) { peer in
                        DeviceCard(peer: peer, isLocal: false)
                    }
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    #if os(macOS)
                    Button(action: { vm.isNewSessionView = true }) {
                        Text("New Session")
                            .bold()
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .foregroundColor(Color.primary)
                    }
                    .background(Color.blue.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    #else
                    Button(action: { vm.isNewSessionView = true }) {
                        Text("New Session")
                    }
                    #endif
                }
            }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }

        var isHealthyMesh: Bool {
            (vm.remotePeers?.filter { $0.value.connected }.count ?? 0) >= (Int(vm.expectedPeers) ?? 0)
        }

        var connectedPeerCount: Int {
            vm.remotePeers?.filter { $0.value.connected }.count ?? 0
        }
    }

    struct StatusBanner: View {
        let isHealthy: Bool

        var body: some View {
            HStack {
                Image(systemName: isHealthy ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                Text(isHealthy ? "Healthy Mesh" : "Unhealthy Mesh")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(isHealthy ? Color.green : Color.red)
            .cornerRadius(12)
        }
    }

    struct DeviceCard: View {
        let peer: Peer
        var isLocal: Bool

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(peer.name)
                        .font(.headline)
                    if peer.connected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                    }
                    Spacer()
                }

                if isLocal {
                    Label("Local Device", systemImage: "iphone")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text(peer.key)
                    .font(.caption)
                    .foregroundColor(.gray)
                Text("Last seen: \(peer.lastSeenFormatted)")
                    .font(.caption2)
                    .foregroundColor(.gray)

                ConnectionRow(peer: peer)
            }
            .padding()
            #if os(iOS)
            .background(Color(UIColor.systemGray6))
            #elseif os(macOS)
            .background(Color(NSColor.windowBackgroundColor)) // or NSColor.controlBackgroundColor
            #else
            .background(Color.gray.opacity(0.15))
            .focusable(true)
            #endif
            .cornerRadius(12)
            .shadow(radius: 1)
            .frame(maxWidth: .infinity)
        }
    }

    struct ConnectionRow: View {
        let peer: Peer

        var body: some View {
            HStack(spacing: 12) {
                connectionInfo(label: "BT", value: peer.transportInfo.bluetoothConnections)
                connectionInfo(label: "LAN", value: peer.transportInfo.lanConnections)
                connectionInfo(label: "P2P", value: peer.transportInfo.p2pConnections)
                connectionInfo(label: "Cloud", value: peer.transportInfo.cloudConnections)
            }
            .font(.caption)
        }

        func connectionInfo(label: String, value: Int?) -> some View {
            VStack {
                Text(label)
                    .fontWeight(.semibold)
                Text("\(value ?? 0)")
                    .foregroundColor(.primary)
            }
            .frame(minWidth: 40)
        }
    }
}
