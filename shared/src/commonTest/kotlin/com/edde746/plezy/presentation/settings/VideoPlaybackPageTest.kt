package com.edde746.plezy.presentation.settings

import com.edde746.plezy.backend.AudioQualityPreset
import com.edde746.plezy.backend.TranscodeQualityPreset
import com.edde746.plezy.data.settings.SkipMode
import com.edde746.plezy.data.settings.DeviceSetting
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.settings.VideoPlaybackPage.Companion as Pb
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.settings.DeinterlaceMode
import com.edde746.plezy.settings.PlayerSettingScope
import com.edde746.plezy.strings.T
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import com.edde746.plezy.playback.AudioChannels as Channels

/**
 * Settings → Video Playback: which rows show (ExoPlayer or mpv, the channel limit, normalization,
 * phones), the values they store, and the number and pattern dialogs' checks.
 */
class VideoPlaybackPageTest {
    private val androidPhone = SettingsPlatform(os = "Android", formFactor = FormFactor.HANDHELD)
    private val appleTv = SettingsPlatform(os = "tvOS", isTv = true, formFactor = FormFactor.TV, appleTv = true, hasFileDialogs = false)
    private val androidTv = SettingsPlatform(os = "Android", isTv = true, formFactor = FormFactor.TV)

    private fun TestScope.playback(platform: SettingsPlatform = SettingsPlatform()): Pair<SettingsFixture, SettingsFixture.Page> {
        val fixture = settingsFixture(platform)
        val page = fixture.page(SettingsPageId.VIDEO_PLAYBACK)
        runCurrent()
        return fixture to page
    }

    private suspend fun SettingsFixture.store(block: suspend com.edde746.plezy.data.settings.DeviceSettingsRepository.() -> Unit) {
        data.deviceSettings.block()
    }

    @Test
    fun musicQualityShowsTheStoredBitrateAndStoresThePick() = runTest {
        val fixture = settingsFixture()
        fixture.store { set(AppSettings.musicQualityPreset, AudioQualityPreset.MEDIUM) }
        val page = fixture.page(SettingsPageId.VIDEO_PLAYBACK)
        runCurrent()
        assertEquals("192 kbps", page.rowOf<SettingChoiceRow>(Pb.MUSIC_QUALITY).valueLabel)

        page.store.choose(Pb.MUSIC_QUALITY, AudioQualityPreset.LOW.name)
        runCurrent()
        assertEquals(AudioQualityPreset.LOW, fixture.data.deviceSettings.value(AppSettings.musicQualityPreset))
        assertEquals("128 kbps", page.rowOf<SettingChoiceRow>(Pb.MUSIC_QUALITY).valueLabel)
    }

    /** The remember rows share one caption, their group's footer, instead of each repeating it. */
    @Test
    fun aRememberScopeShowsAndStoresItsChoice() = runTest {
        val (fixture, page) = playback()
        val row = page.rowOf<SettingChoiceRow>(Pb.SHADER_SCOPE)
        assertEquals(T.settings.scopeShaderPreset, row.title)
        assertEquals(T.settings.playerScopeGlobal, row.valueLabel)
        val group = page.state.groups.single { it.id == "remember" }
        assertEquals(T.settings.rememberPlayerChangesDescription, group.footer)
        assertTrue(group.rows.all { (it as SettingChoiceRow).caption == null })

        page.store.choose(Pb.SHADER_SCOPE, PlayerSettingScope.LIBRARY.name)
        runCurrent()
        assertEquals(PlayerSettingScope.LIBRARY, fixture.data.deviceSettings.value(AppSettings.shaderPresetScope))
        assertEquals(T.settings.playerScopeLibrary, page.rowOf<SettingChoiceRow>(Pb.SHADER_SCOPE).valueLabel)
        assertEquals(
            listOf(Pb.PLAYBACK_SPEED_SCOPE, Pb.SHADER_SCOPE, Pb.BOX_FIT_SCOPE, Pb.ZOOM_SCOPE, Pb.SYNC_SCOPE),
            group.rows.map { it.id },
        )
    }

