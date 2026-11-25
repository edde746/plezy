package com.edde746.plezy.settings

import com.edde746.plezy.backend.AudioQualityPreset
import com.edde746.plezy.backend.TranscodeQualityPreset
import com.edde746.plezy.data.settings.DeviceSetting
import com.edde746.plezy.data.settings.DeviceSettingsRepository
import com.edde746.plezy.data.settings.DolbyVisionConversion
import com.edde746.plezy.data.settings.SettingRange
import com.edde746.plezy.data.settings.SkipMode
import com.edde746.plezy.lang.LanguageTags
import com.edde746.plezy.model.EpisodePosterMode
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.model.PlaybackExtras
import com.edde746.plezy.model.SpecialsOrdering
import com.edde746.plezy.playback.AudioChannels
import com.edde746.plezy.playback.CustomShader
import com.edde746.plezy.playback.ShaderPreset
import com.edde746.plezy.playback.VideoFit
import com.edde746.plezy.trackers.TrackerService
import com.edde746.plezy.watch.WatchPartyRelays
import kotlinx.serialization.KSerializer
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.builtins.nullable
import kotlinx.serialization.builtins.serializer
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject

/**
 * Plezy's settings of this device, one value for every profile, each under the key Plezy's earlier releases stored
 * it as. A setting whose default depends on the device (a TV, a desktop, a car) is stored nullable, `null` while
 * unset, and resolved with the device's facts where it is read ([defaultThemeMode], [audioPassthroughOn], …): TV
 * detection isn't settled when settings are first read.
 */
object AppSettings {
    private val R_E = SettingPolicy.RESET_AND_EXPORT
    private val R = SettingPolicy.RESET
    private val E = SettingPolicy.EXPORT

    private fun bool(key: String, default: Boolean, policy: SettingPolicy) =
        AppSetting(key, default, Boolean.serializer(), policy = policy)

    private fun int(key: String, default: Int, policy: SettingPolicy, range: IntRange? = null): AppSetting<Int> {
        val normalize: (Int) -> Int = range?.let { r -> { v: Int -> v.coerceIn(r) } } ?: { v: Int -> v }
        return AppSetting(key, default, Int.serializer(), normalize, policy)
    }

    private fun double(key: String, default: Double, policy: SettingPolicy, range: ClosedFloatingPointRange<Double>? = null): AppSetting<Double> {
        val normalize: (Double) -> Double = range?.let { r -> { v: Double -> v.coerceIn(r) } } ?: { v: Double -> v }
        return AppSetting(key, default, Double.serializer(), normalize, policy)
    }

    private fun string(key: String, default: String, policy: SettingPolicy) =
        AppSetting(key, default, String.serializer(), policy = policy)

    private fun nullableString(key: String, policy: SettingPolicy, normalize: (String?) -> String? = { it }) =
        AppSetting(key, null, String.serializer().nullable, normalize, policy)

    private fun <T> setting(key: String, default: T, serializer: KSerializer<T>, policy: SettingPolicy) =
        AppSetting(key, default, serializer, policy = policy)

    private val stringList = ListSerializer(String.serializer())

    /** The ranges a few settings are clamped to when stored and read, shared with [ScopedPlayerPrefs]. */
    val PLAYBACK_SPEED_RANGE: ClosedFloatingPointRange<Double> = 0.25..8.0
    val VIDEO_ZOOM_RANGE: ClosedFloatingPointRange<Double> = 0.5..2.0
    val LIBRARY_DENSITY_RANGE: IntRange = 1..5
    val AUTOMOTIVE_UI_SCALE_RANGE: ClosedFloatingPointRange<Double> = 1.0..2.0
    val SUBTITLE_BACKGROUND_RANGE = SettingRange(0, 100)
    const val AUTOMOTIVE_UI_SCALE_DEFAULT: Double = 1.35

    // ---- General and advanced --------------------------------------------------------------------------------------

    /** Verbose logging. */
    val enableDebugLogging = bool("enable_debug_logging", false, R_E)

    /** Sending crash reports; neither reset nor exported. */
    val crashReporting = bool("crash_reporting", true, SettingPolicy.NONE)

    /** The section the app opens in. */
    val startupSection = setting("startup_section", StartupSection.DISCOVER, StartupSection.serializer(), R_E)

    /** The interface language's [AppLocale.storedName], or null for the device's languages ([AppLocale.fromStored]). */
    val appLocale = nullableString("app_locale", R_E) { it?.takeIf(String::isNotEmpty) }

    /** Asking which profile to use as the app opens, when there is more than one. */
    val requireProfileSelectionOnOpen = bool("require_profile_selection_on_open", false, R_E)

    /** The TV interface on any device (Android, desktop). */
    val forceTvMode = bool("force_tv_mode", false, R_E)

    /** Android's visual effects budget. */
    val visualEffects = setting("visual_effects", VisualEffects.AUTO, VisualEffects.serializer(), R_E)

    /** Checking for a new release as the app opens (desktop builds that update themselves). */
    val autoCheckUpdatesOnStartup = bool("auto_check_updates_on_startup", true, R_E)

    /** Opening in fullscreen (desktop). */
    val startInFullscreen = bool("start_in_fullscreen", false, E)

