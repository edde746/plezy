package com.edde746.plezy.music

import com.edde746.plezy.log.Log
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.Deferred
import kotlinx.coroutines.async
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.coroutines.withTimeoutOrNull
import kotlin.coroutines.cancellation.CancellationException
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TimeSource

/** What the vehicle says about driver distraction now. */
enum class CarUxRestrictionState {
    /** No answer: not a car, or the car service can't say. Callers fall back to the app being in the foreground. */
    UNKNOWN,

    /** Parked, or this display is unrestricted. */
    UNRESTRICTED,

    /** Distraction optimization is required (driving): playback must stop and stay stopped. */
    RESTRICTED,
}

/**
 * Whether playback may start (Android Automotive's driver-distraction rule, car app quality DD-2/DD-3): anywhere but a
 * car always; in a car per the vehicle's own [restrictions], or, while it can't answer, only while the app is in the
 * [foreground] (the app is as much in the background when the system covers it for driving as when a parked driver
 * opens navigation, so that is the conservative fallback).
 */
fun automotivePlaybackAllowed(isAutomotive: Boolean, foreground: Boolean, restrictions: CarUxRestrictionState): Boolean {
    if (!isAutomotive) return true
    return when (restrictions) {
        CarUxRestrictionState.RESTRICTED -> false
        CarUxRestrictionState.UNRESTRICTED -> true
        CarUxRestrictionState.UNKNOWN -> foreground
    }
}

/**
 * The vehicle's UX restrictions from the car service ([source]; null off a car, where [state] stays
 * [CarUxRestrictionState.UNKNOWN] and nothing is asked). Observing starts on the first [ensureStarted].
 *
 * Main thread; the source's callbacks may come on any thread and are applied in [scope].
 */
class CarUxRestrictions(
    private val source: CarRestrictionsSource?,
    private val scope: CoroutineScope,
    private val timeSource: TimeSource = TimeSource.Monotonic,
) {
    private val mutableState = MutableStateFlow(CarUxRestrictionState.UNKNOWN)

    /** The current verdict; [CarUxRestrictionState.UNKNOWN] until the first answer lands. */
    val state: StateFlow<CarUxRestrictionState> = mutableState.asStateFlow()

    private var started = false

    /** A deadline already blew: a call still in flight, or a promised push that never came. */
    private var stalled = false
    private val firstAnswer = CompletableDeferred<Unit>()
    private var inFlight: Deferred<Unit>? = null

    /** The car service is connected but has no verdict yet: one is coming over a push. */
    private var pendingVerdict = false

    /** Begins observing the vehicle; later calls and calls off a car do nothing. */
    fun ensureStarted() {
        val source = source ?: return
        if (started) return
        started = true
        source.setListener { pushed -> scope.launch { apply(pushed) } }
        refresh()
    }

    /** Stops observing. */
    fun close() {
        if (started) source?.setListener(null)
    }

    /**
     * Waits for a definitive answer, asking once more when the vehicle answered without one. [timeout] is the whole
     * budget, not per attempt: a car service that never answers must not hold up playback, and a deadline that blew
     * once isn't waited out again (the platform is still asked, which is how it retries its own connection).
     */
    suspend fun ensureResolved(timeout: Duration = 2.seconds) {
        if (source == null) return
        ensureStarted()
        if (mutableState.value != CarUxRestrictionState.UNKNOWN) return
        if (stalled) {
            refresh()
            return
        }
        val budget = timeSource.markNow()
        if (!firstAnswer.isCompleted) {
            withTimeoutOrNull(timeout) { firstAnswer.await() }
            if (!firstAnswer.isCompleted) {
                stalled = true
                return
            }
            if (mutableState.value != CarUxRestrictionState.UNKNOWN) return
        }

        // The answer was "no verdict": a car service that wasn't ready at startup can still connect.
        var remaining = timeout - budget.elapsedNow()
        if (remaining <= Duration.ZERO) return
        if (withTimeoutOrNull(remaining) { refresh().await() } == null) {
            stalled = true
            return
        }
        if (mutableState.value != CarUxRestrictionState.UNKNOWN) return

        // Connected to the car service, which hasn't been handed a verdict yet: it comes over a push.
        if (!pendingVerdict) return
        remaining = timeout - budget.elapsedNow()
        if (remaining <= Duration.ZERO) return
        withTimeoutOrNull(remaining) { mutableState.first { it != CarUxRestrictionState.UNKNOWN } }
        if (mutableState.value == CarUxRestrictionState.UNKNOWN) stalled = true
    }

    private fun refresh(): Deferred<Unit> {
        inFlight?.let { return it }
        val read = scope.async(start = CoroutineStart.UNDISPATCHED) {
            try {
                val answer = CompletableDeferred<CarRestrictionState?>()
                checkNotNull(source).currentState { answer.complete(it) }
                apply(answer.await())
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "Failed to read car UX restrictions" }
            } finally {
                inFlight = null
                firstAnswer.complete(Unit)
            }
        }
        if (!read.isCompleted) inFlight = read
        return read
    }

    private fun apply(answer: CarRestrictionState?) {
        if (answer == null || !answer.supported) {
            pendingVerdict = answer != null && answer.pending
            // Losing a verdict means the platform is alive and talking: waiting out the reconnect is worth a budget.
            if (mutableState.value != CarUxRestrictionState.UNKNOWN) stalled = false
            mutableState.value = CarUxRestrictionState.UNKNOWN
            return
        }
        pendingVerdict = false
        stalled = false
        val next = if (answer.requiresDistractionOptimization) CarUxRestrictionState.RESTRICTED else CarUxRestrictionState.UNRESTRICTED
        if (mutableState.value != next) Log.d(TAG) { "Car UX restrictions: $next" }
        mutableState.value = next
    }

    private companion object {
        const val TAG = "CarUxRestrictions"
    }
}
