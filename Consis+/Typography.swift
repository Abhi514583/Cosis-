import SwiftUI

public enum Typography {
    // We emulate 'Inter' using the system font's sans-serif variable features.
    // Display sizing
    public static let displayLarge = Font.system(size: 56, weight: .bold, design: .default)
    
    // Headline sizing
    public static let headlineLarge = Font.system(size: 32, weight: .semibold, design: .default)
    public static let headlineMedium = Font.system(size: 28, weight: .semibold, design: .default)
    public static let headlineSmall = Font.system(size: 24, weight: .semibold, design: .default)
    
    // Titles
    public static let titleLarge = Font.system(size: 20, weight: .semibold, design: .default)
    public static let titleMedium = Font.system(size: 16, weight: .medium, design: .default)
    
    // Body & Labels
    public static let bodyLarge = Font.system(size: 16, weight: .regular, design: .default)
    public static let bodyMedium = Font.system(size: 14, weight: .regular, design: .default)
    public static let bodySmall = Font.system(size: 12, weight: .regular, design: .default)
    
    public static let labelLarge = Font.system(size: 14, weight: .medium, design: .default)
    public static let labelMedium = Font.system(size: 12, weight: .medium, design: .default)
    public static let labelSmall = Font.system(size: 11, weight: .medium, design: .default).uppercaseSmallCaps()
}

public struct TechnicalMicroCopyModifier: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .font(Typography.labelSmall)
            .textCase(.uppercase)
            .kerning(1.5) // +5% tracking for the "instrument-cluster" aesthetic
    }
}

extension View {
    public func technicalMicroCopy() -> some View {
        self.modifier(TechnicalMicroCopyModifier())
    }
}
