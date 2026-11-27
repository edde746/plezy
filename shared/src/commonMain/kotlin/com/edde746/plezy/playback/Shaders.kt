package com.edde746.plezy.playback

import com.edde746.plezy.log.Log
import com.edde746.plezy.settings.AppSettings
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import kotlinx.io.IOException
import kotlinx.io.buffered
import kotlinx.io.files.Path
import kotlinx.io.files.SystemFileSystem
import kotlinx.io.readByteArray
import kotlinx.io.writeString
import kotlinx.serialization.Serializable
import kotlin.uuid.Uuid

/**
 * The video shaders mpv runs over the picture (`glsl-shaders`): NVIDIA Image Scaling (NVScaler),
 * ArtCNN's luma doublers, Anime4K's modes, and shaders the viewer imported ([Custom]). This device keeps the one chosen
 * (`ScopedPlayerPrefs.shaderPreset`: per library or title, or `AppSettings.globalShaderPreset` everywhere) and the
 * imported ones (`AppSettings.customShaderPresets`): what a GPU can run, and the imported files, are the device's.
 */
sealed interface ShaderPreset {
    /** Stored in `ScopedPlayerPrefs.shaderPreset`; the ids of the built-in presets. */
    val id: String

    /** No shader. */
    data object Off : ShaderPreset {
        override val id = "none"
    }

    /** NVIDIA Image Scaling: sharper upscaling. Skipped on HDR video ([files]). */
    data object NvScaler : ShaderPreset {
        override val id = "nvscaler"
    }

    /** One of ArtCNN's real-time luma doublers. */
    data class ArtCnn(val model: ArtCnnModel, val variant: ArtCnnVariant) : ShaderPreset {
        override val id: String get() = "artcnn_${model.name.lowercase()}_${variant.slug}"
    }

    /** One of Anime4K's modes, with its fast (M) or high-quality (VL) networks. */
    data class Anime4k(val quality: Anime4kQuality, val mode: Anime4kMode) : ShaderPreset {
        override val id: String get() = "anime4k_${quality.slug}_${mode.slug}"
    }

    /** A shader the viewer imported. */
    data class Custom(val shader: CustomShader) : ShaderPreset {
        override val id: String get() = shader.id
    }

    companion object {
        /** Every built-in preset, in the menu's order. */
        val builtIn: List<ShaderPreset> = buildList {
            add(Off)
            add(NvScaler)
            for (model in ArtCnnModel.entries) for (variant in ArtCnnVariant.entries) add(ArtCnn(model, variant))
            for (quality in Anime4kQuality.entries) for (mode in Anime4kMode.entries) add(Anime4k(quality, mode))
        }

        /** The preset stored as [id], built-in or one of [custom]; [Off] for an id neither has (a deleted shader). */
        fun of(id: String, custom: List<CustomShader>): ShaderPreset =
            builtIn.firstOrNull { it.id == id } ?: custom.firstOrNull { it.id == id }?.let(::Custom) ?: Off

        /** The presets [renderer] runs, in the menu's order: the built-in ones it can run, then [custom] where it runs them. */
        fun available(renderer: ShaderRenderer, custom: List<CustomShader>): List<ShaderPreset> =
            (builtIn + custom.map(::Custom)).filter { it.runsOn(renderer) }

        /**
         * What the shader toggle (`G`) turns to from [current]: off when a shader runs; otherwise the stored preset
         * [saved], or the first of [available] when none is stored (NVScaler where it runs).
         */
        fun toggled(current: ShaderPreset, saved: ShaderPreset, available: List<ShaderPreset>): ShaderPreset = when {
            current != Off -> Off
            saved != Off -> saved
            else -> available.firstOrNull { it != Off } ?: Off
        }
    }
}

/**
 * The renderer that runs a device's shaders, which decides the presets it offers ([runsOn]): mpv's own OpenGL renderers
 * run fewer than libplacebo.
 */
enum class ShaderRenderer {
    /** libplacebo: Windows' `gpu-next`, the Apple apps' AVFoundation output. Every preset. */
    LIBPLACEBO,

    /**
     * mpv's own OpenGL renderer, the render API's on Linux, on an OpenGL ES 3 context. No NVScaler: GLSL ES converts no
     * integer to a float implicitly, which its compute pass relies on, so Mesa rejects it and the video shows none. No
     * ArtCNN: Mesa rejects the `#extension` its passes declare after mpv's own lines, and libmpv aborts on the failed
     * compute pass. No imported shaders, which can fail the same way.
     */
    OPENGL,

    /**
     * mpv's own OpenGL ES renderer, Android's GPU output, fed MediaCodec's frames as one RGB texture: no luma plane, so
     * only the presets that hook the whole picture (Anime4K's) and imported shaders. NVScaler and ArtCNN hook the luma.
     */
    OPENGL_ES,
}

