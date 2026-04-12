import SwiftUI
import Combine

public struct MusclePart: Identifiable, Hashable {
    public let id = UUID()
    public let name: String
    public let color: Color
    public let icon: String
    
    public init(name: String, color: Color, icon: String) {
        self.name = name
        self.color = color
        self.icon = icon
    }
}

public enum WeightUnit: String, Codable, CaseIterable, Hashable {
    case kg = "KG"
    case lbs = "LBS"
    
    public func convert(_ weight: Double, from: WeightUnit) -> Double {
        if self == from { return weight }
        if self == .kg { return weight * 0.453592 }
        return weight * 2.20462
    }
}

public struct Exercise: Identifiable, Hashable {
    public var id: UUID
    public let name: String
    public let musclePartName: String
    public let isCustom: Bool
    
    // Derived/volatile stats for UI logic
    public var usageCount: Int
    public var maxWeight: Double
    public var lastPerformance: String
    
    // For "Active Session" tracking of what was planned
    public var previousSets: [WorkoutSet]
    
    public init(id: UUID = UUID(), name: String, musclePartName: String, isCustom: Bool = false, usageCount: Int = 0, maxWeight: Double = 0, lastPerformance: String = "-", previousSets: [WorkoutSet] = []) {
        self.id = id
        self.name = name
        self.musclePartName = musclePartName
        self.isCustom = isCustom
        self.usageCount = usageCount
        self.maxWeight = maxWeight
        self.lastPerformance = lastPerformance
        self.previousSets = previousSets
    }
}

public struct WorkoutSet: Identifiable, Hashable {
    public let id = UUID()
    public var setNumber: Int
    public var reps: Int
    public var weightKg: Double
    public var isPR: Bool = false
    
    public init(setNumber: Int, reps: Int, weightKg: Double, isPR: Bool = false) {
        self.setNumber = setNumber
        self.reps = reps
        self.weightKg = weightKg
        self.isPR = isPR
    }
}

public struct RoutineEntry {
    public let muscles: [MusclePart]
    public let exercises: [(exercise: Exercise, sets: [WorkoutSet])]
}

public struct ExerciseLog: Identifiable, Hashable {
    public let id = UUID()
    public let exercise: Exercise
    public var sets: [WorkoutSet]
}

public struct ActiveWorkoutSession: Identifiable {
    public let id = UUID()
    public var date: Date
    public var exerciseLogs: [ExerciseLog] = []
    public var removedPlannedExercises: Set<String> = []
    public var isFinished: Bool = false
}

// MARK: - Body Map Models

public enum PhotoSide: String, Codable {
    case front, back
}

public struct BodyZone: Identifiable, Codable {
    public let id: UUID
    public let muscleName: String
    public let normalizedX: Double
    public let normalizedY: Double
    public let side: PhotoSide
    
    public init(id: UUID = UUID(), muscleName: String, normalizedX: Double, normalizedY: Double, side: PhotoSide) {
        self.id = id
        self.muscleName = muscleName
        self.normalizedX = normalizedX
        self.normalizedY = normalizedY
        self.side = side
    }
}

public struct ProgressionPhoto: Identifiable, Codable {
    public let id: UUID
    public let date: Date
    public let filename: String
    public let side: PhotoSide
    
    public init(id: UUID = UUID(), date: Date, filename: String, side: PhotoSide) {
        self.id = id
        self.date = date
        self.filename = filename
        self.side = side
    }
}

import SwiftData

@MainActor
public class WorkoutDataManager: ObservableObject {
    private var modelContext: ModelContext?
    
