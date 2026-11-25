@file:OptIn(kotlinx.coroutines.ExperimentalCoroutinesApi::class)

package com.edde746.plezy.playback.output

import com.edde746.plezy.data.settings.DeviceSettings
import com.edde746.plezy.data.settings.DolbyVisionConversion
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.playback.DynamicRange
import com.edde746.plezy.playback.EngineState
import com.edde746.plezy.playback.ServerStream
import com.edde746.plezy.playback.VideoInfo
import kotlinx.coroutines.async
import kotlinx.coroutines.launch
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * One playback's output: the settings' plan first, then one plan per item at its first frame (the rate measured once),
 * again on fullscreen and settings changes; the first frame held while the display is negotiated for it, a newer item
 * abandoning an older negotiation; the display restored at the end.
 */
class PlaybackOutputTest {
    private val modes = listOf(60.0, 23.976, 24.0, 50.0).mapIndexed { i, rate -> DisplayMode(i + 1, 3840, 2160, rate) }

    /** A host whose switches wait for [settle] to be completed (one per apply) when it asks for one. */
    private class Host(private val modes: List<DisplayMode>) : PlaybackOutputHost {
        val plans = mutableListOf<OutputPlan>()
        var restores = 0
        var displayReads = 0
        var settle: CompletableDeferred<Unit>? = null
        var switchesFirst = false
        /** What the engine answers the next plans' HDR output: taken unless a test refuses it. */
        var hdrTaken = true
        override val switchesBeforeOpen get() = switchesFirst

        /** The decoder hold the host offers, if any; [holdsAsked] counts the asks. */
        var hold: Hold? = null
        var holdsAsked = 0

        override fun holdDecoder(): DecoderHold? {
            holdsAsked++
            return hold
        }

        override suspend fun display(): DisplayInfo {
            displayReads++
            return DisplayInfo(modes, modes.first(), hdrSupported = true, hdrEnabled = false)
        }

        override suspend fun apply(plan: OutputPlan): Boolean {
            plans += plan
            settle?.await()
            return hdrTaken
        }

        override fun restore() {
            restores++
        }
    }

    /** An engine's decoder hold: the file's declared video once [declared] completes. */
    private class Hold : DecoderHold {
        val declared = CompletableDeferred<VideoInfo?>()
        var released = false

        override suspend fun video(): VideoInfo? = declared.await()

        override fun release() {
            released = true
        }
    }

    private class Fixture(scope: TestScope, modes: List<DisplayMode>, settings: DeviceSettings, formFactor: FormFactor) {
        val engine = MutableStateFlow(EngineState())
        val fullscreen = MutableStateFlow(false)
        val settings = MutableStateFlow(settings)
        val host = Host(modes)
        val output = PlaybackOutput(engine, fullscreen, formFactor, this.settings, host, scope.backgroundScope)

        init {
            scope.runCurrent()
        }

        /** Item [loadId]'s first frame is up with its video at [fps]. */
        fun firstFrame(loadId: Long, fps: Double?, range: DynamicRange = DynamicRange.SDR) = engine.update {
            it.copy(loadId = loadId, loaded = true, video = VideoInfo(3840, 2160, "hevc", fps, range))
        }

        fun load(loadId: Long) = engine.update { it.copy(loadId = loadId, loaded = false) }
    }

    private fun outputTest(
        settings: DeviceSettings = DeviceSettings.DEFAULT.copy(matchFrameRate = true, audioPassthrough = true),
        formFactor: FormFactor = FormFactor.TV,
        body: suspend Fixture.(TestScope) -> Unit,
    ) = runTest { Fixture(this, modes, settings, formFactor).body(this) }

    @Test
    fun beforeTheOpenATvSwitchesForTheServersRateAndItsFirstFrameFindsTheModeThere() = outputTest { scope ->
        host.switchesFirst = true
        val settle = CompletableDeferred<Unit>()
        host.settle = settle
        val open = scope.launch { output.preOpen(ServerStream(transcode = false, frameRate = 23.976, width = 3840, height = 2160)) }
        scope.runCurrent()
        assertEquals(23.976, host.plans.last().mode?.refreshRate, "the mode for the server's rate")
        assertFalse(open.isCompleted, "the open waits for the display to settle")
        settle.complete(Unit)
        scope.runCurrent()
        assertTrue(open.isCompleted)

        load(1)
        firstFrame(1, 23.976)
        scope.runCurrent()
        assertEquals(23.976, host.plans.last().mode?.refreshRate, "the first frame keeps the mode")
    }

