package com.edde746.plezy.model

import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonObjectBuilder
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put

// The persisted JSON of items and their parts: offline caches and download rows store it, and rows written by earlier
// app versions must keep reading. `backend` carries the server kind; null fields are omitted; Plex-only fields are
// written for Plex items only.

private fun JsonObjectBuilder.putIfNotNull(key: String, value: String?) {
    if (value != null) put(key, value)
}

private fun JsonObjectBuilder.putIfNotNull(key: String, value: Number?) {
    if (value != null) put(key, value)
}

private fun JsonObjectBuilder.putIfNotNull(key: String, value: Boolean?) {
    if (value != null) put(key, value)
}

private fun JsonObjectBuilder.putIfNotNull(key: String, value: JsonElement?) {
    if (value != null) put(key, value)
}

private fun JsonObjectBuilder.putStrings(key: String, values: List<String>?) {
    if (values != null) put(key, JsonArray(values.map { JsonPrimitive(it) }))
}

private fun <T> JsonObjectBuilder.putObjects(key: String, values: List<T>?, toJson: (T) -> JsonObject) {
    if (values != null) put(key, JsonArray(values.map(toJson)))
}

private fun <T> objectsOrNull(raw: JsonElement?, fromJson: (JsonObject) -> T?): List<T>? =
    (raw as? JsonArray)?.mapNotNull { (it as? JsonObject)?.let(fromJson) }

private fun JsonObject.string(key: String): String? = this[key].asStringOrNull

private fun JsonObject.strings(key: String): List<String>? = stringListFromRaw(this[key])

private fun JsonObject.stringifiedStrings(key: String): List<String>? = stringListFromRaw(this[key], stringify = true)

fun MediaItem.toJson(): JsonObject {
    val plex = backend == BackendKind.PLEX
    return buildJsonObject {
        put("backend", backend.id)
        put("id", id)
        put("kind", kind.id)
        putIfNotNull("guid", guid)
        putIfNotNull("title", title)
        putIfNotNull("titleSort", titleSort)
        putIfNotNull("summary", summary)
        putIfNotNull("tagline", tagline)
        putIfNotNull("originalTitle", originalTitle)
        if (plex) putIfNotNull("editionTitle", editionTitle)
        putIfNotNull("studio", studio)
        putIfNotNull("year", year)
        putIfNotNull("originallyAvailableAt", originallyAvailableAt)
        putIfNotNull("contentRating", contentRating)
        putIfNotNull("parentId", parentId)
        putIfNotNull("parentTitle", parentTitle)
        putIfNotNull("parentThumbPath", parentThumbPath)
        putIfNotNull("parentIndex", parentIndex)
        putIfNotNull("index", index)
        putIfNotNull("grandparentId", grandparentId)
        putIfNotNull("grandparentTitle", grandparentTitle)
        putIfNotNull("grandparentThumbPath", grandparentThumbPath)
        putIfNotNull("grandparentArtPath", grandparentArtPath)
        putStrings("grandparentBackdropPaths", grandparentBackdropPaths)
        putIfNotNull("thumbPath", thumbPath)
        putIfNotNull("artPath", artPath)
        putStrings("backdropPaths", backdropPaths)
        putIfNotNull("clearLogoPath", clearLogoPath)
        putIfNotNull("backgroundSquarePath", backgroundSquarePath)
        putIfNotNull("durationMs", durationMs)
        putIfNotNull("viewOffsetMs", viewOffsetMs)
        putIfNotNull("viewCount", viewCount)
        putIfNotNull("lastViewedAt", lastViewedAt)
        putIfNotNull("leafCount", leafCount)
        putIfNotNull("viewedLeafCount", viewedLeafCount)
        putIfNotNull("childCount", childCount)
        putIfNotNull("addedAt", addedAt)
        putIfNotNull("updatedAt", updatedAt)
        putIfNotNull("rating", rating)
        putIfNotNull("userRating", userRating)
        putObjects("ratings", ratings) { it.toJson() }
        putIfNotNull("isFavorite", isFavorite)
        putStrings("genres", genres)
        putStrings("directors", directors)
        putStrings("writers", writers)
        putStrings("producers", producers)
        putStrings("countries", countries)
        putStrings("collections", collections)
        putStrings("labels", labels)
        putStrings("styles", styles)
        putStrings("moods", moods)
        putObjects("roles", roles) { it.toJson() }
        putObjects("mediaVersions", mediaVersions) { it.toJson() }
        putIfNotNull("libraryId", libraryId)
        putIfNotNull("libraryTitle", libraryTitle)
        if (plex) {
            putIfNotNull("trailerKey", trailerKey)
            // Plex's playlist entry id is numeric on the wire.
            val numericPlaylistItemId = playlistItemId?.toLongOrNull()
            if (numericPlaylistItemId != null) put("playlistItemId", numericPlaylistItemId) else putIfNotNull("playlistItemId", playlistItemId)
            putIfNotNull("playQueueItemId", playQueueItemId)
            putIfNotNull("subtype", subtype)
        } else {
            putIfNotNull("playlistItemId", playlistItemId)
        }
        putIfNotNull("serverId", serverId)
        putIfNotNull("serverName", serverName)
        putIfNotNull("backendFolderKey", backendFolderKey)
        putIfNotNull("raw", raw)
    }
}

