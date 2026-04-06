import SwiftUI

public struct DateRailView: View {
    @Binding var selectedDate: Date
    private let weeks: [[Date]]
    
    public init(selectedDate: Binding<Date>) {
        self._selectedDate = selectedDate
        
        let today = Calendar.current.startOfDay(for: Date())
        var generatedWeeks: [[Date]] = []
        for weekOffset in 0..<4 {
            let weekStart = Calendar.current.date(byAdding: .day, value: weekOffset * 7, to: today)!
            let weekDays = (0..<7).compactMap { dayOffset in
                Calendar.current.date(byAdding: .day, value: dayOffset, to: weekStart)
            }
            generatedWeeks.append(weekDays)
        }
        self.weeks = generatedWeeks
    }
    
    @State private var visibleWeekIndex: Int? = 0
    
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
                                        .foregroundColor(isSelected ? Theme.Colors.primary : Theme.Colors.onSurfaceVariant.opacity(0.5))
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
            if new != nil {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            }
        }
    }
}

#Preview {
    DateRailView(selectedDate: .constant(Date()))
        .background(Theme.Colors.surface)
}

