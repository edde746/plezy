package com.edde746.plezy.settings

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.plex.PlexClient
import com.edde746.plezy.servers.WatchedThresholdSource
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch

/**
 * Each Plex server's watched threshold as its `/:/prefs` last said ([ServerSettings.watchedThreshold]), for marking
 * progress queued offline watched: [record] keeps a server's new value, [load] reads the stored ones once. Main-thread
 * confined; writes run in [scope].
 */
class ServerWatchedThresholds(
    private val settings: ServerSettingsRepository,
    private val scope: CoroutineScope,
) : WatchedThresholdSource {
    private val percents = HashMap<ServerId, Int>()

    /** Reads every stored threshold; one [record]ed meanwhile is newer and stays. */
    suspend fun load() {
        for ((serverId, percent) in settings.values(ServerSettings.watchedThreshold)) {
            ServerId.tryParse(serverId)?.let { percents.getOrPut(it) { percent } }
        }
    }

    /** [serverId]'s server now marks videos watched past [percent]; stored for the next start. */
    fun record(serverId: ServerId, percent: Int) {
        percents[serverId] = percent
        scope.launch { settings.set(serverId.value, ServerSettings.watchedThreshold, percent) }
    }

    override fun reportsServerThreshold(client: MediaBackend): Boolean = client is PlexClient && client.hasServerPrefs

    override fun cachedPercent(serverId: ServerId): Int? = percents[serverId]
}
