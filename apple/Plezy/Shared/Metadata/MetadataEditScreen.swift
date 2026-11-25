import SwiftUI
import PlezyKit
#if !os(tvOS)
import UniformTypeIdentifiers
#endif

/// The metadata editor (`MetadataEditStore`): Save in the toolbar (a spinner while a commit runs), the sections as
/// groups of rows, each opening its sheet. Back waits while a commit runs.
struct MetadataEditScreen: View {
    let store: MetadataEditStore
    @State private var state: StoreObserver<MetadataEditUiState>
    @FocusState private var focus: String?

    init?(app: AppModel, route: RouteMetadataEdit) {
        guard let store = app.session.metadata.editor(route: route) else { return nil }
        self.store = store
        _state = State(initialValue: StoreObserver(store.state))
    }

    var body: some View {
        let state = state.state
        content(state)
            .pageTitle(state.title)
            .navigationBarBackButtonHidden(state.committing)
            #if !os(tvOS)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    if state.committing {
                        ProgressView().accessibilityIdentifier("metadata.edit.saving")
                    } else {
                        Button(state.saveLabel, systemImage: "checkmark", action: store.save)
                            .disabled(!state.canSave)
                            .accessibilityIdentifier("metadata.edit.save")
                    }
                }
            }
            #endif
            // The first row takes focus where keys move it (a TV, a keyboard), as the screen opens.
            .task(id: state.load) {
                await FocusRestore.restore($focus, to: state.sections.first?.fields.first?.id, hold: 1.5)
            }
            .appSheet(item: state.dialog.map(DialogItem.init), onDismiss: store.dismissDialog) { item in
                EditorDialogView(store: store, dialog: item.dialog)
            }
            .task { await self.state.observe() }
    }

    @ViewBuilder
    private func content(_ state: MetadataEditUiState) -> some View {
        switch state.load {
        case .loading:
            LoadingStateView()
        case .failed:
            Text(state.failedText)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityIdentifier("metadata.edit.failed")
        default:
            Form {
                #if os(tvOS)
                // Apple TV's navigation bar has no buttons: Save leads the form.
                Section {
                    Button(state.saveLabel, systemImage: "checkmark", action: store.save)
                        .disabled(!state.canSave || state.committing)
                        .accessibilityIdentifier("metadata.edit.save")
                }
                #endif
                ForEach(state.sections, id: \.id) { section in
                    Section {
                        ForEach(section.fields, id: \.id) { field in
                            FieldRow(field: field) { store.edit(fieldId: field.id) }
                                .focused($focus, equals: field.id)
                                .disabled(state.committing)
                        }
                    } header: {
                        Text(section.title).font(.headline.bold())
                    }
                }
            }
            .settingsForm()
        }
    }
}

/// A store's dialog as a sheet's item: the same while it is the same field's.
private struct DialogItem: Equatable {
    let dialog: any EditorDialog

    static func == (lhs: DialogItem, rhs: DialogItem) -> Bool {
        lhs.dialog.fieldId == rhs.dialog.fieldId && type(of: lhs.dialog) == type(of: rhs.dialog)
    }
}

/// A field's row: its label over its value ("Not set", dimmed, without one), or an artwork's preview.
private struct FieldRow: View {
    let field: EditFieldUi
    let action: () -> Void

    var body: some View {
        if let artwork = field.artwork {
            Button(action: action) {
                HStack(spacing: 16) {
                    RemoteImage(url: artwork.imageUrl, contentMode: artwork.contain ? .fit : .fill) { _ in Palette.surfaceContainerHighest }
                        .frame(width: CGFloat(artwork.width), height: CGFloat(artwork.height))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    Text(field.label).frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "chevron.forward").mutedForeground()
                }
                .foregroundStyle(.primary)
                .contentShape(Rectangle())
            }
            .formRowButtonStyle()
            .accessibilityIdentifier("metadata.field.\(field.id)")
        } else {
            Button(action: action) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(field.label)
                        Text(field.value ?? field.notSetLabel)
                            .font(.subheadline)
                            .mutedForeground()
                            .opacity(field.value == nil ? 0.5 : 1)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "chevron.forward").mutedForeground()
                }
                .foregroundStyle(.primary)
                .contentShape(Rectangle())
            }
            .formRowButtonStyle()
            .accessibilityIdentifier("metadata.field.\(field.id)")
        }
    }
}

/// The sheet of the dialog a row opened.
private struct EditorDialogView: View {
    let store: MetadataEditStore
    let dialog: any EditorDialog

