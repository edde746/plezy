package com.edde746.plezy.input

import com.edde746.plezy.backend.TranscodeQualityPreset
import com.edde746.plezy.data.settings.DolbyVisionConversion
import com.edde746.plezy.playback.AudioChannels
import com.edde746.plezy.playback.TrackKind
import com.edde746.plezy.playback.VideoFit

/**
 * The player's menus. At most one is open; while it is, the controls stay up. [OPTIONS] is the settings sheet
 * (`PlayerUiState.options`); the pages after it hold one option's choices each, and Back from one returns to
 * [OPTIONS]. [AUDIO] lists the audio tracks, then the audio delay and the audio settings (`PlayerUiState.audioOptions`);
 * Back from an audio setting's page ([AUDIO_OUTPUT], [AUDIO_CHANNELS]) returns to [AUDIO]. [MORE_SUBTITLES] lists the
 * languages of the subtitles found but not added (`PlayerUiState.moreSubtitles`) and [SUBTITLE_LANGUAGE] one
 * language's (`PlayerUiState.subtitleLanguage`); Back goes from one to the other and on to [SUBTITLES].
 * [WATCH_TOGETHER] is the room's session sheet (`PlayerUiState.watch`), opened from the options or the room pill; Back
 * returns to [OPTIONS] when it opened from there, else closes it, and it closes when the room goes.
 *
 * [TRACKS] is the tracks sheet: audio (or the server's audio while it transcodes) and subtitles side by side, titled
 * "Tracks", or "Audio" / "Subtitles" when it has one column. [SUBTITLE_SEARCH] (Plex) opens from [SUBTITLES] and Back
 * returns there. [VERSIONS] is the version and quality sheet, [FILE_INFO] the file's info, both option pages.
 * [CHAPTERS] and [QUEUE] are their sheets; [CONTENT_STRIP] is the chapters and the queue together (D-pad Down from the
 * button row, a swipe up on a phone), which holds the controls up while it shows. [CUSTOM_SPEED] is the custom speed's
 * control (`PlayerUiState.customSpeed`), opened from [SPEED]'s Custom entry; Back returns there.
 */
enum class PlayerMenu {
    AUDIO,
    SUBTITLES,
    SPEED,
    CUSTOM_SPEED,
    SUBTITLE_DELAY,
    AUDIO_DELAY,
    MORE_SUBTITLES,
    SUBTITLE_LANGUAGE,
    OPTIONS,
    VIDEO_FIT,
    ZOOM,
    SHADERS,
    SLEEP_TIMER,
    AUDIO_CHANNELS,
    AUDIO_OUTPUT,
    WATCH_TOGETHER,
    TRACKS,
    SUBTITLE_SEARCH,
    VERSIONS,
    FILE_INFO,
    CHAPTERS,
    QUEUE,
    CONTENT_STRIP,

    /** A development build's option pages: Dolby Vision Profile 7's conversion, and the HTTP status to simulate. */
    DOLBY_VISION_CONVERSION,
    HTTP_STATUS,
    ;

    /** One option's page of [OPTIONS]. */
    val isOptionPage: Boolean get() = this in OPTION_PAGES

    /**
     * The menu this one opens from, whose button stands for it: a delay's track menu ([AUDIO], [SUBTITLES]), [AUDIO]
     * for an audio setting's page, [SUBTITLES] for the More subtitles pages and the subtitle search, [OPTIONS] for an
     * option's page and the custom speed; every other menu is its own.
     */
    val parent: PlayerMenu
        get() = when {
            this == AUDIO_DELAY || this in AUDIO_PAGES -> AUDIO
            this == SUBTITLE_DELAY || this == MORE_SUBTITLES || this == SUBTITLE_LANGUAGE || this == SUBTITLE_SEARCH -> SUBTITLES
            isOptionPage || this == CUSTOM_SPEED -> OPTIONS
            else -> this
        }

