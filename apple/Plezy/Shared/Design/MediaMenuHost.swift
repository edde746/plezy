import SwiftUI
import PlezyKit
#if os(macOS)
import AppKit
#endif

/// Items' and playlists' menus (`MediaMenu`, `AppSession.mediaActions.menu`) mirrored for SwiftUI: the open menu, its
/// action's question or sheet, and the action's message.
@MainActor
@Observable
final class MediaMenuModel {
    let menu: MediaMenu
    private(set) var open: ItemMenu?
    /// Counts the menus opened: a menu the store updates while it is open (`MediaMenu.menu`) stays the one it was.
    private(set) var openings = 0
    private(set) var prompt: MenuPrompt?
    private(set) var message: MenuMessage?
    /// What the system menus' peeked entries offer may have changed (`MediaMenu.revision`): a view that peeks
    /// (`SystemItemMenu`) reads it, so it peeks again.
    private(set) var revision = 0

    init(_ menu: MediaMenu) {
        self.menu = menu
        open = menu.menu.value
        prompt = menu.prompt.value
        message = menu.message.value
        revision = Int(truncating: menu.revision.value)
    }

    /// Mirrors the menu, its prompt, its message and the revision of peeked menus until the calling task is cancelled.
    func observe() async {
        await withDiscardingTaskGroup { group in
            group.addTask { await self.observeMenu() }
            group.addTask { await self.observePrompt() }
            group.addTask { await self.observeMessage() }
            group.addTask { await self.observeRevision() }
        }
    }

    private func observeMenu() async {
        for await value in menu.menu {
            if open == nil, value != nil { openings += 1 }
            open = value
        }
    }

    private func observePrompt() async {
        for await value in menu.prompt { prompt = value }
    }

    private func observeMessage() async {
        for await value in menu.message { message = value }
    }

    private func observeRevision() async {
        for await value in menu.revision { revision = Int(truncating: value) }
    }

    /// `peeked`'s entries (`MediaMenu.peek`), each running through `selectPeeked` under `request` as it is picked.
    func entries(of peeked: ItemMenu, request: @escaping () -> Void) -> [ItemMenuEntry] {
        peeked.entries.map { entry in
            ItemMenuEntry(entry) { [menu] id in menu.selectPeeked(request: request, entryId: id) }
        }
    }
}

extension EnvironmentValues {
    /// The shared menus' model (`mediaMenuHost`), for the system menus that read theirs as they show (`SystemItemMenu`).
    @Entry var mediaMenu: MediaMenuModel?
}

extension View {
    /// The shared menus over the app: a menu opened from code (`entriesDialog` titled with what it acts on: a
    /// controller's X on iOS, a right click or a ⋯ button at the pointer on the Mac, a Mac episode row's ⋯ under itself;
    /// touch and Apple TV show theirs, and every platform's other Detail ⋯s, as `SystemItemMenu`s),
    /// then its action's question or sheet (`MenuPrompt`):
    /// a confirmation in the system alert, options as the menu is, a name in the alert's field, the playlist or
    /// collection picker and a file's info in an `appSheet`, work in progress in a `progressSheet`. Identifiers as the
    /// Compose host's: the menu `menu.<entry id>`, `menu.confirm.<ok|cancel>`, `menu.option.<i>`,
    /// `menu.text.<field|ok|cancel>`, `menu.picker.<create|<row id>|retry|cancel>`, `menu.fileInfo`, `menu.busy`.
    /// `presenting` false: the host only mirrors the menu while a screen covering it (iPhone's and Apple TV's Now
    /// Playing) shows the menu through its own host, which a view under a full-screen cover can't present over.
    func mediaMenuHost(_ model: MediaMenuModel, presenting: Bool = true) -> some View {
        modifier(MediaMenuHost(model: model, presenting: presenting))
    }