    @Test
    fun enteringALibraryOrTitleScopeResetsTheGlobalValueAndLeavingItKeepsIt() = runTest {
        val (fixture, page) = playback()
        val settings = fixture.data.deviceSettings
        settings.set(AppSettings.defaultPlaybackSpeed, 1.5)

        page.store.choose(Pb.PLAYBACK_SPEED_SCOPE, PlayerSettingScope.TITLE.name)
        runCurrent()
        assertEquals(PlayerSettingScope.TITLE, settings.value(AppSettings.playbackSpeedScope))
        assertEquals(1.0, settings.value(AppSettings.defaultPlaybackSpeed))

        settings.set(AppSettings.defaultPlaybackSpeed, 1.25)
        page.store.choose(Pb.PLAYBACK_SPEED_SCOPE, PlayerSettingScope.LIBRARY.name)
        runCurrent()
        assertEquals(1.25, settings.value(AppSettings.defaultPlaybackSpeed), "keyed to keyed keeps the fallback")
        page.store.choose(Pb.PLAYBACK_SPEED_SCOPE, PlayerSettingScope.GLOBAL.name)
        runCurrent()
        assertEquals(1.25, settings.value(AppSettings.defaultPlaybackSpeed))
    }

    @Test
    fun playNextCountdownOfZeroSaysPlayImmediately() = runTest {
        val (fixture, page) = playback()
        assertNull(page.store.setNumber(Pb.PLAY_NEXT_COUNTDOWN, "0"))
        runCurrent()
        assertEquals(0, fixture.data.deviceSettings.value(AppSettings.playNextCountdown))
        assertEquals(T.settings.playNextCountdownImmediate, page.rowOf<SettingNumberRow>(Pb.PLAY_NEXT_COUNTDOWN).valueLabel)

        page.store.setNumber(Pb.PLAY_NEXT_COUNTDOWN, "12")
        runCurrent()
        assertEquals(T.settings.secondsUnit("12"), page.rowOf<SettingNumberRow>(Pb.PLAY_NEXT_COUNTDOWN).valueLabel)
    }

    @Test
    fun deinterlacingPicksFilmOnTheMpvPath() = runTest {
        val (fixture, page) = playback()
        assertEquals(T.settings.deinterlaceOff, page.rowOf<SettingChoiceRow>(Pb.DEINTERLACE).valueLabel)
        page.store.choose(Pb.DEINTERLACE, DeinterlaceMode.FILM.name)
        runCurrent()
        assertEquals(DeinterlaceMode.FILM, fixture.data.deviceSettings.value(AppSettings.deinterlaceMode))
        val row = page.rowOf<SettingChoiceRow>(Pb.DEINTERLACE)
        assertEquals(T.settings.deinterlaceFilm, row.valueLabel)
        assertEquals(T.settings.deinterlaceFilmDescription, row.options.single { it.selected }.subtitle)
    }

    @Test
    fun passthroughIsHeldOffWhileLoudnessNormalizationIsOn() = runTest {
        val fixture = settingsFixture(appleTv)
        fixture.store { set(AppSettings.audioNormalization, true) }
        val page = fixture.page(SettingsPageId.VIDEO_PLAYBACK)
        runCurrent()

        val held = page.rowOf<SettingToggleRow>(Pb.AUDIO_PASSTHROUGH)
        assertFalse(held.checked)
        assertFalse(held.enabled)
        assertEquals(T.settings.audioPassthroughOverriddenByNormalization, held.subtitle)
        page.store.toggle(Pb.AUDIO_PASSTHROUGH, false)
        runCurrent()
        assertNull(fixture.data.deviceSettings.value(AppSettings.audioPassthrough), "a held-off switch stores nothing")

        fixture.store { set(AppSettings.audioNormalization, false) }
        runCurrent()
        val free = page.rowOf<SettingToggleRow>(Pb.AUDIO_PASSTHROUGH)
        assertTrue(free.checked, "a TV passes through by default")
        assertTrue(free.enabled)
        assertFalse(free.subtitle == T.settings.audioPassthroughOverriddenByNormalization)
        page.store.toggle(Pb.AUDIO_PASSTHROUGH, false)
        runCurrent()
        assertEquals(false, fixture.data.deviceSettings.value(AppSettings.audioPassthrough))
    }

    @Test
    fun theChannelLimitShowsOnlyTheMixOptionsItUses() = runTest {
        val (fixture, page) = playback()
        assertFalse(page.has(Pb.CENTER_BOOST))
        assertFalse(page.has(Pb.DOWNMIX_NORMALIZE))

        page.store.choose(Pb.AUDIO_CHANNELS, Channels.SURROUND_51.name)
        runCurrent()
        assertEquals(Channels.SURROUND_51, fixture.data.deviceSettings.value(AppSettings.audioChannelLimit))
        // A 5.1 fold keeps the centre channel: only normalization applies.
        assertFalse(page.has(Pb.CENTER_BOOST))
        assertTrue(page.has(Pb.DOWNMIX_NORMALIZE))

        fixture.store { set(AppSettings.audioChannelLimit, Channels.STEREO) }
        runCurrent()
        assertTrue(page.has(Pb.CENTER_BOOST))
        assertTrue(page.has(Pb.DOWNMIX_NORMALIZE))
    }