    /** Discord Rich Presence (desktop). */
    val enableDiscordRpc = bool("enable_discord_rpc", false, R_E)

    /** "Allow casting to this device"; null for the device's default ([castingAllowed]). */
    val allowCasting = AppSetting<Boolean?>("allow_casting", null, Boolean.serializer().nullable, policy = E)

    /** A self-hosted Open Watch Party relay's base URL, or null for the public relays. */
    val watchPartyRelayUrl = nullableString("watch_party_relay_url", R) { it?.let(WatchPartyRelays::canonicalBaseUrl) }

    // ---- Appearance --------------------------------------------------------------------------------------------------

    /** The theme; null while unset ([defaultThemeMode]). */
    val themeMode = AppSetting<ThemeMode?>("theme_mode", null, ThemeMode.serializer().nullable, policy = R_E)

    /** The Custom theme's colours, or null until the theme editor first saves them; a partial or corrupt one reads null. */
    val customThemePalette = AppSetting<CustomThemePalette?>(
        "custom_theme_palette",
        null,
        CustomThemePalette.serializer().nullable,
        { it?.canonical() },
        R_E,
    )

    val viewMode = setting("view_mode", ViewMode.GRID, ViewMode.serializer(), R_E)

    /** Library card density, 1 (most compact) to 5 (most comfortable). */
    val libraryDensity = int("library_density", 3, R_E, LIBRARY_DENSITY_RANGE)

    /** The gap between grid cards; null while unset ([defaultGridSpacing]). */
    val gridSpacing = AppSetting<GridSpacing?>("grid_spacing", null, GridSpacing.serializer().nullable, policy = R_E)

    /** The interface's scale in a car; null while unset ([automotiveUiScale]). */
    val automotiveUiScale = AppSetting<Double?>(
        "automotive_ui_scale",
        null,
        Double.serializer().nullable,
        { it?.coerceIn(AUTOMOTIVE_UI_SCALE_RANGE) },
        R_E,
    )

    val showHeroSection = bool("show_hero_section", true, R_E)
    val tvFullCardLayout = bool("tv_full_card_layout", false, E)
    val focusGlow = bool("focus_glow", true, E)

    /** "Use Home Layout": Discover shows the servers' own hubs. */
    val useGlobalHubs = bool("use_global_hubs", true, E)
    val showServerNameOnHubs = bool("show_server_name_on_hubs", false, E)
    val groupLibrariesByServer = bool("group_libraries_by_server", true, E)
    val showExploreTab = bool("show_explore_tab", true, R_E)
    val alwaysKeepSidebarOpen = bool("always_keep_sidebar_open", false, R_E)
    val showUnwatchedCount = bool("show_unwatched_count", true, R_E)

    /** The watched checkmark on posters and thumbnails. */
    val showWatchedIndicators = bool("show_watched_indicators", true, R_E)
    val showEpisodeNumberOnCards = bool("show_episode_number_on_cards", true, R_E)
    val showSeasonPostersOnTabs = bool("show_season_posters_on_tabs", false, R_E)
    val hideSpoilers = bool("hide_spoilers", false, R_E)
    val showNavBarLabels = bool("show_nav_bar_labels", true, R_E)

    /** Read by nothing; stored only so settings files written with it round-trip. */
    val tvCornerSpotlightBackdrop = bool("tv_corner_spotlight_backdrop", false, R_E)
    val liveTvDefaultFavorites = bool("live_tv_default_favorites", false, E)

    /** Which artwork an episode card shows. */
    val episodePosterMode = setting(
        "episode_poster_mode",
        EpisodePosterMode.EPISODE_THUMBNAIL,
        StoredNameSerializer("com.edde746.plezy.settings.EpisodePosterMode", EpisodePosterMode.entries, ::camelName),
        R_E,
    )
    val continueWatchingAction = setting("continue_watching_action", ContinueWatchingAction.PLAY, ContinueWatchingAction.serializer(), R_E)
    val episodeAction = setting("episode_action", EpisodeAction.PLAY, EpisodeAction.serializer(), R_E)

    /** D-pad navigation of the player's controls; null for the device's default ([videoPlayerNavigationOn]). */
    val videoPlayerNavigationEnabled = AppSetting<Boolean?>("video_player_navigation_enabled", null, Boolean.serializer().nullable, policy = R_E)

    /** Keyboard shortcuts by action id: `{key, modifiers}` or `{disabled: true}`, merged over the defaults where read. */
    val keyboardHotkeys = setting("keyboard_hotkeys", JsonObject(emptyMap()), JsonObject.serializer(), R_E)

    // ---- Playback ----------------------------------------------------------------------------------------------------

    val enableHardwareDecoding = bool("enable_hardware_decoding", true, R_E)
    val enableHdr = bool("enable_hdr", true, R_E)

    /** Linux's native video plane: who tone-maps HDR. */
    val hdrToneMapping = setting("hdr_tone_mapping", HdrToneMapping.COMPOSITOR, HdrToneMapping.serializer(), R_E)
    val seekTimeSmall = int("seek_time_small", 10, R_E)
    val seekTimeLarge = int("seek_time_large", 30, R_E)

