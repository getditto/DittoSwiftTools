//
//  Document.swift
//  DataBrowser
//
//  Created by Walker Erekson on 11/8/22.
//

import Foundation
import OrderedCollections

class Document : Hashable, Equatable{
    static func == (lhs: Document, rhs: Document) -> Bool {
        lhs.id.description == rhs.id.description
    }
    
    let id: String
    let value: OrderedDictionary<String,Any?>
    
    init(id: String, value: OrderedDictionary<String,Any?>) {
        self.id = id
        self.value = value
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
