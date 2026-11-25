import SwiftUI
import PlezyKit

/// The player's sizes and fonts per platform: the touch targets of iOS, the Mac's denser bar, the TV seen from across
/// the room.
enum PlayerMetrics {
    #if os(tvOS)
    static let icon: CGFloat = 30
    static let button: CGFloat = 46
    /// A button's platter: its symbol's frame and 10 pt around it (`PlayerIconButton`), AVKit's 66 pt circle.
    static let buttonFrame: CGFloat = button + 20
    static let edge: CGFloat = 0
    static let osdTop: CGFloat = 40
    /// The corner's card and button: their distance from the safe area's bottom while the controls are down.
    static let cornerInset: CGFloat = 0
    /// Between what is over the video: the corner's card and button, them and the controls' top while those are up, and
    /// on iOS the messages at the top and what is in the middle.
    static let overlayGap: CGFloat = 24
    static let timelineSpacing: CGFloat = 24
    /// Between a lifted subtitle line and the top of the bottom controls.
    static let subtitleGap: CGFloat = 16
    static let titleFont = Font.title2.weight(.bold)
    static let subtitleFont = Font.caption.weight(.medium)
    static let timeFont = Font.caption.weight(.semibold).monospacedDigit()
    /// The timeline's times (`TVTimeline`), AVKit's: caption 2, bold.
    static let timelineTimeFont = Font.caption2.weight(.bold).monospacedDigit()
    /// The live label's red dot and its gap to LIVE (`LiveLabel`): the approved 10 dp and 8 dp beside 16 sp, in
    /// proportion to this time font; and play/pause to the label, the row's gap between buttons.
    static let liveDot: CGFloat = 16
    static let liveDotGap: CGFloat = 12
    static let liveLabelGap: CGFloat = 28
    static let menuSpacing: CGFloat = 28
    /// The play/pause flash's circle and glyph (`PlayerTransportFlash`).
    static let transportPlay: CGFloat = 120
    static let transportPlayIcon: CGFloat = 60
    static let cardRadius: CGFloat = 40
    static let cardWidth: CGFloat = 440
    static let cardPadding: CGFloat = 24
    static let cardSpacing: CGFloat = 6
    static let cardButtonSpacing: CGFloat = 16
    static let cardLabelFont = Font.caption.weight(.medium)
    static let cardTitleFont = Font.callout.weight(.semibold)
    static let cardButtonFont = Font.callout.weight(.semibold)
    static let cardButtonInsets = EdgeInsets(top: 12, leading: 32, bottom: 12, trailing: 32)
    static let errorActionSpacing: CGFloat = 24
    static let errorMaxWidth: CGFloat = 1000
    static let errorStackedWidth: CGFloat = 640
    static let promptActionSpacing: CGFloat = 24
    static let promptRadius: CGFloat = 40
    static let promptMaxWidth: CGFloat = 1000
    /// The panel across the bottom (`PlayerTVPanel`): its padding across, and its width, 1798 pt, its glass a little
    /// past the screen's safe area (1760 pt across) and its content within it.
    static let panelPadding: CGFloat = 40
    static let panelWidth: CGFloat = 1798
    /// The regular glass (`playerGlass`); iOS and iPadOS 26 take the clear one.
    static let clearGlass = false
    #elseif os(macOS)
    static let icon: CGFloat = 15
    static let button: CGFloat = 28
    static let edge: CGFloat = 20
    /// Under the title bar's row: the messages at the top where they don't clear the title on it.
    static let osdTop: CGFloat = 56
    static let cornerInset: CGFloat = 20
    static let overlayGap: CGFloat = 12
    static let timelineSpacing: CGFloat = 10
    static let subtitleGap: CGFloat = 8
    static let titleFont = Font.headline
    static let subtitleFont = Font.subheadline
    static let timeFont = Font.callout.weight(.medium).monospacedDigit()
    static let liveDot: CGFloat = 10
    static let liveDotGap: CGFloat = 8
    /// Play/pause to the live label: the transport's spacing (`ControlBar`).
    static let liveLabelGap: CGFloat = 14
    static let menuSpacing: CGFloat = 0
    /// The options menu's ways to start a watch-together room show without symbols on the Mac, with them on iOS.
    static let menuStartSymbols = false
    /// The transport's buttons (`PlayerTransport`) and their symbols: the episodes', back and forward's, play/pause's.
    static let transportEpisode = button
    static let transportEpisodeIcon = icon
    static let transportSkip = button
    static let transportSkipIcon = icon
    static let transportPlay: CGFloat = 36
    static let transportPlayIcon: CGFloat = 22
    static let cardRadius: CGFloat = 20
    static let cardWidth: CGFloat = 300
    static let cardPadding: CGFloat = 14
    static let cardSpacing: CGFloat = 3
    static let cardButtonSpacing: CGFloat = 8
    static let cardLabelFont = Font.caption.weight(.medium)
    static let cardTitleFont = Font.headline
    static let cardButtonFont = Font.callout.weight(.semibold)
    static let cardButtonInsets = EdgeInsets(top: 6, leading: 18, bottom: 6, trailing: 18)
    static let errorActionSpacing: CGFloat = 10
    static let errorMaxWidth: CGFloat = 560
    static let errorStackedWidth: CGFloat = 280
    static let promptActionSpacing: CGFloat = 10
    static let promptRadius: CGFloat = 22
    static let promptMaxWidth: CGFloat = 560
    /// The volume slider's width (`VolumeControl`), and half its mini knob: where its track starts and ends inside it.
    static let volumeWidth: CGFloat = 100
    static let volumeKnobRadius: CGFloat = 7

