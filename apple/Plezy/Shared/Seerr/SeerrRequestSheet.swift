import SwiftUI
import PlezyKit

/// Requesting a title from Seerr, as a settings form in a sheet over the screen it was asked from: the title's name
/// in the bar (Request is the bar's button), then a spinner while the instance's settings load, the
/// failure with Retry, "nothing to request" beside a check, or the form: the seasons (All seasons, then a switch per
/// season, a blocked one on and disabled with its state), Request in 4K, the advanced destination pickers and tags, and
/// the inline error. Request is the bar's confirmation and Cancel its cancellation (on Apple TV the form's last
/// buttons). Once the store says the sheet is done it closes, its message shown on the screen beneath (`AppModel.notice`).
///
/// Accessibility identifiers: `seerrRequest.sheet`, `seerrRequest.<retry|nothing|allSeasons|season.<n>|4k|tags|error|
/// submit|cancel>`, `seerrRequest.picker.<kind>`.
struct SeerrRequestSheet: View {
    let app: AppModel
    let route: RouteSeerrRequest

    @State private var model: StoreModel<SeerrRequestStore, SeerrRequestUiState>?
    @FocusState private var focus: String?

    init(app: AppModel, route: RouteSeerrRequest) {
        self.app = app
        self.route = route
        _model = State(initialValue: StoreModel(app.session.seerrRequest(route: route)) { $0.state })
    }

    var body: some View {
        if let model {
            let state = model.state.state
            let store = model.store
            // Nothing left to request: the sheet only closes, so its button says Close.
            let nothing = if case .nothingToRequest = onEnum(of: state.body) { true } else { false }
            let cancel = SheetAction(
                title: nothing ? T.shared.common.close : T.shared.common.cancel, id: nothing ? "seerrRequest.close" : "seerrRequest.cancel"
            ) { _ = app.navigator.pop(route: route) }
            let submit: SheetAction? = if case .form(let form) = onEnum(of: state.body) {
                // While it sends, Request keeps its title, a spinner beside it; the store ignores presses.
                SheetAction(
                    title: form.submitLabel, id: "seerrRequest.submit", enabled: form.canSubmit || form.submitting,
                    busy: form.submitting, action: store.submit
                )
            } else {
                nil
            }
            SheetPage(id: "seerrRequest.sheet", title: state.title, cancel: cancel, confirm: submit) {
                Form {
                    Section {
                        content(state.body, store: store)
                    }
                    if case .form(let form) = onEnum(of: state.body) {
                        RequestForm(form: form, store: store, focus: $focus)
                    }
                    #if os(tvOS)
                    // The form's buttons (tvOS's bar has none), Request focusable so the store can send focus to it.
                    Section {
                        if let submit {
                            Button(action: submit.action) { SheetActionLabel(action: submit) }
                                .disabled(!submit.enabled)
                                .focused($focus, equals: submit.id)
                                .accessibilityIdentifier(submit.id)
                        }
                        Button(cancel.title, action: cancel.action).accessibilityIdentifier(cancel.id)
                    }
                    #endif
                }
                .settingsForm()
            }
            .task { await model.state.observe() }
            .onChange(of: state.closed, initial: true) {
                guard let closed = state.closed else { return }
                if let message = closed.message { app.notice = MenuMessage(text: message, isError: closed.isError) }
                _ = app.navigator.pop(route: route)
            }
            .onChange(of: state.refocus?.id) {
                guard let refocus = state.refocus else { return }
                // The first season that takes a press (a labelled one has no box).
                let rows: [SeerrSeasonRow] = if case .form(let form) = onEnum(of: state.body) { form.seasons?.rows ?? [] } else { [] }
                let open = rows.firstIndex { $0.blockedLabel == nil } ?? 0
                focus = refocus.target == .submit ? "seerrRequest.submit" : "season.\(open)"
            }
        } else {
            Color.clear.onAppear { _ = app.navigator.pop(route: route) }
        }
    }

