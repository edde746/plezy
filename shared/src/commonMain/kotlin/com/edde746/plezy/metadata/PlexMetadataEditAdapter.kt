package com.edde746.plezy.metadata

import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.lang.LanguageNames
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.plex.PlexClient
import com.edde746.plezy.plex.PlexMetadataType
import com.edde746.plezy.plex.PlexTagChange
import com.edde746.plezy.plex.fetchEditableItem
import com.edde746.plezy.plex.getAvailableArtwork
import com.edde746.plezy.plex.getFilterValues
import com.edde746.plezy.plex.getLibraryFilters
import com.edde746.plezy.plex.getMetadataPrefs
import com.edde746.plezy.plex.setArtworkFromUrl
import com.edde746.plezy.plex.updateMetadata
import com.edde746.plezy.plex.updateMetadataPrefs
import com.edde746.plezy.plex.uploadArtwork
import com.edde746.plezy.strings.T
import kotlin.coroutines.cancellation.CancellationException
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.booleanOrNull

/**
 * Plex's editor: the item's fields, its tags (locked on save), its artwork and, but for episodes, its per-item
 * preferences ("Advanced Settings"), which save as they are picked.
 */
class PlexMetadataEditAdapter(override val client: PlexClient) : MetadataEditAdapter {
    /**
     * Always the item's own full metadata: a list or hub row can carry a summary and library id yet omit genres,
     * labels and credits, and a save diffs tags against what was loaded, so a partial row would drop the tags it never
     * showed. A failed preferences request leaves the advanced settings unset, unless it was cancelled.
     */
    override suspend fun load(item: MediaItem): MetadataDraft {
        val full = client.fetchEditableItem(item.id) ?: throw IllegalStateException("Editable Plex metadata item is unavailable")
        val preferences = if (full.kind == MediaKind.EPISODE) {
            emptyMap()
        } else {
            try {
                client.getMetadataPrefs(full.id)
            } catch (e: CancellationException) {
                throw e
            } catch (e: MediaServerHttpException) {
                if (e.isCancellation) throw e
                Log.w(TAG, e) { "Plex metadata preferences unavailable; continuing without advanced values" }
                emptyMap()
            }
        }
        val values = commonValues(full) + artworkValues(full) + advancedKeys(full.kind).associate { "pref:$it" to preferences[it] }
        return MetadataDraft(sourceItem = item, currentItem = full, values = values)
    }

    override fun schema(draft: MetadataDraft): List<MetadataSection> {
        val kind = draft.sourceItem.kind
        val m = T.metadataEdit
        return listOfNotNull(
            MetadataSection("basic", m.basicInfo, metadataBasicFields(kind)),
            tagFields(kind).takeIf { it.isNotEmpty() }?.let { MetadataSection("tags", m.tags, it) },
            MetadataSection("artwork", m.artwork, artworkFields(kind)),
            if (kind != MediaKind.EPISODE) MetadataSection("advanced", m.advancedSettings, advancedFields(kind)) else null,
        )
    }

    /** One `PUT …/all` of the changed fields and tags; false without a request when the item has no numeric section. */
    override suspend fun save(draft: MetadataDraft): MetadataDraft? {
        val sectionId = sectionId(draft) ?: return null
        val tagChanges = tagFields(draft.sourceItem.kind).filter(draft::changed).associate {
            it.id to PlexTagChange(current = draft.list(it.id), original = metadataStringList(draft.originalValues[it.id]))
        }
        fun changed(id: String) = if (draft.fieldChanged(id)) draft.text(id).orEmpty() else null
        val success = client.updateMetadata(
            sectionId = sectionId,
            ratingKey = draft.sourceItem.id,
            typeNumber = PlexMetadataType.forKind(draft.sourceItem.kind) ?: 0,
            title = changed("title"),
            titleSort = changed("titleSort"),
            originalTitle = changed("originalTitle"),
            originallyAvailableAt = changed("originallyAvailableAt"),
            contentRating = changed("contentRating"),
            studio = changed("studio"),
            tagline = changed("tagline"),
            summary = changed("summary"),
            tagChanges = tagChanges.ifEmpty { null },
        )
        return if (success) draft.accepted() else null
    }

    /** `PUT /library/metadata/{id}/prefs`, a cleared choice sent as `''`. */
    override suspend fun saveImmediate(draft: MetadataDraft, field: MetadataField, value: String?): MetadataDraft? {
        val key = field.id.removePrefix("pref:")
        if (!client.updateMetadataPrefs(draft.sourceItem.id, mapOf(key to value.orEmpty()))) return null
        return draft.with(field.id, value).copy(originalValues = draft.originalValues + (field.id to value))
    }

