package com.edde746.plezy.plex

import com.edde746.plezy.crash.CrashCapture
import com.edde746.plezy.crash.CrashReport
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.DiscographyGroupKind
import com.edde746.plezy.model.MediaChapter
import com.edde746.plezy.model.MediaDisplayCriteria
import com.edde746.plezy.model.MediaHub
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaLibrary
import com.edde746.plezy.model.MediaMarker
import com.edde746.plezy.model.MediaPart
import com.edde746.plezy.model.MediaPartTimeline
import com.edde746.plezy.model.MediaPerson
import com.edde746.plezy.model.MediaPersonDetails
import com.edde746.plezy.model.MediaPlaylist
import com.edde746.plezy.model.MediaRatingSource
import com.edde746.plezy.model.MediaRole
import com.edde746.plezy.model.MediaSourceInfo
import com.edde746.plezy.model.MediaStream
import com.edde746.plezy.model.MediaStreamKind
import com.edde746.plezy.model.MediaVersion
import com.edde746.plezy.model.PersonCredit
import com.edde746.plezy.model.PlaybackExtras
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.model.classifyMediaDisplayColor
import com.edde746.plezy.playback.ChapterMarkerClassifier
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CancellationException
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import kotlin.time.Duration

private const val TAG = "PlexMappers"

/** Plex `Stream.streamType` codes. */
internal const val PLEX_STREAM_VIDEO = 1
internal const val PLEX_STREAM_AUDIO = 2
internal const val PLEX_STREAM_SUBTITLE = 3
internal const val PLEX_STREAM_LYRICS = 4

/** Shared suffix of the unmatched-agent guid schemes: `com.plexapp.agents.none://` and `tv.plex.agents.none://`. */
private const val UNMATCHED_AGENT_MARKER = "agents.none://"

/** Plex `tagType` of an actor (`Role`) and a `Director` tag. */
private const val ACTOR_TAG_TYPE = 6
private const val DIRECTOR_TAG_TYPE = 4

private val HINT_TOKEN = Regex("[a-z0-9]+")
private val URI_SCHEME = Regex("^([a-zA-Z][a-zA-Z0-9+.-]*):")

/**
 * A string field: null when absent or JSON null. Any other shape is malformed metadata and throws, so a hub drops that
 * row instead of mapping it half.
 */
internal fun JsonObject.plexString(key: String): String? {
    val value = get(key) ?: return null
    if (value is JsonNull) return null
    if (value is JsonPrimitive && value.isString) return value.content
    throw IllegalArgumentException("Plex field \"$key\" is not a string")
}

/** A scalar as trimmed text; blank and non-scalar values are null. */
internal fun JsonElement?.trimmedText(): String? = scalarString()?.trim()?.takeIf { it.isNotEmpty() }

/** A list field of objects: null when absent; a non-list or a non-object entry is malformed metadata. */
private fun JsonObject.strictObjectList(key: String): List<JsonObject>? {
    val value = get(key) ?: return null
    if (value is JsonNull) return null
    if (value !is JsonArray) throw IllegalArgumentException("Plex field \"$key\" is not a list")
    return value.map { it as? JsonObject ?: throw IllegalArgumentException("Plex field \"$key\" holds a non-object") }
}

/** The `tag` strings of a `[{tag: …}]` list (bare strings count too); null when the field is not a list. */
private fun JsonObject.tagList(key: String): List<String>? {
    val list = get(key) as? JsonArray ?: return null
    return list.mapNotNull { entry -> ((entry as? JsonObject)?.get("tag") ?: entry).stringOrNull() }
}

/** Mapping of Plex JSON to the backend-neutral model. Image paths stay server-relative; the client resolves them. */
object PlexMappers {
    /**
     * A `/library/metadata` row. `Image[]` clearLogo and backgroundSquare entries win over the top-level fields. A row
     * that doesn't map is reported to the crash reporter with what is safe to know about it (the backend, the row's
     * kind of data and how many fields it has: none of its values) and the error thrown on.
     */
    fun mediaItem(json: JsonObject, serverId: ServerId? = null, serverName: String? = null): MediaItem = try {
        mapMediaItem(json, serverId, serverName)
    } catch (e: IllegalArgumentException) {
        CrashCapture.capture(
            CrashReport(
                error = e,
                contexts = mapOf("plex_mapper" to mapOf("backend" to "plex", "dto" to "PlexMetadataDto", "topLevelFieldCount" to json.size)),
            ),
        )
        throw e
    }

