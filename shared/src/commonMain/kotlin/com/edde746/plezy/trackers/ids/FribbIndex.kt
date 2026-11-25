package com.edde746.plezy.trackers.ids

import com.edde746.plezy.model.ImdbId
import com.edde746.plezy.trackers.AnimeIds

/**
 * One row of Fribb's `anime-list-mini.json` (https://github.com/Fribb/anime-lists): an anime list entry (AniDB,
 * MyAnimeList, AniList, Simkl) with the external ids of the show or film it belongs to. Absent keys and empty lists
 * are `null`.
 *
 * @property tmdbTv the TMDB series (`themoviedb_id: {"tv": id}`).
 * @property tmdbMovies the TMDB films (`themoviedb_id: {"movie": [ids]}`). TMDB numbers films and series apart, so the
 *   two are never mixed.
 * @property imdb the IMDb ids (`imdb_id` is a list), in IMDb's seven-digit form.
 * @property tvdbSeason the TVDB season this entry is (a split-cour show has one row per season); 0 for specials.
 */
internal data class FribbRow(
    /** `TV`, `MOVIE`, `OVA`, `ONA`, `SPECIAL`, `UNKNOWN`, …, or `null`. */
    val type: String? = null,
    val anidb: Int? = null,
    val mal: Int? = null,
    val anilist: Int? = null,
    val simkl: Int? = null,
    val imdb: List<String>? = null,
    val tmdbTv: Int? = null,
    val tmdbMovies: List<Int>? = null,
    val tvdb: Int? = null,
    val tvdbSeason: Int? = null,
    val tmdbSeason: Int? = null,
) {
    val isMovie: Boolean get() = type == "MOVIE"

    val hasSeasonMapping: Boolean get() = tvdbSeason != null || tmdbSeason != null

    /** A regular series entry: not a film, not a special season, and TV, ONA, `UNKNOWN` or untyped. */
    val isRegularSeries: Boolean
        get() = !isMovie && tvdbSeason != 0 && tmdbSeason != 0 &&
            when (type?.uppercase()) {
                null, "TV", "ONA", "UNKNOWN" -> true
                else -> false
            }

    /** The anime-list ids the trackers take. */
    val animeIds: AnimeIds get() = AnimeIds(mal = mal, anilist = anilist, simkl = simkl)
}

/**
 * The Fribb mapping, indexed by every id a lookup starts from: TVDB, the TMDB series and films (each in its own index:
 * one number routinely names an unrelated film and series), IMDb, and the dataset's own keys AniDB and MyAnimeList
 * (the first row of an id is that id's). A row is filed under every id it declares.
 *
 * The file has ~40 000 rows, so rows are packed into one [IntArray] (IMDb ids by their number) and each index is a
 * sorted [LongArray] of `id << 32 | row`: a few MB in all, against tens of MB for maps of row objects. A row's second
 * and later IMDb ids and TMDB films (collections, a handful of rows) are kept beside it.
 */