    var body: some View {
        switch onEnum(of: dialog) {
        case .text(let text):
            TextInputSheet(
                title: text.title, initial: text.value, multiline: text.multiline,
                cancelLabel: text.cancelLabel, saveLabel: text.saveLabel,
                onSave: { store.submitText(value: $0) }, onCancel: store.dismissDialog
            )
        case .date(let date):
            DateSheet(dialog: date, onSave: { y, m, d in store.submitDate(year: y, month: m, day: d) }, onCancel: store.dismissDialog)
        case .tags(let tags):
            TagEditSheet(store: tags.store, onSave: store.submitTags, onCancel: store.dismissDialog)
        case .choice(let choice):
            ChoiceSheet(dialog: choice, onChoose: { store.choose(value: $0) }, onCancel: store.dismissDialog)
        case .artwork(let artwork):
            ArtworkPickerSheet(store: artwork.store, onCancel: store.dismissDialog)
        }
    }
}

/// A text field's sheet titled `title`; Save returns what is typed (empty allowed), Return saves a single-line one.
struct TextInputSheet: View {
    let title: String
    let initial: String
    let multiline: Bool
    let cancelLabel: String
    let saveLabel: String
    var prompt: String?
    let onSave: (String) -> Void
    let onCancel: () -> Void

    @State private var text = ""

    var body: some View {
        let save = SheetAction(title: saveLabel, id: "metadata.text.save") { onSave(text) }
        let cancel = SheetAction(title: cancelLabel, id: "metadata.text.cancel", action: onCancel)
        SheetPage(title: title, cancel: cancel, confirm: save) {
            Form {
                Section {
                    Group {
                        if multiline {
                            TextField(title, text: $text, prompt: prompt.map { Text($0) }, axis: .vertical).lineLimit(3...8)
                        } else {
                            TextField(title, text: $text, prompt: prompt.map { Text($0) }).onSubmit(save.action)
                        }
                    }
                    .accessibilityIdentifier("metadata.text.field")
                    .formFieldRow()
                }
                SheetActionsSection(actions: [save, cancel])
            }
            .settingsForm()
        }
        .backAction(onCancel)
        .onAppear { text = initial }
    }
}

/// The release date's picker, 1800 to 2200, on the field's day (else today). Apple TV has no date picker: there the
/// day is typed as YYYY-MM-DD.
private struct DateSheet: View {
    let dialog: EditorDialogDate
    let onSave: (Int32, Int32, Int32) -> Void
    let onCancel: () -> Void

    @State private var date = Date()
    @State private var typed = ""

    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    var body: some View {
        let save = SheetAction(title: dialog.saveLabel, id: "metadata.date.save") {
            #if os(tvOS)
            let parts = typed.split(separator: "-").compactMap { Int32($0) }
            if parts.count == 3 { onSave(parts[0], parts[1], parts[2]) }
            #else
            let c = Self.calendar.dateComponents([.year, .month, .day], from: date)
            onSave(Int32(c.year ?? 1970), Int32(c.month ?? 1), Int32(c.day ?? 1))
            #endif
        }
        let cancel = SheetAction(title: dialog.cancelLabel, id: "metadata.date.cancel", action: onCancel)
        SheetPage(title: dialog.title, cancel: cancel, confirm: save) {
            Form {
                Section {
                    #if os(tvOS)
                    TextField(dialog.title, text: $typed, prompt: Text("YYYY-MM-DD"))
                        .accessibilityIdentifier("metadata.date.field")
                        .formFieldRow()
                    #else
                    DatePicker(dialog.title, selection: $date, in: range, displayedComponents: .date)
                        .environment(\.timeZone, TimeZone(identifier: "UTC")!)
                        .datePickerStyle(.graphical)
                        .accessibilityIdentifier("metadata.date.picker")
                    #endif
                }
                SheetActionsSection(actions: [save, cancel])
            }
            .settingsForm()
        }
        .backAction(onCancel)
        .onAppear {
            if let y = dialog.year?.intValue, let m = dialog.month?.intValue, let d = dialog.day?.intValue {
                date = Self.calendar.date(from: DateComponents(year: y, month: m, day: d)) ?? Date()
                typed = String(format: "%04d-%02d-%02d", y, m, d)
            }
        }
    }

    private var range: ClosedRange<Date> {
        Self.calendar.date(from: DateComponents(year: 1800, month: 1, day: 1))!...Self.calendar.date(from: DateComponents(year: 2200, month: 12, day: 31))!
    }
}

