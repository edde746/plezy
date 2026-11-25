package com.edde746.plezy.app

import com.edde746.plezy.data.settings.DeviceSetting
import com.edde746.plezy.data.settings.DolbyVisionConversion
import com.edde746.plezy.data.settings.SkipMode
import com.edde746.plezy.model.EpisodePosterMode
import com.edde746.plezy.playback.AudioChannels
import com.edde746.plezy.playback.VideoFit
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.settings.CustomPlayerType
import com.edde746.plezy.settings.DeinterlaceMode
import com.edde746.plezy.settings.ExternalPlayerChoice
import com.edde746.plezy.settings.GridSpacing
import com.edde746.plezy.settings.SubAssOverride
import com.edde746.plezy.settings.StartupSection
import com.edde746.plezy.settings.ThemeMode
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith

class DevSettingTest {
    @Test
    fun `the cast demo takes the receiver the sender or both`() {
        assertEquals(DevSetting.CastDemo(receiver = true, sender = false), DevSetting.parse("cast.demo=receiver"))
        assertEquals(DevSetting.CastDemo(receiver = false, sender = true), DevSetting.parse("cast.demo=sender"))
        assertEquals(DevSetting.CastDemo(receiver = true, sender = true), DevSetting.parse("cast.demo=receiver,sender"))
        assertFailsWith<IllegalArgumentException> { DevSetting.parse("cast.demo=phone") }
    }

    @Test
    fun switchesTakeTrueOrFalseAndTheCacheASizeInItsRangeOrAuto() {
        assertEquals(DevSetting.Switch(AppSettings.enableHardwareDecoding, false), DevSetting.parse("enable_hardware_decoding=false"))
        assertEquals(DevSetting.Switch(AppSettings.matchContentFrameRate, true), DevSetting.parse("match_content_frame_rate=true"))
        assertEquals(DevSetting.Switch(AppSettings.audioNormalization, true), DevSetting.parse("audio_normalization=true"))
        assertEquals(DevSetting.Switch(AppSettings.enableDiscordRpc, true), DevSetting.parse("enable_discord_rpc=true"))
        assertEquals(DevSetting.CacheSize(512), DevSetting.parse("playback.cacheSizeMegabytes=512"))
        assertEquals(DevSetting.CacheSize(16), DevSetting.parse("playback.cacheSizeMegabytes=16"))
        assertEquals(DevSetting.CacheSize(null), DevSetting.parse("playback.cacheSizeMegabytes=auto"))
    }

    @Test
    fun thePlayersChoicesTakeTheirValuesByNameInAnyCase() {
        assertEquals(DevSetting.Value(AppSettings.defaultBoxFitMode, VideoFit.COVER, "cover"), DevSetting.parse("default_box_fit_mode=cover"))
        assertEquals(DevSetting.Value(AppSettings.audioChannelLimit, AudioChannels.SURROUND_51, "surround_51"), DevSetting.parse("audio_channel_limit=surround_51"))
        assertEquals(DevSetting.Later(DevSetting.Value(AppSettings.defaultBoxFitMode, VideoFit.FILL, "FILL"), 10.0), DevSetting.parse("default_box_fit_mode=FILL@10"))
    }

    @Test
    fun ambientLightingAndDolbyVisionConversionTakeTheirKeysAsStored() {
        assertEquals(DevSetting.Switch(AppSettings.ambientLighting, true), DevSetting.parse("ambient_lighting=true"))
        assertEquals(
            DevSetting.Value(AppSettings.dvConversionMode, DolbyVisionConversion.HEVC_STRIP, "hevc_strip"),
            DevSetting.parse("dv_conversion_mode=hevc_strip"),
        )
        assertFailsWith<IllegalArgumentException> { DevSetting.parse("dv_conversion_mode=dv7") }
    }

    @Test
    fun theSkipSettingsTakeTheirValues() {
        assertEquals(DevSetting.Switch(AppSettings.forceSkipMarkerFallback, true), DevSetting.parse("force_skip_marker_fallback=true"))
        assertEquals(DevSetting.Value(AppSettings.skipIntroMode, SkipMode.OFF, "off"), DevSetting.parse("skip_intro_mode=off"))
        assertEquals(DevSetting.Value(AppSettings.skipCreditsMode, SkipMode.AUTO, "auto"), DevSetting.parse("skip_credits_mode=auto"))
        assertFailsWith<IllegalArgumentException> { DevSetting.parse("skip_intro_mode=skip") }
        assertEquals(DevSetting.Value(AppSettings.seekTimeSmall, 15, "15"), DevSetting.parse("seek_time_small=15"))
        assertFailsWith<IllegalArgumentException> { DevSetting.parse("seek_time_small=121") }
    }