/** [renderer] runs this preset ([ShaderRenderer]). */
fun ShaderPreset.runsOn(renderer: ShaderRenderer): Boolean = when (this) {
    ShaderPreset.Off, is ShaderPreset.Anime4k -> true
    ShaderPreset.NvScaler, is ShaderPreset.ArtCnn -> renderer == ShaderRenderer.LIBPLACEBO
    is ShaderPreset.Custom -> renderer.runsCustomShaders
}

/** This renderer runs imported shaders: mpv's OpenGL renderer may abort on one that fails to compile. */
val ShaderRenderer.runsCustomShaders: Boolean get() = this != ShaderRenderer.OPENGL

/** ArtCNN's model sizes: C4F16 the lighter, C4F32 the better. */
enum class ArtCnnModel(val label: String) { C4F16("C4F16"), C4F32("C4F32") }

/** ArtCNN's variants of each model: [slug] in the preset's id, [suffix] in its file's name. */
enum class ArtCnnVariant(internal val slug: String, internal val suffix: String) {
    NEUTRAL("neutral", ""),
    DENOISE("dn", "_DN"),
    DENOISE_SHARPEN("ds", "_DS"),
}

/** Anime4K's network sizes: fast (M) or high quality (VL). */
enum class Anime4kQuality(internal val slug: String, internal val network: String) { FAST("fast", "M"), HQ("hq", "VL") }

/** Anime4K's modes, each a chain of its restore and upscale shaders ([ShaderPreset.files]). */
enum class Anime4kMode(val label: String, internal val slug: String) {
    A("A", "modeA"),
    B("B", "modeB"),
    C("C", "modeC"),
    AA("A+A", "modeAA"),
    BB("B+B", "modeBB"),
    CA("C+A", "modeCA"),
}

/** A shader the viewer imported: its [name] (the file's, without `.glsl`) and its copy's [fileName] in [ShaderFiles]. */
@Serializable
data class CustomShader(val id: String, val name: String, val fileName: String)

/** One file of a shader chain: one of the app's own ([Bundled], by its path among them) or an imported one. */
sealed interface ShaderFile {
    data class Bundled(val path: String) : ShaderFile
    data class Custom(val fileName: String) : ShaderFile
}

/**
 * The files mpv runs for this preset, in order, on a video of [dynamicRange] (null before its first frame, taken as
 * SDR): NVScaler's one, none on HDR video; ArtCNN's one; Anime4K's highlight clamp, then its mode's restore (`A`) and
 * upscale (`C`) steps, with the downscale after an upscale; an imported shader's own file.
 */
fun ShaderPreset.files(dynamicRange: DynamicRange?): List<ShaderFile> = when (this) {
    ShaderPreset.Off -> emptyList()
    ShaderPreset.NvScaler ->
        if (dynamicRange != null && dynamicRange != DynamicRange.SDR) emptyList() else listOf(ShaderFile.Bundled("nvscaler/NVScaler.glsl"))
    is ShaderPreset.ArtCnn -> listOf(ShaderFile.Bundled("artcnn/ArtCNN_${model.label}${variant.suffix}.glsl"))
    is ShaderPreset.Anime4k -> {
        val restore = "anime4k/Anime4K_Restore_CNN_${quality.network}.glsl"
        val upscale = "anime4k/Anime4K_Upscale_CNN_x2_${quality.network}.glsl"
        val downscale = "anime4k/Anime4K_AutoDownscalePre_x2.glsl"
        val steps = when (mode) {
            Anime4kMode.A -> listOf(restore)
            Anime4kMode.B -> listOf(restore, upscale, downscale)
            Anime4kMode.C -> listOf(upscale, downscale)
            Anime4kMode.AA -> listOf(restore, restore)
            Anime4kMode.BB -> listOf(restore, restore, upscale, downscale)
            Anime4kMode.CA -> listOf(upscale, restore, downscale)
        }
        (listOf("anime4k/Anime4K_Clamp_Highlights.glsl") + steps).map(ShaderFile::Bundled)
    }
    is ShaderPreset.Custom -> listOf(ShaderFile.Custom(shader.fileName))
}

/**
 * This device's shaders: the [renderer] that runs them, and where their files are for mpv, the app's own, as it ships
 * them, the imported ones and ambient lighting's. Its calls read and write files, off the main thread.
 */
interface ShaderFiles {
    val renderer: ShaderRenderer

    /** The absolute paths of [files], in order, for mpv's `glsl-shaders`. */
    suspend fun paths(files: List<ShaderFile>): List<String>

    /** Keeps a copy of an imported shader's [source]; the copy's file name ([CustomShader.fileName]). */
    suspend fun import(source: String): String

    /** Deletes the imported shader [fileName]'s copy. */
    suspend fun delete(fileName: String)

    /** The absolute path of ambient lighting's shader ([AmbientLightingShader]), written there first. */
    suspend fun ambientLighting(): String
}

/** How the app ships its shaders ([ShaderFile.Bundled]). */
sealed interface BundledShaders {
    /** As files under [path], which mpv reads where they are. */
    data class Directory(val path: String) : BundledShaders

    /**
     * In a package mpv can't read (Android's assets): [read] gives a shader's bytes by its path among them, and each is
     * copied into the cache before it runs.
     */
    class Packaged(val read: (path: String) -> ByteArray) : BundledShaders
}

