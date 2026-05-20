//
//  AnimatedByteCounterView.swift
//  DittoSwiftTools/DittoDiskUsage
//
//  Created by Rohith Sriram on 4/21/26.
//

import SwiftUI

struct AnimatedByteCounterView: View {
    /// `nil` shows a dash placeholder — used before the first disk usage
    /// snapshot lands so the user doesn't briefly see "0 bytes".
    let bytes: Int?
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
            counter
                .font(.system(size: Self.counterFontSize, weight: .semibold, design: .rounded))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(accessibilityValueText)
    }

    @ViewBuilder
    private var counter: some View {
        if let bytes {
            AnimatedByteCount(value: Double(bytes))
                .foregroundColor(.primary)
        } else {
            Text(verbatim: "—")
                .foregroundColor(.secondary)
        }
    }

    private var accessibilityValueText: Text {
        if let bytes {
            return Text(ByteCountFormatting.format(bytes))
        }
        return Text("Waiting for first report")
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
