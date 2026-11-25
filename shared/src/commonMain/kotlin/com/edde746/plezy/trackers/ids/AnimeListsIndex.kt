package com.edde746.plezy.trackers.ids

/**
 * The Anime-Lists mapping (`anime-list.xml`, https://github.com/Anime-Lists/anime-lists, see its README for the
 * format): its entries by the TVDB and TMDB series they map onto. Several AniDB entries share one series (split cours,
 * specials), so each id holds a list, in the file's order.
 */
internal class AnimeListsIndex(entries: List<AnimeListEntry>) {
    val byTvdb: Map<Int, List<AnimeListEntry>>
    val byTmdbTv: Map<Int, List<AnimeListEntry>>

    init {
        val tvdb = HashMap<Int, MutableList<AnimeListEntry>>()
        val tmdb = HashMap<Int, MutableList<AnimeListEntry>>()
        for (entry in entries) {
            entry.tvdbId?.let { tvdb.getOrPut(it) { ArrayList(2) }.add(entry) }
            entry.tmdbTvId?.let { tmdb.getOrPut(it) { ArrayList(2) }.add(entry) }
        }
        byTvdb = tvdb
        byTmdbTv = tmdb
    }

    val isEmpty: Boolean get() = byTvdb.isEmpty() && byTmdbTv.isEmpty()

    val summary: String get() = "${byTvdb.size} Anime-Lists TVDB series"

    /**
     * The AniDB episode an aired TVDB (or, when TVDB yields nothing, TMDB) [season]/[episode] is, when exactly one is
     * the best match: explicit mappings beat ranges, which beat an entry's default season. Same-priority matches that
     * disagree resolve to `null`: no guess.
     */
    fun lookupEpisode(tvdbId: Int?, tmdbId: Int?, season: Int?, episode: Int?): AnimeEpisodeMatch? {
        if (season == null || episode == null || episode <= 0) return null
        if (tvdbId != null) {
            selectMatch(matches(byTvdb[tvdbId], AnimeListProvider.TVDB, season, episode))?.let { return it }
        }
        if (tmdbId != null) return selectMatch(matches(byTmdbTv[tmdbId], AnimeListProvider.TMDB, season, episode))
        return null
    }

    /** The AniDB entries mapping [season] of the series: by default season or by a mapping of it. TVDB first. */
    fun animeIdsForSeason(tvdbId: Int?, tmdbId: Int?, season: Int): Set<Int> {
        if (tvdbId != null) {
            seasonAnimeIds(byTvdb[tvdbId], AnimeListProvider.TVDB, season).takeIf { it.isNotEmpty() }?.let { return it }
        }
        if (tmdbId != null) return seasonAnimeIds(byTmdbTv[tmdbId], AnimeListProvider.TMDB, season)
        return emptySet()
    }

    /** Every AniDB entry of the series, by its TVDB id, else its TMDB id. */
    fun animeIdsForShow(tvdbId: Int?, tmdbId: Int?): Set<Int> {
        if (tvdbId != null) byTvdb[tvdbId]?.takeIf { it.isNotEmpty() }?.let { entries -> return entries.mapTo(LinkedHashSet()) { it.anidbId } }
        if (tmdbId != null) byTmdbTv[tmdbId]?.takeIf { it.isNotEmpty() }?.let { entries -> return entries.mapTo(LinkedHashSet()) { it.anidbId } }
        return emptySet()
    }

    private fun matches(entries: List<AnimeListEntry>?, provider: AnimeListProvider, season: Int, episode: Int): List<AnimeEpisodeMatch> =
        entries.orEmpty().flatMap { it.resolveEpisode(provider, season, episode) }

    private fun selectMatch(matches: List<AnimeEpisodeMatch>): AnimeEpisodeMatch? {
        if (matches.isEmpty()) return null
        val best = matches.minOf { it.kind.ordinal }
        val candidates = matches.filter { it.kind.ordinal == best }
        val first = candidates.first()
        return first.takeIf { candidates.all(first::sameEpisode) }
    }

    private fun seasonAnimeIds(entries: List<AnimeListEntry>?, provider: AnimeListProvider, season: Int): Set<Int> =
        entries.orEmpty().filter { it.mapsSeason(provider, season) }.mapTo(LinkedHashSet()) { it.anidbId }

