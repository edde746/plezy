package com.edde746.plezy.playback.tracks

import com.edde746.plezy.log.Log
import com.edde746.plezy.model.MediaSubtitleTrack
import com.edde746.plezy.playback.session.SubtitleDownloadOutcome
import com.edde746.plezy.plex.PlexClient
import com.edde746.plezy.plex.PlexSubtitleSearchResult
import com.edde746.plezy.plex.downloadSubtitle
import com.edde746.plezy.plex.getVideoPlaybackData
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.delay
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TimeSource

/** The first external row of [tracks] that is none of [existingSourceIds]: a subtitle the server just downloaded. */
fun findNewExternalSubtitleTrack(tracks: List<MediaSubtitleTrack>, existingSourceIds: Set<Int>): MediaSubtitleTrack? =
    tracks.firstOrNull { it.isExternal && it.id !in existingSourceIds }

/** How a switch of the playing source's subtitle ended. */
enum class SourceSwitchOutcome { APPLIED, UNCHANGED, BUSY, SUPERSEDED, UNAVAILABLE, FAILED }

/** A downloaded subtitle counts as applied when the switch applied it or found it already selected. */
fun subtitleDownloadOutcomeFor(outcome: SourceSwitchOutcome): SubtitleDownloadOutcome = when (outcome) {
    SourceSwitchOutcome.APPLIED, SourceSwitchOutcome.UNCHANGED -> SubtitleDownloadOutcome.APPLIED
    SourceSwitchOutcome.BUSY,
    SourceSwitchOutcome.SUPERSEDED,
    SourceSwitchOutcome.UNAVAILABLE,
    SourceSwitchOutcome.FAILED,
    -> SubtitleDownloadOutcome.NOT_APPLIED
}

/** Thrown when the server refuses a subtitle download. */
class SubtitleDownloadException(message: String) : Exception(message)

/**
 * Downloads a Plex subtitle search result to item [ratingKey] and switches playback to it. The server's download is
 * asynchronous: its stream shows up in the item's metadata seconds later, so the item is re-read ([pollInterval],
 * network-first) until a new external row appears or [pollTimeout] passes.
 */
class PlexSubtitleDownloader(
    private val client: PlexClient,
    private val timeSource: TimeSource = TimeSource.Monotonic,
    private val pollInterval: Duration = 2.seconds,
    private val pollTimeout: Duration = 15.seconds,
) {
    /**
     * Downloads [result] ([searchLanguage] when the result names no language, `srt` when it names no codec), waits
     * for the new row beside [existingSourceIds] (the rows the playing file listed; [position] keeps a stacked item on
     * that file), then has [switchToSource] select it. [isCurrent] false (playback moved to another item) ends the
     * wait as [SubtitleDownloadOutcome.NOT_APPLIED]. A refused download throws [SubtitleDownloadException].
     */
    suspend fun downloadAndApply(
        ratingKey: String,
        result: PlexSubtitleSearchResult,
        searchLanguage: String,
        existingSourceIds: Set<Int>,
        position: () -> Duration?,
        isCurrent: () -> Boolean,
        switchToSource: suspend (sourceStreamId: Int) -> SourceSwitchOutcome,
    ): SubtitleDownloadOutcome {
        val stored = client.downloadSubtitle(
            ratingKey,
            key = result.key,
            codec = result.codec ?: "srt",
            language = result.languageCode ?: searchLanguage,
            hearingImpaired = result.hearingImpaired,
            forced = result.forced,
            providerTitle = result.providerTitle ?: "",
        )
        if (!stored) throw SubtitleDownloadException("The server refused the subtitle download")

        val deadline = timeSource.markNow() + pollTimeout
        var downloaded: MediaSubtitleTrack? = null
        while (deadline.hasNotPassedNow()) {
            delay(pollInterval)
            if (!isCurrent()) return SubtitleDownloadOutcome.NOT_APPLIED
            try {
                val data = client.getVideoPlaybackData(ratingKey, position = position(), forceRefresh = true)
                if (!isCurrent()) return SubtitleDownloadOutcome.NOT_APPLIED
                val info = data.mediaInfo ?: continue
                downloaded = findNewExternalSubtitleTrack(info.subtitleTracks, existingSourceIds)
                if (downloaded != null) break
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "Subtitle download poll failed" }
                if (!isCurrent()) return SubtitleDownloadOutcome.NOT_APPLIED
            }
        }
        if (!isCurrent()) return SubtitleDownloadOutcome.NOT_APPLIED
        val track = downloaded ?: return SubtitleDownloadOutcome.TIMED_OUT
        return subtitleDownloadOutcomeFor(switchToSource(track.id))
    }

    private companion object {
        const val TAG = "PlexSubtitleDownloader"
    }
}
