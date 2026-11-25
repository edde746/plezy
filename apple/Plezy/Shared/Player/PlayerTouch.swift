#if os(iOS)
import PlezyKit
import SwiftUI
import UIKit

/// The fingers on the video of an iPhone or iPad, forwarded to the store as they are (`InputEventTouch`: in points from
/// the view's top-left, with its size); the store tells taps, double taps, holds, two-finger taps, pinches and edge
/// swipes apart. A trackpad's or mouse's click, or the Pencil's, is a click (`InputEventClick`) as it lifts where it
/// went down, and the pointer moving over the video brings the controls up (`InputEventPointerMove`). A finger, or a
/// pointer's press, that goes down in `holdArea` (the locked screen's unlock button, in window coordinates; `.null`:
/// none) is `PlayerCommand.UnlockHold` right after the finger's down reaches the store, until it lifts or is cancelled
/// (a pointer's press there is no click).
struct PlayerTouchSurface: UIViewRepresentable {
    let store: PlayerStore
    var holdArea = CGRect.null

    func makeUIView(context: Context) -> PlayerTouchView { PlayerTouchView() }

    func updateUIView(_ view: PlayerTouchView, context: Context) {
        view.store = store
        view.holdArea = holdArea
    }

    static func dismantleUIView(_ view: PlayerTouchView, coordinator: ()) {
        view.cancelAll()
    }
}

/// The view under `PlayerTouchSurface`: every touch on it, several fingers at once.
final class PlayerTouchView: UIView {
    weak var store: PlayerStore?
    var holdArea = CGRect.null

    /// The fingers down: the store's pointer for each, where it went down (window coordinates), and whether it holds
    /// the unlock button (`holdArea`).
    private var fingers: [ObjectIdentifier: (pointer: Int64, down: CGPoint, holding: Bool)] = [:]
    private var lastPointer: Int64 = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        isMultipleTouchEnabled = true
        backgroundColor = .clear
        addGestureRecognizer(UIHoverGestureRecognizer(target: self, action: #selector(hover(_:))))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            lastPointer += 1
            let down = touch.location(in: nil)
            let holding = holdArea.contains(down)
            fingers[ObjectIdentifier(touch)] = (lastPointer, down, holding)
            if touch.type == .direct { send(.down, touch, pointer: lastPointer) }
            if holding { hold(true) }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches where touch.type == .direct {
            guard let finger = fingers[ObjectIdentifier(touch)] else { continue }
            send(.move, touch, pointer: finger.pointer)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            guard let finger = fingers.removeValue(forKey: ObjectIdentifier(touch)) else { continue }
            let up = touch.location(in: nil)
            if touch.type == .direct {
                send(.up, touch, pointer: finger.pointer)
            } else if !finger.holding, hypot(up.x - finger.down.x, up.y - finger.down.y) <= Self.clickSlop, bounds.width > 0 {
                let x = Float(min(max(touch.location(in: self).x / bounds.width, 0), 1))
                _ = store?.onInput(event: InputEventClick(x: x, clickCount: 1))
            }
            if finger.holding { hold(false) }
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            guard let finger = fingers.removeValue(forKey: ObjectIdentifier(touch)) else { continue }
            if touch.type == .direct { send(.cancel, touch, pointer: finger.pointer) }
            if finger.holding { hold(false) }
        }
    }

    /// The view went away under fingers still down: they count for nothing.
    func cancelAll() {
        for finger in fingers.values {
            let at = convert(finger.down, from: nil)
            _ = store?.onInput(event: event(.cancel, pointer: finger.pointer, at: at))
            if finger.holding { hold(false) }
        }
        fingers.removeAll()
    }

    private func hold(_ held: Bool) {
        store?.dispatch(command: PlayerCommandUnlockHold(held: held))
    }

    private func send(_ phase: TouchPhase, _ touch: UITouch, pointer: Int64) {
        _ = store?.onInput(event: event(phase, pointer: pointer, at: touch.location(in: self)))
    }

    private func event(_ phase: TouchPhase, pointer: Int64, at: CGPoint) -> InputEventTouch {
        InputEventTouch(
            phase: phase,
            pointer: pointer,
            x: Float(at.x),
            y: Float(at.y),
            width: Float(bounds.width),
            height: Float(bounds.height)
        )
    }

    @objc private func hover(_ recognizer: UIHoverGestureRecognizer) {
        if recognizer.state == .began || recognizer.state == .changed {
            _ = store?.onInput(event: InputEventPointerMove.shared)
        }
    }

    /// How far a click may move between its press and its release: UIKit's tap slop.
    private static let clickSlop: CGFloat = 10
}
#endif
