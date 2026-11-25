import SwiftUI
import PlezyKit

#if os(macOS) || os(tvOS)
import Combine
#endif

#if os(macOS)
import Carbon.HIToolbox
#endif

#if !os(tvOS)
/// A key of a hardware keyboard (iOS) or the Mac's, or a Playback menu item's (`PlaybackCommands.press`), to the store's
/// keymap. Whether the player used it.
@MainActor
enum PlayerKeys {
    /// A key going down, or repeating while held: a keyboard's. Escape and Backspace act as Back once they come up
    /// (`up`), the store taking their press.
    static func down(_ key: InputKey, modifiers: KeyModifiers, repeat: Bool, to store: PlayerStore) -> Bool {
        store.onInput(event: InputEventKeyDown(key: key, modifiers: modifiers, repeat: `repeat`, source: .keyboard))
    }

    static func up(_ key: InputKey, to store: PlayerStore) -> Bool {
        store.onInput(event: InputEventKeyUp(key: key))
    }

    #if os(macOS)
    /// A SwiftUI key press on the Mac (the video's, the timeline's) to the store, down, repeating and up.
    static func handle(_ press: KeyPress, to store: PlayerStore) -> Bool {
        // The key's place, for a layout of another script (`InputKey(typed:usCharacter:)`): the event being handled.
        let keyCode = NSApp.currentEvent.flatMap { $0.type == .keyDown || $0.type == .keyUp ? $0.keyCode : nil }
        guard let key = InputKey(press.key, characters: press.characters, keyCode: keyCode) else { return false }
        switch press.phase {
        case .down, .repeat:
            let modifiers = KeyModifiers(
                shift: press.modifiers.contains(.shift),
                ctrl: press.modifiers.contains(.control),
                alt: press.modifiers.contains(.option),
                meta: press.modifiers.contains(.command)
            )
            return down(key, modifiers: modifiers, repeat: press.phase == .repeat, to: store)
        case .up:
            return up(key, to: store)
        default:
            return false
        }
    }
    #endif
}
#endif

#if os(iOS)
extension PlayerUiState {
    /// A hardware keyboard's keys reach the store (`HardwareKeys`), and the Playback menu's items with them
    /// (`playbackCommands(_:)`): no menu, popover or sheet of the player is up.
    var takesKeys: Bool {
        menu == nil
    }
}

/// A hardware keyboard's keys over the video (iOS), to the store as they go down, repeat while held and come up: a
/// UIKit view that takes first responder once it is in a window and takes it back when a native menu, the player's
/// popover or its sheet goes. A native menu opening takes it away (`NativeMenuButton`): with any first responder under
/// it (this view, or SwiftUI's hosting view for SwiftUI's key presses), UIKit brings the software keyboard up with the
/// menu when no hardware keyboard is attached.
struct HardwareKeys: UIViewRepresentable {
    let store: PlayerStore
    /// No menu, popover or sheet of the player is up.
    let active: Bool

    func makeUIView(context: Context) -> KeyView {
        KeyView()
    }

    func updateUIView(_ view: KeyView, context: Context) {
        view.store = store
        view.active = active
    }

    static func dismantleUIView(_ view: KeyView, coordinator: ()) {
        view.stopRepeating()
    }

    final class KeyView: UIView {
        var store: PlayerStore?
        var active = true {
            didSet { if active, !oldValue { claim() } }
        }
        /// The keys whose press the store took, by key code: their release goes to it too.
        private var taken: [UIKeyboardHIDUsage: InputKey] = [:]
        /// The last key the store took while it is held, repeating as the keyboard's own repeat does.
        private var held: (code: UIKeyboardHIDUsage, key: InputKey, modifiers: KeyModifiers)?
        private var repeater: Timer?

        override var canBecomeFirstResponder: Bool { true }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            if window != nil { claim() } else { stopRepeating() }
        }

        /// Takes first responder once the presentation that brought the view in, or took it away, has settled: after
        /// the transition under way (the player's cover coming up), whose frames the keyboard's input views, which
        /// becoming first responder reloads, would otherwise take main-thread time from.
        private func claim() {
            DispatchQueue.main.async { [weak self] in
                guard let self, window != nil, active, !isFirstResponder else { return }
                let controllers = sequence(first: self as UIResponder, next: { $0.next }).lazy.compactMap { $0 as? UIViewController }
                if let transition = controllers.compactMap(\.transitionCoordinator).first {
                    transition.animate(alongsideTransition: nil) { [weak self] _ in
                        MainActor.assumeIsolated { self?.claim() }
                    }
                    return
                }
                becomeFirstResponder()
            }
        }

