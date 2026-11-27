import SwiftUI
import PlezyKit
#if os(macOS)
import AppKit
#endif

/// One entry of an item's menu: its `label` from the screen's store, the SF Symbol beside it if any (the watched
/// toggle's eye), its accessibility identifier where it needs a fixed one (else `<probe>.<index>`), whether it removes
/// something (`destructive`: the system's red), and the intent it sends; or, with a `submenu`, the entries it opens
/// instead.
struct ItemMenuEntry {
    let label: String
    var systemImage: String?
    var id: String?
    var destructive = false
    /// Whether the entry is the current choice, for an entry that is one of several choices (a version, a quality): the
    /// menu draws the system's check before it. `nil` for an entry that is no choice.
    var selected: Bool?
    /// The entries of the submenu the entry opens (its `action` then goes unused); empty for an entry that acts itself.
    var submenu: [ItemMenuEntry] = []
    let action: () -> Void
}

extension View {
    /// An item's menu (mark as watched, remove, …), as the Compose `ItemMenu` is, opened the way each platform asks
    /// for one: a long press on touch, a right click on the Mac and on an iPad with a pointer, a long press of Select
    /// on the Siri Remote. It is the system's context menu everywhere, without a heading: a `Section` heading drops the
    /// entries' accessibility identifiers. The context menu shows each entry's symbol where it has one. Picking an
    /// entry closes the menu. Entries are identified `<probe>.0`, `<probe>.1`, … as the Compose probes are
    /// (`library.menu.item.0`), unless they carry their own. A card or an episode also gives the entries to its button
    /// as VoiceOver's actions (`accessibilityActions(_:)`): a menu on a long press is found only by those who know to
    /// hold. A game controller's X opens the same entries while the item has focus (`ItemMenuTrigger`); on Apple TV a
    /// controller's held A opens the context menu as a held Select does.
    func itemMenu(entries: [ItemMenuEntry], probe: String) -> some View {
        modifier(ItemMenuTrigger(entries: entries, probe: probe))
    }

    /// `entries` as VoiceOver's actions on this element (a card's or an episode's menu, an ordered row's Move up, Move
    /// down, Remove), on every platform. Entries that act themselves: a submenu's entries aren't reached from here.
    func accessibilityActions(_ entries: [ItemMenuEntry]) -> some View {
        accessibilityActions {
            ForEach(Array(entries.enumerated()), id: \.offset) { _, entry in
                Button(entry.label, action: entry.action)
            }
        }
    }

    /// `entries` to pick one of while `isPresented`, a store's state (the menu it resolved for an item, a question's
    /// options), headed by `title` where given (what they act on): the system's action sheet (`confirmationDialog`) on
    /// iPhone, iPad and Apple TV, its menu at the pointer on the Mac (`PointerMenu`). Entries are identified as
    /// `ItemMenuEntries` does; on iOS
    /// and Apple TV a submenu's entries follow their entry's label. A pick runs its entry's action, which clears the
    /// state; closing it without one (Cancel, a tap outside, a swipe down, Escape, the remote's Menu) runs `onCancel`,
    /// once the pick, if any, has run. `identity`, where given, keeps the dialog one across changes of its entries (a
    /// menu its store updated as it learnt what to show): on the Mac they reach its menu while it is yet to show, and
    /// bring no other once it shows; elsewhere the dialog shows anew with them.
    func entriesDialog(
        _ title: String?,
        isPresented: Bool,
        entries: [ItemMenuEntry],
        probe: String,
        identity: AnyHashable? = nil,
        onCancel: @escaping () -> Void
    ) -> some View {
        modifier(EntriesDialog(title: title, isPresented: isPresented, entries: entries, probe: probe, identity: identity, onCancel: onCancel))
    }
}

/// An item's context menu (none without entries: an empty one would stand in front of the shared menu's), and the same
/// entries for a game controller's X while the item has focus (`itemMenuOpener`), which no context menu opens from code:
/// in an `entriesDialog` until a pick or a cancel. Apple TV's menus are the system's alone.
private struct ItemMenuTrigger: ViewModifier {
    let entries: [ItemMenuEntry]
    let probe: String

    @State private var open = false