    @Test
    fun theSubtitleStyleTakesItsSettingsValuesNumbersInTheirRangesAndNamesInAnyCase() {
        assertEquals(DevSetting.Value(AppSettings.subtitleFontSize, 60, "60"), DevSetting.parse("subtitle_font_size=60"))
        assertFailsWith<IllegalArgumentException> { DevSetting.parse("subtitle_font_size=81") }
        assertEquals(DevSetting.Value(AppSettings.subtitleTextColor, "#FFFF00", "#FFFF00"), DevSetting.parse("subtitle_text_color=#FFFF00"))
        assertFailsWith<IllegalArgumentException> { DevSetting.parse("subtitle_text_color=yellow") }
        assertEquals(DevSetting.Value(AppSettings.subAssOverride, SubAssOverride.FORCE, "force"), DevSetting.parse("sub_ass_override=force"))
        assertEquals(DevSetting.Value(AppSettings.subtitleBackgroundOpacity, 0, "0"), DevSetting.parse("subtitle_background_opacity=0"))
        assertEquals(DevSetting.Value(AppSettings.subtitleItalic, true, "true"), DevSetting.parse("subtitle_italic=true"))
        assertEquals(DevSetting.Value(AppSettings.deinterlaceMode, DeinterlaceMode.FILM, "FILM"), DevSetting.parse("deinterlace_mode=FILM"))
        assertEquals(
            DevSetting.Later(DevSetting.Value(AppSettings.subtitlePosition, 120, "120"), 60.0),
            DevSetting.parse("subtitle_position=120@60"),
        )
    }

    @Test
    fun theRelayTakesARelayUrlStoredCanonicalOrPublic() {
        assertEquals(
            DevSetting.Value(AppSettings.watchPartyRelayUrl, "http://127.0.0.1:18180", "HTTP://127.0.0.1:18180/"),
            DevSetting.parse("watch_party_relay_url=HTTP://127.0.0.1:18180/"),
        )
        assertEquals(DevSetting.Value(AppSettings.watchPartyRelayUrl, "https://relay.example/plezy", "https://relay.example:443/plezy"), DevSetting.parse("watch_party_relay_url=https://relay.example:443/plezy"))
        assertEquals(DevSetting.Value<String?>(AppSettings.watchPartyRelayUrl, null, "public"), DevSetting.parse("watch_party_relay_url=public"))
        assertEquals(DevSetting.Value<String?>(AppSettings.watchPartyRelayUrl, null, ""), DevSetting.parse("watch_party_relay_url="))
    }

    @Test
    fun theExternalPlayerTakesAKnownIdAndTheCustomPlayerANameATypeAndAValue() {
        assertEquals(DevSetting.Switch(AppSettings.useExternalPlayer, true), DevSetting.parse("use_external_player=true"))
        assertEquals(
            DevSetting.Value(AppSettings.selectedExternalPlayer, ExternalPlayerChoice("vlc", "VLC"), "vlc"),
            DevSetting.parse("selected_external_player=vlc"),
        )
        assertFailsWith<IllegalArgumentException> { DevSetting.parse("selected_external_player=plezy") }
        assertEquals(
            DevSetting.CustomPlayers(ExternalPlayerChoice("dev", "My mpv", isCustom = true, customValue = "mpv", customType = CustomPlayerType.COMMAND)),
            DevSetting.parse("custom_external_players=My mpv;command;mpv"),
        )
        // A URL scheme with an `@` of its own.
        val scheme = DevSetting.parse("custom_external_players=Handoff;urlScheme;http://user@192.168.1.5:8765/handoff?url=")
        assertEquals(
            DevSetting.CustomPlayers(
                ExternalPlayerChoice("dev", "Handoff", isCustom = true, customValue = "http://user@192.168.1.5:8765/handoff?url=", customType = CustomPlayerType.URL_SCHEME),
            ),
            scheme,
        )
        assertEquals("custom_external_players", scheme.key)
        for (bad in listOf("custom_external_players=mpv", "custom_external_players=x;program;mpv", "custom_external_players=;command;mpv", "custom_external_players=")) {
            assertFailsWith<IllegalArgumentException>(bad) { DevSetting.parse(bad) }
        }
    }

