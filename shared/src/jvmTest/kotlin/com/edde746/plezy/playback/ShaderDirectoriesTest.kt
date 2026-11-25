package com.edde746.plezy.playback

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.runBlocking
import java.io.File
import java.nio.file.Files
import kotlin.test.Test
import kotlin.test.assertContentEquals
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class ShaderDirectoriesTest {
    private val root = Files.createTempDirectory("shaders").toFile().apply { deleteOnExit() }
    private val cache = File(root, "cache/shaders")
    private val custom = File(root, "support/custom_shaders")
    private val shipped = mapOf(
        "nvscaler/NVScaler.glsl" to "//!HOOK LUMA\n// nvscaler\n".encodeToByteArray(),
        "anime4k/Anime4K_Clamp_Highlights.glsl" to "//!HOOK MAIN\n// clamp\n".encodeToByteArray(),
        "anime4k/Anime4K_Restore_CNN_M.glsl" to "//!HOOK MAIN\n// restore\n".encodeToByteArray(),
        "anime4k/Anime4K_Upscale_CNN_x2_M.glsl" to "//!HOOK MAIN\n// upscale\n".encodeToByteArray(),
        "anime4k/Anime4K_AutoDownscalePre_x2.glsl" to "//!HOOK MAIN\n// downscale\n".encodeToByteArray(),
    )
    private var reads = 0

    private val files = ShaderDirectories(
        ShaderRenderer.OPENGL_ES,
        BundledShaders.Packaged { path ->
            reads++
            shipped.getValue(path)
        },
        cache.path,
        custom.path,
        io = Dispatchers.Unconfined,
    )

    private fun pending(dir: File) = dir.listFiles().orEmpty().filter { ".pending." in it.name }

    @Test
    fun aShippedChainIsCopiedIntoTheCacheInMpvsOrderWithTheShippedBytes() = runBlocking<Unit> {
        val paths = files.paths(ShaderPreset.Anime4k(Anime4kQuality.FAST, Anime4kMode.BB).files(DynamicRange.SDR))
        assertEquals(
            listOf("Clamp_Highlights", "Restore_CNN_M", "Restore_CNN_M", "Upscale_CNN_x2_M", "AutoDownscalePre_x2").map { "Anime4K_$it.glsl" },
            paths.map { File(it).name },
        )
        assertEquals(paths[1], paths[2], "the doubled restore runs the same file again")
        for (path in paths) {
            assertTrue(path.startsWith(cache.path), path)
            assertContentEquals(shipped.getValue(File(path).relativeTo(cache).invariantSeparatorsPath), File(path).readBytes())
        }
        assertEquals(4, reads, "each file once")
    }

    @Test
    fun aStaleOrTruncatedCopyIsReplacedByACompleteOne() = runBlocking<Unit> {
        val target = File(cache, "nvscaler/NVScaler.glsl").apply { parentFile.mkdirs() }
        val unrelated = File(target.parentFile, "NVScaler.glsl.pending.interrupted").apply { writeBytes(byteArrayOf(1)) }
        for (stale in listOf("stale".encodeToByteArray(), shipped.getValue("nvscaler/NVScaler.glsl").copyOf(5))) {
            target.writeBytes(stale)
            val fresh = ShaderDirectories(ShaderRenderer.OPENGL_ES, BundledShaders.Packaged(shipped::getValue), cache.path, custom.path, Dispatchers.Unconfined)
            assertEquals(listOf(target.path), fresh.paths(listOf(ShaderFile.Bundled("nvscaler/NVScaler.glsl"))))
            assertContentEquals(shipped.getValue("nvscaler/NVScaler.glsl"), target.readBytes())
        }
        assertEquals(listOf(unrelated), pending(target.parentFile), "only its own copy is cleaned up")
    }

    @Test
    fun aCopyThatCantReplaceTheTargetFailsWithoutAPartialPath() = runBlocking<Unit> {
        val target = File(cache, "nvscaler/NVScaler.glsl").apply { mkdirs() }
        File(target, "keep").writeText("x")
        assertFailsWith<IllegalStateException> { files.paths(listOf(ShaderFile.Bundled("nvscaler/NVScaler.glsl"))) }
        assertTrue(target.isDirectory)
        assertEquals(emptyList(), pending(target.parentFile))
    }

    @Test
    fun loadsAtOnceShareOneCopy() = runBlocking<Unit> {
        val nvscaler = listOf(ShaderFile.Bundled("nvscaler/NVScaler.glsl"))
        val results = List(4) { async(Dispatchers.Default) { files.paths(nvscaler) } }.awaitAll()
        assertEquals(1, results.distinct().size)
        assertEquals(1, reads)
        assertEquals(emptyList(), pending(File(cache, "nvscaler")))
    }

    @Test
    fun shadersShippedAsFilesRunWhereTheyAre() = runBlocking<Unit> {
        val shippedDir = File(root, "app/shaders/nvscaler").apply { mkdirs() }
        File(shippedDir, "NVScaler.glsl").writeText("//!HOOK LUMA\n")
        val direct = ShaderDirectories(ShaderRenderer.OPENGL, BundledShaders.Directory(File(root, "app/shaders").path), cache.path, custom.path, Dispatchers.Unconfined)
        assertEquals(listOf(File(shippedDir, "NVScaler.glsl").path), direct.paths(listOf(ShaderFile.Bundled("nvscaler/NVScaler.glsl"))))
        assertFalse(cache.exists(), "nothing copied")
    }

    @Test
    fun ambientLightingsShaderIsWrittenIntoTheCache() = runBlocking<Unit> {
        val path = files.ambientLighting()
        assertEquals(File(cache, "ambient_lighting.glsl").path, path)
        assertEquals(AmbientLightingShader.source, File(path).readText())
    }

    @Test
    fun anImportedShaderIsKeptUnderANewNameUntilDeleted() = runBlocking<Unit> {
        val name = files.import("//!HOOK LUMA\n")
        assertTrue(Regex("[0-9a-f-]+\\.glsl").matches(name), name)
        val copy = File(custom, name)
        assertEquals("//!HOOK LUMA\n", copy.readText())
        assertEquals(listOf(copy.path), files.paths(listOf(ShaderFile.Custom(name))))
        assertTrue(files.import("//!HOOK LUMA\n") != name, "each import gets its own file")
        files.delete(name)
        assertFalse(copy.exists())
        assertFailsWith<IllegalArgumentException> { files.paths(listOf(ShaderFile.Custom(name))) }
    }

    @Test
    fun theEarlierReleasesShorterNamesStillLoadAndDelete() = runBlocking<Unit> {
        val legacy = File(custom, "ks9p7.glsl").apply { parentFile.mkdirs(); writeText("legacy") }
        assertEquals(listOf(legacy.path), files.paths(listOf(ShaderFile.Custom("ks9p7.glsl"))))
        files.delete("ks9p7.glsl")
        assertFalse(legacy.exists())
    }

    @Test
    fun aNameThatIsntAnImportsReachesNoFile() = runBlocking<Unit> {
        val sentinel = File(root, "support/sentinel.glsl").apply { parentFile.mkdirs(); writeText("sentinel") }
        val nested = File(custom, "subdir/name.glsl").apply { parentFile.mkdirs(); writeText("nested") }
        val extra = File(custom, "name.glsl.txt").apply { writeText("extra") }
        for (name in listOf("../sentinel.glsl", sentinel.path, "subdir/name.glsl", "subdir\\name.glsl", ".", "..", "name.glsl.txt", "name.txt")) {
            assertFalse(isCustomShaderFileName(name), name)
            assertFailsWith<IllegalArgumentException>(name) { files.paths(listOf(ShaderFile.Custom(name))) }
            assertFailsWith<IllegalArgumentException>(name) { files.delete(name) }
        }
        assertEquals("sentinel", sentinel.readText())
        assertEquals("nested", nested.readText())
        assertEquals("extra", extra.readText())
        assertTrue(isCustomShaderFileName("ABC-1.GLSL"))
    }
}
