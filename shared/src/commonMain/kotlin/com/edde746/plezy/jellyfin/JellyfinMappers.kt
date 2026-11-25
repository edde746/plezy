package com.edde746.plezy.jellyfin

import com.edde746.plezy.format.resolutionLabelFromDimensions
import com.edde746.plezy.model.MediaBrowserDialect
import com.edde746.plezy.model.MediaDisplayCriteria
import com.edde746.plezy.model.MediaHub
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaLibrary
import com.edde746.plezy.model.MediaPart
import com.edde746.plezy.model.MediaRatingSource
import com.edde746.plezy.model.MediaRole
import com.edde746.plezy.model.MediaStream
import com.edde746.plezy.model.MediaStreamKind
import com.edde746.plezy.model.MediaVersion
import com.edde746.plezy.model.bitrateKbpsFromBps
import com.edde746.plezy.model.classifyMediaDisplayColor
import com.edde746.plezy.net.UriComponent
import com.edde746.plezy.strings.T
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive

/**
 * Relative image paths (`/Items/{id}/Images/Primary?tag=…`) made absolute against the server. No token: both dialects
 * serve item images without one, and a URL without it is safe to persist (downloads, saved music sessions) and to key
 * image caches on. Pure strings, so the cache layer can use it without a client.
 */
class JellyfinImageAbsolutizer(val baseUrl: String) {
    fun absolutize(path: String?): String? {
        if (path.isNullOrEmpty() || path.startsWith("http://") || path.startsWith("https://")) return path
        return joinUrl(baseUrl, path)
    }

    /** Every image path of [item] absolutized; the first backdrop becomes the art. */
    fun applyTo(item: MediaItem): MediaItem {
        val backdrops = item.backdropPaths?.map { absolutize(it)!! }
        val grandparentBackdrops = item.grandparentBackdropPaths?.map { absolutize(it)!! }
        return item.copy(
            thumbPath = absolutize(item.thumbPath),
            artPath = backdrops?.firstOrNull() ?: absolutize(item.artPath),
            backdropPaths = backdrops,
            clearLogoPath = absolutize(item.clearLogoPath),
            backgroundSquarePath = absolutize(item.backgroundSquarePath),
            parentThumbPath = absolutize(item.parentThumbPath),
            grandparentThumbPath = absolutize(item.grandparentThumbPath),
            grandparentArtPath = grandparentBackdrops?.firstOrNull() ?: absolutize(item.grandparentArtPath),
            grandparentBackdropPaths = grandparentBackdrops,
            roles = item.roles?.map { it.copy(thumbPath = absolutize(it.thumbPath)) },
        )
    }

    companion object {
        private val ABSOLUTE = Regex("^[A-Za-z][A-Za-z0-9+.\\-]*://")

        /** [urlOrPath] unchanged when absolute, else appended to [baseUrl] with exactly one slash between. */
        fun joinUrl(baseUrl: String, urlOrPath: String): String {
            if (ABSOLUTE.containsMatchIn(urlOrPath)) return urlOrPath
            return baseUrl.trimEnd('/') + (if (urlOrPath.startsWith("/")) urlOrPath else "/$urlOrPath")
        }

        /** [url] with query parameter [name] set to [value] (replacing an existing one), the rest kept as written. */
        fun setQueryParam(url: String, name: String, value: String): String =
            withQuery(url, name) { it + (UriComponent.encode(name) + "=" + JellyfinUrls.queryComponent(value)) }

        /** [url] without query parameter [name] (every occurrence), the rest kept as written; no `?` when none is left. */
        fun removeQueryParam(url: String, name: String): String = withQuery(url, name) { it }

        /** [url] with the query's [name] parameters dropped and the rest passed through [params]. */
        private fun withQuery(url: String, name: String, params: (List<String>) -> List<String>): String {
            val hash = url.indexOf('#')
            val fragment = if (hash >= 0) url.substring(hash) else ""
            val noFragment = if (hash >= 0) url.substring(0, hash) else url
            val q = noFragment.indexOf('?')
            val path = if (q >= 0) noFragment.substring(0, q) else noFragment
            val kept = if (q >= 0) noFragment.substring(q + 1).split('&').filter { it.isNotEmpty() && UriComponent.decode(it.substringBefore('=')) != name } else emptyList()
            val query = params(kept)
            return path + (if (query.isEmpty()) "" else "?" + query.joinToString("&")) + fragment
        }

        /** The query parameter values of [url], decoded (`+` as space). */
        fun queryParams(url: String): Map<String, String> {
            val q = url.substringBefore('#').substringAfter('?', "")
            if (q.isEmpty()) return emptyMap()
            return q.split('&').filter { it.isNotEmpty() }.associate {
                UriComponent.decode(it.substringBefore('=').replace('+', ' ')) to UriComponent.decode(it.substringAfter('=', "").replace('+', ' '))
            }
        }
    }
}

