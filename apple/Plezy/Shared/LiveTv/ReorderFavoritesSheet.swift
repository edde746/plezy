import SwiftUI
import PlezyKit

/// Reorder favourites (`ReorderFavoritesUiState`) in a sheet: the favourites in their order as a list, each its logo
/// (else the live TV symbol), name and number; Close in the bar. iPhone and iPad move a row by its reorder control (the
/// list is editing), the Mac by dragging the row, and both remove one with its remove button; on Apple TV Select picks
/// a row up (its symbol turns to the arrows), Up and Down move it, Select puts it down, and its context menu (Select
/// held) removes it. Each move and removal is saved at once; removing the last closes the sheet.
///
/// Accessibility identifiers: `livetv.reorder`, `livetv.reorder.close`, `livetv.reorder.row.<index>`,
/// `livetv.reorder.remove.<index>`.
struct ReorderFavoritesSheet: View {
    let app: AppModel
    let state: ReorderFavoritesUiState
    let store: LiveTvStore

    #if os(tvOS)
    /// The key of the row picked up, which Up and Down move.
    @State private var moving: String?
    /// The focused row's key; the first row's as the sheet opens.
    @FocusState private var focusedRow: String?
    #endif

    var body: some View {
        SheetPage(id: "livetv.reorder", title: state.title, close: SheetAction(title: T.shared.common.close, id: "livetv.reorder.close") { store.closeReorder() }) {
            List {
                ForEach(Array(state.rows.enumerated()), id: \.element.key) { index, row in
                    rowView(row, index: index)
                }
                #if !os(tvOS)
                .onMove { source, destination in
                    guard let from = source.first else { return }
                    let to = destination > from ? destination - 1 : destination
                    store.moveFavorite(from: Int32(from), to: Int32(to))
                }
                #endif
            }
            #if os(iOS)
            .environment(\.editMode, .constant(.active))
            #endif
            #if os(tvOS)
            .task { await FocusRestore.restore($focusedRow, to: state.rows.first?.key, hold: 1) }
            // Up or Down with a row picked up moves focus to its neighbour: the row moves there instead, keeping focus.
            .onChange(of: focusedRow) { left, now in
                guard let moved = moving, left == moved, let now, now != moved else { return }
                let keys = state.rows.map(\.key)
                guard let from = keys.firstIndex(of: moved), let to = keys.firstIndex(of: now), abs(from - to) == 1 else {
                    moving = nil
                    return
                }
                store.moveFavorite(from: Int32(from), to: Int32(to))
                Task { @MainActor in await FocusRestore.restore($focusedRow, to: moved, hold: 0.5, replacing: true) }
            }
            #endif
        }
    }

    private func rowView(_ row: ReorderFavoriteRow, index: Int) -> some View {
        #if os(tvOS)
        pickUp(row, index: index) { rowLabel(row, index: index) }
            .contextMenu {
                Button(T.shared.common.delete, systemImage: "minus.circle", role: .destructive) { remove(index) }
                    .accessibilityIdentifier("livetv.reorder.remove.\(index)")
            }
        #else
        HStack(spacing: 12) {
            pickUp(row, index: index) { rowLabel(row, index: index) }
            Button(role: .destructive) { remove(index) } label: {
                Image(systemName: "minus.circle.fill")
                    .symbolRenderingMode(.multicolor)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(T.shared.common.delete)
            .accessibilityIdentifier("livetv.reorder.remove.\(index)")
        }
        #endif
    }

    private func rowLabel(_ row: ReorderFavoriteRow, index: Int) -> some View {
        HStack(spacing: 12) {
            #if os(tvOS)
            Image(systemName: moving == row.key ? "arrow.up.arrow.down" : "line.3.horizontal")
                .foregroundStyle(moving == row.key ? AnyShapeStyle(.tint) : AnyShapeStyle(Palette.onSurfaceVariant))
            #endif
            RemoteImage(
                artwork: app.liveTvArtwork(serverId: row.serverId, path: row.thumb, kind: .thumb),
                contentMode: .fit
            ) { failed in
                if failed { ArtworkPlaceholder(kind: .channel) }
            }
            .frame(width: 40, height: 40)
            .clipShape(RoundedRectangle(cornerRadius: Radius.small, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(row.title).lineLimit(1)
                if let number = row.number {
                    Text(number).font(.caption).mutedForeground()
                }
            }
            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
    }

    /// The row's main part: on Apple TV the button that picks it up and puts it down; elsewhere the row's content,
    /// which the list moves.
    @ViewBuilder
    private func pickUp<Label: View>(_ row: ReorderFavoriteRow, index: Int, @ViewBuilder label: () -> Label) -> some View {
        #if os(tvOS)
        Button { moving = moving == row.key ? nil : row.key } label: { label() }
            .focused($focusedRow, equals: row.key)
            .accessibilityIdentifier("livetv.reorder.row.\(index)")
        #else
        label()
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("livetv.reorder.row.\(index)")
        #endif
    }

    private func remove(_ index: Int) {
        #if os(tvOS)
        moving = nil
        #endif
        store.removeFavorite(index: Int32(index))
    }
}
