package com.edde746.plezy.presentation.player

import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals

/** [KeepAwakeController]: one platform call at a time, settling on the latest request; failures are not retried. */
class KeepAwakeControllerTest {
    @Test
    fun drainsEnableThenDisableWithoutOverlappingPlatformWork() = runTest {
        val platform = ControlledToggle()
        val controller = KeepAwakeController(this, platform::call)

        val enable = async { controller.setEnabled(true) }
        runCurrent()
        assertEquals(listOf(true), platform.calls)

        val disable = async { controller.setEnabled(false) }
        runCurrent()
        assertEquals(listOf(true), platform.calls)
        assertEquals(1, platform.maxConcurrent)

        platform.succeedNext()
        runCurrent()
        assertEquals(listOf(true, false), platform.calls)

        platform.succeedNext()
        listOf(enable, disable).awaitAll()

        assertEquals(listOf(true, false), platform.completed)
        assertEquals(0, platform.active)
        assertEquals(1, platform.maxConcurrent)
    }

    @Test
    fun drainsDisableThenEnableToTheLatestDesiredState() = runTest {
        val platform = ControlledToggle()
        val controller = KeepAwakeController(this, platform::call)

        val initialEnable = async { controller.setEnabled(true) }
        runCurrent()
        platform.succeedNext()
        initialEnable.await()

        val disable = async { controller.setEnabled(false) }
        runCurrent()
        assertEquals(listOf(true, false), platform.calls)

        val enable = async { controller.setEnabled(true) }
        runCurrent()
        assertEquals(listOf(true, false), platform.calls)

        platform.succeedNext()
        runCurrent()
        assertEquals(listOf(true, false, true), platform.calls)

        platform.succeedNext()
        listOf(disable, enable).awaitAll()

        assertEquals(listOf(true, false, true), platform.completed)
        assertEquals(1, platform.maxConcurrent)
    }

    @Test
    fun absorbsAcquisitionFailureAndRetriesOnlyWhenRequested() = runTest {
        var calls = 0
        val controller = KeepAwakeController(this) { enabled ->
            calls++
            assertEquals(true, enabled)
            if (calls == 1) throw IllegalStateException("enable failed")
        }

        controller.setEnabled(true)
        runCurrent()
        assertEquals(1, calls, "a failure must not start an automatic retry loop")

        controller.setEnabled(true)
        assertEquals(2, calls, "the failed state must remain explicitly retryable")

        controller.setEnabled(true)
        assertEquals(2, calls, "only successful platform work becomes effective")
    }

    @Test
    fun appliesANewerOpposingRequestAfterAcquisitionFails() = runTest {
        val platform = ControlledToggle()
        val controller = KeepAwakeController(this, platform::call)

        val enable = async { controller.setEnabled(true) }
        runCurrent()
        val disable = async { controller.setEnabled(false) }

        platform.failNext(IllegalStateException("enable failed"))
        runCurrent()
        assertEquals(listOf(true, false), platform.calls)
        assertEquals(1, platform.maxConcurrent)

        platform.succeedNext()
        listOf(enable, disable).awaitAll()

        assertEquals(listOf(false), platform.completed)
        assertEquals(0, platform.active)
    }

    @Test
    fun keepsEffectiveStateAfterReleaseFailureAndRetriesDisable() = runTest {
        var disableAttempts = 0
        val calls = mutableListOf<Boolean>()
        val controller = KeepAwakeController(this) { enabled ->
            calls += enabled
            if (!enabled && disableAttempts++ == 0) throw IllegalStateException("disable failed")
        }

        controller.setEnabled(true)
        controller.setEnabled(false)
        assertEquals(listOf(true, false), calls)

        controller.setEnabled(false)
        assertEquals(listOf(true, false, false), calls)

        controller.setEnabled(false)
        assertEquals(listOf(true, false, false), calls)
    }

    @Test
    fun detachedTeardownDisableDrainsAfterAnInFlightEnable() = runTest {
        val platform = ControlledToggle()
        val controller = KeepAwakeController(this, platform::call)

        val enable = async { controller.setEnabled(true) }
        runCurrent()
        controller.request(false)

        platform.succeedNext()
        runCurrent()
        assertEquals(listOf(true, false), platform.calls)

        platform.succeedNext()
        enable.await()
        runCurrent()

        assertEquals(listOf(true, false), platform.completed)
        assertEquals(0, platform.active)
        assertEquals(1, platform.maxConcurrent)
    }

    @Test
    fun followsThePlayersKeepAwakeAndLetsTheDisplaySleepOnRelease() = runTest {
        val calls = mutableListOf<Boolean>()
        val controller = KeepAwakeController(backgroundScope) { calls += it }
        val state = MutableStateFlow(false)
        controller.followAwake(state)
        runCurrent()
        state.value = true
        runCurrent()
        state.value = false
        runCurrent()
        state.value = true
        runCurrent()
        controller.release()
        runCurrent()
        assertEquals(listOf(false, true, false, true, false), calls, "the first state is applied too: nothing is known held before it")
    }

    private class ControlledToggle {
        val calls = mutableListOf<Boolean>()
        val completed = mutableListOf<Boolean>()
        private val pending = ArrayDeque<CompletableDeferred<Unit>>()
        var active = 0
        var maxConcurrent = 0

        suspend fun call(enabled: Boolean) {
            calls += enabled
            active++
            if (active > maxConcurrent) maxConcurrent = active
            val done = CompletableDeferred<Unit>()
            pending.addLast(done)
            try {
                done.await()
                completed += enabled
            } finally {
                active--
            }
        }

        fun succeedNext() {
            pending.removeFirst().complete(Unit)
        }

        fun failNext(error: Throwable) {
            pending.removeFirst().completeExceptionally(error)
        }
    }
}
