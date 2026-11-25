package com.edde746.plezy.presentation.player

import com.edde746.plezy.backend.TranscodeQualityPreset
import com.edde746.plezy.format.clockTime
import com.edde746.plezy.format.formatBitrate
import com.edde746.plezy.format.formatByteSize
import com.edde746.plezy.format.formatTimecode
import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.input.PlayerMenu
import com.edde746.plezy.playback.Chapter
import com.edde746.plezy.playback.PlaybackFailure
import com.edde746.plezy.playback.SkipKind
import com.edde746.plezy.playback.SkipSegment
import com.edde746.plezy.playback.TrackKind
import com.edde746.plezy.playback.displayText
import com.edde746.plezy.playback.queue.shouldRestartBeforePreviousItem
import com.edde746.plezy.playback.session.LiveWindow
import com.edde746.plezy.playback.session.NextEpisode
import com.edde746.plezy.playback.session.QueueEntry
import com.edde746.plezy.playback.session.SessionInfo
import com.edde746.plezy.strings.T
import kotlin.math.abs
import kotlin.math.floor
import kotlin.math.roundToInt
import kotlin.math.roundToLong

/** The formatted parts of [PlayerUiState] and [TimelineState], each from plain values. */
internal object PlayerStates {
    /**
     * A video's timeline at [position], with [scrub]'s preview while the viewer scrubs and [motion] while it plays; the
     * buffered part ends where the engine's read ahead does ([cacheEnd]), never short of the position.
     */
    fun timeline(position: Double, duration: Double, cacheEnd: Double?, chapters: List<Float>, scrub: ScrubState?, motion: PlayheadMotion?): TimelineState {
        val positionText = formatTimecode(position)
        val durationText = formatTimecode(duration)
        return TimelineState(
            position = positionText,
            duration = durationText,
            // Whole seconds on both sides, so position and remaining always add up to the duration shown.
            remaining = PlayerText.remaining((wholeSeconds(duration) - wholeSeconds(position)).coerceAtLeast(0.0)),
            positionLabel = T.player.position(positionText, durationText),
            progress = fraction(position, duration),
            buffered = fraction(maxOf(position, cacheEnd ?: position), duration),
            chapters = chapters,
            positionSeconds = position,
            durationSeconds = duration,
            liveLabel = "",
            scrub = scrub,
            motion = motion,
        )
    }

    /** A live playback's timeline ([PlaybackMode.LIVE]) at [position]: no times, the label LIVE. */
    fun liveTimeline(position: Double): TimelineState = TimelineState(
        position = "",
        duration = "",
        remaining = "",
        positionLabel = T.player.live.atEdge,
        progress = 0f,
        buffered = 0f,
        chapters = emptyList(),
        positionSeconds = position,
        durationSeconds = 0.0,
        liveLabel = T.player.live.badge,
    )

    /**
     * A live playback's timeline with its rewind [window] ([PlaybackMode.LIVE_WINDOW]) at [position], its place in the
     * window (0 at its start); [scrub]'s preview while the viewer scrubs. At the edge the bar is full and the label is
     * LIVE; behind it the label says how far (`LIVE · −0:40`). Its [TimelineState.position] is the clock time the shown
     * position went out live, at [nowMillis] on the wall clock: the edge's is now, a position behind it is that much
     * earlier ([clockTime], on a 24-hour clock when [use24HourClock]).
     */
    fun rewindTimeline(position: Double, window: LiveWindow, scrub: ScrubState?, nowMillis: Long, use24HourClock: Boolean): TimelineState {
        val behind = (window.windowSeconds - position).coerceAtLeast(0.0)
        val atEdge = window.atEdge(behind)
        return TimelineState(
            position = airedAt(behind, nowMillis, use24HourClock),
            duration = formatTimecode(window.windowSeconds),
            remaining = "",
            positionLabel = if (atEdge) T.player.live.atEdge else T.player.live.behind(formatTimecode(behind)),
            progress = if (atEdge) 1f else fraction(position, window.windowSeconds),
            buffered = 0f,
            chapters = emptyList(),
            positionSeconds = if (atEdge) window.windowSeconds else position,
            durationSeconds = window.windowSeconds,
            liveLabel = if (atEdge) T.player.live.badge else T.detail.infoJoin(T.player.live.badge, PlayerText.remaining(behind)),
            atLiveEdge = atEdge,
            behind = if (atEdge) "" else PlayerText.remaining(behind),
            scrub = scrub,
        )
    }

