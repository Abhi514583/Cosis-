import SwiftUI

public enum Theme {
    public enum Colors {
        public static let background = Color(hex: "#131313")
        public static let surface = Color(hex: "#131313")
        public static let surfaceBright = Color(hex: "#393939")
        public static let surfaceContainerLowest = Color(hex: "#0e0e0e")
        public static let surfaceContainerLow = Color(hex: "#1b1b1b")
        public static let surfaceContainer = Color(hex: "#1f1f1f")
        public static let surfaceContainerHigh = Color(hex: "#2a2a2a")
        public static let surfaceContainerHighest = Color(hex: "#353535")
        public static let surfaceDim = Color(hex: "#131313")
        
        public static let primary = Color(hex: "#C4524D")
        public static let primaryContainer = Color(hex: "#A03A36")
        public static let onPrimaryContainer = Color(hex: "#FFFFFF")
        
        public static let secondaryContainer = Color(hex: "#2A2A2A")
        public static let outlineVariant = Color(hex: "#4A2A28")
        
        public static let onSurface = Color(hex: "#e2e2e2")
        public static let onSurfaceVariant = Color(hex: "#DDA09E")
        public static let error = Color(hex: "#FF453A")
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
