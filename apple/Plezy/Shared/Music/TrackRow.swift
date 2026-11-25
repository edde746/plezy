import SwiftUI
import PlezyKit

/// A track's row in an album, a playlist or the queue, built as Detail's episode rows are: a button on a plain surface
/// (`SurfaceButtonStyle`), then the track's ⋯ beside it, which opens its item menu in the system's menu
/// (`SystemItemMenu`). The button holds the equalizer while it is the current track, else its number; where
/// `showsArtwork` (a playlist's rows and the queue's, whose tracks come from many albums) the track's small square
/// artwork instead, the album placeholder where it has none, carrying the now-playing mark while current, as Apple
/// Music's rows; the title, semibold while current and muted where `dimmed` (the queue's played
/// entries); the artist line; the duration. The current row sits on a faint tint. A tap (Select) plays the row; ⋯, a
/// long press, a right click or a long Select open its item menu (`onMenu`, the shared `MediaMenu`). `onRemove` puts a
/// × (`removeLabel`) in the menu's place (the queue on Apple TV and the Mac, which have no swipe; a playlist's rows in
/// Edit mode there).
struct TrackRow: View {
    let title: String
    var subtitle: String?
    var number: String?
    var duration: String?
    var isCurrent = false
    var playing = false
    var dimmed = false
    var showsArtwork = false
    var artwork: Artwork?
    var onMenu: (() -> Void)?
    var onRemove: (() -> Void)?
    var removeLabel = T.shared.common.delete
    /// The row's key in its list's focus state (the queue sheet puts focus on the current row).
    var focus: (binding: FocusState<String?>.Binding, key: String)?
    var id: String
    let onTap: () -> Void

    /// The side of a row's artwork (`showsArtwork`).
    #if os(tvOS)
    static let artworkSide: CGFloat = 64
    #else
    static let artworkSide: CGFloat = 40
    #endif