    /** A scrub's [preview] in a live window [windowSeconds] long: the clock time it went out live, at [nowMillis]. */
    fun rewindScrub(preview: Double, origin: Double, windowSeconds: Double, nowMillis: Long, use24HourClock: Boolean): ScrubState = ScrubState(
        seconds = preview,
        progress = fraction(preview, windowSeconds),
        position = airedAt((windowSeconds - preview).coerceAtLeast(0.0), nowMillis, use24HourClock),
        offset = PlayerText.offset(preview - origin),
        chapter = null,
    )

    /** The local clock time ("21:43", "9:43 PM") [behindSeconds] before [nowMillis]: when that point went out live. */
    private fun airedAt(behindSeconds: Double, nowMillis: Long, use24HourClock: Boolean): String =
        clockTime((nowMillis - (behindSeconds * 1000).roundToLong()).floorDiv(1000L), use24HourClock)

    /** Chapter starts as fractions of [duration], for the seek bar's marks. */
    fun chapterMarks(chapters: List<Chapter>, duration: Double): List<Float> =
        if (duration <= 0.0) emptyList()
        else chapters.mapNotNull { chapter -> (chapter.startSeconds / duration).takeIf { it > 0.0 && it < 1.0 }?.toFloat() }

    fun scrub(preview: Double, origin: Double, duration: Double, chapter: Chapter?): ScrubState = ScrubState(
        seconds = preview,
        progress = fraction(preview, duration),
        position = formatTimecode(preview),
        offset = PlayerText.offset(preview - origin),
        chapter = chapter?.title?.takeIf { it.isNotBlank() },
    )

    /** The custom speed's control at [speed], over the player's range ([PlayerConfig.MIN_SPEED] to [PlayerConfig.MAX_SPEED]). */
    fun customSpeed(speed: Double): SpeedControl {
        val step = PlayerConfig.CUSTOM_SPEED_STEP
        val min = PlayerConfig.MIN_SPEED
        val max = PlayerConfig.MAX_SPEED
        return SpeedControl(
            speed = speed,
            label = T.player.speed.value(PlayerText.decimal(speed)),
            decreaseLabel = T.player.speed.slower,
            increaseLabel = T.player.speed.faster,
            decrease = PlayerCommand.SetSpeed(customSpeed(speed - step, step, min, max)),
            increase = PlayerCommand.SetSpeed(customSpeed(speed + step, step, min, max)),
            reset = PlayerCommand.SetSpeed(1.0),
            canDecrease = speed > min + PlayerText.SPEED_EPSILON,
            canIncrease = speed < max - PlayerText.SPEED_EPSILON,
            canReset = abs(speed - 1.0) >= PlayerText.SPEED_EPSILON,
            min = min,
            max = max,
            step = step,
        )
    }

    /** [value] on the [step] grid, to the hundredth, within [min] and [max]. */
    fun customSpeed(value: Double, step: Double, min: Double, max: Double): Double =
        ((value / step).roundToLong() * step * 100).roundToLong().div(100.0).coerceIn(min, max)

    /**
     * The version and quality sheet: the versions ([SessionInfo.versions], the one playing ticked) and the qualities
     * ([SessionInfo.quality]: "Original 8.5 Mbps" with the source's bitrate, then "720p 4 Mbps" and so on, each with its
     * [qualitySize]); a preset the source already fits under, in both its bitrate and its height, isn't offered (it
     * would play no better than the original), unless it is the one playing. Null where neither has a choice (one
     * version and no transcoding: live, a download, a server that can't transcode).
     */
    fun versions(info: SessionInfo): VersionsMenu? {
        val quality = info.quality
        if (info.versions.size < 2 && quality == null) return null
        val versions = info.versions.mapIndexed { index, version ->
            OptionChoice(version.label, version.detail, selected = index == info.versionIndex, PlayerCommand.SelectVersion(index))
        }
        val qualities = quality?.let { choice ->
            offeredQualities(choice.sourceBitrateKbps, choice.sourceHeightPx, choice.selected).map { row ->
                OptionChoice(
                    row.label,
                    detail = qualitySize(row.preset, choice.sourceBitrateKbps, choice.sourceDurationMs),
                    selected = row.selected,
                    PlayerCommand.SelectQuality(row.preset),
                )
            }
        }.orEmpty()
        return VersionsMenu(versions, qualities)
    }

