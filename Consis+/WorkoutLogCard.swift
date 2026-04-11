import SwiftUI

public struct WorkoutLogCard: View {
    @EnvironmentObject var dataManager: WorkoutDataManager
    public var exerciseName: String
    public var sets: [WorkoutSet]
    
    public init(exerciseName: String, sets: [WorkoutSet]) {
        self.exerciseName = exerciseName
        self.sets = sets
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(exerciseName)
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundColor(Theme.Colors.onSurface)
                .padding(.horizontal, 24)
            
            VStack(spacing: 8) { // Small gap between cells
                ForEach(Array(sets.enumerated()), id: \.element.id) { index, workoutSet in
                    HStack(spacing: 16) {
                        Text("\(workoutSet.setNumber)")
                            .font(Typography.labelMedium)
                            .foregroundColor(Theme.Colors.onSurfaceVariant)
                            .frame(width: 24, alignment: .leading)
                        
                        Text("\(workoutSet.weight, specifier: "%.1f") \(dataManager.weightUnit.rawValue.lowercased())")
                            .font(.system(size: 20, weight: .bold, design: .monospaced))
                            .foregroundColor(Theme.Colors.onSurface)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        if workoutSet.isPR {
                            Text("PR")
                                .font(Typography.labelSmall)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Theme.Colors.secondaryContainer)
                                .foregroundColor(Theme.Colors.onSurface)
                                .clipShape(Capsule())
                        }
                        
                        Text("\(workoutSet.reps) reps")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.Colors.primary) // Red focus
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10) // Reduced from 16
                    // Zebra striping
                    .background(index % 2 == 0 ? Theme.Colors.surfaceContainerLow : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 8)
        }
        .padding(.vertical, 16)
    }
}

#Preview {
    WorkoutLogCard(exerciseName: "Barbell Bench Press", sets: [
        WorkoutSet(setNumber: 1, reps: 8, weight: 60),
        WorkoutSet(setNumber: 2, reps: 6, weight: 70),
        WorkoutSet(setNumber: 3, reps: 5, weight: 75, isPR: true)
    ])
    .background(Theme.Colors.surface)
}
