//
//  DocSizeBucket.swift
//  DittoSwiftTools/DittoDiskUsage
//
//  Created by Rohith Sriram on 4/21/26.
//

import Foundation

/// One bucket in the document-size histogram.
public struct DocSizeBucket: Identifiable, Equatable, Hashable, Sendable {
    public let id: String
    public let label: String
    public let count: Int

    public init(id: String, label: String, count: Int) {
        self.id = id
        self.label = label
        self.count = count
    }
}