    private fun mapMediaItem(json: JsonObject, serverId: ServerId?, serverName: String?): MediaItem {
        val kind = MediaKind.fromString(json.plexString("type"))
        var clearLogo: String? = null
        var backgroundSquare: String? = null
        for (image in (json["Image"] as? JsonArray).orEmpty()) {
            if (image !is JsonObject) continue
            val url = image.plexString("url") ?: continue
            when (image["type"].stringOrNull()) {
                "clearLogo" -> clearLogo = url
                "backgroundSquare" -> backgroundSquare = url
            }
        }
        val year = json["year"].flexInt()
        return MediaItem(
            id = json["ratingKey"].scalarString() ?: json["key"].scalarString() ?: "",
            backend = BackendKind.PLEX,
            kind = kind,
            guid = json.plexString("guid"),
            title = json.plexString("title"),
            titleSort = json.plexString("titleSort"),
            summary = json.plexString("summary"),
            tagline = json.plexString("tagline"),
            originalTitle = json.plexString("originalTitle"),
            editionTitle = json.plexString("editionTitle"),
            studio = json.plexString("studio"),
            // Plex keeps an ordinary track's release year on its album.
            year = if (kind == MediaKind.TRACK) year ?: json["parentYear"].flexInt() else year,
            originallyAvailableAt = json.plexString("originallyAvailableAt"),
            contentRating = json.plexString("contentRating"),
            parentId = json["parentRatingKey"].scalarString(),
            parentTitle = json.plexString("parentTitle"),
            parentThumbPath = json.plexString("parentThumb"),
            parentIndex = json["parentIndex"].flexInt(),
            index = json["index"].flexInt(),
            grandparentId = json["grandparentRatingKey"].scalarString(),
            grandparentTitle = json.plexString("grandparentTitle"),
            grandparentThumbPath = json.plexString("grandparentThumb"),
            grandparentArtPath = json.plexString("grandparentArt"),
            thumbPath = json.plexString("thumb"),
            artPath = json.plexString("art"),
            clearLogoPath = clearLogo ?: json.plexString("clearLogo"),
            backgroundSquarePath = backgroundSquare ?: json.plexString("backgroundSquare"),
            durationMs = json["duration"].flexLong(),
            viewOffsetMs = json["viewOffset"].flexLong(),
            viewCount = json["viewCount"].flexInt(),
            lastViewedAt = json["lastViewedAt"].flexLong(),
            leafCount = json["leafCount"].flexInt(),
            viewedLeafCount = if (kind.usesLeafWatchCounts) json["viewedLeafCount"].flexInt() else null,
            childCount = json["childCount"].flexInt(),
            addedAt = json["addedAt"].flexLong(),
            updatedAt = json["updatedAt"].flexLong(),
            rating = json["rating"].flexDouble(),
            userRating = json["userRating"].flexDouble(),
            ratings = plexRatingSources(json),
            genres = json.tagList("Genre"),
            directors = json.tagList("Director"),
            writers = json.tagList("Writer"),
            producers = json.tagList("Producer"),
            countries = json.tagList("Country"),
            collections = json.tagList("Collection"),
            labels = json.tagList("Label"),
            styles = json.tagList("Style"),
            moods = json.tagList("Mood"),
            roles = json.strictObjectList("Role")?.map(::role),
            mediaVersions = json.strictObjectList("Media")?.map(::mediaVersion),
            libraryId = json["librarySectionID"].flexInt()?.toString(),
            libraryTitle = json.plexString("librarySectionTitle"),
            trailerKey = json.plexString("primaryExtraKey"),
            playlistItemId = json["playlistItemID"].flexInt()?.toString(),
            playQueueItemId = json["playQueueItemID"].flexInt(),
            subtype = json.plexString("subtype"),
            serverId = serverId?.value,
            serverName = serverName,
            raw = rawMetadata(json),
        )
    }

