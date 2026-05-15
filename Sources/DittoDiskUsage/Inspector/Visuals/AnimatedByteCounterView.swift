//
//  AnimatedByteCounterView.swift
//  DittoSwiftTools/DittoDiskUsage
//
//  Created by Rohith Sriram on 4/21/26.
//

import SwiftUI

struct AnimatedByteCounterView: View {
    let bytes: Int
    let label: LocalizedStringKey

    /// Headline size for the counter — large enough to stand out, small
    /// enough not to crowd surrounding rows.
    private static let counterFontSize: CGFloat = 40

    /// Spacing between the small label and the headline counter.
    private static let labelToCounterSpacing: CGFloat = 4

    var body: some View {
        VStack(alignment: .leading, spacing: Self.labelToCounterSpacing) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            AnimatedByteCount(value: Double(bytes))
                .font(.system(size: Self.counterFontSize, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(Text(ByteCountFormatting.format(bytes)))
    }
}

/// A `Text` whose byte count interpolates smoothly via `Animatable`.
private struct AnimatedByteCount: View, Animatable {
    var value: Double

    var animatableData: Double {
        get { value }
        set { value = newValue }
    }

    var body: some View {
        Text(ByteCountFormatting.format(max(0, Int(value))))
    }
}