    @Test
    fun androidShowsMpvRowsAndDvConversionWhileDolbyVisionIsOn() = runTest {
        val (fixture, page) = playback(androidPhone)
        for (id in listOf(Pb.MPV_CONFIG, Pb.DEINTERLACE, Pb.HDR_SDR_CONVERSION, Pb.DISABLE_DOLBY_VISION, Pb.DV_CONVERSION)) assertTrue(page.has(id), id)
        assertEquals(Channels.entries.map { it.name }, page.rowOf<SettingChoiceRow>(Pb.AUDIO_CHANNELS).options.map { it.id })

        fixture.store { set(AppSettings.disableDolbyVision, true) }
        runCurrent()
        assertFalse(page.has(Pb.DV_CONVERSION))
    }

    @Test
    fun stereoSaysItTurnsPassthroughOffOnlyWhereTheDeviceHasPassthrough() = runTest {
        fun subtitles(page: SettingsFixture.Page) = page.rowOf<SettingChoiceRow>(Pb.AUDIO_CHANNELS).options.map { it.subtitle }
        val settings = T.settings
        val (_, tv) = playback(appleTv)
        assertEquals(
            listOf(settings.audioChannelLimitOriginalDescription, settings.audioChannelLimitSurround51Description, settings.audioChannelLimitStereoDescription),
            subtitles(tv),
        )
        val (_, phone) = playback(androidPhone)
        assertEquals(listOf(settings.audioChannelLimitOriginalDescription, settings.audioChannelLimitSurround51Description, null), subtitles(phone))
    }

    /**
     * Rows doing different jobs never share a glyph: the seek and skip rows, the HDR and Dolby Vision rows, the audio
     * rows, the delays and timers and the two marker patterns, the remember rows beside Pinch to Zoom.
     */
    @Test
    fun rowsDoingDifferentJobsEachShowTheirOwnGlyph() = runTest {
        val related = listOf(
            listOf(Pb.SEEK_SMALL, Pb.SEEK_LARGE, Pb.REWIND_ON_RESUME, Pb.AUTO_PLAY_NEXT, Pb.SKIP_INTRO, Pb.SKIP_CREDITS),
            listOf(Pb.HDR, Pb.MATCH_DYNAMIC_RANGE, Pb.DISABLE_DOLBY_VISION, Pb.DV_CONVERSION, Pb.HDR_SDR_CONVERSION),
            listOf(Pb.AUDIO_PASSTHROUGH, Pb.AUDIO_CHANNELS, Pb.CENTER_BOOST, Pb.DOWNMIX_NORMALIZE, Pb.MAX_VOLUME),
            listOf(Pb.DISPLAY_SWITCH_DELAY, Pb.SLEEP_TIMER, Pb.PLAY_NEXT_COUNTDOWN, Pb.AUTO_SKIP_DELAY, Pb.INTRO_PATTERN, Pb.CREDITS_PATTERN),
            listOf(Pb.PLAYBACK_SPEED_SCOPE, Pb.SHADER_SCOPE, Pb.BOX_FIT_SCOPE, Pb.ZOOM_SCOPE, Pb.SYNC_SCOPE, Pb.PINCH_TO_ZOOM),
        )
        val (desktop, desktopPage) = playback()
        // Display matching on, so the switch delay shows.
        desktop.store { set(AppSettings.matchRefreshRate, true) }
        runCurrent()
        assertTrue(desktopPage.has(Pb.DISPLAY_SWITCH_DELAY))
        for (page in listOf(desktopPage, playback(androidPhone).second)) {
            for (ids in related) {
                val icons = ids.filter(page::has).map { page.row(it).icon }
                assertEquals(icons.distinct(), icons, "$ids")
            }
        }
    }

    /** Every row leads with a glyph, so the titles of every group start at one edge. */
    @Test
    fun everyRowShowsAGlyph() = runTest {
        for (platform in listOf(SettingsPlatform(), androidPhone, androidTv, appleTv)) {
            val page = playback(platform).second
            assertEquals(emptyList(), page.ids.filter { page.row(it).icon == null }, "rows without a glyph on ${platform.device.platform}")
        }
    }

