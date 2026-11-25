package com.edde746.plezy.playback.session

import com.edde746.plezy.data.settings.DolbyVisionConversion
import com.edde746.plezy.playback.AudioChannels
import com.edde746.plezy.playback.Downmix
import com.edde746.plezy.playback.EngineError
import com.edde746.plezy.playback.EngineErrorKind
import com.edde746.plezy.playback.EngineFeatures
import com.edde746.plezy.playback.EngineState
import com.edde746.plezy.playback.LoadRequest
import com.edde746.plezy.playback.PlayerEngine
import com.edde746.plezy.playback.PlayerEngineListener
import com.edde746.plezy.playback.SubtitleStyle
import com.edde746.plezy.playback.Track
import com.edde746.plezy.playback.TrackKind
import com.edde746.plezy.playback.VideoLayout

/**
 * An engine that behaves like mpv towards the session: it reports a new file opening, then open (its first frame up:
 * one playback restart, seekable), counts a restart per seek of an open file, and echoes track selections and added
 * subtitles in its track list. Tests move the position and raise errors with [report].
 */
internal class ScriptedEngine : PlayerEngine {
    private var listener: PlayerEngineListener? = null
    var state = EngineState()
        private set

    val loads = mutableListOf<LoadRequest>()
    val selections = mutableListOf<Pair<TrackKind, Long?>>()
    val secondSelections = mutableListOf<Long?>()
    val addedSubtitles = mutableListOf<Triple<String, String?, String?>>()
    val pauses = mutableListOf<Boolean>()
    val subtitleStyles = mutableListOf<SubtitleStyle>()
    var released = false
    var stops = 0

    /** The tracks the next [open] file has. */
    var fileTracks: List<Track> = emptyList()

    /**
     * How far a seek reaches in a file it can't seek in: the end of the last keyframe range its read-ahead holds whole
     * (`demuxer-cache-state`'s `seekable-ranges`, which the session isn't told). As mpv 0.41, a seek past it is refused
     * ("Cannot seek in this stream") and playback goes on; a seek before what it holds read
     * ([EngineState.cacheStartSeconds]) lands at its start. Null: every seek lands.
     */
    var seekableEnd: Double? = null

    /** Subtitle URLs that don't load: as mpv's `sub-add` of a dead link, adding one lists no track. */
    var deadSubtitles: Set<String> = emptySet()

    fun report(change: (EngineState) -> EngineState) {
        state = change(state)
        listener?.onState(state)
    }

    /** The last loaded file opens: [duration] long, at the load's start position. */
    fun open(duration: Double) {
        val start = loads.last().startSeconds
        report {
            it.copy(
                loaded = true, durationSeconds = duration, positionSeconds = start, tracks = fileTracks, buffering = false,
                seekable = true, playbackRestarts = 1,
            )
        }
    }

    fun play(position: Double) = report { it.copy(positionSeconds = position) }

    fun fail(message: String, httpStatus: Int? = null, kind: EngineErrorKind = EngineErrorKind.OTHER) =
        report { it.copy(loaded = false, error = EngineError(message, httpStatus, kind), tracks = emptyList()) }

    /** The state the last load replaced: what [refuse] makes current again. */
    private var outgoing: EngineState? = null

    /**
     * As mpv refusing the last load before it replaced the file: the load fails with [message], then the file it plays
     * on is current again under its own load id, the player's settings (pause, speed, volume, delays) as they are now.
     */
    fun refuse(message: String) {
        val before = checkNotNull(outgoing) { "no load to take back" }
        outgoing = null
        fail(message, kind = EngineErrorKind.OPEN)
        report {
            before.copy(
                paused = it.paused, speed = it.speed, volume = it.volume, muted = it.muted, audioDelaySeconds = it.audioDelaySeconds,
                subtitleDelaySeconds = it.subtitleDelaySeconds,
            )
        }
    }

    override fun load(request: LoadRequest): Long {
        loads += request
        val id = loads.size.toLong()
        outgoing = state
        report {
            it.copy(
                loadId = id, loaded = false, eof = false, error = null, buffering = true, positionSeconds = 0.0, tracks = emptyList(),
                playbackRestarts = 0, cacheStartSeconds = null, cacheEndSeconds = null, httpErrorStatus = null,
            )
        }
        return id
    }

    override fun setPaused(paused: Boolean) {
        pauses += paused
        // As mpv with keep-open: at the end of a file it pauses again on its own, until a load replaces the file.
        report { it.copy(paused = paused || it.eof) }
    }

    override fun seek(seconds: Double, exact: Boolean) {
        if (!state.seekable && seekableEnd?.let { seconds > it } == true) return
        val lands = if (state.seekable) seconds else state.cacheStartSeconds?.let { maxOf(seconds, it) } ?: seconds
        report { it.copy(positionSeconds = lands, playbackRestarts = if (it.loaded) it.playbackRestarts + 1 else it.playbackRestarts) }
    }
    override fun setSpeed(speed: Double) = report { it.copy(speed = speed) }
    override fun setSubtitleDelay(seconds: Double) = report { it.copy(subtitleDelaySeconds = seconds) }
    override fun setAudioDelay(seconds: Double) = report { it.copy(audioDelaySeconds = seconds) }
    override fun setSubtitleLift(fraction: Double) = Unit
    override fun setSubtitleStyle(style: SubtitleStyle) {
        subtitleStyles += style
    }
    override fun setVolume(volume: Double) = report { it.copy(volume = volume) }
    override fun setMuted(muted: Boolean) = report { it.copy(muted = muted) }
    override fun setVideoLayout(layout: VideoLayout) = Unit
    override fun setAudioNormalization(enabled: Boolean) = Unit
    override fun setAudioChannels(channels: AudioChannels, downmix: Downmix) = Unit
    override fun setShaders(paths: List<String>) = Unit
    override fun setAmbientLighting(shaderPath: String?) = Unit
    override fun setAudioDevice(name: String) = Unit
    override fun setStatsWanted(wanted: Boolean) = Unit

