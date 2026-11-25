package com.edde746.plezy.plex

import com.edde746.plezy.model.LibraryFilter
import com.edde746.plezy.model.LibraryQuery
import com.edde746.plezy.model.LibrarySortDirection
import com.edde746.plezy.model.MediaKind

/** Plex's numeric metadata `type` codes. */
object PlexMetadataType {
    const val MOVIE = 1
    const val SHOW = 2
    const val SEASON = 3
    const val EPISODE = 4
    const val ARTIST = 8
    const val ALBUM = 9
    const val TRACK = 10

    /** Null for kinds Plex has no code for. */
    fun forKind(kind: MediaKind?): Int? = when (kind) {
        MediaKind.MOVIE -> MOVIE
        MediaKind.SHOW -> SHOW
        MediaKind.SEASON -> SEASON
        MediaKind.EPISODE -> EPISODE
        MediaKind.ARTIST -> ARTIST
        MediaKind.ALBUM -> ALBUM
        MediaKind.TRACK -> TRACK
        else -> null
    }

    fun kindFor(type: Int?): MediaKind? = when (type) {
        MOVIE -> MediaKind.MOVIE
        SHOW -> MediaKind.SHOW
        SEASON -> MediaKind.SEASON
        EPISODE -> MediaKind.EPISODE
        ARTIST -> MediaKind.ARTIST
        ALBUM -> MediaKind.ALBUM
        TRACK -> MediaKind.TRACK
        else -> null
    }
}

/**
 * [query] as `/library/sections/{id}/all` parameters, in order, a key repeated where Plex should AND: `type` (the
 * include kinds' codes as CSV, else the kind's code), `sort=field:asc|desc`, `title` (search), `alphaPrefix`, then the
 * filter clauses ([plexFilterQueryParameters]). Paging is not included.
 */
fun plexLibraryQueryParameters(query: LibraryQuery): List<Pair<String, String>> = buildList {
    if (query.includeKinds.isNotEmpty()) {
        val codes = query.includeKinds.mapNotNull(PlexMetadataType::forKind).joinToString(",")
        if (codes.isNotEmpty()) add("type" to codes)
    } else {
        PlexMetadataType.forKind(query.kind)?.let { add("type" to it.toString()) }
    }
    query.sort?.let {
        add("sort" to it.field + if (it.direction == LibrarySortDirection.DESCENDING) ":desc" else ":asc")
    }
    query.search?.takeIf { it.isNotEmpty() }?.let { add("title" to it) }
    query.nameStartsWith?.takeIf { it.isNotEmpty() }?.let { add("alphaPrefix" to it) }
    addAll(plexFilterQueryParameters(query.filters))
}

/**
 * Filter clauses on Plex's vocabulary: the operator rides in the key (`year>>` = `2015`), a clause's values are
 * comma-joined (OR), clauses producing the same key repeat it (AND). Empty fields and clauses without a non-empty value
 * are dropped.
 */
fun plexFilterQueryParameters(clauses: List<LibraryFilter>): List<Pair<String, String>> = clauses.mapNotNull { clause ->
    val values = clause.values.filter { it.isNotEmpty() }
    if (clause.field.isEmpty() || values.isEmpty()) null else (clause.field + clause.op.wireSuffix) to values.joinToString(",")
}
