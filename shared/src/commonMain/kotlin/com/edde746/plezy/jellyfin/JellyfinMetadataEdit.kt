package com.edde746.plezy.jellyfin

import com.edde746.plezy.log.Log
import com.edde746.plezy.model.MediaItem
import kotlin.coroutines.cancellation.CancellationException
import kotlin.io.encoding.Base64
import kotlin.io.encoding.ExperimentalEncodingApi
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive

/**
 * The metadata editor's transport: the full editable item DTO, its write-back, tag suggestions and artwork.
 * [invalidateItem] drops the item's cached rows after a write.
 */
internal class JellyfinMetadataEdit(
    private val core: JellyfinCore,
    private val invalidateItem: suspend (String) -> Unit,
) {
    /** The whole DTO (the user-scoped route; no `Fields`); null offline or on 404. */
    suspend fun fetchEditableMetadataItem(itemId: String): JsonObject? {
        if (core.offlineMode) return null
        val response = core.get("/Users/${JellyfinCore.segment(core.userId)}/Items/${JellyfinCore.segment(itemId)}")
        if (response.status == 404) return null
        return response.throwIfError().obj
    }

    /** Posts the full DTO back: the route replaces the item's editable fields with what it is given. */
    suspend fun updateMetadataItem(itemId: String, item: JsonObject): Boolean {
        core.post("/Items/${JellyfinCore.segment(itemId)}", body = item).throwIfError()
        invalidate(itemId)
        return true
    }

    /**
     * Server-wide values of a tag-like facet (`Tags`, `Genres`): item DTOs carry no library id. Jellyfin answers the
     * aggregate `/Items/Filters`, Emby the per-facet route. Best-effort: suggestions never block editing.
     */
    suspend fun fetchTagFacetValues(facet: String): List<String> {
        if (core.offlineMode) return emptyList()
        return try {
            if (!core.dialect.supportsAggregateItemFilters) {
                val response = core.get("/$facet", listOf("UserId" to core.userId, "Recursive" to "true")).throwIfError()
                core.itemsArray(response.obj).mapNotNull { it.str("Name")?.ifEmpty { null } }
            } else {
                val response = core.get("/Items/Filters", listOf("userId" to core.userId), timeoutMillis = FILTERS_TIMEOUT_MS).throwIfError()
                response.obj?.strings(facet).orEmpty().filter { it.isNotEmpty() }
            }
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "Tag facet $facet unavailable" }
            emptyList()
        }
    }

    suspend fun getRemoteImages(
        itemId: String,
        imageType: String,
        startIndex: Int = 0,
        limit: Int = 60,
        providerName: String? = null,
        includeAllLanguages: Boolean = false,
    ): JsonObject {
        val response = core.get(
            "/Items/${JellyfinCore.segment(itemId)}/RemoteImages",
            listOf(
                "type" to imageType,
                "startIndex" to startIndex.toString(),
                "limit" to limit.toString(),
                "providerName" to providerName?.ifEmpty { null },
                "includeAllLanguages" to includeAllLanguages.toString(),
            ),
        ).throwIfError()
        return response.obj ?: JsonObject(emptyMap())
    }

    suspend fun downloadRemoteImage(itemId: String, imageType: String, imageUrl: String): Boolean {
        core.post(
            "/Items/${JellyfinCore.segment(itemId)}/RemoteImages/Download",
            listOf("type" to imageType, "imageUrl" to imageUrl),
        ).throwIfError()
        invalidate(itemId)
        return true
    }

    /**
     * The body is base64 text: both dialects answer 500 to raw bytes. [contentType] still names the image type, which
     * picks the file extension on the server.
     */
    @OptIn(ExperimentalEncodingApi::class)
    suspend fun uploadItemImage(itemId: String, imageType: String, bytes: ByteArray, contentType: String): Boolean {
        core.postText(
            "/Items/${JellyfinCore.segment(itemId)}/Images/${JellyfinCore.segment(imageType)}",
            Base64.encode(bytes),
            contentType,
        ).throwIfError()
        invalidate(itemId)
        return true
    }

    /** A stale cache row only costs a refetch, so a failed invalidation never fails the accepted write. */
    private suspend fun invalidate(itemId: String) {
        try {
            invalidateItem(itemId)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "Metadata edit cache invalidation failed" }
        }
    }

    private companion object {
        const val TAG = "JellyfinMetadataEdit"
        const val FILTERS_TIMEOUT_MS = 8_000L
    }
}

