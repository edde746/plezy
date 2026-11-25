package com.edde746.plezy.livetv

import com.edde746.plezy.log.Log
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.servers.LiveTvServerEntry
import com.edde746.plezy.servers.MultiServerStore
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.withTimeoutOrNull
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds

/**
 * The channel a `plezy://live` link names ([com.edde746.plezy.links.DeepLink.Live], which reads and writes the link)
 * and how it starts: what Live TV tunes from a link.
 *
 * @param channel matched against the channel key, identifier, number and call sign ([selectChannel]).
 * @param serverId restricts the lookup to one server; without it every Live TV server is searched.
 * @param startPosition answers the watch-from-start prompt; [LiveTvStartPosition.ASK] shows it.
 */
data class LiveLink(
    val channel: String,
    val serverId: ServerId? = null,
    val startPosition: LiveTvStartPosition = LiveTvStartPosition.ASK,
) {
    /**
     * The channel this link names in [channels]: the first rule that matches exactly one channel wins (key, identifier,
     * number, call sign ignoring case). Null when nothing matches or a rule matches several channels.
     */
    fun selectChannel(channels: List<LiveTvChannel>): LiveTvChannel? {
        val wanted = channel.lowercase()
        val rules = listOf<(LiveTvChannel) -> Boolean>(
            { it.key == channel },
            { it.identifier == channel },
            { it.number == channel },
            { it.callSign?.lowercase() == wanted },
        )
        for (rule in rules) {
            val matches = channels.filter(rule)
            if (matches.size == 1) return matches.single()
            if (matches.size > 1) {
                Log.w(TAG) { "Channel \"$channel\" is ambiguous (${matches.size} matches)" }
                return null
            }
        }
        return null
    }

    /**
     * The launch this link asks for. The Live TV sources are [servers]' (only [serverId]'s when set); with none and the
     * app online, it waits up to [serverWait] for a server (that one) to connect and checks Live TV again. It loads the
     * channels of every source (a failing source is skipped) and picks [channel] among them ([selectChannel]). Fails
     * with "No Live TV" or "Channel not found".
     */
    suspend fun resolve(servers: MultiServerStore, isOffline: Boolean, serverWait: Duration = SERVER_WAIT): LiveTvLaunchResult {
        fun sources(): List<LiveTvServerEntry> = servers.state.value.liveTvServers.filter { serverId == null || it.serverId == serverId }
        var found = sources()
        if (found.isEmpty() && !isOffline) {
            // Live TV is known once a server has connected and been checked: right after a start that may be running.
            withTimeoutOrNull(serverWait) {
                servers.state.first { if (serverId == null) it.hasConnectedServers else it.isServerOnline(serverId) }
            }
            servers.checkLiveTvAvailability()
            found = sources()
        }
        if (found.isEmpty()) {
            Log.w(TAG) { "No Live TV server${serverId?.let { " $it" }.orEmpty()}" }
            return LiveTvLaunchResult.Failed(T.deepLinks.noLiveTv)
        }
        val channels = mutableListOf<LiveTvChannel>()
        for (source in found) {
            val client = servers.client(source.serverId) ?: continue
            try {
                client.liveTv.fetchChannels(source.lineup).mapTo(channels) { it.copy(serverId = source.serverId.value, liveDvrKey = source.dvrKey) }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "Channels of ${source.serverId} failed" }
            }
        }
        val match = selectChannel(channels)
        if (match == null) {
            Log.w(TAG) { "Channel \"$channel\" not found" }
            return LiveTvLaunchResult.Failed(T.deepLinks.channelNotFound(channel = channel))
        }
        return liveTvLaunch(servers.state.value.liveTvServers, servers::client, match, channels, startPosition)
    }

    companion object {
        /** How long a link waits for a server to connect. */
        val SERVER_WAIT: Duration = 20.seconds
        private const val TAG = "LiveLink"
    }
}
