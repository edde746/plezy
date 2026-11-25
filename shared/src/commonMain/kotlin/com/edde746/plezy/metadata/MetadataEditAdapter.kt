package com.edde746.plezy.metadata

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.jellyfin.JellyfinClient
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.plex.PlexClient

/**
 * A backend's metadata editor: what an item's editor shows ([schema]), how it loads and saves, and its artwork. Drafts
 * are values: every change returns a new one. A save returns the accepted draft, or null when the server refused.
 */
interface MetadataEditAdapter {
    val client: MediaBackend

    fun supportsKind(kind: MediaKind): Boolean =
        kind == MediaKind.MOVIE || kind == MediaKind.SHOW || kind == MediaKind.SEASON || kind == MediaKind.EPISODE

    /** The item as the server holds it now; throws when the server has no editable copy. */
    suspend fun load(item: MediaItem): MetadataDraft

    fun schema(draft: MetadataDraft): List<MetadataSection>

    /** A field that waits for Save differs from the server's value; immediate fields never count. */
    fun hasChanges(draft: MetadataDraft): Boolean =
        schema(draft).flatMap { it.fields }.any { it.saveMode == MetadataSaveMode.DRAFT && draft.changed(it) }

    suspend fun save(draft: MetadataDraft): MetadataDraft?

    /** Saves [value] of the immediate [field] alone. */
    suspend fun saveImmediate(draft: MetadataDraft, field: MetadataField, value: String?): MetadataDraft? =
        save(draft.with(field.id, value))

    /** The server's own values for a tag field (its labels, its genres); empty where it lists none. */
    suspend fun tagSuggestions(draft: MetadataDraft, field: MetadataField): List<String> = emptyList()

    suspend fun artwork(draft: MetadataDraft, field: MetadataField): List<ArtworkOption>

    suspend fun applyArtworkFromUrl(draft: MetadataDraft, field: MetadataField, url: String): Boolean

    suspend fun uploadArtwork(draft: MetadataDraft, field: MetadataField, bytes: ByteArray, fileName: String?): Boolean

    /** The item again after an artwork change. */
    suspend fun reloadItem(draft: MetadataDraft): MediaItem? = client.fetchItem(draft.sourceItem.id)

    /** [draft] showing [item]'s artwork; pending edits stay. */
    fun withReloadedArtwork(draft: MetadataDraft, item: MediaItem): MetadataDraft

    companion object {
        /** The editor of [client]'s backend; null for one without metadata editing. */
        fun of(client: MediaBackend?): MetadataEditAdapter? = when (client) {
            is PlexClient -> PlexMetadataEditAdapter(client)
            is JellyfinClient -> JellyfinMetadataEditAdapter(client)
            else -> null
        }

        /** [client]'s server edits metadata and its editor takes [kind]. */
        fun supports(client: MediaBackend?, kind: MediaKind?): Boolean {
            if (client == null || kind == null || !client.capabilities.richMetadataEdit) return false
            return of(client)?.supportsKind(kind) == true
        }
    }
}
