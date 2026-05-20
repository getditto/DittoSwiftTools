//
//  HealthStatusSection.swift
//  DittoSwiftTools/DittoDiskUsage
//
//  Created by Rohith Sriram on 5/20/26.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Read-only state ``HealthStatusSection`` needs.
struct HealthStatusSectionState {
    let currentBytes: Int
    let thresholdBytes: Int
    let status: HealthStatus
    /// Gates the indicator and gauge — they read as misleading
    /// ("Healthy / 0% / 0 bytes") before the first snapshot lands.
    let hasReceivedFirstSnapshot: Bool
}

/// Callbacks for user actions on this section.
struct HealthStatusSectionActions {
    let onIncreaseThreshold: () -> Void
    let onDecreaseThreshold: () -> Void
}

struct HealthStatusSection: View {
    let state: HealthStatusSectionState
    let actions: HealthStatusSectionActions

    /// Spacing between the indicator, gauge, and threshold row.
    private static let stackSpacing: CGFloat = 12

    /// Vertical padding inside the row.
    private static let verticalPadding: CGFloat = 6

    /// Width reserved for the threshold stepper control.
    private static let stepperWidth: CGFloat = 100

    /// Horizontal spacing between the placeholder icon and label.
    private static let placeholderIconSpacing: CGFloat = 8

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: Self.stackSpacing) {
                if state.hasReceivedFirstSnapshot {
                    HealthIndicatorView(status: state.status)
                    HealthGaugeView(
                        currentBytes: state.currentBytes,
                        thresholdBytes: state.thresholdBytes
                    )
                } else {
                    waitingPlaceholder
                }
                // Always shown — the user can adjust the threshold even
                // before the first snapshot arrives.
                thresholdRow
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, Self.verticalPadding)
        } header: {
            Text("Health Status")
        } footer: {
            Text("Adjust the threshold in \(ByteCountFormatting.format(DiskStorageViewModel.thresholdStepBytes)) steps. The gauge and indicator update live.")
        }
    }

    private var waitingPlaceholder: some View {
        HStack(spacing: Self.placeholderIconSpacing) {
            Image(systemName: "hourglass")
                .foregroundColor(.secondary)
                // Decorative — the text already carries the meaning.
                .accessibilityHidden(true)
            Text("Waiting for the first disk usage report…")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var thresholdRow: some View {
        HStack {
            Text("Threshold")
                .font(.subheadline)
            Spacer()
            Text(ByteCountFormatting.format(state.thresholdBytes))
                .font(.subheadline)
                .foregroundColor(.secondary)
            Stepper(
                "",
                onIncrement: actions.onIncreaseThreshold,
                onDecrement: actions.onDecreaseThreshold
            )
            .labelsHidden()
            .frame(width: Self.stepperWidth)
        }
        // Group label + value + stepper into one VoiceOver element so the
        // current threshold is announced alongside the adjust action.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Threshold")
        .accessibilityValue(Text(ByteCountFormatting.format(state.thresholdBytes)))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                actions.onIncreaseThreshold()
            case .decrement:
                // Avoid silent no-ops at the minimum — VoiceOver users
                // get no feedback otherwise.
                if state.thresholdBytes <= DiskStorageViewModel.minimumThresholdBytes {
                    postAccessibilityAnnouncement(
                        NSLocalizedString(
                            "Minimum threshold reached",
                            comment: "VoiceOver announcement when the threshold stepper is decremented at the minimum"
                        )
                    )
                } else {
                    actions.onDecreaseThreshold()
                }
            @unknown default:
                break
            }
        }
    }

    /// Posts a VoiceOver announcement. No-op on platforms without UIKit.
    private func postAccessibilityAnnouncement(_ message: String) {
        #if canImport(UIKit)
        UIAccessibility.post(notification: .announcement, argument: message)
        #endif
    }
}
