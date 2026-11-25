package com.edde746.plezy.app

import com.edde746.plezy.backend.TranscodeQualityPreset
import com.edde746.plezy.data.settings.DeviceSetting
import com.edde746.plezy.data.settings.DeviceSettingsRepository
import com.edde746.plezy.data.settings.DolbyVisionConversion
import com.edde746.plezy.data.settings.SettingRange
import com.edde746.plezy.data.settings.SkipMode
import com.edde746.plezy.settings.DeinterlaceMode
import com.edde746.plezy.settings.SubAssOverride
import com.edde746.plezy.settings.SubtitleRenderResolution
import com.edde746.plezy.model.EpisodePosterMode
import com.edde746.plezy.playback.AudioChannels
import com.edde746.plezy.playback.ShaderPreset
import com.edde746.plezy.playback.VideoFit
import com.edde746.plezy.playback.players.KnownPlayers
import com.edde746.plezy.settings.AppLocale
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.settings.CustomPlayerType
import com.edde746.plezy.settings.ExternalPlayerChoice
import com.edde746.plezy.settings.GridSpacing
import com.edde746.plezy.settings.StartupSection
import com.edde746.plezy.settings.ThemeMode
import com.edde746.plezy.settings.ContinueWatchingAction
import com.edde746.plezy.settings.EpisodeAction
import com.edde746.plezy.settings.ViewMode
import com.edde746.plezy.settings.VisualEffects
import com.edde746.plezy.watch.WatchPartyRelays
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlin.coroutines.cancellation.CancellationException
import kotlin.time.Duration.Companion.seconds

/**
 * A device setting a development session starts with (`--dev-setting`, [DevLaunch]), as given on the command line:
 * [parse] reads `<key>=<value>` by [DeviceSetting.key]. The switches
 * (`enable_hardware_decoding`, `enable_hdr`, `match_content_frame_rate`, `audio_passthrough`, `audio_normalization`,
 * `enable_discord_rpc`, `crash_reporting`, `ambient_lighting`, `require_profile_selection_on_open`,
 * the playback info's `show_performance_overlay` and `auto_hide_performance_overlay`, `start_in_fullscreen`,
 * `force_skip_marker_fallback`) take
 * `true` or `false`, the read-ahead cache (`playback.cacheSizeMegabytes`) a size in MB within its range, or `auto`, the
 * player's fit (`default_box_fit_mode`), audio channels (`audio_channel_limit`), Dolby Vision conversion
 * (`dv_conversion_mode`) and the default quality (`default_quality_preset`) a value by name (`default_box_fit_mode=cover`,
 * `audio_channel_limit=stereo`, `dv_conversion_mode=hevc_strip`, `default_quality_preset=p720_4mbps`), the subtitle style
 * (`subtitle_*`, `sub_ass_override`) a value of the setting: a
 * whole number within its range, `true` or `false`, a colour as `#RRGGBB` or a choice by name
 * (`subtitle_text_color=#FFFF00`, `sub_ass_override=force`), Deinterlacing (`deinterlace_mode=film`), the skip modes
 * (`skip_intro_mode`, `skip_credits_mode`) `off`, `button` or `auto`, the Small Skip Duration (`seek_time_small`)
 * seconds from 1 to 120, the
 * watch-together relay (`watch_party_relay_url`) a relay's
 * `http(s)` URL, stored canonical, or `public` (or nothing) for
 * Open Watch Party's public relays, and the external player (`selected_external_player`) a known player's id
 * (`selected_external_player=vlc`), and the interface language (`app_locale`) a language's stored name
 * (`app_locale=de`, `app_locale=zhHant`). `custom_external_players=<name>;<command|urlScheme>;<value>` makes the custom
 * players this one alone, with the id `dev`, and selects it (`custom_external_players=Handoff;urlScheme;myplayer://?u=`);
 * its value is taken whole, `@` included. `use_external_player=true` plays in the external player. `offline=true`
 * holds the device offline whatever the platform reports ([Offline]: the network reported gone and the servers
 * unreachable, on desktop and simulators too; `offline=false` brings them back). `player.fastTimers=true` makes the
 * sleep timer's minutes 6 s
 * each in the players opened from then on ([FastTimers]: a UI test's 5 minutes run out in 30 s). `@<seconds>` after
 * the value (`subtitle_font_size=60@60`) stores it that long after the session starts instead ([Later]: a change
 * while a video plays). [applyDevSettings] stores them.
 */
