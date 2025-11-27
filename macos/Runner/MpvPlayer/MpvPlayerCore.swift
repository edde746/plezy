import Cocoa
import Libmpv

/// Protocol for receiving player events
protocol MpvPlayerDelegate: AnyObject {
    func onPropertyChange(name: String, value: Any?)
    func onEvent(name: String, data: [String: Any]?)
}

// Workaround for MoltenVK problems that cause flicker
// https://github.com/mpv-player/mpv/pull/13651
private class MetalLayer: CAMetalLayer {
    override var drawableSize: CGSize {
        get { return super.drawableSize }
        set {
            if Int(newValue.width) > 1 && Int(newValue.height) > 1 {
                super.drawableSize = newValue
            }
        }
    }

    // Fix for target-colorspace-hint - needs main thread for EDR
    override var wantsExtendedDynamicRangeContent: Bool {
        get { return super.wantsExtendedDynamicRangeContent }
        set {
            if Thread.isMainThread {
                super.wantsExtendedDynamicRangeContent = newValue
            } else {
                DispatchQueue.main.sync {
                    super.wantsExtendedDynamicRangeContent = newValue
                }
            }
        }
    }
}

/// Core MPV player using Metal rendering
class MpvPlayerCore: NSObject {

    // MARK: - Properties

    private var metalLayer: MetalLayer?
    private var mpv: OpaquePointer?
    private weak var window: NSWindow?
    private lazy var queue = DispatchQueue(label: "mpv", qos: .userInitiated)

    weak var delegate: MpvPlayerDelegate?

    private(set) var isInitialized = false

    // MARK: - Initialization

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