/** A MediaBrowser stream's fields as both the mappers and the playback layer read them. */
internal data class JellyfinStreamFields(
    val type: String?,
    val index: Int,
    val codec: String?,
    val language: String?,
    val languageCode: String?,
    val title: String?,
    val displayTitle: String?,
    val isDefault: Boolean,
    val isForced: Boolean,
    /** A real subtitle file next to the media (`IsExternal`). */
    val isExternalFile: Boolean,
    /** The server serves it as a separate file (`DeliveryMethod: External`), extracted or real. */
    val usesExternalDelivery: Boolean,
    val deliveryUrl: String?,
    val channels: Int?,
    val frameRate: Double?,
) {
    val isExternal: Boolean get() = isExternalFile || usesExternalDelivery

    companion object {
        fun parse(s: JsonObject, fallbackIndex: Int = 0): JellyfinStreamFields = JellyfinStreamFields(
            type = s.str("Type")?.lowercase(),
            index = s["Index"].flexibleLong()?.toInt() ?: fallbackIndex,
            codec = s.str("Codec"),
            language = s.str("DisplayLanguage") ?: s.str("Language"),
            languageCode = s.str("Language"),
            title = s.str("Title"),
            displayTitle = s.str("DisplayTitle"),
            isDefault = flexibleBool(s["IsDefault"]),
            isForced = flexibleBool(s["IsForced"]),
            isExternalFile = s.bool("IsExternal") == true,
            usesExternalDelivery = s.str("DeliveryMethod")?.lowercase() == "external",
            deliveryUrl = s.str("DeliveryUrl"),
            channels = s["Channels"].flexibleLong()?.toInt(),
            frameRate = flexibleDouble(s["RealFrameRate"]) ?: flexibleDouble(s["AverageFrameRate"]),
        )

        private fun flexibleBool(e: kotlinx.serialization.json.JsonElement?): Boolean =
            (e as? JsonPrimitive)?.content?.lowercase().let { it == "true" || it == "1" }

        private fun flexibleDouble(e: kotlinx.serialization.json.JsonElement?): Double? =
            (e as? JsonPrimitive)?.content?.toDoubleOrNull()
    }
}

