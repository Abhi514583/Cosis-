import SwiftUI

public struct WorkoutSessionView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: WorkoutDataManager
    
    enum SessionPhase {
        case overview
        case selection
        case logging(Exercise)
    }
    
    @State private var phase: SessionPhase = .overview
    
    public var body: some View {
        ZStack {
            Theme.Colors.surface.ignoresSafeArea()
            
            switch phase {
            case .overview:
                ActiveWorkoutOverviewView(
                    onAddExercise: { withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { phase = .selection } },
                    onFinish: {
                        dataManager.activeSession = nil
                        dismiss()
                    }
                )
            case .selection:
                ExerciseSelectionFeedView(
                    onSelect: { ex in withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { phase = .logging(ex) } },
                    onClose: { withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { phase = .overview } }
                )
            case .logging(let ex):
                TableLoggerView(
                    exercise: ex,
                    onBack: { withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { phase = .overview } }
                )
            }
        }
        .onAppear {
            if dataManager.activeSession == nil {
                dataManager.activeSession = ActiveWorkoutSession(date: Date(), exerciseLogs: [])
            }
        }
    }
}

// MARK: - Phase 0: Active Overview

struct ActiveWorkoutOverviewView: View {
    @EnvironmentObject var dataManager: WorkoutDataManager
    let onAddExercise: () -> Void
    let onFinish: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Active Session")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Text("REC").font(.system(size: 12, weight: .bold)).foregroundColor(.red)
                Circle().fill(Color.red).frame(width: 8, height: 8)
            }
            .padding(.horizontal, 24).padding(.top, 24).padding(.bottom, 16)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    if let session = dataManager.activeSession, !session.exerciseLogs.isEmpty {
                        ForEach(session.exerciseLogs) { log in
                            PaintedLogCard(log: log)
                        }
                    } else {
                        VStack(spacing: 12) {
                            Spacer().frame(height: 60)
                            Image(systemName: "dumbbell.fill").font(.system(size: 48)).foregroundColor(.white.opacity(0.1))
                            Text("Workout Empty").font(.system(size: 18, weight: .bold)).foregroundColor(.gray)
                            Text("Add an exercise to start painting your canvas.").font(.system(size: 14)).foregroundColor(.white.opacity(0.4))
                        }
                    }
                    
                    Spacer().frame(height: 100)
                }
                .padding(.horizontal, 24).padding(.top, 16)
            }
            
            // Footer Actions
            VStack(spacing: 16) {
                Button(action: onAddExercise) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add Exercise")
                    }
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(Theme.Colors.surfaceContainerHigh)
                    .clipShape(Capsule())
                }
                
                Button(action: onFinish) {
                    Text("FINISH WORKOUT")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity).padding(.vertical, 18)
                        .background(Color(hex: "#30D158"))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 24).padding(.vertical, 16)
            .background(Theme.Colors.surface.ignoresSafeArea())
        }
    }
}

struct PaintedLogCard: View {
    let log: ExerciseLog
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(log.exercise.name).font(.system(size: 18, weight: .black, design: .rounded)).foregroundColor(.white)
                Spacer()
                Text("\(log.sets.count) SETS").font(.system(size: 12, weight: .bold)).foregroundColor(.white.opacity(0.7))
            }
            .padding(20)
            .background(Color.white.opacity(0.1))
            
            if !log.sets.isEmpty {
                VStack(spacing: 6) {
                    ForEach(log.sets) { s in
                        HStack {
                            Text("\(s.setNumber)").font(.system(size: 12, weight: .black)).foregroundColor(.white.opacity(0.5)).frame(width: 30, alignment: .leading)
                            Text("\(String(format: "%.1f", s.weight)) \(log.unit.rawValue)").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                            Spacer()
                            Text("\(s.reps) reps").font(.system(size: 14, weight: .bold)).foregroundColor(.white.opacity(0.5))
                        }.padding(.horizontal, 20).padding(.vertical, 6)
                    }
                }.padding(.bottom, 16).padding(.top, 8)
            }
        }
        .background(Theme.Colors.surfaceContainerHigh)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        // Paint it subtly with muscle color (defaulting to primary if we don't have the color easily accessible here)
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Theme.Colors.primary.opacity(0.3), lineWidth: 2))
    }
}

// MARK: - Phase 1: Selection

