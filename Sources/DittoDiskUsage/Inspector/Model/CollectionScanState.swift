//
//  CollectionScanState.swift
//  DittoSwiftTools/DittoDiskUsage
//
//  Created by Rohith Sriram on 4/21/26.
//

import Foundation

/// Per-collection scan outcome. One enum keeps state consistent rather
/// than splitting it across parallel "counts" / "failures" dictionaries.
public enum CollectionScanState: Equatable {
    case pending
    case counted(Int)
    case failed
}
