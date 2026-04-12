import SwiftUI

struct WorkoutCalendarView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: WorkoutDataManager
    @Binding var selectedDate: Date
    
    @State private var currentMonth: Date = Date()
    @State private var isYearlyMode: Bool = false
    @Namespace private var animation
    
    // Intensity Mapping Colors
    private func color(for level: Int) -> Color {
        switch level {
        case 0: return Color.white.opacity(0.05)
        case 1: return dataManager.primaryColor.opacity(0.2)
        case 2: return dataManager.primaryColor.opacity(0.4)
        case 3: return dataManager.primaryColor.opacity(0.7)
        case 4: return dataManager.primaryColor
        default: return Color.white.opacity(0.05)
        }
    }
    
    var body: some View {
        ZStack {
            Theme.Colors.surface.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header (Liquid Glass)
                VStack(spacing: 20) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(isYearlyMode ? "ANNUAL MOMENTUM" : "MONTHLY PERSPECTIVE")
                                .technicalMicroCopy()
                                .foregroundColor(dataManager.primaryColor)
                            Text(isYearlyMode ? "HISTORY HEATMAP" : "WORKOUT LOGS")
                                .font(.system(size: 24, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                        }
                        Spacer()
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(Theme.Colors.onSurfaceVariant.opacity(0.4))
                        }
                    }
                    
                    // Controls Bar
                    HStack {
                        if !isYearlyMode {
                            // Month Selector
                            HStack(spacing: 16) {
                                Button(action: { changeMonth(by: -1) }) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 36, height: 36)
                                        .background(Theme.Colors.surfaceContainerHigh)
                                        .clipShape(Circle())
                                }
                                
                                Text(currentMonth.format("MMMM yyyy").uppercased())
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .frame(minWidth: 140)
                                
                                Button(action: { changeMonth(by: 1) }) {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 36, height: 36)
                                        .background(Theme.Colors.surfaceContainerHigh)
                                        .clipShape(Circle())
                                }
                            }
                        } else {
                            Text("\(Calendar.current.component(.year, from: Date())) TOTAL ACTIVITY")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        // Mode Toggle
                        Button(action: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                isYearlyMode.toggle()
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: isYearlyMode ? "calendar" : "square.grid.3x3.fill")
                                Text(isYearlyMode ? "MONTHLY" : "HEATMAP")
                                    .font(.system(size: 12, weight: .black, design: .rounded))
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(dataManager.primaryColor)
                            .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 24)
                .background(
                    Theme.Colors.surfaceContainerLow.opacity(0.6)
                        .background(.ultraThinMaterial)
                        .ignoresSafeArea()
                )
                .ghostBorder(radius: 0) // Border only at bottom if needed
                
                if isYearlyMode {
                    YearlyHeatmapView(selectedDate: $selectedDate, dismiss: { dismiss() })
                        .transition(.scale(scale: 0.95).combined(with: .opacity))
                } else {
                    MonthlyCalendarView(currentMonth: currentMonth, selectedDate: $selectedDate, dismiss: { dismiss() })
                        .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)).combined(with: .opacity))
                }
                
                Spacer()
            }
        }
    }
    
    private func changeMonth(by value: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: value, to: currentMonth) {
            withAnimation {
                currentMonth = newDate
            }
        }
    }
}

// MARK: - Monthly View
struct MonthlyCalendarView: View {
    let currentMonth: Date
    @Binding var selectedDate: Date
    let dismiss: () -> Void
    @EnvironmentObject var dataManager: WorkoutDataManager
    
    private let weekdays = ["S", "M", "T", "W", "T", "F", "S"]
    
    private var days: [Date?] {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        let range = calendar.range(of: .day, in: .month, for: startOfMonth)!
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        
        var d: [Date?] = Array(repeating: nil, count: firstWeekday - 1)
        for day in 1...range.count {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                d.append(date)
            }
        }
        return d
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Weekday symbols
            HStack {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.gray.opacity(0.6))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 24)
            
            // Grid
            let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 7)
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(0..<days.count, id: \.self) { index in
                    if let date = days[index] {
                        DayCell(date: date, isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate)) {
                            selectedDate = date
                            dismiss()
                        }
                    } else {
                        Color.clear.aspectRatio(1, contentMode: .fit)
                    }
                }
            }
            .padding(.horizontal, 24)
        }
        .padding(.top, 24)
    }
}

// MARK: - Day Cell
struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var dataManager: WorkoutDataManager
    
    var body: some View {
        Button(action: action) {
            ZStack {
                let intensity = dataManager.activityLevel(for: date)
                
                RoundedRectangle(cornerRadius: 12)
                    .fill(color(for: intensity))
                    .aspectRatio(1, contentMode: .fit)
                
                if isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white, lineWidth: 2)
                }
                
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(colorText(for: intensity))
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    private func color(for level: Int) -> Color {
        switch level {
        case 0: return Theme.Colors.surfaceContainerHigh.opacity(0.5)
        case 1: return dataManager.primaryColor.opacity(0.3)
        case 2: return dataManager.primaryColor.opacity(0.5)
        case 3: return dataManager.primaryColor.opacity(0.8)
        case 4: return dataManager.primaryColor
        default: return Theme.Colors.surfaceContainerHigh.opacity(0.5)
        }
    }
    
    private func colorText(for level: Int) -> Color {
        return level > 2 ? .black : .white
    }
}

// MARK: - Yearly Heatmap
struct YearlyHeatmapView: View {
    @Binding var selectedDate: Date
    let dismiss: () -> Void
    @EnvironmentObject var dataManager: WorkoutDataManager
    
    private let months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                ForEach(0..<12, id: \.self) { mIndex in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(months[mIndex].uppercased())
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundColor(.gray)
                        
                        HeatmapMonthGrid(month: mIndex + 1, selectedDate: $selectedDate, dismiss: dismiss)
                    }
                }
            }
            .padding(24)
            .padding(.bottom, 100)
        }
    }
}

struct HeatmapMonthGrid: View {
    let month: Int
    @Binding var selectedDate: Date
    let dismiss: () -> Void
    @EnvironmentObject var dataManager: WorkoutDataManager
    
    private var daysInMonth: [Date?] {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = calendar.component(.year, from: Date())
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
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(0..<daysInMonth.count, id: \.self) { index in
                if let date = daysInMonth[index] {
                    let intensity = dataManager.activityLevel(for: date)
                    let isSel = Calendar.current.isDate(date, inSameDayAs: selectedDate)
                    
                    Button(action: {
                        selectedDate = date
                        dismiss()
                    }) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(color(for: intensity))
                            .aspectRatio(1, contentMode: .fit)
                            .overlay(
                                RoundedRectangle(cornerRadius: 3)
                                    .stroke(Color.white.opacity(isSel ? 1 : 0), lineWidth: 1)
                            )
                    }
                } else {
                    Color.clear.aspectRatio(1, contentMode: .fit)
                }
            }
        }
    }
    
    private func color(for level: Int) -> Color {
        switch level {
        case 0: return Color.white.opacity(0.05)
        case 1: return dataManager.primaryColor.opacity(0.3)
        case 2: return dataManager.primaryColor.opacity(0.5)
        case 3: return dataManager.primaryColor.opacity(0.8)
        case 4: return dataManager.primaryColor
        default: return Color.white.opacity(0.05)
        }
    }
}



extension Date {
    func format(_ format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
}