    func body(content: Content) -> some View {
        if entries.isEmpty {
            content
        } else {
            #if os(tvOS)
            content.contextMenu { ItemMenuEntries(entries: entries, probe: probe) }
            #else
            content
                .contextMenu { ItemMenuEntries(entries: entries, probe: probe) }
                .entriesDialog(nil, isPresented: open, entries: closing(entries), probe: probe) { open = false }
                .itemMenuOpener { open = true }
            #endif
        }
    }

    /// `entries` whose picks close the dialog first.
    private func closing(_ entries: [ItemMenuEntry]) -> [ItemMenuEntry] {
        entries.map { entry in
            ItemMenuEntry(
                label: entry.label, systemImage: entry.systemImage, id: entry.id, destructive: entry.destructive,
                selected: entry.selected, submenu: closing(entry.submenu)
            ) {
                open = false
                entry.action()
            }
        }
    }
}

/// A ⋯ button that opens an item's menu: for items whose menu should be found without a long press or a right click.
/// `label` names it for VoiceOver (the store's "More actions"), on the Mac as its tooltip too. `probe` identifies the
/// button and, as `ItemMenuEntries` does, its entries.
struct ItemMenuButton: View {
    let label: String
    let entries: [ItemMenuEntry]
    let probe: String

    var body: some View {
        Menu {
            ItemMenuEntries(entries: entries, probe: probe)
        } label: {
            Image(systemName: "ellipsis")
                .font(.body.weight(.semibold))
                .foregroundStyle(Palette.onSurfaceVariant)
                // At least 44 pt square, larger where the symbol grows past it with the text size.
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
                .focusRing(radius: 22)
        }
        .menuStyle(.button)
        .menuIndicator(.hidden)
        .buttonStyle(PressDimButtonStyle())
        #if os(macOS)
        .tooltip(label)
        #endif
        .accessibilityLabel(label)
        .accessibilityIdentifier(probe)
    }
}

/// An `ItemMenuButton` named `label` ("More actions for <title>") built again only when `key`, what its entries
/// say and do, or `label` changes (its parent compares it: `.equatable()`). A list redraws a row on every progress
/// report of its download (the Downloads rows, Detail's episodes), and a menu built again while open dropped the tap on
/// one of its entries, the menu staying open and the action never running.
struct SteadyMenuButton: View {
    let key: [AnyHashable]
    let label: String
    let entries: [ItemMenuEntry]
    let probe: String

    var body: some View {
        ItemMenuButton(label: label, entries: entries, probe: probe)
    }
}

/// SwiftUI compares views on the main actor, where the entries' store lives.
extension SteadyMenuButton: @preconcurrency Equatable {
    static func == (lhs: SteadyMenuButton, rhs: SteadyMenuButton) -> Bool {
        lhs.key == rhs.key && lhs.label == rhs.label && lhs.probe == rhs.probe
    }
}

/// An item menu's entries, each a button or, with a submenu, a menu of its own.
struct ItemMenuEntries: View {
    let entries: [ItemMenuEntry]
    let probe: String

    var body: some View {
        ForEach(Array(entries.enumerated()), id: \.offset) { index, entry in
            let id = entry.id ?? "\(probe).\(index)"
            if entry.submenu.isEmpty, let selected = entry.selected {
                // The menu's own check, which a Mac's menu draws too (it draws no label's symbol).
                Toggle(isOn: Binding(get: { selected }, set: { _ in entry.action() })) {
                    EntryLabel(entry: entry)
                }
                .accessibilityIdentifier(id)
            } else if entry.submenu.isEmpty {
                Button(role: entry.destructive ? .destructive : nil, action: entry.action) {
                    EntryLabel(entry: entry)
                }
                .accessibilityIdentifier(id)
            } else {
                Menu {
                    ItemMenuEntries(entries: entry.submenu, probe: id)
                } label: {
                    EntryLabel(entry: entry)
                }
                .accessibilityIdentifier(id)
            }
        }
    }
}

/// An entry's words, with its symbol where it has one; a submenu that is the current choice (a version) shows the check
/// in its place, as no Toggle can open a submenu.
private struct EntryLabel: View {
    let entry: ItemMenuEntry

    var body: some View {
        if let systemImage = entry.selected == true && !entry.submenu.isEmpty ? "checkmark" : entry.systemImage {
            Label(entry.label, systemImage: systemImage)
        } else {
            Text(entry.label)
        }
    }
}

