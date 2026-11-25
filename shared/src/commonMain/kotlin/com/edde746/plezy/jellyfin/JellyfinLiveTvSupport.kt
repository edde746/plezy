package com.edde746.plezy.jellyfin

import com.edde746.plezy.backend.MediaServerHttpErrorType
import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.backend.MediaServerTimeouts
import com.edde746.plezy.backend.PlaybackException
import com.edde746.plezy.backend.PlaybackFailureReason
import com.edde746.plezy.backend.TranscodeQualityPreset
import com.edde746.plezy.data.livetv.FavoriteChannel
import com.edde746.plezy.livetv.FavoriteChannelPersistenceMode
import com.edde746.plezy.livetv.LiveTvChannel
import com.edde746.plezy.livetv.LiveTvDvrSupport
import com.edde746.plezy.livetv.LiveTvPlaybackSession
import com.edde746.plezy.livetv.LiveTvProgram
import com.edde746.plezy.livetv.LiveTvSupport
import com.edde746.plezy.livetv.LiveTvWhatsOn
import com.edde746.plezy.log.Log
import com.edde746.plezy.net.UriComponent
import com.edde746.plezy.servers.OperationTimeoutException
import com.edde746.plezy.servers.timeoutReleasingLate
import com.edde746.plezy.strings.T
import kotlin.coroutines.cancellation.CancellationException
import kotlin.time.Instant
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject

/** What a live `PlaybackInfo` negotiation settled on: the URL to play and the identity its heartbeats carry. */
internal data class LiveStreamResolution(
    val url: String,
    val playSessionId: String?,
    val mediaSourceId: String?,
    val liveStreamId: String?,
    /** `DirectPlay`, `DirectStream` or `Transcode`, as the session reports it. */
    val playMethod: String,
)

/**
 * Live TV on a MediaBrowser server, Jellyfin or Emby: one flat channel list, a guide, recordings through the timer
 * adapter ([JellyfinLiveTvDvr]), favourites flagged on the server and ordered locally, and tuning by `PlaybackInfo`.
 *
 * Favourites live in the local store per connection (`{machineId}/{userId}`), which keeps the order and the display
 * fields; the server's per-user `IsFavorite` flag mirrors them on every write. [scope] runs what outlives a call: a
 * late tune's release and stream closes nobody waits for.
 */
