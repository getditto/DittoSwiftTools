//
//  GlossarySection.swift
//  DittoSwiftTools/DittoDiskUsage
//
//  Created by Rohith Sriram on 4/21/26.
//

import SwiftUI

struct GlossarySection: View {
    var body: some View {
        Section {
            ForEach(StorageCategory.allCases) { category in
                GlossaryRow(category: category)
            }
        } header: {
            Text("Glossary")
        } footer: {
            Text("Reference only. The Inspector doesn't group bytes by category yet — that needs a typed signal from the SDK.")
        }
    }
}

private struct GlossaryRow: View {
    let category: StorageCategory

    /// Spacing between the icon and the text column.
    private static let iconToTextSpacing: CGFloat = 10

    /// Vertical spacing between the category name and its definition.
    private static let titleToBodySpacing: CGFloat = 4

    /// Vertical padding so glossary rows don't crowd each other.
    private static let verticalPadding: CGFloat = 2

    /// Reserved width for the leading icon so the text columns align.
    private static let iconWidth: CGFloat = 22

    var body: some View {
        HStack(alignment: .top, spacing: Self.iconToTextSpacing) {
            Image(systemName: iconName)
                .font(.subheadline)
                .foregroundColor(iconTint)
                .frame(width: Self.iconWidth, alignment: .center)
                // Decorative — the category name already follows.
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Self.titleToBodySpacing) {
                Text(category.displayName)
                    .font(.headline)
                Text(category.glossary)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, Self.verticalPadding)
        .accessibilityElement(children: .combine)
    }

    private var iconName: String {
        switch category {
        case .store: return "doc.fill"
        case .attachments: return "paperclip"
        case .logs: return "text.alignleft"
        case .replication: return "arrow.triangle.2.circlepath"
        }
    }

    private var iconTint: Color {
        switch category {
        case .store: return .blue
        case .attachments: return .pink
        case .logs: return .green
        case .replication: return .purple
        }
    }
}
