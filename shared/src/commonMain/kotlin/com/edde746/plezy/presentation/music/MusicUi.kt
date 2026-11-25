package com.edde746.plezy.presentation.music

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.backend.localizedErrorReason
import com.edde746.plezy.format.formatTimecode
import com.edde746.plezy.image.Artwork
import com.edde746.plezy.image.ImageKind
import com.edde746.plezy.model.LyricLine
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.music.MusicPlayContext
import com.edde746.plezy.music.MusicPlayContextKind
import com.edde746.plezy.music.MusicRepeatMode
import com.edde746.plezy.music.MusicState
import com.edde746.plezy.music.engine.AudioPlayerInitializationException
import com.edde746.plezy.presentation.player.sleepTimerMinutes
import com.edde746.plezy.strings.T
import kotlin.math.min
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.minutes

/** [item]'s square artwork: its own, else its album's (a track without art of its own). */
internal fun MediaBackend?.squareArtwork(item: MediaItem): Artwork? =
    Artwork.of(this, item.thumbPath ?: item.parentThumbPath.takeIf { item.kind == MediaKind.TRACK }, ImageKind.SQUARE)

/** A track as Now Playing and the mini-player show it. */
data class MusicTrackUi(
    /** Server and id: the same id on another server is another track. */
    val globalKey: String,
    val title: String,
    /** The performing artist (the album artist when the track names none); null hides the line. */
    val artist: String?,
    /** Square artwork, null for the music note. */
    val artwork: Artwork?,
    /** The artist line opens the artist ([MusicScreens.openArtist]). */
    val artistLinked: Boolean,
)

internal fun MediaItem.toTrackUi(backend: MediaBackend?): MusicTrackUi = MusicTrackUi(
    globalKey = globalKey,
    title = title.orEmpty(),
    artist = trackArtistTitle?.takeIf { it.isNotEmpty() },
    artwork = backend.squareArtwork(this),
    artistLinked = grandparentId != null && backend != null,
)

/**
 * Where the queue came from, for "Playing from …": album and ad-hoc queues (and none) follow the current track's album
 * and its year, so the line changes as the queue crosses albums; artist, playlist, mix and library keep their own title.
 * Null: the line hides.
 */
fun playingFromTitle(track: MediaItem, context: MusicPlayContext?): String? {
    val followsAlbum = context == null || context.kind == MusicPlayContextKind.ALBUM || context.kind == MusicPlayContextKind.TRACKS
    val title = (if (followsAlbum) track.albumTitle else context?.title)?.trim()
    if (title.isNullOrEmpty()) return null
    val year = track.albumYear
    return if (followsAlbum && year != null) bulleted(listOf(title, year.toString())) else title
}

/** [parts] joined by " · ". */
internal fun bulleted(parts: List<String>): String = parts.joinToString(" · ")

/** The repeat button's next mode: off, all, one, off. */
val MusicRepeatMode.next: MusicRepeatMode
    get() = when (this) {
        MusicRepeatMode.OFF -> MusicRepeatMode.ALL
        MusicRepeatMode.ALL -> MusicRepeatMode.ONE
        MusicRepeatMode.ONE -> MusicRepeatMode.OFF
    }

/** The repeat button's name for [this] mode. */
val MusicRepeatMode.label: String
    get() = when (this) {
        MusicRepeatMode.OFF -> T.music.repeat
        MusicRepeatMode.ALL -> T.music.repeatAll
        MusicRepeatMode.ONE -> T.music.repeatOne
    }

/**
 * What a failure mid-playback says: the audio core failing to start is "Playback failed", anything else names its
 * reason; never an exception's class name.
 */
fun musicErrorText(error: Throwable): String =
    if (error is AudioPlayerInitializationException) T.messages.playbackFailed else T.messages.errorLoading(localizedErrorReason(error))

/** `m:ss`, or `h:mm:ss` from an hour. */
internal fun timestamp(duration: Duration): String = formatTimecode(duration.inWholeMilliseconds / 1000.0)

/** A sleep timer preset ([sleepTimerOptions]). */
sealed interface SleepTimerChoice {
    data object Off : SleepTimerChoice
    data class Minutes(val minutes: Int) : SleepTimerChoice
    data object EndOfTrack : SleepTimerChoice
}

/** One entry of the sleep timer sheet; only the armed preset is [selected]. */
data class SleepTimerOptionUi(val choice: SleepTimerChoice, val label: String, val selected: Boolean)

/**
 * The sleep timer's entries, as the video player offers them: Off and End of track ("Stop at"), then the durations
 * ([sleepTimerMinutes]: the configured [defaultMinutes] among them), the armed one selected.
 */
fun sleepTimerOptions(state: MusicState, defaultMinutes: Int): List<SleepTimerOptionUi> {
    val timed = state.sleepTimerActive && !state.sleepTimerEndOfTrack
    return buildList {
        add(SleepTimerOptionUi(SleepTimerChoice.Off, T.common.off, !state.sleepTimerActive))
        add(SleepTimerOptionUi(SleepTimerChoice.EndOfTrack, T.music.sleepTimerEndOfTrack, state.sleepTimerEndOfTrack))
        for (minutes in sleepTimerMinutes(defaultMinutes)) {
            add(SleepTimerOptionUi(SleepTimerChoice.Minutes(minutes), T.music.sleepTimerMinutes(minutes.toString()), timed && state.sleepTimerDuration == minutes.minutes))
        }
    }
}

/**
 * The lyric line playing at [positionMs]: the last whose start is at or before it, −1 before the first. Lines without
 * a start never become active; a list with such holes is walked line by line instead of searched.
 */
