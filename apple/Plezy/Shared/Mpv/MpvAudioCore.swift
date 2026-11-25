import Foundation
import Libmpv
import PlezyKit

private let log = EngineLog(tag: "mpv-audio")

/// The shared music player's mpv core (`MpvAudioCore`) on MPVKit: one libmpv handle of its own, apart from every video
/// engine's, with no video output. The shared `MpvAudioPlayer` holds every rule; this only carries its requests to mpv
/// and mpv's reports back. The audio session is the music session's Now Playing host's, not this core's.
///
/// Threading: every libmpv call runs on `queue`, a private serial queue, in call order, and requests use libmpv's async
/// API; answers and reports go out from `queue`. `start` waits on `queue`, from the shared player's own thread.
final class AppleMpvAudioCore: MpvAudioCore, @unchecked Sendable {
    private let queue = DispatchQueue(label: "com.edde746.plezy.mpv-audio", qos: .userInitiated)

    // Confined to `queue`.
    private var mpv: OpaquePointer?
    private var wakeupTarget: Unmanaged<AudioWakeupTarget>?
    private var listener: (any MpvAudioCoreListener)?
    private var observed: [String] = []
    private var nextRequest: UInt64 = 1
    private var replies: [UInt64: (String?) -> Void] = [:]
    private var reads: [UInt64: (String?, String?) -> Void] = [:]

    /// A new music player on this platform's audio outputs (the video engine's `ao`), passing AC-3 and E-AC-3 (and from
    /// 26 TrueHD and DTS-HD) through where the music session turns passthrough on.
    static func player() -> any AudioPlayer {
        var options: [String: String] = [:]
        if !MpvPlayerEngine.audioOutput.isEmpty { options["ao"] = MpvPlayerEngine.audioOutput }
        #if !os(macOS)
        // ao_audiounit (iOS's fallback, tvOS's PCM output) asks the session to mix with others unless this is set, and
        // a mixable session loses the lock screen's Now Playing; on iOS and tvOS it claims nothing else (on the Mac it
        // would mean CoreAudio's hog mode). As the video engine's (`MpvPlayerEngine.options`).
        options["audio-exclusive"] = "yes"
        #endif
        #if DEBUG
        for (name, value) in EngineDebug.startupOptions { options[name] = value }
        #endif
        return MpvAudioPlayer(
            core: AppleMpvAudioCore(),
            platformOptions: options,
            passthroughCodecs: MpvPlayerEngine.passthroughCodecs,
            contentFds: nil
        )
    }

    func start(options: [String: String], observed: [String], listener: any MpvAudioCoreListener) -> String? {
        queue.sync { create(options: options, observed: observed, listener: listener) }
    }

    func command(args: [String], done: @escaping (String?) -> Void) {
        queue.async { [self] in
            guard let mpv else { return done("the audio core is gone") }
            let id = register(done)
            let cStrings = args.map { strdup($0) }
            defer { cStrings.forEach { free($0) } }
            var argv: [UnsafePointer<CChar>?] = cStrings.map { UnsafePointer($0) }
            argv.append(nil)
            // libmpv copies the arguments before returning.
            answerIfRefused(id, mpv_command_async(mpv, id, &argv))
        }
    }

    func setProperty(name: String, value: String, done: @escaping (String?) -> Void) {
        queue.async { [self] in
            guard let mpv else { return done("the audio core is gone") }
            let id = register(done)
            let status = value.withCString { pointer in
                var data: UnsafePointer<CChar>? = pointer
                return mpv_set_property_async(mpv, id, name, MPV_FORMAT_STRING, &data)
            }
            answerIfRefused(id, status)
        }
    }

    func getProperty(name: String, done: @escaping (String?, String?) -> Void) {
        queue.async { [self] in
            guard let mpv else { return done(nil, "the audio core is gone") }
            let id = nextRequest
            nextRequest += 1
            let status = mpv_get_property_async(mpv, id, name, MPV_FORMAT_STRING)
            if status < 0 { return done(nil, MpvPlayerEngine.errorString(status)) }
            reads[id] = done
        }
    }

    func setLogLevel(level: String) {
        queue.async { [self] in
            guard let mpv else { return }
            _ = mpv_request_log_messages(mpv, level)
        }
    }

    func destroy() {
        queue.async { [self] in
            listener = nil
            guard let mpv else { return }
            self.mpv = nil
            // After this returns no wakeup callback is running or can start (libmpv takes the same lock).
            mpv_set_wakeup_callback(mpv, nil, nil)
            mpv_terminate_destroy(mpv)
            wakeupTarget?.release()
            wakeupTarget = nil
            for done in replies.values { done("the audio core is gone") }
            for done in reads.values { done(nil, "the audio core is gone") }
            replies = [:]
            reads = [:]
        }
    }

    // MARK: Handle

