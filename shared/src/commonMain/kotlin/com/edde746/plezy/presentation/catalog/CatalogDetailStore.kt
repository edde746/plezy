package com.edde746.plezy.presentation.catalog

import com.edde746.plezy.catalog.CatalogAudiencePeriod
import com.edde746.plezy.catalog.CatalogAvailability
import com.edde746.plezy.catalog.CatalogCastMember
import com.edde746.plezy.catalog.CatalogCreditRole
import com.edde746.plezy.catalog.CatalogDetail
import com.edde746.plezy.catalog.CatalogItem
import com.edde746.plezy.catalog.CatalogRecommendationReason
import com.edde746.plezy.catalog.CatalogSource
import com.edde746.plezy.catalog.CatalogSourceId
import com.edde746.plezy.catalog.label
import com.edde746.plezy.catalog.matching.CatalogLibraryMatcher
import com.edde746.plezy.catalog.matching.uncheckedServerIds
import com.edde746.plezy.catalog.youTubeAppUrl
import com.edde746.plezy.format.clockTime
import com.edde746.plezy.format.formatCompactNumber
import com.edde746.plezy.format.formatDurationTextual
import com.edde746.plezy.format.formatMediumDate
import com.edde746.plezy.format.formatPercent
import com.edde746.plezy.format.formatUsd
import com.edde746.plezy.format.weekdayName
import com.edde746.plezy.lang.LanguageNames
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.CountryCodes
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaLibrary
import com.edde746.plezy.model.MediaRatingSource
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.model.libraryCopyQualityLabel
import com.edde746.plezy.model.mergeLibraryCopies
import com.edde746.plezy.model.primaryTrailer
import com.edde746.plezy.presentation.explore.CatalogSourcesState
import com.edde746.plezy.presentation.seerr.SeerrBlock
import com.edde746.plezy.seerr.SeerrPermission
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.servers.LibraryLookupResult
import com.edde746.plezy.servers.WatchClients
import com.edde746.plezy.strings.T
import kotlin.coroutines.cancellation.CancellationException
import kotlin.math.abs
import kotlin.math.roundToLong
import kotlin.time.Clock
import kotlin.time.Duration.Companion.minutes
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

/**
 * What the catalog detail screen asks of the device around it; called on the main thread.
 */
interface CatalogDetailHost {
    /**
     * The device has a browser. Without one (Apple TV) outbound links are hidden and the provider's trailer is offered
     * only as a YouTube-app link, once [youTubeAppInstalled] says the app is there.
     */
    val hasBrowser: Boolean

    /** The platform shows times on a 24-hour clock (its 12/24-hour setting), read as the detail is built. */
    val use24HourClock: Boolean

    /** Whether the YouTube app opens `youtube://` links; asked once, only without a browser. */
    suspend fun youTubeAppInstalled(): Boolean

    /**
     * Opens [url] in another app: a web link in the browser or the app handling it, or without a browser the YouTube
     * app's `youtube://` link. False when nothing opened it.
     */
    fun openUrl(url: String): Boolean

    /** Plays a library copy's own [trailer] in the player (it carries its server's id); false when it can't play here. */
    fun playTrailer(trailer: MediaItem): Boolean
}

