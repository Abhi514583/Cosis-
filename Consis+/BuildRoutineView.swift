import SwiftUI

public struct BuildRoutineView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: WorkoutDataManager
    @State private var selectedDay: Int? = 2 // Default to Monday
    
    private let weekdays = [
        (2, "MON"), (3, "TUE"), (4, "WED"), (5, "THU"), (6, "FRI"), (7, "SAT"), (1, "SUN")
    ]
    
    public var body: some View {
        ZStack {
            Theme.Colors.surface.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 0) {
                // Header with Close
                HStack {
                    Text("ROUTINE BUILDER")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Theme.Colors.onSurfaceVariant.opacity(0.4))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 24)
                
                // TOP: COMPACT DAY RAIL
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(weekdays, id: \.0) { dayNum, dayAbbr in
                            DaySelectorChip(
                                label: dayAbbr,
                                isSelected: selectedDay == dayNum,
                                hasContent: !(dataManager.routine[dayNum]?.isEmpty ?? true),
                                accentColor: dataManager.accentColor
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedDay = dayNum
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 32)
                
                // VIEWPORT: CURRENT DAY SUMMARY
                VStack(alignment: .leading, spacing: 16) {
                    if let dayNum = selectedDay {
                        let dayName = weekdays.first(where: { $0.0 == dayNum })?.1 ?? ""
                        HStack {
                            Text("\(dayName) BLUEPRINT")
                                .technicalMicroCopy()
                                .foregroundColor(Theme.Colors.onSurfaceVariant)
                            Spacer()
                            if !(dataManager.routine[dayNum]?.isEmpty ?? true) {
                                Button(action: {
                                    withAnimation(.spring()) { dataManager.routine[dayNum] = [] }
                                }) {
                                    Label("CLEAR", systemImage: "trash.fill")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(Theme.Colors.error)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        if let parts = dataManager.routine[dayNum], !parts.isEmpty {
                            HStack(spacing: 8) {
                                ForEach(parts) { part in
                                    Text(part.name)
                                        .font(.system(size: 12, weight: .black))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(part.color.opacity(0.1))
                                        .foregroundColor(part.color)
                                        .clipShape(Capsule())
                                        .ghostBorder(radius: 20, opacity: 0.3)
                                }
                            }
                            .padding(.horizontal, 24)
                        } else {
                            Text("No muscle groups assigned.")
                                .font(Typography.bodySmall)
                                .foregroundColor(Theme.Colors.outlineVariant)
                                .padding(.horizontal, 24)
                        }
                    }
                }
                .frame(maxHeight: .infinity, alignment: .top)
                
                // BOTTOM: EXERCISE PARTS SHELF
                VStack(alignment: .leading, spacing: 16) {
                    Text("SELECT MUSCLE GROUPS")
                        .technicalMicroCopy()
                        .foregroundColor(Theme.Colors.onSurfaceVariant)
                        .padding(.horizontal, 24)
                    
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 16) {
                            ForEach(dataManager.availableParts) { part in
                                let isSelected = selectedDay != nil && (dataManager.routine[selectedDay!]?.contains(where: { $0.name == part.name }) ?? false)
                                
                                MultiSelectPartCard(part: part, isSelected: isSelected) {
                                    if let day = selectedDay {
                                        togglePart(part, for: day)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 120) // Critical space for the floating lock button
                    }
                }
                .frame(height: 340) // Weighted shelf height
                .background(Theme.Colors.surfaceContainerLow)
                .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                .ignoresSafeArea(edges: .bottom)
            }
            
            // LOCK ROUTINE FLOATING FOOTER
            VStack {
                Spacer()
                Button(action: { dismiss() }) {
                    Text("LOCK WEEKLY ROUTINE")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(dataManager.accentColor)
                        .clipShape(Capsule())
                        .shadow(color: dataManager.accentColor.opacity(0.4), radius: 15, x: 0, y: 8)
                }
                .padding(.horizontal, 48)
                .padding(.bottom, 40)
            }
        }
    }
    
    private func togglePart(_ part: MusclePart, for day: Int) {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
        
        var currentParts = dataManager.routine[day] ?? []
        if let index = currentParts.firstIndex(where: { $0.name == part.name }) {
            currentParts.remove(at: index)
        } else {
            currentParts.append(part)
        }
        dataManager.routine[day] = currentParts
    }
}

struct DaySelectorChip: View {
    let label: String
    let isSelected: Bool
    let hasContent: Bool
    let accentColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(label)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(isSelected ? .black : Theme.Colors.onSurfaceVariant)
                
                if hasContent {
                    Circle()
                        .fill(isSelected ? .black : accentColor)
                        .frame(width: 4, height: 4)
                }
            }
            .frame(width: 52, height: 64)
            .background(isSelected ? accentColor : Theme.Colors.surfaceContainerHigh)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: isSelected ? accentColor.opacity(0.3) : .clear, radius: 8)
        }
    }
}

struct MultiSelectPartCard: View {
    let part: MusclePart
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 8) {
                    Image(systemName: part.icon)
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? .white : part.color)
                    
                    Text(part.name)
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 90)
                .background(isSelected ? part.color : Theme.Colors.surfaceContainerHigh.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .ghostBorder(radius: 20, opacity: isSelected ? 0.3 : 0.1)
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .background(Circle().fill(.black.opacity(0.2)))
                        .padding(8)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }
}

#Preview {
    BuildRoutineView()
}