/// A choice's options: moving focus never picks, only a press does.
private struct ChoiceSheet: View {
    let dialog: EditorDialogChoice
    let onChoose: (String) -> Void
    let onCancel: () -> Void

    var body: some View {
        let cancel = SheetAction(title: T.shared.common.cancel, id: "metadata.choice.cancel", action: onCancel)
        SheetPage(title: dialog.title, cancel: cancel, confirm: nil) {
            Form {
                Section {
                    ForEach(Array(dialog.options.enumerated()), id: \.offset) { index, option in
                        Button { onChoose(option.value) } label: {
                            HStack {
                                Text(option.label).frame(maxWidth: .infinity, alignment: .leading)
                                if option.value == dialog.selected {
                                    Image(systemName: "checkmark").foregroundStyle(Palette.primary)
                                }
                            }
                            .foregroundStyle(.primary)
                            .contentShape(Rectangle())
                        }
                        .formRowButtonStyle()
                        .accessibilityIdentifier("metadata.choice.\(index)")
                    }
                }
                SheetActionsSection(actions: [cancel])
            }
            .settingsForm()
        }
        .backAction(onCancel)
    }
}

/// A tag list's sheet (`TagEditStore`): the "Add tag" field with its + button (Return adds too), up to 12 suggestion
/// chips, the tags (a press removes one), Cancel and Save.
struct TagEditSheet: View {
    let store: TagEditStore
    let onSave: () -> Void
    let onCancel: () -> Void

    @State private var state: StoreObserver<TagEditUiState>
    @State private var text = ""
    @FocusState private var fieldFocused: Bool
    #if os(tvOS)
    /// The focused suggestion chip: Down from the field lands on the first (the most recent), not the one under it.
    @FocusState private var chipFocus: Int?
    #endif

    init(store: TagEditStore, onSave: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.store = store
        self.onSave = onSave
        self.onCancel = onCancel
        _state = State(initialValue: StoreObserver(store.state))
    }

