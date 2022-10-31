//
//  NetworkPage.swift
//  Pluto
//
//  Created by Maximilian Alexander on 9/16/21.
//
import SwiftUI
import Combine
import DittoSwift

struct NetworkPage: View {

    class ViewModel: ObservableObject {
        @Published var dittoRemotePeers = [DittoRemotePeer]()

        var observer: DittoObserver?

        init() {
            observer = DittoManager.shared
                .ditto?.observePeers(callback: { [weak self] peers in
                    self?.dittoRemotePeers = peers

                })
        }
    }

    @ObservedObject var viewModel = ViewModel()

    var body: some View {
        List {
            Section(header: HStack {
                Text("Remote Peers")
                Spacer()
                Text("Count: \(viewModel.dittoRemotePeers.count)")
            }) {
                ForEach(viewModel.dittoRemotePeers) { peer in
                    VStack(alignment: .leading, spacing: /*@START_MENU_TOKEN@*/nil/*@END_MENU_TOKEN@*/, content: {
                        Text(peer.deviceName)
                            .font(.title)
                        Text("Connections: \(peer.connections.joined(separator: ", "))")
                        let approximateDistanceInMeters: String = peer.approximateDistanceInMeters == nil ? "Unknown": String(peer.approximateDistanceInMeters!)
                        Text("Approximate Distance (Meters) \(approximateDistanceInMeters)")
                            .font(.subheadline)
                    })
                }
            }
        }
        .navigationTitle("Network Info")
    }
}

struct NetworkPage_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            NetworkPage()
        }
    }
}
