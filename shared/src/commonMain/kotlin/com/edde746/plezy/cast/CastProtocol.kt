package com.edde746.plezy.cast

import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.music.MusicPlayContextKind
import com.edde746.plezy.presentation.cast.CastDeviceKind
import com.edde746.plezy.presentation.cast.CastMediaKind
import com.edde746.plezy.presentation.cast.CastOption
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json

/*
 * Casting's protocol, version 2. A receiver serves a WebSocket on `/cast` (TCP 48640, else a free port) and announces
 * itself over DNS-SD. The handshake is plain JSON text frames ([Handshake]); after it every message is a [CastMessage]
 * as JSON in an AES-256-GCM binary frame ([CastCrypto]).
 *
 * Handshake: the receiver says [Handshake.Hello]. A sender it paired with answers [Handshake.Auth]; one it doesn't know
 * gets [Handshake.Unknown] and may then pair: [Handshake.Pair] with its ECDH key, [Handshake.PairKey] with the
 * receiver's, both show the code, and the receiver's user decides. A wrong tag or a refusal gets [Handshake.Refused]
 * and the connection closes; acceptance is the first encrypted message, [CastMessage.Welcome].
 */

internal const val CAST_PROTOCOL_VERSION: Int = 2

internal const val CAST_PATH: String = "/cast"

internal val castJson = Json {
    ignoreUnknownKeys = true
    explicitNulls = false
}

/** A device as the handshake introduces it. */
@Serializable
data class CastPeerInfo(val id: String, val name: String, val platform: String, val kind: CastDeviceKind)

@Serializable
internal sealed interface Handshake {
    @Serializable
    @SerialName("hello")
    data class Hello(val v: Int, val device: CastPeerInfo, val nonce: String) : Handshake

    @Serializable
    @SerialName("auth")
    data class Auth(val device: CastPeerInfo, val nonce: String, val tag: String) : Handshake

    @Serializable
    @SerialName("unknown")
    data object Unknown : Handshake

    @Serializable
    @SerialName("pair")
    data class Pair(val device: CastPeerInfo, val nonce: String, val key: String) : Handshake

    @Serializable
    @SerialName("pairKey")
    data class PairKey(val key: String) : Handshake

    @Serializable
    @SerialName("refused")
    data object Refused : Handshake
}

/**
 * A server as the sender reaches it, handed over for one cast: its [kind], id, name and [baseUrls] in failover order,
 * and the per-server [token] the sender plays with (never the plex.tv account's). Jellyfin and Emby add the user and
 * the device id the token belongs to; Plex the sender's client identifier. The receiver keeps it in memory only.
 */
@Serializable
data class ServerAccess(
    val kind: BackendKind,
    val serverId: String,
    val name: String,
    val baseUrls: List<String>,
    val token: String,
    val userId: String? = null,
    val userName: String? = null,
    val deviceId: String? = null,
) {
    override fun toString(): String = "ServerAccess($kind, $serverId)"
}

/** What a cast plays, on the [ServerAccess]'s server. */
@Serializable
sealed interface CastItem {
    /**
     * A movie, an episode or another video; [startMs] null resumes at the saved position. Its version is [mediaIndex]
     * (and [mediaSourceId] where the server names its versions), played as it is when [strict]; a receiver older than
     * these fields plays the default version.
     */
    @Serializable
    @SerialName("video")
    data class Video(
        val itemId: String,
        val startMs: Long? = null,
        val mediaIndex: Int = 0,
        val mediaSourceId: String? = null,
        val strict: Boolean = false,
    ) : CastItem

    /** Music: [trackIds] in order, starting at [startIndex] ([startMs] into it), under [title] as [context]. */
    @Serializable
    @SerialName("music")
    data class Music(
        val trackIds: List<String>,
        val startIndex: Int,
        val title: String,
        val context: MusicPlayContextKind,
        val shuffle: Boolean = false,
        val startMs: Long? = null,
    ) : CastItem

    /** A Live TV channel of the Live TV source [dvrKey] (its [lineup] for Plex). */
    @Serializable
    @SerialName("live")
    data class Live(val dvrKey: String, val channelKey: String, val lineup: String? = null) : CastItem
}

/** A sender's control of what plays. Option keys are those of the last [CastState]. */
@Serializable
sealed interface CastCommand {
    @Serializable
    @SerialName("togglePause")
    data object TogglePause : CastCommand

    @Serializable
    @SerialName("seekTo")
    data class SeekTo(val ms: Long) : CastCommand

    @Serializable
    @SerialName("seekBy")
    data class SeekBy(val ms: Long) : CastCommand

    @Serializable
    @SerialName("audio")
    data class Audio(val key: String) : CastCommand

    @Serializable
    @SerialName("subtitle")
    data class Subtitle(val key: String) : CastCommand

    @Serializable
    @SerialName("quality")
    data class Quality(val key: String) : CastCommand

    @Serializable
    @SerialName("next")
    data object Next : CastCommand

    @Serializable
    @SerialName("previous")
    data object Previous : CastCommand

    @Serializable
    @SerialName("stop")
    data object Stop : CastCommand

    @Serializable
    @SerialName("volume")
    data class Volume(val percent: Int) : CastCommand
}

/**
 * What the receiver plays: sent on every change but the position's, and every second. [serverId] and [thumb] let a
 * sender with its own access to the server show the artwork; [from] is the sender that cast it.
 */
@Serializable
data class CastState(
    val kind: CastMediaKind,
    val title: String,
    val subtitle: String? = null,
    val serverId: String? = null,
    val thumb: String? = null,
    val paused: Boolean,
    val buffering: Boolean = false,
    val positionMs: Long,
    val durationMs: Long,
    val canSeek: Boolean,
    val audio: List<CastOption> = emptyList(),
    val subtitles: List<CastOption> = emptyList(),
    val qualities: List<CastOption> = emptyList(),
    val hasPrevious: Boolean = false,
    val hasNext: Boolean = false,
    val volume: Int? = null,
    val from: String,
)

/** Why a load failed on the receiver. */
enum class CastFailure { SERVER_UNREACHABLE, PLAYBACK_FAILED }

/** A message over an open link, either way. */
@Serializable
internal sealed interface CastMessage {
    /** The receiver accepted the sender: always the link's first message. */
    @Serializable
    @SerialName("welcome")
    data object Welcome : CastMessage

    /** Sender: play [item] with [access], replacing what plays. */
    @Serializable
    @SerialName("load")
    data class Load(val access: ServerAccess, val item: CastItem) : CastMessage

    @Serializable
    @SerialName("control")
    data class Control(val command: CastCommand) : CastMessage

    /** Receiver: what plays now; null for nothing. */
    @Serializable
    @SerialName("state")
    data class State(val state: CastState?) : CastMessage

    /** Receiver: the cast ended there (Back, Stop, the end of what played). */
    @Serializable
    @SerialName("ended")
    data object Ended : CastMessage

    /** Receiver: the sender's last load failed. */
    @Serializable
    @SerialName("failed")
    data class Failed(val failure: CastFailure) : CastMessage
}
