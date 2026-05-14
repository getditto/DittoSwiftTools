//
//  SparklineView.swift
//  DittoSwiftTools/DittoDiskUsage
//
//  Created by Rohith Sriram on 4/21/26.
//

import SwiftUI

/// Minimal line trend of integer values; auto-scales to the value range so the
/// trend shape is visible even when absolute deltas are small.
struct SparklineView: View {
    let values: [Int]
    let color: Color

    /// 1 KB floor — smaller variation is treated as noise and renders flat.
    static let minVisibleRange: Int = 1024

    var body: some View {
        GeometryReader { geometry in
            sparklinePath(in: geometry.size)
                .stroke(color, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
        }
        .frame(height: 40)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Disk usage trend")
        .accessibilityValue(Text(accessibilitySummary))
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

    private var accessibilitySummary: String {
        guard let first = values.first, let last = values.last, values.count >= 2 else {
            return "Not enough samples"
        }
        let delta = last - first
        let direction = delta == 0 ? "stable" : (delta > 0 ? "up" : "down")
        return "\(values.count) samples, trending \(direction)"
    }
}
