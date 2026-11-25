package com.edde746.plezy.trackers

import com.edde746.plezy.data.settings.DeviceSettingsRepository
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.settings.isLibraryAllowedForTracker

/**
 * The device-wide switches that decide whether a connected tracker gets a write: each service's scrobble toggle
 * ([AppSettings.scrobble], on by default), Trakt's separate watched-sync toggle ([AppSettings.enableTraktWatchedSync]),
 * and each service's library filter ([isLibraryAllowedForTracker]). A tracker also needs a connection, which the
 * coordinator checks. Read at each write, so a change applies to the next one.
 */
internal class TrackerGates(private val settings: DeviceSettingsRepository) {
    /** Whether [service] takes live playback reports: its scrobble toggle. */
    suspend fun reportsPlayback(service: TrackerService): Boolean = settings.value(AppSettings.scrobble(service))

    /**
     * Whether [service] takes watched and unwatched writes: Trakt's watched-sync toggle (its scrobble toggle covers only
     * live reports), every other service's scrobble toggle.
     */
    suspend fun writesWatched(service: TrackerService): Boolean =
        settings.value(if (service == TrackerService.TRAKT) AppSettings.enableTraktWatchedSync else AppSettings.scrobble(service))

    /** Whether [service]'s library filter lets writes about an item of [libraryGlobalKey] through. */
    suspend fun allowsLibrary(service: TrackerService, libraryGlobalKey: String?): Boolean =
        settings.isLibraryAllowedForTracker(service, libraryGlobalKey)
}
