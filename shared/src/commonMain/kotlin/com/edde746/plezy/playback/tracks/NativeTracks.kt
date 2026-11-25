package com.edde746.plezy.playback.tracks

import com.edde746.plezy.backend.AudioTrackPreference
import com.edde746.plezy.backend.SubtitleSidecar
import com.edde746.plezy.model.titleSaysForced
import com.edde746.plezy.playback.Track
import com.edde746.plezy.playback.TrackKind

/**
 * An audio track as the player lists it. [id] is the player's own id ("1", "2"…), `source:<id>` for a track the
 * player names by the server's stream id, or one of the sentinels [AUTO] and [OFF], which are never real tracks.
 */
data class NativeAudioTrack(
    val id: String,
    val title: String? = null,
    val language: String? = null,
    val codec: String? = null,
    /** The codec's profile as FFmpeg names it ("DTS-HD MA"); names the DTS variant in labels. */
    val codecProfile: String? = null,
    val channels: Int? = null,
    val isDefault: Boolean = false,
    val isForced: Boolean = false,
) {
    /** Not a sentinel: a track the file has. */
    val isReal: Boolean get() = id != AUTO.id && id != OFF.id

    /** What a server's playback negotiation needs of this track to pick the same one on another item. */
    fun toPreference(): AudioTrackPreference = AudioTrackPreference(language = language, title = title, codec = codec, channels = channels)

    companion object {
        val AUTO = NativeAudioTrack(id = "auto", title = "Auto")
        val OFF = NativeAudioTrack(id = "no", title = "Off")
    }
}

/**
 * A subtitle track as the player lists it; ids as [NativeAudioTrack]'s. [isExternal]: loaded from a file of its own
 * ([uri]). [isContainer]: one of several tracks the player extracted from a sidecar container, which keep the source
 * container's order but have no stable id.
 */
data class NativeSubtitleTrack(
    val id: String,
    val title: String? = null,
    val language: String? = null,
    val codec: String? = null,
    val isDefault: Boolean = false,
    val isForced: Boolean = false,
    val isExternal: Boolean = false,
    val isContainer: Boolean = false,
    val uri: String? = null,
) {
    /** Not a sentinel: a track the file or a sidecar has. */
    val isReal: Boolean get() = id != AUTO.id && id != OFF.id

    /** Forced-ness as the servers treat it: the flag, or a title that says "forced". */
    val effectiveForced: Boolean get() = isForced || titleSaysForced(title)

    companion object {
        val AUTO = NativeSubtitleTrack(id = "auto", title = "Auto")
        val OFF = NativeSubtitleTrack(id = "no", title = "Off")

        /** The track a subtitle file at [uri] becomes once the player loaded it. */
        fun fromUri(
            uri: String,
            title: String? = null,
            language: String? = null,
            codec: String? = null,
            isDefault: Boolean = false,
            isForced: Boolean = false,
            isContainer: Boolean = false,
        ) = NativeSubtitleTrack(
            id = "external:$uri",
            title = title,
            language = language,
            codec = codec,
            isDefault = isDefault,
            isForced = isForced,
            isExternal = true,
            isContainer = isContainer,
            uri = uri,
        )
    }
}

/** The player's track lists and what it plays from them; a null selection is none known. */
data class NativeTracks(
    val audio: List<NativeAudioTrack> = emptyList(),
    val subtitle: List<NativeSubtitleTrack> = emptyList(),
    val selectedAudio: NativeAudioTrack? = null,
    val selectedSubtitle: NativeSubtitleTrack? = null,
    val selectedSecondarySubtitle: NativeSubtitleTrack? = null,
) {
    val realAudio: List<NativeAudioTrack> get() = audio.filter { it.isReal }
    val realSubtitle: List<NativeSubtitleTrack> get() = subtitle.filter { it.isReal }
}

/** The track a sidecar file becomes once the player loaded it. */
fun SubtitleSidecar.toNativeTrack(): NativeSubtitleTrack =
    NativeSubtitleTrack.fromUri(url, title = title, language = language, codec = codec, isDefault = isDefault, isForced = forced)

/** [this] engine audio track as the selection rules see it. */
fun Track.toNativeAudioTrack(): NativeAudioTrack {
    require(kind == TrackKind.AUDIO) { "Not an audio track: $kind" }
    return NativeAudioTrack(
        id = id.toString(),
        title = title,
        language = language,
        codec = codec,
        codecProfile = codecProfile,
        channels = channels,
        isDefault = isDefault,
        isForced = forced,
    )
}

/** [this] engine subtitle track as the selection rules see it; [uri] the file it was loaded from, when external. */
fun Track.toNativeSubtitleTrack(uri: String? = null): NativeSubtitleTrack {
    require(kind == TrackKind.SUBTITLE) { "Not a subtitle track: $kind" }
    return NativeSubtitleTrack(
        id = id.toString(),
        title = title,
        language = language,
        codec = codec,
        isDefault = isDefault,
        isForced = forced,
        isExternal = external,
        uri = uri,
    )
}

/** The engine id of a track [NativeAudioTrack.id]/[NativeSubtitleTrack.id] names; null for sentinels and other ids. */
fun engineTrackId(nativeId: String): Long? = nativeId.toLongOrNull()

/** The server stream id a `source:<id>` track id names, else null. */
fun sourceStreamIdOf(nativeId: String): Int? =
    if (nativeId.startsWith(SOURCE_PREFIX)) nativeId.removePrefix(SOURCE_PREFIX).toIntOrNull() else null

/** The track id naming server stream [id]. */
fun sourceTrackId(id: Int): String = "$SOURCE_PREFIX$id"

private const val SOURCE_PREFIX = "source:"
