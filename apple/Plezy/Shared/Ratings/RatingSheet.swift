import SwiftUI
import PlezyKit

extension View {
    /// Raises `store`'s rating sheet (`RatingSheet`) over the app while `store` is set, in an `appSheet`; `onDismiss`
    /// when the user closes it (Close, a swipe, Escape, the remote's Menu), which should clear `store`. A store cleared
    /// or replaced is released, its pending saves still going out: not as the sheet's view goes, which the sheet may
    /// build again.
    func ratingSheet(store: RatingSheetStore?, backend: BackendKind, onDismiss: @escaping () -> Void) -> some View {
        appSheet(item: store, id: "ratingSheet.panel", size: .panel, onDismiss: onDismiss) { store in
            RatingSheet(store: store, backend: backend, onClose: onDismiss)
                .id(ObjectIdentifier(store))
        }
        .onChange(of: store) { old, _ in old?.release() }
    }
}

/// The rating sheet of `store`'s item ("Rate" in its menu), titled by the store: one group of rows (on a card, but
/// on iOS free on the sheet), the server's (its `backend`'s
/// mark; five stars in half steps, or a heart where the server keeps favourites only), then one per connected tracker
/// (its mark, name, account or, in the error colour, why it can't rate), or a line saying to connect one. Each row
/// shows a spinner while it reads or saves and a check once saved, after its name; its control ends the row. A tap or
/// a drag along the stars sets the score and saves it as the finger lifts. On Apple TV each row is a focus stop, the
/// first focused as the sheet opens: Left and Right move it a half star (saved once the presses rest), Select saves it
/// now (flips the favourite), Up and Down move between rows; the Mac's keyboard (with keyboard navigation on) the same,
/// Return or Space saving. VoiceOver reads each row as one adjustable element. A failed save shows as a toast. The store
/// is released once the sheet is gone, its pending saves still going out.
/// Harness names: `ratingSheet`, `ratingSheet.row.server`, `ratingSheet.row.<tracker id>`, `ratingSheet.toast`,
/// `ratingSheet.close`.
struct RatingSheet: View {
    let store: RatingSheetStore
    let backend: BackendKind
    let onClose: () -> Void

    @State private var model: StoreObserver<RatingSheetUiState>
    @FocusState private var focus: String?
    @State private var width: CGFloat = 0

    init(store: RatingSheetStore, backend: BackendKind, onClose: @escaping () -> Void) {
        self.store = store
        self.backend = backend
        self.onClose = onClose
        _model = State(initialValue: StoreObserver(store.state))
    }

    var body: some View {
        let state = model.state
        let controlWidth = RatingMetrics.controlWidth(narrow: width > 0 && width < 430)
        SheetPage(id: "ratingSheet", title: state.title, close: SheetAction(title: T.shared.common.close, id: "ratingSheet.close", action: onClose)) {
            ScrollView {
                VStack(alignment: .leading, spacing: RatingMetrics.spacing) {
                    if state.server != nil || !state.trackers.isEmpty {
                        VStack(spacing: 0) {
                            if let server = state.server {
                                serverRow(server, controlWidth: controlWidth)
                            }
                            ForEach(Array(state.trackers.enumerated()), id: \.element.service) { index, row in
                                if index > 0 || state.server != nil { RatingDivider() }
                                trackerRow(row, controlWidth: controlWidth)
                            }
                        }
                        // On iOS free on the sheet, no card behind: the rows pad themselves from its edges (`lineInset`).
                        #if !os(iOS)
                        .background(Palette.surfaceContainer, in: RoundedRectangle(cornerRadius: RatingMetrics.groupRadius, style: .continuous))
                        #endif
                        #if os(tvOS)
                        .focusSection()
                        #endif
                    }
                    if let text = state.noConnectedServices {
                        Text(text)
                            .font(.subheadline)
                            .foregroundStyle(Palette.onSurfaceVariant)
                            .fixedSize(horizontal: false, vertical: true)
                            #if os(iOS)
                            .padding(.horizontal, RatingMetrics.lineInset)
                            #endif
                    }
                }
                #if os(tvOS)
                .padding(.trailing, 48)
                .padding(.vertical, 48)
                #elseif os(macOS)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 20)
                #else
                .padding(.top, 8)
                .padding(.bottom, 20)
                #endif
                .foregroundStyle(Palette.onBackground)
            }
            .scrollBounceBehavior(.basedOnSize)
            #if os(tvOS)
            .scrollClipDisabled()
            #endif
        }
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        .toast(state.message, id: "ratingSheet.toast") { store.messageShown() }
        .task { await model.observe() }
        #if os(tvOS)
        .task {
            focus = state.server != nil ? "server" : state.trackers.first?.service.id
        }
        #endif
    }

