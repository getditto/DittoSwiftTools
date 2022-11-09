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
        lhs.key.description == rhs.key.description
    }
    
    
    let value: OrderedDictionary<String,Any?>
    let key: String
    
    init(key: String, value: OrderedDictionary<String,Any?>) {
        self.key = key
        self.value = value
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(key)
    }
}