    /** The menu Back returns to: the one a page was opened from; null where Back closes the menu. */
    val back: PlayerMenu?
        get() = when {
            this == SUBTITLE_LANGUAGE -> MORE_SUBTITLES
            this == CUSTOM_SPEED -> SPEED
            this == MORE_SUBTITLES -> SUBTITLES
            this == SUBTITLE_SEARCH -> SUBTITLES
            this in AUDIO_PAGES -> AUDIO
            isOptionPage -> OPTIONS
            else -> null
        }

    private companion object {
        val OPTION_PAGES = setOf(SPEED, VIDEO_FIT, ZOOM, SHADERS, SLEEP_TIMER, VERSIONS, FILE_INFO, DOLBY_VISION_CONVERSION, HTTP_STATUS)

        /** The audio settings' pages, opened from [AUDIO]. */
        val AUDIO_PAGES = setOf(AUDIO_OUTPUT, AUDIO_CHANNELS)
    }
}

/**
 * Everything the player can be told to do. Keymaps turn [InputEvent]s into commands; the views' buttons,
 * sliders and menus send them directly through the store's `dispatch`, the platform's audio session its
 * [SystemPause] and [SystemResume].
 */
sealed interface PlayerCommand {
    data object TogglePause : PlayerCommand
    data object Play : PlayerCommand
    data object Pause : PlayerCommand

    /**
     * The system stopped the playback on this device, not the viewer: a call or another app took the audio (Android's
     * audio focus, an iOS or tvOS interruption), the audio output went (headphones unplugged, AirPods or a Bluetooth
     * device gone), the platform's audio restarted, the app's task was removed. It pauses as [Pause] does, but in a
     * watch-together room only whoever controls playback pauses the room; anyone else's player pauses on this device
     * alone and the room plays on (`PlayerStore`'s room rule).
     */
    data object SystemPause : PlayerCommand

    /**
     * What [SystemPause] was for is over and the system says to play on: Android's audio focus back after a transient
     * loss, an iOS or tvOS interruption ended with its resume option.
     */
    data object SystemResume : PlayerCommand

    /** Seek relative to the shown position; negative goes back. */
    data class SeekBy(val seconds: Double) : PlayerCommand

    /**
     * One seek step ([forward] or back) from the OS media controls (skip and seek buttons, a remote's fast forward):
     * the player's own step (`seek_time_small`), whatever interval the OS asked for, onto the running burst of skips.
     */
    data class Skip(val forward: Boolean) : PlayerCommand

    /** Seek to [seconds] from the start: the OS media controls' seek bar. */
    data class SeekTo(val seconds: Double) : PlayerCommand

    /** Seek to [fraction] (0–1) of the duration: digit keys jump to tenths. */
    data class SeekToFraction(val fraction: Double) : PlayerCommand

    /**
     * Drag scrubbing: move the preview to [fraction] (0–1) of the duration, the video seeking along at most every
     * 200 ms where it may. The first one starts a scrub; [CommitScrub] seeks to the preview on release,
     * [CancelScrub] drops it, the video back where the scrub started.
     */
    data class ScrubTo(val fraction: Double) : PlayerCommand

    data object CommitScrub : PlayerCommand
    data object CancelScrub : PlayerCommand

    /**
     * A mouse rests over the seek bar at [fraction] (0–1) of its length, or left it (null): the bar's tooltip shows
     * the time there and its thumbnail (`TimelineState.hover`). Seeks nothing.
     */
    data class HoverTimeline(val fraction: Double?) : PlayerCommand

    /** Change the volume by [delta] percentage points. */
    data class AdjustVolume(val delta: Double) : PlayerCommand

    /** Set the volume, in percent. */
    data class SetVolume(val percent: Double) : PlayerCommand
    data object ToggleMute : PlayerCommand

    data object ToggleFullscreen : PlayerCommand
    data object ExitFullscreen : PlayerCommand

    /** Select a track; `id == null` turns subtitles off, the second subtitle with them. */
    data class SelectTrack(val kind: TrackKind, val id: Long?) : PlayerCommand

    /**
     * A subtitle row's second action (a long press, a right-click, a held select) on track [id], `null` the Off row: a
     * track that is neither the subtitle nor the second subtitle shows as the second, at the top of the picture; the
     * second's own row or Off turns the second off; the subtitle's row does nothing. The menu stays open.
     */
    data class ToggleSecondSubtitle(val id: Long?) : PlayerCommand

