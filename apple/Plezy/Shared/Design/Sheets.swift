import SwiftUI
import PlezyKit

extension View {
    /// The app's sheet, every one of them: `content` (a `SheetPage`, a settings form) while `isPresented`, sized by
    /// `size` (`SheetSize`, `sheetFrame`): on iPhone half height, pulled up to full, with the grabber and no Close; on
    /// iPad a form sheet with Close; on the Mac its kind's size; on Apple TV, whose own sheets are cards that clip a
    /// form and leave long ones below the remote's reach, a form covers the screen and the rest show in a
    /// `TrailingPanel` identified `id`. It goes through `statePresentation`: closed by the user (a swipe, Close,
    /// Escape, the remote's Menu), it stays closed while the state that holds it open follows. `onDismiss` runs once it
    /// has gone, its dismissal done.
    @ViewBuilder
    func appSheet<Content: View>(
        isPresented: Binding<Bool>,
        id: String? = nil,
        size: SheetSize = .form,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        #if os(tvOS)
        if size.coversScreen {
            statePresentation(isPresented) { base, shown in
                base.fullScreenCover(isPresented: shown, onDismiss: onDismiss) {
                    content().background(Palette.background)
                }
            }
        } else {
            trailingPanel(isPresented: isPresented, id: id ?? "sheet.panel", onDismiss: onDismiss, content: content)
        }
        #else
        statePresentation(isPresented) { base, shown in
            base.sheet(isPresented: shown, onDismiss: onDismiss) {
                content().sheetFrame(size)
            }
        }
        #endif
    }

    /// `appSheet(isPresented:)` of a store's state: up while `item` is set, drawn by `content`, `onDismiss` when the
    /// user closes it. Once `item` goes nil (closed, saved, cancelled) the sheet draws the last `item` it had while it
    /// animates out, not an empty sheet.
    func appSheet<Item: Equatable, Content: View>(
        item: Item?,
        id: String? = nil,
        size: SheetSize = .form,
        onDismiss: @escaping () -> Void,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        modifier(LastItemSheet(item: item, id: id, size: size, onDismiss: onDismiss, sheet: content))
    }

    /// Work behind a progress indicator while `isPresented` (a play queue loading, a deletion that takes a while):
    /// `title` over `content` in an `appSheet` of `SheetSize.progress` that no swipe or click closes, identified `id`.
    /// Where the work can stop, `cancel` sits in the bar's cancellation slot (Escape presses it; on Apple TV a button
    /// under `content`, and the remote's Menu). `onDismiss` runs once it has gone.
    func progressSheet<Content: View>(
        _ title: String?,
        isPresented: Bool,
        id: String,
        cancel: SheetAction?,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        let shown = Binding(get: { isPresented }, set: { if !$0 { cancel?.action() } })
        return appSheet(isPresented: shown, id: "\(id).panel", size: .progress, onDismiss: onDismiss) {
            NavigationStack {
                VStack(spacing: 24) {
                    content()
                    #if os(tvOS)
                    if let cancel {
                        Button(cancel.title, action: cancel.action).accessibilityIdentifier(cancel.id)
                    }
                    #endif
                }
                .padding(24)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .pageTitle(title ?? "")
                .sheetToolbar(cancel: cancel, confirm: nil)
            }
            #if os(tvOS)
            .interactiveDismissDisabled(cancel == nil)
            #else
            .interactiveDismissDisabled()
            #endif
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(id)
        }
    }
}

private struct LastItemSheet<Item: Equatable, Sheet: View>: ViewModifier {
    let item: Item?
    let id: String?
    let size: SheetSize
    let onDismiss: () -> Void
    let sheet: (Item) -> Sheet

    /// The item last shown, drawn while the sheet animates out after `item` went nil.
    @State private var shown: Item?