    /// Opens an item's shared menu (`open`, which asks its store to): a right click or a Control-click on the Mac, a
    /// game controller's X while the item has focus (`itemMenuOpener`), VoiceOver's Show menu action on the Mac and on
    /// iOS. Nothing without `open`. On touch and on Apple TV the item's menu is the system's context menu, which a long
    /// press (a held Select, a controller's held A) opens: it needs its entries as it opens, so they are read as the item
    /// shows, and again as `item` (what the menu is of, as the screen shows it) changes (`SystemItemMenu`). `opener`
    /// false: the screen publishes one opener for whichever of its items has focus (`itemMenuOpener`), so a list's
    /// rows add no focused value each: the Mac's menu bar is built again from the focused values as rows come and go.
    /// `anchor`: on the Mac, where VoiceOver's and the controller's menu opens, read as it opens; without one the item's
    /// own frame, kept as it moves.
    func mediaMenuTrigger(
        _ open: (() -> Void)?, item: AnyHashable, opener: Bool = true, anchor: (() -> CGRect?)? = nil
    ) -> some View {
        modifier(MediaMenuTrigger(open: open, item: item, opener: opener, anchor: anchor))
    }
}

private struct MediaMenuTrigger: ViewModifier {
    let open: (() -> Void)?
    let item: AnyHashable
    let opener: Bool
    let anchor: (() -> CGRect?)?

    #if os(macOS)
    /// The item's frame in its window, kept out of the view's state: it changes on every frame of a scroll.
    private final class Frame {
        var rect: CGRect?
    }

    @State private var frame = Frame()
    #endif

    func body(content: Content) -> some View {
        #if os(macOS)
        // VoiceOver's action and a controller's X open the menu under the item, where focus is; a right click at the
        // pointer.
        let anchored: (() -> Void)? = open.map { open in { [frame, anchor] in MenuAnchor.frame = anchor?() ?? frame.rect; open() } }
        let trigger = content.modifier(SecondaryClick(open: open, item: item))
            .itemMenuOpener(opener ? anchored : nil)
            .showMenuAction(anchored)
        if anchor == nil {
            trigger.onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { [frame] in frame.rect = $0 }
        } else {
            trigger
        }
        #elseif os(tvOS)
        content.modifier(SystemItemMenu(open: open, item: item, kind: .contextMenu))
        #else
        content.modifier(SystemItemMenu(open: open, item: item, kind: .contextMenu))
            .itemMenuOpener(opener ? open : nil)
            .showMenuAction(open)
        #endif
    }
}

private extension View {
    /// "Show menu" among this element's accessibility actions where `open` is given, opening the menu.
    func showMenuAction(_ open: (() -> Void)?) -> some View {
        accessibilityActions {
            if let open {
                Button(T.shared.mediaMenu.showMenu, action: open)
            }
        }
    }
}

/// An item's shared menu as a system menu: the context menu of what it modifies (a card; iOS, Apple TV), or the menu it
/// labels (a ⋯). The menu is read as the item shows (`MediaMenu.peek`, from what is at hand: no server asked), and again
/// as `item` changes or what menus offer does (`MediaMenuModel.revision`), so its entries are there as it opens. On iOS
/// its title (what it acts on) heads it (`menuContent`); destructive entries are the system's red. Focus warms what the
/// next reading should know (`MediaMenu.warm`); `warm` warms it at once. The system's menu keeps the entries it was built
/// with, so once built it is built again only as what they show changes (a label or a check, a submenu's too; a new
/// identity for what it modifies): a context menu's first entries come without one, so the item isn't made anew as it
/// shows; a menu built empty never opens, so a ⋯'s first entries take one. An entry picks under the latest `open`
/// (`MenuRequest`), so the item shown again (back from a detail) keeps its menu, and its focus. A rebuild takes focus
/// from the item, which takes it back. The system puts focus back on the item as the menu closes.
struct SystemItemMenu: ViewModifier {
    enum Kind { case contextMenu, menu }

    let open: (() -> Void)?
    let item: AnyHashable
    let kind: Kind
    var warm = false

