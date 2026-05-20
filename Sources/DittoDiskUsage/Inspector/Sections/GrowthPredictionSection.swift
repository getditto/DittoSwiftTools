//
//  GrowthPredictionSection.swift
//  DittoSwiftTools/DittoDiskUsage
//
//  Created by Rohith Sriram on 5/20/26.
//

import SwiftUI

/// Read-only state ``GrowthPredictionSection`` needs.
struct GrowthPredictionSectionState {
    let estimatedSecondsToThreshold: Double?
    let remainingBytes: Int
}

struct GrowthPredictionSection: View {
    let state: GrowthPredictionSectionState

    /// Vertical padding inside the row.
    private static let verticalPadding: CGFloat = 6

    var body: some View {
        Section {
            TimeToThresholdView(
                estimatedSecondsToThreshold: state.estimatedSecondsToThreshold,
                remainingBytes: state.remainingBytes
            )
            .padding(.vertical, Self.verticalPadding)
        } header: {
            Text("Growth Prediction")
        } footer: {
            Text("Projected from the current growth rate. Real disk growth fluctuates with sync activity and document changes — treat this as a rough estimate.")
        }
    }
}
