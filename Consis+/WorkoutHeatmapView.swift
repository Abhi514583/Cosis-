import SwiftUI

struct WorkoutHeatmapView: View {
    @EnvironmentObject var dataManager: WorkoutDataManager
    
    // Calculate the last 52 weeks of dates
    private var weeks: [[Date?]] {
        let calendar = Calendar.current
        var allDates: [Date?] = []
        
        // Find the most recent Sunday to start the grid
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let daysToSubtract = (weekday - 1)
        guard let endDate = calendar.date(byAdding: .day, value: -daysToSubtract, to: today) else { return [] }
        
        // Go back 364 days (52 weeks)
        for i in (0..<371).reversed() {
            if let date = calendar.date(byAdding: .day, value: -i, to: endDate) {
                allDates.append(date)
            }
        }
        
        // Group into weeks of 7
        var result: [[Date?]] = []
        for i in stride(from: 0, to: allDates.count, by: 7) {
            let week = Array(allDates[i..<min(i + 7, allDates.count)])
            result.append(week)
        }
        return result
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("CONSISTENCY")
                .technicalMicroCopy()
                .foregroundColor(dataManager.primaryColor)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    // Weekday Labels
                    VStack(alignment: .leading, spacing: 4) {
                        Spacer().frame(height: 20) // For month labels alignment
                        Text("Mon").font(.system(size: 8)).foregroundColor(.gray)
                        Spacer()
                        Text("Wed").font(.system(size: 8)).foregroundColor(.gray)
                        Spacer()
                        Text("Fri").font(.system(size: 8)).foregroundColor(.gray)
                    }
                    .frame(width: 24)
                    
                    // The Grid
                    ForEach(0..<weeks.count, id: \.self) { weekIndex in
                        VStack(spacing: 4) {
                            // Month Label (Only show if it's the start of a month)
                            if let firstDate = weeks[weekIndex].first(where: { $0 != nil })!,
                               Calendar.current.component(.day, from: firstDate) <= 7 {
                                Text(firstDate.monthAbbreviation())
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.gray)
                                    .frame(height: 12)
                            } else {
                                Spacer().frame(height: 12)
                            }
                            
                            ForEach(0..<7) { dayIndex in
                                if dayIndex < weeks[weekIndex].count, let date = weeks[weekIndex][dayIndex] {
                                    HeatmapCell(date: date)
                                } else {
                                    Rectangle()
                                        .fill(Color.clear)
                                        .frame(width: 12, height: 12)
                                }
                            }
                        }
                    }
                }
                .padding(.bottom, 8)
            }
            .ghostBorder(radius: 20)
            .padding(.horizontal, -4)
        }
    }
}

struct HeatmapCell: View {
    let date: Date
    @EnvironmentObject var dataManager: WorkoutDataManager
    
    var body: some View {
        let dateKey = dataManager.dateKey(date)
        let heatmapColor = dataManager.heatmapData()[dateKey]
        
        RoundedRectangle(cornerRadius: 3)
            .fill(heatmapColor ?? Theme.Colors.surfaceContainerLow)
            .frame(width: 12, height: 12)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(Color.white.opacity(heatmapColor != nil ? 0.2 : 0.05), lineWidth: 0.5)
            )
            .shadow(color: (heatmapColor ?? Color.clear).opacity(0.3), radius: 2)
    }
}

extension Date {
    func monthAbbreviation() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: self)
    }
}
