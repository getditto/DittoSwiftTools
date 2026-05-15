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

    /// Spacing between the counter and the small caption below it.
    private static let counterToCaptionSpacing: CGFloat = 8

    /// Top and bottom padding inside the row so it doesn't crowd
    /// neighbouring sections.
    private static let verticalPadding: CGFloat = 4

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: Self.counterToCaptionSpacing) {
                AnimatedByteCounterView(bytes: totalBytes, label: "Total on disk")
                Text(caption)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, Self.verticalPadding)
        }
    }

    private var caption: LocalizedStringKey {
        hasReceivedFirstSnapshot
            ? "Reported by the Ditto SDK's disk usage publisher."
            : "Waiting for the first disk usage report…"
    }
}
