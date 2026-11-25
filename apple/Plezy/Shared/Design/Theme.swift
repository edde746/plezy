import SwiftUI
import PlezyKit
#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// The theme on screen: the session's `AppTheme` (`AppSession.appearance`) as SwiftUI colours. A theme with a palette
/// paints it whatever the system's appearance; System (no palette) paints Light or Dark as the system's appearance is,
/// each colour resolving where it is drawn as the system's own do. One per process: the app has one window and one
/// session. `AppModel` sets it from its first frame on and as the appearance changes; before a session the device's
/// default paints (OLED on Apple TV, System elsewhere). Views read it through `Palette`, which SwiftUI observes.
@MainActor
@Observable
final class ThemeState {
    static let shared = ThemeState()

    /// The theme painted.
    private(set) var theme: AppTheme? = nil
    /// The colour roles of `theme`.
    private(set) var colors: ThemeColors
    /// The appearance the system's chrome takes: the palette's, or nil (System) to follow the system.
    private(set) var colorScheme: ColorScheme?

    private init() {
        #if os(tvOS)
        let initial = AppTheme(mode: .oled, palette: PlezyKit.Palette.companion.OLED, lockedStored: nil)
        #else
        let initial = AppTheme(mode: .system, palette: nil, lockedStored: nil)
        #endif
        theme = initial
        colors = ThemeColors(initial)
        colorScheme = initial.palette.map { $0.isDark ? .dark : .light }
        #if os(macOS)
        NSApp?.appearance = colorScheme.map { NSAppearance(named: $0 == .dark ? .darkAqua : .aqua) } ?? nil
        #endif
    }

    /// Paints `theme` from now on; the same theme again changes nothing.
    func apply(_ theme: AppTheme) {
        if let current = self.theme, current.isEqual(theme) { return }
        self.theme = theme
        colors = ThemeColors(theme)
        colorScheme = theme.palette.map { $0.isDark ? .dark : .light }
        #if os(macOS)
        // The window's title bar and toolbar, its sheets, alerts and panels, the menus: the theme's appearance.
        NSApp?.appearance = colorScheme.map { NSAppearance(named: $0 == .dark ? .darkAqua : .aqua) } ?? nil
        #else
        styleWindows()
        #endif
    }

    #if !os(macOS)
    /// Sets every window's interface style (UIKit's, which SwiftUI's colour scheme, the system's chrome, alerts and
    /// keyboard take) to the palette's, or to unspecified (System) to follow the system's appearance live: as the theme
    /// changes, and as a window's root shows (`plezyTheme`). On the windows themselves: `preferredColorScheme` going
    /// back to nil leaves the style a palette set in place.
    func styleWindows() {
        let style: UIUserInterfaceStyle = switch colorScheme {
        case .dark: .dark
        case .light: .light
        default: .unspecified
        }
        for window in UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).flatMap(\.windows) {
            window.overrideUserInterfaceStyle = style
        }
    }
    #endif
}

/// The colour roles of one theme. Dark and OLED paint the app's own palette: Apple's dark grouped greys for the surfaces,
/// white text and controls, on black screens (OLED) or Dark's near-black (its shared palette's background, as Compose
/// paints it). System paints the system's semantic colours, so light and dark and Increase
/// Contrast come from the OS; Light paints them in the light appearance. An accent palette (Ember, Glacier, Forest, Plum,
/// Paper, a custom one) takes its accent as `primary` (the tint, progress, the keyboard focus ring); Paper keeps the
/// light semantic surfaces, the others their background and surface, the higher steps lighter on a dark palette and
/// darker on a light one, each a step further with Increase Contrast.
struct ThemeColors {
    let background: Color
    let onBackground: Color
    let onSurfaceVariant: Color
    let primary: Color
    let onPrimary: Color
    let outline: Color
    let surfaceContainerLow: Color
    let surfaceContainer: Color
    let surfaceContainerHigh: Color
    let surfaceContainerHighest: Color
    let error: Color
    /// Apple TV's primary button at rest: the accent as a solid tint over the background (40 % on a dark theme, 50 % on
    /// a light one), apart from a secondary's glass while only focus turns a control white.
    let primaryRest: Color
}

extension ThemeColors {
    init(_ theme: AppTheme) {
        switch theme.mode {
        case .system: self = .system
        case .oled: self = .dark
        case .dark: self = .dark.over(Color(argb: PlezyKit.Palette.companion.DARK.bg))
        case .light: self = .light
        default:
            guard let palette = theme.palette else {
                self = .system
                return
            }
            self = theme.mode == .paper ? Self.light.accented(palette) : ThemeColors(palette)
        }
    }