    /** Switch to the next audio track, wrapping around. */
    data object CycleAudio : PlayerCommand

    /** Switch to the next subtitle track, then off, then the first again. */
    data object CycleSubtitles : PlayerCommand

    /**
     * Hide the subtitles, or show them again (the subtitle shortcut): the track stays chosen, and nothing changes
     * without one.
     */
    data object ToggleSubtitles : PlayerCommand

    /** Seek to the next ([forward]) or previous subtitle line's start (the subtitle seek shortcuts; mpv's `sub-seek`). */
    data class SubtitleSeek(val forward: Boolean) : PlayerCommand

    /** Save a screenshot of the video with its subtitles (the screenshot shortcut, desktop). */
    data object Screenshot : PlayerCommand

    /** Open [PlayerMenu.SUBTITLE_LANGUAGE] on the language of `PlayerUiState.moreSubtitles` with [key]. */
    data class OpenSubtitleLanguage(val key: String) : PlayerCommand

    /** Add the subtitle at [url] from `PlayerUiState.moreSubtitles` and select it. [url] can carry a key. */
    data class AddSubtitle(val url: String) : PlayerCommand {
        override fun toString(): String = "AddSubtitle(url=<redacted>)"
    }

    data class SetSpeed(val speed: Double) : PlayerCommand

    /** The next faster speed of the speed menu. */
    data object SpeedUp : PlayerCommand

    /** The next slower speed of the speed menu. */
    data object SpeedDown : PlayerCommand
    data object ResetSpeed : PlayerCommand

    /** A finger held on the video: 2× while it is held, until [ReleaseSpeed]. */
    data object HoldSpeed : PlayerCommand

    /** The held finger lifted: the speed [HoldSpeed] replaced comes back. */
    data object ReleaseSpeed : PlayerCommand

    /** Change the subtitle delay by [deltaSeconds]; positive shows subtitles later. */
    data class AdjustSubtitleDelay(val deltaSeconds: Double) : PlayerCommand
    data class SetSubtitleDelay(val seconds: Double) : PlayerCommand

    /** Change the audio delay by [deltaSeconds]; positive plays audio later. */
    data class AdjustAudioDelay(val deltaSeconds: Double) : PlayerCommand
    data class SetAudioDelay(val seconds: Double) : PlayerCommand

    data object NextChapter : PlayerCommand

    /** Back to the start of the current chapter, or to the previous one when just past a chapter start. */
    data object PreviousChapter : PlayerCommand

    /** Play the next episode now (the controls' button, up next's prompt button, a remote's Next key). */
    data object NextEpisode : PlayerCommand

    /** Play the episode before this one (the controls' button, a remote's Previous key). */
    data object PreviousEpisode : PlayerCommand

    /**
     * The skip button's action: seek exactly to the end of the intro, recap or credits playing, or play the next episode
     * for credits to the end of an episode with a next one. In a room it seeks for everyone, as any seek does.
     */
    data object SkipSegment : PlayerCommand

    /** A live playback behind its live edge ([com.edde746.plezy.playback.session.LiveWindow]): back to the edge. */
    data object GoToLive : PlayerCommand

    /** After an error: try the same video again. */
    data object Retry : PlayerCommand

    /** How the picture fills the player; this device keeps it for the next video. */
    data class SetVideoFit(val fit: VideoFit) : PlayerCommand

    /** The viewer's zoom on the picture, a factor (1.0 for none), kept in whole percent from 50 % to 200 %. */
    data class SetZoom(val zoom: Double) : PlayerCommand
    data object ZoomIn : PlayerCommand
    data object ZoomOut : PlayerCommand
    data object ResetZoom : PlayerCommand

    /** Run the shader preset [id] (`ShaderPreset.id`); this device keeps it for the next video. */
    data class SetShaderPreset(val id: String) : PlayerCommand

    /**
     * Turn the shaders off for this playback, or on again (`ShaderPreset.toggled`): on is kept for the next video, off
     * only for this playback.
     */
    data object ToggleShaders : PlayerCommand

