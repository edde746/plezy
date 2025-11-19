//
//  Extensions.swift
//  Beacon tvOS
//
//  Useful extensions and helpers
//

import SwiftUI
import Combine

// MARK: - View Extensions

extension View {
    /// Disables ScrollView clipping on tvOS when the API is available.
    /// Keeps focus-scaled content (like cards) from having their corners cut off.
    @ViewBuilder
    func tvOSScrollClipDisabled() -> some View {
        if #available(tvOS 17.0, *) {
            self.scrollClipDisabled()
        } else {
            self
        }
    }
}

// MARK: - Button Styles

/// Media Card button style for tvOS focus engine
/// Designed for poster/card-based media browsing with Apple's automatic focus behavior
/// The system handles scale, animation, and parallax effects automatically
struct MediaCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .focusable()
    }
}

/// Card button style with Liquid Glass design for tvOS
/// Uses regularMaterial for depth and vibrancy
/// Focus state is tracked for visual styling only - Apple handles focus behavior
struct CardButtonStyle: ButtonStyle {
    @Environment(\.isFocused) private var isFocused: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 40)
            .padding(.vertical, DesignTokens.spacingXLarge) // Ensures minimum 44pt touch target
            .background(
                ZStack {
                    // Liquid Glass background
                    RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusLarge, style: .continuous)
                        .fill(.regularMaterial)
                        .opacity(configuration.isPressed ? 0.7 : (isFocused ? 1.0 : DesignTokens.materialOpacityButton))

                    // Vibrancy layer
                    RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusLarge, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(configuration.isPressed ? 0.12 : (isFocused ? 0.28 : 0.15)),
                                    Color.white.opacity(configuration.isPressed ? 0.08 : (isFocused ? 0.20 : 0.10))
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusLarge, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: isFocused ? [.white.opacity(0.5), .white.opacity(0.25)] : [.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isFocused ? DesignTokens.borderWidthFocused : 0
                    )
            )
            .contentShape(RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusLarge, style: .continuous))
            .shadow(
                color: DesignTokens.Shadow.cardFocused.color,
                radius: isFocused ? DesignTokens.Shadow.cardFocused.radius : DesignTokens.Shadow.cardUnfocused.radius,
                x: 0,
                y: isFocused ? DesignTokens.Shadow.cardFocused.y : DesignTokens.Shadow.cardUnfocused.y
            )
            .scaleEffect(configuration.isPressed ? DesignTokens.pressScale : 1.0)
            .animation(DesignTokens.Animation.press.spring(), value: configuration.isPressed)
    }
}

