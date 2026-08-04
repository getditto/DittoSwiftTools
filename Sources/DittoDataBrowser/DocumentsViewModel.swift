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
    var collectionObserver: DittoStoreObserver?
    var ditto: Ditto

    @Published var docProperties: [String]?
    @Published var docsList: [Document] = []
    @Published var selectedDoc = 0
    @Published var documentsErrorMessage: String?
    @Published var queryStatus = "Loading documents…"

    init(collectionName: String, ditto: Ditto) {
        self.collectionName = collectionName
        self.ditto = ditto
        findAll()
    }

    func findAll() {
        observe(
            query: "SELECT * FROM `\(collectionName)` LIMIT 1000",
            isFilterQuery: false,
            successStatus: "Showing all documents"
        )
    }

    func findWithFilter(queryString: String) {
        self.selectedDoc = 0
        observe(
            query: "SELECT * FROM `\(collectionName)` WHERE \(queryString) LIMIT 1000",
            isFilterQuery: true,
            successStatus: "Showing results for: \(queryString)"
        )
    }

    func filterDocs(queryString: String) {
        collectionObserver?.cancel()
        collectionObserver = nil

        let whereExpression = queryString.trimmingCharacters(in: .whitespacesAndNewlines)
        if whereExpression.isEmpty {
            findAll()
        } else {
            findWithFilter(queryString: whereExpression)
        }
    }

    func closeLiveQuery() {
        collectionObserver?.cancel()
        collectionObserver = nil
    }

    private func observe(query: String, isFilterQuery: Bool, successStatus: String) {
        documentsErrorMessage = nil
        queryStatus = "Running query…"

        do {
            self.collectionObserver = try self.ditto.store.registerObserver(query: query) { [weak self] result in
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
                self.queryStatus = successStatus
            }
        } catch {
            docsList = []
            docProperties = nil
            selectedDoc = 0
            queryStatus = "Query failed"
            if isFilterQuery && isQueryFailure(error) {
                documentsErrorMessage = displayMessage(
                    "The filter couldn't be applied. Check the DQL WHERE expression and try again.",
                    error: error
                )
            } else {
                documentsErrorMessage = displayMessage(
                    "Documents couldn't be loaded.",
                    error: error
                )
            }
        }
    }
}

private func isQueryFailure(_ error: Error) -> Bool {
    guard
        let dittoError = error as? DittoError,
        case .storeError(let reason) = dittoError
    else {
        return false
    }

    switch reason {
    case .queryError, .queryInvalid, .queryNotSupported:
        return true
    default:
        return false
    }
}

private func displayMessage(_ summary: String, error: Error) -> String {
    let details = error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
    return details.isEmpty ? summary : "\(summary)\n\n\(details)"
}