        override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
            var others = Set<UIPress>()
            for press in presses {
                guard let store, let uiKey = press.key, let key = InputKey(uiKey) else {
                    others.insert(press)
                    continue
                }
                let modifiers = KeyModifiers(
                    shift: uiKey.modifierFlags.contains(.shift),
                    ctrl: uiKey.modifierFlags.contains(.control),
                    alt: uiKey.modifierFlags.contains(.alternate),
                    meta: uiKey.modifierFlags.contains(.command)
                )
                if PlayerKeys.down(key, modifiers: modifiers, repeat: false, to: store) {
                    taken[uiKey.keyCode] = key
                    startRepeating(uiKey.keyCode, key, modifiers)
                } else {
                    others.insert(press)
                }
            }
            if !others.isEmpty { super.pressesBegan(others, with: event) }
        }

        override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
            let others = release(presses)
            if !others.isEmpty { super.pressesEnded(others, with: event) }
        }

        override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
            let others = release(presses)
            if !others.isEmpty { super.pressesCancelled(others, with: event) }
        }

        /// Sends the release of the keys the store took; returns the other presses.
        private func release(_ presses: Set<UIPress>) -> Set<UIPress> {
            var others = Set<UIPress>()
            for press in presses {
                guard let code = press.key?.keyCode, let key = taken.removeValue(forKey: code) else {
                    others.insert(press)
                    continue
                }
                if held?.code == code { stopRepeating() }
                if let store { _ = PlayerKeys.up(key, to: store) }
            }
            return others
        }

        /// Repeats a held key after half a second, ten times a second, until it comes up (UIKit reports a key's
        /// press and release only); the store drops the repeats of commands that don't repeat.
        private func startRepeating(_ code: UIKeyboardHIDUsage, _ key: InputKey, _ modifiers: KeyModifiers) {
            stopRepeating()
            held = (code, key, modifiers)
            let timer = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in
                MainActor.assumeIsolated { self?.repeatHeld() }
            }
            timer.fireDate = Date().addingTimeInterval(0.5)
            RunLoop.main.add(timer, forMode: .common)
            repeater = timer
        }

        private func repeatHeld() {
            guard let held, let store else { return }
            _ = PlayerKeys.down(held.key, modifiers: held.modifiers, repeat: true, to: store)
        }

        func stopRepeating() {
            repeater?.invalidate()
            repeater = nil
            held = nil
        }
    }
}
#endif

#if !os(tvOS)
extension InputKey {
    #if os(macOS)
    /// The shared key for a key press: arrows and editing keys by their key, the rest by the character they type
    /// without modifiers, so shortcuts follow the keyboard layout, or by their place (`keyCode`) where that character is
    /// of another script (`init(typed:usCharacter:)`). Nil for keys the keymaps don't use.
    init?(_ key: KeyEquivalent, characters: String, keyCode: UInt16?) {
        switch key {
        case .upArrow: self = .up
        case .downArrow: self = .down
        case .leftArrow: self = .left
        case .rightArrow: self = .right
        case .return: self = .select
        case .escape: self = .escape
        case .space: self = .space
        case .delete: self = .backspace
        case .tab: self = .tab
        case .home: self = .home
        case .end: self = .end
        case .pageUp: self = .pageUp
        case .pageDown: self = .pageDown
        default:
            guard let character = characters.lowercased().first ?? key.character.lowercased().first else { return nil }
            self.init(typed: character, usCharacter: keyCode.flatMap { Self.usCharacters[Int($0)] })
        }
    }