    /** The season-display flags, folder key and playlist type a few readers need from the original row; null when it has none. */
    private fun rawMetadata(json: JsonObject): JsonObject? {
        val key = json.plexString("key")
        val skipChildren = json["skipChildren"].flexBoolOrNull()
        val flattenSeasons = json["flattenSeasons"].flexInt()
        val playlistType = json.plexString("playlistType")
        if (key == null && skipChildren == null && flattenSeasons == null && playlistType == null) return null
        return buildJsonObject {
            if (key != null) put("key", key)
            if (skipChildren != null) put("skipChildren", skipChildren)
            if (flattenSeasons != null) put("flattenSeasons", flattenSeasons)
            if (playlistType != null) put("playlistType", playlistType)
        }
    }

    /** An item with no guid, or one from a no-agent scheme, is unmatched. */
    fun isUnmatched(guid: String?): Boolean = guid.isNullOrEmpty() || UNMATCHED_AGENT_MARKER in guid

    /**
     * An album's release-format section: `Format` EP or Single, else `Subformat` live, else compilation, else albums.
     * Case-insensitive.
     */
    fun discographyKind(json: JsonObject): DiscographyGroupKind {
        fun hasTag(key: String, wanted: Set<String>) = json.tagList(key)?.any { it.lowercase() in wanted } == true
        return when {
            hasTag("Format", setOf("ep", "single")) -> DiscographyGroupKind.SINGLES_AND_EPS
            hasTag("Subformat", setOf("live")) -> DiscographyGroupKind.LIVE
            hasTag("Subformat", setOf("compilation")) -> DiscographyGroupKind.COMPILATIONS
            else -> DiscographyGroupKind.ALBUMS
        }
    }

    fun role(json: JsonObject): MediaRole = MediaRole(
        id = json["id"].flexInt()?.toString(),
        tag = json.plexString("tag") ?: throw IllegalArgumentException("Plex role without a tag"),
        role = json.plexString("role"),
        thumbPath = json.plexString("thumb"),
    )

    /**
     * One `Directory` row of a people search: an actor (`tagType` 6) or director (4) tag, else null. A person tag
     * without an id or name throws. [MediaPerson.thumbPath] keeps `thumb` verbatim (usually an absolute URL).
     */
    fun personFromSearchResultJson(json: JsonObject, serverId: ServerId, serverName: String? = null): MediaPerson? {
        if (json["type"].stringOrNull() != "tag") return null
        val credit = when (json["tagType"].flexInt()) {
            ACTOR_TAG_TYPE -> PersonCredit.ACTOR
            DIRECTOR_TAG_TYPE -> PersonCredit.DIRECTOR
            else -> return null
        }
        val id = json["id"].flexInt()
        val name = json["tag"].trimmedText()
        if (id == null || name == null) throw IllegalArgumentException("Plex person search row without id or name")
        return MediaPerson(
            id = id.toString(),
            name = name,
            backend = BackendKind.PLEX,
            serverId = serverId,
            thumbPath = json["thumb"].trimmedText(),
            credit = credit,
            serverName = serverName,
        )
    }

    /** The person row plex.tv answers with; an unknown person is an empty container, a null [json]. */
    fun personDetails(json: JsonObject?): MediaPersonDetails {
        if (json == null) return MediaPersonDetails.EMPTY
        return MediaPersonDetails(
            biography = json["summary"].trimmedText(),
            birthDate = MediaPersonDetails.parseDate(json["bornAt"].stringOrNull()),
            deathDate = MediaPersonDetails.parseDate(json["diedAt"].stringOrNull()),
            birthPlace = json["birthPlace"].trimmedText(),
        )
    }

    /**
     * A `Media` entry. The first part's id falls back to the media id, later ones to `"{id}:{i}"`; a version without
     * `Part` gets one synthesized part.
     */
    fun mediaVersion(json: JsonObject): MediaVersion {
        val id = (json["id"].flexInt() ?: 0).toString()
        val container = json["container"].scalarString()
        val parts = json["Part"].objectList().mapIndexed { i, part ->
            mediaPart(part, fallbackId = if (i == 0) id else "$id:$i", fallbackContainer = container, media = json)
        }
        return MediaVersion(
            id = id,
            width = json["width"].flexInt(),
            height = json["height"].flexInt(),
            videoResolution = json["videoResolution"].scalarString(),
            videoCodec = json["videoCodec"].scalarString(),
            bitrate = json["bitrate"].flexInt(),
            container = container,
            parts = parts.ifEmpty { listOf(MediaPart(id = id, streamPath = "", container = container)) },
        )
    }

