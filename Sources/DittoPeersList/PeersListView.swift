///
//  PeersListView.swift
//  DittoSwiftTools
//
//  Created by Eric Turner on 3/7/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import DittoSwift
import SwiftUI

@available(iOS 15, *)
public struct PeersListView: View {
    @StateObject var vm: PeersObserverVM
    private let dividerColor: Color
    
    static var footerText: String {
        "BLE approximate distance inaccurate."
    }
        
    public init(ditto: Ditto) {
        self._vm = StateObject(wrappedValue: PeersObserverVM(ditto: ditto))
        self.dividerColor = .accentColor
    }
    
    public var body: some View {
        List {
            Section {
                if let localPeer = vm.localPeer {
                    peerView(localPeer)
                }
            } header: {
                Text("Local (Self) Peer")
                    .font(Font.subheadline.weight(.bold))
            } footer: {
                Text(Self.footerText)
            }
            .listRowSeparator(.visible, edges: .top)
            .listRowSeparatorTint(dividerColor)
            
            Section {
                ForEach(vm.peers, id: \.address) { peer in
                    peerView(peer)
                        .padding(.bottom, 4)
                        .listRowSeparator(.visible, edges: .top)
                        .listRowSeparatorTint(dividerColor)
                }
            } header: {
                Text("Remote Peers")
                    .font(Font.subheadline.weight(.bold))
            } footer: {
                Text(Self.footerText)
            }
        }
        .onDisappear { vm.cleanup() }
        .navigationTitle("Peers List")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    vm.isPaused.toggle()
                } label: {
                    Image(systemName: vm.isPaused ? "play.circle" : "pause.circle")
                        .symbolRenderingMode(.multicolor)
                }
                .font(.system(size: 24))
                .foregroundColor(.accentColor)
                .buttonStyle(.borderless)
            }
        }
    }
    
    @ViewBuilder
    func peerView(_ peer: DittoPeer) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            
            // Device name + siteID
            Text("\(peer.deviceName): ").font(Font.body.weight(.bold))
            + Text("\(vm.siteId(for: peer.address))").font(Font.subheadline.weight(.bold))

            // connection types subview
            ForEach(vm.remotePeerAddresses(for: peer, in: peer.connections), id: \.self) { addr in
                VStack(alignment: .leading) {
                    Divider()
                        .frame(height: 1)
                        .overlay(.gray).opacity(0.4)

                    Text("peer: \(vm.siteId(for: addr))")
                    connectionsView(for: addr, in: peer.connections)
                }
                .padding(.leading, 16)
            }
        }
    }
    
    @ViewBuilder
    func connectionsView(for addr: DittoAddress, in conxs: [DittoConnection]) -> some View {
        VStack(alignment: .leading) {
            ForEach(vm.connectionTypes(for: addr, in: conxs), id: \.self) { conx in
                HStack {
                    Text("-\(conx.type.rawValue)")
                        .padding(.leading, 16)

                    Spacer()

                    if conx.type == DittoConnectionType.bluetooth {
                        Text("\(vm.formattedDistanceString(conx.approximateDistanceInMeters))m")
                    } else {
                        Text("-")
                    }
                }
            }
        }
    }
}
