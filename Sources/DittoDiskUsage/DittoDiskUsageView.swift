//
//  DittoDiskUsageView.swift
//  DittoSwiftTools/DiskUsage
//
//  Created by Ben Chatelain on 2023-01-30.
//

import DittoSwift
import SwiftUI
import Combine

fileprivate struct DiskUsage: Hashable {
    let relativePath: String
    let sizeInBytes: Int
    let size: String
}

fileprivate struct DiskUsageState {
    let rootPath: String
    let totalSizeInBytes: Int
    let totalSize: String
    let children: [DiskUsage]
    let lastUpdated: String
    let error: String?
}

@available(iOS 14, *)
class DiskUsageViewModel: ObservableObject {

    @Published fileprivate var diskUsage: DiskUsageState?
    var cancellable: Cancellable?

    /// Convenience property for Ditto instance.
    private var ditto: Ditto

    /// Formats file sizes like:
    /// - 248 bytes
    /// - 58 KB
    /// - 4.2 MB
    private static let byteCountFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter
    }()

    /// Formats times like: 12:38:45 PM
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter
    }()

    /// Uses `byteCountFormatter` to create a human-readable string.
    private func formatBytes(bytes: Int) -> String {
        guard let formattedSize = DiskUsageViewModel.byteCountFormatter.string(for: bytes) else { return "error" }
        return formattedSize
    }

    init(ditto: Ditto) {
        self.ditto = ditto
        cancellable = ditto.diskUsage
            .diskUsagePublisher()
            .map { diskUsage in
                let children = diskUsage.childItems
                    .map { (child: DiskUsageItem) in
                        DiskUsage(
                            relativePath: child.path,
                            sizeInBytes: child.sizeInBytes,
                            size: DiskUsageViewModel.byteCountFormatter.string(for: child.sizeInBytes) ?? "error"
                        )
                    }
                    .sorted { $0.relativePath < $1.relativePath }

                return DiskUsageState(
                    rootPath: diskUsage.path,
                    totalSizeInBytes: diskUsage.sizeInBytes,
                    totalSize: DiskUsageViewModel.byteCountFormatter.string(for: diskUsage.sizeInBytes) ?? "error",
                    children: children,
                    lastUpdated: DiskUsageViewModel.dateFormatter.string(from: Date()),
                    error: nil
                )
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.diskUsage, on: self)
    }
}

@available(iOS 14, *)
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

@available(iOS 14, *)
struct DittoDiskUsageView_Previews: PreviewProvider {
    static var previews: some View {
        DittoDiskUsageView(ditto: Ditto())
    }
}
