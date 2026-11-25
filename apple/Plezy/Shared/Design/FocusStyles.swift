import SwiftUI

/// Focus and press styles. tvOS moves focus with the remote, so a focused control must stand out from across a room:
/// it lifts and turns white, as the system's own rows do. On iOS and macOS focus comes from a keyboard (iPad keyboards,
/// macOS keyboard navigation) and shows as a white ring hugging the control; touch and clicks dim a pressed control.

/// A button drawn as a filled rounded surface: stream rows, choice rows, panels that act as one button, chips.
///
/// - tvOS: focused, the surface turns the text colour under the background's (white under black on a dark theme),
///   never the accent; it doesn't grow or lift (a row in a list, not a card).
///   A click shrinks it while Select is down (`tvPressed`).
///   The style colours its label for either state, and a colour set inside the label wins over it (white on the white
///   surface): the label's text and symbols take the hierarchical styles (`.primary`, `.secondary`), or
///   `mutedForeground()` and `accentForeground()` for the theme's muted and accent colours, never a palette colour.
///   A text link (`outset`: an album's artist) is its words alone at rest; focused, the surface is a capsule, as Play's
///   and the alphabet's are, reaching `outset` past the words, which stay where they rest.
/// - iOS, macOS: the surface dims while pressed and shows the focus ring while it has keyboard focus.
struct SurfaceButtonStyle: ButtonStyle {
    var fill: Color = Palette.surfaceContainer
    var radius: CGFloat = Radius.large
    var outset: EdgeInsets?

    func makeBody(configuration: Configuration) -> some View {
        SurfaceButton(configuration: configuration, fill: fill, radius: radius, outset: outset)
    }

    private struct SurfaceButton: View {
        let configuration: Configuration
        let fill: Color
        let radius: CGFloat
        let outset: EdgeInsets?
        @Environment(\.isFocused) private var focused
        @Environment(\.isEnabled) private var enabled

        var body: some View {
            let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
            #if os(tvOS)
            let surface = focused ? Palette.focusedSurface : fill
            configuration.label
                .foregroundStyle(focused ? Palette.onFocusedSurface : Palette.onBackground)
                .environment(\.onFocusedSurface, focused)
                .background {
                    if let outset {
                        Capsule().fill(surface)
                            .padding(EdgeInsets(top: -outset.top, leading: -outset.leading, bottom: -outset.bottom, trailing: -outset.trailing))
                    } else {
                        shape.fill(surface)
                    }
                }
                .opacity(enabled ? 1 : 0.5)
                .effectsAnimation(.easeOut(duration: 0.15), value: focused)
                .tvPressed(configuration.isPressed)
            #else
            configuration.label
                .background(fill, in: shape)
                .contentShape(shape)
                .opacity(configuration.isPressed ? 0.7 : enabled ? 1 : 0.5)
                .focusRing(radius: radius)
            #endif
        }
    }
}

extension EnvironmentValues {
    /// The content sits on a focused tvOS surface, which is white (`SurfaceButtonStyle`): colours chosen for the black
    /// background (badges) turn around.
    @Entry var onFocusedSurface = false
}

extension View {
    /// Secondary text and symbols (a row's subtitle, a hint, a status line) in the theme's muted colour
    /// (`Palette.onSurfaceVariant`), so an accent palette tints them as it does the rest. On a focused Apple TV row (the
    /// system's white platter, `SurfaceButtonStyle`'s) the secondary level of the row's own text instead, which the
    /// muted colour would vanish into.
    func mutedForeground() -> some View {
        modifier(FocusAwareForeground(resting: Palette.onSurfaceVariant, focused: .secondary))
    }

    /// `mutedForeground()` for text over a backdrop picture (`Palette.onBackdropVariant`).
    func backdropMutedForeground() -> some View {
        modifier(FocusAwareForeground(resting: Palette.onBackdropVariant, focused: .secondary))
    }

