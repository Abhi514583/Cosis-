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

public struct Exercise: Identifiable, Hashable {
    public let id = UUID()
    public let name: String
    public let musclePartName: String // Links to MusclePart.name
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
}

public struct ActiveWorkoutSession: Identifiable {
    public let id = UUID()
    public var date: Date
    public var exerciseLogs: [ExerciseLog] = []
}

public class WorkoutDataManager: ObservableObject {
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
        Exercise(name: "Barbell Bench Press", musclePartName: "CHEST"),
        Exercise(name: "Incline Dumbbell Press", musclePartName: "CHEST"),
        Exercise(name: "Cable Crossovers", musclePartName: "CHEST"),
        Exercise(name: "Deadlift", musclePartName: "BACK"),
        Exercise(name: "Pull-ups", musclePartName: "BACK"),
        Exercise(name: "Bent Over Rows", musclePartName: "BACK"),
        Exercise(name: "Squats", musclePartName: "LEGS"),
        Exercise(name: "Leg Press", musclePartName: "LEGS"),
        Exercise(name: "Lunges", musclePartName: "LEGS"),
        Exercise(name: "Overhead Press", musclePartName: "SHOULDERS"),
        Exercise(name: "Lateral Raises", musclePartName: "SHOULDERS"),
        Exercise(name: "Bicep Curls", musclePartName: "BICEPS"),
        Exercise(name: "Hammer Curls", musclePartName: "BICEPS"),
        Exercise(name: "Tricep Pushdowns", musclePartName: "TRICEPS"),
        Exercise(name: "Skull Crushers", musclePartName: "TRICEPS"),
        Exercise(name: "Plank", musclePartName: "ABS"),
        Exercise(name: "Crunches", musclePartName: "ABS"),
        Exercise(name: "Running", musclePartName: "CARDIO"),
        Exercise(name: "Cycling", musclePartName: "CARDIO")
    ]
    
    public init() {}
    
    public func parts(for date: Date) -> [MusclePart] {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        return routine[weekday] ?? []
    }
}
