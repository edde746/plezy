package com.edde746.plezy.livetv

import com.edde746.plezy.data.livetv.FavoriteChannel
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.flexibleBool
import com.edde746.plezy.model.flexibleBoolNullable
import com.edde746.plezy.model.flexibleDouble
import com.edde746.plezy.model.flexibleInt
import com.edde746.plezy.model.flexibleLong
import com.edde746.plezy.model.firstFlexibleMap
import com.edde746.plezy.model.parseFlexibleJsonList
import com.edde746.plezy.model.readStringField
import com.edde746.plezy.strings.T
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlin.math.roundToLong

/**
 * A Live TV channel. [key] tunes it and matches guide airings; the server, DVR and favourite fields are stamped by the
 * code that loads it, never by the server's JSON.
 */
data class LiveTvChannel(
    val key: String,
    val identifier: String? = null,
    val callSign: String? = null,
    val title: String? = null,
    val thumb: String? = null,
    val art: String? = null,
    val number: String? = null,
    val hd: Boolean = false,
    val lineup: String? = null,
    val slug: String? = null,
    val drm: Boolean? = null,
    val serverId: String? = null,
    val serverName: String? = null,
    /** The DVR (Plex) or synthesized Live TV entry (Jellyfin, Emby: the server id) the channel was loaded through. */
    val liveDvrKey: String? = null,
    /** The guide source's title for group headers: the DVR's lineup title. */
    val liveTvSourceTitle: String? = null,
    /** The favourites source the channel belongs to (`server://{id}/{provider}`). */
    val favoriteSource: String? = null,
    /** The favourites store the channel's favourite lives in ([LiveTvSupport.favoriteStoreKey]). */
    val favoriteStoreKey: String? = null,
) {
    val displayName: String
        get() = callSign ?: title ?: number?.let { T.liveTv.channelNumber(number = it) } ?: T.liveTv.unknownChannel

    companion object {
        /**
         * A channel row: `key` falls back through ratingKey, identifier, id and channelIdentifier; `title` to callSign;
         * `number` through channelNumber, channelVcn and vcn (numbers printed).
         */
        fun fromJson(json: JsonObject): LiveTvChannel = LiveTvChannel(
            key = json.string("key") ?: json.string("ratingKey") ?: json.string("identifier") ?: json.string("id")
                ?: json.string("channelIdentifier") ?: "",
            identifier = json.string("identifier") ?: json.string("id") ?: json.string("channelIdentifier"),
            callSign = json.string("callSign"),
            title = json.string("title") ?: json.string("callSign"),
            thumb = json.string("thumb"),
            art = json.string("art"),
            number = json.string("number") ?: json.string("channelNumber") ?: readStringField(json, "channelVcn")
                ?: readStringField(json, "vcn"),
            hd = flexibleBool(json["hd"]),
            lineup = json.string("lineup"),
            slug = json.string("slug"),
            drm = json["drm"]?.let { flexibleBool(it) },
        )
    }
}

/** A favourite's identity: `{source}\0{id}`. */
fun favoriteChannelKey(source: String, id: String): String = "$source\u0000$id"

val FavoriteChannel.stableKey: String get() = favoriteChannelKey(source, id)

/** The favourite row the stores persist (`title`, `thumb`, `vcn` only when present). */
fun FavoriteChannel.toJson(): JsonObject = buildJsonObject {
    put("source", JsonPrimitive(source))
    put("id", JsonPrimitive(id))
    title?.let { put("title", JsonPrimitive(it)) }
    thumb?.let { put("thumb", JsonPrimitive(it)) }
    vcn?.let { put("vcn", JsonPrimitive(it)) }
}

/** A favourite row read from a store: `id` falls back to `key`, a missing source is empty. */
fun favoriteChannelFromJson(json: JsonObject): FavoriteChannel = FavoriteChannel(
    source = json.string("source") ?: "",
    id = json.string("id") ?: json.string("key") ?: "",
    title = json.string("title"),
    thumb = json.string("thumb"),
    vcn = json.string("vcn"),
)

/** The favourite of [channel] on [source]. */
fun favoriteChannelOf(channel: LiveTvChannel, source: String): FavoriteChannel =
    FavoriteChannel(source = source, id = channel.key, title = channel.title ?: channel.callSign, thumb = channel.thumb, vcn = channel.number)

