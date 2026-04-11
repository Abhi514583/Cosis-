import SwiftUI
import Charts

struct AnalyticsDetailView: View {
    let musclePart: String
    @EnvironmentObject var dataManager: WorkoutDataManager
    @State private var selectedExercise: Exercise?
    @State private var historyItems: [(date: Date, volume: Double, maxWeight: Double)] = []
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text(musclePart)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(dataManager.primaryColor)
                Text("PROGRESSION")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 32)
            
            // Exercise Selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(dataManager.exercises(for: musclePart)) { ex in
                        Button(action: { selectExercise(ex) }) {
                            Text(ex.name)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(selectedExercise == ex ? .black : .white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(selectedExercise == ex ? dataManager.primaryColor : Theme.Colors.surfaceContainerHigh)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
            
            if let ex = selectedExercise {
                VStack(spacing: 24) {
                    // Chart
                    if !historyItems.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("VOLUME TREND")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.gray)
                            
                            Chart {
                                ForEach(historyItems, id: \.date) { item in
                                    LineMark(
                                        x: .value("Date", item.date),
                                        y: .value("Volume", item.volume)
                                    )
                                    .foregroundStyle(dataManager.primaryColor)
                                    .interpolationMethod(.catmullRom)
                                    
                                    AreaMark(
                                        x: .value("Date", item.date),
                                        y: .value("Volume", item.volume)
                                    )
                                    .foregroundStyle(dataManager.primaryColor.opacity(0.1))
                                }
                            }
                            .frame(height: 180)
                            .chartXAxis {
                                AxisMarks(values: .stride(by: .day)) { _ in
                                    AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [2, 4])).foregroundStyle(.white.opacity(0.1))
                                    AxisValueLabel(format: .dateTime.day().month(), centered: true).foregroundStyle(.gray)
                                }
                            }
                            .chartYAxis {
                                AxisMarks { value in
                                    AxisGridLine().foregroundStyle(.white.opacity(0.1))
                                    AxisValueLabel().foregroundStyle(.gray)
                                }
                            }
                        }
                        .padding(24)
                        .background(Theme.Colors.surfaceContainerLow)
                        .clipShape(RoundedRectangle(cornerRadius: 32))
                        .padding(.horizontal, 24)
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 40))
                                .foregroundColor(.white.opacity(0.1))
                            Text("No history for this exercise yet.")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    }
                    
                    // Stats Row
                    HStack(spacing: 16) {
                        StatSmall(title: "BEST VOL", value: String(format: "%.0f", historyItems.map { $0.volume }.max() ?? 0))
                        StatSmall(title: "MAX WT", value: String(format: "%.1f", historyItems.map { $0.maxWeight }.max() ?? 0))
                    }
                    .padding(.horizontal, 24)
                }
            } else {
                Spacer()
                Text("Select an exercise to see progress")
                    .foregroundColor(.gray)
                Spacer()
            }
            
            Spacer()
        }
        .background(Theme.Colors.surface.ignoresSafeArea())
        .onAppear {
            if let first = dataManager.exercises(for: musclePart).first {
                selectExercise(first)
            }
        }
    }
    
    private func selectExercise(_ ex: Exercise) {
        selectedExercise = ex
        historyItems = dataManager.history(for: ex.name)
    }
}

struct StatSmall: View {
    let title: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.system(size: 10, weight: .bold)).foregroundColor(.gray)
            Text(value).font(.system(size: 20, weight: .black, design: .rounded)).foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Theme.Colors.surfaceContainerHigh)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}
