package com.edde746.plezy.plex

import com.edde746.plezy.backend.MediaServerTimeouts
import com.edde746.plezy.backend.RecordingConflictException
import com.edde746.plezy.backend.TranscodeQualityPreset
import com.edde746.plezy.backend.net.MediaServerResponse
import com.edde746.plezy.backend.net.encodeQueryParameters
import com.edde746.plezy.backend.net.throwIfHttpError
import com.edde746.plezy.data.livetv.FavoriteChannel
import com.edde746.plezy.livetv.FavoriteChannelPersistenceMode
import com.edde746.plezy.livetv.LiveTvChannel
import com.edde746.plezy.livetv.LiveTvDvr
import com.edde746.plezy.livetv.LiveTvDvrSupport
import com.edde746.plezy.livetv.LiveTvHub
import com.edde746.plezy.livetv.LiveTvHubEntry
import com.edde746.plezy.livetv.LiveTvPlaybackSession
import com.edde746.plezy.livetv.LiveTvProgram
import com.edde746.plezy.livetv.LiveTvSupport
import com.edde746.plezy.livetv.LiveTvWhatsOn
import com.edde746.plezy.livetv.MediaGrabOperation
import com.edde746.plezy.livetv.MediaSubscription
import com.edde746.plezy.livetv.MediaSubscriptionCreateRequest
import com.edde746.plezy.livetv.SubscriptionTemplate
import com.edde746.plezy.livetv.favoriteChannelFromJson
import com.edde746.plezy.livetv.toJson
import com.edde746.plezy.log.Log
import com.edde746.plezy.strings.T
import kotlin.time.Instant
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject

private const val TAG = "PlexLiveTv"
private const val FAVORITE_CHANNELS_URL = "https://epg.provider.plex.tv/settings/favoriteChannels"
private const val DEFAULT_EPG_PROVIDER = "tv.plex.provider.epg"

/** Plex's cloud guides; their channels come from the server-wide `/lineups/plex/channels` first. */
private const val CLOUD_EPG_PREFIX = "tv.plex.providers.epg"

/**
 * Plex's Live TV: the EPG providers `/media/providers` advertised ([PlexClient.providers]), the DVRs under
 * `/livetv/dvrs`, recording rules under `/media/subscriptions`, and favourites on plex.tv (one list per account).
 * Tunes run in [scope], which outlives a caller that stops waiting so a late tune can still be released.
 */