    /// What the keys the keymaps use type on a US keyboard, by the Mac's key code for their place.
    private static let usCharacters: [Int: Character] = [
        kVK_ANSI_A: "a", kVK_ANSI_B: "b", kVK_ANSI_C: "c", kVK_ANSI_D: "d", kVK_ANSI_E: "e", kVK_ANSI_F: "f",
        kVK_ANSI_G: "g", kVK_ANSI_H: "h", kVK_ANSI_I: "i", kVK_ANSI_J: "j", kVK_ANSI_K: "k", kVK_ANSI_L: "l",
        kVK_ANSI_M: "m", kVK_ANSI_N: "n", kVK_ANSI_O: "o", kVK_ANSI_P: "p", kVK_ANSI_Q: "q", kVK_ANSI_R: "r",
        kVK_ANSI_S: "s", kVK_ANSI_T: "t", kVK_ANSI_U: "u", kVK_ANSI_V: "v", kVK_ANSI_W: "w", kVK_ANSI_X: "x",
        kVK_ANSI_Y: "y", kVK_ANSI_Z: "z",
        kVK_ANSI_0: "0", kVK_ANSI_1: "1", kVK_ANSI_2: "2", kVK_ANSI_3: "3", kVK_ANSI_4: "4",
        kVK_ANSI_5: "5", kVK_ANSI_6: "6", kVK_ANSI_7: "7", kVK_ANSI_8: "8", kVK_ANSI_9: "9",
        kVK_ANSI_Minus: "-", kVK_ANSI_Equal: "=", kVK_ANSI_LeftBracket: "[", kVK_ANSI_RightBracket: "]",
        kVK_ANSI_Comma: ",", kVK_ANSI_Period: ".",
    ]
    #else
    /// The shared key for a hardware keyboard's key: arrows and editing keys by their key, the rest by the character
    /// they type without modifiers, so shortcuts follow the keyboard layout, or by their place where that character is
    /// of another script (`init(typed:usCharacter:)`). Nil for keys the keymaps don't use.
    init?(_ key: UIKey) {
        switch key.keyCode {
        case .keyboardUpArrow: self = .up
        case .keyboardDownArrow: self = .down
        case .keyboardLeftArrow: self = .left
        case .keyboardRightArrow: self = .right
        case .keyboardReturnOrEnter, .keypadEnter: self = .select
        case .keyboardEscape: self = .escape
        case .keyboardSpacebar: self = .space
        case .keyboardDeleteOrBackspace: self = .backspace
        case .keyboardTab: self = .tab
        case .keyboardHome: self = .home
        case .keyboardEnd: self = .end
        case .keyboardPageUp: self = .pageUp
        case .keyboardPageDown: self = .pageDown
        default:
            guard let character = key.charactersIgnoringModifiers.lowercased().first else { return nil }
            self.init(typed: character, usCharacter: Self.usCharacters[key.keyCode])
        }
    }

    /// What the keys the keymaps use type on a US keyboard, by their place (the HID usage, which numbers the letters A
    /// to Z and the digits 1 to 9 in order).
    private static let usCharacters: [UIKeyboardHIDUsage: Character] = {
        var characters: [UIKeyboardHIDUsage: Character] = [
            .keyboard0: "0", .keyboardHyphen: "-", .keyboardEqualSign: "=", .keyboardOpenBracket: "[",
            .keyboardCloseBracket: "]", .keyboardComma: ",", .keyboardPeriod: ".",
        ]
        for (offset, letter) in "abcdefghijklmnopqrstuvwxyz".enumerated() {
            if let usage = UIKeyboardHIDUsage(rawValue: UIKeyboardHIDUsage.keyboardA.rawValue + offset) { characters[usage] = letter }
        }
        for (offset, digit) in "123456789".enumerated() {
            if let usage = UIKeyboardHIDUsage(rawValue: UIKeyboardHIDUsage.keyboard1.rawValue + offset) { characters[usage] = digit }
        }
        return characters
    }()
    #endif

    /// The key a press typing `character` (lower case) means: the keymaps' key for that character; where it is a letter
    /// or digit of another script than Latin (a Russian, Greek or Arabic layout's), the key typing `usCharacter` in the
    /// same place on a US keyboard, so the player's keys work whatever the layout. A Latin layout keeps its own
    /// characters: `M` mutes on an AZERTY keyboard, where it sits beside L.
    init?(typed character: Character, usCharacter: Character?) {
        if let key = InputKey(typing: character) {
            self = key
        } else if character.isOfAnotherScript, let usCharacter, let key = InputKey(typing: usCharacter) {
            self = key
        } else {
            return nil
        }
    }

    /// The key that types `character` (lower case): a letter, a digit or one of the keymaps' punctuation keys.
    init?(typing character: Character) {
        switch character {
        case "a"..."z":
            guard let ascii = character.asciiValue else { return nil }
            self = InputKey.companion.letter(index: Int32(ascii - UInt8(ascii: "a")))
        case "0"..."9":
            guard let value = character.wholeNumberValue else { return nil }
            self = InputKey.companion.digit(value: Int32(value))
        case "-", "_": self = .minus
        case "=", "+": self = .plus
        case "[", "{": self = .bracketLeft
        case "]", "}": self = .bracketRight
        case ",", "<": self = .comma
        case ".", ">": self = .period
        default: return nil
        }
    }
}

private extension Character {
    /// A letter or digit of another script than Latin: Cyrillic, Greek, Arabic (its digits too), Hebrew, Thai, Hangul…
    /// Latin's are those up to the IPA extensions (U+036F) and Latin Extended Additional's (Vietnamese).
    var isOfAnotherScript: Bool {
        guard isLetter || isNumber, let scalar = unicodeScalars.first else { return false }
        return scalar.value > 0x036F && !(0x1E00...0x1EFF).contains(scalar.value)
    }
}
#endif