    override fun selectTrack(kind: TrackKind, id: Long?) {
        selections += kind to id
        // As mpv: the second subtitle's track can't be the first too.
        if (kind == TrackKind.SUBTITLE && state.tracks.any { it.kind == kind && it.id == id && it.secondary }) return
        report { s -> s.copy(tracks = s.tracks.map { if (it.kind == kind) it.copy(selected = it.id == id) else it }) }
    }

    override fun screenshot(onResult: (saved: Boolean) -> Unit) = onResult(false)

    override fun subtitleSeek(forward: Boolean) = Unit

    override val features = EngineFeatures()

    override fun setHdrOutput(enabled: Boolean, onResult: (applied: Boolean) -> Unit) = onResult(true)

    override fun setDolbyVisionConversion(mode: DolbyVisionConversion) = Unit

    /** As mpv's `stop`: the file goes, the engine reports nothing open. */
    override fun stop() {
        stops++
        report { it.copy(loaded = false, video = null, tracks = emptyList(), positionSeconds = 0.0, durationSeconds = 0.0) }
    }

    override fun selectSecondSubtitle(id: Long?) {
        secondSelections += id
        // As mpv: the first subtitle's track can't be the second too.
        if (state.tracks.any { it.kind == TrackKind.SUBTITLE && it.id == id && it.selected }) return
        report { s -> s.copy(tracks = s.tracks.map { if (it.kind == TrackKind.SUBTITLE) it.copy(secondary = it.id == id) else it }) }
    }

    override fun addSubtitle(url: String, title: String?, lang: String?) {
        addedSubtitles += Triple(url, title, lang)
        if (url in deadSubtitles) return
        report { s ->
            val id = (s.tracks.filter { it.kind == TrackKind.SUBTITLE }.maxOfOrNull { it.id } ?: 0) + 1
            s.copy(tracks = s.tracks + Track(id, TrackKind.SUBTITLE, title, lang, "subrip", selected = false, external = true, externalFilename = url))
        }
    }

    override fun setListener(listener: PlayerEngineListener?) {
        this.listener = listener
    }

    override fun release() {
        released = true
    }
}

internal fun track(
    id: Long,
    kind: TrackKind,
    language: String?,
    title: String? = null,
    selected: Boolean = false,
    forced: Boolean = false,
    default: Boolean = false,
    external: Boolean = false,
    hearingImpaired: Boolean = false,
    visualImpaired: Boolean = false,
    codec: String? = null,
    channels: Int? = null,
) = Track(
    id = id, kind = kind, title = title, language = language, codec = codec, selected = selected, external = external, isDefault = default,
    forced = forced, hearingImpaired = hearingImpaired, visualImpaired = visualImpaired, channels = channels,
)

/** An episode's tracks as a REMUX has them (`tools/media`'s remux.mkv); English audio playing. */
internal val EPISODE_1_TRACKS = listOf(
    track(1, TrackKind.AUDIO, "en", "English - TrueHD 5.1", selected = true, default = true, codec = "truehd", channels = 6),
    track(2, TrackKind.AUDIO, "de", "Deutsch - AC-3 5.1", codec = "ac3", channels = 6),
    track(3, TrackKind.AUDIO, "en", "Commentary - AAC 2.0", codec = "aac", channels = 2),
    track(1, TrackKind.SUBTITLE, "en", "English (forced)", forced = true, default = true, codec = "hdmv_pgs_subtitle"),
    track(2, TrackKind.SUBTITLE, "en", "English", codec = "hdmv_pgs_subtitle"),
    track(3, TrackKind.SUBTITLE, "en", "English (SDH)", hearingImpaired = true, codec = "hdmv_pgs_subtitle"),
    track(4, TrackKind.SUBTITLE, "es", "Español", codec = "ass"),
    track(5, TrackKind.SUBTITLE, "fr", "Français", codec = "subrip"),
)

/** The next episode's (`tools/media`'s remux-next.mkv): the same kinds of tracks in another order, so other ids. */
internal val EPISODE_2_TRACKS = listOf(
    track(1, TrackKind.AUDIO, "en", "English - AAC 2.0", selected = true, default = true, codec = "aac", channels = 2),
    track(2, TrackKind.AUDIO, "en", "Commentary - AAC 2.0", codec = "aac", channels = 2),
    track(3, TrackKind.AUDIO, "de", "Deutsch - AAC 2.0", codec = "aac", channels = 2),
    track(1, TrackKind.SUBTITLE, "en", "English (SDH)", hearingImpaired = true, codec = "subrip"),
    track(2, TrackKind.SUBTITLE, "fr", "Français", codec = "subrip"),
    track(3, TrackKind.SUBTITLE, "en", "English", codec = "subrip"),
    track(4, TrackKind.SUBTITLE, "en", "English (forced)", forced = true, default = true, codec = "subrip"),
    track(5, TrackKind.SUBTITLE, "es", "Español", codec = "ass"),
)

/** The track of [kind] with [id]. */
internal fun List<Track>.withId(kind: TrackKind, id: Long): Track = single { it.kind == kind && it.id == id }
