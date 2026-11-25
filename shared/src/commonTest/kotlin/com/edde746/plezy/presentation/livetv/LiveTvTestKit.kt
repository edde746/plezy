package com.edde746.plezy.presentation.livetv

import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.data.livetv.FavoriteChannel
import com.edde746.plezy.livetv.FakeLiveTv
import com.edde746.plezy.livetv.LiveTvChannel
import com.edde746.plezy.livetv.LiveTvChannelGroup
import com.edde746.plezy.livetv.LiveTvProgram
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.servers.LiveTvServerEntry
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlin.time.Duration.Companion.minutes

/** A [LiveTvServers] over fixed clients; tests change [entries] as they go. */
class FakeLiveTvServers(override var entries: List<LiveTvServerEntry>, clients: List<MediaBackend>) : LiveTvServers {
    val clients = clients.associateBy { it.serverId }.toMutableMap()
    override fun client(serverId: ServerId): MediaBackend? = clients[serverId]
}

/** The tab stores [LiveTvStore] drives, recording what it asks of them. */
class FakeTabs(scope: CoroutineScope) {
    val foreground = MutableStateFlow(true)
    val guide = FakeGuideTab(gate(scope))
    val whatsOn = FakeWhatsOnTab(gate(scope))
    val recordings = FakeRecordingsTab(gate(scope))

    private fun gate(scope: CoroutineScope) = LiveTvRefreshGate(scope, 1.minutes, foreground, onTick = {})
}

class FakeGuideTab(override val refresh: LiveTvRefreshGate) : LiveTvGuideTab {
    var displayed: List<LiveTvChannel> = emptyList()
    var groups: List<LiveTvChannelGroup> = emptyList()
    var favoriteKeys: Set<String> = emptySet()
    val jumps = mutableListOf<String>()

    override fun setChannels(displayed: List<LiveTvChannel>, groups: List<LiveTvChannelGroup>, favoriteKeys: Set<String>) {
        this.displayed = displayed
        this.groups = groups
        this.favoriteKeys = favoriteKeys
    }

    override fun jumpToChannel(channel: LiveTvChannel) {
        jumps += "channel ${channel.key}"
    }

    override fun jumpToProgram(channel: LiveTvChannel, program: LiveTvProgram) {
        jumps += "program ${channel.key} ${program.ratingKey}"
    }
}

class FakeWhatsOnTab(override val refresh: LiveTvRefreshGate) : LiveTvWhatsOnTab {
    var received: List<LiveTvChannel> = emptyList()

    override fun setChannels(channels: List<LiveTvChannel>) {
        received = channels
    }
}

class FakeRecordingsTab(override val refresh: LiveTvRefreshGate) : LiveTvRecordingsTab {
    var reloads = 0

    override fun reload() {
        reloads++
    }
}

/**
 * One Live TV server's scripted [FakeLiveTv]: channels [channelKeys] titled "Unique Channel …", favourites read from
 * [favoriteReads] one deferred per read (complete the last), writes recorded in [writes] and failing with
 * [writeFailures] in turn.
 */
class ScreenLiveTv(
    val serverId: String = "server-a",
    storeKey: String = "test-store",
    var channelKeys: List<String> = listOf(if (serverId == "server-a") "channel-a" else "channel-$serverId"),
    hasDvr: Boolean = false,
) {
    val liveTv = FakeLiveTv(hasDvr = hasDvr, favoriteStoreKey = storeKey)
    val client = FakeMediaBackend(serverId, backend = BackendKind.JELLYFIN).also { it.liveTv = liveTv }
    var channelsFailure: Exception? = null
    val favoriteReads = mutableListOf<CompletableDeferred<List<FavoriteChannel>>>()
    val writes = mutableListOf<List<FavoriteChannel>>()
    val writeFailures = ArrayDeque<Exception>()

    val favorites: CompletableDeferred<List<FavoriteChannel>> get() = favoriteReads.last()

    init {
        liveTv.favoriteSource = { lineup -> "server://$serverId/${lineup ?: "default"}" }
        liveTv.channels = {
            channelsFailure?.let { throw it }
            channelKeys.map { key ->
                LiveTvChannel(key = key, title = if (key == "channel-a") "Unique Channel A" else "Unique Channel $key", serverId = serverId)
            }
        }
        liveTv.favorites = { CompletableDeferred<List<FavoriteChannel>>().also { favoriteReads += it }.await() }
        liveTv.saveFavorites = { channels ->
            writes += channels
            writeFailures.removeFirstOrNull()?.let { throw it }
        }
    }
}
