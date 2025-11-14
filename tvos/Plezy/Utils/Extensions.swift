//
//  Extensions.swift
//  Plezy tvOS
//
//  Useful extensions and helpers
//

import SwiftUI

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

struct CardButtonStyle: ButtonStyle {
    @FocusState private var isFocused: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 35)
            .padding(.vertical, 22) // Ensures minimum 44pt height
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.regularMaterial)
                        .opacity(configuration.isPressed ? 0.7 : (isFocused ? 1.0 : 0.8))

                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(configuration.isPressed ? 0.15 : (isFocused ? 0.25 : 0.1)))
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(isFocused ? 0.4 : 0.0), lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.3), radius: isFocused ? 20 : 10, x: 0, y: isFocused ? 10 : 5)
            .scaleEffect(configuration.isPressed ? 0.95 : (isFocused ? 1.08 : 1.0))
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
            .focusEffectDisabled()
            .focused($isFocused)
            .focusable()
    }
}

/// Clear Liquid Glass button style for media overlays
/// Uses highly translucent material ideal for rich media backgrounds
struct ClearGlassButtonStyle: ButtonStyle {
    @FocusState private var isFocused: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 40)
            .padding(.vertical, 22) // Ensures minimum 44pt height
            .background(
                ZStack {
                    // Dark dimming layer (35% opacity) for contrast over bright content
                    Capsule()
                        .fill(Color.black.opacity(0.35))

                    // Clear Liquid Glass material
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .opacity(configuration.isPressed ? 0.7 : (isFocused ? 1.0 : 0.9))
                }
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(isFocused ? 0.6 : 0.3), lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.5), radius: isFocused ? 25 : 12, x: 0, y: isFocused ? 12 : 6)
            .scaleEffect(configuration.isPressed ? 0.95 : (isFocused ? 1.1 : 1.0))
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
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