    @Environment(\.mediaMenu) private var model
    @State private var request = MenuRequest()
    /// The entries the menu was last built with.
    @State private var built: [ItemMenuEntry] = []
    /// The title the menu was last built with.
    @State private var builtTitle: String?
    /// Builds that needed a new identity for what it modifies: its rebuilds, and a ⋯'s first build.
    @State private var rebuilds = 0
    /// Entries come while the item hasn't focus (its menu open or closing), built once it has.
    @State private var pending: (entries: [ItemMenuEntry], title: String?)?
    /// The menu is being built again while it has focus, which the rebuild takes from it.
    @State private var refocus = false
    /// A focus state of its own, beside the screen's on the same button.
    @FocusState private var focused: Bool

    /// The closing menu gives the item its focus back (Apple TV).
    #if os(tvOS)
    private static let focusReturns = true
    #else
    private static let focusReturns = false
    #endif

    func body(content: Content) -> some View {
        if let open { request.open = open }
        // Read here, not in the menu's builder: the body reads the menu again as what it offers changes.
        let peeked = open == nil ? nil : model.flatMap { request.peek($0, item: item) }
        let entries = peeked.flatMap { peeked in model?.entries(of: peeked, request: request.run) } ?? []
        let title = peeked?.title
        let looks = entries.flatMap(\.look)
        let shown = built.map { entry in
            entry.wrapped { action in
                // What the menu offers once the pick ends should know (the watchlist's membership): on touch nothing
                // has focus to warm it before.
                model?.menu.warm(request: request.run)
                action()
            }
        }
        return Group {
            switch kind {
            case .contextMenu:
                content.contextMenu { menuContent(shown) }
            case .menu:
                Menu { menuContent(shown) } label: { content }
            }
        }
        .id(rebuilds)
        .focused($focused)
        .onChange(of: looks, initial: true) { _, looks in
            guard !looks.isEmpty, looks != built.flatMap(\.look) || title != builtTitle else { return }
            // Built now while the item hasn't focus (its menu open, or the menu of a pick closing), the menu or the item
            // the closing menu gives focus back to would be gone: focus would stay on an entry or land elsewhere. Built
            // once the item has its focus back (Apple TV; on touch nothing gives focus back, so the menu is built at once).
            if Self.focusReturns, !focused, !built.isEmpty {
                pending = (entries, title)
            } else {
                rebuild(entries, title: title)
            }
        }
        .onChange(of: focused) { _, now in
            if now {
                if let pending { rebuild(pending.entries, title: pending.title) }
                if open != nil { model?.menu.warm(request: request.run) }
            } else if refocus {
                refocus = false
                focused = true
            }
        }
        .onAppear {
            if warm, open != nil { model?.menu.warm(request: request.run) }
        }
    }

    @ViewBuilder
    private func menuContent(_ entries: [ItemMenuEntry]) -> some View {
        #if os(iOS)
        if let builtTitle, !entries.isEmpty {
            // The menu's title as a disabled row. The system's own caption is a section's header, which shows only
            // over the entries inside the section, and entries inside a section lose their accessibility identifiers;
            // an empty section shows nothing.
            Button(builtTitle) {}
                .disabled(true)
                .accessibilityIdentifier("menu.title")
        }
        ItemMenuEntries(entries: entries, probe: "menu")
        #else
        ItemMenuEntries(entries: entries, probe: "menu")
        #endif
    }

    private func rebuild(_ entries: [ItemMenuEntry], title: String?) {
        refocus = focused
        pending = nil
        if !built.isEmpty || kind == .menu { rebuilds += 1 }
        built = entries
        builtTitle = title
    }
}

/// A system menu's request (`SystemItemMenu`): the latest `open`, which an entry of a menu built earlier picks under,
/// and the menu it last read, kept while neither the item nor what menus offer (`MediaMenuModel.revision`) changed.
@MainActor
final class MenuRequest {
    var open: () -> Void = {}
    private var last: (item: AnyHashable, revision: Int, menu: ItemMenu?)?

