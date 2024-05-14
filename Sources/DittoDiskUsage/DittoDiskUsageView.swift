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
                    .frame(width: 400, alignment: .center)
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
                                    .frame(width: 200, alignment: .leading)
                                Text(child.size)
                                    .frame(width: 100, alignment: .trailing)
                            }
                        }
                        HStack {
                            Group {
                                Text("Total")
                                    .frame(width: 200, alignment: .leading)
                                Text(diskUsage.totalSize)
                                    .frame(width: 100, alignment: .trailing)
                            }
                        }
                    }
                } else {
                    // Displayed before first async callback
                    Text("Calculating disk usage 💾⏳")
                }
            }

            Section {
                HStack {
                    Text("Updated at:")
                        .frame(width: 200, alignment: .leading)
                    Text(viewModel.diskUsage?.lastUpdated ?? DiskUsageViewModel.dateFormatter.string(from: Date()))
                        .frame(width: 100, alignment: .trailing)
                }
            }

            Section {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    // Label was added in iOS 14
                    Label("Close", systemImage: "xmark")
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
