import SwiftUI

public struct HomeWorkoutLogView: View {
    @EnvironmentObject var dataManager: WorkoutDataManager
    @Binding var selectedDate: Date
    var onQuickLog: ((Exercise) -> Void)? = nil
    
    @State private var dotOffset: CGSize = .zero
    @AppStorage("userName") private var userName: String = "Abhi's"
    
    @State private var isEditingName = false
    @State private var tempName = ""
    @FocusState private var isNameFocused: Bool
    
    public var body: some View {
        GeometryReader { geo in
            ZStack {
                Theme.Colors.surface.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // PINNED HEADER (DATE & HEART)
                    HStack(spacing: 12) {
                        Text(selectedDate.formatted(.dateTime.day()))
                            .font(.system(size: 80, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .contentTransition(.numericText())
                        
                        // Glowing Dynamic Accent Heart
                        Image(systemName: "heart.fill")
                            .font(.system(size: 14))
                            .foregroundColor(dataManager.accentColor)
                            .shadow(color: dataManager.accentColor.opacity(0.8), radius: 12, x: 0, y: 0)
                            .shadow(color: dataManager.accentColor.opacity(0.4), radius: 20, x: 0, y: 0)
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
                            .onTapGesture { jumpToToday() }
                            .zIndex(100)
                        
                        Spacer()
                        
                        Button(action: {
                            tempName = userName
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                isEditingName = true
                            }
                        }) {
                            VStack(spacing: -2) {
                                Text(userName)
                                    .font(.system(size: 20, weight: .black, design: .rounded))
                                    .foregroundColor(dataManager.primaryColor)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(1)
                                
                                Text("Logger")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(Theme.Colors.onSurfaceVariant)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .frame(maxWidth: 130)
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: -2) {
                            Text(selectedDate.formatted(.dateTime.month().day()))
                                .font(.system(size: 20, weight: .black, design: .rounded))
                                .foregroundColor(dataManager.primaryColor.opacity(0.8))
                                .contentTransition(.numericText())
                            Text(selectedDate.formatted(.dateTime.year()))
                                .font(.system(size: 24, weight: .black, design: .rounded))
                                .foregroundColor(Theme.Colors.onSurfaceVariant.opacity(0.3))
                                .contentTransition(.numericText())
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Theme.Colors.surface)
                    .zIndex(1) 
                    
                    // FIXED HORIZONTAL RAIL + PAGER SECTION
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 8) {
                            DateRailView(selectedDate: $selectedDate)
                                .padding(.top, 4)
                            
                            TabView(selection: $selectedDate) {
                                ForEach(generateDateRange(), id: \.self) { date in
                                    DailyLogView(date: date, onQuickLog: onQuickLog)
                                        .tag(date)
                                }
                            }
                            .tabViewStyle(.page(indexDisplayMode: .never))
                            .frame(height: geo.size.height * 0.82)
                        }
                    }
                    .frame(height: geo.size.height * 0.90) 
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedDate)
                
                // Name Editing Glass Overlay
                if isEditingName {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring()) {
                                userName = tempName.isEmpty ? "Abhi's" : tempName
                                isEditingName = false
                            }
                            isNameFocused = false
                        }
                    
                    VStack {
                        HStack(spacing: 16) {
                            TextField("Enter your name", text: $tempName)
                                .focused($isNameFocused)
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.leading)
                                .submitLabel(.done)
                                .onSubmit {
                                    withAnimation(.spring()) {
                                        userName = tempName.isEmpty ? "Abhi's" : tempName
                                        isEditingName = false
                                    }
                                }
                            
                            Button(action: {
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                                withAnimation(.spring()) {
                                    userName = tempName.isEmpty ? "Abhi's" : tempName
                                    isEditingName = false
                                }
                                isNameFocused = false
                            }) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(dataManager.primaryColor)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 28)
                                .fill(Theme.Colors.surfaceContainerHigh.opacity(0.7))
                                .background(.ultraThinMaterial)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                        .overlay(
                            RoundedRectangle(cornerRadius: 28)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.4), radius: 30, x: 0, y: 15)
                        .padding(.horizontal, 24)
                        
                        Spacer()
                    }
                    .padding(.top, 80)
                    .transition(.move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: 0.9)))
                    .zIndex(200)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isNameFocused = true
                        }
                    }
                }
            }
        }
    }
    
    // Generate ±60 days range for the paging system
    private func generateDateRange() -> [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (-60...60).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: today)
        }
    }
    
    private func jumpToToday() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            selectedDate = Calendar.current.startOfDay(for: Date())
        }
    }
}

// Subview for the daily log content
struct DailyLogView: View {
    let date: Date
    var onQuickLog: ((Exercise) -> Void)? = nil
    @EnvironmentObject var dataManager: WorkoutDataManager
    @State private var isExerciseListVisible = false
    
    // Computed daily stats
    private var dailyMuscleParts: [MusclePart] {
        dataManager.parts(for: date)
    }
    
