package com.edde746.plezy.model

import com.edde746.plezy.net.UriComponent

/** How the filter sheet edits a filter's value. */
enum class FilterEditorKind { TOGGLE, VALUE_LIST, NUMBER, DATE, TEXT }

/** The unit a numeric filter's value is entered in, and its scale to the server's. */
enum class MediaFilterUnit(val scale: Long, val suffix: String?) {
    NONE(1, null),
    DURATION(60_000, "min"),
    FILE_SIZE(1_000_000_000, "GB"),
    ;

    companion object {
        fun fromPlexSubType(subType: Any?): MediaFilterUnit = when (subType) {
            "duration" -> DURATION
            "fileSize" -> FILE_SIZE
            else -> NONE
        }
    }
}

object MediaFilterType {
    const val BOOLEAN = "boolean"
    const val INTEGER = "integer"
    const val DATE = "date"
    const val STRING = "string"
    const val TAG = "tag"
}

object MediaFilterField {
    const val UNWATCHED = "unwatched"
    const val FAVORITE = "favorite"
    const val GENRE = "genre"
    const val YEAR = "year"
    const val CONTENT_RATING = "contentRating"
    const val TAG = "tag"
    const val FILE = "file"
}

/** A filter category a library offers. [key] (when not empty) lists its values. */
data class MediaFilter(
    val filter: String,
    val title: String,
    val filterType: String = MediaFilterType.STRING,
    val key: String = "",
    val type: String = "filter",
    val unit: MediaFilterUnit = MediaFilterUnit.NONE,
    val operators: List<LibraryFilterOperator> = defaultOperatorsFor(filterType),
) {
    val hasValueList: Boolean get() = key.isNotEmpty()
    val isBoolean: Boolean get() = filterType == MediaFilterType.BOOLEAN
    val supportsExclusion: Boolean get() = operators.any { it.isNegated }

    val editorKind: FilterEditorKind
        get() = when {
            isBoolean -> FilterEditorKind.TOGGLE
            hasValueList -> FilterEditorKind.VALUE_LIST
            filterType == MediaFilterType.INTEGER -> FilterEditorKind.NUMBER
            filterType == MediaFilterType.DATE -> FilterEditorKind.DATE
            else -> FilterEditorKind.TEXT
        }

    companion object {
        /** The comparisons a filter type supports when the server lists none (a date only has its two bounds). */
        fun defaultOperatorsFor(filterType: String): List<LibraryFilterOperator> = when (filterType) {
            MediaFilterType.BOOLEAN -> listOf(LibraryFilterOperator.IS, LibraryFilterOperator.IS_NOT)
            MediaFilterType.INTEGER -> listOf(
                LibraryFilterOperator.IS,
                LibraryFilterOperator.IS_NOT,
                LibraryFilterOperator.AT_LEAST,
                LibraryFilterOperator.AT_MOST,
            )
            MediaFilterType.DATE -> listOf(LibraryFilterOperator.AT_LEAST, LibraryFilterOperator.AT_MOST)
            else -> listOf(LibraryFilterOperator.IS, LibraryFilterOperator.IS_NOT)
        }
    }
}

/** One value of a filter. */
data class MediaFilterValue(val key: String, val title: String, val type: String? = null) {
    companion object
}

/** A library's filters, and the values a backend served up front (keyed by [MediaFilter.filter]). */
data class LibraryFilterResult(val filters: List<MediaFilter>, val cachedValues: Map<String, List<MediaFilterValue>>) {
    companion object {
        val EMPTY = LibraryFilterResult(emptyList(), emptyMap())
    }
}

/**
 * The value id a filter value's [key] stands for: its query's [filterName] parameter (the last one when repeated, the
 * whole key without one), else a path's last segment, percent-decoded. Plex lists some ids encoded already (`5%2E1`,
 * `16%2B`): the id a clause keeps is the literal value, as encoding it twice on the wire selects nothing. A segment
 * that isn't a whole encoding (a literal `%` in a tag) is kept as it is.
 */
fun libraryFilterValueId(key: String, filterName: String): String {
    val question = key.indexOf('?')
    if (question >= 0) {
        var value: String? = null
        for (pair in key.substring(question + 1).split('&')) {
            if (pair.isEmpty()) continue
            val eq = pair.indexOf('=')
            val name = decodeQueryPart(if (eq < 0) pair else pair.substring(0, eq))
            if (name == filterName) value = decodeQueryPart(if (eq < 0) "" else pair.substring(eq + 1))
        }
        return value ?: key
    }
    val raw = if (key.startsWith('/')) key.substringAfterLast('/') else key
    if ('%' !in raw || !PERCENT_ENCODED.matches(raw)) return raw
    val decoded = UriComponent.decode(raw)
    // Escapes that aren't UTF-8 aren't an encoding either.
    return if ('\uFFFD' in decoded && '\uFFFD' !in raw) raw else decoded
}

private val PERCENT_ENCODED = Regex("(?:[^%]|%[0-9A-Fa-f]{2})*")

private fun decodeQueryPart(part: String): String =
    UriComponent.decode(part.replace('+', ' '))