/** Display (refresh rate, HDR) criteria of a source's video stream; null when nothing usable is reported. */
fun jellyfinDisplayCriteria(source: JsonObject, videoStream: JsonObject?): MediaDisplayCriteria? {
    if (videoStream == null) return null
    val doviProfile = videoStream["DvProfile"].flexibleLong()?.toInt()
    val doviCompatibilityId = videoStream["DvBlSignalCompatibilityId"].flexibleLong()?.toInt()
    val rangeType = (videoStream["VideoRangeType"] as? JsonPrimitive)?.content?.lowercase()
    val videoRange = (videoStream["VideoRange"] as? JsonPrimitive)?.content?.lowercase()
    fun text(key: String) = (videoStream[key] as? JsonPrimitive)?.content?.trim()?.ifEmpty { null }
    val transfer = text("ColorTransfer")
    val primaries = text("ColorPrimaries")
    val matrix = text("ColorSpace")
    val range = "${rangeType.orEmpty()} ${videoRange.orEmpty()}"
    val defaults = classifyMediaDisplayColor(
        isDolbyVision = (doviProfile ?: 0) > 0,
        doviCompatibilityId = doviCompatibilityId,
        range = range,
        transfer = transfer,
        primaries = primaries,
        matrix = matrix,
        assumeSdr = range.isBlank(),
    ).defaultTags
    val criteria = MediaDisplayCriteria.fromRaw(
        fps = (videoStream["RealFrameRate"] ?: videoStream["AverageFrameRate"]).primitiveValue(),
        width = (videoStream["Width"] ?: source["Width"]).primitiveValue(),
        height = (videoStream["Height"] ?: source["Height"]).primitiveValue(),
        doviProfile = doviProfile,
        doviLevel = videoStream["DvLevel"].primitiveValue(),
        doviCompatibilityId = doviCompatibilityId,
        transfer = transfer ?: defaults.transfer,
        primaries = primaries ?: defaults.primaries,
        matrix = matrix ?: defaults.matrix,
    )
    return criteria.takeIf { it.isUsable }
}

private fun kotlinx.serialization.json.JsonElement?.primitiveValue(): Any? =
    (this as? JsonPrimitive)?.let { if (it.isString) it.content else it.content.toLongOrNull() ?: it.content.toDoubleOrNull() }

fun jellyfinIsDolbyVision(videoStream: JsonObject): Boolean {
    if ((videoStream["DvProfile"].flexibleLong() ?: 0) > 0) return true
    if ((videoStream["DvVersionMajor"].flexibleLong() ?: 0) > 0) return true
    if ((videoStream["DvVersionMinor"].flexibleLong() ?: 0) > 0) return true
    val text = listOf("VideoRangeType", "VideoRange", "VideoDoViTitle")
        .mapNotNull { (videoStream[it] as? JsonPrimitive)?.content?.lowercase() }.joinToString(" ")
    return "dovi" in text || "dolby vision" in text || "dolbyvision" in text
}

fun jellyfinIsHdr(source: JsonObject, videoStream: JsonObject): Boolean {
    if (jellyfinIsDolbyVision(videoStream)) return true
    if (jellyfinDisplayCriteria(source, videoStream)?.isHdr == true) return true
    val range = listOf("VideoRangeType", "VideoRange").mapNotNull { (videoStream[it] as? JsonPrimitive)?.content?.lowercase() }.joinToString(" ")
    return "hdr" in range || "hlg" in range
}

/** The first `Type: Video` stream of a source's `MediaStreams`. */
internal fun jellyfinFirstVideoStream(source: JsonObject): JsonObject? =
    source.objects("MediaStreams").firstOrNull { it.str("Type")?.lowercase() == "video" }

/** `BaseItemDto` → neutral model. Pure: no client needed, so the cache layer maps the same way. */
object JellyfinMappers {
    private fun seg(value: String) = UriComponent.encode(value)

    internal fun itemImagePath(id: String, type: String, tag: String? = null, imageIndex: Int? = null): String =
        "/Items/${seg(id)}/Images/$type" + (imageIndex?.let { "/$it" } ?: "") + (tag?.let { "?tag=${UriComponent.encode(it)}" } ?: "")

