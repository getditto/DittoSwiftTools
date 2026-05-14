//
//  HorizontalBarChartView.swift
//  DittoSwiftTools/DittoDiskUsage
//
//  Created by Rohith Sriram on 4/21/26.
//

import SwiftUI

/// A horizontal bar chart. Each row: label, bar sized by `value / maxValue`,
/// and a formatted value. `valueFormatter` picks the format (bytes, counts, …).
struct HorizontalBarChartView: View {
    struct Item: Identifiable, Equatable {
        let id: String
        let label: String
        let value: Int
    }

    let items: [Item]
    let tint: Color
    let valueFormatter: (Int) -> String

    init(
        items: [Item],
        tint: Color = .accentColor,
        valueFormatter: @escaping (Int) -> String = { "\($0)" }
    ) {
        self.items = items
        self.tint = tint
        self.valueFormatter = valueFormatter
    }

    /// Vertical spacing between rows.
    private static let rowSpacing: CGFloat = 10

    /// Spacing between a row's text label and its bar.
    private static let labelToBarSpacing: CGFloat = 3

    /// Bar thickness — readable in dense lists, visible on small screens.
    private static let barHeight: CGFloat = 6

    var body: some View {
        let maxValue = items.map(\.value).max() ?? 0
        VStack(alignment: .leading, spacing: Self.rowSpacing) {
            ForEach(items) { item in
                row(for: item, maxValue: maxValue)
            }
        }
    }

    private func row(for item: Item, maxValue: Int) -> some View {
        VStack(alignment: .leading, spacing: Self.labelToBarSpacing) {
            HStack {
                Text(item.label)
                    .font(.caption)
                    .lineLimit(1)
                Spacer()
                Text(valueFormatter(item.value))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.2))
                    Capsule()
                        .fill(tint)
                        .frame(width: geometry.size.width * fillRatio(value: item.value, max: maxValue))
                }
            }
            .frame(height: Self.barHeight)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(item.label))
        .accessibilityValue(Text(valueFormatter(item.value)))
    }

    private func fillRatio(value: Int, max: Int) -> CGFloat {
        guard max > 0 else { return 0 }
        return CGFloat(value) / CGFloat(max)
    }
}