    /** Seconds playback goes back when it resumes. */
    val rewindOnResume = int("rewind_on_resume", 0, E)

    /** The sleep timer's minutes. */
    val sleepTimerDuration = int("sleep_timer_duration", 30, R_E)

    /** Milliseconds; the global value of the sync offset scope ([syncOffsetScope]). */
    val audioSyncOffset = int("audio_sync_offset", 0, R_E)
    val subtitleSyncOffset = int("subtitle_sync_offset", 0, R_E)

    /** The language last searched for subtitles in (ISO 639). */
    val subtitleSearchLanguage = nullableString("subtitle_search_language", R_E)

    /** The video player's volume, 0 to 300 (up to [maxVolume]). */
    val volume = double("volume", 100.0, R_E)

    /** The player's rotation lock (phones and tablets). */
    val rotationLocked = bool("rotation_locked", true, E)
    val rememberTrackSelections = bool("remember_track_selections", true, R_E)

    /** The next episode takes the server's audio and subtitle selections instead of carrying the current ones over. */
    val followServerTrackSelections = bool("follow_server_track_selections", false, R_E)
    val showChapterMarkersOnTimeline = bool("show_chapter_markers_on_timeline", true, E)
    val clickVideoTogglesPlayback = bool("click_video_toggles_playback", false, E)

    /** What the player does at an intro; its earlier releases' `auto_skip_intro` toggle migrates ([legacyBoolEnums]). */
    val skipIntroMode = setting("skip_intro_mode", SkipMode.BUTTON, SkipMode.serializer(), E)
    val skipCreditsMode = setting("skip_credits_mode", SkipMode.BUTTON, SkipMode.serializer(), E)
    val forceSkipMarkerFallback = bool("force_skip_marker_fallback", false, E)

    /** Seconds the skip button counts down in [SkipMode.AUTO]. */
    val autoSkipDelay = int("auto_skip_delay", 5, E)

    /** Chapter-title patterns, matched case-insensitively. */
    val introPattern = string("intro_pattern", PlaybackExtras.DEFAULT_INTRO_PATTERN, E)
    val creditsPattern = string("credits_pattern", PlaybackExtras.DEFAULT_CREDITS_PATTERN, E)

    /**
     * The playback info over the video, and its fading out with the controls. The stored names are historical (the
     * performance overlay's, which the playback info took in): kept so settings saved and exported earlier still apply.
     */
    val showPlaybackInfo = bool("show_performance_overlay", false, R_E)
    val autoHidePlaybackInfo = bool("auto_hide_performance_overlay", true, R_E)

    val matchContentFrameRate = bool("match_content_frame_rate", false, R_E)
    val matchContentResolution = bool("match_content_resolution", false, R_E)
    val matchRefreshRate = bool("match_refresh_rate", false, E)
    val matchDynamicRange = bool("match_dynamic_range", false, E)

    /** Seconds playback waits after the display switched modes. */
    val displaySwitchDelay = int("display_switch_delay", 0, E, 0..10)

    val dvConversionMode = setting("dv_conversion_mode", DolbyVisionConversion.AUTO, DolbyVisionConversion.serializer(), R_E)

    /** Dolby Vision files play as the HDR10 or HLG base layer they carry (Android mpv, Apple TV). */
    val disableDolbyVision = bool("disable_dolby_vision", false, R_E)
    val hdrSdrConversion = setting("hdr_sdr_conversion", HdrSdrConversion.AUTO, HdrSdrConversion.serializer(), R_E)
    val defaultQualityPreset = setting("default_quality_preset", TranscodeQualityPreset.ORIGINAL, transcodeQualitySerializer, E)

    /** The quality cap on a cellular-only connection; null follows [defaultQualityPreset]. */
    val cellularQualityPreset = setting("cellular_quality_preset", null, transcodeQualitySerializer.nullable, E)

    /** A source already under the quality cap plays directly instead of transcoding (Plex). */
    val directPlayCoveredQuality = bool("direct_play_covered_quality", true, R_E)

    /** Video codec ids (`av1`, `hevc`) this machine refuses: the server transcodes them (desktop). */
    val refusedVideoCodecs = setting("refused_video_codecs", emptyList(), stringList, R)
    val autoPlayNextEpisode = bool("auto_play_next_episode", true, R_E)

    /** Shuffled queues start every episode from its beginning. */
    val shuffleStartsFromBeginning = bool("shuffle_starts_from_beginning", false, R_E)

    /** Seconds the Play Next prompt counts down; 0 starts the next episode at once. */
    val playNextCountdown = int("play_next_countdown", 5, R_E, 0..30)
    val gestureBrightnessSwipe = bool("gesture_brightness_swipe", true, R_E)
    val gestureVolumeSwipe = bool("gesture_volume_swipe", true, R_E)
    val gesturePinchToZoom = bool("gesture_pinch_to_zoom", true, R_E)
    val rememberBrightnessLevel = bool("remember_brightness_level", false, R_E)

    /** The brightness the swipe gesture last settled on, 0 to 1; -1 while never set. */
    val rememberedBrightnessLevel = double("remembered_brightness_level", -1.0, R)

