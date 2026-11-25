import GameController
import SwiftUI
import PlezyKit
#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// Game controllers (an Xbox, PlayStation or MFi controller's extended profile) as the app's own keys, from launch on:
/// the shared `GamepadNavigator` turns their buttons and left stick into key presses, which go on as each platform's own
/// input, so every screen's key handling applies.
///
/// - The Mac: the D-pad and the stick are the arrow keys, A is Space (Return in a text field, which it submits), X opens
///   the focused item's menu (`ItemMenuOpener`), B is Escape as the app's Back (`WindowBack`: also at Home's root, where
///   a keyboard's Escape only leaves full screen). A held 500 ms on an item with a menu opens the menu instead, and its
///   release then does nothing. The arrows reach the app's buttons and cards as a keyboard's do: with the system's
///   keyboard navigation on (System Settings → Keyboard), which AppKit reads from the system's settings alone. Nothing
///   reaches the app while another app is active; a press hides the pointer until it moves, as a key does
///   (`KeyboardPointer`).
/// - Apple TV: the focus engine moves for the D-pad, the stick, A and B itself; X opens the focused item's menu.
/// - iPhone and iPad: the focus system moves for the D-pad and the stick where the device has one (an iPad with a
///   keyboard's focus), A activates the focused control, X opens its menu, B is the app's Back.
/// - Everywhere the shoulder buttons step through the visible screen's top tabs (`gamepadTabs`), and nothing reaches
///   the app while a text field takes native input (iPhone, iPad, Apple TV) or a controller goes away holding a button.
@MainActor
final class GamepadInput {
    static let shared = GamepadInput()

    /// The screens with top tabs on screen, which the shoulder buttons step through (`gamepadTabs`).
    let tabs = TabNavigation()

    /// The focused item's menu, which X opens: the latest focused value of the app's root (`gamepadInput`).
    weak var menu: ItemMenuOpener?

    #if os(iOS)
    /// The running app's Back for B (`gamepadInput`); the Mac's is the window's (`WindowBack`).
    var back: (@MainActor () -> Void)?
    #endif

    private lazy var navigator: GamepadNavigator = GamepadNavigator(
        engineOwnsNavigation: Self.engineOwnsNavigation,
        nowMillis: { KotlinLong(value: Int64(ProcessInfo.processInfo.systemUptime * 1000)) },
        emit: { action in
            // Emitted on the main thread (the navigator's main scope).
            nonisolated(unsafe) let action = action
            MainActor.assumeIsolated { GamepadInput.shared.perform(action) }
        }
    )
    private var observers: [NSObjectProtocol] = []
    private var heldSelect: HeldSelect?

    private static var engineOwnsNavigation: Bool {
        #if os(tvOS)
        true
        #else
        false
        #endif
    }

    /// Listens for controllers, the app's activation and native text input: once, as the app starts.
    func start() {
        guard observers.isEmpty else { return }
        observe(.GCControllerDidConnect) { GamepadInput.shared.connect($0.object as? GCController) }
        observe(.GCControllerDidDisconnect) { _ in GamepadInput.shared.disconnected() }
        #if os(macOS)
        observe(NSApplication.didBecomeActiveNotification) { _ in GamepadInput.shared.navigator.windowFocused = true }
        observe(NSApplication.didResignActiveNotification) { _ in GamepadInput.shared.unfocused() }
        navigator.windowFocused = NSApp.isActive
        #else
        observe(UIApplication.didBecomeActiveNotification) { _ in GamepadInput.shared.navigator.windowFocused = true }
        observe(UIApplication.willResignActiveNotification) { _ in GamepadInput.shared.unfocused() }
        for begin in [UITextField.textDidBeginEditingNotification, UITextView.textDidBeginEditingNotification] {
            observe(begin) { _ in GamepadInput.shared.textInputBegan() }
        }
        for end in [UITextField.textDidEndEditingNotification, UITextView.textDidEndEditingNotification] {
            observe(end) { _ in GamepadInput.shared.navigator.textInputActive = false }
        }
        #endif
        for controller in GCController.controllers() { connect(controller) }
    }

