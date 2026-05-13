//
//  DiskUsageInspectorView.swift
//  DittoSwiftTools/DittoDiskUsage
//
//  Created by Rohith Sriram on 4/21/26.
//

import SwiftUI
import DittoSwift

/// Visualizes Ditto's local on-disk storage using only public SDK APIs.
public struct DiskUsageInspectorView: View {
    @StateObject private var viewModel: DiskUsageInspectorViewModel

    public init(ditto: Ditto) {
        _viewModel = StateObject(wrappedValue: DiskUsageInspectorViewModel(ditto: ditto))
    }

    public var body: some View {
        List {
            TotalCounterSection(
                totalBytes: viewModel.breakdown.totalOnDiskBytes,
                hasReceivedFirstSnapshot: viewModel.hasReceivedFirstSnapshot
            )
            GlossarySection()
        }
        .navigationTitle("Disk Usage Inspector")
    }
}