    var body: some View {
        HStack(spacing: 4) {
            Button(action: onTap) {
                HStack(spacing: 12) {
                    TrackLeading(isCurrent: isCurrent, playing: playing, number: number, showsArtwork: showsArtwork, artwork: artwork)
                        .frame(width: showsArtwork ? Self.artworkSide : 28)
                    VStack(alignment: .leading, spacing: 2) {
                        let name = Text(title)
                            .font(.body.weight(isCurrent ? .semibold : .regular))
                            .lineLimit(1)
                        // A played row's title in the muted colour, which still reads 4.5:1 on the page.
                        if isCurrent || !dimmed { name } else { name.mutedForeground() }
                        if let subtitle {
                            Text(subtitle)
                                .font(.footnote)
                                .mutedForeground()
                                .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    if let duration {
                        Text(duration)
                            .font(.footnote.monospacedDigit())
                            .mutedForeground()
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(minHeight: 52)
                .contentShape(Rectangle())
            }
            .buttonStyle(SurfaceButtonStyle(fill: isCurrent ? Palette.primary.opacity(0.08) : .clear, radius: Radius.medium))
            .optionalFocus(focus)
            .mediaMenuTrigger(onMenu, item: id)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier(id)
            // The equalizer is the now-playing mark the video player's lists show too: VoiceOver reads it as their rows'.
            .accessibilityValue(isCurrent ? T.shared.player.nowPlaying : "")
            .accessibilityAddTraits(isCurrent ? .isSelected : [])
            trailing
        }
        // The ⋯ as tall as the row beside it (`maxHeight`), not a shorter square of its own.
        .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private var trailing: some View {
        if let onRemove {
            RowRemoveButton(label: removeLabel, id: "\(id).remove", action: onRemove)
        } else if let onMenu {
            Image(systemName: "ellipsis")
                .font(.body.weight(.semibold))
                .foregroundStyle(Palette.onSurfaceVariant)
                .frame(minWidth: 44, minHeight: 44)
                .frame(maxHeight: .infinity)
                .contentShape(Rectangle())
                .focusRing(radius: 22)
                .modifier(SystemItemMenu(open: onMenu, item: "\(id).more", kind: .menu))
                .menuStyle(.button)
                .menuIndicator(.hidden)
                .buttonStyle(PressDimButtonStyle())
                #if os(macOS)
                .tooltip(T.shared.common.options)
                #endif
                .accessibilityLabel(T.shared.common.options)
                .accessibilityIdentifier("\(id).more")
        }
    }
}

/// The equalizer on the current row (dark on a focused tvOS surface), else the track's number; where `showsArtwork`, the
/// artwork, carrying the now-playing mark the player's lists put on their thumbnails while current (`nowPlayingMark`).
private struct TrackLeading: View {
    let isCurrent: Bool
    let playing: Bool
    let number: String?
    let showsArtwork: Bool
    let artwork: Artwork?

    @Environment(\.onFocusedSurface) private var onFocusedSurface

    var body: some View {
        if showsArtwork {
            MusicArtwork(artwork: artwork, placeholder: .album, cornerRadius: Radius.extraSmall)
                .frame(width: TrackRow.artworkSide, height: TrackRow.artworkSide)
                .nowPlayingMark(isCurrent, playing: playing, scale: 1, cornerRadius: Radius.extraSmall)
        } else if isCurrent {
            EqualizerIcon(animate: playing, color: onFocusedSurface ? Palette.onFocusedSurface : Palette.primary)
        } else if let number {
            Text(number)
                .font(.footnote.monospacedDigit())
                .mutedForeground()
        } else {
            Color.clear.frame(height: 1)
        }
    }
}

#if os(macOS)
/// A track row's drag handle on the Mac (the queue's, a playlist's in Edit mode; a list's own reorder starts on a row,
/// and the row is a button there, which takes the mouse): a drag from it carries the row's key to the row it is
/// dropped on (`dropDestination`).
struct TrackDragHandle: View {
    let key: String
    let id: String

    var body: some View {
        Image(systemName: "line.3.horizontal")
            .font(.body)
            .foregroundStyle(Palette.onSurfaceVariant)
            .frame(width: 24, height: 44)
            .contentShape(Rectangle())
            .draggable(key)
            .help(T.shared.libraries.dragToReorder)
            .accessibilityLabel(T.shared.libraries.dragToReorder)
            .accessibilityIdentifier(id)
    }
}
#endif

/// A row's × (a track row's, a playlist entry's in Edit mode): the glyph alone at rest, on the focused surface on
/// Apple TV and in the focus ring elsewhere when focused, the one look every list's remove has.
struct RowRemoveButton: View {
    let label: String
    let id: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.body.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(SurfaceButtonStyle(fill: .clear, radius: 22))
        .accessibilityLabel(label)
        .accessibilityIdentifier(id)
    }
}

#if os(tvOS)
/// A row's handle in Edit mode on Apple TV (an audio or a video playlist's): selected, it starts move mode (swap
/// arrows), Up and Down move the row (`onStep`), and selected again it saves the order; focused, it takes the focused
/// surface as the row's × does; while another row moves it can't take focus.
struct MoveModeHandle: View {
    let title: String
    let id: String
    let moving: Bool
    let moveMode: Bool
    let onSelect: () -> Void
    let onStep: (Int32) -> Void

    var body: some View {
        Button(action: onSelect) {
            Image(systemName: moving ? "arrow.up.arrow.down" : "line.3.horizontal")
                .font(.body.weight(.semibold))
                .foregroundStyle(.secondary)
                // As tall as its row: the focus engine then brings the whole row (its move-mode ring) into view, not the glyph.
                .frame(width: 56)
                .frame(minHeight: 72, maxHeight: .infinity)
                .contentShape(Rectangle())
        }
        .buttonStyle(SurfaceButtonStyle(fill: .clear, radius: Radius.medium))
        .disabled(moveMode && !moving)
        .onMoveCommand { direction in
            guard moving else { return }
            switch direction {
            case .up: onStep(-1)
            case .down: onStep(1)
            default: break
            }
        }
        .accessibilityLabel(T.shared.libraries.dragToReorderNamed(name: title))
        .accessibilityIdentifier(id)
    }
}

/// A playlist's Edit, Done in Edit mode, in its action row on Apple TV (an audio or a video playlist's): as wide as the
/// wider of the two, so the buttons after it stay put as it turns from one into the other. `focus` takes it as
/// `focusKey`; the sizing buttons are never seen, focused or read out.
struct EditDoneButton: View {
    let editing: Bool
    let id: String
    let focus: FocusState<String?>.Binding
    let focusKey: String
    let action: () -> Void

    var body: some View {
        ZStack {
            ActionButton(title: T.shared.common.edit, id: "\(id).sizing", systemImage: "pencil", fullWidth: false) {}
            ActionButton(title: T.shared.common.doneEditing, id: "\(id).sizing", systemImage: "checkmark", fullWidth: false) {}
        }
        .disabled(true)
        .hidden()
        .accessibilityHidden(true)
        .overlay {
            ActionButton(
                title: editing ? T.shared.common.doneEditing : T.shared.common.edit, id: id,
                systemImage: editing ? "checkmark" : "pencil", fullWidth: true, action: action
            )
            .focused(focus, equals: focusKey)
        }
    }
}
#endif

#if os(iOS)
/// A playlist's Edit, Done in Edit mode, in its navigation bar on iPhone and iPad (an audio or a video playlist's): the
/// list's Edit mode as `EditButton` sets it, but with its words both ways and as wide as the wider of the two, so the
/// bar's title stays where it is (the system's Done, a narrower checkmark, let the title move to the centre).
struct PlaylistEditButton: View {
    @Binding var editMode: EditMode
    let id: String

    var body: some View {
        let editing = editMode.isEditing
        Button {
            withAnimation { editMode = editing ? .inactive : .active }
        } label: {
            ZStack {
                Text(T.shared.common.edit).hidden()
                Text(T.shared.common.doneEditing).hidden()
                Text(editing ? T.shared.common.doneEditing : T.shared.common.edit)
            }
        }
        .accessibilityLabel(editing ? T.shared.common.doneEditing : T.shared.common.edit)
        .accessibilityIdentifier(id)
    }
}
#endif

extension View {
    /// `focused(_:equals:)` where `focus` is given (a row's key in its list's focus, a page's Play), else the view as is.
    @ViewBuilder
    func optionalFocus(_ focus: (binding: FocusState<String?>.Binding, key: String)?) -> some View {
        if let focus { focused(focus.binding, equals: focus.key) } else { self }
    }
}