    func body(content: Content) -> some View {
        content
            .appSheet(isPresented: Binding(get: { item != nil }, set: { if !$0 { onDismiss() } }), id: id, size: size) {
                if let drawn = item ?? shown { sheet(drawn) }
            }
            .onChange(of: item, initial: true) { _, item in
                if let item { shown = item }
            }
    }
}

#if os(macOS)
/// A settings sheet's form as tall as its content, up to `SheetSize.formMaxHeight`, past which it scrolls (`active`:
/// macOS 15 and later, `formSetsSheetHeight`), so the sheet's buttons sit right under its last row. A Mac sheet takes
/// its content's ideal height, which a form doesn't have: at a fixed height the Install sheet's preview ended 250 pt
/// above Cancel and Install. The sheet adds its title bar to that height and lays the form out under it (macOS 26),
/// the bar in the form's safe area: the height asked for leaves the safe area out (or it showed again under the last
/// row), and the form fills the sheet, the safe area with it.
struct SheetHeightFromForm: ViewModifier {
    let active: Bool

    /// The form's content with its insets, the safe area's among them: the height that shows it all.
    @State private var height: CGFloat?
    @State private var safeArea = EdgeInsets()

    func body(content: Content) -> some View {
        if active, #available(macOS 15, *) {
            let bars = safeArea.top + safeArea.bottom
            let fit = height.map { min(($0 - bars).rounded(.up), SheetSize.formMaxHeight) }
            content
                .onScrollGeometryChange(for: CGFloat.self) { geometry in
                    geometry.contentSize.height + geometry.contentInsets.top + geometry.contentInsets.bottom
                } action: { _, contentHeight in
                    height = contentHeight
                }
                .onGeometryChange(for: EdgeInsets.self) { $0.safeAreaInsets } action: { safeArea = $0 }
                .frame(minHeight: fit, idealHeight: fit, maxHeight: fit.map { $0 + bars })
        } else {
            content
        }
    }
}
#endif

extension EnvironmentValues {
    /// Inside a sized sheet (`sheetFrame`: iOS, macOS) or a `TrailingPanel` (tvOS).
    @Entry var isInSheet = false
    /// The sheet around has the grabber (`sheetFrame`): resizable in a compact window (an iPhone), where it closes by a
    /// swipe down and shows no Close (`sheetToolbar(close:)`).
    @Entry var sheetHasGrabber = false
    #if os(macOS)
    /// Inside a settings form's sheet on macOS 15 and later (`sheetFrame`): the form sets the sheet's height
    /// (`SheetHeightFromForm`).
    @Entry var formSetsSheetHeight = false
    #endif
}

/// A modal form's actions on tvOS, whose navigation bar has no buttons: a section of buttons, the main action first
/// (focused first). iOS and macOS put the same actions in the sheet's toolbar.
struct SheetAction {
    let title: String
    let id: String
    var role: ButtonRole?
    var enabled = true
    /// Its work is under way: a spinner beside its title, which stays.
    var busy = false
    let action: () -> Void
}

/// An action's title, after a small spinner while it is `busy`.
struct SheetActionLabel: View {
    let action: SheetAction

    var body: some View {
        if action.busy {
            HStack(spacing: 6) {
                ProgressView().controlSize(.small)
                Text(action.title)
            }
        } else {
            Text(action.title)
        }
    }
}