    var body: some View {
        let state = state.state
        let save = SheetAction(title: state.saveLabel, id: "metadata.tags.save", action: onSave)
        let cancel = SheetAction(title: state.cancelLabel, id: "metadata.tags.cancel", action: onCancel)
        SheetPage(title: state.title, cancel: cancel, confirm: save) {
            Form {
                Section {
                    HStack {
                        TextField(state.addTagLabel, text: $text)
                            .focused($fieldFocused)
                            .onAppear { fieldFocused = true }
                            #if os(tvOS)
                            .onMoveCommand { direction in
                                if direction == .down, !state.suggestions.isEmpty { chipFocus = 0 }
                            }
                            #endif
                            .onSubmit(add)
                            .accessibilityIdentifier("metadata.tags.field")
                        Button(state.addTagLabel, systemImage: "plus", action: add)
                            .labelStyle(.iconOnly)
                            .accessibilityIdentifier("metadata.tags.add")
                    }
                }
                if !state.suggestions.isEmpty {
                    Section {
                        ScrollView(.horizontal) {
                            HStack(spacing: 8) {
                                ForEach(Array(state.suggestions.enumerated()), id: \.offset) { index, suggestion in
                                    Button {
                                        _ = store.add(text: suggestion)
                                        fieldFocused = true
                                    } label: {
                                        Label(suggestion, systemImage: "plus")
                                    }
                                    .pillButtonStyle()
                                    #if os(tvOS)
                                    .focused($chipFocus, equals: index)
                                    #endif
                                    .accessibilityIdentifier("metadata.tags.chip.\(index)")
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .scrollIndicators(.hidden)
                        #if os(tvOS)
                        .focusSection()
                        .defaultFocus($chipFocus, 0, priority: .userInitiated)
                        #endif
                    }
                }
                if !state.tags.isEmpty {
                    Section {
                        ForEach(Array(state.tags.enumerated()), id: \.offset) { index, tag in
                            Button {
                                store.remove(index: Int32(index))
                                fieldFocused = true
                            } label: {
                                HStack {
                                    Text(tag).frame(maxWidth: .infinity, alignment: .leading)
                                    Image(systemName: "xmark").mutedForeground()
                                }
                                .foregroundStyle(.primary)
                                .contentShape(Rectangle())
                            }
                            .formRowButtonStyle()
                            .accessibilityIdentifier("metadata.tags.tag.\(index)")
                        }
                    }
                }
                SheetActionsSection(actions: [save, cancel])
            }
            .settingsForm()
        }
        .backAction(onCancel)
        .onChange(of: text) { store.setQuery(query: text) }
        .task { await self.state.observe() }
    }

    private func add() {
        if store.add(text: text) { text = "" }
        fieldFocused = true
    }
}

/// An artwork field's picker (`ArtworkPickerStore`): the candidates in a grid, the current one checked; From URL,
/// Upload File (not on Apple TV, which has no file dialogs) and Cancel. While one applies a spinner shows and nothing
/// else takes a press.
private struct ArtworkPickerSheet: View {
    let store: ArtworkPickerStore
    let onCancel: () -> Void

    @State private var state: StoreObserver<ArtworkPickerUiState>
    @State private var fromUrl = false
    @State private var importing = false

    init(store: ArtworkPickerStore, onCancel: @escaping () -> Void) {
        self.store = store
        self.onCancel = onCancel
        _state = State(initialValue: StoreObserver(store.state))
    }

    var body: some View {
        let state = state.state
        let cancel = SheetAction(title: state.cancelLabel, id: "metadata.artwork.cancel", enabled: !state.applying, action: onCancel)
        SheetPage(title: state.title, cancel: cancel, confirm: nil) {
            Group {
                if state.loading {
                    LoadingStateView()
                } else if state.tiles.isEmpty {
                    Text(state.emptyText)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .accessibilityIdentifier("metadata.artwork.empty")
                } else {
                    ScrollView {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: Int(state.columns)), spacing: 8) {
                            ForEach(Array(state.tiles.enumerated()), id: \.offset) { index, tile in
                                ArtworkTile(tile: tile, aspectRatio: state.aspectRatio, contain: state.contain) {
                                    store.select(index: Int32(index))
                                }
                                .disabled(state.applying)
                                .accessibilityIdentifier("metadata.artwork.tile.\(index)")
                            }
                        }
                        .padding()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 16) {
                    if state.applying { ProgressView().accessibilityIdentifier("metadata.artwork.applying") }
                    Spacer()
                    Button(state.fromUrlLabel, systemImage: "link") { fromUrl = true }
                        .accessibilityIdentifier("metadata.artwork.url")
                    #if !os(tvOS)
                    Button(state.uploadLabel, systemImage: "square.and.arrow.up") { importing = true }
                        .accessibilityIdentifier("metadata.artwork.upload")
                    #endif
                    #if os(tvOS)
                    Button(cancel.title, action: cancel.action).accessibilityIdentifier(cancel.id)
                    #endif
                }
                .disabled(state.applying)
                .padding()
            }
        }
        .backAction(state.applying ? nil : onCancel)
        .interactiveDismissDisabled(state.applying)
        .appSheet(isPresented: $fromUrl) {
            TextInputSheet(
                title: state.fromUrlLabel, initial: "", multiline: false, cancelLabel: state.cancelLabel,
                saveLabel: T.shared.common.save, prompt: state.imageUrlHint,
                onSave: { url in
                    fromUrl = false
                    store.applyUrl(url: url)
                },
                onCancel: { fromUrl = false }
            )
        }
        #if !os(tvOS)
        .fileImporter(isPresented: $importing, allowedContentTypes: [.image]) { result in
            guard case .success(let url) = result else { return }
            Task {
                guard let data = await importedData(url) else { return }
                store.upload(bytes: data.kotlinBytes, fileName: url.lastPathComponent)
            }
        }
        #endif
        .task { await self.state.observe() }
    }
}

/// A candidate: its image at the grid's aspect ratio, 8 pt corners, a check on the current one.
private struct ArtworkTile: View {
    let tile: ArtworkTileUi
    let aspectRatio: Double
    let contain: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            RemoteImage(url: tile.imageUrl, contentMode: contain ? .fit : .fill) { _ in Palette.surfaceContainerHighest }
                .aspectRatio(CGFloat(aspectRatio), contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(alignment: .bottomTrailing) { check }
        }
        .cardButtonStyle()
        .accessibilityLabel(tile.label)
    }

    @ViewBuilder
    private var check: some View {
        if tile.selected {
            Image(systemName: "checkmark")
                .font(.caption.bold())
                .foregroundStyle(Palette.onPrimary)
                .padding(4)
                .background(Circle().fill(Palette.primary))
                .padding(6)
        }
    }
}

extension Data {
    /// These bytes as a Kotlin `ByteArray`.
    var kotlinBytes: KotlinByteArray {
        let array = KotlinByteArray(size: Int32(count))
        for (index, byte) in enumerated() {
            array.set(index: Int32(index), value: Int8(bitPattern: byte))
        }
        return array
    }
}
