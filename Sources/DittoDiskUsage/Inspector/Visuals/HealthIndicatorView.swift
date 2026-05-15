//
//  HealthIndicatorView.swift
//  DittoSwiftTools/DittoDiskUsage
//
//  Created by Rohith Sriram on 4/21/26.
//

import SwiftUI

struct HealthIndicatorView: View {
    let status: HealthStatus

    /// Spacing between the status icon and its label.
    private static let iconToLabelSpacing: CGFloat = 6

    var body: some View {
        HStack(spacing: Self.iconToLabelSpacing) {
            Image(systemName: status.systemImageName)
                .foregroundColor(status.tint)
            Text(status.label)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(status.label)
    }
}