    /// A button of a controller went `down` or up: the GameController handlers' entry, and a UI test's (DEBUG builds'
    /// `plezy://dev-gamepad` link), which has no controller to press.
    func button(_ button: GamepadButton, down: Bool) {
        navigator.button(button: button, down: down)
    }

    /// The left stick's position, each axis from -1 to 1, y -1 up.
    func stick(x: Float, y: Float) {
        navigator.stick(x: x, y: y)
    }

    /// A controller went away.
    func disconnected() {
        cancelHeldSelect()
        navigator.disconnected()
    }

    /// The app went inactive: a held button goes up with no press.
    private func unfocused() {
        cancelHeldSelect()
        navigator.windowFocused = false
    }

    #if !os(macOS)
    /// A text field took native input: a held button goes up with no press.
    private func textInputBegan() {
        cancelHeldSelect()
        navigator.textInputActive = true
    }
    #endif

    /// A held Select cut short (the controller gone, the app inactive, text input begun) neither opens the menu nor
    /// presses: the navigator's release that follows lifts nothing.
    private func cancelHeldSelect() {
        heldSelect?.cancel()
    }

    private func observe(_ name: Notification.Name, _ action: @escaping @MainActor @Sendable (Notification) -> Void) {
        observers.append(NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { notification in
            // Delivered on the main queue.
            nonisolated(unsafe) let notification = notification
            MainActor.assumeIsolated { action(notification) }
        })
    }

    private func connect(_ controller: GCController?) {
        // The extended profile's: the Siri Remote, a micro gamepad, is the focus engine's alone.
        guard let controller, let pad = controller.extendedGamepad else { return }
        #if os(macOS)
        controller.handlerQueue = Self.handlerQueue
        #endif
        bind(pad.dpad.up, .dpadUp)
        bind(pad.dpad.down, .dpadDown)
        bind(pad.dpad.left, .dpadLeft)
        bind(pad.dpad.right, .dpadRight)
        bind(pad.buttonA, .a)
        bind(pad.buttonB, .b)
        bind(pad.buttonX, .x)
        bind(pad.leftShoulder, .leftShoulder)
        bind(pad.rightShoulder, .rightShoulder)
        // GameController's y is 1 up.
        pad.leftThumbstick.valueChangedHandler = { _, x, y in
            Self.onMain { GamepadInput.shared.stick(x: x, y: -y) }
        }
    }

    private func bind(_ input: GCControllerButtonInput, _ button: GamepadButton) {
        nonisolated(unsafe) let button = button
        input.pressedChangedHandler = { _, _, pressed in
            Self.onMain { GamepadInput.shared.button(button, down: pressed) }
        }
    }

    #if os(macOS)
    /// The controllers' handler queue on the Mac, off the main queue: an open menu's tracking runs no main-queue work, so
    /// B would reach a menu only once it closed, then go back as well.
    private static let handlerQueue = DispatchQueue(label: "com.edde746.plezy.gamepad")

    /// `work` on the main thread in the run loop's common modes, which an open menu's tracking runs too (`WindowBack`
    /// closes it on B). Called on the handler queue.
    nonisolated static func onMain(_ work: @escaping @MainActor () -> Void) {
        nonisolated(unsafe) let work = work
        let main = CFRunLoopGetMain()
        CFRunLoopPerformBlock(main, CFRunLoopMode.commonModes.rawValue) { MainActor.assumeIsolated { work() } }
        CFRunLoopWakeUp(main)
    }
    #else
    /// `work` on the main thread: the handlers' queue, the main queue.
    nonisolated static func onMain(_ work: @escaping @MainActor () -> Void) {
        nonisolated(unsafe) let work = work
        MainActor.assumeIsolated { work() }
    }
    #endif

    private func perform(_ action: GamepadAction) {
        switch onEnum(of: action) {
        case .keyDown(let press):
            keyDown(press.key, repeating: press.`repeat`)
        case .keyUp(let release):
            keyUp(release.key)
        case .back:
            #if os(macOS)
            WindowBack.pressFromGamepad()
            #elseif os(iOS)
            back?()
            #endif
        case .tab(let tab):
            if !Self.presentationUp { _ = tabs.dispatch(next: tab.next) }
        case .nonPointerInput:
            #if os(macOS)
            KeyboardPointer.hide()
            #endif
        }
    }