internal class PlexLiveTvSupport(
    private val client: PlexClient,
    private val scope: CoroutineScope = client.scope,
) : LiveTvSupport, LiveTvDvrSupport, LiveTvWhatsOn {
    override val dvr: LiveTvDvrSupport get() = this
    override val whatsOn: LiveTvWhatsOn get() = this

    /** Whether the server has at least one DVR. */
    override suspend fun isAvailable(): Boolean = try {
        fetchDvrs().isNotEmpty()
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        Log.w(TAG, e) { "DVR probe failed" }
        false
    }

    /**
     * The channels of each EPG provider matching [lineup] (every provider when none matches), from `Channel` or
     * `Metadata` rows with a key. A cloud guide reads `/lineups/plex/channels` first and falls back to
     * `/{provider}/lineups/dvr/channels`; a provider that fails contributes nothing.
     */
    override suspend fun fetchChannels(lineup: String?): List<LiveTvChannel> {
        val channels = mutableListOf<LiveTvChannel>()
        for (provider in providersForLineup(lineup)) {
            val legacyEndpoint = "/${provider.identifier}/lineups/dvr/channels"
            if (provider.identifier.startsWith(CLOUD_EPG_PREFIX)) {
                val cloud = try {
                    channelsFrom("/lineups/plex/channels")
                } catch (e: CancellationException) {
                    throw e
                } catch (e: Exception) {
                    Log.d(TAG, e) { "Cloud channel endpoint unavailable, falling back to $legacyEndpoint" }
                    emptyList()
                }
                if (cloud.isNotEmpty()) {
                    channels += cloud
                    continue
                }
            }
            try {
                channels += channelsFrom(legacyEndpoint)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.e(TAG, e) { "Failed to get EPG channels from ${provider.identifier} via $legacyEndpoint" }
            }
        }
        return channels
    }

    private suspend fun channelsFrom(path: String): List<LiveTvChannel> =
        client.getWithFailover(path).containerRows("Channel", "Metadata")
            .map { LiveTvChannel.fromJson(it).copy(serverId = client.serverId.value, serverName = client.serverName) }
            .filter { it.key.isNotEmpty() }

    /**
     * Every provider's airings from its grid endpoint (`endsAt>` [from], `beginsAt<` [to]): the `Metadata` rows and
     * those nested in `Hub` rows. A provider that fails contributes nothing.
     */
    override suspend fun fetchSchedule(from: Instant?, to: Instant?): List<LiveTvProgram> {
        val query = buildMap<String, Any?> {
            if (from != null) put("endsAt>", from.epochSeconds)
            if (to != null) put("beginsAt<", to.epochSeconds)
        }
        val programs = mutableListOf<LiveTvProgram>()
        for (provider in client.providers.epg) {
            try {
                val container = client.getWithFailover(provider.gridEndpoint, query).data.mediaContainer() ?: continue
                programs += parsePrograms(container["Metadata"], provider.identifier)
                for (hub in container["Hub"].objectList()) programs += parsePrograms(hub["Metadata"], provider.identifier)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.e(TAG, e) { "Failed to get EPG grid from ${provider.identifier}" }
            }
        }
        return programs
    }

    /** One program per row; a row whose `Media` lists several back-to-back airings gives one program per airing. */
    private fun parsePrograms(rows: JsonElement?, providerIdentifier: String): List<LiveTvProgram> = rows.objectList().flatMap { row ->
        val airings = row["Media"].objectList()
        val programs = if (airings.size > 1) airings.map { LiveTvProgram.fromJson(row, mediaOverride = it) } else listOf(LiveTvProgram.fromJson(row))
        programs.map { it.copy(serverId = client.serverId.value, serverName = client.serverName, providerIdentifier = providerIdentifier) }
    }

    /** Plex tunes through a DVR: without [dvrKey] there is nothing to tune. */
    override suspend fun startPlayback(channelKey: String, dvrKey: String?, quality: TranscodeQualityPreset): LiveTvPlaybackSession? {
        if (dvrKey == null) {
            Log.w(TAG) { "Plex live playback requires a dvrKey to tune $channelKey" }
            return null
        }
        return PlexLiveTvPlaybackSession.start(client, scope, dvrKey, channelKey, quality, directStream = true, directStreamAudio = true)
    }

    /** `server://{machineId}/{provider}` for the first provider matching [lineup]. */
    override suspend fun buildFavoriteChannelSource(lineup: String?): String {
        val provider = providersForLineup(lineup).firstOrNull()?.identifier ?: DEFAULT_EPG_PROVIDER
        return "server://${client.config.machineIdentifier ?: client.serverId.value}/$provider"
    }

    /** The plex.tv account's list: the client identifier is shared by every account on the device. */
    override val favoriteStoreKey: String get() = "plex:${client.plexAccountId ?: client.config.clientIdentifier}"

    override val favoritePersistenceMode: FavoriteChannelPersistenceMode get() = FavoriteChannelPersistenceMode.SHARED_FULL_LIST

    /**
     * The account's plex.tv favourites. Never fails the media server over: plex.tv's health says nothing about the
     * server's endpoints. A missing container or a non-list `FavoriteChannel` throws; a missing list is empty.
     */
    override suspend fun fetchFavoriteChannels(migrate: Boolean, checkCurrent: (() -> Unit)?): List<FavoriteChannel> {
        val response = client.http.get(FAVORITE_CHANNELS_URL, headers = plexTvHeaders(), allowEndpointFailover = false)
        throwIfHttpError(response)
        val container = response.data.mediaContainer() ?: error("Plex favorite-channel response is missing MediaContainer")
        val rows = container["FavoriteChannel"]
        if (rows == null || rows is JsonNull) return emptyList()
        if (rows !is JsonArray) error("Plex FavoriteChannel must be a list")
        return rows.map { favoriteChannelFromJson(it as? JsonObject ?: error("Plex FavoriteChannel rows must be objects")) }
    }

    /** Replaces the account's plex.tv list with [channels], sent as JSON. */
    override suspend fun setFavoriteChannels(channels: List<FavoriteChannel>, checkCurrent: (() -> Unit)?) {
        checkCurrent?.invoke()
        throwIfHttpError(client.http.put(FAVORITE_CHANNELS_URL, headers = plexTvHeaders(), body = JsonArray(channels.map { it.toJson() })))
    }

    /** plex.tv's provider API takes the account's token, never a Home user's server token, when the client has one. */
    private fun plexTvHeaders(): Map<String, String> = buildMap {
        put("X-Plex-Provider-Version", "5.1")
        client.plexAccountToken?.let { put("X-Plex-Token", it) }
    }

    /** `GET /livetv/dvrs`: each `Dvr` inherits the root `ChannelMapping` when it has none of its own. */
    override suspend fun fetchDvrs(): List<LiveTvDvr> {
        val container = client.getWithFailover("/livetv/dvrs").data.mediaContainer() ?: return emptyList()
        val rootMappings = container["ChannelMapping"]
        return container["Dvr"].objectList().map { dvr ->
            val ownMappings = dvr["ChannelMapping"]
            LiveTvDvr.fromJson(if ((ownMappings == null || ownMappings is JsonNull) && rootMappings != null) JsonObject(dvr + ("ChannelMapping" to rootMappings)) else dvr)
        }
    }

    override suspend fun reloadGuide(dvrId: String) {
        throwIfHttpError(client.http.post("/livetv/dvrs/$dvrId/reloadGuide", timeout = MediaServerTimeouts.RECEIVE, allowEndpointFailover = false))
    }

    override suspend fun getSubscriptionTemplate(guid: String): List<SubscriptionTemplate> =
        client.getWithFailover("/media/subscriptions/template", mapOf("guid" to guid)).containerRows("SubscriptionTemplate").map(SubscriptionTemplate::fromJson)

    override suspend fun fetchRecordingRules(includeGrabs: Boolean, includeStorage: Boolean): List<MediaSubscription> =
        client.getWithFailover(
            "/media/subscriptions",
            mapOf("includeGrabs" to if (includeGrabs) 1 else 0, "includeStorage" to if (includeStorage) 1 else 0),
        ).containerRows("MediaSubscription").map(MediaSubscription::fromJson)

    /**
     * `POST /media/subscriptions` with everything in the query: the template's already-encoded parameters, then the
     * target section and location, the type and each pref as `prefs[{id}]`. A 409 is [RecordingConflictException].
     */
    override suspend fun createRecordingRule(request: MediaSubscriptionCreateRequest): MediaSubscription? {
        val flat = buildMap<String, Any?> {
            put("targetLibrarySectionID", request.targetLibrarySectionId)
            put("targetSectionLocationID", request.targetSectionLocationId)
            put("type", request.type)
            for ((id, value) in request.prefs) put("prefs[$id]", value)
        }
        val query = listOfNotNull(request.parameters?.takeIf { it.isNotEmpty() }, encodeQueryParameters(flat).takeIf { it.isNotEmpty() })
            .joinToString("&")
        val path = if (query.isEmpty()) "/media/subscriptions" else "/media/subscriptions?$query"
        val response = client.http.post(path, allowEndpointFailover = false)
        if (response.statusCode == 409) throw RecordingConflictException("Recording already scheduled")
        throwIfHttpError(response)
        return response.containerRows("MediaSubscription").firstOrNull()?.let(MediaSubscription::fromJson)
    }

    /** `PUT /media/subscriptions/{id}?prefs[{id}]=…`. */
    override suspend fun updateRecordingRule(subscriptionId: String, prefs: Map<String, Any?>, checkCurrent: (() -> Unit)?): MediaSubscription? {
        checkCurrent?.invoke()
        val response = client.http.put("/media/subscriptions/$subscriptionId", prefs.mapKeys { (id, _) -> "prefs[$id]" })
        throwIfHttpError(response)
        return response.containerRows("MediaSubscription").firstOrNull()?.let(MediaSubscription::fromJson)
    }

    override suspend fun deleteRecordingRule(subscriptionId: String) {
        throwIfHttpError(client.http.delete("/media/subscriptions/$subscriptionId"))
    }

    override val supportsRuleProcessing: Boolean get() = true

    override suspend fun processRecordingRules() {
        throwIfHttpError(client.http.post("/media/subscriptions/process", allowEndpointFailover = false))
    }

    override suspend fun fetchScheduledRecordings(): List<MediaGrabOperation> =
        client.getWithFailover("/media/subscriptions/scheduled").containerRows("MediaGrabOperation").map(MediaGrabOperation::fromJson)

    /** Deletes a grab by id or by its `/media/grabbers/operations/…` key. */
    override suspend fun cancelGrab(operationId: String) {
        require(operationId.isNotEmpty()) { "operationId must not be empty" }
        val path = when {
            operationId.startsWith("/media/grabbers/operations/") -> operationId
            operationId.startsWith("media/grabbers/operations/") -> "/$operationId"
            else -> "/media/grabbers/operations/$operationId"
        }
        throwIfHttpError(client.http.delete(path))
    }

    /**
     * The rules covering [ratingKeys]. The route is mounted under the provider's numeric id from `/media/providers` (the
     * identifier form answers 404); an unknown provider uses [providerId] as is.
     */
    override suspend fun fetchSubscriptionMapping(providerId: String, ratingKeys: List<String>, includeStorage: Boolean): List<MediaSubscription> {
        if (ratingKeys.isEmpty()) return emptyList()
        val numericId = client.providers.epg.firstOrNull { it.identifier == providerId }?.id
        return client.getWithFailover(
            "/media/providers/${numericId ?: providerId}/media/subscriptions/mapping/${ratingKeys.joinToString(",")}",
            mapOf("includeStorage" to if (includeStorage) 1 else 0),
        ).containerRows("MediaSubscription").map(MediaSubscription::fromJson)
    }

    /** Every provider's `/{provider}/hubs/discover` hubs with at least one item. A provider that fails contributes nothing. */
    override suspend fun fetchHubs(count: Int): List<LiveTvHub> {
        val hubs = mutableListOf<LiveTvHub>()
        for (provider in client.providers.epg) {
            try {
                val response = client.getWithFailover(
                    "/${provider.identifier}/hubs/discover",
                    mapOf("count" to count, "includeStations" to 1, "includeRecentChannels" to 1, "includeMeta" to 1, "includeExternalMetadata" to 1),
                )
                response.containerRows("Hub").mapNotNullTo(hubs) { parseHub(it, provider.identifier) }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.e(TAG, e) { "Failed to get live TV hubs from ${provider.identifier}" }
            }
        }
        return hubs
    }

    private fun parseHub(hub: JsonObject, providerIdentifier: String): LiveTvHub? {
        val entries = hub["Metadata"].objectList().map { row ->
            val item = withLiveTvImages(row)
            LiveTvHubEntry(
                metadata = PlexMappers.mediaItem(item, client.serverId, client.serverName),
                program = LiveTvProgram.fromJson(item)
                    .copy(serverId = client.serverId.value, serverName = client.serverName, providerIdentifier = providerIdentifier),
            )
        }
        if (entries.isEmpty()) return null
        return LiveTvHub(title = hub["title"].stringOrNull() ?: T.liveTv.unknownHub, hubKey = hub["key"].stringOrNull() ?: "", entries = entries)
    }

    private fun providersForLineup(lineup: String?): List<PlexEpgProvider> {
        val epg = client.providers.epg
        if (lineup.isNullOrEmpty()) return epg
        return epg.filter { it.identifier == lineup || lineup in it.gridEndpoint }.ifEmpty { epg }
    }
}

/**
 * EPG items often carry their artwork only in `Image[]`: `coverPoster` always becomes the thumb, `coverArt` or
 * `background` the art when the row has none.
 */
private fun withLiveTvImages(row: JsonObject): JsonObject {
    val images = row["Image"].objectList()
    if (images.isEmpty()) return row
    val fields = row.toMutableMap()
    for (image in images) {
        val url = image["url"]?.takeIf { it.stringOrNull() != null } ?: continue
        when (image["type"].stringOrNull()) {
            "coverPoster" -> fields["thumb"] = url
            "coverArt", "background" -> if (fields["art"] == null || fields["art"] is JsonNull) fields["art"] = url
        }
    }
    return JsonObject(fields)
}

/** The object rows under the first of [keys] the container holds. */
private fun MediaServerResponse.containerRows(vararg keys: String): List<JsonObject> {
    val container = data.mediaContainer() ?: return emptyList()
    val key = keys.firstOrNull { container[it] != null && container[it] !is JsonNull } ?: return emptyList()
    return container[key].objectList()
}