    /**
     * The size a quality plays, as "≈ 1.2 GB": the bitrate its row shows (the source's for the original, the preset's
     * for a transcode) over [durationMs], one basis for every row, so a lower bitrate never reads larger. Null where the
     * inputs are missing.
     */
    fun qualitySize(preset: TranscodeQualityPreset, sourceBitrateKbps: Int?, durationMs: Long?): String? {
        val duration = durationMs?.takeIf { it > 0 } ?: return null
        val kbps = (if (preset.isOriginal) sourceBitrateKbps else preset.videoBitrateKbps)?.takeIf { it > 0 } ?: return null
        return "≈ ${formatByteSize(kbps.toLong() * duration / 8)}"
    }

    /**
     * The qualities every version and quality list offers, in [TranscodeQualityPreset.displayOrder]: each labelled for a
     * source of [sourceBitrateKbps] ([qualityLabel]), [current] the one selected.
     */
    fun qualities(sourceBitrateKbps: Int?, current: TranscodeQualityPreset): List<QualityRow> =
        TranscodeQualityPreset.displayOrder.map { QualityRow(it, qualityLabel(it, sourceBitrateKbps), selected = it == current) }

    /**
     * The [qualities] a version and quality list offers for a source of [sourceBitrateKbps] and [sourceHeightPx]: a
     * preset the source already fits under in both ([TranscodeQualityPreset.coversSource]) would play no better than the
     * original and is left out, unless it is [current]. Lists pick by a row's preset, never by its place.
     */
    fun offeredQualities(sourceBitrateKbps: Int?, sourceHeightPx: Int?, current: TranscodeQualityPreset): List<QualityRow> =
        qualities(sourceBitrateKbps, current).filter { it.selected || !it.preset.coversSource(sourceBitrateKbps, sourceHeightPx) }

    /** "Original" (with the source's bitrate when known: "Original 8.5 Mbps"), else "720p 2 Mbps", "480p 1.5 Mbps". */
    fun qualityLabel(preset: TranscodeQualityPreset, sourceBitrateKbps: Int?): String {
        if (preset.isOriginal) {
            val bitrate = sourceBitrateKbps?.takeIf { it > 0 }?.let(::formatBitrate)
            return listOfNotNull(T.videoControls.qualityOriginal, bitrate).joinToString(" ")
        }
        val kbps = preset.videoBitrateKbps ?: 0
        val mbps = kbps / 1000.0
        val bitrate = if (mbps >= 10 || kbps % 1000 == 0) mbps.roundToInt().toString() else ((kbps / 100.0).roundToInt() / 10.0).toString()
        return T.videoControls.qualityPresetLabel(preset.resolutionHeight?.toString().orEmpty(), bitrate)
    }

    /**
     * The [kind] ([TrackKind.SUBTITLE] or [TrackKind.AUDIO]) delay's control, its sync bar, at [seconds]: steps of 10 ms
     * for audio and 50 ms for subtitles, within [config]'s range.
     */
    fun delay(kind: TrackKind, seconds: Double, config: PlayerConfig): DelayState {
        val text = T.player.menu
        val subtitles = kind == TrackKind.SUBTITLE
        val step = if (subtitles) SUBTITLE_SYNC_STEP else AUDIO_SYNC_STEP
        val max = config.maxDelaySeconds
        return DelayState(
            menu = if (subtitles) PlayerMenu.SUBTITLE_DELAY else PlayerMenu.AUDIO_DELAY,
            title = if (subtitles) T.videoSettings.subtitleSync else T.videoSettings.audioSync,
            label = PlayerText.delay(seconds),
            decreaseLabel = if (subtitles) text.subtitleDelayEarlier else text.audioDelayEarlier,
            increaseLabel = if (subtitles) text.subtitleDelayLater else text.audioDelayLater,
            decrease = if (subtitles) PlayerCommand.AdjustSubtitleDelay(-step) else PlayerCommand.AdjustAudioDelay(-step),
            increase = if (subtitles) PlayerCommand.AdjustSubtitleDelay(step) else PlayerCommand.AdjustAudioDelay(step),
            reset = if (subtitles) PlayerCommand.SetSubtitleDelay(0.0) else PlayerCommand.SetAudioDelay(0.0),
            canDecrease = seconds > -max + DELAY_EPSILON,
            canIncrease = seconds < max - DELAY_EPSILON,
            canReset = abs(seconds) >= DELAY_EPSILON,
            seconds = seconds,
            stepSeconds = step,
            limitSeconds = max,
        )
    }