    /// The regular glass (`playerGlass`); iOS and iPadOS 26 take the clear one.
    static let clearGlass = false
    #else
    static let icon: CGFloat = 17
    static let button: CGFloat = 44
    static let edge: CGFloat = 16
    /// The controls' distance from the safe area's top and bottom (`TouchControls`); the messages at the top sit as far
    /// down, level with the top bar's buttons, where they fit between them.
    static let barInset: CGFloat = 8
    /// Under the top bar: the messages at the top where they don't fit beside its buttons.
    static let osdTop: CGFloat = 72
    static let cornerInset = barInset
    static let overlayGap: CGFloat = 12
    static let timelineSpacing: CGFloat = 12
    static let subtitleGap: CGFloat = 8
    static let titleFont = Font.headline
    static let subtitleFont = Font.subheadline
    static let timeFont = Font.footnote.weight(.semibold).monospacedDigit()
    static let liveDot: CGFloat = 10
    static let liveDotGap: CGFloat = 8
    static let menuSpacing: CGFloat = 0
    static let menuStartSymbols = true
    static let transportEpisode: CGFloat = 44
    static let transportEpisodeIcon: CGFloat = 20
    static let transportSkip: CGFloat = 56
    static let transportSkipIcon: CGFloat = 24
    static let transportPlay: CGFloat = 72
    static let transportPlayIcon: CGFloat = 32
    static let cardRadius: CGFloat = 22
    static let cardWidth: CGFloat = 300
    /// The narrowest a card may be beside the centre transport: its title and buttons still read whole there.
    static let cardMinWidth: CGFloat = 160
    static let cardPadding: CGFloat = 16
    static let cardSpacing: CGFloat = 3
    static let cardButtonSpacing: CGFloat = 8
    static let cardLabelFont = Font.caption.weight(.medium)
    static let cardTitleFont = Font.headline
    static let cardButtonFont = Font.subheadline.weight(.semibold)
    static let cardButtonInsets = EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20)
    /// A card's buttons where the card is narrowed beside the centre transport (`CardButtons`).
    static let cardNarrowButtonInsets = EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
    static let errorActionSpacing: CGFloat = 10
    /// The error's column: its lines stay short across a landscape iPhone.
    static let errorMaxWidth: CGFloat = 460
    /// The error's buttons one above the other (an upright iPhone), each as wide as the others.
    static let errorStackedWidth: CGFloat = 300
    static let promptActionSpacing: CGFloat = 10
    static let promptRadius: CGFloat = 22
    static let promptMaxWidth: CGFloat = 560
    /// iOS and iPadOS 26 draw the player in clear glass (`playerGlass`); before 26, the thin material.
    static var clearGlass: Bool {
        guard #available(iOS 26, *) else { return false }
        return true
    }
    #endif
}