    /**
     * One item; null without `Id` (an empty id would break cache keys and image URLs). [absolutizer] null keeps
     * relative image paths. `libraryId` stays null: no DTO names its library.
     */
    fun mediaItem(
        item: JsonObject,
        serverId: String,
        serverName: String?,
        absolutizer: JellyfinImageAbsolutizer?,
        dialect: MediaBrowserDialect = MediaBrowserDialect.JELLYFIN,
    ): MediaItem? {
        val id = item.str("Id")?.ifEmpty { null } ?: return null
        val type = item.str("Type")
        val kind = if (type == null && item.bool("IsFolder") == true) MediaKind.FOLDER else MediaKind.fromString(type)
        val childCount = nonNegative(item["ChildCount"].flexibleLong())
        val leafCount = nonNegative(item["RecursiveItemCount"].flexibleLong()) ?: childCount
        val albumPrimary = if (kind == MediaKind.TRACK) albumPrimaryImage(item) else null
        val backdrops = backdropPaths(id, item.array("BackdropImageTags"))
        val parentBackdrops = parentBackdropPaths(item)
        val seriesBackdrop = item.str("SeriesId")?.let { itemImagePath(it, "Backdrop", imageIndex = 0) }
        val grandparentBackdrops = parentBackdrops.ifEmpty { listOfNotNull(seriesBackdrop) }
        val userData = item.obj("UserData")
        val people = item.objects("People")
        val mapped = MediaItem(
            id = id,
            backend = dialect.backend,
            kind = kind,
            guid = id,
            title = item.str("Name"),
            titleSort = item.str("SortName"),
            summary = item.str("Overview"),
            tagline = item.strings("Taglines")?.firstOrNull(),
            originalTitle = item.str("OriginalTitle") ?: trackArtistsOriginalTitle(item),
            studio = item.objects("Studios").firstOrNull()?.str("Name"),
            year = item.int("ProductionYear"),
            originallyAvailableAt = JellyfinTime.isoToYmd(item.str("PremiereDate")),
            contentRating = item.str("OfficialRating"),
            parentId = item.str("SeasonId") ?: item.str("AlbumId") ?: (if (kind == MediaKind.ALBUM) firstAlbumArtistId(item) else null) ?: item.str("ParentId"),
            parentTitle = item.str("SeasonName") ?: item.str("Album") ?: (if (kind == MediaKind.ALBUM) item.str("AlbumArtist") else null),
            parentThumbPath = item.str("SeasonId")?.let { itemImagePath(it, "Primary", item.str("SeasonPrimaryImageTag")) } ?: albumPrimary,
            parentIndex = item.int("ParentIndexNumber"),
            index = item.int("IndexNumber"),
            grandparentId = item.str("SeriesId") ?: (if (kind == MediaKind.TRACK) firstAlbumArtistId(item) else null),
            grandparentTitle = item.str("SeriesName") ?: (if (kind == MediaKind.TRACK) item.str("AlbumArtist") else null),
            grandparentThumbPath = item.str("SeriesId")?.let { itemImagePath(it, "Primary", item.str("SeriesPrimaryImageTag")) },
            grandparentArtPath = grandparentBackdrops.firstOrNull(),
            grandparentBackdropPaths = grandparentBackdrops.ifEmpty { null },
            thumbPath = selfImagePath(id, item, "Primary") ?: albumPrimary,
            artPath = backdrops.firstOrNull(),
            backdropPaths = backdrops.ifEmpty { null },
            clearLogoPath = selfImagePath(id, item, "Logo") ?: item.str("ParentLogoItemId")?.let { itemImagePath(it, "Logo", item.str("ParentLogoImageTag")) },
            durationMs = JellyfinTime.ticksToMs(item.long("RunTimeTicks")),
            viewOffsetMs = JellyfinTime.ticksToMs(userData?.long("PlaybackPositionTicks")),
            viewCount = viewCount(userData),
            lastViewedAt = JellyfinTime.isoToEpochSeconds(userData?.str("LastPlayedDate")),
            leafCount = leafCount,
            viewedLeafCount = if (kind.usesLeafWatchCounts) viewedLeafCount(userData, leafCount) else null,
            childCount = childCount,
            addedAt = JellyfinTime.isoToEpochSeconds(item.str("DateCreated")),
            updatedAt = JellyfinTime.isoToEpochSeconds(item.str("DateLastSaved") ?: item.str("DateModified")),
            rating = item.double("CommunityRating"),
            ratings = ratingSources(item, kind),
            isFavorite = userData?.bool("IsFavorite"),
            genres = stringsOrNamePairs(item, "Genres", "GenreItems"),
            directors = peopleByType(people, "Director"),
            writers = peopleByType(people, "Writer"),
            producers = peopleByType(people, "Producer"),
            countries = item.strings("ProductionLocations"),
            labels = stringsOrNamePairs(item, "Tags", "TagItems"),
            roles = actors(people),
            mediaVersions = mediaVersions(item),
            playlistItemId = item.str("PlaylistItemId"),
            serverId = serverId,
            serverName = serverName,
            raw = item,
        )
        return absolutizer?.applyTo(mapped) ?: mapped
    }