    private fun mediaPart(json: JsonObject, fallbackId: String, fallbackContainer: String?, media: JsonObject) = MediaPart(
        id = json["id"].scalarString() ?: fallbackId,
        streamPath = json["key"].scalarString(),
        file = json["file"].scalarString(),
        sizeBytes = json["size"].flexLong(),
        container = json["container"].scalarString() ?: fallbackContainer,
        durationMs = json["duration"].flexLong(),
        accessible = json["accessible"].flexBoolOrNull(),
        exists = json["exists"].flexBoolOrNull(),
        streams = mediaStreams(json, media),
    )

    /**
     * `Part.Stream[]` video, audio and subtitle entries, then a stream synthesized from the `Media` roll-up for each
     * kind the part did not list (an HDR/DV video from `videoProfile`/title/file-name tokens, audio from
     * `audioCodec`/`audioChannels`).
     */
    private fun mediaStreams(part: JsonObject, media: JsonObject): List<MediaStream> {
        val result = ArrayList<MediaStream>()
        for (stream in part["Stream"].objectList()) {
            val kind = when (stream["streamType"].flexInt()) {
                PLEX_STREAM_VIDEO -> MediaStreamKind.VIDEO
                PLEX_STREAM_AUDIO -> MediaStreamKind.AUDIO
                PLEX_STREAM_SUBTITLE -> MediaStreamKind.SUBTITLE
                else -> continue
            }
            val isVideo = kind == MediaStreamKind.VIDEO
            val isDolbyVision = isVideo && isDolbyVision(stream)
            val isHdr = (isVideo && displayCriteria(media, stream)?.isHdr == true) || isDolbyVision
            result += MediaStream(
                id = stream["id"].scalarString() ?: result.size.toString(),
                kind = kind,
                index = stream["index"].flexInt(),
                codec = stream["codec"].scalarString(),
                language = stream["language"].scalarString(),
                languageCode = stream["languageCode"].scalarString(),
                title = stream["title"].scalarString(),
                displayTitle = stream["displayTitle"].scalarString() ?: stream["extendedDisplayTitle"].scalarString(),
                selected = stream["selected"].flexBool(),
                isDefault = stream["default"].flexBool(),
                channels = stream["channels"].flexInt(),
                frameRate = stream["frameRate"].flexDouble(),
                hdr = isHdr,
                dolbyVision = isDolbyVision,
                dolbyVisionProfile = if (isDolbyVision) stream["DOVIProfile"].flexInt() else null,
                forced = stream["forced"].flexBool(),
                sidecarPath = if (kind == MediaStreamKind.SUBTITLE) stream["key"].scalarString() else null,
            )
        }
        for (fallback in fallbackStreams(media, part)) {
            if (result.none { it.kind == fallback.kind }) result += fallback
        }
        return result
    }

    private fun fallbackStreams(media: JsonObject, part: JsonObject): List<MediaStream> {
        val hints = listOfNotNull(
            media["videoProfile"].scalarString(),
            media["displayTitle"].scalarString(),
            media["extendedDisplayTitle"].scalarString(),
            part["file"].scalarString(),
        ).joinToString(" ").lowercase().let { text -> HINT_TOKEN.findAll(text).map { it.value }.toSet() }
        val hasDolbyVision = "dv" in hints || "dovi" in hints || "dolbyvision" in hints
        val hasHdr = hasDolbyVision || "hdr" in hints || "hdr10" in hints || "hdr10plus" in hints || "hlg" in hints
        val mediaId = media["id"].scalarString()
        return buildList {
            if (hasHdr) {
                add(
                    MediaStream(
                        id = "${mediaId ?: "video"}:video",
                        kind = MediaStreamKind.VIDEO,
                        codec = media["videoCodec"].scalarString(),
                        hdr = true,
                        dolbyVision = hasDolbyVision,
                    ),
                )
            }
            val audioCodec = media["audioCodec"].scalarString()
            val audioChannels = media["audioChannels"].flexInt()
            if (!audioCodec.isNullOrEmpty() || audioChannels != null) {
                add(
                    MediaStream(
                        id = "${mediaId ?: "audio"}:audio",
                        kind = MediaStreamKind.AUDIO,
                        codec = audioCodec,
                        channels = audioChannels,
                        selected = true,
                    ),
                )
            }
        }
    }