    /**
     * Turn ambient lighting on or off (`AmbientLightingController`); this device keeps it for the next video. On turns
     * the shaders off and the picture back to Fit.
     */
    data object ToggleAmbientLighting : PlayerCommand

    /**
     * Import the shader the system's open dialog picked: its file's [fileName] (a `.glsl` file's, named after it in the
     * menu) and [source]. It runs at once, and this device keeps it.
     */
    data class ImportShader(val fileName: String, val source: String) : PlayerCommand

    /** The file the open dialog picked for [ImportShader] couldn't be read as UTF-8 text: the import fails. */
    data object ShaderImportFailed : PlayerCommand

    /** Delete the imported shader [id] (`CustomShader.id`); the shaders go off if it was running. */
    data class DeleteShader(val id: String) : PlayerCommand

    /** Pause the playback [minutes] from now, after asking whether anyone is still watching. */
    data class SetSleepTimer(val minutes: Int) : PlayerCommand

    /** Stop at the end of the video playing: it pauses there instead of moving on to the next episode. */
    data object SleepAtEndOfVideo : PlayerCommand
    data object CancelSleepTimer : PlayerCommand

    /** Answer the sleep timer's "Still watching?": keep playing, with the timer started again. */
    data object KeepWatching : PlayerCommand

    /** Play the next episode on its own at the end of this one (the profile's binge watching setting). */
    data class SetAutoPlayNext(val enabled: Boolean) : PlayerCommand

    /** Even out the audio's loudness; this device keeps it for the next video. */
    data class SetAudioNormalization(val enabled: Boolean) : PlayerCommand

    /** The most channels the audio plays with; this device keeps it for the next video. */
    data class SetAudioChannels(val channels: AudioChannels) : PlayerCommand

    /** Play to the audio output [name] (`EngineState.audioDevices`); once the engine plays to it, kept for the players to come. */
    data class SetAudioDevice(val name: String) : PlayerCommand

    /** Let the picture go out as HDR, or tone-map it to SDR; this device keeps it once the engine took it. */
    data class SetHdr(val enabled: Boolean) : PlayerCommand

    /** A development build's: what Dolby Vision Profile 7 becomes, for this player. */
    data class SetDolbyVisionConversion(val mode: DolbyVisionConversion) : PlayerCommand

    /** A development build's: fail the playback as the server answering [status] would. */
    data class SimulateHttpStatus(val status: Int) : PlayerCommand

    /** Turn the playback info over the video on or off; this device keeps it for the next video. */
    data object ToggleInfo : PlayerCommand

    data object ShowControls : PlayerCommand
    data object HideControls : PlayerCommand
    data object ToggleControls : PlayerCommand

    /**
     * Lock the screen against stray touches (the lock button in a touch screen's top bar): a menu closes and the
     * controls hide whatever kept them up, and until the screen unlocks they stay hidden and no touch on the video acts;
     * keys, the system's media controls and picture in picture still do.
     */
    data object LockScreen : PlayerCommand

    /**
     * A finger or a pointer went down on the locked screen's unlock button ([held]), or (not [held]) lifted again or was
     * cancelled: held for [com.edde746.plezy.presentation.player.UnlockButton.HOLD_MILLIS] it unlocks; lifted sooner,
     * or a finger moved or joined by a second, it counts for nothing. A view that forwards the button's touches
     * ([InputEvent.Touch]) sends it right after the finger's [TouchPhase.DOWN] and [TouchPhase.UP].
     */
    data class UnlockHold(val held: Boolean) : PlayerCommand

    /** A screen reader pressed the unlock button (it has no finger to hold it with): the screen unlocks at once. */
    data object UnlockPress : PlayerCommand

    data class OpenMenu(val menu: PlayerMenu) : PlayerCommand
    data object CloseMenu : PlayerCommand

    /**
     * Back out of the innermost layer: a scrub, an option's page (back to the options), a menu, the sleep timer's
     * question (as keep watching), the up-next card, the skip button, the info panel, the controls; with none of those,
     * leave the player.
     */
    data object Back : PlayerCommand

