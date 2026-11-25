package com.edde746.plezy.presentation.player

import com.edde746.plezy.input.InputEvent
import com.edde746.plezy.input.InputProfile
import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.input.TouchPhase
import com.edde746.plezy.input.VideoClickAction
import kotlin.time.Duration.Companion.milliseconds

/**
 * The device's brightness and volume, in memory: [brightnessWrites] and [volumeWrites] are what the player set, in
 * order. With [deferReads] a read answers only at [answerReads], as a platform's asynchronous one does.
 */
class FakeLevels(var brightness: Double? = 0.5, var volume: Double? = 0.5) : DeviceLevels {
    val brightnessWrites = mutableListOf<Double>()
    val volumeWrites = mutableListOf<Double>()
    var restores = 0
    var deferReads = false
    private val reads = mutableListOf<() -> Unit>()

    override fun readBrightness(result: (Double?) -> Unit) = read { result(brightness) }

    override fun readVolume(result: (Double?) -> Unit) = read { result(volume) }

    override fun setBrightness(level: Double) {
        brightness = level
        brightnessWrites += level
    }

    override fun setVolume(level: Double) {
        volume = level
        volumeWrites += level
    }

    override fun restoreBrightness() {
        restores++
    }

    fun answerReads() {
        val waiting = reads.toList()
        reads.clear()
        waiting.forEach { it() }
    }

    private fun read(answer: () -> Unit) {
        if (deferReads) reads += answer else answer()
    }
}

/** The player's size in the touch tests, in dp. */
const val WIDTH = 800f
const val HEIGHT = 600f

/** Points on the player: in the forward and backward skip zones, the middle, and the brightness and volume edges. */
val FORWARD = WIDTH * 0.9f to HEIGHT / 2
val BACKWARD = WIDTH * 0.1f to HEIGHT / 2
val CENTRE = WIDTH / 2 to HEIGHT / 2

/** Where the unlock button shows, at the top centre. */
val UNLOCK_BUTTON = WIDTH / 2 to 40f

private var lastPointer = 0L

fun nextPointer(): Long = ++lastPointer

fun PlayerHarness.touch(phase: TouchPhase, pointer: Long, at: Pair<Float, Float>) =
    input(InputEvent.Touch(phase, pointer, at.first, at.second, WIDTH, HEIGHT))

/** One finger down and up where it went down. */
fun PlayerHarness.tap(at: Pair<Float, Float>) {
    val pointer = nextPointer()
    touch(TouchPhase.DOWN, pointer, at)
    touch(TouchPhase.UP, pointer, at)
}

/** Two taps 50 ms apart, which pair into a double tap. */
fun PlayerHarness.doubleTap(at: Pair<Float, Float>) {
    tap(at)
    advance(50.milliseconds)
    tap(at)
}

/** One tap, then past the double-tap window, so it acts alone. */
fun PlayerHarness.loneTap(at: Pair<Float, Float>) {
    tap(at)
    advance(400.milliseconds)
}

/** Two fingers down [spread] apart around [at], then both up. */
fun PlayerHarness.twoFingerTap(at: Pair<Float, Float> = CENTRE, spread: Float = 40f) {
    val first = nextPointer()
    val second = nextPointer()
    touch(TouchPhase.DOWN, first, at.first - spread / 2 to at.second)
    touch(TouchPhase.DOWN, second, at.first + spread / 2 to at.second)
    touch(TouchPhase.UP, first, at.first - spread / 2 to at.second)
    touch(TouchPhase.UP, second, at.first + spread / 2 to at.second)
}

/**
 * One finger down at [x], [fromY] up the player, moved to [toY] and lifted: from 400 to 316 is 84 of the 420 between
 * the top and bottom bands, a change of 0.2.
 */
fun PlayerHarness.edgeSwipe(x: Float, fromY: Float = 400f, toY: Float = 316f) {
    val pointer = nextPointer()
    touch(TouchPhase.DOWN, pointer, x to fromY)
    touch(TouchPhase.MOVE, pointer, x to toY)
    touch(TouchPhase.UP, pointer, x to toY)
}

/** A finger held still on [at] past the long-press time; [lift] lifts it. */
fun PlayerHarness.hold(at: Pair<Float, Float> = CENTRE): Long {
    val pointer = nextPointer()
    touch(TouchPhase.DOWN, pointer, at)
    advance(600.milliseconds)
    return pointer
}

fun PlayerHarness.lift(pointer: Long, at: Pair<Float, Float> = CENTRE) = touch(TouchPhase.UP, pointer, at)

/**
 * A touch-screen player playing [position] of [duration] with the controls down (the state the gestures start from),
 * a tap in the middle showing and hiding the controls as Plezy's default has it.
 */
fun touchTest(
    position: Double = 600.0,
    duration: Double = 2700.0,
    levels: DeviceLevels? = null,
    preferences: PlayerChoices = PlayerChoices(),
    body: PlayerHarness.() -> Unit,
) = playerTest(InputProfile.TOUCH, levels = levels, preferences = preferences) {
    sessionInfo { it.copy(videoClick = VideoClickAction.CONTROLS) }
    playing(position = position, duration = duration)
    dispatch(PlayerCommand.HideControls)
    check(!state.controlsVisible) { "the gestures start with the controls down" }
    body()
}
