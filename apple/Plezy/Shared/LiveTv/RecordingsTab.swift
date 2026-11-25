import SwiftUI
import PlezyKit

/// The Scheduled tab (`RecordingsUiState`) as the platform's list (`rowList`): a spinner until the first load; the empty
/// state under the record symbol when there is nothing to list; else the "Upcoming" section (each recording: its title,
/// "{day} · {time} · {length} · {call sign}", a running one with the record symbol and "Recording now", a failed one
/// with its error) and the "Recording Rules" section (title, "Record series · {airings} · {n} scheduled"), their rows
/// starting where the header's controls do. A recording asks to be cancelled; a rule offers Edit and Delete
/// (`ruleRow`). Over it: the confirmation and the Edit rule sheet.
///
/// Accessibility identifiers: `livetv.recordings`, `livetv.recordings.loading`, `livetv.recordings.empty`,
/// `livetv.recordings.grab.<index>`, `livetv.recordings.rule.<index>`, `livetv.recordings.ruleMenu.<0: Edit, 1: Delete>`.
struct RecordingsTab: View {
    let state: RecordingsUiState
    let store: RecordingsStore
    var focus: FocusState<LiveTvField?>.Binding

    /// The rule focused, and the one last focused, which gets focus back as its Edit rule sheet or confirmation closes
    /// (else the tab's first row: the rule deleted).
    @FocusState private var focusedRule: String?
    @State private var lastRule: String?

    @Environment(\.screenSides) private var sides
    @Environment(\.formFactor) private var formFactor

    var body: some View {
        Group {
            switch onEnum(of: state.body) {
            case .loading:
                LoadingStateView().accessibilityIdentifier("livetv.recordings.loading")
            case .empty(let empty):
                EmptyStateView(message: empty.text, systemImage: "record.circle")
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("livetv.recordings.empty")
            case .lists(let lists):
                rowList {
                    if !lists.grabs.isEmpty {
                        section(state.scheduledTitle) {
                            ForEach(Array(lists.grabs.enumerated()), id: \.element.id) { index, grab in
                                Button { store.tapGrab(id: grab.id) } label: { grabRow(grab) }
                                    .formRowButtonStyle()
                                    .focused(focus, as: .content, when: index == 0)
                                    .accessibilityIdentifier("livetv.recordings.grab.\(index)")
                                    .macRowInsets(sides)
                            }
                        }
                    }
                    if !lists.rules.isEmpty {
                        section(state.rulesTitle) {
                            ForEach(Array(lists.rules.enumerated()), id: \.element.id) { index, rule in
                                ruleRow(rule)
                                    .focused(focus, as: .content, when: lists.grabs.isEmpty && index == 0)
                                    .focused($focusedRule, equals: rule.id)
                                    .accessibilityIdentifier("livetv.recordings.rule.\(index)")
                                    .macRowInsets(sides)
                            }
                        }
                    }
                }
                .accessibilityIdentifier("livetv.recordings")
            }
        }
        .liveTvConfirmation(state.confirmation, onConfirm: { store.confirm() }, onCancel: { store.dismissConfirmation() })
        .recordOptionsSheet(state.recordOptions)
        #if os(tvOS)
        .entriesDialog(
            state.ruleMenu?.title,
            isPresented: state.ruleMenu != nil,
            entries: ruleEntries,
            probe: "livetv.recordings.ruleMenu",
            onCancel: { store.chooseRuleAction(action: nil) }
        )
        #endif
        .onChange(of: focusedRule) { _, rule in if let rule { lastRule = rule } }
        .onChange(of: state.recordOptions == nil && state.confirmation == nil) { _, closed in
            guard closed else { return }
            Task { @MainActor in
                if case .lists(let lists) = onEnum(of: state.body), let lastRule, lists.rules.contains(where: { $0.id == lastRule }) {
                    await FocusRestore.restore($focusedRule, to: lastRule, hold: 1)
                } else {
                    await FocusRestore.restore(focus, to: .content, hold: 1)
                }
            }
        }
    }