/// An entry of an `entriesDialog` as one button: a submenu's entries follow their entry's label ("Play with… · VLC").
private struct DialogRow {
    let label: String
    let id: String
    let destructive: Bool
    let selected: Bool
    let action: () -> Void

    static func rows(_ entries: [ItemMenuEntry], probe: String, prefix: String? = nil) -> [DialogRow] {
        entries.enumerated().flatMap { index, entry -> [DialogRow] in
            let id = entry.id ?? "\(probe).\(index)"
            let label = prefix.map { "\($0) · \(entry.label)" } ?? entry.label
            if entry.submenu.isEmpty {
                return [DialogRow(label: label, id: id, destructive: entry.destructive, selected: entry.selected == true, action: entry.action)]
            }
            return rows(entry.submenu, probe: id, prefix: label)
        }
    }
}

private struct EntriesDialog: ViewModifier {
    let title: String?
    let isPresented: Bool
    let entries: [ItemMenuEntry]
    let probe: String
    let identity: AnyHashable?
    let onCancel: () -> Void

    #if os(macOS)
    /// The menu asked for last, which its own entries' changes reach while it is yet to show.
    @State private var asked = AskedMenu()
    #else
    /// The dialog is up, as the system last left it or the state put it.
    @State private var shown = false
    /// Counts the dialogs the state has put up. Each shows from the other of two presenters than the one before
    /// (`presenter`): the system drops a dialog asked of a presenter whose last one is still animating out, as the one a
    /// pick closed is when the pick brings up the next (a download's all or unwatched, then once or kept synced; a
    /// version, then its quality).
    @State private var presented = 0
    /// The dialog an entry was picked in (its `presented`): its closing is no cancel.
    @State private var picked: Int?
    #endif

    /// What the dialog shows while it is presented: a pick that brings up other entries (a menu's options, a version's
    /// qualities) shows them anew, as the system has closed the dialog it was picked in.
    private var key: String? {
        isPresented ? ([probe, title ?? ""] + entries.map(\.label)).joined(separator: "\u{0}") : nil
    }

    func body(content: Content) -> some View {
        #if os(macOS)
        content.onChange(of: key, initial: true) { _, key in
            guard key != nil else { return }
            let again = identity != nil && identity == asked.identity
            asked.identity = identity
            asked.title = title
            asked.entries = entries
            // The asked menu's own entries changed: they reach it while it is yet to show; once it shows, the system's
            // menu keeps what it shows, and nothing runs until it closes.
            if again { return }
            // Out of the update that showed it: the menu's tracking runs until it closes.
            Task { @MainActor [asked, probe, onCancel] in
                PointerMenu.show(title: asked.title, entries: asked.entries, probe: probe, onCancel: onCancel)
            }
        }
        #else
        content
            .confirmationDialog(title ?? "", isPresented: presenter(0), titleVisibility: title == nil ? .hidden : .visible) {
                rows()
            }
            .confirmationDialog(title ?? "", isPresented: presenter(1), titleVisibility: title == nil ? .hidden : .visible) {
                rows()
            }
            .onChange(of: key, initial: true) { _, key in
                if key != nil { presented += 1 }
                shown = key != nil
            }
        #endif
    }

    #if !os(macOS)
    /// The presenter of the dialogs whose `presented` has `parity`: up while it holds the dialog the state has up. Only
    /// it speaks for that dialog; the other's closing is the last dialog's, gone already.
    private func presenter(_ parity: Int) -> Binding<Bool> {
        Binding(get: { shown && presented % 2 == parity }, set: { value in
            guard presented % 2 == parity else { return }
            let wasShown = shown
            shown = value
            // Closed once: an iPad's popover reports its closing again, which would cancel what the pick brought up
            // (the item's link, which a cancel closes).
            guard !value, wasShown else { return }
            // The system closes the dialog before or after it runs the picked button's action: past both.
            let closed = presented
            Task { @MainActor in
                if picked != closed { onCancel() }
            }
        })
    }

    /// The entries' buttons, then Cancel.
    @ViewBuilder
    private func rows() -> some View {
        ForEach(DialogRow.rows(entries, probe: probe), id: \.id) { row in
            Button(row.label, role: row.destructive ? .destructive : nil) {
                picked = presented
                row.action()
            }
            .accessibilityIdentifier(row.id)
            .accessibilityAddTraits(row.selected ? .isSelected : [])
        }
        Button(T.shared.common.cancel, role: .cancel) {}
            .accessibilityIdentifier("\(probe).cancel")
    }
    #endif
}

