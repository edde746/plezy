package com.edde746.plezy.presentation.settings

import com.edde746.plezy.backend.AudioQualityPreset
import com.edde746.plezy.backend.TranscodeQualityPreset
import com.edde746.plezy.data.settings.DeviceSetting
import com.edde746.plezy.data.settings.DeviceSettingsRepository
import com.edde746.plezy.data.settings.DolbyVisionConversion
import com.edde746.plezy.data.settings.SkipMode
import com.edde746.plezy.model.SpecialsOrdering
import com.edde746.plezy.playback.AudioChannels
import com.edde746.plezy.playback.players.KnownPlayers
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.settings.DeinterlaceMode
import com.edde746.plezy.settings.HdrSdrConversion
import com.edde746.plezy.settings.HdrToneMapping
import com.edde746.plezy.settings.PlayerSettingScope
import com.edde746.plezy.settings.ScopedPlayerPrefs
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch

/**
 * Settings → Video Playback: Player, Video & Display, Audio, Quality, Subtitles, Seek & Timing,
 * Auto-Play & Skip, Behavior, Gestures (phones and tablets) and Remember Player Changes. Which rows show follows the
 * settings live: display matching shows the switch delay, the channel limit the mix options, normalization holds
 * passthrough off.
 */
internal class VideoPlaybackPage(
    settings: DeviceSettingsRepository,
    private val facts: StateFlow<SettingsFacts>,
    parentScope: CoroutineScope,
) : RowPageStore(settings, parentScope, { T.settings.videoPlayback }) {
    init {
        follow(facts) {}
        start(READ)
    }

    override fun build(rows: Rows): List<SettingsGroup> {
        val facts = facts.value
        return listOf(
            SettingsGroup("player", T.settings.player, playerRows(rows, facts)),
            SettingsGroup("video", T.settings.videoAndDisplay, videoRows(rows, facts)),
            SettingsGroup("audio", T.settings.audio, audioRows(rows, facts)),
            SettingsGroup("quality", T.settings.quality, qualityRows(rows, facts)),
            SettingsGroup(
                "subtitles",
                T.settings.subtitles,
                listOf(rows.page(SUBTITLE_STYLING, T.settings.subtitleStyling, T.settings.subtitleStylingDescription, SettingIcon.SUBTITLES, SettingsPageId.SUBTITLE_STYLING)),
            ),
            SettingsGroup("seek", T.settings.seekAndTiming, seekRows(rows)),
            SettingsGroup("auto_play", T.settings.autoPlayAndSkip, autoPlayRows(rows)),
            SettingsGroup("behavior", T.settings.behavior, behaviorRows(rows, facts)),
            SettingsGroup("gestures", T.settings.gestures, if (facts.handheld) gestureRows(rows) else emptyList()),
            SettingsGroup("remember", T.settings.rememberPlayerChanges, rememberRows(rows), footer = T.settings.rememberPlayerChangesDescription),
        )
    }

    private fun playerRows(rows: Rows, facts: SettingsFacts): List<SettingRow> = listOfNotNull(
        if (facts.supportsExternalPlayers) {
            rows.page(EXTERNAL_PLAYER, T.externalPlayer.title, null, SettingIcon.OPEN_IN_NEW, SettingsPageId.EXTERNAL_PLAYER, valueLabel = externalPlayerValue(facts))
        } else {
            null
        },
        rows.page(MPV_CONFIG, T.mpvConfig.title, T.mpvConfig.description, SettingIcon.TUNE, SettingsPageId.MPV_CONFIG),
        rows.toggle(HARDWARE_DECODING, AppSettings.enableHardwareDecoding, T.settings.hardwareDecoding, T.settings.hardwareDecodingDescription, SettingIcon.MEMORY),
        if (facts.supportsPip) {
            rows.toggle(AUTO_PIP, AppSettings.autoPipOn(value(AppSettings.autoPip), supportsPictureInPicture = true, isMacOs = facts.macos), T.settings.autoPip, T.settings.autoPipDescription, SettingIcon.EXIT_FULLSCREEN) {
                write(AppSettings.autoPip, it)
            }
        } else {
            null
        },
    )

    /** "Off", "System Default", or the selected player's name. */
    private fun externalPlayerValue(facts: SettingsFacts): String {
        val choice = value(AppSettings.selectedExternalPlayer)
        return when {
            !AppSettings.useExternalPlayerOn(value(AppSettings.useExternalPlayer), facts.supportsExternalPlayers) -> T.externalPlayer.off
            choice.id == KnownPlayers.SYSTEM_DEFAULT_ID -> T.externalPlayer.systemDefault
            else -> choice.name
        }
    }

    private fun videoRows(rows: Rows, facts: SettingsFacts): List<SettingRow> {
        val matchRefresh = value(AppSettings.matchRefreshRate)
        val matchDynamic = value(AppSettings.matchDynamicRange)
        val showSwitchDelay = facts.appleTv ||
            (facts.windows && (matchRefresh || matchDynamic)) ||
            (facts.macos && matchRefresh) ||
            (facts.android && (value(AppSettings.matchContentFrameRate) || value(AppSettings.matchContentResolution)))
        val showDisableDolbyVision = facts.android || facts.appleTv
        val showDvConversion = facts.android && !value(AppSettings.disableDolbyVision)
        val hdr = facts.features.hdr && (facts.ios || facts.desktopOs)
        return listOfNotNull(
            if (facts.android) {
                rows.toggle(MATCH_FRAME_RATE, AppSettings.matchContentFrameRate, T.settings.matchContentFrameRate, T.settings.matchContentFrameRateDescription, SettingIcon.DISPLAY)
            } else {
                null
            },
            if (facts.androidTv) {
                rows.toggle(MATCH_RESOLUTION, AppSettings.matchContentResolution, T.settings.matchContentResolution, T.settings.matchContentResolutionDescription, SettingIcon.HD)
            } else {
                null
            },
            if (facts.windows || facts.macos) {
                rows.toggle(MATCH_REFRESH_RATE, AppSettings.matchRefreshRate, T.settings.matchRefreshRate, T.settings.matchRefreshRateDescription, SettingIcon.DISPLAY)
            } else {
                null
            },
            if (facts.windows) rows.toggle(MATCH_DYNAMIC_RANGE, AppSettings.matchDynamicRange, T.settings.matchDynamicRange, T.settings.matchDynamicRangeDescription, SettingIcon.TONALITY) else null,
            if (showSwitchDelay) {
                rows.number(
                    DISPLAY_SWITCH_DELAY, AppSettings.displaySwitchDelay, T.settings.displaySwitchDelay, ::seconds,
                    T.settings.secondsLabel, T.settings.secondsShort, SettingIcon.SCHEDULE,
                )
            } else {
                null
            },
            if (hdr) rows.toggle(HDR, AppSettings.enableHdr, T.videoSettings.hdr, null, SettingIcon.HDR) else null,
            if (hdr && facts.linux && value(AppSettings.enableHdr)) {
                rows.choice(
                    HDR_TONE_MAPPING, AppSettings.hdrToneMapping, T.videoSettings.hdrToneMapping,
                    choices(
                        HdrToneMapping.entries,
                        { if (it == HdrToneMapping.COMPOSITOR) T.videoSettings.hdrToneMappingCompositor else T.videoSettings.hdrToneMappingPlayer },
                        { if (it == HdrToneMapping.COMPOSITOR) T.videoSettings.hdrToneMappingCompositorDescription else T.videoSettings.hdrToneMappingPlayerDescription },
                    ),
                    SettingIcon.BRIGHTNESS,
                )
            } else {
                null
            },
            if (showDisableDolbyVision) {
                rows.toggle(DISABLE_DOLBY_VISION, AppSettings.disableDolbyVision, T.settings.disableDolbyVision, T.settings.disableDolbyVisionDescription, SettingIcon.HDR_OFF)
            } else {
                null
            },
            if (showDvConversion) {
                rows.choice(
                    DV_CONVERSION, AppSettings.dvConversionMode, T.settings.dvConversionMode,
                    choices(DolbyVisionConversion.entries, ::dvLabel, ::dvDescription), SettingIcon.HDR_STRONG,
                )
            } else {
                null
            },
            if (facts.android) {
                rows.choice(
                    HDR_SDR_CONVERSION, AppSettings.hdrSdrConversion, T.settings.hdrSdrConversion,
                    choices(HdrSdrConversion.entries, ::hdrSdrLabel, ::hdrSdrDescription), SettingIcon.TONALITY,
                )
            } else {
                null
            },
            rows.choice(
                DEINTERLACE, AppSettings.deinterlaceMode, T.settings.deinterlace,
                choices(DeinterlaceMode.entries, ::deinterlaceLabel, ::deinterlaceDescription), SettingIcon.LAYERS,
            ),
        )
    }

    private fun audioRows(rows: Rows, facts: SettingsFacts): List<SettingRow> {
        val channels = value(AppSettings.audioChannelLimit)
        return listOfNotNull(
            if (facts.supportsAudioPassthrough) passthroughRow(rows, facts) else null,
            rows.choice(
                AUDIO_CHANNELS, T.settings.audioChannelLimit,
                choices(AudioChannels.entries, ::channelsLabel) { channelsDescription(it, facts.supportsAudioPassthrough) }, channels,
                SettingIcon.SPEAKER,
            ) { write(AppSettings.audioChannelLimit, it) },
            if (channels == AudioChannels.STEREO) {
                rows.number(
                    CENTER_BOOST, AppSettings.downmixCenterBoost, T.settings.downmixCenterBoost, { T.settings.downmixCenterBoostValue(it.toString()) },
                    T.settings.downmixCenterBoostLabel, T.settings.downmixCenterBoostShort, SettingIcon.VOICE,
                )
            } else {
                null
            },
            if (channels != AudioChannels.ORIGINAL) {
                rows.toggle(DOWNMIX_NORMALIZE, AppSettings.audioDownmixNormalize, T.settings.audioDownmixNormalize, T.settings.audioDownmixNormalizeDescription, SettingIcon.GRAPHIC_EQ)
            } else {
                null
            },
            rows.number(
                MAX_VOLUME, AppSettings.maxVolume, T.settings.maxVolume, { T.settings.maxVolumePercent(it.toString()) },
                T.settings.maxVolumeDescription, "%", SettingIcon.VOLUME,
            ),
        )
    }

    /** Passthrough: held off, dimmed and explained while loudness normalization is on. */
    private fun passthroughRow(rows: Rows, facts: SettingsFacts): SettingToggleRow {
        val normalizing = value(AppSettings.audioNormalization)
        val subtitle = when {
            normalizing -> T.settings.audioPassthroughOverriddenByNormalization
            facts.features.passthroughTarget == PassthroughTarget.SYSTEM_SPATIAL -> T.settings.audioPassthroughDescriptionAppleSpatial
            facts.features.passthroughTarget == PassthroughTarget.SYSTEM_DECODER -> T.settings.audioPassthroughDescriptionApple
            else -> T.settings.audioPassthroughDescription
        }
        val on = !normalizing && AppSettings.audioPassthroughOn(value(AppSettings.audioPassthrough), facts.tv)
        return rows.toggle(AUDIO_PASSTHROUGH, on, T.settings.audioPassthrough, subtitle, SettingIcon.SURROUND, enabled = !normalizing) {
            write(AppSettings.audioPassthrough, it)
        }
    }

    private fun qualityRows(rows: Rows, facts: SettingsFacts): List<SettingRow> {
        val presets = TranscodeQualityPreset.displayOrder.map { Choice(it, it.name, qualityLabel(it)) }
        return listOfNotNull(
            rows.choice(DEFAULT_QUALITY, AppSettings.defaultQualityPreset, T.settings.defaultQualityTitle, presets, SettingIcon.HD),
            if (facts.handheld) {
                rows.choice(
                    CELLULAR_QUALITY, AppSettings.cellularQualityPreset, T.settings.cellularQualityTitle,
                    listOf(Choice<TranscodeQualityPreset?>(null, SAME_AS_DEFAULT, T.settings.cellularQualitySameAsDefault)) +
                        presets.map { Choice<TranscodeQualityPreset?>(it.value, it.id, it.label) },
                    SettingIcon.CELLULAR,
                )
            } else {
                null
            },
            rows.toggle(DIRECT_PLAY_COVERED, AppSettings.directPlayCoveredQuality, T.settings.directPlayCoveredQuality, T.settings.directPlayCoveredQualityDescription, SettingIcon.PLAY_ARROW),
            if (facts.desktopOs) codecsRow(rows) else null,
            rows.choice(
                MUSIC_QUALITY, AppSettings.musicQualityPreset, T.settings.musicQualityTitle,
                choices(AudioQualityPreset.entries, ::musicQualityLabel), SettingIcon.MUSIC,
            ),
        )
    }

    /** Video Codecs: the checked codecs are accepted; H.264 always is. Stores the unchecked ones. */
    private fun codecsRow(rows: Rows): SettingChecklistRow {
        val refused = value(AppSettings.refusedVideoCodecs)
        val options = CODECS.map { (id, label) ->
            val locked = id == H264
            SettingCheckOption(id, label, checked = locked || id !in refused, locked = locked, subtitle = if (locked) T.settings.videoCodecsAlwaysAccepted else null)
        }
        val accepted = options.filter { it.checked }.joinToString(", ") { it.label }
        return rows.checklist(VIDEO_CODECS, T.settings.videoCodecs, accepted, T.settings.videoCodecsDescription, options, SettingIcon.MOVIE) { checked ->
            write(AppSettings.refusedVideoCodecs, CODECS.map { it.first }.filter { it != H264 && it !in checked })
        }
    }

    private fun seekRows(rows: Rows): List<SettingRow> = listOf(
        rows.number(SEEK_SMALL, AppSettings.seekTimeSmall, T.settings.smallSkipDuration, ::seconds, T.settings.secondsLabel, T.settings.secondsShort, SettingIcon.REPLAY_10),
        rows.number(SEEK_LARGE, AppSettings.seekTimeLarge, T.settings.largeSkipDuration, ::seconds, T.settings.secondsLabel, T.settings.secondsShort, SettingIcon.REPLAY_30),
        rows.number(REWIND_ON_RESUME, AppSettings.rewindOnResume, T.settings.rewindOnResume, ::seconds, T.settings.secondsLabel, T.settings.secondsShort, SettingIcon.REPLAY),
        rows.number(
            SLEEP_TIMER, AppSettings.sleepTimerDuration, T.settings.defaultSleepTimer, { T.settings.minutesUnit(it.toString()) },
            T.settings.minutesLabel, T.settings.minutesShort, SettingIcon.BEDTIME,
        ),
    )

    private fun autoPlayRows(rows: Rows): List<SettingRow> = listOf(
        rows.toggle(AUTO_PLAY_NEXT, AppSettings.autoPlayNextEpisode, T.settings.autoPlayNextEpisode, T.settings.autoPlayNextEpisodeDescription, SettingIcon.PLAYLIST_PLAY),
        rows.toggle(SHUFFLE_FROM_BEGINNING, AppSettings.shuffleStartsFromBeginning, T.settings.shuffleStartsFromBeginning, T.settings.shuffleStartsFromBeginningDescription, SettingIcon.SHUFFLE),
        rows.number(
            PLAY_NEXT_COUNTDOWN, AppSettings.playNextCountdown, T.settings.playNextCountdown,
            { if (it == 0) T.settings.playNextCountdownImmediate else seconds(it) },
            T.settings.secondsLabel, T.settings.secondsShort, SettingIcon.TIMER,
        ),
        rows.choice(
            SKIP_INTRO, AppSettings.skipIntroMode, T.settings.skipIntroMode, choices(SkipMode.entries, ::skipLabel), SettingIcon.FAST_FORWARD,
            caption = introDescription(value(AppSettings.skipIntroMode)),
        ),
        rows.choice(
            SKIP_CREDITS, AppSettings.skipCreditsMode, T.settings.skipCreditsMode, choices(SkipMode.entries, ::skipLabel), SettingIcon.SKIP_NEXT,
            caption = creditsDescription(value(AppSettings.skipCreditsMode)),
        ),
        rows.toggle(FORCE_MARKER_FALLBACK, AppSettings.forceSkipMarkerFallback, T.settings.forceSkipMarkerFallback, T.settings.forceSkipMarkerFallbackDescription, SettingIcon.BOOKMARK),
        rows.number(AUTO_SKIP_DELAY, AppSettings.autoSkipDelay, T.settings.autoSkipDelay, ::seconds, T.settings.secondsLabel, T.settings.secondsShort, SettingIcon.HOURGLASS),
        rows.regex(INTRO_PATTERN, AppSettings.introPattern, T.settings.introPattern, T.settings.introPatternDescription, SettingIcon.TEXT_SELECT_START),
        rows.regex(CREDITS_PATTERN, AppSettings.creditsPattern, T.settings.creditsPattern, T.settings.creditsPatternDescription, SettingIcon.TEXT_SELECT_END),
    )

    private fun behaviorRows(rows: Rows, facts: SettingsFacts): List<SettingRow> = listOfNotNull(
        rows.toggle(
            REMEMBER_TRACKS, AppSettings.rememberTrackSelections, T.settings.rememberTrackSelections,
            "${T.settings.rememberTrackSelectionsDescription} · ${T.settings.rememberTrackSelectionsBackendRule}", SettingIcon.BOOKMARK,
        ),
        rows.toggle(FOLLOW_SERVER_TRACKS, AppSettings.followServerTrackSelections, T.settings.followServerTrackSelections, T.settings.followServerTrackSelectionsDescription, SettingIcon.DNS),
        rows.toggle(RESUME_MUSIC, AppSettings.resumeMusicOnLaunch, T.settings.resumeMusicOnLaunch, T.settings.resumeMusicOnLaunchDescription, SettingIcon.MUSIC),
        rows.toggle(CHAPTER_MARKERS, AppSettings.showChapterMarkersOnTimeline, T.settings.showChapterMarkersOnTimeline, T.settings.showChapterMarkersOnTimelineDescription, SettingIcon.CHAPTERS),
        rows.choice(
            SPECIALS_ORDERING, AppSettings.specialsOrdering, T.settings.specialsOrdering,
            choices(SpecialsOrdering.entries, ::specialsLabel), SettingIcon.ORDER,
        ),
        // A pointer's click: not on a touch screen, nor with a TV's remote.
        if (facts.handheld || facts.tv || facts.appleTv) {
            null
        } else {
            rows.toggle(CLICK_TOGGLES_PLAYBACK, AppSettings.clickVideoTogglesPlayback, T.settings.clickVideoTogglesPlayback, T.settings.clickVideoTogglesPlaybackDescription, SettingIcon.MOUSE)
        },
        if (facts.desktopOs) {
            rows.toggle(EXIT_FULLSCREEN_ON_CLOSE, AppSettings.exitFullscreenOnPlayerClose, T.settings.exitFullscreenOnPlayerClose, T.settings.exitFullscreenOnPlayerCloseDescription, SettingIcon.EXIT_FULLSCREEN)
        } else {
            null
        },
    )

    private fun gestureRows(rows: Rows): List<SettingRow> = listOf(
        rows.toggle(BRIGHTNESS_SWIPE, AppSettings.gestureBrightnessSwipe, T.settings.gestureBrightnessSwipe, T.settings.gestureBrightnessSwipeDescription, SettingIcon.BRIGHTNESS),
        rows.toggle(REMEMBER_BRIGHTNESS, AppSettings.rememberBrightnessLevel, T.settings.rememberBrightnessLevel, T.settings.rememberBrightnessLevelDescription, SettingIcon.RESTORE),
        rows.toggle(VOLUME_SWIPE, AppSettings.gestureVolumeSwipe, T.settings.gestureVolumeSwipe, T.settings.gestureVolumeSwipeDescription, SettingIcon.VOLUME),
        rows.toggle(PINCH_TO_ZOOM, AppSettings.gesturePinchToZoom, T.settings.gesturePinchToZoom, T.settings.gesturePinchToZoomDescription, SettingIcon.ZOOM),
    )

    private fun rememberRows(rows: Rows): List<SettingRow> = listOf(
        scopeRow(rows, PLAYBACK_SPEED_SCOPE, AppSettings.playbackSpeedScope, T.settings.scopePlaybackSpeed, SettingIcon.SPEED),
        scopeRow(rows, SHADER_SCOPE, AppSettings.shaderPresetScope, T.settings.scopeShaderPreset, SettingIcon.SHADER),
        scopeRow(rows, BOX_FIT_SCOPE, AppSettings.boxFitScope, T.settings.scopeAspectRatio, SettingIcon.ASPECT),
        scopeRow(rows, ZOOM_SCOPE, AppSettings.videoZoomScope, T.settings.scopeZoom, SettingIcon.CROP_FREE),
        scopeRow(rows, SYNC_SCOPE, AppSettings.syncOffsetScope, T.settings.scopeSyncOffsets, SettingIcon.SYNC_OFFSET),
    )

    /** A remember row; a pick goes through [ScopedPlayerPrefs.setScope], which resets the globals a keyed scope leaves. */
    private fun scopeRow(rows: Rows, id: String, setting: DeviceSetting<PlayerSettingScope>, title: String, icon: SettingIcon) =
        rows.choice(id, title, choices(PlayerSettingScope.entries, ::scopeLabel), value(setting), icon) { picked ->
            scope.launch { guarded("storing ${setting.key}") { ScopedPlayerPrefs.setScope(settings, setting, picked) } }
        }

    companion object {
        const val EXTERNAL_PLAYER = "external_player"
        const val MPV_CONFIG = "mpv_config"
        const val HARDWARE_DECODING = "hardware_decoding"
        const val AUTO_PIP = "auto_pip"
        const val MATCH_FRAME_RATE = "match_content_frame_rate"
        const val MATCH_RESOLUTION = "match_content_resolution"
        const val MATCH_REFRESH_RATE = "match_refresh_rate"
        const val MATCH_DYNAMIC_RANGE = "match_dynamic_range"
        const val DISPLAY_SWITCH_DELAY = "display_switch_delay"
        const val HDR = "enable_hdr"
        const val HDR_TONE_MAPPING = "hdr_tone_mapping"
        const val DISABLE_DOLBY_VISION = "disable_dolby_vision"
        const val DV_CONVERSION = "dv_conversion_mode"
        const val HDR_SDR_CONVERSION = "hdr_sdr_conversion"
        const val DEINTERLACE = "deinterlace_mode"
        const val AUDIO_PASSTHROUGH = "audio_passthrough"
        const val AUDIO_CHANNELS = "audio_channel_limit"
        const val CENTER_BOOST = "downmix_center_boost"
        const val DOWNMIX_NORMALIZE = "audio_downmix_normalize"
        const val MAX_VOLUME = "max_volume"
        const val DEFAULT_QUALITY = "default_quality_preset"
        const val CELLULAR_QUALITY = "cellular_quality_preset"
        const val DIRECT_PLAY_COVERED = "direct_play_covered_quality"
        const val VIDEO_CODECS = "refused_video_codecs"
        const val MUSIC_QUALITY = "music_quality_preset"
        const val SUBTITLE_STYLING = "subtitle_styling"
        const val SEEK_SMALL = "seek_time_small"
        const val SEEK_LARGE = "seek_time_large"
        const val REWIND_ON_RESUME = "rewind_on_resume"
        const val SLEEP_TIMER = "sleep_timer_duration"
        const val AUTO_PLAY_NEXT = "auto_play_next_episode"
        const val SHUFFLE_FROM_BEGINNING = "shuffle_starts_from_beginning"
        const val PLAY_NEXT_COUNTDOWN = "play_next_countdown"
        const val SKIP_INTRO = "skip_intro_mode"
        const val SKIP_CREDITS = "skip_credits_mode"
        const val FORCE_MARKER_FALLBACK = "force_skip_marker_fallback"
        const val AUTO_SKIP_DELAY = "auto_skip_delay"
        const val INTRO_PATTERN = "intro_pattern"
        const val CREDITS_PATTERN = "credits_pattern"
        const val REMEMBER_TRACKS = "remember_track_selections"
        const val FOLLOW_SERVER_TRACKS = "follow_server_track_selections"
        const val RESUME_MUSIC = "resume_music_on_launch"
        const val CHAPTER_MARKERS = "show_chapter_markers_on_timeline"
        const val SPECIALS_ORDERING = "specials_ordering"
        const val CLICK_TOGGLES_PLAYBACK = "click_video_toggles_playback"
        const val EXIT_FULLSCREEN_ON_CLOSE = "exit_fullscreen_on_player_close"
        const val BRIGHTNESS_SWIPE = "gesture_brightness_swipe"
        const val REMEMBER_BRIGHTNESS = "remember_brightness_level"
        const val VOLUME_SWIPE = "gesture_volume_swipe"
        const val PINCH_TO_ZOOM = "gesture_pinch_to_zoom"
        const val PLAYBACK_SPEED_SCOPE = "playback_speed_scope"
        const val SHADER_SCOPE = "shader_preset_scope"
        const val BOX_FIT_SCOPE = "box_fit_scope"
        const val ZOOM_SCOPE = "video_zoom_scope"
        const val SYNC_SCOPE = "sync_offset_scope"

        /** The cellular quality's "Use Default" option: it follows the Default Quality. */
        const val SAME_AS_DEFAULT = "same_as_default"

        private const val H264 = "h264"
        private val CODECS = listOf("av1" to "AV1", "hevc" to "HEVC", H264 to "H.264")

        private val READ: List<DeviceSetting<*>> = listOf(
            AppSettings.useExternalPlayer, AppSettings.selectedExternalPlayer,
            AppSettings.enableHardwareDecoding, AppSettings.autoPip,
            AppSettings.matchContentFrameRate, AppSettings.matchContentResolution, AppSettings.matchRefreshRate, AppSettings.matchDynamicRange,
            AppSettings.displaySwitchDelay, AppSettings.enableHdr, AppSettings.hdrToneMapping, AppSettings.disableDolbyVision,
            AppSettings.dvConversionMode, AppSettings.hdrSdrConversion, AppSettings.deinterlaceMode, AppSettings.audioPassthrough,
            AppSettings.audioNormalization, AppSettings.audioChannelLimit, AppSettings.downmixCenterBoost, AppSettings.audioDownmixNormalize,
            AppSettings.maxVolume, AppSettings.defaultQualityPreset, AppSettings.cellularQualityPreset, AppSettings.directPlayCoveredQuality,
            AppSettings.refusedVideoCodecs, AppSettings.musicQualityPreset, AppSettings.seekTimeSmall, AppSettings.seekTimeLarge,
            AppSettings.rewindOnResume, AppSettings.sleepTimerDuration, AppSettings.autoPlayNextEpisode, AppSettings.shuffleStartsFromBeginning,
            AppSettings.playNextCountdown, AppSettings.skipIntroMode, AppSettings.skipCreditsMode, AppSettings.forceSkipMarkerFallback,
            AppSettings.autoSkipDelay, AppSettings.introPattern, AppSettings.creditsPattern, AppSettings.rememberTrackSelections,
            AppSettings.followServerTrackSelections, AppSettings.resumeMusicOnLaunch, AppSettings.showChapterMarkersOnTimeline,
            AppSettings.specialsOrdering, AppSettings.clickVideoTogglesPlayback, AppSettings.exitFullscreenOnPlayerClose,
            AppSettings.gestureBrightnessSwipe, AppSettings.rememberBrightnessLevel, AppSettings.gestureVolumeSwipe,
            AppSettings.gesturePinchToZoom, AppSettings.playbackSpeedScope, AppSettings.shaderPresetScope, AppSettings.boxFitScope,
            AppSettings.videoZoomScope, AppSettings.syncOffsetScope,
        )

        private fun seconds(value: Int) = T.settings.secondsUnit(value.toString())

        private fun dvLabel(mode: DolbyVisionConversion) = when (mode) {
            DolbyVisionConversion.AUTO -> T.settings.dvConversionAuto
            DolbyVisionConversion.DISABLED -> T.settings.dvConversionNative
            DolbyVisionConversion.DV81 -> T.settings.dvConversionDv81
            DolbyVisionConversion.HEVC_STRIP -> T.settings.dvConversionHevcStrip
        }

        private fun dvDescription(mode: DolbyVisionConversion) = when (mode) {
            DolbyVisionConversion.AUTO -> T.settings.dvConversionAutoDescription
            DolbyVisionConversion.DISABLED -> T.settings.dvConversionNativeDescription
            DolbyVisionConversion.DV81 -> T.settings.dvConversionDv81Description
            DolbyVisionConversion.HEVC_STRIP -> T.settings.dvConversionHevcStripDescription
        }

        private fun hdrSdrLabel(mode: HdrSdrConversion) = when (mode) {
            HdrSdrConversion.AUTO -> T.settings.hdrSdrConversionAuto
            HdrSdrConversion.DEVICE -> T.settings.hdrSdrConversionDevice
            HdrSdrConversion.PLAYER -> T.settings.hdrSdrConversionPlayer
        }

        private fun hdrSdrDescription(mode: HdrSdrConversion) = when (mode) {
            HdrSdrConversion.AUTO -> T.settings.hdrSdrConversionAutoDescription
            HdrSdrConversion.DEVICE -> T.settings.hdrSdrConversionDeviceDescription
            HdrSdrConversion.PLAYER -> T.settings.hdrSdrConversionPlayerDescription
        }

        private fun deinterlaceLabel(mode: DeinterlaceMode) = when (mode) {
            DeinterlaceMode.OFF -> T.settings.deinterlaceOff
            DeinterlaceMode.VIDEO -> T.settings.deinterlaceVideo
            DeinterlaceMode.FILM -> T.settings.deinterlaceFilm
        }

        private fun deinterlaceDescription(mode: DeinterlaceMode) = when (mode) {
            DeinterlaceMode.OFF -> T.settings.deinterlaceOffDescription
            DeinterlaceMode.VIDEO -> T.settings.deinterlaceVideoDescription
            DeinterlaceMode.FILM -> T.settings.deinterlaceFilmDescription
        }

        private fun channelsLabel(channels: AudioChannels) = when (channels) {
            AudioChannels.ORIGINAL -> T.settings.audioChannelLimitOriginal
            AudioChannels.SURROUND_51 -> T.settings.audioChannelLimitSurround51
            AudioChannels.STEREO -> T.settings.audioChannelLimitStereo
        }

        /** Stereo's says it turns passthrough off only where the device has passthrough. */
        private fun channelsDescription(channels: AudioChannels, passthrough: Boolean) = when (channels) {
            AudioChannels.ORIGINAL -> T.settings.audioChannelLimitOriginalDescription
            AudioChannels.SURROUND_51 -> T.settings.audioChannelLimitSurround51Description
            AudioChannels.STEREO -> if (passthrough) T.settings.audioChannelLimitStereoDescription else null
        }

        private fun skipLabel(mode: SkipMode) = when (mode) {
            SkipMode.OFF -> T.settings.skipMarkerModeOff
            SkipMode.BUTTON -> T.settings.skipMarkerModeButton
            SkipMode.AUTO -> T.settings.skipMarkerModeAuto
        }

        private fun introDescription(mode: SkipMode) = when (mode) {
            SkipMode.OFF -> T.settings.skipIntroModeOffDescription
            SkipMode.BUTTON -> T.settings.skipIntroModeButtonDescription
            SkipMode.AUTO -> T.settings.skipIntroModeAutoDescription
        }

        private fun creditsDescription(mode: SkipMode) = when (mode) {
            SkipMode.OFF -> T.settings.skipCreditsModeOffDescription
            SkipMode.BUTTON -> T.settings.skipCreditsModeButtonDescription
            SkipMode.AUTO -> T.settings.skipCreditsModeAutoDescription
        }

        private fun specialsLabel(ordering: SpecialsOrdering) = when (ordering) {
            SpecialsOrdering.RESPECT_SERVER -> T.settings.specialsOrderingServer
            SpecialsOrdering.AIR_DATE -> T.settings.specialsOrderingAirDate
            SpecialsOrdering.SPECIALS_LAST -> T.settings.specialsOrderingLast
        }
    }
}
