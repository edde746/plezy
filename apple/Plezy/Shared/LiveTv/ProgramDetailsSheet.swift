import SwiftUI
import PlezyKit

extension View {
    /// The program details of `store` in an `appSheet` while it is set (a `TrailingPanel` on Apple TV); closed by the
    /// user, `onClose`.
    func programDetailsSheet(_ store: ProgramDetailsStore?, onClose: @escaping () -> Void) -> some View {
        appSheet(item: store, id: "livetv.detailsPanel", size: .panel, onDismiss: onClose) { details in
            ProgramDetailsSheet(store: details, onClose: onClose)
                .id(ObjectIdentifier(details))
        }
    }
}

/// A program's details (`ProgramDetailsUiState`), as the guide's programme sheet: the poster, the title with its NEW and
/// LIVE badges, "{channel} · {start} - {end} · {length}" and the whole summary, scrolling, and under them the actions
/// (Play or Watch Channel, Record or Manage recording; the filled one the main action; the cast button beside Play or
/// Watch Channel); Close in the bar. Over it the delete-rule confirmation and the Record Options sheet.
///
/// Accessibility identifiers: `livetv.details`, `livetv.details.title`, `livetv.details.close`,
/// `livetv.details.action.<play|watch|record|manage>`, `livetv.details.cast`, `livetv.confirm`, `livetv.confirm.cancel`.
struct ProgramDetailsSheet: View {
    let store: ProgramDetailsStore
    let onClose: () -> Void

    @State private var observer: StoreObserver<ProgramDetailsUiState>
    @Environment(\.formFactor) private var formFactor

    init(store: ProgramDetailsStore, onClose: @escaping () -> Void) {
        self.store = store
        self.onClose = onClose
        _observer = State(initialValue: StoreObserver(store.state))
    }

    var body: some View {
        let state = observer.state
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                ScrollView {
                    details(state)
                        .padding(.horizontal, formFactor == .tv ? 0 : 20)
                        .padding(.vertical, formFactor == .tv ? 40 : 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .scrollBounceBehavior(.basedOnSize)
                actions(state)
                    .padding(.horizontal, formFactor == .tv ? 0 : 20)
                    .padding(.vertical, formFactor == .tv ? 40 : 12)
            }
            .frame(maxHeight: .infinity, alignment: .top)
            // On the stack's content: a sheet's navigation stack doesn't carry an identifier to accessibility.
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("livetv.details")
            .sheetToolbar(close: SheetAction(title: T.shared.common.close, id: "livetv.details.close", action: onClose))
        }
        .liveTvConfirmation(state.confirmation, onConfirm: { store.confirm() }, onCancel: { store.dismissConfirmation() })
        .recordOptionsSheet(state.recordOptions)
        .task { await observer.observe() }
    }

    private func details(_ state: ProgramDetailsUiState) -> some View {
        HStack(alignment: .top, spacing: formFactor == .tv ? 40 : 16) {
            if let poster = state.poster {
                RemoteImage(artwork: poster)
                    .frame(width: formFactor == .tv ? 200 : 100, height: formFactor == .tv ? 300 : 150)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.small, style: .continuous))
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 8) {
                Text(state.title)
                    .font(.title2.weight(.semibold))
                    .accessibilityIdentifier("livetv.details.title")
                if state.premiereBadge != nil || state.liveBadge != nil || state.endedBadge != nil {
                    HStack(spacing: 6) {
                        if let premiere = state.premiereBadge { BadgeView(text: premiere, emphasis: .strong) }
                        if let live = state.liveBadge {
                            Label(live, systemImage: "dot.radiowaves.left.and.right")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Palette.live)
                        }
                        if let ended = state.endedBadge { BadgeView(text: ended) }
                    }
                }
                Text(state.info)
                    .font(.subheadline)
                    .foregroundStyle(Palette.onSurfaceVariant)
                if let summary = state.summary {
                    Text(summary)
                        .font(.body)
                        .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private func actions(_ state: ProgramDetailsUiState) -> some View {
        if !state.actions.isEmpty {
            let layout = formFactor == .compact ? AnyLayout(VStackLayout(spacing: 8)) : AnyLayout(HStackLayout(spacing: 16))
            layout {
                ForEach(Array(state.actions.enumerated()), id: \.offset) { _, action in
                    ActionButton(
                        title: action.label, id: "livetv.details.action.\(Self.id(action.kind))",
                        prominence: action.filled ? .primary : .secondary, systemImage: Self.symbol(action.kind),
                        fullWidth: formFactor == .compact
                    ) { store.act(kind: action.kind) }
                }
                if state.actions.contains(where: { $0.kind == .play || $0.kind == .watchChannel }) {
                    CastButton(look: .detail, id: "livetv.details.cast")
                }
            }
            .glassGroup(spacing: 8)
            .shelfFocusSection()
        }
    }

    static func symbol(_ kind: ProgramActionKind) -> String {
        switch kind {
        case .play: "play.fill"
        case .watchChannel: "play.tv"
        default: "record.circle"
        }
    }

    private static func id(_ kind: ProgramActionKind) -> String {
        switch kind {
        case .play: "play"
        case .watchChannel: "watch"
        case .record: "record"
        default: "manage"
        }
    }
}
