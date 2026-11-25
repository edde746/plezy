package com.edde746.plezy.jellyfin

import com.edde746.plezy.model.LibraryFilter
import com.edde746.plezy.model.LibraryQuery
import com.edde746.plezy.model.LibrarySort
import com.edde746.plezy.model.LibrarySortDirection
import com.edde746.plezy.model.MediaFilterField
import com.edde746.plezy.model.MediaKind

/**
 * A neutral [LibraryQuery] as `/Items` parameters for one user's browse of library [parentId], asking for [fields].
 * Kept apart from the client so the filter and sort name mappings are testable without HTTP.
 */
internal class JellyfinLibraryQueryTranslator(val userId: String, val parentId: String, val fields: String) {
    fun toQueryParameters(query: LibraryQuery): LinkedHashMap<String, String> {
        val params = linkedMapOf(
            "userId" to userId,
            "ParentId" to parentId,
            "Recursive" to "true",
            "StartIndex" to query.offset.toString(),
            "Limit" to query.limit.toString(),
            "EnableTotalRecordCount" to "true",
            "IncludeItemTypes" to includeTypesFor(query),
            "Fields" to fields,
        )
        params.putAll(JellyfinCore.IMAGE_PARAMS)
        applyFilterClauses(query.filters, params)
        // Unsorted, the server lists by `SortName`, which the app shows as the title order; a season's and an
        // episode's isn't their title ([sortFieldFor]), so they ask for the title order.
        val sort = query.sort ?: LibrarySort("title", LibrarySortDirection.ASCENDING).takeIf { query.kind == MediaKind.SEASON || query.kind == MediaKind.EPISODE }
        sort?.let {
            params["SortBy"] = sortFieldFor(it.field, query.kind)
            params["SortOrder"] = if (it.direction == LibrarySortDirection.DESCENDING) "Descending" else "Ascending"
        }
        if (!query.search.isNullOrEmpty()) params["SearchTerm"] = query.search
        val prefix = query.nameStartsWith
        if (!prefix.isNullOrEmpty()) {
            // `#` is the jump bar's "not a letter": everything sorting before "A", as Jellyfin Web asks.
            if (prefix == "#") params["NameLessThan"] = "A" else params["NameStartsWith"] = prefix
        }
        return params
    }

    companion object {
        /**
         * Only the two booleans can be negated on `/Items` (`IsPlayed`; favourites have no exclusion and a negated
         * clause is dropped). Values of one clause OR. `/Items` cannot AND two clauses on one field, so the first wins.
         */
        private fun applyFilterClauses(clauses: List<LibraryFilter>, params: MutableMap<String, String>) {
            val wireFilters = mutableListOf<String>()
            val claimed = mutableSetOf<String>()
            for (clause in clauses) {
                val values = clause.values.filter { it.isNotEmpty() }
                if (values.isEmpty() || !claimed.add(clause.field)) continue
                val negated = clause.op.isNegated
                when (clause.field) {
                    MediaFilterField.UNWATCHED -> if (values.first() == "1") wireFilters += if (negated) "IsPlayed" else "IsUnplayed"
                    MediaFilterField.FAVORITE -> if (values.first() == "1" && !negated) wireFilters += "IsFavorite"
                    MediaFilterField.GENRE -> params["Genres"] = values.joinToString("|")
                    MediaFilterField.CONTENT_RATING -> params["OfficialRatings"] = values.joinToString("|")
                    MediaFilterField.TAG -> params["Tags"] = values.joinToString("|")
                    MediaFilterField.YEAR -> values.mapNotNull { it.toIntOrNull() }.takeIf { it.isNotEmpty() }?.let { params["Years"] = it.joinToString(",") }
                }
            }
            if (wireFilters.isNotEmpty()) params["Filters"] = wireFilters.joinToString(",")
        }

        private fun includeTypesFor(query: LibraryQuery): String =
            if (query.includeKinds.isNotEmpty()) query.includeKinds.joinToString(",") { includeTypesForKind(it) } else includeTypesForKind(query.kind)

        private fun includeTypesForKind(kind: MediaKind?): String = when (kind) {
            MediaKind.MOVIE -> "Movie"
            MediaKind.SHOW -> "Series"
            MediaKind.SEASON -> "Season"
            MediaKind.EPISODE -> "Episode"
            MediaKind.ARTIST -> "MusicArtist"
            MediaKind.ALBUM -> "MusicAlbum"
            MediaKind.TRACK -> "Audio"
            MediaKind.COLLECTION -> "BoxSet"
            MediaKind.PLAYLIST -> "Playlist"
            MediaKind.CLIP -> "Video,MusicVideo"
            MediaKind.PHOTO -> "Photo"
            else -> "Movie,Series,Episode,Audio"
        }

        /**
         * `/Items`' `SortBy` for a neutral sort key. Title: a season's and an episode's `SortName` isn't their title
         * (Jellyfin builds it from their numbers, "0001" and "001 - 0001 - Pilot"; Emby's season is "Season 1"), and
         * their cards are titled by their show, so they sort by their show's title, then their season and number.
         */
        private fun sortFieldFor(neutral: String, kind: MediaKind?): String = when (neutral) {
            "addedAt", "dateCreated" -> "DateCreated"
            "episode.addedAt" -> "DateLastContentAdded,SortName"
            "originallyAvailableAt", "premiereDate" -> "PremiereDate"
            "lastViewedAt", "datePlayed" -> if (kind == MediaKind.SHOW) "SeriesDatePlayed" else "DatePlayed"
            "title", "name" -> when (kind) {
                MediaKind.SEASON -> "SeriesSortName,IndexNumber"
                MediaKind.EPISODE -> "SeriesSortName,ParentIndexNumber,IndexNumber"
                else -> "SortName"
            }
            "rating", "communityRating" -> "CommunityRating"
            "viewCount", "playCount" -> "PlayCount"
            "productionYear" -> "ProductionYear"
            "runtime" -> "Runtime"
            "officialRating" -> "OfficialRating"
            "criticRating" -> "CriticRating"
            "airTime" -> "AirTime"
            "studio" -> "Studio"
            "random" -> "Random"
            else -> neutral
        }
    }
}