    /** The section's `label` or `genre` filter values; none for other fields, an item without a section, or a failure. */
    override suspend fun tagSuggestions(draft: MetadataDraft, field: MetadataField): List<String> {
        val filterName = when (field.id) {
            "label" -> "label"
            "genre" -> "genre"
            else -> return emptyList()
        }
        val sectionId = sectionId(draft) ?: return emptyList()
        return try {
            val filter = client.getLibraryFilters(sectionId.toString()).firstOrNull { it.filter == filterName }
            if (filter == null || filter.key.isEmpty()) return emptyList()
            client.getFilterValues(filter.key).map { it.title }.filter { it.isNotEmpty() }
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "Plex tag suggestions unavailable" }
            emptyList()
        }
    }

    override suspend fun artwork(draft: MetadataDraft, field: MetadataField): List<ArtworkOption> {
        val element = field.artwork?.key ?: return emptyList()
        return client.getAvailableArtwork(draft.sourceItem.id, element).mapNotNull { json ->
            val source = json.string("ratingKey") ?: json.string("key") ?: ""
            if (source.isEmpty()) return@mapNotNull null
            ArtworkOption(
                id = source,
                thumbnailPath = json.string("thumb") ?: source,
                sourceUrl = source,
                selected = (json["selected"] as? JsonPrimitive)?.booleanOrNull == true,
            )
        }
    }

    override suspend fun applyArtworkFromUrl(draft: MetadataDraft, field: MetadataField, url: String): Boolean {
        val element = field.artwork?.key ?: return false
        if (url.isBlank()) return false
        return client.setArtworkFromUrl(draft.sourceItem.id, element, url.trim())
    }

    override suspend fun uploadArtwork(draft: MetadataDraft, field: MetadataField, bytes: ByteArray, fileName: String?): Boolean {
        val element = field.artwork?.key ?: return false
        if (bytes.isEmpty()) return false
        return client.uploadArtwork(draft.sourceItem.id, element, bytes)
    }

    override fun withReloadedArtwork(draft: MetadataDraft, item: MediaItem): MetadataDraft =
        draft.copy(currentItem = item, values = draft.values + artworkValues(item))

    private fun sectionId(draft: MetadataDraft): Int? = (draft.currentItem.libraryId ?: draft.sourceItem.libraryId)?.toIntOrNull()

    private fun commonValues(item: MediaItem): Map<String, Any?> = mapOf(
        "title" to item.title.orEmpty(),
        "titleSort" to item.titleSort.orEmpty(),
        "originalTitle" to item.originalTitle.orEmpty(),
        "originallyAvailableAt" to item.originallyAvailableAt.orEmpty(),
        "contentRating" to item.contentRating.orEmpty(),
        "studio" to item.studio.orEmpty(),
        "tagline" to item.tagline.orEmpty(),
        "summary" to item.summary.orEmpty(),
        "genre" to item.genres.orEmpty(),
        "director" to item.directors.orEmpty(),
        "writer" to item.writers.orEmpty(),
        "producer" to item.producers.orEmpty(),
        "country" to item.countries.orEmpty(),
        "collection" to item.collections.orEmpty(),
        "label" to item.labels.orEmpty(),
        // Loaded so a save never loses them; Plex's editor has no field for them.
        "style" to item.styles.orEmpty(),
        "mood" to item.moods.orEmpty(),
    )

    private fun artworkValues(item: MediaItem): Map<String, Any?> = mapOf(
        "artwork:posters" to item.thumbPath,
        "artwork:arts" to item.artPath,
        "artwork:clearLogos" to item.clearLogoPath,
        "artwork:squareArts" to item.backgroundSquarePath,
    )

    private fun advancedKeys(kind: MediaKind): List<String> = buildList {
        if (kind == MediaKind.SHOW) addAll(listOf("episodeSort", "autoDeletionItemPolicyUnwatchedLibrary", "autoDeletionItemPolicyWatchedLibrary", "flattenSeasons", "showOrdering"))
        if (kind == MediaKind.SHOW || kind == MediaKind.MOVIE) addAll(listOf("languageOverride", "useOriginalTitle"))
        if (kind == MediaKind.SHOW || kind == MediaKind.SEASON) addAll(listOf("audioLanguage", "subtitleLanguage", "subtitleMode"))
    }

    private fun tagFields(kind: MediaKind): List<MetadataField> {
        val m = T.metadataEdit
        return when (kind) {
            MediaKind.MOVIE, MediaKind.SHOW -> listOf(
                tagField("genre", m.genre), tagField("director", m.director), tagField("writer", m.writer),
                tagField("producer", m.producer), tagField("country", m.country), tagField("collection", m.collection),
                tagField("label", m.label),
            )
            MediaKind.EPISODE -> listOf(tagField("director", m.director), tagField("writer", m.writer))
            else -> emptyList()
        }
    }

    private fun artworkFields(kind: MediaKind) = metadataArtworkFields(
        kind, posterKey = "posters", backdropKey = "arts", logoKey = "clearLogos", squareKey = "squareArts",
        logoKinds = setOf(MediaKind.MOVIE, MediaKind.SHOW, MediaKind.COLLECTION),
    )

    private fun advancedFields(kind: MediaKind): List<MetadataField> {
        val m = T.metadataEdit
        val o = ::MetadataOption
        return when (kind) {
            MediaKind.SHOW -> listOf(
                choice("episodeSort", m.episodeSorting, o("-1", m.libraryDefault), o("0", m.oldestFirst), o("1", m.newestFirst)),
                choice(
                    "autoDeletionItemPolicyUnwatchedLibrary", m.keep,
                    o("0", m.allEpisodes), o("5", m.latestEpisodes("5")), o("3", m.latestEpisodes("3")), o("1", m.latestEpisode),
                    o("-3", m.episodesAddedPastDays("3")), o("-7", m.episodesAddedPastDays("7")), o("-30", m.episodesAddedPastDays("30")),
                ),
                choice(
                    "autoDeletionItemPolicyWatchedLibrary", m.deleteAfterPlaying,
                    o("0", m.never), o("1", m.afterADay), o("7", m.afterAWeek), o("30", m.afterAMonth), o("100", m.onNextRefresh),
                ),
                choice("flattenSeasons", m.seasons, o("-1", m.libraryDefault), o("0", m.show), o("1", m.hide)),
                choice(
                    "showOrdering", m.episodeOrdering,
                    o("", m.libraryDefault), o("tmdbAiring", m.tmdbAiring), o("tvdbAiring", m.tvdbAiring), o("tvdbAbsolute", m.tvdbAbsolute),
                ),
            ) + metadataLanguageFields() + audioSubtitleFields(m.accountDefault)
            MediaKind.MOVIE -> metadataLanguageFields()
            MediaKind.SEASON -> audioSubtitleFields(m.seriesDefault)
            else -> emptyList()
        }
    }

    private fun metadataLanguageFields(): List<MetadataField> {
        val m = T.metadataEdit
        return listOf(
            choice("languageOverride", m.metadataLanguage, *PlexLanguages.options(m.libraryDefault, PlexLanguages.locales).toTypedArray()),
            choice(
                "useOriginalTitle", m.useOriginalTitle,
                MetadataOption("-1", m.libraryDefault), MetadataOption("0", T.common.no), MetadataOption("1", T.common.yes),
            ),
        )
    }

    private fun audioSubtitleFields(defaultLabel: String): List<MetadataField> {
        val m = T.metadataEdit
        val languages = PlexLanguages.options(defaultLabel, PlexLanguages.audioSubtitle).toTypedArray()
        return listOf(
            choice("audioLanguage", m.preferredAudioLanguage, *languages),
            choice("subtitleLanguage", m.preferredSubtitleLanguage, *languages),
            choice(
                "subtitleMode", m.subtitleMode,
                MetadataOption("-1", defaultLabel), MetadataOption("0", m.manuallySelected),
                MetadataOption("1", m.shownWithForeignAudio), MetadataOption("2", m.alwaysEnabled),
            ),
        )
    }

    private fun choice(prefKey: String, label: String, vararg options: MetadataOption) =
        MetadataField("pref:$prefKey", label, MetadataFieldType.CHOICE, MetadataSaveMode.IMMEDIATE, options.toList())

    private fun kotlinx.serialization.json.JsonObject.string(key: String): String? =
        (this[key] as? JsonPrimitive)?.takeIf { it.isString }?.content

    private companion object {
        const val TAG = "PlexMetadataEdit"
    }
}

