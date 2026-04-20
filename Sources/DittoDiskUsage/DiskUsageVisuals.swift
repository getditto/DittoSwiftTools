//
//  DiskUsageVisuals.swift
//  DittoSwiftTools/DittoDiskUsage
//

import SwiftUI

// MARK: - Donut Chart

struct DonutSlice: Identifiable {
    let id = UUID()
    let label: String
    let bytes: Int
    let color: Color
}

struct DonutChartView: View {
    let slices: [DonutSlice]
    let lineWidth: CGFloat

    init(slices: [DonutSlice], lineWidth: CGFloat = 22) {
        self.slices = slices
        self.lineWidth = lineWidth
    }

    private var total: Int {
        slices.reduce(0) { $0 + $1.bytes }
    }

    var body: some View {
        ZStack {
            if total > 0 {
                ForEach(Array(sliceAngles.enumerated()), id: \.offset) { index, angles in
                    DonutArc(startAngle: angles.start, endAngle: angles.end, lineWidth: lineWidth)
                        .fill(slices[index].color)
                        .animation(.easeInOut(duration: 0.6), value: total)
                }
            } else {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: lineWidth)
            }

            VStack(spacing: 2) {
                Text(StorageBreakdown.formatBytes(total))
                    .font(.system(.title3, design: .rounded).bold())
                Text("Total")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private var sliceAngles: [(start: Angle, end: Angle)] {
        guard total > 0 else { return [] }
        var angles: [(start: Angle, end: Angle)] = []
        var currentAngle = Angle.degrees(-90) // start at top
        for slice in slices {
            let fraction = Double(slice.bytes) / Double(total)
            let sweep = Angle.degrees(fraction * 360)
            angles.append((start: currentAngle, end: currentAngle + sweep))
            currentAngle = currentAngle + sweep
        }
        return angles
    }
}

private struct DonutArc: Shape {
    var startAngle: Angle
    var endAngle: Angle
    var lineWidth: CGFloat

    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(startAngle.degrees, endAngle.degrees) }
        set {
            startAngle = .degrees(newValue.first)
            endAngle = .degrees(newValue.second)
        }
    }

    func path(in rect: CGRect) -> Path {
        let radius = min(rect.width, rect.height) / 2 - lineWidth / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)
        var path = Path()
        path.addArc(center: center, radius: radius,
                     startAngle: startAngle, endAngle: endAngle,
                     clockwise: false)
        return path.strokedPath(.init(lineWidth: lineWidth, lineCap: .butt))
    }
}

struct DonutLegendView: View {
    let slices: [DonutSlice]

