package com.edde746.plezy.presentation.navigation

import com.edde746.plezy.settings.StartupSection

/** Which top-level destinations show, and where the app starts. */
object NavigationTabs {
    /**
     * The destinations the chrome shows, in display order: Downloads only on a device that keeps them ([downloads]; never
     * the Apple TV), and offline only Downloads and Settings; Explore only while a catalog source is connected and the
     * Explore tab is on ([hasExplore]).
     */
    fun visible(offline: Boolean, hasExplore: Boolean, downloads: Boolean): List<TopLevelDestination> =
        TopLevelDestination.entries.filter {
            when {
                offline && it.onlineOnly -> false
                it == TopLevelDestination.DOWNLOADS -> downloads
                it == TopLevelDestination.EXPLORE -> hasExplore
                else -> true
            }
        }

    /** The destination to start on among [visible]: the [preferred] one while it shows, otherwise the first. */
    fun startup(visible: List<TopLevelDestination>, preferred: TopLevelDestination?): TopLevelDestination =
        preferred?.takeIf { it in visible } ?: visible.first()

    /** Where the startup section setting opens the app: Live TV is pushed over Home. */
    fun startupOf(section: StartupSection): Startup = when (section) {
        StartupSection.DISCOVER -> Startup(TopLevelDestination.HOME)
        StartupSection.LIBRARIES -> Startup(TopLevelDestination.LIBRARIES)
        StartupSection.LIVE_TV -> Startup.LIVE_TV
        StartupSection.EXPLORE -> Startup(TopLevelDestination.EXPLORE)
        StartupSection.SEARCH -> Startup(TopLevelDestination.SEARCH)
    }
}
