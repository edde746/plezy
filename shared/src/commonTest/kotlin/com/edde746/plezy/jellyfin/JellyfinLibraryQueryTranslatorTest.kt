package com.edde746.plezy.jellyfin

import com.edde746.plezy.model.LibraryFilter
import com.edde746.plezy.model.LibraryFilterOperator
import com.edde746.plezy.model.LibraryQuery
import com.edde746.plezy.model.LibrarySort
import com.edde746.plezy.model.LibrarySortDirection
import com.edde746.plezy.model.MediaKind
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse

class JellyfinLibraryQueryTranslatorTest {
    private val translator = JellyfinLibraryQueryTranslator(userId = "user-1", parentId = "lib-1", fields = "UserData")

    private fun params(query: LibraryQuery) = translator.toQueryParameters(query)

    @Test
    fun alwaysSetsUserParentRecursiveFieldsAndImageParams() {
        val p = params(LibraryQuery())
        assertEquals("user-1", p["userId"])
        assertEquals("lib-1", p["ParentId"])
        assertEquals("true", p["Recursive"])
        assertEquals("UserData", p["Fields"])
        assertEquals("true", p["EnableTotalRecordCount"])
        assertEquals("Primary,Backdrop,Logo", p["EnableImageTypes"])
        assertEquals("3", p["ImageTypeLimit"])
    }

    @Test
    fun kindsMapToIncludeItemTypes() {
        val cases = mapOf(
            MediaKind.MOVIE to "Movie",
            MediaKind.SHOW to "Series",
            MediaKind.SEASON to "Season",
            MediaKind.EPISODE to "Episode",
            MediaKind.ARTIST to "MusicArtist",
            MediaKind.ALBUM to "MusicAlbum",
            MediaKind.TRACK to "Audio",
            MediaKind.COLLECTION to "BoxSet",
            MediaKind.PLAYLIST to "Playlist",
            MediaKind.CLIP to "Video,MusicVideo",
            MediaKind.PHOTO to "Photo",
        )
        for ((kind, wire) in cases) assertEquals(wire, params(LibraryQuery(kind = kind))["IncludeItemTypes"], kind.name)
        assertEquals("Movie,Series,Episode,Audio", params(LibraryQuery())["IncludeItemTypes"])
    }

    @Test
    fun includeKindsWinOverKind() {
        assertEquals("Movie,Series", params(LibraryQuery(kind = MediaKind.EPISODE, includeKinds = listOf(MediaKind.MOVIE, MediaKind.SHOW)))["IncludeItemTypes"])
    }

    @Test
    fun valueClausesJoinWithTheirSeparators() {
        val p = params(
            LibraryQuery(
                filters = listOf(
                    LibraryFilter("genre", listOf("Action", "Drama")),
                    LibraryFilter("year", listOf("2020", "2021")),
                    LibraryFilter("contentRating", listOf("PG", "R")),
                    LibraryFilter("tag", listOf("Holiday", "Archive")),
                ),
            ),
        )
        assertEquals("Action|Drama", p["Genres"])
        assertEquals("2020,2021", p["Years"])
        assertEquals("PG|R", p["OfficialRatings"])
        assertEquals("Holiday|Archive", p["Tags"])
    }

    @Test
    fun fieldsMediaBrowserCannotFilterOnAreDropped() {
        val p = params(LibraryQuery(filters = listOf(LibraryFilter("director", listOf("12345")), LibraryFilter("file", listOf("1080p")))))
        assertFalse("director" in p)
        assertFalse("file" in p)
        assertFalse("Filters" in p)
    }

    @Test
    fun secondClauseOnOneFieldIsDropped() {
        val p = params(LibraryQuery(filters = listOf(LibraryFilter("genre", listOf("Action")), LibraryFilter("genre", listOf("Drama")))))
        assertEquals("Action", p["Genres"])
    }