    /** Leave the player. */
    data object Close : PlayerCommand

    /** Play the video's version [index] (`SessionInfo.versions`) from the position, remembered for the title. */
    data class SelectVersion(val index: Int) : PlayerCommand

    /** Play at quality [preset] from the position: the original, or the server's transcode capped at it. */
    data class SelectQuality(val preset: TranscodeQualityPreset) : PlayerCommand

    /**
     * Pick the server's track [id] of [kind] (`SessionInfo.sourceAudio` / `sourceSubtitles`; null: subtitles off): the
     * server switches its transcode (or burns the subtitle in) and the video reopens at the position.
     */
    data class SelectSourceTrack(val kind: TrackKind, val id: Int?) : PlayerCommand

    /** The server refused to play the file as it is (its limit): play it again transcoded, at the position. */
    data object ForceTranscode : PlayerCommand

    /** Play the queue's entry [key] (`QueueItem.key`). */
    data class PlayQueueItem(val key: String) : PlayerCommand

    /** Seek to chapter [index] of `PlayerUiState.chapters`. */
    data class SeekToChapter(val index: Int) : PlayerCommand

    /**
     * Search the server's subtitle providers in [language] (ISO 639-1) for [title] (null: the video's own title). The
     * search sheet sends one per edit of its title, which searches once the title rests for half a second; a new
     * language (kept for the next searches) or [now] (the field submitted) searches at once.
     */
    data class SearchSubtitles(val language: String, val title: String?, val now: Boolean = false) : PlayerCommand

    /** Download the search's result [key] to the server and switch to it once the server lists it. */
    data class DownloadSubtitle(val key: String) : PlayerCommand

    /** Lock the phone's rotation to landscape, or let it follow the device (kept as a setting). */
    data object ToggleRotationLock : PlayerCommand

    /** Keep the player's window above the others (Windows, Linux). */
    data object ToggleAlwaysOnTop : PlayerCommand

    /** Push the sleep timer on by 15 minutes. */
    data object ExtendSleepTimer : PlayerCommand

    /** Answer the session's question (`PlayerUiState.choice`) with its option [index]; null dismisses it. */
    data class AnswerChoice(val index: Int?) : PlayerCommand

    /** Watch together: the room panel's and a guest's prompt's actions. */
    data class Watch(val command: WatchCommand) : PlayerCommand
}

/**
 * The commands that move the position, none of which a live playback takes ([seeksLive] aside), nor a guest in a
 * room that doesn't let it control playback ([roomControl]).
 */