    private fun isDolbyVision(stream: JsonObject): Boolean =
        (stream["DOVIProfile"].flexInt() ?: 0) > 0 || stream["DOVIPresent"].flexBool()

    /**
     * The display description of a video stream: its rate, dimensions (falling back to the [media]'s) and colour tags,
     * with tags the stream lacks filled from its classification (SDR when it names nothing and is not Dolby Vision).
     * Null when that says too little to describe the stream.
     */
    fun displayCriteria(media: JsonObject?, videoStream: JsonObject?): MediaDisplayCriteria? {
        if (videoStream == null) return null
        val doviProfile = videoStream["DOVIProfile"].flexInt()
        val doviCompatibilityId = videoStream["DOVIBLCompatID"].flexInt()
        val hasDolbyVision = (doviProfile ?: 0) > 0 || videoStream["DOVIPresent"].flexBool()
        val transfer = videoStream["colorTrc"].trimmedText()
        val primaries = videoStream["colorPrimaries"].trimmedText()
        val matrix = videoStream["colorSpace"].trimmedText()
        val defaults = classifyMediaDisplayColor(
            isDolbyVision = hasDolbyVision,
            doviCompatibilityId = doviCompatibilityId,
            transfer = transfer,
            primaries = primaries,
            matrix = matrix,
            assumeSdr = !hasDolbyVision,
        ).defaultTags
        val criteria = MediaDisplayCriteria(
            fps = videoStream["frameRate"].flexDouble(),
            width = videoStream["width"].flexInt() ?: media?.get("width").flexInt(),
            height = videoStream["height"].flexInt() ?: media?.get("height").flexInt(),
            doviProfile = doviProfile,
            doviLevel = videoStream["DOVILevel"].flexInt(),
            doviCompatibilityId = doviCompatibilityId,
            transfer = transfer ?: defaults.transfer,
            primaries = primaries ?: defaults.primaries,
            matrix = matrix ?: defaults.matrix,
        )
        return criteria.takeIf { it.isUsable }
    }

    /** A library section. Home-video sections (`type=movie subtype=clip`) get the clip kind. */
    fun mediaLibrary(json: JsonObject, serverId: ServerId? = null, serverName: String? = null, isShared: Boolean = false): MediaLibrary {
        val type = json.plexString("type") ?: ""
        return MediaLibrary(
            id = json["key"].scalarString() ?: "",
            backend = BackendKind.PLEX,
            title = json.plexString("title") ?: "",
            kind = if (type == "movie" && json.plexString("subtype") == "clip") MediaKind.CLIP else MediaKind.fromString(type),
            language = json.plexString("language"),
            updatedAt = json["updatedAt"].flexLong(),
            createdAt = json["createdAt"].flexLong(),
            hidden = json["hidden"].flexInt() == 1,
            isShared = isShared,
            serverId = serverId?.value,
            serverName = serverName,
        )
    }

    /**
     * A hub: `Metadata` then `Directory` rows, a typeless `Directory` read as a show when it counts children and a
     * folder otherwise. A row that does not map is left out. `size` defaults to the item count.
     */
    fun mediaHub(json: JsonObject, serverId: ServerId? = null, serverName: String? = null): MediaHub {
        val items = ArrayList<MediaItem>()
        fun append(rows: JsonElement?, isDirectory: Boolean) {
            for (row in (rows as? JsonArray).orEmpty()) {
                if (row !is JsonObject) continue
                val entry = if (isDirectory && "type" !in row) {
                    val type = if ("leafCount" in row || "childCount" in row) "show" else "folder"
                    JsonObject(row + ("type" to JsonPrimitive(type)))
                } else {
                    row
                }
                try {
                    items += mediaItem(entry, serverId, serverName)
                } catch (e: IllegalArgumentException) {
                    Log.w(TAG, e) { "Skipping a hub row that does not map" }
                }
            }
        }
        append(json["Metadata"], isDirectory = false)
        append(json["Directory"], isDirectory = true)
        return MediaHub(
            id = json["key"].scalarString() ?: "",
            title = json.plexString("title") ?: T.common.unknown,
            type = json.plexString("type") ?: "hub",
            items = items,
            identifier = json.plexString("hubIdentifier"),
            size = json["size"].flexInt() ?: items.size,
            more = json["more"].flexBool(),
            serverId = serverId?.value,
            serverName = serverName,
        )
    }

