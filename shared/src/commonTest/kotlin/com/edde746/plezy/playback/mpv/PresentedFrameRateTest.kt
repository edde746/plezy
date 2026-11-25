package com.edde746.plezy.playback.mpv

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * The rate the player presents a video at ([com.edde746.plezy.playback.VideoInfo.fps]), which display matching and
 * the frame-rate vote follow: fields double the container's rate, the measured cadence is all that reveals a decoder
 * that deinterlaces by itself, and inverse telecine presents the film frames.
 */
class PresentedFrameRateTest {
    private val mpv = MpvLifecycle()

    /** A file whose video is up, its track declaring [demuxFps] (or none). */
    private fun shown(demuxFps: String? = null) {
        mpv.load(mpv.nextLoadId())
        mpv.startFile()
        val fps = demuxFps?.let { ""","demux-fps":$it""" }.orEmpty()
        mpv.text("track-list", """[{"id":1,"type":"video","selected":true,"codec":"mpeg2video"$fps}]""")
        mpv.text("video-params", """{"pixelformat":"yuv420p","w":720,"h":480,"gamma":"bt.1886"}""")
    }

    private val fps: Double? get() = mpv.state.video?.fps

    @Test
    fun anInterlacedStreamIsPresentedAtFieldRateWhileMpvDeinterlacesIt() {
        // bwdif's send_field turns 29.97i into 59.94p: an exact 29.97 Hz mode would drop every other frame.
        shown()
        mpv.double("container-fps", 29.970030)
        mpv.flag("deinterlace-active", true)
        assertEquals(59.94006, assertNotNull(fps), 1e-5)
        assertEquals(720 to 480, mpv.state.video?.let { it.width to it.height })
    }

    @Test
    fun aDecoderThatDeinterlacesByItselfIsCaughtByTheMeasuredCadence() {
        // MediaCodec on Tegra or Amlogic emits 59.94 frames for 29.97i with no mpv filter to say so.
        shown()
        mpv.double("container-fps", 29.970030)
        mpv.flag("deinterlace-active", false)
        mpv.double("estimated-vf-fps", 58.823529)
        assertEquals(59.94006, assertNotNull(fps), 1e-5)
    }

    @Test
    fun inverseTelecinePresentsFourFifthsOfTheContainerRate() {
        // fieldmatch and decimate turn 29.97i film back into 23.976p; 29.97 or 59.94 Hz would bring the judder back.
        shown()
        mpv.double("container-fps", 29.970030)
        mpv.flag("ivtc-active", true)
        mpv.double("estimated-vf-fps", 23.976024)
        assertEquals(23.976024, assertNotNull(fps), 1e-5)
        // Before a cadence exists the property alone decides.
        assertEquals(0.8, MpvState.presentedRateFactor(29.97003, null, deinterlaceActive = false, ivtcActive = true))
        assertEquals(2.0, MpvState.presentedRateFactor(29.97003, null, deinterlaceActive = true, ivtcActive = false))
        assertEquals(1.0, MpvState.presentedRateFactor(29.97003, 29.97003, deinterlaceActive = false, ivtcActive = false))
    }

    @Test
    fun onlyADoubledCadenceCountsAsFieldOutput() {
        // Matroska rounds the first field's duration to 16 or 17 ms; MediaTek's first field pair shares a timestamp.
        assertTrue(MpvState.presentsFields(29.97003, 1000.0 / 16, deinterlaceActive = false))
        assertTrue(MpvState.presentsFields(29.97003, 1000.0 / 17, deinterlaceActive = false))
        assertTrue(MpvState.presentsFields(29.97003, 10 / 0.150150, deinterlaceActive = false))
        assertTrue(MpvState.presentsFields(25.0, 50.0, deinterlaceActive = false))
        assertTrue(MpvState.presentsFields(29.97003, null, deinterlaceActive = true), "mpv's deinterlacer, before any cadence")
        // Telecine (1.25×), a duplicated first frame (3×), a dropped one (0.5×), progressive.
        assertFalse(MpvState.presentsFields(23.976, 29.97, deinterlaceActive = false))
        assertFalse(MpvState.presentsFields(29.97003, 89.91, deinterlaceActive = false))
        assertFalse(MpvState.presentsFields(29.97003, 14.985, deinterlaceActive = false))
        assertFalse(MpvState.presentsFields(23.976, 23.976, deinterlaceActive = false))
        // Nothing measured yet, or no container rate to compare with.
        assertFalse(MpvState.presentsFields(29.97003, null, deinterlaceActive = false))
        assertFalse(MpvState.presentsFields(0.0, 59.94, deinterlaceActive = false))
    }

    @Test
    fun aProgressiveStreamKeepsTheContainerRate() {
        shown()
        mpv.double("container-fps", 23.976)
        mpv.flag("deinterlace-active", false)
        mpv.double("estimated-vf-fps", 23.976)
        assertEquals(23.976, assertNotNull(fps), 1e-9)
    }

    @Test
    fun aTrackRateAloneIsKeptAndDoubledCadencesCountAgainstIt() {
        // No `container-fps`: the track's `demux-fps` is the rate.
        shown(demuxFps = "25.0")
        assertEquals(25.0, assertNotNull(fps), 1e-9)
        mpv.double("estimated-vf-fps", 50.0)
        assertEquals(50.0, assertNotNull(fps), 1e-9)
    }

    @Test
    fun noUsableContainerRateIsNoRate() {
        shown()
        mpv.flag("deinterlace-active", true)
        assertNull(fps)
        mpv.double("container-fps", 0.0)
        assertNull(fps)
        mpv.double("container-fps", -1.0)
        assertNull(fps)
        mpv.unavailable("container-fps")
        assertNull(fps)
    }

    @Test
    fun theCadenceMovingWithinItsBandChangesNothing() {
        shown()
        mpv.double("container-fps", 29.970030)
        mpv.double("estimated-vf-fps", 59.9)
        val video = mpv.state.video
        mpv.double("estimated-vf-fps", 60.1)
        assertTrue(video === mpv.state.video, "the same video while the factor stays")
    }
}