#if os(macOS)
/// What an `EntriesDialog` last asked its menu to show, and which of its store's dialogs that is (`identity`); read as
/// the menu shows.
@MainActor
private final class AskedMenu {
    var identity: AnyHashable?
    var title: String?
    var entries: [ItemMenuEntry] = []
}

/// Where the next menu opened from code shows: the frame (in its window, SwiftUI's global space) of the item that opened
/// it from itself (VoiceOver's Show menu, a controller's X), where the user's focus is, or of the ⋯ pressed (a Detail
/// episode row's, `pullDown`); nil for the pointer (a right click). Taken by the menu that shows next.
@MainActor
enum MenuAnchor {
    static var frame: CGRect?
    /// The menu drops from the ⋯ at `frame` as the ⋯'s own pull-down menu would: without the heading naming what it
    /// acts on.
    static var pullDown = false
}

/// The system's menu at the pointer or under the item it was opened from (`MenuAnchor`), for entries a store resolved
/// after the press that asked for them.
@MainActor
private enum PointerMenu {
    /// Shows `entries` under `title` (a section heading identified `<probe>.title`, but for a ⋯'s pull-down) at the
    /// pointer, or under the item `MenuAnchor` holds, until it closes; then runs the entry picked, or `onCancel`.
    static func show(title: String?, entries: [ItemMenuEntry], probe: String, onCancel: @escaping () -> Void) {
        let anchor = MenuAnchor.frame
        let pullDown = MenuAnchor.pullDown
        MenuAnchor.frame = nil
        MenuAnchor.pullDown = false
        var picked: (() -> Void)?
        let menu = NSMenu()
        menu.autoenablesItems = false
        if let title, !pullDown {
            let heading = NSMenuItem.sectionHeader(title: title)
            heading.identifier = NSUserInterfaceItemIdentifier("\(probe).title")
            menu.addItem(heading)
        }
        add(entries, probe: probe, to: menu) { picked = $0 }
        // In the window's view, so the menu belongs to the window (accessibility finds it there).
        if let window = NSApp.keyWindow, let view = window.contentView {
            // Under the item, at its leading edge, as a native list's menu shows for VoiceOver.
            let point = anchor.map { NSPoint(x: $0.minX, y: view.isFlipped ? $0.maxY : view.bounds.height - $0.maxY) }
                ?? view.convert(window.convertPoint(fromScreen: NSEvent.mouseLocation), from: nil)
            menu.popUp(positioning: nil, at: point, in: view)
        } else {
            menu.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
        }
        if let picked { picked() } else { onCancel() }
    }

    private static func add(_ entries: [ItemMenuEntry], probe: String, to menu: NSMenu, pick: @escaping (@escaping () -> Void) -> Void) {
        for (index, entry) in entries.enumerated() {
            let id = entry.id ?? "\(probe).\(index)"
            // An entry that opens a submenu runs nothing: clicked, it opened the entry's own prompt as another menu at
            // the pointer, away from the menu, rather than its submenu beside it.
            let item = entry.submenu.isEmpty ? ActionItem(title: entry.label) { pick(entry.action) } : NSMenuItem(title: entry.label, action: nil, keyEquivalent: "")
            item.image = entry.systemImage.flatMap { NSImage(systemSymbolName: $0, accessibilityDescription: nil) }
            item.identifier = NSUserInterfaceItemIdentifier(id)
            item.state = entry.selected == true ? .on : .off
            if !entry.submenu.isEmpty {
                let submenu = NSMenu()
                add(entry.submenu, probe: id, to: submenu, pick: pick)
                item.submenu = submenu
            }
            menu.addItem(item)
        }
    }

    /// A menu item that runs a closure.
    private final class ActionItem: NSMenuItem {
        private let run: () -> Void

        init(title: String, run: @escaping () -> Void) {
            self.run = run
            super.init(title: title, action: #selector(fire), keyEquivalent: "")
            target = self
        }

        @available(*, unavailable)
        required init(coder: NSCoder) { fatalError("not from a coder") }

        @objc private func fire() { run() }
    }
}
#endif
