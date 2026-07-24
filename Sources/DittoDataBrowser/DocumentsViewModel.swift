//
//  DocumentsViewModel.swift
//  DataBrowser
//
//  Created by Walker Erekson on 11/7/22.
//

import Foundation
import DittoSwift
import OrderedCollections

class DocumentsViewModel: ObservableObject {

    let collectionName: String
    var subscription: DittoSyncSubscription?
    var collectionObserver: DittoStoreObserver?
    var ditto: Ditto

    @Published var docProperties: [String]?
    @Published var docsList: [Document] = []
    @Published var selectedDoc = 0

    init(collectionName: String, ditto: Ditto, isStandAlone: Bool) {
        self.collectionName = collectionName
        self.ditto = ditto
        startSubscription(isStandAlone: isStandAlone)
        findAll()
    }

    func startSubscription(isStandAlone: Bool) {
        if isStandAlone {
            self.subscription = try? ditto.sync.registerSubscription(
                query: "SELECT * FROM `\(collectionName)` LIMIT 1000"
            )
        }
    }

    func findAll() {
        observe(query: "SELECT * FROM `\(collectionName)`")
    }

    func findWithFilter(queryString: String) {
        self.selectedDoc = 0
        observe(query: "SELECT * FROM `\(collectionName)` WHERE \(queryString)")
    }

    func filterDocs(queryString: String) {
        collectionObserver?.cancel()
        collectionObserver = nil

        if queryString.isEmpty {
            findAll()
        } else {
            findWithFilter(queryString: queryString)
        }
    }

    func closeLiveQuery() {
        collectionObserver?.cancel()
        collectionObserver = nil
    }

    private func observe(query: String) {
        self.collectionObserver = try? self.ditto.store.registerObserver(query: query) { [weak self] result in
            guard let self = self else { return }
            self.docsList = result.items.map { item in
                let value = item.value
                let id = (value["_id"].flatMap { $0 }).map { String(describing: $0) } ?? ""
                var ordered = OrderedDictionary<String, Any?>()
                for key in value.keys.sorted() {
                    ordered[key] = value[key].flatMap { $0 }
                }
                return Document(id: id, value: ordered)
            }
            self.docProperties = self.docsList.first?.value.keys.map { $0 }
        }
    }
}