/**
 * The editor's fields over a MediaBrowser item DTO. Field ids: `title`, `titleSort`, `originalTitle`,
 * `originallyAvailableAt` (`YYYY-MM-DD`), `contentRating`, `summary`, `tagline` (strings); `studio`, `genre`,
 * `director`, `writer`, `producer`, `country`, `label` (string lists).
 */
internal object JellyfinMetadataEditDto {
    /** The editable values of [raw], falling back to [item] where the DTO is silent. */
    fun readValues(raw: JsonObject, item: MediaItem): Map<String, Any> {
        val studios = names(raw["Studios"])
        val tagline = raw.strings("Taglines")?.firstOrNull().orEmpty()
        return mapOf(
            "title" to (raw.str("Name") ?: item.title ?: ""),
            "titleSort" to (raw.str("ForcedSortName") ?: ""),
            "originalTitle" to (raw.str("OriginalTitle") ?: item.originalTitle ?: ""),
            "originallyAvailableAt" to (JellyfinTime.isoToYmd(raw.str("PremiereDate")) ?: item.originallyAvailableAt ?: ""),
            "contentRating" to (raw.str("OfficialRating") ?: item.contentRating ?: ""),
            "studio" to studios.ifEmpty { listOfNotNull(item.studio?.trim()?.ifEmpty { null }) },
            "tagline" to tagline.ifEmpty { item.tagline ?: "" },
            "summary" to (raw.str("Overview") ?: item.summary ?: ""),
            "genre" to namedStrings(raw, "Genres", "GenreItems"),
            "director" to peopleByType(raw["People"], "Director"),
            "writer" to peopleByType(raw["People"], "Writer"),
            "producer" to peopleByType(raw["People"], "Producer"),
            "country" to stringList(raw["ProductionLocations"]),
            "label" to namedStrings(raw, "Tags", "TagItems"),
        )
    }

    /**
     * The DTO to post: [raw] normalized (Trickplay dropped: the write route rejects it) with [changes] applied —
     * only the fields the user changed, so untouched people and studios keep their ids and images. [namePairs]
     * (Emby) mirrors `Genres`/`Tags` into `GenreItems`/`TagItems` on every save: Emby reads only the pairs, and the
     * fetched DTO's old pairs would otherwise reinstate the previous values.
     */
    fun applyEdits(raw: JsonObject, changes: Map<String, Any?>, namePairs: Boolean): JsonObject {
        val dto = raw.toMutableMap()
        dto["ProviderIds"] = JsonObject((raw["ProviderIds"] as? JsonObject).orEmpty().mapValues { (_, v) -> JsonPrimitive((v as? JsonPrimitive)?.content ?: "") })
        dto["Tags"] = strings(namedStrings(raw, "Tags", "TagItems"))
        dto["Genres"] = strings(namedStrings(raw, "Genres", "GenreItems"))
        dto["People"] = JsonArray(objects(raw["People"]))
        dto["Studios"] = JsonArray(objects(raw["Studios"]))
        dto["LockedFields"] = strings(stringList(raw["LockedFields"]))
        dto["LockData"] = JsonPrimitive((raw["LockData"] as? JsonPrimitive)?.content == "true")
        dto.remove("Trickplay")

        fun text(id: String) = (changes[id] as String?).orEmpty()
        fun list(id: String) = stringList(changes[id])
        fun nullable(value: String) = value.trim().ifEmpty { null }?.let(::JsonPrimitive) ?: JsonNull

        if ("title" in changes) dto["Name"] = JsonPrimitive(text("title").trim())
        for ((id, key) in listOf("titleSort" to "ForcedSortName", "originalTitle" to "OriginalTitle", "contentRating" to "OfficialRating", "summary" to "Overview")) {
            if (id in changes) dto[key] = nullable(text(id))
        }
        if ("originallyAvailableAt" in changes) {
            val value = text("originallyAvailableAt").trim()
            dto["PremiereDate"] = premiereDate(value, raw.str("PremiereDate"))?.let(::JsonPrimitive) ?: JsonNull
            // Item years are mapped from ProductionYear; the full re-post would otherwise resend the stale one.
            dto["ProductionYear"] = Regex("^(\\d{4})-\\d{2}-\\d{2}").find(value)?.groupValues?.get(1)?.toInt()?.let(::JsonPrimitive) ?: JsonNull
        }
        if ("studio" in changes) dto["Studios"] = JsonArray(replaceNamed(objects(raw["Studios"]), list("studio"), null))
        if ("tagline" in changes) {
            val tagline = text("tagline").trim().ifEmpty { null }
            dto["Taglines"] = strings(if (tagline == null) emptyList() else listOf(tagline) + stringList(raw["Taglines"]).drop(1))
        }
        if ("genre" in changes) dto["Genres"] = strings(list("genre"))
        if ("country" in changes) dto["ProductionLocations"] = strings(list("country"))
        if ("label" in changes) dto["Tags"] = strings(list("label"))

        var people = objects(raw["People"])
        for ((id, type) in listOf("director" to "Director", "writer" to "Writer", "producer" to "Producer")) {
            if (id !in changes) continue
            val kept = people.filter { !it.isType(type) }
            people = kept + replaceNamed(people.filter { it.isType(type) }, list(id), type)
            dto["People"] = JsonArray(people)
        }

        if (namePairs) {
            dto["GenreItems"] = namePairArray(dto["Genres"])
            dto["TagItems"] = namePairArray(dto["Tags"])
        }
        return JsonObject(dto)
    }

