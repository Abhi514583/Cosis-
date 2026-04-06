import SwiftUI

public struct DateRailView: View {
    @EnvironmentObject var dataManager: WorkoutDataManager
    @Binding var selectedDate: Date
    
    // Generate fixed Sunday-Saturday weeks
    private let weeks: [[Date]] = {
        var calendar = Calendar.current
        calendar.firstWeekday = 1 // Sunday
        let today = calendar.startOfDay(for: Date())
        
        // Find the Sunday of THIS week
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        let startOfThisWeek = calendar.date(from: components) ?? today
        
        return (-8...8).map { weekOffset in
            let weekStart = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: startOfThisWeek)!
            return (0...6).map { calendar.date(byAdding: .day, value: $0, to: weekStart)! }
        }
    }()
    
    @State private var visibleWeekIndex: Int?
    
    public var body: some View {
        VStack(spacing: 0) {
            // 7-DAY RAIL (Horizontally Stationary)
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 0) {
                    ForEach(0..<weeks.count, id: \.self) { weekIndex in
                        HStack(spacing: 12) { // Adjusted for tighter fit: 12 is the sweet spot
                            ForEach(weeks[weekIndex], id: \.self) { date in
                                DayButton(date: date, isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate)) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedDate = date
                                    }
                                }
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
            .onChange(of: selectedDate) { _, newDate in
                // LOG-TO-RAIL SYNC: Move the rail when the log pager crosses a week boundary
                if let targetWeekIndex = weekIndex(for: newDate), targetWeekIndex != visibleWeekIndex {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        visibleWeekIndex = targetWeekIndex
                    }
                }
            }
            .onChange(of: visibleWeekIndex) { old, new in
                // RAIL-TO-LOG SYNC: PARALLEL DAY SELECTION
                if let newIndex = new, old != new {
                    let calendar = Calendar.current
                    let newWeek = weeks[newIndex]
                    
                    // Find the day-of-week index (0-6) of the current selection
                    let dayOfWeek = calendar.component(.weekday, from: selectedDate)
                    
                    // Find the corresponding day in the new week (1=Sunday, 2=Monday...)
                    if let parallelDate = newWeek.first(where: { calendar.component(.weekday, from: $0) == dayOfWeek }) {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            selectedDate = parallelDate
                        }
                    }
                }
            }
            .onAppear {
                if visibleWeekIndex == nil {
                    visibleWeekIndex = weekIndex(for: selectedDate) ?? 8
                }
            }
        }
    }
    
    private func weekIndex(for date: Date) -> Int? {
        let calendar = Calendar.current
        return weeks.firstIndex(where: { week in
            week.contains { calendar.isDate($0, inSameDayAs: date) }
        })
    }
}

// Internal component for the day buttons in the rail
struct DayButton: View {
    let date: Date
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var dataManager: WorkoutDataManager
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(date.formatted(.dateTime.day()))
                    .font(.system(size: 24, weight: .black))
                    .foregroundColor(isSelected ? .white : Theme.Colors.onSurfaceVariant.opacity(0.4))
                    .contentTransition(.numericText())
                
                Text(date.formatted(.dateTime.weekday(.abbreviated)).uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(isSelected ? dataManager.primaryColor : Theme.Colors.onSurfaceVariant.opacity(0.4))
            }
            .frame(width: 48, height: 72) // Slightly narrower to fit better
            .background(isSelected ? Theme.Colors.surfaceContainerLow : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// Subtle scale effect on tap
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(.interactiveSpring(), value: configuration.isPressed)
    }
}

#Preview {
    DateRailView(selectedDate: .constant(Date()))
        .background(Theme.Colors.surface)
        .environmentObject(WorkoutDataManager())
}