val PlayerCommand.seeks: Boolean
    get() = when (this) {
        is PlayerCommand.SeekBy,
        is PlayerCommand.Skip,
        is PlayerCommand.SeekTo,
        is PlayerCommand.SeekToFraction,
        is PlayerCommand.ScrubTo,
        PlayerCommand.CommitScrub,
        PlayerCommand.NextChapter,
        PlayerCommand.PreviousChapter,
        PlayerCommand.SkipSegment,
        PlayerCommand.GoToLive,
        is PlayerCommand.SeekToChapter,
        -> true
        PlayerCommand.TogglePause,
        PlayerCommand.Play,
        PlayerCommand.Pause,
        PlayerCommand.SystemPause,
        PlayerCommand.SystemResume,
        PlayerCommand.CancelScrub,
        is PlayerCommand.HoverTimeline,
        is PlayerCommand.AdjustVolume,
        is PlayerCommand.SetVolume,
        PlayerCommand.ToggleMute,
        PlayerCommand.ToggleFullscreen,
        PlayerCommand.ExitFullscreen,
        is PlayerCommand.SelectTrack,
        is PlayerCommand.ToggleSecondSubtitle,
        PlayerCommand.CycleAudio,
        PlayerCommand.CycleSubtitles,
        is PlayerCommand.OpenSubtitleLanguage,
        is PlayerCommand.AddSubtitle,
        is PlayerCommand.SetSpeed,
        PlayerCommand.SpeedUp,
        PlayerCommand.SpeedDown,
        PlayerCommand.ResetSpeed,
        PlayerCommand.HoldSpeed,
        PlayerCommand.ReleaseSpeed,
        is PlayerCommand.AdjustSubtitleDelay,
        is PlayerCommand.SetSubtitleDelay,
        is PlayerCommand.AdjustAudioDelay,
        is PlayerCommand.SetAudioDelay,
        PlayerCommand.NextEpisode,
        PlayerCommand.PreviousEpisode,
        PlayerCommand.Retry,
        is PlayerCommand.SetVideoFit,
        is PlayerCommand.SetZoom,
        PlayerCommand.ZoomIn,
        PlayerCommand.ZoomOut,
        PlayerCommand.ResetZoom,
        is PlayerCommand.SetShaderPreset,
        PlayerCommand.ToggleShaders,
        PlayerCommand.ToggleAmbientLighting,
        is PlayerCommand.ImportShader,
        PlayerCommand.ShaderImportFailed,
        is PlayerCommand.DeleteShader,
        is PlayerCommand.SetSleepTimer,
        PlayerCommand.SleepAtEndOfVideo,
        PlayerCommand.CancelSleepTimer,
        PlayerCommand.KeepWatching,
        is PlayerCommand.SetAutoPlayNext,
        is PlayerCommand.SetAudioNormalization,
        is PlayerCommand.SetAudioChannels,
        is PlayerCommand.SetAudioDevice,
        is PlayerCommand.SetHdr,
        is PlayerCommand.SetDolbyVisionConversion,
        is PlayerCommand.SimulateHttpStatus,
        PlayerCommand.ToggleInfo,
        PlayerCommand.ShowControls,
        PlayerCommand.HideControls,
        PlayerCommand.ToggleControls,
        PlayerCommand.LockScreen,
        is PlayerCommand.UnlockHold,
        PlayerCommand.UnlockPress,
        is PlayerCommand.OpenMenu,
        PlayerCommand.CloseMenu,
        PlayerCommand.Back,
        PlayerCommand.Close,
        is PlayerCommand.SelectVersion,
        is PlayerCommand.SelectQuality,
        is PlayerCommand.SelectSourceTrack,
        PlayerCommand.ForceTranscode,
        is PlayerCommand.PlayQueueItem,
        is PlayerCommand.SearchSubtitles,
        is PlayerCommand.DownloadSubtitle,
        PlayerCommand.ToggleRotationLock,
        PlayerCommand.ToggleAlwaysOnTop,
        PlayerCommand.ExtendSleepTimer,
        is PlayerCommand.AnswerChoice,
        PlayerCommand.Screenshot,
        PlayerCommand.ToggleSubtitles,
        is PlayerCommand.SubtitleSeek,
        is PlayerCommand.Watch,
        -> false
    }

/**
 * The seeks a live playback with a rewind window takes, within the window: those a video's timeline and keys make. The
 * OS media controls' seek bar ([PlayerCommand.SeekTo]) isn't shown live, and a live stream has no chapters or skips.
 */