    fun volume(volume: Double, muted: Boolean, maxPercent: Int): VolumeState {
        val percent = volume.roundToInt()
        return VolumeState(
            percent = percent,
            fraction = (volume / maxPercent).coerceIn(0.0, 1.0).toFloat(),
            muted = muted,
            label = if (muted) T.player.volume.muted else PlayerText.volume(percent),
            maxPercent = maxPercent,
        )
    }

    /**
     * Up next's prompt for [next], counting down while [progress] is set, [secondsLeft] to go, [withControls] when it
     * shows only with the controls: "S1E2 · Please Remain Calm", the code and the separator its [PlayerPrompt.lead]
     * (the session's "episode · title" format), or the code alone without a name. Its still is the card's backdrop,
     * and the shuffle icon shows when the queue is [shuffled].
     */
    fun upNext(next: NextEpisode, progress: Float?, secondsLeft: Int?, withControls: Boolean, shuffled: Boolean = false): PlayerPrompt = PlayerPrompt(
        kind = PromptKind.UP_NEXT,
        lead = next.subtitle?.let { code -> T.session.episodeTitle(code, "") },
        text = next.title,
        progress = progress,
        secondsLeft = secondsLeft,
        command = PlayerCommand.NextEpisode,
        withControls = withControls,
        imageUrl = next.imageUrl,
        shuffled = shuffled,
    )

    /**
     * The skip button for [segment], counting down while [progress] is set, [secondsLeft] to go, [withControls] when it
     * shows only with the controls.
     */
    fun skip(segment: SkipSegment, progress: Float?, secondsLeft: Int?, withControls: Boolean): PlayerPrompt {
        val (kind, label) = when (segment.kind) {
            SkipKind.INTRO -> PromptKind.INTRO to T.player.skip.intro
            SkipKind.RECAP -> PromptKind.RECAP to T.player.skip.recap
            SkipKind.CREDITS, SkipKind.PREVIEW -> PromptKind.CREDITS to T.player.skip.credits
        }
        return PlayerPrompt(
            kind = kind,
            lead = null,
            text = label,
            progress = progress,
            secondsLeft = secondsLeft,
            command = PlayerCommand.SkipSegment,
            withControls = withControls,
        )
    }

    fun stillWatching(secondsLeft: Int): StillWatchingState = StillWatchingState(
        countdown = T.player.stillWatching.countdown(secondsLeft),
        secondsLeft = secondsLeft,
        progress = 1f - secondsLeft.toFloat() / SleepTimer.STILL_WATCHING_SECONDS,
    )

    /**
     * The error card for [failure]: Retry (its primary button, focused and filled on every UI) and Close. The server's
     * limit (HTTP 500) says so, and where the session can play the file transcoded its primary button tries that
     * ([PlayerCommand.ForceTranscode]) instead of Retry.
     */
    fun error(failure: PlaybackFailure): ErrorState {
        val close = ErrorButton(ErrorAction.CLOSE, T.player.error.close, PlayerCommand.Close, primary = false)
        if (failure is PlaybackFailure.ServerLimit) {
            val first = if (failure.transcodeOffered) {
                ErrorButton(ErrorAction.TRANSCODE, T.messages.serverLimitTranscode, PlayerCommand.ForceTranscode, primary = true)
            } else {
                ErrorButton(ErrorAction.RETRY, T.player.error.retry, PlayerCommand.Retry, primary = true)
            }
            return ErrorState(T.messages.serverLimitTitle, failure.displayText, listOf(first, close))
        }
        return ErrorState(
            title = T.player.error.title,
            message = failure.displayText,
            buttons = listOf(ErrorButton(ErrorAction.RETRY, T.player.error.retry, PlayerCommand.Retry, primary = true), close),
        )
    }

