package com.edde746.plezy.presentation.player

import com.edde746.plezy.input.InputEvent
import com.edde746.plezy.input.TouchPhase
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlin.math.abs
import kotlin.math.hypot
import kotlin.math.max
import kotlin.math.min
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.TimeMark
import kotlin.time.TimeSource

/**
 * The fingers on the video of a touch screen ([InputEvent.Touch]), told apart into the player's gestures:
 *
 * - Skip zones: a tap in the left or right [SKIP_ZONE] of the player (outside the top and bottom [SKIP_BAND]) waits
 *   [DOUBLE_TAP]; a second tap in the same zone within it is a double tap, which skips, and otherwise the first acts
 *   alone. Every skip takes a fresh pair of taps: a stream of taps pairs into one skip per two. A tap in the middle acts
 *   at once.
 * - A finger held still [LONG_PRESS] plays at 2× until it lifts; an edge swipe ends it.
 * - Two fingers tapped together ([TwoFingerTapTracker]) toggle playback at once; taps are ignored for [TAP_SUPPRESSION]
 *   after any two-finger contact or edge swipe, so neither leaves a stray tap behind.
 * - Two fingers apart pinch the picture's zoom.
 * - A swipe up or down the left edge sets the screen's brightness, the right edge the system's volume
 *   ([EdgeSwipeTracker]), from the level read as the finger went down (waiting up to [BASELINE_WAIT] for it), writing
 *   the device at most every [WRITE_INTERVAL] and by [WRITE_STEP] at least; the level shows until [LEVEL_HIDE] after it
 *   ends.
 * - Locked, a tap shows or hides the unlock button, and a contact with a second finger counts for nothing but hiding it.
 *
 * Distances are in the units of the touches (dp, points). After [release] nothing acts.
 */
