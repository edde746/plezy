import Foundation
import Sentry
import PlezyKit

/// Crash reports to Sentry. The SDK runs while the shared gate has a DSN (`CrashReports.active`: this device's setting
/// is on, and the release build, or a dev session's setting, has one) and is closed while it has none. Closing removes
/// its crash handler too, so a crash while the setting is off leaves no report on disk for a later launch to send.
///
/// Kotlin exceptions nothing caught reach the same crash handler: the shared hook (`UncaughtKotlinExceptions.record`)
/// hands each over as an Objective-C exception whose return addresses are the Kotlin throw site's, and the handler
/// records it as it records an uncaught Objective-C exception, before Kotlin/Native ends the process. The report is
/// sent at the next launch with the setting on, its Kotlin frames symbolicated from the app's dSYM (PlezyKit is
/// linked into the app's binary).
///
/// The Kotlin exceptions the app survived (`CrashReports.failures`: a coroutine of the product that threw, which the
/// shared failure boundary logged and the app ran on after) go out at once as error events, their stacks the Kotlin
/// throw site's, symbolicated as a crash's.
///
/// Every event is scrubbed before it leaves (`scrubbed`): no user, no device id, no request, and every free text and
/// path through the shared `CrashReports.scrub` (addon and stream URLs keep only their origin, keys and ids go, the home
/// folder becomes `~`).
enum CrashReporting {
    /// Follows the gate for the rest of the process.
    @MainActor
    static func follow(_ crashReports: CrashReports) async {
        let gate = UncheckedBox(crashReports)
        Task { for await failure in gate.value.failures { _ = capture(CrashReport.companion.of(error: failure)) } }
        for await dsn in crashReports.active {
            CrashCapture.shared.sink = nil
            CrashCapture.shared.breadcrumbs = nil
            if SentrySDK.isEnabled { SentrySDK.close() }
            if let dsn {
                start(dsn: dsn, crashReports: gate)
                CrashCapture.shared.sink = SentrySink()
                CrashCapture.shared.breadcrumbs = SentryBreadcrumbs()
            }
        }
    }

    @MainActor
    private static func start(dsn: String, crashReports: UncheckedBox<CrashReports>) {
        SentrySDK.start { options in configure(options, dsn: dsn, crashReports: crashReports) }
        recordKotlinCrashes()
    }

    /// Off the main actor: Sentry calls `beforeSend` on its own queues.
    nonisolated private static func configure(_ options: Options, dsn: String, crashReports: UncheckedBox<CrashReports>) {
        let gate = crashReports.value
        options.dsn = dsn
        options.releaseName = gate.releaseName
        options.environment = gate.channel.environment
        if let dist = gate.channel.dist { options.dist = dist }
        options.sendDefaultPii = false
        // Crashes, app hangs and the Kotlin exceptions the app survived only: no sessions, request breadcrumbs, failed
        // requests or client reports (tracing is off without a sample rate).
        options.enableAutoSessionTracking = false
        options.enableNetworkBreadcrumbs = false
        options.enableCaptureFailedRequests = false
        options.sendClientReports = false
        #if DEBUG
        // A Debug build's main thread stalls under the debugger and the UI tests: hangs are a release build's to report.
        options.enableAppHangTracking = false
        #endif
        // A hang is a main thread stalled 3 s, as the earlier releases reported (the SDK's default is 2 s).
        options.appHangTimeoutInterval = 3
        let home = NSHomeDirectory()
        options.beforeSend = { event in
            // The setting turned off after the event was made: nothing leaves.
            guard crashReports.value.active.value != nil else { return nil }
            if (event.exceptions ?? []).contains(where: { CrashFilter.shared.drops(type: $0.type, value: $0.value) }) { return nil }
            return scrubbed(event, home: home)
        }
    }

    /// Each Kotlin exception nothing caught goes to the uncaught exception handler, the crash handler's while the SDK
    /// runs, with the Kotlin throw site's return addresses as its stack.
    nonisolated private static func recordKotlinCrashes() {
        UncaughtKotlinExceptions.shared.record { uncaught in
            NSGetUncaughtExceptionHandler()?(KotlinException(uncaught))
        }
    }

