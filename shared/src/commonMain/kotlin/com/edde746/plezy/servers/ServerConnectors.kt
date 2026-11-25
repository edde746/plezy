package com.edde746.plezy.servers

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.model.ServerId
import kotlinx.coroutines.flow.Flow

/*
 * The seams between [MultiServerManager] and the two backend families. The manager owns the orchestration (status,
 * health probes, timers, debounces, single-flight, staleness, preferred-endpoint and relay rules); the Plex and the
 * MediaBrowser (Jellyfin, Emby) code implement these interfaces with their own clients, endpoint races and storage.
 */

/** Where a URL sits among a Plex server's published connections. */
enum class EndpointNetworkClass { LOCAL, REMOTE, RELAY }

/**
 * A working endpoint an endpoint race found, with what its probe read from the server root (null: not reported): the
 * transcoder capability and Plex's Allow media deletion switch.
 */
data class RacedEndpoint(val url: String, val transcoderVideo: Boolean? = null, val allowMediaDeletion: Boolean? = null)

/**
 * A server of a signed-in Plex account, as plex.tv lists it. The manager compares entries by identity: a server list
 * refresh brings new objects, and work started for an older one is dropped.
 */
interface PlexServerEntry {
    val serverId: ServerId
    val name: String
    val owned: Boolean

    /** The server's token for the account's current profile. */
    val accessToken: String

    /** Whether the server publishes a local connection that is not a relay. */
    val publishesLocalDirectConnection: Boolean

    /** [url]'s class among the published connections; an unpublished URL is classified by its host. */
    fun networkClassForUrl(url: String): EndpointNetworkClass

    /** Every published endpoint in failover order, [preferredFirst] first. */
    fun prioritizedEndpointUrls(preferredFirst: String): List<String>
}

/** A signed-in Plex account and the servers it reaches. */
interface PlexAccountServers {
    /** The account's connection id (`plex.<accountUuid>`). */
    val accountId: String

    /** This device's identifier on the account's plex.tv device list. */
    val clientIdentifier: String

    val accountToken: String
    val servers: List<PlexServerEntry>
}

/**
 * A Plex client as the manager drives it. Its [MediaBackend.cacheServerId] is its [PlexProfileScopeId].
 */
interface PlexServerClient : MediaBackend {
    /** The endpoint requests go to now. */
    val baseUrl: String

    /** The server token requests carry. */
    val token: String?

    /** Replaces the failover order; [switchToFirst] moves requests to its first endpoint now. */
    suspend fun updateEndpointPreferences(endpoints: List<String>, switchToFirst: Boolean)

    /**
     * Moves the client to [token] and [profileScopeId] once a probe under [token] confirms the same server. True when
     * committed; false when a newer update superseded this one. Throws the probe's failure (a 401 or 403 as
     * [com.edde746.plezy.backend.MediaServerHttpException], another server answering as any other exception); nothing
     * changes then.
     */
    suspend fun applyProfileUpdate(token: String, profileScopeId: PlexProfileScopeId): Boolean

    /** The language metadata is requested in from now on. */
    fun applyLanguage(languageCode: String)

    /** The plex.tv account this client acts for (Live TV favorites are keyed by it). */
    fun bindAccount(accountId: String, accountToken: String)
}

/** What a Plex client reports back to the manager. */
interface PlexClientEvents {
    /** One request failed on every endpoint. */
    fun onAllEndpointsExhausted()

    /** Failover moved the client to [newUrl]. */
    suspend fun onEndpointChanged(newUrl: String)
}

/** The Plex side of connecting: endpoint races, client creation and plex.tv server lists. */
interface PlexConnector {
    /**
     * Races [server]'s endpoints, [preferredUrl] with a head start. The first emission is the first working endpoint;
     * each later one is a better endpoint. Completes when the race is over; completes empty when nothing answers.
     */
    fun raceEndpoints(server: PlexServerEntry, preferredUrl: String?, clientIdentifier: String?): Flow<RacedEndpoint>

    /**
     * A client for [server] on [endpoint] that fails over along [failoverEndpoints], acts for [clientIdentifier],
     * requests in the app's language, reports to [events], and is scoped to [profileScopeId].
     */
    suspend fun createClient(
        server: PlexServerEntry,
        endpoint: RacedEndpoint,
        failoverEndpoints: List<String>,
        clientIdentifier: String,
        profileScopeId: PlexProfileScopeId,
        events: PlexClientEvents,
    ): PlexServerClient

    /**
     * Fetches [accountId]'s server list (addresses, tokens) from plex.tv again and applies it through
     * [MultiServerManager.refreshTokensForProfile]. A server that restarted may have a new address or port.
     */
    suspend fun refreshServerList(accountId: String)
}

/** The base URL a Plex server answered on last (`server_endpoint_<serverId>`): the next race's head start. */
interface PreferredEndpointStore {
    suspend fun read(serverId: ServerId): String?

    suspend fun save(serverId: ServerId, url: String)

    suspend fun clear(serverId: ServerId)
}

/** One user on one Jellyfin or Emby server. */
interface MediaBrowserConnection {
    /** `"{machineId}/{userId}"`: also the client's [MediaBackend.cacheServerId]. */
    val id: String
    val serverId: ServerId
    val serverName: String
    val isAdministrator: Boolean
}

/** A Jellyfin or Emby client; [connection] is its current view of the connection. */
interface MediaBrowserServerClient : MediaBackend {
    val connection: MediaBrowserConnection
}

/** What a MediaBrowser client reports back to the manager. */
interface MediaBrowserClientEvents {
    /** One request failed on every endpoint. */
    fun onAllEndpointsExhausted()

    /**
     * The client learned a changed connection (admin flag, avatar tag, endpoints), as it is to be stored. Returns once
     * it is persisted or the manager dropped it.
     */
    suspend fun onConnectionUpdated(updated: MediaBrowserConnection)
}

/** The MediaBrowser side of connecting. */
interface MediaBrowserConnector {
    /**
     * Whether a live client on [live] serves [incoming] unchanged: same dialect, token and device id, and the same set
     * of base URLs in any order.
     */
    fun canReuse(live: MediaBrowserConnection, incoming: MediaBrowserConnection): Boolean

    /**
     * A client for [connection] reporting to [events]: with several base URLs it races them (keeping the stored ones as
     * fallbacks, persisting a reconciled connection); when the race fails it uses the stored active URL alone. Throws
     * when no client can be built.
     */
    suspend fun createClient(connection: MediaBrowserConnection, events: MediaBrowserClientEvents): MediaBrowserServerClient

    /** Stores [connection] (the connections table). */
    suspend fun persistConnection(connection: MediaBrowserConnection)
}
