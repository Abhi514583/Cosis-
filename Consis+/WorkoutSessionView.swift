import SwiftUI

public struct WorkoutSessionView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: WorkoutDataManager
    
    // Flow State: 0 = Muscles, 1 = Exercises, 2 = Active Logger
    @State private var sessionStep: Int = 0
    @State private var selectedMuscleParts: Set<String> = []
    @State private var selectedExercises: Set<Exercise> = []
    
    // Active Session State
    @State private var activeLog: [ExerciseLog] = []
    
    private let activeGreen = Color(hex: "#30D158")
    
    public var body: some View {
        ZStack {
            Theme.Colors.surface.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header (Dynamic based on step)
                HeaderView(step: sessionStep, onDismiss: { dismiss() }, onBack: {
                    withAnimation(.spring()) { sessionStep -= 1 }
                })
                
                Group {
                    switch sessionStep {
                    case 0:
                        MuscleSelectionView(
                            selectedParts: $selectedMuscleParts,
                            availableParts: dataManager.availableParts,
                            onNext: { withAnimation(.spring()) { sessionStep = 1 } }
                        )
                    case 1:
                        ExerciseSelectionView(
                            muscleParts: selectedMuscleParts,
                            selectedExercises: $selectedExercises,
                            exerciseLibrary: dataManager.exerciseLibrary,
                            onStart: startWorkout
                        )
                    case 2:
                        ActiveLoggerView(logs: $activeLog, onFinish: finishWorkout)
                    default:
                        Text("Unknown Step")
                    }
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            }
        }
    }
    
    private func startWorkout() {
        // Initialize the active logs with 1 empty set for each selected exercise
        activeLog = selectedExercises.map { exercise in
            ExerciseLog(exercise: exercise, sets: [WorkoutSet(setNumber: 1, reps: 0, weight: 0)])
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            sessionStep = 2
        }
    }
    
    private func finishWorkout() {
        // In a real app, we'd save this to a database
        dataManager.activeSession = nil 
        dismiss()
    }
}

// MARK: - Subviews

struct HeaderView: View {
    let step: Int
    let onDismiss: () -> Void
    let onBack: () -> Void
    
    var title: String {
        switch step {
        case 0: return "CHOOSE MUSCLES"
        case 1: return "PICK EXERCISES"
        case 2: return "ACTIVE SESSION"
        default: return "WORKOUT"
        }
    }
    
    var body: some View {
        HStack {
            if step > 0 && step < 2 {
                Button(action: onBack) {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(Theme.Colors.onSurfaceVariant.opacity(0.4))
                }
            }
            
            Text(title)
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(Theme.Colors.onSurfaceVariant.opacity(0.4))
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 16)
    }
}

struct MuscleSelectionView: View {
    @Binding var selectedParts: Set<String>
    let availableParts: [MusclePart]
    let onNext: () -> Void
    