    companion object {
        val EMPTY = AnimeListsIndex(emptyList())

        /**
         * The index of anime-mappings' Anime-Lists tables: `anime_lists` (an `<anime>` of `anime-list.xml` a row, in its
         * order; rows without an `anidbid` skipped) and `anime_lists_mappings` (its `<mapping>`s, by `anidbid`). An
         * attribute holding a number or a word (`tvdbid="movie"`, `defaulttvdbseason="a"`) is two columns, the word in
         * `<name>_text`; only `a` (absolute numbering) means something.
         */
        fun from(tables: PackedTables): AnimeListsIndex {
            val m = tables.table("anime_lists_mappings")
            val mAnidb = m.ints("anidbid")
            val anidbSeason = m.ints("anidbseason")
            val tvdbSeason = m.ints("tvdbseason")
            val tmdbSeason = m.ints("tmdbseason")
            val start = m.ints("start")
            val end = m.ints("end")
            val offset = m.ints("offset")
            val text = m.strings("text")
            val mappings = HashMap<Int, MutableList<AnimeListEpisodeMapping>>()
            for (j in 0 until m.rows) {
                val anidb = mAnidb[j].orNull() ?: continue
                val season = anidbSeason[j].orNull() ?: continue
                val explicit = parseExplicit(text[j].orEmpty())
                val into = mappings.getOrPut(anidb) { ArrayList(2) }
                // A mapping naming both a TVDB and a TMDB season serves each provider.
                for ((provider, external) in listOf(AnimeListProvider.TVDB to tvdbSeason[j], AnimeListProvider.TMDB to tmdbSeason[j])) {
                    val externalSeason = external.orNull() ?: continue
                    into += AnimeListEpisodeMapping(season, provider, externalSeason, start[j].orNull(), end[j].orNull(), offset[j].orNull() ?: 0, explicit)
                }
            }

            val a = tables.table("anime_lists")
            val anidb = a.ints("anidbid")
            val tvdb = a.ints("tvdbid")
            val defaultTvdbSeason = a.ints("defaulttvdbseason")
            val defaultTvdbSeasonText = a.strings("defaulttvdbseason_text")
            val episodeOffset = a.ints("episodeoffset")
            val tmdbTv = a.ints("tmdbtv")
            val tmdbSeasonOf = a.ints("tmdbseason")
            val tmdbSeasonText = a.strings("tmdbseason_text")
            val tmdbOffset = a.ints("tmdboffset")
            val entries = ArrayList<AnimeListEntry>(a.rows)
            for (i in 0 until a.rows) {
                val id = anidb[i].orNull() ?: continue
                entries += AnimeListEntry(
                    anidbId = id,
                    tvdbId = tvdb[i].orNull(),
                    defaultTvdbSeason = seasonRef(defaultTvdbSeason[i], defaultTvdbSeasonText[i]),
                    episodeOffset = episodeOffset[i].orNull() ?: 0,
                    tmdbTvId = tmdbTv[i].orNull(),
                    tmdbSeason = seasonRef(tmdbSeasonOf[i], tmdbSeasonText[i]),
                    tmdbOffset = tmdbOffset[i].orNull() ?: 0,
                    mappings = mappings[id].orEmpty(),
                )
            }
            return AnimeListsIndex(entries)
        }

        /** A season: its number, else `a` for absolute numbering; any other word isn't one. */
        private fun seasonRef(number: Int, text: String?): SeasonRef? = when {
            number != PackedTables.NONE -> SeasonRef.of(number)
            text == "a" -> SeasonRef.ABSOLUTE
            else -> null
        }

        private fun Int.orNull(): Int? = takeIf { it != PackedTables.NONE }
    }
}

internal enum class AnimeListProvider { TVDB, TMDB }

/** How an episode was matched; the order is the preference. */
internal enum class AnimeListMatchKind { EXPLICIT, RANGE, DEFAULT_MAPPING }

/** A default season: a number, or `a` for absolute numbering. */
internal class SeasonRef private constructor(val number: Int?) {
    val isAbsolute: Boolean get() = number == null

    companion object {
        val ABSOLUTE = SeasonRef(null)

        fun of(number: Int) = SeasonRef(number)
    }
}

