package com.edde746.plezy.presentation.theme

import com.edde746.plezy.data.settings.DeviceSettingsRepository
import com.edde746.plezy.model.EpisodePosterMode
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.settings.CustomThemePalette
import com.edde746.plezy.settings.GridSpacing
import com.edde746.plezy.settings.StartupSection
import com.edde746.plezy.settings.ThemeMode
import com.edde746.plezy.settings.ViewMode
import com.edde746.plezy.settings.VisualEffects
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

/**
 * The appearance and browsing settings ([AppSettings]) as stored ([observe], [read]); [Appearance.of] turns them into
 * what the UIs draw.
 */
data class AppearanceSettings(
    /** Null: never chosen, the device's default ([AppSettings.defaultThemeMode]). */
    val themeMode: ThemeMode? = null,
    val customThemePalette: CustomThemePalette? = null,
    /** The TV layout on any device. */
    val forceTvMode: Boolean = false,
    val showNavBarLabels: Boolean = true,
    val alwaysKeepSidebarOpen: Boolean = false,
    val showExploreTab: Boolean = true,
    val startupSection: StartupSection = StartupSection.DISCOVER,
    /** Null: never chosen, the device's default ([AppSettings.defaultGridSpacing]). */
    val gridSpacing: GridSpacing? = null,
    /** 1 most compact to 5 most comfortable. */
    val libraryDensity: Int = 3,
    val viewMode: ViewMode = ViewMode.GRID,
    val episodePosterMode: EpisodePosterMode = EpisodePosterMode.EPISODE_THUMBNAIL,
    val tvFullCardLayout: Boolean = false,
    val focusGlow: Boolean = true,
    val showHeroSection: Boolean = true,
    val visualEffects: VisualEffects = VisualEffects.AUTO,
    /** Null: never chosen, the car's default ([AppSettings.automotiveUiScale]). */
    val automotiveUiScale: Double? = null,
) {
    companion object {
        private val SETTINGS = listOf(
            AppSettings.themeMode, AppSettings.customThemePalette, AppSettings.forceTvMode, AppSettings.showNavBarLabels,
            AppSettings.alwaysKeepSidebarOpen, AppSettings.showExploreTab, AppSettings.startupSection, AppSettings.gridSpacing,
            AppSettings.libraryDensity, AppSettings.viewMode, AppSettings.episodePosterMode, AppSettings.tvFullCardLayout,
            AppSettings.focusGlow, AppSettings.showHeroSection, AppSettings.visualEffects, AppSettings.automotiveUiScale,
        )

        /** The stored settings now and after every change. */
        fun observe(settings: DeviceSettingsRepository): Flow<AppearanceSettings> =
            settings.observe(SETTINGS).map { of(it) }

        /** The stored settings now: the first frame paints them, no default flashing first. */
        suspend fun read(settings: DeviceSettingsRepository): AppearanceSettings = of(settings.values(SETTINGS))

        private fun of(values: List<Any?>): AppearanceSettings = AppearanceSettings(
            themeMode = values[0] as ThemeMode?,
            customThemePalette = values[1] as CustomThemePalette?,
            forceTvMode = values[2] as Boolean,
            showNavBarLabels = values[3] as Boolean,
            alwaysKeepSidebarOpen = values[4] as Boolean,
            showExploreTab = values[5] as Boolean,
            startupSection = values[6] as StartupSection,
            gridSpacing = values[7] as GridSpacing?,
            libraryDensity = values[8] as Int,
            viewMode = values[9] as ViewMode,
            episodePosterMode = values[10] as EpisodePosterMode,
            tvFullCardLayout = values[11] as Boolean,
            focusGlow = values[12] as Boolean,
            showHeroSection = values[13] as Boolean,
            visualEffects = values[14] as VisualEffects,
            automotiveUiScale = values[15] as Double?,
        )
    }
}

/**
 * What the UIs draw with ([of]): the theme, the effective form factor (a device in Force TV mode lays out as a TV), and
 * the card and layout settings with the device's defaults applied.
 */
data class Appearance(
    val theme: AppTheme,
    val formFactor: FormFactor,
    val gridSpacing: GridSpacing,
    val libraryDensity: Int,
    val viewMode: ViewMode,
    /** Episodes show their own 16:9 thumbnail, not their series' or season's poster. */
    val episodeThumbnails: Boolean,
    val tvFullCardLayout: Boolean,
    val focusGlow: Boolean,
    val showHeroSection: Boolean,
    val showNavBarLabels: Boolean,
    val alwaysKeepSidebarOpen: Boolean,
    /** The visual effects tier the user picked; Auto leaves it to the hardware (`ArtworkDisplay.of`). */
    val visualEffects: VisualEffects,
    /** A car's display (Android Automotive, [com.edde746.plezy.app.AppPlatform.automotive]): Now Playing's transport keeps its full size. */
    val automotive: Boolean,
    /**
     * How much larger the whole interface draws than the platform's own density: the car's display scale (1.35 unless
     * the user picked one, 1.0 to 2.0) on a head unit, 1 everywhere else whatever is stored.
     */
    val uiScale: Double,
) {
    val tv: Boolean get() = formFactor == FormFactor.TV

    companion object {
        /**
         * [settings] on a device of [detected] form factor, [automotive] on a car's display; Supporter themes paint only
         * while [supporterUnlocked]. Force TV mode makes a handheld or desktop a TV.
         */
        fun of(settings: AppearanceSettings, detected: FormFactor, supporterUnlocked: Boolean, automotive: Boolean = false): Appearance {
            val formFactor = if (settings.forceTvMode) FormFactor.TV else detected
            val tv = formFactor == FormFactor.TV
            return Appearance(
                theme = AppTheme.resolve(settings.themeMode, settings.customThemePalette?.let(Palette::of), supporterUnlocked, tv),
                formFactor = formFactor,
                gridSpacing = settings.gridSpacing ?: AppSettings.defaultGridSpacing(tv),
                libraryDensity = settings.libraryDensity.coerceIn(1, 5),
                viewMode = settings.viewMode,
                episodeThumbnails = settings.episodePosterMode == EpisodePosterMode.EPISODE_THUMBNAIL,
                tvFullCardLayout = settings.tvFullCardLayout,
                focusGlow = settings.focusGlow,
                showHeroSection = settings.showHeroSection,
                showNavBarLabels = settings.showNavBarLabels,
                alwaysKeepSidebarOpen = settings.alwaysKeepSidebarOpen,
                visualEffects = settings.visualEffects,
                automotive = automotive,
                uiScale = if (automotive) AppSettings.automotiveUiScale(settings.automotiveUiScale, isAutomotive = true) else 1.0,
            )
        }
    }
}