extension View {
    /// The sheet's `cancel` and `confirm` actions: in the toolbar (iOS, macOS) or as the form's last buttons (tvOS,
    /// `SheetActionsSection`, which the form draws itself). Escape presses `cancel`, with or without focus in the
    /// sheet, unless it destroys something (a Reject); Return presses `confirm` on the Mac.
    func sheetToolbar(cancel: SheetAction?, confirm: SheetAction?) -> some View {
        #if os(tvOS)
        self
        #else
        toolbar {
            if let cancel {
                ToolbarItem(placement: .cancellationAction) {
                    Button(cancel.title, role: cancel.role, action: cancel.action)
                        .disabled(!cancel.enabled)
                        .keyboardShortcut(cancel.role == .destructive ? nil : .cancelAction)
                        .accessibilityIdentifier(cancel.id)
                }
            }
            if let confirm {
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: confirm.role, action: confirm.action) { SheetActionLabel(action: confirm) }
                        .disabled(!confirm.enabled)
                        .accessibilityIdentifier(confirm.id)
                }
            }
        }
        #endif
    }

    /// A sheet whose one action, `close`, loses nothing: `SheetCloseButton` in the bar's cancellation slot (iOS,
    /// macOS; Escape presses it, Return doesn't), none where the sheet has the grabber (`sheetHasGrabber`: an iPhone's
    /// resizable sheet, which a pull down closes). tvOS draws `close` in the form (`SheetActionsSection`).
    func sheetToolbar(close: SheetAction) -> some View {
        #if os(tvOS)
        self
        #else
        modifier(CloseToolbar(close: close))
        #endif
    }
}

#if !os(tvOS)
private struct CloseToolbar: ViewModifier {
    let close: SheetAction

    @Environment(\.sheetHasGrabber) private var grabber

    func body(content: Content) -> some View {
        content.toolbar {
            if !grabber {
                ToolbarItem(placement: .cancellationAction) {
                    SheetCloseButton(title: close.title, id: close.id, action: close.action)
                }
            }
        }
    }
}
#endif

/// tvOS: a sheet's actions as the form's buttons, the main action first; elsewhere nothing (they are in the toolbar).
/// With `focus`, each button is that focus state's element named by its action's id.
struct SheetActionsSection: View {
    let actions: [SheetAction]
    var focus: FocusState<String?>.Binding?

    var body: some View {
        #if os(tvOS)
        if !actions.isEmpty {
            Section {
                ForEach(Array(actions.enumerated()), id: \.offset) { _, action in
                    let button = Button(role: action.role, action: action.action) { Text(action.title).destructiveLabel(action.role == .destructive) }
                        .disabled(!action.enabled)
                        .accessibilityIdentifier(action.id)
                    if let focus {
                        button.focused(focus, equals: action.id)
                    } else {
                        button
                    }
                }
            }
        }
        #endif
    }
}

/// A sheet's page, every sheet's: `content` under the bar's `title` (inline; with `titleInContent` the content heads
/// itself and the bar shows none, `pageTitle(_:inContent:)`), Back in the bar where the sheet has a
/// page to go back to (`onBack`; the remote's Menu and Escape too), and its actions: `close` alone where nothing is lost
/// (`sheetToolbar(close:)`; none on iPhone, whose sheet a swipe closes; on Apple TV the remote's Menu), or `cancel` and
/// `confirm` (`sheetToolbar(cancel:confirm:)`; on Apple TV the form draws them, `SheetActionsSection`). `id` identifies
/// the content to accessibility, a container of its own inside the navigation stack: set on the stack, the Mac's sheet
/// drops it and Apple TV's panel replaces it with its own.
struct SheetPage<Content: View>: View {
    var id: String?
    let title: String
    var titleInContent = false
    var onBack: (() -> Void)?
    private let close: SheetAction?
    private let cancel: SheetAction?
    private let confirm: SheetAction?
    @ViewBuilder let content: () -> Content

    init(
        id: String? = nil,
        title: String,
        titleInContent: Bool = false,
        onBack: (() -> Void)? = nil,
        close: SheetAction,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.id = id
        self.title = title
        self.titleInContent = titleInContent
        self.onBack = onBack
        self.close = close
        cancel = nil
        confirm = nil
        self.content = content
    }

    init(id: String? = nil, title: String, cancel: SheetAction?, confirm: SheetAction?, @ViewBuilder content: @escaping () -> Content) {
        self.id = id
        self.title = title
        onBack = nil
        close = nil
        self.cancel = cancel
        self.confirm = confirm
        self.content = content
    }

