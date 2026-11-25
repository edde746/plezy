package com.edde746.plezy.playback.session

import com.edde746.plezy.backend.ScrubPreviewSource
import com.edde746.plezy.backend.TranscodeQualityPreset
import com.edde746.plezy.data.settings.SkipMode
import com.edde746.plezy.input.VideoClickAction
import com.edde746.plezy.model.MediaFileInfo
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.playback.EngineState
import com.edde746.plezy.playback.PlaybackFailure
import com.edde746.plezy.playback.SkipKind
import com.edde746.plezy.playback.SkipSegment
import com.edde746.plezy.playback.TrackKind
import kotlinx.coroutines.flow.StateFlow
import kotlin.time.DurationUnit
import kotlin.time.TimeMark

/**
 * What the player store needs from the playback session: the session owns the engine (it loads the files, listens to
 * the engine and saves progress), and the store only renders it and turns input into engine commands and these
 * actions.
 *
 * Failures: the session decides what is shown. A failure it recovers from never reaches [SessionInfo.failure]; a
 * failure it gives up on does.
 *
 * A command a session has nothing to act on for (a URL's video has no episodes, live no versions) does nothing.
 */
interface PlayerSession {
    /** The engine's latest state, as the session takes it. */
    val engineState: StateFlow<EngineState>

    val info: StateFlow<SessionInfo>

    /** Try the current video again, reloaded at the last position. */
    fun retry()

    /** Play [SessionInfo.nextEpisode]. */
    fun playNextEpisode() {}

    /** Play the episode before this one ([SessionInfo.hasPreviousEpisode]), or, with none, restart this video. */
    fun playPreviousEpisode()

    /**
     * The user moved the position to [seconds]; the store calls this right before it sends the seek to the engine,
     * so the session saves the progress up to the old position and records the jump as a seek, not as time watched.
     */
    fun onSeek(seconds: Double) {}

    /**
     * The user picked track [id] of [kind] (null: none, subtitles off); the session stops choosing that kind for the
     * current file and carries the pick to the title's next files.
     */
    fun onTrackSelected(kind: TrackKind, id: Long?) {}

    /**
     * The user picked subtitle track [id] as the second subtitle (null: off); the session stops choosing the second
     * subtitle for the current file and carries the pick to the title's next files, as [onTrackSelected] does.
     */
    fun onSecondSubtitleSelected(id: Long?) {}

    /**
     * The user picked [SessionInfo.moreSubtitles]' subtitle at [url]: the session adds it to the file and selects it
     * once the engine lists it, as a pick of the user's ([onTrackSelected]).
     */
    fun addSubtitle(url: String) {}

    /** The user turned auto-play of the next episode on or off in the player: [NextEpisode.autoplay] follows at once. */
    fun setAutoPlayNext(enabled: Boolean) {}

    /**
     * Moves a live playback with a rewind window ([SessionInfo.liveWindow]) to [behindSeconds] behind the live edge
     * (0: the edge, "go to live", where an open lands, a few segments back): by a seek within what the engine has read
     * ahead of the position or holds behind it, else by opening the stream again at the segment that holds it
     * ([LiveWindow]). Nothing about it is saved.
     */
    fun seekLive(behindSeconds: Double) {}

    /** Reopen the video at the position in version [index] of [SessionInfo.versions], remembered for the title. */
    fun selectVersion(index: Int) {}

    /**
     * Reopen the video at the position at quality [preset] ([SessionInfo.quality]); a quality picked here outranks a
     * download of the video for the rest of the player.
     */
    fun selectQuality(preset: TranscodeQualityPreset) {}

    /**
     * The user picked the server's track [id] of [kind] ([SessionInfo.sourceAudio] / [SessionInfo.sourceSubtitles];
     * null: subtitles off), the pick carried as [onTrackSelected]'s. A subtitle the engine already has (a sidecar, or
     * the file's own track while nothing is burned in) is selected in place; otherwise the server's selection changes
     * and the transcode (or burned-in subtitle) reopens at the position.
     */
    fun selectSourceTrack(kind: TrackKind, id: Int?) {}