    @Test
    fun withoutTheServersRateATvSwitchesWhileTheDecoderIsHeldForTheRateTheContainerDeclares() = outputTest { scope ->
        host.switchesFirst = true
        val hold = Hold()
        host.hold = hold
        val settle = CompletableDeferred<Unit>()
        host.settle = settle
        val before = host.plans.size

        output.preOpen(null)
        assertEquals(1, host.holdsAsked, "a download has no server rate: the decoder is held")
        assertEquals(before, host.plans.size, "nothing switches before the container is read")
        hold.declared.complete(VideoInfo(3840, 2160, null, 23.976, DynamicRange.SDR))
        scope.runCurrent()
        assertEquals(23.976, host.plans.last().mode?.refreshRate, "the mode for the declared rate")
        assertFalse(hold.released, "the decoder waits for the display to settle")
        settle.complete(Unit)
        scope.runCurrent()
        assertTrue(hold.released)

        val switches = host.plans.size
        load(1)
        firstFrame(1, 23.976)
        scope.runCurrent()
        assertTrue(host.plans.drop(switches).all { it.mode?.refreshRate == 23.976 }, "the first frame keeps the mode")
    }

    @Test
    fun aHeldDecoderWithNothingToSwitchForGoesAtOnce() = outputTest { scope ->
        host.switchesFirst = true
        val nothing = Hold().also { host.hold = it }
        output.preOpen(ServerStream(transcode = true))
        nothing.declared.complete(null)
        scope.runCurrent()
        assertTrue(nothing.released, "no video track or a failed open")

        val noRate = Hold().also { host.hold = it }
        val plans = host.plans.size
        output.preOpen(null)
        noRate.declared.complete(VideoInfo(1920, 1080, null, null, DynamicRange.SDR))
        scope.runCurrent()
        assertTrue(noRate.released, "a container without a rate, resolution matching off")
        assertEquals(plans, host.plans.size)
    }

    @Test
    fun aServersRateADesktopAndSettingsThatMatchNothingHoldNoDecoder() = runTest {
        val cases = listOf(
            Triple(ServerStream(transcode = false, frameRate = 23.976), FormFactor.TV, DeviceSettings.DEFAULT.copy(matchFrameRate = true)),
            Triple(null, FormFactor.DESKTOP, DeviceSettings.DEFAULT.copy(matchFrameRate = true, matchRefreshRate = true)),
            Triple(null, FormFactor.TV, DeviceSettings.DEFAULT.copy(matchFrameRate = false, matchResolution = false)),
        )
        for ((server, formFactor, settings) in cases) {
            val fixture = Fixture(this, modes, settings, formFactor)
            fixture.host.switchesFirst = true
            fixture.host.settle = CompletableDeferred(Unit)
            fixture.host.hold = Hold()
            fixture.output.preOpen(server)
            assertEquals(0, fixture.host.holdsAsked, "$formFactor $server $settings")
        }
    }

    @Test
    fun theEndOfThePlaybackLetsAHeldDecoderGo() = outputTest { scope ->
        host.switchesFirst = true
        val hold = Hold().also { host.hold = it }
        output.preOpen(null)
        output.release()
        scope.runCurrent()
        assertTrue(hold.released)
    }

    @Test
    fun aTranscodeAHostThatSwitchesAfterAndADesktopOpenAtOnce() = runTest {
        val cases = listOf(
            Triple(true, ServerStream(transcode = true, frameRate = 23.976), FormFactor.TV),
            Triple(false, ServerStream(transcode = false, frameRate = 23.976), FormFactor.TV),
            Triple(true, ServerStream(transcode = false, frameRate = 23.976), FormFactor.DESKTOP),
        )
        for ((switches, server, formFactor) in cases) {
            val fixture = Fixture(this, modes, DeviceSettings.DEFAULT.copy(matchFrameRate = true, matchRefreshRate = true), formFactor)
            fixture.host.switchesFirst = switches
            val before = fixture.host.plans.size
            fixture.output.preOpen(server)
            runCurrent()
            assertEquals(before, fixture.host.plans.size, "$formFactor switching first $switches, $server")
        }
    }