    private func serverRow(_ row: ServerRatingRow, controlWidth: CGFloat) -> some View {
        let key = RatingRowKeyServer.shared
        return RatingSheetRow(
            id: "server",
            title: row.title,
            subtitle: row.subtitle,
            status: row.status,
            loading: row.loading,
            value: row.favoriteOnly ? (row.favorite ? T.shared.rateSheet.favorited : T.shared.rateSheet.favorite) : starsValue(row.value),
            controlWidth: row.favoriteOnly ? RatingMetrics.starHeight : controlWidth,
            focus: $focus,
            onStep: { store.step(key: key, delta: Int32($0)) },
            onSubmit: { store.submit(key: key, value: nil) },
            leading: { BackendLogo(backend: backend, size: RatingMetrics.markSize - 2) },
            control: {
                if row.favoriteOnly {
                    FavoriteControl(favorite: row.favorite, enabled: !row.loading) {
                        store.submit(key: key, value: KotlinInt(int: row.favorite ? 0 : 1))
                    }
                } else {
                    StarControl(value: Int(row.value), enabled: !row.loading, key: key, store: store)
                }
            }
        )
    }

    private func trackerRow(_ row: TrackerRatingRow, controlWidth: CGFloat) -> some View {
        let key = RatingRowKeyTracker(service: row.service)
        return RatingSheetRow(
            id: row.service.id,
            title: row.title,
            subtitle: row.subtitle,
            status: row.status,
            loading: row.loading,
            value: starsValue(row.value),
            controlWidth: controlWidth,
            focus: $focus,
            onStep: { store.step(key: key, delta: Int32($0)) },
            onSubmit: { store.submit(key: key, value: nil) },
            leading: { TrackerLogo(service: row.service, size: RatingMetrics.markSize) },
            control: { StarControl(value: Int(row.value), enabled: !row.loading, key: key, store: store) }
        )
    }

    /// A score (0–10) as VoiceOver reads it: in stars, "4.5".
    private func starsValue(_ value: Int32) -> String {
        RatingBadgesKt.formatRating(value: Double(value) / 2)
    }
}

/// The measures of the rating sheet and the watchlist chooser: points on iOS and the Mac; on
/// Apple TV, whose points are a 1080p screen's pixels, the same share of the screen.
enum RatingMetrics {
    #if os(tvOS)
    static let spacing: CGFloat = 32
    static let markSize: CGFloat = 48
    static let markGap: CGFloat = 32
    static let lineInset: CGFloat = 32
    static let lineHeight: CGFloat = 96
    static let starHeight: CGFloat = 64
    static let groupRadius: CGFloat = Radius.large
    /// The name and status column's least width: room for "MyAnimeList" and a status on one line each in the sheet's
    /// narrow panel.
    static let nameWidth: CGFloat = 200
    /// Between the name column, the control and the status mark.
    static let controlGap: CGFloat = 20
    /// The status mark after a row's name.
    static let statusSize: CGFloat = 28
    #else
    static let spacing: CGFloat = 16
    static let markSize: CGFloat = 24
    static let markGap: CGFloat = 16
    static let lineInset: CGFloat = 16
    static let lineHeight: CGFloat = 52
    static let starHeight: CGFloat = 34
    static let groupRadius: CGFloat = Radius.medium
    /// Between the name column and the control: tight, so "Connected as @account" keeps one line beside the stars on
    /// a 390-pt iPhone.
    static let controlGap: CGFloat = 10
    static let nameWidth: CGFloat = 0
    static let statusSize: CGFloat = 14
    #endif

    /// The stars' (or the favourite's) width: narrower below 430 pt (every iPhone but the largest), leaving the name and
    /// its account a line each; on Apple TV five 46-point stars, the name column taking the rest of the panel.
    static func controlWidth(narrow: Bool) -> CGFloat {
        #if os(tvOS)
        230
        #else
        narrow ? 88 : 142
        #endif
    }
}

