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
        "BLE approximate distance is inaccurate."
    }
        
    public init(ditto: Ditto) {
        self._vm = StateObject(wrappedValue: PeersObserverVM(ditto: ditto))
        self.dividerColor = .accentColor
    }
    
    public var body: some View {
        List {
            Section {
                peerView(vm.localPeer, showBLEDistance: true)
            } header: {
                Text("Local (Self) Peer")
                    .font(Font.subheadline.weight(.bold))
            } footer: {
                Text(Self.footerText)
            }
            .listRowSeparator(.visible, edges: .top)
            .listRowSeparatorTint(dividerColor)
            
            Section {
                ForEach(vm.peers, id: \.peerKey) { peer in
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
    func peerView(_ peer: DittoPeer, showBLEDistance: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            
            // Device name + siteID
            Text("\(peer.deviceName): ").font(Font.body.weight(.bold))
            + Text("\(peer.peerKeyString)")
            
            if vm.isLocalPeer(peer) {
                ForEach(vm.peers, id: \.self) { conPeer in
                    VStack(alignment: .leading) {
                        Divider()
                            .frame(height: 1)
                            .overlay(.gray).opacity(0.4)
                        
                        Text("peer: \(conPeer.peerKeyString)")
                            .lineLimit(1)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        presenceSnapshotDirectlyConnectedPeersView(conPeer, showBLEDistance: showBLEDistance)
                    }
                    .padding(.leading, 12)
                }
            }
            Text(peer.peerSDKVersion).font(.subheadline)
        }
    }
    
    @ViewBuilder
    func presenceSnapshotDirectlyConnectedPeersView(_ peer: DittoPeer, showBLEDistance: Bool = false) -> some View {
        VStack(alignment: .leading) {
            ForEach(vm.connectionsWithLocalPeer(peer)) { conx in
                HStack {
                    Text("-\(conx.type.rawValue)")
                        .padding(.leading, 16)

                    Spacer()

                    if showBLEDistance && conx.type == DittoConnectionType.bluetooth {
                        Text("\(vm.formattedDistanceString(conx.approximateDistanceInMeters))m")
                    } else {
                        Text("-")
                    }
                }
            }
        }
    }
}