val PlayerCommand.seeksLive: Boolean
    get() = when (this) {
        is PlayerCommand.SeekBy,
        is PlayerCommand.Skip,
        is PlayerCommand.SeekToFraction,
        is PlayerCommand.ScrubTo,
        PlayerCommand.CommitScrub,
        PlayerCommand.GoToLive,
        -> true
        PlayerCommand.TogglePause,
        PlayerCommand.Play,
        PlayerCommand.Pause,
        PlayerCommand.SystemPause,
        PlayerCommand.SystemResume,
        is PlayerCommand.SeekTo,
        PlayerCommand.CancelScrub,
        is PlayerCommand.HoverTimeline,
        is PlayerCommand.AdjustVolume,
        is PlayerCommand.SetVolume,
        PlayerCommand.ToggleMute,
        PlayerCommand.ToggleFullscreen,
        PlayerCommand.ExitFullscreen,
        is PlayerCommand.SelectTrack,
        is PlayerCommand.ToggleSecondSubtitle,
        PlayerCommand.CycleAudio,
        PlayerCommand.CycleSubtitles,
        is PlayerCommand.OpenSubtitleLanguage,
        is PlayerCommand.AddSubtitle,
        is PlayerCommand.SetSpeed,
        PlayerCommand.SpeedUp,
        PlayerCommand.SpeedDown,
        PlayerCommand.ResetSpeed,
        PlayerCommand.HoldSpeed,
        PlayerCommand.ReleaseSpeed,
        is PlayerCommand.AdjustSubtitleDelay,
        is PlayerCommand.SetSubtitleDelay,
        is PlayerCommand.AdjustAudioDelay,
        is PlayerCommand.SetAudioDelay,
        PlayerCommand.NextChapter,
        PlayerCommand.PreviousChapter,
        PlayerCommand.NextEpisode,
        PlayerCommand.PreviousEpisode,
        PlayerCommand.SkipSegment,
        PlayerCommand.Retry,
        is PlayerCommand.SetVideoFit,
        is PlayerCommand.SetZoom,
        PlayerCommand.ZoomIn,
        PlayerCommand.ZoomOut,
        PlayerCommand.ResetZoom,
        is PlayerCommand.SetShaderPreset,
        PlayerCommand.ToggleShaders,
        PlayerCommand.ToggleAmbientLighting,
        is PlayerCommand.ImportShader,
        PlayerCommand.ShaderImportFailed,
        is PlayerCommand.DeleteShader,
        is PlayerCommand.SetSleepTimer,
        PlayerCommand.SleepAtEndOfVideo,
        PlayerCommand.CancelSleepTimer,
        PlayerCommand.KeepWatching,
        is PlayerCommand.SetAutoPlayNext,
        is PlayerCommand.SetAudioNormalization,
        is PlayerCommand.SetAudioChannels,
        is PlayerCommand.SetAudioDevice,
        is PlayerCommand.SetHdr,
        is PlayerCommand.SetDolbyVisionConversion,
        is PlayerCommand.SimulateHttpStatus,
        PlayerCommand.ToggleInfo,
        PlayerCommand.ShowControls,
        PlayerCommand.HideControls,
        PlayerCommand.ToggleControls,
        PlayerCommand.LockScreen,
        is PlayerCommand.UnlockHold,
        PlayerCommand.UnlockPress,
        is PlayerCommand.OpenMenu,
        PlayerCommand.CloseMenu,
        PlayerCommand.Back,
        PlayerCommand.Close,
        is PlayerCommand.SelectVersion,
        is PlayerCommand.SelectQuality,
        is PlayerCommand.SelectSourceTrack,
        PlayerCommand.ForceTranscode,
        is PlayerCommand.PlayQueueItem,
        is PlayerCommand.SearchSubtitles,
        is PlayerCommand.DownloadSubtitle,
        PlayerCommand.ToggleRotationLock,
        PlayerCommand.ToggleAlwaysOnTop,
        PlayerCommand.ExtendSleepTimer,
        is PlayerCommand.AnswerChoice,
        PlayerCommand.Screenshot,
        PlayerCommand.ToggleSubtitles,
        is PlayerCommand.SubtitleSeek,
        is PlayerCommand.SeekToChapter,
        is PlayerCommand.Watch,
        -> false
    }

/** What a watch-together room decides of a command: which of its permissions it needs, if any. */
enum class RoomControl {
    /** Another episode: the host's to change. */
    EPISODE,

    /** Play, or play/pause: playback control, or a guest's player paused here alone catching up. */
    PLAY,

    /** Pause: playback control, or the sleep timer's stop. */
    PAUSE,

    /** The speed: playback control. */
    SPEED,

    /** A seek ([PlayerCommand.seeks]): playback control. */
    SEEK,

    /** Nothing the room decides: the system's pause and resume, tracks, menus, volume, the screen's brightness. */
    FREE,
}

