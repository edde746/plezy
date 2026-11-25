package com.edde746.plezy.catalog.seerr

import com.edde746.plezy.catalog.CatalogAirStatus
import com.edde746.plezy.catalog.CatalogAvailability
import com.edde746.plezy.catalog.CatalogCastMember
import com.edde746.plezy.catalog.CatalogCredit
import com.edde746.plezy.catalog.CatalogCreditRole
import com.edde746.plezy.catalog.CatalogDetail
import com.edde746.plezy.catalog.CatalogItem
import com.edde746.plezy.catalog.CatalogItemIds
import com.edde746.plezy.catalog.CatalogPage
import com.edde746.plezy.catalog.CatalogRequestState
import com.edde746.plezy.catalog.CatalogRowId
import com.edde746.plezy.catalog.CatalogServerState
import com.edde746.plezy.catalog.CatalogSource
import com.edde746.plezy.catalog.CatalogSourceId
import com.edde746.plezy.catalog.CatalogTag
import com.edde746.plezy.catalog.parseCatalogInstant
import com.edde746.plezy.catalog.youTubeTrailerUrl
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.CountryCodes
import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaPersonDetails
import com.edde746.plezy.seerr.SeerrClient
import com.edde746.plezy.seerr.SeerrDetails
import com.edde746.plezy.seerr.SeerrMedia
import com.edde746.plezy.seerr.SeerrMediaInfo
import com.edde746.plezy.seerr.SeerrMediaStatus
import com.edde746.plezy.seerr.SeerrNamedValue
import com.edde746.plezy.seerr.SeerrPage
import com.edde746.plezy.seerr.SeerrPermission
import com.edde746.plezy.seerr.SeerrRelatedVideo
import com.edde746.plezy.seerr.SeerrRequestStatus
import kotlin.coroutines.cancellation.CancellationException
import kotlin.time.Instant
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.emptyFlow

/**
 * The Explore source backed by a Seerr instance's TMDB-based discover API. [client] belongs to the Seerr account and is
 * never disposed here. Seerr has no watchlist; beyond discovery its part is the request flow, which reaches [client]
 * directly.
 */
class SeerrCatalogSource(val client: SeerrClient) : CatalogSource {
    override val id: CatalogSourceId get() = CatalogSourceId.SEERR

    override val supportedRows: List<CatalogRowId> = listOf(
        CatalogRowId.TRENDING,
        CatalogRowId.POPULAR_MOVIES,
        CatalogRowId.POPULAR_SHOWS,
        CatalogRowId.UPCOMING_MOVIES,
        CatalogRowId.UPCOMING_SHOWS,
    )

    override val supportsWatchlist: Boolean get() = false

    override val watchlistChanges: Flow<Unit> = emptyFlow()

    /** Whether the signed-in user may request titles of [kind], read from the live permission mask. */
    fun canRequest(kind: MediaKind): Boolean = SeerrPermission.canRequest(client.session.permissions, movie = kind == MediaKind.MOVIE)

    /** Seerr pages hold a fixed 20 items: [limit] is ignored and [CatalogPage.hasMore] follows `totalPages`. */
    override suspend fun fetchRow(row: CatalogRowId, page: Int, limit: Int): CatalogPage = coroutineScope {
        val results = async {
            when (row) {
                CatalogRowId.TRENDING -> client.getTrending(page)
                CatalogRowId.POPULAR_MOVIES -> client.getPopularMovies(page)
                CatalogRowId.POPULAR_SHOWS -> client.getPopularTv(page)
                CatalogRowId.UPCOMING_MOVIES -> client.getUpcomingMovies(page)
                CatalogRowId.UPCOMING_SHOWS -> client.getUpcomingTv(page)
                else -> throw IllegalArgumentException("Seerr does not serve ${row.id}")
            }
        }
        val origin = async { imageOrigin() }
        toPage(results.await(), origin.await())
    }

    override suspend fun search(query: String, limit: Int): List<CatalogItem> {
        val trimmed = query.trim()
        if (trimmed.isEmpty()) return emptyList()
        return coroutineScope {
            val results = async { client.search(trimmed) }
            val origin = async { imageOrigin() }
            toPage(results.await(), origin.await()).items
        }
    }