    @Test
    fun theSettingsGoOutFirstThenTheItemsPlanAtItsFirstFrame() = outputTest { scope ->
        val first = host.plans.single()
        assertNull(first.mode)
        assertNull(first.frameRate)
        assertTrue(first.audioPassthrough)
        assertTrue(first.hdrOutput)

        load(1)
        scope.runCurrent()
        assertEquals(1, host.plans.size, "nothing before the first frame")
        firstFrame(1, 23.976)
        scope.runCurrent()
        assertEquals(23.976, host.plans.last().mode?.refreshRate)
        assertEquals(23.976, host.plans.last().frameRate)
    }

    @Test
    fun anItemIsMeasuredOnceAndTheNextIsDecidedAgainstTheDisplaysOwnMode() = outputTest { scope ->
        firstFrame(1, 23.976)
        scope.runCurrent()
        val count = host.plans.size
        // The cadence settles later in the item: no second switch for it.
        firstFrame(1, 47.952)
        scope.runCurrent()
        assertEquals(count, host.plans.size)

        load(2)
        scope.runCurrent()
        assertEquals(count, host.plans.size, "between items the last plan stays")
        firstFrame(2, 50.0)
        scope.runCurrent()
        assertEquals(50.0, host.plans.last().mode?.refreshRate)
        assertEquals(1, host.displayReads, "the display is read once, before anything switched it")
    }

    @Test
    fun aRateReportedAfterTheFirstFrameGetsTimeForIt() = outputTest { scope ->
        firstFrame(1, null)
        scope.runCurrent()
        assertEquals(1, host.plans.size, "waits for the rate")
        scope.advanceTimeBy(1_000)
        firstFrame(1, 24.0)
        scope.runCurrent()
        assertEquals(24.0, host.plans.last().mode?.refreshRate)

        firstFrame(2, null)
        scope.runCurrent()
        scope.advanceTimeBy(PlaybackOutput.RATE_WAIT_MS + 1)
        assertNull(host.plans.last().frameRate, "no rate by then: planned without one")
        assertNull(host.plans.last().mode)
    }

    @Test
    fun theFirstFrameIsHeldWhileTheDisplayIsNegotiated() = outputTest { scope ->
        val settle = CompletableDeferred<Unit>()
        host.settle = settle
        assertFalse(output.negotiating.value, "the settings' plan holds no frame")
        firstFrame(1, 23.976)
        scope.runCurrent()
        assertTrue(output.negotiating.value)
        settle.complete(Unit)
        scope.runCurrent()
        assertFalse(output.negotiating.value)
    }

    @Test
    fun aNewerItemAbandonsThePendingNegotiationWithoutReleasingItsOwn() = outputTest { scope ->
        val first = CompletableDeferred<Unit>()
        host.settle = first
        firstFrame(1, 23.976)
        scope.runCurrent()
        assertTrue(output.negotiating.value)

        val second = CompletableDeferred<Unit>()
        host.settle = second
        load(2)
        firstFrame(2, 50.0)
        scope.runCurrent()
        assertTrue(output.negotiating.value, "the newer item's negotiation")
        first.complete(Unit)
        scope.runCurrent()
        assertTrue(output.negotiating.value, "the older one finishing late releases nothing")
        second.complete(Unit)
        scope.runCurrent()
        assertFalse(output.negotiating.value)
    }

    @Test
    fun aDesktopSwitchesOnEnteringFullscreenAndGoesBackOnLeaving() = outputTest(
        DeviceSettings.DEFAULT.copy(matchRefreshRate = true, matchDynamicRange = true),
        FormFactor.DESKTOP,
    ) { scope ->
        firstFrame(1, 23.976, DynamicRange.HDR10)
        scope.runCurrent()
        assertNull(host.plans.last().mode, "windowed")
        assertFalse(host.plans.last().enableHdr)

        fullscreen.value = true
        scope.runCurrent()
        assertEquals(23.976, host.plans.last().mode?.refreshRate)
        assertTrue(host.plans.last().enableHdr)

        fullscreen.value = false
        scope.runCurrent()
        assertNull(host.plans.last().mode)
        assertFalse(host.plans.last().enableHdr)
    }

