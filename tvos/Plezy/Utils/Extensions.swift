//
//  Extensions.swift
//  Plezy tvOS
//
//  Useful extensions and helpers
//

import SwiftUI
import Combine

// MARK: - View Extensions

extension View {
    /// Makes a view focusable with a focus change callback
    func onFocusChange(_ isFocusable: Bool = true, perform action: @escaping (Bool) -> Void) -> some View {
        self.modifier(FocusableModifier(isFocusable: isFocusable, onFocusChange: action))
    }
}

struct FocusableModifier: ViewModifier {
    let isFocusable: Bool
    let onFocusChange: (Bool) -> Void
    @FocusState private var isFocused: Bool

    func body(content: Content) -> some View {
        content
            .focusable(isFocusable)
            .focused($isFocused)
            .onChange(of: isFocused) { _, newValue in
                onFocusChange(newValue)
            }
    }
}

// MARK: - Button Styles

/// Media Card button style for tvOS focus engine
/// Designed for poster/card-based media browsing with proper focus indication
struct MediaCardButtonStyle: ButtonStyle {
    let isFocused: FocusState<Bool>.Binding

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .focusEffectDisabled()
            .focused(isFocused)
            .focusable()
    }
}

/// Card button style with Liquid Glass design for tvOS
/// Uses regularMaterial for depth and vibrancy
struct CardButtonStyle: ButtonStyle {
    @FocusState private var isFocused: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 40)
            .padding(.vertical, 24) // Ensures minimum 44pt touch target
            .background(
                ZStack {
                    // Liquid Glass background
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.regularMaterial)
                        .opacity(configuration.isPressed ? 0.7 : (isFocused ? 1.0 : 0.85))

                    // Vibrancy layer
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
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
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: isFocused ? [.white.opacity(0.5), .white.opacity(0.25)] : [.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isFocused ? 2.5 : 0
                    )
            )
            .shadow(color: .black.opacity(0.35), radius: isFocused ? 25 : 12, x: 0, y: isFocused ? 12 : 6)
            .scaleEffect(configuration.isPressed ? 0.94 : (isFocused ? 1.09 : 1.0))
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isFocused)
            .animation(.spring(response: 0.2, dampingFraction: 0.65), value: configuration.isPressed)
            .focusEffectDisabled()
            .focused($isFocused)
            .focusable()
    }
}

/// Clear Liquid Glass button style for media overlays
/// Uses highly translucent material ideal for rich media backgrounds with strong vibrancy
struct ClearGlassButtonStyle: ButtonStyle {
    @FocusState private var isFocused: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 48)
            .padding(.vertical, 24) // Ensures minimum 44pt touch target
            .background(
                ZStack {
                    // Dark dimming layer for contrast over bright content
                    Capsule()
                        .fill(Color.black.opacity(0.4))

                    // Clear Liquid Glass material with vibrancy
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .opacity(configuration.isPressed ? 0.65 : (isFocused ? 1.0 : 0.88))

                    // Additional vibrancy overlay when focused
                    if isFocused {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.white.opacity(0.18), .white.opacity(0.10)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                }
            )
            .overlay(
                Capsule()
                    .strokeBorder(
                        LinearGradient(
                            colors: isFocused ? [.white.opacity(0.7), .white.opacity(0.4)] : [.white.opacity(0.35)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isFocused ? 2.5 : 1.5
                    )
            )
            .shadow(color: .black.opacity(0.55), radius: isFocused ? 30 : 15, x: 0, y: isFocused ? 14 : 7)
            .scaleEffect(configuration.isPressed ? 0.94 : (isFocused ? 1.11 : 1.0))
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isFocused)
            .animation(.spring(response: 0.2, dampingFraction: 0.65), value: configuration.isPressed)
            .focusEffectDisabled()
            .focused($isFocused)
            .focusable()
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

// MARK: - Color Extensions

extension Color {
    static let plexOrange = Color(red: 0.9, green: 0.6, blue: 0.0)
    static let plexYellow = Color(red: 1.0, green: 0.8, blue: 0.0)
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
