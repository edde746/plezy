package com.edde746.plezy.ui.crash

import com.edde746.plezy.crash.CrashCapture
import com.edde746.plezy.crash.CrashFilter
import com.edde746.plezy.crash.CrashReport
import com.edde746.plezy.crash.NativeCrash
import com.edde746.plezy.crash.CrashReports
import io.sentry.ScopeCallback
import io.sentry.SentryLevel
import io.sentry.protocol.DebugImage
import io.sentry.protocol.DebugMeta
import io.sentry.protocol.Mechanism
import io.sentry.protocol.Message
import io.sentry.protocol.SentryException
import io.sentry.protocol.SentryId
import io.sentry.protocol.SentryStackFrame
import io.sentry.protocol.SentryStackTrace
import io.sentry.Breadcrumb
import io.sentry.Sentry
import io.sentry.SentryEvent
import io.sentry.SentryOptions
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch

/**
 * Crash reports through Sentry's Java SDK, on Android (sentry-android, whose NDK part also catches native crashes, as
 * libmpv's) and the desktop (sentry-java). [follow] starts the SDK while [CrashReports.active] has a DSN and closes it
 * when it has none. Only crashes and the exceptions the shared core survived ([CrashReports.failures], as error events)
 * are reported: no sessions, tracing, profiling, replays, client reports or logs, and every event and breadcrumb
 * passes [CrashReportScrubber] before it is kept or sent.
 */
object SentryReports {
    /**
     * Calls [start] (the platform's `SentryAndroid.init` or `Sentry.init`, given what to set on its options) each time
     * [reports] turns on, and closes Sentry each time it turns off, and sends each of [CrashReports.failures], until
     * [scope] ends.
     */
    fun follow(reports: CrashReports, scope: CoroutineScope, start: (configure: (SentryOptions) -> Unit) -> Unit): Job =
        scope.launch {
            // The DSN Sentry runs with: set once [start] returned for it, null once Sentry closed.
            val running = MutableStateFlow<String?>(null)
            launch {
                reports.failures.collect { failure ->
                    // One that comes as reports turn on waits for Sentry to start (before, Sentry drops it); one that
                    // comes as they turn off goes unsent.
                    if (running.value != reports.active.value) combine(running, reports.active) { ran, on -> ran == on }.first { it }
                    if (running.value != null) capture(CrashReport.of(failure))
                }
            }
            reports.active.collect { dsn ->
                CrashCapture.sink = null
                CrashCapture.breadcrumbs = null
                if (dsn == null) {
                    Sentry.close()
                } else {
                    start { options -> configure(options, dsn, reports) }
                    CrashCapture.sink = CrashCapture.Sink(::capture)
                    CrashCapture.breadcrumbs = CrashCapture.BreadcrumbSink(::addBreadcrumb)
                }
                running.value = dsn
            }
        }

    /** [report] as a Sentry event; whether Sentry took it (a non-empty id: not dropped, not off). */
    internal fun capture(report: CrashReport): Boolean {
        val level = when (report.level) {
            CrashReport.Level.WARNING -> SentryLevel.WARNING
            CrashReport.Level.ERROR -> SentryLevel.ERROR
            CrashReport.Level.FATAL -> SentryLevel.FATAL
        }
        val scoped = ScopeCallback { scope ->
            scope.level = level
            report.tags.forEach(scope::setTag)
            report.contexts.forEach { (name, values) -> scope.setContexts(name, values) }
            report.fingerprint?.let { scope.fingerprint = it }
        }
        val error = report.error
        val native = report.nativeCrash
        val id = when {
            error != null -> Sentry.captureException(error, scoped)
            native != null -> Sentry.captureEvent(nativeEvent(native, report.message, level), scoped)
            else -> Sentry.captureMessage(report.message.orEmpty(), level, scoped)
        }
        return id != SentryId.EMPTY_ID
    }

    /**
     * [crash] as a native event: one unhandled exception whose stack the tracker symbolicates (frames oldest first, each
     * at its instruction address) with the debug files of [NativeCrash.images], listed as the event's debug images.
     */
    internal fun nativeEvent(crash: NativeCrash, message: String?, level: SentryLevel): SentryEvent = SentryEvent().apply {
        this.level = level
        platform = "native"
        message?.let { text -> this.message = Message().apply { this.message = text } }
        exceptions = listOf(
            SentryException().apply {
                type = crash.type
                value = crash.value
                mechanism = Mechanism().apply {
                    type = "signalhandler"
                    isHandled = false
                }
                stacktrace = SentryStackTrace(
                    crash.frames.asReversed().map { frame ->
                        SentryStackFrame().apply {
                            platform = "native"
                            instructionAddr = frame.instructionAddress?.let(::hex)
                            `package` = frame.module
                            function = frame.function
                        }
                    },
                )
            },
        )
        debugMeta = DebugMeta().apply {
            images = crash.images.map { image ->
                DebugImage().apply {
                    type = image.kind
                    codeFile = image.codeFile
                    imageAddr = hex(image.imageAddress)
                    imageSize = image.imageSize
                    debugId = image.debugId
                    codeId = image.codeId
                    debugFile = image.debugFile
                }
            }
        }
    }

