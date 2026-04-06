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
    public let id = UUID()
    public let name: String
    public let musclePartName: String
    public var usageCount: Int
    public var maxWeight: Double // All-time PR
    public var lastPerformance: String // Fallback string
    public var previousSets: [WorkoutSet] // For set-by-set mapping
    
    public init(name: String, musclePartName: String, usageCount: Int = 0, maxWeight: Double = 0, lastPerformance: String = "-", previousSets: [WorkoutSet] = []) {
        self.name = name
        self.musclePartName = musclePartName
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
    public var weight: Double
    public var isPR: Bool = false
    
    public init(setNumber: Int, reps: Int, weight: Double, isPR: Bool = false) {
        self.setNumber = setNumber
        self.reps = reps
        self.weight = weight
        self.isPR = isPR
    }
}

public struct ExerciseLog: Identifiable, Hashable {
    public let id = UUID()
    public let exercise: Exercise
    public var sets: [WorkoutSet]
    public var unit: WeightUnit = .kg
}

public struct ActiveWorkoutSession: Identifiable {
    public let id = UUID()
    public var date: Date
    public var exerciseLogs: [ExerciseLog] = []
}

public class WorkoutDataManager: ObservableObject {
    @Published public var weightUnit: WeightUnit = .kg
    @Published public var routine: [Int: [MusclePart]] = [
        2: [MusclePart(name: "CHEST", color: Color(hex: "#FF453A"), icon: "shield.fill"), 
            MusclePart(name: "TRICEPS", color: Color(hex: "#0A84FF"), icon: "bolt.fill")],
        3: [MusclePart(name: "BACK", color: Color(hex: "#30D158"), icon: "figure.walk")],
        4: [MusclePart(name: "LEGS", color: Color(hex: "#FF9F0A"), icon: "flame.fill")]
    ]
    
    @Published public var activeSession: ActiveWorkoutSession? = nil
    
    // Theme Customization
    @Published public var primaryColor: Color = Color(hex: "#C4524D") // Crimson
    @Published public var accentColor: Color = Color(hex: "#FF2D55") // Glowing Red for Heart
    
    public let availableParts = [
        MusclePart(name: "CHEST", color: Color(hex: "#FF453A"), icon: "shield.fill"),
        MusclePart(name: "BACK", color: Color(hex: "#30D158"), icon: "figure.walk"),
        MusclePart(name: "LEGS", color: Color(hex: "#FF9F0A"), icon: "flame.fill"),
        MusclePart(name: "SHOULDERS", color: Color(hex: "#BF5AF2"), icon: "crown.fill"),
        MusclePart(name: "BICEPS", color: Color(hex: "#FF375F"), icon: "dumbbell.fill"),
        MusclePart(name: "TRICEPS", color: Color(hex: "#0A84FF"), icon: "bolt.fill"),
        MusclePart(name: "ABS", color: Color(hex: "#64D2FF"), icon: "star.fill"),
        MusclePart(name: "CARDIO", color: Color(hex: "#32ADE6"), icon: "heart.fill")
    ]
    
    public let exerciseLibrary = [
        Exercise(name: "Barbell Bench Press", musclePartName: "CHEST", usageCount: 50, maxWeight: 100, lastPerformance: "80 KG x 10", previousSets: [
            WorkoutSet(setNumber: 1, reps: 10, weight: 80),
            WorkoutSet(setNumber: 2, reps: 8, weight: 80),
            WorkoutSet(setNumber: 3, reps: 6, weight: 85)
        ]),
        Exercise(name: "Incline Dumbbell Press", musclePartName: "CHEST", usageCount: 30, maxWeight: 40, lastPerformance: "35 KG x 8"),
        Exercise(name: "Cable Crossovers", musclePartName: "CHEST", usageCount: 10, maxWeight: 25, lastPerformance: "20 KG x 15"),
        Exercise(name: "Deadlift", musclePartName: "BACK", usageCount: 45, maxWeight: 180, lastPerformance: "140 KG x 5", previousSets: [
            WorkoutSet(setNumber: 1, reps: 5, weight: 140),
            WorkoutSet(setNumber: 2, reps: 3, weight: 150)
        ]),
        Exercise(name: "Pull-ups", musclePartName: "BACK", usageCount: 60, maxWeight: 0, lastPerformance: "BW x 12"),
        Exercise(name: "Bent Over Rows", musclePartName: "BACK", usageCount: 20, maxWeight: 90, lastPerformance: "70 KG x 10"),
        Exercise(name: "Squats", musclePartName: "LEGS", usageCount: 80, maxWeight: 140, lastPerformance: "120 KG x 6", previousSets: [
            WorkoutSet(setNumber: 1, reps: 8, weight: 100),
            WorkoutSet(setNumber: 2, reps: 6, weight: 120)
        ]),
        Exercise(name: "Leg Press", musclePartName: "LEGS", usageCount: 15, maxWeight: 300, lastPerformance: "250 KG x 12"),
        Exercise(name: "Lunges", musclePartName: "LEGS", usageCount: 10, maxWeight: 60, lastPerformance: "50 KG x 10"),
        Exercise(name: "Overhead Press", musclePartName: "SHOULDERS", usageCount: 40, maxWeight: 60, lastPerformance: "50 KG x 8"),
        Exercise(name: "Lateral Raises", musclePartName: "SHOULDERS", usageCount: 35, maxWeight: 15, lastPerformance: "12 KG x 12"),
        Exercise(name: "Bicep Curls", musclePartName: "BICEPS", usageCount: 55, maxWeight: 25, lastPerformance: "20 KG x 10"),
        Exercise(name: "Hammer Curls", musclePartName: "BICEPS", usageCount: 25, maxWeight: 20, lastPerformance: "18 KG x 12"),
        Exercise(name: "Tricep Pushdowns", musclePartName: "TRICEPS", usageCount: 48, maxWeight: 45, lastPerformance: "35 KG x 12"),
        Exercise(name: "Skull Crushers", musclePartName: "TRICEPS", usageCount: 12, maxWeight: 35, lastPerformance: "30 KG x 8"),
        Exercise(name: "Plank", musclePartName: "ABS", usageCount: 70, maxWeight: 0, lastPerformance: "2min"),
        Exercise(name: "Crunches", musclePartName: "ABS", usageCount: 40, maxWeight: 0, lastPerformance: "30 reps"),
        Exercise(name: "Running", musclePartName: "CARDIO", usageCount: 100, maxWeight: 0, lastPerformance: "5km in 25min"),
        Exercise(name: "Cycling", musclePartName: "CARDIO", usageCount: 20, maxWeight: 0, lastPerformance: "10km in 20min")
    ]
    
    public init() {}
    
    public func parts(for date: Date) -> [MusclePart] {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        return routine[weekday] ?? []
    }
}
