package com.edde746.plezy.metadata

import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.strings.T
import kotlinx.serialization.json.JsonObject

/** How the editor edits a field, and what its value is: text (`String`), a date (`YYYY-MM-DD`), a tag list, a choice. */
enum class MetadataFieldType { TEXT, MULTILINE_TEXT, DATE, STRING_LIST, CHOICE, ARTWORK }

/** [DRAFT] fields wait for Save; [IMMEDIATE] ones (artwork, Plex's per-item preferences) save as they are picked. */
enum class MetadataSaveMode { DRAFT, IMMEDIATE }

enum class ArtworkFit { COVER, CONTAIN }

data class MetadataOption(val value: String, val label: String)

/**
 * An artwork field's picker: [key] is the backend's artwork kind (Plex's `posters`, MediaBrowser's `Primary`), the
 * preview's size in dp, and the picker grid's columns and tile aspect ratio (width / height).
 */
data class ArtworkConfig(
    val key: String,
    val selectTitle: String,
    val previewWidth: Int,
    val previewHeight: Int,
    val gridColumns: Int,
    val gridAspectRatio: Double,
    val fit: ArtworkFit = ArtworkFit.COVER,
)

data class MetadataField(
    val id: String,
    val label: String,
    val type: MetadataFieldType,
    val saveMode: MetadataSaveMode = MetadataSaveMode.DRAFT,
    val options: List<MetadataOption> = emptyList(),
    val artwork: ArtworkConfig? = null,
)

data class MetadataSection(val id: String, val title: String, val fields: List<MetadataField>)

/** One artwork the server offers: [thumbnailPath] to show, [sourceUrl] to apply. */
data class ArtworkOption(
    val id: String,
    val thumbnailPath: String,
    val sourceUrl: String,
    val selected: Boolean = false,
    val provider: String? = null,
    val width: Int? = null,
    val height: Int? = null,
)

/**
 * An item being edited: its values by field id (a `String`, a `List<String>` or null) beside the values the server
 * holds ([originalValues]), which a successful save replaces. [sourceItem] is the item the editor opened, [currentItem]
 * the server's latest copy. [raw] is the MediaBrowser item DTO a save posts back whole.
 */
data class MetadataDraft(
    val sourceItem: MediaItem,
    val currentItem: MediaItem,
    val values: Map<String, Any?>,
    val originalValues: Map<String, Any?> = values,
    val raw: JsonObject? = null,
) {
    fun text(id: String): String? = values[id] as? String

    fun list(id: String): List<String> = metadataStringList(values[id])

    fun with(id: String, value: Any?): MetadataDraft = copy(values = values + (id to value))

    fun fieldChanged(id: String): Boolean = values[id] != originalValues[id]

    /** The values as the server now holds them. */
    fun accepted(): MetadataDraft = copy(originalValues = values)

    /** [field] differs from what the server holds; tag lists compare as sets of trimmed, non-blank tags. */
    fun changed(field: MetadataField): Boolean = if (field.type == MetadataFieldType.STRING_LIST) {
        !metadataStringListEquals(values[field.id], originalValues[field.id])
    } else {
        values[field.id] != originalValues[field.id]
    }

    /** Per tag field of [fields], the tags added since load: what a save records as recent tags. */
    fun addedTags(fields: List<MetadataField>): Map<String, List<String>> = fields
        .filter { it.type == MetadataFieldType.STRING_LIST }
        .mapNotNull { field ->
            val original = metadataStringList(originalValues[field.id])
            list(field.id).filter { it !in original }.takeIf { it.isNotEmpty() }?.let { field.id to it }
        }
        .toMap()
}