sealed interface DevSetting {
    /** The setting's [DeviceSetting.key] and the value as given, for logs and test reports. */
    val key: String
    val value: String

    data class Switch(val setting: DeviceSetting<Boolean>, val on: Boolean) : DevSetting {
        override val key: String get() = setting.key
        override val value: String get() = on.toString()
    }

    /** [megabytes] null is Automatic. */
    data class CacheSize(val megabytes: Int?) : DevSetting {
        override val key: String get() = DeviceSetting.CacheSizeMegabytes.key
        override val value: String get() = megabytes?.toString() ?: AUTOMATIC_CACHE
    }

    /**
     * A subtitle style setting (`subtitle_*`), a player choice (`default_box_fit_mode`, `audio_channel_limit`), the
     * watch-together relay (`watch_party_relay_url`) or the external player (`selected_external_player`), [stored] as
     * [value] gives it.
     */
    data class Value<T>(val setting: DeviceSetting<T>, val stored: T, override val value: String) : DevSetting {
        override val key: String get() = setting.key

        internal suspend fun storeIn(settings: DeviceSettingsRepository) = settings.set(setting, stored)
    }

    /**
     * The device held offline ([on]): the network reported offline whatever the platform reports ([AppGraph.network])
     * and every request of the session's HTTP client failing as without a network ([httpClient]); or released to the
     * platform's report and the network. Not stored.
     */
    data class Offline(val on: Boolean) : DevSetting {
        override val key: String get() = OFFLINE_KEY
        override val value: String get() = on.toString()
    }

    /**
     * The player's timers fast ([on]) or as in the product: while on, the sleep timer's minutes are a tenth as long in
     * the players opened from then on ([AppGraph.fastPlayerTimers]); "Still watching?"'s countdown and the other timers
     * (up next's) stay as they are. Not stored.
     */
    data class FastTimers(val on: Boolean) : DevSetting {
        override val key: String get() = FAST_TIMERS_KEY
        override val value: String get() = on.toString()
    }

    /** `custom_external_players`: the custom players are [player] alone (its id `dev`), and it is the one selected. */
    data class CustomPlayers(val player: ExternalPlayerChoice) : DevSetting {
        override val key: String get() = CUSTOM_PLAYER_KEY
        override val value: String get() = listOf(player.name, if (player.customType == CustomPlayerType.URL_SCHEME) URL_SCHEME else COMMAND, player.customValue).joinToString(";")
    }

    /**
     * `cast.demo=receiver|sender|receiver,sender`: the stand-ins for a second device ([DevCastDemo]). [receiver]: "Demo
     * TV" in the picker; [sender]: "Demo Phone" casting here, with casting to this device allowed.
     */
    data class CastDemo(val receiver: Boolean, val sender: Boolean) : DevSetting {
        override val key: String get() = CAST_DEMO_KEY
        override val value: String get() = listOfNotNull(RECEIVER.takeIf { receiver }, SENDER.takeIf { sender }).joinToString(",")

        companion object {
            const val RECEIVER = "receiver"
            const val SENDER = "sender"
        }
    }

    /** [setting], stored [seconds] after the session starts rather than before it. */
    data class Later(val setting: DevSetting, val seconds: Double) : DevSetting {
        override val key: String get() = setting.key
        override val value: String get() = "${setting.value}@$seconds"
    }