internal class TouchGestures(
    private val scope: CoroutineScope,
    private val timeSource: TimeSource,
    private val actions: PlayerStore.TouchHooks,
) {
    private class Finger(val startX: Float, val startY: Float, val down: TimeMark) {
        var x = startX
        var y = startY
    }

    /** One contact: from the first finger down to the last up. */
    private class Contact(val down: TimeMark) {
        var multiTouch = false
        var moved = false

        /** Something else took the contact: it is no tap (a finger on the unlock button). */
        var taken = false
    }

    private val fingers = LinkedHashMap<Long, Finger>()
    private var contact: Contact? = null
    private var width = 0f
    private var height = 0f
    private var released = false

    private val twoFinger = TwoFingerTapTracker(timeSource)
    private val edge = EdgeSwipeTracker()

    private var suppressTapsUntil: TimeMark? = null
    private var pendingTap: Job? = null
    private var pendingForward = false

    private var longPressJob: Job? = null
    private var holding = false

    private var pinchPair: Pair<Long, Long>? = null
    private var pinchStart = 0f

    // The edge swipe: the levels last read or written, the read under way, the swipe waiting for its baseline, and
    // the one under way.
    private val known = HashMap<LevelKind, Double>()
    private var readGeneration = 0
    private var reading: LevelKind? = null
    private var waiting: LevelKind? = null
    private var waitingDelta = 0.0
    private var waitJob: Job? = null
    private var swipe: LevelKind? = null
    private var swipeStart = 0.0
    private var lastWrite: TimeMark? = null
    private var lastWritten: Double? = null
    private var levelShown = false
    private var hideLevelJob: Job? = null

    fun on(event: InputEvent.Touch) {
        if (released) return
        width = event.width
        height = event.height
        when (event.phase) {
            TouchPhase.DOWN -> down(event.pointer, event.x, event.y)
            TouchPhase.MOVE -> move(event.pointer, event.x, event.y)
            TouchPhase.UP -> up(event.pointer, event.x, event.y)
            TouchPhase.CANCEL -> cancel(event.pointer)
        }
    }

    /**
     * A finger or a pointer went down on the unlock button: true unless a finger's contact is no lone finger still
     * where it went down; that finger then is no tap on the locked screen. [unlockHoldIntact] says whether it still
     * holds. A pointer has no contact here: always true.
     */
    fun takeUnlockHold(): Boolean {
        val contact = contact ?: return true
        if (contact.multiTouch || contact.moved || contact.taken) return false
        contact.taken = true
        return true
    }

    /** A finger is on the screen. */
    val fingerDown: Boolean get() = contact != null

    /** The finger that went down on the unlock button is still down, alone and where it went down. */
    fun unlockHoldIntact(): Boolean {
        val contact = contact ?: return false
        return !contact.multiTouch && !contact.moved
    }

    /** The screen locked: whatever a finger was doing stops (a hold gives its speed back). */
    fun stop() {
        cancelSwipe()
        twoFinger.reset()
        endPinch()
        pendingTap?.cancel()
        pendingTap = null
        cancelLongPress()
        contact?.taken = true
    }

    /**
     * The player opened or came back into sight: the remembered brightness, if any, and then the levels a swipe
     * starts from.
     */
    fun refresh(remembered: Double?) {
        val levels = actions.levels ?: return
        if (remembered != null) {
            levels.setBrightness(remembered)
            known[LevelKind.BRIGHTNESS] = remembered
        }
        read(LevelKind.BRIGHTNESS)
        read(LevelKind.VOLUME)
    }

    fun release() {
        released = true
        pendingTap?.cancel()
        longPressJob?.cancel()
        waitJob?.cancel()
        hideLevelJob?.cancel()
    }

    // Fingers

    private fun down(pointer: Long, x: Float, y: Float) {
        if (fingers.isEmpty()) contact = Contact(timeSource.markNow())
        fingers[pointer] = Finger(x, y, timeSource.markNow())
        val contact = contact ?: return
        if (fingers.size > 1) {
            contact.multiTouch = true
            cancelLongPressTimer()
        }
        if (actions.locked) {
            if (contact.multiTouch) actions.lockedMultiTouch()
            return
        }
        twoFinger.pointerDown(pointer, x, y)
        if (twoFinger.chordActive) {
            suppressTaps()
            cancelSwipe()
            if (fingers.size == 2 && actions.gesturesAllowed) startPinch()
            return
        }
        onEdge(if (actions.gesturesAllowed) edge.pointerDown(pointer, x, y, width, height, actions::edgeEnabled) else EdgeEvent.None)
        if (fingers.size == 1 && actions.zonesActive) {
            longPressJob = scope.launch {
                delay(LONG_PRESS)
                longPressJob = null
                if (contact.moved || contact.multiTouch || contact.taken || swipe != null || waiting != null) return@launch
                holding = true
                actions.hold(true)
            }
        }
    }

    private fun move(pointer: Long, x: Float, y: Float) {
        val finger = fingers[pointer] ?: return
        finger.x = x
        finger.y = y
        val contact = contact ?: return
        if (hypot(x - finger.startX, y - finger.startY) > TAP_SLOP) {
            contact.moved = true
            cancelLongPressTimer()
        }
        if (actions.locked) return
        twoFinger.pointerMove(pointer, x, y)
        if (twoFinger.chordActive) {
            suppressTaps()
            cancelSwipe()
            pinchMoved()
            return
        }
        if (!actions.gesturesAllowed) {
            cancelSwipe()
            return
        }
        onEdge(edge.pointerMove(pointer, x, y))
    }

    private fun up(pointer: Long, x: Float, y: Float) {
        val finger = fingers.remove(pointer) ?: return
        finger.x = x
        finger.y = y
        val contact = contact ?: return
        if (actions.locked) {
            if (fingers.isEmpty()) {
                this.contact = null
                if (!contact.multiTouch && !contact.moved && !contact.taken && !held(contact)) actions.lockedTap()
            }
            return
        }
        val twoFingerTap = twoFinger.pointerUp(pointer, x, y)
        onEdge(edge.pointerUp(pointer, y))
        if (tapsSuppressed() || twoFingerTap) suppressTaps()
        if (twoFingerTap && actions.gesturesAllowed) actions.twoFingerTap()
        if (pinchPair?.let { pointer == it.first || pointer == it.second } == true) endPinch()
        if (fingers.isNotEmpty()) return
        this.contact = null
        cancelLongPressTimer()
        when {
            holding -> {
                holding = false
                actions.hold(false)
            }
            contact.multiTouch || contact.moved || contact.taken || tapsSuppressed() -> Unit
            else -> tap(x, y)
        }
    }

    private fun cancel(pointer: Long) {
        fingers.remove(pointer) ?: return
        val contact = contact ?: return
        contact.moved = true
        if (fingers.isEmpty()) this.contact = null
        cancelLongPressTimer()
        if (actions.locked) return
        twoFinger.pointerCancel(pointer)
        onEdge(edge.pointerCancel(pointer))
        if (twoFinger.chordActive) suppressTaps()
        if (pinchPair?.let { pointer == it.first || pointer == it.second } == true) endPinch()
        if (fingers.isEmpty() && holding) {
            holding = false
            actions.hold(false)
        }
    }

    private fun held(contact: Contact): Boolean = contact.down.elapsedNow() >= LONG_PRESS

    // Taps

    private fun tap(x: Float, y: Float) {
        val forward = if (actions.zonesActive) skipZone(x, y, width, height) else null
        if (forward == null) {
            actions.tap(centre = true)
            return
        }
        // The tap waiting in the window is resolved either way: paired into a skip, or replaced by this one.
        val pairs = pendingTap != null && pendingForward == forward
        pendingTap?.cancel()
        pendingTap = null
        if (pairs) {
            actions.skip(forward)
            return
        }
        pendingForward = forward
        pendingTap = scope.launch {
            delay(DOUBLE_TAP)
            pendingTap = null
            actions.tap(centre = false)
        }
    }

    private fun suppressTaps() {
        pendingTap?.cancel()
        pendingTap = null
        suppressTapsUntil = timeSource.markNow() + TAP_SUPPRESSION
    }

    private fun tapsSuppressed(): Boolean = suppressTapsUntil?.hasPassedNow() == false

    // Holds

    private fun cancelLongPressTimer() {
        longPressJob?.cancel()
        longPressJob = null
    }

    private fun cancelLongPress() {
        cancelLongPressTimer()
        if (holding) {
            holding = false
            actions.hold(false)
        }
    }

    // Pinches

    private fun startPinch() {
        val (first, second) = fingers.keys.take(2)
        pinchPair = first to second
        pinchStart = spread(first, second)
    }

    private fun pinchMoved() {
        val (first, second) = pinchPair ?: return
        if (pinchStart <= 0f || !actions.gesturesAllowed) return
        actions.pinch((spread(first, second) / pinchStart).toDouble())
    }

    private fun endPinch() {
        if (pinchPair == null) return
        pinchPair = null
        actions.pinchEnd()
    }

    private fun spread(first: Long, second: Long): Float {
        val a = fingers[first] ?: return 0f
        val b = fingers[second] ?: return 0f
        return hypot(a.x - b.x, a.y - b.y)
    }

    // Edge swipes

    private fun onEdge(event: EdgeEvent) {
        when (event) {
            EdgeEvent.None -> Unit
            is EdgeEvent.Candidate -> read(event.kind)
            is EdgeEvent.Activated -> beginSwipe(event.kind, event.delta)
            is EdgeEvent.Update -> when {
                waiting == event.kind -> waitingDelta = event.delta
                swipe == event.kind -> updateSwipe(event.kind, event.delta, force = false)
            }
            is EdgeEvent.Ended -> if (waiting != null) {
                stopWaiting()
                finishSwipe(suppressTaps = false)
            } else {
                val active = swipe
                if (active == event.kind) updateSwipe(active, event.delta, force = true)
                finishSwipe(suppressTaps = active != null)
            }
            is EdgeEvent.Cancelled -> {
                stopWaiting()
                finishSwipe(suppressTaps = event.wasActive || swipe != null)
            }
        }
    }

    private fun cancelSwipe() = onEdge(edge.cancel())

    private fun read(kind: LevelKind) {
        val levels = actions.levels ?: return
        val generation = ++readGeneration
        reading = kind
        val done: (Double?) -> Unit = { value ->
            if (!released) {
                if (value != null) known[kind] = value
                if (generation == readGeneration) reading = null
                if (waiting == kind) resolveWaiting(kind)
            }
        }
        when (kind) {
            LevelKind.BRIGHTNESS -> levels.readBrightness(done)
            LevelKind.VOLUME -> levels.readVolume(done)
        }
    }

    private fun beginSwipe(kind: LevelKind, delta: Double) {
        val start = known[kind]
        if (start != null) {
            startSwipe(kind, delta, start)
            return
        }
        // The level isn't known yet: wait for its read a little, then give up.
        suppressTaps()
        cancelLongPress()
        waiting = kind
        waitingDelta = delta
        waitJob = scope.launch {
            delay(BASELINE_WAIT)
            waitJob = null
            resolveWaiting(kind)
        }
        if (reading != kind) read(kind)
    }

    private fun resolveWaiting(kind: LevelKind) {
        if (waiting != kind) return
        val delta = waitingDelta
        stopWaiting()
        val start = known[kind]
        if (start == null) finishSwipe(suppressTaps = false) else startSwipe(kind, delta, start)
    }

    private fun stopWaiting() {
        waiting = null
        waitingDelta = 0.0
        waitJob?.cancel()
        waitJob = null
    }

    private fun startSwipe(kind: LevelKind, delta: Double, start: Double) {
        suppressTaps()
        cancelLongPress()
        hideLevelJob?.cancel()
        swipe = kind
        swipeStart = start
        lastWrite = null
        lastWritten = null
        actions.swipeStarted()
        updateSwipe(kind, delta, force = true)
    }

    private fun updateSwipe(kind: LevelKind, delta: Double, force: Boolean) {
        val value = (swipeStart + delta).coerceIn(0.0, 1.0)
        levelShown = true
        actions.level(kind, value)
        val last = lastWritten
        val changed = last == null || abs(value - last) >= WRITE_STEP
        val due = lastWrite?.let { it.elapsedNow() >= WRITE_INTERVAL } ?: true
        if (!force && (!changed || !due)) return
        lastWrite = timeSource.markNow()
        lastWritten = value
        known[kind] = value
        val levels = actions.levels ?: return
        when (kind) {
            LevelKind.BRIGHTNESS -> levels.setBrightness(value)
            LevelKind.VOLUME -> levels.setVolume(value)
        }
    }

    private fun finishSwipe(suppressTaps: Boolean) {
        if (suppressTaps) suppressTaps()
        val ended = swipe
        swipe = null
        lastWrite = null
        lastWritten = null
        if (ended != null) actions.swipeEnded(if (ended == LevelKind.BRIGHTNESS) known[LevelKind.BRIGHTNESS] else null)
        hideLevelJob?.cancel()
        if (!levelShown) return
        hideLevelJob = scope.launch {
            delay(LEVEL_HIDE)
            levelShown = false
            actions.hideLevel()
        }
    }

    companion object {
        /** A finger moving further than this is no tap or hold (the platforms' touch slop). */
        const val TAP_SLOP = 18f
        val LONG_PRESS = 500.milliseconds
        val DOUBLE_TAP = 300.milliseconds
        val TAP_SUPPRESSION = DOUBLE_TAP + 80.milliseconds
        val BASELINE_WAIT = 300.milliseconds
        val WRITE_INTERVAL = 45.milliseconds
        const val WRITE_STEP = 0.01
        val LEVEL_HIDE = 700.milliseconds

        /** Each skip zone's share of the player's width, and the bands at the top and bottom outside the zones. */
        const val SKIP_ZONE = 0.35f
        const val SKIP_BAND = 0.15f
    }
}

