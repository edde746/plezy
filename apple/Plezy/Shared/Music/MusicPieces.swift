import SwiftUI
import PlezyKit

/// The "now playing" mark: three bars, 16 × 14, the bars rising and falling out of step while `animate` (the session
/// plays), still at fixed heights otherwise, with Reduce Motion and on the reduced visual effects tier. Leads the
/// current track's row, the queue's current entry and Apple TV's Now Playing rail item.
struct EqualizerIcon: View {
    let animate: Bool
    var color: Color = Palette.primary
    var scale: CGFloat = 1

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.reducedEffects) private var reducedEffects

    private static let stillHeights: [CGFloat] = [0.55, 0.9, 0.4]
    private static let phases: [Double] = [0, 0.35, 0.7]
    private static let period = 0.9

    var body: some View {
        let moving = animate && !reduceMotion && !reducedEffects
        TimelineView(.animation(paused: !moving)) { context in
            let t = context.date.timeIntervalSinceReferenceDate / Self.period
            Canvas { canvas, size in
                let gap = 2.5 * scale
                let width = (size.width - gap * 2) / 3
                for index in 0..<3 {
                    let fraction = moving
                        ? 0.3 + 0.7 * (0.5 + 0.5 * sin(2 * .pi * (t + Self.phases[index])))
                        : Self.stillHeights[index]
                    let height = size.height * fraction
                    let bar = CGRect(x: CGFloat(index) * (width + gap), y: size.height - height, width: width, height: height)
                    canvas.fill(Path(roundedRect: bar, cornerRadius: 1.5 * scale), with: .color(color))
                }
            }
        }
        .frame(width: 16 * scale, height: 14 * scale)
        .accessibilityHidden(true)
    }
}

extension View {
    /// The now-playing mark over a list entry's artwork (a chapter's, a video queue entry's, a playlist track's), one
    /// look on every device: while `current` the artwork (or its placeholder) darkens under a white equalizer, moving
    /// while `playing`, its edge (rounded `cornerRadius`, the artwork's) drawn in the secondary text colour so even a dark
    /// placeholder tile stands off the sheet (on Apple TV, over the panel's dark glass, a light edge twice as wide). (A
    /// tile in the primary colour would read as Apple TV's white focus.) Rows without artwork (an album's tracks, the
    /// music queue's) carry the equalizer in their leading column (`TrackRow`): either way the title beside it stays
    /// where every row's starts.
    func nowPlayingMark(_ current: Bool, playing: Bool, scale: CGFloat = 1.5, cornerRadius: CGFloat = 4) -> some View {
        overlay {
            if current {
                let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                ZStack {
                    shape.fill(.black.opacity(0.6))
                    #if os(tvOS)
                    shape.strokeBorder(Color.white.opacity(0.8), lineWidth: 3)
                    #else
                    shape.strokeBorder(Palette.onSurfaceVariant, lineWidth: 1.5)
                    #endif
                    EqualizerIcon(animate: playing, color: .white, scale: scale)
                }
            }
        }
    }
}

/// Square artwork of a track, an album or an artist, its `placeholder` while it has none or it fails to load; round
/// where the placeholder is (an artist's).
struct MusicArtwork: View {
    let artwork: Artwork?
    var placeholder: PlaceholderKind = .track
    var cornerRadius: CGFloat = Radius.large

    var body: some View {
        ZStack {
            Palette.surfaceContainerHighest
            RemoteImage(artwork: artwork) { failed in
                if failed { ArtworkPlaceholder(kind: placeholder) }
            }
        }
        .clipShape(MusicArtworkShape(circular: placeholder.circular, radius: cornerRadius))
        .accessibilityHidden(true)
    }
}

struct MusicArtworkShape: Shape {
    let circular: Bool
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        circular ? Circle().path(in: rect) : RoundedRectangle(cornerRadius: radius, style: .continuous).path(in: rect)
    }
}

/// A transport or utility control: an SF Symbol in the text colour (`NowPlayingBackground.secondaryText` while not
/// `active`) on a clear round `SurfaceButtonStyle` surface (faint while disabled), which the remote's focus fills and a
/// keyboard's rings. A toggle (`isOn` set: Shuffle, Repeat, Lyrics) that is on rests on a filled disc (`ToggleDisc`),
/// off its symbol alone in the muted colour; it tells VoiceOver its state too, as its value ("On", "Off") and selected
/// while on (`toggleState`).
struct MusicIconButton: View {
    let systemImage: String
    let label: String
    var size: CGFloat = 22
    var active = true
    var tint: Color?
    var id: String?
    /// The control is a toggle, on or off; nil for a plain action.
    var isOn: Bool?
    let action: () -> Void

    @Environment(\.dimens) private var dimens