/// The hairline between two rows of a rating group, from the text's leading edge.
struct RatingDivider: View {
    var body: some View {
        Divider().padding(.leading, RatingMetrics.lineInset + RatingMetrics.markSize + RatingMetrics.markGap)
    }
}

/// A row of the sheet: `leading` mark, `title` (then the spinner while `loading`, else `status`'s check or error mark)
/// over `subtitle` (or an error `status`'s text in the error colour), then the `control` `controlWidth` wide at its end.
/// On Apple TV the row is a button, its focus a solid fill behind it: Left and Right `onStep` its control, Select
/// `onSubmit`s it. On the Mac it takes keyboard focus the same way. One element for VoiceOver, valued `value`: a swipe up
/// or down steps it, a double tap submits it.
private struct RatingSheetRow<Leading: View, Control: View>: View {
    let id: String
    let title: String
    let subtitle: String
    let status: RatingRowStatus?
    let loading: Bool
    let value: String
    let controlWidth: CGFloat
    let focus: FocusState<String?>.Binding
    let onStep: (Int) -> Void
    let onSubmit: () -> Void
    @ViewBuilder let leading: () -> Leading
    @ViewBuilder let control: () -> Control

    var body: some View {
        Group {
            #if os(tvOS)
            Button(action: onSubmit) { content }
                .buttonStyle(RatingRowStyle())
                .focused(focus, equals: id)
                .onMoveCommand(perform: move)
            #elseif os(macOS)
            content
                .background(
                    focus.wrappedValue == id ? Palette.surfaceContainerHigh : .clear,
                    in: RoundedRectangle(cornerRadius: RatingMetrics.groupRadius, style: .continuous)
                )
                .focusable(true, interactions: .activate)
                .focusEffectDisabled()
                .focused(focus, equals: id)
                .onMoveCommand(perform: move)
                .onKeyPress(.return) { onSubmit(); return .handled }
                .onKeyPress(.space) { onSubmit(); return .handled }
            #else
            content
            #endif
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel([title, error?.text ?? subtitle, status.flatMap { $0.isError ? nil : $0.text }].compactMap { $0 }.joined(separator: ", "))
        .accessibilityValue(value)
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: onStep(1)
            case .decrement: onStep(-1)
            @unknown default: break
            }
        }
        .accessibilityAction(.default, onSubmit)
        .accessibilityIdentifier("ratingSheet.row.\(id)")
    }

    private var error: RatingRowStatus? { status.flatMap { $0.isError ? $0 : nil } }

    #if !os(iOS)
    private func move(_ direction: MoveCommandDirection) {
        switch direction {
        case .left: onStep(-1)
        case .right: onStep(1)
        default: break
        }
    }
    #endif

    private var content: some View {
        HStack(spacing: RatingMetrics.markGap) {
            leading()
                .frame(width: RatingMetrics.markSize, height: RatingMetrics.markSize)
            HStack(spacing: RatingMetrics.controlGap) {
                names
                    .frame(minWidth: RatingMetrics.nameWidth, maxWidth: .infinity, alignment: .leading)
                    .layoutPriority(1)
                control()
                    .frame(width: controlWidth)
            }
        }
        .padding(.horizontal, RatingMetrics.lineInset)
        .frame(minHeight: RatingMetrics.lineHeight)
        .contentShape(Rectangle())
    }

    /// The name with the row's status mark after it, over the subtitle (or an error status's text in the error colour):
    /// a line each, cut short in the middle where the stars leave too little room.
    private var names: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Text(title)
                    .foregroundStyle(Palette.onBackground)
                    .lineLimit(1)
                RowStatusMark(status: status, loading: loading)
                    .frame(width: RatingMetrics.statusSize, height: RatingMetrics.statusSize)
            }
            Text(error?.text ?? subtitle)
                #if os(iOS)
                .font(.footnote)
                #else
                .font(.subheadline)
                #endif
                .foregroundStyle(error != nil ? Palette.error : Palette.onSurfaceVariant)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }
}

