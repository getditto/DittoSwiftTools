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
    var collectionsObserver: DittoStoreObserver?
    var ditto: Ditto

    init(ditto: Ditto) {
        self.ditto = ditto
        observeCollections()
    }

    // The Data Browser intentionally observes only the local store. The host
    // application owns its sync subscriptions.
    func observeCollections() {
        collectionsObserver = try? self.ditto.store.registerObserver(
            query: "SELECT * FROM system:collections"
        ) { [weak self] result in
            guard let self = self else { return }
            self.collectionNames = result.items.compactMap { $0.value["name"] as? String }
        }
    }

    deinit {
        collectionsObserver?.cancel()
    }
}
