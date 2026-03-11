import Foundation
import Libmpv
import QuartzCore

#if os(iOS)
import UIKit
#elseif os(macOS)
import Cocoa
#endif

protocol MpvPlayerDelegate: AnyObject {
    func onPropertyChange(name: String, value: Any?)
    func onEvent(name: String, data: [String: Any]?)
}

// Workaround for MoltenVK problems that cause flicker.
// https://github.com/mpv-player/mpv/pull/13651
class MpvMetalLayer: CAMetalLayer {
    override var drawableSize: CGSize {
        get { super.drawableSize }
        set {
            if newValue == .zero || (Int(newValue.width) > 1 && Int(newValue.height) > 1) {
                super.drawableSize = newValue
            }
        }
    }

    #if os(iOS)
    @available(iOS 16.0, *)
    override var wantsExtendedDynamicRangeContent: Bool {
        get { super.wantsExtendedDynamicRangeContent }
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
    #elseif os(macOS)
    override var wantsExtendedDynamicRangeContent: Bool {
        get { super.wantsExtendedDynamicRangeContent }
        set {
            if Thread.isMainThread {
                super.wantsExtendedDynamicRangeContent = newValue
            } else {
                DispatchQueue.main.async {
                    super.wantsExtendedDynamicRangeContent = newValue
                }
            }
        }
    }
    #endif
}

/// Safely convert a C string to Swift String with UTF-8 validation.
/// Falls back to Latin-1 decoding if the bytes are not valid UTF-8.
/// mpv does not guarantee UTF-8 for log messages, error strings, or
/// system-encoded paths and Flutter codecs reject invalid UTF-8.
func safeString(_ cstr: UnsafePointer<CChar>) -> String {
    if let string = String(validatingUTF8: cstr) {
        return string
    }

    let length = strlen(cstr)
    let buffer = UnsafeBufferPointer(
        start: UnsafeRawPointer(cstr).assumingMemoryBound(to: UInt8.self),
        count: length
    )
    return String(buffer.map { Character(Unicode.Scalar($0)) })
}

class MpvPlayerCoreBase: NSObject {
    weak var delegate: MpvPlayerDelegate?

    var metalLayer: MpvMetalLayer?
    var mpv: OpaquePointer?
    var isInitialized = false
    var isDisposing = false
    var isPipActive = false
    var hdrEnabled = true
    var lastSigPeak = 0.0

    let queue = DispatchQueue(label: "mpv", qos: .userInitiated)
    private let queueKey = DispatchSpecificKey<Void>()

    private var pendingCommands: [UInt64: (Result<Void, Error>) -> Void] = [:]
    private let pendingCommandsLock = NSLock()
    private var nextRequestId: UInt64 = 1

    override init() {
        super.init()
        queue.setSpecific(key: queueKey, value: ())
    }

    func configurePlatformMpvOptions() {}

    func updateEDRMode(sigPeak: Double) {}

    func setupMpv() -> Bool {
        guard let metalLayer else { return false }

        mpv = mpv_create()
        guard let mpv else {
            print("[MpvPlayerCore] Failed to create MPV context")
            return false
        }

        #if DEBUG
        checkError(mpv_request_log_messages(mpv, "info"))
        #else
        checkError(mpv_request_log_messages(mpv, "warn"))
        #endif

        var layer = metalLayer
        checkError(mpv_set_option(mpv, "wid", MPV_FORMAT_INT64, &layer))
        applySharedMpvOptions()
        configurePlatformMpvOptions()

        let initResult = mpv_initialize(mpv)
        if initResult < 0 {
            print("[MpvPlayerCore] mpv_initialize failed: \(safeString(mpv_error_string(initResult)))")
            mpv_terminate_destroy(mpv)
            self.mpv = nil
            return false
        }

        mpv_set_wakeup_callback(
            mpv,
            { context in
                guard let context else { return }
                let core = Unmanaged<MpvPlayerCoreBase>.fromOpaque(context).takeUnretainedValue()
                core.readEvents()
            },
            UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        )

        mpv_observe_property(mpv, 0, "video-params/sig-peak", MPV_FORMAT_DOUBLE)
        return true
    }

    func setLogLevel(_ level: String) {
        guard let mpv else { return }
        mpv_request_log_messages(mpv, level)
    }

    func setProperty(_ name: String, value: String) {
        guard mpv != nil else { return }

        if name == "hdr-enabled" {
            let enabled = value == "yes" || value == "true" || value == "1"
            setHDREnabled(enabled)
            return
        }

        mpv_set_property_string(mpv, name, value)
    }

    func setHDREnabled(_ enabled: Bool) {
        hdrEnabled = enabled
        print("[MpvPlayerCore] HDR enabled: \(enabled)")

        if mpv != nil {
            mpv_set_property_string(mpv, "target-colorspace-hint", enabled ? "yes" : "no")
        }

        DispatchQueue.main.async {
            self.updateEDRMode(sigPeak: self.lastSigPeak)
        }
    }