    /// The menu `open` opens, read (`MediaMenu.peek`) unless `last` still holds it. It reads the model's revision, so
    /// a view that calls it reads the menu again as the revision moves.
    func peek(_ model: MediaMenuModel, item: AnyHashable) -> ItemMenu? {
        let revision = model.revision
        if let last, last.item == item, last.revision == revision { return last.menu }
        let menu = model.menu.peek(request: run)
        last = (item, revision, menu)
        return menu
    }

    func run() {
        open()
    }
}

private struct MediaMenuHost: ViewModifier {
    let model: MediaMenuModel
    let presenting: Bool

    /// The busy sheet is up or still going. A presentation started while a sheet is being dismissed never shows (iOS
    /// drops it: Delete's question, asked as the server's answer on the permission closed the busy sheet, never came),
    /// so what follows the busy prompt waits until the sheet has gone.
    @State private var busySheet = false

    func body(content: Content) -> some View {
        let menu = model.menu
        let current = presenting ? model.prompt.map { onEnum(of: $0) } : nil
        let busy: MenuPromptBusy? = if case .busy(let busy) = current { busy } else { nil }
        let presenting = self.presenting && (busy != nil || !busySheet)
        let prompt = presenting ? current : nil
        #if os(tvOS)
        let options: MenuPromptOptions? = if case .options(let options) = prompt { options } else { nil }
        #else
        let options: MenuPromptOptions? = if case .options(let options) = prompt, sourceChoice == nil { options } else { nil }
        #endif
        let input: MenuPromptTextInput? = if case .textInput(let input) = prompt { input } else { nil }
        let panel: MenuPanel? = switch prompt {
        case .picker(let picker): .picker(picker.picker)
        case .fileInfo(let info): .fileInfo(info)
        case .link(let link): .link(link)
        default: nil
        }
        let open = presenting ? model.open : nil
        content
            .environment(\.mediaMenu, model)
            // The menu and an action's options in one dialog: the options come up as the menu goes.
            .entriesDialog(
                open?.title ?? options?.title,
                isPresented: open != nil || options != nil,
                entries: open.map { open in
                    open.entries.map { entry in ItemMenuEntry(entry) { menu.select(entryId: $0) } }
                } ?? optionEntries(options, menu: menu),
                probe: open != nil ? "menu" : "menu.option",
                identity: open != nil ? model.openings : nil,
                onCancel: { open != nil ? menu.dismiss() : menu.choose(index: nil) }
            )
            .confirmation(
                presenting ? confirmation : nil,
                onConfirm: { menu.confirm(accepted: true) },
                onCancel: { menu.confirm(accepted: false) }
            )
            .textPrompt(
                input?.title ?? "",
                isPresented: input != nil,
                message: input?.label,
                placeholder: input?.hint ?? "",
                confirmLabel: T.shared.common.save,
                id: "menu.text",
                onSubmit: { menu.submit(text: $0) },
                onCancel: { menu.submit(text: nil) }
            )
            .appSheet(item: panel, id: "menu.panel", size: panel?.size ?? .panel, onDismiss: {
                if case .picker(let picker) = panel { picker.cancel() } else { menu.closePrompt() }
            }) { panel in
                switch panel {
                case .picker(let picker): PickerSheet(picker: picker).id(ObjectIdentifier(picker))
                case .fileInfo(let info): FileInfoSheet(prompt: info, menu: menu)
                case .link(let link): LinkSheet(prompt: link, menu: menu)
                }
            }
            #if !os(tvOS)
            .watchlistChooser(
                presenting ? sourceChoice : nil,
                probe: "menu.option",
                onPick: { menu.choose(index: KotlinInt(int: Int32($0))) },
                onDismiss: { menu.choose(index: nil) }
            )
            #endif
            .progressSheet(
                busy?.title,
                isPresented: busy != nil,
                id: "menu.busy",
                cancel: busy?.cancellable == true
                    ? SheetAction(title: T.shared.common.cancel, id: "menu.busy.cancel", action: menu.closePrompt)
                    : nil,
                onDismiss: { busySheet = false }
            ) {
                // Set as the sheet shows, not as the busy prompt comes: a presentation that never showed holds nothing.
                ProgressView().largeSpinner().onAppear { busySheet = true }
            }
            .task { await model.observe() }
    }

