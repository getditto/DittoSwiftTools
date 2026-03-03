//
//  StorageBreakdownView.swift
//  DittoSwiftTools/DittoDiskUsage
//
//  A categorized view showing where Ditto storage is allocated on disk.
//  Adapted from DittoStore_Calculator by Chad James.
//

import SwiftUI
import DittoSwift

/// A SwiftUI view that displays a categorized breakdown of Ditto on-disk storage,
/// including per-collection document count, JSON payload size, WAL/SHM, logs,
/// and metadata overhead.
///
/// Usage:
/// ```swift
/// DittoStorageBreakdownView(ditto: myDittoInstance)
/// ```
public struct DittoStorageBreakdownView: View {
    @StateObject private var viewModel: StorageBreakdownViewModel

    public init(ditto: Ditto) {
        _viewModel = StateObject(wrappedValue: StorageBreakdownViewModel(ditto: ditto))
    }

    public var body: some View {
        List {
            // Collection picker
            Section(header: Text("Collection")) {
                if viewModel.isLoading {
                    HStack {
                        ProgressView()
                        Text("Loading collections...")
                            .foregroundColor(.secondary)
                    }
                } else if viewModel.collections.isEmpty {
                    Text("No collections found")
                        .foregroundColor(.secondary)
                } else {
                    Picker("Collection", selection: Binding(
                        get: { viewModel.selectedCollection },
                        set: { viewModel.changeCollection(to: $0) }
                    )) {
                        ForEach(viewModel.collections, id: \.self) { name in
                            Text(name).tag(name)
                        }
                    }
                    #if os(iOS)
                    .pickerStyle(.menu)
                    #endif
                }

                Button {
                    viewModel.refreshCollections()
                } label: {
                    Label("Refresh Collections", systemImage: "arrow.clockwise")
                }
            }

            // Document count
            Section(header: Text("Documents")) {
                HStack {
                    Text("Documents in collection")
                    Spacer()
                    Text("\(viewModel.breakdown.documentCount)")
                        .font(.system(.title2, design: .rounded).bold())
                }
                #if os(tvOS)
                .focusable(true)
                #endif
            }

            // Storage breakdown
            Section(header: Text("Storage Breakdown")) {
                breakdownRow(
                    label: "Collection payload (JSON)",
                    bytes: viewModel.breakdown.collectionPayloadBytes
                )
                breakdownRow(
                    label: "SQLite WAL / SHM",
                    bytes: viewModel.breakdown.walShmBytes
                )
                breakdownRow(
                    label: "Logging",
                    bytes: viewModel.breakdown.logsBytes
                )
                breakdownRow(
                    label: "Metadata & overhead",
                    bytes: viewModel.breakdown.metadataOverheadBytes
                )

                HStack {
                    Text("Total on-disk (all Ditto)")
                        .fontWeight(.semibold)
                    Spacer()
                    Text(StorageBreakdown.formatBytes(viewModel.breakdown.totalOnDiskBytes))
                        .font(.system(.title3, design: .rounded).bold())
                }
                #if os(tvOS)
                .focusable(true)
                #endif
            }
        }
        .navigationTitle("Storage Breakdown")
    }

    @ViewBuilder
    private func breakdownRow(label: String, bytes: Int) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(StorageBreakdown.formatBytes(bytes))
                .foregroundColor(.secondary)
        }
        #if os(tvOS)
        .focusable(true)
        #endif
    }
}