/** The skip zone a tap at ([x], [y]) on a player [width] by [height] lands in: forward (true), back, or none (null). */
internal fun skipZone(x: Float, y: Float, width: Float, height: Float): Boolean? {
    if (!inZoneBand(y, height)) return null
    val zone = width * TouchGestures.SKIP_ZONE
    return when {
        x < zone -> false
        x > width - zone -> true
        else -> null
    }
}

/** How wide each edge's swipe zone is: 14 % of the player's width, within 48 to 96 and at most half of it. */
internal fun edgeZoneWidth(width: Float): Float = min(max(48f, min(width * 0.14f, 96f)), width / 2)

/** The edge a finger at ([x], [y]) is on: the left's brightness, the right's volume, or none (null). */
internal fun edgeZone(x: Float, y: Float, width: Float, height: Float): LevelKind? {
    if (!inZoneBand(y, height)) return null
    val zone = edgeZoneWidth(width)
    return when {
        x < zone -> LevelKind.BRIGHTNESS
        x > width - zone -> LevelKind.VOLUME
        else -> null
    }
}

private fun inZoneBand(y: Float, height: Float): Boolean {
    val band = height * TouchGestures.SKIP_BAND
    return y > band && y < height - band
}

/**
 * A two-finger tap from raw touches: it arms when exactly two fingers are down and completes as the last lifts within
 * [timeout] of the first finger's down, none of them having moved past [slop]. A third finger, a cancelled one or a
 * move past the slop (a pinch, even one back where it started) undoes it. There is no double two-finger tap: each tap
 * stands alone, at once.
 */
