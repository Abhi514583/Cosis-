import SwiftUI

struct AnalyticsDetailView: View {
    let musclePart: String
    @EnvironmentObject var dataManager: WorkoutDataManager
    @State private var selectedExercise: Exercise?
    
    var body: some View {
        VStack(spacing: 0) {
            // Drag Handle
            Capsule()
                .fill(Color.white.opacity(0.15))
                .frame(width: 36, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.top, 16)
            
            // Header
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(musclePart)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(dataManager.colorForMuscle(musclePart))
                        Text("PROGRESSION")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                    }
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)
            
            // Exercise Selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(dataManager.exercises(for: musclePart)) { ex in
                        Button(action: { withAnimation { selectedExercise = ex } }) {
                            Text(ex.name)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(selectedExercise?.id == ex.id ? .black : .white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 9)
                                .background(selectedExercise?.id == ex.id ? dataManager.colorForMuscle(musclePart) : Theme.Colors.surfaceContainerHigh)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 4)
            }
            
            // History Sheet Content using shared component
            if let ex = selectedExercise {
                ScrollView(showsIndicators: false) {
                    ExerciseHistorySheet(exercise: ex, onSeeMore: nil)
                }
            } else {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.08))
                    Text("Select an exercise to see progress")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                }
                Spacer()
            }
        }
        .background(Theme.Colors.surface.ignoresSafeArea())
        .onAppear {
            if let first = dataManager.exercises(for: musclePart).first {
                selectedExercise = first
            }
        }
    }
}

struct StatSmall: View {
    let title: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.system(size: 10, weight: .bold)).foregroundColor(.gray)
            Text(value).font(.system(size: 20, weight: .black, design: .rounded)).foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Theme.Colors.surfaceContainerHigh)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}