    /** Its earlier releases' `deinterlace` toggle migrates ([legacyBoolEnums]). */
    val deinterlaceMode = setting("deinterlace_mode", DeinterlaceMode.OFF, DeinterlaceMode.serializer(), R_E)
    val playerAlwaysOnTop = bool("player_always_on_top", false, R_E)
    val specialsOrdering = setting(
        "specials_ordering",
        SpecialsOrdering.RESPECT_SERVER,
        StoredNameSerializer("com.edde746.plezy.settings.SpecialsOrdering", SpecialsOrdering.entries) { it.id },
        R_E,
    )

    /** Plays open in an external player ([useExternalPlayerOn]). */
    val useExternalPlayer = bool("use_external_player", false, R_E)
    val selectedExternalPlayer = setting("selected_external_player", ExternalPlayerChoice.SYSTEM_DEFAULT, ExternalPlayerChoice.serializer(), R)
    val customExternalPlayers = setting("custom_external_players", emptyList(), ListSerializer(ExternalPlayerChoice.serializer()), R)

    /** Picture-in-picture as the app goes to the background; null for the device's default ([autoPipOn]). */
    val autoPip = AppSetting<Boolean?>("auto_pip", null, Boolean.serializer().nullable, policy = R_E)
    val exitFullscreenOnPlayerClose = bool("exit_fullscreen_on_player_close", false, E)
    val ambientLighting = bool("ambient_lighting", false, R_E)

    /** mpv.conf lines applied to mpv; its earlier releases' `mpv_config_entries` migrate ([SettingsMigrations]). */
    val mpvConfigText = string("mpv_config_text", "", R)
    val mpvConfigPresets = setting("mpv_config_presets", emptyList(), ListSerializer(MpvPreset.serializer()), R)

    /** The video shader preset's id, the global value of [shaderPresetScope]. */
    val globalShaderPreset = string("global_shader_preset", ShaderPreset.Off.id, R_E)
    val customShaderPresets = setting("custom_shader_presets", emptyList(), ListSerializer(CustomShader.serializer()), R)

    /** The version picked per title: `{serverId}:{id}` → `{id?, sig?, idx, at?}` (a bare index in earlier releases). */
    val mediaVersionPreferences = setting("media_version_preferences", JsonObject(emptyMap()), JsonObject.serializer(), R)

    /** When items last played on this device: global key → epoch ms. */
    val localLastPlayedAt = setting("local_last_played_at", JsonObject(emptyMap()), JsonObject.serializer(), R)

    // ---- Player options remembered (ScopedPlayerPrefs) ---------------------------------------------------------------

    val defaultPlaybackSpeed = double("default_playback_speed", 1.0, R_E, PLAYBACK_SPEED_RANGE)

    /** The box fit: 0 contain, 1 cover, 2 fill. */
    val defaultBoxFitMode = setting("default_box_fit_mode", VideoFit.CONTAIN, VideoFitIndexSerializer, R_E)
    val defaultVideoZoom = double("default_video_zoom", 1.0, R_E, VIDEO_ZOOM_RANGE)
    val playbackSpeedScope = setting("playback_speed_scope", PlayerSettingScope.GLOBAL, PlayerSettingScope.serializer(), R_E)
    val shaderPresetScope = setting("shader_preset_scope", PlayerSettingScope.GLOBAL, PlayerSettingScope.serializer(), R_E)
    val boxFitScope = setting("box_fit_scope", PlayerSettingScope.GLOBAL, PlayerSettingScope.serializer(), R_E)

    /** Zoom was the session's only before it could be kept, hence [PlayerSettingScope.OFF]. */
    val videoZoomScope = setting("video_zoom_scope", PlayerSettingScope.OFF, PlayerSettingScope.serializer(), R_E)

    /** One scope for both sync offsets. */
    val syncOffsetScope = setting("sync_offset_scope", PlayerSettingScope.GLOBAL, PlayerSettingScope.serializer(), R_E)

    /** Per-library and per-title values: property id → scope key → `{v, t}` ([ScopedPlayerPrefs]). */
    val scopedPlayerPrefValues = setting("scoped_player_pref_values", JsonObject(emptyMap()), JsonObject.serializer(), R_E)

    /** Set once the globals of the keyed scopes were reset after an upgrade ([SettingsMigrations]). */
    val playerScopeGlobalsReset = bool("player_scope_globals_reset", false, SettingPolicy.NONE)

    // ---- Audio -------------------------------------------------------------------------------------------------------

    /** Passthrough; null for the device's default ([audioPassthroughOn]). */
    val audioPassthrough = AppSetting<Boolean?>("audio_passthrough", null, Boolean.serializer().nullable, policy = R_E)
    val audioNormalization = bool("audio_normalization", false, R_E)

    /** Its earlier releases' `audio_downmix` toggle migrates ([legacyBoolEnums]). */
    val audioChannelLimit = setting(
        "audio_channel_limit",
        AudioChannels.ORIGINAL,
        StoredNameSerializer("com.edde746.plezy.settings.AudioChannelLimit", AudioChannels.entries, ::camelName),
        R_E,
    )
    val audioDownmixNormalize = bool("audio_downmix_normalize", true, R_E)