    /** Click on Video to Toggle Play/Pause needs a pointer: neither a touch screen nor a TV's remote offers it. */
    @Test
    fun theClickRowShowsOnlyWithAPointer() = runTest {
        assertTrue(playback().second.has(Pb.CLICK_TOGGLES_PLAYBACK))
        for (platform in listOf(androidPhone, androidTv, appleTv)) {
            assertFalse(playback(platform).second.has(Pb.CLICK_TOGGLES_PLAYBACK), platform.device.platform)
        }
    }

    @Test
    fun desktopShowsTheSwitchDelayWithMatching() = runTest {
        val (fixture, page) = playback()
        assertTrue(page.has(Pb.MPV_CONFIG))
        assertTrue(page.has(Pb.MATCH_DYNAMIC_RANGE))
        assertFalse(page.has(Pb.DISPLAY_SWITCH_DELAY))
        fixture.store { set(AppSettings.matchRefreshRate, true) }
        runCurrent()
        assertTrue(page.has(Pb.DISPLAY_SWITCH_DELAY))
    }

    @Test
    fun androidShowsTheSwitchDelayWithFrameRateOrResolutionMatching() = runTest {
        val (fixture, page) = playback(androidPhone)
        assertFalse(page.has(Pb.DISPLAY_SWITCH_DELAY))
        fixture.store { set(AppSettings.matchContentResolution, true) }
        runCurrent()
        assertTrue(page.has(Pb.DISPLAY_SWITCH_DELAY))
        fixture.store {
            set(AppSettings.matchContentResolution, false)
            set(AppSettings.matchContentFrameRate, true)
        }
        runCurrent()
        assertTrue(page.has(Pb.DISPLAY_SWITCH_DELAY))
        fixture.store { set(AppSettings.matchContentFrameRate, false) }
        runCurrent()
        assertFalse(page.has(Pb.DISPLAY_SWITCH_DELAY))
    }

    @Test
    fun coveredQualityDirectPlayTurnsOff() = runTest {
        val (fixture, page) = playback()
        assertTrue(page.rowOf<SettingToggleRow>(Pb.DIRECT_PLAY_COVERED).checked)
        page.store.toggle(Pb.DIRECT_PLAY_COVERED, false)
        runCurrent()
        assertFalse(fixture.data.deviceSettings.value(AppSettings.directPlayCoveredQuality))
        assertTrue(page.state.groups.single { it.id == "quality" }.rows.any { it.id == Pb.DIRECT_PLAY_COVERED })
    }

    @Test
    fun codecsChecklistAlwaysAcceptsH264AndStoresTheUncheckedOnes() = runTest {
        val (fixture, page) = playback()
        val row = page.rowOf<SettingChecklistRow>(Pb.VIDEO_CODECS)
        val h264 = row.options.single { it.id == "h264" }
        assertTrue(h264.checked)
        assertTrue(h264.locked)
        assertEquals(T.settings.videoCodecsAlwaysAccepted, h264.subtitle)
        assertEquals("AV1, HEVC, H.264", row.valueLabel)
        assertEquals(T.settings.videoCodecsDescription, row.caption)

        page.store.setChecked(Pb.VIDEO_CODECS, listOf("av1"))
        runCurrent()
        assertEquals(listOf("hevc"), fixture.data.deviceSettings.value(AppSettings.refusedVideoCodecs))
        val after = page.rowOf<SettingChecklistRow>(Pb.VIDEO_CODECS)
        assertEquals("AV1, H.264", after.valueLabel)
        assertTrue(after.options.single { it.id == "h264" }.checked)

        val (_, phone) = playback(androidPhone)
        assertFalse(phone.has(Pb.VIDEO_CODECS))
        assertTrue(phone.has(Pb.CELLULAR_QUALITY))
    }

    @Test
    fun gestureRowsShowOnPhonesAndStore() = runTest {
        val (fixture, page) = playback(androidPhone)
        assertEquals(
            listOf(Pb.BRIGHTNESS_SWIPE, Pb.REMEMBER_BRIGHTNESS, Pb.VOLUME_SWIPE, Pb.PINCH_TO_ZOOM),
            page.state.groups.single { it.id == "gestures" }.rows.map { it.id },
        )
        page.store.toggle(Pb.VOLUME_SWIPE, false)
        runCurrent()
        val settings = fixture.data.deviceSettings
        assertFalse(settings.value(AppSettings.gestureVolumeSwipe))
        assertTrue(settings.value(AppSettings.gestureBrightnessSwipe))
        assertTrue(settings.value(AppSettings.gesturePinchToZoom))
    }

