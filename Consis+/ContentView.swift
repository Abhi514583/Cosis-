import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var dataManager = WorkoutDataManager()
    @State private var selectedTab = 0
    @State private var isPlusMenuOpen = false
    @State private var selectedDate = Date()
    @State private var isBuildingRoutine = false
    @State private var isStartingWorkout = false
    @State private var isSettingsOpen = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.Colors.surface.ignoresSafeArea()
            
            Group {
                switch selectedTab {
                case 0:
                    HomeWorkoutLogView(selectedDate: $selectedDate)
                case 1:
                    AnalyticsView()
                default:
                    HomeWorkoutLogView(selectedDate: $selectedDate)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Blurred Overlay for Plus Menu
            if isPlusMenuOpen {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring()) { isPlusMenuOpen = false }
                    }
                
                VStack(spacing: 20) {
                    PlusMenuItem(title: "Start Workout", icon: "play.fill", color: dataManager.accentColor) {
                        isStartingWorkout = true
                        isPlusMenuOpen = false
                    }
                    
                    PlusMenuItem(title: "Build Routine", icon: "hammer.fill", color: dataManager.primaryColor) {
                        isBuildingRoutine = true
                        isPlusMenuOpen = false
                    }
                    
                    PlusMenuItem(title: "Settings", icon: "gearshape.fill", color: .gray) {
                        isSettingsOpen = true
                        isPlusMenuOpen = false
                    }
                    
                    Spacer().frame(height: 100) // Space for bottom nav
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(5)
            }
            
            BottomFloatingNav(selectedTab: $selectedTab, isPlusMenuOpen: $isPlusMenuOpen, selectedDate: $selectedDate)
        }
        .environmentObject(dataManager)
        .fullScreenCover(isPresented: $isBuildingRoutine) {
            BuildRoutineView()
                .environmentObject(dataManager)
        }
        .fullScreenCover(isPresented: $isStartingWorkout) {
            // Placeholder for Start Workout
            ZStack {
                Theme.Colors.surface.ignoresSafeArea()
                VStack {
                    Text("Starting Workout...")
                        .font(Typography.headlineLarge)
                    Button("Close") { isStartingWorkout = false }
                        .padding()
                }
            }
        }
        .sheet(isPresented: $isSettingsOpen) {
            SettingsView()
                .environmentObject(dataManager)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .preferredColorScheme(.dark)
    }
}

struct PlusMenuItem: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                Text(title.uppercased())
                    .font(.system(size: 16, weight: .black, design: .rounded))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 20)
            .background(Theme.Colors.surfaceContainerHigh)
            .clipShape(Capsule())
            .ghostBorder(radius: 32, opacity: 0.3)
            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        }
    }
}

#Preview {
    ContentView()
}
