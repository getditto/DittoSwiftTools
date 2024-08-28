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
    @Environment(\.colorScheme) private var colorScheme

    // Export Ditto Directory
    @State private var presentExportDataShare: Bool = false
    @State private var presentExportDataAlert: Bool = false
    private var textColor: Color {
        colorScheme == .dark ? Color(UIColor.systemBlue) : .blue
    }
    var ditto: Ditto
    @ObservedObject var viewModel: DiskUsageViewModel

    public init(ditto: Ditto) {
        self.ditto = ditto
        self.viewModel = DiskUsageViewModel(ditto: ditto)
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
                    #if os(tvOS)
                    .focusable(true)
                    #endif
                    HStack {
                        Group {
                            Text("Total")
                                .frame(minWidth: 200, alignment: .leading)
                            Spacer()
                            Text(diskUsage.totalSize)
                                .frame(minWidth: 100, alignment: .trailing)
                        }
                    }
                    #if os(tvOS)
                    .focusable(true)
                    #endif
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
                #if os(tvOS)
                .focusable(true)
                #endif
            }

            Section {
                // Export Ditto Directory
                Button {
                    self.presentExportDataAlert.toggle()
                } label: {
                    Label("Export Data Directory", systemImage: "square.and.arrow.up")
                        .foregroundColor(textColor)
                }
                .foregroundColor(textColor)
                .sheet(isPresented: $presentExportDataShare) {
                    #if !os(tvOS)
                    ExportData(ditto: self.ditto)
                    #endif
                }
            }
            .alert(isPresented: $presentExportDataAlert) {
                #if os(tvOS)
                Alert(title: Text("Export Ditto Directory"),
                      message: Text("Exporting the Ditto Directory on tvOS does not work at this time."))
                #else
                Alert(title: Text("Export Ditto Directory"),
                      message:
                        Text("Compressing the data may take a while."),
                      primaryButton: .default(
                        Text("Export"),
                        action: {
                            presentExportDataShare = true
                        }),
                      secondaryButton: .cancel()
                )
                #endif
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

struct DittoDiskUsageView_Previews: PreviewProvider {
    static var previews: some View {
        DittoDiskUsageView(ditto: Ditto())
    }
}