    public init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
        loadInitialState()
    }
    
    @Published public var weightUnit: WeightUnit = .kg
    @Published public var routine: [Int: RoutineEntry] = [:]
    @Published public var sessions: [String: ActiveWorkoutSession] = [:]
    
    // Theme Customization
    @Published public var primaryColor: Color = Color(hex: "#C4524D") // Crimson
    @Published public var accentColor: Color = Color(hex: "#FF2D55") // Glowing Red for Heart
    @Published public var availableParts: [MusclePart] = [
        MusclePart(name: "CHEST", color: Color(hex: "#FF453A"), icon: "shield.fill"),
        MusclePart(name: "BACK", color: Color(hex: "#30D158"), icon: "figure.walk"),
        MusclePart(name: "LEGS", color: Color(hex: "#FF9F0A"), icon: "flame.fill"),
        MusclePart(name: "SHOULDERS", color: Color(hex: "#BF5AF2"), icon: "crown.fill"),
        MusclePart(name: "BICEPS", color: Color(hex: "#FF375F"), icon: "dumbbell.fill"),
        MusclePart(name: "TRICEPS", color: Color(hex: "#0A84FF"), icon: "bolt.fill"),
        MusclePart(name: "ABS", color: Color(hex: "#64D2FF"), icon: "star.fill"),
        MusclePart(name: "CARDIO", color: Color(hex: "#32ADE6"), icon: "heart.fill")
    ]
    
    @Published public var exerciseLibrary: [Exercise] = []
    
    private func loadInitialState() {
        guard let ctx = modelContext else { return }
        
        let settingsFetch = FetchDescriptor<AppSettings>()
        if let settings = try? ctx.fetch(settingsFetch).first {
            // 1. Settings
            self.weightUnit = WeightUnit(rawValue: settings.preferredWeightUnitString) ?? .kg
            self.primaryColor = Color(hex: settings.primaryColorHex)
            self.accentColor = Color(hex: settings.accentColorHex)
            
            // 2. Exercises Map
            let exFetch = FetchDescriptor<ExerciseEntity>()
            let dbExercises = (try? ctx.fetch(exFetch)) ?? []
            let exDict = Dictionary(uniqueKeysWithValues: dbExercises.map { ($0.id, $0) })
            
            self.exerciseLibrary = dbExercises.map { ex in
                Exercise(id: ex.id, name: ex.name, musclePartName: ex.musclePartName, isCustom: ex.isCustom, usageCount: 0, maxWeight: 0, lastPerformance: "-", previousSets: [])
            }
            
            // 3. Routines
            let routineFetch = FetchDescriptor<RoutineDayEntity>()
            let dbRoutines = (try? ctx.fetch(routineFetch)) ?? []
            var loadedRoutine: [Int: RoutineEntry] = [:]
            for day in dbRoutines {
                let muscles = day.selectedMusclePartNames.compactMap { mName in
                    self.availableParts.first(where: { $0.name == mName })
                }
                let exercises: [(exercise: Exercise, sets: [WorkoutSet])] = day.plannedExercises.sorted(by: { $0.displayOrder < $1.displayOrder }).compactMap { pEx in
                    guard let exEntity = dbExercises.first(where: { $0.id == pEx.exerciseId }) else { return nil }
                    let exercise = Exercise(id: exEntity.id, name: exEntity.name, musclePartName: exEntity.musclePartName)
                    let mappedSets = pEx.plannedSets.sorted(by: { $0.setNumber < $1.setNumber }).map { pSet in
                        return WorkoutSet(setNumber: pSet.setNumber, reps: pSet.reps, weightKg: pSet.weightKg)
                    }
                    return (exercise: exercise, sets: mappedSets)
                }
                loadedRoutine[day.weekday] = RoutineEntry(muscles: muscles, exercises: exercises)
            }
            self.routine = loadedRoutine
            
            // 4. Sessions
            let sessionFetch = FetchDescriptor<WorkoutSessionEntity>()
            let dbSessions = (try? ctx.fetch(sessionFetch)) ?? []
            var loadedSessions: [String: ActiveWorkoutSession] = [:]
            for s in dbSessions {
                let logs: [ExerciseLog] = s.exerciseLogs.sorted(by: { $0.displayOrder < $1.displayOrder }).map { log in
                    let eName = exDict[log.exerciseId]?.name ?? log.snapshotExerciseName
                    let mName = exDict[log.exerciseId]?.musclePartName ?? log.snapshotMusclePartName
                    let baseEx = Exercise(id: log.exerciseId, name: eName, musclePartName: mName)
                    let sets = log.sets.sorted(by: { $0.setNumber < $1.setNumber }).map { dbSet in
                        return WorkoutSet(setNumber: dbSet.setNumber, reps: dbSet.reps, weightKg: dbSet.weightKg, isPR: dbSet.isPR)
                    }
                    return ExerciseLog(exercise: baseEx, sets: sets)
                }
                loadedSessions[s.dateKey] = ActiveWorkoutSession(
                    date: s.sessionDate,
                    exerciseLogs: logs,
                    removedPlannedExercises: Set(s.removedPlannedExerciseIds.compactMap { exDict[$0]?.name }),
                    isFinished: s.isFinished
                )
            }
            self.sessions = loadedSessions
            // 5. Body Zones
            let zoneFetch = FetchDescriptor<BodyZoneEntity>()
            let dbZones = (try? ctx.fetch(zoneFetch)) ?? []
            self.bodyZones = dbZones.map { z in
                BodyZone(id: z.id, muscleName: z.muscleName, normalizedX: z.normalizedX, normalizedY: z.normalizedY, side: PhotoSide(rawValue: z.sideRaw) ?? .front)
            }
            
            // 6. Progression Photos
            let photoFetch = FetchDescriptor<ProgressionPhotoEntity>()
            let dbPhotos = (try? ctx.fetch(photoFetch)) ?? []
            self.progressionPhotos = dbPhotos.map { p in
                ProgressionPhoto(id: p.id, date: p.date, filename: p.filename, side: PhotoSide(rawValue: p.sideRaw) ?? .front)
            }
            
        } else {
            // FIRST LAUNCH SEED
            seedDatabase()
            loadInitialState() // Reload after seed
        }
    }
    
    private func seedDatabase() {
        guard let ctx = modelContext else { return }
        
        let settings = AppSettings(preferredWeightUnitString: "KG", primaryColorHex: "#C4524D", accentColorHex: "#FF2D55", userName: "Abhi's")
        ctx.insert(settings)
        
        let defaultExercises = [
            ("Bench Press", "CHEST"),
            ("Incline Dumbbell Press", "CHEST"),
            ("Cable Flyes", "CHEST"),
            ("Pull-ups", "BACK"),
            ("Barbell Row", "BACK"),
            ("Lat Pulldown", "BACK"),
            ("Squats", "LEGS"),
            ("Leg Press", "LEGS"),
            ("Romanian Deadlift", "LEGS"),
            ("Overhead Press", "SHOULDERS"),
            ("Lateral Raises", "SHOULDERS"),
            ("Dumbbell Curls", "BICEPS"),
            ("Hammer Curls", "BICEPS"),
            ("Tricep Pushdown", "TRICEPS"),
            ("Overhead Tricep Extension", "TRICEPS"),
            ("Crunches", "ABS"),
            ("Plank", "ABS"),
            ("Treadmill Running", "CARDIO")
        ]
        
        var exEntities: [String: ExerciseEntity] = [:]
        for ex in defaultExercises {
            let entity = ExerciseEntity(id: UUID(), name: ex.0, musclePartName: ex.1, isCustom: false)
            ctx.insert(entity)
            exEntities[ex.0] = entity
        }
        
        let routineSeedData = [
            2: (["CHEST", "TRICEPS"], ["Bench Press", "Incline Dumbbell Press", "Tricep Pushdown", "Overhead Tricep Extension"]), // Monday
            3: (["BACK", "BICEPS"], ["Pull-ups", "Barbell Row", "Lat Pulldown", "Dumbbell Curls"]), // Tuesday
            4: (["LEGS", "SHOULDERS", "ABS"], ["Squats", "Leg Press", "Overhead Press", "Lateral Raises", "Crunches"]) // Wednesday
        ]
        
        for (day, data) in routineSeedData {
            let rd = RoutineDayEntity(id: UUID(), weekday: day, selectedMusclePartNames: data.0)
            for (i, exName) in data.1.enumerated() {
                if let exEntity = exEntities[exName] {
                    let pe = PlannedExerciseEntity(id: UUID(), exerciseId: exEntity.id, displayOrder: i)
                    for setNum in 1...3 {
                        let pse = PlannedSetEntity(id: UUID(), setNumber: setNum, reps: 10, weightKg: 0)
                        pe.plannedSets.append(pse)
                    }
                    rd.plannedExercises.append(pe)
                }
            }
            ctx.insert(rd)
        }
        
        try? ctx.save()
    }
    
    public func addCustomExercise(name: String, musclePartName: String) {
        let ex = Exercise(name: name, musclePartName: musclePartName, isCustom: true)
        exerciseLibrary.append(ex)
        
        if let ctx = modelContext {
            let entity = ExerciseEntity(id: ex.id, name: ex.name, musclePartName: ex.musclePartName, isCustom: true)
            ctx.insert(entity)
            try? ctx.save()
        }
    }
    
    public func session(for date: Date) -> ActiveWorkoutSession? {
        return sessions[dateKey(date)]
    }
    
    public func saveSession(_ session: ActiveWorkoutSession, for date: Date) {
        sessions[dateKey(date)] = session
        
        guard let ctx = modelContext else { return }
        let dKey = dateKey(date)
        
        let sessionFetch = FetchDescriptor<WorkoutSessionEntity>(predicate: #Predicate { $0.dateKey == dKey })
        if let existing = try? ctx.fetch(sessionFetch).first {
            ctx.delete(existing)
        }
        
        let exFetch = FetchDescriptor<ExerciseEntity>()
        let dbExercises = (try? ctx.fetch(exFetch)) ?? []
        let exDict = Dictionary(uniqueKeysWithValues: dbExercises.map { ($0.name, $0) })
        
        let removedIds = session.removedPlannedExercises.compactMap { name in
            exDict[name]?.id
        }
        
        let entity = WorkoutSessionEntity(id: session.id, dateKey: dKey, sessionDate: session.date, isFinished: session.isFinished)
        entity.removedPlannedExerciseIds = removedIds
        
        for (i, log) in session.exerciseLogs.enumerated() {
            let exEntityId = log.exercise.id
            
            let logEntity = ExerciseLogEntity(id: log.id, exerciseId: exEntityId, snapshotExerciseName: log.exercise.name, snapshotMusclePartName: log.exercise.musclePartName, displayOrder: i)
            for storedSet in log.sets {
                let setEntity = WorkoutSetEntity(id: storedSet.id, setNumber: storedSet.setNumber, reps: storedSet.reps, weightKg: storedSet.weightKg, isPR: storedSet.isPR)
                logEntity.sets.append(setEntity)
            }
            
            entity.exerciseLogs.append(logEntity)
        }
        
        ctx.insert(entity)
        try? ctx.save()
    }
    
    public func deleteExerciseLog(name: String, for date: Date) {
        if var current = session(for: date) {
            current.exerciseLogs.removeAll(where: { $0.exercise.name == name })
            current.removedPlannedExercises.insert(name)
            saveSession(current, for: date)
        }
    }
    
    public func deleteWorkoutSet(exerciseId: UUID, setId: UUID, for date: Date) {
        if var current = session(for: date),
           let idx = current.exerciseLogs.firstIndex(where: { $0.exercise.id == exerciseId }) {
            current.exerciseLogs[idx].sets.removeAll(where: { $0.id == setId })
            for i in 0..<current.exerciseLogs[idx].sets.count {
                current.exerciseLogs[idx].sets[i].setNumber = i + 1
            }
            saveSession(current, for: date)
        }
    }
    
    public func saveRoutineDay(dayId: Int, muscles: [MusclePart]) {
        // Phase 5: Enforce consistency by auto-generating exercises for chosen muscles
        var selectedExercises: [(exercise: Exercise, sets: [WorkoutSet])] = []
        for muscle in muscles {
            // Pick a default exercise for this muscle group from library
            if let defaultEx = exerciseLibrary.first(where: { $0.musclePartName == muscle.name }) {
                // Default 3 sets of 10
                let sets = [
                    WorkoutSet(setNumber: 1, reps: 10, weightKg: 0),
                    WorkoutSet(setNumber: 2, reps: 10, weightKg: 0),
                    WorkoutSet(setNumber: 3, reps: 10, weightKg: 0)
                ]
                selectedExercises.append((exercise: defaultEx, sets: sets))
            }
        }
        
        let entry = RoutineEntry(muscles: muscles, exercises: selectedExercises)
        routine[dayId] = entry
        
        guard let ctx = modelContext else { return }
        let fetch = FetchDescriptor<RoutineDayEntity>(predicate: #Predicate { $0.weekday == dayId })
        if let existing = try? ctx.fetch(fetch).first {
            ctx.delete(existing)
        }
        
        let entity = RoutineDayEntity(id: UUID(), weekday: dayId, selectedMusclePartNames: muscles.map { $0.name })
        
        let exFetch = FetchDescriptor<ExerciseEntity>()
        let dbExercises = (try? ctx.fetch(exFetch)) ?? []
        let exDict = Dictionary(uniqueKeysWithValues: dbExercises.map { ($0.name, $0) })
        
        for (i, ex) in selectedExercises.enumerated() {
            let exId = ex.exercise.id
            let pEx = PlannedExerciseEntity(id: UUID(), exerciseId: exId, displayOrder: i)
            for pSet in ex.sets {
                let pSetEntity = PlannedSetEntity(id: UUID(), setNumber: pSet.setNumber, reps: pSet.reps, weightKg: pSet.weightKg)
                pEx.plannedSets.append(pSetEntity)
            }
            entity.plannedExercises.append(pEx)
        }
        
        ctx.insert(entity)
        try? ctx.save()
    }
    
    public func dateKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    public func routineExercises(for date: Date) -> [(exercise: Exercise, sets: [WorkoutSet])] {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        return routine[weekday]?.exercises ?? []
    }
    

    
    public func parts(for date: Date) -> [MusclePart] {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        return routine[weekday]?.muscles ?? []
    }

    public func exercises(for musclePart: String) -> [Exercise] {
        return exerciseLibrary.filter { $0.musclePartName == musclePart }
    }
    
    public func history(for exerciseName: String) -> [(date: Date, volume: Double, maxWeight: Double)] {
        var results: [(date: Date, volume: Double, maxWeight: Double)] = []
        let sortedSessions = sessions.values.sorted { $0.date < $1.date }
        for session in sortedSessions {
            if let log = session.exerciseLogs.first(where: { $0.exercise.name == exerciseName }) {
                let volume = log.sets.reduce(0.0) { $0 + ($1.weightKg * Double($1.reps)) }
                let maxW = log.sets.map { $0.weightKg }.max() ?? 0.0
                results.append((date: session.date, volume: volume, maxWeight: maxW))
            }
        }
        return results
    }
    
    public func workoutVolume(for date: Date) -> Double {
        let key = dateKey(date)
        guard let session = sessions[key] else { return 0.0 }
        return session.exerciseLogs.reduce(0.0) { logSum, log in
            logSum + log.sets.reduce(0.0) { setSum, set in
                setSum + (set.weightKg * Double(set.reps))
            }
        }
    }
    
    public func activityLevel(for date: Date) -> Int {
        let volume = workoutVolume(for: date)
        if volume == 0 { return 0 }
        if volume < 1000 { return 1 }
        if volume < 3000 { return 2 }
        if volume < 6000 { return 3 }
        return 4
    }
    
    public func yearlyActivity(for year: Int) -> [String: Int] {
        var results: [String: Int] = [:]
        for (dateKey, session) in sessions {
            let calendar = Calendar.current
            let sessionYear = calendar.component(.year, from: session.date)
            if sessionYear == year {
                results[dateKey] = activityLevel(for: session.date)
            }
        }
        return results
    }
    
    public func heatmapData(year: Int) -> [String: Color] {
        var results: [String: Color] = [:]
        for (dateKey, session) in sessions {
            let calendar = Calendar.current
            let sessionYear = calendar.component(.year, from: session.date)
            if sessionYear == year {
                if let firstLog = session.exerciseLogs.first {
                    results[dateKey] = colorForMuscle(firstLog.exercise.musclePartName)
                }
            }
        }
        return results
    }
    
    public func colorForMuscle(_ name: String) -> Color {
        return availableParts.first(where: { $0.name == name })?.color ?? primaryColor
    }
    
    // MARK: - Body Map
    
    @Published public var bodyZones: [BodyZone] = []
    @Published public var progressionPhotos: [ProgressionPhoto] = []
    
    // Directory for storing progression images
    private var progressionDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("progression", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    
    public func saveProgressionPhoto(_ image: UIImage, side: PhotoSide) {
        let filename = "progression_\(UUID().uuidString).jpg"
        let url = progressionDirectory.appendingPathComponent(filename)
        if let data = image.jpegData(compressionQuality: 0.85) {
            try? data.write(to: url)
        }
        let id = UUID()
        let date = Date()
        let entry = ProgressionPhoto(id: id, date: date, filename: filename, side: side)
        progressionPhotos.append(entry)
        
        // Persist to SwiftData
        if let ctx = modelContext {
            let entity = ProgressionPhotoEntity(id: id, date: date, filename: filename, sideRaw: side.rawValue)
            ctx.insert(entity)
            try? ctx.save()
        }
    }
    
    public func loadImage(filename: String) -> UIImage? {
        let url = progressionDirectory.appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
    
    public func deleteProgressionPhoto(_ photo: ProgressionPhoto) {
        let url = progressionDirectory.appendingPathComponent(photo.filename)
        try? FileManager.default.removeItem(at: url)
        progressionPhotos.removeAll { $0.id == photo.id }
        
        if let ctx = modelContext {
            let photoId = photo.id
            let fetch = FetchDescriptor<ProgressionPhotoEntity>(predicate: #Predicate { $0.id == photoId })
            if let entity = try? ctx.fetch(fetch).first {
                ctx.delete(entity)
                try? ctx.save()
            }
        }
    }
    
    // Latest photo for a given side
    public func latestPhoto(for side: PhotoSide) -> ProgressionPhoto? {
        progressionPhotos.filter { $0.side == side }.sorted { $0.date < $1.date }.last
    }
    
    public func zones(for side: PhotoSide) -> [BodyZone] {
        bodyZones.filter { $0.side == side }
    }
    
    public func addZone(_ zone: BodyZone) {
        bodyZones.removeAll { $0.muscleName == zone.muscleName && $0.side == zone.side }
        bodyZones.append(zone)
        
        if let ctx = modelContext {
            let mName = zone.muscleName
            let sRaw = zone.side.rawValue
            let fetch = FetchDescriptor<BodyZoneEntity>(predicate: #Predicate { $0.muscleName == mName && $0.sideRaw == sRaw })
            if let existing = try? ctx.fetch(fetch).first {
                ctx.delete(existing)
            }
            
            let entity = BodyZoneEntity(id: zone.id, muscleName: zone.muscleName, normalizedX: zone.normalizedX, normalizedY: zone.normalizedY, sideRaw: zone.side.rawValue)
            ctx.insert(entity)
            try? ctx.save()
        }
    }
    
    public func removeZone(id: UUID) {
        bodyZones.removeAll { $0.id == id }
        if let ctx = modelContext {
            let fetch = FetchDescriptor<BodyZoneEntity>(predicate: #Predicate { $0.id == id })
            if let existing = try? ctx.fetch(fetch).first {
                ctx.delete(existing)
                try? ctx.save()
            }
        }
    }
}