    companion object {
        /** @throws IllegalArgumentException for an unknown key or a value the setting doesn't take, with the message to show. */
        @Throws(IllegalArgumentException::class)
        fun parse(spec: String): DevSetting {
            // A custom player's command may hold an `@` of its own: never a later setting.
            if ('@' in spec && !spec.startsWith("$CUSTOM_PLAYER_KEY=")) {
                val seconds = spec.substringAfterLast('@').toDoubleOrNull()?.takeIf { it.isFinite() && it >= 0 }
                    ?: throw IllegalArgumentException("needs <key>=<value>@<seconds after the start>, got '$spec'")
                return Later(parseNow(spec.substringBeforeLast('@')), seconds)
            }
            return parseNow(spec)
        }

        private fun parseNow(spec: String): DevSetting {
            val key = spec.substringBefore('=')
            val value = spec.substringAfter('=', missingDelimiterValue = "")
            DEV_SWITCHES.firstOrNull { it.key == key }?.let { setting ->
                val on = value.toBooleanStrictOrNull() ?: throw IllegalArgumentException("$key takes true or false, got '$spec'")
                return Switch(setting, on)
            }
            if (key == OFFLINE_KEY) {
                val on = value.toBooleanStrictOrNull() ?: throw IllegalArgumentException("$key takes true or false, got '$spec'")
                return Offline(on)
            }
            if (key == FAST_TIMERS_KEY) {
                val on = value.toBooleanStrictOrNull() ?: throw IllegalArgumentException("$key takes true or false, got '$spec'")
                return FastTimers(on)
            }
            if (key == CAST_DEMO_KEY) {
                val roles = value.split(',').map { it.trim() }.toSet()
                require(roles.isNotEmpty() && roles.all { it == CastDemo.RECEIVER || it == CastDemo.SENDER }) {
                    "$key takes receiver, sender or receiver,sender, got '$spec'"
                }
                return CastDemo(CastDemo.RECEIVER in roles, CastDemo.SENDER in roles)
            }
            if (key == CUSTOM_PLAYER_KEY) {
                val parts = value.split(';', limit = 3)
                val name = parts[0].trim()
                val type = when (parts.getOrNull(1)?.trim()) {
                    COMMAND -> CustomPlayerType.COMMAND
                    URL_SCHEME -> CustomPlayerType.URL_SCHEME
                    else -> null
                }
                val command = parts.getOrNull(2)?.trim().orEmpty()
                require(name.isNotEmpty() && type != null && command.isNotEmpty()) { "$key takes <name>;<$COMMAND|$URL_SCHEME>;<value>, got '$spec'" }
                return CustomPlayers(ExternalPlayerChoice(DEV_CUSTOM_PLAYER_ID, name, isCustom = true, customValue = command, customType = type))
            }
            if (key == DeviceSetting.CacheSizeMegabytes.key) {
                if (value == AUTOMATIC_CACHE) return CacheSize(null)
                val range = DeviceSetting.CacheSizeMegabytes.range
                val megabytes = value.toIntOrNull()?.takeIf { it in range }
                    ?: throw IllegalArgumentException("$key takes $AUTOMATIC_CACHE or a size in MB from ${range.min} to ${range.max}, got '$spec'")
                return CacheSize(megabytes)
            }
            valueSetting(key, value, spec)?.let { return it }
            appearanceSetting(key, value, spec)?.let { return it }
            val keys = (
                DEV_SWITCHES.map { it.key } + DeviceSetting.CacheSizeMegabytes.key + DEV_VALUE_KEYS + CUSTOM_PLAYER_KEY + OFFLINE_KEY +
                    FAST_TIMERS_KEY + CAST_DEMO_KEY + APPEARANCE_KEYS
                ).joinToString()
            throw IllegalArgumentException("needs <key>=<value> with a key of $keys, got '$spec'")
        }
    }
}

private const val AUTOMATIC_CACHE = "auto"

/** [DevSetting.Offline]'s key. */
private const val OFFLINE_KEY = "offline"

/** [DevSetting.FastTimers]' key. */
private const val FAST_TIMERS_KEY = "player.fastTimers"

/** [DevSetting.CastDemo]'s key. */
private const val CAST_DEMO_KEY = "cast.demo"

/** [DevSetting.CustomPlayers]' key. */
private const val CUSTOM_PLAYER_KEY = "custom_external_players"

/** The id of [DevSetting.CustomPlayers]' player. */
private const val DEV_CUSTOM_PLAYER_ID = "dev"

/** [DevSetting.CustomPlayers]' types, as stored. */
private const val COMMAND = "command"
private const val URL_SCHEME = "urlScheme"

private val DEV_SWITCHES: List<DeviceSetting<Boolean>> = listOf(
    AppSettings.enableHardwareDecoding,
    AppSettings.enableHdr,
    AppSettings.matchContentFrameRate,
    AppSettings.audioNormalization,
    AppSettings.gestureBrightnessSwipe,
    AppSettings.gestureVolumeSwipe,
    AppSettings.gesturePinchToZoom,
    AppSettings.enableDiscordRpc,
    AppSettings.crashReporting,
    AppSettings.showPlaybackInfo,
    AppSettings.autoHidePlaybackInfo,
    AppSettings.ambientLighting,
    AppSettings.useExternalPlayer,
    AppSettings.startInFullscreen,
    AppSettings.requireProfileSelectionOnOpen,
    AppSettings.forceSkipMarkerFallback,
)

