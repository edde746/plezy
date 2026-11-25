package com.edde746.plezy.catalog

import com.edde746.plezy.trackers.ids.FribbIndex
import com.edde746.plezy.trackers.ids.FribbRow

/** A Fribb mapping of [rows] that counts how often the anime catalogs read it. */
internal class FixedAnimeMappings(rows: List<FribbRow>) : FribbIndexSource {
    private val index = FribbIndex.Builder().apply { rows.forEach { add(it) } }.build()
    var fribbReads = 0
        private set

    override suspend fun fribb(): FribbIndex {
        fribbReads++
        return index
    }
}

/** Attack on Titan, a split-cour show: one row per season under the same TVDB id. */
internal val aotSeason1 = FribbRow(mal = 16498, anilist = 16498, simkl = 43665, tvdb = 267440, tvdbSeason = 1, imdb = listOf("tt2560140"))
internal val aotSeason3 = FribbRow(mal = 35760, anilist = 35760, tvdb = 267440, tvdbSeason = 3, tmdbSeason = 2, imdb = listOf("tt2560140"))

/** Your Name., an anime film. */
internal val yourNameMovie = FribbRow(mal = 32281, anilist = 21519, tmdbMovies = listOf(372058), imdb = listOf("tt5311514"), type = "MOVIE")