    fun mediaPlaylist(json: JsonObject, serverId: ServerId? = null, serverName: String? = null): MediaPlaylist = MediaPlaylist(
        id = json["ratingKey"].scalarString() ?: "",
        backend = BackendKind.PLEX,
        title = json.plexString("title") ?: "",
        playlistType = json.plexString("playlistType") ?: "",
        summary = json.plexString("summary"),
        guid = json.plexString("guid"),
        smart = json["smart"].flexBool(),
        durationMs = json["duration"].flexLong(),
        leafCount = json["leafCount"].flexInt(),
        viewCount = json["viewCount"].flexInt(),
        addedAt = json["addedAt"].flexLong(),
        updatedAt = json["updatedAt"].flexLong(),
        lastViewedAt = json["lastViewedAt"].flexLong(),
        compositeImagePath = json.plexString("composite"),
        thumbPath = json.plexString("thumb"),
        serverId = serverId?.value,
        serverName = serverName,
    )
}

/**
 * Every attributed score of a Plex row, headline first: the `rating`/`ratingImage` pair, the
 * `audienceRating`/`audienceRatingImage` pair, then the `Rating[]` array only `/library/metadata/{id}` sends. Deduped
 * on (source, value), since the array repeats the scalar pair's source. IMDb entries carry `imdbRatingCount` as votes.
 * Null when there is none.
 */
fun plexRatingSources(metadata: JsonObject): List<MediaRatingSource>? {
    val imdbVotes = metadata["imdbRatingCount"].flexInt()
    val ratings = ArrayList<MediaRatingSource>()
    fun add(rawValue: JsonElement?, fallbackSource: String, image: JsonElement?, type: JsonElement? = null) {
        val value = normalizedPlexRating(rawValue) ?: return
        val source = plexRatingSource(image, type, fallbackSource)
        if (ratings.any { it.source == source && it.value == value }) return
        ratings += MediaRatingSource(source, value, if (source == "imdb") imdbVotes else null)
    }
    add(metadata["rating"], "critic", metadata["ratingImage"])
    add(metadata["audienceRating"], "audience", metadata["audienceRatingImage"])
    for (entry in metadata["Rating"].objectList()) add(entry["value"], "audience", entry["image"], entry["type"])
    return ratings.ifEmpty { null }
}

private fun plexRatingSource(image: JsonElement?, type: JsonElement?, fallback: String): String {
    val scheme = image.stringOrNull()?.trim()?.let { URI_SCHEME.find(it)?.groupValues?.get(1)?.lowercase() }
    if (scheme == "imdb") return "imdb"
    if (scheme == "themoviedb" || scheme == "tmdb") return "tmdb"
    val ratingType = type.stringOrNull()?.trim()?.takeIf { it.isNotEmpty() }?.lowercase() ?: fallback
    if (scheme == "rottentomatoes") return if (ratingType == "critic") "rottenTomatoesCritic" else "rottenTomatoesAudience"
    return if (ratingType == "critic" || ratingType == "audience") ratingType else fallback
}

/** A Plex score on the 0–10 scale: 0–10 as is, a stray 0–100 value divided by ten, anything else null. */
fun normalizedPlexRating(value: JsonElement?): Double? {
    val rating = value.flexDouble() ?: return null
    if (!rating.isFinite() || rating < 0 || rating > 100) return null
    return if (rating > 10) rating / 10 else rating
}

/**
 * The version and part playback opens, shared by cache previews and playback. [media] are the `Media` objects and
 * [versions] their mapping, index for index.
 */