    @Test
    fun gestureRowsStayHiddenOffPhones() = runTest {
        for (platform in listOf(SettingsPlatform(os = "macOS"), SettingsPlatform(), appleTv)) {
            val (_, page) = playback(platform)
            assertFalse(page.state.groups.any { it.id == "gestures" })
        }
    }

    @Test
    fun theSubtitlesRowOpensSubtitleStylingOnEveryPlatform() = runTest {
        for (platform in listOf(androidPhone, SettingsPlatform(os = "macOS"), SettingsPlatform(), appleTv)) {
            val (_, page) = playback(platform)
            val row = page.rowOf<SettingLinkRow>(Pb.SUBTITLE_STYLING)
            assertEquals(T.settings.subtitleStyling, row.title)
            page.store.activate(Pb.SUBTITLE_STYLING)
            assertEquals(SettingsEvent.Open(SettingsPageId.SUBTITLE_STYLING), page.events.last())
        }
    }

    @Test
    fun shuffleStartsAtBeginningToggleIsStored() = runTest {
        val (fixture, page) = playback()
        assertFalse(page.rowOf<SettingToggleRow>(Pb.SHUFFLE_FROM_BEGINNING).checked)
        page.store.toggle(Pb.SHUFFLE_FROM_BEGINNING, true)
        runCurrent()
        assertTrue(fixture.data.deviceSettings.value(AppSettings.shuffleStartsFromBeginning))
        assertTrue(page.rowOf<SettingToggleRow>(Pb.SHUFFLE_FROM_BEGINNING).checked)
    }

    @Test
    fun numberDialogRefusesTextAndOutOfRangeValuesAndStoresTheRest() = runTest {
        val (fixture, page) = playback()
        val row = page.rowOf<SettingNumberRow>(Pb.SEEK_SMALL)
        assertEquals(1, row.min)
        assertEquals(120, row.max)
        assertEquals(T.settings.durationHint("1", "120"), row.hint)
        assertEquals(T.settings.secondsShort, row.suffix)

        assertEquals(T.settings.validationErrorEnterNumber, page.store.setNumber(Pb.SEEK_SMALL, "ten"))
        assertEquals(T.settings.validationErrorEnterNumber, page.store.setNumber(Pb.SEEK_SMALL, ""))
        val unit = T.settings.secondsLabel.lowercase()
        assertEquals(T.settings.validationErrorDuration("1", "120", unit), page.store.setNumber(Pb.SEEK_SMALL, "0"))
        assertEquals(T.settings.validationErrorDuration("1", "120", unit), page.store.setNumber(Pb.SEEK_SMALL, "121"))
        runCurrent()
        assertEquals(AppSettings.seekTimeSmall.default, fixture.data.deviceSettings.value(AppSettings.seekTimeSmall))

        assertNull(page.store.setNumber(Pb.SEEK_SMALL, " 45 "))
        runCurrent()
        assertEquals(45, fixture.data.deviceSettings.value(AppSettings.seekTimeSmall))
        assertEquals(T.settings.secondsUnit("45"), page.rowOf<SettingNumberRow>(Pb.SEEK_SMALL).valueLabel)

        for ((id, bounds) in listOf(Pb.MAX_VOLUME to (100 to 300), Pb.AUTO_SKIP_DELAY to (1 to 30), Pb.SLEEP_TIMER to (5 to 240), Pb.REWIND_ON_RESUME to (0 to 10))) {
            val number = page.rowOf<SettingNumberRow>(id)
            assertEquals(bounds, number.min to number.max, id)
        }
        assertFalse(page.store.setNumber(Pb.MAX_VOLUME, "99") == null)
        assertNull(page.store.setNumber(Pb.MAX_VOLUME, "300"))
        runCurrent()
        assertEquals(300, fixture.data.deviceSettings.value(AppSettings.maxVolume))
    }

    @Test
    fun theTimingRowsKeepTheirBoundsAndSayTheirValuesInTheirUnits() = runTest {
        val (fixture, page) = playback()
        fixture.store {
            set(AppSettings.matchRefreshRate, true)
            set(AppSettings.seekTimeLarge, 45)
            set(AppSettings.sleepTimerDuration, 90)
            set(AppSettings.autoSkipDelay, 7)
            set(AppSettings.rewindOnResume, 3)
        }
        runCurrent()
        for ((id, bounds) in listOf(Pb.SEEK_LARGE to (1 to 120), Pb.PLAY_NEXT_COUNTDOWN to (0 to 30), Pb.DISPLAY_SWITCH_DELAY to (0 to 10))) {
            val number = page.rowOf<SettingNumberRow>(id)
            assertEquals(bounds, number.min to number.max, id)
        }
        assertEquals(T.settings.secondsUnit("45"), page.rowOf<SettingNumberRow>(Pb.SEEK_LARGE).valueLabel)
        assertEquals(T.settings.secondsUnit("3"), page.rowOf<SettingNumberRow>(Pb.REWIND_ON_RESUME).valueLabel)
        assertEquals(T.settings.minutesUnit("90"), page.rowOf<SettingNumberRow>(Pb.SLEEP_TIMER).valueLabel)
        assertEquals(T.settings.secondsUnit("7"), page.rowOf<SettingNumberRow>(Pb.AUTO_SKIP_DELAY).valueLabel)
    }

