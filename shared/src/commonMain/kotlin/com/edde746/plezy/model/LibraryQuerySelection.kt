package com.edde746.plezy.model

private const val DESC_SUFFIX = ":desc"
private const val ASC_SUFFIX = ":asc"

/** A Plex-style sort string (`field`, `field:asc`, `field:desc`) as a [LibrarySort]; null when empty or without a field. */
fun parseSortParam(raw: String?): LibrarySort? {
    if (raw.isNullOrEmpty()) return null
    val descending = raw.endsWith(DESC_SUFFIX)
    val field = when {
        descending -> raw.removeSuffix(DESC_SUFFIX)
        else -> raw.removeSuffix(ASC_SUFFIX)
    }
    if (field.isEmpty()) return null
    return LibrarySort(field, if (descending) LibrarySortDirection.DESCENDING else LibrarySortDirection.ASCENDING)
}

/**
 * The neutral query a library browse runs. [clauses] is the user's filter selection; [typeParam] the grouping's Plex
 * metadata type: a single number becomes [LibraryQuery.kind], a comma list stays a `type` clause so Plex still
 * receives it verbatim. [libraryKind] overrides [typeParam]. [sortParam] is the sort sheet's `field:desc` string.
 */
fun libraryQueryFromSelection(
    clauses: List<LibraryFilter>,
    libraryKind: MediaKind? = null,
    typeParam: String? = null,
    sortParam: String? = null,
    alphaPrefix: String? = null,
    search: String? = null,
    offset: Int = 0,
    limit: Int = 50,
): LibraryQuery {
    val type = typeParam?.ifEmpty { null }
    val typeList = type?.takeIf { ',' in it }?.split(',')
    val kindFromType = if (type != null && typeList == null) kindForPlexType(type.toIntOrNull()) else null
    val kind = libraryKind ?: kindFromType
    val filters = if (typeList != null) clauses + LibraryFilter("type", typeList) else clauses
    return LibraryQuery(
        kind = kind?.takeIf { it != MediaKind.UNKNOWN },
        offset = offset,
        limit = limit,
        nameStartsWith = alphaPrefix?.ifEmpty { null },
        search = search?.ifEmpty { null },
        sort = parseSortParam(sortParam),
        filters = filters,
    )
}

/** The kind a Plex metadata type number names; null for every other number. */
private fun kindForPlexType(type: Int?): MediaKind? = when (type) {
    1 -> MediaKind.MOVIE
    2 -> MediaKind.SHOW
    3 -> MediaKind.SEASON
    4 -> MediaKind.EPISODE
    8 -> MediaKind.ARTIST
    9 -> MediaKind.ALBUM
    10 -> MediaKind.TRACK
    else -> null
}