/** What a watch-together room decides of this command ([RoomControl]). */
val PlayerCommand.roomControl: RoomControl
    get() = when (this) {
        PlayerCommand.NextEpisode,
        PlayerCommand.PreviousEpisode,
        is PlayerCommand.PlayQueueItem,
        -> RoomControl.EPISODE
        PlayerCommand.TogglePause,
        PlayerCommand.Play,
        -> RoomControl.PLAY
        PlayerCommand.Pause,
        -> RoomControl.PAUSE
        is PlayerCommand.SetSpeed,
        PlayerCommand.SpeedUp,
        PlayerCommand.SpeedDown,
        PlayerCommand.ResetSpeed,
        PlayerCommand.HoldSpeed,
        -> RoomControl.SPEED
        is PlayerCommand.SeekBy,
        is PlayerCommand.Skip,
        is PlayerCommand.SeekTo,
        is PlayerCommand.SeekToFraction,
        is PlayerCommand.ScrubTo,
        PlayerCommand.CommitScrub,
        PlayerCommand.NextChapter,
        PlayerCommand.PreviousChapter,
        PlayerCommand.SkipSegment,
        PlayerCommand.GoToLive,
        is PlayerCommand.SeekToChapter,
        is PlayerCommand.SubtitleSeek,
        -> RoomControl.SEEK
        PlayerCommand.SystemPause,
        PlayerCommand.SystemResume,
        PlayerCommand.CancelScrub,
        is PlayerCommand.HoverTimeline,
        is PlayerCommand.AdjustVolume,
        is PlayerCommand.SetVolume,
        PlayerCommand.ReleaseSpeed,
        PlayerCommand.ToggleMute,
        PlayerCommand.ToggleFullscreen,
        PlayerCommand.ExitFullscreen,
        is PlayerCommand.SelectTrack,
        is PlayerCommand.ToggleSecondSubtitle,
        PlayerCommand.CycleAudio,
        PlayerCommand.CycleSubtitles,
        is PlayerCommand.OpenSubtitleLanguage,
        is PlayerCommand.AddSubtitle,
        is PlayerCommand.AdjustSubtitleDelay,
        is PlayerCommand.SetSubtitleDelay,
        is PlayerCommand.AdjustAudioDelay,
        is PlayerCommand.SetAudioDelay,
        PlayerCommand.Retry,
        is PlayerCommand.SetVideoFit,
        is PlayerCommand.SetZoom,
        PlayerCommand.ZoomIn,
        PlayerCommand.ZoomOut,
        PlayerCommand.ResetZoom,
        is PlayerCommand.SetShaderPreset,
        PlayerCommand.ToggleShaders,
        PlayerCommand.ToggleAmbientLighting,
        is PlayerCommand.ImportShader,
        PlayerCommand.ShaderImportFailed,
        is PlayerCommand.DeleteShader,
        is PlayerCommand.SetSleepTimer,
        PlayerCommand.SleepAtEndOfVideo,
        PlayerCommand.CancelSleepTimer,
        PlayerCommand.KeepWatching,
        is PlayerCommand.SetAutoPlayNext,
        is PlayerCommand.SetAudioNormalization,
        is PlayerCommand.SetAudioChannels,
        is PlayerCommand.SetAudioDevice,
        is PlayerCommand.SetHdr,
        is PlayerCommand.SetDolbyVisionConversion,
        is PlayerCommand.SimulateHttpStatus,
        PlayerCommand.ToggleInfo,
        PlayerCommand.ShowControls,
        PlayerCommand.HideControls,
        PlayerCommand.ToggleControls,
        PlayerCommand.LockScreen,
        is PlayerCommand.UnlockHold,
        PlayerCommand.UnlockPress,
        is PlayerCommand.OpenMenu,
        PlayerCommand.CloseMenu,
        PlayerCommand.Back,
        is PlayerCommand.SelectVersion,
        is PlayerCommand.SelectQuality,
        is PlayerCommand.SelectSourceTrack,
        PlayerCommand.ForceTranscode,
        is PlayerCommand.SearchSubtitles,
        is PlayerCommand.DownloadSubtitle,
        PlayerCommand.ToggleRotationLock,
        PlayerCommand.ToggleAlwaysOnTop,
        PlayerCommand.ExtendSleepTimer,
        is PlayerCommand.AnswerChoice,
        PlayerCommand.Screenshot,
        PlayerCommand.ToggleSubtitles,
        PlayerCommand.Close,
        is PlayerCommand.Watch,
        -> RoomControl.FREE
    }
