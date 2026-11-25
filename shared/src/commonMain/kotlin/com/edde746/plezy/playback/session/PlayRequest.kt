package com.edde746.plezy.playback.session

import com.edde746.plezy.backend.AudioTrackPreference
import com.edde746.plezy.backend.SubtitlePreference
import com.edde746.plezy.backend.TranscodeQualityPreset
import com.edde746.plezy.livetv.LiveTvLaunch
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.model.buildGlobalKey
import com.edde746.plezy.presentation.livetv.LiveTvServers
import kotlin.time.Duration

/** What a play asks the app to open in its player ([com.edde746.plezy.app.AppSession.play]). */
sealed interface PlayRequest {
    /**
     * The key of what this plays across every server (`serverId:itemId`, [buildGlobalKey]), or null when it isn't a
     * server's item.
     */
    val globalKey: String?

    /**
     * A server's item: [itemId] on the server [serverId].
     *
     * @param item the item as the screen that played it has it already; null makes the session fetch it.
     * @param mediaIndex the version of the item to play, by its index in the item's versions.
     * @param mediaSourceId the version's id, which outranks [mediaIndex] where the server gives versions one (Jellyfin,
     *   Emby).
     * @param preferredVersionSignature the signature of the saved version preference [mediaIndex] came from, when the
     *   index isn't verified against the item's versions yet; null for a version the user picked.
     * @param strictMediaSelection [mediaIndex] or [mediaSourceId] must be played as it is: no fallback to another
     *   version when it isn't there.
     * @param qualityPreset the quality for this play; null plays at the saved default quality.
     * @param audioStreamId the server's audio stream the transcoder takes when [qualityPreset] transcodes; null takes the
     *   one the server has selected (else the first).
     * @param audioTrack / [subtitleTrack] / [secondarySubtitleTrack] the tracks the play starts on, carried from the
     *   player the user played it from (the next item of a queue); null lets the session choose.
     * @param startPosition where the play starts; null resumes at the item's saved position.
     * @param offline the play is of the item's download, without its server.
     * @param roomStart a watch-together room opens the file: it opens paused (the room starts it) at the room's speed,
     *   not the title's saved one.
     * @param showPlay the play is a show's Play of [item], its next (or first) episode, rather than of the episode on its
     *   own: the show's queue starts where the server's own client starts a show's
     *   ([com.edde746.plezy.playback.queue.EpisodeQueue.loadAdjacent]).
     */
    data class Item(
        val serverId: ServerId,
        val itemId: String,
        val item: MediaItem? = null,
        val mediaIndex: Int = 0,
        val mediaSourceId: String? = null,
        val preferredVersionSignature: String? = null,
        val strictMediaSelection: Boolean = false,
        val qualityPreset: TranscodeQualityPreset? = null,
        val audioStreamId: Int? = null,
        val audioTrack: AudioTrackPreference? = null,
        val subtitleTrack: SubtitlePreference? = null,
        val secondarySubtitleTrack: SubtitlePreference? = null,
        val startPosition: Duration? = null,
        val offline: Boolean = false,
        val roomStart: Boolean = false,
        val showPlay: Boolean = false,
    ) : PlayRequest {
        override val globalKey: String get() = buildGlobalKey(serverId, itemId)
    }

    /**
     * A Live TV channel, tuned on its server ([launch]); [servers] finds the server of a channel zapped to.
     */
    data class Live(val launch: LiveTvLaunch, val servers: LiveTvServers) : PlayRequest {
        override val globalKey: String? get() = null
    }

    /** A video at [url] (`http` or `https`), titled by its file name. */
    data class Url(val url: String) : PlayRequest {
        override val globalKey: String? get() = null
    }
}

/**
 * A file a [PlaybackSession] committed to its engine ([PlaybackSession.opened]): the [item], its version ([mediaIndex],
 * [mediaSourceId] where the server names versions) and whether it plays from this device ([offline], a download).
 * [serial] counts the session's opens, so a reload of the same file is a new value. [loadId] is the engine's load of
 * it ([com.edde746.plezy.playback.EngineState.loadId]) and [startMs] where in the item it opens: the engine reports
 * neither until it has the file.
 */
data class OpenedFile(
    val item: MediaItem,
    val mediaIndex: Int,
    val mediaSourceId: String?,
    val offline: Boolean,
    val serial: Int,
    val loadId: Long,
    val startMs: Long,
)