    /**
     * The subtitle shortcut while [SessionInfo.sourceSubtitles] are the choice: the next of [off, each of them]. Presses
     * made while a switch or a reload runs add up and apply as one switch once it ended.
     */
    fun cycleSourceSubtitles() {}

    /** Retry a file the server refused to play as it is ([PlaybackFailure.ServerLimit]) transcoded, at the position. */
    fun forceTranscode() {}

    /** Play [SessionInfo.queue]'s entry [key]. */
    fun playQueueItem(key: String) {}

    /** The server's subtitle providers' subtitles in [language] (ISO 639-1) for [title] (null: the video's). */
    suspend fun searchSubtitles(language: String, title: String?): List<SubtitleSearchHit>

    /** Has the server download the search's subtitle [key] and switches to it once the server lists it. */
    suspend fun downloadSubtitle(key: String): SubtitleDownloadOutcome

    /** The open file's info (container, streams, file), or null where the server has none. */
    suspend fun loadFileInfo(): MediaFileInfo?

    /** The user moved the audio ([audio]) or subtitle sync offset to [seconds]: kept for the title. */
    fun onSyncOffsetChanged(audio: Boolean, seconds: Double) {}

    /** The user changed the speed: kept for the title's scope. */
    fun onSpeedChanged(speed: Double) {}

    /**
     * Leaves the video (its last progress saved and reported stopped), releases the engine and ends the session; the
     * last reports complete in the background. The app calls it once, as the player closes.
     */
    fun close()

    /**
     * The viewer answered [SessionInfo.choice] with its option [index]; null dismissed it (Back). The session takes
     * [SessionInfo.choice] away once answered.
     */
    fun answerChoice(index: Int?) {}

    /**
     * Fails the open file as the engine reporting the server's HTTP [status] for its stream would (a development build's
     * player entry): the failure the player shows for that status, as a real one takes it.
     */
    fun simulateHttpError(status: Int)

    /**
     * The app sat in the background on a TV with the video paused: an on-demand video gives the engine's decoders back
     * (it unloads), ends its server session and keeps where it was for [restoreAfterBackground]; false while it can't
     * yet (a reload or the first frame on its way: ask again later). A live stream keeps its stream (its buffer is
     * the time shift), and a URL's video has no server session: neither suspends.
     */
    fun suspendInBackground(): Boolean = true

    /**
     * The app is back after [suspendInBackground]: the video opens again where it was, paused; returns once it opened
     * or failed.
     */
    suspend fun restoreAfterBackground() {}
}

/** One subtitle a server's providers have ([PlayerSession.searchSubtitles]): [label] its name, [detail] provider and flags. */
data class SubtitleSearchHit(val key: String, val label: String, val detail: String?)

/** A message the player shows as its toast ([SessionInfo.notice]); a new [serial] shows the same text again. */
data class SessionNotice(val text: String, val serial: Int)

/** A question the session asks the viewer ([SessionInfo.choice]): [title] and the [options] it offers, in order. */
data class SessionChoice(val title: String, val options: List<String>)

/**
 * How a subtitle download ended ([PlayerSession.downloadSubtitle]); a failed download throws instead. [APPLIED]: the
 * server listed it and it shows; [NOT_APPLIED]: listed but couldn't be selected; [TIMED_OUT]: not listed in time.
 */
enum class SubtitleDownloadOutcome { APPLIED, NOT_APPLIED, TIMED_OUT }

/** A version of the video as the version sheet lists it: [label] ("4K · HEVC · 58 Mbps"), [detail] its file name. */
data class VersionOption(val label: String, val detail: String? = null)