#if os(tvOS)
/// A rating row on Apple TV: a solid fill behind it while it has focus, nothing grown or lifted, shrinking a little while
/// clicked (`tvPressed`).
private struct RatingRowStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        Row(configuration: configuration)
    }

    private struct Row: View {
        let configuration: Configuration

        @Environment(\.isFocused) private var focused

        var body: some View {
            configuration.label
                .background(
                    focused ? Palette.surfaceContainerHigh : .clear,
                    in: RoundedRectangle(cornerRadius: RatingMetrics.groupRadius, style: .continuous)
                )
                .animation(.easeOut(duration: 0.15), value: focused)
                .tvPressed(configuration.isPressed)
        }
    }
}
#endif

/// The spinner while the row reads or saves, else its status: the check once saved, the error mark in the error
/// colour.
private struct RowStatusMark: View {
    let status: RatingRowStatus?
    let loading: Bool

    var body: some View {
        if loading {
            ProgressView()
                .controlSize(.mini)
        } else if let status {
            Image(systemName: status.isError ? "exclamationmark.circle.fill" : "checkmark")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .fontWeight(.semibold)
                .foregroundStyle(status.isError ? Palette.error : Palette.onBackground)
        } else {
            // Keeps the slot, so every row's stars line up.
            Color.clear
        }
    }
}

/// Five stars at the control's end, each half a point of `value` (0–10): the given half stars in the
/// text colour, the rest a dim solid fill. A press sets the score at the finger or pointer (its share of the whole
/// control's width in half stars, rounded) and so does each move of a drag (`change`); the release saves the last one
/// (`submit`). Apple TV draws it only: the row's Left, Right and Select change it.
private struct StarControl: View {
    let value: Int
    let enabled: Bool
    let key: RatingRowKey
    let store: RatingSheetStore

    @State private var width: CGFloat = 0
    @State private var dragged: Int?

    var body: some View {
        let starWidth = width / 5
        let iconSize = min(starWidth * 0.85, RatingMetrics.starHeight * 0.75)
        HStack(spacing: 0) {
            ForEach(1...5, id: \.self) { star in
                StarGlyph(fill: value >= star * 2 ? 1 : value == star * 2 - 1 ? 0.5 : 0)
                    .frame(width: iconSize, height: iconSize)
                    .frame(width: starWidth)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: RatingMetrics.starHeight)
        .opacity(enabled ? 1 : 0.5)
        .contentShape(Rectangle())
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        #if !os(tvOS)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { drag in
                    let score = score(at: drag.location.x)
                    guard score != dragged else { return }
                    dragged = score
                    store.change(key: key, value: Int32(score))
                }
                .onEnded { drag in
                    dragged = nil
                    store.submit(key: key, value: KotlinInt(int: Int32(score(at: drag.location.x))))
                },
            including: enabled ? .all : .none
        )
        #endif
    }

    /// The score at `x`: its share of the control's width in half stars, rounded.
    private func score(at x: CGFloat) -> Int {
        let span = width > 0 ? width : 1
        return Int((min(max(x, 0), span) / span * 10).rounded())
    }
}

/// A star in the text colour from its leading edge as far as `fill` (0, ½ or 1), the rest a dim solid fill.
private struct StarGlyph: View {
    let fill: CGFloat

    var body: some View {
        let glyph = Image(systemName: "star.fill").resizable().aspectRatio(contentMode: .fit)
        glyph
            .foregroundStyle(Palette.onBackground.opacity(0.2))
            .overlay {
                if fill > 0 {
                    glyph
                        .foregroundStyle(Palette.onBackground)
                        .mask {
                            GeometryReader { proxy in
                                Rectangle().frame(width: proxy.size.width * fill)
                            }
                        }
                }
            }
    }
}

/// A heart, filled while `favorite`, named "Favorite" or "Favorited" for VoiceOver; a tap toggles it (`onToggle`; on
/// Apple TV the row's Select).
private struct FavoriteControl: View {
    let favorite: Bool
    let enabled: Bool
    let onToggle: () -> Void

    var body: some View {
        Image(systemName: favorite ? "heart.fill" : "heart")
            .font(.title3.weight(.semibold))
            .foregroundStyle(Palette.onBackground)
            .opacity(enabled ? 1 : 0.5)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .frame(height: RatingMetrics.starHeight)
            .accessibilityLabel(favorite ? T.shared.rateSheet.favorited : T.shared.rateSheet.favorite)
            .contentShape(Rectangle())
            #if !os(tvOS)
            .onTapGesture { if enabled { onToggle() } }
            #endif
    }
}