    /** The detail, the recommendations and the artwork origin load concurrently; each failure is isolated. */
    override suspend fun fetchDetail(item: CatalogItem, castLimit: Int, relatedLimit: Int): CatalogDetail {
        val tmdbId = item.ids.tmdb ?: return CatalogDetail(item)
        val movie = item.kind == MediaKind.MOVIE
        return coroutineScope {
            val detailsLoad = async { withoutFailure("detail", tmdbId) { if (movie) client.getMovie(tmdbId) else client.getTv(tmdbId) } }
            val relatedLoad = async {
                withoutFailure("recommendations", tmdbId) {
                    if (movie) client.getMovieRecommendations(tmdbId) else client.getTvRecommendations(tmdbId)
                }
            }
            val originLoad = async { imageOrigin() }
            val details = detailsLoad.await()
            val related = relatedLoad.await()
            val origin = originLoad.await()
            CatalogDetail(
                item = details?.let { item.enrichedWith(detailItem(it, item.kind, origin)) } ?: item,
                cast = details?.let { cast(it, castLimit, origin) }.orEmpty(),
                related = related?.let { toPage(it, origin).items.take(relatedLimit) }.orEmpty(),
            )
        }
    }

    /**
     * The Seerr person page of [personId] (TMDB's): their details and their titles, cast credits then crew credits in
     * Seerr's order. Both load concurrently; either failing fails the page.
     */
    suspend fun fetchPerson(personId: Int): SeerrCatalogPerson = coroutineScope {
        val personLoad = async { client.getPerson(personId) }
        val creditsLoad = async { client.getPersonCombinedCredits(personId) }
        val originLoad = async { imageOrigin() }
        val person = personLoad.await()
        val credits = creditsLoad.await()
        val origin = originLoad.await()
        SeerrCatalogPerson(
            name = nonEmpty(person.name),
            imageUrl = imageUrl(origin, person.profilePath, CAST_SIZE),
            department = nonEmpty(person.knownForDepartment),
            details = MediaPersonDetails(
                biography = nonEmpty(person.biography),
                birthDate = MediaPersonDetails.parseDate(person.birthday),
                deathDate = MediaPersonDetails.parseDate(person.deathday),
                birthPlace = nonEmpty(person.placeOfBirth),
            ),
            titles = (credits.cast + credits.crew).map { it.media }.filter { it.displayTitle.isNotEmpty() }.map { rowItem(it, origin) },
        )
    }

    /** Requests key on TMDB ids: any library item carrying one is in scope. */
    override suspend fun resolveItemIds(kind: MediaKind, external: ExternalIds): CatalogItemIds? =
        external.tmdb?.let { CatalogItemIds(tmdb = it, imdb = external.imdb, tvdb = external.tvdb) }

    override suspend fun ensureWatchlistLoaded() = Unit

    override fun isOnWatchlist(kind: MediaKind, ids: CatalogItemIds): Boolean? = null

    override suspend fun addToWatchlist(kind: MediaKind, ids: CatalogItemIds) = throw UnsupportedOperationException("Seerr has no watchlist")

    override suspend fun removeFromWatchlist(kind: MediaKind, ids: CatalogItemIds) =
        throw UnsupportedOperationException("Seerr has no watchlist")

    override fun dispose() = Unit

    private suspend fun <R> withoutFailure(request: String, tmdbId: Int, block: suspend () -> R): R? = try {
        block()
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        Log.w(TAG, e) { "Seerr: $request load failed for tmdb:$tmdbId" }
        null
    }

    /**
     * The origin of one load's artwork: the instance's image proxy when its admin enabled image caching, TMDB's CDN
     * otherwise. Unreadable settings fall back to the CDN, and the next load reads them again.
     */
    private suspend fun imageOrigin(): String = try {
        client.tmdbImageProxyUrl() ?: TMDB_IMAGE_CDN
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        Log.w(TAG, e) { "Seerr: public settings unavailable, loading artwork from TMDB directly" }
        TMDB_IMAGE_CDN
    }

    private fun toPage(page: SeerrPage<SeerrMedia>, origin: String): CatalogPage = CatalogPage(
        items = page.items.filter { it.displayTitle.isNotEmpty() }.map { rowItem(it, origin) },
        hasMore = page.hasMore,
        totalResults = page.totalResults,
    )

