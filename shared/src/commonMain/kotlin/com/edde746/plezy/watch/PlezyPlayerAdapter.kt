package com.edde746.plezy.watch

import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Job
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.joinAll
import kotlinx.coroutines.selects.select
import party.openwatch.PlayerAdapter
import kotlin.math.abs
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TimeSource

/** Where a file opens: the engine's load of it ([loadId]) and its start ([positionMs]), before the player reports them. */
internal data class WatchFileStart(val loadId: Long, val positionMs: Long)

/**
 * Plezy's player behind the Open Watch Party SDK: one adapter per opened file, attached with the [copy] that file is.
 *
 * Reads come from the player once it reports the file ([start]'s load showed its first frame); until then the file
 * reads as opening at its start, at the copy's length, not ready, so a host shares where the file opens rather than
 * where the engine still is. Commands finish when the player has done them; a seek first waits until the player takes
 * seeks in this file (mpv refuses one while it still opens the file) and then until it lands. Once [release]d, every
 * command and wait returns at once, so the party's release completes and the player can go.
 *
 * @param timeSource measures the landing waits; tests pass their scheduler's.
 * @param start the open of [copy]'s file the player may not report yet; null when it does.
 */
internal class PlezyPlayerAdapter(
    val player: RoomPlayer,
    val copy: WatchCopy,
    private val timeSource: TimeSource = TimeSource.Monotonic,
    start: WatchFileStart? = null,
) : PlayerAdapter {
    private val released = CompletableDeferred<Unit>()
    private val holds = mutableSetOf<Job>()
    private var opening: WatchFileStart? = start

    val isReleased: Boolean get() = released.isCompleted

    /** Ends every wait and makes later commands return at once. */
    fun release() {
        released.complete(Unit)
    }

    /**
     * Holds the room off until [until] completes, however it completes: the player reads as not ready, so the room
     * waits, and commands wait for every hold. Used while the player still prepares the file or drives itself (a
     * reload, a display-mode switch).
     */
    fun hold(until: Job) {
        if (until.isCompleted) return
        holds += until
        until.invokeOnCompletion { holds -= until }
    }

    /** Whether a [hold] is pending. */
    val isHeld: Boolean get() = holds.isNotEmpty()

    /** The player opened this file again (a reload of it) at [start]: it reads as opening until that load shows a frame. */
    fun reopened(start: WatchFileStart) {
        opening = start
    }

    /** The player reports this file: no open of it is pending, or the pending one's load showed its first frame. */
    private val reporting: Boolean
        get() {
            val pending = opening ?: return true
            if (player.loadId != pending.loadId || !player.renderedFrame) return false
            opening = null
            return true
        }

    /** The player has this file's load, though maybe without a frame yet. */
    private val onFile: Boolean get() = opening?.let { it.loadId == player.loadId } ?: true

    private val usable: Boolean get() = !isReleased && !player.disposed

    override val positionMs: Long get() = if (reporting) player.positionMs else opening?.positionMs ?: player.positionMs

    override val durationMs: Long? get() = player.durationMs?.takeIf { it > 0 && reporting } ?: copy.durationMs

    override val paused: Boolean get() = !player.playing

    override val buffering: Boolean get() = player.buffering

    override val firstFrameShown: Boolean get() = holds.isEmpty() && player.renderedFrame && reporting

    override val canSetRate: Boolean get() = !player.audioPassthrough

    /**
     * mpv's absolute seeks land where asked, so 0 while the file can seek. A file that shows frames but
     * can't seek (a stream without an index) would otherwise be sought again every couple of seconds.
     */
    override val seekAccuracyMs: Long get() = if (player.renderedFrame && reporting && !player.seekable) CANNOT_SEEK_ACCURACY_MS else 0

    override suspend fun play() {
        if (!ready()) return
        orReleased { player.play() }
    }

    override suspend fun pause() {
        if (!ready()) return
        orReleased { player.pause() }
    }

    override suspend fun setRate(rate: Double) {
        if (!ready()) return
        orReleased { player.setRate(rate) }
    }

    override suspend fun seek(positionMs: Long) {
        if (!ready()) return
        // mpv refuses a seek while it opens the file, and the file's own first frame would then pass for the landing.
        if (!until { onFile && (player.seekable || player.renderedFrame) }) return
        val restarts = player.restarts
        orReleased { player.seek(positionMs) }
        val issued = timeSource.markNow()
        until {
            player.restarts > restarts ||
                (issued.elapsedNow() >= LANDING_GRACE && !player.buffering && abs(player.positionMs - positionMs) <= LANDED_WITHIN_MS)
        }
    }

    /** [command], or nothing once released: it may wait on a player that is going away. A refusal still throws. */
    private suspend fun orReleased(command: suspend () -> Unit) {
        if (isReleased) return
        coroutineScope {
            val work = async { command() }
            select {
                work.onAwait {}
                released.onAwait { work.cancel() }
            }
        }
    }

    /** Waits out every hold; false when released meanwhile or the player is gone. */
    private suspend fun ready(): Boolean {
        while (holds.isNotEmpty() && !isReleased) {
            val pending = holds.toList()
            orReleased { pending.joinAll() }
        }
        return usable
    }

    /** Polls [done] until it holds, the adapter is released or [LANDING_TIMEOUT] passes. False only when unusable. */
    private suspend fun until(done: () -> Boolean): Boolean {
        val start = timeSource.markNow()
        while (usable && !done() && start.elapsedNow() < LANDING_TIMEOUT) {
            orReleased { delay(POLL) }
        }
        return usable
    }

    companion object {
        /** The longest a seek waits for the player to take seeks, and then to land. */
        val LANDING_TIMEOUT = 10.seconds
        private val POLL = 50.milliseconds

        /** A position near the target counts as landed only this long after the seek, so the old one doesn't. */
        private val LANDING_GRACE = 300.milliseconds
        private const val LANDED_WITHIN_MS = 1000L

        /** The seek accuracy of a file that can't seek: longer than any file, so the room follows it by rate only. */
        const val CANNOT_SEEK_ACCURACY_MS = 604_800_000L
    }
}
