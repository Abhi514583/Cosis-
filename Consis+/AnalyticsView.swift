import SwiftUI

public struct AnalyticsView: View {
    public var body: some View {
        ZStack {
            Theme.Colors.surface.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    TopBarView(title: "Analytics")
                    
                    VStack(alignment: .leading, spacing: 32) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("TOTAL VOLUME")
                                .technicalMicroCopy()
                                .foregroundColor(Theme.Colors.onSurfaceVariant)
                            
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text("42.5")
                                    .font(Typography.displayLarge)
                                    .foregroundColor(Theme.Colors.primary)
                                Text("k lbs")
                                    .font(Typography.titleLarge)
                                    .foregroundColor(Theme.Colors.onSurfaceVariant)
                            }
                        }
                        
                        HStack(spacing: 16) {
                            MetricCardView(title: "WORKOUTS", value: "12", unit: "")
                            MetricCardView(title: "PRS", value: "3", unit: "", primaryTheme: true)
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Heatmap Placeholder
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Consistency")
                            .font(Typography.headlineMedium)
                            .foregroundColor(Theme.Colors.onSurface)
                        
                        RoundedRectangle(cornerRadius: 32)
                            .fill(Theme.Colors.surfaceContainerLow)
                            .frame(height: 200)
                            .ghostBorder(radius: 32)
                            .overlay(
                                Text("Calendar & Heatmap Data")
                                    .font(Typography.labelMedium)
                                    .foregroundColor(Theme.Colors.onSurfaceVariant)
                            )
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer(minLength: 120)
                }
            }
        }
    }
}

#Preview {
    AnalyticsView()
}