    private fun rowItem(media: SeerrMedia, origin: String): CatalogItem = CatalogItem(
        source = CatalogSourceId.SEERR,
        kind = if (media.isMovie) MediaKind.MOVIE else MediaKind.SHOW,
        title = media.displayTitle,
        year = media.year,
        overview = nonEmpty(media.overview),
        rating = media.voteAverage,
        votes = media.voteCount,
        ids = CatalogItemIds(tmdb = media.id),
        posterUrl = imageUrl(origin, media.posterPath, POSTER_SIZE),
        backdropUrl = imageUrl(origin, media.backdropPath, BACKDROP_SIZE),
        posterVariants = variants(origin, media.posterPath, POSTER_LADDER),
        backdropVariants = variants(origin, media.backdropPath, BACKDROP_LADDER),
        serverState = serverState(media.mediaInfo),
        releaseDate = date(media.date),
        originalTitle = originalTitle(media.displayOriginalTitle, media.displayTitle),
        languages = languageCodes(listOf(media.originalLanguage)),
        countries = countryCodes(media.originCountry),
        isAdult = if (media.isMovie) media.adult else null,
    )

    private fun detailItem(details: SeerrDetails, kind: MediaKind, origin: String): CatalogItem {
        val show = kind == MediaKind.SHOW
        val airStatus = airStatus(details.status, kind)
        return CatalogItem(
            source = CatalogSourceId.SEERR,
            kind = kind,
            title = details.displayTitle,
            year = details.date?.takeIf { it.length >= 4 }?.substring(0, 4)?.toIntOrNull(),
            overview = nonEmpty(details.overview),
            runtimeMinutes = positive(details.runtime) ?: details.episodeRunTime?.firstOrNull { it > 0 },
            rating = details.voteAverage,
            votes = details.voteCount,
            genres = names(details.genres),
            certification = certification(details, kind),
            trailerUrl = if (show) null else trailerUrl(details.relatedVideos),
            airStatus = airStatus,
            episodeCount = if (show) episodeCount(details) else null,
            network = if (show) details.networks?.firstNotNullOfOrNull { nonEmpty(it.name) } else null,
            ids = CatalogItemIds(
                tmdb = positive(details.id),
                imdb = nonEmpty(details.imdbId) ?: nonEmpty(details.externalIds?.imdbId),
                tvdb = positive(details.externalIds?.tvdbId),
            ),
            posterUrl = imageUrl(origin, details.posterPath, POSTER_SIZE),
            backdropUrl = imageUrl(origin, details.backdropPath, BACKDROP_SIZE),
            posterVariants = variants(origin, details.posterPath, POSTER_LADDER),
            backdropVariants = variants(origin, details.backdropPath, BACKDROP_LADDER),
            serverState = serverState(details.mediaInfo),
            releaseDate = date(details.date),
            originalTitle = originalTitle(details.displayOriginalTitle, details.displayTitle),
            tagline = nonEmpty(details.tagline),
            endDate = if (show && (airStatus == CatalogAirStatus.ENDED || airStatus == CatalogAirStatus.CANCELED)) date(details.lastAirDate) else null,
            studios = names(details.productionCompanies),
            countries = countryCodes(details.originCountry.orEmpty() + details.productionCountries.orEmpty().map { it.countryCode ?: it.name }),
            languages = languageCodes(listOf(details.originalLanguage) + details.languages.orEmpty() + details.spokenLanguages.orEmpty().map { it.languageCode }),
            credits = credits(details),
            tags = names(details.keywords)?.map { CatalogTag(name = it) },
            budget = details.budget?.takeIf { it > 0 },
            revenue = details.revenue?.takeIf { it > 0 },
            isAdult = if (show) null else details.adult,
        )
    }

    private fun cast(details: SeerrDetails, limit: Int, origin: String): List<CatalogCastMember> =
        details.credits?.cast.orEmpty().take(limit).mapNotNull { member ->
            nonEmpty(member.name)?.let {
                CatalogCastMember(it, secondary = nonEmpty(member.character), imageUrl = imageUrl(origin, member.profilePath, CAST_SIZE), personId = positive(member.id))
            }
        }