struct ExerciseSelectionFeedView: View {
    @EnvironmentObject var dataManager: WorkoutDataManager
    @State private var selectedMuscle: MusclePart?
    let onSelect: (Exercise) -> Void
    let onClose: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Select Exercise").font(.system(size: 24, weight: .bold, design: .rounded)).foregroundColor(.white)
                Spacer()
                Button(action: onClose) { Image(systemName: "xmark.circle.fill").font(.system(size: 24)).foregroundColor(Theme.Colors.surfaceContainerHighest) }
            }
            .padding(.horizontal, 24).padding(.top, 24).padding(.bottom, 16)
            
            // Segments
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(dataManager.availableParts) { part in
                        Text(part.name.capitalized).font(.system(size: 16, weight: selectedMuscle == part ? .bold : .medium))
                            .foregroundColor(selectedMuscle == part ? .white : .gray).padding(.vertical, 8).padding(.horizontal, 16)
                            .background(selectedMuscle == part ? Theme.Colors.surfaceContainerHigh : Color.clear).clipShape(Capsule())
                            .onTapGesture { withAnimation { selectedMuscle = part } }
                    }
                }.padding(.horizontal, 24)
            }.padding(.bottom, 12)
            
            Divider().background(Color.white.opacity(0.1))
            
            // Vertical Feed
            ScrollView {
                if let muscle = selectedMuscle {
                    LazyVStack(spacing: 12) {
                        ForEach(dataManager.exerciseLibrary.filter { $0.musclePartName == muscle.name }) { ex in
                            Button(action: { onSelect(ex) }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(ex.name).font(.system(size: 18, weight: .bold, design: .rounded)).foregroundColor(.white)
                                        Text(ex.musclePartName).font(.system(size: 10, weight: .bold)).foregroundColor(muscle.color).padding(.horizontal, 8).padding(.vertical, 4).background(muscle.color.opacity(0.15)).clipShape(Capsule())
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right").font(.system(size: 14, weight: .bold)).foregroundColor(.white.opacity(0.3))
                                }.padding(20).background(Theme.Colors.surfaceContainerLow).clipShape(RoundedRectangle(cornerRadius: 24))
                            }.buttonStyle(PlainButtonStyle())
                        }
                    }.padding(24)
                }
            }
        }.onAppear { if selectedMuscle == nil { selectedMuscle = dataManager.availableParts.first } }
    }
}

// MARK: - Phase 2: Table Logger with Keyboard Toolbar

struct TableLoggerView: View {
    let exercise: Exercise
    let onBack: () -> Void
    @EnvironmentObject var dataManager: WorkoutDataManager
    
