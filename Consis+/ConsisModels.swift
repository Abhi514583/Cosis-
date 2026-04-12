import SwiftUI
import SwiftData

// MARK: - App Settings
@Model
public class AppSettings {
    @Attribute(.unique) public var id: UUID
    public var preferredWeightUnitString: String // "KG" or "LBS"
    public var primaryColorHex: String
    public var accentColorHex: String
    public var userName: String
    public var createdAt: Date
    public var updatedAt: Date
    
    public init(id: UUID = UUID(), preferredWeightUnitString: String, primaryColorHex: String, accentColorHex: String, userName: String) {
        self.id = id
        self.preferredWeightUnitString = preferredWeightUnitString
        self.primaryColorHex = primaryColorHex
        self.accentColorHex = accentColorHex
        self.userName = userName
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Exercises
@Model
public class ExerciseEntity {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var musclePartName: String
    public var isCustom: Bool
    public var createdAt: Date
    public var updatedAt: Date
    
    public init(id: UUID = UUID(), name: String, musclePartName: String, isCustom: Bool = false) {
        self.id = id
        self.name = name
        self.musclePartName = musclePartName
        self.isCustom = isCustom
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Routines
@Model
public class RoutineDayEntity {
    @Attribute(.unique) public var id: UUID
    public var weekday: Int // 1 (Sunday) to 7 (Saturday)
    public var selectedMusclePartNames: [String] // E.g. ["CHEST", "TRICEPS"]
    
    @Relationship(deleteRule: .cascade, inverse: \PlannedExerciseEntity.routineDay)
    public var plannedExercises: [PlannedExerciseEntity]
    
    public var createdAt: Date
    public var updatedAt: Date
    
    public init(id: UUID = UUID(), weekday: Int, selectedMusclePartNames: [String] = []) {
        self.id = id
        self.weekday = weekday
        self.selectedMusclePartNames = selectedMusclePartNames
        self.plannedExercises = []
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

@Model
public class PlannedExerciseEntity {
    @Attribute(.unique) public var id: UUID
    public var exerciseId: UUID // Reference to ExerciseEntity
    public var displayOrder: Int
    
    public var routineDay: RoutineDayEntity?
    
    @Relationship(deleteRule: .cascade, inverse: \PlannedSetEntity.plannedExercise)
    public var plannedSets: [PlannedSetEntity]
    
    public init(id: UUID = UUID(), exerciseId: UUID, displayOrder: Int) {
        self.id = id
        self.exerciseId = exerciseId
        self.displayOrder = displayOrder
        self.plannedSets = []
    }
}

@Model
public class PlannedSetEntity {
    @Attribute(.unique) public var id: UUID
    public var setNumber: Int
    public var reps: Int
    public var weightKg: Double
    
    public var plannedExercise: PlannedExerciseEntity?
    
    public init(id: UUID = UUID(), setNumber: Int, reps: Int, weightKg: Double) {
        self.id = id
        self.setNumber = setNumber
        self.reps = reps
        self.weightKg = weightKg
    }
}

// MARK: - Sessions (Workout Logs)
@Model
public class WorkoutSessionEntity {
    @Attribute(.unique) public var id: UUID
    public var dateKey: String // e.g. "2026-04-11"
    public var sessionDate: Date
    public var isFinished: Bool
    public var removedPlannedExerciseIds: [UUID] // Track custom removed logic
    
    @Relationship(deleteRule: .cascade, inverse: \ExerciseLogEntity.workoutSession)
    public var exerciseLogs: [ExerciseLogEntity]
    
    public var createdAt: Date
    public var updatedAt: Date
    
    public init(id: UUID = UUID(), dateKey: String, sessionDate: Date, isFinished: Bool = false) {
        self.id = id
        self.dateKey = dateKey
        self.sessionDate = sessionDate
        self.isFinished = isFinished
        self.removedPlannedExerciseIds = []
        self.exerciseLogs = []
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

@Model
public class ExerciseLogEntity {
    @Attribute(.unique) public var id: UUID
    public var exerciseId: UUID // Link to the original exercise
    public var snapshotExerciseName: String // Keep if exercise deleted
    public var snapshotMusclePartName: String
    public var displayOrder: Int
    
    public var workoutSession: WorkoutSessionEntity?
    
    @Relationship(deleteRule: .cascade, inverse: \WorkoutSetEntity.exerciseLog)
    public var sets: [WorkoutSetEntity]
    
    public init(id: UUID = UUID(), exerciseId: UUID, snapshotExerciseName: String, snapshotMusclePartName: String, displayOrder: Int) {
        self.id = id
        self.exerciseId = exerciseId
        self.snapshotExerciseName = snapshotExerciseName
        self.snapshotMusclePartName = snapshotMusclePartName
        self.displayOrder = displayOrder
        self.sets = []
    }
}

@Model
public class WorkoutSetEntity {
    @Attribute(.unique) public var id: UUID
    public var setNumber: Int
    public var reps: Int
    public var weightKg: Double
    public var isPR: Bool
    
    public var exerciseLog: ExerciseLogEntity?
    
    public var createdAt: Date
    public var updatedAt: Date
    
    public init(id: UUID = UUID(), setNumber: Int, reps: Int, weightKg: Double, isPR: Bool = false) {
        self.id = id
        self.setNumber = setNumber
        self.reps = reps
        self.weightKg = weightKg
        self.isPR = isPR
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Body Map / Visuals
@Model
public class ProgressionPhotoEntity {
    @Attribute(.unique) public var id: UUID
    public var date: Date
    public var filename: String
    public var sideRaw: String
    public var createdAt: Date
    
    public init(id: UUID = UUID(), date: Date, filename: String, sideRaw: String) {
        self.id = id
        self.date = date
        self.filename = filename
        self.sideRaw = sideRaw
        self.createdAt = Date()
    }
}

@Model
public class BodyZoneEntity {
    @Attribute(.unique) public var id: UUID
    public var muscleName: String
    public var normalizedX: Double
    public var normalizedY: Double
    public var sideRaw: String
    public var createdAt: Date
    public var updatedAt: Date
    
    public init(id: UUID = UUID(), muscleName: String, normalizedX: Double, normalizedY: Double, sideRaw: String) {
        self.id = id
        self.muscleName = muscleName
        self.normalizedX = normalizedX
        self.normalizedY = normalizedY
        self.sideRaw = sideRaw
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