    func getProperty(_ name: String) -> String? {
        guard mpv != nil else { return nil }
        let cstr = mpv_get_property_string(mpv, name)
        defer { mpv_free(cstr) }
        return cstr.map { safeString($0) }
    }

    func observeProperty(_ name: String, format: String) {
        guard mpv != nil else { return }

        let mpvFormat: mpv_format
        switch format {
        case "double":
            mpvFormat = MPV_FORMAT_DOUBLE
        case "flag":
            mpvFormat = MPV_FORMAT_FLAG
        case "node":
            mpvFormat = MPV_FORMAT_NODE
        case "string":
            mpvFormat = MPV_FORMAT_STRING
        default:
            return
        }

        mpv_observe_property(mpv, 0, name, mpvFormat)
    }

    func command(_ args: [String]) {
        guard mpv != nil, !args.isEmpty else { return }
        command(args[0], args: Array(args.dropFirst()))
    }

    func commandAsync(_ args: [String], completion: @escaping (Result<Void, Error>) -> Void) {
        guard let mpv, !args.isEmpty else {
            completion(.success(()))
            return
        }

        pendingCommandsLock.lock()
        let requestId = nextRequestId
        nextRequestId += 1
        pendingCommands[requestId] = completion
        pendingCommandsLock.unlock()

        var cargs: [UnsafeMutablePointer<CChar>?] = args.map { strdup($0) }
        cargs.append(nil)

        cargs.withUnsafeBufferPointer { buffer in
            var constPointers = buffer.map { UnsafePointer($0) }
            let result = mpv_command_async(mpv, requestId, &constPointers)
            if result < 0 {
                pendingCommandsLock.lock()
                let pending = pendingCommands.removeValue(forKey: requestId)
                pendingCommandsLock.unlock()

                guard let pending else { return }
                let error = NSError(
                    domain: "mpv",
                    code: Int(result),
                    userInfo: [NSLocalizedDescriptionKey: safeString(mpv_error_string(result))]
                )
                DispatchQueue.main.async {
                    pending(.failure(error))
                }
            }
        }

        for pointer in cargs {
            free(pointer)
        }
    }

    var isPaused: Bool {
        guard let mpv else { return true }
        var flag: Int32 = 0
        mpv_get_property(mpv, "pause", MPV_FORMAT_FLAG, &flag)
        return flag != 0
    }

    var duration: Double {
        guard let mpv else { return 0 }
        var value: Double = 0
        mpv_get_property(mpv, "duration", MPV_FORMAT_DOUBLE, &value)
        return value
    }

    var timePos: Double {
        guard let mpv else { return 0 }
        var value: Double = 0
        mpv_get_property(mpv, "time-pos", MPV_FORMAT_DOUBLE, &value)
        return value
    }

    func disposeSharedState(destroySynchronously: Bool) {
        isDisposing = true
        cancelPendingCommands()

        let mpvHandle = mpv
        mpv = nil

        let destroy = {
            if let mpvHandle {
                mpv_set_wakeup_callback(mpvHandle, nil, nil)
                mpv_terminate_destroy(mpvHandle)
            }
        }

        if destroySynchronously {
            if DispatchQueue.getSpecific(key: queueKey) != nil {
                destroy()
            } else {
                queue.sync(execute: destroy)
            }
        } else {
            queue.async(execute: destroy)
        }
    }

    func applyGpuNextOptions() {
        guard mpv != nil else { return }
        mpv_set_property_string(mpv, "gpu-api", "vulkan")
        mpv_set_property_string(mpv, "gpu-context", "moltenvk")
        mpv_set_property_string(mpv, "vo", "gpu-next")
    }

    private func applySharedMpvOptions() {
        guard let mpv else { return }
        checkError(mpv_set_option_string(mpv, "vo", "gpu-next"))
        checkError(mpv_set_option_string(mpv, "gpu-api", "vulkan"))
        checkError(mpv_set_option_string(mpv, "gpu-context", "moltenvk"))
        checkError(mpv_set_option_string(mpv, "hwdec", "videotoolbox"))
        checkError(mpv_set_option_string(mpv, "target-colorspace-hint", "yes"))
    }

    private func cancelPendingCommands() {
        pendingCommandsLock.lock()
        let pending = pendingCommands
        pendingCommands.removeAll()
        pendingCommandsLock.unlock()

        let error = NSError(
            domain: "mpv",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Player disposed"]
        )
        for (_, completion) in pending {
            DispatchQueue.main.async {
                completion(.failure(error))
            }
        }
    }

