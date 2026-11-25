import SwiftUI
import PlezyKit

/// A paged grid of a server's items (`PagedGridUi`: a person's titles, a collection's items): the loaded cards, then a
/// blank card for each item not loaded yet, whose showing asks for its page (`onReach`); the spinner while the first page
/// loads, its error with Retry, or `emptyMessage` for an empty grid. A later page that failed shows its error with Retry
/// under the loaded cards, in the blank cards' place. `onMenu`, where given, opens a card's item menu. Each card
/// tells VoiceOver where it sits: "Row 2 of 5, column 3 of 4" after its state.
struct PagedGrid: View {
    let grid: PagedGridUi
    let shape: CardShape_
    let cells: GridCells
    /// What an empty grid says: a collection with no items, a person with no titles on the server.
    let emptyMessage: String
    var caption = true
    let onOpen: (MediaCardUi) -> Void
    var onMenu: ((MediaCardUi) -> Void)?
    let onReach: (Int) -> Void
    let onRetry: () -> Void

    var body: some View {
        switch grid.load {
        case .loading:
            LoadingStateView()
        case .error:
            ErrorStateView(message: grid.error ?? "", onRetry: onRetry)
                .accessibilityIdentifier("grid.error")
        case .empty:
            ContentUnavailableView(emptyMessage, systemImage: "film")
                .accessibilityIdentifier("grid.empty")
        default:
            // A failed later page leaves no blank cards: its error and Retry stand in their place.
            let count = grid.moreError == nil ? max(Int(grid.total), grid.items.count) : grid.items.count
            CardGrid(cells: cells) {
                ForEach(Array(grid.items.enumerated()), id: \.element.id) { index, card in
                    PosterCard(
                        card: card, shape: shape, width: cells.cell, caption: caption, onOpen: { onOpen(card) },
                        onMenu: onMenu.map { open in { open(card) } },
                        position: Self.position(index, of: count, columns: cells.columns)
                    )
                }
                ForEach(grid.items.count..<count, id: \.self) { index in
                    BlankCard(shape: shape, width: cells.cell)
                        .onAppear { onReach(index) }
                }
            }
            .shelfFocusSection()
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("grid.items")
            if let moreError = grid.moreError {
                VStack(spacing: 12) {
                    Text(moreError)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    ActionButton(title: T.shared.common.retry, id: "grid.retry", systemImage: "arrow.clockwise", fullWidth: false, action: onRetry)
                }
                .frame(maxWidth: .infinity)
                #if os(tvOS)
                // As wide as the grid: Down from a card in any column reaches Retry.
                .focusSection()
                #endif
                .padding(.vertical, 16)
            }
        }
    }

    /// Where cell `index` of `count` sits in a grid of `columns`: its row, and its column where there are several.
    private static func position(_ index: Int, of count: Int, columns: Int) -> String {
        let columns = max(columns, 1)
        let row = String(index / columns + 1)
        let rows = String((count + columns - 1) / columns)
        guard columns > 1 else { return T.shared.accessibility.rowPosition(row: row, rowCount: rows) }
        return T.shared.accessibility.rowColumnPosition(row: row, rowCount: rows, column: String(index % columns + 1), columnCount: String(columns))
    }
}
