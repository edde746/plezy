#if !os(tvOS)
import SwiftUI
import PlezyKit

/// Sync rules, a settings page pushed from Downloads under its title and Back, over the session's `SyncRulesStore`: the
/// profile's rules as one group of rows, each its symbol (a show or season, a collection, a playlist), title, what it
/// keeps ("Keep 5 unwatched", "All items") and its server with that server's state, muted; beside it its enabled switch
/// and Remove, a plain icon button. A press edits the rule (a show's or season's episode count, a list's filter). The
/// same actions are in the row's context menu (a long press, a right click) and on iPhone and iPad its swipes: Pause or
/// Resume from the leading edge, Remove from the trailing edge. Removing asks first. No rules: "No sync rules" under the
/// sync symbol. Feedback shows as a toast.
///
/// Accessibility identifiers: `syncRules.screen`, `syncRules.row.<key>`, `syncRules.row.<key>.enabled`,
/// `syncRules.row.<key>.remove`, the menu's `syncRules.row.<key>.menu.<edit|enabled|remove>`, `syncRules.empty`,
/// `syncRules.message`.
struct SyncRulesScreen: View {
    @State private var store: SyncRulesStore?
    @State private var observer: StoreObserver<SyncRulesUiState>?

    init(app: AppModel) {
        let store = app.session.syncRulesStore()
        _store = State(initialValue: store)
        _observer = State(initialValue: store.map { StoreObserver($0.state) })
    }

    var body: some View {
        if let store, let observer {
            let state = observer.state
            Group {
                if state.rules.isEmpty {
                    EmptyStateView(message: state.empty, systemImage: "arrow.triangle.2.circlepath")
                        .accessibilityElement(children: .combine)
                        .accessibilityIdentifier("syncRules.empty")
                } else {
                    Form {
                        Section {
                            ForEach(state.rules, id: \.globalKey) { rule in
                                SyncRuleRowView(rule: rule, removeLabel: state.removeLabel, store: store)
                            }
                        }
                    }
                    .settingsForm()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .pageTitle(state.title)
            .toast(state.message?.message, id: "syncRules.message", isError: state.message?.isError == true, onShown: store.messageShown)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("syncRules.screen")
            .task { await observer.observe() }
        }
    }
}

private struct SyncRuleRowView: View {
    let rule: SyncRuleRow
    let removeLabel: String
    let store: SyncRulesStore

    var body: some View {
        let id = "syncRules.row.\(rule.globalKey)"
        let enabled = Binding(get: { rule.enabled }, set: { store.setEnabled(globalKey: rule.globalKey, enabled: $0) })
        HStack(spacing: 12) {
            Button { store.edit(globalKey: rule.globalKey) } label: {
                HStack(spacing: 12) {
                    Image(systemName: rule.icon.systemImage)
                        .foregroundStyle(rule.enabled ? Palette.primary : Palette.onSurfaceVariant)
                        .frame(width: 28)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(rule.title).foregroundStyle(Palette.onBackground).lineLimit(2)
                        Text(rule.subtitle).font(.footnote).mutedForeground()
                        Text(rule.serverLine).font(.footnote).mutedForeground()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PressDimButtonStyle())
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier(id)
            Toggle(rule.title, isOn: enabled)
                .labelsHidden()
                .toggleStyle(.switch)
                .tint(Palette.switchOn)
                .accessibilityIdentifier("\(id).enabled")
            Button { store.remove(globalKey: rule.globalKey) } label: {
                Image(systemName: "xmark").mutedForeground()
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(removeLabel)
            #if os(macOS)
            .help(removeLabel)
            #endif
            .accessibilityIdentifier("\(id).remove")
        }
        .contextMenu {
            Button { store.edit(globalKey: rule.globalKey) } label: { Label(T.shared.downloads.editSyncRule, systemImage: "pencil") }
                .accessibilityIdentifier("\(id).menu.edit")
            Toggle(isOn: enabled) { Label(rule.title, systemImage: "arrow.triangle.2.circlepath") }
                .accessibilityIdentifier("\(id).menu.enabled")
            Button(role: .destructive) { store.remove(globalKey: rule.globalKey) } label: { Label(removeLabel, systemImage: "trash") }
                .accessibilityIdentifier("\(id).menu.remove")
        }
        #if os(iOS)
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button { store.setEnabled(globalKey: rule.globalKey, enabled: !rule.enabled) } label: {
                Label(rule.title, systemImage: rule.enabled ? "pause.fill" : "play.fill")
            }
            .tint(Palette.primary)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            // Red, not the destructive role: a list takes that role's row away at once, before the question is answered.
            Button { store.remove(globalKey: rule.globalKey) } label: { Label(removeLabel, systemImage: "trash") }
                .tint(Palette.error)
        }
        #endif
    }
}

extension SyncRuleIcon {
    var systemImage: String {
        switch self {
        case .show: "tv"
        case .collection: "rectangle.stack"
        case .playlist: "music.note.list"
        }
    }
}
#endif
