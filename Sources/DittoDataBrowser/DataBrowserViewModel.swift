//
//  DataBrowserViewModel.swift
//  DataBrowser
//
//  Created by Walker Erekson on 11/3/22.
//

import SwiftUI
import DittoSwift

@available(iOS 13.0, *)
class DataBrowserViewModel: ObservableObject {
    
    @Published var collections: [DittoCollection]?
    let subscription: DittoSubscription?
    var collectionsObserver: DittoLiveQuery?
    var ditto: Ditto
    
    init(ditto: Ditto) {
        self.ditto = ditto
        subscription = ditto.store.collections().subscribe()
        observeCollections()
    }
    
    func observeCollections() {
                                                                                         
        collectionsObserver = self.ditto.store.collections().observeLocal(eventHandler: { _ in
            
            // self.collections = ditto.store.collectionNames()
            self.collections = self.ditto.store.collections().exec()
        })
    }
    
}