internal class TwoFingerTapTracker(
    private val timeSource: TimeSource,
    private val timeout: Duration = 300.milliseconds,
    private val slop: Float = 100f,
) {
    private class Touch(val x: Float, val y: Float, val down: TimeMark)

    private val touches = LinkedHashMap<Long, Touch>()
    private var start: TimeMark? = null
    private var armed = false
    private var invalid = false

    /** Two fingers are down, or a two-finger tap is under way. */
    val chordActive: Boolean get() = touches.size > 1 || armed

    fun pointerDown(pointer: Long, x: Float, y: Float) {
        touches[pointer] = Touch(x, y, timeSource.markNow())
        if (touches.size == 2) {
            armed = true
            invalid = false
            start = touches.values.maxBy { it.down.elapsedNow() }.down
        } else if (touches.size > 2) {
            invalid = true
        }
    }

    fun pointerMove(pointer: Long, x: Float, y: Float) {
        val touch = touches[pointer] ?: return
        if (hypot(x - touch.x, y - touch.y) > slop) invalid = true
    }

    /** True when this lift completes a two-finger tap. */
    fun pointerUp(pointer: Long, x: Float, y: Float): Boolean {
        pointerMove(pointer, x, y)
        touches.remove(pointer) ?: return false
        if (touches.isNotEmpty()) return false
        val tap = armed && !invalid && start?.let { it.elapsedNow() <= timeout } == true
        clear()
        return tap
    }

    fun pointerCancel(pointer: Long) {
        touches.remove(pointer)
        invalid = true
        if (touches.isEmpty()) clear()
    }

    /** Forgets every finger: the touch was taken elsewhere (the screen locked). */
    fun reset() {
        touches.clear()
        clear()
    }

    private fun clear() {
        start = null
        armed = false
        invalid = false
    }
}

