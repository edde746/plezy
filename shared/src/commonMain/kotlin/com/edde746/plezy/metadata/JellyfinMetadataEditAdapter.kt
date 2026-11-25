package com.edde746.plezy.metadata

import com.edde746.plezy.jellyfin.JellyfinClient
import com.edde746.plezy.jellyfin.JellyfinMetadataEditDto
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.strings.T
import kotlin.coroutines.cancellation.CancellationException
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.intOrNull

/**
 * Jellyfin's and Emby's editor: the item's whole DTO is loaded and posted back with the changed fields, keeping the
 * ids of people and studios that stay. No advanced section and no locking: the server's locks are posted as read.
 */
class JellyfinMetadataEditAdapter(override val client: JellyfinClient) : MetadataEditAdapter {
    override suspend fun load(item: MediaItem): MetadataDraft {
        val raw = client.fetchEditableMetadataItem(item.id)
            ?: throw IllegalStateException("Editable MediaBrowser metadata item is unavailable")
        val values = JellyfinMetadataEditDto.readValues(raw, item) + artworkValues(item)
        return MetadataDraft(sourceItem = item, currentItem = item, values = values, raw = raw)
    }

    override fun schema(draft: MetadataDraft): List<MetadataSection> {
        val kind = draft.sourceItem.kind
        val m = T.metadataEdit
        return listOfNotNull(
            MetadataSection("basic", m.basicInfo, metadataBasicFields(kind, studioType = MetadataFieldType.STRING_LIST)),
            tagFields(kind).takeIf { it.isNotEmpty() }?.let { MetadataSection("tags", m.tags, it) },
            MetadataSection("artwork", m.artwork, metadataArtworkFields(kind, posterKey = "Primary", backdropKey = "Backdrop", logoKey = "Logo")),
        )
    }

    /**
     * `POST /Items/{id}` with the changed fields applied to a fresh read of the DTO, so server-side changes made while
     * the editor was open survive; the DTO read at load stands in when that read fails.
     */
    override suspend fun save(draft: MetadataDraft): MetadataDraft? {
        val loaded = draft.raw ?: return null
        val raw = try {
            client.fetchEditableMetadataItem(draft.sourceItem.id)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "Editable metadata re-read failed; saving over the loaded DTO" }
            null
        } ?: loaded
        val changes = buildMap {
            for (id in SCALARS) if (draft.fieldChanged(id)) put(id, draft.text(id))
            for (id in LISTS) if (!metadataStringListEquals(draft.values[id], draft.originalValues[id])) put(id, draft.list(id))
        }
        val dto = JellyfinMetadataEditDto.applyEdits(raw, changes, client.dialect.metadataWritesUseNamePairLists)
        if (!client.updateMetadataItem(draft.sourceItem.id, dto)) return null
        return draft.copy(raw = dto).accepted()
    }

    /** The server-wide `Tags` (labels) or `Genres`; no request for other fields. */
    override suspend fun tagSuggestions(draft: MetadataDraft, field: MetadataField): List<String> = when (field.id) {
        "label" -> client.fetchTagFacetValues("Tags")
        "genre" -> client.fetchTagFacetValues("Genres")
        else -> emptyList()
    }

    /** The image providers' candidates (`RemoteImages`); a failed request throws. */
    override suspend fun artwork(draft: MetadataDraft, field: MetadataField): List<ArtworkOption> {
        val type = field.artwork?.key ?: return emptyList()
        val images = client.getRemoteImages(draft.sourceItem.id, type)["Images"] as? JsonArray ?: return emptyList()
        return images.filterIsInstance<JsonObject>().mapNotNull { image ->
            val url = image.string("Url").orEmpty()
            if (url.isEmpty()) return@mapNotNull null
            ArtworkOption(
                id = url,
                thumbnailPath = image.string("ThumbnailUrl")?.ifEmpty { null } ?: url,
                sourceUrl = url,
                provider = image.string("ProviderName"),
                width = (image["Width"] as? JsonPrimitive)?.intOrNull,
                height = (image["Height"] as? JsonPrimitive)?.intOrNull,
            )
        }
    }

    override suspend fun applyArtworkFromUrl(draft: MetadataDraft, field: MetadataField, url: String): Boolean {
        val type = field.artwork?.key ?: return false
        if (url.isBlank()) return false
        return client.downloadRemoteImage(draft.sourceItem.id, type, url.trim())
    }

    override suspend fun uploadArtwork(draft: MetadataDraft, field: MetadataField, bytes: ByteArray, fileName: String?): Boolean {
        val type = field.artwork?.key ?: return false
        if (bytes.isEmpty()) return false
        return client.uploadItemImage(draft.sourceItem.id, type, bytes, JellyfinMetadataEditDto.imageContentType(bytes, fileName))
    }

    override fun withReloadedArtwork(draft: MetadataDraft, item: MediaItem): MetadataDraft =
        draft.copy(currentItem = item, values = draft.values + artworkValues(item))

    private fun artworkValues(item: MediaItem): Map<String, Any?> = mapOf(
        "artwork:Primary" to item.thumbPath,
        "artwork:Backdrop" to item.artPath,
        "artwork:Logo" to item.clearLogoPath,
    )

    private fun tagFields(kind: MediaKind): List<MetadataField> {
        val m = T.metadataEdit
        return when (kind) {
            MediaKind.MOVIE, MediaKind.SHOW -> listOf(
                tagField("genre", m.genre), tagField("director", m.director), tagField("writer", m.writer),
                tagField("producer", m.producer), tagField("country", m.country), tagField("label", m.label),
            )
            MediaKind.EPISODE -> listOf(tagField("director", m.director), tagField("writer", m.writer))
            else -> emptyList()
        }
    }

    private fun JsonObject.string(key: String): String? = (this[key] as? JsonPrimitive)?.takeIf { it.isString }?.content

    private companion object {
        const val TAG = "JellyfinMetadataEdit"
        val SCALARS = listOf("title", "titleSort", "originalTitle", "originallyAvailableAt", "contentRating", "summary", "tagline")
        val LISTS = listOf("studio", "genre", "country", "label", "director", "writer", "producer")
    }
}
