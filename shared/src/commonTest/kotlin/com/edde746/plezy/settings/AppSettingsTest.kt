package com.edde746.plezy.settings

import com.edde746.plezy.backend.AudioQualityPreset
import com.edde746.plezy.backend.TranscodeQualityPreset
import com.edde746.plezy.data.testData
import com.edde746.plezy.data.settings.DolbyVisionConversion
import com.edde746.plezy.playback.VideoFit
import com.edde746.plezy.trackers.TrackerService
import kotlinx.coroutines.test.runTest
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class AppSettingsTest {
    private val data = testData()
    private val settings = data.deviceSettings

    @AfterTest
    fun close() = data.close()

    // ---- Typed values and their stored form ---------------------------------------------------------------------

    @Test
    fun musicQualityPersistsByItsStoredName() = runTest {
        assertEquals(AudioQualityPreset.ORIGINAL, settings.value(AppSettings.musicQualityPreset))
        settings.set(AppSettings.musicQualityPreset, AudioQualityPreset.MEDIUM)
        assertEquals("\"medium\"", data.storedJson("music_quality_preset"))
        assertEquals(AudioQualityPreset.MEDIUM, settings.value(AppSettings.musicQualityPreset))
    }

    @Test
    fun cellularQualityFollowsTheDefaultUntilSetAndPersistsByName() = runTest {
        assertNull(settings.value(AppSettings.cellularQualityPreset))
        settings.set(AppSettings.cellularQualityPreset, TranscodeQualityPreset.P720_2MBPS)
        assertEquals("\"p720_2mbps\"", data.storedJson("cellular_quality_preset"))
        assertEquals(TranscodeQualityPreset.P720_2MBPS, settings.value(AppSettings.cellularQualityPreset))
    }

    @Test
    fun writingNullRemovesTheKey() = runTest {
        settings.set(AppSettings.cellularQualityPreset, TranscodeQualityPreset.P1080_8MBPS)
        settings.set(AppSettings.cellularQualityPreset, null)
        assertNull(data.storedJson("cellular_quality_preset"))
        assertNull(settings.value(AppSettings.cellularQualityPreset))
    }

    @Test
    fun anUnrecognizedStoredQualityReadsAsNullNotAFallbackPreset() = runTest {
        data.store("cellular_quality_preset", "\"p9999_removed\"")
        assertNull(settings.value(AppSettings.cellularQualityPreset))
    }

    @Test
    fun anUnknownEnumNameReadsAsTheDefault() = runTest {
        data.store("startup_section", "\"downloads\"")
        assertEquals(StartupSection.DISCOVER, settings.value(AppSettings.startupSection))
    }

    @Test
    fun severalSettingsReadTogetherAreEachOnesValueAsReadAlone() = runTest {
        settings.set(AppSettings.libraryDensity, 5)
        data.store("startup_section", "\"downloads\"")
        val read = listOf(AppSettings.themeMode, AppSettings.libraryDensity, AppSettings.startupSection, AppSettings.focusGlow)
        assertEquals(listOf(null, 5, StartupSection.DISCOVER, true), settings.values(read))
        assertEquals(read.map { settings.value(it) }, settings.values(read))
    }

    @Test
    fun anUnknownStoredThemeReadsAsUnsetSoThePlatformDefaultApplies() = runTest {
        data.store("theme_mode", "\"bogus\"")
        assertNull(settings.value(AppSettings.themeMode))
        data.store("theme_mode", "\"glacier\"")
        assertEquals(ThemeMode.GLACIER, settings.value(AppSettings.themeMode))
    }

    @Test
    fun dolbyVisionConversionPersistsByItsStoredNameAndReachesTheEnginesByItsWireName() = runTest {
        assertEquals(DolbyVisionConversion.AUTO, settings.value(AppSettings.dvConversionMode))
        settings.set(AppSettings.dvConversionMode, DolbyVisionConversion.DV81)
        assertEquals("\"dv81\"", data.storedJson("dv_conversion_mode"))
        data.store("dv_conversion_mode", "\"hevcStrip\"")
        assertEquals(DolbyVisionConversion.HEVC_STRIP, settings.value(AppSettings.dvConversionMode))
        assertEquals(listOf("auto", "disabled", "dv81", "hevc_strip"), DolbyVisionConversion.entries.map { it.wire })
    }

    @Test
    fun theBoxFitIsStoredAsItsIndexAndClampedOnRead() = runTest {
        settings.set(AppSettings.defaultBoxFitMode, VideoFit.COVER)
        assertEquals("1", data.storedJson("default_box_fit_mode"))
        data.store("default_box_fit_mode", "7")
        assertEquals(VideoFit.FILL, settings.value(AppSettings.defaultBoxFitMode))
    }

    @Test
    fun clampedSettingsClampOnWriteAndRead() = runTest {
        settings.set(AppSettings.maxVolume, 50)
        assertEquals("100", data.storedJson("max_volume"))
        data.store("play_next_countdown", "45")
        assertEquals(30, settings.value(AppSettings.playNextCountdown))
        settings.set(AppSettings.defaultPlaybackSpeed, 12.0)
        assertEquals(8.0, settings.value(AppSettings.defaultPlaybackSpeed))
    }

    // ---- Tolerant reads -------------------------------------------------------------------------------------------

    @Test
    fun aWrongStoredTypeReadsAsTheDefault() = runTest {
        data.store("enable_debug_logging", "\"yes\"")
        assertFalse(settings.value(AppSettings.enableDebugLogging))
    }

    @Test
    fun aReadableValueIsReturnedUnchanged() = runTest {
        data.store("enable_debug_logging", "true")
        assertTrue(settings.value(AppSettings.enableDebugLogging))
    }

    @Test
    fun aPartialCustomPaletteReadsAsNone() = runTest {
        data.store("custom_theme_palette", """{"bg":"#FF000000","surface":"#FF111111"}""")
        assertNull(settings.value(AppSettings.customThemePalette))
    }

    @Test
    fun aPaletteWithAnInvalidColourReadsAsNoneAndValidOnesReadAsArgb() = runTest {
        data.store(
            "custom_theme_palette",
            """{"bg":"#000000","surface":"ff111111","outline":"#222222","text":"#ffffff","textMuted":"#99AAAAAA","accent":"#E5A00D"}""",
        )
        assertEquals(
            CustomThemePalette("#FF000000", "#FF111111", "#FF222222", "#FFFFFFFF", "#99AAAAAA", "#FFE5A00D"),
            settings.value(AppSettings.customThemePalette),
        )
        data.store(
            "custom_theme_palette",
            """{"bg":"#000000","surface":"blue","outline":"#222222","text":"#ffffff","textMuted":"#999999","accent":"#E5A00D"}""",
        )
        assertNull(settings.value(AppSettings.customThemePalette))
    }

    // ---- App locale -----------------------------------------------------------------------------------------------

    @Test
    fun scriptSpecificLocalesPersistByStoredName() = runTest {
        settings.set(AppSettings.appLocale, AppLocale.ZH_HANT.storedName)
        assertEquals("\"zhHant\"", data.storedJson("app_locale"))
        assertEquals(AppLocale.ZH_HANT, AppLocale.fromStored(settings.value(AppSettings.appLocale)))
        settings.set(AppSettings.appLocale, AppLocale.PT_PT.storedName)
        assertEquals("\"ptPt\"", data.storedJson("app_locale"))
        assertEquals(AppLocale.PT_PT, AppLocale.fromStored(settings.value(AppSettings.appLocale)))
    }

    @Test
    fun legacyLanguageCodeValuesStillRead() = runTest {
        data.store("app_locale", "\"zh\"")
        assertEquals(AppLocale.ZH, AppLocale.fromStored(settings.value(AppSettings.appLocale)))
    }

    @Test
    fun noLocaleFollowsTheDeviceAndAnUnknownOneIsEnglish() {
        assertNull(AppLocale.fromStored(null))
        assertNull(AppLocale.fromStored(""))
        assertEquals(AppLocale.EN, AppLocale.fromStored("tlh"))
    }

    // ---- Platform gates -------------------------------------------------------------------------------------------

    @Test
    fun audioPassthroughDefaultsOffOffTvAndHonorsExplicitChoices() = runTest {
        assertFalse(AppSettings.audioPassthroughOn(settings.value(AppSettings.audioPassthrough), isTv = false))
        settings.set(AppSettings.audioPassthrough, true)
        assertTrue(AppSettings.audioPassthroughOn(settings.value(AppSettings.audioPassthrough), isTv = false))
        settings.set(AppSettings.audioPassthrough, false)
        assertFalse(AppSettings.audioPassthroughOn(settings.value(AppSettings.audioPassthrough), isTv = false))
    }

    @Test
    fun audioPassthroughDefaultsOnForATvUntilTurnedOff() = runTest {
        assertTrue(AppSettings.audioPassthroughOn(settings.value(AppSettings.audioPassthrough), isTv = true))
        settings.set(AppSettings.audioPassthrough, false)
        assertFalse(AppSettings.audioPassthroughOn(settings.value(AppSettings.audioPassthrough), isTv = true))
    }

    @Test
    fun autoPipIsOffWithoutPictureInPictureEvenWhenStoredOn() = runTest {
        settings.set(AppSettings.autoPip, true)
        val stored = settings.value(AppSettings.autoPip)
        assertFalse(AppSettings.autoPipOn(stored, supportsPictureInPicture = false, isMacOs = false))
        assertTrue(AppSettings.autoPipOn(stored, supportsPictureInPicture = true, isMacOs = true))
    }

    @Test
    fun autoPipDefaultsOnWhereSupportedButOnAMac() {
        assertTrue(AppSettings.autoPipOn(null, supportsPictureInPicture = true, isMacOs = false))
        assertFalse(AppSettings.autoPipOn(null, supportsPictureInPicture = true, isMacOs = true))
    }

    @Test
    fun anExternalPlayerIsOffWhereTheDeviceHasNone() {
        assertFalse(AppSettings.useExternalPlayerOn(stored = true, supportsExternalPlayers = false))
    }

    // ---- Trackers -------------------------------------------------------------------------------------------------

    @Test
    fun trackerLibraryFilterOnlyAllowsUnknownLibrariesWhenNoFilterIsConfigured() = runTest {
        val trakt = TrackerService.TRAKT
        assertTrue(settings.isLibraryAllowedForTracker(trakt, null))

        settings.set(AppSettings.trackerFilterIds(trakt), listOf("server:blocked"))
        assertFalse(settings.isLibraryAllowedForTracker(trakt, null))
        assertFalse(settings.isLibraryAllowedForTracker(trakt, "server:blocked"))
        assertTrue(settings.isLibraryAllowedForTracker(trakt, "server:other"))

        settings.set(AppSettings.trackerFilterMode(trakt), TrackerLibraryFilterMode.WHITELIST)
        settings.set(AppSettings.trackerFilterIds(trakt), listOf("server:allowed"))
        assertFalse(settings.isLibraryAllowedForTracker(trakt, null))
        assertTrue(settings.isLibraryAllowedForTracker(trakt, "server:allowed"))
        assertFalse(settings.isLibraryAllowedForTracker(trakt, "server:other"))
    }

    @Test
    fun trackerSettingsAreKeyedByTheServicesStoredName() {
        assertEquals("enable_mal_scrobble", AppSettings.scrobble(TrackerService.MYANIMELIST).key)
        assertEquals("tracker_library_filter_mode_anilist", AppSettings.trackerFilterMode(TrackerService.ANILIST).key)
        assertEquals("tracker_library_filter_ids_mdblist", AppSettings.trackerFilterIds(TrackerService.MDBLIST).key)
    }

    // ---- Validation -----------------------------------------------------------------------------------------------

    @Test
    fun validationRejectsWhatTheSettingsScreensWould() {
        assertFailsWith<IllegalArgumentException> { AppSettings.validate(AppSettings.seekTimeSmall, 0) }
        AppSettings.validate(AppSettings.seekTimeSmall, 120)
        assertFailsWith<IllegalArgumentException> { AppSettings.validate(AppSettings.volume, Double.NaN) }
        assertFailsWith<IllegalArgumentException> { AppSettings.validate(AppSettings.rememberedBrightnessLevel, -0.5) }
        AppSettings.validate(AppSettings.rememberedBrightnessLevel, -1.0)
        assertFailsWith<IllegalArgumentException> { AppSettings.validate(AppSettings.introPattern, "  ") }
        assertFailsWith<IllegalArgumentException> { AppSettings.validate(AppSettings.creditsPattern, "(unclosed") }
        AppSettings.validate(AppSettings.creditsPattern, AppSettings.creditsPattern.default)
        assertFailsWith<IllegalArgumentException> { AppSettings.validate(AppSettings.subtitleTextColor, "#FFF") }
        AppSettings.validate(AppSettings.subtitleTextColor, "#a0B1c2")
        assertFailsWith<IllegalArgumentException> { AppSettings.validate(AppSettings.subtitleSearchLanguage, "klingon") }
        AppSettings.validate(AppSettings.subtitleSearchLanguage, "eng")
        val ids = AppSettings.trackerFilterIds(TrackerService.TRAKT)
        assertFailsWith<IllegalArgumentException> { AppSettings.validate(ids, listOf("a", "a")) }
        assertFailsWith<IllegalArgumentException> { AppSettings.validate(ids, listOf(" ")) }
    }
}