    @Test
    fun offlineAndFastTimersTakeTrueOrFalse() {
        assertEquals(DevSetting.Offline(true), DevSetting.parse("offline=true"))
        assertEquals(DevSetting.Later(DevSetting.Offline(false), 30.0), DevSetting.parse("offline=false@30"))
        assertFailsWith<IllegalArgumentException> { DevSetting.parse("offline=yes") }
        assertEquals(DevSetting.FastTimers(true), DevSetting.parse("player.fastTimers=true"))
        assertEquals(DevSetting.FastTimers(false), DevSetting.parse("player.fastTimers=false"))
        assertEquals(DevSetting.Later(DevSetting.FastTimers(true), 5.0), DevSetting.parse("player.fastTimers=true@5"))
        assertFailsWith<IllegalArgumentException> { DevSetting.parse("player.fastTimers=yes") }
    }

    @Test
    fun theInterfaceLanguageTakesAStoredLanguageName() {
        assertEquals(DevSetting.Value<String?>(AppSettings.appLocale, "zhHant", "zhHant"), DevSetting.parse("app_locale=zhHant"))
        assertEquals(DevSetting.Later(DevSetting.Value<String?>(AppSettings.appLocale, "de", "de"), 5.0), DevSetting.parse("app_locale=de@5"))
        for (bad in listOf("app_locale=zh-Hant", "app_locale=xx", "app_locale=")) {
            assertFailsWith<IllegalArgumentException>(bad) { DevSetting.parse(bad) }
        }
    }

    @Test
    fun anythingElseIsRefused() {
        for (bad in listOf(
            "enable_hardware_decoding", "enable_hardware_decoding=off", "enable_hdr=", "playback.cacheSizeMegabytes=15",
            "playback.cacheSizeMegabytes=4097", "playback.cacheSizeMegabytes=big", "app.activeProfileId=a", "hwdec=no",
            "subtitle_font_size=9", "subtitle_position=151", "subtitle_text_color=magenta", "sub_ass_override=",
            "subtitle_bold=yes", "subtitle_font_size=40@", "subtitle_font_size=40@-1", "subtitle_font_size=40@1@2",
            "default_box_fit_mode=zoom", "default_box_fit_mode=", "audio_channel_limit=7.1", "audio_normalization=on", "video.output=metal",
            "watch_party_relay_url=ws://relay.example", "watch_party_relay_url=relay.example", "watch_party_relay_url=https://relay.example/?a=1",
            "watch_party_relay_url=https://user@relay.example", "player.fastTimers=on", "player.fastTimers=",
        )) {
            assertFailsWith<IllegalArgumentException>(bad) { DevSetting.parse(bad) }
        }
    }

    @Test
    fun appearanceSettingsTakeTheirStoredKeysAndValues() {
        assertEquals(DevSetting.Value(AppSettings.themeMode, ThemeMode.EMBER, "ember"), DevSetting.parse("theme_mode=ember"))
        assertEquals(DevSetting.Value(AppSettings.forceTvMode, true, "true"), DevSetting.parse("force_tv_mode=true"))
        assertEquals(DevSetting.Value(AppSettings.startupSection, StartupSection.LIVE_TV, "liveTv"), DevSetting.parse("startup_section=liveTv"))
        assertEquals(DevSetting.Value(AppSettings.gridSpacing, GridSpacing.SPACIOUS, "spacious"), DevSetting.parse("grid_spacing=spacious"))
        assertEquals(DevSetting.Value(AppSettings.libraryDensity, 5, "5"), DevSetting.parse("library_density=5"))
        assertEquals(
            DevSetting.Value(AppSettings.episodePosterMode, EpisodePosterMode.SERIES_POSTER, "seriesPoster"),
            DevSetting.parse("episode_poster_mode=seriesPoster"),
        )
        for (bad in listOf("theme_mode=neon", "library_density=6", "force_tv_mode=yes", "view_mode=")) {
            assertFailsWith<IllegalArgumentException>(bad) { DevSetting.parse(bad) }
        }
    }
}
