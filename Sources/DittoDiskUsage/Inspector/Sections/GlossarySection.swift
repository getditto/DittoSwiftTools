//
//  GlossarySection.swift
//  DittoSwiftTools/DittoDiskUsage
//
//  Created by Rohith Sriram on 4/21/26.
//

import SwiftUI

struct GlossarySection: View {
    var body: some View {
        Section(header: Text("Storage categories")) {
            ForEach(StorageCategory.allCases) { category in
                GlossaryRow(category: category)
            }
        }
    }
}

private struct GlossaryRow: View {
    let category: StorageCategory

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(category.displayName)
                .font(.headline)
            Text(category.glossary)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }
}
