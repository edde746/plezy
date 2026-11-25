package com.edde746.plezy.downloads

import com.edde746.plezy.log.Log
import kotlin.time.Clock
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds
import kotlin.time.Instant
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.drop
import kotlinx.coroutines.launch

/**
 * Why background downloads are expected to fail on this device. [id] is the reader's wire id; the order is how
 * actionable the remedy is, and [BackgroundWorkStatus.reasons] keeps the order the reader reports.
 */
enum class BackgroundWorkReason(val id: String) {
    /** The per-app "Restricted" background usage (Samsung's sleeping apps land here too). */
    BACKGROUND_RESTRICTED("background_restricted"),

    /** The app standby bucket is RESTRICTED or NEVER: work is deferred indefinitely. */
    STANDBY_RESTRICTED("standby_restricted"),

    /** The downloads' notification channel is muted, which removes the foreground anchor of a transfer. */
    DOWNLOAD_CHANNEL_BLOCKED("download_channel_blocked"),

    /** Notifications are off app-wide. */
    NOTIFICATIONS_DISABLED("notifications_disabled"),

    /** Data Saver blocks metered background traffic. */
    DATA_SAVER("data_saver"),

    /**
     * No restriction the OS admits to, but downloads repeatedly made no progress while the app was in the background
     * (OEMs that stop background work while reporting a clean bucket).
     */
    OEM_UNKNOWN("oem_unknown"),
    ;

    companion object {
        fun fromId(id: String): BackgroundWorkReason? = entries.firstOrNull { it.id == id }
    }
}

/** How bad the detected restrictions are. */
enum class BackgroundWorkVerdict {
    /** Nothing detected, or the platform can't tell. */
    OK,

    /** Downloads run, but not under every network condition. */
    DEGRADED,

    /** Downloads are expected to stall as soon as the app leaves the foreground. */
    BLOCKED,
}

/** The system settings screen a remedy opens; [id] is the reader's wire id. */
enum class BackgroundSettingsTarget(val id: String) {
    APP_DETAILS("app_details"),
    APP_NOTIFICATIONS("app_notifications"),
    NOTIFICATION_CHANNEL("notification_channel"),
}

/**
 * One probe's result. [probed] is false before the first probe lands (and on every platform without a reader), so
 * "healthy" and "never asked" differ.
 */
data class BackgroundWorkStatus(
    val verdict: BackgroundWorkVerdict = BackgroundWorkVerdict.OK,
    val reasons: List<BackgroundWorkReason> = emptyList(),
    val standbyBucket: Int? = null,
    val ignoringBatteryOptimizations: Boolean? = null,
    val probed: Boolean = false,
) {
    val isBlocked: Boolean get() = verdict == BackgroundWorkVerdict.BLOCKED
    val isHealthy: Boolean get() = verdict == BackgroundWorkVerdict.OK

    /** The reason a one-line summary leads with. */
    val primaryReason: BackgroundWorkReason? get() = reasons.firstOrNull()

    /** The settings screen that best addresses [primaryReason]. */
    val remedyTarget: BackgroundSettingsTarget
        get() = when (primaryReason) {
            BackgroundWorkReason.NOTIFICATIONS_DISABLED -> BackgroundSettingsTarget.APP_NOTIFICATIONS
            BackgroundWorkReason.DOWNLOAD_CHANNEL_BLOCKED -> BackgroundSettingsTarget.NOTIFICATION_CHANNEL
            else -> BackgroundSettingsTarget.APP_DETAILS
        }

    /** This status with [reason] added, which makes it blocked. */
    fun withReason(reason: BackgroundWorkReason): BackgroundWorkStatus =
        if (reason in reasons) this else copy(verdict = BackgroundWorkVerdict.BLOCKED, reasons = reasons + reason)

    /** The compact form a log upload's header carries. */
    fun describe(): String {
        if (!probed) return "unknown"
        return listOfNotNull(
            verdict.name.lowercase(),
            reasons.takeIf { it.isNotEmpty() }?.joinToString("+") { it.id },
            standbyBucket?.let { "bucket:$it" },
            ignoringBatteryOptimizations?.let { "batteryWhitelist:$it" },
        ).joinToString(" ")
    }
}

/** What [DownloadStallDetector] compares: the activity as the app went to the background and as it came back. */
data class DownloadStallObservation(
    val paused: DownloadActivitySnapshot,
    val resumed: DownloadActivitySnapshot,
    val backgroundGap: Duration,
)

/**
 * Detects OEMs that stop background work while reporting a clean standby bucket, by watching whether downloads
 * advance while the app is in the background. [observationsToConfirm] stalled trips in a row confirm it, so one network
 * blip can't raise a warning.
 *
 * @param minimumBackgroundGap shorter trips prove nothing: the OS grants a grace period before deferring work.
 * @param minimumProgressBytes less than this is indistinguishable from a buffer flush.
 */