    /// The app's own dark palette.
    static let dark = ThemeColors(
        background: .black,
        onBackground: .white,
        onSurfaceVariant: Color(Color(rgb: 0xEBEBF5).opacity(0.6), increased: Color(rgb: 0xEBEBF5).opacity(0.7)),
        primary: .white,
        onPrimary: .black,
        outline: Color(rgb: 0x38383A, increased: 0x545456),
        surfaceContainerLow: Color(rgb: 0x0F0F0F),
        surfaceContainer: Color(rgb: 0x1C1C1E, increased: 0x242426),
        surfaceContainerHigh: Color(rgb: 0x2C2C2E, increased: 0x363638),
        surfaceContainerHighest: Color(rgb: 0x3A3A3C, increased: 0x444446),
        error: Color(rgb: 0xFF453A, increased: 0xFF6961),
        primaryRest: Color(rgb: 0x666666)
    )

    /// The system's light grouped colours, but for the secondary text: the system's secondary label (3C3C43 at 60 %)
    /// reads 3.3:1 on the grouped background, so it takes the label's Increase Contrast level, 80 % (90 % with it on),
    /// at least 4.5:1 on the background and every surface step.
    static let light = ThemeColors(
        background: Color(rgb: 0xF2F2F7, increased: 0xEBEBF0),
        onBackground: .black,
        onSurfaceVariant: Color(Color(rgb: 0x3C3C43).opacity(0.8), increased: Color(rgb: 0x3C3C43).opacity(0.9)),
        primary: .black,
        onPrimary: .white,
        outline: Color(rgb: 0xC6C6C8, increased: 0xA6A6AA),
        surfaceContainerLow: Color(rgb: 0xF7F7FA),
        surfaceContainer: .white,
        surfaceContainerHigh: Color(rgb: 0xE5E5EA, increased: 0xD8D8DC),
        surfaceContainerHighest: Color(rgb: 0xD1D1D6, increased: 0xC0C0C6),
        error: Color(rgb: 0xFF3B30, increased: 0xD70015),
        primaryRest: Color(rgb: 0x79797C)
    )

    /// The system's semantic colours: `light` or `dark` as the appearance is, resolved where they are drawn.
    static var system: ThemeColors {
        let light = ThemeColors.light, dark = ThemeColors.dark
        return ThemeColors(
            background: Color(light: light.background, dark: dark.background),
            onBackground: Color(light: light.onBackground, dark: dark.onBackground),
            onSurfaceVariant: Color(light: light.onSurfaceVariant, dark: dark.onSurfaceVariant),
            primary: Color(light: light.primary, dark: dark.primary),
            onPrimary: Color(light: light.onPrimary, dark: dark.onPrimary),
            outline: Color(light: light.outline, dark: dark.outline),
            surfaceContainerLow: Color(light: light.surfaceContainerLow, dark: dark.surfaceContainerLow),
            surfaceContainer: Color(light: light.surfaceContainer, dark: dark.surfaceContainer),
            surfaceContainerHigh: Color(light: light.surfaceContainerHigh, dark: dark.surfaceContainerHigh),
            surfaceContainerHighest: Color(light: light.surfaceContainerHighest, dark: dark.surfaceContainerHighest),
            error: Color(light: light.error, dark: dark.error),
            primaryRest: Color(light: light.primaryRest, dark: dark.primaryRest)
        )
    }

    /// These surfaces and text with `palette`'s accent.
    private func accented(_ palette: PlezyKit.Palette) -> ThemeColors {
        ThemeColors(
            background: background, onBackground: onBackground, onSurfaceVariant: onSurfaceVariant,
            primary: Color(argb: palette.accent), onPrimary: Color(argb: palette.onAccent), outline: outline,
            surfaceContainerLow: surfaceContainerLow, surfaceContainer: surfaceContainer,
            surfaceContainerHigh: surfaceContainerHigh, surfaceContainerHighest: surfaceContainerHighest, error: error,
            primaryRest: Color(argb: Self.mix(0xFFF2_F2F7, palette.accent, 0.5))
        )
    }

