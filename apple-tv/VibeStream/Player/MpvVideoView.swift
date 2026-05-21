import SwiftUI

struct MpvVideoView: UIViewRepresentable {
    let onCoreReady: (MpvPlayerCore) -> Void
    var onPlayPause: (() -> Void)?
    var onSkipBackward: (() -> Void)?
    var onSkipForward: (() -> Void)?
    var onSkipBackwardHold: (() -> Void)?
    var onSkipForwardHold: (() -> Void)?
    var onSelect: (() -> Void)?
    var onUpArrow: (() -> Void)?
    var onDownArrow: (() -> Void)?
    var onLeftArrow: (() -> Void)?
    var onRightArrow: (() -> Void)?
    var overlayActive: Bool = false
    var transportButtonsFocused: Bool = false

    func makeCoordinator() -> Coordinator {
        Coordinator(onCoreReady: onCoreReady)
    }

    func makeUIView(context: Context) -> MpvContainerView {
        let view = MpvContainerView()
        view.backgroundColor = .black
        view.coordinator = context.coordinator
        return view
    }

    func updateUIView(_ uiView: MpvContainerView, context: Context) {
        uiView.onPlayPause = onPlayPause
        uiView.onSkipBackward = onSkipBackward
        uiView.onSkipForward = onSkipForward
        uiView.onSkipBackwardHold = onSkipBackwardHold
        uiView.onSkipForwardHold = onSkipForwardHold
        uiView.onSelect = onSelect
        uiView.onUpArrow = onUpArrow
        uiView.onDownArrow = onDownArrow
        uiView.onLeftArrow = onLeftArrow
        uiView.onRightArrow = onRightArrow
        uiView.overlayActive = overlayActive
        uiView.transportButtonsFocused = transportButtonsFocused
    }

    static func dismantleUIView(_ uiView: MpvContainerView, coordinator: Coordinator) {
        coordinator.core?.dispose()
        coordinator.core = nil
    }

    class Coordinator: NSObject {
        var core: MpvPlayerCore?
        var didInitialize = false
        let onCoreReady: (MpvPlayerCore) -> Void

        init(onCoreReady: @escaping (MpvPlayerCore) -> Void) {
            self.onCoreReady = onCoreReady
        }

        func initializeIfNeeded(in view: UIView) {
            guard !didInitialize else { return }
            didInitialize = true

            let core = MpvPlayerCore()
            if core.initialize(in: view) {
                self.core = core
                onCoreReady(core)
            }
        }
    }
}

// MARK: - PlayerContainerView

/// Shared base class that handles all Siri Remote button presses and
/// touchpad swipe gestures for player views.
///
/// All remote button presses except menu are handled via `pressesBegan`.
/// The menu/back button is handled by SwiftUI's `.onExitCommand` on
/// PlayerView, which works because the player is presented via
/// `.fullScreenCover` (SwiftUI-managed presentation).
/// Touchpad swipes use gesture recognizers.
class PlayerContainerView: UIView {
    var onPlayPause: (() -> Void)?
    var onSkipBackward: (() -> Void)?
    var onSkipForward: (() -> Void)?
    var onSkipBackwardHold: (() -> Void)?
    var onSkipForwardHold: (() -> Void)?
    var onSelect: (() -> Void)?
    var onUpArrow: (() -> Void)?
    var onDownArrow: (() -> Void)?
    var onLeftArrow: (() -> Void)?
    var onRightArrow: (() -> Void)?
    var overlayActive: Bool = false
    var transportButtonsFocused: Bool = false

    private var gesturesAdded = false
    private var holdTimer: Timer?
    private var holdFired = false
    private var holdDirection: UIPress.PressType?
    private static let holdThreshold: TimeInterval = 0.5

    override var canBecomeFocused: Bool { true }

    /// Return a plain black snapshot instead of letting UIKit try to
    /// capture the CAMetalLayer content, which can crash during
    /// view controller transitions (_UIReplicantView snapshot errors).
    override func snapshotView(afterScreenUpdates afterUpdates: Bool) -> UIView? {
        let snapshot = UIView(frame: bounds)
        snapshot.backgroundColor = .black
        return snapshot
    }