    @Test
    fun everyNumberRowShowsItsBareValueBesideItsTitle() = runTest {
        val (fixture, page) = playback()
        fixture.store {
            set(AppSettings.matchRefreshRate, true)
            set(AppSettings.audioChannelLimit, Channels.STEREO)
        }
        runCurrent()
        val numbers = page.state.groups.flatMap { it.rows }.filterIsInstance<SettingNumberRow>()
        assertTrue(page.has(Pb.AUTO_SKIP_DELAY) && page.has(Pb.CENTER_BOOST) && page.has(Pb.DISPLAY_SWITCH_DELAY))
        for (row in numbers) {
            assertEquals(row.valueLabel, row.trailingValue, row.id)
            assertNull(row.subtitle, row.id)
        }
    }

    @Test
    fun skipModesSayWhatTheyDoAndTheAutoPlaySwitchesStore() = runTest {
        val (fixture, page) = playback()
        val intro = page.rowOf<SettingChoiceRow>(Pb.SKIP_INTRO)
        assertEquals(listOf(T.settings.skipMarkerModeOff, T.settings.skipMarkerModeButton, T.settings.skipMarkerModeAuto), intro.options.map { it.label })
        assertEquals(T.settings.skipMarkerModeButton, intro.valueLabel)
        assertEquals(T.settings.skipIntroModeButtonDescription, intro.caption)

        page.store.choose(Pb.SKIP_CREDITS, SkipMode.AUTO.name)
        page.store.toggle(Pb.FORCE_MARKER_FALLBACK, true)
        page.store.toggle(Pb.AUTO_PLAY_NEXT, false)
        runCurrent()
        val settings = fixture.data.deviceSettings
        assertEquals(SkipMode.AUTO, settings.value(AppSettings.skipCreditsMode))
        assertEquals(T.settings.skipCreditsModeAutoDescription, page.rowOf<SettingChoiceRow>(Pb.SKIP_CREDITS).caption)
        assertTrue(settings.value(AppSettings.forceSkipMarkerFallback))
        assertFalse(settings.value(AppSettings.autoPlayNextEpisode))
    }

    @Test
    fun behaviorRowsFollowThePlatform() = runTest {
        val behavior = listOf(Pb.REMEMBER_TRACKS, Pb.FOLLOW_SERVER_TRACKS, Pb.RESUME_MUSIC, Pb.CHAPTER_MARKERS, Pb.SPECIALS_ORDERING)
        val (_, desktop) = playback()
        assertEquals(behavior + Pb.CLICK_TOGGLES_PLAYBACK + Pb.EXIT_FULLSCREEN_ON_CLOSE, desktop.state.groups.single { it.id == "behavior" }.rows.map { it.id })
        assertEquals(
            "${T.settings.rememberTrackSelectionsDescription} · ${T.settings.rememberTrackSelectionsBackendRule}",
            desktop.rowOf<SettingToggleRow>(Pb.REMEMBER_TRACKS).subtitle,
        )
        assertEquals(
            listOf(T.settings.specialsOrderingServer, T.settings.specialsOrderingAirDate, T.settings.specialsOrderingLast),
            desktop.rowOf<SettingChoiceRow>(Pb.SPECIALS_ORDERING).options.map { it.label },
        )
        val (_, phone) = playback(androidPhone)
        assertEquals(behavior, phone.state.groups.single { it.id == "behavior" }.rows.map { it.id })
        val (_, androidTv) = playback(SettingsPlatform(os = "Android", isTv = true, formFactor = FormFactor.TV, hasFileDialogs = false))
        assertEquals(behavior, androidTv.state.groups.single { it.id == "behavior" }.rows.map { it.id })
    }