    /// These colours on `background` instead.
    private func over(_ background: Color) -> ThemeColors {
        ThemeColors(
            background: background, onBackground: onBackground, onSurfaceVariant: onSurfaceVariant,
            primary: primary, onPrimary: onPrimary, outline: outline,
            surfaceContainerLow: surfaceContainerLow, surfaceContainer: surfaceContainer,
            surfaceContainerHigh: surfaceContainerHigh, surfaceContainerHighest: surfaceContainerHighest, error: error,
            primaryRest: primaryRest
        )
    }

    /// An accent palette's own background and surface, the steps above it toward its text.
    private init(_ palette: PlezyKit.Palette) {
        let surface = palette.surface, text = palette.text
        func step(_ amount: Double) -> Color {
            Color(Color(argb: Self.mix(surface, text, amount)), increased: Color(argb: Self.mix(surface, text, amount + 0.04)))
        }
        self.init(
            background: Color(argb: palette.bg),
            onBackground: Color(argb: text),
            onSurfaceVariant: Color(argb: palette.textMuted),
            primary: Color(argb: palette.accent),
            onPrimary: Color(argb: palette.onAccent),
            outline: Color(argb: palette.outline),
            surfaceContainerLow: Color(argb: Self.mix(palette.bg, surface, 0.5)),
            surfaceContainer: Color(argb: surface),
            surfaceContainerHigh: step(0.07),
            surfaceContainerHighest: step(0.13),
            error: palette.isDark ? ThemeColors.dark.error : ThemeColors.light.error,
            primaryRest: Color(argb: Self.mix(palette.bg, palette.accent, palette.isDark ? 0.4 : 0.5))
        )
    }

    /// `from` moved `amount` (0–1) of the way to `to`, opaque, as `0xAARRGGBB`.
    private static func mix(_ from: Int64, _ to: Int64, _ amount: Double) -> Int64 {
        var result: Int64 = 0xFF00_0000
        for shift in [16, 8, 0] {
            let a = Double((from >> Int64(shift)) & 0xFF), b = Double((to >> Int64(shift)) & 0xFF)
            result |= Int64((a + (b - a) * amount).rounded()) << Int64(shift)
        }
        return result
    }
}

/// The app's colour roles, the theme's (`ThemeState`) but for those of the video, which stay as they are whatever the
/// theme: the player's controls draw white over the picture. Read in a view's body, a role follows the theme.
enum Palette {
    @MainActor private static var colors: ThemeColors { ThemeState.shared.colors }

    /// Screens, bars and the areas behind grouped rows.
    @MainActor static var background: Color { colors.background }
    /// Text and icons on `background`.
    @MainActor static var onBackground: Color { colors.onBackground }
    /// Secondary text: hints, status lines, captions.
    @MainActor static var onSurfaceVariant: Color { colors.onSurfaceVariant }
    /// Secondary text over a backdrop picture (the detail page's facts, its episode rows): the text colour a little
    /// dimmed, since the muted colour falls under 4.5:1 on a light or saturated picture.
    @MainActor static var onBackdropVariant: Color { colors.onBackground.opacity(0.75) }
    /// The emphasised fill: selection, progress (the theme's accent).
    @MainActor static var primary: Color { colors.primary }
    /// Text and icons on `primary`.
    @MainActor static var onPrimary: Color { colors.onPrimary }
    /// Hairlines and text fields' outlines.
    @MainActor static var outline: Color { colors.outline }
    /// Text, symbols and fills over the video (the player's controls, menus and panels): pure white, the player's
    /// foreground style (`PlayerScreen`), so a control there draws in it without naming a colour.
    static let onVideo = Color.white
    /// The player's secondary level (`.secondary` over the video: the episode line, why the controls are off): `onVideo`
    /// at 60 %, at 70 % with Increase Contrast (the secondary label's step).
    static let onVideoSecondary = Color(onVideo.opacity(0.6), increased: onVideo.opacity(0.7))
    /// Surfaces from the lowest to the highest emphasis: sheets and panels, grouped rows and cards, solid badges and
    /// pressed or selected rows, artwork while it loads.
    @MainActor static var surfaceContainerLow: Color { colors.surfaceContainerLow }
    @MainActor static var surfaceContainer: Color { colors.surfaceContainer }
    @MainActor static var surfaceContainerHigh: Color { colors.surfaceContainerHigh }
    @MainActor static var surfaceContainerHighest: Color { colors.surfaceContainerHighest }
    /// Apple TV's primary button at rest (`ThemeColors.primaryRest`).
    @MainActor static var primaryRest: Color { colors.primaryRest }
    /// A tonal badge on a focused tvOS surface: a mid grey under the dark text.
    static let focusedTonalBadge = Color(white: 0.62)
    /// Errors: the system's red for the appearance.
    @MainActor static var error: Color { colors.error }
    /// The player's live dot, beside LIVE over the video: the one red of a live playback (Compose's `PlezyColors.Live`).
    static let live = Color(rgb: 0xE5251B)
    /// The keyboard focus ring (iOS, macOS): the accent. tvOS's focus never takes it: its styles lift and turn white.
    @MainActor static var focusRing: Color { colors.primary }
    /// A focused tvOS surface (`SurfaceButtonStyle`) and what is drawn on it: the text colour under the background's,
    /// whatever the accent.
    @MainActor static var focusedSurface: Color { colors.onBackground }
    @MainActor static var onFocusedSurface: Color { colors.background }
    static let scrim = Color.black
    /// A switch that is on: the system's own green (iOS) or the Mac's accent colour, which keep the knob visible
    /// whatever the theme's accent.
    #if os(macOS)
    static let switchOn = Color.accentColor
    #else
    static let switchOn = Color.green
    #endif
}