/** Title, sort title, original title, release date, content rating, studio, tagline and summary, as [kind] has them. */
fun metadataBasicFields(kind: MediaKind, studioType: MetadataFieldType = MetadataFieldType.TEXT): List<MetadataField> {
    val movieOrShow = kind == MediaKind.MOVIE || kind == MediaKind.SHOW
    val season = kind == MediaKind.SEASON
    val m = T.metadataEdit
    return listOfNotNull(
        MetadataField("title", m.title, MetadataFieldType.TEXT),
        MetadataField("titleSort", m.sortTitle, MetadataFieldType.TEXT).takeIf { !season },
        MetadataField("originalTitle", m.originalTitle, MetadataFieldType.TEXT).takeIf { movieOrShow },
        MetadataField("originallyAvailableAt", m.releaseDate, MetadataFieldType.DATE).takeIf { !season },
        MetadataField("contentRating", m.contentRating, MetadataFieldType.TEXT).takeIf { !season },
        MetadataField("studio", m.studio, studioType).takeIf { movieOrShow },
        MetadataField("tagline", m.tagline, MetadataFieldType.TEXT).takeIf { movieOrShow },
        MetadataField("summary", m.summary, MetadataFieldType.MULTILINE_TEXT),
    )
}

/**
 * Poster, background, logo and square art as [kind] has them, under each backend's artwork keys: an episode's poster
 * is a 16:9 thumbnail; only [logoKinds] carry a logo, and square art only where the backend has a [squareKey].
 */
fun metadataArtworkFields(
    kind: MediaKind,
    posterKey: String,
    backdropKey: String,
    logoKey: String,
    squareKey: String? = null,
    logoKinds: Set<MediaKind> = setOf(MediaKind.MOVIE, MediaKind.SHOW),
): List<MetadataField> {
    val m = T.metadataEdit
    val fields = mutableListOf(
        if (kind == MediaKind.EPISODE) {
            artworkField(posterKey, m.poster, m.selectPoster, 80, 45, 2, 16.0 / 9)
        } else {
            artworkField(posterKey, m.poster, m.selectPoster, 40, 60, 3, 2.0 / 3)
        },
    )
    if (kind == MediaKind.MOVIE || kind == MediaKind.SHOW || kind == MediaKind.EPISODE) {
        fields += artworkField(backdropKey, m.background, m.selectBackground, 80, 45, 2, 16.0 / 9)
    }
    if (kind in logoKinds) {
        fields += artworkField(logoKey, m.logo, m.selectLogo, 80, 32, 2, 2.5, ArtworkFit.CONTAIN)
        if (squareKey != null) fields += artworkField(squareKey, m.squareArt, m.selectSquareArt, 50, 50, 3, 1.0)
    }
    return fields
}

private fun artworkField(
    key: String,
    label: String,
    title: String,
    width: Int,
    height: Int,
    columns: Int,
    aspect: Double,
    fit: ArtworkFit = ArtworkFit.COVER,
) = MetadataField(
    id = "artwork:$key",
    label = label,
    type = MetadataFieldType.ARTWORK,
    saveMode = MetadataSaveMode.IMMEDIATE,
    artwork = ArtworkConfig(key, title, width, height, columns, aspect, fit),
)

fun tagField(id: String, label: String) = MetadataField(id, label, MetadataFieldType.STRING_LIST)

/** A tag list's tags: strings trimmed, blanks dropped; a lone non-blank string is a list of one. */
fun metadataStringList(value: Any?): List<String> = when (value) {
    is List<*> -> value.filterIsInstance<String>().map { it.trim() }.filter { it.isNotEmpty() }
    is String -> listOfNotNull(value.trim().ifEmpty { null })
    else -> emptyList()
}

/** Order and duplicates aside, the same tags. */
fun metadataStringListEquals(a: Any?, b: Any?): Boolean = metadataStringList(a).toSet() == metadataStringList(b).toSet()

/** `YYYY-MM-DD`, zero-padded. */
fun metadataDate(year: Int, month: Int, day: Int): String =
    "${year.toString().padStart(4, '0')}-${month.toString().padStart(2, '0')}-${day.toString().padStart(2, '0')}"

/** The date of a `YYYY-MM-DD…` value as (year, month, day); null when it doesn't start with one. */
fun parseMetadataDate(value: String?): Triple<Int, Int, Int>? {
    val match = Regex("^(\\d{4})-(\\d{2})-(\\d{2})").find(value?.trim().orEmpty()) ?: return null
    val (y, m, d) = match.destructured
    return Triple(y.toInt(), m.toInt(), d.toInt()).takeIf { it.second in 1..12 && it.third in 1..31 }
}