class DownloadStallDetector(
    val minimumBackgroundGap: Duration = 60.seconds,
    val minimumProgressBytes: Long = 64L * 1024,
    val observationsToConfirm: Int = 2,
) {
    private var pausedSnapshot: DownloadActivitySnapshot? = null
    private var pausedAt: Instant? = null

    var consecutiveStalls: Int = 0
        private set

    val isStalled: Boolean get() = consecutiveStalls >= observationsToConfirm

    /** Arms the detector as the app leaves the foreground; only while something downloads. */
    fun onPaused(snapshot: DownloadActivitySnapshot, at: Instant) {
        if (snapshot.activeTasks <= 0) {
            clearArmedSnapshot()
            return
        }
        pausedSnapshot = snapshot
        pausedAt = at
    }

    /**
     * Captures the state as the app comes back, before any suspending work could let later progress leak into this
     * observation. Null when the detector wasn't armed.
     */
    fun captureResumed(snapshot: DownloadActivitySnapshot, at: Instant): DownloadStallObservation? {
        val paused = pausedSnapshot
        val pausedAt = pausedAt
        clearArmedSnapshot()
        if (paused == null || pausedAt == null) return null
        return DownloadStallObservation(paused, snapshot, at - pausedAt)
    }

    /**
     * Scores a captured background trip; true only when this trip just confirmed a repeated stall. [networkAvailable]:
     * the network and the download policy allowed downloads at resume.
     */
    fun evaluate(observation: DownloadStallObservation?, networkAvailable: Boolean): Boolean {
        if (observation == null) return false
        val paused = observation.paused
        val resumed = observation.resumed

        val completedInBackground = resumed.completedTasks > paused.completedTasks
        val byteDelta = resumed.downloadedBytes - paused.downloadedBytes
        val progressDelta = resumed.progressUnits - paused.progressUnits

        // Real progress clears earlier evidence; a completion may report no bytes, so each counts on its own.
        if (completedInBackground || byteDelta >= minimumProgressBytes || progressDelta > 0) {
            consecutiveStalls = 0
            return false
        }
        // Removed rows and other counters going back are no evidence of a stall.
        if (byteDelta < 0 || progressDelta < 0) return false
        if (observation.backgroundGap < minimumBackgroundGap) return false
        // Known-good endpoints, no network transition in the window, and a policy that allows downloads at resume.
        if (!networkAvailable ||
            paused.networkAvailable != true ||
            resumed.networkAvailable != true ||
            resumed.networkStateGeneration != paused.networkStateGeneration
        ) {
            return false
        }
        // A paused, cancelled or removed task is no evidence; a failed one is.
        if (resumed.activeTasks < paused.activeTasks && resumed.failedTasks <= paused.failedTasks) return false

        val wasConfirmed = isStalled
        consecutiveStalls++
        return !wasConfirmed && isStalled
    }

    fun reset() {
        clearArmedSnapshot()
        consecutiveStalls = 0
    }

    private fun clearArmedSnapshot() {
        pausedSnapshot = null
        pausedAt = null
    }
}

/** The OS side of [BackgroundWorkDiagnosticsService]: Android's reader of its background-work signals. */
interface BackgroundWorkProbe {
    /**
     * The OS's signals: `verdict` (`ok`, `degraded`, `blocked`), `reasons` (reason ids, most actionable first),
     * `standbyBucket` (Int) and `ignoringBatteryOptimizations` (Boolean), plus the raw signals; null when the OS gave
     * no answer. Throws [UnsupportedOperationException] when this build has no reader.
     */
    suspend fun backgroundWorkSignals(): Map<String, Any?>?

    /** Opens the settings screen [target] names; false when the device has none. */
    suspend fun openBackgroundSettings(target: BackgroundSettingsTarget): Boolean
}

/**
 * Probes the OS for reasons background downloads won't run, and watches for the symptom on OEMs that don't admit to it
 * ([DownloadStallDetector], scored on each return to the foreground while an activity source is bound).
 *
 * Every failure resolves to [BackgroundWorkVerdict.OK]: a warning that can't be substantiated trains users to ignore
 * the ones that can. [isSupported] is Android phones and tablets: TV boxes run on mains power, and mobile battery and
 * data restrictions there are noise.
 *
 * @param foreground whether the app is in the foreground; its changes after [bindActivitySource] arm and score the
 *   stall detector.
 * @param networkProbe whether the network and the download policy allow downloads now; an unknown answer is false.
 */