    private var total: Int {
        slices.reduce(0) { $0 + $1.bytes }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(slices) { slice in
                HStack(spacing: 6) {
                    Circle()
                        .fill(slice.color)
                        .frame(width: 10, height: 10)
                    Text(slice.label)
                        .font(.caption)
                    Spacer()
                    Text(StorageBreakdown.formatBytes(slice.bytes))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if total > 0 {
                        Text("(\(Int(round(Double(slice.bytes) / Double(total) * 100)))%)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - Health Gauge

struct HealthGaugeView: View {
    let currentBytes: Int
    let thresholdBytes: Int

    private var fraction: Double {
        guard thresholdBytes > 0 else { return 0 }
        return min(Double(currentBytes) / Double(thresholdBytes), 1.5)
    }

    private var displayFraction: Double {
        min(fraction, 1.0)
    }

    private var gaugeColor: Color {
        if fraction >= 1.0 {
            return .red
        } else if fraction >= 0.75 {
            return .orange
        } else {
            return .green
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Disk Health")
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text("\(Int(min(fraction, 1.5) * 100))%")
                    .font(.system(.subheadline, design: .rounded).bold())
                    .foregroundColor(gaugeColor)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 12)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(gaugeColor)
                        .frame(width: max(0, geo.size.width * CGFloat(displayFraction)), height: 12)
                        .animation(.easeInOut(duration: 0.5), value: currentBytes)
                }
            }
            .frame(height: 12)

            HStack {
                Text("0")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text("Threshold: \(StorageBreakdown.formatBytes(thresholdBytes))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Health Traffic Light

struct HealthIndicatorView: View {
    let currentBytes: Int
    let thresholdBytes: Int

    private var fraction: Double {
        guard thresholdBytes > 0 else { return 0 }
        return Double(currentBytes) / Double(thresholdBytes)
    }

    private var statusColor: Color {
        if fraction >= 1.0 { return .red }
        if fraction >= 0.75 { return .orange }
        return .green
    }

    private var statusLabel: String {
        if fraction >= 1.0 { return "Unhealthy" }
        if fraction >= 0.75 { return "Warning" }
        return "Healthy"
    }

    private var statusIcon: String {
        if fraction >= 1.0 { return "exclamationmark.triangle.fill" }
        if fraction >= 0.75 { return "exclamationmark.circle.fill" }
        return "checkmark.circle.fill"
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: statusIcon)
                .font(.title2)
                .foregroundColor(statusColor)
                .animation(.easeInOut(duration: 0.3), value: statusLabel)
            VStack(alignment: .leading, spacing: 1) {
                Text(statusLabel)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(statusColor)
                Text("\(StorageBreakdown.formatBytes(currentBytes)) of \(StorageBreakdown.formatBytes(thresholdBytes)) limit")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Sparkline (Trend)

struct SparklineView: View {
    let dataPoints: [Int]
    let color: Color

    var body: some View {
        if dataPoints.count < 2 {
            HStack {
                Image(systemName: "chart.xyaxis.line")
                    .foregroundColor(.secondary)
                Text("Collecting trend data...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        } else {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Usage Trend")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    if let last = dataPoints.last {
                        Text(StorageBreakdown.formatBytes(last))
                            .font(.system(.caption, design: .rounded).bold())
                            .foregroundColor(color)
                    }
                }

                GeometryReader { geo in
                    sparklinePath(in: geo.size, closed: false)
                        .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                        .animation(.easeInOut(duration: 0.4), value: dataPoints.count)

                    sparklinePath(in: geo.size, closed: true)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [color.opacity(0.25), color.opacity(0.0)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .animation(.easeInOut(duration: 0.4), value: dataPoints.count)
                }
                .frame(height: 50)

                HStack {
                    Text("\(dataPoints.count) samples")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    if let minVal = dataPoints.min(), let maxVal = dataPoints.max() {
                        Text("Range: \(StorageBreakdown.formatBytes(minVal)) – \(StorageBreakdown.formatBytes(maxVal))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func sparklinePath(in size: CGSize, closed: Bool = true) -> Path {
        guard dataPoints.count >= 2 else { return Path() }

        let minVal = dataPoints.min() ?? 0
        let maxVal = dataPoints.max() ?? 1
        let range = max(Double(maxVal - minVal), 1)
        let stepX = size.width / CGFloat(dataPoints.count - 1)
        let padding: CGFloat = 4

        var path = Path()
        for (index, value) in dataPoints.enumerated() {
            let x = CGFloat(index) * stepX
            let normalised = CGFloat(Double(value - minVal) / range)
            let y = size.height - padding - normalised * (size.height - padding * 2)
            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        if closed {
            path.addLine(to: CGPoint(x: CGFloat(dataPoints.count - 1) * stepX, y: size.height))
            path.addLine(to: CGPoint(x: 0, y: size.height))
            path.closeSubpath()
        }

        return path
    }
}

// MARK: - Horizontal Bar Chart (Collection Ranking)

struct HorizontalBarChartView: View {
    let items: [(label: String, bytes: Int)]
    let barColor: Color
    let valueFormatter: (Int) -> String

    init(
        items: [(label: String, bytes: Int)],
        barColor: Color,
        valueFormatter: @escaping (Int) -> String = StorageBreakdown.formatBytes
    ) {
        self.items = items
        self.barColor = barColor
        self.valueFormatter = valueFormatter
    }

    private var maxBytes: Int {
        items.map(\.bytes).max() ?? 1
    }

    var body: some View {
        if items.isEmpty {
            HStack {
                Image(systemName: "chart.bar.xaxis")
                    .foregroundColor(.secondary)
                Text("No collection data available.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        } else {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(items.prefix(10).enumerated()), id: \.offset) { index, item in
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(item.label)
                                .font(.caption)
                                .lineLimit(1)
                            Spacer()
                            Text(valueFormatter(item.bytes))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(barColor.opacity(1.0 - Double(index) * 0.07))
                                .frame(
                                    width: maxBytes > 0
                                        ? max(2, geo.size.width * CGFloat(Double(item.bytes) / Double(maxBytes)))
                                        : 2,
                                    height: 8
                                )
                                .animation(.easeInOut(duration: 0.4), value: item.bytes)
                        }
                        .frame(height: 8)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Histogram (Document Size Distribution)

public struct DocSizeBucket: Identifiable {
    public let id: String
    public let label: String
    public var count: Int

    public init(id: String, label: String, count: Int) {
        self.id = id
        self.label = label
        self.count = count
    }
}

struct HistogramView: View {
    let buckets: [DocSizeBucket]
    let barColor: Color

    private var maxCount: Int {
        buckets.map(\.count).max() ?? 1
    }

    private var totalDocs: Int {
        buckets.reduce(0) { $0 + $1.count }
    }

    var body: some View {
        if totalDocs == 0 {
            HStack {
                Image(systemName: "chart.bar")
                    .foregroundColor(.secondary)
                Text("No documents to analyze.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        } else {
            VStack(spacing: 8) {
                GeometryReader { geo in
                    HStack(alignment: .bottom, spacing: 4) {
                        ForEach(buckets) { bucket in
                            VStack(spacing: 2) {
                                if bucket.count > 0 {
                                    Text("\(bucket.count)")
                                        .font(.system(.caption2, design: .rounded).bold())
                                        .foregroundColor(barColor)
                                }

                                RoundedRectangle(cornerRadius: 3)
                                    .fill(barColor)
                                    .frame(height: barHeight(for: bucket.count, in: geo.size.height - 20))
                                    .animation(.easeInOut(duration: 0.4), value: bucket.count)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                .frame(height: 80)

                HStack(spacing: 4) {
                    ForEach(buckets) { bucket in
                        Text(bucket.label)
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func barHeight(for count: Int, in maxHeight: CGFloat) -> CGFloat {
        guard maxCount > 0 else { return 2 }
        return max(2, maxHeight * CGFloat(Double(count) / Double(maxCount)))
    }
}

// MARK: - Stacked Bar (Replication vs Store)

struct StackedComparisonView: View {
    let leftLabel: String
    let leftBytes: Int
    let leftColor: Color
    let rightLabel: String
    let rightBytes: Int
    let rightColor: Color

    private var total: Int { leftBytes + rightBytes }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            GeometryReader { geo in
                HStack(spacing: 0) {
                    if total > 0 {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(leftColor)
                            .frame(width: max(2, geo.size.width * CGFloat(Double(leftBytes) / Double(total))))
                            .animation(.easeInOut(duration: 0.4), value: leftBytes)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(rightColor)
                            .frame(width: max(2, geo.size.width * CGFloat(Double(rightBytes) / Double(total))))
                            .animation(.easeInOut(duration: 0.4), value: rightBytes)
                    } else {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.15))
                    }
                }
            }
            .frame(height: 16)

            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Circle().fill(leftColor).frame(width: 8, height: 8)
                    Text(leftLabel).font(.caption)
                    Text(StorageBreakdown.formatBytes(leftBytes))
                        .font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                HStack(spacing: 4) {
                    Circle().fill(rightColor).frame(width: 8, height: 8)
                    Text(rightLabel).font(.caption)
                    Text(StorageBreakdown.formatBytes(rightBytes))
                        .font(.caption).foregroundColor(.secondary)
                }
            }

            if total > 0 {
                HStack {
                    Spacer()
                    Text("Ratio: \(percentString(leftBytes))  /  \(percentString(rightBytes))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func percentString(_ bytes: Int) -> String {
        guard total > 0 else { return "0%" }
        return "\(Int(round(Double(bytes) / Double(total) * 100)))%"
    }
}

// MARK: - Growth Rate Display

struct GrowthRateView: View {
    let bytesPerSecond: Double?

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(rateColor)
            VStack(alignment: .leading, spacing: 1) {
                Text("Growth Rate")
                    .font(.subheadline.weight(.medium))
                if let rate = bytesPerSecond {
                    let perMinute = rate * 60
                    Text(rateText(perMinute))
                        .font(.system(.caption, design: .rounded).bold())
                        .foregroundColor(rateColor)
                } else {
                    Text("Calculating...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
    }

    private var icon: String {
        guard let rate = bytesPerSecond else { return "hourglass" }
        if rate > 100 { return "arrow.up.right" }
        if rate < -100 { return "arrow.down.right" }
        return "arrow.right"
    }

    private var rateColor: Color {
        guard let rate = bytesPerSecond else { return .secondary }
        if rate > 1_000_000 { return .red }     // > 1 MB/s
        if rate > 100 { return .orange }          // growing
        if rate < -100 { return .green }          // shrinking
        return .secondary                          // stable
    }

    private func rateText(_ perMinute: Double) -> String {
        let absRate = abs(perMinute)
        let formatted = StorageBreakdown.formatBytes(Int(absRate))
        if perMinute > 100 {
            return "+\(formatted) / min"
        } else if perMinute < -100 {
            return "-\(formatted) / min"
        } else {
            return "Stable"
        }
    }
}

// MARK: - Glossary Item

struct GlossaryRow: View {
    let term: String
    let definition: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(term)
                .font(.caption.weight(.semibold))
            Text(definition)
                .font(.caption2)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Animated Counter

struct AnimatedByteCounterView: View {
    let targetBytes: Int
    let font: Font
    let color: Color

    @State private var displayedBytes: Int = 0
    @State private var timer: Timer?

    var body: some View {
        Text(StorageBreakdown.formatBytes(displayedBytes))
            .font(font)
            .foregroundColor(color)
            .onAppear {
                displayedBytes = targetBytes
            }
            .onDisappear {
                timer?.invalidate()
                timer = nil
            }
            .onChange(of: targetBytes) { newValue in
                animateTo(newValue)
            }
    }

    private func animateTo(_ target: Int) {
        timer?.invalidate()
        let start = displayedBytes
        let diff = target - start
        guard diff != 0 else { return }

        let totalSteps = 20
        let stepDuration: TimeInterval = 0.025
        var currentStep = 0

        timer = Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { t in
            currentStep += 1
            if currentStep >= totalSteps {
                t.invalidate()
                displayedBytes = target
            } else {
                let progress = Double(currentStep) / Double(totalSteps)
                let eased = 1.0 - pow(1.0 - progress, 3)
                displayedBytes = start + Int(Double(diff) * eased)
            }
        }
    }
}
