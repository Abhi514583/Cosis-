import SwiftUI

public struct AnalyticsView: View {
    @EnvironmentObject var dataManager: WorkoutDataManager
    @State private var selectedMusclePart: String? = nil
    
    public var body: some View {
        ZStack {
            Theme.Colors.surface.ignoresSafeArea()
            
            VStack(spacing: 0) {
                TopBarView(title: "Analytics")
                    .padding(.bottom, 16)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        // 3D Model Header
                        VStack(alignment: .leading, spacing: 16) {
                            Text("BODY VISUALIZER")
                                .technicalMicroCopy()
                                .foregroundColor(dataManager.primaryColor)
                            
                            HumanBodyView { part in
                                withAnimation {
                                    selectedMusclePart = part
                                }
                            }
                            .frame(height: 400)
                        }
                        .padding(.horizontal, 24)
                        
                        // Volume Stats
                        VStack(alignment: .leading, spacing: 32) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("TOTAL VOLUME")
                                    .technicalMicroCopy()
                                    .foregroundColor(Theme.Colors.onSurfaceVariant)
                                
                                HStack(alignment: .firstTextBaseline, spacing: 8) {
                                    // Simulated total volume logic
                                    let totalVol = dataManager.sessions.values.reduce(0.0) { sess, acc in 
                                        sess + acc.exerciseLogs.reduce(0.0) { log, accLog in
                                            log + accLog.sets.reduce(0.0) { $0 + ($1.weight * Double($1.reps)) }
                                        }
                                    }
                                    Text("\(String(format: "%.1f", totalVol / 1000.0))")
                                        .font(Typography.displayLarge)
                                        .foregroundColor(Theme.Colors.primary)
                                    Text("k lbs")
                                        .font(Typography.titleLarge)
                                        .foregroundColor(Theme.Colors.onSurfaceVariant)
                                }
                            }
                            
                            HStack(spacing: 16) {
                                MetricCardView(title: "WORKOUTS", value: "\(dataManager.sessions.count)", unit: "")
                                MetricCardView(title: "PRS", value: "3", unit: "", primaryTheme: true)
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        Spacer(minLength: 120)
                    }
                }
            }
        }
        .sheet(item: Binding(
            get: { selectedMusclePart.map { MuscleSheetItem(name: $0) } },
            set: { selectedMusclePart = $0?.name }
        )) { item in
            AnalyticsDetailView(musclePart: item.name)
        }
    }
}

struct MuscleSheetItem: Identifiable {
    let name: String
    var id: String { name }
}


#Preview {
    AnalyticsView()
}
