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

public class WorkoutDataManager: ObservableObject {
    @Published public var routine: [Int: [MusclePart]] = [
        2: [MusclePart(name: "CHEST", color: Color(hex: "#FF453A"), icon: "shield.fill"), 
            MusclePart(name: "TRICEPS", color: Color(hex: "#0A84FF"), icon: "bolt.fill")],
        3: [MusclePart(name: "BACK", color: Color(hex: "#30D158"), icon: "figure.walk")],
        4: [MusclePart(name: "LEGS", color: Color(hex: "#FF9F0A"), icon: "flame.fill")]
    ]
    
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
    
    public init() {}
    
    public func parts(for date: Date) -> [MusclePart] {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        return routine[weekday] ?? []
    }
}