/**
 * The detail screen of a catalog item (an Explore title): renders the opening [item] at once, and meanwhile looks the
 * title up in the user's libraries and loads its detail from the item's own source.
 *
 * - The detail replaces the item once loaded (the source enriches it, [CatalogItem.enrichedWith]) and brings cast,
 *   related titles and franchise relations; a failed load keeps the opening item and leaves those sections out. Either
 *   way the detail has [settled][CatalogDetailUiState.settled] and the actions show. Then the connected trackers' scores
 *   for the title are asked for, with the detail's ids ([communityRatings]).
 * - When the detail adds id forms or title candidates the libraries are asked again. Copies found by any pass are kept
 *   ([mergeLibraryCopies]): a pass can come back short a server. Which servers count as unchecked follows only the
 *   newest pass started; a failed lookup counts every expected server unchecked.
 * - Library copies are walked for their own trailer, which plays in the player before the provider's link opens in
 *   another app.
 * - The watchlist toggle binds to the item's own source ([CatalogSourcesState.watchlistSourceFor]). While membership
 *   is unknown a press loads it instead of toggling; one change at a time; a failed change says so ([message]).
 * - The Seerr Request action follows the connected Seerr source and its permission mask live. Seerr is asked where the
 *   title stands ([seerrRequestBlock]): one available, or already requested, shows that state, disabled, in its place.
 *   The detail [settles][CatalogDetailUiState.settled] once that answer is in too. A request sent from the sheet
 *   ([seerrRequested], by TMDB id) asks again.
 *
 * Call everything on the main thread; [release] ends it.
 *
 * @param seerrPermissions the signed-in Seerr user's permission mask; null while Seerr is not connected.
 * @param seerrRequestBlock why a title (its kind, TMDB id) can't be requested on the connected Seerr; null when it can.
 * @param seerrRequested the TMDB ids of the requests sent from the request sheet.
 * @param matchLibrary looks the item up across the profile's servers ([CatalogLibraryMatcher.match]).
 * @param expectedServerIds the servers a lookup is expected to answer for ([CatalogLibraryMatcher.expectedServerIds]).
 * @param clients the bound server clients, for the library copies' extras.
 * @param libraries the profile's libraries, for the kind of the library each copy sits in.
 * @param communityRatings the connected trackers' scores for a title, as they arrive.
 */