    @Test
    fun aSettingsChangeIsANewPlan() = outputTest { scope ->
        firstFrame(1, 23.976)
        scope.runCurrent()
        settings.update { it.copy(matchFrameRate = false) }
        scope.runCurrent()
        assertNull(host.plans.last().mode)
        settings.update { it.copy(hdr = false) }
        scope.runCurrent()
        assertFalse(host.plans.last().hdrOutput)
    }

    @Test
    fun releaseRestoresTheDisplayOnce() = outputTest { scope ->
        firstFrame(1, 23.976)
        scope.runCurrent()
        output.release()
        output.release()
        assertEquals(1, host.restores)
        val count = host.plans.size
        firstFrame(2, 50.0)
        scope.runCurrent()
        assertEquals(count, host.plans.size, "nothing after the release")
    }

    @Test
    fun aSuspendRestoresTheDisplayAndTheNextFirstFramePlansAgain() = outputTest { scope ->
        firstFrame(1, 23.976)
        scope.runCurrent()
        output.suspend()
        output.suspend()
        assertEquals(1, host.restores, "once")
        val count = host.plans.size

        // The video opens again after the background.
        load(2)
        firstFrame(2, 23.976)
        scope.runCurrent()
        assertEquals(count + 1, host.plans.size)
        assertEquals(23.976, host.plans.last().mode?.refreshRate)
        output.release()
        assertEquals(2, host.restores)
    }

    @Test
    fun aDisplayThatCantBeReadChangesNothing() = runTest {
        val host = object : PlaybackOutputHost {
            var applied = 0
            var restored = 0

            override suspend fun display(): DisplayInfo = error("no display")

            override suspend fun apply(plan: OutputPlan): Boolean {
                applied++
                return true
            }

            override fun restore() {
                restored++
            }
        }
        val output = PlaybackOutput(MutableStateFlow(EngineState()), MutableStateFlow(false), FormFactor.TV, MutableStateFlow(DeviceSettings.DEFAULT), host, backgroundScope)
        runCurrent()
        val switched = async { output.setHdr(false) }
        runCurrent()
        assertFalse(switched.await(), "no plan, no HDR switch")
        output.release()
        assertEquals(0, host.applied)
        assertEquals(0, host.restored)
    }

    @Test
    fun theHdrSwitchIsThePlansInputUntilTheStoredSettingSaysTheSame() = outputTest { scope ->
        firstFrame(1, 23.976, DynamicRange.HDR10)
        scope.runCurrent()
        assertTrue(host.plans.last().hdrOutput)
        val switched = scope.async { output.setHdr(false) }
        scope.runCurrent()
        assertTrue(switched.await())
        assertFalse(host.plans.last().hdrOutput, "the plan writes the switch's HDR output")
        assertFalse(host.plans.last().hdr)
        settings.update { it.copy(hdr = false) }
        scope.runCurrent()
        val count = host.plans.size
        settings.update { it.copy(hdr = true) }
        scope.runCurrent()
        assertTrue(host.plans.last().hdrOutput, "the stored setting drives the plan again once it caught up")
        assertEquals(count + 1, host.plans.size)
    }

    @Test
    fun theDolbyVisionConversionIsThePlansFromTheSettingOrThePlayersPage() = outputTest { scope ->
        firstFrame(1, 23.976)
        scope.runCurrent()
        assertEquals(DolbyVisionConversion.AUTO, host.plans.last().dolbyVisionConversion)
        output.setDolbyVisionConversion(DolbyVisionConversion.HEVC_STRIP)
        scope.runCurrent()
        assertEquals(DolbyVisionConversion.HEVC_STRIP, host.plans.last().dolbyVisionConversion, "the page stands in for the setting")
        settings.update { it.copy(dvConversionMode = DolbyVisionConversion.DV81) }
        scope.runCurrent()
        assertEquals(DolbyVisionConversion.HEVC_STRIP, host.plans.last().dolbyVisionConversion, "for the rest of the playback")
    }

    @Test
    fun aRefusedHdrSwitchPutsThePlanBack() = outputTest { scope ->
        firstFrame(1, 23.976)
        scope.runCurrent()
        host.hdrTaken = false
        val switched = scope.async { output.setHdr(false) }
        scope.runCurrent()
        assertFalse(switched.await())
        host.hdrTaken = true
        scope.runCurrent()
        assertTrue(host.plans.last().hdrOutput, "the setting's HDR output again")
        assertFalse(host.plans[host.plans.size - 2].hdrOutput, "the switch's plan went out first")
    }
}