    /** mpv's `audio-device` name; `auto` leaves it to mpv. This machine's. */
    val audioOutputDevice = string("audio_output_device", "auto", R)

    /** The most the volume goes to, in percent. */
    val maxVolume = int("max_volume", 100, R_E, 100..300)
    val downmixCenterBoost = int("downmix_center_boost", 0, R_E, 0..12)
    val musicQualityPreset = setting("music_quality_preset", AudioQualityPreset.ORIGINAL, audioQualitySerializer, E)

    /** The music player's volume, 0 to 100, apart from the video player's. */
    val musicVolume = double("music_volume", 100.0, R_E)

    /** The last music session comes back paused as the app opens. */
    val resumeMusicOnLaunch = bool("resume_music_on_launch", true, R_E)

    // ---- Subtitles ---------------------------------------------------------------------------------------------------

    val subtitleFontSize = int("subtitle_font_size", 38, R_E)
    val subtitleTextColor = string("subtitle_text_color", "#FFFFFF", R_E)
    val subtitleBorderSize = int("subtitle_border_size", 3, R_E)
    val subtitleBorderColor = string("subtitle_border_color", "#000000", R_E)
    val subtitleBackgroundColor = string("subtitle_background_color", "#000000", R_E)
    val subtitleBackgroundOpacity = AppSetting("subtitle_background_opacity", 0, Int.serializer(), SUBTITLE_BACKGROUND_RANGE::clamp, R_E)
    val subAssOverride = setting("sub_ass_override", SubAssOverride.NO, SubAssOverride.serializer(), E)
    val subtitleRenderResolution = setting("subtitle_render_resolution", SubtitleRenderResolution.SCREEN, SubtitleRenderResolution.serializer(), E)
    val subtitleBold = bool("subtitle_bold", false, E)
    val subtitleItalic = bool("subtitle_italic", false, E)

    /** mpv's text subtitles may use space outside the picture. */
    val subtitleUseMargins = bool("subtitle_use_margins", true, R_E)

    /** mpv's `sub-pos`. */
    val subtitlePosition = int("subtitle_position", 100, R_E, 0..150)

    // ---- Downloads ---------------------------------------------------------------------------------------------------

    /** A custom downloads folder (a path, or an Android tree URI); this device's. */
    val customDownloadPath = nullableString("custom_download_path", R)

    /** [customDownloadPath]'s kind: `file` (null) or `saf`. */
    val customDownloadPathType = nullableString("custom_download_path_type", R)
    val downloadOnWifiOnly = bool("download_on_wifi_only", false, R_E)
    val autoRemoveWatchedDownloads = bool("auto_remove_watched_downloads", false, E)

    /** The "background downloads are blocked" dialog was shown. */
    val backgroundDownloadWarningAck = bool("background_download_warning_ack", false, R_E)

    /** The show download dialog's Include Specials toggle. */
    val downloadIncludeSpecials = bool("download_include_specials", true, R_E)

    /** 2 once the stored download paths were normalized. */
    val downloadPathsNormalizedVersion = int("download_paths_normalized_version", 0, SettingPolicy.NONE)

    // ---- Trackers ----------------------------------------------------------------------------------------------------

    val enableTraktWatchedSync = bool("enable_trakt_watched_sync", true, R_E)

    /** Scrobbling to [service]. Device-wide, not per profile. */
    fun scrobble(service: TrackerService): AppSetting<Boolean> = scrobbleSettings.getValue(service)

    /** Whether [trackerFilterIds] lists the libraries [service] skips or the only ones it scrobbles. */
    fun trackerFilterMode(service: TrackerService): AppSetting<TrackerLibraryFilterMode> = filterModeSettings.getValue(service)

    /** Library global keys (`{serverId}:{libraryId}`) of [service]'s filter. */
    fun trackerFilterIds(service: TrackerService): AppSetting<List<String>> = filterIdSettings.getValue(service)

    private val scrobbleSettings = TrackerService.entries.associateWith { bool("enable_${it.id}_scrobble", true, R_E) }
    private val filterModeSettings = TrackerService.entries.associateWith {
        setting("tracker_library_filter_mode_${it.id}", TrackerLibraryFilterMode.BLACKLIST, TrackerLibraryFilterMode.serializer(), R_E)
    }
    private val filterIdSettings = TrackerService.entries.associateWith {
        setting("tracker_library_filter_ids_${it.id}", emptyList(), stringList, R_E)
    }

    /** When the anime mappings were last checked (epoch ms) and their ETag. */
    val animeMappingsEtag = nullableString("anime_mappings_etag", SettingPolicy.NONE)
    val animeMappingsLastCheck = AppSetting<Long?>("anime_mappings_last_check", null, Long.serializer().nullable)

    // ---- Runtime state, identity -------------------------------------------------------------------------------------

    /** The old image cache was deleted once. */
    val cleanedOldImageCache = bool("cleaned_old_image_cache", false, SettingPolicy.NONE)

    /** The last confirmed Supporter entitlement; cleared only on a confirmed revocation. */
    val supporterEntitlementCached = bool("supporter_entitlement_cached", false, SettingPolicy.NONE)

