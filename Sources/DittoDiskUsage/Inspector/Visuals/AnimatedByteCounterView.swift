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

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            AnimatedByteCount(value: Double(bytes))
                .font(.system(size: 40, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(Text(bytes.formattedByteCount))
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
        Text(max(0, Int(value)).formattedByteCount)
    }
}