extension View {
    /// Part of the controls: a pointer moving over it keeps them up (`PointerMove`), an iPad's trackpad or mouse; they
    /// hide on their timer once it rests. The Mac's moves over the player reach the store from its window
    /// (`PlayerWindowChrome`), over the controls or not.
    func controlRegion(_ store: PlayerStore) -> some View {
        #if os(iOS)
        onContinuousHover { phase in
            if case .active = phase { _ = store.onInput(event: InputEventPointerMove.shared) }
        }
        #else
        self
        #endif
    }

    /// Liquid Glass in `shape` (iOS, macOS and tvOS 26), else the system's thin material; `interactive` glass reacts
    /// to touch. Where `PlayerMetrics.clearGlass` (iOS and iPadOS 26) it is the clear glass Apple puts over media,
    /// dimmed by 45 % black inside it: the video shows through unblurred, and a white symbol keeps 3:1 over a white
    /// frame. (The clear glass adds a light veil of its own, which the dimming covers: 40 % under the glass left 2.1:1.)
    /// Over an HDR picture (`hdrPicture`) every glass has that black inside, through `ControlsScrim`: the video behind
    /// it can be several times as bright as the white on it. The shape is also the accessibility frame of what the glass
    /// holds: without it, an accessibility container in Liquid Glass with an AppKit slider in it (the Mac's volume)
    /// takes the slider's frame for its own (with two sliders, their union), set inside the glass or around it.
    func playerGlass<S: Shape>(in shape: S, interactive: Bool = false) -> some View {
        modifier(PlayerGlass(shape: shape, interactive: interactive))
    }

    /// A text button of the player's panels; `prominent` for the panel's primary action. tvOS: `PlayerTVButtonStyle`'s
    /// capsule platter, which focus turns white; iOS and macOS: glass (26), else the bordered styles, the prominent one
    /// white. The Mac fills a glass button with the tint, and the player's is white (`Palette.onVideo`): there the other
    /// buttons drop it, so they stay neutral glass beside the white primary one (`glassButtonStyle`).
    @ViewBuilder
    func playerActionStyle(prominent: Bool = false) -> some View {
        #if os(tvOS)
        buttonStyle(PlayerTVButtonStyle(shape: Capsule(), prominent: prominent, insets: EdgeInsets(top: 14, leading: 32, bottom: 14, trailing: 32)))
        #else
        if #available(iOS 26, macOS 26, *) {
            if prominent {
                buttonStyle(.glassProminent).tint(Palette.onVideo).foregroundStyle(.black)
            } else {
                #if os(macOS)
                buttonStyle(.glass).tint(Color?.none)
                #else
                buttonStyle(.glass)
                #endif
            }
        } else if prominent {
            buttonStyle(.borderedProminent).tint(Palette.onVideo).foregroundStyle(.black)
        } else {
            buttonStyle(.bordered)
        }
        #endif
    }
}

extension EnvironmentValues {
    /// The player's picture goes out as HDR (`PlayerUiState.hdrPicture`): what the controls draw behind themselves
    /// goes through `ControlsScrim`.
    @Entry var hdrPicture = false
    /// Apple TV's transport bar is out of focus's way under a menu (`TVControls`): disabled for focus but drawn at full
    /// strength, as AVKit's is; a control disabled on its own account still dims (`playerDisabled`).
    @Entry var playerControlsAside = false
    /// Apple TV: a player control that is off but keeps focus (`playerOff`): drawn dimmed, as a disabled one.
    @Entry var playerControlOff = false
}