private val DEV_VALUE_KEYS: List<String> = listOf(
    AppSettings.defaultBoxFitMode, AppSettings.audioChannelLimit, AppSettings.audioPassthrough,
    AppSettings.subtitleFontSize, AppSettings.subtitleTextColor, AppSettings.subtitleBorderSize, AppSettings.subtitleBorderColor,
    AppSettings.subtitleBackgroundColor, AppSettings.subtitleBackgroundOpacity, AppSettings.subtitleBold, AppSettings.subtitleItalic,
    AppSettings.subAssOverride, AppSettings.subtitlePosition, AppSettings.subtitleUseMargins, AppSettings.deinterlaceMode,
    AppSettings.watchPartyRelayUrl, AppSettings.selectedExternalPlayer, AppSettings.globalShaderPreset,
    AppSettings.dvConversionMode, AppSettings.appLocale,
    AppSettings.enableDebugLogging, AppSettings.maxVolume, AppSettings.subtitleRenderResolution, AppSettings.mpvConfigText,
    AppSettings.skipIntroMode, AppSettings.skipCreditsMode, AppSettings.seekTimeSmall,
).map { it.key }

/** `watch_party_relay_url`'s value for Open Watch Party's public relays (stored as no override). */
private const val PUBLIC_RELAYS = "public"

/**
 * [key] as a player choice, the video output, a subtitle style setting, the relay or the player ([DevSetting.Value]), or
 * null when it is none.
 */
private fun valueSetting(key: String, value: String, spec: String): DevSetting? {
    fun number(setting: DeviceSetting<Int>, range: SettingRange) = DevSetting.Value(
        setting,
        value.toIntOrNull()?.takeIf { it in range } ?: throw IllegalArgumentException("$key takes a whole number from ${range.min} to ${range.max}, got '$spec'"),
        value,
    )
    fun <E : Enum<E>> named(setting: DeviceSetting<E>, entries: List<E>) = DevSetting.Value(
        setting,
        entries.firstOrNull { it.name.equals(value, ignoreCase = true) }
            ?: throw IllegalArgumentException("$key takes one of ${entries.joinToString { it.name.lowercase() }}, got '$spec'"),
        value,
    )
    fun switch(setting: DeviceSetting<Boolean>) = DevSetting.Value(
        setting,
        value.toBooleanStrictOrNull() ?: throw IllegalArgumentException("$key takes true or false, got '$spec'"),
        value,
    )
    fun color(setting: DeviceSetting<String>) = DevSetting.Value(
        setting,
        value.takeIf { Regex("^#[0-9a-fA-F]{6}$").matches(it) } ?: throw IllegalArgumentException("$key takes a colour as #RRGGBB, got '$spec'"),
        value,
    )
    return when (key) {
        AppSettings.defaultBoxFitMode.key -> named(AppSettings.defaultBoxFitMode, VideoFit.entries)
        AppSettings.audioChannelLimit.key -> named(AppSettings.audioChannelLimit, AudioChannels.entries)
        AppSettings.dvConversionMode.key -> named(AppSettings.dvConversionMode, DolbyVisionConversion.entries)
        AppSettings.defaultQualityPreset.key -> named(AppSettings.defaultQualityPreset, TranscodeQualityPreset.entries)
        AppSettings.subtitleFontSize.key -> number(AppSettings.subtitleFontSize, SettingRange(10, 80))
        AppSettings.subtitleBorderSize.key -> number(AppSettings.subtitleBorderSize, SettingRange(0, 5))
        AppSettings.subtitlePosition.key -> number(AppSettings.subtitlePosition, SettingRange(0, 150))
        AppSettings.subtitleTextColor.key -> color(AppSettings.subtitleTextColor)
        AppSettings.subtitleBorderColor.key -> color(AppSettings.subtitleBorderColor)
        AppSettings.subtitleBackgroundColor.key -> color(AppSettings.subtitleBackgroundColor)
        AppSettings.subtitleBackgroundOpacity.key -> number(AppSettings.subtitleBackgroundOpacity, AppSettings.SUBTITLE_BACKGROUND_RANGE)
        AppSettings.subtitleBold.key -> switch(AppSettings.subtitleBold)
        AppSettings.subtitleItalic.key -> switch(AppSettings.subtitleItalic)
        AppSettings.subtitleUseMargins.key -> switch(AppSettings.subtitleUseMargins)
        AppSettings.subAssOverride.key -> named(AppSettings.subAssOverride, SubAssOverride.entries)
        AppSettings.deinterlaceMode.key -> named(AppSettings.deinterlaceMode, DeinterlaceMode.entries)
        AppSettings.enableDebugLogging.key -> switch(AppSettings.enableDebugLogging)
        AppSettings.maxVolume.key -> number(AppSettings.maxVolume, SettingRange(100, 300))
        AppSettings.seekTimeSmall.key -> number(AppSettings.seekTimeSmall, SettingRange(1, 120))
        AppSettings.subtitleRenderResolution.key -> named(AppSettings.subtitleRenderResolution, SubtitleRenderResolution.entries)
        // The user's mpv.conf as given.
        AppSettings.mpvConfigText.key -> DevSetting.Value(AppSettings.mpvConfigText, value, value)
        AppSettings.skipIntroMode.key -> named(AppSettings.skipIntroMode, SkipMode.entries)
        AppSettings.skipCreditsMode.key -> named(AppSettings.skipCreditsMode, SkipMode.entries)
        // Unset is the form factor's default (`DeviceSettings.audioPassthroughOn`); a run sets it either way.
        AppSettings.audioPassthrough.key -> DevSetting.Value<Boolean?>(
            AppSettings.audioPassthrough,
            value.toBooleanStrictOrNull() ?: throw IllegalArgumentException("$key takes true or false, got '$spec'"),
            value,
        )
        AppSettings.watchPartyRelayUrl.key -> DevSetting.Value(
            AppSettings.watchPartyRelayUrl,
            if (value.isEmpty() || value == PUBLIC_RELAYS) {
                null
            } else {
                WatchPartyRelays.canonicalBaseUrl(value) ?: throw IllegalArgumentException("$key takes a relay's http(s) URL or $PUBLIC_RELAYS, got '$spec'")
            },
            value,
        )
        // A known player by id, offered on this platform or not, as after a settings import.
        AppSettings.selectedExternalPlayer.key -> DevSetting.Value(
            AppSettings.selectedExternalPlayer,
            KnownPlayers.findById(value)?.choice
                ?: throw IllegalArgumentException("$key takes one of ${KnownPlayers.all.joinToString { it.id }}, got '$spec'"),
            value,
        )
        // A built-in preset: a run measures what each costs on its device.
        AppSettings.globalShaderPreset.key -> DevSetting.Value(
            AppSettings.globalShaderPreset,
            ShaderPreset.builtIn.firstOrNull { it.id == value }?.id
                ?: throw IllegalArgumentException("$key takes one of ${ShaderPreset.builtIn.joinToString { it.id }}, got '$spec'"),
            value,
        )
        // A language by its stored name (`de`, `zhHant`): `app_locale=de@5` switches the running app's language.
        AppSettings.appLocale.key -> DevSetting.Value(
            AppSettings.appLocale,
            AppLocale.entries.firstOrNull { it.storedName == value }?.storedName
                ?: throw IllegalArgumentException("$key takes one of ${AppLocale.entries.joinToString { it.storedName }}, got '$spec'"),
            value,
        )
        else -> null
    }
}