    /// The sections as the platform's list. A Mac's grouped form keeps its cards in a centred column of its own, so
    /// there a plain list (the Downloads list's) whose rows run from the header's leading edge to the page's other side
    /// (`macRowInsets`). Elsewhere a grouped form: on Apple TV and wider than a phone its cards start and end at the
    /// page's sides, the chips' and the actions' edges; on a phone its own margins already are the header's.
    @ViewBuilder
    private func rowList<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        #if os(macOS)
        List(content: content)
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        #else
        Form(content: content)
            .formStyle(.grouped)
            #if os(tvOS)
            // A focused card's platter reaches past the form's edge: the form doesn't cut it off.
            .scrollClipDisabled()
            #endif
            .contentMargins(.leading, formFactor == .compact ? nil : sides.leading, for: .scrollContent)
            .contentMargins(.trailing, formFactor == .compact ? nil : sides.trailing, for: .scrollContent)
        #endif
    }

    /// A section of `rowList` headed `title`. A Mac's plain list keeps its section headers at the table's own inset, so
    /// there the heading is the section's first row, starting where its rows do.
    @ViewBuilder
    private func section<Rows: View>(_ title: String, @ViewBuilder rows: () -> Rows) -> some View {
        #if os(macOS)
        Section {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.top, 8)
                .accessibilityAddTraits(.isHeader)
                .macRowInsets(sides)
            rows()
        }
        #else
        Section(title, content: rows)
        #endif
    }

    private func grabRow(_ grab: GrabRow) -> some View {
        HStack(spacing: 12) {
            rowText(grab.title, grab.subtitle)
            if let pill = grab.pill {
                Label(pill, systemImage: grab.failed ? "exclamationmark.triangle.fill" : "record.circle")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(grab.failed ? Palette.error : Palette.live)
            }
        }
    }

    private func rowText(_ title: String, _ subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.subheadline)
                    .mutedForeground()
            }
        }
        .lineLimit(1)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    /// The rule's row, which offers Edit and Delete (the store's rule picker, `tapRule` then the choice): a menu, on
    /// Apple TV a button of the form's opening them as the system's action sheet (`ruleEntries`), since a menu there
    /// draws a platter of its own inside the form's card.
    @ViewBuilder
    private func ruleRow(_ rule: RuleRow) -> some View {
        #if os(tvOS)
        Button { store.tapRule(id: rule.id) } label: { rowText(rule.title, rule.subtitle) }
        #else
        Menu {
            Button {
                store.tapRule(id: rule.id)
                store.chooseRuleAction(action: .edit)
            } label: {
                SwiftUI.Label(T.shared.liveTv.editRuleAction, systemImage: "pencil")
            }
            .accessibilityIdentifier("livetv.recordings.ruleMenu.0")
            Button(role: .destructive) {
                store.tapRule(id: rule.id)
                store.chooseRuleAction(action: .delete)
            } label: {
                SwiftUI.Label(T.shared.common.delete, systemImage: "trash")
            }
            .accessibilityIdentifier("livetv.recordings.ruleMenu.1")
        } label: {
            rowText(rule.title, rule.subtitle)
        }
        .menuStyle(.button)
        .formRowButtonStyle()
        #endif
    }

    #if os(tvOS)
    /// The rule picker's Edit and Delete while it is up (`RecordingsUiState.ruleMenu`).
    private var ruleEntries: [ItemMenuEntry] {
        (state.ruleMenu?.actions ?? []).enumerated().map { index, choice in
            let delete = choice.action == RuleAction.delete
            return ItemMenuEntry(
                label: choice.label,
                systemImage: delete ? "trash" : "pencil",
                id: "livetv.recordings.ruleMenu.\(index)",
                destructive: delete
            ) { store.chooseRuleAction(action: choice.action) }
        }
    }
    #endif
}

private extension View {
    /// A Mac's list row (or section header) from the page's leading side to its trailing one, less the list's own cell
    /// margin; elsewhere the form's own insets.
    @ViewBuilder
    func macRowInsets(_ sides: ScreenSides) -> some View {
        #if os(macOS)
        listRowInsets(EdgeInsets(top: 4, leading: sides.leading - listRowMargin, bottom: 4, trailing: sides.trailing - listRowMargin))
            .listRowSeparator(.hidden)
        #else
        self
        #endif
    }
}
