package com.edde746.plezy.trackers

import com.edde746.plezy.trackers.anilist.AnilistProvider
import com.edde746.plezy.trackers.mal.MalProvider
import com.edde746.plezy.trackers.mdblist.MdblistProvider
import com.edde746.plezy.trackers.simkl.SimklProvider
import com.edde746.plezy.trackers.trakt.TraktProvider
import io.ktor.client.HttpClient

/**
 * The services this build can connect, in [TrackerService] order: each one whose registration [config] carries.
 * Trakt, Simkl and MDBList need their client ids, MyAnimeList its client id (for refreshes) and the relay, AniList the
 * relay. A service left out is reported as unavailable, never half-offered. [appVersion] is what Simkl's identity
 * parameters and user agent name.
 */
fun trackerProviders(http: HttpClient, config: TrackerConfig, appVersion: String): List<TrackerProvider> = TrackerService.entries.mapNotNull { service ->
    val available = when (service) {
        TrackerService.TRAKT -> config.traktClientId.isNotBlank()
        TrackerService.SIMKL -> config.simklClientId.isNotBlank()
        TrackerService.MDBLIST -> config.mdblistClientId.isNotBlank()
        TrackerService.MYANIMELIST -> config.malClientId.isNotBlank() && config.relayBaseUrl.isNotBlank()
        TrackerService.ANILIST -> config.relayBaseUrl.isNotBlank()
    }
    if (!available) return@mapNotNull null
    when (service) {
        TrackerService.TRAKT -> TraktProvider(http, config.traktClientId, config.traktClientSecret, MAX_APP_ANSWER_BYTES)
        TrackerService.SIMKL -> SimklProvider(http, config.simklClientId, config.simklLegacyClientId, appVersion, MAX_APP_ANSWER_BYTES)
        TrackerService.MDBLIST -> MdblistProvider(http, config.mdblistClientId, MAX_APP_ANSWER_BYTES)
        TrackerService.MYANIMELIST -> MalProvider(http, config.malClientId, MAX_APP_ANSWER_BYTES)
        TrackerService.ANILIST -> AnilistProvider(http, MAX_APP_ANSWER_BYTES)
    }
}

/** The cap on one answer: 32 MiB, far above the longest list a service sends whole. */
const val MAX_APP_ANSWER_BYTES: Long = 32L * 1024 * 1024