/**
 * Stores [settings] as this device's settings: a development session's database is its own. A [DevSetting.Later] is
 * stored that long after this call, while the session runs.
 */
@Throws(CancellationException::class)
suspend fun AppGraph.applyDevSettings(settings: List<DevSetting>) {
    for (setting in settings) {
        if (setting is DevSetting.Later) {
            scope.launch {
                delay(setting.seconds.seconds)
                storeDevSetting(setting.setting)
            }
        } else {
            storeDevSetting(setting)
        }
    }
}

private suspend fun AppGraph.storeDevSetting(setting: DevSetting) {
    when (setting) {
        is DevSetting.Switch -> data.deviceSettings.set(setting.setting, setting.on)
        is DevSetting.CacheSize -> if (setting.megabytes == null) {
            data.deviceSettings.reset(DeviceSetting.CacheSizeMegabytes)
        } else {
            data.deviceSettings.set(DeviceSetting.CacheSizeMegabytes, setting.megabytes)
        }
        is DevSetting.Value<*> -> setting.storeIn(data.deviceSettings)
        is DevSetting.Later -> storeDevSetting(setting.setting)
        // A request held offline finds the network reported offline (the dev sign-in lets such a failure go).
        is DevSetting.Offline -> if (setting.on) {
            holdOffline(true)
            http.holdDevOffline(true)
        } else {
            http.holdDevOffline(false)
            holdOffline(false)
        }
        is DevSetting.FastTimers -> fastPlayerTimers = setting.on
        // The stand-in sender casts here: this device receives whatever its form factor's default.
        is DevSetting.CastDemo -> if (setting.sender) data.deviceSettings.set(AppSettings.allowCasting, true)
        is DevSetting.CustomPlayers -> {
            data.deviceSettings.set(AppSettings.customExternalPlayers, listOf(setting.player))
            data.deviceSettings.set(AppSettings.selectedExternalPlayer, setting.player)
        }
    }
}

