//
//  SwiftUIView.swift
//  
//
//  Created by Walker Erekson on 2/13/24.
//

import SwiftUI
import DittoSwift

@available(iOS 15.0, *)
public struct PresenceDegradationView: View {
    
    @StateObject var vm: PresenceDegradationVM
    var callback: ((Int, [String: Peer]?, Settings?) -> Void)?

    public init(ditto: Ditto, callback: ((Int, [String: Peer]?, Settings?) -> Void)?) {
        self._vm = StateObject(wrappedValue: PresenceDegradationVM(ditto: ditto))
        self.callback = callback
    }

    public var body: some View {
        VStack(alignment: .leading) {
            bannerColor
                .frame(height: 25, alignment: .top)
                .overlay(
                    Text(vm.remotePeers?.filter { $0.value.connected } == nil ? "" : ((vm.remotePeers?.filter { $0.value.connected }.count) ?? 0 < vm.expectedPeers) ? "Unhealthy Mesh" : "Healthy Mesh")
                )
            Text("Expected Minimum Peers: \(vm.expectedPeers )")
            Text("Report API: \(vm.apiEnabled ? "Enabled" : "Disabled")")
            Text("Session started at: \(vm.sessionStartTime ?? "")")

            Button {
                vm.isSheetPresented = true
            } label: {
                Text("New Session")
                    .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(Color.blue, lineWidth: 2)
                    )
            }
            Divider()
            
            Text("Local Device")
            VStack(alignment: .leading) {
                Text("device name: \(vm.localPeer?.name ?? "")")
                Text("\(vm.localPeer?.key  ?? "")")
                Text("last Seen \(vm.localPeer?.lastSeenFormatted ?? "")")
                Divider()
                HStack {
                    connectionText(connectionType: "BT", connectionCount: vm.localPeer?.transportInfo.bluetoothConnections)
                    connectionText(connectionType: "LAN", connectionCount: vm.localPeer?.transportInfo.lanConnections)
                    connectionText(connectionType: "P2P", connectionCount: vm.localPeer?.transportInfo.p2pConnections)
                    connectionText(connectionType: "Cloud", connectionCount: vm.localPeer?.transportInfo.cloudConnections)
                }
            }
            .padding()
            .background(Color(UIColor.systemGreen))
            .cornerRadius(10)
            Divider()
            
            Text("Remote Devices (\(vm.remotePeers?.filter { $0.value.connected }.count ?? 0)/\(vm.remotePeers?.count ?? 0))")
            ScrollView {
                if let values = vm.remotePeers?.values {
                    ForEach(Array(values)) { peer in
                        VStack(alignment: .leading) {
                            Text("device name \(peer.name)")
                            Text("pk: \(peer.key)")
                            Text("last Seen \(peer.lastSeenFormatted)")
                            Divider()
                            HStack {
                                connectionText(connectionType: "BT", connectionCount: peer.transportInfo.bluetoothConnections)
                                connectionText(connectionType: "LAN", connectionCount: peer.transportInfo.lanConnections)
                                connectionText(connectionType: "P2P", connectionCount: peer.transportInfo.p2pConnections)
                                connectionText(connectionType: "Cloud", connectionCount: peer.transportInfo.cloudConnections)
                            }
                        }
                        .padding()
                        .background(peer.connected ? Color.green : Color.red)
                        .cornerRadius(10)
                    }
                }
            }
        }
        .padding([.leading, .trailing])
//        .background(vm.remotePeers?.filter { $0.value.connected } == nil ? Color.white : ((vm.remotePeers?.filter { $0.value.connected }.count) ?? 0 < vm.expectedPeers) ? Color.red : Color.green)
        .fullScreenCover(isPresented: $vm.isSheetPresented, content: {
            NewSessionView(expectedPeers: $vm.expectedPeers, apiEnabled: $vm.apiEnabled, isPresented: $vm.isSheetPresented, sessionStartTime: $vm.sessionStartTime) {
                
                vm.startNewSession()

            }
        })
        .onReceive(vm.$expectedPeers.combineLatest(vm.$remotePeers, vm.$settings, vm.$apiEnabled)) { expectedPeers, remotePeers, settings, apiEnabled in
            // Call the update callback when any of the published properties change
            if apiEnabled {
                if let callback = self.callback {
                    callback(expectedPeers, remotePeers, settings)
                }
            }
        }
    }
    
    func connectionText(connectionType: String?, connectionCount: Int?) -> Text {
        if let count = connectionCount {
            return Text("\(connectionType ?? "--"): \(count)")
        } else {
            return Text("\(connectionType ?? "--"): --")
        }
    }
    
    var bannerColor: some View {
        Rectangle()
            .foregroundColor(vm.remotePeers?.filter { $0.value.connected } == nil ? Color.white : ((vm.remotePeers?.filter { $0.value.connected }.count) ?? 0 < vm.expectedPeers) ? Color.red : Color.green)
    }
}

