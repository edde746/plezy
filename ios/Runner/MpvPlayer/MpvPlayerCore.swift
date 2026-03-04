import Libmpv
import UIKit

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
    @available(iOS 16.0, *)
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

/// Safely convert a C string to Swift String with UTF-8 validation.
/// Falls back to Latin-1 decoding if the bytes are not valid UTF-8.
/// mpv does not guarantee UTF-8 for log messages, error strings, or
/// system-encoded paths — sending invalid UTF-8 through Flutter's
/// StandardMessageCodec causes FormatException crashes.
private func safeString(_ cstr: UnsafePointer<CChar>) -> String {
    if let s = String(validatingUTF8: cstr) {
        return s
    }
    // Latin-1 fallback: interpret each byte as its Unicode scalar
    let len = strlen(cstr)
    let buf = UnsafeBufferPointer(start: UnsafeRawPointer(cstr).assumingMemoryBound(to: UInt8.self), count: len)
    return String(buf.map { Character(Unicode.Scalar($0)) })
}

/// Core MPV player using Metal rendering for iOS
class MpvPlayerCore: NSObject {

    // MARK: - Properties

    private var metalLayer: MetalLayer?
    private var containerView: UIView?  // Container for proper EDR activation
    private var mpv: OpaquePointer?
    private weak var window: UIWindow?
    private lazy var queue = DispatchQueue(label: "mpv", qos: .userInitiated)

    weak var delegate: MpvPlayerDelegate?

    private(set) var isInitialized = false
    private var isDisposing = false  // Flag to prevent race conditions during disposal

    // PiP state
    var isPipActive = false
    var isPipStarting = false  // VO switched for PiP, waiting for first frame

    // HDR settings
    private var hdrEnabled = true  // User preference for HDR
    private var lastSigPeak: Double = 0.0  // Last known sig-peak for re-evaluation

    // Async command tracking to prevent UI blocking
    private var pendingCommands: [UInt64: (Result<Void, Error>) -> Void] = [:]
    private var pendingCommandsLock = NSLock()
    private var nextRequestId: UInt64 = 1

    // MARK: - Initialization

    func initialize(in window: UIWindow) -> Bool {
        guard !isInitialized else {
            print("[MpvPlayerCore] Already initialized")
            return true
        }

        self.window = window

        // Create container view for proper EDR activation
        // EDR requires the CAMetalLayer to be in a UIView hierarchy, not just window.layer
        let container = UIView(frame: window.bounds)
        container.backgroundColor = .clear
        container.isUserInteractionEnabled = false

        // Create Metal layer for video rendering
        let layer = MetalLayer()
        layer.frame = container.bounds
        layer.contentsScale = UIScreen.main.nativeScale
        layer.framebufferOnly = true
        layer.backgroundColor = UIColor.black.cgColor

        container.layer.addSublayer(layer)
        containerView = container
        metalLayer = layer

        // Add container view to window (behind Flutter's root view controller)
        window.insertSubview(container, at: 0)

        // Initialize MPV with this Metal layer
        guard setupMpv() else {
            print("[MpvPlayerCore] Failed to setup MPV")
            layer.removeFromSuperlayer()
            container.removeFromSuperview()
            metalLayer = nil
            containerView = nil
            return false
        }

        // Setup background/foreground notifications
        setupNotifications()

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
        checkError(mpv_set_option_string(mpv, "target-colorspace-hint", "yes"))

        // Initialize MPV
        let initResult = mpv_initialize(mpv)
        if initResult < 0 {
            print(
                "[MpvPlayerCore] mpv_initialize failed: \(String(cString: mpv_error_string(initResult)))"
            )
            mpv_terminate_destroy(mpv)
            mpv = nil
            return false
        }

        // Set up wakeup callback for event handling
        mpv_set_wakeup_callback(
            mpv,
            { ctx in
                guard let ctx = ctx else { return }  // Safe guard instead of force unwrap
                let core = Unmanaged<MpvPlayerCore>.fromOpaque(ctx).takeUnretainedValue()
                core.readEvents()
            }, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))

        // Observe video-params/sig-peak for HDR detection
        mpv_observe_property(mpv, 0, "video-params/sig-peak", MPV_FORMAT_DOUBLE)