/**
 * The quality column (the presets of `PlayerStates.qualities`): [selected] the one playing; [sourceBitrateKbps] labels
 * the original; [sourceDurationMs] sizes each row; [sourceHeightPx] with the bitrate drops the
 * presets the source already fits under.
 */
data class QualityChoice(
    val selected: TranscodeQualityPreset,
    val sourceBitrateKbps: Int? = null,
    val sourceDurationMs: Long? = null,
    val sourceHeightPx: Int? = null,
)

/** One of the server's tracks of the source ([SessionInfo.sourceAudio]): its server [id], its [label] and [detail]. */
data class SourceTrack(val id: Int, val label: String, val detail: String? = null, val selected: Boolean = false)

/** A chapter the server lists, with its thumbnail ([imageUrl]; a download's saved one first). */
data class SessionChapter(val title: String?, val startSeconds: Double, val endSeconds: Double? = null, val imageUrl: String? = null)

/**
 * One entry of what plays around this video ([SessionInfo.queue]): a play queue's, the season's or a playlist's.
 * [spoiler]: an unwatched episode whose title and image the profile's hide-spoilers setting blanks.
 */
data class QueueEntry(
    val key: String,
    val title: String,
    val subtitle: String? = null,
    val imageUrl: String? = null,
    val current: Boolean = false,
    val spoiler: Boolean = false,
)

/**
 * @param title the headline, formatted by the session (the movie or series name).
 * @param subtitle the secondary line, formatted by the session (`S1E2 · Pilot`), or null.
 * @param artworkUrl the image the OS media controls show ([com.edde746.plezy.presentation.player.NowPlaying]); null
 *   when there is none.
 * @param posterUrl the poster (an episode's series poster), the image Discord shows
 *   ([com.edde746.plezy.presentation.player.DiscordActivity]); null when there is none.
 * @param resolving the session is still getting the video's playable URL from its server; shown apart from buffering.
 * @param episode the video is one of a series' episodes: the controls show the previous and next buttons, as for an
 *   item of a [queue] ([com.edde746.plezy.presentation.player.EpisodeButtons]).
 * @param trailer the video is a trailer of the title.
 * @param nextEpisode what plays next, when there is a next episode; null again as another item opens, until its own
 *   lookup lands.
 * @param hasPreviousEpisode there is an episode before this one ([PlayerSession.playPreviousEpisode]); false again as
 *   another item opens, until its own lookup lands.
 * @param skipping what the player does with intros, recaps and credits ([SkipModes]); a change to the settings reaches
 *   it while the video plays.
 * @param videoClick what a click on the video does with a mouse, followed while the video plays as [skipping] is.
 * @param moreSubtitles the subtitles found for the open file and not added to it ([PlayerSession.addSubtitle]), in
 *   the order found; empty before the file opens and its subtitles are found.
 * @param local the video plays from a file on this device (a download): the info panel says so and shows no network.
 * @param live the playback is live: the title is, or the engine's reports say the open file is a live stream (while
 *   it can't seek in it, its duration grows past the first one reported or, without one, its position runs on; a
 *   duration that comes where there was none is the file's length, not growth; a video from a server without Range
 *   support can't be seeked in either, but its duration stays put, and a still image has no duration and its position
 *   stays put), latched for the file. Nothing seeks outside [liveWindow], nothing about the position is saved, and no
 *   credits, skip or up next show.
 * @param liveWindow the live file's rewind window, read from its HLS playlist: set while the playlist reaches at least
 *   [LiveWindow.MIN_SECONDS] back and hasn't ended (`#EXT-X-ENDLIST`), from the file's first frame; null otherwise.
 * @param versions the video's versions; [versionIndex] the one playing. Fewer than two: nothing to choose.
 * @param quality the quality column; null where there is nothing to choose (no transcoding, live, a download).
 * @param transcoding the server transcodes the video playing.
 * @param sourceAudio / [sourceSubtitles] the server's tracks of the source while the player picks them on the server
 *   (it transcodes); empty otherwise, when the engine's own tracks are the choice.
 * @param chapters the server's chapters with thumbnails; null when it has none, and the engine's chapters show.
 * @param chapterMarks the seek bar marks the chapters' starts (`show_chapter_markers_on_timeline`); the chapter list
 *   shows either way.
 * @param segments the server's intro and credits markers (or the chapters classified), which replace the engine's
 *   chapter classification; null when the server said nothing.
 * @param queue what plays around this video; empty without a queue. Its [QueueEntry.current] entry moves to another
 *   item of it as that opens. [shuffled] the queue is shuffled.
 * @param scrubPreview the seek bar's thumbnails once loaded after the first frame; null without.
 * @param subtitleSearch the server has subtitle search ([PlayerSession.searchSubtitles]: Plex).
 * @param fileInfo the server has the file's info ([PlayerSession.loadFileInfo]; not live).
 * @param rewindOnResumeSeconds a play after a pause first seeks back this far (`rewind_on_resume`), 0 off.
 * @param audioOffsetSeconds / [subtitleOffsetSeconds] the title's saved sync offsets, applied as the video opens.
 * @param notice the last message for the viewer ("Transcoding unavailable — playing original quality"), shown as the
 *   player's toast each time its serial changes; null before any.
 * @param choice a question for the viewer the player shows over the video until [PlayerSession.answerChoice]; null
 *   while there is none.
 * @param ended the video played to its end and nothing plays after it (a movie, the queue's last item): the player
 *   leaves, unless watch together keeps it or the sleep timer stopped it there. False again once the viewer goes back
 *   from the end.
 * @param stoppedByServer the server ended this playback's session (an admin's stop) and the viewer hasn't played since:
 *   the video may play out what it buffered, but nothing starts the next item for the viewer.
 * @param nextFailures how often the next item, started by the end of the video, failed to open because its server
 *   didn't answer: each one offers it again ([com.edde746.plezy.playback.session.playNextRetryPresentation]).
 */
