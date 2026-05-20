//
//  SparklineView.swift
//  DittoSwiftTools/DittoDiskUsage
//
//  Created by Rohith Sriram on 4/21/26.
//

import SwiftUI

/// Minimal line trend of integer values. Auto-scales to the value range
/// with a `minVisibleRange` floor so byte-level noise renders flat
/// instead of looking like a dramatic trend.
struct SparklineView: View {
    let values: [Int]
    let color: Color

    /// 1 KB floor — smaller variation is treated as noise and renders flat.
    static let minVisibleRange: Int = 1024

    /// Line thickness — thin enough to feel like a sparkline, thick enough
    /// to remain visible at typical row heights.
    private static let lineWidth: CGFloat = 1.5

    /// Sparkline strip height — short enough to fit inline in a section
    /// without dominating, tall enough to show shape.
    private static let height: CGFloat = 40

    var body: some View {
        GeometryReader { geometry in
            sparklinePath(in: geometry.size)
                .stroke(color, style: StrokeStyle(lineWidth: Self.lineWidth, lineCap: .round, lineJoin: .round))
        }
        .frame(height: Self.height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Disk usage trend")
        .accessibilityValue(accessibilitySummary)
    }

    private func sparklinePath(in size: CGSize) -> Path {
        guard values.count >= 2 else { return Path() }

        let minValue = values.min() ?? 0
        let maxValue = values.max() ?? 0
        let midpoint = Double(minValue + maxValue) / 2.0
        let displayRange = max(maxValue - minValue, Self.minVisibleRange)
        let stepX = size.width / CGFloat(values.count - 1)

        var path = Path()
        for (index, value) in values.enumerated() {
            let x = CGFloat(index) * stepX
            // Centered around the vertical midpoint; small actual ranges
            // cluster near the middle instead of filling the chart.
            let offsetFromMid = (Double(value) - midpoint) / Double(displayRange)
            let y = size.height * (0.5 - CGFloat(offsetFromMid))
            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        return path
    }

    /// Built as `Text` (not `String`) so each segment goes through the
    /// localization table — a German VoiceOver user should hear German.
    private var accessibilitySummary: Text {
        guard let first = values.first, let last = values.last, values.count >= 2 else {
            return Text("Not enough samples")
        }
        let delta = last - first
        // Mirror the visual floor: changes smaller than `minVisibleRange`
        // render flat, so VoiceOver should say "stable" too.
        let direction: Text
        if abs(delta) < Self.minVisibleRange {
            direction = Text("stable")
        } else if delta > 0 {
            direction = Text("trending up")
        } else {
            direction = Text("trending down")
        }
        return Text("\(values.count) samples, \(direction)")
    }
}