/** Reads [toJson]'s output. A missing or unknown `backend` reads as Plex, as rows from before Jellyfin support do. */
fun MediaItem.Companion.fromJson(json: JsonObject): MediaItem {
    val backend = BackendKind.fromString(json.string("backend"))
    val plex = backend == BackendKind.PLEX
    return MediaItem(
        id = readStringField(json, "id") ?: "",
        backend = backend,
        kind = MediaKind.fromString(json.string("kind")),
        guid = json.string("guid"),
        title = json.string("title"),
        titleSort = json.string("titleSort"),
        summary = json.string("summary"),
        tagline = json.string("tagline"),
        originalTitle = json.string("originalTitle"),
        editionTitle = if (plex) json.string("editionTitle") else null,
        studio = json.string("studio"),
        year = flexibleInt(json["year"]),
        originallyAvailableAt = json.string("originallyAvailableAt"),
        contentRating = json.string("contentRating"),
        parentId = json.string("parentId"),
        parentTitle = json.string("parentTitle"),
        parentThumbPath = json.string("parentThumbPath"),
        parentIndex = flexibleInt(json["parentIndex"]),
        index = flexibleInt(json["index"]),
        grandparentId = json.string("grandparentId"),
        grandparentTitle = json.string("grandparentTitle"),
        grandparentThumbPath = json.string("grandparentThumbPath"),
        grandparentArtPath = json.string("grandparentArtPath"),
        grandparentBackdropPaths = json.strings("grandparentBackdropPaths"),
        thumbPath = json.string("thumbPath"),
        artPath = json.string("artPath"),
        backdropPaths = json.strings("backdropPaths"),
        clearLogoPath = json.string("clearLogoPath"),
        backgroundSquarePath = json.string("backgroundSquarePath"),
        durationMs = flexibleLong(json["durationMs"]),
        viewOffsetMs = flexibleLong(json["viewOffsetMs"]),
        viewCount = flexibleInt(json["viewCount"]),
        lastViewedAt = flexibleLong(json["lastViewedAt"]),
        leafCount = flexibleInt(json["leafCount"]),
        viewedLeafCount = flexibleInt(json["viewedLeafCount"]),
        childCount = flexibleInt(json["childCount"]),
        addedAt = flexibleLong(json["addedAt"]),
        updatedAt = flexibleLong(json["updatedAt"]),
        rating = flexibleDouble(json["rating"]),
        userRating = flexibleDouble(json["userRating"]),
        ratings = objectsOrNull(json["ratings"]) { MediaRatingSource.fromJson(it) },
        isFavorite = json["isFavorite"].asBooleanOrNull,
        genres = json.stringifiedStrings("genres"),
        directors = json.stringifiedStrings("directors"),
        writers = json.stringifiedStrings("writers"),
        producers = json.stringifiedStrings("producers"),
        countries = json.stringifiedStrings("countries"),
        collections = json.stringifiedStrings("collections"),
        labels = json.stringifiedStrings("labels"),
        styles = json.stringifiedStrings("styles"),
        moods = json.stringifiedStrings("moods"),
        roles = objectsOrNull(json["roles"]) { MediaRole.fromJson(it) },
        mediaVersions = objectsOrNull(json["mediaVersions"]) { MediaVersion.fromJson(it) },
        libraryId = json.string("libraryId"),
        libraryTitle = json.string("libraryTitle"),
        trailerKey = if (plex) json.string("trailerKey") else null,
        playlistItemId = if (plex) flexibleLong(json["playlistItemId"])?.toString() else json.string("playlistItemId"),
        playQueueItemId = if (plex) flexibleInt(json["playQueueItemId"]) else null,
        subtype = if (plex) json.string("subtype") else null,
        serverId = json.string("serverId"),
        serverName = json.string("serverName"),
        backendFolderKey = json.string("backendFolderKey"),
        raw = json["raw"] as? JsonObject,
    )
}

