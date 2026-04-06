import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var dataManager: WorkoutDataManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.Colors.surface.ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 32) {
                    Text("APP THEME")
                        .technicalMicroCopy()
                        .foregroundColor(Theme.Colors.onSurfaceVariant)
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                    
                    VStack(spacing: 24) {
                        // Primary Color Picker
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Primary Accent")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                Text("Used for buttons and headers")
                                    .font(.system(size: 12))
                                    .foregroundColor(Theme.Colors.onSurfaceVariant.opacity(0.6))
                            }
                            Spacer()
                            ColorPicker("", selection: $dataManager.primaryColor)
                                .labelsHidden()
                        }
                        .padding(20)
                        .background(Theme.Colors.surfaceContainerHigh)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        
                        // Accent/Dot Color Picker
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("System Dot")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                Text("Used for status and activity indicators")
                                    .font(.system(size: 12))
                                    .foregroundColor(Theme.Colors.onSurfaceVariant.opacity(0.6))
                            }
                            Spacer()
                            ColorPicker("", selection: $dataManager.accentColor)
                                .labelsHidden()
                        }
                        .padding(20)
                        .background(Theme.Colors.surfaceContainerHigh)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal, 24)
                    
                    // Preview Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("PREVIEW")
                            .technicalMicroCopy()
                            .foregroundColor(Theme.Colors.onSurfaceVariant)
                        
                        HStack(spacing: 12) {
                            Circle()
                                .fill(dataManager.accentColor)
                                .frame(width: 12, height: 12)
                                .shadow(color: dataManager.accentColor.opacity(0.5), radius: 4)
                            
                            Text("Kinetic Monolith")
                                .font(.system(size: 18, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(24)
                        .background(dataManager.primaryColor.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .ghostBorder(radius: 24, opacity: 0.3)
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.bold)
                        .foregroundColor(dataManager.primaryColor)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    SettingsView()
        .environmentObject(WorkoutDataManager())
}