/// Clear Liquid Glass button style for media overlays
/// Uses highly translucent material ideal for rich media backgrounds with strong vibrancy
/// Focus state is tracked for visual styling only - Apple handles focus behavior
struct ClearGlassButtonStyle: ButtonStyle {
    @Environment(\.isFocused) private var isFocused: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 48)
            .padding(.vertical, DesignTokens.spacingXLarge) // Ensures minimum 44pt touch target
            .background(
                ZStack {
                    // Dark dimming layer for contrast over bright content
                    Capsule()
                        .fill(Color.black.opacity(DesignTokens.materialOpacityDimming))

                    // Clear Liquid Glass material with vibrancy
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .opacity(configuration.isPressed ? 0.65 : (isFocused ? 1.0 : 0.88))

                    // Beacon gradient fill when focused
                    if isFocused {
                        Capsule()
                            .fill(Color.beaconGradient)
                            .opacity(0.4)
                    }
                }
            )
            .contentShape(Capsule())
            .shadow(
                color: isFocused ? Color.beaconPurple.opacity(0.5) : DesignTokens.Shadow.buttonFocused.color,
                radius: isFocused ? DesignTokens.Shadow.buttonFocused.radius : DesignTokens.Shadow.buttonUnfocused.radius,
                x: 0,
                y: isFocused ? DesignTokens.Shadow.buttonFocused.y : DesignTokens.Shadow.buttonUnfocused.y
            )
            .scaleEffect(configuration.isPressed ? DesignTokens.pressScale : 1.0)
            .animation(DesignTokens.Animation.press.spring(), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == CardButtonStyle {
    static var card: CardButtonStyle {
        CardButtonStyle()
    }
}

extension ButtonStyle where Self == ClearGlassButtonStyle {
    static var clearGlass: ClearGlassButtonStyle {
        ClearGlassButtonStyle()
    }
}

// MARK: - Liquid Glass View Modifiers

extension View {
    /// Applies a Liquid Glass background effect with beacon gradient accent
    /// Perfect for cards, panels, and elevated UI elements
    func liquidGlassBackground(cornerRadius: CGFloat = DesignTokens.cornerRadiusXLarge, opacity: Double = DesignTokens.materialOpacityFull) -> some View {
        LiquidGlassBackgroundModifier(cornerRadius: cornerRadius, opacity: opacity, content: self)
    }
}

struct LiquidGlassBackgroundModifier<Content: View>: View {
    let cornerRadius: CGFloat
    let opacity: Double
    let content: Content

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        content
            .background(
                ZStack {
                    if reduceTransparency {
                        // Solid color fallback for Reduce Transparency
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(Color.beaconSurface)
                    } else {
                        // Base glass material
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(.regularMaterial)
                            .opacity(opacity)

                        // Beacon gradient vibrancy overlay
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.beaconBlue.opacity(0.12),
                                        Color.beaconPurple.opacity(0.10),
                                        Color.beaconMagenta.opacity(0.08)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .blendMode(.plusLighter)
                    }
                }
            )
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

extension View {
    /// Applies an ultra-thin Liquid Glass effect for overlays
    /// Ideal for navigation bars, toolbars, and floating panels
    func thinLiquidGlass(cornerRadius: CGFloat = DesignTokens.cornerRadiusMedium) -> some View {
        ThinLiquidGlassModifier(cornerRadius: cornerRadius, content: self)
    }
}

struct ThinLiquidGlassModifier<Content: View>: View {
    let cornerRadius: CGFloat
    let content: Content

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        content
            .background(
                ZStack {
                    if reduceTransparency {
                        // Solid color fallback for Reduce Transparency
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(Color.beaconSurface.opacity(0.7))
                    } else {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(.ultraThinMaterial)

                        // Subtle beacon accent
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(DesignTokens.materialOpacitySubtle),
                                        Color.beaconPurple.opacity(0.08)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .blendMode(.overlay)
                    }
                }
            )
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

extension View {
    /// Applies a beacon gradient border
    func beaconBorder(cornerRadius: CGFloat = DesignTokens.cornerRadiusLarge, lineWidth: CGFloat = 2) -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.beaconBlue,
                            Color.beaconPurple,
                            Color.beaconMagenta
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: lineWidth
                )
        )
    }

    /// Applies a subtle beacon glow shadow
    func beaconGlow(radius: CGFloat = 20, opacity: Double = 0.4) -> some View {
        self.shadow(
            color: Color.beaconPurple.opacity(opacity),
            radius: radius,
            x: 0,
            y: DesignTokens.spacingXSmall
        )
    }
}

// MARK: - Responsive Scaling

/// Helper for responsive scaling based on screen size
enum ResponsiveScale {
    /// Base width for 1080p Apple TV (1920px)
    static let baseWidth: CGFloat = 1920

    /// Get scaling factor for current screen
    static func factor(for width: CGFloat) -> CGFloat {
        return width / baseWidth
    }

    /// Scale a value based on screen width
    static func scaled(_ value: CGFloat, for width: CGFloat) -> CGFloat {
        return value * factor(for: width)
    }
}

extension View {
    /// Get the current screen width for responsive scaling
    func withResponsiveScale<Content: View>(@ViewBuilder content: @escaping (CGFloat) -> Content) -> some View {
        GeometryReader { geometry in
            content(ResponsiveScale.factor(for: geometry.size.width))
        }
    }
}

// MARK: - Design Tokens

/// Liquid Glass Design System Tokens
/// Centralized constants for consistent UI implementation across tvOS app
enum DesignTokens {
    // MARK: - Corner Radius
    /// Small corner radius (8pt) - For compact elements, small buttons
    static let cornerRadiusSmall: CGFloat = 8

    /// Medium corner radius (12pt) - For standard buttons, controls
    static let cornerRadiusMedium: CGFloat = 12

    /// Large corner radius (14pt) - For cards, panels, primary buttons
    static let cornerRadiusLarge: CGFloat = 14

    /// Extra large corner radius (16pt) - For media cards, containers
    static let cornerRadiusXLarge: CGFloat = 16