    /// Creates, configures and initializes the handle (on `queue`); mpv's reason when a step fails, which ends it.
    private func create(options: [String: String], observed: [String], listener: any MpvAudioCoreListener) -> String? {
        // libmpv requires the C numeric locale (client.h).
        setlocale(LC_NUMERIC, "C")
        guard let handle = mpv_create() else { return "mpv_create failed" }
        func fail(_ message: String) -> String {
            mpv_terminate_destroy(handle)
            log.error("audio core failed to start: \(message)")
            return message
        }
        _ = mpv_request_log_messages(handle, "warn")
        let common = Set(MpvOptionsKt.COMMON_MPV_OPTIONS.keys)
        for (name, value) in options {
            let status = mpv_set_option_string(handle, name, value)
            #if !os(macOS)
            // iOS's and tvOS's libmpv has no Lua: no scripts, and none of the options that turn them off.
            if status == MPV_ERROR_OPTION_NOT_FOUND.rawValue, common.contains(name) { continue }
            #endif
            if status < 0 { return fail("option \(name)=\(value): \(MpvPlayerEngine.errorString(status))") }
        }
        #if !os(macOS)
        // As the video engine: mpv's default title is expanded on every update for an audio stream name nothing reads.
        if mpv_set_option_string(handle, "title", "mpv") < 0 { return fail("option title=mpv") }
        #endif
        let initialized = mpv_initialize(handle)
        if initialized < 0 { return fail("mpv_initialize: \(MpvPlayerEngine.errorString(initialized))") }
        for (index, name) in observed.enumerated() {
            let status = mpv_observe_property(handle, UInt64(index), name, MPV_FORMAT_STRING)
            if status < 0 { return fail("observe \(name): \(MpvPlayerEngine.errorString(status))") }
        }
        self.observed = observed
        self.listener = listener
        // libmpv keeps this pointer without retaining it; the target is released after mpv_terminate_destroy.
        let target = Unmanaged.passRetained(AudioWakeupTarget(core: self))
        mpv_set_wakeup_callback(handle, { context in
            guard let context else { return }
            Unmanaged<AudioWakeupTarget>.fromOpaque(context).takeUnretainedValue().core?.scheduleDrain()
        }, target.toOpaque())
        mpv = handle
        wakeupTarget = target
        return nil
    }

    private func register(_ done: @escaping (String?) -> Void) -> UInt64 {
        let id = nextRequest
        nextRequest += 1
        replies[id] = done
        return id
    }

    private func answerIfRefused(_ id: UInt64, _ status: CInt) {
        guard status < 0 else { return }
        replies.removeValue(forKey: id)?(MpvPlayerEngine.errorString(status))
    }

    // MARK: Events

    fileprivate func scheduleDrain() {
        queue.async { [weak self] in self?.drainEvents() }
    }

    private func drainEvents() {
        while let mpv, let event = mpv_wait_event(mpv, 0), event.pointee.event_id != MPV_EVENT_NONE {
            handle(event.pointee)
        }
    }

    private func handle(_ event: mpv_event) {
        switch event.event_id {
        case MPV_EVENT_PROPERTY_CHANGE:
            guard let data = event.data, Int(event.reply_userdata) < observed.count else { return }
            let property = data.assumingMemoryBound(to: mpv_event_property.self).pointee
            listener?.onProperty(name: observed[Int(event.reply_userdata)], value: MpvValue(property).string)
        case MPV_EVENT_COMMAND_REPLY, MPV_EVENT_SET_PROPERTY_REPLY:
            replies.removeValue(forKey: event.reply_userdata)?(event.error < 0 ? MpvPlayerEngine.errorString(event.error) : nil)
        case MPV_EVENT_GET_PROPERTY_REPLY:
            guard let done = reads.removeValue(forKey: event.reply_userdata) else { return }
            if event.error < 0 { return done(nil, MpvPlayerEngine.errorString(event.error)) }
            let value = event.data.map { MpvValue($0.assumingMemoryBound(to: mpv_event_property.self).pointee).string } ?? nil
            done(value, nil)
        case MPV_EVENT_FILE_LOADED:
            listener?.onFileLoaded()
        case MPV_EVENT_END_FILE:
            guard let data = event.data else { return }
            let end = data.assumingMemoryBound(to: mpv_event_end_file.self).pointee
            listener?.onEndFile(error: end.reason == MPV_END_FILE_REASON_ERROR ? MpvPlayerEngine.errorString(end.error) : nil)
        case MPV_EVENT_LOG_MESSAGE:
            guard let data = event.data else { return }
            let message = data.assumingMemoryBound(to: mpv_event_log_message.self).pointee
            let prefix = message.prefix.map(mpvString) ?? ""
            let text = (message.text.map(mpvString) ?? "").trimmingCharacters(in: .newlines)
            log.mpv(prefix: prefix, level: message.log_level, text: text)
        default:
            break
        }
    }
}

/// The wakeup callback's context: libmpv calls it on its own threads, and it only schedules a drain on the core's
/// queue. Weak, so a late callback never keeps a destroyed core alive.
private final class AudioWakeupTarget: @unchecked Sendable {
    weak var core: AppleMpvAudioCore?
    init(core: AppleMpvAudioCore) { self.core = core }
}
