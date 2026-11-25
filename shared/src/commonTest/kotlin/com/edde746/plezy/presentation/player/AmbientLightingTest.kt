package com.edde746.plezy.presentation.player

import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.playback.VideoFit
import com.edde746.plezy.playback.VideoLayout
import com.edde746.plezy.presentation.player.FakeShaderFiles.Companion.AMBIENT_SHADER
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class AmbientLightingTest {
    private fun PlayerHarness.option(): PlayerOption? = state.options.firstOrNull { it.id == PlayerOptionId.AMBIENT_LIGHTING }

    private fun PlayerHarness.firstFrame() = engineState { it.copy(loaded = true, playbackRestarts = 1) }

    /** Another file starts loading, and shows its first frame. */
    private fun PlayerHarness.nextFile() {
        engineState { it.copy(playbackRestarts = 0) }
        firstFrame()
    }

    private fun ambientTest(stored: PlayerChoices = PlayerChoices(), picture: PictureChoices = PictureChoices(), body: PlayerHarness.() -> Unit) =
        playerTest(preferences = stored, shaderFiles = FakeShaderFiles(), ambientLighting = true, picture = picture, body = body)

    @Test
    fun theSwitchFollowsTheShadersWhereThePlayerRunsIt() = ambientTest {
        val ids = state.options.map { it.id }
        assertEquals(ids.indexOf(PlayerOptionId.SHADERS) + 1, ids.indexOf(PlayerOptionId.AMBIENT_LIGHTING))
        val option = option()!!
        assertEquals("Ambient lighting", option.label)
        assertEquals(false, option.on)
        assertEquals(PlayerCommand.ToggleAmbientLighting, option.toggle)
    }

    @Test
    fun withoutItThePlayerOffersNoSwitchAndTheToggleDoesNothing() = playerTest(shaderFiles = FakeShaderFiles()) {
        assertNull(option())
        dispatch(PlayerCommand.ToggleAmbientLighting)
        assertEquals(emptyList(), engine.ambientLighting)
    }

    @Test
    fun theStoredSettingComesOnAtTheFirstFrameOnly() = ambientTest(PlayerChoices(ambientLighting = true)) {
        assertEquals(emptyList(), engine.ambientLighting, "nothing before the picture")
        firstFrame()
        assertEquals(listOf<String?>(AMBIENT_SHADER), engine.ambientLighting)
        assertEquals(true, option()?.on)
        dispatch(PlayerCommand.SetVideoFit(VideoFit.COVER))
        assertEquals(null, engine.ambientLighting.last(), "a fit change turns it off")
        assertEquals(true, preferences.choices.value.ambientLighting, "for this player only")
        nextFile()
        assertEquals(null, engine.ambientLighting.last(), "the next file doesn't bring it back")
    }

    @Test
    fun theToggleIsKeptAndTurnsTheShaderOffAndThePictureBackToFit() =
        ambientTest(picture = PictureChoices(fit = VideoFit.FILL, shaderPreset = "nvscaler")) {
            firstFrame()
            dispatch(PlayerCommand.SetZoom(1.5))
            dispatch(PlayerCommand.ToggleAmbientLighting)
            assertEquals(AMBIENT_SHADER, engine.ambientLighting.last())
            assertEquals(true, preferences.choices.value.ambientLighting)
            assertEquals(emptyList(), engine.shaders.last(), "no shader before it")
            assertEquals(VideoLayout(VideoFit.CONTAIN, 1.0), engine.layouts.last())
            assertEquals(PictureChoices(VideoFit.FILL, 1.5, "nvscaler"), preferences.kept(), "the shader, the fit and the zoom stay kept")
            assertEquals(VideoLayout(VideoFit.CONTAIN, 1.0), engine.layouts.last(), "the stored change of ambient lighting leaves the fit")

            dispatch(PlayerCommand.ToggleAmbientLighting)
            assertEquals(null, engine.ambientLighting.last())
            assertEquals(false, preferences.choices.value.ambientLighting)
        }

    @Test
    fun aShaderTurnsItOffForGood() = ambientTest(PlayerChoices(ambientLighting = true)) {
        firstFrame()
        dispatch(PlayerCommand.SetShaderPreset("anime4k_fast_modeA"))
        assertEquals(null, engine.ambientLighting.last())
        assertEquals(false, preferences.choices.value.ambientLighting)
    }

    @Test
    fun choosingNoShaderLeavesItOn() = ambientTest(PlayerChoices(ambientLighting = true)) {
        firstFrame()
        dispatch(PlayerCommand.SetShaderPreset("none"))
        assertEquals(AMBIENT_SHADER, engine.ambientLighting.last())
    }

    @Test
    fun pictureInPictureShowsNoBarsAndItComesBackAfter() = ambientTest(PlayerChoices(ambientLighting = true)) {
        firstFrame()
        store.onPictureInPictureChanged(true)
        advance(kotlin.time.Duration.ZERO)
        assertEquals(null, engine.ambientLighting.last())
        store.onPictureInPictureChanged(false)
        advance(kotlin.time.Duration.ZERO)
        assertEquals(AMBIENT_SHADER, engine.ambientLighting.last())
        assertEquals(true, preferences.choices.value.ambientLighting)
    }
}