/** What a finger did to an edge swipe ([EdgeSwipeTracker]). [delta] is the level's change, up positive. */
internal sealed interface EdgeEvent {
    data object None : EdgeEvent
    data class Candidate(val kind: LevelKind) : EdgeEvent
    data class Activated(val kind: LevelKind, val delta: Double) : EdgeEvent
    data class Update(val kind: LevelKind, val delta: Double) : EdgeEvent
    data class Ended(val kind: LevelKind, val delta: Double) : EdgeEvent
    data class Cancelled(val kind: LevelKind?, val wasActive: Boolean) : EdgeEvent
}

/**
 * A swipe up or down an edge of the player ([edgeZone]), from raw touches. A finger going down on an enabled edge is
 * a candidate; it activates once it has moved [slop] up or down and more than [dominance] times as far as across, and
 * a move clearly across first cancels it. The change is the way it moved up over the player's height between the top
 * and bottom bands. A second finger cancels it, and nothing starts again until every finger is up; a finger on a
 * disabled edge isn't tracked but still counts as one.
 */
internal class EdgeSwipeTracker(private val slop: Float = TouchGestures.TAP_SLOP, private val dominance: Float = 1.5f) {
    private val pointers = HashSet<Long>()
    private var tracked: Long? = null
    private var startY = 0f
    private var startX = 0f
    private var height = 0f
    private var kind: LevelKind? = null
    private var blocked = false

