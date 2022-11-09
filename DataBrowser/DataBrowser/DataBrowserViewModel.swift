//
//  DataBrowserViewModel.swift
//  DataBrowser
//
//  Created by Walker Erekson on 11/3/22.
//

import SwiftUI
import DittoSwift

class DataBrowserViewModel: ObservableObject {
    
    @Published var collections: [DittoCollection]?
    let subscription: DittoSubscription?
    var collectionsObserver: DittoLiveQuery?
    
    init() {
        
        subscription = DittoManager.shared.ditto.store.collections().subscribe()
        observeCollections()
    }
    
    func observeCollections() {
                                                                                         
        collectionsObserver = DittoManager.shared.ditto.store.collections().observeLocal(eventHandler: { _ in
            
            // self.collections = ditto.store.collectionNames()
            self.collections = DittoManager.shared.ditto.store.collections().exec()
        })
    }
    
}