    @Test
    fun displayMatchingRowsFollowThePlatform() = runTest {
        val (_, phone) = playback(androidPhone)
        assertTrue(phone.has(Pb.MATCH_FRAME_RATE))
        assertFalse(phone.has(Pb.MATCH_RESOLUTION))
        assertEquals(
            listOf(T.settings.dvConversionAuto, T.settings.dvConversionNative, T.settings.dvConversionDv81, T.settings.dvConversionHevcStrip),
            phone.rowOf<SettingChoiceRow>(Pb.DV_CONVERSION).options.map { it.label },
        )
        assertEquals(listOf("AUTO", "DISABLED", "DV81", "HEVC_STRIP"), phone.rowOf<SettingChoiceRow>(Pb.DV_CONVERSION).options.map { it.id })

        val (_, androidTv) = playback(SettingsPlatform(os = "Android", isTv = true, formFactor = FormFactor.TV, hasFileDialogs = false))
        assertTrue(androidTv.has(Pb.MATCH_RESOLUTION))
        assertFalse(androidTv.has(Pb.MATCH_REFRESH_RATE))

        val (fixture, windows) = playback()
        assertFalse(windows.has(Pb.MATCH_FRAME_RATE))
        fixture.store { set(AppSettings.matchDynamicRange, true) }
        runCurrent()
        assertTrue(windows.has(Pb.DISPLAY_SWITCH_DELAY), "HDR switching alone waits for the display too")
        assertFalse(windows.has(Pb.DISABLE_DOLBY_VISION))

        val (_, linux) = playback(SettingsPlatform(os = "Linux"))
        assertFalse(linux.has(Pb.MATCH_REFRESH_RATE))
        assertFalse(linux.has(Pb.MATCH_DYNAMIC_RANGE))
    }

    @Test
    fun defaultQualityListsOriginalThenHighestFirstAndCellularCanFollowIt() = runTest {
        val (fixture, phone) = playback(androidPhone)
        val presets = phone.rowOf<SettingChoiceRow>(Pb.DEFAULT_QUALITY).options
        assertEquals(TranscodeQualityPreset.ORIGINAL.name, presets.first().id)
        assertEquals(T.videoControls.qualityOriginal, presets.first().label)
        assertEquals(listOf("1080p 20 Mbps", "1080p 12 Mbps"), presets.drop(1).take(2).map { it.label })
        assertEquals(TranscodeQualityPreset.P240_320.name, presets.last().id)

        val cellular = phone.rowOf<SettingChoiceRow>(Pb.CELLULAR_QUALITY).options
        assertEquals(T.settings.cellularQualitySameAsDefault, cellular.first().label)
        assertEquals(presets.map { it.label }, cellular.drop(1).map { it.label })
        phone.store.choose(Pb.CELLULAR_QUALITY, TranscodeQualityPreset.P720_2MBPS.name)
        runCurrent()
        assertEquals(TranscodeQualityPreset.P720_2MBPS, fixture.data.deviceSettings.value(AppSettings.cellularQualityPreset))
        phone.store.choose(Pb.CELLULAR_QUALITY, Pb.SAME_AS_DEFAULT)
        runCurrent()
        assertNull(fixture.data.deviceSettings.value(AppSettings.cellularQualityPreset))

        val (_, desktop) = playback()
        assertFalse(desktop.has(Pb.CELLULAR_QUALITY))
    }

    @Test
    fun patternDialogRefusesBlankAndInvalidAndStoresVerbatim() = runTest {
        val fixture = settingsFixture()
        // An earlier release stored a blank pattern: it can't be saved back.
        fixture.store { set(AppSettings.introPattern, "") }
        val page = fixture.page(SettingsPageId.VIDEO_PLAYBACK)
        runCurrent()
        val row = page.rowOf<SettingTextRow>(Pb.INTRO_PATTERN)
        assertEquals("", row.value)
        assertEquals(T.settings.regex, row.fieldLabel)
        assertEquals(T.settings.resetToDefault, row.resetLabel)
        assertTrue(row.monospace)

        assertEquals(T.settings.invalidRegex, page.store.submitText(Pb.INTRO_PATTERN, ""))
        assertEquals(T.settings.invalidRegex, page.store.submitText(Pb.INTRO_PATTERN, "   "))
        assertEquals(T.settings.invalidRegex, page.store.submitText(Pb.INTRO_PATTERN, "(unclosed"))
        runCurrent()
        assertEquals("", fixture.data.deviceSettings.value(AppSettings.introPattern))

        val typed = """ credits\s*roll """
        assertNull(page.store.submitText(Pb.CREDITS_PATTERN, typed))
        runCurrent()
        assertEquals(typed, fixture.data.deviceSettings.value(AppSettings.creditsPattern))
        assertEquals(typed, page.rowOf<SettingTextRow>(Pb.CREDITS_PATTERN).value)

        assertEquals(AppSettings.introPattern.default, page.store.resetText(Pb.INTRO_PATTERN))
        runCurrent()
        assertEquals("", fixture.data.deviceSettings.value(AppSettings.introPattern), "reset only fills the field in")
    }

