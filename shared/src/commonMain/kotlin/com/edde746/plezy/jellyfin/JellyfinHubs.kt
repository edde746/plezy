package com.edde746.plezy.jellyfin

import com.edde746.plezy.backend.DEFAULT_HUB_PREVIEW_LIMIT
import com.edde746.plezy.backend.HubFetchDiagnostics
import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.backend.MediaServerTimeouts
import com.edde746.plezy.backend.net.retryTransientMediaServerCall
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.LibraryPage
import com.edde746.plezy.model.MediaHub
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaLibrary
import com.edde746.plezy.strings.T
import kotlin.coroutines.cancellation.CancellationException
import kotlin.time.Clock
import kotlin.time.Duration
import kotlin.time.Duration.Companion.days
import kotlin.time.Duration.Companion.seconds
import kotlin.time.Instant
import kotlinx.coroutines.Deferred
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.withTimeoutOrNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive

/**
 * The home and library rows and the Continue Watching shelf. MediaBrowser has no hubs endpoint, so every row is
 * synthesized from Latest, the resume route and Next Up.
 */
internal class JellyfinHubs(
    private val core: JellyfinCore,
    /** The library views: the client's last loaded list when it has one, else a fresh `/Views` fetch. */
    private val fetchLibraries: suspend () -> List<MediaLibrary>,
) {
    /**
     * A hub surface's transport: one whole-request deadline, retries only on immediate connection errors and no
     * endpoint failover, so a slow row never moves the client off a working endpoint.
     */
    private class HubPolicy(val operation: String, val deadline: Duration)

    private class ShelfRows(val resume: List<MediaItem>, val nextUp: List<MediaItem>)

    private class SplitRows(val resume: List<JsonObject>, val nextUp: List<JsonObject>)

    private val latestItemsPath: String get() = "/Users/${JellyfinCore.segment(core.userId)}/Items/Latest"

    suspend fun fetchContinueWatching(count: Int? = 20, excludedLibraryIds: Set<String> = emptySet()): List<MediaItem> {
        if (excludedLibraryIds.isEmpty()) {
            val rows = continueWatchingRows(count, library = null)
            return mergeContinueWatching(rows.resume, rows.nextUp, count)
        }
        // Resume and Next Up rows name no library, so asking each visible library on its own is the only way to leave
        // a hidden one out; it also stamps every row with its library. Both queries are video-only, so music
        // is skipped.
        val visible = fetchLibraries().filter { it.id !in excludedLibraryIds && it.kind != MediaKind.ARTIST }
        val resume = mutableListOf<MediaItem>()
        val nextUp = mutableListOf<MediaItem>()
        for (batch in visible.chunked(LIBRARY_CONCURRENCY)) {
            val rows = coroutineScope { batch.map { async { continueWatchingRows(count, it) } }.awaitAll() }
            for (row in rows) {
                resume += row.resume
                nextUp += row.nextUp
            }
        }
        return mergeContinueWatching(resume, nextUp, count)
    }

    private suspend fun continueWatchingRows(count: Int?, library: MediaLibrary?): ShelfRows {
        val parentId = library?.id
        fun stamped(items: List<MediaItem>) =
            if (library == null) items else items.map { it.copy(libraryId = library.id, libraryTitle = library.title) }

        if (!core.dialect.resumeReturnsOnlyStartedItems) {
            val split = splitEmbyResumeRows(fetchItemsArray(core.paths.resumeItems, embyResumeWindowQuery(parentId), CONTINUE_WATCHING))
            return ShelfRows(stamped(core.mapItems(split.resume)), stamped(core.mapItems(stampEmbyNextUpRows(split.nextUp, parentId))))
        }
        return coroutineScope {
            val resume = async { fetchItemsArray(core.paths.resumeItems, resumeItemsQuery(limit = count, parentId = parentId), CONTINUE_WATCHING) }
            val nextUp = async { safeFetchItemsArray("/Shows/NextUp", nextUpQuery(limit = count, parentId = parentId), CONTINUE_WATCHING) }
            // Next Up rows carry no series play date; date them before the recency merge.
            ShelfRows(stamped(core.mapItems(resume.await())), stamped(attachSeriesLastPlayed(core.mapItems(nextUp.await()))))
        }
    }

    suspend fun fetchGlobalHubs(
        limit: Int = DEFAULT_HUB_PREVIEW_LIMIT,
        includePlaybackHubs: Boolean = true,
        diagnostics: HubFetchDiagnostics? = null,
    ): List<MediaHub> = playbackHubSet(
        idPrefix = "home",
        limit = limit,
        includePlaybackHubs = includePlaybackHubs,
        includeNextUp = true,
        policy = HOME_HUBS,
        continueTitle = T.discover.continueWatching,
        nextUpTitle = T.discover.nextUp,
        recentTitle = T.discover.recentlyAdded,
        library = null,
        latestItemTypes = "Movie,Series,Episode",
        diagnostics = diagnostics,
    )

    suspend fun fetchLibraryHubs(
        libraryId: String,
        libraryName: String,
        limit: Int = DEFAULT_HUB_PREVIEW_LIMIT,
        includePlaybackHubs: Boolean = true,
        libraryKind: MediaKind? = null,
        diagnostics: HubFetchDiagnostics? = null,
    ): List<MediaHub> {
        if (libraryKind == MediaKind.ARTIST) return musicLibraryHubs(libraryId, libraryName, limit, includePlaybackHubs, diagnostics)
        // A known movie library skips Next Up: the server would scan TV state only to return nothing.
        return playbackHubSet(
            idPrefix = "library.$libraryId",
            limit = limit,
            includePlaybackHubs = includePlaybackHubs,
            includeNextUp = libraryKind == null || libraryKind == MediaKind.SHOW,
            policy = LIBRARY_HUBS,
            continueTitle = T.discover.continueWatchingIn(libraryName),
            nextUpTitle = T.discover.nextUpIn(libraryName),
            recentTitle = T.discover.recentlyAddedIn(libraryName),
            library = libraryId to libraryName,
            latestItemTypes = null,
            diagnostics = diagnostics,
        )
    }

    /**
     * Latest, Continue Watching and Next Up, issued in that order and in parallel. Latest is issued before the
     * [includePlaybackHubs] short-circuit so a Recently Added-only caller still gets it in one round trip.
     */
    private suspend fun playbackHubSet(
        idPrefix: String,
        limit: Int,
        includePlaybackHubs: Boolean,
        includeNextUp: Boolean,
        policy: HubPolicy,
        continueTitle: String,
        nextUpTitle: String,
        recentTitle: String,
        library: Pair<String, String>?,
        latestItemTypes: String?,
        diagnostics: HubFetchDiagnostics?,
    ): List<MediaHub> = coroutineScope {
        val parentId = library?.first
        val latest = async {
            safeFetchItemsArray(
                latestItemsPath,
                listOf("Limit" to "$limit", "ParentId" to parentId, "Fields" to core.hubRowFields, "IncludeItemTypes" to latestItemTypes) +
                    JellyfinCore.IMAGE_PARAMS,
                policy,
                diagnostics,
            )
        }

        fun hub(suffix: String, title: String, type: String, rows: List<JsonObject>) =
            JellyfinMappers.syntheticHub(
                identifier = "$idPrefix.$suffix",
                title = title,
                type = type,
                items = mapRows(rows, library),
                serverId = core.serverId,
                serverName = core.connection.serverName,
                rawCount = rows.size,
                previewLimit = limit,
            )

        if (!includePlaybackHubs) return@coroutineScope listOf(hub("recent", recentTitle, "mixed", latest.await())).filter { it.items.isNotEmpty() }

        val resume: Deferred<List<JsonObject>>
        val nextUp: Deferred<List<JsonObject>>
        if (core.dialect.resumeReturnsOnlyStartedItems) {
            resume = async { safeFetchItemsArray(core.paths.resumeItems, resumeItemsQuery(limit = limit, parentId = parentId), policy, diagnostics) }
            nextUp = async {
                if (includeNextUp) safeFetchItemsArray("/Shows/NextUp", nextUpQuery(limit = limit, parentId = parentId), policy, diagnostics) else emptyList()
            }
        } else {
            // Emby: one window request feeds both shelves (see embyResumeWindowQuery).
            val split = async { splitEmbyResumeRows(safeFetchItemsArray(core.paths.resumeItems, embyResumeWindowQuery(parentId), policy, diagnostics)) }
            resume = async { split.await().resume }
            nextUp = async { if (includeNextUp) stampEmbyNextUpRows(split.await().nextUp, parentId) else emptyList() }
        }
        // The Emby halves are carved from the window rather than capped by the request: slice both to the preview.
        listOf(
            hub("continue", continueTitle, "mixed", resume.await().take(limit)),
            hub("nextup", nextUpTitle, "episode", nextUp.await().take(limit)),
            hub("recent", recentTitle, "mixed", latest.await()),
        ).filter { it.items.isNotEmpty() }
    }

    /** Library-scoped rows carry the library: a DTO never names it, and home orders and hides rows by it. */
    private fun mapRows(rows: List<JsonObject>, library: Pair<String, String>?): List<MediaItem> {
        val items = core.mapItems(rows)
        return if (library == null) items else items.map { it.copy(libraryId = library.first, libraryTitle = library.second) }
    }

    /**
     * Latest groups a music library's new items into albums (`latestalbums`); the played rows filter `IsPlayed` so
     * unplayed tracks never pad them.
     */
    private suspend fun musicLibraryHubs(
        libraryId: String,
        libraryName: String,
        limit: Int,
        includePlaybackHubs: Boolean,
        diagnostics: HubFetchDiagnostics?,
    ): List<MediaHub> = coroutineScope {
        val library = libraryId to libraryName
        val latest = async { safeFetchItemsArray(latestItemsPath, latestAlbumsQuery(limit, libraryId), LIBRARY_HUBS, diagnostics) }

        fun hub(suffix: String, title: String, type: String, rows: List<JsonObject>) =
            JellyfinMappers.syntheticHub(
                identifier = "library.$libraryId.$suffix",
                title = title,
                type = type,
                items = mapRows(rows, library),
                serverId = core.serverId,
                serverName = core.connection.serverName,
                rawCount = rows.size,
                previewLimit = limit,
            )

        if (!includePlaybackHubs) {
            return@coroutineScope listOf(hub("latestalbums", T.discover.latestAlbumsIn(libraryName), "album", latest.await())).filter { it.items.isNotEmpty() }
        }
        val recentlyPlayed = async { safeFetchItemsArray("/Items", playedTracksQuery("DatePlayed", limit, libraryId), LIBRARY_HUBS, diagnostics) }
        val mostPlayed = async { safeFetchItemsArray("/Items", playedTracksQuery("PlayCount", limit, libraryId), LIBRARY_HUBS, diagnostics) }
        listOf(
            hub("latestalbums", T.discover.latestAlbumsIn(libraryName), "album", latest.await()),
            hub("recentlyplayed", T.discover.recentlyPlayedIn(libraryName), "track", recentlyPlayed.await()),
            hub("mostplayed", T.discover.mostPlayedIn(libraryName), "track", mostPlayed.await()),
        ).filter { it.items.isNotEmpty() }
    }

    /** [fetchMoreHubItemsPage]'s first page; a failure reads as empty, a cancellation propagates. */
    suspend fun fetchMoreHubItems(hubId: String, limit: Int? = null): List<MediaItem> = try {
        fetchMoreHubItemsPage(hubId, start = 0, size = limit ?: DEFAULT_SEE_ALL_PAGE).items
    } catch (e: Exception) {
        if (e.isDisruption()) throw e
        Log.w(TAG, e) { "hub items for $hubId failed (treating as empty)" }
        emptyList()
    }

    /** A hub's see-all page, by the id's suffix; `library.{id}.{suffix}` scopes to that library. Unknown ids are empty. */
    suspend fun fetchMoreHubItemsPage(hubId: String, start: Int? = null, size: Int? = null): LibraryPage<MediaItem> {
        val offset = start ?: 0
        val pageSize = size ?: DEFAULT_SEE_ALL_PAGE
        val parentId = if (hubId.startsWith("library.")) {
            val rest = hubId.removePrefix("library.")
            val dot = rest.lastIndexOf('.')
            if (dot > 0) rest.substring(0, dot) else null
        } else {
            null
        }
        return when (val suffix = hubId.substringAfterLast('.')) {
            "recent" -> fetchMediaPage(
                "/Items",
                listOf(
                    "userId" to core.userId,
                    "ParentId" to parentId,
                    "Recursive" to "true",
                    "StartIndex" to "$offset",
                    "Limit" to "$pageSize",
                    "EnableTotalRecordCount" to "true",
                    "IncludeItemTypes" to "Movie,Series,Episode,Video,MusicVideo,Photo",
                    "SortBy" to "DateCreated,SortName,ProductionYear",
                    "SortOrder" to "Descending,Descending,Descending",
                    "Fields" to core.hubRowFields,
                    // Placeholder episodes carry a fresh DateCreated and would lead the grid.
                    "ExcludeLocationTypes" to "Virtual",
                ) + JellyfinCore.IMAGE_PARAMS,
                offset,
                pageSize,
            )
            // Latest groups music into albums but has no StartIndex: one page only.
            "latestalbums" -> if (offset > 0) {
                LibraryPage(emptyList(), totalCount = offset, offset = offset)
            } else {
                fetchMediaPage(latestItemsPath, latestAlbumsQuery(pageSize, parentId), offset, pageSize, singlePage = true)
            }
            "continue" -> if (!core.dialect.resumeReturnsOnlyStartedItems) {
                val resume = splitEmbyResumeRows(fetchItemsArray(core.paths.resumeItems, embyResumeWindowQuery(parentId))).resume
                LibraryPage(core.mapItems(resume.drop(offset).take(pageSize)), totalCount = resume.size, offset = offset)
            } else {
                fetchMediaPage(
                    core.paths.resumeItems,
                    resumeItemsQuery(limit = pageSize, parentId = parentId, start = offset, totalCount = true, videoOnly = parentId == null),
                    offset,
                    pageSize,
                )
            }
            "nextup" -> if (core.dialect.supportsGlobalNextUp) {
                fetchMediaPage("/Shows/NextUp", nextUpQuery(limit = pageSize, parentId = parentId, start = offset, totalCount = true), offset, pageSize)
            } else {
                val split = splitEmbyResumeRows(fetchItemsArray(core.paths.resumeItems, embyResumeWindowQuery(parentId)))
                val rows = stampEmbyNextUpRows(split.nextUp, parentId)
                LibraryPage(core.mapItems(rows.drop(offset).take(pageSize)), totalCount = rows.size, offset = offset)
            }
            "recentlyplayed", "mostplayed" -> fetchMediaPage(
                "/Items",
                playedTracksQuery(if (suffix == "mostplayed") "PlayCount" else "DatePlayed", pageSize, parentId, start = offset, totalCount = true),
                offset,
                pageSize,
            )
            else -> LibraryPage(emptyList(), totalCount = 0, offset = offset)
        }
    }

    private suspend fun fetchMediaPage(
        path: String,
        query: List<Pair<String, String?>>,
        offset: Int,
        requestedSize: Int,
        singlePage: Boolean = false,
    ): LibraryPage<MediaItem> {
        val response = core.get(path, query).throwIfError()
        return core.pagedItems(response.data, offset, requestedSize, singlePage, core::mapItems)
    }

    /**
     * Dates Next Up rows with their series' newest play, so the shelf's recency sort doesn't fall back to when the
     * episode was added. At most [SERIES_LAST_PLAYED_LOOKUP_LIMIT] series, in Next Up order (most recently played
     * first), [SERIES_LAST_PLAYED_CONCURRENCY] at a time. Each lookup's own timeout bounds connect and receive
     * separately, so one [SERIES_LAST_PLAYED_BUDGET] deadline cancels whatever is in flight and bounds the whole
     * pass. Undated rows degrade to their addedAt.
     */
    private suspend fun attachSeriesLastPlayed(nextUp: List<MediaItem>): List<MediaItem> {
        val seriesIds = nextUp.filter { it.kind == MediaKind.EPISODE && it.lastViewedAt == null }
            .mapNotNull { it.grandparentId }
            .distinct()
            .take(SERIES_LAST_PLAYED_LOOKUP_LIMIT)
        if (seriesIds.isEmpty()) return nextUp

        val lastPlayedBySeries = mutableMapOf<String, Long>()
        withTimeoutOrNull(SERIES_LAST_PLAYED_BUDGET) {
            for (batch in seriesIds.chunked(SERIES_LAST_PLAYED_CONCURRENCY)) {
                val played = coroutineScope { batch.map { id -> async { id to fetchSeriesLastPlayed(id) } }.awaitAll() }
                for ((id, playedAt) in played) if (playedAt != null) lastPlayedBySeries[id] = playedAt
            }
        }
        if (lastPlayedBySeries.isEmpty()) return nextUp
        return nextUp.map { item ->
            val playedAt = item.grandparentId?.let(lastPlayedBySeries::get)
            if (item.lastViewedAt == null && playedAt != null) item.copy(lastViewedAt = playedAt) else item
        }
    }

    /**
     * The newest play across [seriesId]'s episodes, null when never played or the lookup failed. No `IsPlayed`
     * filter: an episode can carry a LastPlayedDate while unplayed (started, or marked unwatched), and Jellyfin's own
     * Next Up ranks by it. Scoped to one series: the unscoped DatePlayed sort pegs 12.0-rc3 for seconds.
     */
    private suspend fun fetchSeriesLastPlayed(seriesId: String): Long? = try {
        val rows = safeFetchItemsArray(
            "/Items",
            listOf(
                "userId" to core.userId,
                "ParentId" to seriesId,
                "IncludeItemTypes" to "Episode",
                "Recursive" to "true",
                "SortBy" to "DatePlayed",
                "SortOrder" to "Descending",
                "Fields" to "UserData",
                "Limit" to "1",
                "EnableImages" to "false",
                "EnableTotalRecordCount" to "false",
            ),
            timeoutMillis = SERIES_LAST_PLAYED_REQUEST_TIMEOUT.inWholeMilliseconds,
            allowEndpointFailover = false,
        )
        core.mapItems(rows).firstOrNull()?.lastViewedAt
    } catch (e: MediaServerHttpException) {
        null
    }

    /**
     * Emby's resume route also returns one zero-position next episode per started series, and no filter separates
     * them, yet it is the only listing honouring HideFromResume. Both shelves therefore ride one window of
     * [EMBY_RESUME_WINDOW_LIMIT] recency-ordered rows, split by [splitEmbyResumeRows].
     */
    private fun embyResumeWindowQuery(parentId: String?) = resumeItemsQuery(limit = EMBY_RESUME_WINDOW_LIMIT, parentId = parentId)

    private fun resumeItemsQuery(
        limit: Int? = null,
        parentId: String? = null,
        start: Int? = null,
        totalCount: Boolean = false,
        videoOnly: Boolean = true,
    ): List<Pair<String, String?>> = listOf(
        "userId" to core.userId,
        "ParentId" to parentId,
        "StartIndex" to start?.toString(),
        "Limit" to limit?.toString(),
        "Fields" to core.hubRowFields,
        "MediaTypes" to "Video".takeIf { videoOnly },
        "Recursive" to "true",
        "EnableTotalRecordCount" to "$totalCount",
    ) + JellyfinCore.IMAGE_PARAMS

    /** Resumable episodes belong to the resume shelf; the cutoff bounds the server's otherwise unbounded scan. */
    private suspend fun nextUpQuery(limit: Int? = null, parentId: String? = null, start: Int? = null, totalCount: Boolean = false): List<Pair<String, String?>> =
        listOf(
            "userId" to core.userId,
            "ParentId" to parentId,
            "StartIndex" to start?.toString(),
            "Limit" to limit?.toString(),
            "Fields" to core.hubRowFields,
            "EnableResumable" to "false",
            "NextUpDateCutoff" to nextUpDateCutoff().toString(),
            "EnableRewatching" to "true".takeIf { core.sendNextUpRewatching() },
            "EnableTotalRecordCount" to "$totalCount",
        ) + JellyfinCore.IMAGE_PARAMS

    /** Album folder rows: count and user-data fields would each cost a recursive query per album. */
    private fun latestAlbumsQuery(limit: Int, parentId: String?): List<Pair<String, String?>> = listOf(
        "Limit" to "$limit",
        "ParentId" to parentId,
        "Fields" to core.musicAlbumRowFields,
        "EnableUserData" to "false",
    ) + JellyfinCore.IMAGE_PARAMS

    private fun playedTracksQuery(sortBy: String, limit: Int, parentId: String?, start: Int? = null, totalCount: Boolean = false): List<Pair<String, String?>> =
        listOf(
            "userId" to core.userId,
            "ParentId" to parentId,
            "IncludeItemTypes" to "Audio",
            "Recursive" to "true",
            "Filters" to "IsPlayed",
            "SortBy" to sortBy,
            "SortOrder" to "Descending",
            "StartIndex" to start?.toString(),
            "Limit" to "$limit",
            "Fields" to core.musicTrackRowFields,
            "EnableTotalRecordCount" to "$totalCount",
        ) + JellyfinCore.IMAGE_PARAMS

    /** Rows with progress are Continue Watching, zero-position episodes are Next Up; both keep the server's order. */
    private fun splitEmbyResumeRows(rows: List<JsonObject>): SplitRows {
        val resume = mutableListOf<JsonObject>()
        val nextUp = mutableListOf<JsonObject>()
        for (row in rows) {
            val positionMs = JellyfinTime.ticksToMs(row.obj("UserData")?.long("PlaybackPositionTicks"))
            if (positionMs != null && positionMs > 0) {
                resume += row
            } else if (row.str("Type") == "Episode") {
                nextUp += row
            }
        }
        return SplitRows(resume, nextUp)
    }

    /**
     * Stamps Emby's Next Up rows with their series' newest play date and applies the cutoff Jellyfin enforces
     * server-side (Emby ignores `NextUpDateCutoff`). A series the recency scan didn't reach is dropped, so the shelf is
     * bounded to series the scan vouches for; a failed scan empties the Next Up half, never the resume half. A series
     * the server gave no date for is kept unstamped.
     */
    private suspend fun stampEmbyNextUpRows(rows: List<JsonObject>, parentId: String?): List<JsonObject> {
        if (rows.isEmpty()) return rows
        val cutoff = nextUpDateCutoff()
        val lastPlayedBySeries = fetchRecentlyPlayedSeries(parentId).filterValues { date ->
            val playedAt = date?.let { runCatching { Instant.parse(it) }.getOrNull() }
            playedAt == null || playedAt >= cutoff
        }
        return rows.mapNotNull { row ->
            val seriesId = row.str("SeriesId")
            if (seriesId == null || seriesId !in lastPlayedBySeries) return@mapNotNull null
            val lastPlayed = lastPlayedBySeries[seriesId] ?: return@mapNotNull row
            // Merged into the row's own UserData so its position survives.
            val userData = JsonObject(row.obj("UserData").orEmpty() + ("LastPlayedDate" to JsonPrimitive(lastPlayed)))
            JsonObject(row + ("UserData" to userData))
        }
    }

    /**
     * Distinct series behind the user's most recently played episodes, newest first, each with its newest play
     * date: the first row naming a series is its newest play. `IsPlayed` + `DatePlayed` is the only library-wide
     * recency signal Emby has for series. Best effort on a short per-request timeout and without failover.
     */
    private suspend fun fetchRecentlyPlayedSeries(parentId: String?): Map<String, String?> {
        val rows = safeFetchItemsArray(
            "/Items",
            listOf(
                "userId" to core.userId,
                "ParentId" to parentId,
                "Recursive" to "true",
                "IncludeItemTypes" to "Episode",
                "Filters" to "IsPlayed",
                "SortBy" to "DatePlayed",
                "SortOrder" to "Descending",
                // Eight played episodes per shelf slot, so a few binged series don't starve the rest.
                "Limit" to "${SERIES_LAST_PLAYED_LOOKUP_LIMIT * 8}",
                "Fields" to core.withDialectRowFields("SeriesId"),
                "EnableImages" to "false",
                "EnableTotalRecordCount" to "false",
            ),
            timeoutMillis = SERIES_LAST_PLAYED_REQUEST_TIMEOUT.inWholeMilliseconds,
            allowEndpointFailover = false,
        )
        val lastPlayedBySeries = LinkedHashMap<String, String?>()
        for (row in rows) {
            val seriesId = row.str("SeriesId")?.ifEmpty { null } ?: continue
            if (seriesId in lastPlayedBySeries) continue
            lastPlayedBySeries[seriesId] = row.obj("UserData")?.str("LastPlayedDate")
            if (lastPlayedBySeries.size >= SERIES_LAST_PLAYED_LOOKUP_LIMIT) break
        }
        return lastPlayedBySeries
    }

    /**
     * Resume first so an in-progress episode beats its series' Next Up entry (dedup by id and series), then a stable
     * recency sort before the limit, so a recent Next Up episode is never starved by older resume items.
     */
    private fun mergeContinueWatching(resume: List<MediaItem>, nextUp: List<MediaItem>, limit: Int?): List<MediaItem> {
        if (limit != null && limit <= 0) return emptyList()
        val seenIds = HashSet<String>()
        val seenSeries = HashSet<String>()
        val merged = (resume + nextUp).filter { item ->
            val seriesId = if (item.kind == MediaKind.EPISODE) item.grandparentId else null
            seenIds.add(item.id) && (seriesId == null || seenSeries.add(seriesId))
        }
        val ordered = merged.sortedByDescending { it.recencySortKey }
        return if (limit != null) ordered.take(limit) else ordered
    }

    private suspend fun getItems(path: String, query: List<Pair<String, String?>>, policy: HubPolicy?, timeoutMillis: Long?, allowEndpointFailover: Boolean) =
        if (policy == null) {
            core.get(path, query, timeoutMillis, allowEndpointFailover)
        } else {
            retryTransientMediaServerCall(policy.operation, policy.deadline) { timeout ->
                core.get(path, query, timeout.inWholeMilliseconds, allowEndpointFailover = false)
            }
        }

    private suspend fun fetchItemsArray(path: String, query: List<Pair<String, String?>>, policy: HubPolicy? = null): List<JsonObject> =
        core.itemsArray(getItems(path, query, policy, timeoutMillis = null, allowEndpointFailover = true).throwIfError().data)

    /**
     * One row's items, a failure read as empty (recorded in [diagnostics]) so one broken endpoint doesn't sink the
     * others. A cancellation says nothing about the server's content and propagates.
     */
    private suspend fun safeFetchItemsArray(
        path: String,
        query: List<Pair<String, String?>>,
        policy: HubPolicy? = null,
        diagnostics: HubFetchDiagnostics? = null,
        timeoutMillis: Long? = null,
        allowEndpointFailover: Boolean = true,
    ): List<JsonObject> = try {
        core.itemsArray(getItems(path, query, policy, timeoutMillis, allowEndpointFailover).throwIfError().data)
    } catch (e: Exception) {
        if (e.isDisruption()) throw e
        diagnostics?.recordFailure(e)
        Log.w(TAG, e) { "$path failed (treating as empty)" }
        emptyList()
    }

    /** A cancelled call, ours or the transport's: never a reason to publish an empty row. */
    private fun Exception.isDisruption() = this is CancellationException || (this is MediaServerHttpException && isCancellation)

    private companion object {
        const val TAG = "JellyfinHubs"
        val HOME_HUBS = HubPolicy("Jellyfin home hubs", MediaServerTimeouts.HOME_HUB_DEADLINE)
        val LIBRARY_HUBS = HubPolicy("Jellyfin library hubs", MediaServerTimeouts.LIBRARY_HUB_DEADLINE)
        val CONTINUE_WATCHING = HubPolicy("Jellyfin continue watching", MediaServerTimeouts.HOME_HUB_DEADLINE)

        const val DEFAULT_SEE_ALL_PAGE = 50
        const val LIBRARY_CONCURRENCY = 3

        /** Mirrors Jellyfin web's `maxDaysForNextUp`. */
        val NEXT_UP_CUTOFF_AGE = 365.days

        /** Past this many rows the window is old enough that the Next Up cutoff drops it anyway. */
        const val EMBY_RESUME_WINDOW_LIMIT = 300

        /** Where wall time for 21 series stopped improving on a 12.0-rc3 server. */
        const val SERIES_LAST_PLAYED_CONCURRENCY = 4

        /** Just above the home shelf's 21-row probe, and the cap of an uncapped shelf's dating work. */
        const val SERIES_LAST_PLAYED_LOOKUP_LIMIT = 24
        val SERIES_LAST_PLAYED_REQUEST_TIMEOUT = 3.seconds
        val SERIES_LAST_PLAYED_BUDGET = 4.seconds

        /** Millisecond precision: .NET parses at most 7 fraction digits. */
        fun nextUpDateCutoff(): Instant = Instant.fromEpochMilliseconds((Clock.System.now() - NEXT_UP_CUTOFF_AGE).toEpochMilliseconds())
    }
}