    var body: some View {
        NavigationStack {
            Group {
                if let id {
                    content().accessibilityElement(children: .contain).accessibilityIdentifier(id)
                } else {
                    content()
                }
            }
            .pageTitle(title, inContent: titleInContent)
            #if !os(tvOS)
            .toolbar {
                if let onBack {
                    ToolbarItem(placement: .navigation) {
                        Button(T.shared.nav.back, systemImage: "chevron.backward", action: onBack)
                            .accessibilityIdentifier("sheet.back")
                    }
                }
            }
            #endif
            .modifier(SheetPageActions(close: close, cancel: cancel, confirm: confirm))
            .backAction(onBack)
        }
    }
}

private struct SheetPageActions: ViewModifier {
    let close: SheetAction?
    let cancel: SheetAction?
    let confirm: SheetAction?

    func body(content: Content) -> some View {
        if let close {
            content.sheetToolbar(close: close)
        } else {
            content.sheetToolbar(cancel: cancel, confirm: confirm)
        }
    }
}

/// A sheet's kind (`appSheet`, `sheetFrame`): on iOS the heights it takes (`PhoneSheetFrame`); on the Mac the least size
/// and the size it opens at (a Mac sheet takes its content's ideal size, which a form or a list doesn't have, and would
/// start small), but for a settings form's height on macOS 15 and later, which its form sets (`SheetHeightFromForm`);
/// on Apple TV whether it covers the screen (a form) or shows in a `TrailingPanel`.
enum SheetSize {
    /// A settings form (its fields, its choices, Cancel and Save): resizable.
    case form
    /// A form that must show whole (a code and its QR code, the app icons, the theme editor): full height.
    case fullHeightForm
    /// Choices or facts (a picker, a file's info, a rating, a queue): resizable.
    case panel
    /// Rows that may be few (the player's chapters and queue): a `panel`, but on the Mac as tall as its list's rows up
    /// to `formMaxHeight` (macOS 15 and later, `SheetHeightFromForm`), not a fixed height with nothing under a short
    /// list. The iPad keeps the form size: a fitted form sheet takes its size once, as it presents, before the rows lay
    /// out, so it opened one row tall.
    case list
    /// Choices or facts that must show whole (a link's QR code, the PIN pad): full height.
    case fullHeightPanel
    /// Work behind a progress indicator (`progressSheet`): as tall as a title, the indicator and a line.
    case progress
    /// Over the player: the watch-together room, and on iOS the playback info: resizable.
    case player

    #if os(tvOS)
    /// A form covers the screen; the rest show in a `TrailingPanel`.
    var coversScreen: Bool { self == .form || self == .fullHeightForm }
    #elseif os(macOS)
    /// The most a settings sheet's form takes on macOS 15 and later (`SheetHeightFromForm`): the height every one
    /// opened at before, which a long form scrolls in.
    static let formMaxHeight: CGFloat = 560

    fileprivate var frame: (minWidth: CGFloat, idealWidth: CGFloat?, minHeight: CGFloat, idealHeight: CGFloat?) {
        switch self {
        case .form: (520, 560, 440, 560)
        case .fullHeightForm, .panel, .list, .fullHeightPanel: (520, 560, 480, 600)
        case .progress: (360, nil, 180, nil)
        case .player: (460, 520, 520, 640)
        }
    }

    /// Whether the sheet's form sets its height (`formSetsSheetHeight`): a settings form's on macOS 15 and later,
    /// which reads its content's height (`onScrollGeometryChange`); macOS 14 opens it at `frame`'s.
    fileprivate var formSetsHeight: Bool {
        guard self == .form || self == .list else { return false }
        if #available(macOS 15, *) { return true }
        return false
    }
    #else
    @MainActor fileprivate func detents(compact: Bool) -> Set<PresentationDetent> {
        switch self {
        case .form, .panel, .list, .player: compact ? [.medium, .large] : [.large]
        case .fullHeightForm, .fullHeightPanel: [.large]
        case .progress: [.height(220)]
        }
    }
    #endif
}

