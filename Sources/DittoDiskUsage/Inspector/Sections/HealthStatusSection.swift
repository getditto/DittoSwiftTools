//
//  HealthStatusSection.swift
//  DittoSwiftTools/DittoDiskUsage
//
//  Created by Rohith Sriram on 5/20/26.
//

import SwiftUI

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
    /// Receives the new absolute threshold in bytes. The view model is
    /// responsible for clamping and persisting.
    let onSetThreshold: (Int) -> Void
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
            Text("Adjust the threshold in \(Format.bytes(DiskStorageViewModel.thresholdStepBytes)) steps. The gauge and indicator update live.")
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
                // Hidden so VoiceOver reads the Stepper as one combined
                // adjustable element ("Threshold, 500 MB") instead of
                // announcing the label and value separately.
                .accessibilityHidden(true)
            Spacer()
            Text(Format.bytes(state.thresholdBytes))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .accessibilityHidden(true)
            // Value-binding `Stepper` gives us the adjustable-action and
            // min-clamp announcements for free. SwiftUI takes care of the
            // VoiceOver swipe-up / swipe-down contract.
            Stepper(
                "Threshold, \(Format.bytes(state.thresholdBytes))",
                value: thresholdBinding,
                in: DiskStorageViewModel.minimumThresholdBytes...Int.max,
                step: DiskStorageViewModel.thresholdStepBytes
            )
            .labelsHidden()
            .frame(width: Self.stepperWidth)
        }
    }

    private var thresholdBinding: Binding<Int> {
        Binding(
            get: { state.thresholdBytes },
            set: { actions.onSetThreshold($0) }
        )
    }
}
