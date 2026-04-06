import SwiftUI

// MARK: - Haptic Shadow
public struct HapticShadowModifier: ViewModifier {
    public func body(content: Content) -> some View {
        content
            // Simulated ambient glow per the specs: on-surface at 4%, 64px blur
            .shadow(color: Theme.Colors.onSurface.opacity(0.04), radius: 64, x: 0, y: 0)
    }
}

// MARK: - Ghost Border
public struct GhostBorderModifier: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 12) // Default container rounding
                    .stroke(Theme.Colors.outlineVariant.opacity(0.15), lineWidth: 1)
            )
    }
}

public struct GhostBorderWithRadius: ViewModifier {
    let radius: CGFloat
    let opacity: Double
    
    public func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(Theme.Colors.outlineVariant.opacity(opacity), lineWidth: 1)
            )
    }
}

// MARK: - Glassmorphism
public struct GlassmorphismModifier: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .background(
                Theme.Colors.surfaceContainerLowest.opacity(0.7)
            )
            .background(.regularMaterial)
    }
}

// MARK: - Signature Gradient
public struct PrimaryPulseGradient: ShapeStyle {
    public func resolve(in environment: EnvironmentValues) -> some ShapeStyle {
        RadialGradient(
            colors: [Theme.Colors.primary, Theme.Colors.primaryContainer],
            center: .center,
            startRadius: 0,
            endRadius: 150
        ).resolve(in: environment)
    }
}

public extension View {
    func hapticShadow() -> some View {
        self.modifier(HapticShadowModifier())
    }
    
    func ghostBorder() -> some View {
        self.modifier(GhostBorderModifier())
    }
    
    func ghostBorder(radius: CGFloat, opacity: Double = 0.15) -> some View {
        self.modifier(GhostBorderWithRadius(radius: radius, opacity: opacity))
    }
    
    func glassmorphism() -> some View {
        self.modifier(GlassmorphismModifier())
    }
}
