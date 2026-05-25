//
//  AboutSection.swift
//  DittoSwiftTools/DittoDiskUsage
//
//  Created by Rohith Sriram on 5/19/26.
//

import SwiftUI

/// Closing section that explains what the Inspector measures, what it
/// doesn't, and why a few obvious things are missing.
struct AboutSection: View {
    /// Reserved width for the leading icon so the text columns align.
    private static let iconWidth: CGFloat = 22

    /// Vertical spacing between bullet rows.
    private static let rowSpacing: CGFloat = 8

    /// Horizontal spacing between bullet icon and text.
    private static let iconToTextSpacing: CGFloat = 10

    /// Vertical padding inside the section.
    private static let verticalPadding: CGFloat = 4

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: Self.rowSpacing) {
                bullet(
                    iconName: "lock.shield",
                    title: "Public APIs only",
                    detail: "All data comes from the disk usage publisher and one-shot DQL queries. No file-system access, no SDK internals."
                )
                bullet(
                    iconName: "eye.slash",
                    title: "No live observers",
                    detail: "Counts and samples run only when you tap. Nothing watches your collections in the background."
                )
                bullet(
                    iconName: "ruler",
                    title: "Bounded memory",
                    detail: "Document sampling is capped at \(Format.count(CollectionInspectionViewModel.sampleLimit)) items and released as soon as each item is measured."
                )
                // The Glossary section's footer already explains the
                // per-category gap. Don't say it twice.
            }
            .padding(.vertical, Self.verticalPadding)
        } header: {
            Text("About This Tool")
        }
    }

    private func bullet(
        iconName: String,
        title: LocalizedStringKey,
        detail: LocalizedStringKey
    ) -> some View {
        HStack(alignment: .top, spacing: Self.iconToTextSpacing) {
            Image(systemName: iconName)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: Self.iconWidth, alignment: .center)
                // Decorative — the symbol name would otherwise be spoken
                // ("lock shield, Public APIs only…").
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