/** One `<anime>` element, as far as episode matching reads it. */
internal class AnimeListEntry(
    val anidbId: Int,
    val tvdbId: Int? = null,
    val defaultTvdbSeason: SeasonRef? = null,
    val episodeOffset: Int = 0,
    val tmdbTvId: Int? = null,
    val tmdbSeason: SeasonRef? = null,
    val tmdbOffset: Int = 0,
    val mappings: List<AnimeListEpisodeMapping> = emptyList(),
) {
    /**
     * The AniDB episodes external [season]/[episode] can be: explicit `;anidb-external;` pairs first, then ranges
     * (`anidbEpisode = episode − offset` within start..end), then the default season (`episode − episodeoffset` on
     * AniDB season 1); only positive AniDB episodes.
     */
    fun resolveEpisode(provider: AnimeListProvider, season: Int, episode: Int): List<AnimeEpisodeMatch> {
        val explicit = mappings.filter { it.matches(provider, season) }.flatMap { mapping ->
            mapping.explicit.filter { episode in it.externalEpisodes }.map {
                AnimeEpisodeMatch(anidbId, mapping.anidbSeason, it.anidbEpisode, provider, season, episode, AnimeListMatchKind.EXPLICIT)
            }
        }
        if (explicit.isNotEmpty()) return explicit

        val ranges = mappings.filter { it.matches(provider, season) }.mapNotNull { mapping ->
            val start = mapping.start ?: return@mapNotNull null
            val anidbEpisode = episode - mapping.offset
            val end = mapping.end
            if (anidbEpisode < start || (end != null && anidbEpisode > end) || anidbEpisode <= 0) return@mapNotNull null
            AnimeEpisodeMatch(anidbId, mapping.anidbSeason, anidbEpisode, provider, season, episode, AnimeListMatchKind.RANGE)
        }
        if (ranges.isNotEmpty()) return ranges

        val default = defaultSeason(provider)
        if (default == null || default.isAbsolute || default.number != season) return emptyList()
        val anidbEpisode = episode - defaultOffset(provider)
        if (anidbEpisode <= 0) return emptyList()
        return listOf(AnimeEpisodeMatch(anidbId, 1, anidbEpisode, provider, season, episode, AnimeListMatchKind.DEFAULT_MAPPING))
    }

    /** Whether the entry maps [season] of [provider]: as its default season or by a mapping of it. */
    fun mapsSeason(provider: AnimeListProvider, season: Int): Boolean {
        val default = defaultSeason(provider)
        if (default != null && !default.isAbsolute && default.number == season) return true
        return mappings.any { it.matches(provider, season) }
    }

    private fun defaultSeason(provider: AnimeListProvider) = when (provider) {
        AnimeListProvider.TVDB -> defaultTvdbSeason
        AnimeListProvider.TMDB -> tmdbSeason
    }

    private fun defaultOffset(provider: AnimeListProvider) = when (provider) {
        AnimeListProvider.TVDB -> episodeOffset
        AnimeListProvider.TMDB -> tmdbOffset
    }
}

/**
 * One `<mapping>`: AniDB season [anidbSeason] (1 regular, 0 specials) onto [externalSeason] of [provider], either as
 * explicit `;anidb-external;` pairs or as the range [start]..[end] shifted by [offset].
 */
internal class AnimeListEpisodeMapping(
    val anidbSeason: Int,
    val provider: AnimeListProvider,
    val externalSeason: Int,
    val start: Int? = null,
    val end: Int? = null,
    val offset: Int = 0,
    val explicit: List<AnimeListExplicitEpisode> = emptyList(),
) {
    fun matches(provider: AnimeListProvider, season: Int) = this.provider == provider && externalSeason == season
}

/** `anidb-e1+e2`: one AniDB episode as one or more external episodes. */
internal class AnimeListExplicitEpisode(val anidbEpisode: Int, val externalEpisodes: List<Int>)

/** An external episode matched to an AniDB entry's episode. */
internal data class AnimeEpisodeMatch(
    val anidbId: Int,
    val anidbSeason: Int,
    val anidbEpisode: Int,
    val provider: AnimeListProvider,
    val externalSeason: Int,
    val externalEpisode: Int,
    val kind: AnimeListMatchKind,
) {
    fun sameEntry(other: AnimeEpisodeMatch) = anidbId == other.anidbId && anidbSeason == other.anidbSeason

    fun sameEpisode(other: AnimeEpisodeMatch) = sameEntry(other) && anidbEpisode == other.anidbEpisode && kind == other.kind
}

/** `;1-2;3-4+5;6-0;` → pairs; a malformed pair, and one mapping to no episode (`-0`), is left out. */
private fun parseExplicit(raw: String): List<AnimeListExplicitEpisode> = raw.split(';').mapNotNull { segment ->
    val item = segment.trim()
    val separator = item.indexOf('-')
    if (separator <= 0 || separator == item.length - 1) return@mapNotNull null
    val anidbEpisode = item.substring(0, separator).toIntOrNull() ?: return@mapNotNull null
    val targets = item.substring(separator + 1).split('+').mapNotNull { it.trim().toIntOrNull()?.takeIf { episode -> episode != 0 } }
    if (targets.isEmpty()) null else AnimeListExplicitEpisode(anidbEpisode, targets)
}
