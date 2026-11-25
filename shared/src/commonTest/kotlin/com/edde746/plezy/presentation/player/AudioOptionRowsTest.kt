package com.edde746.plezy.presentation.player

import com.edde746.plezy.data.settings.DolbyVisionConversion
import com.edde746.plezy.playback.AudioChannels
import com.edde746.plezy.playback.AudioDevice
import com.edde746.plezy.playback.AudioRendering
import com.edde746.plezy.playback.ShaderPreset
import com.edde746.plezy.playback.VideoFit
import com.edde746.plezy.strings.T
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class AudioOptionRowsTest {
    private fun audio(passthroughSupported: Boolean = false, rendering: AudioRendering? = null, passthroughOn: Boolean = false) = PlayerOptions.AudioValues(
        audioDevices = null,
        audioDevice = "auto",
        audioNormalization = false,
        audioChannels = AudioChannels.ORIGINAL,
        locale = "en",
        passthroughSupported = passthroughSupported,
        passthroughOn = passthroughOn,
        audioRendering = rendering,
    )

    private fun List<PlayerOption>.of(id: PlayerOptionId) = firstOrNull { it.id == id }

    /** Normalization says, in the stereo limit's words, that it turns passthrough off only where passthrough is on. */
    @Test
    fun normalizationSaysItTurnsPassthroughOffOnlyWherePassthroughIsOn() {
        fun detail(supported: Boolean, on: Boolean) =
            PlayerOptions.audio(audio(passthroughSupported = supported, passthroughOn = on)).of(PlayerOptionId.AUDIO_NORMALIZATION)?.detail
        assertEquals(T.settings.audioChannelLimitStereoDescription, detail(supported = true, on = true))
        assertNull(detail(supported = true, on = false), "passthrough offered but off")
        assertNull(detail(supported = false, on = false), "no passthrough")
    }

    @Test
    fun stereoSaysItTurnsPassthroughOffOnlyWhereTheDeviceHasIt() {
        fun details(passthrough: Boolean) = PlayerOptions.audio(audio(passthroughSupported = passthrough)).of(PlayerOptionId.AUDIO_CHANNELS)?.choices?.map { it.detail }
        val settings = T.settings
        assertEquals(
            listOf(settings.audioChannelLimitOriginalDescription, settings.audioChannelLimitSurround51Description, settings.audioChannelLimitStereoDescription),
            details(passthrough = true),
        )
        assertEquals(listOf(settings.audioChannelLimitOriginalDescription, settings.audioChannelLimitSurround51Description, null), details(passthrough = false))
    }

    @Test
    fun passthroughIsNotAnInPlayerOption() {
        val labels = PlayerOptions.audio(audio(passthroughSupported = true)).map { it.label }
        assertFalse(labels.any { it.contains("passthrough", ignoreCase = true) }, "$labels")
    }

    @Test
    fun theRenderingRowShowsOnlyWhatTheSystemKnowsAndMarksDolby() {
        assertNull(PlayerOptions.audio(audio()).of(PlayerOptionId.AUDIO_RENDERING), "unknown: no row")
        val atmos = PlayerOptions.audio(audio(rendering = AudioRendering.DOLBY_ATMOS))
        val row = atmos.of(PlayerOptionId.AUDIO_RENDERING)!!
        assertEquals(T.videoSettings.audioOutput, row.label)
        assertEquals(T.videoSettings.audioOutputDolbyAtmos, row.value)
        assertTrue(row.adjusted)
        assertEquals(null, row.page)
        assertEquals(null, row.toggle)
        val ids = atmos.map { it.id }
        assertEquals(ids.indexOf(PlayerOptionId.AUDIO_NORMALIZATION) - 1, ids.indexOf(PlayerOptionId.AUDIO_RENDERING), "before normalization")
        val stereo = PlayerOptions.audio(audio(rendering = AudioRendering.STEREO)).of(PlayerOptionId.AUDIO_RENDERING)!!
        assertEquals(T.videoSettings.audioOutputStereo, stereo.value)
        assertFalse(stereo.adjusted)
    }

    @Test
    fun theAudioMenuHoldsTheAudioSettingsAndTheOptionsNone() {
        val every = PlayerOptions.Values(
            fit = VideoFit.CONTAIN,
            zoom = 1.0,
            sleepMinutes = null,
            sleepAtEndOfVideo = false,
            sleepSecondsLeft = 0,
            autoPlayNext = true,
            locale = "en",
            speed = 1.0,
            speeds = listOf(1.0),
            versions = VersionsMenu(emptyList(), emptyList()),
            hdr = true,
            shader = ShaderPreset.Off,
            ambientLighting = false,
            fileInfo = true,
            watch = FakeWatch(canControl = true, canChangeEpisode = true).state.value,
            dolbyVisionConversion = DolbyVisionConversion.AUTO,
            httpStatus = true,
        )
        assertEquals(
            listOf(
                PlayerOptionId.SPEED, PlayerOptionId.ZOOM, PlayerOptionId.VERSIONS, PlayerOptionId.SLEEP_TIMER,
                PlayerOptionId.HDR, PlayerOptionId.AUTO_PLAY_NEXT, PlayerOptionId.SHADERS, PlayerOptionId.AMBIENT_LIGHTING,
                PlayerOptionId.PLAYBACK_INFO, PlayerOptionId.FILE_INFO, PlayerOptionId.WATCH_TOGETHER,
                PlayerOptionId.DOLBY_VISION_CONVERSION, PlayerOptionId.HTTP_STATUS,
            ),
            PlayerOptions.build(every).map { it.id },
        )
        val everyAudio = audio(rendering = AudioRendering.STEREO).copy(audioDevices = listOf(AudioDevice("auto", "Autoselect device")))
        assertEquals(
            listOf(PlayerOptionId.AUDIO_OUTPUT, PlayerOptionId.AUDIO_RENDERING, PlayerOptionId.AUDIO_NORMALIZATION, PlayerOptionId.AUDIO_CHANNELS),
            PlayerOptions.audio(everyAudio).map { it.id },
        )
    }
}