extension View {
    /// Disables a player control on its own account (no episode that way, a guest's speed or play/pause): on tvOS it
    /// dims even while the transport bar steps aside under a menu.
    func playerDisabled(_ disabled: Bool) -> some View {
        self.disabled(disabled).transformEnvironment(\.playerControlsAside) { if disabled { $0 = false } }
    }

    /// A player control that goes off and on while focus may rest on it (the episode buttons): on tvOS it stays
    /// focusable, drawn dimmed, and its caller ignores its presses, since the focus engine moves focus off a disabled
    /// view and the button would take it from the viewer as it turns off (Previous at a restart). Elsewhere disabled.
    @ViewBuilder
    func playerOff(_ off: Bool) -> some View {
        #if os(tvOS)
        environment(\.playerControlOff, off)
        #else
        playerDisabled(off)
        #endif
    }
}

private struct PlayerGlass<S: Shape>: ViewModifier {
    let shape: S
    let interactive: Bool
    @Environment(\.hdrPicture) private var hdr

    func body(content: Content) -> some View {
        let dim = PlayerMetrics.clearGlass || hdr ? Double(ControlsScrim.shared.alpha(alpha: 0.45, hdr: hdr)) : 0
        Group {
            if #available(iOS 26, macOS 26, tvOS 26, *) {
                if PlayerMetrics.clearGlass {
                    content.background(.black.opacity(dim), in: shape)
                        .glassEffect(interactive ? .clear.interactive() : .clear, in: shape)
                } else {
                    content.background(.black.opacity(dim), in: shape)
                        .glassEffect(interactive ? .regular.interactive() : .regular, in: shape)
                }
            } else {
                content.background(.black.opacity(dim), in: shape)
                    .background(.ultraThinMaterial, in: shape)
            }
        }
        .contentShape(.accessibility, shape)
    }
}

extension View {
    /// The controls' muted text over the video (why the controls are off): secondary, and primary over an HDR picture
    /// (`ControlsScrim.textMuted`).
    func playerMuted() -> some View {
        modifier(PlayerMutedText())
    }
}

private struct PlayerMutedText: ViewModifier {
    @Environment(\.hdrPicture) private var hdr

    func body(content: Content) -> some View {
        content.foregroundStyle(ControlsScrim.shared.textMuted(hdr: hdr) ? .secondary : .primary)
    }
}

/// Darkens the video behind the controls, so white glyphs and text read over bright video: `ControlsScrim`'s gradient
/// over the whole player, full width with no edges of its own, eased from black at the top and bottom edges to clear.
/// The edge the title and the episode line sit at reaches far enough in under them that they read at 4.5:1 or more over
/// a white frame (`ControlsScrim.reach`): the bottom on iOS and tvOS, from the far side of the title lines (`titleTop`,
/// global), and the top on the Mac, from the title row's bottom (`titleBottom`, global). On tvOS no scrim at the top, as
/// AVKit's player has none. Over an HDR picture darker, through `ControlsScrim.alpha`.
struct PlayerScrim: View {
    var titleTop: CGFloat?
    var titleBottom: CGFloat?

    @Environment(\.hdrPicture) private var hdr
    @State private var frame = CGRect.zero

    var body: some View {
        LinearGradient(stops: stops, startPoint: .top, endPoint: .bottom)
            // Measured as drawn, edge to edge: the frame outside `ignoresSafeArea` would be the safe area's.
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frame = $0 }
            .ignoresSafeArea()
            .allowsHitTesting(false)
    }

    private var stops: [Gradient.Stop] {
        let scrim = ControlsScrim.shared
        let height = Float(frame.height)
        let topText = titleBottom.map { Float($0 - frame.minY) } ?? 0
        let bottomText = titleTop.map { Float(frame.maxY - $0) } ?? 0
        #if os(tvOS)
        let top: Float = 0
        #else
        let top = scrim.reach(text: topText, height: height)
        #endif
        let bottom = scrim.reach(text: bottomText, height: height)
        return scrim.stops(hdr: hdr, top: top, bottom: bottom).map { .init(color: .black.opacity(Double($0.alpha)), location: CGFloat($0.position)) }
    }
}