    private func keyDown(_ key: InputKey, repeating: Bool) {
        switch key {
        case .menu:
            menu?.open()
        case .select:
            // A press on an item with a menu waits to see whether it is a hold, which opens the menu.
            if let menu {
                let hold = HeldSelect(menu: menu)
                heldSelect = hold
                hold.start()
            } else {
                select(down: true)
            }
        default:
            move(key, down: true, repeating: repeating)
        }
    }

    private func keyUp(_ key: InputKey) {
        switch key {
        case .menu:
            break
        case .select:
            if let hold = heldSelect {
                heldSelect = nil
                // Released before the hold opened the menu: one press.
                if hold.release() {
                    select(down: true)
                    select(down: false)
                }
            } else {
                select(down: false)
            }
        default:
            move(key, down: false, repeating: false)
        }
    }

    /// A sheet, alert or other system presentation is over the app's window: the screen under it keeps its tab.
    private static var presentationUp: Bool {
        #if os(macOS)
        guard let window = NSApp.keyWindow else { return true }
        return window.sheetParent != nil || window.attachedSheet != nil
        #else
        let windows = UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.keyWindow }
        return windows.contains { $0.rootViewController?.presentedViewController != nil }
        #endif
    }

    #if os(macOS)
    /// The key Select typed at its press, which its release lifts: Return into a text field, else Space, which presses
    /// the focused control.
    private var selectKey: MacKey = .space

    private func select(down: Bool) {
        if down { selectKey = NSApp.keyWindow?.firstResponder is NSText ? .return : .space }
        selectKey.post(down: down)
    }

    private func move(_ key: InputKey, down: Bool, repeating: Bool) {
        let mac: MacKey? = switch key {
        case .up: .up
        case .down: .down
        case .left: .left
        case .right: .right
        default: nil
        }
        // With no view the key's in the window (none focused yet), the first press focuses the window's first control,
        // as Tab does.
        if down, !repeating, let window = NSApp.keyWindow, window.firstResponder == nil || window.firstResponder === window {
            MacKey.tab.post(down: true)
            MacKey.tab.post(down: false)
            return
        }
        mac?.post(down: down, repeating: repeating)
    }
    #else
    private func select(down: Bool) {
        #if os(iOS)
        if down { FocusMover.activate() }
        #endif
    }

    private func move(_ key: InputKey, down: Bool, repeating: Bool) {
        #if os(iOS)
        if down { FocusMover.move(key) }
        #endif
    }
    #endif
}

/// A held Select on an item with a menu: 500 ms held, it opens the menu.
@MainActor
private final class HeldSelect {
    private weak var menu: ItemMenuOpener?
    private var task: Task<Void, Never>?
    /// The menu opened, or the hold was cut short: the release is no press.
    private var ended = false

    init(menu: ItemMenuOpener) {
        self.menu = menu
    }

    func start() {
        task = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(500))
            guard let self, !Task.isCancelled else { return }
            ended = true
            menu?.open()
        }
    }

    /// The release: true when it is a press's (the menu didn't open, the hold wasn't cut short).
    func release() -> Bool {
        task?.cancel()
        return !ended
    }

    /// Cut short: the menu doesn't open, and the release is no press.
    func cancel() {
        task?.cancel()
        ended = true
    }
}

/// The focused item's menu (a card's, a row's), published by the item as long as it has focus (`itemMenuOpener`), for a
/// controller's X and a held A. `open` is the item's latest.
@MainActor
final class ItemMenuOpener {
    var open: () -> Void = {}
}

private struct ItemMenuKey: FocusedValueKey {
    typealias Value = ItemMenuOpener
}

extension FocusedValues {
    /// The focused item's menu (`ItemMenuOpener`).
    var itemMenu: ItemMenuOpener? {
        get { self[ItemMenuKey.self] }
        set { self[ItemMenuKey.self] = newValue }
    }
}