    @Test
    fun sortFieldsMapToItemSortBy() {
        val title = params(LibraryQuery(sort = LibrarySort("title", LibrarySortDirection.ASCENDING)))
        assertEquals("SortName", title["SortBy"])
        assertEquals("Ascending", title["SortOrder"])
        val added = params(LibraryQuery(sort = LibrarySort("addedAt")))
        assertEquals("DateCreated", added["SortBy"])
        assertEquals("Descending", added["SortOrder"])
        val cases = mapOf(
            "rating" to "CommunityRating",
            "criticRating" to "CriticRating",
            "viewCount" to "PlayCount",
            "productionYear" to "ProductionYear",
            "runtime" to "Runtime",
            "officialRating" to "OfficialRating",
            "originallyAvailableAt" to "PremiereDate",
            "airTime" to "AirTime",
            "studio" to "Studio",
            "random" to "Random",
            "episode.addedAt" to "DateLastContentAdded,SortName",
        )
        for ((key, wire) in cases) assertEquals(wire, params(LibraryQuery(sort = LibrarySort(key)))["SortBy"], key)
    }

    @Test
    fun datePlayedSortIsSeriesSpecificForShows() {
        assertEquals("SeriesDatePlayed", params(LibraryQuery(kind = MediaKind.SHOW, sort = LibrarySort("lastViewedAt")))["SortBy"])
        assertEquals("DatePlayed", params(LibraryQuery(kind = MediaKind.MOVIE, sort = LibrarySort("lastViewedAt")))["SortBy"])
    }

    @Test
    fun seasonsAndEpisodesSortByShowTitleThenNumberUnderTitleOrUnsorted() {
        for (sort in listOf(LibrarySort("title", LibrarySortDirection.DESCENDING), null)) {
            val seasons = params(LibraryQuery(kind = MediaKind.SEASON, sort = sort))
            assertEquals("SeriesSortName,IndexNumber", seasons["SortBy"], "$sort")
            assertEquals(if (sort == null) "Ascending" else "Descending", seasons["SortOrder"])
            assertEquals("SeriesSortName,ParentIndexNumber,IndexNumber", params(LibraryQuery(kind = MediaKind.EPISODE, sort = sort))["SortBy"], "$sort")
        }
        assertEquals("SortName", params(LibraryQuery(kind = MediaKind.SHOW, sort = LibrarySort("title")))["SortBy"])
        assertFalse("SortBy" in params(LibraryQuery(kind = MediaKind.MOVIE)))
    }

    @Test
    fun hashPrefixAsksForNamesBeforeA() {
        val hash = params(LibraryQuery(nameStartsWith = "#"))
        assertEquals("A", hash["NameLessThan"])
        assertFalse("NameStartsWith" in hash)
        val letter = params(LibraryQuery(nameStartsWith = "B"))
        assertEquals("B", letter["NameStartsWith"])
        assertFalse("NameLessThan" in letter)
    }

    @Test
    fun booleanClausesBecomeFilters() {
        assertEquals("IsUnplayed", params(LibraryQuery(filters = listOf(LibraryFilter("unwatched", listOf("1")))))["Filters"])
        assertEquals("IsPlayed", params(LibraryQuery(filters = listOf(LibraryFilter("unwatched", listOf("1"), LibraryFilterOperator.IS_NOT))))["Filters"])
        assertEquals("IsFavorite", params(LibraryQuery(filters = listOf(LibraryFilter("favorite", listOf("1")))))["Filters"])
        val notFavorite = params(LibraryQuery(filters = listOf(LibraryFilter("favorite", listOf("1"), LibraryFilterOperator.IS_NOT))))
        assertFalse("Filters" in notFavorite)
        assertFalse("isFavorite" in notFavorite)
        val both = params(LibraryQuery(filters = listOf(LibraryFilter("unwatched", listOf("1")), LibraryFilter("favorite", listOf("1")))))
        assertEquals("IsUnplayed,IsFavorite", both["Filters"])
    }

    @Test
    fun searchAndPagingPassThrough() {
        val p = params(LibraryQuery(search = "matrix", offset = 50, limit = 25))
        assertEquals("matrix", p["SearchTerm"])
        assertEquals("50", p["StartIndex"])
        assertEquals("25", p["Limit"])
    }
}