    /** The update the user chose to skip, and when updates were last checked (ISO 8601). */
    val updateSkippedVersion = nullableString("update_skipped_version", SettingPolicy.NONE)
    val updateLastCheckTime = nullableString("update_last_check_time", SettingPolicy.NONE)

    /** This device's identity to servers: Plex's client identifier, Jellyfin's and Emby's device id (a UUID). */
    val clientIdentifier = nullableString("client_identifier", SettingPolicy.NONE)

    /** The active profile's id (`local-…`, `plex-home-{connectionId}-{uuid}`), or null for none. */
    val activeAppProfileId = nullableString("active_app_profile_id", SettingPolicy.NONE)

    /** Set once the single-account data of Plezy's earliest releases moved to profiles. */
    val profileMigrationDone = bool("profile_migration_v1_done", false, SettingPolicy.NONE)

    /** When [profileId] was last activated, epoch ms. */
    fun profileLastUsed(profileId: String): DeviceSetting<Long?> =
        AppSetting(PROFILE_LAST_USED_PREFIX + profileId, null, Long.serializer().nullable)

    /** The Plex Home users of the Plex account [connectionId], as the account last listed them. */
    fun plexHomeUsers(connectionId: String): DeviceSetting<JsonArray?> =
        AppSetting(PLEX_HOME_USERS_PREFIX + connectionId, null, JsonArray.serializer().nullable)

    const val PROFILE_LAST_USED_PREFIX = "profile_last_used_"
    const val PLEX_HOME_USERS_PREFIX = "plex_home_users_"

    // The single-account state of Plezy's earliest releases, read once by the profile migration.

    /** The active Plex Home user's uuid. */
    val currentUserUuid = nullableString("current_user_uuid", SettingPolicy.NONE)

    /** The Plex Home `{id, users: [...]}`, and its old expiry (epoch ms, ignored). */
    val homeUsersCache = AppSetting<JsonElement?>("home_users_cache", null, JsonElement.serializer().nullable)
    val homeUsersCacheExpiry = AppSetting<Long?>("home_users_cache_expiry", null, Long.serializer().nullable)

    /** The Plex servers the account had. */
    val serversList = AppSetting<JsonArray?>("servers_list", null, JsonArray.serializer().nullable)

    /** A server order no release reads any more; only cleared. */
    val serverOrder = AppSetting<JsonElement?>("server_order", null, JsonElement.serializer().nullable)

    // ---- Device-dependent defaults ----------------------------------------------------------------------------------

    /** OLED on a TV, else the system's. */
    fun defaultThemeMode(isTv: Boolean): ThemeMode = if (isTv) ThemeMode.OLED else ThemeMode.SYSTEM

    /** Gaps between cards on a TV, where gapless cards read as one slab across the room; none elsewhere. */
    fun defaultGridSpacing(isTv: Boolean): GridSpacing = if (isTv) GridSpacing.NORMAL else GridSpacing.TIGHT

    /** The stored passthrough choice, else on for a TV (Android TV, Apple TV) and off elsewhere. */
    fun audioPassthroughOn(stored: Boolean?, isTv: Boolean): Boolean = stored ?: isTv

    /** Off where the device has no picture-in-picture (Apple TV, cars), whatever is stored; else on by default but on a Mac. */
    fun autoPipOn(stored: Boolean?, supportsPictureInPicture: Boolean, isMacOs: Boolean): Boolean =
        supportsPictureInPicture && (stored ?: !isMacOs)

    /** Off where external players aren't supported, whatever is stored. */
    fun useExternalPlayerOn(stored: Boolean, supportsExternalPlayers: Boolean): Boolean = supportsExternalPlayers && stored

    /** The stored choice, else on for a TV. */
    fun videoPlayerNavigationOn(stored: Boolean?, isTv: Boolean): Boolean = stored ?: isTv

    /** The stored choice, else on for a TV or a desktop and off for a phone or tablet. */
    fun castingAllowed(stored: Boolean?, formFactor: FormFactor): Boolean = stored ?: (formFactor != FormFactor.HANDHELD)

    /** The stored scale, else 1.35 in a car and 1.0 elsewhere. */
    fun automotiveUiScale(stored: Double?, isAutomotive: Boolean): Double =
        stored ?: if (isAutomotive) AUTOMOTIVE_UI_SCALE_DEFAULT else 1.0

    // ---- Registry ----------------------------------------------------------------------------------------------------

