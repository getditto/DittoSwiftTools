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
        }
        .navigationTitle("Disk Usage")
    }
}

struct DittoDiskUsageView_Previews: PreviewProvider {
    static var previews: some View {
        DittoDiskUsageView(ditto: Ditto())
    }
}
