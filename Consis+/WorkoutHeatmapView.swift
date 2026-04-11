import SwiftUI

struct WorkoutHeatmapView: View {
    let year: Int
    @EnvironmentObject var dataManager: WorkoutDataManager
    
    private let months = [
        "Jan", "Feb", "Mar", "Apr", "May", "Jun", 
        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 16) {
                ForEach(0..<12, id: \.self) { monthIndex in
                    MonthBlockView(year: year, month: monthIndex + 1, monthName: months[monthIndex])
                }
            }
            .padding(16)
            .background(Theme.Colors.surfaceContainerLow.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .ghostBorder(radius: 24)
        }
    }
}

struct MonthBlockView: View {
    let year: Int
    let month: Int
    let monthName: String
    @EnvironmentObject var dataManager: WorkoutDataManager
    
    private var daysInMonth: [Date?] {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        
        guard let startOfMonth = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: startOfMonth) else { return [] }
        
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)
        
        for day in 1...range.count {
            components.day = day
            days.append(calendar.date(from: components))
        }
        return days
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(monthName)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(.gray)
            
            let columns = Array(repeating: GridItem(.fixed(6), spacing: 2), count: 7)
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(0..<daysInMonth.count, id: \.self) { index in
                    if let date = daysInMonth[index] {
                        let dateKey = dataManager.dateKey(date)
                        let heatmapColor = dataManager.heatmapData(year: year)[dateKey]
                        
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(heatmapColor ?? Color.white.opacity(0.05))
                            .frame(width: 6, height: 6)
                    } else {
                        Spacer().frame(width: 6, height: 6)
                    }
                }
            }
        }
    }
}
