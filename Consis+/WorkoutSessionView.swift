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
    @State private var selectedMuscle: MusclePart?
    let sessionDate: Date
    @FocusState private var focusedField: TableLoggerView.Field?
    
    public init(sessionDate: Date = Date(), initialExercise: Exercise? = nil) {
        self.sessionDate = sessionDate
        if let ex = initialExercise {
            _phase = State(initialValue: .logging(ex))
        }
    }
    
    public var body: some View {
        ZStack {
            Theme.Colors.surface.ignoresSafeArea()
            
            switch phase {
            case .overview:
                ActiveWorkoutOverviewView(
                    sessionDate: sessionDate,
                    onAddExercise: { withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { phase = .selection } },
                    onFinish: {
                        dismiss()
                    },
                    onResumeExercise: { ex in 
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { phase = .logging(ex) } 
                    }
                )
            case .selection:
                ExerciseSelectionFeedView(
                    selectedMuscle: $selectedMuscle,
                    onSelect: { ex in 
                        focusedField = nil
                        var resolvedEx = ex
                        // Check if this exercise is in today's routine to inject template data
                        let routine = dataManager.routineExercises(for: sessionDate)
                        if let plan = routine.first(where: { $0.name == ex.name }) {
                            resolvedEx.previousSets = plan.sets
                        }
                        
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { phase = .logging(resolvedEx) } 
                    },
                    onClose: { 
                        focusedField = nil
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { phase = .overview } 
                    }
                )
            case .logging(let ex):
                TableLoggerView(
                    exercise: ex,
                    sessionDate: sessionDate,
                    focusedField: $focusedField,
                    onBack: { 
                        focusedField = nil
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { phase = .overview } 
                    }
                )
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                if focusedField == .weight {
                    HStack(spacing: 6) {
                        Text("2x").font(.system(size: 12, weight: .black)).foregroundColor(.gray)
                        ForEach([25, 35, 45], id: \.self) { p in
                            Button("+\(p)") {
                                NotificationCenter.default.post(name: Notification.Name("AddWeight"), object: nil, userInfo: ["amount": p])
                            }
                            .font(.system(size: 14, weight: .black)).foregroundColor(.white)
                            .padding(.horizontal, 8).padding(.vertical, 6)
                            .background(Theme.Colors.surfaceContainerHighest).clipShape(Capsule())
                        }
                    }
                    Spacer()
                    Button(action: { focusedField = .reps }) {
                        HStack(spacing: 4) {
                            Text("Next: Reps").font(.system(size: 14, weight: .black))
                            Image(systemName: "arrow.right.circle.fill")
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Theme.Colors.primary)
                        .clipShape(Capsule())
                    }
                } else if focusedField == .reps {
                    Button(action: { focusedField = .weight }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.left.circle.fill")
                            Text("Weight").font(.system(size: 14, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Theme.Colors.surfaceContainerHigh)
                        .clipShape(Capsule())
                    }
                    Spacer()
                    Button(action: {
                        NotificationCenter.default.post(name: Notification.Name("LogSet"), object: nil)
                    }) {
                        HStack(spacing: 4) {
                            Text("LOG SET").font(.system(size: 14, weight: .black))
                            Image(systemName: "checkmark.circle.fill")
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Color(hex: "#30D158"))
                        .clipShape(Capsule())
                    }
                }
            }
        }
        .onAppear {
            if dataManager.session(for: sessionDate) == nil {
                let initialSession = ActiveWorkoutSession(date: sessionDate, exerciseLogs: [])
                dataManager.saveSession(initialSession, for: sessionDate)
            }
        }
    }
}

// MARK: - Phase 0: Active Overview

struct ActiveWorkoutOverviewView: View {
    @EnvironmentObject var dataManager: WorkoutDataManager
    let sessionDate: Date
    let onAddExercise: () -> Void
    let onFinish: () -> Void
    let onResumeExercise: (Exercise) -> Void
    
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
                    let routine = dataManager.routineExercises(for: sessionDate)
                    let session = dataManager.session(for: sessionDate) ?? ActiveWorkoutSession(date: sessionDate, exerciseLogs: [])
                    
