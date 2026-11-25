import SwiftUI
import PlezyKit

/// The detail's watchlist button: the bookmark, filled while the item is on any connected source's watchlist, its
/// label what a press does; with several sources a press opens the watchlist sheet (`watchlistChooser`), on Apple TV
/// the button is the system's menu of the sources once their watchlists are known (each its name, what picking it
/// does, a check while the item is on it), which gives it focus back as it closes. Off Apple TV it can't be pressed
/// until a membership is known; on Apple TV a press then loads the watchlists. Nothing while the store has no button.
/// Identifiers `detail.watchlist`, `detail.watchlist.option.<i>`.
struct DetailWatchlistButton: View {
    let model: StoreModel<DetailWatchlistStore, DetailWatchlistUi?>
    var focus: FocusState<String?>.Binding?

    var body: some View {
        if let state = model.state.state {
            let store = model.store
            let symbol = state.onWatchlist == true ? "bookmark.fill" : "bookmark"
            #if os(tvOS)
            if state.enabled, let sources = state.sources {
                focusing(sourcesMenu(sources, symbol: symbol, label: state.label))
            } else {
                focusing(IconButton(systemImage: symbol, label: state.label, id: "detail.watchlist", action: store.press))
            }
            #else
            focusing(
                IconButton(systemImage: symbol, label: state.label, id: "detail.watchlist", enabled: state.enabled, action: store.press)
                    .watchlistChooser(
                        state.chooser,
                        probe: "detail.watchlist.option",
                        onPick: { store.choose(index: KotlinInt(int: Int32($0))) },
                        onDismiss: { store.choose(index: nil) }
                    )
            )
            #endif
        }
    }

    @ViewBuilder
    private func focusing(_ button: some View) -> some View {
        if let focus {
            button.focused(focus, equals: "detail.watchlist")
        } else {
            button
        }
    }

    #if os(tvOS)
    private func sourcesMenu(_ sources: [WatchlistSourceOption], symbol: String, label: String) -> some View {
        Menu {
            ForEach(Array(sources.enumerated()), id: \.offset) { index, source in
                Button { model.store.toggleSource(index: Int32(index)) } label: {
                    if source.member {
                        Label {
                            Text(source.name)
                            Text(source.action)
                        } icon: {
                            Image(systemName: "checkmark")
                        }
                    } else {
                        Text(source.name)
                        Text(source.action)
                    }
                }
                .accessibilityLabel("\(source.name), \(source.action)")
                .accessibilityAddTraits(source.member ? .isSelected : [])
                .accessibilityIdentifier("detail.watchlist.option.\(index)")
            }
        } label: {
            Image(systemName: symbol)
                .font(.body.weight(.semibold))
                .roundGlassLabel(.circle, menu: true)
        }
        .roundGlassControl(.circle, menu: true)
        .accessibilityLabel(label)
        .accessibilityIdentifier("detail.watchlist")
    }
    #endif
}

#if !os(tvOS)
extension View {
    /// The watchlist sheet of `options` while they're set, titled Watchlist: a full-height sheet with Close
    /// (`appSheet` of `SheetSize.panel`). Picking a row toggles that source's watchlist and closes
    /// the sheet: `onPick` gets the row's index, `onDismiss` a dismissal. Apple TV picks from the system's menus
    /// instead (the detail's button; an item menu's options). Identifiers `<probe>.sheet`, `<probe>.<i>`,
    /// `<probe>.close`.
    func watchlistChooser(
        _ options: [WatchlistSourceOption]?,
        probe: String,
        onPick: @escaping (Int) -> Void,
        onDismiss: @escaping () -> Void
    ) -> some View {
        modifier(WatchlistChooserHost(options: options, probe: probe, onPick: onPick, onDismiss: onDismiss))
    }
}

private struct WatchlistChooserHost: ViewModifier {
    let options: [WatchlistSourceOption]?
    let probe: String
    let onPick: (Int) -> Void
    let onDismiss: () -> Void

    /// The sheet is up. It follows `options` a moment late on iPhone and iPad: an item menu's Add to Watchlist sets
    /// them from the menu's dialog as the system closes it, and a sheet asked for while that dialog goes never shows.
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .appSheet(isPresented: Binding(get: { shown }, set: { if !$0 { onDismiss() } }), id: "\(probe).panel", size: .panel) {
                SheetPage(id: "\(probe).sheet", title: T.shared.explore.rows.watchlist, close: SheetAction(title: T.shared.common.close, id: "\(probe).close", action: onDismiss)) {
                    ScrollView(.vertical) {
                        WatchlistChooserList(options: options ?? [], probe: probe, onPick: onPick)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                            .padding(.bottom, 20)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                }
            }
            .task(id: options != nil) {
                guard options != nil else {
                    shown = false
                    return
                }
                #if os(iOS)
                // The menu dialog's closing animation.
                do { try await Task.sleep(for: .milliseconds(450)) } catch { return }
                #endif
                shown = true
            }
    }
}

/// The sheet's rows in one group: each source's mark and name, then what picking it does
/// (Add, Remove) and a check while the item is on that watchlist. The first row takes focus.
private struct WatchlistChooserList: View {
    let options: [WatchlistSourceOption]
    let probe: String
    let onPick: (Int) -> Void

    @FocusState private var focus: Int?

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                if index > 0 { RatingDivider() }
                Button { onPick(index) } label: {
                    HStack(spacing: RatingMetrics.markGap) {
                        SourceMark(id: option.logo, size: RatingMetrics.markSize)
                        Text(option.name)
                            .foregroundStyle(Palette.onBackground)
                            .lineLimit(1)
                        Spacer(minLength: 16)
                        Text(option.action)
                            .font(.subheadline)
                            .foregroundStyle(Palette.onSurfaceVariant)
                            .lineLimit(1)
                        if option.member {
                            Image(systemName: "checkmark")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(Palette.onBackground)
                        }
                    }
                    .padding(.horizontal, RatingMetrics.lineInset)
                    .frame(minHeight: RatingMetrics.lineHeight)
                    .contentShape(Rectangle())
                }
                .buttonStyle(WatchlistRowStyle())
                .focused($focus, equals: index)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(option.name), \(option.action)")
                .accessibilityAddTraits(option.member ? [.isButton, .isSelected] : .isButton)
                .accessibilityIdentifier("\(probe).\(index)")
            }
        }
        .background(Palette.surfaceContainer, in: RoundedRectangle(cornerRadius: RatingMetrics.groupRadius, style: .continuous))
        .task { focus = 0 }
    }
}

/// A row of the sheet: dimmed while pressed.
private struct WatchlistRowStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}
#endif