    private func optionEntries(_ options: MenuPromptOptions?, menu: MediaMenu) -> [ItemMenuEntry] {
        let options = options?.options ?? []
        let choices = options.contains { $0.selected }
        return options.enumerated().map { index, option in
            ItemMenuEntry(
                label: option.detail.map { "\(option.label) · \($0)" } ?? option.label,
                systemImage: option.icon?.systemImage,
                id: "menu.option.\(index)",
                selected: choices ? option.selected : nil
            ) {
                menu.choose(index: KotlinInt(int: Int32(index)))
            }
        }
    }

    private var confirmation: Confirmation? {
        guard let prompt = model.prompt as? MenuPromptConfirm else { return nil }
        return Confirmation(
            title: prompt.title, message: prompt.message, confirmLabel: prompt.confirmLabel, cancelLabel: T.shared.common.cancel,
            destructive: prompt.destructive, confirmId: "menu.confirm.ok", cancelId: "menu.confirm.cancel", warning: prompt.warning
        )
    }

    #if !os(tvOS)
    /// The prompt as a watchlist source choice (every option a catalog source's, with its logo); the option's filled
    /// bookmark marks a source the item is on. Apple TV asks it as other options are.
    private var sourceChoice: [WatchlistSourceOption]? {
        guard let prompt = model.prompt as? MenuPromptOptions else { return nil }
        var choice: [WatchlistSourceOption] = []
        for option in prompt.options {
            guard let logo = option.logo else { return nil }
            choice.append(WatchlistSourceOption(logo: logo, name: option.label, member: option.icon == .bookmarkRemove, action: option.detail ?? ""))
        }
        return choice
    }
    #endif
}

/// A prompt the host shows in its `appSheet`.
private enum MenuPanel: Equatable {
    case picker(ContainerPicker)
    case fileInfo(MenuPromptFileInfo)
    case link(MenuPromptLink)

    /// The link's QR code shows whole; the rest are choices and facts.
    var size: SheetSize {
        if case .link = self { .fullHeightPanel } else { .panel }
    }
}

/// The playlist or collection picker (`ContainerPicker`): a list under its title, filtered from the search field once
/// ten or more are loaded, Create new, the rows (a smart playlist's dimmed and inert) loading the next page as the end
/// nears, then a spinner while more load, the error row that retries, or the line saying there are none. Close cancels.
private struct PickerSheet: View {
    let picker: ContainerPicker

    @State private var state: StoreObserver<PickerState>
    @State private var filter = ""

    init(picker: ContainerPicker) {
        self.picker = picker
        _state = State(initialValue: StoreObserver(picker.state))
    }

    var body: some View {
        let state = state.state
        SheetPage(id: "menu.picker", title: state.title, close: SheetAction(title: T.shared.common.cancel, id: "menu.picker.cancel", action: picker.cancel)) {
            let list = List {
                row(T.shared.common.createNew, subtitle: nil, systemImage: "plus", id: "menu.picker.create", action: picker.createNew)
                ForEach(Array(state.rows.enumerated()), id: \.element.id) { index, item in
                    row(item.title, subtitle: item.subtitle, systemImage: item.icon.systemImage, id: "menu.picker.\(item.id)") {
                        picker.pick(id: item.id)
                    }
                    .disabled(!item.enabled)
                    // Within a few rows of the end, the next page loads.
                    .onAppear { if index >= state.rows.count - 3 { picker.loadMore() } }
                }
                status(state)
            }
            if state.showFilter {
                list
                    .searchable(text: $filter, prompt: Text(state.searchHint))
                    .onChange(of: filter) { _, text in picker.filter(text: text) }
            } else {
                list
            }
        }
        .task { await self.state.observe() }
    }