                    // Merge routine with actual logs
                    let displayItems: [(name: String, sets: [WorkoutSet], isLogged: Bool, unit: WeightUnit)] = {
                        var items: [(name: String, sets: [WorkoutSet], isLogged: Bool, unit: WeightUnit)] = []
                        var loggedNames = Set<String>()
                        
                        // First, add all logged exercises
                        for log in session.exerciseLogs {
                            items.append((name: log.exercise.name, sets: log.sets, isLogged: true, unit: log.unit))
                            loggedNames.insert(log.exercise.name)
                        }
                        
                        // Then add planned exercises from routine (Assume library/routine defaults to KG)
                        for plan in routine {
                            if !loggedNames.contains(plan.name) {
                                items.append((name: plan.name, sets: plan.sets, isLogged: false, unit: .kg))
                            }
                        }
                        return items
                    }()
                    
                    if !displayItems.isEmpty {
                        ForEach(displayItems, id: \.name) { item in
                            PaintedLogCard(name: item.name, sets: item.sets, isLogged: item.isLogged, originalUnit: item.unit)
                                .onTapGesture {
                                    // Resolve exercise from library or create fallback
                                    let fallback = Exercise(name: item.name, musclePartName: "CUSTOM")
                                    var resolvedEx = dataManager.exerciseLibrary.first(where: { $0.name == item.name }) ?? fallback
                                    
                                    if !item.isLogged {
                                        // Inject template sets into previousSets so logger pre-fills
                                        resolvedEx.previousSets = item.sets
                                    }
                                    
                                    onResumeExercise(resolvedEx)
                                }
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
    let name: String
    let sets: [WorkoutSet]
    let isLogged: Bool
    let originalUnit: WeightUnit // The unit these sets were originally logged in
    @EnvironmentObject var dataManager: WorkoutDataManager
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(name).font(.system(size: 18, weight: .black, design: .rounded)).foregroundColor(.white)
                    if !isLogged {
                        Text("PLANNED").font(.system(size: 10, weight: .bold)).foregroundColor(Theme.Colors.primary).padding(.horizontal, 6).padding(.vertical, 2).background(Theme.Colors.primary.opacity(0.2)).clipShape(Capsule())
                    }
                }
                Spacer()
                Text("\(sets.count) SETS").font(.system(size: 12, weight: .bold)).foregroundColor(.white.opacity(0.7))
            }
            .padding(20)
            .background(Color.white.opacity(isLogged ? 0.1 : 0.05))
            
            if !sets.isEmpty {
                VStack(spacing: 6) {
                    ForEach(sets) { s in
                        HStack {
                            Text("\(s.setNumber)").font(.system(size: 12, weight: .black)).foregroundColor(.white.opacity(0.5)).frame(width: 30, alignment: .leading)
                            
                            // Convert to global unit
                            let convertedW = dataManager.weightUnit.convert(s.weight, from: originalUnit)
                            Text("\(String(format: "%.1f", convertedW).replacingOccurrences(of: ".0", with: "")) \(dataManager.weightUnit.rawValue)").font(.system(size: 14, weight: .bold)).foregroundColor(.white.opacity(isLogged ? 1.0 : 0.4))
                            
                            Spacer()
                            Text("\(s.reps) reps").font(.system(size: 14, weight: .bold)).foregroundColor(.white.opacity(isLogged ? 0.5 : 0.2))
                        }.padding(.horizontal, 20).padding(.vertical, 6)
                    }
                }.padding(.bottom, 16).padding(.top, 8)
            }
        }
        .background(Theme.Colors.surfaceContainerHigh.opacity(isLogged ? 1.0 : 0.6))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(isLogged ? Theme.Colors.primary.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 2))
    }
}

// MARK: - Phase 1: Selection

struct ExerciseSelectionFeedView: View {
    @EnvironmentObject var dataManager: WorkoutDataManager
    @Binding var selectedMuscle: MusclePart?
    let onSelect: (Exercise) -> Void
    let onClose: () -> Void
    @State private var showCreateCustom = false
    
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
                        
                        Button(action: { showCreateCustom = true }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Create Custom Exercise")
                            }
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.Colors.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(Theme.Colors.surfaceContainerLow)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            .overlay(RoundedRectangle(cornerRadius: 24).stroke(Theme.Colors.primary.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [6, 6])))
                        }
                        .padding(.top, 12)
                    }.padding(24)
                }
            }
        }
        .onAppear { if selectedMuscle == nil { selectedMuscle = dataManager.availableParts.first } }
        .sheet(isPresented: $showCreateCustom) {
            CreateCustomExerciseSheet(selectedMuscle: $selectedMuscle)
        }
    }
}

// MARK: - Phase 1.5: Custom Exercise Sheet