data class SessionInfo(
    val title: String,
    val subtitle: String? = null,
    val artworkUrl: String? = null,
    val posterUrl: String? = null,
    /** The server's item playing; null for a URL's video and before the first item loads. */
    val item: MediaItem? = null,
    val resolving: Boolean = false,
    val episode: Boolean = false,
    val trailer: Boolean = false,
    val nextEpisode: NextEpisode? = null,
    val hasPreviousEpisode: Boolean = false,
    val failure: PlaybackFailure? = null,
    val skipping: SkipModes = SkipModes(),
    val videoClick: VideoClickAction = VideoClickAction.PAUSE,
    val moreSubtitles: List<ExternalSubtitle> = emptyList(),
    val live: Boolean = false,
    val liveWindow: LiveWindow? = null,
    val local: Boolean = false,
    val versions: List<VersionOption> = emptyList(),
    val versionIndex: Int = 0,
    val quality: QualityChoice? = null,
    val transcoding: Boolean = false,
    val sourceAudio: List<SourceTrack> = emptyList(),
    val sourceSubtitles: List<SourceTrack> = emptyList(),
    val chapters: List<SessionChapter>? = null,
    val chapterMarks: Boolean = true,
    val segments: List<SkipSegment>? = null,
    val queue: List<QueueEntry> = emptyList(),
    val shuffled: Boolean = false,
    val scrubPreview: ScrubPreviewSource? = null,
    val subtitleSearch: Boolean = false,
    val fileInfo: Boolean = false,
    val rewindOnResumeSeconds: Int = 0,
    val audioOffsetSeconds: Double = 0.0,
    val subtitleOffsetSeconds: Double = 0.0,
    val notice: SessionNotice? = null,
    val choice: SessionChoice? = null,
    val ended: Boolean = false,
    val stoppedByServer: Boolean = false,
    val nextFailures: Int = 0,
)

