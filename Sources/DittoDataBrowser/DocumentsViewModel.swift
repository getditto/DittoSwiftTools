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
    var subscription: DittoSyncSubscription?
    var collectionObserver: DittoStoreObserver?
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
            do {
                self.subscription = try self.ditto.sync.registerSubscription(query: "SELECT * FROM \(collectionName) LIMIT 1000")
            } catch {
                print(
                    "DocumentsVM.\(#function) - ERROR starting subscription for collection: " +
                    "\(collectionName)\n" +
                    "error: \(error.localizedDescription)"
                )
            }
        }
    }
    
    func findAll_LiveQuery() {
        do {
            self.collectionObserver = try self.ditto.store.registerObserver(
                query: "SELECT * FROM \(collectionName)",
                handler: { queryResult in
                    self.docsList.removeAll()

                    for item in queryResult.items {
                        let docValue = item.value
                        self.docProperties = docValue.keys.map{$0}.sorted()

                        for (key, value) in docValue {
                            self.orderedDict[key] = value
                        }

                        let documentId = docValue["_id"] as? String ?? ""
                        self.docsList.append(Document(id: documentId, value: self.orderedDict))
                    }
                }
            )
        } catch {
            print(
                "DocumentsVM.\(#function) - ERROR fetching all from collection: " +
                "\(collectionName)\n" +
                "error: \(error.localizedDescription)"
            )
        }
    }

    
    func findWithFilter_LiveQuery(queryString: String) {
        self.selectedDoc = 0
        
        print("Query String: " + queryString)

        // Convert legacy query string to DQL WHERE clause
        let dqlQuery = "SELECT * FROM \(collectionName) WHERE \(queryString)"

        do {
            collectionObserver = try self.ditto.store.registerObserver(
                query: dqlQuery,
                handler: { queryResult in
                    self.docsList.removeAll()

                    for item in queryResult.items {
                        let docValue = item.value
                        self.docProperties = docValue.keys.map{$0}.sorted()

                        for (key, value) in docValue {
                            self.orderedDict[key] = value
                        }

                        // ID is now accessed via item.value["_id"] as String
                        let documentId = docValue["_id"] as? String ?? ""
                        self.docsList.append(Document(id: documentId, value: self.orderedDict))
                    }
                }
            )
        } catch {
            print(
                "DocumentsVM.\(#function) - ERROR fetching \(queryString) from collection: " +
                "\(collectionName)\n" +
                "error: \(error.localizedDescription)"
            )
        }
    }

    
    
    func filterDocs(queryString: String) {
        collectionObserver?.cancel()
        collectionObserver = nil
        
        if(queryString.isEmpty) {
            collectionObserver?.cancel()
            findAll_LiveQuery()
        }
        else {
            collectionObserver?.cancel()
            findWithFilter_LiveQuery(queryString: queryString)
        }
    }
    
    func closeLiveQuery() {
        collectionObserver?.cancel()
    }
}