    /** The image type of [bytes] by signature, else by [fileName]'s extension, else JPEG. */
    fun imageContentType(bytes: ByteArray, fileName: String?): String {
        fun at(i: Int) = bytes[i].toInt() and 0xFF
        fun ascii(from: Int, count: Int) = (from until from + count).map { at(it).toChar() }.joinToString("")
        val png = intArrayOf(0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A)
        when {
            bytes.size >= 8 && png.indices.all { at(it) == png[it] } -> return "image/png"
            bytes.size >= 3 && at(0) == 0xFF && at(1) == 0xD8 && at(2) == 0xFF -> return "image/jpeg"
            bytes.size >= 6 && ascii(0, 6).let { it == "GIF87a" || it == "GIF89a" } -> return "image/gif"
            bytes.size >= 12 && ascii(0, 4) == "RIFF" && ascii(8, 4) == "WEBP" -> return "image/webp"
            bytes.size >= 2 && at(0) == 0x42 && at(1) == 0x4D -> return "image/bmp"
        }
        val name = fileName?.lowercase().orEmpty()
        return when {
            name.endsWith(".png") -> "image/png"
            name.endsWith(".gif") -> "image/gif"
            name.endsWith(".webp") -> "image/webp"
            name.endsWith(".bmp") -> "image/bmp"
            else -> "image/jpeg"
        }
    }

    /** A date-only edit keeps the original's time of day when the day is unchanged. */
    private fun premiereDate(value: String, original: String?): String? {
        if (value.isEmpty()) return null
        if (original != null && original.startsWith(value)) {
            val t = original.indexOf('T')
            if (t >= 0) return value + original.substring(t)
        }
        return value
    }

    /** One entry per name, reusing an existing entry of the same name (case-insensitive) to keep its id and image. */
    private fun replaceNamed(existing: List<JsonObject>, names: List<String>, type: String?): List<JsonObject> {
        val used = mutableSetOf<Int>()
        return names.map { name ->
            val trimmed = name.trim()
            val match = existing.indices.firstOrNull { it !in used && existing[it].str("Name")?.trim()?.lowercase() == trimmed.lowercase() }
            val base = match?.let { used += it; existing[it] }.orEmpty()
            JsonObject(base + ("Name" to JsonPrimitive(trimmed)) + listOfNotNull(type?.let { "Type" to JsonPrimitive(it) }))
        }
    }

    private fun JsonObject.isType(type: String) = str("Type")?.lowercase() == type.lowercase()

    /** The plain string array, else its name-pair sibling: Emby never returns plain `Tags`. */
    private fun namedStrings(dto: JsonObject, key: String, pairKey: String) = stringList(dto[key]).ifEmpty { names(dto[pairKey]) }

    private fun peopleByType(value: JsonElement?, type: String) =
        objects(value).filter { it.isType(type) }.mapNotNull { it.str("Name")?.trim()?.ifEmpty { null } }

    private fun names(value: JsonElement?) = objects(value).mapNotNull { it.str("Name")?.trim()?.ifEmpty { null } }

    private fun objects(value: JsonElement?): List<JsonObject> = (value as? JsonArray)?.filterIsInstance<JsonObject>().orEmpty()

    /** Strings of a JSON array or a Kotlin list, trimmed, blanks dropped. */
    private fun stringList(value: Any?): List<String> {
        val raw = when (value) {
            is JsonArray -> value.mapNotNull { (it as? JsonPrimitive)?.takeIf { p -> p.isString }?.content }
            is List<*> -> value.filterIsInstance<String>()
            else -> emptyList()
        }
        return raw.map { it.trim() }.filter { it.isNotEmpty() }
    }

    private fun strings(values: List<String>) = JsonArray(values.map(::JsonPrimitive))

    private fun namePairArray(names: JsonElement?) = JsonArray(stringList(names).map { JsonObject(mapOf("Name" to JsonPrimitive(it))) })
}