    var active = false
        private set

    fun pointerDown(pointer: Long, x: Float, y: Float, width: Float, height: Float, enabled: (LevelKind) -> Boolean): EdgeEvent {
        pointers += pointer
        if (blocked) return EdgeEvent.None
        if (pointers.size > 1) return cancelTracking(block = true)
        if (tracked != null) return EdgeEvent.None
        val kind = edgeZone(x, y, width, height)
        if (kind == null || !enabled(kind)) return EdgeEvent.None
        tracked = pointer
        startX = x
        startY = y
        this.height = height
        this.kind = kind
        active = false
        return EdgeEvent.Candidate(kind)
    }

    fun pointerMove(pointer: Long, x: Float, y: Float): EdgeEvent {
        if (pointer != tracked) return EdgeEvent.None
        val kind = kind ?: return EdgeEvent.None
        if (active) return EdgeEvent.Update(kind, delta(y))
        val dx = abs(x - startX)
        val dy = abs(y - startY)
        if (dx >= slop && dx > dy * dominance) return cancelTracking(block = true)
        if (dy < slop) return EdgeEvent.None
        if (dy <= dx * dominance) return cancelTracking(block = true)
        active = true
        return EdgeEvent.Activated(kind, delta(y))
    }

    fun pointerUp(pointer: Long, y: Float): EdgeEvent {
        pointers -= pointer
        if (pointers.isEmpty()) blocked = false
        if (pointer != tracked) return EdgeEvent.None
        val kind = kind
        val wasActive = active
        val delta = if (wasActive) delta(y) else 0.0
        reset()
        return if (wasActive && kind != null) EdgeEvent.Ended(kind, delta) else EdgeEvent.None
    }

    fun pointerCancel(pointer: Long): EdgeEvent {
        pointers -= pointer
        if (pointers.isEmpty()) blocked = false
        if (pointer != tracked) return EdgeEvent.None
        return cancelTracking(block = pointers.isNotEmpty())
    }

    /** Ends a swipe from outside (the screen locked, gestures went off); every finger starts over. */
    fun cancel(): EdgeEvent {
        val event = cancelTracking(block = false)
        pointers.clear()
        blocked = false
        return event
    }

    private fun cancelTracking(block: Boolean): EdgeEvent {
        val kind = kind
        val hadTracking = tracked != null
        val wasActive = active
        reset()
        if (block && pointers.isNotEmpty()) blocked = true
        return if (hadTracking) EdgeEvent.Cancelled(kind, wasActive) else EdgeEvent.None
    }

    private fun delta(y: Float): Double = ((startY - y) / max(1f, height * (1 - 2 * TouchGestures.SKIP_BAND))).toDouble()

    private fun reset() {
        tracked = null
        kind = null
        active = false
    }
}