/// A round player button with an SF Symbol: `label` for accessibility (and `value`, a menu's current choice), the
/// Compose player's probe name as its identifier. No background of its own: it sits in a glass group, or the caller
/// gives it its own glass. `selected` marks an open panel; `busy` puts a spinner in place of the symbol (the button
/// still acts); `badged` puts a dot by the symbol (the options with the picture zoomed or a shader on); `struck` strikes
/// the symbol through (the subtitles while the subtitle shortcut hid them); `tooltip` is the Mac's in place of `label`
/// (a chapter button names its chapter). With `repeating`, a press held as long as a long press runs it at once and then
/// every 200 ms until let go (`PressRepeat`), and the release that ends the hold doesn't run `action`. Disabled, its
/// symbol dims inside the glass: Liquid Glass draws at full strength through an opacity around it. tvOS:
/// `PlayerTVButtonStyle`'s round platter, which focus turns white.
struct PlayerIconButton: View {
    let systemImage: String
    let label: String
    var value: String?
    let id: String
    var selected = false
    var size: CGFloat = PlayerMetrics.button
    var iconSize: CGFloat = PlayerMetrics.icon
    var busy = false
    var badged = false
    var struck = false
    var tooltip: String?
    let action: () -> Void
    var repeating: (() -> Void)?

    @State private var press = PressRepeat()

    /// The symbol's share of `iconSize` at the text size: 1 at the default, following Dynamic Type as the body does.
    @ScaledMetric(relativeTo: .body) private var symbolScale: CGFloat = 1
    @Environment(\.isEnabled) private var enabled

    var body: some View {
        Button { if press.click() { action() } } label: {
            #if os(tvOS)
            symbol
                .font(.system(size: iconSize, weight: .medium))
                .frame(width: size, height: size)
                .padding(10)
            #else
            symbol
                .font(.system(size: iconSize * symbolScale, weight: .semibold))
                .opacity(busy ? 0 : enabled ? 1 : 0.45)
                .overlay {
                    if busy { ProgressView().controlSize(.large) }
                }
                // The scale the UIKit menu buttons beside it draw at (`NativeMenuButton`).
                .imageScale(.medium)
                .frame(width: size, height: size)
                .background(Circle().fill(Palette.onVideo.opacity(selected ? 0.22 : 0)))
                .contentShape(Circle())
            #endif
        }
        #if os(tvOS)
        .buttonStyle(PressRepeatStyle(base: PlayerTVButtonStyle(shape: Circle(), selected: selected), press: press, repeating: repeating))
        #else
        .buttonStyle(PressRepeatStyle(base: PlayerPressStyle(), press: press, repeating: repeating))
        #endif
        .accessibilityLabel(label)
        #if os(macOS)
        .tooltip(tooltip ?? label)
        #endif
        .accessibilityValue(value ?? "")
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier(id)
        #if os(iOS)
        .accessibilityShowsLargeContentViewer { Label(label, systemImage: systemImage) }
        #endif
    }

    /// The symbol, struck through or with its dot.
    private var symbol: some View {
        Image(systemName: systemImage)
            .overlay {
                if struck { Capsule().frame(width: 2).padding(.vertical, -2).rotationEffect(.degrees(-45)) }
            }
            .overlay(alignment: .topTrailing) {
                if badged { Circle().frame(width: 6, height: 6).offset(x: 4, y: -2).accessibilityHidden(true) }
            }
    }
}