/// Corner radii.
enum Radius {
    static let extraSmall: CGFloat = 6
    static let small: CGFloat = 10
    static let medium: CGFloat = 14
    static let large: CGFloat = 20
}

extension Color {
    /// An opaque sRGB colour from `0xRRGGBB`.
    init(rgb: UInt32) {
        self.init(
            .sRGB,
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255
        )
    }

    /// An opaque sRGB colour from `0xRRGGBB`, `increased` while Increase Contrast is on.
    init(rgb: UInt32, increased: UInt32) {
        self.init(Color(rgb: rgb), increased: Color(rgb: increased))
    }

    /// `normal`, or `increased` while Increase Contrast is on (`colorSchemeContrast == .increased`), resolved where it
    /// is drawn as the system's colours are: from the trait collection (iOS, tvOS) or the appearance (macOS).
    init(_ normal: Color, increased: Color) {
        #if os(macOS)
        let high: [NSAppearance.Name] = [.accessibilityHighContrastDarkAqua, .accessibilityHighContrastAqua]
        self.init(nsColor: NSColor(name: nil) { appearance in
            let match = appearance.bestMatch(from: [.darkAqua, .aqua] + high)
            return NSColor(match.map(high.contains) == true ? increased : normal)
        })
        #else
        self.init(uiColor: UIColor { $0.accessibilityContrast == .high ? UIColor(increased) : UIColor(normal) })
        #endif
    }

    /// `light` in the light appearance, `dark` in the dark one, resolved where it is drawn.
    init(light: Color, dark: Color) {
        #if os(macOS)
        self.init(nsColor: NSColor(name: nil) { appearance in
            let match = appearance.bestMatch(from: [.darkAqua, .aqua, .accessibilityHighContrastDarkAqua, .accessibilityHighContrastAqua])
            return NSColor(match == .darkAqua || match == .accessibilityHighContrastDarkAqua ? dark : light)
        })
        #else
        self.init(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light) })
        #endif
    }

    /// A colour from a shared `0xAARRGGBB` value (`Palette`, `ProfileAvatar.background`).
    init(argb: Int64) {
        let value = UInt32(truncatingIfNeeded: argb)
        self.init(
            .sRGB,
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255,
            opacity: Double((value >> 24) & 0xFF) / 255
        )
    }
}

extension View {
    /// The theme (`ThemeState`) for everything below: its appearance (none for System, which follows the system's)
    /// and its accent as the tint. On iPhone, iPad and Apple TV the appearance is the windows' interface style
    /// (`ThemeState.apply`), not `preferredColorScheme`, which going back to nil from a palette's leaves that palette's
    /// in place. tvOS keeps the system's tint: its alerts and dialogs draw their labels in the tint, which would vanish
    /// into a focused entry. Every window's root applies it once.
    func plezyTheme() -> some View {
        modifier(ThemeModifier())
    }
}

private struct ThemeModifier: ViewModifier {
    func body(content: Content) -> some View {
        #if os(tvOS)
        content.onAppear { ThemeState.shared.styleWindows() }
        #elseif os(iOS)
        content
            .tint(Palette.primary)
            .onAppear { ThemeState.shared.styleWindows() }
        #else
        content
            .preferredColorScheme(ThemeState.shared.colorScheme)
            .tint(Palette.primary)
        #endif
    }
}