/**
 * The languages Plex's per-item preferences take: its 45 metadata locales, and for audio and subtitles nine common
 * languages before them. Named in English, each locale with its region ("English (Australia)"), whatever the app's
 * language, as Plex's own editor names them.
 */
internal object PlexLanguages {
    val locales = listOf(
        "ar-SA", "bg-BG", "ca-ES", "zh-CN", "zh-HK", "zh-TW", "hr-HR", "cs-CZ", "da-DK", "nl-NL", "en-US", "en-AU", "en-CA",
        "en-GB", "et-EE", "fi-FI", "fr-FR", "fr-CA", "de-DE", "el-GR", "he-IL", "hi-IN", "hu-HU", "is-IS", "id-ID", "it-IT",
        "ja-JP", "ko-KR", "lv-LV", "lt-LT", "nb-NO", "fa-IR", "pl-PL", "pt-BR", "pt-PT", "ro-RO", "ru-RU", "sk-SK", "es-ES",
        "es-MX", "sv-SE", "th-TH", "tr-TR", "uk-UA", "vi-VN",
    )

    val audioSubtitle = listOf("en", "ja", "fr", "de", "it", "es", "pt", "ru", "ar") + locales

    private val regions = mapOf(
        "AU" to "Australia", "BR" to "Brazil", "CA" to "Canada", "GB" to "UK", "HK" to "Hong Kong", "MX" to "Mexico",
        "PT" to "Portugal", "TW" to "Taiwan",
    )

    fun options(defaultLabel: String, codes: List<String>): List<MetadataOption> =
        listOf(MetadataOption("", defaultLabel)) + codes.map { MetadataOption(it, displayName(it)) }

    /** `en` → "English", `en-US` → "English", `en-AU` → "English (Australia)". */
    fun displayName(code: String): String {
        val language = code.substringBefore('-')
        val name = LanguageNames.displayName(language, "en") ?: language
        val region = regions[code.substringAfter('-', "")]
        return if (region != null) "$name ($region)" else name
    }
}

