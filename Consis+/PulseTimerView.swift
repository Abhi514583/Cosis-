import SwiftUI

public struct PulseTimerView: View {
    public var progress: Double // 0 to 1
    public var timeRemaining: String
    
    public init(progress: Double, timeRemaining: String) {
        self.progress = progress
        self.timeRemaining = timeRemaining
    }
    
    public var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(Theme.Colors.outlineVariant.opacity(0.3), lineWidth: 8)
            
            // Progress pulse
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Theme.Colors.primary, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear, value: progress)
            
            VStack(spacing: 4) {
                Text(timeRemaining)
                    .font(Typography.displayLarge)
                    .foregroundColor(Theme.Colors.onSurface)
                
                Text("REST")
                    .technicalMicroCopy()
                    .foregroundColor(Theme.Colors.primary)
            }
            // Haptic shadow for the center elements
            .hapticShadow()
        }
        .padding(32)
    }
}

#Preview {
    PulseTimerView(progress: 0.65, timeRemaining: "01:23")
        .frame(width: 300, height: 300)
        .background(Theme.Colors.surface)
}
