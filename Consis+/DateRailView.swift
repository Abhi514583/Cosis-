import SwiftUI

public struct DateRailView: View {
    @EnvironmentObject var dataManager: WorkoutDataManager
    @Binding var selectedDate: Date
    private let weeks: [[Date]]
    
    public init(selectedDate: Binding<Date>) {
        self._selectedDate = selectedDate
        
        // Find the start of the current week (Monday)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let currentWeekday = calendar.component(.weekday, from: today)
        let daysToMonday = (currentWeekday == 1 ? -6 : 2 - currentWeekday)
        let thisMonday = calendar.date(byAdding: .day, value: daysToMonday, to: today)!
        
        var generatedWeeks: [[Date]] = []
        // Generate 8 weeks back and 8 weeks forward (~60 days each way)
        for weekOffset in -8...8 {
            let weekStart = calendar.date(byAdding: .day, value: weekOffset * 7, to: thisMonday)!
            let weekDays = (0..<7).compactMap { dayOffset in
                calendar.date(byAdding: .day, value: dayOffset, to: weekStart)
            }
            generatedWeeks.append(weekDays)
        }
        self.weeks = generatedWeeks
    }
    
    @State private var visibleWeekIndex: Int? = 8 // Default to today's week (center of range)
    
    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 0) {
                ForEach(0..<weeks.count, id: \.self) { weekIndex in
                    HStack(spacing: 8) {
                        ForEach(weeks[weekIndex], id: \.self) { date in
                            let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
                            
                            Button(action: {
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedDate = date
                                }
                            }) {
                                VStack(spacing: 2) {
                                    Text(date.formatted(.dateTime.day()))
                                        .font(.system(size: 20, weight: .black))
                                        .foregroundColor(isSelected ? .white : Theme.Colors.onSurfaceVariant.opacity(0.5))
                                    
                                    Text(date.formatted(.dateTime.weekday(.abbreviated)).uppercased())
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(isSelected ? dataManager.primaryColor : Theme.Colors.onSurfaceVariant.opacity(0.5))
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 56) // Aggressively shorter
                                .background(isSelected ? Theme.Colors.surfaceContainerLow : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 24)
                    .containerRelativeFrame(.horizontal)
                    .id(weekIndex)
                }
            }
            .scrollTargetLayout()
        }
        .scrollPosition(id: $visibleWeekIndex)
        .scrollTargetBehavior(.paging)
        .onChange(of: visibleWeekIndex) { old, new in
            if let newIndex = new, old != new {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                
                // When swiping to a new week, select the first day (Monday) of that week
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    selectedDate = weeks[newIndex][0]
                }
            }
        }
    }
}

#Preview {
    DateRailView(selectedDate: .constant(Date()))
        .background(Theme.Colors.surface)
}

