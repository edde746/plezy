package com.edde746.plezy.playback.queue

import com.edde746.plezy.app.testData
import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.jellyfin.FakeResponse
import com.edde746.plezy.jellyfin.JellyfinApiCache
import com.edde746.plezy.jellyfin.JellyfinCacheResolver
import com.edde746.plezy.jellyfin.JellyfinClient
import com.edde746.plezy.jellyfin.JellyfinDeviceIdentity
import com.edde746.plezy.jellyfin.JellyfinTestServer
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaBrowserDialect
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.model.SpecialsOrdering
import com.edde746.plezy.servers.OnlineServers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.emptyFlow
import kotlinx.coroutines.test.TestScope

/** Online servers serving [clients], in order. */
internal class FakeServers(vararg clients: MediaBackend) : OnlineServers {
    override val onlineClients: Map<ServerId, MediaBackend> = clients.associateBy { it.serverId }
    override val visibleOnlineClients: Map<ServerId, MediaBackend> get() = onlineClients
    override fun client(serverId: ServerId): MediaBackend? = onlineClients[serverId]
    override val changes: Flow<Unit> = emptyFlow()
}

/** A backend whose series' episodes are [seriesEpisodes] (or [fetchError]); each series asked for lands in [seriesQueueCalls]. */
internal class SeriesBackend(
    serverId: String = "srv-jf",
    backend: BackendKind = BackendKind.JELLYFIN,
    private val seriesEpisodes: List<MediaItem> = emptyList(),
    private val fetchError: Exception? = null,
) : FakeMediaBackend(serverId, backend) {
    val seriesQueueCalls = mutableListOf<String>()

    override suspend fun fetchClientSideEpisodeQueue(seriesId: String): List<MediaItem>? {
        seriesQueueCalls += seriesId
        fetchError?.let { throw it }
        return seriesEpisodes
    }
}

internal fun jfEpisode(id: String, seriesId: String, serverId: String = "srv-jf") = MediaItem(
    id = id,
    backend = BackendKind.JELLYFIN,
    kind = MediaKind.EPISODE,
    title = "Episode $id",
    serverId = serverId,
    grandparentId = seriesId,
)

internal fun jfMovie(id: String) = MediaItem(id = id, backend = BackendKind.JELLYFIN, kind = MediaKind.MOVIE, title = "Movie $id", serverId = "srv-jf")

internal fun plexMovie(id: String, playQueueItemId: Int) =
    MediaItem(id = id, backend = BackendKind.PLEX, kind = MediaKind.MOVIE, title = "Movie $id", playQueueItemId = playQueueItemId)

internal fun plexEpisode(id: String, seriesId: String, viewCount: Int? = null) = MediaItem(
    id = id,
    backend = BackendKind.PLEX,
    kind = MediaKind.EPISODE,
    title = "Episode $id",
    serverId = "srv-plex",
    grandparentId = seriesId,
    viewCount = viewCount,
)

/**
 * Maestro Show's episodes as the test servers' Jellyfin and Emby list them, `season/episode/name/air date`: one Special with no
 * `AirsBefore*`/`AirsAfter*` placement, aired before Season 1, then Seasons 1 and 2.
 */
private val MAESTRO_EPISODES = listOf(
    "0/1/Behind the Pattern/2026-01-01",
    "1/1/Maestro Episode 1/2026-02-01",
    "1/2/Maestro Episode 2/2026-02-02",
    "1/3/Maestro Episode 3/2026-02-03",
    "2/1/Second Season Opener/2026-03-01",
    "2/2/Second Season Finale/2026-03-02",
)

/** The ids of [MAESTRO_EPISODES] in the servers' own order: `s<season>e<episode>`, the Special `s0e1`. */
internal val MAESTRO_SERVER_ORDER = MAESTRO_EPISODES.map { row -> row.split('/').let { "s${it[0]}e${it[1]}" } }

/**
 * A [dialect] server holding Maestro Show (`maestro`) as the test servers do, with the user's [ordering]. Its
 * `/Shows/maestro/Episodes` answers in the server's own order (Seasons by number, so the unplaced Special first), as
 * both answer without `SortBy`; anything else is a 404.
 */
internal fun TestScope.maestroServer(dialect: MediaBrowserDialect, ordering: SpecialsOrdering = SpecialsOrdering.RESPECT_SERVER): JellyfinClient {
    val rows = MAESTRO_EPISODES.map { row ->
        val (season, episode, name, aired) = row.split('/')
        """{"Id":"s${season}e$episode","Type":"Episode","Name":"$name","ParentIndexNumber":$season,"IndexNumber":$episode,""" +
            """"SeasonId":"season-$season","SeriesId":"maestro","SeriesName":"Maestro Show","PremiereDate":"${aired}T00:00:00.0000000Z"}"""
    }
    val server = JellyfinTestServer { request ->
        if (request.path == "/Shows/maestro/Episodes") {
            FakeResponse(body = """{"Items":[${rows.joinToString(",")}],"TotalRecordCount":${rows.size}}""")
        } else {
            FakeResponse(404)
        }
    }
    val connection = server.connection(dialect)
    return JellyfinClient(
        connection = connection,
        http = server.http,
        identity = JellyfinDeviceIdentity("Plezy Linux", "Test Box", "1.2.3", connection.deviceId),
        cache = JellyfinApiCache(server.store, JellyfinCacheResolver(server.store, { listOf(connection) }, { emptyList() })),
        scope = backgroundScope,
        favorites = testData().liveTvFavorites,
        specialsOrdering = { ordering },
    )
}

/** Maestro Show's episodes from [server], by id, as its client maps them. */
internal suspend fun maestroEpisodes(server: JellyfinClient): Map<String, MediaItem> =
    server.fetchClientSideEpisodeQueue("maestro")!!.associateBy { it.id }
