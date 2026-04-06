import SwiftUI

public struct MetricCardView: View {
    public var title: String
    public var value: String
    public var unit: String
    public var primaryTheme: Bool
    
    public init(title: String, value: String, unit: String, primaryTheme: Bool = false) {
        self.title = title
        self.value = value
        self.unit = unit
        self.primaryTheme = primaryTheme
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .technicalMicroCopy()
                .foregroundColor(primaryTheme ? Theme.Colors.onSurface : Theme.Colors.onSurfaceVariant)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(Typography.displayLarge)
                    .foregroundColor(primaryTheme ? Theme.Colors.primary : Theme.Colors.onSurface)
                    // High-energy primary focus
                
                Text(unit)
                    .font(Typography.labelLarge)
                    .foregroundColor(Theme.Colors.onSurfaceVariant)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: 32))
        .ghostBorder(radius: 32)
    }
}

#Preview {
    HStack {
        MetricCardView(title: "Volume", value: "8.5", unit: "k lbs", primaryTheme: true)
        MetricCardView(title: "Duration", value: "1h", unit: "15m")
    }
    .padding()
    .background(Theme.Colors.surface)
}