    private let activeGreen = Color(hex: "#30D158")
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 16) {
                    ForEach(availableParts) { part in
                        let isSelected = selectedParts.contains(part.name)
                        Button(action: {
                            if isSelected {
                                selectedParts.remove(part.name)
                            } else {
                                selectedParts.insert(part.name)
                            }
                        }) {
                            VStack(spacing: 12) {
                                Image(systemName: part.icon)
                                    .font(.system(size: 32))
                                Text(part.name)
                                    .font(.system(size: 12, weight: .black, design: .rounded))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 120)
                            .background(isSelected ? activeGreen : Theme.Colors.surfaceContainerHigh.opacity(0.5))
                            .foregroundColor(isSelected ? .black : .white)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            .ghostBorder(radius: 24, opacity: isSelected ? 0.4 : 0.1)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 120)
            }
            
            if !selectedParts.isEmpty {
                Button(action: onNext) {
                    HStack {
                        Text("NEXT")
                        Image(systemName: "arrow.right")
                    }
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(activeGreen)
                    .clipShape(Capsule())
                    .padding(.horizontal, 48)
                    .padding(.bottom, 32)
                    .shadow(color: activeGreen.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
}

struct ExerciseSelectionView: View {
    let muscleParts: Set<String>
    @Binding var selectedExercises: Set<Exercise>
    let exerciseLibrary: [Exercise]
    let onStart: () -> Void
    
    private let activeGreen = Color(hex: "#30D158")
    
    var filteredExercises: [Exercise] {
        exerciseLibrary.filter { muscleParts.contains($0.musclePartName) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(filteredExercises) { exercise in
                        let isSelected = selectedExercises.contains(exercise)
                        Button(action: {
                            if isSelected {
                                selectedExercises.remove(exercise)
                            } else {
                                selectedExercises.insert(exercise)
                            }
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(exercise.musclePartName)
                                        .technicalMicroCopy()
                                        .foregroundColor(.white.opacity(0.4))
                                    Text(exercise.name)
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                }
                                Spacer()
                                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 24))
                                    .foregroundColor(isSelected ? activeGreen : .white.opacity(0.2))
                            }
                            .padding(20)
                            .background(isSelected ? activeGreen.opacity(0.1) : Theme.Colors.surfaceContainerLow.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .ghostBorder(radius: 20, opacity: isSelected ? 0.3 : 0.1)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 120)
            }
            
            if !selectedExercises.isEmpty {
                Button(action: onStart) {
                    Text("START WORKOUT")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(activeGreen)
                        .clipShape(Capsule())
                        .padding(.horizontal, 48)
                        .padding(.bottom, 32)
                        .shadow(color: activeGreen.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
}

struct ActiveLoggerView: View {
    @Binding var logs: [ExerciseLog]
    let onFinish: () -> Void
    
    private let activeGreen = Color(hex: "#30D158")
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    ForEach($logs) { $log in
                        ActiveExerciseCard(log: $log)
                    }
                    
                    Spacer(minLength: 120)
                }
                .padding(.horizontal, 24)
            }
            
            Button(action: onFinish) {
                Text("FINISH SESSION")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color(hex: "#C4524D")) // Crimson for finish
                    .clipShape(Capsule())
                    .padding(.horizontal, 48)
                    .padding(.bottom, 32)
                    .shadow(color: Color(hex: "#C4524D").opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .background(
                LinearGradient(colors: [.clear, Theme.Colors.surface], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
            )
        }
    }
}

struct ActiveExerciseCard: View {
    @Binding var log: ExerciseLog
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(log.exercise.name.uppercased())
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Button(action: addSet) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Theme.Colors.primary.opacity(0.6))
                }
            }
            
            VStack(spacing: 12) {
                ForEach($log.sets) { $set in
                    ActiveSetRow(workoutSet: $set) {
                        removeSet(set)
                    }
                }
            }
        }
        .padding(24)
        .background(Theme.Colors.surfaceContainerHigh)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .ghostBorder(radius: 24)
    }
    
    private func addSet() {
        let newNum = (log.sets.last?.setNumber ?? 0) + 1
        log.sets.append(WorkoutSet(setNumber: newNum, reps: 0, weight: 0))
    }
    
    private func removeSet(_ workoutSet: WorkoutSet) {
        if log.sets.count > 1 {
            log.sets.removeAll(where: { $0.id == workoutSet.id })
        }
    }
}

struct ActiveSetRow: View {
    @Binding var workoutSet: WorkoutSet
    var onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Text("\(workoutSet.setNumber)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.3))
                .frame(width: 20)
            
            // Weight Input (Mechanical Roll)
            HStack {
                TextField("0", value: $workoutSet.weight, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .contentTransition(.numericText())
                Text("KG")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.2))
            }
            .padding(.horizontal, 12)
            .frame(height: 56)
            .background(Theme.Colors.surfaceContainerLowest)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .ghostBorder(radius: 16, opacity: 0.1)
            
            Image(systemName: "xmark")
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.1))
            
            // Reps Input (Mechanical Roll)
            HStack {
                TextField("0", value: $workoutSet.reps, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .contentTransition(.numericText())
                Text("REPS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.2))
            }
            .padding(.horizontal, 12)
            .frame(height: 56)
            .background(Theme.Colors.surfaceContainerLowest)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .ghostBorder(radius: 16, opacity: 0.1)
            
            Button(action: onDelete) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.error.opacity(0.4))
            }
            .frame(width: 44, height: 56)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: workoutSet.weight)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: workoutSet.reps)
    }
}

#Preview {
    WorkoutSessionView()
        .environmentObject(WorkoutDataManager())
}