fun MediaVersion.toJson(): JsonObject = buildJsonObject {
    put("id", id)
    putIfNotNull("width", width)
    putIfNotNull("height", height)
    putIfNotNull("videoResolution", videoResolution)
    putIfNotNull("videoCodec", videoCodec)
    putIfNotNull("bitrate", bitrate)
    putIfNotNull("container", container)
    put("parts", JsonArray(parts.map { it.toJson() }))
    putIfNotNull("name", name)
}

fun MediaVersion.Companion.fromJson(json: JsonObject): MediaVersion = MediaVersion(
    id = stringOrEmpty(json["id"]),
    width = flexibleInt(json["width"]),
    height = flexibleInt(json["height"]),
    videoResolution = json.string("videoResolution"),
    videoCodec = json.string("videoCodec"),
    bitrate = flexibleInt(json["bitrate"]),
    container = json.string("container"),
    parts = objectsOrNull(json["parts"]) { MediaPart.fromJson(it) }.orEmpty(),
    name = json.string("name"),
)

/** Streams are not persisted. */
fun MediaPart.toJson(): JsonObject = buildJsonObject {
    put("id", id)
    putIfNotNull("streamPath", streamPath)
    putIfNotNull("file", file)
    putIfNotNull("sizeBytes", sizeBytes)
    putIfNotNull("container", container)
    putIfNotNull("durationMs", durationMs)
    putIfNotNull("accessible", accessible)
    putIfNotNull("exists", exists)
}

fun MediaPart.Companion.fromJson(json: JsonObject): MediaPart = MediaPart(
    id = stringOrEmpty(json["id"]),
    streamPath = json.string("streamPath"),
    file = json.string("file"),
    sizeBytes = flexibleLong(json["sizeBytes"]),
    container = json.string("container"),
    durationMs = flexibleLong(json["durationMs"]),
    accessible = json["accessible"].asBooleanOrNull,
    exists = json["exists"].asBooleanOrNull,
)

fun MediaRole.toJson(): JsonObject = buildJsonObject {
    putIfNotNull("id", id)
    put("tag", tag)
    putIfNotNull("role", role)
    putIfNotNull("thumbPath", thumbPath)
}

fun MediaRole.Companion.fromJson(json: JsonObject): MediaRole = MediaRole(
    id = json.string("id"),
    tag = stringOrEmpty(json["tag"]),
    role = json.string("role"),
    thumbPath = json.string("thumbPath"),
)

/** `{source, value, votes?}`. */
fun MediaRatingSource.toJson(): JsonObject = buildJsonObject {
    put("source", source)
    put("value", value)
    putIfNotNull("votes", votes)
}

/** Null without a string `source` and a numeric `value`. */
fun MediaRatingSource.Companion.fromJson(json: JsonObject): MediaRatingSource? {
    val source = json.string("source") ?: return null
    val value = json["value"].takeIf { it.asStringOrNull == null }?.let(::flexibleDouble) ?: return null
    val votes = json["votes"].takeIf { it.asStringOrNull == null }?.let(::flexibleInt)
    return MediaRatingSource(source, value, votes)
}

/** The filter's unit and operators are not persisted; reading restores the defaults. */
fun MediaFilter.toJson(): JsonObject = buildJsonObject {
    put("filter", filter)
    put("filterType", filterType)
    put("key", key)
    put("title", title)
    put("type", type)
}

fun MediaFilter.Companion.fromJson(json: JsonObject): MediaFilter = MediaFilter(
    filter = json.string("filter") ?: "",
    filterType = json.string("filterType") ?: MediaFilterType.STRING,
    key = json.string("key") ?: "",
    title = json.string("title") ?: "",
    type = json.string("type") ?: "filter",
)

fun MediaFilterValue.toJson(): JsonObject = buildJsonObject {
    put("key", key)
    put("title", title)
    putIfNotNull("type", type)
}

fun MediaFilterValue.Companion.fromJson(json: JsonObject): MediaFilterValue = MediaFilterValue(
    key = json.string("key") ?: "",
    title = json.string("title") ?: "",
    type = json.string("type"),
)

/** Writes every field, nulls included. */
fun MediaSort.toJson(): JsonObject = buildJsonObject {
    put("key", key)
    put("descKey", descKey)
    put("title", title)
    put("defaultDirection", defaultDirection)
    put("unsortedDirection", unsortedDirection)
}

/** Throws [IllegalArgumentException] without a string `key` and `title`. */
fun MediaSort.Companion.fromJson(json: JsonObject): MediaSort = MediaSort(
    key = requireNotNull(json.string("key")) { "MediaSort JSON has no key" },
    title = requireNotNull(json.string("title")) { "MediaSort JSON has no title" },
    descKey = json.string("descKey"),
    defaultDirection = json.string("defaultDirection"),
    unsortedDirection = json.string("unsortedDirection"),
)