    /** Null when [info] is absent or says nothing. The product is read live: a settings fetch can upgrade a legacy session. */
    private fun serverState(info: SeerrMediaInfo?): CatalogServerState? {
        if (info == null) return null
        val product = client.session.product
        val seasons = info.seasons.orEmpty().filter { it.seasonNumber > 0 }
        val status = info.status(product)
        val status4k = info.status4k(product)
        val state = CatalogServerState(
            availability = availability(status),
            availability4k = availability(status4k),
            request = requestState(info, is4k = false, mediaStatus = status),
            request4k = requestState(info, is4k = true, mediaStatus = status4k),
            availableSeasons = if (seasons.isEmpty()) null else seasons.count { it.status(product) == SeerrMediaStatus.AVAILABLE },
            totalSeasons = if (seasons.isEmpty()) null else seasons.size,
        )
        return if (state.isEmpty) null else state
    }

    private fun trailerUrl(videos: List<SeerrRelatedVideo>?): String? {
        for (video in videos.orEmpty()) {
            if (video.type?.lowercase() != "trailer") continue
            nonEmpty(video.url)?.let { return it }
            val key = nonEmpty(video.key)
            if (key != null && video.site?.lowercase() == "youtube") return youTubeTrailerUrl(key)
        }
        return null
    }

    private fun credits(details: SeerrDetails): List<CatalogCredit>? {
        val result = mutableListOf<CatalogCredit>()
        val seen = mutableSetOf<Pair<CatalogCreditRole, String>>()
        fun add(rawName: String?, role: CatalogCreditRole?) {
            val name = nonEmpty(rawName) ?: return
            if (role != null && seen.add(role to name)) result += CatalogCredit(name, role)
        }
        details.createdBy.orEmpty().forEach { add(it.name, CatalogCreditRole.CREATOR) }
        details.credits?.crew.orEmpty().forEach { add(it.name, creditRole(it.job, it.department)) }
        return result.ifEmpty { null }
    }

