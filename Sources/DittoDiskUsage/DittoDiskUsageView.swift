//
//  DittoDiskUsageView.swift
//  DittoSwiftTools/DiskUsage
//
//  Created by Ben Chatelain on 2023-01-30.
//

import DittoSwift
import SwiftUI
import Combine

public struct DittoDiskUsageView: View {

    @Environment(\.presentationMode) var presentationMode

    var ditto: Ditto

    @ObservedObject var viewModel: DiskUsageViewModel

    public init(ditto: Ditto) {
        self.ditto = ditto
        self.viewModel = DiskUsageViewModel(ditto: ditto)
    }

    public var body: some View {
        List {
            Section {
                Text("Disk Usage")
                    .frame(alignment: .center)
                    .font(.title)
            }

            Section {
                if let diskUsage = viewModel.diskUsage {
                    if let error = diskUsage.error {
                        Text("Error: \(error)")
                            .foregroundColor(.red)
                    } else {
                        ForEach(diskUsage.children, id: \.self) { (child: DiskUsage) in
                            HStack {
                                Text(child.relativePath)
                                    .font(.body)
                                Spacer()
                                Text(child.size)
                                    .font(.body)
                            }
                        }
                        HStack {
                            Group {
                                Text("Total")
                                    .font(.body)
                                Spacer()
                                Text(diskUsage.totalSize)
                                    .font(.body)
                            }
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
                        .font(.body)
                    Spacer()
                    Text(viewModel.diskUsage?.lastUpdated ?? DiskUsageViewModel.dateFormatter.string(from: Date()))
                        .font(.body)
                }
            }

            Section {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Label("Close", systemImage: "xmark")
                        .font(.body)
                }
            }
        }
    }
}

struct DittoDiskUsageView_Previews: PreviewProvider {
    static var previews: some View {
        DittoDiskUsageView(ditto: Ditto())
    }
}