#if os(tvOS)
/// The Apple TV's player buttons, as AVKit's transport bar draws them (as measured): the system's material under a
/// white symbol (white 60 % while `selected`, the button of the open menu, or `prominent`); under focus the platter
/// turns white with a black symbol and grows from AVKit's 66 to 74 pt, with no shadow; a click shrinks it a little
/// (`tvPressed`). With Increase Contrast the symbol or label on the 60 % white is black: about 7.4:1 over black video,
/// where white reads 2.85:1.
struct PlayerTVButtonStyle<S: Shape>: ButtonStyle {
    let shape: S
    var selected = false
    var prominent = false
    /// Room around a text label inside its platter (a symbol's frame brings its own).
    var insets = EdgeInsets()

    func makeBody(configuration: Configuration) -> some View {
        Face(configuration: configuration, shape: shape, strong: selected || prominent, insets: insets)
    }

    private struct Face: View {
        let configuration: Configuration
        let shape: S
        let strong: Bool
        let insets: EdgeInsets
        @Environment(\.isFocused) private var focused
        @Environment(\.isEnabled) private var enabled
        @Environment(\.playerControlsAside) private var aside
        @Environment(\.playerControlOff) private var off
        @Environment(\.colorSchemeContrast) private var contrast

        var body: some View {
            configuration.label
                .font(.callout.weight(.semibold))
                .lineLimit(1)
                .padding(insets)
                .foregroundStyle(focused || strong && contrast == .increased ? Color.black : Palette.onVideo)
                .background {
                    if focused || strong {
                        shape.fill(focused ? Palette.onVideo : Palette.onVideo.opacity(0.6))
                    } else {
                        shape.fill(.regularMaterial)
                    }
                }
                .contentShape(shape)
                .scaleEffect(focused ? 1.12 : 1)
                .opacity((enabled || aside) && !off ? 1 : 0.45)
                .effectsAnimation(.easeOut(duration: 0.15), value: focused)
                .tvPressed(configuration.isPressed)
        }
    }
}
#endif

/// Dims a pressed control; the glass under it gives the rest of the feedback.
struct PlayerPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.opacity(configuration.isPressed ? 0.55 : 1)
    }
}

/// One button's held press (`PressRepeatStyle`): held as long as a long press, the button's `repeating` runs at once and
/// then every 200 ms until it is let go (`KeyRepeat`); the click that ends a held press does nothing.
@MainActor
final class PressRepeat {
    private var held = false
    private lazy var repeater = KeyRepeat(delayMillis: KeyRepeat.companion.HOLD_DELAY_MILLIS, intervalMillis: KeyRepeat.companion.HOLD_INTERVAL_MILLIS)

    /// The press went down (`down`) or up.
    func pressed(_ down: Bool, repeating: @escaping () -> Void) {
        guard down else { return repeater.stop() }
        held = false
        repeater.hold { [weak self] in
            // Run on the main thread (the repeat's main scope).
            MainActor.assumeIsolated {
                self?.held = true
                repeating()
            }
        }
    }

    /// The click that ends a press: whether it acts, not having been held.
    func click() -> Bool {
        defer { held = false }
        return !held
    }

    func stop() {
        repeater.stop()
    }
}

/// `base`'s look; with `repeating`, the press held repeats it (`PressRepeat`).
struct PressRepeatStyle<Base: ButtonStyle>: ButtonStyle {
    let base: Base
    let press: PressRepeat
    let repeating: (() -> Void)?

    func makeBody(configuration: Configuration) -> some View {
        base.makeBody(configuration: configuration)
            .onChange(of: configuration.isPressed) { _, down in
                if let repeating { press.pressed(down, repeating: repeating) }
            }
            .onDisappear { press.stop() }
    }
}

/// `focused` for a view that may have no focus binding (the episode buttons outside tvOS).
struct OptionalPlayerFocus: ViewModifier {
    let focus: FocusState<PlayerFocus?>.Binding?
    let target: PlayerFocus

    func body(content: Content) -> some View {
        if let focus { content.focused(focus, equals: target) } else { content }
    }
}