    /// A report the shared code made (`CrashReport`): a Kotlin exception the app survived, as an error event whose
    /// stack is the Kotlin throw site's (oldest frame first, as Sentry orders them), or a message; with its level,
    /// tags, contexts and fingerprint. Whether Sentry took it: it drops everything while it isn't running.
    nonisolated static func capture(_ report: CrashReport) -> Bool {
        let level: SentryLevel = switch report.level {
        case .warning: .warning
        case .fatal: .fatal
        default: .error
        }
        let event = Event(level: level)
        if let failure = report.error {
            let kotlin = KotlinExceptionReport.companion.of(throwable: failure)
            let frames = kotlin.returnAddresses.reversed().map { address in
                let frame = Frame()
                frame.instructionAddress = String(format: "0x%016llx", UInt64(bitPattern: address.int64Value))
                return frame
            }
            let stacktrace = SentryStacktrace(frames: frames, registers: [:])
            let thread = SentryThread(threadId: NSNumber(value: 0))
            thread.stacktrace = stacktrace
            thread.current = NSNumber(value: true)
            let mechanism = Mechanism(type: "coroutine")
            mechanism.handled = NSNumber(value: true)
            let exception = Exception(value: kotlin.reason, type: kotlin.name)
            exception.mechanism = mechanism
            exception.stacktrace = stacktrace
            exception.threadId = thread.threadId
            event.exceptions = [exception]
            // The thread names the binary images the frames are in, so the event carries them for symbolication.
            event.threads = [thread]
        } else {
            event.message = SentryMessage(formatted: report.message ?? "")
        }
        if !report.tags.isEmpty { event.tags = report.tags }
        if !report.contexts.isEmpty {
            var contexts = event.context ?? [:]
            for (name, values) in report.contexts { contexts[name] = values }
            event.context = contexts
        }
        if let fingerprint = report.fingerprint { event.fingerprint = fingerprint }
        return SentrySDK.capture(event: event) != SentryId.empty
    }

    /// The event as it may leave the device.
    nonisolated static func scrubbed(_ event: Event, home: String) -> Event {
        func scrub(_ text: String) -> String { CrashReports.companion.scrub(text: text, home: home) }
        event.user = nil
        event.serverName = nil
        event.request = nil
        if let message = event.message {
            let clean = SentryMessage(formatted: scrub(message.formatted))
            clean.message = message.message.map(scrub)
            clean.params = message.params?.map(scrub)
            event.message = clean
        }
        for exception in event.exceptions ?? [] {
            exception.value = exception.value.map(scrub)
            exception.mechanism?.desc = exception.mechanism?.desc.map(scrub)
            scrubFrames(exception.stacktrace, scrub)
        }
        for thread in event.threads ?? [] {
            thread.name = thread.name.map(scrub)
            scrubFrames(thread.stacktrace, scrub)
        }
        scrubFrames(event.stacktrace, scrub)
        for image in event.debugMeta ?? [] {
            image.codeFile = image.codeFile.map(scrub)
        }
        for breadcrumb in event.breadcrumbs ?? [] {
            breadcrumb.message = breadcrumb.message.map(scrub)
            var data = breadcrumb.data?.mapValues { ($0 as? String).map(scrub) ?? $0 }
            if breadcrumb.type?.hasPrefix("http") == true || breadcrumb.category.hasPrefix("http") {
                for key in ["url", "http.query", "http.fragment"] { data?[key] = nil }
            }
            breadcrumb.data = data
        }
        event.tags = event.tags?.mapValues(scrub)
        event.extra = event.extra?.mapValues { ($0 as? String).map(scrub) ?? $0 }
        // The trace context's description and data (which may name the thread).
        if var trace = event.context?["trace"] {
            trace["description"] = (trace["description"] as? String).map(scrub)
            trace["data"] = (trace["data"] as? [String: Any])?.mapValues { ($0 as? String).map(scrub) ?? $0 }
            event.context?["trace"] = trace
        }
        // A hash of the device's id and the app's, the device's id and its name.
        event.context?["app"]?["device_app_hash"] = nil
        event.context?["device"]?["id"] = nil
        event.context?["device"]?["name"] = nil
        return event
    }

    nonisolated private static func scrubFrames(_ stacktrace: SentryStacktrace?, _ scrub: (String) -> String) {
        for frame in stacktrace?.frames ?? [] {
            frame.package = frame.package.map(scrub)
            frame.fileName = frame.fileName.map(scrub)
        }
    }
}

/// A Kotlin exception nothing caught, as the uncaught exception handler takes it: the Kotlin class as its name, the
/// message (and causes) as its reason, and the Kotlin throw site's return addresses as its stack, which the crash
/// handler records instead of the current thread's.
private final class KotlinException: NSException, @unchecked Sendable {
    private let addresses: [NSNumber]

    init(_ uncaught: KotlinExceptionReport) {
        addresses = uncaught.returnAddresses.map { NSNumber(value: UInt64(bitPattern: $0.int64Value)) }
        super.init(name: NSExceptionName(uncaught.name), reason: uncaught.reason, userInfo: nil)
    }

    required init?(coder: NSCoder) { nil }

    override var callStackReturnAddresses: [NSNumber] { addresses }
}

/// The running Sentry as the shared code's way to the crash reporter (`CrashCapture.sink`).
private final class SentrySink: CrashCaptureSink {
    func capture(report: CrashReport) -> Bool { CrashReporting.capture(report) }
}

/// The running Sentry's trail as the shared code's (`CrashCapture.breadcrumbs`).
private final class SentryBreadcrumbs: CrashCaptureBreadcrumbSink {
    func add(breadcrumb: PlezyKit.Breadcrumb) {
        let crumb = Sentry.Breadcrumb(level: breadcrumb.warning ? .warning : .info, category: breadcrumb.category)
        crumb.message = breadcrumb.message
        if !breadcrumb.data.isEmpty { crumb.data = breadcrumb.data }
        SentrySDK.addBreadcrumb(crumb)
    }
}