    private fun hex(address: Long): String = "0x" + address.toULong().toString(16)

    /** [breadcrumb] on Sentry's trail, scrubbed by its `beforeBreadcrumb`. */
    internal fun addBreadcrumb(breadcrumb: com.edde746.plezy.crash.Breadcrumb) {
        Sentry.addBreadcrumb(
            Breadcrumb().apply {
                category = breadcrumb.category
                message = breadcrumb.message
                level = if (breadcrumb.warning) SentryLevel.WARNING else SentryLevel.INFO
                breadcrumb.data.forEach { (key, value) -> setData(key, value) }
            },
        )
    }

    /**
     * The options every platform reports with: [dsn], [CrashReports.releaseName] and [CrashReports.channel], no
     * personal data, no sessions, tracing or client reports, and the scrubber, which also drops an event that comes
     * once [reports] is off.
     */
    fun configure(options: SentryOptions, dsn: String, reports: CrashReports) {
        options.dsn = dsn
        options.release = reports.releaseName
        options.environment = reports.channel.environment
        reports.channel.dist?.let { options.dist = it }
        options.isSendDefaultPii = false
        // The JVM prints an uncaught exception's stack trace when no handler is set; Sentry's handler does so too.
        options.isPrintUncaughtStackTrace = true
        options.isAttachServerName = false
        options.isEnableAutoSessionTracking = false
        options.isSendClientReports = false
        options.isSendModules = false
        options.isEnableUserInteractionBreadcrumbs = false
        options.tracesSampleRate = null
        val scrubber = CrashReportScrubber(System.getProperty("user.home"))
        options.beforeSend = SentryOptions.BeforeSendCallback { event, _ ->
            when {
                reports.active.value == null -> null
                event.exceptions.orEmpty().any { CrashFilter.drops(it.type, it.value) } -> null
                else -> {
                    event.throwable?.let(CrashFilter::timeoutTags)?.let { (tags, fingerprint) ->
                        tags.forEach(event::setTag)
                        event.fingerprints = fingerprint
                    }
                    scrubber.event(event)
                }
            }
        }
        options.beforeBreadcrumb = SentryOptions.BeforeBreadcrumbCallback { breadcrumb, _ -> scrubber.breadcrumb(breadcrumb) }
    }
}

/**
 * What a crash report may hold. No user (Sentry's Android SDK puts an installation id there, and an IP would go
 * there), no device id or name, app hash, host name or request. Every free text, exception messages, the message,
 * thread names (also in the trace context's data), a native crash's library paths (its frames' and debug images'),
 * tags, extras and breadcrumbs' messages and data, passes
 * [CrashReports.scrub]: the user's [home] directory becomes `~`, and URLs keep only their origin (media server URLs
 * carry access tokens in their paths and queries) and keys go. HTTP breadcrumbs lose their URL, query and fragment altogether.
 */
class CrashReportScrubber(private val home: String?) {
    fun event(event: SentryEvent): SentryEvent {
        event.user = null
        event.serverName = null
        event.request = null
        event.contexts.device?.id = null
        event.contexts.device?.name = null
        event.contexts.app?.deviceAppHash = null
        event.message?.let { message ->
            message.formatted = message.formatted?.let(::text)
            message.message = message.message?.let(::text)
            message.params = message.params?.map(::text)
        }
        event.logger = event.logger?.let(::text)
        event.transaction = event.transaction?.let(::text)
        event.exceptions?.forEach { exception ->
            exception.value = exception.value?.let(::text)
            exception.stacktrace?.frames?.forEach { it.`package` = it.`package`?.let(::text) }
        }
        event.debugMeta?.images?.forEach { image ->
            image.codeFile = image.codeFile?.let(::text)
            image.debugFile = image.debugFile?.let(::text)
        }
        event.threads?.forEach { it.name = it.name?.let(::text) }
        event.contexts.trace?.let { trace ->
            trace.description = trace.description?.let(::text)
            trace.data?.toList()?.forEach { (key, value) -> if (value is String) trace.setData(key, text(value)) }
        }
        event.tags = event.tags?.mapValuesTo(LinkedHashMap()) { (_, value) -> text(value) }
        event.extras = event.extras?.mapValuesTo(LinkedHashMap()) { (_, value) -> if (value is String) text(value) else value }
        event.breadcrumbs?.forEach(::breadcrumb)
        return event
    }

    fun breadcrumb(breadcrumb: Breadcrumb): Breadcrumb {
        breadcrumb.message = breadcrumb.message?.let(::text)
        if (breadcrumb.type == "http" || breadcrumb.category?.startsWith("http") == true) HTTP_URL_KEYS.forEach(breadcrumb::removeData)
        for ((key, value) in breadcrumb.data.toList()) if (value is String) breadcrumb.setData(key, text(value))
        return breadcrumb
    }

    private fun text(value: String): String = CrashReports.scrub(value, home)

    private companion object {
        val HTTP_URL_KEYS = listOf("url", "http.query", "http.fragment")
    }
}