data class PlexPlaybackSelection(val media: List<JsonObject>, val versions: List<MediaVersion>, val mediaIndex: Int, val partIndex: Int)

/**
 * Picks the version by [mediaSourceId], else [preferredVersionSignature], else [mediaIndex] (out of range is 0). With
 * [preferPlayable] an unplayable pick falls back to the first playable version ([onVersionFallback] hears requested
 * and chosen index). A version stacked across several files opens the file holding [position] (item time); with
 * [preferPlayable] a missing file plays on from the next playable one, else the first. Null without `Media`.
 */
fun resolvePlexPlaybackSelection(
    metadata: JsonObject,
    mediaIndex: Int = 0,
    mediaSourceId: String? = null,
    preferredVersionSignature: String? = null,
    onVersionFallback: ((requestedIndex: Int, fallbackIndex: Int) -> Unit)? = null,
    preferPlayable: Boolean = true,
    position: Duration? = null,
): PlexPlaybackSelection? {
    val media = metadata["Media"].objectList()
    if (media.isEmpty()) return null
    val versions = media.map(PlexMappers::mediaVersion)
    var index = mediaIndex
    val requestedId = mediaSourceId?.trim()
    val byId = if (requestedId.isNullOrEmpty()) -1 else versions.indexOfFirst { it.id == requestedId }
    if (byId >= 0) {
        index = byId
    } else if (!preferredVersionSignature.isNullOrEmpty()) {
        index = MediaVersion.findMatchingIndex(versions, listOf(preferredVersionSignature)) ?: index
    }
    if (index !in versions.indices) index = 0
    if (preferPlayable && !versions[index].isPlayable) {
        val fallback = versions.indexOfFirst { it.isPlayable }
        if (fallback >= 0) {
            onVersionFallback?.invoke(index, fallback)
            index = fallback
        }
    }
    return PlexPlaybackSelection(media, versions, index, plexPartIndex(versions[index].parts, position, preferPlayable))
}

private fun plexPartIndex(parts: List<MediaPart>, position: Duration?, preferPlayable: Boolean): Int {
    val timeline = MediaPartTimeline.fromParts(parts)
    if (timeline == null) {
        val playable = if (preferPlayable) parts.indexOfFirst { it.isPlayable } else 0
        return if (playable < 0) 0 else playable
    }
    val held = timeline.indexAt(position ?: Duration.ZERO)
    if (!preferPlayable || parts[held].isPlayable) return held
    val later = (held + 1 until parts.size).firstOrNull { parts[it].isPlayable }
    if (later != null) return later
    val any = parts.indexOfFirst { it.isPlayable }
    return if (any >= 0) any else held
}

/**
 * The selected part's source description: its audio and subtitle tracks (a stream without a numeric id is skipped),
 * the item's chapters, the part timeline of a stacked version and the video stream's display criteria. Null when the
 * selected version has no `Part`.
 */
fun plexMediaSourceInfoForSelection(metadata: JsonObject, selection: PlexPlaybackSelection, videoUrl: String = ""): MediaSourceInfo? {
    val media = selection.media[selection.mediaIndex]
    val parts = media["Part"].objectList()
    if (parts.isEmpty()) return null
    val part = parts[selection.partIndex]
    val streams = plexPlaybackStreams(part["Stream"])
    val version = selection.versions[selection.mediaIndex]
    return MediaSourceInfo(
        videoUrl = videoUrl,
        audioTracks = streams.audioTracks,
        subtitleTracks = streams.subtitleTracks,
        chapters = plexChaptersFromCacheJson(metadata),
        partId = part["id"].flexInt(),
        displayCriteria = PlexMappers.displayCriteria(media, streams.videoStream),
        mediaSourceId = version.id,
        mediaIndex = selection.mediaIndex,
        partIndex = selection.partIndex,
        partTimeline = MediaPartTimeline.fromParts(version.parts, currentIndex = selection.partIndex),
        videoAspectRatio = media["aspectRatio"].flexDouble(),
    )
}