    /** A `/Users/{uid}/Views` entry; null without `Id`. */
    fun library(view: JsonObject, serverId: String, serverName: String?, dialect: MediaBrowserDialect = MediaBrowserDialect.JELLYFIN): MediaLibrary? {
        val id = view.str("Id")?.ifEmpty { null } ?: return null
        val collectionType = view.str("CollectionType")?.trim()?.lowercase()
        val type = view.str("Type")
        val kind = if (!collectionType.isNullOrEmpty()) {
            when (collectionType) {
                "movies" -> MediaKind.MOVIE
                "tvshows" -> MediaKind.SHOW
                "music" -> MediaKind.ARTIST
                "musicvideos", "homevideos" -> MediaKind.CLIP
                "photos" -> MediaKind.PHOTO
                "boxsets" -> MediaKind.COLLECTION
                "playlists" -> MediaKind.PLAYLIST
                else -> MediaKind.UNKNOWN
            }
        } else {
            MediaKind.fromString(type)
        }
        return MediaLibrary(
            id = id,
            backend = dialect.backend,
            title = view.str("Name") ?: T.libraries.fallbackTitle,
            kind = kind,
            // A CollectionFolder without a CollectionType is a mixed library.
            defaultBrowseKinds = if (collectionType.isNullOrEmpty() && type?.lowercase() == "collectionfolder") listOf(MediaKind.MOVIE, MediaKind.SHOW) else emptyList(),
            updatedAt = JellyfinTime.isoToEpochSeconds(view.str("DateLastSaved") ?: view.str("DateModified")),
            createdAt = JellyfinTime.isoToEpochSeconds(view.str("DateCreated")),
            serverId = serverId,
            serverName = serverName,
        )
    }

    /** A home/library row synthesized from fetched [items]; [more] when the preview limit was reached. */
    fun syntheticHub(identifier: String, title: String, type: String, items: List<MediaItem>, serverId: String, serverName: String?, rawCount: Int = items.size, previewLimit: Int? = null) =
        MediaHub(
            id = identifier,
            title = title,
            type = type,
            items = items,
            identifier = identifier,
            size = items.size,
            more = previewLimit != null && rawCount >= previewLimit,
            serverId = serverId,
            serverName = serverName,
        )

    /** One version per source with an `Id`; stream path `/Videos/{sourceId}/stream`. */
    internal fun mediaVersions(item: JsonObject): List<MediaVersion>? {
        val result = item.objects("MediaSources").mapNotNull { source ->
            val id = source.str("Id")?.ifEmpty { null } ?: return@mapNotNull null
            sourceToVersion(source, versionId = id, partId = id, streamPath = "/Videos/${seg(id)}/stream",
                streams = mediaStreams(source), includePartDuration = true, requireParsedVideoStreamForDimensions = true, name = source.str("Name"))
        }
        return result.ifEmpty { null }
    }