    // MARK: - Press Handling

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for press in presses {
            switch press.type {
            case .playPause:
                onPlayPause?()
                return

            case .leftArrow:
                if overlayActive && transportButtonsFocused {
                    onLeftArrow?()
                } else {
                    startHoldDetection(direction: .leftArrow)
                }
                return

            case .rightArrow:
                if overlayActive && transportButtonsFocused {
                    onRightArrow?()
                } else {
                    startHoldDetection(direction: .rightArrow)
                }
                return

            case .select:
                onSelect?()
                return

            case .upArrow:
                onUpArrow?()
                return

            case .downArrow:
                onDownArrow?()
                return

            default:
                break
            }
        }
        super.pressesBegan(presses, with: event)
    }

    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for press in presses {
            if press.type == holdDirection {
                endHoldDetection(press.type)
            }
        }
        super.pressesEnded(presses, with: event)
    }

    override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        cancelHoldDetection()
        super.pressesCancelled(presses, with: event)
    }

    // MARK: - Hold Detection

    private func startHoldDetection(direction: UIPress.PressType) {
        cancelHoldDetection()
        holdDirection = direction
        holdFired = false
        holdTimer = Timer.scheduledTimer(withTimeInterval: Self.holdThreshold, repeats: false) { [weak self] _ in
            guard let self else { return }
            self.holdFired = true
            if direction == .rightArrow {
                self.onSkipForwardHold?()
            } else {
                self.onSkipBackwardHold?()
            }
        }
    }

    private func endHoldDetection(_ pressType: UIPress.PressType) {
        holdTimer?.invalidate()
        holdTimer = nil
        if !holdFired {
            // Short tap — fire the regular skip
            if pressType == .rightArrow {
                onSkipForward?()
            } else if pressType == .leftArrow {
                onSkipBackward?()
            }
        }
        holdFired = false
        holdDirection = nil
    }

    private func cancelHoldDetection() {
        holdTimer?.invalidate()
        holdTimer = nil
        holdFired = false
        holdDirection = nil
    }

    // MARK: - Swipe Gestures (touchpad)

    // 1st-gen Siri Remote (glass touchpad) fires gesture events for swipes
    // but does not synthesize directional UIPress events — only edge clicks
    // do. Without these recognizers, swiping on the touchpad can't bring up
    // controls or move between transport buttons; only the center click
    // works (which fires .select → play/pause).
    func addSwipeGesturesIfNeeded() {
        guard !gesturesAdded else { return }
        gesturesAdded = true

        let directions: [(UISwipeGestureRecognizer.Direction, Selector)] = [
            (.left,  #selector(handleSwipeLeft)),
            (.right, #selector(handleSwipeRight)),
            (.up,    #selector(handleSwipeUp)),
            (.down,  #selector(handleSwipeDown)),
        ]
        for (direction, action) in directions {
            let recognizer = UISwipeGestureRecognizer(target: self, action: action)
            recognizer.direction = direction
            addGestureRecognizer(recognizer)
        }
    }

    @objc private func handleSwipeLeft() {
        if overlayActive && transportButtonsFocused {
            onLeftArrow?()
        } else {
            onSkipBackward?()
        }
    }

    @objc private func handleSwipeRight() {
        if overlayActive && transportButtonsFocused {
            onRightArrow?()
        } else {
            onSkipForward?()
        }
    }

    @objc private func handleSwipeUp() {
        onUpArrow?()
    }

    @objc private func handleSwipeDown() {
        onDownArrow?()
    }
}

// MARK: - MpvContainerView

/// Custom UIView that handles mpv initialization and Metal layer management.
/// Remote input is inherited from PlayerContainerView.
class MpvContainerView: PlayerContainerView {
    weak var coordinator: MpvVideoView.Coordinator?

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            coordinator?.initializeIfNeeded(in: self)
            addSwipeGesturesIfNeeded()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        coordinator?.core?.updateFrame()
    }
}