    @ViewBuilder
    private func status(_ state: PickerState) -> some View {
        if let error = state.error {
            row(error, subtitle: nil, systemImage: "exclamationmark.circle", id: "menu.picker.retry", action: picker.retry)
        } else if state.loading || state.hasMore {
            ProgressView()
                .frame(maxWidth: .infinity)
                .onAppear { picker.loadMore() }
        } else if state.rows.isEmpty {
            Text(state.emptyMessage)
                .mutedForeground()
                .frame(maxWidth: .infinity)
        }
    }

    /// A row: its symbol, its title and, under it, its subtitle (the item count).
    private func row(_ title: String, subtitle: String?, systemImage: String, id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).lineLimit(1)
                    if let subtitle {
                        Text(subtitle).font(.footnote).mutedForeground().lineLimit(1)
                    }
                }
            } icon: {
                Image(systemName: systemImage)
            }
        }
        .accessibilityIdentifier(id)
    }
}

/// A file's info: a page titled "File Info" over `FileInfoContent` (every version, file and stream of the item); Close
/// closes it.
private struct FileInfoSheet: View {
    let prompt: MenuPromptFileInfo
    let menu: MediaMenu

    var body: some View {
        SheetPage(id: "menu.fileInfo", title: InterfaceLocale.shared.menuTitle(text: T.shared.fileInfo.title), close: SheetAction(title: T.shared.common.close, id: "menu.fileInfo.close", action: menu.closePrompt)) {
            FileInfoContent(info: prompt.info, title: prompt.title, probe: "menu.fileInfo")
        }
    }
}

/// Show link: the item's link (`LinkDialog`, `menu.link`) with its kind's hint and, where the account has several
/// profiles, the "Open as {profile}" switch that shows the link naming the active profile; Copy says so in the menu's
/// message.
private struct LinkSheet: View {
    let prompt: MenuPromptLink
    let menu: MediaMenu

    @State private var asProfile = false

    var body: some View {
        let profileLink = prompt.asProfile
        LinkDialog(
            link: asProfile ? profileLink?.link ?? prompt.link : prompt.link,
            hint: hint,
            id: "menu.link",
            onCopied: { menu.show(text: T.shared.deepLinks.copied, isError: false) },
            onClose: menu.closePrompt,
            toggle: profileLink.map { (label: $0.label, isOn: $asProfile) }
        )
    }

    private var hint: String {
        switch prompt.kind {
        case .show: T.shared.deepLinks.showHint
        case .episode: T.shared.deepLinks.episodeHint
        default: T.shared.deepLinks.movieHint
        }
    }
}

#if os(macOS)
/// A right click or a Control-click on the view runs `open`; every other press goes through to it. What it opens comes
/// from a store a moment later (`MediaMenu` resolves the entries after the press), and a `.contextMenu` needs its
/// entries at the click, so the press is caught (`PointerItem`) and the menu shows at the pointer. The view tells only
/// that the pointer is over it: a view of its own over every card had AppKit place and hit-test it on every frame of
/// a scroll. The pointer coming over it warms what its menu should know (`MediaMenu.warm`: the watchlist's
/// membership), as focus does elsewhere: nothing runs while the system's menu shows, so the open menu can't learn it.
private struct SecondaryClick: ViewModifier {
    let open: (() -> Void)?
    let item: AnyHashable

    @Environment(\.mediaMenu) private var model

    func body(content: Content) -> some View {
        if let open {
            content
                .onHover { inside in
                    PointerItem.shared.hover(inside, item: item, open: open)
                    if inside { model?.menu.warm(request: open) }
                }
                .onDisappear { PointerItem.shared.hover(false, item: item, open: open) }
        } else {
            content
        }
    }
}

/// The item under the pointer (`SecondaryClick`) and the app's one monitor of presses: a right click or a Control-click
/// while an item is under the pointer runs its `open` and goes no further, so the item's own click doesn't run.
@MainActor
private final class PointerItem {
    static let shared = PointerItem()

    private var hovered: (item: AnyHashable, open: () -> Void)?
    private var monitor: Any?