        return true
    }

    // MARK: - Background/Foreground Handling

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(enterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(enterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    @objc private func enterBackground() {
        if isPipActive || isPipStarting {
            print("[MpvPlayerCore] Entering background - PiP active/starting, keeping video")
            return
        }
        // Disable video output to fix black screen when returning from background
        print("[MpvPlayerCore] Entering background - disabling video")
        if mpv != nil {
            mpv_set_option_string(mpv, "vid", "no")
        }
    }

    @objc private func enterForeground() {
        // Skip if PiP is active - video is already enabled
        if isPipActive {
            print("[MpvPlayerCore] Entering foreground - PiP active, skipping vid restore")
            return
        }
        // Re-enable video output
        print("[MpvPlayerCore] Entering foreground - enabling video")
        if mpv != nil {
            mpv_set_option_string(mpv, "vid", "auto")
        }
    }

    // MARK: - MPV Properties and Commands

    func setProperty(_ name: String, value: String) {
        guard mpv != nil else { return }

        // Handle custom HDR toggle property
        if name == "hdr-enabled" {
            let enabled = value == "yes" || value == "true" || value == "1"
            setHDREnabled(enabled)
            return
        }

        mpv_set_property_string(mpv, name, value)
    }

    /// Enable or disable HDR mode
    func setHDREnabled(_ enabled: Bool) {
        hdrEnabled = enabled
        print("[MpvPlayerCore] HDR enabled: \(enabled)")

        // Update MPV's target-colorspace-hint
        if mpv != nil {
            mpv_set_property_string(mpv, "target-colorspace-hint", enabled ? "yes" : "no")
        }

        // Re-evaluate EDR mode with current sig-peak
        DispatchQueue.main.async {
            self.updateEDRMode(sigPeak: self.lastSigPeak)
        }
    }

    func getProperty(_ name: String) -> String? {
        guard mpv != nil else { return nil }
        let cstr = mpv_get_property_string(mpv, name)
        defer { mpv_free(cstr) }
        return cstr.map { String(cString: $0) }
    }

    func setLogLevel(_ level: String) {
        guard let mpv = mpv else { return }
        mpv_request_log_messages(mpv, level)
    }

    func observeProperty(_ name: String, format: String) {
        guard mpv != nil else { return }

        let mpvFormat: mpv_format
        switch format {
        case "double": mpvFormat = MPV_FORMAT_DOUBLE
        case "flag": mpvFormat = MPV_FORMAT_FLAG
        case "node": mpvFormat = MPV_FORMAT_NODE
        case "string": mpvFormat = MPV_FORMAT_STRING
        default: return
        }

        mpv_observe_property(mpv, 0, name, mpvFormat)
    }

    func command(_ args: [String]) {
        guard mpv != nil, !args.isEmpty else { return }
        command(args[0], args: Array(args.dropFirst()))
    }

    /// Execute an MPV command asynchronously to prevent UI blocking.
    /// Uses mpv_command_async which returns immediately; the completion is called
    /// when MPV_EVENT_COMMAND_REPLY is received.
    func commandAsync(_ args: [String], completion: @escaping (Result<Void, Error>) -> Void) {
        guard let mpv = mpv, !args.isEmpty else {
            completion(.success(()))
            return
        }

        // Generate unique request ID
        pendingCommandsLock.lock()
        let requestId = nextRequestId
        nextRequestId += 1
        pendingCommands[requestId] = completion
        pendingCommandsLock.unlock()

        // Build array of C strings for mpv_command_async
        var cargs: [UnsafeMutablePointer<CChar>?] = args.map { strdup($0) }
        cargs.append(nil)  // null-terminate

        // mpv_command_async returns immediately
        cargs.withUnsafeBufferPointer { buffer in
            var constPtrs = buffer.map { UnsafePointer($0) }
            let result = mpv_command_async(mpv, requestId, &constPtrs)
            if result < 0 {
                // Command submission failed, complete immediately with error
                pendingCommandsLock.lock()
                if let pending = pendingCommands.removeValue(forKey: requestId) {
                    pendingCommandsLock.unlock()
                    let error = NSError(domain: "mpv", code: Int(result),
                                        userInfo: [NSLocalizedDescriptionKey: String(cString: mpv_error_string(result))])
                    DispatchQueue.main.async { pending(.failure(error)) }
                } else {
                    pendingCommandsLock.unlock()
                }
            }
        }

        // Free the C strings
        for ptr in cargs {
            free(ptr)
        }
    }

    // MARK: - PiP VO Switching

    /// Switch from gpu-next to vo_pip for PiP rendering.
    /// vo_pip feeds VideoToolbox CVPixelBuffers to an AVSampleBufferDisplayLayer
    /// which is required by AVPictureInPictureController.
    ///
    /// Strategy: disable the video track (`vid=no`) to tear down the active VO,
    /// then set `wid` and `vo` while no VO is running, then re-enable video.
    /// This avoids the crash where gpu-next calls `drawableSize` on an
    /// AVSampleBufferDisplayLayer, and ensures the new VO reads `wid` at init.
    func switchToPipVO(layerPtr: UnsafeMutableRawPointer) -> Bool {
        guard let mpv = mpv else { return false }

        print("[MpvPlayerCore] Switching to pip VO for PiP")

        // Detach the Metal layer from the view hierarchy on the main thread BEFORE
        // vid=no, so the 'vo' thread VO uninit has no UIKit work to do (avoids
        // "layout engine from background thread" crash).
        metalLayer?.removeFromSuperlayer()

        // 1. Disable video track — tears down the current VO completely
        mpv_set_property_string(mpv, "vid", "no")

        // 2. Point wid at the PiP sample-buffer layer (safe — no active VO)
        var ptr = Int64(Int(bitPattern: layerPtr))
        mpv_set_property(mpv, "wid", MPV_FORMAT_INT64, &ptr)

        // 3. Set VO to pip (stored, not yet created)
        mpv_set_property_string(mpv, "vo", "pip")

        // 4. Re-enable video — creates pip VO with our layer as wid
        mpv_set_property_string(mpv, "vid", "auto")

        print("[MpvPlayerCore] Switched to pip VO successfully")
        return true
    }

    /// Switch back from vo_pip to gpu-next VO for normal rendering.
    /// Same strategy: vid=no → reconfigure → vid=auto.
    func switchToGpuNextVO() -> Bool {
        guard let mpv = mpv, let metalLayer = metalLayer else { return false }

        print("[MpvPlayerCore] Switching back to gpu-next VO")

        // 1. Disable video track — tears down pip VO
        mpv_set_property_string(mpv, "vid", "no")

        // 2. Point wid back at the Metal layer (safe — no active VO)
        var layer = metalLayer
        mpv_set_property(mpv, "wid", MPV_FORMAT_INT64, &layer)

        // 3. Restore gpu-next + Vulkan/MoltenVK settings (read at VO creation)
        mpv_set_property_string(mpv, "gpu-api", "vulkan")
        mpv_set_property_string(mpv, "gpu-context", "moltenvk")
        mpv_set_property_string(mpv, "vo", "gpu-next")

        // 4. Re-enable video — creates gpu-next VO with Metal layer as wid
        mpv_set_property_string(mpv, "vid", "auto")

        // Re-attach the Metal layer to the view hierarchy (was detached in switchToPipVO)
        if metalLayer.superlayer == nil, let container = containerView {
            container.layer.addSublayer(metalLayer)
        }

        print("[MpvPlayerCore] Switched back to gpu-next VO successfully")
        return true
    }

    /// Whether mpv is currently paused
    var isPaused: Bool {
        guard let mpv = mpv else { return true }
        var flag: Int32 = 0
        mpv_get_property(mpv, "pause", MPV_FORMAT_FLAG, &flag)
        return flag != 0
    }

    /// Current playback duration in seconds
    var duration: Double {
        guard let mpv = mpv else { return 0 }
        var value: Double = 0
        mpv_get_property(mpv, "duration", MPV_FORMAT_DOUBLE, &value)
        return value
    }

    /// Current playback time in seconds
    var timePos: Double {
        guard let mpv = mpv else { return 0 }
        var value: Double = 0
        mpv_get_property(mpv, "time-pos", MPV_FORMAT_DOUBLE, &value)
        return value
    }

    // MARK: - Visibility

    func setVisible(_ visible: Bool) {
        guard let container = containerView else { return }

        if visible {
            // Re-insert at the bottom of the window view stack
            container.removeFromSuperview()
            window?.insertSubview(container, at: 0)
        }

        container.isHidden = !visible
    }

    func updateFrame(_ frame: CGRect? = nil) {
        guard let metalLayer = metalLayer, let container = containerView else { return }

        if let frame = frame {
            container.frame = frame
            metalLayer.frame = container.bounds
        } else if let window = window {
            container.frame = window.bounds
            metalLayer.frame = container.bounds
        }

        // Update drawable size for proper scaling
        let scale = UIScreen.main.nativeScale
        metalLayer.drawableSize = CGSize(
            width: metalLayer.frame.width * scale,
            height: metalLayer.frame.height * scale
        )
    }

    // MARK: - Private Helpers

    private func command(_ cmd: String, args: [String] = []) {
        guard mpv != nil else { return }

        // Build array of C strings for mpv_command
        var cargs: [UnsafeMutablePointer<CChar>?] = ([cmd] + args).map { strdup($0) }
        cargs.append(nil)  // null-terminate
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
            guard let self = self, !self.isDisposing, let mpv = self.mpv else { return }

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

        case MPV_EVENT_COMMAND_REPLY:
            // Handle async command completion
            let requestId = event.reply_userdata
            pendingCommandsLock.lock()
            let completion = pendingCommands.removeValue(forKey: requestId)
            pendingCommandsLock.unlock()

            if let completion = completion {
                if event.error < 0 {
                    let error = NSError(domain: "mpv", code: Int(event.error),
                                        userInfo: [NSLocalizedDescriptionKey: String(cString: mpv_error_string(event.error))])
                    DispatchQueue.main.async { completion(.failure(error)) }
                } else {
                    DispatchQueue.main.async { completion(.success(())) }
                }
            }

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

        case MPV_EVENT_PLAYBACK_RESTART:
            DispatchQueue.main.async {
                self.delegate?.onEvent(name: "playback-restart", data: nil)
            }

        case MPV_EVENT_LOG_MESSAGE:
            if let msgPtr = event.data?.assumingMemoryBound(to: mpv_event_log_message.self) {
                let msg = msgPtr.pointee
                let prefix = msg.prefix.map { safeString($0) } ?? ""
                let level = msg.level.map { safeString($0) } ?? ""
                let text = msg.text.map { safeString($0) } ?? ""

                DispatchQueue.main.async {
                    self.delegate?.onEvent(name: "log-message", data: [
                        "prefix": prefix,
                        "level": level,
                        "text": text
                    ])
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
                value = cstr.map { safeString($0) }
            }

        default:
            break
        }

        // Handle sig-peak for HDR/EDR activation
        if name == "video-params/sig-peak", let sigPeak = value as? Double {
            lastSigPeak = sigPeak
            DispatchQueue.main.async {
                self.updateEDRMode(sigPeak: sigPeak)
            }
        }

        DispatchQueue.main.async {
            self.delegate?.onPropertyChange(name: name, value: value)
        }
    }

    // MARK: - HDR/EDR Support

    private func updateEDRMode(sigPeak: Double) {
        guard let layer = metalLayer else { return }

        // Check if screen supports EDR (iOS 16+)
        var edrHeadroom: CGFloat = 1.0
        if #available(iOS 16.0, *) {
            edrHeadroom = containerView?.window?.screen.potentialEDRHeadroom ?? 1.0
        }

        let isHDRContent = sigPeak > 1.0
        let screenSupportsEDR = edrHeadroom > 1.0
        let shouldEnableEDR = hdrEnabled && isHDRContent && screenSupportsEDR

        if #available(iOS 16.0, *) {
            layer.wantsExtendedDynamicRangeContent = shouldEnableEDR
        }

        print(
            "[MpvPlayerCore] EDR mode: \(shouldEnableEDR) (hdrEnabled: \(hdrEnabled), sigPeak: \(sigPeak), headroom: \(edrHeadroom))"
        )
    }

    private func convertNode(_ node: mpv_node) -> Any? {
        switch node.format {
        case MPV_FORMAT_STRING:
            return node.u.string.map { safeString($0) }

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
                if let key = list.keys?[i].map({ safeString($0) }),
                    let val = convertNode(list.values[i])
                {
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
        // Set disposing flag first to prevent race conditions with event callbacks
        isDisposing = true

        NotificationCenter.default.removeObserver(self)

        // Cancel any pending async commands
        pendingCommandsLock.lock()
        let pending = pendingCommands
        pendingCommands.removeAll()
        pendingCommandsLock.unlock()

        // Complete pending commands with cancellation error
        let cancelError = NSError(domain: "mpv", code: -1,
                                  userInfo: [NSLocalizedDescriptionKey: "Player disposed"])
        for (_, completion) in pending {
            DispatchQueue.main.async { completion(.failure(cancelError)) }
        }

        let mpvHandle = mpv
        mpv = nil

        // Use async to avoid blocking the main thread (prevents deadlock)
        queue.async {
            if let handle = mpvHandle {
                mpv_set_wakeup_callback(handle, nil, nil)
                mpv_terminate_destroy(handle)
            }
        }
        metalLayer?.removeFromSuperlayer()
        metalLayer = nil
        containerView?.removeFromSuperview()
        containerView = nil
        isInitialized = false
        print("[MpvPlayerCore] Disposed")
    }

    deinit {
        dispose()
    }
}
