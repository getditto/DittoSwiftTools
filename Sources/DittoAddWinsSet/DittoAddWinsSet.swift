//
//  File.swift
//  
//
//  Created by Maximilian Alexander on 1/29/23.
//

import Foundation
import DittoSwift
import SwiftCBOR

public struct DittoAddWinsSet {

    public var values: Set<AnyHashable?>

    init(dictionary: [String: Any?]) {
        let hashableValues = dictionary.values.map({ $0 as? AnyHashable })
        self.values = Set(hashableValues)
    }

    func asDictionary() throws -> [String: Any?] {
        var dictionary: [String: Any?] = [:]
        for v in values {
            let bytes = try SwiftCBOR.CBOR.encodeAny(v)
            let data = Data(bytes)
            dictionary[data.base64EncodedString()] = v
        }
        return dictionary
    }

    mutating func insert(_ value: AnyHashable) {
        self.values.insert(value)
    }

    mutating func remove(_ value: AnyHashable) {
        self.values.remove(value)
    }
}

extension DittoDocumentPath {

    var addWinsSet: DittoAddWinsSet? {
        guard let dictionary = dictionary else { return nil }
        return DittoAddWinsSet(dictionary: dictionary)
    }

}