struct CreateCustomExerciseSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: WorkoutDataManager
    @Binding var selectedMuscle: MusclePart?
    @State private var rawName: String = ""
    
    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Text("New Custom Exercise").font(.system(size: 24, weight: .black, design: .rounded)).foregroundColor(.white)
                Spacer()
                Button(action: { dismiss() }) { Image(systemName: "xmark.circle.fill").font(.system(size: 24)).foregroundColor(Theme.Colors.surfaceContainerHighest) }
            }.padding(.top, 32)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("EXERCISE NAME").font(.system(size: 12, weight: .bold)).foregroundColor(.gray)
                TextField("e.g. Incline Machine Press", text: $rawName)
                    .font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                    .padding().background(Theme.Colors.surfaceContainerLow).clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.top, 16)
            
            Spacer()
            
            Button(action: {
                let m = selectedMuscle?.name ?? "CUSTOM"
                let ex = Exercise(name: rawName, musclePartName: m)
                dataManager.exerciseLibrary.append(ex)
                dismiss()
            }) {
                Text("CREATE & ADD TO LIBRARY")
                    .font(.system(size: 16, weight: .black, design: .rounded)).foregroundColor(.black)
                    .frame(maxWidth: .infinity).padding(.vertical, 18).background(Color(hex: "#30D158")).clipShape(Capsule())
            }
            .disabled(rawName.isEmpty).opacity(rawName.isEmpty ? 0.3 : 1.0)
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 24).background(Theme.Colors.surface.ignoresSafeArea())
    }
}

// MARK: - Phase 2: Table Logger with Keyboard Toolbar

struct TableLoggerView: View {
    let exercise: Exercise
    let sessionDate: Date
    @FocusState.Binding var focusedField: Field?
    let onBack: () -> Void
    @EnvironmentObject var dataManager: WorkoutDataManager
    
    @State private var weightInput: String = ""
    @State private var repsInput: String = ""
    
