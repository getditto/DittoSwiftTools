//
//  DataBrowserViewModel.swift
//  DataBrowser
//
//  Created by Walker Erekson on 11/3/22.
//

import SwiftUI
import DittoSwift

class DataBrowserViewModel: ObservableObject {

    @Published var collectionNames: [String] = []
    var subscription: DittoSyncSubscription?
    var collectionsObserver: DittoStoreObserver?
    var ditto: Ditto

    init(ditto: Ditto) {
        self.ditto = ditto
        observeCollections()
    }

    func observeCollections() {
        collectionsObserver = try? self.ditto.store.registerObserver(
            query: "SELECT * FROM system:collections"
        ) { [weak self] result in
            guard let self = self else { return }
            self.collectionNames = result.items.compactMap { $0.value["name"] as? String }
        }
    }

    func startSubscription() {
        // system:collections is a local virtual collection; no sync subscription is needed.
        // Subscribing to it via sync would silently fail. Skip it.
    }

    func closeLiveQuery() {
        collectionsObserver?.cancel()
        subscription?.cancel()
    }

}