/** The source of a cached item for the given version choice, without playback negotiation. */
fun plexMediaSourceInfoFromCacheJson(
    metadata: JsonObject,
    mediaIndex: Int = 0,
    mediaSourceId: String? = null,
    preferredVersionSignature: String? = null,
): MediaSourceInfo? {
    val selection = resolvePlexPlaybackSelection(metadata, mediaIndex, mediaSourceId, preferredVersionSignature) ?: return null
    return plexMediaSourceInfoForSelection(metadata, selection)
}

/** Chapters and markers of a metadata row, with markers the row lacks derived from chapter titles. */
internal fun plexPlaybackExtrasFromCacheJson(
    metadataJson: JsonObject?,
    classifier: ChapterMarkerClassifier,
    introPattern: String? = null,
    creditsPattern: String? = null,
    forceChapterFallback: Boolean = false,
): PlaybackExtras = PlaybackExtras.withChapterFallback(
    chapters = plexChaptersFromCacheJson(metadataJson),
    markers = plexMarkersFromCacheJson(metadataJson),
    classifier = classifier,
    introPattern = introPattern,
    creditsPattern = creditsPattern,
    forceChapterFallback = forceChapterFallback,
)

/**
 * Whether a show or movie row has Plex credits detection explicitly off (`enableCreditsMarkerGeneration` 0). `-1`
 * (library default) and an absent attribute (servers without the feature) are not off.
 */
fun plexCreditsDetectionDisabled(metadataJson: JsonObject?): Boolean = metadataJson?.get("enableCreditsMarkerGeneration").flexInt() == 0

/**
 * [extras] without credits markers when the owning show or movie has credits detection off, so the chapter-title
 * fallback cannot bring back a credits skip the server admin turned off. A movie carries the attribute itself; an
 * episode's show row comes from [loadMetadataJson] (by `grandparentRatingKey`), asked only when a credits marker is
 * present. A loader failure keeps the markers.
 */
suspend fun plexApplyCreditsDetectionPreference(
    extras: PlaybackExtras,
    metadataJson: JsonObject?,
    loadMetadataJson: suspend (ratingKey: String) -> JsonObject?,
): PlaybackExtras {
    if (metadataJson == null || !extras.hasCreditsMarkers) return extras
    val ownPreference = metadataJson["enableCreditsMarkerGeneration"].flexInt()
    val disabled = if (ownPreference != null) {
        ownPreference == 0
    } else {
        val showKey = metadataJson["grandparentRatingKey"].scalarString()
        if (showKey.isNullOrEmpty()) return extras
        try {
            plexCreditsDetectionDisabled(loadMetadataJson(showKey))
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "Failed to resolve the credits-detection preference of show $showKey" }
            return extras
        }
    }
    return if (disabled) extras.withoutCreditsMarkers() else extras
}

/** `Chapter[]` of a metadata row; entries without a numeric id are skipped. */
fun plexChaptersFromCacheJson(metadataJson: JsonObject?): List<MediaChapter> {
    val chapters = metadataJson?.get("Chapter") as? JsonArray ?: return emptyList()
    return chapters.filterIsInstance<JsonObject>().mapNotNull { chapter ->
        MediaChapter(
            id = chapter["id"].flexInt() ?: return@mapNotNull null,
            index = chapter["index"].flexInt(),
            startTimeOffset = chapter["startTimeOffset"].flexLong(),
            endTimeOffset = chapter["endTimeOffset"].flexLong(),
            title = chapter["tag"].scalarString() ?: chapter["title"].scalarString(),
            thumb = chapter["thumb"].stringOrNull(),
        )
    }
}

/** `Marker[]` of a metadata row; entries missing an id, type, start or end are skipped. */
fun plexMarkersFromCacheJson(metadataJson: JsonObject?): List<MediaMarker> {
    val markers = metadataJson?.get("Marker") as? JsonArray ?: return emptyList()
    return markers.filterIsInstance<JsonObject>().mapNotNull { marker ->
        MediaMarker(
            id = marker["id"].flexInt() ?: return@mapNotNull null,
            type = marker["type"].scalarString() ?: return@mapNotNull null,
            startTimeOffset = marker["startTimeOffset"].flexLong() ?: return@mapNotNull null,
            endTimeOffset = marker["endTimeOffset"].flexLong() ?: return@mapNotNull null,
        )
    }
}