    private func command(_ command: String, args: [String] = []) {
        guard mpv != nil else { return }

        var cargs: [UnsafeMutablePointer<CChar>?] = ([command] + args).map { strdup($0) }
        cargs.append(nil)
        defer {
            for pointer in cargs {
                free(pointer)
            }
        }

        cargs.withUnsafeBufferPointer { buffer in
            var constPointers = buffer.map { UnsafePointer($0) }
            _ = mpv_command(mpv, &constPointers)
        }
    }

    private func readEvents() {
        queue.async { [weak self] in
            guard let self, !self.isDisposing, let mpv = self.mpv else { return }

            while true {
                let event = mpv_wait_event(mpv, 0)
                guard let event else { break }

                if event.pointee.event_id == MPV_EVENT_NONE {
                    break
                }

                self.handleEvent(event.pointee)
            }
        }
    }

    private func handleEvent(_ event: mpv_event) {
        switch event.event_id {
        case MPV_EVENT_PROPERTY_CHANGE:
            guard let data = event.data else { break }
            let property = data.assumingMemoryBound(to: mpv_event_property.self).pointee
            let name = safeString(property.name)
            handlePropertyChange(name: name, property: property)

        case MPV_EVENT_COMMAND_REPLY:
            let requestId = event.reply_userdata
            pendingCommandsLock.lock()
            let completion = pendingCommands.removeValue(forKey: requestId)
            pendingCommandsLock.unlock()

            guard let completion else { break }
            if event.error < 0 {
                let error = NSError(
                    domain: "mpv",
                    code: Int(event.error),
                    userInfo: [NSLocalizedDescriptionKey: safeString(mpv_error_string(event.error))]
                )
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            } else {
                DispatchQueue.main.async {
                    completion(.success(()))
                }
            }

        case MPV_EVENT_FILE_LOADED:
            DispatchQueue.main.async {
                self.delegate?.onEvent(name: "file-loaded", data: nil)
            }

        case MPV_EVENT_END_FILE:
            if let endFilePtr = event.data?.assumingMemoryBound(to: mpv_event_end_file.self) {
                let endFile = endFilePtr.pointee
                var data: [String: Any] = ["reason": Int(endFile.reason.rawValue)]
                if endFile.reason == MPV_END_FILE_REASON_ERROR {
                    data["error"] = Int(endFile.error)
                    data["message"] = safeString(mpv_error_string(endFile.error))
                }
                DispatchQueue.main.async {
                    self.delegate?.onEvent(name: "end-file", data: data)
                }
            } else {
                DispatchQueue.main.async {
                    self.delegate?.onEvent(name: "end-file", data: nil)
                }
            }

        case MPV_EVENT_SHUTDOWN:
            print("[MpvPlayerCore] MPV shutdown event")

        case MPV_EVENT_PLAYBACK_RESTART:
            DispatchQueue.main.async {
                self.delegate?.onEvent(name: "playback-restart", data: nil)
            }

        case MPV_EVENT_LOG_MESSAGE:
            if let messagePointer = event.data?.assumingMemoryBound(to: mpv_event_log_message.self) {
                let message = messagePointer.pointee
                let prefix = message.prefix.map { safeString($0) } ?? ""
                let level = message.level.map { safeString($0) } ?? ""
                let text = message.text.map { safeString($0) } ?? ""

                DispatchQueue.main.async {
                    self.delegate?.onEvent(
                        name: "log-message",
                        data: ["prefix": prefix, "level": level, "text": text]
                    )
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
            if let data = property.data {
                value = data.assumingMemoryBound(to: Double.self).pointee
            }

        case MPV_FORMAT_FLAG:
            if let data = property.data {
                value = data.assumingMemoryBound(to: Int32.self).pointee != 0
            }

        case MPV_FORMAT_NODE:
            if let data = property.data {
                let node = data.assumingMemoryBound(to: mpv_node.self).pointee
                value = convertNode(node)
            }

        case MPV_FORMAT_STRING:
            if let data = property.data {
                let cstring = data.assumingMemoryBound(to: UnsafePointer<CChar>?.self).pointee
                value = cstring.map { safeString($0) }
            }

        default:
            break
        }

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
            for index in 0..<Int(list.num) {
                if let item = convertNode(list.values[index]) {
                    array.append(item)
                }
            }
            return array

        case MPV_FORMAT_NODE_MAP:
            guard let list = node.u.list?.pointee else { return nil }
            var dictionary = [String: Any]()
            for index in 0..<Int(list.num) {
                if let key = list.keys?[index].map({ safeString($0) }),
                   let value = convertNode(list.values[index]) {
                    dictionary[key] = value
                }
            }
            return dictionary

        default:
            return nil
        }
    }

    func checkError(_ status: CInt) {
        if status < 0 {
            print("[MpvPlayerCore] MPV error: \(safeString(mpv_error_string(status)))")
        }
    }
}
