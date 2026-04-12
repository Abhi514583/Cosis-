import SwiftUI
import Charts

// MARK: - History Sheet (used both in Logger + Analytics)

struct ExerciseHistorySheet: View {
    let exercise: Exercise
    let onSeeMore: (() -> Void)?
    @EnvironmentObject var dataManager: WorkoutDataManager
    @State private var metricMode: MetricMode = .maxWeight
    
    enum MetricMode: String, CaseIterable {
        case maxWeight = "Max Weight"
        case volume = "Volume"
    }

    // Last 4-5 sessions for this exercise
    private var history: [(date: Date, volume: Double, maxWeight: Double)] {
        Array(dataManager.history(for: exercise.name).suffix(5))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Drag indicator
            Capsule()
                .fill(Color.white.opacity(0.15))
                .frame(width: 36, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.top, 16)
            
            // Title Row
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("HISTORY")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(dataManager.primaryColor)
                    Text(exercise.name)
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }
                Spacer()
                // PR Badge
                if let maxW = history.map({ $0.maxWeight }).max(), maxW > 0 {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("ALL-TIME PR")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.gray)
                        let convertedMax = dataManager.weightUnit.convert(maxW, from: .kg)
                        Text("\(String(format: "%.1f", convertedMax)) \(dataManager.weightUnit.rawValue)")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundColor(dataManager.primaryColor)
                    }
                }
            }
            .padding(.horizontal, 24)
            
            if history.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.1))
                    Text("No history yet. Log a set to start tracking progress!")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 48)
            } else {
                // Metric Toggle
                HStack(spacing: 8) {
                    ForEach(MetricMode.allCases, id: \.self) { mode in
                        Button(action: { withAnimation { metricMode = mode } }) {
                            Text(mode.rawValue)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(metricMode == mode ? .black : .white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(metricMode == mode ? dataManager.primaryColor : Color.white.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                    Spacer()
                    Text("LAST \(history.count) SESSIONS")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 24)
                
                // Line Chart
                Chart {
                    ForEach(history, id: \.date) { item in
                        let rawYVal = metricMode == .maxWeight ? item.maxWeight : item.volume
                        let yVal = dataManager.weightUnit.convert(rawYVal, from: .kg)
                        LineMark(
                            x: .value("Date", item.date),
                            y: .value(metricMode.rawValue, yVal)
                        )
                        .foregroundStyle(dataManager.primaryColor)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                        .interpolationMethod(.catmullRom)
                        
                        AreaMark(
                            x: .value("Date", item.date),
                            y: .value(metricMode.rawValue, yVal)
                        )
                        .foregroundStyle(dataManager.primaryColor.opacity(0.08))
                        
                        PointMark(
                            x: .value("Date", item.date),
                            y: .value(metricMode.rawValue, yVal)
                        )
                        .foregroundStyle(dataManager.primaryColor)
                        .symbolSize(40)
                    }
                }
                .frame(height: 160)
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisGridLine().foregroundStyle(.white.opacity(0.06))
                        AxisValueLabel(format: .dateTime.day().month(), centered: true)
                            .foregroundStyle(.gray)
                            .font(.system(size: 10))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .trailing) { value in
                        AxisGridLine().foregroundStyle(.white.opacity(0.06))
                        AxisValueLabel()
                            .foregroundStyle(.gray)
                            .font(.system(size: 10))
                    }
                }
                .padding(.horizontal, 24)
                
                // Session Cards
                VStack(spacing: 10) {
                    ForEach(history.reversed(), id: \.date) { item in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.date.relativeLabel())
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                                Text(item.date, format: .dateTime.day().month().year())
                                    .font(.system(size: 10))
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                let cMax = dataManager.weightUnit.convert(item.maxWeight, from: .kg)
                                let cVol = dataManager.weightUnit.convert(item.volume, from: .kg)
                                Text("\(String(format: "%.1f", cMax)) \(dataManager.weightUnit.rawValue)")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                Text("Vol \(Int(cVol)) \(dataManager.weightUnit.rawValue)")
                                    .font(.system(size: 10))
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Theme.Colors.surfaceContainerHigh)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding(.horizontal, 24)
                
                // See More Button
                if let seeMore = onSeeMore {
                    Button(action: seeMore) {
                        HStack(spacing: 8) {
                            Image(systemName: "chart.bar.fill")
                            Text("SEE FULL PROGRESS")
                                .font(.system(size: 13, weight: .bold))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(dataManager.primaryColor)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(dataManager.primaryColor.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(dataManager.primaryColor.opacity(0.3), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal, 24)
                }
            }
            
            Spacer(minLength: 40)
        }
        .background(Theme.Colors.surface.ignoresSafeArea())
    }
}

extension Date {
    func relativeLabel() -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(self) { return "Today" }
        if calendar.isDateInYesterday(self) { return "Yesterday" }
        let days = calendar.dateComponents([.day], from: self, to: Date()).day ?? 0
        if days < 7 { return "\(days) days ago" }
        if days < 14 { return "Last week" }
        return "\(days / 7) weeks ago"
    }
}
