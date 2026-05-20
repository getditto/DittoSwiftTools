//
//  GroupHeaderRow.swift
//  DittoSwiftTools/DittoDiskUsage
//
//  Created by Rohith Sriram on 5/19/26.
//

import SwiftUI

/// Visual banner that introduces a group of related sections in the
/// Inspector — a colored icon tile, a title, and a one-line subtitle.
/// Sits inside its own `Section` with a clear row background so the
/// icon tile reads against the List backdrop.
struct GroupHeaderRow: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let systemImageName: String
    let tint: Color

    private static let iconSize: CGFloat = 36
    private static let iconCornerRadius: CGFloat = 8
    private static let iconToTextSpacing: CGFloat = 12
    private static let titleToSubtitleSpacing: CGFloat = 2
    private static let verticalPadding: CGFloat = 6

    var body: some View {
        HStack(spacing: Self.iconToTextSpacing) {
            Image(systemName: systemImageName)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: Self.iconSize, height: Self.iconSize)
                .background(tint)
                .clipShape(RoundedRectangle(cornerRadius: Self.iconCornerRadius))
            VStack(alignment: .leading, spacing: Self.titleToSubtitleSpacing) {
                Text(title)
                    .font(.system(.headline, design: .rounded))
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, Self.verticalPadding)
        .accessibilityElement(children: .combine)
    }
}