    private var dailyWorkouts: [(name: String, sets: [WorkoutSet])] {
        let weekday = Calendar.current.component(.weekday, from: date)
        switch weekday {
        case 2, 5: return [
            ("Barbell Bench Press", [WorkoutSet(setNumber: 1, reps: 8, weight: 135), WorkoutSet(setNumber: 2, reps: 6, weight: 155)]),
            ("Incline Dumbbell Press", [WorkoutSet(setNumber: 1, reps: 10, weight: 65)])
        ]
        case 3: return [("Deadlift", [WorkoutSet(setNumber: 1, reps: 5, weight: 225)]), ("Pull-ups", [WorkoutSet(setNumber: 1, reps: 12, weight: 0)])]
        case 4, 7: return [("Squats", [WorkoutSet(setNumber: 1, reps: 10, weight: 185)]), ("Leg Press", [WorkoutSet(setNumber: 1, reps: 15, weight: 360)])]
        case 6: return [("Overhead Press", [WorkoutSet(setNumber: 1, reps: 8, weight: 95)]), ("Bicep Curls", [WorkoutSet(setNumber: 1, reps: 12, weight: 35)])]
        default: return []
        }
    }
    
    private var displayWorkouts: [(name: String, sets: [WorkoutSet])] {
        let isToday = Calendar.current.isDateInToday(date)
        var merged = dailyWorkouts
        
        if isToday, let session = dataManager.activeSession {
            var activeExerciseNames = Set<String>()
            
            // Override templated exercises with logged ones
            for i in 0..<merged.count {
                if let activeLog = session.exerciseLogs.first(where: { $0.exercise.name == merged[i].name }) {
                    merged[i].sets = activeLog.sets
                    activeExerciseNames.insert(merged[i].name)
                } else {
                    merged[i].sets = [] // Show empty if not started
                }
            }
            
            // Add any extra exercises they logged outside the template
            for log in session.exerciseLogs {
                if !activeExerciseNames.contains(log.exercise.name) {
                    merged.append((name: log.exercise.name, sets: log.sets))
                }
            }
        }
        return merged
    }

    var body: some View {
        VStack(spacing: 16) {
            if dailyMuscleParts.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.system(size: 48))
                        .foregroundColor(dataManager.primaryColor)
                    Text("REST DAY").font(.system(size: 24, weight: .black, design: .rounded)).foregroundColor(.white)
                    Text("Recovery is where the growth happens.").font(Typography.bodySmall).foregroundColor(Theme.Colors.onSurfaceVariant).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity).frame(height: 300)
                .background(Theme.Colors.surfaceContainerLow).clipShape(RoundedRectangle(cornerRadius: 32)).padding(.horizontal, 24).padding(.top, 8)
            } else {
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { isExerciseListVisible.toggle() }
                }) {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("TODAY'S FOCUS").technicalMicroCopy().foregroundColor(dataManager.primaryColor.opacity(0.8))
                                Text(dailyMuscleParts.map({ $0.name }).joined(separator: " & ").uppercased()).font(.system(size: 32, weight: .black, design: .rounded)).foregroundColor(.white).fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer()
                            Image(systemName: isExerciseListVisible ? "chevron.up.circle.fill" : "chevron.down.circle.fill").font(.system(size: 32)).foregroundColor(dataManager.primaryColor)
                        }
                        HStack(spacing: 8) {
                            Label("\(dailyWorkouts.count) EXERCISES", systemImage: "dumbbell.fill")
                            Text("•")
                            Label("45 MINS", systemImage: "clock.fill")
                        }.font(Typography.labelSmall).foregroundColor(Theme.Colors.onSurfaceVariant)
                    }
                    .padding(32).frame(maxWidth: .infinity, alignment: .leading)
                    .background(ZStack { Theme.Colors.surfaceContainerHigh; LinearGradient(colors: [dataManager.primaryColor.opacity(0.05), .clear], startPoint: .topLeading, endPoint: .bottomTrailing) })
                    .clipShape(RoundedRectangle(cornerRadius: 32)).ghostBorder(radius: 32).shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                }
                .buttonStyle(ScaleButtonStyle()).padding(.horizontal, 24).padding(.top, 8)
                
                if isExerciseListVisible {
                    VStack(spacing: 12) {
                        ForEach(displayWorkouts, id: \.name) { workout in
                            WorkoutLogCard(exerciseName: workout.name, sets: workout.sets)
                                .onTapGesture {
                                    if let ex = dataManager.exerciseLibrary.first(where: { $0.name == workout.name }) {
                                        onQuickLog?(ex)
                                    } else {
                                        let fallback = Exercise(name: workout.name, musclePartName: "CUSTOM")
                                        onQuickLog?(fallback)
                                    }
                                }
                        }
                    }.padding(.top, 8)
                }
            }
            Spacer(minLength: 140)
        }
    }
}

#Preview {
    HomeWorkoutLogView(selectedDate: .constant(Date()))
        .environmentObject(WorkoutDataManager())
}