    var body: some View {
        let unit = dimens.unit
        let full = isOn ?? active
        Button(action: action) {
            MusicSymbol(
                systemImage: systemImage, size: size * unit,
                style: tint.map(AnyShapeStyle.init)
                    ?? AnyShapeStyle(isOn == true ? ToggleDisc.symbol : full ? Palette.onBackground : NowPlayingBackground.secondaryText)
            )
            .frame(width: (size + 22) * unit, height: (size + 22) * unit)
            .contentShape(Circle())
        }
        .buttonStyle(SurfaceButtonStyle(fill: isOn == true ? ToggleDisc.fill : .clear, radius: (size + 22) * unit / 2))
        #if os(macOS)
        .tooltip(label)
        #endif
        .accessibilityLabel(label)
        .toggleState(isOn)
        .accessibilityIdentifier(id ?? "")
    }
}

/// A Now Playing toggle's disc while on: on iPhone, iPad and the Mac the text colour, its symbol in the background
/// colour (as Apple Music's), plain over any artwork or bar; on Apple TV, where focus turns a control white, the accent's
/// rest tint (`Palette.primaryRest`) under the text colour, so a focused toggle still differs from one at rest.
enum ToggleDisc {
    @MainActor static var fill: Color {
        #if os(tvOS)
        Palette.primaryRest
        #else
        Palette.onBackground
        #endif
    }

    @MainActor static var symbol: Color {
        #if os(tvOS)
        Palette.onBackground
        #else
        Palette.background
        #endif
    }
}

extension View {
    /// A Now Playing toggle drawn by hand (the Mac's bar and panes): on, its symbol on a filled disc `diameter` across
    /// (`ToggleDisc`), as `MusicIconButton` draws one; off, the symbol alone in `NowPlayingBackground.secondaryText`.
    @MainActor
    func toggleDisc(_ on: Bool, diameter: CGFloat) -> some View {
        foregroundStyle(on ? ToggleDisc.symbol : NowPlayingBackground.secondaryText)
            .background {
                if on { Circle().fill(ToggleDisc.fill).frame(width: diameter, height: diameter) }
            }
    }
}

/// A music control's symbol in `style`; on a focused tvOS surface (white) in the surface's own text colour instead,
/// so a muted symbol (a toggle that is off) stays visible with focus on it.
struct MusicSymbol: View {
    let systemImage: String
    let size: CGFloat
    let style: AnyShapeStyle

    @Environment(\.onFocusedSurface) private var onFocusedSurface

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: size, weight: .semibold))
            .foregroundStyle(onFocusedSurface ? AnyShapeStyle(Palette.onFocusedSurface) : style)
    }
}

extension View {
    /// A toggle's state for VoiceOver and the UI tests where `isOn` is set: its value "On" or "Off", selected while on.
    @ViewBuilder
    func toggleState(_ isOn: Bool?) -> some View {
        if let isOn {
            accessibilityValue(isOn ? T.shared.player.options.on : T.shared.player.options.off)
                .accessibilityAddTraits(isOn ? .isSelected : [])
        } else {
            self
        }
    }
}

/// The 72 pt play/pause control: the inverse surface, a circle while paused and a rounded square while playing, a
/// spinner in it while the track loads; focused it grows a little.
struct PlayPauseButton: View {
    let playing: Bool
    let loading: Bool
    var size: CGFloat = 72
    let action: () -> Void

    @Environment(\.dimens) private var dimens

    var body: some View {
        let unit = dimens.unit
        let side = size * unit
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: playing ? Radius.large * unit + 4 * unit : side / 2, style: .continuous)
                    .fill(Palette.onBackground)
                if loading {
                    ProgressView()
                        .tint(Palette.background)
                        .controlSize(.regular)
                } else {
                    Image(systemName: playing ? "pause.fill" : "play.fill")
                        .font(.system(size: side * 0.4, weight: .bold))
                        .foregroundStyle(Palette.background)
                }
            }
            .frame(width: side, height: side)
            .contentShape(Circle())
        }
        .buttonStyle(GrowOnFocusStyle())
        .effectsAnimation(.spring(duration: 0.35), value: playing)
        .accessibilityLabel(playing ? T.shared.common.pause : T.shared.common.play)
        .accessibilityIdentifier("music.playPause")
    }

    private struct GrowOnFocusStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            Grow(configuration: configuration)
        }

        private struct Grow: View {
            let configuration: Configuration
            @Environment(\.isFocused) private var focused

            var body: some View {
                configuration.label
                    .scaleEffect(configuration.isPressed ? 0.96 : focused ? 1.08 : 1)
                    .effectsAnimation(.easeOut(duration: Double(FocusTokens.shared.DURATION_MILLIS) / 1000), value: focused)
            }
        }
    }
}

extension MusicRepeatMode {
    /// The repeat control's symbol: off, all (tinted), one (tinted).
    var systemImage: String {
        switch self {
        case .one: "repeat.1"
        default: "repeat"
        }
    }

    var label: String {
        switch self {
        case .all: T.shared.music.repeatAll
        case .one: T.shared.music.repeatOne
        default: T.shared.music.repeatText
        }
    }
}