    @State private var weightInput: String = ""
    @State private var repsInput: String = ""
    @FocusState private var focusedField: Field?
    enum Field { case weight, reps }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 6) { Image(systemName: "chevron.left"); Text("Done"); }.font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                    .padding(.horizontal, 16).padding(.vertical, 8).background(Theme.Colors.surfaceContainerHigh).clipShape(Capsule())
                }
                Spacer()
            }.padding(.horizontal, 24).padding(.top, 24).padding(.bottom, 16)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Title
                    Text(exercise.name).font(.system(size: 32, weight: .heavy, design: .rounded)).foregroundColor(.white).padding(.horizontal, 24)
                    
                    VStack(spacing: 0) {
                        // Table Header
                        HStack {
                            Text("SET").frame(width: 40, alignment: .center)
                            Text("PREVIOUS").frame(maxWidth: .infinity, alignment: .center)
                            Text(dataManager.weightUnit.rawValue).frame(width: 80, alignment: .center)
                            Text("REPS").frame(width: 70, alignment: .center)
                            Image(systemName: "checkmark").frame(width: 40, alignment: .center)
                        }.font(.system(size: 12, weight: .bold)).foregroundColor(.gray).padding(.horizontal, 24).padding(.bottom, 12)
                        
                        Divider().background(Color.white.opacity(0.1)).padding(.horizontal, 24)
                        
                        // Data Rows
                        if let log = dataManager.activeSession?.exerciseLogs.first(where: { $0.exercise.id == exercise.id }) {
                            ForEach(log.sets) { s in
                                HStack {
                                    Text("\(s.setNumber)").frame(width: 40, alignment: .center).font(.system(size: 14, weight: .black)).foregroundColor(.white)
                                    // Simulated Previous based on historical data array
                                    let prevStr = previousDataString(for: s.setNumber)
                                    Text(prevStr).frame(maxWidth: .infinity, alignment: .center).font(.system(size: 14, weight: .bold)).foregroundColor(.gray.opacity(0.5))
                                    Text("\(String(format: "%.1f", s.weight).replacingOccurrences(of: ".0", with: ""))")
                                        .frame(width: 80, height: 36, alignment: .center).font(.system(size: 16, weight: .bold)).background(Theme.Colors.surfaceContainerLow).clipShape(RoundedRectangle(cornerRadius: 10)).foregroundColor(.white)
                                    Text("\(s.reps)")
                                        .frame(width: 70, height: 36, alignment: .center).font(.system(size: 16, weight: .bold)).background(Theme.Colors.surfaceContainerLow).clipShape(RoundedRectangle(cornerRadius: 10)).foregroundColor(.white)
                                    Image(systemName: "checkmark").frame(width: 40, alignment: .trailing).font(.system(size: 16, weight: .heavy)).foregroundColor(Color(hex: "#30D158"))
                                }.padding(.horizontal, 24).padding(.vertical, 10)
                            }
                        }
                        
                        // Active Input Row
                        let nextSetNum = (dataManager.activeSession?.exerciseLogs.first(where: { $0.exercise.id == exercise.id })?.sets.last?.setNumber ?? 0) + 1
                        
                        HStack {
                            Text("\(nextSetNum)").frame(width: 40, alignment: .center).font(.system(size: 14, weight: .black)).foregroundColor(.white)
                            Text(previousDataString(for: nextSetNum)).frame(maxWidth: .infinity, alignment: .center).font(.system(size: 12, weight: .bold)).foregroundColor(.gray.opacity(0.5)).lineLimit(1)
                            
                            TextField("-", text: $weightInput)
                                .keyboardType(.decimalPad).focused($focusedField, equals: .weight).multilineTextAlignment(.center)
                                .frame(width: 80, height: 42).font(.system(size: 18, weight: .black)).foregroundColor(.white).tint(Theme.Colors.primary).background(Theme.Colors.surfaceContainerLow).clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(focusedField == .weight ? Theme.Colors.primary : Color.clear, lineWidth: 2))
                            
                            TextField("-", text: $repsInput)
                                .keyboardType(.numberPad).focused($focusedField, equals: .reps).multilineTextAlignment(.center)
                                .frame(width: 70, height: 42).font(.system(size: 18, weight: .black)).foregroundColor(.white).tint(Theme.Colors.primary).background(Theme.Colors.surfaceContainerLow).clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(focusedField == .reps ? Theme.Colors.primary : Color.clear, lineWidth: 2))
                            
                            Button(action: logSet) {
                                Image(systemName: "checkmark").frame(width: 32, height: 32).background(Color(hex: "#30D158")).clipShape(Circle()).foregroundColor(Theme.Colors.surface).font(.system(size: 14, weight: .black))
                            }.frame(width: 40, alignment: .trailing).disabled(weightInput.isEmpty || repsInput.isEmpty).opacity(weightInput.isEmpty || repsInput.isEmpty ? 0.3 : 1.0)
                        }.padding(.horizontal, 24).padding(.vertical, 16).background(Theme.Colors.surfaceContainerLowest.opacity(0.5))
                    }.padding(.top, 8)
                    Spacer().frame(height: 100)
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(Theme.Colors.surface.ignoresSafeArea())
        .onAppear {
            focusedField = .weight
            populatePrevious()
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                if focusedField == .weight {
                    Spacer()
                    Button(action: { focusedField = .reps }) {
                        Text("Next (Reps)").font(.system(size: 16, weight: .bold))
                    }
                } else if focusedField == .reps {
                    Button(action: { focusedField = .weight }) {
                        HStack { Image(systemName: "chevron.left"); Text("Weight") }
                    }
                    Spacer()
                    Button(action: logSet) {
                        Text("Log Set").font(.system(size: 16, weight: .bold)).foregroundColor(.green)
                    }.disabled(weightInput.isEmpty || repsInput.isEmpty)
                }
            }
        }
    }
    
    private func previousDataString(for setNum: Int) -> String {
        if setNum - 1 < exercise.previousSets.count {
            let pSet = exercise.previousSets[setNum - 1]
            return "\(String(format: "%.0f", pSet.weight)) × \(pSet.reps)"
        }
        return "-"
    }
    
    private func populatePrevious() {
        let nextSetNum = (dataManager.activeSession?.exerciseLogs.first(where: { $0.exercise.id == exercise.id })?.sets.last?.setNumber ?? 0) + 1
        if nextSetNum - 1 < exercise.previousSets.count {
            weightInput = String(format: "%.1f", exercise.previousSets[nextSetNum - 1].weight).replacingOccurrences(of: ".0", with: "")
        }
    }
    
    private func logSet() {
        guard let w = Double(weightInput), let r = Int(repsInput) else { return }
        
        if dataManager.activeSession == nil { dataManager.activeSession = ActiveWorkoutSession(date: Date(), exerciseLogs: []) }
        
        if let idx = dataManager.activeSession?.exerciseLogs.firstIndex(where: { $0.exercise.id == exercise.id }) {
            let n = (dataManager.activeSession?.exerciseLogs[idx].sets.last?.setNumber ?? 0) + 1
            dataManager.activeSession?.exerciseLogs[idx].sets.append(WorkoutSet(setNumber: n, reps: r, weight: w))
        } else {
            dataManager.activeSession?.exerciseLogs.append(ExerciseLog(exercise: exercise, sets: [WorkoutSet(setNumber: 1, reps: r, weight: w)], unit: dataManager.weightUnit))
        }
        
        repsInput = ""
        focusedField = .weight
        populatePrevious()
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.success)
    }
}

#Preview {
    WorkoutSessionView().environmentObject(WorkoutDataManager())
}
