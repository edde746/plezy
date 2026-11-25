import SwiftUI
import PlezyKit

/// The lyrics pane, in place of the artwork on Now Playing (`NowPlayingUiState.lyrics`): a spinner while they load, the
/// lyrics symbol and "No lyrics available" without any. Synced lyrics light the line playing (`active`, the store's
/// `activeLyricLine`) in semibold and the text colour, the rest muted, and keep it 40 % down the pane as it moves,
/// unless the user scrolled in the last 3 s. A tap (Select) on a synced line seeks to its start (`onSeek`). Unsynced
/// lyrics are plain lines in the text colour. With a remote or a keyboard each line takes focus, drawn as a fill; Back
/// (`onExit`) returns to the transport.
struct LyricsView: View {
    let lyrics: LyricsUi
    let active: Int
    let onSeek: (Int) -> Void
    var onExit: (() -> Void)?

    var body: some View {
        switch onEnum(of: lyrics) {
        case .loading:
            ProgressView()
                .tint(Palette.onSurfaceVariant)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityIdentifier("music.lyrics.loading")
        case .none:
            EmptyStateView(message: T.shared.music.noLyrics, systemImage: "quote.bubble")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityIdentifier("music.lyrics.none")
        case .lines(let lines):
            LyricLines(lines: lines.lines, synced: lines.synced, active: active, onSeek: onSeek, onExit: onExit)
        }
    }
}

private struct LyricLines: View {
    let lines: [String]
    let synced: Bool
    let active: Int
    let onSeek: (Int) -> Void
    let onExit: (() -> Void)?

    @Environment(\.dimens) private var dimens
    @State private var manualScrollAt: Date?

    private static let manualScrollHold: TimeInterval = 3

    var body: some View {
        let unit = dimens.unit
        GeometryReader { pane in
            ScrollViewReader { reader in
                ScrollView(.vertical) {
                    VStack(spacing: 0) {
                        ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                            LyricLine(text: line, active: synced && index == active, synced: synced) {
                                if synced { onSeek(index) }
                            }
                            .id(index)
                        }
                    }
                    .padding(.horizontal, 16 * unit)
                    .padding(.vertical, 32 * unit)
                    // Lyrics shorter than the pane sit in its middle.
                    .frame(maxWidth: .infinity, minHeight: pane.size.height)
                }
                .scrollIndicators(.hidden)
                .modifier(ManualScrollWatch { manualScrollAt = .now })
                .onAppear { reveal(active, reader: reader, animated: false) }
                .onChange(of: active) { _, index in reveal(index, reader: reader, animated: true) }
            }
        }
        .accessibilityIdentifier("music.lyrics")
        #if !os(iOS)
        .onExitCommand(perform: onExit)
        #endif
    }

    private func reveal(_ index: Int, reader: ScrollViewProxy, animated: Bool) {
        guard synced, index >= 0 else { return }
        if let at = manualScrollAt, Date.now.timeIntervalSince(at) < Self.manualScrollHold { return }
        let anchor = UnitPoint(x: 0.5, y: 0.4)
        if animated {
            withAnimation(.easeOut(duration: 0.3)) { reader.scrollTo(index, anchor: anchor) }
        } else {
            reader.scrollTo(index, anchor: anchor)
        }
    }
}

private struct LyricLine: View {
    let text: String
    let active: Bool
    let synced: Bool
    let action: () -> Void

    @Environment(\.dimens) private var dimens

    var body: some View {
        let unit = dimens.unit
        Button(action: action) {
            Text(text)
                .font(.title3.weight(active ? .semibold : .regular))
                .lineSpacing(7 * unit)
                .multilineTextAlignment(.center)
                .foregroundStyle(active || !synced ? HierarchicalShapeStyle.primary : .secondary)
                .padding(.horizontal, 12 * unit)
                .padding(.vertical, 8 * unit)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .animation(.easeOut(duration: 0.2), value: active)
        }
        .buttonStyle(SurfaceButtonStyle(fill: .clear, radius: Radius.small * unit))
        .accessibilityAddTraits(active ? .isSelected : [])
    }
}

/// Notes when the user scrolls the pane (a drag, a wheel, the remote), which holds the auto-reveal for a moment.
private struct ManualScrollWatch: ViewModifier {
    let onManualScroll: () -> Void

    func body(content: Content) -> some View {
        if #available(iOS 18, macOS 15, *) {
            content.onScrollPhaseChange { _, phase in
                if phase == .interacting || phase == .tracking { onManualScroll() }
            }
        } else {
            content
        }
    }
}
