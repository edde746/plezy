import SwiftUI

struct VLCPlayerVideoView: UIViewRepresentable {
    let onCoreReady: (VLCPlayerCore) -> Void
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

    func makeUIView(context: Context) -> VLCPlayerContainerView {
        let view = VLCPlayerContainerView()
        view.backgroundColor = .black
        view.coordinator = context.coordinator
        return view
    }

    func updateUIView(_ uiView: VLCPlayerContainerView, context: Context) {
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

    static func dismantleUIView(_ uiView: VLCPlayerContainerView, coordinator: Coordinator) {
        coordinator.core?.dispose()
        coordinator.core = nil
    }

    class Coordinator {
        var core: VLCPlayerCore?
        var didInitialize = false
        let onCoreReady: (VLCPlayerCore) -> Void

        init(onCoreReady: @escaping (VLCPlayerCore) -> Void) {
            self.onCoreReady = onCoreReady
        }

        func initializeIfNeeded(in view: UIView) {
            guard !didInitialize else { return }
            didInitialize = true
            let core = VLCPlayerCore()
            core.initialize(in: view)
            self.core = core
            onCoreReady(core)
        }
    }
}

class VLCPlayerContainerView: PlayerContainerView {
    weak var coordinator: VLCPlayerVideoView.Coordinator?

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            coordinator?.initializeIfNeeded(in: self)
            addSwipeGesturesIfNeeded()
        }
    }
}
