package com.edde746.plezy.livetv

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.servers.LiveTvServerEntry
import com.edde746.plezy.strings.T
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject

/** How the first tune treats a channel that already has recorded history (a recording or a running capture). */
enum class LiveTvStartPosition {
    /** Ask whether to start from the program's beginning or join live. */
    ASK,

    /** Start from the current program's beginning without asking. */
    BEGINNING,

    /** Join at the live edge without asking. */
    LIVE,
}

/**
 * What the player opens for a channel: the Live TV source that tunes it ([serverId], [dvrKey]), the [channel], every
 * channel zapping steps through ([channels], always holding [channel]), how the first tune starts, and the
 * [item] standing in for the channel in the media session and the player's metadata.
 */
data class LiveTvLaunch(
    val serverId: ServerId,
    val dvrKey: String,
    val channel: LiveTvChannel,
    val channels: List<LiveTvChannel>,
    val startPosition: LiveTvStartPosition,
    val item: MediaItem,
) {
    /** [channel]'s position in [channels]. */
    val channelIndex: Int get() = channels.indexOfFirst { it.scopeKey == channel.scopeKey }
}

/** A channel launch: the [LiveTvLaunch] to open, or the error to show instead. */
sealed interface LiveTvLaunchResult {
    data class Ready(val launch: LiveTvLaunch) : LiveTvLaunchResult

    data class Failed(val message: String) : LiveTvLaunchResult
}

/**
 * The Live TV source that tunes [channel]. A channel scoped to a server and DVR takes exactly that pair; one scoped to
 * a server only, any DVR on it; only an unscoped channel falls back to the first source.
 */
fun liveTvServerFor(servers: List<LiveTvServerEntry>, channel: LiveTvChannel): LiveTvServerEntry? {
    val serverId = channel.serverId ?: return servers.firstOrNull()
    val dvrKey = channel.liveDvrKey
    return servers.firstOrNull { it.serverId.value == serverId && (dvrKey == null || it.dvrKey == dvrKey) }
}

/**
 * The item standing in for a tuned channel: the launch and every zap describe the channel actually playing, with its
 * logo as artwork. [serverId] scopes a channel that carries no server of its own.
 */
fun liveTvChannelItem(channel: LiveTvChannel, backend: BackendKind, serverId: String? = null): MediaItem = MediaItem(
    id = channel.key,
    backend = backend,
    kind = MediaKind.CLIP,
    title = channel.displayName,
    serverId = serverId ?: channel.serverId,
    serverName = channel.serverName,
    thumbPath = channel.thumb ?: channel.art,
    raw = buildJsonObject { put("key", JsonPrimitive(channel.key)) },
)

/**
 * Opens [channel] among [channels]: resolves its source ([liveTvServerFor]) and that server's client, and puts
 * [channel] first in the list when the list lacks it. Fails with the snackbar text when no source or no connected
 * client serves it.
 */
fun liveTvLaunch(
    servers: List<LiveTvServerEntry>,
    client: (ServerId) -> MediaBackend?,
    channel: LiveTvChannel,
    channels: List<LiveTvChannel>,
    startPosition: LiveTvStartPosition = LiveTvStartPosition.ASK,
): LiveTvLaunchResult {
    val server = liveTvServerFor(servers, channel) ?: return LiveTvLaunchResult.Failed(T.liveTv.serverUnavailable)
    val backend = client(server.serverId) ?: return LiveTvLaunchResult.Failed(T.liveTv.serverNotConnected)
    val normalized = if (channels.any { it.scopeKey == channel.scopeKey }) {
        channels
    } else {
        Log.w(TAG) { "Launch channel ${channel.key} is not in the channel list; putting it first" }
        listOf(channel) + channels
    }
    return LiveTvLaunchResult.Ready(
        LiveTvLaunch(
            serverId = server.serverId,
            dvrKey = server.dvrKey,
            channel = channel,
            channels = normalized,
            startPosition = startPosition,
            item = liveTvChannelItem(channel, backend.backend, server.serverId.value),
        ),
    )
}

private const val TAG = "LiveTvLaunch"
