package com.edde746.plezy.playback

import kotlin.test.Test
import kotlin.test.assertEquals

class ShaderPresetTest {
    private fun ShaderPreset.paths(dynamicRange: DynamicRange? = DynamicRange.SDR) =
        files(dynamicRange).map { (it as ShaderFile.Bundled).path }

    @Test
    fun theBuiltInPresetsKeepTheirOrderAndIds() {
        assertEquals(
            listOf(
                "none", "nvscaler",
                "artcnn_c4f16_neutral", "artcnn_c4f16_dn", "artcnn_c4f16_ds",
                "artcnn_c4f32_neutral", "artcnn_c4f32_dn", "artcnn_c4f32_ds",
                "anime4k_fast_modeA", "anime4k_fast_modeB", "anime4k_fast_modeC",
                "anime4k_fast_modeAA", "anime4k_fast_modeBB", "anime4k_fast_modeCA",
                "anime4k_hq_modeA", "anime4k_hq_modeB", "anime4k_hq_modeC",
                "anime4k_hq_modeAA", "anime4k_hq_modeBB", "anime4k_hq_modeCA",
            ),
            ShaderPreset.builtIn.map { it.id },
        )
    }

    @Test
    fun offRunsNothingAndNvScalerAndArtCnnOneFileEach() {
        assertEquals(emptyList(), ShaderPreset.Off.paths())
        assertEquals(listOf("nvscaler/NVScaler.glsl"), ShaderPreset.NvScaler.paths())
        assertEquals(
            listOf(
                "artcnn/ArtCNN_C4F16.glsl", "artcnn/ArtCNN_C4F16_DN.glsl", "artcnn/ArtCNN_C4F16_DS.glsl",
                "artcnn/ArtCNN_C4F32.glsl", "artcnn/ArtCNN_C4F32_DN.glsl", "artcnn/ArtCNN_C4F32_DS.glsl",
            ),
            ShaderPreset.builtIn.filterIsInstance<ShaderPreset.ArtCnn>().flatMap { it.paths() },
        )
    }

    @Test
    fun anime4kModesChainTheClampThenTheirRestoreAndUpscaleStepsWithTheirQualitysNetworks() {
        val clamp = "anime4k/Anime4K_Clamp_Highlights.glsl"
        val restore = "anime4k/Anime4K_Restore_CNN_M.glsl"
        val upscale = "anime4k/Anime4K_Upscale_CNN_x2_M.glsl"
        val downscale = "anime4k/Anime4K_AutoDownscalePre_x2.glsl"
        val fast = Anime4kMode.entries.associate { it.label to ShaderPreset.Anime4k(Anime4kQuality.FAST, it).paths() }
        assertEquals(
            mapOf(
                "A" to listOf(clamp, restore),
                "B" to listOf(clamp, restore, upscale, downscale),
                "C" to listOf(clamp, upscale, downscale),
                "A+A" to listOf(clamp, restore, restore),
                "B+B" to listOf(clamp, restore, restore, upscale, downscale),
                "C+A" to listOf(clamp, upscale, restore, downscale),
            ),
            fast,
        )
        assertEquals(
            listOf(clamp, "anime4k/Anime4K_Restore_CNN_VL.glsl", "anime4k/Anime4K_Upscale_CNN_x2_VL.glsl", downscale),
            ShaderPreset.Anime4k(Anime4kQuality.HQ, Anime4kMode.B).paths(),
        )
    }

    @Test
    fun nvScalerSkipsHdrVideoAndTheOthersRunOnEveryRange() {
        for (range in listOf(DynamicRange.HDR10, DynamicRange.HLG, DynamicRange.DOLBY_VISION)) {
            assertEquals(emptyList(), ShaderPreset.NvScaler.files(range), "$range")
            assertEquals(1, ShaderPreset.ArtCnn(ArtCnnModel.C4F16, ArtCnnVariant.NEUTRAL).files(range).size, "$range")
        }
        assertEquals(listOf("nvscaler/NVScaler.glsl"), ShaderPreset.NvScaler.paths(dynamicRange = null), "no frame yet: as SDR")
    }

    @Test
    fun anImportedShaderRunsItsOwnCopy() {
        val custom = CustomShader("custom_a.glsl", "Sharpen", "a.glsl")
        assertEquals(listOf(ShaderFile.Custom("a.glsl")), ShaderPreset.Custom(custom).files(DynamicRange.HDR10))
        assertEquals(ShaderPreset.Custom(custom), ShaderPreset.of("custom_a.glsl", listOf(custom)))
        assertEquals(ShaderPreset.Off, ShaderPreset.of("custom_gone.glsl", listOf(custom)), "a deleted shader's id is off")
        assertEquals(ShaderPreset.NvScaler, ShaderPreset.of("nvscaler", emptyList()))
    }

    @Test
    fun theToggleTurnsARunningShaderOffAndBringsBackTheStoredOneOrNvScaler() {
        val anime = ShaderPreset.Anime4k(Anime4kQuality.FAST, Anime4kMode.A)
        val all = ShaderPreset.available(ShaderRenderer.LIBPLACEBO, emptyList())
        assertEquals(ShaderPreset.Off, ShaderPreset.toggled(anime, anime, all))
        assertEquals(anime, ShaderPreset.toggled(ShaderPreset.Off, anime, all))
        assertEquals(ShaderPreset.NvScaler, ShaderPreset.toggled(ShaderPreset.Off, ShaderPreset.Off, all))
        val android = ShaderPreset.available(ShaderRenderer.OPENGL_ES, emptyList())
        assertEquals(ShaderPreset.Anime4k(Anime4kQuality.FAST, Anime4kMode.A), ShaderPreset.toggled(ShaderPreset.Off, ShaderPreset.Off, android))
    }

    @Test
    fun eachRendererOffersThePresetsItRuns() {
        val custom = CustomShader("custom_a.glsl", "Sharpen", "a.glsl")
        fun kinds(renderer: ShaderRenderer) = ShaderPreset.available(renderer, listOf(custom)).map { it::class.simpleName }.distinct()
        assertEquals(listOf("Off", "NvScaler", "ArtCnn", "Anime4k", "Custom"), kinds(ShaderRenderer.LIBPLACEBO), "Windows, Apple")
        assertEquals(listOf("Off", "Anime4k"), kinds(ShaderRenderer.OPENGL), "Linux: no NVScaler, no ArtCNN, no imported shaders")
        assertEquals(listOf("Off", "Anime4k", "Custom"), kinds(ShaderRenderer.OPENGL_ES), "Android: no luma hooks")
        assertEquals(13, ShaderPreset.available(ShaderRenderer.OPENGL_ES, emptyList()).size)
    }
}
