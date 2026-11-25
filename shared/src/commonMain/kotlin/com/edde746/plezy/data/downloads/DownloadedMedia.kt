package com.edde746.plezy.data.downloads

import com.edde746.plezy.backend.TranscodeQualityPreset
import com.edde746.plezy.data.db.Downloaded_media
import kotlinx.serialization.SerializationException
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonArray

/** Where a download in `downloaded_media` stands; its [ordinal] is the stored `status`. */
enum class DownloadedMediaStatus {
    QUEUED,
    DOWNLOADING,
    PAUSED,
    COMPLETED,
    FAILED,
    CANCELLED,
    PARTIAL,
    ;

    /** The stored `status` value. */
    val code: Long get() = ordinal.toLong()

    companion object {
        /** The status stored as [code], or null for a value no status has. */
        fun of(code: Long): DownloadedMediaStatus? = if (code in 0L..<entries.size.toLong()) entries[code.toInt()] else null
    }
}

/** The row's status, or null when it holds a value no status has. */
internal val Downloaded_media.downloadStatus: DownloadedMediaStatus? get() = DownloadedMediaStatus.of(status)

/** The quality the row downloads: the original file, or a server transcode. */
internal val Downloaded_media.transcodeQuality: TranscodeQualityPreset get() = storedTranscodeQuality(transcode_quality)

/**
 * The stored path of each file after the first of a version stacked across several files, null while that file isn't
 * stored yet. Null for a single-file download.
 */
internal val Downloaded_media.additionalPartPathList: List<String?>? get() = decodeAdditionalPartPaths(additional_part_paths)

/** How many files the downloaded version is stacked across. */
internal val Downloaded_media.partCount: Int get() = 1 + (additionalPartPathList?.size ?: 0)

/** The stored path of file [partIndex] (0-based), or null when that file isn't stored or the download has no such file. */
internal fun Downloaded_media.storedPartPath(partIndex: Int): String? {
    if (partIndex == 0) return video_file_path
    val paths = additionalPartPathList ?: return null
    if (partIndex < 0 || partIndex > paths.size) return null
    return paths[partIndex - 1]
}

/** Every stored file, in playback order. */
internal val Downloaded_media.storedPartPaths: List<String> get() = listOfNotNull(video_file_path) + additionalPartPathList.orEmpty().filterNotNull()

/** The first file not stored yet, the one the download fetches next, or null once every file is stored. */
internal val Downloaded_media.nextMissingPartIndex: Int?
    get() {
        if (video_file_path == null) return 0
        val missing = additionalPartPathList?.indexOf(null) ?: -1
        return if (missing < 0) null else missing + 1
    }

/**
 * Reads the stored `additional_part_paths`: a JSON array of paths, null entries for files not stored yet. A value that
 * isn't a non-empty array reads as a single-file download (null); an entry that isn't a non-empty string reads as not stored.
 */
fun decodeAdditionalPartPaths(json: String?): List<String?>? {
    if (json == null) return null
    val decoded = try {
        Json.parseToJsonElement(json)
    } catch (e: SerializationException) {
        // A malformed value reads as a single file, like any other value that isn't an array.
        return null
    }
    if (decoded !is JsonArray || decoded.isEmpty()) return null
    return decoded.map { entry -> (entry as? JsonPrimitive)?.takeIf { it.isString }?.content?.takeIf { it.isNotEmpty() } }
}

/** The stored form of [paths]: null for a single-file download (null or empty). */
fun encodeAdditionalPartPaths(paths: List<String?>?): String? {
    if (paths.isNullOrEmpty()) return null
    return buildJsonArray { paths.forEach { add(if (it == null) JsonNull else JsonPrimitive(it)) } }.toString()
}