/**
 * A subtitle file found for the open video and not part of it ([SessionInfo.moreSubtitles]): its [url] (which can
 * carry a key), its BCP 47 [language] when known and its [title] when it has one.
 */
data class ExternalSubtitle(val url: String, val language: String?, val title: String?) {
    override fun toString(): String = "ExternalSubtitle(url=<redacted>, language=$language, title=$title)"
}

/**
 * A live stream's rewind window: how far its HLS playlist reaches behind the live edge (the
 * end of its newest segment), and where the open file joined it, from which the engine's position places it. The edge
 * moves on with the clock; so does a paused position's distance from it.
 *
 * @param windowSeconds the playlist's segments summed, at its latest read.
 * @param segmentSeconds the playlist's target segment duration (`#EXT-X-TARGETDURATION`).
 * @param joinedBehindSeconds how far behind the edge the open file's first segment started when it was opened.
 * @param joinedPositionSeconds the engine's position at the open file's first frame.
 * @param joinedAt when the open file was asked to open: the edge has moved on by the time since.
 */
data class LiveWindow(
    val windowSeconds: Double,
    val segmentSeconds: Double,
    val joinedBehindSeconds: Double,
    val joinedPositionSeconds: Double,
    val joinedAt: TimeMark,
) {
    /**
     * How far the engine's [positionSeconds] is behind the live edge now: never less than 0, and past [windowSeconds]
     * once the window slid past it (a paused position).
     */
    fun behind(positionSeconds: Double): Double =
        (joinedBehindSeconds + joinedAt.elapsedNow().toDouble(DurationUnit.SECONDS) - (positionSeconds - joinedPositionSeconds)).coerceAtLeast(0.0)

    /**
     * [behindSeconds] reads as live: within [EDGE_SEGMENTS] segments of the edge, where a file opened at the edge lands
     * ([com.edde746.plezy.playback.resolve.LivePlaylist.JOIN_SEGMENTS], one segment more for the playlist's age).
     */
    fun atEdge(behindSeconds: Double): Boolean = behindSeconds <= EDGE_SEGMENTS * segmentSeconds

    companion object {
        /** The shortest window that rewinds: a playlist that reaches less far back plays as live without one. */
        const val MIN_SECONDS = 30.0

        const val EDGE_SEGMENTS = 4
    }
}

/**
 * The skipping settings: what the player does with each kind of [SkipSegment]. Recaps follow [intros], previews
 * [credits]. [autoSkipDelaySeconds] is how long the button counts down before a kind in [SkipMode.AUTO] skips on its
 * own; 0 or less, it never does, and the button shows as in [SkipMode.BUTTON].
 */
data class SkipModes(
    val intros: SkipMode = SkipMode.BUTTON,
    val credits: SkipMode = SkipMode.BUTTON,
    val autoSkipDelaySeconds: Int = 5,
) {
    fun of(kind: SkipKind): SkipMode = when (kind) {
        SkipKind.INTRO, SkipKind.RECAP -> intros
        SkipKind.CREDITS, SkipKind.PREVIEW -> credits
    }

    /** A segment of [kind] counts down and skips on its own. */
    fun skipsOnItsOwn(kind: SkipKind): Boolean = of(kind) == SkipMode.AUTO && autoSkipDelaySeconds > 0
}

/**
 * The next episode as up next's button shows it, formatted by the session: [title] is its name, or its code when it
 * has none; [subtitle] its code ("S1E2") when [title] is its name.
 * @param autoplay the next episode plays on its own (binge watching); without it the button doesn't count down and
 *   the next episode only plays when asked.
 * @param countdownSeconds how long the button counts down before the next episode plays; 0 plays it at once.
 */
data class NextEpisode(
    val title: String,
    val subtitle: String? = null,
    val autoplay: Boolean = true,
    val countdownSeconds: Int = 10,
    /** The next episode's still for up next's card (a download's saved one offline); null without one. */
    val imageUrl: String? = null,
)
