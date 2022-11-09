//
//  DocumentsViewModel.swift
//  DataBrowser
//
//  Created by Walker Erekson on 11/7/22.
//

import Foundation
import DittoSwift
import OrderedCollections

class DocumentsViewModel : ObservableObject {
    
    let collectionName: String
    let subscription: DittoSubscription?
    var collectionObserver: DittoLiveQuery?
        
    @Published var docProperties: [String]?
    @Published var docsList: [Document] = []
    var orderedDict = OrderedDictionary<String, Any?>()
    
    init(collectionName: String) {
        self.collectionName = collectionName
        subscription = DittoManager.shared.ditto.store.collection(collectionName).findAll().subscribe()
        setupLiveQuery()
    }
    
    func setupLiveQuery() {
        collectionObserver = DittoManager.shared.ditto.store.collection(collectionName).findAll().observeLocal(eventHandler: {docs, event in
            for doc in docs {
                print(doc.value)
//                ["isCompleted": Optional(false), "_id": Optional("62cef664008fd87e00e60667"), "body": Optional("run")]
//                ["body": Optional("Cxvb"), "isDeleted": Optional(false), "_id": Optional("63333b1600ce507b0097e3b3"), "isCompleted": Optional(false)]
                
                self.docProperties = doc.value.keys.map{$0}
                
                for (key, value) in doc.value {
                    self.orderedDict[key] = value
                }
                
                self.docsList.append(Document(key: doc.id.toString(), value: self.orderedDict))
                print(self.docsList.count)
                
            }
        })
    }
}
