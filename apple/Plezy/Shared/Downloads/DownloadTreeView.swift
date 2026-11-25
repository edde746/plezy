#if !os(tvOS)
import SwiftUI
import PlezyKit

/// The Downloads screen's Manage tab, a plain list: the flattened tree (`DownloadsUiState.tree`: movies, then shows with
/// their seasons and episodes, then albums with their tracks), each row indented a level deeper than its container. A
/// row is its chevron (only a show, season or album has one, which a tap opens or closes; a tap on a movie, episode or
/// track opens its page; those keep no room for the chevron), its status (`DownloadStatusIcon`, from
/// the status it shows: a download waiting in the downloader's queue as queued), its title (semibold for a container)
/// over a container's "2 of 5 completed", a download's progress bar with its percent and speed, "Queued", or why it
/// failed. Its actions (`downloadRowActions`: pause, resume, retry, cancel, delete) are in its ⋯, its context menu (a
/// long press, a right click) and on iOS its swipes: those that remove at the trailing edge, the first other at the
/// leading edge. Every row is at least as tall as a title over a line of details, so a film's is as tall as a show's.
/// The Libraries tab picked again brings the list back to its first row (`scrollToTopRequests`). Empty: "No downloads".
///
/// Accessibility identifiers: `downloads.tree`, `downloads.row.<key>` with its ⋯ `downloads.row.<key>.menu` and its
/// actions `downloads.row.<key>.<action>` (`pause`, `deleteAll`, …), `downloads.tree.empty`.
struct DownloadTreeView: View {
    let rows: [DownloadTreeRow]
    let empty: String
    let onToggle: (String) -> Void
    let onOpen: (MediaItem) -> Void
    let onAction: (DownloadTreeNode, DownloadRowAction) -> Void

    @Environment(\.screenSides) private var sides
    @Environment(\.scrollToTopRequests) private var scrollToTopRequests

    var body: some View {
        if rows.isEmpty {
            EmptyStateView(message: empty, systemImage: "arrow.down.circle")
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("downloads.tree.empty")
        } else {
            ScrollViewReader { scroller in
                List {
                    ForEach(Array(rows.enumerated()), id: \.element.node.key) { index, row in
                        // A container is open when the row after it is one level deeper.
                        let open = index + 1 < rows.count && rows[index + 1].depth > row.depth
                        DownloadTreeRowView(row: row, expanded: open, onToggle: onToggle, onOpen: onOpen, onAction: onAction)
                            .listRowInsets(EdgeInsets(top: 2, leading: sides.leading + CGFloat(row.depth) * 20 - listRowMargin, bottom: 2, trailing: sides.trailing - listRowMargin))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .environment(\.defaultMinListRowHeight, 0)
                .accessibilityIdentifier("downloads.tree")
                .onChange(of: scrollToTopRequests) {
                    if let first = rows.first { withAnimation { scroller.scrollTo(first.node.key, anchor: .top) } }
                }
            }
        }
    }
}

/// What a plain list adds beside its rows' insets: 8 pt each side on the Mac (its table's cell margin), none on iOS.
#if os(macOS)
let listRowMargin: CGFloat = 8
#else
let listRowMargin: CGFloat = 0
#endif

private struct DownloadTreeRowView: View {
    let row: DownloadTreeRow
    let expanded: Bool
    let onToggle: (String) -> Void
    let onOpen: (MediaItem) -> Void
    let onAction: (DownloadTreeNode, DownloadRowAction) -> Void

    var body: some View {
        let node = row.node
        let container = node.hasChildren
        let status = node.effectiveStatus
        let id = "downloads.row.\(node.key)"
        let actions = DownloadTreeKt.downloadRowActions(node: node)
        let entries = actions.map { action in
            ItemMenuEntry(label: action.label, systemImage: action.systemImage, id: "\(id).\(action.identifier)", destructive: action.removes) {
                onAction(node, action)
            }
        }
        HStack(spacing: 8) {
            Button {
                if container { onToggle(node.key) } else if let item = node.metadata { onOpen(item) }
            } label: {
                HStack(spacing: 8) {
                    if container {
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .rotationEffect(.degrees(expanded ? 90 : 0))
                            .frame(width: 16)
                            .accessibilityHidden(true)
                    }
                    DownloadStatusIcon(status: status, progress: nil)
                    // Every row as tall as a title over a line of details (a show's, a season's), so a film's or an
                    // episode's row is as tall as its container's.
                    ZStack(alignment: .leading) {
                        VStack(spacing: 4) {
                            Text(verbatim: " ").font(.body)
                            Text(verbatim: " ").font(.footnote)
                        }
                        .hidden()
                        .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(node.title)
                                .font(container ? .body.weight(.semibold) : .body)
                                .foregroundStyle(Palette.onBackground)
                                .lineLimit(1)
                            details(node: node, status: status)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(PressDimButtonStyle())
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier(id)
            .accessibilityActions(entries)
            if !entries.isEmpty {
                SteadyMenuButton(key: [node.key, actions.map(\.identifier)], label: T.shared.common.options, entries: entries, probe: id)
                    .equatable()
                    .accessibilityIdentifier("\(id).menu")
            }
        }
        .contentShape(Rectangle())
        .itemMenu(entries: entries, probe: id)
        #if os(iOS)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            // Red, not the destructive role: a list takes that role's row away at once, before any question is answered.
            ForEach(actions.filter(\.removes), id: \.self) { action in
                Button { onAction(node, action) } label: { Label(action.label, systemImage: action.systemImage) }
                    .tint(Palette.error)
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            if let action = actions.first(where: { !$0.removes }) {
                Button { onAction(node, action) } label: { Label(action.label, systemImage: action.systemImage) }
                    .tint(Palette.primary)
            }
        }
        #endif
    }

    @ViewBuilder
    private func details(node: DownloadTreeNode, status: DownloadedMediaStatus) -> some View {
        if node.hasChildren {
            Text(node.summary).font(.footnote).mutedForeground()
        }
        if status == .downloading {
            ProgressView(value: min(max(node.progress, 0), 1))
                .progressViewStyle(.linear)
                .tint(Palette.primary)
            if let progress = node.downloadProgress {
                Text("\(String(format: "%.1f", node.progress * 100))% - \(progress.speedFormatted)")
                    .font(.footnote)
                    .mutedForeground()
            }
        } else if status == .queued {
            Text(T.shared.downloads.downloadQueued).font(.footnote).mutedForeground()
        } else if status == .failed, let error = node.downloadProgress?.errorMessage {
            Text(error).font(.footnote).foregroundStyle(Palette.error).lineLimit(2)
        }
    }
}

extension DownloadRowAction {
    /// The action takes downloads away: a trailing swipe, the menu's destructive entries.
    var removes: Bool { self == .cancel || self == .delete || self == .deleteAll }
}
#endif