class BackgroundWorkDiagnosticsService(
    private val probe: BackgroundWorkProbe,
    val isSupported: Boolean,
    private val foreground: StateFlow<Boolean>,
    private val networkProbe: suspend () -> Boolean,
    private val scope: CoroutineScope,
    private val stallDetector: DownloadStallDetector = DownloadStallDetector(),
    private val clock: Clock = Clock.System,
) {
    private val mutableStatus = MutableStateFlow(BackgroundWorkStatus())

    /** The current status; it changes only when the verdict, reasons or signals do. */
    val status: StateFlow<BackgroundWorkStatus> = mutableStatus.asStateFlow()

    private var lastProbedStatus = BackgroundWorkStatus()
    private var activitySource: (() -> DownloadActivitySnapshot)? = null
    private var inFlightRefresh: CompletableDeferred<Unit>? = null
    private var observing: Job? = null
    private var probeMissing = false
    private var closed = false

    /** Lets the download layer publish its aggregate activity, and probes for the cold start. */
    fun bindActivitySource(source: () -> DownloadActivitySnapshot) {
        activitySource = source
        startObserving()
        scope.launch { refresh() }
    }

    fun unbindActivitySource(source: () -> DownloadActivitySnapshot) {
        if (activitySource === source) activitySource = null
    }

    private fun startObserving() {
        if (observing != null || !isSupported || closed) return
        observing = scope.launch {
            foreground.drop(1).collect { onForegroundChanged(it) }
        }
    }

    /** Probes the OS again; concurrent calls share one probe. */
    suspend fun refresh(): BackgroundWorkStatus {
        if (!isSupported || probeMissing || closed) return status.value
        inFlightRefresh?.let {
            it.await()
            return status.value
        }
        val done = CompletableDeferred<Unit>()
        inFlightRefresh = done
        try {
            probeNow()
        } finally {
            if (inFlightRefresh === done) inFlightRefresh = null
            done.complete(Unit)
        }
        return status.value
    }

    private suspend fun probeNow() {
        val raw = try {
            probe.backgroundWorkSignals()
        } catch (e: CancellationException) {
            throw e
        } catch (_: UnsupportedOperationException) {
            // A build without the reader: never warn on a signal that couldn't be read, and stop asking.
            probeMissing = true
            return
        } catch (e: Exception) {
            Log.d(TAG, e) { "Background work probe failed" }
            return
        }
        if (closed || raw == null) return
        lastProbedStatus = parse(raw)
        applyCurrentStatus()
    }

    private fun parse(raw: Map<String, Any?>): BackgroundWorkStatus {
        val verdict = when (raw["verdict"]) {
            "blocked" -> BackgroundWorkVerdict.BLOCKED
            "degraded" -> BackgroundWorkVerdict.DEGRADED
            else -> BackgroundWorkVerdict.OK
        }
        // oem_unknown is this service's own conclusion, never the reader's.
        val reasons = (raw["reasons"] as? List<*>).orEmpty()
            .mapNotNull { (it as? String)?.let(BackgroundWorkReason::fromId) }
            .filter { it != BackgroundWorkReason.OEM_UNKNOWN }
        return BackgroundWorkStatus(
            // A verdict without a reason this build knows can't be explained to the user, so it doesn't count.
            verdict = if (reasons.isEmpty()) BackgroundWorkVerdict.OK else verdict,
            reasons = reasons,
            standbyBucket = raw["standbyBucket"] as? Int,
            ignoringBatteryOptimizations = raw["ignoringBatteryOptimizations"] as? Boolean,
            probed = true,
        )
    }

    private fun applyCurrentStatus() {
        if (closed) return
        // A confirmed stall outlives every probe: the OS keeps reporting healthy on exactly the devices it catches.
        val next = if (stallDetector.isStalled) lastProbedStatus.withReason(BackgroundWorkReason.OEM_UNKNOWN) else lastProbedStatus
        val previous = mutableStatus.value
        if (next == previous) return
        mutableStatus.value = next
        if (previous.verdict != next.verdict || previous.reasons != next.reasons) {
            Log.i(TAG) { "Background work status: ${next.describe()}" }
        }
    }

    /** Opens the settings screen [target] names; false when the device has none, so the caller can say so. */
    suspend fun openSettings(target: BackgroundSettingsTarget): Boolean {
        if (!isSupported) return false
        return try {
            probe.openBackgroundSettings(target)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "Opening background settings failed" }
            false
        }
    }

    /** Drops a confirmed stall once the user says they fixed it, and probes again. */
    suspend fun clearStallEvidence() {
        if (closed) return
        stallDetector.reset()
        applyCurrentStatus()
        refresh()
    }

    internal fun onForegroundChanged(inForeground: Boolean) {
        val source = activitySource
        if (!inForeground) {
            if (source != null) stallDetector.onPaused(source(), clock.now())
            return
        }
        val observation = source?.let { stallDetector.captureResumed(it(), clock.now()) }
        scope.launch { onResumed(observation) }
    }

    private suspend fun onResumed(observation: DownloadStallObservation?) {
        if (observation != null) {
            val networkAvailable = try {
                networkProbe()
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                // Unknown connectivity is inconclusive, not proof of a stall.
                Log.d(TAG, e) { "Network check for stall scoring failed" }
                false
            }
            if (closed) return
            val wasStalled = stallDetector.isStalled
            val confirmed = stallDetector.evaluate(observation, networkAvailable)
            if (wasStalled && !stallDetector.isStalled) applyCurrentStatus()
            if (confirmed) {
                Log.w(TAG) {
                    "Background downloads made no progress across ${stallDetector.observationsToConfirm} background periods; " +
                        "treating it as an OEM background restriction"
                }
            }
        }
        refresh()
    }

    /** Stops observing; a probe still in flight is ignored when it lands. */
    fun close() {
        closed = true
        observing?.cancel()
        observing = null
    }

    private companion object {
        const val TAG = "BackgroundWork"
    }
}
