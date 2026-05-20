//
//  TimeToThresholdView.swift
//  DittoSwiftTools/DittoDiskUsage
//
//  Created by Rohith Sriram on 5/19/26.
//

import SwiftUI

/// Predicts when current usage will reach the configured health
/// threshold, based on the growth rate. Pure math from the growth rate
/// — no SDK internals involved.
struct TimeToThresholdView: View {
    /// `nil` if no rate is available yet, `0` if already past the
    /// threshold, otherwise seconds until threshold is hit.
    let estimatedSecondsToThreshold: Double?
    /// Bytes still available before the threshold. Negative when usage
    /// has already gone past the threshold.
    let remainingBytes: Int

    private static let iconToTextSpacing: CGFloat = 8
    private static let textRowSpacing: CGFloat = 2

    // Boundaries between "urgent / soon / comfortable" used to pick
    // the icon and color. Arbitrary but useful.
    private static let urgentHours: Double = 1
    private static let warningHours: Double = 24

    var body: some View {
        HStack(spacing: Self.iconToTextSpacing) {
            Image(systemName: iconName)
                .foregroundColor(tint)
                .font(.title2)
            VStack(alignment: .leading, spacing: Self.textRowSpacing) {
                titleText
                    .font(.caption)
                    .foregroundColor(.secondary)
                primaryText
                    .font(.system(.subheadline, design: .rounded).bold())
                    .foregroundColor(tint)
            }
            Spacer()
            // Hidden when usage is exactly at the threshold — "Over by 0"
            // reads as a typo.
            if remainingBytes != 0 {
                VStack(alignment: .trailing, spacing: Self.textRowSpacing) {
                    trailingLabel
                        .font(.caption)
                        .foregroundColor(.secondary)
                    trailingValue
                        .font(.caption.weight(.medium))
                        .foregroundColor(.secondary)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(titleText)
        .accessibilityValue(accessibilityValueText)
    }

    // MARK: - Severity (single source of truth for icon + tint)

    private enum Severity {
        case past
        case urgent
        case warning
        case comfortable
        case noData
    }

    private var severity: Severity {
        if isPastThreshold { return .past }
        guard let seconds = estimatedSecondsToThreshold else { return .noData }
        let hours = seconds / 3600
        if hours < Self.urgentHours { return .urgent }
        if hours < Self.warningHours { return .warning }
        return .comfortable
    }

    private var iconName: String {
        switch severity {
        case .past, .urgent: return "exclamationmark.triangle.fill"
        case .warning: return "exclamationmark.circle.fill"
        case .comfortable: return "clock.fill"
        case .noData: return "hourglass"
        }
    }

    private var tint: Color {
        switch severity {
        case .past, .urgent: return .red
        case .warning: return .orange
        case .comfortable: return .green
        case .noData: return .secondary
        }
    }

    // MARK: - Text

    private var isPastThreshold: Bool {
        if let seconds = estimatedSecondsToThreshold, seconds <= 0 { return true }
        return remainingBytes <= 0
    }

    private var titleText: Text {
        isPastThreshold ? Text("Threshold exceeded") : Text("Time to threshold")
    }

    private var primaryText: Text {
        if isPastThreshold { return Text("Over threshold") }
        guard let seconds = estimatedSecondsToThreshold else {
            return Text("Not enough data yet")
        }
        // `verbatim:` avoids creating a fresh `LocalizedStringKey` per value
        // — the formatter output is already localized for numbers.
        return Text(verbatim: Self.format(seconds: seconds))
    }

    private var trailingLabel: Text {
        isPastThreshold ? Text("Over by") : Text("Remaining")
    }

    private var trailingValue: Text {
        let bytes = abs(remainingBytes)
        return Text(verbatim: ByteCountFormatting.format(bytes))
    }

    /// Combines primary and trailing into one VoiceOver value so the
    /// trailing column isn't dropped by `.accessibilityElement(children: .ignore)`.
    private var accessibilityValueText: Text {
        guard remainingBytes != 0 else { return primaryText }
        return Text("\(primaryText), \(trailingLabel) \(trailingValue)")
    }

    /// Human-friendly duration string from seconds. Uses the largest
    /// unit that gives a readable number.
    static func format(seconds: Double) -> String {
        if seconds < 60 { return "< 1 min" }
        let minutes = seconds / 60
        if minutes < 60 { return String(format: "%.0f min", minutes) }
        let hours = minutes / 60
        if hours < 24 { return String(format: "%.1f hours", hours) }
        let days = hours / 24
        if days < 365 { return String(format: "%.1f days", days) }
        let years = days / 365
        return String(format: "%.1f years", years)
    }
}
