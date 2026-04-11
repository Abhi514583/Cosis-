import SwiftUI

public struct AnalyticsView: View {
    @EnvironmentObject var dataManager: WorkoutDataManager
    @State private var selectedMusclePart: String? = nil
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    
    public var body: some View {
        ZStack {
            Theme.Colors.surface.ignoresSafeArea()
            
            VStack(spacing: 0) {
                TopBarView(title: "Analytics")
                    .padding(.bottom, 16)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        // Year Selector
                        YearSelectorView(selectedYear: $selectedYear)
                            .padding(.horizontal, 24)
                        
                        // Body Photo Mapper
                        VStack(alignment: .leading, spacing: 16) {
                            Text("BODY MAP")
                                .technicalMicroCopy()
                                .foregroundColor(dataManager.primaryColor)
                            
                            BodyPhotoAnalyticsView()
                            
                            WorkoutHeatmapView(year: selectedYear)
                                .padding(.top, 16)
                        }
                        .padding(.horizontal, 24)
                        
                        // Volume Stats
                        VStack(alignment: .leading, spacing: 32) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("\(selectedYear) TOTAL VOLUME")
                                    .technicalMicroCopy()
                                    .foregroundColor(Theme.Colors.onSurfaceVariant)
                                
                                HStack(alignment: .firstTextBaseline, spacing: 8) {
                                    // Year-specific volume logic
                                    let totalVol = dataManager.sessions.values.reduce(0.0) { sess, acc in 
                                        let calendar = Calendar.current
                                        if calendar.component(.year, from: acc.date) == selectedYear {
                                            return sess + acc.exerciseLogs.reduce(0.0) { log, accLog in
                                                log + accLog.sets.reduce(0.0) { $0 + ($1.weight * Double($1.reps)) }
                                            }
                                        }
                                        return sess
                                    }
                                    Text("\(String(format: "%.1f", totalVol / 1000.0))")
                                        .font(Typography.displayLarge)
                                        .foregroundColor(Theme.Colors.primary)
                                    Text("k lbs")
                                        .font(Typography.titleLarge)
                                        .foregroundColor(Theme.Colors.onSurfaceVariant)
                                }
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

struct YearSelectorView: View {
    @Binding var selectedYear: Int
    @EnvironmentObject var dataManager: WorkoutDataManager
    let years = [2024, 2025, 2026]
    
    var body: some View {
        Menu {
            ForEach(years, id: \.self) { year in
                Button(action: {
                    withAnimation(.spring()) {
                        selectedYear = year
                    }
                }) {
                    HStack {
                        Text("\(year)")
                        if selectedYear == year {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .foregroundColor(dataManager.primaryColor)
                Text("\(selectedYear)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Theme.Colors.surfaceContainerHigh)
            .clipShape(Capsule())
            .ghostBorder(radius: 20)
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
