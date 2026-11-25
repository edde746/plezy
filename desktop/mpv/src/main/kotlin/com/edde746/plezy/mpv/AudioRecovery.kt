package com.edde746.plezy.mpv

/**
 * When the desktop engine reloads mpv's audio output (`ao-reload`), on the mpv thread; times are milliseconds on one
 * monotonic clock.
 *
 * - The output fell back to `null` (`current-ao`: the device went away or failed) while a file is loaded, after an
 *   output had played ([setOutput]): a reload
 *   [NULL_FIRST_DELAY_MS] later, then with the wait doubling up to [NULL_BACKOFF_CAP_MS], [NULL_BUDGET] reloads in all.
 *   The outage counts as the same one while the output came back for less than [STABLE_AUDIO_MS] (a device flapping), or
 *   across files; a change of `audio-device-list` (a device plugged in) starts the budget again, [DEVICE_LIST_DEBOUNCE_MS]
 *   later. Still `null` one wait after the last reload: the engine gives up and ends the file as an audio output
 *   failure ([Action.GiveUp]).
 * - No output ever opened (a machine with no audio device; mpv tries each driver, finds none and plays to `null`):
 *   that is no outage. The file plays on without sound: no reloads, and never a give-up, also when a change of
 *   `audio-device-list` starts the reloads and none brings an output up.
 * - The system woke from sleep ([requestResume]): two reloads, [RESUME_FIRST_DELAY_MS] and then [RESUME_RETRY_DELAY_MS]
 *   later, whatever the output says (a woken device can play silence on a stale stream).
 *
 * The engine reloads synchronously, so a reload is done when [next] returns it.
 */
internal class AudioRecovery {
    sealed interface Action {
        data class Reload(val reason: String, val attempt: Int) : Action
        data object GiveUp : Action
    }

    private var fileLoaded = false
    private var outputNull = false
    private var hadOutput = false
    private var resumeRequested = false
    private var resumeAttemptsLeft = 0
    private var resumeNextAt = 0L
    private var nullAttemptsLeft = 0
    private var nullNextAt = 0L
    private var nullBackoff = 0L
    private var episodeActive = false
    private var recoveredInEpisode = false
    private var lastRecoveredAt = 0L
    private var gaveUp = false

    fun setFileLoaded(loaded: Boolean, now: Long) {
        val was = fileLoaded
        fileLoaded = loaded
        if (!loaded) {
            resumeRequested = false
            resumeAttemptsLeft = 0
            // The give-up ended this file; the next one gets its own outage.
            gaveUp = false
            return
        }
        // The budget survives the file boundary: a skip mid-outage is the same outage.
        if (!was && outputNull && hadOutput) armNull(now)
    }

    fun requestResume() {
        if (!fileLoaded) {
            resumeRequested = false
            resumeAttemptsLeft = 0
            return
        }
        resumeRequested = true
    }

    /** mpv's `current-ao` changed: [ao] is the driver in use, `null` when it fell back to none, absent before one opens. */
    fun setOutput(ao: String?, now: Long) {
        val isNull = ao == "null"
        if (ao != null && !isNull) hadOutput = true
        if (isNull == outputNull) return
        outputNull = isNull
        if (isNull) {
            if (fileLoaded && hadOutput) armNull(now)
        } else {
            lastRecoveredAt = now
            recoveredInEpisode = true
        }
    }

    fun onDeviceListChanged(now: Long) {
        if (!fileLoaded || !outputNull) return
        val candidate = now + DEVICE_LIST_DEBOUNCE_MS
        if (nullAttemptsLeft <= 0 || candidate < nullNextAt) nullNextAt = candidate
        nullAttemptsLeft = NULL_BUDGET
        nullBackoff = NULL_FIRST_DELAY_MS
        // A new device is a new outage, whatever became of the last one.
        episodeActive = true
        recoveredInEpisode = false
        gaveUp = false
    }

    /** What is due at [now], if anything. */
    fun next(now: Long): Action? {
        if (resumeRequested && fileLoaded) {
            resumeRequested = false
            resumeAttemptsLeft = RESUME_ATTEMPTS
            resumeNextAt = now + RESUME_FIRST_DELAY_MS
        }
        if (resumeAttemptsLeft > 0 && now >= resumeNextAt) {
            val attempt = RESUME_ATTEMPTS - resumeAttemptsLeft + 1
            resumeAttemptsLeft--
            resumeNextAt = now + RESUME_RETRY_DELAY_MS
            return Action.Reload("resume", attempt)
        }
        if (!nullWorkOwed()) return null
        if (now < nullNextAt) return null
        if (nullAttemptsLeft > 0) {
            val attempt = NULL_BUDGET - nullAttemptsLeft + 1
            nullAttemptsLeft--
            nullNextAt = now + nullBackoff
            nullBackoff = minOf(nullBackoff * 2, NULL_BACKOFF_CAP_MS)
            return Action.Reload("null output", attempt)
        }
        // The last reload had the same wait as every earlier one to bring a real output up.
        gaveUp = true
        episodeActive = false
        // Without an output ever, the file plays on without sound.
        return if (hadOutput) Action.GiveUp else null
    }

    /** When [next] may next have something to do, or null for nothing owed. */
    fun nextDueAt(): Long? = listOfNotNull(
        resumeNextAt.takeIf { fileLoaded && resumeAttemptsLeft > 0 },
        0L.takeIf { fileLoaded && resumeRequested },
        nullNextAt.takeIf { nullWorkOwed() },
    ).minOrNull()

    private fun nullWorkOwed() = fileLoaded && outputNull && episodeActive && !gaveUp

    private fun armNull(now: Long) {
        val sameOutage = episodeActive && (!recoveredInEpisode || now - lastRecoveredAt < STABLE_AUDIO_MS)
        if (sameOutage) {
            nullNextAt = now + nullBackoff
            return
        }
        nullAttemptsLeft = NULL_BUDGET
        nullBackoff = NULL_FIRST_DELAY_MS
        nullNextAt = now + NULL_FIRST_DELAY_MS
        episodeActive = true
        recoveredInEpisode = false
    }

    companion object {
        const val RESUME_ATTEMPTS = 2
        const val NULL_BUDGET = 5
        const val RESUME_FIRST_DELAY_MS = 1_500L
        const val RESUME_RETRY_DELAY_MS = 4_500L
        const val NULL_FIRST_DELAY_MS = 500L
        const val NULL_BACKOFF_CAP_MS = 8_000L
        const val DEVICE_LIST_DEBOUNCE_MS = 250L
        const val STABLE_AUDIO_MS = 10_000L
    }
}