    private companion object {
        const val TAG = "catalog"

        /** TMDB's image CDN; Seerr's image proxy serves the same `/t/p/<size>/<file>` paths under its own route. */
        const val TMDB_IMAGE_CDN = "https://image.tmdb.org"

        const val POSTER_SIZE = "w600_and_h900_bestv2"
        const val BACKDROP_SIZE = "w1920_and_h800_multi_faces"
        const val CAST_SIZE = "w300"

        val POSTER_LADDER = linkedMapOf(92 to "w92", 154 to "w154", 185 to "w185", 342 to "w342", 500 to "w500", 600 to POSTER_SIZE, 780 to "w780")
        val BACKDROP_LADDER = linkedMapOf(300 to "w300", 780 to "w780", 1280 to "w1280", 1920 to BACKDROP_SIZE)

        /** Seerr sends TMDB relative paths (`/abc.jpg`), sized here as the Seerr web UI sizes them. */
        fun imageUrl(origin: String, path: String?, size: String): String? =
            if (path.isNullOrEmpty()) null else "$origin/t/p/$size$path"

        fun variants(origin: String, path: String?, ladder: Map<Int, String>): Map<Int, String>? =
            if (path.isNullOrEmpty()) null else ladder.mapValues { (_, size) -> "$origin/t/p/$size$path" }

        fun availability(status: SeerrMediaStatus): CatalogAvailability? = when (status) {
            SeerrMediaStatus.AVAILABLE -> CatalogAvailability.AVAILABLE
            SeerrMediaStatus.PARTIALLY_AVAILABLE -> CatalogAvailability.PARTIALLY_AVAILABLE
            SeerrMediaStatus.PENDING, SeerrMediaStatus.PROCESSING, SeerrMediaStatus.BLOCKLISTED, SeerrMediaStatus.DELETED ->
                CatalogAvailability.UNAVAILABLE
            SeerrMediaStatus.UNKNOWN -> null
        }

        /**
         * The request state of one variant. A request's PENDING waits for approval; the media's PENDING is an approved
         * request queued in the pipeline. A failed request with no approved one beside it outranks a Processing or
         * Pending media status the failure left behind, so re-requesting stays open. Completed requests are settled.
         */
        fun requestState(info: SeerrMediaInfo, is4k: Boolean, mediaStatus: SeerrMediaStatus): CatalogRequestState? {
            val statuses = info.requests.orEmpty().filter { (it.is4k ?: false) == is4k }.map { it.status }.toSet()
            val approved = SeerrRequestStatus.APPROVED in statuses
            return when {
                SeerrRequestStatus.PENDING in statuses -> CatalogRequestState.PENDING
                SeerrRequestStatus.FAILED in statuses && !approved -> CatalogRequestState.FAILED
                mediaStatus == SeerrMediaStatus.PROCESSING -> CatalogRequestState.PROCESSING
                approved || mediaStatus == SeerrMediaStatus.PENDING -> CatalogRequestState.APPROVED
                SeerrRequestStatus.DECLINED in statuses -> CatalogRequestState.DECLINED
                else -> null
            }
        }

        /** The US certification, else the first one. Movies read `releases`, shows `contentRatings`. */
        fun certification(details: SeerrDetails, kind: MediaKind): String? = if (kind == MediaKind.MOVIE) {
            preferredCountryValue(details.releases, { it.countryCode }) { entry ->
                nonEmpty(entry.rating) ?: entry.releaseDates?.firstNotNullOfOrNull { nonEmpty(it.certification) }
            }
        } else {
            preferredCountryValue(details.contentRatings, { it.countryCode }) { nonEmpty(it.rating) }
        }

        fun <E> preferredCountryValue(entries: List<E>?, country: (E) -> String?, value: (E) -> String?): String? {
            if (entries == null) return null
            return entries.filter { country(it)?.uppercase() == "US" }.firstNotNullOfOrNull(value) ?: entries.firstNotNullOfOrNull(value)
        }

        fun airStatus(raw: String?, kind: MediaKind): CatalogAirStatus? = when (raw?.trim()?.lowercase()) {
            "returning series", "airing" -> CatalogAirStatus.AIRING
            "ended" -> CatalogAirStatus.ENDED
            "canceled", "cancelled" -> CatalogAirStatus.CANCELED
            "planned", "pilot", "rumored", "in production", "post production" -> CatalogAirStatus.UPCOMING
            "released" -> if (kind == MediaKind.SHOW) CatalogAirStatus.ENDED else null
            else -> null
        }

        /** `numberOfEpisodes`, else the sum of the seasons' episode counts. */
        fun episodeCount(details: SeerrDetails): Int? {
            positive(details.numberOfEpisodes)?.let { return it }
            val counts = details.seasons.orEmpty().mapNotNull { positive(it.episodeCount) }
            return if (counts.isEmpty()) null else counts.sum()
        }

        fun creditRole(job: String?, department: String?): CatalogCreditRole? = when (job?.trim()?.lowercase()) {
            "director" -> CatalogCreditRole.DIRECTOR
            "writer", "screenplay", "story", "teleplay" -> CatalogCreditRole.WRITER
            "producer", "executive producer", "co-producer" -> CatalogCreditRole.PRODUCER
            "composer", "original music composer" -> CatalogCreditRole.COMPOSER
            else -> if (department?.trim()?.lowercase() == "writing") CatalogCreditRole.WRITER else null
        }

        fun countryCodes(values: List<String?>?): List<String>? =
            values.orEmpty().mapNotNull { nonEmpty(it)?.let(CountryCodes::normalizeCode)?.takeIf(String::isNotEmpty) }.distinct().ifEmpty { null }

        fun languageCodes(values: List<String?>): List<String>? =
            values.mapNotNull { nonEmpty(it)?.lowercase() }.distinct().ifEmpty { null }

        fun names(values: List<SeerrNamedValue>?): List<String>? = values?.mapNotNull { nonEmpty(it.name) }?.ifEmpty { null }

        fun originalTitle(original: String?, displayed: String): String? = nonEmpty(original)?.takeIf { it != displayed }

        fun date(raw: String?): Instant? = parseCatalogInstant(raw)

        fun positive(value: Int?): Int? = value?.takeIf { it > 0 }

        fun nonEmpty(value: String?): String? = value?.trim()?.takeIf { it.isNotEmpty() }
    }
}

/**
 * A Seerr person page's content ([SeerrCatalogSource.fetchPerson]): [department] what they are known for (TMDB's
 * `Acting`, `Directing`), [titles] their credits as catalog items, cast before crew, a title once per credit.
 */
data class SeerrCatalogPerson(
    val name: String?,
    val imageUrl: String?,
    val department: String?,
    val details: MediaPersonDetails,
    val titles: List<CatalogItem>,
)