    /** A pattern row's subtitle is its pattern alone, however short; what the pattern does is said in its dialog. */
    @Test
    fun aPatternRowShowsItsPatternAsItsSubtitle() = runTest {
        val fixture = settingsFixture()
        fixture.store { set(AppSettings.creditsPattern, "end") }
        val page = fixture.page(SettingsPageId.VIDEO_PLAYBACK)
        runCurrent()
        val credits = page.rowOf<SettingTextRow>(Pb.CREDITS_PATTERN)
        assertEquals("end", credits.subtitle)
        assertNull(credits.trailingValue)
        assertEquals(T.settings.creditsPatternDescription, credits.caption)
        val intro = page.rowOf<SettingTextRow>(Pb.INTRO_PATTERN)
        assertEquals(AppSettings.introPattern.default, intro.subtitle)
        assertNull(intro.trailingValue)
    }

    @Test
    fun numberAndPatternChecksSayWhatSaveWouldRefuseAndStoreNothing() = runTest {
        val (fixture, page) = playback()
        val unit = T.settings.secondsLabel.lowercase()
        assertEquals(T.settings.validationErrorEnterNumber, page.store.checkNumber(Pb.SEEK_SMALL, "ten"))
        assertEquals(T.settings.validationErrorEnterNumber, page.store.checkNumber(Pb.SEEK_SMALL, ""))
        assertEquals(T.settings.validationErrorDuration("1", "120", unit), page.store.checkNumber(Pb.SEEK_SMALL, "999"))
        assertNull(page.store.checkNumber(Pb.SEEK_SMALL, " 45 "))
        assertEquals(page.store.checkNumber(Pb.SEEK_SMALL, "999"), page.store.setNumber(Pb.SEEK_SMALL, "999"))

        assertEquals(T.settings.invalidRegex, page.store.checkText(Pb.INTRO_PATTERN, "   "))
        assertEquals(T.settings.invalidRegex, page.store.checkText(Pb.INTRO_PATTERN, "(unclosed"))
        assertNull(page.store.checkText(Pb.CREDITS_PATTERN, "end"))
        assertEquals(page.store.checkText(Pb.INTRO_PATTERN, "(unclosed"), page.store.submitText(Pb.INTRO_PATTERN, "(unclosed"))
        runCurrent()
        assertEquals(AppSettings.seekTimeSmall.default, fixture.data.deviceSettings.value(AppSettings.seekTimeSmall))
        assertEquals(AppSettings.introPattern.default, fixture.data.deviceSettings.value(AppSettings.introPattern))
        assertEquals(AppSettings.creditsPattern.default, fixture.data.deviceSettings.value(AppSettings.creditsPattern))
        assertTrue(page.messages.isEmpty())
    }

    @Test
    fun aFailedSaveSaysSoKeepsTheValueAndASecondTryStores() = runTest {
        val (fixture, page) = playback()
        fixture.failWrites(AppSettings.seekTimeSmall.key)
        fixture.failWrites(AppSettings.creditsPattern.key)
        assertNull(page.store.setNumber(Pb.SEEK_SMALL, "45"))
        assertNull(page.store.submitText(Pb.CREDITS_PATTERN, "end"))
        runCurrent()
        val failed = SettingsEvent.Message(T.settings.saveFailed, error = true)
        assertEquals(listOf(failed, failed), page.messages)
        assertEquals(AppSettings.seekTimeSmall.default, fixture.data.deviceSettings.value(AppSettings.seekTimeSmall))
        assertEquals(AppSettings.creditsPattern.default, fixture.data.deviceSettings.value(AppSettings.creditsPattern))

        fixture.allowWrites(AppSettings.seekTimeSmall.key)
        fixture.allowWrites(AppSettings.creditsPattern.key)
        assertNull(page.store.setNumber(Pb.SEEK_SMALL, "45"))
        assertNull(page.store.submitText(Pb.CREDITS_PATTERN, "end"))
        runCurrent()
        assertEquals(45, fixture.data.deviceSettings.value(AppSettings.seekTimeSmall))
        assertEquals("end", fixture.data.deviceSettings.value(AppSettings.creditsPattern))
    }
}
