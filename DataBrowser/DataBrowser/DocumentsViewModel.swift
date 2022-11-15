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
    @Published var selectedDoc = 0

    var orderedDict = OrderedDictionary<String, Any?>()

    
    init(collectionName: String) {
        self.collectionName = collectionName
        subscription = DittoManager.shared.ditto.store.collection(collectionName).findAll().subscribe()
        findAll_LiveQuery()
    }
    
    func findAll_LiveQuery() {
        collectionObserver = DittoManager.shared.ditto.store.collection(collectionName).findAll().observeLocal(eventHandler: {docs, event in
            self.docsList.removeAll()
            for doc in docs {
                print(type(of: docs))
                print(type(of: doc))
                print(doc.value)
                self.docProperties = doc.value.keys.map{$0}.sorted()
                
                for (key, value) in doc.value {
                    self.orderedDict[key] = value
                }
                
                self.docsList.append(Document(id: doc.id.toString(), value: self.orderedDict))
            }
        })
    }
    
    func findWithFilter_LiveQuery(queryString: String) throws {
        self.selectedDoc = 0

        collectionObserver = DittoManager.shared.ditto.store.collection(collectionName).find(queryString).observeLocal(eventHandler: {docs, event in
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
        
        if(queryString == "") {
            findAll_LiveQuery()
        }
        else {
            do {
                try findWithFilter_LiveQuery(queryString: queryString)
            } catch {
                print("error filtering data")
            }
        }
    }
}