    /**
     * Every global setting a user edits or the app keeps, the trackers' families expanded: what Reset All Settings and
     * the settings file go through ([AppSetting.policy]). Keyed families of runtime state ([profileLastUsed],
     * [plexHomeUsers]) aren't in it.
     */
    val all: List<AppSetting<*>> by lazy {
        listOf(
            enableDebugLogging, crashReporting, startupSection, appLocale, requireProfileSelectionOnOpen, forceTvMode,
            visualEffects, autoCheckUpdatesOnStartup, startInFullscreen, enableDiscordRpc, allowCasting,
            watchPartyRelayUrl, themeMode, customThemePalette, viewMode, libraryDensity,
            gridSpacing, automotiveUiScale, showHeroSection, tvFullCardLayout, focusGlow, useGlobalHubs,
            showServerNameOnHubs, groupLibrariesByServer, showExploreTab, alwaysKeepSidebarOpen,
            showUnwatchedCount, showWatchedIndicators, showEpisodeNumberOnCards,
            showSeasonPostersOnTabs, hideSpoilers, showNavBarLabels, tvCornerSpotlightBackdrop, liveTvDefaultFavorites,
            episodePosterMode, continueWatchingAction, episodeAction, videoPlayerNavigationEnabled, keyboardHotkeys,
            enableHardwareDecoding, enableHdr, hdrToneMapping, seekTimeSmall, seekTimeLarge, rewindOnResume,
            sleepTimerDuration, audioSyncOffset, subtitleSyncOffset, subtitleSearchLanguage, volume, rotationLocked,
            rememberTrackSelections, followServerTrackSelections, showChapterMarkersOnTimeline,
            clickVideoTogglesPlayback, skipIntroMode, skipCreditsMode, forceSkipMarkerFallback, autoSkipDelay,
            introPattern, creditsPattern, showPlaybackInfo, autoHidePlaybackInfo, matchContentFrameRate,
            matchContentResolution, matchRefreshRate, matchDynamicRange, displaySwitchDelay, dvConversionMode,
            disableDolbyVision, hdrSdrConversion,
            defaultQualityPreset, cellularQualityPreset, directPlayCoveredQuality, refusedVideoCodecs,
            autoPlayNextEpisode, shuffleStartsFromBeginning, playNextCountdown, gestureBrightnessSwipe,
            gestureVolumeSwipe, gesturePinchToZoom, rememberBrightnessLevel, rememberedBrightnessLevel, deinterlaceMode,
            playerAlwaysOnTop, specialsOrdering, useExternalPlayer, selectedExternalPlayer, customExternalPlayers,
            autoPip, exitFullscreenOnPlayerClose, ambientLighting, mpvConfigText, mpvConfigPresets, globalShaderPreset,
            customShaderPresets, mediaVersionPreferences, localLastPlayedAt, defaultPlaybackSpeed, defaultBoxFitMode,
            defaultVideoZoom, playbackSpeedScope, shaderPresetScope, boxFitScope, videoZoomScope, syncOffsetScope,
            scopedPlayerPrefValues, playerScopeGlobalsReset, audioPassthrough, audioNormalization, audioChannelLimit,
            audioDownmixNormalize, audioOutputDevice, maxVolume, downmixCenterBoost, musicQualityPreset, musicVolume,
            resumeMusicOnLaunch, subtitleFontSize, subtitleTextColor, subtitleBorderSize, subtitleBorderColor,
            subtitleBackgroundColor, subtitleBackgroundOpacity, subAssOverride, subtitleRenderResolution, subtitleBold,
            subtitleItalic, subtitleUseMargins, subtitlePosition, customDownloadPath,
            customDownloadPathType, downloadOnWifiOnly, autoRemoveWatchedDownloads, backgroundDownloadWarningAck,
            downloadIncludeSpecials, downloadPathsNormalizedVersion, enableTraktWatchedSync, animeMappingsEtag,
            animeMappingsLastCheck, cleanedOldImageCache, supporterEntitlementCached, updateSkippedVersion,
            updateLastCheckTime, clientIdentifier, activeAppProfileId, profileMigrationDone, currentUserUuid,
            homeUsersCache, homeUsersCacheExpiry, serversList, serverOrder,
        ) + TrackerService.entries.flatMap { listOf(scrobble(it), trackerFilterMode(it), trackerFilterIds(it)) }
    }


    /**
     * The enum settings that replaced a toggle of Plezy's earlier releases: [LegacyBoolEnum.legacyKey]'s `true` and
     * `false` become [LegacyBoolEnum.whenTrue] and [LegacyBoolEnum.whenFalse] (stored names). A stored enum value
     * always wins over a leftover toggle.
     */
    val legacyBoolEnums: List<LegacyBoolEnum> by lazy {
        listOf(
            LegacyBoolEnum("auto_skip_intro", skipIntroMode, whenTrue = "auto", whenFalse = "button"),
            LegacyBoolEnum("auto_skip_credits", skipCreditsMode, whenTrue = "auto", whenFalse = "button"),
            LegacyBoolEnum("audio_downmix", audioChannelLimit, whenTrue = "stereo", whenFalse = "original"),
            LegacyBoolEnum("deinterlace", deinterlaceMode, whenTrue = "video", whenFalse = "off"),
        )
    }

    // ---- Validation --------------------------------------------------------------------------------------------------