/**
 * [ShaderFiles] in directories. [bundled] shaders shipped in a package are copied into [cacheDirectory] at their paths
 * the first time this process runs each, checked byte for byte against the shipped one: a stale or truncated copy is
 * replaced by a complete one written beside it (`<name>.pending.<id>`) and renamed over it, so mpv never gets a path to
 * a partial file, and loads of the same file at once wait for the one copy. Ambient lighting's shader is written into
 * [cacheDirectory] the same way. [customDirectory] holds the imported shaders, each named by a random id.
 */
class ShaderDirectories internal constructor(
    override val renderer: ShaderRenderer,
    private val bundled: BundledShaders,
    private val cacheDirectory: String,
    private val customDirectory: String,
    private val io: CoroutineDispatcher,
) : ShaderFiles {
    constructor(renderer: ShaderRenderer, bundled: BundledShaders, cacheDirectory: String, customDirectory: String) :
        this(renderer, bundled, cacheDirectory, customDirectory, Dispatchers.IO)

    /** One copy at a time; the paths of the copies this process checked. */
    private val copying = Mutex()
    private val verified = mutableMapOf<String, Path>()

    override suspend fun paths(files: List<ShaderFile>): List<String> = withContext(io) {
        files.map { file ->
            when (file) {
                is ShaderFile.Bundled -> bundled(file.path)
                is ShaderFile.Custom -> custom(file.fileName)
            }.also { require(SystemFileSystem.exists(it)) { "No shader at $it" } }.toString()
        }
    }

    override suspend fun import(source: String): String = withContext(io) {
        SystemFileSystem.createDirectories(Path(customDirectory))
        val fileName = "${Uuid.random()}.glsl"
        SystemFileSystem.sink(custom(fileName)).buffered().use { it.writeString(source) }
        fileName
    }

    override suspend fun delete(fileName: String) = withContext(io) {
        SystemFileSystem.delete(custom(fileName), mustExist = false)
    }

    override suspend fun ambientLighting(): String = withContext(io) {
        cached(AMBIENT_LIGHTING_FILE) { AmbientLightingShader.source.encodeToByteArray() }.toString()
    }

    private suspend fun bundled(path: String): Path = when (bundled) {
        is BundledShaders.Directory -> Path(bundled.path, path)
        is BundledShaders.Packaged -> cached(path) { bundled.read(path) }
    }

    /** [path] in [cacheDirectory], holding exactly [bytes] once checked or copied there. */
    private suspend fun cached(path: String, bytes: () -> ByteArray): Path = copying.withLock {
        verified[path]?.takeIf { SystemFileSystem.exists(it) }?.let { return@withLock it }
        val target = Path(cacheDirectory, path)
        val expected = bytes()
        if (!holds(target, expected)) replace(target, expected)
        check(holds(target, expected)) { "Couldn't copy the shader $path to $target" }
        verified[path] = target
        target
    }

    /** Writes [bytes] beside [target] and renames the copy over it; the copy never stays behind. */
    private fun replace(target: Path, bytes: ByteArray) {
        target.parent?.let(SystemFileSystem::createDirectories)
        val pending = Path("$target.pending.${Uuid.random()}")
        try {
            SystemFileSystem.sink(pending).buffered().use { it.write(bytes) }
            try {
                SystemFileSystem.atomicMove(pending, target)
            } catch (e: IOException) {
                if (holds(target, bytes)) return
                SystemFileSystem.delete(target, mustExist = false)
                SystemFileSystem.atomicMove(pending, target)
            }
        } catch (e: IOException) {
            Log.w(TAG, e) { "Couldn't replace the shader at $target" }
        } finally {
            SystemFileSystem.delete(pending, mustExist = false)
        }
    }

    private fun holds(file: Path, bytes: ByteArray): Boolean {
        val metadata = SystemFileSystem.metadataOrNull(file) ?: return false
        if (!metadata.isRegularFile || metadata.size != bytes.size.toLong()) return false
        return SystemFileSystem.source(file).buffered().use { it.readByteArray() }.contentEquals(bytes)
    }

    /** Only a name an import could have given: a plain `.glsl` name, nothing outside [customDirectory]. */
    private fun custom(fileName: String): Path {
        require(isCustomShaderFileName(fileName)) { "Not an imported shader's name: $fileName" }
        return Path(customDirectory, fileName)
    }

    private companion object {
        const val TAG = "Shaders"
        const val AMBIENT_LIGHTING_FILE = "ambient_lighting.glsl"
    }
}

/**
 * [fileName] is one an import gives an imported shader's copy: letters, digits and dashes, then `.glsl` (a random id
 * now, a shorter one from the earlier releases), so it names a file directly in the imported shaders' directory.
 */
fun isCustomShaderFileName(fileName: String): Boolean = CUSTOM_SHADER_NAME.matches(fileName)

private val CUSTOM_SHADER_NAME = Regex("[A-Za-z0-9-]+\\.glsl", RegexOption.IGNORE_CASE)
