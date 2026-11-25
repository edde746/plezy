import SwiftUI
import PlezyKit

/// Plex's match search (`PlexMatchStore`): the name and year fields (Return in the name moves to the year, Return in
/// the year searches), Search, then the candidates or "No matches found".
struct PlexMatchScreen: View {
    let store: PlexMatchStore
    @State private var state: StoreObserver<PlexMatchUiState>
    @State private var name: String
    @State private var year: String
    @FocusState private var focus: Field?

    private enum Field { case name, year }

    init?(app: AppModel, route: RoutePlexMatch) {
        guard let store = app.session.metadata.match(route: route) else { return nil }
        self.store = store
        _state = State(initialValue: StoreObserver(store.state))
        _name = State(initialValue: store.state.value.name)
        _year = State(initialValue: store.state.value.year)
    }

    var body: some View {
        let state = state.state
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                TextField(state.titleHint, text: $name)
                    .focused($focus, equals: .name)
                    .onSubmit { focus = .year }
                    .accessibilityIdentifier("metadata.match.name")
                TextField(state.yearHint, text: $year)
                    .focused($focus, equals: .year)
                    #if os(iOS)
                    .keyboardType(.numberPad)
                    #endif
                    .frame(width: 140)
                    .onSubmit {
                        // The text first: the `onChange` of the last key typed can run after the submit.
                        store.setName(name: name)
                        store.setYear(year: year)
                        store.search()
                    }
                    .accessibilityIdentifier("metadata.match.year")
            }
            #if !os(tvOS)
            .textFieldStyle(.roundedBorder)
            #endif
            Button(state.searchLabel, systemImage: "magnifyingglass", action: store.search)
                .buttonProminence(.primary)
                .disabled(state.searching)
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("metadata.match.search")
            results(state)
        }
        .padding(.horizontal)
        .padding(.top)
        .pageTitle(state.title)
        .onChange(of: name) { store.setName(name: name) }
        .onChange(of: year) {
            store.setYear(year: year)
            if year != store.state.value.year { year = store.state.value.year }
        }
        .task { await self.state.observe() }
    }

    @ViewBuilder
    private func results(_ state: PlexMatchUiState) -> some View {
        if state.searching || state.results == nil {
            LoadingStateView()
        } else if let results = state.results, results.isEmpty {
            Text(state.noMatchesText)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityIdentifier("metadata.match.empty")
        } else if let results = state.results {
            List {
                ForEach(Array(results.enumerated()), id: \.offset) { index, result in
                    Button { store.apply(index: Int32(index)) } label: {
                        HStack(spacing: 16) {
                            RemoteImage(url: result.thumbUrl) { failed in
                                if failed { ArtworkPlaceholder(kind: .movie) }
                            }
                            .background(Palette.surfaceContainerHighest)
                            .frame(width: 48, height: 72)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(result.title).fontWeight(.semibold)
                                if let summary = result.summary {
                                    Text(summary).font(.subheadline).mutedForeground().lineLimit(2)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            if result.applying {
                                ProgressView()
                            } else if let score = result.score {
                                Text(score)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(Palette.surfaceContainer))
                            }
                        }
                        .foregroundStyle(.primary)
                        .contentShape(Rectangle())
                    }
                    .formRowButtonStyle()
                    .disabled(state.applyingGuid != nil)
                    .accessibilityIdentifier("metadata.match.result.\(index)")
                }
            }
            .listStyle(.plain)
        }
    }
}

/// Quick Tag of an item's menu (`MetadataEditing.open`): a blocking spinner while it loads or saves, the Label sheet
/// between; `onDone` once it is over.
struct QuickTagView: View {
    let store: QuickTagStore
    let onDone: () -> Void
    @State private var state: StoreObserver<QuickTagUiState>

    init(store: QuickTagStore, onDone: @escaping () -> Void) {
        self.store = store
        self.onDone = onDone
        _state = State(initialValue: StoreObserver(store.state))
    }

    var body: some View {
        let state = state.state
        ZStack {
            if state.busy {
                Color.black.opacity(0.3).ignoresSafeArea()
                ProgressView().largeSpinner().accessibilityIdentifier("metadata.quickTag.busy")
            }
        }
        .appSheet(item: state.tags, onDismiss: store.cancel) { tags in
            TagEditSheet(store: tags, onSave: store.save, onCancel: store.cancel)
        }
        .onChange(of: state.done) { if state.done { onDone() } }
        .task { await self.state.observe() }
    }
}