    enum Field { case weight, reps }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Spacer()
                // Settings/Unit toggle
                Button(action: {
                    let old = dataManager.weightUnit
                    let new: WeightUnit = old == .kg ? .lbs : .kg
                    
                    // Convert current active input
                    if let curW = Double(weightInput) {
                        weightInput = String(format: "%.1f", new.convert(curW, from: old)).replacingOccurrences(of: ".0", with: "")
                    }
                    
                    dataManager.weightUnit = new
                    let gen = UIImpactFeedbackGenerator(style: .light)
                    gen.impactOccurred()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.left.arrow.right").font(.system(size: 10))
                        Text(dataManager.weightUnit.rawValue)
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Theme.Colors.surfaceContainerHigh)
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // NEW PR Title Display
                    VStack(alignment: .leading, spacing: 12) {
                        Text(exercise.name)
                            .font(.system(size: 32, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .padding(.horizontal, 24)
                        
                        HStack {
                            // Convert maxWeight to CURRENT unit for display
                            let displayedMax = dataManager.weightUnit.convert(exercise.maxWeight, from: .kg) // Assuming library stores in KG
                            SuggestionPill(baseWeight: displayedMax, baseReps: exercise.previousSets.first?.reps ?? 10) { suggestedWeight, suggestedReps in
                                weightInput = String(format: "%.1f", suggestedWeight).replacingOccurrences(of: ".0", with: "")
                                repsInput = "\(suggestedReps)"
                                
                                // Auto-focus weight field after tap if not already
                                focusedField = .weight
                                let gen = UINotificationFeedbackGenerator()
                                gen.notificationOccurred(.success)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                    }
                    
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
                        if let log = dataManager.session(for: sessionDate)?.exerciseLogs.first(where: { $0.exercise.id == exercise.id }) {
                            ForEach(log.sets) { s in
                                HStack {
                                    Text("\(s.setNumber)").frame(width: 40, alignment: .center).font(.system(size: 14, weight: .black)).foregroundColor(.white)
                                    // Simulated Previous based on historical data array
                                    let prevStr = previousDataString(for: s.setNumber)
                                    Text(prevStr).frame(maxWidth: .infinity, alignment: .center).font(.system(size: 14, weight: .bold)).foregroundColor(.gray.opacity(0.5))
                                    // Convert logged weight to CURRENT unit display
                                    let convertedWeight = dataManager.weightUnit.convert(s.weight, from: log.unit)
                                    Text("\(String(format: "%.1f", convertedWeight).replacingOccurrences(of: ".0", with: ""))")
                                        .frame(width: 80, height: 36, alignment: .center).font(.system(size: 16, weight: .bold)).background(Theme.Colors.surfaceContainerLow).clipShape(RoundedRectangle(cornerRadius: 10)).foregroundColor(.white)
                                    Text("\(s.reps)")
                                        .frame(width: 70, height: 36, alignment: .center).font(.system(size: 16, weight: .bold)).background(Theme.Colors.surfaceContainerLow).clipShape(RoundedRectangle(cornerRadius: 10)).foregroundColor(.white)
                                    Image(systemName: "checkmark").frame(width: 40, alignment: .trailing).font(.system(size: 16, weight: .heavy)).foregroundColor(Color(hex: "#30D158"))
                                }.padding(.horizontal, 24).padding(.vertical, 10)
                            }
                        }
                        
                        // Active Input Row
                        let nextSetNum = (dataManager.session(for: sessionDate)?.exerciseLogs.first(where: { $0.exercise.id == exercise.id })?.sets.last?.setNumber ?? 0) + 1
                        
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
            
            // Sticky Footer for Finish Button
            VStack {
                Button(action: onBack) {
                    HStack {
                        Text("FINISH EXERCISE")
                        Image(systemName: "arrow.right")
                    }
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity).padding(.vertical, 18)
                    .background(Color.white)
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 16)
            .background(Theme.Colors.surface) // Solid background so it sits cleanly
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .background(Theme.Colors.surface.ignoresSafeArea())
        .onAppear {
            populatePrevious()
            // Reset focus first to ensure the transition doesn't confuse the keyboard manager
            focusedField = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if weightInput.isEmpty {
                    focusedField = .weight
                } else {
                    focusedField = .reps
                }
            }
        }
        .onDisappear {
            focusedField = nil
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("AddWeight"))) { note in
            if let amount = note.userInfo?["amount"] as? Int {
                let cur = Double(weightInput) ?? 0.0
                weightInput = String(format: "%.1f", cur + Double(amount * 2)).replacingOccurrences(of: ".0", with: "")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("LogSet"))) { _ in
            logSet()
        }
    }
    
    private func previousDataString(for setNum: Int) -> String {
        if setNum - 1 < exercise.previousSets.count {
            let pSet = exercise.previousSets[setNum - 1]
            // Convert historical weight to CURRENT unit display
            let convertedW = dataManager.weightUnit.convert(pSet.weight, from: .kg) // Assuming library stores base as KG
            return "\(String(format: "%.1f", convertedW).replacingOccurrences(of: ".0", with: "")) × \(pSet.reps)"
        }
        return "-"
    }
    
    private func populatePrevious() {
        let loggedSets = dataManager.session(for: sessionDate)?.exerciseLogs.first(where: { $0.exercise.id == exercise.id })?.sets ?? []
        let nextSetNum = (loggedSets.last?.setNumber ?? 0) + 1
        
        var suggestedW: Double? = nil
        
        if nextSetNum - 1 < exercise.previousSets.count {
            suggestedW = exercise.previousSets[nextSetNum - 1].weight
        } else if let lastLogged = loggedSets.last {
            // Carry over the weight from the most recent set logged TODAY
            suggestedW = lastLogged.weight
        }
        
        if let w = suggestedW {
            if w > 0 {
                // If suggested weight comes from today's log, it might be in current unit. 
                // However, populatePrevious is often called after unit change, so we should ensure consistency.
                // For now, let's assume the weight input logic handles current unit values.
                weightInput = String(format: "%.1f", w).replacingOccurrences(of: ".0", with: "")
            } else {
                weightInput = "" // Clear for bodyweight
            }
        }
    }
    
    private func logSet() {
        guard let w = Double(weightInput), let r = Int(repsInput) else { return }
        
        var currentSession = dataManager.session(for: sessionDate) ?? ActiveWorkoutSession(date: sessionDate, exerciseLogs: [])
        
        if let idx = currentSession.exerciseLogs.firstIndex(where: { $0.exercise.id == exercise.id }) {
            let n = (currentSession.exerciseLogs[idx].sets.last?.setNumber ?? 0) + 1
            currentSession.exerciseLogs[idx].sets.append(WorkoutSet(setNumber: n, reps: r, weight: w))
        } else {
            currentSession.exerciseLogs.append(ExerciseLog(exercise: exercise, sets: [WorkoutSet(setNumber: 1, reps: r, weight: w)], unit: dataManager.weightUnit))
        }
        
        dataManager.saveSession(currentSession, for: sessionDate)
        
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
