package com.edde746.plezy.model

import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive

/**
 * An item's ids in the public catalogs (IMDb, TMDB, TVDB) and AniDB, read from a media server's metadata. Plex keeps
 * modern ids in a `Guid` array ([fromGuids]) and legacy agents in the scalar `guid` ([fromLegacyPlexGuid]; read both and
 * [fillFrom]); Jellyfin and Emby inline a `ProviderIds` map ([fromJellyfinProviderIds]).
 *
 * Serialized with the tracker write queue; absent ids stay absent, so a re-read answers [hasAny] and [intersects] the
 * same.
 */
@Serializable
data class ExternalIds(
    /** `tt0944947`. */
    val imdb: String? = null,
    val tmdb: Int? = null,
    val tvdb: Int? = null,
    /**
     * AniDB series id; only Plex's HAMA agent produces it. Almost nothing accepts it: it names a Fribb row (and through
     * it MAL, AniList, Simkl) but Trakt, Plex Discover, Seerr and the Anime-Lists episode mappings are keyed the other way.
     */
    val anidb: Int? = null,
) {
    /** An id a catalog (and Explore) can look up: AniDB isn't one. */
    val hasCatalogIds: Boolean get() = imdb != null || tmdb != null || tvdb != null

    val hasAny: Boolean get() = hasCatalogIds || anidb != null

    /** No id Trakt, Simkl or MDBList accept. */
    val isEmpty: Boolean get() = !hasCatalogIds

    /** Both name the same title by at least one id; the two sides may carry different subsets. */
    fun intersects(other: ExternalIds): Boolean =
        (imdb != null && imdb == other.imdb) || (tmdb != null && tmdb == other.tmdb) ||
            (tvdb != null && tvdb == other.tvdb) || (anidb != null && anidb == other.anidb)

    /** These ids, with the ones missing taken from [other]. */
    fun fillFrom(other: ExternalIds): ExternalIds =
        ExternalIds(imdb ?: other.imdb, tmdb ?: other.tmdb, tvdb ?: other.tvdb, anidb ?: other.anidb)

    /**
     * One id in a fixed preference order, as a stable name for a tracker's remote row.
     * One rather than all: which ids an item has varies with the media server's metadata and with the mapping
     * datasets, and a key that moved with them would stop matching rows already queued.
     */
    fun rowIdentity(): String? = when {
        imdb != null -> "imdb=$imdb"
        tmdb != null -> "tmdb=$tmdb"
        tvdb != null -> "tvdb=$tvdb"
        else -> null
    }

    /**
     * The scalar `guid` prefixes a legacy-agent Plex item with these ids would have, as `/library/all?guid=` values:
     * the inverse of [fromLegacyPlexGuid]. That filter is a literal prefix match and every legacy guid ends in
     * `?lang=xx`, so each value ends in `?` and can't run into a longer id. HAMA's `anidb2`..`anidb9` modes are left out.
     */
    val legacyPlexGuidPrefixes: List<String>
        get() = buildList {
            imdb?.let {
                add("$PLEX_AGENT.imdb://$it?")
                add("$PLEX_AGENT.hama://imdb-$it?")
            }
            tmdb?.let {
                add("$PLEX_AGENT.themoviedb://$it?")
                add("$PLEX_AGENT.hama://tmdb-$it?")
                add("$PLEX_AGENT.hama://tsdb-$it?")
            }
            tvdb?.let {
                add("$PLEX_AGENT.thetvdb://$it?")
                add("$PLEX_AGENT.hama://tvdb-$it?")
                for (mode in 2..9) add("$PLEX_AGENT.hama://tvdb$mode-$it?")
            }
            anidb?.let { add("$PLEX_AGENT.hama://anidb-$it?") }
        }

    companion object {
        private const val PLEX_AGENT = "com.plexapp.agents"
        private val DECIMAL_ID = Regex("^[0-9]+$")
        private val HAMA_TVDB_SOURCE = Regex("^tvdb[2-9]?$")
        private val URI_SCHEME = Regex("^[A-Za-z][A-Za-z0-9+.-]*$")

        /** Plex's `Guid` array: objects whose `id` is `imdb://tt…`, `tmdb://N` or `tvdb://N`; anything else is skipped. */
        fun fromGuids(guids: List<JsonElement>?): ExternalIds {
            var imdb: String? = null
            var tmdb: Int? = null
            var tvdb: Int? = null
            for (guid in guids.orEmpty()) {
                val id = ((guid as? JsonObject)?.get("id") as? JsonPrimitive)?.takeIf { it.isString }?.content ?: continue
                when {
                    id.startsWith("imdb://") -> imdb = id.substring(7)
                    id.startsWith("tmdb://") -> tmdb = id.substring(7).toIntOrNull()
                    id.startsWith("tvdb://") -> tvdb = id.substring(7).toIntOrNull()
                }
            }
            return ExternalIds(imdb = imdb, tmdb = tmdb, tvdb = tvdb)
        }

        /**
         * A legacy-agent Plex item's scalar `guid`: the IMDb, TheMovieDB and TheTVDB agents, and HAMA's
         * `<source>-<id>` over `anidb|tvdb|tvdb2..9|tmdb|tsdb|imdb`. Only plain `anidb-` maps: `anidb2`..`anidb9` are
         * HAMA's grouping modes, where several AniDB entries share one Plex show under TVDB-shaped seasons, so the guid
         * names the root entry only and would mislabel every later season.
         */
        fun fromLegacyPlexGuid(guid: String?): ExternalIds {
            val (scheme, value) = parseAgentGuid(guid) ?: return ExternalIds()
            when (scheme) {
                "$PLEX_AGENT.imdb" -> return ExternalIds(imdb = normalizeImdb(value, allowBareDigits = false))
                "$PLEX_AGENT.themoviedb" -> return ExternalIds(tmdb = parseNumericId(value))
                "$PLEX_AGENT.thetvdb" -> return ExternalIds(tvdb = parseNumericId(value))
                "$PLEX_AGENT.hama" -> {
                    val separator = value.indexOf('-')
                    if (separator <= 0 || separator == value.length - 1) return ExternalIds()
                    val source = value.substring(0, separator)
                    val id = value.substring(separator + 1)
                    return when {
                        source == "imdb" -> ExternalIds(imdb = normalizeImdb(id, allowBareDigits = true))
                        source == "anidb" -> ExternalIds(anidb = parseNumericId(id))
                        source == "tmdb" || source == "tsdb" -> ExternalIds(tmdb = parseNumericId(id))
                        HAMA_TVDB_SOURCE.matches(source) -> ExternalIds(tvdb = parseNumericId(id))
                        else -> ExternalIds()
                    }
                }
            }
            return ExternalIds()
        }

        /**
         * A Jellyfin or Emby `ProviderIds` map. Keys are matched case-insensitively (`Tmdb`, `Imdb`, `Tvdb`); only
         * non-empty string values count, and a non-numeric TMDB or TVDB id is ignored.
         */
        fun fromJellyfinProviderIds(providerIds: Map<String, JsonElement>?): ExternalIds {
            var imdb: String? = null
            var tmdb: Int? = null
            var tvdb: Int? = null
            for ((key, raw) in providerIds.orEmpty()) {
                val value = (raw as? JsonPrimitive)?.takeIf { it.isString }?.content
                if (value.isNullOrEmpty()) continue
                when (key.lowercase()) {
                    "imdb" -> imdb = value
                    "tmdb" -> tmdb = value.toIntOrNull()
                    "tvdb" -> tvdb = value.toIntOrNull()
                }
            }
            return ExternalIds(imdb = imdb, tmdb = tmdb, tvdb = tvdb)
        }

        /**
         * Every raw Jellyfin item whose `ProviderIds` intersect [ids], in response order. One title can own several
         * library items (a 4K and an HD library), and the caller lists every copy.
         */
        fun jellyfinCandidatesMatching(candidates: List<JsonObject>, ids: ExternalIds): List<JsonObject> = candidates.filter { item ->
            val providerIds = item["ProviderIds"] as? JsonObject ?: return@filter false
            ids.intersects(fromJellyfinProviderIds(providerIds))
        }

        /**
         * The lower-cased scheme and host of `scheme://host[?query]`; null unless the guid has an authority and an
         * empty path.
         */
        private fun parseAgentGuid(guid: String?): Pair<String, String>? {
            if (guid.isNullOrEmpty()) return null
            val schemeEnd = guid.indexOf("://")
            if (schemeEnd <= 0) return null
            val scheme = guid.substring(0, schemeEnd)
            if (!URI_SCHEME.matches(scheme)) return null
            val rest = guid.substring(schemeEnd + 3)
            val authorityEnd = rest.indexOfAny(charArrayOf('/', '?', '#')).let { if (it < 0) rest.length else it }
            if (authorityEnd < rest.length && rest[authorityEnd] == '/') return null
            val authority = rest.substring(0, authorityEnd)
            val hostAndPort = authority.substringAfterLast('@')
            val portSeparator = hostAndPort.lastIndexOf(':')
            val host = if (portSeparator < 0) {
                hostAndPort
            } else {
                if (!hostAndPort.substring(portSeparator + 1).all { it in '0'..'9' }) return null
                hostAndPort.substring(0, portSeparator)
            }
            if (host.any { it.isWhitespace() }) return null
            return scheme.lowercase() to host.lowercase()
        }

        private fun parseNumericId(value: String): Int? = if (DECIMAL_ID.matches(value)) value.toIntOrNull() else null

        private fun normalizeImdb(value: String, allowBareDigits: Boolean): String? {
            val normalized = value.lowercase()
            if (normalized.startsWith("tt")) {
                val digits = normalized.substring(2)
                return if (DECIMAL_ID.matches(digits)) "tt$digits" else null
            }
            return if (allowBareDigits && DECIMAL_ID.matches(normalized)) "tt$normalized" else null
        }
    }
}

/** The season a catalog entry maps to, by TVDB's and TMDB's numbering (the Fribb mapping's `season`). */
@Serializable
data class ExternalSeasonRef(val tvdb: Int? = null, val tmdb: Int? = null) {
    val hasAny: Boolean get() = tvdb != null || tmdb != null

    /**
     * Season 2 or later by either numbering. Knowable even when the numberings disagree; callers drop the ±1 year
     * window for a sequel, whose catalog year is its own season's, not the parent show's.
     */
    val isSequel: Boolean get() = (tvdb ?: 0) > 1 || (tmdb ?: 0) > 1

    /**
     * The season both numberings agree on; null when either is missing or they differ. TVDB and TMDB disagree on
     * split-cour and continuation seasons, and which one a library follows is a server setting nothing here can see.
     */
    val agreedSeason: Int? get() = if (tvdb != null && tvdb == tmdb) tvdb else null
}
