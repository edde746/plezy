package com.edde746.plezy.playback.mpv

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class OpenFailureLogTest {
    private fun classify(text: String, error: Boolean = true, prefix: String = "cplayer") = OpenFailureLog.cause(error, prefix, text)

    @Test
    fun anAudioDeviceThatWouldNotOpenIsTheAudioOutputFailure() {
        assertEquals(OpenFailureCause.AUDIO_OUTPUT, classify("Could not open/initialize audio device -> no sound.\n"))
    }

    @Test
    fun aDecoderThatCouldNotStartForTheCodecFailsTheStream() {
        assertEquals(OpenFailureCause.STREAM_INIT, classify("Failed to initialize a decoder for codec 'hevc'.", prefix = "vd"))
    }

    @Test
    fun aFailedVideoChainIsTerminal() {
        assertEquals(OpenFailureCause.STREAM_INIT, classify("Could not initialize video chain."))
    }

    @Test
    fun aFailedOutputConversionIsTerminalOnTheAudioChainOnly() {
        val line = "Cannot convert decoder/filter output to any format supported by the output."
        assertEquals(OpenFailureCause.STREAM_INIT, classify(line, prefix = "af"))
        assertNull(classify(line, prefix = "vf"))
    }

    @Test
    fun aFilterMpvBypassedIsNotAFailure() {
        assertNull(classify("Disabling filter loudnorm because it has failed.", prefix = "af"))
    }

    @Test
    fun aLibavfilterGraphThatRefusedToRunLeavesItsChainStuck() {
        assertEquals(OpenFailureCause.STREAM_INIT, classify("error on filtering (-12)", prefix = "lavfi"))
        assertNull(classify("error on filtering (-12)", prefix = "af"))
    }

    @Test
    fun oneFailedHardwareDecoderProbeIsNotAFailure() {
        assertNull(classify("Could not open codec.", prefix = "vd"))
    }

    @Test
    fun onlyErrorAndFatalLevelsCount() {
        assertNull(classify("Could not open/initialize audio device -> no sound.", error = false))
    }

    @Test
    fun httpStatusLinesStayWithTheStatusLatchAndThe503Watchdog() {
        assertNull(classify("https: HTTP error 503 Service Unavailable", prefix = "ffmpeg"))
    }

    @Test
    fun libavProtocolWarningsAndErrorsAreTransportFaults() {
        assertTrue(OpenFailureLog.isTransportFault(warning = true, prefix = "ffmpeg", text = "x"))
        assertTrue(OpenFailureLog.isTransportFault(warning = true, prefix = "", text = "http: Stream ends prematurely at 565588, should be 1155664"))
    }

    @Test
    fun decoderDemuxerAndInformationalLinesAreNotTransportFaults() {
        assertFalse(OpenFailureLog.isTransportFault(warning = true, prefix = "ffmpeg/video", text = "x"))
        assertFalse(OpenFailureLog.isTransportFault(warning = true, prefix = "ffmpeg/demuxer", text = "x"))
        assertFalse(OpenFailureLog.isTransportFault(warning = false, prefix = "ffmpeg", text = "x"))
        assertFalse(OpenFailureLog.isTransportFault(warning = true, prefix = "cplayer", text = "x"))
        assertFalse(OpenFailureLog.isTransportFault(warning = true, prefix = "", text = "hevc: Invalid NAL unit size"))
    }
}
