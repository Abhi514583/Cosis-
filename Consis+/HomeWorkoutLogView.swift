import SwiftUI

public struct HomeWorkoutLogView: View {
    @State private var selectedDate = Date()
    @State private var isExerciseListVisible = true
    @State private var dotOffset: CGSize = .zero
    
    private let pillColors: [Color] = [
        Color(hex: "#FF453A"), // Red
        Color(hex: "#0A84FF"), // Blue
        Color(hex: "#30D158"), // Green
        Color(hex: "#FF9F0A"), // Orange
        Color(hex: "#BF5AF2")  // Purple
    ]
    
    // Computed properties for dynamic daily stats
    private var dailyMuscleGroups: [String] {
        let weekday = Calendar.current.component(.weekday, from: selectedDate)
        switch weekday {
        case 1: return [] // Sunday - Rest
        case 2: return ["Chest", "Triceps", "Shoulders"] // Monday
        case 3: return ["Back", "Biceps", "Forearms"] // Tuesday
        case 4: return ["Legs", "Abs"] // Wednesday
        case 5: return ["Chest", "Back"] // Thursday
        case 6: return ["Shoulders", "Arms"] // Friday
        case 7: return ["Legs", "Abs"] // Saturday
        default: return []
        }
    }
    
    private var dailyWorkouts: [(name: String, sets: [WorkoutSet])] {
        let weekday = Calendar.current.component(.weekday, from: selectedDate)
        switch weekday {
        case 2, 5: // Chest days
            return [
                ("Barbell Bench Press", [
                    WorkoutSet(setNumber: 1, reps: 8, weight: 135),
                    WorkoutSet(setNumber: 2, reps: 8, weight: 135),
                    WorkoutSet(setNumber: 3, reps: 6, weight: 155, isPR: weekday == 5)
                ]),
                ("Incline Dumbbell Press", [
                    WorkoutSet(setNumber: 1, reps: 10, weight: 65),
                    WorkoutSet(setNumber: 2, reps: 10, weight: 65)
                ])
            ]
        case 3: // Back day
            return [
                ("Deadlift", [
                    WorkoutSet(setNumber: 1, reps: 5, weight: 225),
                    WorkoutSet(setNumber: 2, reps: 5, weight: 275),
                    WorkoutSet(setNumber: 3, reps: 5, weight: 315)
                ]),
                ("Pull-ups", [
                    WorkoutSet(setNumber: 1, reps: 12, weight: 0),
                    WorkoutSet(setNumber: 2, reps: 10, weight: 0)
                ])
            ]
        case 4, 7: // Leg days
            return [
                ("Squats", [
                    WorkoutSet(setNumber: 1, reps: 10, weight: 185),
                    WorkoutSet(setNumber: 2, reps: 10, weight: 205),
                    WorkoutSet(setNumber: 3, reps: 8, weight: 225)
                ]),
                ("Leg Press", [
                    WorkoutSet(setNumber: 1, reps: 15, weight: 360),
                    WorkoutSet(setNumber: 2, reps: 15, weight: 360)
                ])
            ]
        case 6: // Shoulders/Arms
            return [
                ("Overhead Press", [
                    WorkoutSet(setNumber: 1, reps: 8, weight: 95),
                    WorkoutSet(setNumber: 2, reps: 8, weight: 115)
                ]),
                ("Bicep Curls", [
                    WorkoutSet(setNumber: 1, reps: 12, weight: 35),
                    WorkoutSet(setNumber: 2, reps: 12, weight: 35)
                ])
            ]
        default: return []
        }
    }
    
