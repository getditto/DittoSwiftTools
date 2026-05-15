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

    /// Vertical spacing between the category name and its definition.
    private static let titleToBodySpacing: CGFloat = 4

    /// Vertical padding so glossary rows don't crowd each other.
    private static let verticalPadding: CGFloat = 2

    var body: some View {
        VStack(alignment: .leading, spacing: Self.titleToBodySpacing) {
            Text(category.displayName)
                .font(.headline)
            Text(category.glossary)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, Self.verticalPadding)
        .accessibilityElement(children: .combine)
    }
}