    /**
     * The chapter sheet's [chapters], chapter [current] playing: each titled (else "Chapter 3"), its start, its thumbnail from the
     * server's chapters ([images], by index), the one playing marked; [canSeek] false (a guest in a host-only room)
     * leaves them without a command.
     */
    fun chapters(chapters: List<Chapter>, images: List<String?>, current: Int, canSeek: Boolean): List<ChapterItem> =
        chapters.mapIndexed { index, chapter ->
            ChapterItem(
                title = chapter.title?.takeIf { it.isNotBlank() } ?: T.common.chapterNumber((index + 1).toString()),
                start = formatTimecode(chapter.startSeconds),
                imageUrl = images.getOrNull(index),
                current = index == current,
                command = if (canSeek) PlayerCommand.SeekToChapter(index) else null,
            )
        }

    /**
     * The sleep timer's banner: "Playback will pause in 12m 30s" with "+15 min" while it counts [secondsLeft] down, or
     * "… at the end of this video" ([atEndOfVideo]) without it.
     */
    fun sleepBanner(atEndOfVideo: Boolean, secondsLeft: Int): SleepTimerBanner = if (atEndOfVideo) {
        SleepTimerBanner(T.videoControls.playbackWillPauseAtEnd, extend = null)
    } else {
        SleepTimerBanner(
            T.videoControls.playbackWillPauseIn(shortDuration(secondsLeft)),
            extend = T.videoControls.addTime(SleepTimer.EXTEND_MINUTES.toString(), " min"),
        )
    }

    /** "1h 2m 5s", "12m 30s", "45s": the parts that aren't zero, seconds at the least. */
    fun shortDuration(seconds: Int): String {
        val h = seconds / 3600
        val m = seconds % 3600 / 60
        val s = seconds % 60
        return listOfNotNull(
            if (h > 0) "${h}h" else null,
            if (m > 0) "${m}m" else null,
            if (s > 0 || (h == 0 && m == 0)) "${s}s" else null,
        ).joinToString(" ")
    }

    /**
     * The previous and next buttons, for an episode and for every item of a queue: with the queue holding the item
     * playing ([SessionInfo.queue]), each is on while the queue lists an entry that way, so the buttons and the queue
     * shown never disagree; without one (a download played offline, a live channel) the session's own lookup decides
     * ([SessionInfo.hasPreviousEpisode], [SessionInfo.nextEpisode]). Both off where this device may not change what
     * plays ([canChange]), and while an item opens ([SessionInfo.resolving]): the session takes no other item then, so
     * neither looks live while it would do nothing. Previous, on, restarts what plays once [positionSeconds] is past the
     * first seconds ([shouldRestartBeforePreviousItem]). Null for a video alone.
     */
    fun episodeButtons(info: SessionInfo, canChange: Boolean, positionSeconds: Double): EpisodeButtons? {
        val current = info.queue.indexOfFirst { it.current }
        if (!info.episode && current < 0) return null
        if (!canChange || info.resolving) return EpisodeButtons(previous = false, next = false, episode = info.episode)
        val before = if (current < 0) info.hasPreviousEpisode else current > 0
        val next = if (current < 0) info.nextEpisode != null else current < info.queue.lastIndex
        // Past the first seconds Previous restarts what plays, with or without an entry before it.
        val restarts = !info.live && shouldRestartBeforePreviousItem(positionSeconds)
        return EpisodeButtons(previous = before || restarts, next = next, previousRestarts = restarts, episode = info.episode)
    }

    /** The queue's entry after the one playing ([SessionInfo.queue]); null without one. */
    fun entryAfter(info: SessionInfo): QueueEntry? {
        val current = info.queue.indexOfFirst { it.current }
        return if (current < 0) null else info.queue.getOrNull(current + 1)
    }

    private fun fraction(value: Double, total: Double): Float =
        if (total > 0.0) (value / total).coerceIn(0.0, 1.0).toFloat() else 0f

    private fun wholeSeconds(seconds: Double): Double = if (seconds.isFinite() && seconds > 0) floor(seconds) else 0.0

    /** Delays are kept to the millisecond. */
    const val DELAY_EPSILON = 0.0005

    /** A sync bar's step: 10 ms for audio, 50 ms for subtitles. */
    const val AUDIO_SYNC_STEP = 0.01
    const val SUBTITLE_SYNC_STEP = 0.05
}

/** One row of [PlayerStates.qualities]: its [preset], its [label], and whether it is the one [selected]. */
data class QualityRow(val preset: TranscodeQualityPreset, val label: String, val selected: Boolean)