        // Create Metal layer for video rendering
        let layer = MetalLayer()
        layer.frame = contentView.bounds
        if let screen = window.screen ?? NSScreen.main {
            layer.contentsScale = screen.backingScaleFactor
        }
        layer.framebufferOnly = true
        layer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]

        metalLayer = layer

        // Ensure contentView has a layer and add our Metal layer
        contentView.wantsLayer = true
        contentView.layer?.addSublayer(layer)

        print("[MpvPlayerCore] Metal layer added, frame: \(layer.frame)")

        // Initialize MPV with this Metal layer
        guard setupMpv() else {
            print("[MpvPlayerCore] Failed to setup MPV")
            layer.removeFromSuperlayer()
            metalLayer = nil
            return false
        }

        isInitialized = true
        print("[MpvPlayerCore] Initialized successfully with MPV")
        return true
    }

    private func setupMpv() -> Bool {
        guard let metalLayer = metalLayer else { return false }

        mpv = mpv_create()
        guard mpv != nil else {
            print("[MpvPlayerCore] Failed to create MPV context")
            return false
        }

        // Logging
        #if DEBUG
        checkError(mpv_request_log_messages(mpv, "info"))
        #else
        checkError(mpv_request_log_messages(mpv, "warn"))
        #endif

        // Set the Metal layer as the render target (must use local var for &)
        var layer = metalLayer
        checkError(mpv_set_option(mpv, "wid", MPV_FORMAT_INT64, &layer))

        // Video output settings for Metal/Vulkan
        checkError(mpv_set_option_string(mpv, "vo", "gpu-next"))
        checkError(mpv_set_option_string(mpv, "gpu-api", "vulkan"))
        checkError(mpv_set_option_string(mpv, "gpu-context", "moltenvk"))
        checkError(mpv_set_option_string(mpv, "hwdec", "videotoolbox"))

        // Initialize MPV
        let initResult = mpv_initialize(mpv)
        if initResult < 0 {
            print("[MpvPlayerCore] mpv_initialize failed: \(String(cString: mpv_error_string(initResult)))")
            mpv_terminate_destroy(mpv)
            mpv = nil
            return false
        }

        // Observe properties for state updates
        mpv_observe_property(mpv, 0, "time-pos", MPV_FORMAT_DOUBLE)
        mpv_observe_property(mpv, 0, "duration", MPV_FORMAT_DOUBLE)
        mpv_observe_property(mpv, 0, "pause", MPV_FORMAT_FLAG)
        mpv_observe_property(mpv, 0, "paused-for-cache", MPV_FORMAT_FLAG)
        mpv_observe_property(mpv, 0, "track-list", MPV_FORMAT_NODE)
        mpv_observe_property(mpv, 0, "eof-reached", MPV_FORMAT_FLAG)

        // Set up wakeup callback for event handling
        mpv_set_wakeup_callback(mpv, { ctx in
            let core = Unmanaged<MpvPlayerCore>.fromOpaque(ctx!).takeUnretainedValue()
            core.readEvents()
        }, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))

        print("[MpvPlayerCore] MPV initialized successfully")
        return true
    }

    // MARK: - Playback Control

    func loadFile(_ url: String, play: Bool = true) {
        guard mpv != nil else {
            print("[MpvPlayerCore] Cannot load file - MPV not initialized")
            return
        }

        print("[MpvPlayerCore] Loading: \(url)")
        command("loadfile", args: [url, "replace"])

        if !play {
            setFlag("pause", true)
        }
    }

    func play() {
        setFlag("pause", false)
    }

    func pause() {
        setFlag("pause", true)
    }

    func stop() {
        command("stop")
    }

    func seek(to seconds: Double) {
        command("seek", args: [String(seconds), "absolute"])
    }

    func setAudioTrack(_ id: String) {
        setProperty("aid", value: id)
    }

    func setSubtitleTrack(_ id: String) {
        setProperty("sid", value: id)
    }

    func addSubtitleTrack(url: String, title: String?, language: String?, select: Bool) {
        var args = [url]
        if select {
            args.append("select")
        } else {
            args.append("auto")
        }
        if let title = title {
            args.append("title=\(title)")
        }
        if let language = language {
            args.append("lang=\(language)")
        }
        command("sub-add", args: args)
    }

    func setVolume(_ volume: Double) {
        guard mpv != nil else { return }
        var vol = volume
        mpv_set_property(mpv, "volume", MPV_FORMAT_DOUBLE, &vol)
    }

    func setRate(_ rate: Double) {
        guard mpv != nil else { return }
        var r = rate
        mpv_set_property(mpv, "speed", MPV_FORMAT_DOUBLE, &r)
    }

    func setProperty(_ name: String, value: String) {
        guard mpv != nil else { return }
        mpv_set_property_string(mpv, name, value)
    }

    func getProperty(_ name: String) -> String? {
        guard mpv != nil else { return nil }
        let cstr = mpv_get_property_string(mpv, name)
        defer { mpv_free(cstr) }
        return cstr.map { String(cString: $0) }
    }

    func command(_ args: [String]) {
        guard mpv != nil, !args.isEmpty else { return }
        command(args[0], args: Array(args.dropFirst()))
    }

    // MARK: - Visibility

    func setVisible(_ visible: Bool) {
        metalLayer?.isHidden = !visible
        print("[MpvPlayerCore] setVisible(\(visible))")
    }

    func updateFrame(_ frame: CGRect? = nil) {
        guard let metalLayer = metalLayer else { return }

        if let frame = frame {
            metalLayer.frame = frame
        } else if let contentView = window?.contentView {
            metalLayer.frame = contentView.bounds
        }

        // Update drawable size for proper scaling
        if let screen = window?.screen ?? NSScreen.main {
            let scale = screen.backingScaleFactor
            metalLayer.drawableSize = CGSize(
                width: metalLayer.frame.width * scale,
                height: metalLayer.frame.height * scale
            )
        }

        print("[MpvPlayerCore] updateFrame: \(metalLayer.frame)")
    }

    // MARK: - Private Helpers

    private func setFlag(_ name: String, _ flag: Bool) {
        guard mpv != nil else { return }
        var data: Int = flag ? 1 : 0
        mpv_set_property(mpv, name, MPV_FORMAT_FLAG, &data)
    }

    private func command(_ cmd: String, args: [String] = []) {
        guard mpv != nil else { return }

        // Build array of C strings for mpv_command
        var cargs: [UnsafeMutablePointer<CChar>?] = ([cmd] + args).map { strdup($0) }
        cargs.append(nil) // null-terminate
        defer {
            for ptr in cargs {
                free(ptr)
            }
        }

        // mpv_command expects UnsafePointer, use withUnsafeBufferPointer for the conversion
        cargs.withUnsafeBufferPointer { buffer in
            var constPtrs = buffer.map { UnsafePointer($0) }
            _ = mpv_command(mpv, &constPtrs)
        }
    }

    private func readEvents() {
        queue.async { [weak self] in
            guard let self = self, let mpv = self.mpv else { return }

            while true {
                let event = mpv_wait_event(mpv, 0)
                guard let eventPtr = event else { break }

                if eventPtr.pointee.event_id == MPV_EVENT_NONE {
                    break
                }

                self.handleEvent(eventPtr.pointee)
            }
        }
    }

    private func handleEvent(_ event: mpv_event) {
        switch event.event_id {
        case MPV_EVENT_PROPERTY_CHANGE:
            guard let data = event.data else { break }
            let property = data.assumingMemoryBound(to: mpv_event_property.self).pointee
            let name = String(cString: property.name)
            handlePropertyChange(name: name, property: property)

        case MPV_EVENT_FILE_LOADED:
            DispatchQueue.main.async {
                self.delegate?.onEvent(name: "file-loaded", data: nil)
            }

        case MPV_EVENT_END_FILE:
            DispatchQueue.main.async {
                self.delegate?.onEvent(name: "end-file", data: nil)
            }

        case MPV_EVENT_SHUTDOWN:
            print("[MpvPlayerCore] MPV shutdown event")

        case MPV_EVENT_LOG_MESSAGE:
            if let msgPtr = event.data?.assumingMemoryBound(to: mpv_event_log_message.self) {
                let msg = msgPtr.pointee
                if let prefix = msg.prefix, let level = msg.level, let text = msg.text {
                    print("[MPV:\(String(cString: prefix))] \(String(cString: level)): \(String(cString: text))", terminator: "")
                }
            }

        default:
            break
        }
    }

    private func handlePropertyChange(name: String, property: mpv_event_property) {
        var value: Any?

        switch property.format {
        case MPV_FORMAT_DOUBLE:
            if let ptr = property.data {
                value = ptr.assumingMemoryBound(to: Double.self).pointee
            }

        case MPV_FORMAT_FLAG:
            if let ptr = property.data {
                value = ptr.assumingMemoryBound(to: Int32.self).pointee != 0
            }

        case MPV_FORMAT_NODE:
            if let ptr = property.data {
                let node = ptr.assumingMemoryBound(to: mpv_node.self).pointee
                value = convertNode(node)
            }

        case MPV_FORMAT_STRING:
            if let ptr = property.data {
                let cstr = ptr.assumingMemoryBound(to: UnsafePointer<CChar>?.self).pointee
                value = cstr.map { String(cString: $0) }
            }

        default:
            break
        }

        DispatchQueue.main.async {
            self.delegate?.onPropertyChange(name: name, value: value)
        }
    }

    private func convertNode(_ node: mpv_node) -> Any? {
        switch node.format {
        case MPV_FORMAT_STRING:
            return node.u.string.map { String(cString: $0) }

        case MPV_FORMAT_FLAG:
            return node.u.flag != 0

        case MPV_FORMAT_INT64:
            return node.u.int64

        case MPV_FORMAT_DOUBLE:
            return node.u.double_

        case MPV_FORMAT_NODE_ARRAY:
            guard let list = node.u.list?.pointee else { return nil }
            var array = [Any]()
            for i in 0..<Int(list.num) {
                if let item = convertNode(list.values[i]) {
                    array.append(item)
                }
            }
            return array

        case MPV_FORMAT_NODE_MAP:
            guard let list = node.u.list?.pointee else { return nil }
            var dict = [String: Any]()
            for i in 0..<Int(list.num) {
                if let key = list.keys?[i].map({ String(cString: $0) }),
                   let val = convertNode(list.values[i]) {
                    dict[key] = val
                }
            }
            return dict

        default:
            return nil
        }
    }

    private func checkError(_ status: CInt) {
        if status < 0 {
            print("[MpvPlayerCore] MPV error: \(String(cString: mpv_error_string(status)))")
        }
    }

    // MARK: - Cleanup

    func dispose() {
        if let mpv = mpv {
            mpv_terminate_destroy(mpv)
            self.mpv = nil
        }
        metalLayer?.removeFromSuperlayer()
        metalLayer = nil
        isInitialized = false
        print("[MpvPlayerCore] Disposed")
    }

    deinit {
        dispose()
    }
}