extension View {
    /// Publishes `open`, this item's menu, while the item has focus, for a controller's X (`GamepadInput`); nothing while
    /// nil. `focused`, where given, says whether it has focus, as the screen's focus state reads it (a list publishing
    /// one opener for its focused row); else the item gets a focus binding of its own for it.
    func itemMenuOpener(_ open: (() -> Void)?, focused: Bool? = nil) -> some View {
        modifier(ItemMenuOpenerSource(open: open, focused: focused))
    }

    /// The running app's part of the controllers' input (`GamepadInput`): the focused item's menu, and the app's Back
    /// (on the Mac also the keyboard's, `WindowBack`). `playerShown`: the player is up, which takes its own keys.
    func gamepadInput(_ app: AppModel, playerShown: Bool) -> some View {
        modifier(GamepadInputHost(app: app, playerShown: playerShown))
    }

    /// Registers this screen's top tabs for a controller's shoulder buttons while it is on screen: a press steps to the
    /// tab before or after `selected()` in `tabs()` (read at the press) and `select`s it, stopping at the first and the
    /// last, while no sheet, alert, menu or other screen covers this one and `enabled`.
    func gamepadTabs<Tab: Equatable>(
        enabled: Bool = true, tabs: @escaping () -> [Tab], selected: @escaping () -> Tab?, select: @escaping (Tab) -> Void
    ) -> some View {
        modifier(GamepadTabs(enabled: enabled, tabs: tabs, selected: selected, select: select))
    }
}

/// The item's menu published while the item has focus alone: an item without focus publishes nothing, so a grid's cells
/// coming and going as it scrolls don't change the focused values. Whether it has focus comes from the screen where it
/// says (`focused`), else from a focus binding of the item's own.
private struct ItemMenuOpenerSource: ViewModifier {
    let open: (() -> Void)?
    let focused: Bool?

    @State private var opener = ItemMenuOpener()
    @FocusState private var ownFocus: Bool

    func body(content: Content) -> some View {
        if let open {
            opener.open = open
        }
        // Nothing published without a menu, so an item's other menu source (a card's shared menu over its own) shows.
        return Group {
            if open == nil {
                content
            } else if let focused {
                content.focusedValue(\.itemMenu, focused ? opener : nil)
            } else {
                content.focused($ownFocus).focusedValue(\.itemMenu, ownFocus ? opener : nil)
            }
        }
    }
}

private struct GamepadInputHost: ViewModifier {
    let app: AppModel
    let playerShown: Bool

    @FocusedValue(\.itemMenu) private var menu

    func body(content: Content) -> some View {
        content
            .onChange(of: menu.map { ObjectIdentifier($0) }, initial: true) {
                GamepadInput.shared.menu = menu
            }
            #if os(macOS)
            .onAppear { WindowBack.shared.action = { [app] keyboard in Self.back(app, keyboard: keyboard) } }
            // Escape on a focused SwiftUI view (a card) is its exit command, which goes no further up the responder
            // chain: the root's, where no screen, sheet or overlay took it, is WindowBack's press.
            .onExitCommand { WindowBack.shared.cancelOperation(nil) }
            .onChange(of: playerShown, initial: true) { KeyboardPointer.playerShown = playerShown }
            #elseif os(iOS)
            .onAppear { GamepadInput.shared.back = { [app] in Self.back(app) } }
            #endif
    }

    #if os(macOS)
    /// Back from the window (`WindowBack`): the shell's (a screen pops, a destination's root goes to the first
    /// destination, the first's arms the exit, then quits), but for the keyboard's Escape at the first destination's
    /// root outside a TV layout, which only takes the window out of full screen. The player takes its own Escape.
    private static func back(_ app: AppModel, keyboard: Bool) {
        if BackStackLayout.companion.of(backStack: app.backStack).screens.last is RoutePlayer { return }
        let shell = app.session.shell
        if keyboard, !app.appearance.state.tv, shell.atFirstRoot {
            if let window = NSApp.keyWindow, window.styleMask.contains(.fullScreen) { window.toggleFullScreen(nil) }
            return
        }
        if shell.back() == .exit { NSApp.terminate(nil) }
    }
    #elseif os(iOS)
    /// A controller's B: closes the sheet or cover over the app, else the shell's Back short of its root, where iPhone and
    /// iPad have no exit to arm.
    private static func back(_ app: AppModel) {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        if let root = scenes.compactMap(\.keyWindow?.rootViewController).first, let presented = root.presentedViewController {
            presented.dismiss(animated: true)
            return
        }
        let shell = app.session.shell
        if !shell.atFirstRoot { _ = shell.back() }
    }
    #endif
}

