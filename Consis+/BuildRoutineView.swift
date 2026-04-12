import SwiftUI

public struct BuildRoutineView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: WorkoutDataManager
    @State private var expandedDayId: Int? = Calendar.current.component(.weekday, from: Date())
    
    private let weekdays = [
        (1, "SUNDAY"), (2, "MONDAY"), (3, "TUESDAY"), 
        (4, "WEDNESDAY"), (5, "THURSDAY"), (6, "FRIDAY"), (7, "SATURDAY")
    ]
    
    public var body: some View {
        ZStack {
            Theme.Colors.surface.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 0) {
                // Header (Glass Pinned)
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("WEEKLY BLUEPRINT")
                            .technicalMicroCopy()
                            .foregroundColor(dataManager.primaryColor)
                        Text("ROUTINE BUILDER")
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
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 20)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(weekdays, id: \.0) { id, name in
                            RoutineDayRow(
                                dayId: id,
                                dayName: name,
                                isExpanded: expandedDayId == id,
                                onToggle: {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        if expandedDayId == id {
                                            expandedDayId = nil
                                        } else {
                                            expandedDayId = id
                                        }
                                    }
                                }
                            )
                        }
                        
                        Spacer(minLength: 120) // Space for bottom button
                    }
                    .padding(.horizontal, 24)
                }
            }
            
            // Fixed Bottom Lock Button
            VStack {
                Spacer()
                Button(action: { dismiss() }) {
                    HStack {
                        Image(systemName: "lock.fill")
                        Text("LOCK ROUTINE")
                    }
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(dataManager.primaryColor)
                    .clipShape(Capsule())
                    .shadow(color: dataManager.primaryColor.opacity(0.3), radius: 15, x: 0, y: 8)
                }
                .padding(.horizontal, 48)
                .padding(.bottom, 32)
                .background(
                    LinearGradient(colors: [.clear, Theme.Colors.surface.opacity(0.8), Theme.Colors.surface], startPoint: .top, endPoint: .bottom)
                        .ignoresSafeArea()
                        .frame(height: 150)
                )
            }
        }
    }
}

struct RoutineDayRow: View {
    let dayId: Int
    let dayName: String
    let isExpanded: Bool
    let onToggle: () -> Void
    @EnvironmentObject var dataManager: WorkoutDataManager
    
    // Aesthetic accent (Green for active selection as requested)
    private let activeGreen = Color(hex: "#30D158")
    
    var body: some View {
        VStack(spacing: 0) {
            // Main Row Header
            Button(action: onToggle) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(dayName)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(isExpanded ? .white : Theme.Colors.onSurfaceVariant)
                        
                        if let entry = dataManager.routine[dayId], !entry.muscles.isEmpty {
                            Text(entry.muscles.map({ $0.name }).joined(separator: " • "))
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(dataManager.primaryColor.opacity(0.6))
                        } else {
                            Text("REST DAY")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(Theme.Colors.onSurfaceVariant.opacity(0.4))
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(isExpanded ? dataManager.primaryColor : Theme.Colors.onSurfaceVariant.opacity(0.3))
                }
                .padding(20)
                .background(isExpanded ? Theme.Colors.surfaceContainerHigh : Theme.Colors.surfaceContainerLow.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .ghostBorder(radius: 24, opacity: isExpanded ? 0.3 : 0.1)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expanded Muscle Selection Grid
            if isExpanded {
                VStack(spacing: 20) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: 12) {
                        ForEach(dataManager.availableParts) { part in
                            MuscleToggleItem(
                                part: part,
                                isSelected: dataManager.routine[dayId]?.muscles.contains(where: { $0.name == part.name }) ?? false,
                                activeColor: activeGreen
                            ) {
                                togglePart(part)
                            }
                        }
                    }
                    .padding(.top, 12)
                    
                    // Row Actions: Remove & Tick
                    HStack(spacing: 12) {
                        Button(action: {
                            withAnimation { dataManager.saveRoutineDay(dayId: dayId, muscles: []) }
                        }) {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.6))
                                .frame(width: 56, height: 56)
                                .background(Theme.Colors.surfaceContainerLowest)
                                .clipShape(Circle())
                        }
                        
                        Button(action: onToggle) {
                            HStack {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 18, weight: .bold))
                                 Text("SAVE CHANGES")
                                    .font(.system(size: 14, weight: .black, design: .rounded))
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(activeGreen)
                            .clipShape(Capsule())
                            .shadow(color: activeGreen.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                    }
                }
                .padding(20)
                .background(Theme.Colors.surfaceContainerHigh)
                .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 24, bottomTrailingRadius: 24))
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
    
    private func togglePart(_ part: MusclePart) {
        let entry = dataManager.routine[dayId] ?? RoutineEntry(muscles: [], exercises: [])
        var currentMuscles = entry.muscles
        if let index = currentMuscles.firstIndex(where: { $0.name == part.name }) {
            currentMuscles.remove(at: index)
        } else {
            currentMuscles.append(part)
        }
        dataManager.saveRoutineDay(dayId: dayId, muscles: currentMuscles)
        
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

struct MuscleToggleItem: View {
    let part: MusclePart
    let isSelected: Bool
    let activeColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: part.icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.4))
                Text(part.name)
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.4))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(isSelected ? activeColor : Theme.Colors.surfaceContainerLowest.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    BuildRoutineView()
        .environmentObject(WorkoutDataManager(modelContext: nil))
}
