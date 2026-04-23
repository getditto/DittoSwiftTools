//
//  DataBrowserViewModel.swift
//  DataBrowser
//
//  Created by Walker Erekson on 11/3/22.
//

import SwiftUI
import DittoSwift

class DataBrowserViewModel: ObservableObject {
    
    @Published var collections: [String] = []
    var subscription: DittoSyncSubscription?
    var collectionsObserver: DittoStoreObserver?
    var ditto: Ditto
    
    init(ditto: Ditto) {
        self.ditto = ditto
        observeCollections()
    }
    
    func observeCollections() {
        do {
            collectionsObserver = try self.ditto.store.registerObserver(
                query: "SELECT * FROM system:collections"
            ) { [weak self] queryResult in
                // Extract collection names from the system collections query
                self?.collections = queryResult.items.compactMap { item in
                    item.value["name"] as? String
                }
            }
        } catch {
            print(
                "DataBrowserVM.\(#function) - ERROR observing all collections" +
                "error: \(error.localizedDescription)"
            )
        }
    }

    
    func startSubscription() {
        do {
            subscription = try ditto.sync.registerSubscription(query: "SELECT * FROM system:collections")
        } catch {
            print(
                "DataBrowserVM.\(#function) - ERROR starting subscription to all collections" +
                "error: \(error.localizedDescription)"
            )
        }
    }
    
    func closeLiveQuery() {
        collectionsObserver?.cancel()
    }
    
}

