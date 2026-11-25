package com.edde746.plezy.presentation.player

import com.edde746.plezy.input.InputKey
import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.input.PlayerMenu
import com.edde746.plezy.playback.CustomShader
import com.edde746.plezy.playback.DynamicRange
import com.edde746.plezy.playback.ShaderFile
import com.edde746.plezy.playback.ShaderRenderer
import com.edde746.plezy.playback.VideoInfo
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class ShadersTest {
    private fun PlayerHarness.shaders(): PlayerOption? = state.options.firstOrNull { it.id == PlayerOptionId.SHADERS }

    private fun PlayerHarness.choose(label: String) {
        val option = assertNotNull(shaders())
        dispatch(PlayerCommand.OpenMenu(PlayerMenu.OPTIONS))
        dispatch(PlayerCommand.OpenMenu(assertNotNull(option.page)))
        dispatch(option.choices.first { it.label == label }.command)
    }

    private fun PlayerHarness.video(range: DynamicRange) = engineState { it.copy(video = VideoInfo(1920, 1080, "hevc", 23.976, range)) }

    private fun shaderTest(
        stored: PlayerChoices = PlayerChoices(),
        kept: String = "none",
        importsShaders: Boolean = true,
        body: PlayerHarness.() -> Unit,
    ) = playerTest(preferences = stored, shaderFiles = FakeShaderFiles(), importsShaders = importsShaders, picture = PictureChoices(shaderPreset = kept)) {
        playing()
        body()
    }

    @Test
    fun theOptionsOfferShadersWhereThePlatformHasThem() = shaderTest {
        val option = assertNotNull(shaders())
        assertEquals("Off", option.value)
        assertEquals(false, option.adjusted)
        assertEquals(PlayerMenu.SHADERS, option.page)
        assertEquals(
            listOf(
                "Off", "NVScaler",
                "ArtCNN C4F16", "ArtCNN C4F16 Denoise", "ArtCNN C4F16 Denoise + Sharpen",
                "ArtCNN C4F32", "ArtCNN C4F32 Denoise", "ArtCNN C4F32 Denoise + Sharpen",
                "Anime4K Fast A", "Anime4K Fast B", "Anime4K Fast C", "Anime4K Fast A+A", "Anime4K Fast B+B", "Anime4K Fast C+A",
                "Anime4K High quality A", "Anime4K High quality B", "Anime4K High quality C",
                "Anime4K High quality A+A", "Anime4K High quality B+B", "Anime4K High quality C+A",
            ),
            option.choices.map { it.label },
        )
        assertEquals(
            listOf(null, "NVIDIA image scaling for sharper video", "C4F16 · Neutral"),
            option.choices.take(3).map { it.detail },
        )
        assertEquals("Fast · Mode C+A", option.choices.first { it.label == "Anime4K Fast C+A" }.detail)
        assertTrue(option.choices.none { it.delete != null }, "the app's own presets can't be deleted")
        assertEquals("Import shader", option.importLabel)
    }

    @Test
    fun withoutShaderFilesThePlayerOffersNoShadersAndTheToggleDoesNothing() = playerTest {
        playing()
        assertNull(shaders())
        press(InputKey.G)
        dispatch(PlayerCommand.SetShaderPreset("nvscaler"))
        assertEquals(emptyList(), engine.shaders)
        assertEquals("none", preferences.kept().shaderPreset)
    }

    @Test
    fun aDeviceWithoutFileDialogsListsThePresetsWithoutTheImport() = shaderTest(importsShaders = false) {
        assertNull(assertNotNull(shaders()).importLabel)
        dispatch(PlayerCommand.ImportShader("sharpen.glsl", "//!HOOK MAIN"))
        assertEquals(emptyList(), harnessImports())
    }

    @Test
    fun aPickedPresetRunsItsChainAndIsKeptForTheNextVideo() = shaderTest {
        choose("Anime4K Fast C")
        assertEquals(
            listOf(
                listOf(
                    "/app/shaders/anime4k/Anime4K_Clamp_Highlights.glsl",
                    "/app/shaders/anime4k/Anime4K_Upscale_CNN_x2_M.glsl",
                    "/app/shaders/anime4k/Anime4K_AutoDownscalePre_x2.glsl",
                ),
            ),
            engine.shaders,
        )
        assertEquals("anime4k_fast_modeC", preferences.kept().shaderPreset)
        assertNull(state.menu, "a pick closes the page")
        assertEquals("Anime4K Fast C", shaders()?.value)
        assertEquals(true, shaders()?.adjusted)
        assertEquals(listOf("Anime4K Fast C"), shaders()?.choices?.filter { it.selected }?.map { it.label })
        choose("Off")
        assertEquals(emptyList(), engine.shaders.last())
        assertEquals("none", preferences.kept().shaderPreset)
    }

    @Test
    fun theKeptPresetRunsAsThePlayerOpens() = shaderTest(kept = "artcnn_c4f32_ds") {
        assertEquals(listOf(listOf("/app/shaders/artcnn/ArtCNN_C4F32_DS.glsl")), engine.shaders)
    }

    @Test
    fun nvScalerStopsOnHdrVideoAndRunsAgainOnSdr() = shaderTest(kept = "nvscaler") {
        assertEquals(listOf(listOf("/app/shaders/nvscaler/NVScaler.glsl")), engine.shaders, "before the first frame: as SDR")
        video(DynamicRange.HDR10)
        assertEquals(emptyList(), engine.shaders.last())
        assertEquals("NVScaler", shaders()?.value, "the choice stays NVScaler")
        video(DynamicRange.SDR)
        assertEquals(listOf("/app/shaders/nvscaler/NVScaler.glsl"), engine.shaders.last())
        assertEquals(3, engine.shaders.size)
    }

    @Test
    fun gTurnsTheShadersOffForThisPlayerOnlyAndBackOn() = shaderTest(kept = "anime4k_hq_modeA") {
        press(InputKey.G)
        assertEquals(emptyList(), engine.shaders.last())
        assertEquals("Shaders off", state.osd)
        assertEquals("anime4k_hq_modeA", preferences.kept().shaderPreset, "off isn't kept for the next video")
        choices { it.copy(audioNormalization = true) }
        assertEquals("Off", shaders()?.value, "another setting changing leaves the shaders off")
        press(InputKey.G)
        assertEquals(
            listOf("/app/shaders/anime4k/Anime4K_Clamp_Highlights.glsl", "/app/shaders/anime4k/Anime4K_Restore_CNN_VL.glsl"),
            engine.shaders.last(),
        )
        assertEquals("Shaders: Anime4K High quality A", state.osd)
    }

    @Test
    fun gWithNoStoredPresetTurnsOnNvScalerAndKeepsIt() = shaderTest {
        press(InputKey.G)
        assertEquals(listOf(listOf("/app/shaders/nvscaler/NVScaler.glsl")), engine.shaders)
        assertEquals("nvscaler", preferences.kept().shaderPreset)
        assertEquals("Shaders: NVScaler", state.osd)
    }

    @Test
    fun anImportedShaderRunsIsKeptAndListedAfterTheAppsOwn() = playerTest(shaderFiles = FakeShaderFiles(), importsShaders = true) {
        playing()
        dispatch(PlayerCommand.ImportShader("/Users/me/Downloads/FSRCNNX.glsl", "//!HOOK LUMA\nvec4 hook() { return HOOKED_tex(HOOKED_pos); }"))
        assertEquals<List<String>?>(listOf("//!HOOK LUMA\nvec4 hook() { return HOOKED_tex(HOOKED_pos); }"), shaderFiles?.imported)
        assertEquals(listOf(listOf("/custom/shader-1.glsl")), engine.shaders)
        val custom = CustomShader("custom_shader-1.glsl", "FSRCNNX", "shader-1.glsl")
        assertEquals(listOf(custom), preferences.choices.value.customShaders)
        assertEquals(custom.id, preferences.kept().shaderPreset)
        assertEquals("Shader imported", state.osd)
        val last = assertNotNull(shaders()).choices.last()
        assertEquals("FSRCNNX", last.label)
        assertEquals("Custom GLSL shader", last.detail)
        assertEquals(true, last.selected)
        assertEquals(PlayerCommand.DeleteShader(custom.id), last.delete)
    }

    @Test
    fun aFileThatIsntGlslIsntImported() = shaderTest {
        dispatch(PlayerCommand.ImportShader("notes.txt", "hello"))
        dispatch(PlayerCommand.ImportShader(".glsl", "hello"))
        assertEquals(emptyList(), harnessImports())
        assertEquals("Couldn't import the shader", state.osd)
        assertEquals(emptyList(), engine.shaders)
    }

    @Test
    fun deletingTheRunningImportedShaderTurnsTheShadersOffAndDeletesItsCopy() {
        val custom = CustomShader("custom_a.glsl", "Sharpen", "a.glsl")
        shaderTest(stored = PlayerChoices(customShaders = listOf(custom)), kept = custom.id) {
            assertEquals(listOf(listOf("/custom/a.glsl")), engine.shaders)
            dispatch(assertNotNull(shaders()?.choices?.last()?.delete))
            assertEquals(emptyList(), engine.shaders.last())
            assertEquals<List<String>?>(listOf("a.glsl"), shaderFiles?.deleted)
            assertEquals(PlayerChoices(), preferences.choices.value)
            assertEquals("none", preferences.kept().shaderPreset)
            assertEquals("Off", shaders()?.value)
            assertTrue(shaders()?.choices?.none { it.label == "Sharpen" } == true)
        }
    }

    @Test
    fun aPresetWhoseFileIsMissingTurnsTheShadersOff() {
        val custom = CustomShader("custom_a.glsl", "Sharpen", "a.glsl")
        val files = FakeShaderFiles().apply { missing += ShaderFile.Custom("a.glsl") }
        playerTest(preferences = PlayerChoices(customShaders = listOf(custom)), picture = PictureChoices(shaderPreset = custom.id), shaderFiles = files) {
            playing()
            assertTrue(engine.shaders.all { it.isEmpty() }, "the engine runs no shader")
            assertEquals("Off", shaders()?.value)
        }
    }

    @Test
    fun androidsRendererListsWhatRunsThereAndAStoredPresetThatCantRunIsOff() =
        playerTest(picture = PictureChoices(shaderPreset = "nvscaler"), shaderFiles = FakeShaderFiles(ShaderRenderer.OPENGL_ES), importsShaders = true) {
            playing()
            assertEquals("Off", shaders()?.value)
            assertEquals(emptyList(), engine.shaders)
            assertEquals(listOf("Off", "Anime4K Fast A"), shaders()?.choices?.take(2)?.map { it.label })
            assertTrue(shaders()?.choices?.none { it.label.startsWith("NVScaler") || it.label.startsWith("ArtCNN") } == true)
            assertEquals("Import shader", shaders()?.importLabel)
            press(InputKey.G)
            assertEquals("Shaders: Anime4K Fast A", state.osd)
            dispatch(PlayerCommand.SetShaderPreset("artcnn_c4f16_neutral"))
            assertEquals("Off", shaders()?.value, "ArtCNN can't run here")
            assertEquals("none", preferences.kept().shaderPreset)
        }

    @Test
    fun linuxsRendererHasNoArtCnnAndNoImports() =
        playerTest(shaderFiles = FakeShaderFiles(ShaderRenderer.OPENGL), importsShaders = true) {
            playing()
            assertTrue(shaders()?.choices?.none { it.label.startsWith("ArtCNN") } == true)
            assertEquals(true, shaders()?.choices?.any { it.label == "NVScaler" })
            assertNull(shaders()?.importLabel)
            dispatch(PlayerCommand.ImportShader("sharpen.glsl", "//!HOOK MAIN"))
            assertEquals(emptyList(), harnessImports())
        }

    private fun PlayerHarness.harnessImports(): List<String> = assertNotNull(shaderFiles).imported
}