fun activeLyricLine(lines: List<LyricLine>, positionMs: Long): Int {
    if (lines.isEmpty()) return -1
    if (lines.any { it.startMs == null }) return lines.indexOfLast { line -> line.startMs.let { it != null && it <= positionMs } }
    var low = 0
    var high = lines.lastIndex
    var best = -1
    while (low <= high) {
        val mid = (low + high) ushr 1
        if (lines[mid].startMs!! <= positionMs) {
            best = mid
            low = mid + 1
        } else {
            high = mid - 1
        }
    }
    return best
}

/** Now Playing's three layouts. */
enum class NowPlayingLayout {
    /** Artwork over the track's details and transport. */
    PORTRAIT,

    /** Artwork beside the details, transport and the queue, inline (desktop, tablets in landscape). */
    WIDE,

    /** The TV's: artwork beside the details, transport and a queue button. */
    TV,
}

/** The layout for a window of [width] × [height] (any unit): TV on a TV, wide from 800 across in landscape. */
fun nowPlayingLayout(tv: Boolean, width: Double, height: Double): NowPlayingLayout = when {
    tv -> NowPlayingLayout.TV
    width >= 800 && width > height -> NowPlayingLayout.WIDE
    else -> NowPlayingLayout.PORTRAIT
}

/** The square artwork's side in a [width] × [height] box: 85 % of the width at most; on TV 62 % of the height. */
fun nowPlayingArtworkSide(layout: NowPlayingLayout, width: Double, height: Double): Double =
    if (layout == NowPlayingLayout.TV) min(width, height * 0.62) else min(width * 0.85, height)

/** The volume icon's level: muted at 0, low under 50, high from there. */
enum class VolumeLevel { OFF, LOW, HIGH }

fun volumeLevel(volume: Double): VolumeLevel = when {
    volume <= 0 -> VolumeLevel.OFF
    volume < 50 -> VolumeLevel.LOW
    else -> VolumeLevel.HIGH
}

/**
 * One track of a list (an album, a playlist, the queue): `[number | equalizer | artwork] title, subtitle … duration ⋮`.
 * The equalizer shows on the row whose [globalKey] is the current track's (the queue marks its row by position instead,
 * [QueueUi.currentIndex]). A playlist's rows, whose tracks come from many albums, carry each track's [artwork].
 */
data class TrackRowUi(
    /** The track's index in the list it came from. */
    val index: Int,
    /** Unique in the list, stable across reorders: the same track twice gets two keys. */
    val key: String,
    val globalKey: String,
    val title: String,
    /** The performing artist where it adds something; null hides the line. */
    val subtitle: String?,
    /** The album's track number; null for none (the queue never shows it). */
    val trackNumber: String?,
    val duration: String?,
    /** First and last of their group: the grouped card's outer corners. */
    val isFirst: Boolean,
    val isLast: Boolean,
    /** Already played (the queue's history). */
    val dimmed: Boolean = false,
    /**
     * The track's square artwork where the list shows it (a playlist's, the queue's); null shows the number or nothing
     * (the queue: a placeholder).
     */
    val artwork: Artwork? = null,
)

/**
 * The line under a track's title: its artist always when [showArtist] (lists outside an album), else only where it
 * differs from the album's artist (a compilation).
 */
internal fun trackSubtitle(track: MediaItem, showArtist: Boolean): String? {
    val artist = track.trackArtistTitle?.takeIf { it.isNotEmpty() } ?: return null
    return if (showArtist || artist != track.albumArtistTitle) artist else null
}

/** [tracks] as rows keyed by global key and occurrence (a queue can hold one track twice). */
internal fun trackRows(
    tracks: List<MediaItem>,
    showArtist: Boolean,
    showTrackNumber: Boolean,
    subtitle: (MediaItem) -> String? = { trackSubtitle(it, showArtist) },
    dimmedBefore: Int = 0,
): List<TrackRowUi> {
    val seen = HashMap<String, Int>()
    return tracks.mapIndexed { index, track ->
        val occurrence = seen.getOrElse(track.globalKey) { 0 }.also { seen[track.globalKey] = it + 1 }
        TrackRowUi(
            index = index,
            key = "${track.globalKey}#$occurrence",
            globalKey = track.globalKey,
            title = track.title.orEmpty(),
            subtitle = subtitle(track),
            trackNumber = if (showTrackNumber) track.trackNumber?.toString() else null,
            duration = track.durationMs?.let { timestamp(it.milliseconds) },
            isFirst = index == 0,
            isLast = index == tracks.lastIndex,
            dimmed = index < dimmedBefore,
        )
    }
}

/** An album's list: its tracks, with a "Disc N" header before each disc's when it spans several. */
sealed interface AlbumRow {
    data class DiscHeader(val disc: Int, val label: String) : AlbumRow
    data class Track(val row: TrackRowUi) : AlbumRow
}

/** [tracks] (in disc and track order) as an album lists them; corners per disc group on a multi-disc album. */
fun albumRows(tracks: List<MediaItem>): List<AlbumRow> {
    val discs = tracks.map { it.discNumber ?: 1 }
    val multiDisc = discs.toSet().size > 1
    val rows = trackRows(tracks, showArtist = false, showTrackNumber = true)
    return buildList {
        rows.forEachIndexed { i, row ->
            val disc = discs[i]
            val newDisc = i == 0 || discs[i - 1] != disc
            val lastOfDisc = i == rows.lastIndex || discs[i + 1] != disc
            if (multiDisc && newDisc) add(AlbumRow.DiscHeader(disc, T.music.discNumber(disc.toString())))
            add(AlbumRow.Track(if (multiDisc) row.copy(isFirst = newDisc, isLast = lastOfDisc) else row))
        }
    }
}
