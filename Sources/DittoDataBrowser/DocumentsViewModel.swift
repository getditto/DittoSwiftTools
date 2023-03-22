//
//  DocumentsViewModel.swift
//  DataBrowser
//
//  Created by Walker Erekson on 11/7/22.
//

import Foundation
import DittoSwift
import OrderedCollections

@available(iOS 13.0, *)
class DocumentsViewModel : ObservableObject {
    
    let collectionName: String
    var subscription: DittoSubscription?
    var collectionObserver: DittoLiveQuery?
    var ditto: Ditto
        
    @Published var docProperties: [String]?
    @Published var docsList: [Document] = []
    @Published var selectedDoc = 0

    var orderedDict = OrderedDictionary<String, Any?>()

    
    init(collectionName: String, ditto: Ditto, isStandAlone: Bool) {
        self.collectionName = collectionName
        self.ditto = ditto
        startSubscription(isStandAlone: isStandAlone)
        findAll_LiveQuery()
    }
        
    func startSubscription(isStandAlone: Bool) {
        if(isStandAlone) {
            self.subscription = self.ditto.store.collection(collectionName).findAll().limit(1000).subscribe()
        }
    }
    
    func findAll_LiveQuery() {
        self.collectionObserver = self.ditto.store.collection(collectionName).findAll().observeLocal(eventHandler: {docs, event in
            self.docsList.removeAll()
            for doc in docs {
                self.docProperties = doc.value.keys.map{$0}.sorted()
                
                for (key, value) in doc.value {
                    self.orderedDict[key] = value
                }
                
                self.docsList.append(Document(id: doc.id.toString(), value: self.orderedDict))
            }
        })
    }
    
    func findWithFilter_LiveQuery(queryString: String) {
        self.selectedDoc = 0
        
        collectionObserver = self.ditto.store.collection(collectionName).find(queryString).observeLocal(eventHandler: {docs, event in
            self.docsList.removeAll()
            
            for doc in docs {
                
                self.docProperties = doc.value.keys.map{$0}.sorted()
                
                for (key, value) in doc.value {
                    self.orderedDict[key] = value
                }
                
                self.docsList.append(Document(id: doc.id.toString(), value: self.orderedDict))
            }
            
        })

    }
    
    
    func filterDocs(queryString: String) {
        collectionObserver?.stop()
        collectionObserver = nil
        
        if(queryString.isEmpty) {
            findAll_LiveQuery()
        }
        else {
            findWithFilter_LiveQuery(queryString: queryString)
        }
    }
}