    /// Hero corner radius (20pt) - For hero banners, large featured content
    static let cornerRadiusHero: CGFloat = 20

    // MARK: - Material Opacity
    /// Full material opacity (0.95) - Primary cards and containers
    static let materialOpacityFull: Double = 0.95

    /// Button material opacity (0.85) - Interactive elements
    static let materialOpacityButton: Double = 0.85

    /// Hero material opacity (0.30) - Progress indicators on hero content
    static let materialOpacityHero: Double = 0.30

    /// Subtle material opacity (0.15) - Background tints, subtle overlays
    static let materialOpacitySubtle: Double = 0.15

    /// Dimming overlay opacity (0.40) - Dark overlays for contrast
    static let materialOpacityDimming: Double = 0.40

    // MARK: - Spacing Scale
    /// 4pt - Minimum spacing
    static let spacingXXSmall: CGFloat = 4

    /// 8pt - Compact spacing
    static let spacingXSmall: CGFloat = 8

    /// 12pt - Standard small spacing
    static let spacingSmall: CGFloat = 12

    /// 16pt - Medium spacing
    static let spacingMedium: CGFloat = 16

    /// 20pt - Standard large spacing
    static let spacingLarge: CGFloat = 20

    /// 24pt - Extra large spacing
    static let spacingXLarge: CGFloat = 24

    /// 32pt - Section spacing
    static let spacingXXLarge: CGFloat = 32

    /// 40pt - Major section spacing
    static let spacingXXXLarge: CGFloat = 40

    /// 60pt - Hero spacing
    static let spacingHero: CGFloat = 60

    // MARK: - Shadow Presets
    struct Shadow {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat

        /// Standard unfocused shadow for cards
        static let cardUnfocused = Shadow(
            color: Color.black.opacity(0.35),
            radius: 12,
            x: 0,
            y: 6
        )

        /// Focused shadow for cards with enhanced depth
        static let cardFocused = Shadow(
            color: Color.black.opacity(0.35),
            radius: 25,
            x: 0,
            y: 12
        )

        /// Unfocused shadow for buttons
        static let buttonUnfocused = Shadow(
            color: Color.black.opacity(0.55),
            radius: 15,
            x: 0,
            y: 7
        )

        /// Focused shadow for buttons with maximum depth
        static let buttonFocused = Shadow(
            color: Color.black.opacity(0.55),
            radius: 30,
            x: 0,
            y: 14
        )

        /// Subtle shadow for overlays
        static let overlay = Shadow(
            color: Color.black.opacity(0.25),
            radius: 10,
            x: 0,
            y: 4
        )
    }

    // MARK: - Animation Presets
    struct Animation {
        let response: Double
        let dampingFraction: Double

        /// Standard focus animation (response: 0.35, damping: 0.75)
        static let focus = Animation(response: 0.35, dampingFraction: 0.75)

        /// Press animation (response: 0.2, damping: 0.65)
        static let press = Animation(response: 0.2, dampingFraction: 0.65)

        /// Quick animation for filters (response: 0.2, damping: 0.7)
        static let quick = Animation(response: 0.2, dampingFraction: 0.7)

        /// Smooth transition (response: 0.4, damping: 0.8)
        static let smooth = Animation(response: 0.4, dampingFraction: 0.8)

        /// Create SwiftUI spring animation
        func spring() -> SwiftUI.Animation {
            .spring(response: response, dampingFraction: dampingFraction)
        }
    }

    // MARK: - Focus Scale
    /// Standard focus scale (1.12) - Applied to most interactive elements
    static let focusScale: CGFloat = 1.12

    /// Press scale (0.94) - Applied when button is pressed
    static let pressScale: CGFloat = 0.94

    // MARK: - Border Width
    /// Standard border width for unfocused elements
    static let borderWidthUnfocused: CGFloat = 1.5

    /// Border width for focused elements
    static let borderWidthFocused: CGFloat = 2.5

    /// Thick border for emphasized focus states
    static let borderWidthFocusedThick: CGFloat = 4.0

    // MARK: - Icon Sizes
    /// Small icon size (20pt)
    static let iconSizeSmall: CGFloat = 20

    /// Medium icon size (24pt)
    static let iconSizeMedium: CGFloat = 24

    /// Large icon size (28pt)
    static let iconSizeLarge: CGFloat = 28