class CatalogDetailStore internal constructor(
    private val opening: CatalogItem,
    private val sources: StateFlow<CatalogSourcesState>,
    seerrPermissions: Flow<Int?>,
    private val seerrRequestBlock: suspend (MediaKind, Int) -> SeerrBlock?,
    seerrRequested: Flow<Int>,
    private val matchLibrary: suspend (CatalogItem) -> LibraryLookupResult,
    private val expectedServerIds: () -> Set<ServerId>,
    private val clients: WatchClients,
    libraries: Flow<List<MediaLibrary>>,
    private val communityRatings: (CatalogItem) -> Flow<List<MediaRatingSource>>,
    private val host: CatalogDetailHost,
    parentScope: CoroutineScope,
    private val clock: Clock = Clock.System,
) {
    private val scope = parentScope.childScope()

    private var detailItem: CatalogItem? = null
    private var cast: List<CatalogCastMember> = emptyList()
    private var related: List<CatalogItem> = emptyList()
    private var relations: List<CatalogRelationEntry> = emptyList()
    private var trackerRatings: List<MediaRatingSource> = emptyList()

    /** Library copies; null until the first lookup returns. */
    private var matches: List<MediaItem>? = null
    private var resolutionGeneration = 0
    private var resolving = false
    private var uncheckedServerIds: Set<ServerId> = emptySet()

    /** Each library's kind by its global key ([MediaLibrary.globalKey]). */
    private var libraryKinds: Map<String, MediaKind> = emptyMap()

    private var libraryTrailer: MediaItem? = null
    private var lookingUpLibraryTrailer = false
    private val trailerCheckedCopies = mutableSetOf<String>()
    private var youTubeAppInstalled = false

    private var watchlistSource: CatalogSource? = null
    private var watchlistJob: Job? = null
    private var mutatingWatchlist = false
    private var seerrMask: Int? = null
    private var showSpoilerTags = false
    private var message: String? = null

    /** Why the title can't be requested ([seerrRequestBlock]); the TMDB id it was asked for, and whether that runs. */
    private var requestBlock: SeerrBlock? = null
    private var requestLookedUp: Int? = null
    private var requestLookup: Job? = null
    private var lookingUpRequest = false

    /** The detail load has ended. */
    private var detailEnded = false

    /** The detail load and the request's lookup have ended ([CatalogDetailUiState.settled]); it stays so. */
    private var settled = false

    private val item: CatalogItem get() = detailItem ?: opening

    private val mutableState = MutableStateFlow(build())

    val state: StateFlow<CatalogDetailUiState> = mutableState.asStateFlow()

    init {
        resolveMatches(opening)
        scope.launch { loadDetail() }
        if (!host.hasBrowser) {
            scope.launch {
                youTubeAppInstalled = host.youTubeAppInstalled()
                publish()
            }
        }
        scope.launch {
            sources.collect { state ->
                bindWatchlist(state.watchlistSourceFor(opening))
                lookUpRequest()
                publish()
            }
        }
        scope.launch {
            seerrPermissions.collect { mask ->
                seerrMask = mask
                lookUpRequest()
                publish()
            }
        }
        scope.launch {
            seerrRequested.collect { tmdbId ->
                if (tmdbId != item.ids.tmdb) return@collect
                lookUpRequest(again = true)
                // The title's own request state (its stats line) comes with its detail: fetch it again.
                if (fetchDetail() != null) publish()
            }
        }
        scope.launch {
            libraries.collect { list ->
                libraryKinds = list.associate { it.globalKey to it.kind }
                publish()
            }
        }
    }

    /**
     * Adds the item to its watchlist or removes it. While membership is unknown the press loads it instead; a press
     * during a change is ignored.
     */
    fun toggleWatchlist() {
        val source = watchlistSource ?: return
        if (mutatingWatchlist) return
        val current = item
        val onWatchlist = source.isOnWatchlist(current.kind, current.ids)
        if (onWatchlist == null) {
            scope.launch { source.ensureWatchlistLoaded() }
            return
        }
        mutatingWatchlist = true
        scope.launch {
            try {
                if (onWatchlist) source.removeFromWatchlist(current.kind, current.ids) else source.addToWatchlist(current.kind, current.ids)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "Catalog watchlist update failed for ${current.identityKey}" }
                message = T.explore.watchlistUpdateFailed
                publish()
            } finally {
                mutatingWatchlist = false
            }
        }
    }

    /**
     * Plays a library copy's trailer, else (or when it can't play here) opens the provider's; says so when nothing
     * played or opened.
     */
    fun playTrailer() {
        if (libraryTrailer?.let(host::playTrailer) == true) return
        val url = externalTrailerUrl()
        if (url != null && host.openUrl(url)) return
        Log.d(TAG) { "Catalog trailer could not be played or opened: $url" }
        message = T.explore.detail.trailerUnavailable
        publish()
    }

    /** Opens an outbound link ([CatalogDetailLink.url]); says so when nothing opened it. */
    fun openLink(url: String) {
        if (hasScheme(url) && host.openUrl(url)) return
        Log.d(TAG) { "Catalog external URL could not be opened: $url" }
        message = T.explore.detail.linkUnavailable
        publish()
    }

    /** Shows the spoiler tags. */
    fun revealSpoilerTags() {
        showSpoilerTags = true
        publish()
    }

    /** The [CatalogDetailUiState.message] has shown. */
    fun messageShown() {
        message = null
        publish()
    }

    fun release() {
        scope.cancel()
    }

    private fun bindWatchlist(source: CatalogSource?) {
        if (source === watchlistSource) return
        watchlistJob?.cancel()
        watchlistSource = source
        watchlistJob = source?.let {
            scope.launch {
                if (it.isOnWatchlist(opening.kind, opening.ids) == null) launch { it.ensureWatchlistLoaded() }
                it.watchlistChanges.collect { publish() }
            }
        }
    }

    private fun ownSource(): CatalogSource? {
        val state = sources.value
        return state.connected.firstOrNull { it.id == opening.source } ?: state.seerr?.takeIf { it.id == opening.source }
    }

    /** Fetches the detail from the title's own source and takes it in; null when there is none or it failed. */
    private suspend fun fetchDetail(): CatalogDetail? {
        val detail = ownSource()?.let { source ->
            try {
                source.fetchDetail(opening)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.d(TAG, e) { "Catalog detail load failed for ${opening.identityKey}" }
                null
            }
        } ?: return null
        detailItem = detail.item
        cast = detail.cast
        related = detail.related
        relations = detail.relations.flatMap { relation ->
            relation.items.map { CatalogRelationEntry(relation.type.label, it.year?.let { year -> "${it.title} • $year" } ?: it.title, it) }
        }
        return detail
    }

    private suspend fun loadDetail() {
        val detail = fetchDetail()
        detailEnded = true
        lookUpRequest()
        settle()
        publish()
        // A Plex Discover row carries only its rating key, and an exact guid finds only modern-agent copies; aliases and
        // native titles reach copies filed under them. A second pass can only add copies.
        if (detail != null && CatalogLibraryMatcher.widensLookup(opening, detail.item)) resolveMatches(detail.item)
        communityRatings(item).collect {
            trackerRatings = it
            publish()
        }
    }

    private fun resolveMatches(lookup: CatalogItem) {
        val generation = ++resolutionGeneration
        resolving = true
        scope.launch {
            val result = try {
                matchLibrary(lookup)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "Catalog library match failed for ${lookup.identityKey}" }
                if (generation == resolutionGeneration) {
                    resolving = false
                    uncheckedServerIds = expectedServerIds()
                }
                mergeMatches(emptyList())
                return@launch
            }
            if (generation == resolutionGeneration) {
                resolving = false
                uncheckedServerIds = result.uncheckedServerIds
            }
            mergeMatches(result.items)
        }
    }

    private fun mergeMatches(found: List<MediaItem>) {
        matches = mergeLibraryCopies(matches.orEmpty(), found)
        publish()
        resolveLibraryTrailer()
    }

    /** Walks the copies for one with a trailer among its extras, picking up after the copies already asked. */
    private fun resolveLibraryTrailer() {
        if (lookingUpLibraryTrailer) return
        lookingUpLibraryTrailer = true
        scope.launch {
            try {
                while (libraryTrailer == null) {
                    val copy = matches?.firstOrNull { it.globalKey !in trailerCheckedCopies } ?: return@launch
                    trailerCheckedCopies += copy.globalKey
                    val serverId = ServerId.tryParse(copy.serverId) ?: continue
                    val client = if (clients.isClientOnline(serverId)) clients.client(serverId) else null
                    if (client == null) continue
                    try {
                        primaryTrailer(copy, client.fetchExtras(copy.id))?.let {
                            libraryTrailer = it.copy(serverId = copy.serverId, serverName = copy.serverName)
                            publish()
                        }
                    } catch (e: CancellationException) {
                        throw e
                    } catch (e: Exception) {
                        Log.d(TAG, e) { "Catalog library trailer lookup failed for ${copy.globalKey}" }
                    }
                }
            } finally {
                lookingUpLibraryTrailer = false
            }
        }
    }

    /** The provider's trailer as this device opens it: the web link, or without a browser the YouTube app's link. */
    private fun externalTrailerUrl(): String? {
        val url = item.trailerUrl?.trim()?.takeIf { it.isNotEmpty() } ?: return null
        if (!host.hasBrowser) return if (youTubeAppInstalled) youTubeAppUrl(url) else null
        return url.takeIf(::hasScheme)
    }

    private fun publish() {
        mutableState.value = build()
    }

    /** The Request action applies: Seerr is connected, its user may request the kind, and the title's TMDB id is known. */
    private fun requestApplies(): Boolean {
        val mask = seerrMask
        return sources.value.seerr != null && mask != null && item.ids.tmdb != null && SeerrPermission.canRequest(mask, movie = opening.kind == MediaKind.MOVIE)
    }

    /** Asks Seerr where the title stands once the Request action applies to its TMDB id, or [again] after a request. */
    private fun lookUpRequest(again: Boolean = false) {
        val tmdbId = item.ids.tmdb
        if (tmdbId == null || !requestApplies()) {
            requestLookup?.cancel()
            requestLookedUp = null
            requestBlock = null
            lookingUpRequest = false
            settle()
            return
        }
        if (!again && requestLookedUp == tmdbId) return
        requestLookedUp = tmdbId
        requestLookup?.cancel()
        lookingUpRequest = true
        requestLookup = scope.launch {
            val block = try {
                seerrRequestBlock(opening.kind, tmdbId)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "Seerr request state lookup failed for tmdb:$tmdbId" }
                null
            }
            requestBlock = block
            lookingUpRequest = false
            settle()
            publish()
        }
    }

    private fun settle() {
        if (detailEnded && !lookingUpRequest) settled = true
    }

    private fun build(): CatalogDetailUiState {
        val locale = T.locale
        val watchlist = watchlistSource?.let { source ->
            val onWatchlist = source.isOnWatchlist(item.kind, item.ids)
            CatalogWatchlistAction(onWatchlist, if (onWatchlist == true) T.explore.removeFromWatchlist else T.explore.addToWatchlist)
        }
        val tmdbId = item.ids.tmdb
        val request = if (tmdbId != null && requestApplies()) CatalogRequestAction(tmdbId, item.title, requestBlock) else null
        val links = if (host.hasBrowser) item.links.orEmpty().filter { it.label.isNotBlank() && it.url.isNotBlank() } else emptyList()
        return CatalogDetailUiState(
            item = item,
            tagline = item.tagline?.trim()?.takeIf { it.isNotEmpty() },
            title = item.title,
            metaLine = listOfNotNull(
                item.year?.toString(),
                item.runtimeMinutes?.let { formatDurationTextual(it.minutes) },
                item.certification?.trim()?.takeIf { it.isNotEmpty() },
            ).joinToString(" • ").takeIf { it.isNotEmpty() },
            genres = item.genres?.takeIf { it.isNotEmpty() }?.joinToString(" • "),
            watchlist = watchlist,
            request = request,
            hasTrailer = libraryTrailer != null || externalTrailerUrl() != null,
            settled = settled,
            stats = stats(item, locale, request?.blocked),
            overview = item.overview?.trim()?.takeIf { it.isNotEmpty() },
            background = item.background?.trim()?.takeIf { it.isNotEmpty() },
            facts = facts(item, locale),
            recommenders = item.recommenders.orEmpty().map { recommender ->
                val text = when (recommender.reason) {
                    CatalogRecommendationReason.FAVORITED -> T.explore.detail.favoritedBy(recommender.displayName)
                    CatalogRecommendationReason.RECOMMENDED -> T.explore.detail.recommendedBy(recommender.displayName)
                }
                CatalogDetailRecommender(text, recommender.note?.trim()?.takeIf { it.isNotEmpty() })
            },
            ratings = item.ratings.orEmpty(),
            communityRatings = trackerRatings,
            schedule = schedule(item, locale),
            crew = CatalogCreditRole.entries.mapNotNull { role ->
                joinValues(item.credits.orEmpty().filter { it.role == role }.map { it.name })?.let { CatalogDetailFact(role.label, it) }
            },
            tags = tags(item),
            watchOnLinks = links.filter { it.isStreaming }.map { CatalogDetailLink(T.explore.detail.openOn(it.label), it.url) },
            links = links.filterNot { it.isStreaming }.map { CatalogDetailLink(T.explore.detail.openOn(it.label), it.url) },
            library = librarySection(available = request?.blocked == SeerrBlock.AVAILABLE),
            castTitle = if (item.source == CatalogSourceId.MAL || item.source == CatalogSourceId.ANILIST) T.explore.characters else T.explore.cast,
            cast = cast,
            relations = relations,
            related = related,
            message = message,
        )
    }

    /**
     * The stats chips. [shown] is the state the Request action shows in its place: no chip repeats it (Available, or
     * the request's state while it is requested or processing); the availability facts beside it stay.
     */
    private fun stats(item: CatalogItem, locale: String, shown: SeerrBlock?): List<String> {
        val chips = mutableListOf<String>()
        fun chip(label: String?) {
            if (!label.isNullOrBlank()) chips += label
        }
        fun compact(count: Int) = formatCompactNumber(count.toLong(), locale)

        item.rating?.let { rating ->
            val score = oneDecimal(rating)
            chip(item.votes?.let { "$score (${T.explore.stats.votes(compact(it))})" } ?: score)
        }
        item.airStatus?.let { chip(it.label) }
        item.episodeCount?.let { chip(T.explore.episodeCount(it)) }
        item.unairedEpisodeCount?.let { chip(T.explore.detail.unairedEpisodes(it.toString())) }
        chip(item.network)
        item.broadcastSeason?.let { chip(it.label) }
        item.format?.let { chip(it.label) }
        item.sourceMaterial?.let { chip(it.label) }
        if (item.isAdult == true) chip(T.explore.badge.adult)
        item.addedAt?.let { chip(T.explore.detail.addedOn(formatMediumDate(it, locale))) }
        item.ranks.orEmpty().forEach { chip(it.label) }

        item.audience?.let { audience ->
            audience.watchingNow?.let { chip(T.explore.badge.watchingNow(compact(it))) }
            audience.listed?.let { chip(T.explore.stats.listed(compact(it))) }
            val viewers = audience.viewers
            val period = audience.viewersPeriod
            if (viewers != null && period != null) {
                val n = compact(viewers)
                chip(
                    when (period) {
                        CatalogAudiencePeriod.DAY -> T.explore.stats.viewersDay(n)
                        CatalogAudiencePeriod.WEEK -> T.explore.stats.viewersWeek(n)
                        CatalogAudiencePeriod.MONTH -> T.explore.stats.viewersMonth(n)
                        CatalogAudiencePeriod.YEAR -> T.explore.stats.viewersYear(n)
                        CatalogAudiencePeriod.ALL_TIME -> T.explore.stats.viewersAllTime(n)
                    },
                )
            }
            audience.planning?.let { chip(T.explore.stats.planning(compact(it))) }
            audience.watching?.let { chip(T.explore.stats.watching(compact(it))) }
            audience.completed?.let { chip(T.explore.stats.completed(compact(it))) }
            audience.onHold?.let { chip(T.explore.stats.onHold(compact(it))) }
            audience.dropped?.let { chip(T.explore.stats.dropped(compact(it))) }
            audience.favorited?.let { chip(T.explore.stats.favorited(compact(it))) }
            audience.dropRate?.let { chip(T.explore.stats.dropRate(formatPercent(it, locale))) }
            audience.comments?.let { chip(T.explore.stats.comments(it)) }
        }

        item.serverState?.let { server ->
            server.availability?.takeUnless { it == CatalogAvailability.AVAILABLE && shown == SeerrBlock.AVAILABLE }?.let { chip(it.label(is4k = false)) }
            server.availability4k?.let { chip(it.label(is4k = true)) }
            if (shown != SeerrBlock.REQUESTED && shown != SeerrBlock.PROCESSING) server.request?.let { chip(it.label(is4k = false)) }
            server.request4k?.let { chip(it.label(is4k = true)) }
            val available = server.availableSeasons
            val total = server.totalSeasons
            if (available != null && total != null) chip(T.explore.badge.seasonsAvailable(available.toString(), total.toString()))
        }
        return chips
    }

    private fun facts(item: CatalogItem, locale: String): List<CatalogDetailFact> {
        val facts = mutableListOf<CatalogDetailFact>()
        fun fact(label: String, value: String?) {
            if (!value.isNullOrBlank()) facts += CatalogDetailFact(label, value)
        }
        val detail = T.explore.detail
        fact(detail.originalTitle, item.originalTitle)
        fact(detail.alsoKnownAs, joinValues(item.altTitles))
        fact(detail.studios, joinValues(item.studios))
        fact(detail.country, joinValues(item.countries, CountryCodes::getDisplayName))
        fact(detail.language, joinValues(item.languages) { LanguageNames.displayName(it, locale) ?: it })
        fact(detail.released, item.releaseDate?.let { formatMediumDate(it, locale) })
        fact(detail.physicalRelease, item.physicalReleaseDate?.let { formatMediumDate(it, locale) })
        fact(detail.ended, item.endDate?.let { formatMediumDate(it, locale) })
        fact(detail.yourRating, item.userRating?.let(::oneDecimal))
        fact(detail.budget, item.budget?.let { formatUsd(it, locale) })
        fact(detail.revenue, item.revenue?.let { formatUsd(it, locale) })
        fact(detail.contentAdvisory, item.contentAdvisory)
        return facts
    }

    private fun schedule(item: CatalogItem, locale: String): List<String> {
        val chips = mutableListOf<String>()
        val broadcast = item.broadcast
        val weekday = broadcast?.weekday
        val time = broadcast?.time?.trim()
        if (weekday != null && weekday in 1..7 && !time.isNullOrEmpty()) {
            val day = weekdayName(weekday, locale)
            val timezone = broadcast.timezone?.trim()
            val clock = broadcastClock(time, host.use24HourClock)
            chips += if (timezone.isNullOrEmpty()) T.explore.broadcast(day, clock) else T.explore.broadcastWithZone(day, clock, timezone)
        }
        item.nextEpisode?.let { next ->
            val duration = formatDurationTextual(next.timeUntil(clock.now()))
            val episode = next.episode
            chips += if (episode == null) T.explore.badge.nextAiringIn(duration) else T.explore.badge.nextEpisodeIn(episode.toString(), duration)
        }
        return chips
    }

    /**
     * A broadcast's time ("21:00", the wall clock of its own time zone) on the platform's 12/24-hour clock ([clockTime]),
     * as it is when it isn't hours and minutes.
     */
    private fun broadcastClock(time: String, use24HourClock: Boolean): String {
        val (hours, minutes) = BROADCAST_TIME.matchEntire(time)?.destructured ?: return time
        if (hours.toInt() > 23 || minutes.toInt() > 59) return time
        return clockTime((hours.toInt() * 60 + minutes.toInt()) * 60L, use24HourClock) { 0 }
    }

    private fun tags(item: CatalogItem): CatalogDetailTags? {
        val ordered = item.tags.orEmpty().filter { it.name.isNotBlank() }.sortedByDescending { it.rank ?: -1 }
        if (ordered.isEmpty()) return null
        return CatalogDetailTags(
            visible = ordered.filter { !it.isSpoiler || showSpoilerTags }.map { it.name },
            canRevealSpoilers = !showSpoilerTags && ordered.any { it.isSpoiler },
        )
    }

    /** Where the title is in the libraries; with none holding it, [available] (Seerr has it) leaves it to the status. */
    private fun librarySection(available: Boolean): CatalogLibrarySection {
        val matches = matches
        val unchecked = uncheckedServerIds.size
        return when {
            matches == null || (matches.isEmpty() && resolving) -> CatalogLibrarySection.Checking
            matches.isEmpty() && unchecked == 0 -> if (available) CatalogLibrarySection.SaidByStatus else CatalogLibrarySection.NotInLibrary
            matches.isEmpty() -> CatalogLibrarySection.Unchecked(T.explore.libraryCheckFailed(unchecked))
            else -> CatalogLibrarySection.Copies(
                copies = matches.map { copy ->
                    // A MediaBrowser copy carries its library title only when the ancestors lookup succeeded.
                    val details = listOfNotNull(libraryCopyQualityLabel(copy), copy.serverName.takeIf { copy.libraryTitle != null })
                    CatalogLibraryCopy(
                        key = copy.globalKey,
                        item = copy,
                        backend = copy.backend,
                        title = copy.libraryTitle ?: copy.serverName ?: copy.backend.dialect?.productName ?: "Plex",
                        subtitle = details.takeIf { it.isNotEmpty() }?.joinToString(" • "),
                        libraryKind = copy.libraryGlobalKey?.let(libraryKinds::get)?.takeIf { it != MediaKind.UNKNOWN } ?: copy.kind,
                    )
                },
                uncheckedNote = if (unchecked > 0) T.explore.libraryCheckFailed(unchecked) else null,
            )
        }
    }

    private companion object {
        const val TAG = "CatalogDetail"
        val URI_SCHEME = Regex("^[A-Za-z][A-Za-z0-9+.-]*:")
        val BROADCAST_TIME = Regex("""(\d{1,2}):(\d{2})""")

        fun hasScheme(url: String) = URI_SCHEME.containsMatchIn(url.trim())

        /** One decimal, as scores are written: `7.5`, `9.0`. */
        fun oneDecimal(value: Double): String {
            val tenths = (value * 10).roundToLong()
            return "${tenths / 10}.${abs(tenths % 10)}"
        }

        /** Trimmed, non-blank, distinct [values] (by their [displayName]) joined with ` • `; null when none is left. */
        fun joinValues(values: List<String>?, displayName: (String) -> String = { it }): String? =
            values.orEmpty().map { it.trim() }.filter { it.isNotEmpty() }.map(displayName).filter { it.isNotBlank() }
                .distinct().takeIf { it.isNotEmpty() }?.joinToString(" • ")
    }
}