private struct GamepadTabs<Tab: Equatable>: ViewModifier {
    let enabled: Bool
    let tabs: () -> [Tab]
    let selected: () -> Tab?
    let select: (Tab) -> Void

    @State private var screen = Screen()

    /// What the shared `TabScreen` reads at a press: this view's latest.
    @MainActor
    final class Screen {
        var shown = false
        var enabled = false
        var tabs: () -> [Tab] = { [] }
        var selected: () -> Tab? = { nil }
        var select: (Tab) -> Void = { _ in }

        /// The tabs by index, as `TabNavigation` takes any screen's.
        lazy var tab = TabScreen<AnyObject>(
            tabs: { [unowned self] in tabs().indices.map { KotlinInt(value: Int32($0)) } },
            selected: { [unowned self] () -> AnyObject? in
                let list = tabs()
                return KotlinInt(value: Int32(selected().flatMap(list.firstIndex(of:)) ?? -1))
            },
            select: { [unowned self] (index: AnyObject?) in
                let list = tabs()
                if let index = (index as? KotlinInt)?.intValue, list.indices.contains(index) { select(list[index]) }
            },
            isActive: { [unowned self] in KotlinBoolean(value: shown && enabled && !Self.presenting) }
        )

        /// A sheet, alert, menu or cover is up over the window, which the screen under it doesn't see.
        private static var presenting: Bool {
            #if os(macOS)
            guard let window = NSApp.keyWindow else { return true }
            return window.attachedSheet != nil || window.sheetParent != nil
            #else
            let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            return scenes.compactMap(\.keyWindow?.rootViewController).first?.presentedViewController != nil
            #endif
        }
    }

    func body(content: Content) -> some View {
        screen.enabled = enabled
        screen.tabs = tabs
        screen.selected = selected
        screen.select = select
        return content
            .onAppear {
                screen.shown = true
                GamepadInput.shared.tabs.register(screen: screen.tab)
            }
            .onDisappear {
                screen.shown = false
                GamepadInput.shared.tabs.unregister(screen: screen.tab)
            }
    }
}

#if os(macOS)
/// A key the Mac's controller input types (`GamepadInput`), posted to the app's queue as the keyboard's are, so it goes
/// through the menus, the key window and the focused view as a typed key does.
enum MacKey {
    case up, down, left, right, space, `return`, escape, tab

    func post(down: Bool, repeating: Bool = false) {
        guard let event = event(down: down, repeating: repeating) else { return }
        NSApp.postEvent(event, atStart: false)
    }

    /// The event, with the timestamp `WindowBack` tells the controller's Escape by.
    func event(down: Bool, repeating: Bool = false, timestamp: TimeInterval = ProcessInfo.processInfo.systemUptime) -> NSEvent? {
        guard let window = NSApp.keyWindow else { return nil }
        let (code, character, arrow): (UInt16, Int, Bool) = switch self {
        case .up: (126, NSUpArrowFunctionKey, true)
        case .down: (125, NSDownArrowFunctionKey, true)
        case .left: (123, NSLeftArrowFunctionKey, true)
        case .right: (124, NSRightArrowFunctionKey, true)
        case .space: (49, 0x20, false)
        case .return: (36, 0x0D, false)
        case .escape: (53, 0x1B, false)
        case .tab: (48, 0x09, false)
        }
        let characters = UnicodeScalar(character).map { String(Character($0)) } ?? ""
        return NSEvent.keyEvent(
            with: down ? .keyDown : .keyUp,
            location: .zero,
            modifierFlags: arrow ? [.numericPad, .function] : [],
            timestamp: timestamp,
            windowNumber: window.windowNumber,
            context: nil,
            characters: characters,
            charactersIgnoringModifiers: characters,
            isARepeat: repeating,
            keyCode: code
        )
    }
}
#endif