/** A channel's identity across servers and DVRs: `{serverId}\0{dvrKey}\0{key}`. */
val LiveTvChannel.scopeKey: String get() = "${serverId.orEmpty()}\u0000${liveDvrKey.orEmpty()}\u0000$key"

/**
 * The channels the guide shows: all of them with the filter off or the favourites not loaded yet, none when the loaded
 * list is empty, else the favourites in their order mapped to loaded channels (a favourite no channel matches is
 * skipped).
 */
fun filterLiveTvChannelsForFavorites(
    channels: List<LiveTvChannel>,
    favoritesOnly: Boolean,
    favoritesLoaded: Boolean,
    favorites: Iterable<FavoriteChannel>,
    sourceForChannel: (LiveTvChannel) -> String,
): List<LiveTvChannel> {
    if (!favoritesOnly || !favoritesLoaded) return channels
    val list = favorites.toList()
    if (list.isEmpty()) return emptyList()
    val byKey = channels.associateBy { favoriteChannelKey(sourceForChannel(it), it.key) }
    return list.mapNotNull { byKey[it.stableKey] }
}

/**
 * One airing in the guide. Times are epoch seconds. The server, DVR and provider fields are stamped by the loader.
 */
data class LiveTvProgram(
    val key: String? = null,
    val ratingKey: String? = null,
    val guid: String? = null,
    val title: String,
    val summary: String? = null,
    val type: String? = null,
    val year: Int? = null,
    val beginsAt: Long? = null,
    val endsAt: Long? = null,
    /** The series name, for episodes. */
    val grandparentTitle: String? = null,
    val parentTitle: String? = null,
    /** The episode number. */
    val index: Int? = null,
    /** The season number. */
    val parentIndex: Int? = null,
    val thumb: String? = null,
    val art: String? = null,
    val channelIdentifier: String? = null,
    val channelCallSign: String? = null,
    val live: Boolean? = null,
    val premiere: Boolean? = null,
    val subscriptionId: String? = null,
    val grandparentSubscriptionId: String? = null,
    val serverId: String? = null,
    val serverName: String? = null,
    val liveDvrKey: String? = null,
    val providerIdentifier: String? = null,
) {
    /** The rule recording this airing: the series rule, else the airing's own. */
    val recordingRuleKey: String?
        get() = grandparentSubscriptionId?.trim()?.takeIf { it.isNotEmpty() } ?: subscriptionId?.trim()?.takeIf { it.isNotEmpty() }

    val durationMinutes: Int
        get() {
            val begins = beginsAt ?: return 0
            val ends = endsAt ?: return 0
            return ((ends - begins) / 60.0).roundToLong().toInt()
        }

    fun isAiringAt(nowEpochSeconds: Long): Boolean {
        val begins = beginsAt ?: return false
        val ends = endsAt ?: return false
        return nowEpochSeconds in begins until ends
    }

    /** `{show} - S{p}E{i} - {title}` (or `E{i}`) for an episode of a show, else the title. */
    val displayTitle: String
        get() {
            val show = grandparentTitle
            val episode = index
            if (show != null && episode != null) {
                val code = if (parentIndex != null) "S${parentIndex}E$episode" else "E$episode"
                return "$show - $code - $title"
            }
            return title
        }

    companion object {
        /**
         * An airing row. The first `Media` supplies times and channel fields the row lacks; with [mediaOverride] (one
         * airing of a multi-airing row) that Media wins over the row.
         */
        fun fromJson(json: JsonObject, mediaOverride: JsonObject? = null): LiveTvProgram {
            val pinned = mediaOverride != null
            val media = mediaOverride ?: firstFlexibleMap(json["Media"])
            val channel = firstFlexibleMap(json["Channel"])
            fun pickLong(name: String): Long? {
                val fromMedia = flexibleLong(media?.get(name))
                val fromJson = flexibleLong(json[name])
                return if (pinned) fromMedia ?: fromJson else fromJson ?: fromMedia
            }
            fun pickString(name: String): String? {
                val fromMedia = media?.let { readStringField(it, name) }
                val fromJson = json.string(name)
                return if (pinned) fromMedia ?: fromJson else fromJson ?: fromMedia
            }
            fun pickBool(name: String): Boolean? {
                val fromMedia = flexibleBoolNullable(media?.get(name))
                val fromJson = flexibleBoolNullable(json[name])
                return if (pinned) fromMedia ?: fromJson else fromJson ?: fromMedia
            }
            return LiveTvProgram(
                key = json.string("key"),
                ratingKey = json.string("ratingKey"),
                guid = json.string("guid"),
                title = json.string("title") ?: T.liveTv.unknownProgram,
                summary = json.string("summary"),
                type = json.string("type"),
                year = flexibleInt(json["year"]),
                beginsAt = pickLong("beginsAt"),
                endsAt = pickLong("endsAt"),
                grandparentTitle = json.string("grandparentTitle"),
                parentTitle = json.string("parentTitle"),
                index = flexibleInt(json["index"]),
                parentIndex = flexibleInt(json["parentIndex"]),
                thumb = json.string("thumb") ?: json.string("grandparentThumb"),
                art = json.string("art"),
                channelIdentifier = pickString("channelIdentifier") ?: channel?.let { readStringField(it, "id") },
                channelCallSign = pickString("channelCallSign"),
                live = flexibleBool(json["live"]),
                premiere = pickBool("premiere"),
                subscriptionId = readStringField(json, "subscriptionID"),
                grandparentSubscriptionId = readStringField(json, "grandparentSubscriptionID"),
            )
        }
    }
}

