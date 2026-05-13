//
//  TotalCounterSection.swift
//  DittoSwiftTools/DittoDiskUsage
//
//  Created by Rohith Sriram on 4/21/26.
//

import SwiftUI

struct TotalCounterSection: View {
    let totalBytes: Int
    let hasReceivedFirstSnapshot: Bool

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                AnimatedByteCounterView(bytes: totalBytes, label: "Total on disk")
                Text(caption)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
        }
    }

    private var caption: LocalizedStringKey {
        hasReceivedFirstSnapshot
            ? "Reported by the Ditto SDK's disk usage publisher."
            : "Waiting for the first disk usage report…"
    }
}