#if !os(tvOS)
extension View {
    /// The sheet at `size` (`SheetSize`), its content told it is in a sheet (`isInSheet`); on iOS for the presenting
    /// window's form factor and without the vertical bar (`verticalBarDisabled`), resizable ones in a compact window
    /// with the grabber (`sheetHasGrabber`, `PhoneSheetFrame`).
    fileprivate func sheetFrame(_ size: SheetSize) -> some View {
        #if os(macOS)
        let sizes = size.frame
        let formSetsHeight = size.formSetsHeight
        return frame(
            minWidth: sizes.minWidth,
            idealWidth: sizes.idealWidth,
            minHeight: formSetsHeight ? nil : sizes.minHeight,
            idealHeight: formSetsHeight ? nil : sizes.idealHeight
        )
        .environment(\.isInSheet, true)
        .environment(\.formSetsSheetHeight, formSetsHeight)
        #else
        return modifier(PhoneSheetFrame(size: size))
        #endif
    }
}
#endif

#if os(iOS)
/// One rule for every sheet: in a compact window (an iPhone, the iPhone Duo's cover) a resizable sheet opens
/// at half height and pulls up to full, with the grabber and no Close; in a regular one (iPad, the Duo's inner screen) a
/// form sheet with Close, a player's (`SheetSize.player`) a page sheet, whose height takes the Watch Together room's
/// rows whole down to End Room. An iPhone on its side (a compact height) shows every sheet over the whole screen,
/// with nothing to pull: Close, no grabber. The system draws the background: Liquid Glass while the sheet is partway
/// up, opaque at full height (before iOS 26 a player's sheet takes the regular material, the video showing through it).
private struct PhoneSheetFrame: ViewModifier {
    let size: SheetSize

    @Environment(\.formFactor) private var formFactor
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    func body(content: Content) -> some View {
        let compact = formFactor == .compact
        let detents = size.detents(compact: compact)
        let grabber = compact && verticalSizeClass != .compact && detents.count > 1
        content
            .verticalBarDisabled()
            .presentationDetents(detents)
            .presentationDragIndicator(grabber ? .visible : .hidden)
            .modifier(FormSheetSizing(active: !compact && size != .progress, page: size == .player))
            .modifier(PlayerSheetBackground(active: size == .player))
            .environment(\.isInSheet, true)
            .environment(\.sheetHasGrabber, grabber)
    }
}

/// A form sheet on iPad (iOS 18 and later), centred at the system's form size, or at its page size (`page`).
private struct FormSheetSizing: ViewModifier {
    let active: Bool
    let page: Bool

    func body(content: Content) -> some View {
        if active, #available(iOS 18, *) {
            if page {
                content.presentationSizing(.page)
            } else {
                content.presentationSizing(.form)
            }
        } else {
            content
        }
    }
}

/// A player sheet's background before iOS 26: the regular material, the video showing through it; from iOS 26 the
/// system's Liquid Glass sheet, as every sheet has.
private struct PlayerSheetBackground: ViewModifier {
    let active: Bool

    func body(content: Content) -> some View {
        if active {
            if #available(iOS 26, *) {
                content
            } else {
                content.presentationBackground(.regularMaterial)
            }
        } else {
            content
        }
    }
}
#endif

extension View {
    /// The remote's Back (tvOS Menu) and the Mac's Escape run `action` while this view is on screen; nil leaves them
    /// alone. iOS has neither: there Escape presses the page's or sheet's visible Back, Cancel or Close
    /// (`keyboardShortcut(.cancelAction)`), which works without focus, where a key press (`onKeyPress`) needs it.
    @ViewBuilder
    func backAction(_ action: (() -> Void)?) -> some View {
        #if os(iOS)
        self
        #else
        if let action {
            onExitCommand(perform: action)
        } else {
            self
        }
        #endif
    }
}