internal class FribbIndex private constructor(
    private val fields: IntArray,
    private val types: Array<String?>,
    private val moreImdb: Map<Int, IntArray>,
    private val moreTmdbMovies: Map<Int, IntArray>,
    private val byAnidb: LongArray,
    private val byMal: LongArray,
    private val byImdb: LongArray,
    private val byTvdb: LongArray,
    private val byTmdbTv: LongArray,
    private val byTmdbMovie: LongArray,
) {
    val size: Int get() = types.size

    val isEmpty: Boolean get() = size == 0

    val summary: String get() = "$size Fribb rows"

    /** The row of AniDB entry [id], the first of the file's. */
    fun byAnidb(id: Int): FribbRow? = rows(byAnidb, id).firstOrNull()

    /** The row of MyAnimeList entry [id], the first of the file's: Explore matches a catalog entry back to a library. */
    fun byMal(id: Int): FribbRow? = rows(byMal, id).firstOrNull()

    /**
     * Rows for a title's external ids: the first non-empty of AniDB (one row: the dataset's own key), TVDB, TMDB and
     * IMDb, in that order. A [movie] skips TVDB (Fribb's `tvdb_id` is always a series; a library film's TVDB id is a
     * TVDB film's) and looks TMDB up among films; a show among series.
     */
    fun lookup(movie: Boolean, anidb: Int? = null, tvdb: Int? = null, tmdb: Int? = null, imdb: String? = null): List<FribbRow> {
        if (anidb != null) byAnidb(anidb)?.let { return listOf(it) }
        if (tvdb != null && !movie) rows(byTvdb, tvdb).takeIf { it.isNotEmpty() }?.let { return it }
        if (tmdb != null) rows(if (movie) byTmdbMovie else byTmdbTv, tmdb).takeIf { it.isNotEmpty() }?.let { return it }
        val imdbNumber = imdb?.let(::imdbNumber)
        if (imdbNumber != null) rows(byImdb, imdbNumber).takeIf { it.isNotEmpty() }?.let { return it }
        return emptyList()
    }

    private fun rows(index: LongArray, id: Int): List<FribbRow> {
        if (id < 0) return emptyList()
        val key = id.toLong() shl 32
        var lo = 0
        var hi = index.size
        while (lo < hi) {
            val mid = (lo + hi) ushr 1
            if (index[mid] < key) lo = mid + 1 else hi = mid
        }
        var result: MutableList<FribbRow>? = null
        var i = lo
        while (i < index.size && (index[i] ushr 32).toInt() == id) {
            (result ?: ArrayList<FribbRow>(2).also { result = it }).add(row((index[i] and 0xFFFFFFFFL).toInt()))
            i++
        }
        return result ?: emptyList()
    }

    private fun row(i: Int): FribbRow {
        val base = i * FIELD_COUNT
        fun f(field: Int) = fields[base + field].takeIf { it != NONE }
        return FribbRow(
            type = types[i],
            anidb = f(ANIDB),
            mal = f(MAL),
            anilist = f(ANILIST),
            simkl = f(SIMKL),
            imdb = f(IMDB)?.let { first -> listOf(imdbId(first)) + moreImdb[i]?.map(::imdbId).orEmpty() },
            tmdbTv = f(TMDB_TV),
            tmdbMovies = f(TMDB_MOVIE)?.let { first -> listOf(first) + moreTmdbMovies[i]?.toList().orEmpty() },
            tvdb = f(TVDB),
            tvdbSeason = f(TVDB_SEASON),
            tmdbSeason = f(TMDB_SEASON),
        )
    }

    /** Collects rows, then sorts the indexes once. */
    class Builder {
        private var fields = IntArray(1024 * FIELD_COUNT)
        private val types = ArrayList<String?>(1024)
        private val moreImdb = HashMap<Int, IntArray>()
        private val moreTmdbMovies = HashMap<Int, IntArray>()
        private val indexes = Array(INDEX_COUNT) { LongList() }

        /** Adds [row]; its IMDb ids that aren't IMDb's are left out. */
        fun add(row: FribbRow): Builder {
            val i = types.size
            if ((i + 1) * FIELD_COUNT > fields.size) fields = fields.copyOf(fields.size * 2)
            types += row.type
            val base = i * FIELD_COUNT
            val imdb = row.imdb.orEmpty().mapNotNull { imdbNumber(it.trim()) }
            val movies = row.tmdbMovies.orEmpty()
            fun put(field: Int, value: Int?) {
                fields[base + field] = value ?: NONE
            }
            put(ANIDB, row.anidb)
            put(MAL, row.mal)
            put(ANILIST, row.anilist)
            put(SIMKL, row.simkl)
            put(IMDB, imdb.firstOrNull())
            put(TMDB_TV, row.tmdbTv)
            put(TMDB_MOVIE, movies.firstOrNull())
            put(TVDB, row.tvdb)
            put(TVDB_SEASON, row.tvdbSeason)
            put(TMDB_SEASON, row.tmdbSeason)
            if (imdb.size > 1) moreImdb[i] = imdb.drop(1).toIntArray()
            if (movies.size > 1) moreTmdbMovies[i] = movies.drop(1).toIntArray()

            fun index(which: Int, id: Int?) {
                if (id != null && id >= 0) indexes[which].add((id.toLong() shl 32) or i.toLong())
            }
            index(I_ANIDB, row.anidb)
            index(I_MAL, row.mal)
            imdb.forEach { index(I_IMDB, it) }
            index(I_TVDB, row.tvdb)
            index(I_TMDB_TV, row.tmdbTv)
            movies.forEach { index(I_TMDB_MOVIE, it) }
            return this
        }

        fun build(): FribbIndex {
            val sorted = indexes.map { it.toSortedArray() }
            return FribbIndex(
                fields.copyOf(types.size * FIELD_COUNT), types.toTypedArray(), moreImdb, moreTmdbMovies,
                sorted[I_ANIDB], sorted[I_MAL], sorted[I_IMDB], sorted[I_TVDB], sorted[I_TMDB_TV], sorted[I_TMDB_MOVIE],
            )
        }
    }

    private class LongList {
        private var values = LongArray(256)
        private var size = 0

        fun add(value: Long) {
            if (size == values.size) values = values.copyOf(size * 2)
            values[size++] = value
        }

        /** By id, then by row: a lookup lists an id's rows in the file's order. */
        fun toSortedArray(): LongArray = values.copyOf(size).also { it.sort() }
    }

    companion object {
        val EMPTY: FribbIndex = Builder().build()

        /**
         * The index of anime-mappings' `fribb` table: Fribb's `anime-list-mini.json`, a row per element in its order,
         * a nested key such as `{"season": {"tvdb": 1}}` as the column `season.tvdb`.
         */
        fun from(table: PackedTables.Table): FribbIndex {
            val type = table.strings("type")
            val anidb = table.ints("anidb_id")
            val mal = table.ints("mal_id")
            val anilist = table.ints("anilist_id")
            val simkl = table.ints("simkl_id")
            val imdb = table.stringLists("imdb_id")
            val tmdbTv = table.ints("themoviedb_id.tv")
            val tmdbMovies = table.intLists("themoviedb_id.movie")
            val tvdb = table.ints("tvdb_id")
            val tvdbSeason = table.ints("season.tvdb")
            val tmdbSeason = table.ints("season.tmdb")
            val builder = Builder()
            for (i in 0 until table.rows) {
                builder.add(
                    FribbRow(
                        type = type[i], anidb = anidb[i].orNull(), mal = mal[i].orNull(), anilist = anilist[i].orNull(),
                        simkl = simkl[i].orNull(), imdb = imdb[i]?.takeIf { it.isNotEmpty() }, tmdbTv = tmdbTv[i].orNull(),
                        tmdbMovies = tmdbMovies[i]?.takeIf { it.isNotEmpty() }?.toList(), tvdb = tvdb[i].orNull(),
                        tvdbSeason = tvdbSeason[i].orNull(), tmdbSeason = tmdbSeason[i].orNull(),
                    ),
                )
            }
            return builder.build()
        }

        private fun Int.orNull(): Int? = takeIf { it != PackedTables.NONE }

        private const val NONE = Int.MIN_VALUE
        private const val ANIDB = 0
        private const val MAL = 1
        private const val ANILIST = 2
        private const val SIMKL = 3
        private const val IMDB = 4
        private const val TMDB_TV = 5
        private const val TMDB_MOVIE = 6
        private const val TVDB = 7
        private const val TVDB_SEASON = 8
        private const val TMDB_SEASON = 9
        private const val FIELD_COUNT = 10

        private const val I_ANIDB = 0
        private const val I_MAL = 1
        private const val I_IMDB = 2
        private const val I_TVDB = 3
        private const val I_TMDB_TV = 4
        private const val I_TMDB_MOVIE = 5
        private const val INDEX_COUNT = 6
    }
}

/** The number of an IMDb title id (`tt0213338` → 213338), or `null` for anything else. */
internal fun imdbNumber(id: String): Int? =
    ImdbId.parse(id)?.value?.substring(2)?.toLong()?.takeIf { it <= Int.MAX_VALUE }?.toInt()

/** IMDb's form of [number]: at least seven digits (`tt0213338`). */
internal fun imdbId(number: Int): String = "tt" + number.toString().padStart(7, '0')
