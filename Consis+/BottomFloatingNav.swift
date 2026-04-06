import SwiftUI

public struct BottomFloatingNav: View {
    @Binding public var selectedTab: Int
    @Binding public var isPlusMenuOpen: Bool
    @Binding public var selectedDate: Date
    @EnvironmentObject var dataManager: WorkoutDataManager
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }
    
    public init(selectedTab: Binding<Int>, isPlusMenuOpen: Binding<Bool>, selectedDate: Binding<Date>) {
        self._selectedTab = selectedTab
        self._isPlusMenuOpen = isPlusMenuOpen
        self._selectedDate = selectedDate
    }
    
    public var body: some View {
        ZStack {
            if isToday {
                // Standard Navigation
                HStack(spacing: 0) {
                    Spacer()
                    NavItem(icon: "doc.plaintext", title: "Log", index: 0, selectedIndex: $selectedTab)
                    Spacer()
                    
                    // Center PLUS button
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isPlusMenuOpen.toggle()
                        }
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .rotationEffect(.degrees(isPlusMenuOpen ? 45 : 0))
                            .frame(width: 64, height: 48)
                            .background(isPlusMenuOpen ? Theme.Colors.primaryContainer : Theme.Colors.surfaceContainerHigh)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: isPlusMenuOpen ? Theme.Colors.primaryContainer.opacity(0.3) : .clear, radius: 10)
                    }
                    .zIndex(10)
                    
                    Spacer()
                    NavItem(icon: "chart.bar", title: "Stats", index: 1, selectedIndex: $selectedTab)
                    Spacer()
                }
                .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity), removal: .scale.combined(with: .opacity)))
            } else {
                // RESET TO TODAY GLASSPHORMISM BUTTON
                Button(action: {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        selectedDate = Calendar.current.startOfDay(for: Date())
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.uturn.backward.circle.fill")
                            .font(.system(size: 22))
                        Text("BACK TO TODAY")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .kerning(1.2)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(.ultraThinMaterial)
                    .background(dataManager.primaryColor.opacity(0.1))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(LinearGradient(colors: [dataManager.primaryColor.opacity(0.5), .clear, dataManager.primaryColor.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                    )
                    .shadow(color: dataManager.primaryColor.opacity(0.2), radius: 15, x: 0, y: 10)
                }
                .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .move(edge: .bottom).combined(with: .opacity)))
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
        .background(Theme.Colors.surfaceContainerLowest.opacity(0.4))
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isToday)
    }
}

struct NavItem: View {
    var icon: String
    var title: String
    var index: Int
    @Binding var selectedIndex: Int
    
    var body: some View {
        Button(action: {
            withAnimation(.spring) {
                selectedIndex = index
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: selectedIndex == index ? .semibold : .regular))
                Text(title)
                    .font(Typography.labelSmall)
            }
            .foregroundColor(selectedIndex == index ? Theme.Colors.primary : Theme.Colors.onSurfaceVariant.opacity(0.6))
        }
    }
}

#Preview {
    BottomFloatingNav(selectedTab: .constant(0), isPlusMenuOpen: .constant(false), selectedDate: .constant(Date()))
        .environmentObject(WorkoutDataManager())
        .frame(maxHeight: .infinity, alignment: .bottom)
        .background(Theme.Colors.surface)
}
