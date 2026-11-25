package com.edde746.plezy.presentation.player

import com.edde746.plezy.presentation.player.PictureInPictureRules.aspectRatio
import com.edde746.plezy.presentation.player.PictureInPictureRules.message
import com.edde746.plezy.presentation.player.PictureInPictureRules.videoSize
import com.edde746.plezy.strings.T
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class PictureInPictureTest {
    // ---- Failure messages ---------------------------------------------------------------------------------------

    @Test
    fun eachFailureCodeHasItsMessage() {
        val errors = T.videoControls.pipErrors
        assertEquals(errors.androidVersion, message(PictureInPictureResult.Failed("android_version")))
        assertEquals(errors.iosVersion, message(PictureInPictureResult.Failed("ios_version")))
        assertEquals(errors.notSupported, message(PictureInPictureResult.Failed("macos_version")))
        assertEquals(errors.permissionDisabled, message(PictureInPictureResult.Failed("permission_disabled")))
        assertEquals(errors.notSupported, message(PictureInPictureResult.Failed("not_supported")))
        assertEquals(errors.prepareFailed, message(PictureInPictureResult.Failed("pip_prepare_failed")))
        assertEquals(errors.voSwitchFailed, message(PictureInPictureResult.Failed("vo_switch_failed")))
        assertEquals(errors.failed, message(PictureInPictureResult.Failed("failed")))
    }

    @Test
    fun anotherCodeIsAnUnknownErrorWithThePlatformsMessage() {
        assertEquals("An error occurred: boom", message(PictureInPictureResult.Failed("unknown", "boom")))
        assertEquals("An error occurred: Unknown", message(PictureInPictureResult.Failed("weird")))
    }

    @Test
    fun noAnswerIsUnknownAndNoCodeTheGenericFailure() {
        assertEquals("An error occurred: Unknown", message(null))
        assertEquals(T.videoControls.pipFailed, message(PictureInPictureResult.Failed(null)))
    }

    // ---- The window's shape -------------------------------------------------------------------------------------

    @Test
    fun aspectRatioIsTheVideosWithinTheSystemsLimits() {
        assertEquals(16 to 9, aspectRatio(null, 1080))
        assertEquals(16 to 9, aspectRatio(0, 1080))
        assertEquals(16 to 9, aspectRatio(1920, -1))
        assertEquals(1920 to 1080, aspectRatio(1920, 1080))
        assertEquals(239 to 100, aspectRatio(3000, 1000))
        assertEquals(100 to 239, aspectRatio(400, 1000))
        assertEquals(239 to 100, aspectRatio(239, 100))
        assertEquals(1080 to 1920, aspectRatio(1080, 1920))
    }

    @Test
    fun videoSizeTakesTheDisplaySizeThenTheDecodedSizeThenThePlayersArea() {
        assertEquals(1920 to 800, videoSize(PictureInPictureVideo(1920, 800, 1920, 1080, 1000, 500)))
        assertEquals(1920 to 1080, videoSize(PictureInPictureVideo(1920, null, 1920, 1080, 1000, 500)))
        assertEquals(1000 to 500, videoSize(PictureInPictureVideo(viewportWidth = 1000, viewportHeight = 500)))
        assertNull(videoSize(PictureInPictureVideo()))
    }

    // ---- Support, auto-PiP and the lifecycle --------------------------------------------------------------------

    @Test
    fun androidHasPictureInPictureFromOreoOnPhonesWithTheFeature() {
        assertTrue(PictureInPictureRules.androidSupported(26, television = false, hasFeature = true))
        assertFalse(PictureInPictureRules.androidSupported(25, television = false, hasFeature = true))
        assertFalse(PictureInPictureRules.androidSupported(34, television = true, hasFeature = true))
        assertFalse(PictureInPictureRules.androidSupported(34, television = false, hasFeature = false))
    }

    @Test
    fun autoPictureInPictureIsReadyOnlyWhileItIsOnAndPlaying() {
        assertTrue(PictureInPictureRules.autoEnterReady(autoPipOn = true, playing = true))
        assertFalse(PictureInPictureRules.autoEnterReady(autoPipOn = true, playing = false))
        assertFalse(PictureInPictureRules.autoEnterReady(autoPipOn = false, playing = true))
    }

    // ---- The button ---------------------------------------------------------------------------------------------

    private class FakeHost(
        override val supported: Boolean = true,
        override var active: Boolean = false,
        val result: PictureInPictureResult = PictureInPictureResult.Entered,
    ) : PictureInPictureHost {
        val log = mutableListOf<String>()

        override suspend fun enter(width: Int?, height: Int?): PictureInPictureResult {
            log += "enter $width×$height"
            return result
        }

        override fun exit() {
            log += "exit"
        }
    }

    private suspend fun toggle(host: FakeHost, video: PictureInPictureVideo = PictureInPictureVideo(1920, 800)) =
        PictureInPictureRules.toggle(
            host,
            video = { host.log += "size"; video },
            prepare = { host.log += "prepare" },
            restore = { host.log += "restore" },
            report = { host.log += "report $it" },
        )

    @Test
    fun withoutPictureInPictureTheButtonSaysSo() = runTest {
        val host = FakeHost(supported = false)
        toggle(host)
        assertEquals(listOf("report ${T.videoControls.pipErrors.notSupported}"), host.log)
    }

    @Test
    fun inPictureInPictureTheButtonLeavesIt() = runTest {
        val host = FakeHost(active = true)
        toggle(host)
        assertEquals(listOf("exit"), host.log)
    }

    @Test
    fun theWholePictureShowsAFrameBeforeTheWindowOpensInTheVideosShape() = runTest {
        val host = FakeHost()
        launch { toggle(host) }
        runCurrent()
        assertEquals(listOf("prepare"), host.log)
        advanceTimeBy(PictureInPictureRules.PREPARE_DELAY_MILLIS)
        runCurrent()
        assertEquals(listOf("prepare", "size", "enter 1920×800"), host.log)
    }

    @Test
    fun aFailedStartRestoresThePictureAndSaysWhy() = runTest {
        val host = FakeHost(result = PictureInPictureError.PERMISSION_DISABLED.failed())
        toggle(host, PictureInPictureVideo())
        assertEquals(
            listOf("prepare", "size", "enter null×null", "restore", "report ${T.videoControls.pipErrors.permissionDisabled}"),
            host.log,
        )
    }
}