internal class JellyfinLiveTvSupport(
    private val core: JellyfinCore,
    private val playback: JellyfinPlayback,
    private val setItemFavorite: suspend (itemId: String, isFavorite: Boolean) -> Unit,
    private val readFavorites: suspend (connectionId: String) -> List<FavoriteChannel>,
    private val writeFavorites: suspend (connectionId: String, channels: List<FavoriteChannel>) -> Unit,
    private val scope: CoroutineScope,
) : LiveTvSupport, LiveTvDvrSupport by JellyfinLiveTvDvr(core) {
    override val dvr: LiveTvDvrSupport get() = this
    override val whatsOn: LiveTvWhatsOn? get() = null

    private val productName: String get() = core.dialect.productName

    /** An int `TotalRecordCount` above 0, else a non-empty `Items`; anything else, failures included, is false. */
    override suspend fun isAvailable(): Boolean = try {
        val route = JellyfinLiveTvRoutes.availability(core.userId)
        val response = core.get(route.path, route.query)
        val data = response.obj
        val total = data?.int("TotalRecordCount")
        when {
            response.status != 200 || data == null -> false
            total != null -> total > 0
            else -> data.array("Items")?.isNotEmpty() ?: false
        }
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        Log.d(TAG, e) { "$productName Live TV probe failed" }
        false
    }

    /** One flat list; [lineup] is Plex's. */
    override suspend fun fetchChannels(lineup: String?): List<LiveTvChannel> {
        val route = JellyfinLiveTvRoutes.channels(core.userId)
        return core.itemsArray(core.get(route.path, route.query).throwIfError().data).map(::channelFromJson)
    }

    /**
     * The window goes out as `minEndDate`/`maxStartDate`, the overlap filter: `minStartDate` would drop the program
     * airing at the window's start. `fields=Overview` because neither dialect sends descriptions unasked.
     */
    override suspend fun fetchSchedule(from: Instant?, to: Instant?): List<LiveTvProgram> {
        val route = JellyfinLiveTvRoutes.programs(core.userId, minEndDate = from?.let(::isoUtc), maxStartDate = to?.let(::isoUtc))
        return core.itemsArray(core.get(route.path, route.query).throwIfError().data).map(::programFromJson)
    }

    override suspend fun startPlayback(channelKey: String, dvrKey: String?, quality: TranscodeQualityPreset): LiveTvPlaybackSession? {
        val resolution = resolveStream(channelKey, quality, forceTranscode = false) ?: return null
        return JellyfinLiveTvPlaybackSession(this, playback, channelKey, quality, resolution)
    }

    override suspend fun buildFavoriteChannelSource(lineup: String?): String = "server://${core.serverId}/jellyfin"

    override val favoriteStoreKey: String get() = "jellyfin:${core.connection.id}"

    override val favoritePersistenceMode: FavoriteChannelPersistenceMode get() = FavoriteChannelPersistenceMode.SERVER_SLICE

    /** The local list; the first-launch import already moved an earlier release's favourites into it, so [migrate] has nothing to do. */
    override suspend fun fetchFavoriteChannels(migrate: Boolean, checkCurrent: (() -> Unit)?): List<FavoriteChannel> {
        val favorites = readFavorites(core.connection.id)
        checkCurrent?.invoke()
        return favorites
    }

    /**
     * Flags additions and unflags removals on the server, then stores the confirmed projection: the requested order
     * for every id the server holds as favourite, followed by earlier favourites whose removal failed. The first
     * server failure is rethrown after that store; a failed baseline read stops before any request.
     */
    override suspend fun setFavoriteChannels(channels: List<FavoriteChannel>, checkCurrent: (() -> Unit)?) {
        checkCurrent?.invoke()
        val connectionId = core.connection.id
        val previous = readFavorites(connectionId)
        val previousIds = previous.mapTo(LinkedHashSet()) { it.id }
        val requestedIds = channels.mapTo(LinkedHashSet()) { it.id }
        val confirmedIds = LinkedHashSet(previousIds)
        var firstError: Exception? = null

        suspend fun mutate(id: String, isFavorite: Boolean) {
            checkCurrent?.invoke()
            try {
                setItemFavorite(id, isFavorite)
                if (isFavorite) confirmedIds += id else confirmedIds -= id
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                if (firstError == null) firstError = e
                Log.w(TAG, e) { "Failed to update a $productName favorite channel" }
            }
        }

        for (id in requestedIds - previousIds) mutate(id, true)
        for (id in previousIds - requestedIds) mutate(id, false)

        val confirmed = channels.filter { it.id in confirmedIds } + previous.filter { it.id !in requestedIds && it.id in confirmedIds }
        checkCurrent?.invoke()
        writeFavorites(connectionId, confirmed)
        firstError?.let { throw it }
    }

    /**
     * Negotiates [channelKey]'s stream, taking the first of: direct play (the server checks the source against the
     * ceiling, so it is asked for on every preset), an HLS `TranscodingUrl`, direct stream (Emby's answer for tuners it
     * will only remux, HDHomeRun among them). Direct ones play the server-proxied static stream. Neither: the live
     * stream the negotiation opened is closed and the result is null.
     *
     * The caller waits [MediaServerTimeouts.TUNE]; the request runs on to its transport budget, and a late answer's
     * live stream is closed, since the server opened the tuner whether or not anyone still listens.
     */
    internal suspend fun resolveStream(channelKey: String, quality: TranscodeQualityPreset, forceTranscode: Boolean): LiveStreamResolution? {
        val wantsDirect = !forceTranscode
        val info = try {
            timeoutReleasingLate(MediaServerTimeouts.TUNE, "$productName Live TV tune", scope, ::releaseLateNegotiation) {
                playback.getPlaybackInfo(
                    channelKey,
                    // An omitted ceiling reads as 8 Mbps server-side; Original asks for the 100 Mbps negotiation ceiling.
                    maxStreamingBitrate = if (quality.isOriginal) ORIGINAL_BITRATE else (quality.videoBitrateKbps ?: 100_000) * 1000L,
                    autoOpenLiveStream = true,
                    enableDirectPlay = wantsDirect,
                    enableDirectStream = wantsDirect,
                    enableTranscoding = true,
                    allowVideoStreamCopy = true,
                    allowAudioStreamCopy = true,
                    isLiveTv = true,
                )
            }
        } catch (e: OperationTimeoutException) {
            throw MediaServerHttpException(MediaServerHttpErrorType.CONNECTION_TIMEOUT, e.message.orEmpty(), cause = e)
        }
        val sources = info["MediaSources"] as JsonArray
        if (sources.isEmpty()) return null
        val source = sources.first() as? JsonObject
            ?: throw PlaybackException(T.liveTv.invalidPlaybackData(product = productName), PlaybackFailureReason.INVALID_PLAYBACK_DATA)

        var playSessionId = info.nonEmpty("PlaySessionId")
        var mediaSourceId = source.nonEmpty("Id")
        val liveStreamId = openedLiveStreamId(source)
        val container = source.nonEmpty("Container")

        fun direct(container: String, playMethod: String): LiveStreamResolution {
            val route = JellyfinLiveTvRoutes.directStream(channelKey, container, mediaSourceId, liveStreamId, core.connection.deviceId)
            val url = core.withApiKey(route.path + JellyfinCore.queryString(route.query))
            return LiveStreamResolution(url, playSessionId, mediaSourceId, liveStreamId, playMethod)
        }

        if (wantsDirect && container != null && source.bool("SupportsDirectPlay") == true) return direct(container, DIRECT_PLAY)

        val transcodingUrl = source.nonEmpty("TranscodingUrl")
        if (transcodingUrl != null && urlPath(transcodingUrl).lowercase().endsWith(".m3u8")) {
            val url = core.withApiKey(transcodingUrl)
            val query = JellyfinImageAbsolutizer.queryParams(url)
            playSessionId = playSessionId ?: query["PlaySessionId"]
            mediaSourceId = mediaSourceId ?: query["MediaSourceId"]
            return LiveStreamResolution(url, playSessionId, mediaSourceId, liveStreamId, TRANSCODE)
        }

        if (wantsDirect && container != null && source.bool("SupportsDirectStream") == true) return direct(container, DIRECT_STREAM)

        Log.w(TAG) { "$productName Live TV negotiation returned neither a direct nor an HLS stream" }
        liveStreamId?.let(::closeLiveStreamLater)
        return null
    }

    private suspend fun releaseLateNegotiation(info: JsonObject) {
        val source = (info["MediaSources"] as? JsonArray)?.firstOrNull() as? JsonObject ?: return
        val liveStreamId = openedLiveStreamId(source) ?: return
        Log.i(TAG) { "$productName Live TV tune answered after its caller gave up; closing its stream" }
        closeLiveStream(liveStreamId)
    }

    /**
     * Releases a session nothing adopted: a transcode's encoding is killed first (an encoding left to its idle timer
     * closes the stream itself, a second release), then the live stream is closed. Never a stop report: from 10.11 a
     * stop only closes a stream no other session plays, and it clears the device's now-playing entry.
     */
    internal suspend fun release(resolution: LiveStreamResolution) {
        val playSessionId = resolution.playSessionId
        if (resolution.playMethod == TRANSCODE && playSessionId != null) stopActiveEncodings(playSessionId)
        resolution.liveStreamId?.let { closeLiveStream(it) }
    }

    internal fun closeLiveStreamLater(liveStreamId: String) {
        scope.launch { closeLiveStream(liveStreamId) }
    }

    /** Best effort: a failure leaves the stream to the server's own reclaim. Queues behind opens, hence the tune budget. */
    private suspend fun closeLiveStream(liveStreamId: String) {
        try {
            val route = JellyfinLiveTvRoutes.closeLiveStream(liveStreamId)
            core.post(route.path, route.query, timeoutMillis = MediaServerTimeouts.TUNE_TRANSPORT.inWholeMilliseconds).throwIfError()
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "Failed to close a $productName live stream" }
        }
    }

    private suspend fun stopActiveEncodings(playSessionId: String) {
        try {
            val route = JellyfinLiveTvRoutes.activeEncodings(core.connection.deviceId, playSessionId)
            core.delete(route.path, route.query).throwIfError()
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "Failed to stop a $productName live transcode" }
        }
    }

    private fun channelFromJson(json: JsonObject): LiveTvChannel {
        val id = json.str("Id") ?: ""
        return LiveTvChannel(
            key = id,
            identifier = id,
            callSign = json.str("CallSign"),
            title = json.str("Name"),
            thumb = json.obj("ImageTags")?.str("Primary")?.let { primaryImage(id, it) },
            number = json.str("Number") ?: json.str("ChannelNumber"),
            serverId = core.serverId,
            serverName = core.connection.serverName,
        )
    }

    /**
     * A guide airing. The program id is also the recording seed (`/LiveTv/Timers/Defaults?programId=`). `TimerId` is
     * present only while the airing records; a `SeriesTimerId` alone means a series rule skips it, so the series key is
     * stamped only next to a timer.
     */
    private fun programFromJson(json: JsonObject): LiveTvProgram {
        val id = json.str("Id")
        val timerId = json.str("TimerId")?.takeIf { it.isNotEmpty() }
        val seriesTimerId = json.str("SeriesTimerId")?.takeIf { it.isNotEmpty() }
        return LiveTvProgram(
            key = id,
            ratingKey = id,
            guid = id,
            title = json.str("Name") ?: T.liveTv.unknownProgram,
            summary = json.str("Overview"),
            type = "episode",
            year = json.int("ProductionYear"),
            beginsAt = JellyfinTime.isoToEpochSeconds(json.str("StartDate")),
            endsAt = JellyfinTime.isoToEpochSeconds(json.str("EndDate")),
            grandparentTitle = json.str("SeriesName"),
            parentTitle = json.str("SeasonName"),
            index = json.int("IndexNumber"),
            parentIndex = json.int("ParentIndexNumber"),
            thumb = id?.let { itemId -> json.obj("ImageTags")?.str("Primary")?.let { primaryImage(itemId, it) } },
            channelIdentifier = json.str("ChannelId"),
            channelCallSign = json.str("ChannelCallSign") ?: json.str("ChannelName"),
            live = json.bool("IsLive"),
            premiere = json.bool("IsPremiere"),
            subscriptionId = timerId?.let { TIMER_RULE_PREFIX + it },
            grandparentSubscriptionId = if (timerId != null && seriesTimerId != null) SERIES_RULE_PREFIX + seriesTimerId else null,
            serverId = core.serverId,
            serverName = core.connection.serverName,
        )
    }

    private fun primaryImage(itemId: String, tag: String): String? =
        core.absolutizer.absolutize("/Items/${JellyfinCore.segment(itemId)}/Images/Primary?tag=${UriComponent.encode(tag)}")

    companion object {
        private const val TAG = "JellyfinLiveTv"
        private const val ORIGINAL_BITRATE = 100_000_000L
        const val DIRECT_PLAY = "DirectPlay"
        const val DIRECT_STREAM = "DirectStream"
        const val TRANSCODE = "Transcode"

        /** The live stream a negotiation opened: named on the source, else in its transcode URL. */
        private fun openedLiveStreamId(source: JsonObject): String? =
            source.nonEmpty("LiveStreamId")
                ?: source.str("TranscodingUrl")?.let { JellyfinImageAbsolutizer.queryParams(it)["LiveStreamId"] }?.takeIf { it.isNotEmpty() }

        private fun JsonObject.nonEmpty(key: String): String? = str(key)?.takeIf { it.isNotEmpty() }

        private fun urlPath(url: String): String = url.substringBefore('#').substringBefore('?')

        /** `2026-01-01T00:00:00.000Z`: whole seconds, the guide's window granularity. */
        private fun isoUtc(instant: Instant): String = Instant.fromEpochSeconds(instant.epochSeconds).toString().removeSuffix("Z") + ".000Z"
    }
}
