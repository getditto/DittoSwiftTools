//
//  DittoDiskUsageView.swift
//  DittoSwiftTools/DiskUsage
//
//  Created by Ben Chatelain on 2023-01-30.
//

import DittoSwift
import SwiftUI
import Combine
import DittoExportData

public struct DittoDiskUsageView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel: DiskUsageViewModel
    @State private var presentExportDataAlert = false
    @State private var presentExportDataShare = false    

    public init(ditto: Ditto) {
        _viewModel = StateObject(wrappedValue: DiskUsageViewModel(ditto: ditto))
    }

    public var body: some View {
        List {
            Section {
                if let diskUsage = viewModel.diskUsage {
                    ForEach(diskUsage.children, id: \.self) { (child: DiskUsage) in
                        HStack {
                            Text(child.relativePath)
                                .frame(minWidth: 200, alignment: .leading)
                            Spacer()
                            Text(child.size)
                                .frame(minWidth: 100, alignment: .trailing)
                        }
                    }
                    HStack {
                        Group {
                            Text("Total")
                                .frame(minWidth: 200, alignment: .leading)
                            Spacer()
                            Text(diskUsage.totalSize)
                                .frame(minWidth: 100, alignment: .trailing)
                        }
                    }
                } else {
                    // Displayed before first async callback
                    Text(DittoDiskUsageConstants.noData)
                }
            }

            Section {
                HStack {
                    Text("Updated at:")
                    Spacer()
                    Text(viewModel.diskUsage?.lastUpdated ?? DiskUsageViewModel.dateFormatter.string(from: Date()))
                }
            }

            Section {
                // Export Ditto Directory
                Button {
                    self.presentExportDataAlert.toggle()
                } label: {
                    Label("Export Data Directory", systemImage: "square.and.arrow.up")
                }
                .sheet(isPresented: $presentExportDataShare) {
                    #if os(iOS)
                    ExportData(ditto: viewModel.ditto)
                    #endif
                }
                .alert(isPresented: $presentExportDataAlert) {
                    Alert(title: Text("Export Ditto Directory"),
                          message:
                            Text("Compressing the data may take a while."),
                          primaryButton: .default(
                            Text("Export"),
                            action: {
                                #if os(iOS)
                                presentExportDataShare = true
                                #elseif os(macOS)
                                ExportDataMacOS(ditto: viewModel.ditto).export()
                                #endif
                            }),
                          secondaryButton: .cancel()
                    )
                }
            }

            Section {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Label("Close", systemImage: "xmark")
                }
            }
        }
        .navigationTitle("Disk Usage")
    }
}