    internal fun sourceToVersion(
        source: JsonObject,
        versionId: String,
        partId: String,
        streamPath: String?,
        streams: List<MediaStream> = emptyList(),
        includePartDuration: Boolean = false,
        requireParsedVideoStreamForDimensions: Boolean = false,
        name: String? = null,
    ): MediaVersion {
        val rawVideo = jellyfinFirstVideoStream(source)
        val parsedVideo = streams.firstOrNull { it.kind == MediaStreamKind.VIDEO }
        val width = source["Width"].flexibleLong()?.toInt() ?: rawVideo?.get("Width").flexibleLong()?.toInt()
        val height = source["Height"].flexibleLong()?.toInt() ?: rawVideo?.get("Height").flexibleLong()?.toInt()
        val expose = !requireParsedVideoStreamForDimensions || parsedVideo != null
        return MediaVersion(
            id = versionId,
            width = if (expose) width else null,
            height = if (expose) height else null,
            videoResolution = resolutionLabelFromDimensions(width, height),
            videoCodec = parsedVideo?.codec ?: rawVideo?.str("Codec"),
            bitrate = bitrateKbpsFromBps(source["Bitrate"].flexibleLong()),
            container = source.str("Container"),
            parts = listOf(
                MediaPart(
                    id = partId,
                    streamPath = streamPath,
                    file = source.str("Path"),
                    sizeBytes = source["Size"].flexibleLong(),
                    container = source.str("Container"),
                    durationMs = if (includePartDuration) JellyfinTime.ticksToMs(source.long("RunTimeTicks")) else null,
                    streams = streams,
                ),
            ),
            name = name,
        )
    }

    /** A source's streams; the selected audio/subtitle follow the source's default indexes, else `IsDefault`. */
    internal fun mediaStreams(source: JsonObject): List<MediaStream> {
        val defaultAudio = source["DefaultAudioStreamIndex"].flexibleLong()?.toInt()
        val defaultSubtitle = source["DefaultSubtitleStreamIndex"].flexibleLong()?.toInt()
        val result = mutableListOf<MediaStream>()
        for (s in source.objects("MediaStreams")) {
            val f = JellyfinStreamFields.parse(s, fallbackIndex = result.size)
            val kind = when (f.type) {
                "video" -> MediaStreamKind.VIDEO
                "audio" -> MediaStreamKind.AUDIO
                "subtitle" -> MediaStreamKind.SUBTITLE
                else -> MediaStreamKind.UNKNOWN
            }
            val isVideo = kind == MediaStreamKind.VIDEO
            val dv = isVideo && jellyfinIsDolbyVision(s)
            val selected = when {
                kind == MediaStreamKind.AUDIO && defaultAudio != null -> f.index == defaultAudio
                kind == MediaStreamKind.SUBTITLE && defaultSubtitle != null -> f.index == defaultSubtitle
                else -> f.isDefault
            }
            result += MediaStream(
                id = "${f.index}",
                kind = kind,
                index = f.index,
                codec = f.codec,
                language = f.language,
                languageCode = f.languageCode,
                title = f.title,
                displayTitle = f.displayTitle,
                selected = selected,
                isDefault = f.isDefault,
                channels = f.channels,
                frameRate = f.frameRate,
                hdr = isVideo && jellyfinIsHdr(source, s),
                dolbyVision = dv,
                dolbyVisionProfile = if (dv) s["DvProfile"].flexibleLong()?.toInt() else null,
                forced = f.isForced,
                sidecarPath = if (f.isExternalFile) f.deliveryUrl else null,
            )
        }
        return result
    }

    private fun nonNegative(value: Long?): Int? = value?.takeIf { it >= 0 }?.toInt()

    private fun viewCount(userData: JsonObject?): Int {
        if (userData?.bool("Played") != true) return 0
        return userData["PlayCount"].flexibleLong()?.toInt()?.takeIf { it > 0 } ?: 1
    }

    private fun viewedLeafCount(userData: JsonObject?, total: Int?): Int? {
        val unplayed = nonNegative(userData?.get("UnplayedItemCount").flexibleLong())
        if (total == null || unplayed == null) return null
        return if (unplayed >= total) 0 else total - unplayed
    }