/** The appearance and browsing settings a session can start with ([appearanceSetting]), by the stored key. */
private val APPEARANCE_KEYS: List<String> = listOf(
    AppSettings.themeMode, AppSettings.forceTvMode, AppSettings.showNavBarLabels, AppSettings.alwaysKeepSidebarOpen,
    AppSettings.showExploreTab, AppSettings.startupSection, AppSettings.gridSpacing, AppSettings.libraryDensity, AppSettings.viewMode,
    AppSettings.episodePosterMode, AppSettings.tvFullCardLayout, AppSettings.focusGlow,
    AppSettings.showHeroSection, AppSettings.showSeasonPostersOnTabs, AppSettings.showWatchedIndicators, AppSettings.hideSpoilers,
    AppSettings.continueWatchingAction, AppSettings.episodeAction, AppSettings.visualEffects,
).map { it.key }

/**
 * [key] as an appearance or browsing setting by its stored key ([DevSetting.Value]: `theme_mode=ember`,
 * `force_tv_mode=true`, `grid_spacing=spacious`, `library_density=5`, `episode_poster_mode=seriesPoster`), or null
 * when it is none. Enum values go by their stored name (`liveTv`, `seriesPoster`), case and `_` aside.
 */
private fun appearanceSetting(key: String, value: String, spec: String): DevSetting? {
    fun flag(setting: DeviceSetting<Boolean>) =
        DevSetting.Value(setting, value.toBooleanStrictOrNull() ?: throw IllegalArgumentException("$key takes true or false, got '$spec'"), value)

    fun <E : Enum<E>> named(entries: List<E>): E = entries.firstOrNull { it.name.replace("_", "").equals(value.replace("_", ""), ignoreCase = true) }
        ?: throw IllegalArgumentException("$key takes one of ${entries.joinToString { it.name.lowercase() }}, got '$spec'")

    return when (key) {
        AppSettings.themeMode.key -> DevSetting.Value(AppSettings.themeMode, named(ThemeMode.entries), value)
        AppSettings.forceTvMode.key -> flag(AppSettings.forceTvMode)
        AppSettings.showNavBarLabels.key -> flag(AppSettings.showNavBarLabels)
        AppSettings.alwaysKeepSidebarOpen.key -> flag(AppSettings.alwaysKeepSidebarOpen)
        AppSettings.showExploreTab.key -> flag(AppSettings.showExploreTab)
        AppSettings.startupSection.key -> DevSetting.Value(AppSettings.startupSection, named(StartupSection.entries), value)
        AppSettings.gridSpacing.key -> DevSetting.Value(AppSettings.gridSpacing, named(GridSpacing.entries), value)
        AppSettings.libraryDensity.key -> DevSetting.Value(
            AppSettings.libraryDensity,
            value.toIntOrNull()?.takeIf { it in 1..5 } ?: throw IllegalArgumentException("$key takes 1 to 5, got '$spec'"),
            value,
        )
        AppSettings.viewMode.key -> DevSetting.Value(AppSettings.viewMode, named(ViewMode.entries), value)
        AppSettings.episodePosterMode.key -> DevSetting.Value(AppSettings.episodePosterMode, named(EpisodePosterMode.entries), value)
        AppSettings.tvFullCardLayout.key -> flag(AppSettings.tvFullCardLayout)
        AppSettings.focusGlow.key -> flag(AppSettings.focusGlow)
        AppSettings.showHeroSection.key -> flag(AppSettings.showHeroSection)
        AppSettings.showSeasonPostersOnTabs.key -> flag(AppSettings.showSeasonPostersOnTabs)
        AppSettings.showWatchedIndicators.key -> flag(AppSettings.showWatchedIndicators)
        AppSettings.hideSpoilers.key -> flag(AppSettings.hideSpoilers)
        AppSettings.continueWatchingAction.key -> DevSetting.Value(AppSettings.continueWatchingAction, named(ContinueWatchingAction.entries), value)
        AppSettings.episodeAction.key -> DevSetting.Value(AppSettings.episodeAction, named(EpisodeAction.entries), value)
        AppSettings.visualEffects.key -> DevSetting.Value(AppSettings.visualEffects, named(VisualEffects.entries), value)
        else -> null
    }
}