    /// Extra large icon size (32pt)
    static let iconSizeXLarge: CGFloat = 32
}

// MARK: - Color Extensions

extension Color {
    // MARK: - Beacon Design System Colors

    // Background Colors
    static let beaconBackground = Color(hex: "#0f0f0f")
    static let beaconSurface = Color(hex: "#1a1a1a")
    static let beaconSurfaceHover = Color(hex: "#242424")
    static let beaconSurfaceSecondary = Color(hex: "#2a2a2a")

    // Gradient Colors (Individual Stops)
    static let beaconBlue = Color(hex: "#2962ff")
    static let beaconPurple = Color(hex: "#7c4dff")
    static let beaconMagenta = Color(hex: "#e91e63")
    static let beaconRed = Color(hex: "#f44336")
    static let beaconOrange = Color(hex: "#ff6b35")

    // Text Colors
    static let beaconTextPrimary = Color(hex: "#ffffff")
    static let beaconTextSecondary = Color(hex: "#e0e0e0")
    static let beaconTextTertiary = Color(hex: "#a0a0a0")
    static let beaconTextDisabled = Color(hex: "#666666")

    // Primary Gradient (for buttons, CTAs, progress bars)
    static var beaconGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                beaconBlue,
                beaconPurple,
                beaconMagenta,
                beaconRed,
                beaconOrange
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    // Gradient overlay at 60% opacity (for hover effects)
    static func beaconGradientOverlay(opacity: Double = 0.6) -> LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                beaconBlue.opacity(opacity),
                beaconPurple.opacity(opacity),
                beaconMagenta.opacity(opacity),
                beaconRed.opacity(opacity),
                beaconOrange.opacity(opacity)
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    // Helper to create Color from hex string
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
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    // Legacy colors for backward compatibility
    static let plexOrange = beaconOrange
    static let plexYellow = beaconOrange
}

// MARK: - Date Extensions

extension Date {
    func timeAgo() -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: self, to: now)

        if let years = components.year, years > 0 {
            return "\(years) year\(years == 1 ? "" : "s") ago"
        }
        if let months = components.month, months > 0 {
            return "\(months) month\(months == 1 ? "" : "s") ago"
        }
        if let days = components.day, days > 0 {
            return "\(days) day\(days == 1 ? "" : "s") ago"
        }
        if let hours = components.hour, hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        }
        if let minutes = components.minute, minutes > 0 {
            return "\(minutes) minute\(minutes == 1 ? "" : "s") ago"
        }

        return "Just now"
    }
}

// MARK: - String Extensions

extension String {
    func truncated(to length: Int, addEllipsis: Bool = true) -> String {
        if self.count <= length {
            return self
        }

        let endIndex = self.index(self.startIndex, offsetBy: length)
        let truncated = String(self[..<endIndex])

        return addEllipsis ? truncated + "..." : truncated
    }
}

// MARK: - URLRequest Extensions

extension URLRequest {
    mutating func addPlexHeaders(token: String? = nil) {
        setValue("application/json", forHTTPHeaderField: "Accept")
        setValue("application/json", forHTTPHeaderField: "Content-Type")
        setValue(PlexAPIClient.plexProduct, forHTTPHeaderField: "X-Plex-Product")
        setValue(PlexAPIClient.plexVersion, forHTTPHeaderField: "X-Plex-Version")
        setValue(PlexAPIClient.plexClientIdentifier, forHTTPHeaderField: "X-Plex-Client-Identifier")
        setValue(PlexAPIClient.plexPlatform, forHTTPHeaderField: "X-Plex-Platform")

        // Get system version for tvOS
        #if os(tvOS)
        setValue(ProcessInfo.processInfo.operatingSystemVersionString, forHTTPHeaderField: "X-Plex-Platform-Version")
        setValue("Apple TV", forHTTPHeaderField: "X-Plex-Device-Name")
        #else
        setValue("Unknown", forHTTPHeaderField: "X-Plex-Platform-Version")
        setValue("Unknown Device", forHTTPHeaderField: "X-Plex-Device-Name")
        #endif

        setValue(PlexAPIClient.plexDevice, forHTTPHeaderField: "X-Plex-Device")

        if let token = token {
            setValue(token, forHTTPHeaderField: "X-Plex-Token")
        }
    }
}