    private init() {
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.rightMouseDown, .leftMouseDown]) { event in
            // On the main thread, before the event goes to its window.
            nonisolated(unsafe) let event = event
            return MainActor.assumeIsolated { PointerItem.shared.press(event) } ? nil : event
        }
    }

    /// The pointer came over `item` (`inside`) or left it; leaving an item it isn't over changes nothing.
    func hover(_ inside: Bool, item: AnyHashable, open: @escaping () -> Void) {
        if inside {
            hovered = (item, open)
        } else if hovered?.item == item {
            hovered = nil
        }
    }

    /// Opens the hovered item's menu for a secondary press, which it then takes. A press in a sheet, or in a window a
    /// sheet covers, isn't the item's.
    private func press(_ event: NSEvent) -> Bool {
        guard let hovered, let window = event.window, !window.isSheet, window.attachedSheet == nil else { return false }
        let secondary = event.type == .rightMouseDown || event.modifierFlags.contains(.control)
        if secondary {
            MenuAnchor.frame = nil
            hovered.open()
        }
        return secondary
    }
}
#endif

extension MenuIcon {
    /// The SF Symbol each menu entry's icon is drawn with.
    var systemImage: String {
        switch self {
        case .play: "play.fill"
        case .trailer: "play.rectangle"
        case .shuffle: "shuffle"
        case .replay: "arrow.counterclockwise"
        case .watched: watchedSymbol(false)
        case .unwatched: watchedSymbol(true)
        case .close: "xmark"
        case .info: "info.circle"
        case .star: "star.fill"
        case .edit: "pencil"
        case .label: "tag.fill"
        case .search: "magnifyingglass"
        case .linkOff: "nosign"
        case .remove: "minus"
        case .tv: "tv"
        case .link: "link"
        case .videoFile: "doc.fill"
        case .openInNew: "arrow.up.forward.square"
        case .download: "arrow.down.circle"
        case .sync: "arrow.triangle.2.circlepath"
        case .syncDisabled: "exclamationmark.arrow.triangle.2.circlepath"
        case .delete: "trash"
        case .deleteForever: "xmark.bin.fill"
        case .bookmarkAdd: "bookmark"
        case .bookmarkRemove: "bookmark.fill"
        case .add: "plus"
        case .playlist: "list.and.film"
        case .collection: "rectangle.stack"
        case .smartPlaylist: "sparkles"
        case .playNext: "text.line.first.and.arrowtriangle.forward"
        case .queue: "text.append"
        case .instantMix: "wand.and.stars"
        case .album: "square.stack"
        case .artist: "music.mic"
        case .error: "exclamationmark.circle"
        case .timer: "timer"
        case .arrowUp: "arrow.up"
        case .arrowDown: "arrow.down"
        }
    }
}

extension ItemMenuEntry {
    /// The shared menu's `entry` (`menu.<entry id>`), with its submenu where it has one; a pick runs `select` with the
    /// id of the entry picked. `choice`: the entry is one of its submenu's choices (one of them selected), checked when
    /// it is the one in effect.
    init(_ entry: MenuEntry, select: @escaping (String) -> Void, choice: Bool = false) {
        let choices = entry.children.contains { $0.selected }
        self.init(
            label: entry.label,
            systemImage: entry.icon?.systemImage,
            id: "menu.\(entry.id)",
            destructive: entry.destructive,
            selected: choice ? entry.selected : nil,
            submenu: entry.children.map { ItemMenuEntry($0, select: select, choice: choices) }
        ) { select(entry.id) }
    }

    /// The entry and its submenu's, each running `wrap` around its action.
    func wrapped(_ wrap: @escaping (@escaping () -> Void) -> Void) -> ItemMenuEntry {
        let action = action
        return ItemMenuEntry(
            label: label, systemImage: systemImage, id: id, destructive: destructive, selected: selected,
            submenu: submenu.map { $0.wrapped(wrap) }
        ) { wrap(action) }
    }

    /// What the entry shows, its submenu's entries included: its label and whether it is checked.
    var look: [String] {
        ["\(label)\u{0}\(selected.map { $0 ? "1" : "0" } ?? "")"] + submenu.flatMap(\.look)
    }
}