    /** The range the settings screens offer for a number setting, or null for one without. */
    fun numericBounds(setting: DeviceSetting<*>): ClosedFloatingPointRange<Double>? = when (setting.key) {
        "seek_time_small", "seek_time_large" -> 1.0..120.0
        "rewind_on_resume", "display_switch_delay" -> 0.0..10.0
        "sleep_timer_duration" -> 5.0..240.0
        "play_next_countdown" -> 0.0..30.0
        "auto_skip_delay" -> 1.0..30.0
        "subtitle_font_size" -> 10.0..80.0
        "subtitle_border_size" -> 0.0..5.0
        "subtitle_position" -> 0.0..150.0
        "subtitle_background_opacity", "music_volume" -> 0.0..100.0
        "volume" -> 0.0..300.0
        "max_volume" -> 100.0..300.0
        "downmix_center_boost" -> 0.0..12.0
        "default_playback_speed" -> PLAYBACK_SPEED_RANGE
        "default_box_fit_mode" -> 0.0..2.0
        "default_video_zoom" -> VIDEO_ZOOM_RANGE
        "library_density" -> LIBRARY_DENSITY_RANGE.first.toDouble()..LIBRARY_DENSITY_RANGE.last.toDouble()
        "automotive_ui_scale" -> AUTOMOTIVE_UI_SCALE_RANGE
        "remembered_brightness_level" -> -1.0..1.0
        else -> null
    }

    /** Whether [value] is a usable chapter-title pattern: not blank, and a valid case-insensitive regular expression. */
    fun isValidSkipPattern(value: String): Boolean {
        if (value.isBlank()) return false
        return try {
            Regex(value, RegexOption.IGNORE_CASE)
            true
        } catch (_: IllegalArgumentException) {
            false
        }
    }

    /**
     * Throws IllegalArgumentException when [value] (the setting's typed value) is one the settings screens would
     * reject: a number outside [numericBounds], a blank or invalid skip pattern, a subtitle search language without an
     * ISO 639-1 code, a brightness below 0 but -1, a subtitle colour not `#RRGGBB`, a string list with blank or
     * repeated entries, keyboard shortcuts that aren't well formed or put two actions on one shortcut ([Hotkeys.validate]).
     */
    fun validate(setting: DeviceSetting<*>, value: Any?) {
        if (value is Number) {
            val number = value.toDouble()
            val bounds = numericBounds(setting)
            require(number.isFinite() && (bounds == null || number in bounds)) { "${setting.key}: $value is outside the supported range" }
            require(setting !== rememberedBrightnessLevel || number >= 0 || number == -1.0) {
                "${setting.key}: brightness is -1 (unset) or in 0..1"
            }
        }
        if (setting === introPattern || setting === creditsPattern) {
            require(value is String && isValidSkipPattern(value)) { "${setting.key}: expected a nonempty valid regular expression" }
        }
        if (setting === subtitleSearchLanguage && value != null) {
            val primary = (value as? String)?.let(LanguageTags::canonical)?.let(LanguageTags::primary)
            require(primary != null && primary.length == 2) { "${setting.key}: expected an ISO 639 language code" }
        }
        if (setting === subtitleTextColor || setting === subtitleBorderColor || setting === subtitleBackgroundColor) {
            require(value is String && SUBTITLE_COLOR.matches(value)) { "${setting.key}: expected a six-digit hex colour" }
        }
        if (value is List<*> && value.all { it is String }) {
            val strings = value.map { it as String }
            require(strings.none(String::isBlank) && strings.toSet().size == strings.size) {
                "${setting.key}: expected unique nonempty identifiers"
            }
        }
        if (setting === keyboardHotkeys) Hotkeys.validate(value as JsonObject)
    }

    private val SUBTITLE_COLOR = Regex("^#[0-9a-fA-F]{6}$")
}

/**
 * An enum setting ([setting]) that replaced the toggle stored as [legacyKey]: `true` is the value named [whenTrue],
 * `false` the one named [whenFalse].
 */
class LegacyBoolEnum(val legacyKey: String, val setting: DeviceSetting<*>, val whenTrue: String, val whenFalse: String)

/** Whether [id] names one of the app's own shader presets (`none` among them), not an imported one. */
fun isBuiltInShaderPreset(id: String): Boolean = ShaderPreset.builtIn.any { it.id == id }

/**
 * Whether [service] scrobbles what plays from the library [libraryGlobalKey]: all but the listed libraries
 * ([TrackerLibraryFilterMode.BLACKLIST]) or only them. An unknown library (null) scrobbles only while nothing is
 * listed to skip.
 */
fun isLibraryAllowedForTracker(mode: TrackerLibraryFilterMode, ids: List<String>, libraryGlobalKey: String?): Boolean {
    if (libraryGlobalKey == null) return mode == TrackerLibraryFilterMode.BLACKLIST && ids.isEmpty()
    val listed = libraryGlobalKey in ids
    return if (mode == TrackerLibraryFilterMode.BLACKLIST) !listed else listed
}

/** [isLibraryAllowedForTracker] with [service]'s stored filter. */
suspend fun DeviceSettingsRepository.isLibraryAllowedForTracker(service: TrackerService, libraryGlobalKey: String?): Boolean =
    isLibraryAllowedForTracker(value(AppSettings.trackerFilterMode(service)), value(AppSettings.trackerFilterIds(service)), libraryGlobalKey)

private val transcodeQualitySerializer =
    StoredNameSerializer("com.edde746.plezy.settings.TranscodeQualityPreset", TranscodeQualityPreset.entries) { it.name.lowercase() }

private val audioQualitySerializer =
    StoredNameSerializer("com.edde746.plezy.settings.AudioQualityPreset", AudioQualityPreset.entries) { it.name.lowercase() }