    /// Text and symbols in the theme's accent (`Palette.primary`: a link, a letter of an index). On a focused Apple TV
    /// control (the white platter) the control's own text colour instead, which the accent (white on a dark theme)
    /// would vanish into.
    func accentForeground() -> some View {
        modifier(FocusAwareForeground(resting: Palette.primary, focused: .primary))
    }
}

private struct FocusAwareForeground: ViewModifier {
    let resting: Color
    let focused: HierarchicalShapeStyle

    @Environment(\.isFocused) private var isFocused

    func body(content: Content) -> some View {
        #if os(tvOS)
        content.foregroundStyle(isFocused ? AnyShapeStyle(focused) : AnyShapeStyle(resting))
        #else
        content.foregroundStyle(resting)
        #endif
    }
}

/// A poster or tile that is a button: the tvOS card style (lift, parallax highlight) on tvOS; elsewhere the artwork
/// dims while pressed and shows the focus ring on keyboard focus. A `circular` card (an artist, a cast member) is a
/// circle to the focus effect too: the card style's plate, lift and highlight and the pointer's highlight on iPad.
struct CardButtonStyleModifier: ViewModifier {
    var circular = false

    func body(content: Content) -> some View {
        #if os(tvOS)
        if circular {
            content.buttonStyle(.card).contentShape(.hoverEffect, Circle())
        } else {
            content.buttonStyle(.card)
        }
        #elseif os(iOS)
        if circular {
            content.buttonStyle(PressDimButtonStyle()).contentShape(.hoverEffect, Circle())
        } else {
            content.buttonStyle(PressDimButtonStyle())
        }
        #else
        content.buttonStyle(PressDimButtonStyle())
        #endif
    }
}

/// Dims the label while pressed; nothing else. Focus rings are drawn by the label where it knows its shape.
struct PressDimButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.opacity(configuration.isPressed ? 0.7 : 1)
    }
}

extension View {
    /// Poster and tile buttons: see `CardButtonStyleModifier`.
    func cardButtonStyle(circular: Bool = false) -> some View {
        modifier(CardButtonStyleModifier(circular: circular))
    }

    /// A white ring around this view while it (or the button it is the label of) has keyboard focus (iOS, macOS).
    /// tvOS styles draw focus themselves, so there it does nothing.
    func focusRing(radius: CGFloat) -> some View {
        modifier(FocusRing(radius: radius))
    }
}

#if os(tvOS)
extension View {
    /// The app's own tvOS button styles' answer to a click, as the system's buttons give one: while Select is down on
    /// the focused control it shrinks to 96 % of the size its focus look gives it, and comes back as Select is let go.
    /// A hold that opens the control's context menu leaves the style's press set after the menu has closed (tvOS 26),
    /// so a press held past `menuHold` counts as the menu's and the control comes back at once.
    func tvPressed(_ pressed: Bool) -> some View {
        modifier(TvPressed(pressed: pressed))
    }
}

private struct TvPressed: ViewModifier {
    let pressed: Bool

    /// Under the system's long press that opens a context menu.
    private static let menuHold: Duration = .milliseconds(400)

    @State private var held = false

    func body(content: Content) -> some View {
        let shrunk = pressed && !held
        content
            .scaleEffect(shrunk ? 0.96 : 1)
            .effectsAnimation(.easeOut(duration: 0.1), value: shrunk)
            .task(id: pressed) {
                held = false
                guard pressed else { return }
                try? await Task.sleep(for: Self.menuHold)
                if !Task.isCancelled { held = true }
            }
    }
}
#endif

private struct FocusRing: ViewModifier {
    let radius: CGFloat
    @Environment(\.isFocused) private var focused

    func body(content: Content) -> some View {
        #if os(tvOS)
        content
        #else
        // Only while focused: an invisible ring still widened the control's accessibility frame by its outset.
        content.overlay {
            if focused {
                RoundedRectangle(cornerRadius: radius + 3, style: .continuous)
                    .strokeBorder(Palette.focusRing, lineWidth: 2)
                    .padding(-3)
            }
        }
        #endif
    }
}
