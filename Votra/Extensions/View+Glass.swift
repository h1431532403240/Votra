//
//  View+Glass.swift
//  Votra
//
//  Convenience extension for Liquid Glass styling in macOS 26.
//

import SwiftUI

extension View {
    /// Apply glass effect with configurable opacity
    /// - Parameter minOpacity: Minimum opacity for the glass effect (default: 0.3)
    /// - Returns: Modified view with glass effect
    func liquidGlass(minOpacity: Double = 0.3) -> some View {
        self
            .background(.ultraThinMaterial)
            .opacity(max(minOpacity, 0.3)) // Ensure minimum opacity per FR-022
    }

    /// Apply glass effect to a container
    /// - Parameter cornerRadius: Corner radius for the glass container
    /// - Returns: Modified view with glass container effect
    func glassContainer(cornerRadius: CGFloat = 16) -> some View {
        self
            .background(.ultraThinMaterial, in: .rect(cornerRadius: cornerRadius))
    }

    /// Apply subtle glass effect for overlays
    /// - Returns: Modified view with subtle glass effect
    func subtleGlass() -> some View {
        self
            .background(.ultraThinMaterial)
    }

    /// Apply prominent glass effect for main containers
    /// - Returns: Modified view with prominent glass effect
    func prominentGlass() -> some View {
        self
            .background(.thickMaterial)
    }
}

// MARK: - Glass Button Style

/// Button style with glass-like appearance
struct GlassButtonStyle: ButtonStyle {
    var isProminent: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                isProminent ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary.opacity(0.2)),
                in: .rect(cornerRadius: 8)
            )
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == GlassButtonStyle {
    /// Glass button style for Liquid Glass UI
    static var glass: GlassButtonStyle { GlassButtonStyle() }

    /// Prominent glass button style
    static var prominentGlass: GlassButtonStyle { GlassButtonStyle(isProminent: true) }
}

// MARK: - Glass Card Modifier

/// View modifier for glass card styling
struct GlassCardModifier: ViewModifier {
    var padding: CGFloat = 16
    var cornerRadius: CGFloat = 12

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(.ultraThinMaterial, in: .rect(cornerRadius: cornerRadius))
    }
}

extension View {
    /// Apply glass card styling
    /// - Parameters:
    ///   - padding: Internal padding for the card
    ///   - cornerRadius: Corner radius of the card
    /// - Returns: View with glass card styling
    func glassCard(padding: CGFloat = 16, cornerRadius: CGFloat = 12) -> some View {
        modifier(GlassCardModifier(padding: padding, cornerRadius: cornerRadius))
    }
}