    public var body: some View {
        GeometryReader { geo in
            ZStack {
                Theme.Colors.surface.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // PINNED HEADER SECTION (Strictly ~15% bounds)
                    VStack(spacing: 0) {
                        // Custom Slot Machine Date Header perfectly aligned tight to the absolute crest
                        HStack(alignment: .center) {
                            HStack(spacing: 8) {
                                Text(selectedDate.formatted(.dateTime.day(.twoDigits)))
                                    .font(.system(size: 64, weight: .heavy, design: .rounded))
                                    .foregroundColor(.white)
                                    .contentTransition(.numericText(value: selectedDate.timeIntervalSince1970))
                                
                                // Glowing Cyan Sky-Blue Interactive Dot
                                Circle()
                                    .fill(Color.cyan)
                                    .frame(width: 14, height: 14)
                                    .shadow(color: Color.cyan.opacity(0.8), radius: 8, x: 0, y: 0)
                                    .shadow(color: Color.cyan.opacity(0.4), radius: 16, x: 0, y: 0)
                                    .offset(x: dotOffset.width, y: 8 + dotOffset.height) 
                                    .gesture(
                                        DragGesture()
                                            .onChanged { gesture in
                                                dotOffset = gesture.translation
                                            }
                                            .onEnded { _ in
                                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                                generator.impactOccurred()
                                                
                                                withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                                                    dotOffset = .zero
                                                }
                                            }
                                    )
                                    .zIndex(100)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: -2) {
                                Text(selectedDate.formatted(.dateTime.month(.wide)) + " " + selectedDate.formatted(.dateTime.day(.twoDigits)))
                                    .font(.system(size: 16, weight: .bold)) 
                                    .foregroundColor(Theme.Colors.onSurfaceVariant)
                                
                                Text(selectedDate.formatted(.dateTime.year()))
                                    .font(.system(size: 16, weight: .bold)) 
                                    .foregroundColor(Theme.Colors.outlineVariant)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 0) 
                        
                        Spacer()
                        
                        // Passed down robust binding for haptics and selection
                        DateRailView(selectedDate: $selectedDate)
                            .padding(.top, 0)
                    }
                    .padding(.bottom, 4)
                    .frame(height: geo.size.height * 0.16)
                    .background(Theme.Colors.surface)
                    .zIndex(1) 
                    
                    // SCROLLABLE CONTENT SECTION (Takes 85%)
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            if dailyMuscleGroups.isEmpty {
                                // Rest Day Card
                                VStack(spacing: 12) {
                                    Image(systemName: "cup.and.saucer.fill")
                                        .font(.system(size: 48))
                                        .foregroundColor(Theme.Colors.primary)
                                        .shadow(color: Theme.Colors.primary.opacity(0.3), radius: 20)
                                    
                                    Text("REST DAY")
                                        .font(.system(size: 24, weight: .black, design: .rounded))
                                        .foregroundColor(.white)
                                    
                                    Text("Recovery is where the growth happens.")
                                        .font(Typography.bodySmall)
                                        .foregroundColor(Theme.Colors.onSurfaceVariant)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: geo.size.height * 0.5)
                                .background(Theme.Colors.surfaceContainerLow)
                                .clipShape(RoundedRectangle(cornerRadius: 32))
                                .padding(.horizontal, 24)
                                .padding(.top, 24)
                            } else {
                                // Master Focus Card - High tier interaction
                                Button(action: {
                                    let generator = UISelectionFeedbackGenerator()
                                    generator.selectionChanged()
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        isExerciseListVisible.toggle()
                                    }
                                }) {
                                    VStack(alignment: .leading, spacing: 20) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("TODAY'S FOCUS")
                                                    .technicalMicroCopy()
                                                    .foregroundColor(Theme.Colors.primary.opacity(0.8))
                                                
                                                Text(dailyMuscleGroups.joined(separator: " & ").uppercased())
                                                    .font(.system(size: 32, weight: .black, design: .rounded))
                                                    .foregroundColor(.white)
                                                    .fixedSize(horizontal: false, vertical: true)
                                            }
                                            Spacer()
                                            Image(systemName: isExerciseListVisible ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                                                .font(.system(size: 32))
                                                .foregroundColor(Theme.Colors.primary)
                                        }
                                        
                                        HStack(spacing: 8) {
                                            Label("\(dailyWorkouts.count) EXERCISES", systemImage: "dumbbell.fill")
                                            Text("•")
                                            Label("45 MINS", systemImage: "clock.fill")
                                        }
                                        .font(Typography.labelSmall)
                                        .foregroundColor(Theme.Colors.onSurfaceVariant)
                                        
                                        // Preview Pills inside card
                                        HStack(spacing: 8) {
                                            ForEach(Array(dailyMuscleGroups.prefix(3).enumerated()), id: \.offset) { index, group in
                                                Text(group)
                                                    .font(.system(size: 10, weight: .bold))
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 4)
                                                    .background(Theme.Colors.primary.opacity(0.1))
                                                    .foregroundColor(Theme.Colors.primary)
                                                    .clipShape(Capsule())
                                            }
                                        }
                                    }
                                    .padding(32)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(
                                        ZStack {
                                            Theme.Colors.surfaceContainerHigh
                                            // Subtle gradient highlight
                                            LinearGradient(colors: [Theme.Colors.primary.opacity(0.05), .clear], startPoint: .topLeading, endPoint: .bottomTrailing)
                                        }
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 32))
                                    .ghostBorder(radius: 32)
                                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.horizontal, 24)
                                .padding(.top, 16)
                                
                                if isExerciseListVisible {
                                    VStack(spacing: 12) {
                                        ForEach(dailyWorkouts, id: \.name) { workout in
                                            WorkoutLogCard(exerciseName: workout.name, sets: workout.sets)
                                                .transition(.asymmetric(
                                                    insertion: .move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: 0.95)),
                                                    removal: .opacity.combined(with: .scale(scale: 0.9))
                                                ))
                                        }
                                    }
                                    .padding(.top, 8)
                                }
                            }
                            
                            Spacer(minLength: 140) 
                        }
                    }
                    .frame(height: geo.size.height * 0.84)
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedDate)
            .onChange(of: selectedDate) {
                // When selecting a new date, collapse the exercise list to keep UI clean
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExerciseListVisible = false
                }
            }
        }
    }
}

#Preview {
    HomeWorkoutLogView()
}

