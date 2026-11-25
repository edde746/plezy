import SwiftUI
import PlezyKit

/// A short message at the bottom of the screen, as a capsule on the theme's highest surface, raised by a shadow: a
/// watch-together room's latest event ("Anna joined"), or an error on the error colour (`isError`). Opaque: a material
/// or glass capsule took the colour of a plain page or sheet under it and let the text there through, the two texts
/// over each other. `id` is its accessibility identifier.
struct Toast: View {
    let text: String
    let id: String
    var isError = false

    var body: some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .multilineTextAlignment(.center)
            .foregroundStyle(isError ? Color.white : Palette.onBackground)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(isError ? Palette.error : Palette.surfaceContainerHighest, in: Capsule())
            .shadow(color: .black.opacity(0.25), radius: 8, y: 2)
            .padding(.horizontal, 24)
            .accessibilityIdentifier(id)
    }
}

extension View {
    /// Shows `text` as a `Toast` while it is set (on the error colour when `isError`), and announces it (`announcing`).
    /// The toast never lies over the content or the controls: it takes a band of its own at the view's foot (a sheet's,
    /// just above its Close bar; a screen's, above the tab bar, the mini-player or the Mac's playback bar), the view's
    /// content kept above it and, where it scrolls (`cutsContent`), cut off at the band's edge (`ToastBand`). Given a
    /// `relay`, the toast shows in the band of the screen the relay names instead (`toastBand`): the shell's toasts, in
    /// the shown screen's. The player's view, which has nothing that scrolls under the band, isn't cut: a cut is a mask
    /// over every frame of its video.
    /// `onShown` is the store's dismiss, which clears its message once shown: 3 s after the toast shows (an error 4 s), or
    /// on the Mac at a click on it; on
    /// iPhone, iPad and the Mac while VoiceOver runs, not until the user dismisses it (its Dismiss action, or the escape
    /// gesture) or the store replaces it, since a toast gone on a timer is one a VoiceOver user seldom reaches (Apple
    /// TV's VoiceOver follows focus, which a toast never takes). It slides in and out, and fades with Reduce Motion on.
    func toast(
        _ text: String?, id: String, isError: Bool = false, in relay: ToastRelay? = nil, cutsContent: Bool = true,
        onShown: @escaping () -> Void
    ) -> some View {
        modifier(ToastHost(text: text, id: id, isError: isError, relay: relay, cuts: cutsContent, onShown: onShown))
    }

    /// The band at this view's foot where the toasts of `relay` show (`toast(_:id:isError:in:onShown:)`); nil shows none.
    func toastBand(_ relay: ToastRelay?) -> some View {
        modifier(RelayBand(relay: relay))
    }
}

extension EnvironmentValues {
    /// How much of the view's height the toast bands at its foot take while they show: a layout sized by its height
    /// (`GeometryReader`) adds it back, so nothing on it moves as a toast comes and goes (Detail's, the catalog's).
    @Entry var toastRoom: CGFloat = 0
}

/// The toasts a view hands to a band elsewhere (`toast(_:id:isError:in:onShown:)`, `toastBand`), in the order they
/// came: the shell's, which show in the band of the screen on top, never over the tab bar or the playback bar.
@MainActor
@Observable
final class ToastRelay {
    struct Entry: Identifiable {
        let id: String
        let text: String
        let isError: Bool
        let dismiss: () -> Void
    }

    private(set) var entries: [Entry] = []

    fileprivate func show(_ entry: Entry?, id: String) {
        if let entry {
            if let index = entries.firstIndex(where: { $0.id == id }) { entries[index] = entry } else { entries.append(entry) }
        } else {
            entries.removeAll { $0.id == id }
        }
    }
}

private struct ToastHost: ViewModifier {
    let text: String?
    let id: String
    let isError: Bool
    let relay: ToastRelay?
    let cuts: Bool
    let onShown: () -> Void

    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver

    /// The toast waits for its dismiss: VoiceOver runs where its user can move to the toast.
    private var stays: Bool {
        #if os(tvOS)
        false
        #else
        voiceOver
        #endif
    }

    func body(content: Content) -> some View {
        Group {
            if let relay {
                content
                    .onChange(of: text, initial: true) { _, text in
                        relay.show(text.map { Entry(id: id, text: $0, isError: isError, dismiss: onShown) }, id: id)
                    }
                    .onDisappear { relay.show(nil, id: id) }
            } else {
                content.modifier(ToastBand(entries: text.map { [Entry(id: id, text: $0, isError: isError, dismiss: onShown)] } ?? [], cuts: cuts))
            }
        }
        .announcing(text)
        // The timer's id is the text, so a new text shows for the whole time again; VoiceOver turned off starts it.
        .task(id: stays ? nil : text) {
            guard !stays, text != nil else { return }
            try? await Task.sleep(for: .seconds(isError ? 4 : 3))
            if !Task.isCancelled { onShown() }
        }
    }

    private typealias Entry = ToastRelay.Entry
}

private struct RelayBand: ViewModifier {
    let relay: ToastRelay?

    func body(content: Content) -> some View {
        content.modifier(ToastBand(entries: relay?.entries ?? [], cuts: true))
    }
}

/// The band at a view's foot holding `entries`, one above the other: an inset of the view's safe area, so the view's
/// content lies above it. Where it `cuts`, what the content draws past its foot (a scroll view's rows, which run on
/// under the safe area) is cut off at the band's edge while a toast shows, fading out over the last points before it
/// (`BandMask`), the band left clear. The content hears how much of its height the bands take (`toastRoom`).
private struct ToastBand: ViewModifier {
    let entries: [ToastRelay.Entry]
    let cuts: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var height: CGFloat = 0

    func body(content: Content) -> some View {
        let room = content.transformEnvironment(\.toastRoom) { $0 += height }
        Group {
            if cuts {
                room
                    .mask { BandMask(cut: !entries.isEmpty) }
                    .safeAreaInset(edge: .bottom, spacing: 0) { measuredBand }
            } else {
                room.safeAreaInset(edge: .bottom, spacing: 0) { measuredBand }
            }
        }
        .animation(.easeOut(duration: 0.2), value: entries.map(\.text))
    }

    private var measuredBand: some View {
        band.onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height = $0 }
    }

    /// Empty, the band takes no room.
    private var band: some View {
        VStack(spacing: 8) {
            ForEach(entries) { entry in
                Toast(text: entry.text, id: entry.id, isError: entry.isError)
                    #if os(macOS)
                    .onTapGesture(perform: entry.dismiss)
                    #endif
                    .accessibilityAction(named: T.shared.nav.dismiss, entry.dismiss)
                    .accessibilityAction(.escape, entry.dismiss)
                    .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, entries.isEmpty ? 0 : 12)
        .padding(.bottom, entries.isEmpty ? 0 : 24)
    }
}

/// The content's mask: the view's own frame run out far past its top and sides (so nothing drawn under the bars or past
/// the sides is cut), and while `cut` ending at its foot, the toast band's edge, the content fading out over the last
/// `fade` points above it (a row there neither cut in half nor drawn behind the toast); else past its foot too. It
/// switches at once as the toast comes: animated, its foot would slide up from far below, the content showing under the
/// toast meanwhile.
private struct BandMask: View {
    let cut: Bool

    private static let reach: CGFloat = 10_000
    #if os(tvOS)
    private static let fade: CGFloat = 60
    #else
    private static let fade: CGFloat = 24
    #endif

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
            LinearGradient(colors: [.black, .black.opacity(0)], startPoint: .top, endPoint: .bottom)
                .frame(height: cut ? Self.fade : 0)
        }
        .padding(.horizontal, -Self.reach)
        .padding(.top, -Self.reach)
        .padding(.bottom, cut ? 0 : -Self.reach)
        .animation(nil, value: cut)
    }
}
