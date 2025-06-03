///
//  PeersListView.swift
//  DittoSwiftTools
//
//  Created by Eric Turner on 3/7/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import DittoSwift
import SwiftUI

public struct PeersListView: View {
    @StateObject var vm: PeersObserverVM
    private let dividerColor: Color
        
    public init(ditto: Ditto) {
        self._vm = StateObject(wrappedValue: PeersObserverVM(ditto: ditto))
        self.dividerColor = .accentColor
    }
    
    public var body: some View {
        List {
            Section {
                peerView(vm.localPeer)
            } header: {
                Text("Local (Self) Peer")
                    .font(Font.subheadline.weight(.bold))
            }

            Section {
                ForEach(vm.peers, id: \.peerKeyString) { peer in
                    peerView(peer)
                        .padding(.bottom, 4)
                }
            } header: {
                Text("Remote Peers")
                    .font(Font.subheadline.weight(.bold))
            }
        }
#if os(tvOS)
        .listStyle(.grouped)
#elseif !os(macOS)
        .listStyle(.insetGrouped)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .onDisappear { vm.cleanup() }
        .navigationTitle("Peers List")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    vm.isPaused.toggle()
                } label: {
                    Image(systemName: vm.isPaused ? "play.circle" : "pause.circle")
                }
                .font(.system(size: 24))
                .foregroundColor(.accentColor)
                .buttonStyle(.automatic)
            }
        }
    }
    
    @ViewBuilder
    func peerView(_ peer: DittoPeer) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            
            // Device name + siteID
            Text("\(peer.deviceName): ").font(Font.body.weight(.bold))
            + Text("\(peer.peerKeyString)")
            
            if vm.isLocalPeer(peer) {
                ForEach(vm.peers, id: \.self) { conPeer in
                    VStack(alignment: .leading) {
                        Divider()
                            .frame(height: 1)
                        Text("peer: \(conPeer.peerKeyString)")
                            .lineLimit(1)

                        presenceSnapshotDirectlyConnectedPeersView(conPeer)
                    }
                    .padding(12)
                }
            }
            Text(peer.peerSDKVersion).font(.subheadline)
        }
#if os(tvOS)
        .focusable(true)
#endif
    }
    
    @ViewBuilder
    func presenceSnapshotDirectlyConnectedPeersView(_ peer: DittoPeer) -> some View {
        VStack(alignment: .leading) {
            ForEach(vm.connectionsWithLocalPeer(peer)) { conx in
                Text("-\(conx.type.rawValue)")
                    .padding(.leading, 16)
            }
        }
    }
}
