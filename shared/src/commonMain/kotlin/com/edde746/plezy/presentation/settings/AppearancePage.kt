package com.edde746.plezy.presentation.settings

import com.edde746.plezy.data.settings.DeviceSettingsRepository
import com.edde746.plezy.model.EpisodePosterMode
import com.edde746.plezy.presentation.theme.AppTheme
import com.edde746.plezy.presentation.theme.Palette
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.settings.ContinueWatchingAction
import com.edde746.plezy.settings.EpisodeAction
import com.edde746.plezy.settings.GridSpacing
import com.edde746.plezy.settings.ViewMode
import com.edde746.plezy.settings.VisualEffects
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.StateFlow

/**
 * Settings → Appearance: Display (Theme, the App icon slot, Visual Effects on Android), Library &
 * Cards, Home Screen, Navigation and Live TV, each row shown where it applies.
 */
internal class AppearancePage(
    settings: DeviceSettingsRepository,
    private val session: SettingsSession,
    private val facts: StateFlow<SettingsFacts>,
    parentScope: CoroutineScope,
) : RowPageStore(settings, parentScope, { T.settings.appearance }) {
    private var unlocked = false
    private var hasCatalog = false

    init {
        follow(facts) {}
        follow(session.perks) { unlocked = it.unlocked }
        follow(session.hasCatalog) { hasCatalog = it }
        start(
            listOf(
                AppSettings.themeMode, AppSettings.customThemePalette, AppSettings.visualEffects, AppSettings.viewMode,
                AppSettings.libraryDensity, AppSettings.gridSpacing, AppSettings.episodePosterMode, AppSettings.showEpisodeNumberOnCards,
                AppSettings.showSeasonPostersOnTabs, AppSettings.hideSpoilers, AppSettings.showWatchedIndicators, AppSettings.tvFullCardLayout,
                AppSettings.focusGlow, AppSettings.continueWatchingAction,
                AppSettings.episodeAction, AppSettings.useGlobalHubs, AppSettings.showServerNameOnHubs, AppSettings.showExploreTab,
                AppSettings.alwaysKeepSidebarOpen, AppSettings.groupLibrariesByServer, AppSettings.showNavBarLabels,
                AppSettings.showUnwatchedCount, AppSettings.liveTvDefaultFavorites,
            ),
        )
    }

    override fun build(rows: Rows): List<SettingsGroup> {
        val facts = facts.value
        val tv = facts.tv
        // Android, Windows and Linux draw poster cards, which space grids by their width and focus with a ring: no
        // glow, and grid spacing only for the TV rails. The stored values stay.
        val posterCards = facts.android || facts.windows || facts.linux
        val custom = value(AppSettings.customThemePalette)?.let(Palette::of)
        val theme = AppTheme.resolve(value(AppSettings.themeMode), custom, unlocked, tv).mode
        val display = listOfNotNull(
            rows.page(THEME, T.settings.theme, null, SettingIcon.PALETTE, SettingsPageId.THEME, valueLabel = themeLabel(theme)),
            if (facts.appIconsSupported) rows.slot(APP_ICON, SettingSlot.APP_ICON) else null,
            if (facts.android) {
                rows.choice(
                    VISUAL_EFFECTS,
                    AppSettings.visualEffects,
                    T.settings.visualEffects,
                    choices(VisualEffects.entries, ::visualEffectsLabel) {
                        when (it) {
                            VisualEffects.AUTO -> T.settings.visualEffectsAutoDescription
                            VisualEffects.FULL -> null
                            VisualEffects.REDUCED -> T.settings.visualEffectsReducedDescription
                        }
                    },
                    SettingIcon.BLUR,
                )
            } else {
                null
            },
        )
        val density = value(AppSettings.libraryDensity)
        val library = listOfNotNull(
            rows.choice(
                VIEW_MODE, AppSettings.viewMode, T.settings.viewMode,
                choices(ViewMode.entries, { if (it == ViewMode.GRID) T.settings.gridView else T.settings.listView }),
                SettingIcon.GRID,
            ),
            rows.slider(
                LIBRARY_DENSITY, T.settings.libraryDensity, density.toDouble(),
                AppSettings.LIBRARY_DENSITY_RANGE.first.toDouble(), AppSettings.LIBRARY_DENSITY_RANGE.last.toDouble(),
                steps = 4, valueLabel = density.toString(), startLabel = T.settings.compact, endLabel = T.settings.comfortable,
                icon = SettingIcon.VIEW_LIST,
            ) { write(AppSettings.libraryDensity, kotlin.math.round(it).toInt()) },
            if (posterCards && !tv) {
                null
            } else {
                rows.choice(
                    GRID_SPACING, T.settings.gridSpacing,
                    choices(GridSpacing.entries, ::gridSpacingLabel),
                    value(AppSettings.gridSpacing) ?: AppSettings.defaultGridSpacing(tv), SettingIcon.SPACING,
                ) { write(AppSettings.gridSpacing, it) }
            },
            rows.choice(
                EPISODE_POSTER_MODE, AppSettings.episodePosterMode, T.settings.episodePosterMode,
                choices(EpisodePosterMode.entries, ::episodePosterLabel), SettingIcon.IMAGE_ASPECT,
            ),
            rows.toggle(SHOW_EPISODE_NUMBER, AppSettings.showEpisodeNumberOnCards, T.settings.showEpisodeNumberOnCards, T.settings.showEpisodeNumberOnCardsDescription, SettingIcon.NUMBERS),
            if (tv) null else rows.toggle(SHOW_SEASON_POSTERS, AppSettings.showSeasonPostersOnTabs, T.settings.showSeasonPostersOnTabs, T.settings.showSeasonPostersOnTabsDescription, SettingIcon.IMAGE),
            rows.toggle(HIDE_SPOILERS, AppSettings.hideSpoilers, T.settings.hideSpoilers, T.settings.hideSpoilersDescription, SettingIcon.BLUR),
            rows.toggle(SHOW_WATCHED_INDICATORS, AppSettings.showWatchedIndicators, T.settings.showWatchedIndicators, T.settings.showWatchedIndicatorsDescription, SettingIcon.CHECK),
            if (tv) rows.toggle(TV_FULL_CARDS, AppSettings.tvFullCardLayout, T.settings.tvFullCardLayout, T.settings.tvFullCardLayoutDescription, SettingIcon.GRID) else null,
        )
        val home = listOfNotNull(
            rows.choice(
                CONTINUE_WATCHING_ACTION, AppSettings.continueWatchingAction, T.settings.continueWatchingAction,
                choices(ContinueWatchingAction.entries, { if (it == ContinueWatchingAction.PLAY) T.settings.continueWatchingPlay else T.settings.continueWatchingDetails }),
                SettingIcon.PLAY_ARROW,
            ),
            rows.choice(
                EPISODE_ACTION, AppSettings.episodeAction, T.settings.episodeAction,
                choices(EpisodeAction.entries, { if (it == EpisodeAction.PLAY) T.settings.episodePlay else T.settings.episodeDetails }),
                SettingIcon.PLAY_ARROW,
            ),
            rows.toggle(USE_GLOBAL_HUBS, AppSettings.useGlobalHubs, T.settings.useGlobalHubs, T.settings.useGlobalHubsDescription, SettingIcon.HOME),
            rows.toggle(SHOW_SERVER_NAME, AppSettings.showServerNameOnHubs, T.settings.showServerNameOnHubs, T.settings.showServerNameOnHubsDescription, SettingIcon.DNS),
        )
        val sideNavigation = !facts.handheld
        val navigation = listOfNotNull(
            if (hasCatalog) rows.toggle(SHOW_EXPLORE_TAB, AppSettings.showExploreTab, T.settings.showExploreTab, T.settings.showExploreTabDescription, SettingIcon.EXPLORE) else null,
            if (facts.keepSidebarOpenSupported) rows.toggle(ALWAYS_KEEP_SIDEBAR_OPEN, AppSettings.alwaysKeepSidebarOpen, T.settings.alwaysKeepSidebarOpen, T.settings.alwaysKeepSidebarOpenDescription, SettingIcon.NAVIGATION) else null,
            if (sideNavigation) rows.toggle(GROUP_LIBRARIES_BY_SERVER, AppSettings.groupLibrariesByServer, T.settings.groupLibrariesByServer, T.settings.groupLibrariesByServerDescription, SettingIcon.LAYERS) else null,
            if (facts.navBarLabelsSupported) rows.toggle(SHOW_NAV_BAR_LABELS, AppSettings.showNavBarLabels, T.settings.showNavBarLabels, T.settings.showNavBarLabelsDescription, SettingIcon.LABEL) else null,
            rows.toggle(SHOW_UNWATCHED_COUNT, AppSettings.showUnwatchedCount, T.settings.showUnwatchedCount, T.settings.showUnwatchedCountDescription, SettingIcon.NUMBERS),
        )
        val liveTv = listOf(
            rows.toggle(LIVE_TV_DEFAULT_FAVORITES, AppSettings.liveTvDefaultFavorites, T.settings.liveTvDefaultFavorites, T.settings.liveTvDefaultFavoritesDescription, SettingIcon.LIVE_TV),
        )
        return listOf(
            SettingsGroup("display", T.settings.display, display),
            SettingsGroup("library", T.settings.libraryAndCards, library),
            SettingsGroup("home", T.settings.homeScreen, home),
            SettingsGroup("navigation", T.settings.navigation, navigation),
            SettingsGroup("live_tv", T.settings.liveTv, liveTv),
        )
    }

    companion object {
        const val THEME = "theme"
        const val APP_ICON = "app_icon"
        const val VISUAL_EFFECTS = "visual_effects"
        const val VIEW_MODE = "view_mode"
        const val LIBRARY_DENSITY = "library_density"
        const val GRID_SPACING = "grid_spacing"
        const val EPISODE_POSTER_MODE = "episode_poster_mode"
        const val SHOW_EPISODE_NUMBER = "show_episode_number_on_cards"
        const val SHOW_SEASON_POSTERS = "show_season_posters_on_tabs"
        const val HIDE_SPOILERS = "hide_spoilers"
        const val SHOW_WATCHED_INDICATORS = "show_watched_indicators"
        const val TV_FULL_CARDS = "tv_full_card_layout"
        const val CONTINUE_WATCHING_ACTION = "continue_watching_action"
        const val EPISODE_ACTION = "episode_action"
        const val USE_GLOBAL_HUBS = "use_global_hubs"
        const val SHOW_SERVER_NAME = "show_server_name_on_hubs"
        const val SHOW_EXPLORE_TAB = "show_explore_tab"
        const val ALWAYS_KEEP_SIDEBAR_OPEN = "always_keep_sidebar_open"
        const val GROUP_LIBRARIES_BY_SERVER = "group_libraries_by_server"
        const val SHOW_NAV_BAR_LABELS = "show_nav_bar_labels"
        const val SHOW_UNWATCHED_COUNT = "show_unwatched_count"
        const val LIVE_TV_DEFAULT_FAVORITES = "live_tv_default_favorites"

        private fun visualEffectsLabel(effects: VisualEffects) = when (effects) {
            VisualEffects.AUTO -> T.settings.visualEffectsAuto
            VisualEffects.FULL -> T.settings.visualEffectsFull
            VisualEffects.REDUCED -> T.settings.visualEffectsReduced
        }

        private fun gridSpacingLabel(spacing: GridSpacing) = when (spacing) {
            GridSpacing.TIGHT -> T.settings.gridSpacingTight
            GridSpacing.NORMAL -> T.settings.gridSpacingNormal
            GridSpacing.SPACIOUS -> T.settings.gridSpacingSpacious
        }

        private fun episodePosterLabel(mode: EpisodePosterMode) = when (mode) {
            EpisodePosterMode.SERIES_POSTER -> T.settings.seriesPoster
            EpisodePosterMode.SEASON_POSTER -> T.settings.seasonPoster
            EpisodePosterMode.EPISODE_THUMBNAIL -> T.settings.episodeThumbnail
        }
    }
}