/** A Plex DVR: its lineup and which channels it maps. */
data class LiveTvDvr(
    val key: String,
    val lineup: String? = null,
    val lineupTitle: String? = null,
    val lineupUrl: String? = null,
    val channelMappings: List<ChannelMapping> = emptyList(),
) {
    companion object {
        fun fromJson(json: JsonObject): LiveTvDvr = LiveTvDvr(
            key = readStringField(json, "key") ?: "",
            lineup = json.string("lineup"),
            lineupTitle = json.string("lineupTitle"),
            lineupUrl = json.string("lineupURL"),
            channelMappings = parseFlexibleJsonList(json["ChannelMapping"], ChannelMapping::fromJson),
        )
    }
}

/** One DVR channel mapping; a non-string `channelKey` rejects the row. */
data class ChannelMapping(val channelKey: String? = null, val enabled: Boolean? = null) {
    companion object {
        fun fromJson(json: JsonObject): ChannelMapping =
            ChannelMapping(channelKey = json.strictString("channelKey"), enabled = json["enabled"]?.let { flexibleBool(it) })
    }
}

/**
 * A Plex `TranscodeSession` window: [startedAt] is the epoch (seconds) of offset 0, the seekable history runs from
 * [seekStartSeconds] to [seekEndSeconds] past it.
 */
data class CaptureBuffer(val startedAt: Double, val seekStartSeconds: Double, val seekEndSeconds: Double) {
    val seekableStartEpoch: Long get() = (startedAt + seekStartSeconds).roundToLong()
    val seekableEndEpoch: Long get() = (startedAt + seekEndSeconds).roundToLong()

    companion object {
        /** Null unless `timeStamp`, `minOffsetAvailable` and `maxOffsetAvailable` are all numbers. */
        fun fromTranscodeSession(session: JsonObject): CaptureBuffer? {
            val timeStamp = flexibleDouble(session["timeStamp"]) ?: return null
            val min = flexibleDouble(session["minOffsetAvailable"]) ?: return null
            val max = flexibleDouble(session["maxOffsetAvailable"]) ?: return null
            return CaptureBuffer(timeStamp, min, max)
        }
    }
}

/** A What's On row (Plex `/hubs/discover`). */
data class LiveTvHub(val title: String, val hubKey: String, val entries: List<LiveTvHubEntry>)

/** One What's On item: the card's [metadata] and the airing it stands for. */
data class LiveTvHubEntry(val metadata: MediaItem, val program: LiveTvProgram)

internal fun JsonObject.string(name: String): String? = (get(name) as? JsonPrimitive)?.takeIf { it.isString }?.content

/** A field that is a string when present: null when missing or null, any other value throws (the row is malformed). */
internal fun JsonObject.strictString(name: String): String? {
    val value = get(name)
    if (value == null || value is JsonNull) return null
    require(value is JsonPrimitive && value.isString) { "$name must be a string" }
    return value.content
}
