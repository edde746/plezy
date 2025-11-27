import Cocoa

/// Protocol for receiving player events
protocol MpvPlayerDelegate: AnyObject {
    func onPropertyChange(name: String, value: Any?)
    func onEvent(name: String, data: [String: Any]?)
}

/// Simplified core - just a colored layer for debugging visibility
class MpvPlayerCore: NSObject {

    // MARK: - Properties

    private var debugLayer: CALayer?
    private weak var window: NSWindow?

    weak var delegate: MpvPlayerDelegate?

    private(set) var isInitialized = false

    // MARK: - Initialization

    /// Initialize with a simple colored layer (no MPV for now)
    func initialize(in window: NSWindow) -> Bool {
        guard !isInitialized else {
            print("[MpvPlayerCore] Already initialized")
            return true
        }

        guard let contentView = window.contentView else {
            print("[MpvPlayerCore] No content view")
            return false
        }

        self.window = window

        // Print full view hierarchy
        print("[MpvPlayerCore] === VIEW HIERARCHY ===")
        printViewHierarchy(contentView, indent: 0)
        print("[MpvPlayerCore] === END HIERARCHY ===")

        // Create a simple colored layer for testing
        let layer = CALayer()
        layer.frame = contentView.bounds
        layer.backgroundColor = CGColor(red: 1.0, green: 0.0, blue: 1.0, alpha: 1.0)  // Magenta
        layer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        // layer.zPosition = -9999  // Very low z-position to be BEHIND everything

        debugLayer = layer

        // Ensure contentView has a layer
        contentView.wantsLayer = true

        // Add our debug layer ON TOP with high zPosition
        contentView.layer?.addSublayer(layer)

        print("[MpvPlayerCore] DEBUG: Added layer with zPosition = \(layer.zPosition)")
        print("[MpvPlayerCore] DEBUG: sublayers = \(contentView.layer?.sublayers ?? [])")

        isInitialized = true
        print("[MpvPlayerCore] Initialized with debug layer")
        return true
    }

    private func printViewHierarchy(_ view: NSView, indent: Int) {
        let prefix = String(repeating: "  ", count: indent)
        print("\(prefix)- \(type(of: view)): \(view.frame)")
        if let layer = view.layer {
            print("\(prefix)  layer: \(type(of: layer)), sublayers: \(layer.sublayers?.count ?? 0)")
        }
        for subview in view.subviews {
            printViewHierarchy(subview, indent: indent + 1)
        }
    }

    // MARK: - Stub methods (do nothing for now)

    func loadFile(_ url: String, play: Bool = true) {
        print("[MpvPlayerCore] loadFile called (stub)")
    }

    func play() {
        print("[MpvPlayerCore] play called (stub)")
    }

    func pause() {
        print("[MpvPlayerCore] pause called (stub)")
    }

    func stop() {
        print("[MpvPlayerCore] stop called (stub)")
    }

    func seek(to seconds: Double) {
        print("[MpvPlayerCore] seek called (stub)")
    }

    func setAudioTrack(_ id: String) {}
    func setSubtitleTrack(_ id: String) {}
    func addSubtitleTrack(url: String, title: String?, language: String?, select: Bool) {}
    func setVolume(_ volume: Double) {}
    func setRate(_ rate: Double) {}
    func setProperty(_ name: String, value: String) {}
    func getProperty(_ name: String) -> String? { return nil }
    func command(_ args: [String]) {}

    // MARK: - Visibility

    func setVisible(_ visible: Bool) {
        debugLayer?.isHidden = !visible
        print("[MpvPlayerCore] setVisible(\(visible)), layer hidden = \(debugLayer?.isHidden ?? true)")
    }

    func updateFrame(_ frame: CGRect? = nil) {
        if let frame = frame {
            debugLayer?.frame = frame
        } else if let contentView = window?.contentView {
            debugLayer?.frame = contentView.bounds
        }
        print("[MpvPlayerCore] updateFrame, new frame = \(debugLayer?.frame ?? .zero)")
    }

    // MARK: - Cleanup

    func dispose() {
        debugLayer?.removeFromSuperlayer()
        debugLayer = nil
        isInitialized = false
        print("[MpvPlayerCore] Disposed")
    }

    deinit {
        dispose()
    }
}