    /**
     * `CommunityRating` (0–10, provenance unknowable) as the generic audience score; `CriticRating` is the
     * Tomatometer percent. Photos reuse `CommunityRating` for EXIF stars, so they get none.
     */
    private fun ratingSources(item: JsonObject, kind: MediaKind): List<MediaRatingSource>? {
        if (kind == MediaKind.PHOTO) return null
        val ratings = buildList {
            item.finite("CommunityRating")?.takeIf { it in 0.0..10.0 }?.let { add(MediaRatingSource("audience", it)) }
            item.finite("CriticRating")?.takeIf { it in 0.0..100.0 }?.let { add(MediaRatingSource("rottenTomatoesCritic", it / 10)) }
        }
        return ratings.ifEmpty { null }
    }

    private fun JsonObject.finite(key: String): Double? = (this[key] as? JsonPrimitive)?.content?.toDoubleOrNull()?.takeIf { it.isFinite() }

    /** Emby returns only `TagItems`/`GenreItems` name pairs, never the plain arrays. */
    private fun stringsOrNamePairs(item: JsonObject, plainKey: String, pairKey: String): List<String>? {
        val direct = item.strings(plainKey)
        if (!direct.isNullOrEmpty()) return direct
        val pairs = item.objects(pairKey).mapNotNull { it.str("Name")?.trim()?.ifEmpty { null } }
        return pairs.ifEmpty { direct }
    }

    private fun peopleByType(people: List<JsonObject>, type: String): List<String>? =
        people.filter { it.str("Type") == type }.mapNotNull { it.str("Name") }.ifEmpty { null }

    private fun actors(people: List<JsonObject>): List<MediaRole>? = people
        .filter { it.str("Type") == "Actor" || it.str("Type") == "GuestStar" }
        .map { MediaRole(id = it.str("Id"), tag = it.str("Name").orEmpty(), role = it.str("Role"), thumbPath = it.str("Id")?.let { pid -> itemImagePath(pid, "Primary", it.str("PrimaryImageTag")) }) }
        .ifEmpty { null }

    private fun selfImagePath(id: String, item: JsonObject, type: String): String? =
        item.obj("ImageTags")?.str(type)?.ifEmpty { null }?.let { itemImagePath(id, type, it) }

    /** One path per distinct tag, keeping each tag's position in the array as its image index. */
    private fun backdropPaths(id: String, tags: kotlinx.serialization.json.JsonArray?): List<String> {
        val seen = mutableSetOf<String>()
        return tags.orEmpty().mapIndexedNotNull { index, element ->
            val tag = (element as? JsonPrimitive)?.takeIf { it.isString }?.content
            if (tag.isNullOrEmpty() || !seen.add(tag)) null else itemImagePath(id, "Backdrop", tag, index)
        }
    }

    private fun parentBackdropPaths(item: JsonObject): List<String> {
        val parentId = item.str("ParentBackdropItemId")?.ifEmpty { null } ?: return emptyList()
        return backdropPaths(parentId, item.array("ParentBackdropImageTags")).ifEmpty { listOf(itemImagePath(parentId, "Backdrop", imageIndex = 0)) }
    }

    private fun firstAlbumArtistId(item: JsonObject): String? = item.objects("AlbumArtists").firstOrNull()?.str("Id")

    /** A compilation track's own performers, only when they differ from the album artist. */
    private fun trackArtistsOriginalTitle(item: JsonObject): String? {
        val artists = item.strings("Artists")?.ifEmpty { null } ?: return null
        val joined = artists.joinToString(", ")
        return if (joined == item.str("AlbumArtist")) null else joined
    }

    private fun albumPrimaryImage(item: JsonObject): String? {
        val albumId = item.str("AlbumId")?.ifEmpty { null } ?: return null
        return itemImagePath(albumId, "Primary", item.str("AlbumPrimaryImageTag"))
    }
}
