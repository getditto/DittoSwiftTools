//
//  TotalCounterSection.swift
//  DittoSwiftTools/DittoDiskUsage
//
//  Created by Rohith Sriram on 4/21/26.
//

import SwiftUI

/// Read-only state the overview section needs.
struct TotalCounterSectionState {
    let totalBytes: Int
    let hasReceivedFirstSnapshot: Bool
    let status: HealthStatus
    let fillRatio: Double
    /// Number of collections seen by the most recent successful scan.
    /// `nil` before any scan or while the most recent scan ended with an error.
    let collectionCount: Int?
    /// Sum of all counted documents from the most recent successful scan.
    /// `nil` before any scan, while a count is still pending, or while the
    /// most recent scan ended with an error.
    let totalDocumentCount: Int?
}

struct TotalCounterSection: View {
    let state: TotalCounterSectionState

    /// Spacing between the counter row, the stat strip, and the caption.
    private static let blockSpacing: CGFloat = 12

    /// Vertical padding inside the row.
    private static let verticalPadding: CGFloat = 4

    /// Padding inside the health badge capsule.
    private static let badgeHorizontalPadding: CGFloat = 10
    private static let badgeVerticalPadding: CGFloat = 5
    private static let badgeBackgroundOpacity: Double = 0.12

    /// Height of the divider between stat-strip columns.
    private static let dividerHeight: CGFloat = 30

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: Self.blockSpacing) {
                counterRow
                statStrip
                Text(caption)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, Self.verticalPadding)
        } header: {
            Text("Overview")
        } footer: {
            Text("Total bytes come from the SDK's disk usage publisher. Collection and document counts appear after you tap Scan collections.")
        }
    }

    // MARK: - Subviews

    private var counterRow: some View {
        HStack(alignment: .firstTextBaseline) {
            // `nil` bytes renders the dash placeholder.
            AnimatedByteCounterView(
                bytes: state.hasReceivedFirstSnapshot ? state.totalBytes : nil,
                label: "Total on disk"
            )
            Spacer()
            // Hide the badge entirely until we have real data — otherwise
            // the user sees a green "Healthy" tag for an empty database
            // before the first snapshot lands.
            if state.hasReceivedFirstSnapshot {
                healthBadge
            }
        }
    }

    private var healthBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: state.status.systemImageName)
                .foregroundColor(state.status.tint)
            Text(state.status.label)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(state.status.tint)
        }
        .padding(.horizontal, Self.badgeHorizontalPadding)
        .padding(.vertical, Self.badgeVerticalPadding)
        .background(state.status.tint.opacity(Self.badgeBackgroundOpacity))
        .clipShape(Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(state.status.label)
    }

    private var statStrip: some View {
        HStack(spacing: 0) {
            statColumn(value: collectionCountText, label: "Collections", accessibilityUnit: "collections")
            Divider().frame(height: Self.dividerHeight)
            statColumn(value: documentCountText, label: "Documents", accessibilityUnit: "documents")
            Divider().frame(height: Self.dividerHeight)
            statColumn(value: percentText, label: "Used", accessibilityUnit: "used")
        }
    }

    /// Placeholder rendered when a numeric value isn't available yet.
    /// Matched against to swap VoiceOver wording away from "em dash".
    private static let placeholder = "—"

    private func statColumn(
        value: String,
        label: LocalizedStringKey,
        accessibilityUnit: LocalizedStringKey
    ) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.title3, design: .rounded).bold())
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        // Read each column as one element: "12 collections" instead of
        // "12" then "Collections" on separate elements. When there's no
        // data, say "No data, collections" instead of "em dash, collections".
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel(for: value, unit: accessibilityUnit))
    }

    private func accessibilityLabel(
        for value: String,
        unit: LocalizedStringKey
    ) -> Text {
        if value == Self.placeholder {
            return Text("No data, \(Text(unit))")
        }
        return Text("\(value) \(Text(unit))")
    }

    // MARK: - Computed strings

    private var caption: LocalizedStringKey {
        state.hasReceivedFirstSnapshot
            ? "Reported by the Ditto SDK's disk usage publisher."
            : "Waiting for the first disk usage report…"
    }

    private var percentText: String {
        guard state.hasReceivedFirstSnapshot else { return Self.placeholder }
        return String(format: "%.0f%%", state.fillRatio * 100)
    }

    private var collectionCountText: String {
        state.collectionCount.map(Format.count) ?? Self.placeholder
    }

    private var documentCountText: String {
        state.totalDocumentCount.map(Format.count) ?? Self.placeholder
    }
}