    /// The first section's rows while there is no form: the spinner, the failure with Retry, or nothing to request; the
    /// form's own rows follow in their sections (`RequestForm`), and here its error.
    @ViewBuilder
    private func content(_ body: SeerrRequestBody, store: SeerrRequestStore) -> some View {
        switch onEnum(of: body) {
        case .loading:
            ProgressView().frame(maxWidth: .infinity).padding(.vertical, 12)
        case .loadFailed(let failed):
            ErrorLine(text: failed.message)
            Button(failed.retryLabel, action: store.retry)
                .focused($focus, equals: "retry")
                .accessibilityIdentifier("seerrRequest.retry")
                .task { focus = "retry" }
        case .nothingToRequest(let nothing):
            Label {
                Text(nothing.message)
            } icon: {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(Palette.primary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("seerrRequest.nothing")
            #if os(tvOS)
            .focusable()
            #endif
        case .form(let form):
            if let error = form.error {
                ErrorLine(text: error).accessibilityIdentifier("seerrRequest.error")
            }
        }
    }
}

/// The request form's sections, every control disabled while a request is on its way: the seasons, Request in 4K and
/// Advanced.
private struct RequestForm: View {
    let form: SeerrRequestBodyForm
    let store: SeerrRequestStore
    var focus: FocusState<String?>.Binding

    var body: some View {
        Group {
            if let seasons = form.seasons {
                Section(seasons.heading) {
                    Toggle(seasons.allLabel, isOn: Binding(get: { seasons.allSelected }, set: { store.setAllSeasons(selected: $0) }))
                        .accessibilityIdentifier("seerrRequest.allSeasons")
                    ForEach(Array(seasons.rows.enumerated()), id: \.element.seasonNumber) { index, row in
                        // A season Seerr has or is processing shows that state in its box's place and takes no press.
                        if let blocked = row.blockedLabel {
                            HStack(spacing: 8) {
                                SettingsRowText(title: row.title, subtitle: row.subtitle)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                // Strong: the tonal fill is the raised form row's own grey on iPad and the Mac.
                                BadgeView(text: blocked, emphasis: .strong)
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityIdentifier("seerrRequest.season.\(row.seasonNumber)")
                        } else {
                            Toggle(isOn: Binding(get: { row.checked }, set: { store.setSeasonSelected(seasonNumber: row.seasonNumber, selected: $0) })) {
                                SettingsRowText(title: row.title, subtitle: row.subtitle)
                            }
                            .disabled(!row.enabled)
                            .focused(focus, equals: "season.\(index)")
                            .accessibilityIdentifier("seerrRequest.season.\(row.seasonNumber)")
                        }
                    }
                }
            }
            if let request4k = form.request4k {
                Section {
                    Toggle(isOn: Binding(get: { request4k.boolValue }, set: { store.set4k(on: $0) })) {
                        Label(form.request4kLabel, systemImage: "4k.tv")
                    }
                    .accessibilityIdentifier("seerrRequest.4k")
                }
            }
            if let advanced = form.advanced {
                AdvancedSection(advanced: advanced, store: store)
            }
        }
        .disabled(form.submitting)
    }
}

/// "Advanced": its heading (with a small spinner while the chosen server's options load), a picker per destination
/// (`SettingsChoicePicker`: a menu, on Apple TV a list), the tags as a row that shows a switch per tag under it, and the
/// anime note under the section.
private struct AdvancedSection: View {
    let advanced: SeerrAdvancedSection
    let store: SeerrRequestStore

    var body: some View {
        Section {
            ForEach(advanced.pickers, id: \.kind) { picker in
                SettingsChoicePicker(
                    row: SettingChoiceRow(
                        id: picker.kind.name, title: picker.label, caption: nil,
                        options: picker.options.map { SettingChoiceOption(id: String($0.id), label: $0.label, selected: $0.selected, subtitle: nil) },
                        unselectedLabel: picker.value, enabled: true, icon: nil
                    ),
                    id: "seerrRequest.picker.\(picker.kind.name.lowercased())",
                    valueBeside: true
                ) { option in
                    if let id = Int32(option) { store.select(kind: picker.kind, optionId: id) }
                }
            }
            if let tags = advanced.tags {
                SettingsLinkRow(
                    title: tags.label, subtitle: tags.summary, systemImage: "tag",
                    trailingSymbol: tags.expanded ? "chevron.up" : "chevron.down", id: "seerrRequest.tags",
                    action: store.toggleTagsExpanded
                )
                if tags.expanded {
                    ForEach(tags.options, id: \.id) { option in
                        Toggle(option.label, isOn: Binding(get: { option.selected }, set: { store.setTagSelected(tagId: option.id, selected: $0) }))
                    }
                }
            }
        } header: {
            HStack(spacing: 8) {
                Text(advanced.heading)
                if advanced.loading { ProgressView().controlSize(.small) }
            }
        } footer: {
            if let note = advanced.animeNote { Text(note) }
        }
    }
}
