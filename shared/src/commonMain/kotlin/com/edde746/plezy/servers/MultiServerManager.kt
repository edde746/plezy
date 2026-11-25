package com.edde746.plezy.servers

import com.edde746.plezy.backend.HealthStatus
import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.backend.MediaServerAuthException
import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.backend.MediaServerTimeouts
import com.edde746.plezy.crash.Breadcrumb
import com.edde746.plezy.crash.CrashCapture
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.net.Backoff
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.Deferred
import kotlinx.coroutines.Job
import kotlinx.coroutines.async
import kotlinx.coroutines.cancel
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.flow.emitAll
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.merge
import kotlinx.coroutines.flow.takeWhile
import kotlinx.coroutines.joinAll
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeoutOrNull
import kotlin.time.ComparableTimeMark
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TimeSource

/** One server settling during a profile bind: the startup splash ticks it off. */
data class ConnectProgress(val serverId: ServerId, val online: Boolean)

/**
 * Every media server the app is connected to, Plex and MediaBrowser (Jellyfin, Emby) alike: one client per server id,
 * each server's online status and refusal (401 [HealthStatus.AUTH_ERROR], 403 [HealthStatus.ACCESS_DENIED]), the
 * active profile's visibility filter, and the work that keeps them current: health probes, reconnects, endpoint
 * re-races on network changes, relay escape, endpoint-exhaustion confirmation.
 *
 * A MediaBrowser machine can carry several users: each user's client is kept by its connection id
 * (`"{machineId}/{userId}"`), one of them is the machine's active client.
 *
 * Confined to [scope]'s thread (the app's main thread): call it there. Client events arrive on the thread of the
 * request that raised them and move to it. Client closes run in [scope]; the manager's own timers and tasks stop with
 * [dispose] or [shutdown].
 *
 * @param connectivityChanges the platform's connectivity reports ([ConnectivityProbe.changes]); collected from the first
 *   profile bind, or once a server is online.
 * @param resumeProbeCooldown how long [probeAfterResume] stays quiet after a probe: [RESUME_PROBE_COOLDOWN_MOBILE] on
 *   phones and TVs, [RESUME_PROBE_COOLDOWN_DESKTOP] on desktop, where every window focus is a resume.
 */
class MultiServerManager(
    private val plexConnector: PlexConnector,
    private val mediaBrowserConnector: MediaBrowserConnector,
    private val preferredEndpoints: PreferredEndpointStore,
    private val connectivityChanges: Flow<Connectivity>,
    private val scope: CoroutineScope,
    private val resumeProbeCooldown: Duration,
    private val timeSource: TimeSource.WithComparableMarks = TimeSource.Monotonic,
    private val connectivityDebounce: Duration = 2.seconds,
) : OnlineServers, WatchClients {
    private val work = scope.childScope()

    /** [scope]'s thread, for client events that arrive from a request on another one. */
    private val managerThread = scope.coroutineContext.minusKey(Job)

    private val clients = LinkedHashMap<ServerId, MediaBackend>()
    private val serverStatus = LinkedHashMap<ServerId, Boolean>()

    // Servers whose last probe was refused, and how; their status is offline too.
    private val refused = HashMap<ServerId, HealthStatus>()

    // Plex registrations: the server entry, this device's id on the account, the account, the profile scope.
    private val plexServers = LinkedHashMap<ServerId, PlexServerEntry>()
    private val clientIdByServer = HashMap<ServerId, String>()
    private val plexAccountByServer = HashMap<ServerId, PlexAccountRef>()
    private val plexScopeByServer = HashMap<ServerId, PlexProfileScopeId>()

    // MediaBrowser clients by connection id, the active connection per machine, and each connection's last health.
    private val mediaBrowserByScope = LinkedHashMap<String, MediaBrowserServerClient>()
    private val activeMediaBrowser = HashMap<ServerId, String>()
    private val mediaBrowserHealth = HashMap<String, HealthStatus>()

    private val exhaustionDebounce = HashMap<ServerId, Job>()

    // Servers whose exhaustion is being confirmed: exhaustion the probe itself raises is ignored.
    private val endpointHealthChecks = HashSet<ServerId>()

    private var activeHealthCheck: Deferred<Unit>? = null
    private var activeReconnect: Deferred<Unit>? = null

    // The one optimize or reconnect task running per server.
    private val activeTasks = HashMap<ServerId, Job>()

    private var profileRefreshEpoch = 0
    private val profileRefreshGenerations = HashMap<String, Int>()

    private val plexServerListRefreshes = HashMap<String, Deferred<Unit>>()
    private val plexServerListRefreshStartedAt = HashMap<String, ComparableTimeMark>()

    private var connectivityJob: Job? = null
    private var connectivityDebounceJob: Job? = null

    private val relayEscapeTimers = HashMap<ServerId, Job>()
    private val relayEscapeAttempts = HashMap<ServerId, Int>()

    private var lastResumeProbe: ComparableTimeMark? = null

    private var offlineRetries: Job? = null

    private val statusEvents = ClosableEvents<Map<ServerId, Boolean>>()
    private val progressEvents = ClosableEvents<ConnectProgress>()
    private val visibilityEvents = ClosableEvents<Unit>()

    /**
     * A copy of the online map each time a server's online state or refusal changes, after each profile bind, after a
     * removal, and an empty map on disconnect. Completes on [dispose] and [shutdown].
     */
    val statusUpdates: Flow<Map<ServerId, Boolean>> = statusEvents.flow

    /** Each server as it settles during [refreshTokensForProfile]; [statusUpdates] still emits once per bind. */
    val connectProgress: Flow<ConnectProgress> = progressEvents.flow

    /** Emits when [visibleServerIds] changes. */
    val visibilityChanges: Flow<Unit> = visibilityEvents.flow

    override val changes: Flow<Unit> = merge(statusUpdates.map { }, visibilityChanges)

    /** Servers with a client. */
    val serverIds: List<ServerId> get() = clients.keys.toList()

    /**
     * Every server the manager holds state for: clients plus registrations without one (a Plex server whose connect
     * failed, or one marked refused before a client existed). A reconnect can bring any of them back.
     */
    val registeredServerIds: List<ServerId> get() = LinkedHashSet<ServerId>().apply {
        addAll(clients.keys)
        addAll(plexServers.keys)
        addAll(serverStatus.keys)
    }.toList()

    /**
     * The active profile's servers in its order ([setServerOrder]): [onlineServerIds], and the fan-outs over
     * [onlineClients], list servers in it first and in this order, whatever order they came online in.
     */
    var serverOrder: List<ServerId> = emptyList()
        private set

    /** Lists the servers in [order] (the profile's, its default connection's first) before the others. */
    fun setServerOrder(order: List<ServerId>) {
        serverOrder = order.distinct()
    }

    /** Servers that answered their last probe: those in [serverOrder] in its order, then the rest as they came online. */
    val onlineServerIds: List<ServerId> get() = serverStatus.filterValues { it }.keys.sortedByServerOrder(serverOrder) { it.value }

    val offlineServerIds: List<ServerId> get() = serverStatus.filterValues { !it }.keys.toList()

    /** Servers whose token was rejected (401): a new sign-in fixes them. */
    val authErrorServerIds: Set<ServerId> get() = refusedOf(HealthStatus.AUTH_ERROR)

    /** Servers that know the account and refuse it (403): a new sign-in does not help. */
    val accessDeniedServerIds: Set<ServerId> get() = refusedOf(HealthStatus.ACCESS_DENIED)

    /** Servers that answered and refuse the account, for either reason. */
    val refusedServerIds: Set<ServerId> get() = refused.keys.toSet()

    private fun refusedOf(kind: HealthStatus): Set<ServerId> = refused.filterValues { it == kind }.keys.toSet()

    override fun client(serverId: ServerId): MediaBackend? = clients[serverId]

    /** The MediaBrowser client of connection [connectionId] (`"{machineId}/{userId}"`), active or not. */
    fun mediaBrowserClient(connectionId: String): MediaBrowserServerClient? = mediaBrowserByScope[connectionId]

    /** The client whose private namespace is exactly [clientScopeId], never another user's on the same server. */
    override fun clientByScope(clientScopeId: String): MediaBackend? {
        mediaBrowserByScope[clientScopeId]?.let { return it }
        val plexScope = PlexProfileScopeId.tryParse(clientScopeId) ?: return null
        if (plexScopeByServer[plexScope.publicServerId] != plexScope) return null
        val client = clients[plexScope.publicServerId]
        return if (client is PlexServerClient && client.cacheServerId == plexScope.value) client else null
    }

    /** Server ids the active profile sees; null: no restriction. */
    var visibleServerIds: Set<ServerId>? = null
        private set

    fun setVisibleServerIds(ids: Set<ServerId>?) {
        if (visibleServerIds == ids) return
        visibleServerIds = ids?.toSet()
        visibilityEvents.emit(Unit)
    }

    fun isServerVisible(serverId: ServerId): Boolean = visibleServerIds?.contains(serverId) ?: true

    /**
     * The client a queued download runs under: null for a hidden server. A given [clientScopeId] must resolve exactly
     * and belong to [serverId]; another user's client would run the work under the wrong identity.
     */
    fun resolveDownloadClient(serverId: ServerId, clientScopeId: String? = null): MediaBackend? {
        if (!isServerVisible(serverId)) return null
        if (!clientScopeId.isNullOrEmpty()) {
            val scoped = clientByScope(clientScopeId)
            return if (scoped?.serverId == serverId) scoped else null
        }
        return client(serverId)
    }

    override val onlineClients: Map<ServerId, MediaBackend>
        get() = LinkedHashMap<ServerId, MediaBackend>().apply {
            for (serverId in onlineServerIds) clients[serverId]?.let { put(serverId, it) }
        }

    /** [onlineClients] the active profile sees: what cross-server readers fan out to. */
    override val visibleOnlineClients: Map<ServerId, MediaBackend>
        get() = onlineClients.filterKeys { isServerVisible(it) }

    fun isServerOnline(serverId: ServerId): Boolean = serverStatus[serverId] ?: false

    /**
     * Whether [serverId] is reachable. With a MediaBrowser [clientScopeId], that user's own last health, not the
     * machine's; a scope of another server is never online.
     */
    override fun isClientOnline(serverId: ServerId, clientScopeId: String?): Boolean {
        if (!clientScopeId.isNullOrEmpty()) {
            val client = clientByScope(clientScopeId)
            if (client == null || client.serverId != serverId) return false
            if (client is MediaBrowserServerClient) return mediaBrowserHealth[clientScopeId] == HealthStatus.ONLINE
        }
        return isServerOnline(serverId)
    }

    /**
     * Whether something registered under [serverId] belongs to a profile other than [profileId]: a Plex client or Plex
     * registration scoped to another profile, or a MediaBrowser client whose connection is not one of
     * [mediaBrowserConnectionIds]. A registration without identity belongs to no profile.
     */
    fun isRegisteredForOtherProfile(
        serverId: ServerId,
        profileId: String,
        mediaBrowserConnectionIds: Set<String> = emptySet(),
    ): Boolean {
        val client = clients[serverId]
        if (client is MediaBrowserServerClient && client.connection.id !in mediaBrowserConnectionIds) return true
        if (client is PlexServerClient && PlexProfileScopeId.tryParse(client.cacheServerId)?.profileId != profileId) return true
        val scope = plexScopeByServer[serverId]
        return scope != null && scope.profileId != profileId
    }

    fun serverDisplayName(serverId: ServerId): String =
        clients[serverId]?.serverName ?: plexServers[serverId]?.name ?: serverId.value

    /** Plex: the account owns the server. Jellyfin and Emby: the user is an administrator. Otherwise false. */
    fun isOwnerOrAdmin(serverId: ServerId): Boolean = when (val client = clients[serverId]) {
        is PlexServerClient -> plexServers[serverId]?.owned == true
        is MediaBrowserServerClient -> client.connection.isAdministrator
        else -> false
    }

    /** Requests metadata in [languageCode] on every Plex client. */
    fun updatePlexLanguage(languageCode: String) {
        for (client in clients.values) if (client is PlexServerClient) client.applyLanguage(languageCode)
    }

    /** Publishes [serverId] online or offline, clearing its refusal. */
    fun updateServerStatus(serverId: ServerId, online: Boolean) =
        applyHealth(serverId, if (online) HealthStatus.ONLINE else HealthStatus.OFFLINE)

    /**
     * Marks every server of [account] offline and refused for its token, without a client: a sign-in that failed at
     * startup still needs a server name for the "Sign in again" banner. A registration another profile left on one of
     * these servers is dropped first. One snapshot.
     */
    fun markPlexConnectionAuthError(account: PlexAccountServers, profileId: String) {
        for (server in account.servers) {
            val id = server.serverId
            if (isRegisteredForOtherProfile(id, profileId)) forgetServer(id)?.let { closeLater(it) }
            registerPlexServer(id, server, account, scope = null)
            serverStatus[id] = false
            refused[id] = HealthStatus.AUTH_ERROR
        }
        emitStatus()
    }

    // Profile binds.

    /**
     * Binds [account]'s servers to [profileId], every server in parallel. A Plex client that is online or refused moves
     * to the new token and scope in place; any other server gets a new client within [timeout] (one that connects later
     * is closed). Each server reports on [connectProgress]; one status snapshot follows. A bind superseded by a newer
     * one for the same account, or by a disconnect, commits nothing and returns empty.
     *
     * @return the servers that ended up bound.
     */
    suspend fun refreshTokensForProfile(
        account: PlexAccountServers,
        profileId: String,
        timeout: Duration = MediaServerTimeouts.PER_SERVER_CONNECT,
    ): Set<ServerId> {
        val accountId = account.accountId
        val epoch = profileRefreshEpoch
        val generation = (profileRefreshGenerations[accountId] ?: 0) + 1
        profileRefreshGenerations[accountId] = generation
        val isStale = { epoch != profileRefreshEpoch || profileRefreshGenerations[accountId] != generation }
        if (account.servers.isEmpty()) {
            if (!isStale()) profileRefreshGenerations.remove(accountId)
            return emptySet()
        }
        val bound = LinkedHashSet<ServerId>()
        coroutineScope {
            for (server in account.servers) launch { bindPlexServer(server, account, profileId, timeout, isStale, bound) }
        }
        if (isStale()) return emptySet()
        emitStatus()
        // Even with nothing bound: a server whose connect failed stays registered, and a network that comes up later
        // must re-probe it.
        startNetworkMonitoring()
        profileRefreshGenerations.remove(accountId)
        return bound
    }

    private suspend fun bindPlexServer(
        server: PlexServerEntry,
        account: PlexAccountServers,
        profileId: String,
        timeout: Duration,
        isStale: () -> Boolean,
        bound: MutableSet<ServerId>,
    ) {
        val serverId = server.serverId
        val profileScope = PlexProfileScopeId.of(serverId, profileId)
        val existing = clients[serverId]
        if (existing is PlexServerClient && (serverStatus[serverId] == true || serverId in refused)) {
            try {
                val applied = existing.applyProfileUpdate(server.accessToken, profileScope)
                if (!applied || isStale() || clients[serverId] !== existing) return
                registerPlexServer(serverId, server, account, profileScope)
                refused.remove(serverId)
                serverStatus[serverId] = true
                bound += serverId
                progressEvents.emit(ConnectProgress(serverId, online = true))
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                if (isStale() || clients[serverId] !== existing) return
                Log.e(TAG, e) { "Failed to refresh ${server.name} for the profile" }
                serverStatus[serverId] = false
                markRefusal(serverId, e)
                progressEvents.emit(ConnectProgress(serverId, online = false))
            }
            return
        }

        // A client another profile left here still carries that profile's token: drop it rather than keep it as the
        // fallback while this profile connects, or a health probe could publish it as this profile's.
        if (existing is PlexServerClient && existing.cacheServerId != profileScope.value) {
            forgetServer(serverId)?.let { closeLater(it) }
        }
        registerPlexServer(serverId, server, account, profileScope)
        try {
            val client = timeoutReleasingLate(
                timeLimit = timeout,
                operation = "connect to ${server.name}",
                scope = work,
                releaseLate = { late -> closeClient(late) },
            ) { createClientForServer(server, account.clientIdentifier, profileScope) }
            if (isStale() || plexServers[serverId] !== server) {
                closeLater(client)
                return
            }
            clients[serverId]?.let { closeLater(it) }
            clients[serverId] = client
            serverStatus[serverId] = true
            refused.remove(serverId)
            bound += serverId
            syncRelayEscape(serverId)
            progressEvents.emit(ConnectProgress(serverId, online = true))
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            if (isStale() || plexServers[serverId] !== server) return
            Log.e(TAG, e) { "Failed to connect ${server.name}" }
            serverStatus[serverId] = false
            markRefusal(serverId, e)
            progressEvents.emit(ConnectProgress(serverId, online = false))
        }
    }

    // The single writer of a Plex server's registrations. A null scope keeps a recorded one.
    private fun registerPlexServer(serverId: ServerId, server: PlexServerEntry, account: PlexAccountServers, scope: PlexProfileScopeId?) {
        clientIdByServer[serverId] = account.clientIdentifier
        plexAccountByServer[serverId] = PlexAccountRef(account.accountId, account.accountToken)
        plexServers[serverId] = server
        if (scope != null) plexScopeByServer[serverId] = scope
        (clients[serverId] as? PlexServerClient)?.bindAccount(account.accountId, account.accountToken)
    }

    /**
     * Races [server]'s endpoints from the stored preferred one, builds the client on the first that answers, and keeps
     * draining the race in the background, promoting each better endpoint while the client is still the registered one.
     */
    private suspend fun createClientForServer(
        server: PlexServerEntry,
        clientIdentifier: String,
        profileScope: PlexProfileScopeId,
    ): PlexServerClient {
        val serverId = server.serverId
        val started = timeSource.markNow()
        val race = startEndpointRace(server, clientIdentifier)
        var handedOver = false
        try {
            val first = race.first(server)
            val events = object : PlexClientEvents {
                override fun onAllEndpointsExhausted() {
                    work.launch { onServerEndpointsExhausted(serverId) }
                }

                override suspend fun onEndpointChanged(newUrl: String) {
                    withContext(managerThread) {
                        Log.i(TAG) { "Endpoint changed for ${server.name} after failover: $newUrl" }
                        savePreferredEndpoint(serverId, newUrl, server)
                        syncRelayEscape(serverId)
                    }
                }
            }
            val client = plexConnector.createClient(
                server = server,
                endpoint = first,
                failoverEndpoints = server.prioritizedEndpointUrls(first.url),
                clientIdentifier = clientIdentifier,
                profileScopeId = profileScope,
                events = events,
            )
            try {
                plexAccountByServer[serverId]?.let { client.bindAccount(it.id, it.token) }
                savePreferredEndpoint(serverId, first.url, server)
            } catch (e: Throwable) {
                closeLater(client)
                throw e
            }
            Log.i(TAG) {
                "Connected ${server.name} via ${first.url} (cached endpoint: ${race.cachedEndpoint != null}, ${started.elapsedNow().inWholeMilliseconds} ms)"
            }
            handedOver = true
            work.launch { drainOptimizations(race, client, server) }
            return client
        } finally {
            if (!handedOver) race.job.cancel()
        }
    }

    /**
     * Points [client], the registered client of [server], at the first of [server]'s endpoints that answers and keeps
     * draining the race in the background like [createClientForServer]. False, with nothing changed, when [server],
     * [client], or the device id or profile scope they were registered under, was replaced meanwhile.
     */
    private suspend fun reconnectClient(
        server: PlexServerEntry,
        client: PlexServerClient,
        clientIdentifier: String,
        profileScope: PlexProfileScopeId,
    ): Boolean {
        val serverId = server.serverId
        val race = startEndpointRace(server, clientIdentifier)
        var handedOver = false
        try {
            val first = race.first(server)
            val stale = clients[serverId] !== client ||
                clientIdByServer[serverId] != clientIdentifier ||
                plexScopeByServer[serverId] != profileScope ||
                !promoteEndpoint(client, server, first.url)
            if (stale) return false
            handedOver = true
            work.launch { drainOptimizations(race, client, server) }
            return true
        } finally {
            if (!handedOver) race.job.cancel()
        }
    }

    /** A race of a server's endpoints: [endpoints] carries the first that answers, then each better one. */
    private class EndpointRace(val endpoints: Channel<RacedEndpoint>, val job: Job, val cachedEndpoint: String?) {
        suspend fun first(server: PlexServerEntry): RacedEndpoint {
            val result = endpoints.receiveCatching()
            return result.getOrNull() ?: throw result.exceptionOrNull() ?: IllegalStateException("No working connection found for ${server.name}")
        }
    }

    private suspend fun startEndpointRace(server: PlexServerEntry, clientIdentifier: String): EndpointRace {
        val cachedEndpoint = preferredEndpoints.read(server.serverId)
        val endpoints = Channel<RacedEndpoint>(Channel.UNLIMITED)
        val job = work.launch {
            try {
                plexConnector.raceEndpoints(server, cachedEndpoint, clientIdentifier).collect { endpoints.send(it) }
                endpoints.close()
            } catch (e: CancellationException) {
                endpoints.close()
                throw e
            } catch (e: Exception) {
                endpoints.close(e)
            }
        }
        return EndpointRace(endpoints, job, cachedEndpoint)
    }

    private suspend fun drainOptimizations(race: EndpointRace, client: PlexServerClient, server: PlexServerEntry) {
        try {
            for (endpoint in race.endpoints) {
                if (!isCurrentPlex(server, client)) {
                    Log.d(TAG) { "Stopping stale endpoint optimization for ${server.name}" }
                    break
                }
                if (endpoint.url == client.baseUrl) continue
                Log.i(TAG) { "Background optimization found a better endpoint for ${server.name}: ${client.baseUrl} -> ${endpoint.url}" }
                promoteEndpoint(client, server, endpoint.url)
            }
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "Background connection optimization failed for ${server.name}" }
        } finally {
            race.job.cancel()
        }
    }

    // Whether [server] and [client] are still what is registered (no client registered counts as current).
    private fun isCurrentPlex(server: PlexServerEntry, client: PlexServerClient): Boolean {
        val registered = clients[server.serverId]
        return plexServers[server.serverId] === server && (registered == null || registered === client)
    }

    /** Persists [newUrl], rebuilds the failover order and switches [client], only while both are still registered. */
    private suspend fun promoteEndpoint(client: PlexServerClient, server: PlexServerEntry, newUrl: String): Boolean {
        if (!isCurrentPlex(server, client)) return false
        savePreferredEndpoint(server.serverId, newUrl, server)
        if (!isCurrentPlex(server, client)) return false
        client.updateEndpointPreferences(server.prioritizedEndpointUrls(newUrl), switchToFirst = true)
        val current = isCurrentPlex(server, client)
        if (current) syncRelayEscape(server.serverId)
        return current
    }

    /**
     * Stores [url] as [serverId]'s preferred endpoint unless it is a relay: the preferred endpoint gets the next bind's
     * head start, and a stored relay would pin later sessions to plex.tv's bandwidth-capped relay. Classified against
     * the registered server and the connect-time [captured] one, since a refresh may rotate relay URLs out of either.
     */
    private suspend fun savePreferredEndpoint(serverId: ServerId, url: String, captured: PlexServerEntry?) {
        fun isRelay(server: PlexServerEntry?) = server?.networkClassForUrl(url) == EndpointNetworkClass.RELAY
        if (isRelay(plexServers[serverId]) || isRelay(captured)) {
            Log.d(TAG) { "Refusing to persist a relay endpoint as preferred for $serverId" }
            return
        }
        preferredEndpoints.save(serverId, url)
    }

    // MediaBrowser connections.

    /**
     * Adds one Jellyfin or Emby user. A live client for the same connection that [MediaBrowserConnector.canReuse] is
     * kept and re-probed; otherwise a new client replaces it. The client becomes its machine's active one; another
     * user's client on the machine stays for a later switch back. True when the health probe says online; false on any
     * failure.
     */
    suspend fun addMediaBrowserConnection(connection: MediaBrowserConnection): Boolean {
        try {
            val existing = mediaBrowserByScope[connection.id]
            if (existing != null && mediaBrowserConnector.canReuse(existing.connection, connection)) {
                return reuseMediaBrowserClient(existing)
            }
            val machineId = connection.serverId
            val connectionId = connection.id
            var created: MediaBrowserServerClient? = null
            val events = object : MediaBrowserClientEvents {
                override fun onAllEndpointsExhausted() {
                    work.launch {
                        if (!isActiveMediaBrowser(machineId, connectionId)) {
                            Log.d(TAG) { "Ignoring endpoint exhaustion from an inactive MediaBrowser client $connectionId" }
                            return@launch
                        }
                        onServerEndpointsExhausted(machineId)
                    }
                }

                override suspend fun onConnectionUpdated(updated: MediaBrowserConnection) {
                    withContext(managerThread) { created?.let { applyConnectionUpdate(it, updated) } }
                }
            }
            val client = mediaBrowserConnector.createClient(connection, events)
            created = client
            mediaBrowserByScope[connectionId]?.let { closeLater(it) }
            mediaBrowserByScope[connectionId] = client
            clients[machineId] = client
            activeMediaBrowser[machineId] = connectionId

            val health = client.checkHealth()
            val healthy = health == HealthStatus.ONLINE
            // The probe suspended: another add may have replaced or removed this client, or made another user active.
            if (mediaBrowserByScope[connectionId] !== client) {
                Log.d(TAG) { "Ignoring the health of a replaced or removed client for ${connection.serverName}" }
                return healthy
            }
            mediaBrowserHealth[connectionId] = health
            if (!isActiveMediaBrowser(machineId, connectionId)) {
                Log.d(TAG) { "Ignoring the health of an inactive user for ${connection.serverName}" }
                return healthy
            }
            applyHealth(machineId, health)
            Log.i(TAG) { "Added ${connection.serverName}${if (healthy) "" else " (unhealthy)"}" }
            return healthy
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.e(TAG, e) { "Failed to add ${connection.serverName}" }
            return false
        }
    }

    // An unchanged re-add: keep the live client, bind it as the machine's active user, probe it again.
    private suspend fun reuseMediaBrowserClient(client: MediaBrowserServerClient): Boolean {
        val connectionId = client.connection.id
        val machineId = client.connection.serverId
        val rebound = !isActiveMediaBrowser(machineId, connectionId)
        clients[machineId] = client
        activeMediaBrowser[machineId] = connectionId

        val health = client.checkHealth()
        mediaBrowserHealth[connectionId] = health
        if (!isActiveMediaBrowser(machineId, connectionId)) {
            Log.d(TAG) { "Ignoring a stale reuse result for ${client.connection.serverName}" }
            return health == HealthStatus.ONLINE
        }
        applyHealth(machineId, health)
        // The machine's active user changed even when its status did not: client-map readers must see the swap.
        if (rebound) emitStatus()
        return health == HealthStatus.ONLINE
    }

    private suspend fun applyConnectionUpdate(client: MediaBrowserServerClient, updated: MediaBrowserConnection) {
        if (mediaBrowserByScope[updated.id] !== client) {
            Log.d(TAG) { "Ignoring a stale connection update for ${updated.serverName}" }
            return
        }
        try {
            mediaBrowserConnector.persistConnection(updated)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "Failed to persist a connection update for ${updated.serverName}" }
        }
        emitStatus()
    }

    /** Closes [connection]'s client; when it was its machine's active one, the machine is forgotten too. */
    fun removeMediaBrowserConnection(connection: MediaBrowserConnection) {
        val connectionId = connection.id
        val machineId = connection.serverId
        mediaBrowserByScope.remove(connectionId)?.let { closeLater(it) }
        mediaBrowserHealth.remove(connectionId)
        if (isActiveMediaBrowser(machineId, connectionId)) {
            forgetServer(machineId)
            emitStatus()
        }
    }

    private fun isActiveMediaBrowser(machineId: ServerId, connectionId: String): Boolean = activeMediaBrowser[machineId] == connectionId

    // Health.

    private fun applyHealth(serverId: ServerId, status: HealthStatus) {
        val online = status == HealthStatus.ONLINE
        val refusal = if (status == HealthStatus.AUTH_ERROR || status == HealthStatus.ACCESS_DENIED) status else null
        val previousOnline = serverStatus[serverId]
        val previousRefusal = refused[serverId]
        serverStatus[serverId] = online
        if (refusal != null) refused[serverId] = refusal else refused.remove(serverId)

        if (previousOnline != online || previousRefusal != refusal) {
            emitStatus()
            when (refusal) {
                HealthStatus.AUTH_ERROR -> Log.w(TAG) { "Server $serverId rejected the token" }
                HealthStatus.ACCESS_DENIED -> Log.w(TAG) { "Server $serverId refused this account (HTTP 403)" }
                else -> Log.d(TAG) { "Server $serverId online: $online" }
            }
        }
        // Network changes re-probe every server, which the offline verdict rests on: monitor whenever one is online,
        // including one a reconnect brought back after a session that started with everything unreachable.
        if (online && serverId in clients) startNetworkMonitoring()
    }

    private fun markRefusal(serverId: ServerId, error: Throwable) {
        refusalFor(error)?.let { refused[serverId] = it }
    }

    /**
     * Probes every client in parallel (auth-required, so a revoked token reads as a refusal). Concurrent calls share
     * one pass. A result for a client replaced meanwhile, or a MediaBrowser user no longer active, is not applied.
     */
    suspend fun checkServerHealth() {
        val active = activeHealthCheck ?: work.async { doCheckServerHealth() }.also { started ->
            activeHealthCheck = started
            started.invokeOnCompletion { if (activeHealthCheck === started) activeHealthCheck = null }
        }
        active.await()
    }

    private suspend fun doCheckServerHealth() = coroutineScope {
        Log.d(TAG) { "Checking health for ${clients.size} servers" }
        for ((serverId, client) in clients.toList()) {
            launch {
                val connectionId = (client as? MediaBrowserServerClient)?.connection?.id
                val status = client.checkHealth()
                if (connectionId != null) {
                    mediaBrowserHealth[connectionId] = status
                    if (!isActiveMediaBrowser(serverId, connectionId)) {
                        Log.d(TAG) { "Ignoring a stale health result for $connectionId" }
                        return@launch
                    }
                }
                if (clients[serverId] !== client) {
                    Log.d(TAG) { "Ignoring a stale health result for $serverId" }
                    return@launch
                }
                applyHealth(serverId, status)
                if (status != HealthStatus.ONLINE) Log.w(TAG) { "Server $serverId health check failed: $status" }
            }
        }
    }

    // Network changes.

    private fun startNetworkMonitoring() {
        if (connectivityJob != null) return
        Log.i(TAG) { "Starting network monitoring" }
        connectivityJob = work.launch(start = CoroutineStart.UNDISPATCHED) {
            try {
                connectivityChanges.collect { connectivity ->
                    // "No network" re-probes like any other change: it means no internet-capable adapter, not no
                    // route to the server. Probes drop the servers that became unreachable and keep loopback or
                    // LAN-without-WAN ones online.
                    connectivityDebounceJob?.cancel()
                    connectivityDebounceJob = work.launch {
                        delay(connectivityDebounce)
                        connectivityDebounceJob = null
                        val first = connectivity.links.firstOrNull() ?: ConnectivityLink.NONE
                        Log.d(TAG) { "Connectivity changed (${connectivity.links}), re-optimizing all servers" }
                        reoptimizeAllServers("connectivity:${first.name.lowercase()}")
                        checkServerHealth()
                    }
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "Connectivity listener failed" }
            }
        }
    }

    private fun stopNetworkMonitoring() {
        connectivityJob?.cancel()
        connectivityJob = null
        connectivityDebounceJob?.cancel()
        connectivityDebounceJob = null
    }

    /**
     * Runs [task] as [serverId]'s single optimize or reconnect task, cut at [timeout] when given. Null, without running
     * it, while another task for the server runs.
     */
    private fun runServerTask(serverId: ServerId, timeout: Duration? = null, label: String = "Task", task: suspend () -> Unit): Job? {
        if (serverId in activeTasks) return null
        val job = work.launch(start = CoroutineStart.LAZY) {
            if (timeout == null) {
                task()
            } else if (withTimeoutOrNull(timeout) { task() } == null) {
                Log.d(TAG) { "$label timed out for $serverId" }
            }
        }
        activeTasks[serverId] = job
        job.invokeOnCompletion { if (activeTasks[serverId] === job) activeTasks.remove(serverId) }
        job.start()
        return job
    }

    // Online Plex servers get their endpoints re-raced, offline ones a reconnect; offline MediaBrowser ones a probe.
    private fun reoptimizeAllServers(reason: String) {
        for ((serverId, server) in plexServers.toList()) {
            if (serverId in activeTasks) {
                Log.d(TAG) { "Optimization already running for ${server.name}, skipping ($reason)" }
                continue
            }
            runServerTask(serverId) {
                if (isServerOnline(serverId)) reoptimizeServer(serverId, server, reason) else reconnectServer(serverId, server)
            }
        }
        // Online MediaBrowser clients keep their endpoint and fail over per request.
        for ((serverId, connectionId) in activeMediaBrowser.toList()) {
            if (isServerOnline(serverId)) continue
            val client = mediaBrowserByScope[connectionId] ?: continue
            runServerTask(serverId) { reconnectMediaBrowserServer(serverId, client) }
        }
    }

    // Races [server]'s endpoints again and promotes the better ones; without a client, only stores the preferred one.
    private suspend fun reoptimizeServer(serverId: ServerId, server: PlexServerEntry, reason: String) {
        val registered = clients[serverId]
        val client = registered as? PlexServerClient
        if (registered != null && client == null) return
        try {
            Log.d(TAG) { "Starting connection optimization for ${server.name} ($reason)" }
            val cachedEndpoint = preferredEndpoints.read(serverId)
            plexConnector.raceEndpoints(server, cachedEndpoint, clientIdByServer[serverId]).takeWhile { endpoint ->
                when {
                    client != null && client.baseUrl == endpoint.url -> true
                    client != null -> promoteEndpoint(client, server, endpoint.url).also { promoted ->
                        if (promoted) Log.i(TAG) { "Switched ${server.name} to ${endpoint.url}" }
                    }
                    plexServers[serverId] !== server -> false
                    else -> {
                        savePreferredEndpoint(serverId, endpoint.url, server)
                        plexServers[serverId] === server
                    }
                }
            }.collect()
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "Connection optimization failed for ${server.name}" }
        }
    }

    private fun isOnRelay(serverId: ServerId): Boolean {
        val client = clients[serverId] as? PlexServerClient ?: return false
        return plexServers[serverId]?.networkClassForUrl(client.baseUrl) == EndpointNetworkClass.RELAY
    }

    /**
     * Re-races every online Plex server that sits on a remote or relay endpoint while it publishes a local direct one:
     * failover can walk a LAN session onto the remote endpoint (a dead pooled socket after sleep looks like a dead
     * endpoint) and a same-network wake brings no connectivity change to undo it.
     */
    suspend fun reoptimizeDemotedServers(reason: String) {
        val jobs = mutableListOf<Job>()
        for ((serverId, server) in plexServers.toList()) {
            val client = clients[serverId] as? PlexServerClient ?: continue
            if (!isServerOnline(serverId) || serverId in activeTasks) continue
            val activeClass = server.networkClassForUrl(client.baseUrl)
            if (activeClass == EndpointNetworkClass.LOCAL || !server.publishesLocalDirectConnection) continue
            Log.i(TAG) { "Re-optimizing ${server.name}: on a ${activeClass.name.lowercase()} endpoint while a local one is published ($reason)" }
            runServerTask(serverId) { reoptimizeServer(serverId, server, reason) }?.let(jobs::add)
        }
        jobs.joinAll()
    }

    /**
     * While [serverId]'s client sits on a relay, re-race its endpoints after about 30 s, 60 s, then every 120 s (equal
     * jitter): plex.tv caps relay bandwidth, and on a stable network nothing else would move the session off it.
     */
    private fun syncRelayEscape(serverId: ServerId) {
        if (!isOnRelay(serverId)) {
            stopRelayEscape(serverId)
            return
        }
        if (serverId in relayEscapeTimers) return
        val attempt = relayEscapeAttempts[serverId] ?: 0
        val wait = Backoff.equalJitter(attempt + 1, RELAY_ESCAPE_BASE_DELAY.inWholeMilliseconds, RELAY_ESCAPE_MAX_DELAY.inWholeMilliseconds).milliseconds
        Log.i(TAG) { "$serverId is on a relay, re-probing direct endpoints in $wait (attempt $attempt)" }
        relayEscapeTimers[serverId] = work.launch {
            delay(wait)
            relayEscapeTimers.remove(serverId)
            runRelayEscape(serverId)
        }
    }

    private fun stopRelayEscape(serverId: ServerId) {
        relayEscapeTimers.remove(serverId)?.cancel()
        relayEscapeAttempts.remove(serverId)
    }

    private suspend fun runRelayEscape(serverId: ServerId) {
        val server = plexServers[serverId]
        // Gone, off the relay, or offline (the reconnect path owns offline servers).
        if (server == null || !isOnRelay(serverId) || !isServerOnline(serverId)) {
            stopRelayEscape(serverId)
            return
        }
        relayEscapeAttempts[serverId] = (relayEscapeAttempts[serverId] ?: 0) + 1
        runServerTask(serverId) { reoptimizeServer(serverId, server, "relay-escape") }?.join()
        syncRelayEscape(serverId)
    }

    // Reconnects.

    /**
     * Brings offline [server] back. A registered client whose token and profile scope still apply is kept and pointed
     * at the endpoint that answers: playback reports, scrobbles and downloads hold that instance, and closing it would
     * fail their later requests. Any other client is replaced by a new one.
     */
    private suspend fun reconnectServer(serverId: ServerId, server: PlexServerEntry) {
        val clientIdentifier = clientIdByServer[serverId] ?: run {
            Log.w(TAG) { "Cannot reconnect ${server.name}: no client identifier" }
            return
        }
        val profileScope = plexScopeByServer[serverId] ?: run {
            Log.w(TAG) { "Cannot reconnect ${server.name}: no profile scope" }
            return
        }
        try {
            Log.d(TAG) { "Reconnecting ${server.name}" }
            val existing = clients[serverId] as? PlexServerClient
            if (existing != null && existing.cacheServerId == profileScope.value && existing.token == server.accessToken) {
                if (!reconnectClient(server, existing, clientIdentifier, profileScope)) {
                    Log.d(TAG) { "Ignoring a stale reconnection of ${server.name}" }
                    return
                }
            } else {
                val client = createClientForServer(server, clientIdentifier, profileScope)
                if (plexServers[serverId] !== server ||
                    clientIdByServer[serverId] != clientIdentifier ||
                    plexScopeByServer[serverId] != profileScope
                ) {
                    closeLater(client)
                    Log.d(TAG) { "Ignoring a stale reconnection of ${server.name}" }
                    return
                }
                clients[serverId]?.let { closeLater(it) }
                clients[serverId] = client
                syncRelayEscape(serverId)
            }
            updateServerStatus(serverId, online = true)
            Log.i(TAG) { "Reconnected ${server.name}" }
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.d(TAG, e) { "Reconnecting ${server.name} failed" }
            // The endpoints tried come from the last bind; a restarted server may be on a new address or port.
            if (plexServers[serverId] === server) refreshPlexServerList(serverId)
        }
    }

    // plex.tv's server list for [serverId]'s account again: one call in flight per account, at most one per 30 s.
    private suspend fun refreshPlexServerList(serverId: ServerId) {
        val accountId = plexAccountByServer[serverId]?.id ?: return
        plexServerListRefreshes[accountId]?.let {
            it.await()
            return
        }
        val now = timeSource.markNow()
        val startedAt = plexServerListRefreshStartedAt[accountId]
        if (startedAt != null && now - startedAt < PLEX_SERVER_LIST_REFRESH_INTERVAL) return
        plexServerListRefreshStartedAt[accountId] = now
        val refresh = work.async {
            try {
                plexConnector.refreshServerList(accountId)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "Plex server list refresh failed for $serverId" }
            }
        }
        plexServerListRefreshes[accountId] = refresh
        refresh.invokeOnCompletion { if (plexServerListRefreshes[accountId] === refresh) plexServerListRefreshes.remove(accountId) }
        refresh.await()
    }

    // A MediaBrowser client keeps its own failover; a reconnect is an authenticated probe.
    private suspend fun reconnectMediaBrowserServer(machineId: ServerId, client: MediaBrowserServerClient) {
        val connectionId = client.connection.id
        try {
            val status = client.checkHealth()
            mediaBrowserHealth[connectionId] = status
            if (!isActiveMediaBrowser(machineId, connectionId)) {
                Log.d(TAG) { "Ignoring a stale reconnection result for $connectionId" }
                return
            }
            applyHealth(machineId, status)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.d(TAG, e) { "Reconnecting ${client.connection.serverName} failed" }
        }
    }

    /**
     * Reconnects every offline server, each within 15 s. Concurrent calls share one pass. [forceRediscovery] (the
     * manual retry) first forgets each offline server's preferred endpoint, so a full race runs, and lifts the plex.tv
     * refresh throttle.
     */
    suspend fun reconnectOfflineServers(forceRediscovery: Boolean = false) {
        val active = activeReconnect ?: work.async { doReconnectOfflineServers(forceRediscovery) }.also { started ->
            activeReconnect = started
            started.invokeOnCompletion { if (activeReconnect === started) activeReconnect = null }
        }
        active.await()
    }

    private suspend fun doReconnectOfflineServers(forceRediscovery: Boolean) {
        val offline = offlineServerIds
        if (offline.isEmpty()) return
        Log.d(TAG) { "Reconnecting ${offline.size} offline servers" }
        CrashCapture.breadcrumb(Breadcrumb("servers", "Reconnecting ${offline.size} offline server(s)"))
        if (forceRediscovery) {
            for (serverId in offline) preferredEndpoints.clear(serverId)
            plexServerListRefreshStartedAt.clear()
        }
        val jobs = offline.mapNotNull { serverId ->
            val server = plexServers[serverId]
            if (server != null) {
                runServerTask(serverId, RECONNECT_TIMEOUT, "Reconnection") { reconnectServer(serverId, server) }
            } else {
                val client = activeMediaBrowser[serverId]?.let { mediaBrowserByScope[it] } ?: return@mapNotNull null
                runServerTask(serverId, RECONNECT_TIMEOUT, "MediaBrowser reconnection") { reconnectMediaBrowserServer(serverId, client) }
            }
        }
        jobs.joinAll()
    }

    /**
     * The app came back to the foreground (the library push channels are resumed by their owner first): probe health,
     * reconnect what is offline, then re-race demoted sessions, in that order, and retry what is still offline
     * ([retryOfflinePlexServers]). Does nothing within [resumeProbeCooldown] of the last run.
     */
    suspend fun probeAfterResume() {
        val now = timeSource.markNow()
        val last = lastResumeProbe
        if (last != null && now - last < resumeProbeCooldown) return
        lastResumeProbe = now
        checkServerHealth()
        reconnectOfflineServers()
        // A server woken by these probes may answer seconds later.
        retryOfflinePlexServers()
        reoptimizeDemotedServers("resume")
    }

    /**
     * Reconnects the offline Plex servers 2, 4, 8, 15 and 30 s after each attempt ends, then stops; a new call restarts
     * the schedule. A server that sleeps to save power can be woken by a bind's probes yet answer only after they gave
     * up, and nothing else retries it: a server whose connect failed has no client to report endpoint exhaustion, and a
     * stable network reports no change.
     *
     * Every probe may wake such a server again, so only a profile bind pass and the app coming back start the schedule,
     * never [refreshTokensForProfile]: a failed reconnect fetches the server list again through it, which would renew
     * the schedule forever. An attempt that falls during a profile refresh leaves the connect to the refresh. Servers
     * that refuse the account are skipped (every endpoint gives the same answer); MediaBrowser clients retry through
     * their own endpoint exhaustion. A disconnect cancels the schedule.
     */
    fun retryOfflinePlexServers() {
        offlineRetries?.cancel()
        offlineRetries = work.launch {
            for (wait in OFFLINE_RETRY_DELAYS) {
                if (offlineRetryTargets().isEmpty()) return@launch
                delay(wait)
                if (profileRefreshGenerations.isNotEmpty()) continue
                val targets = offlineRetryTargets()
                Log.d(TAG) { "Retrying ${targets.size} offline Plex servers" }
                targets.mapNotNull { (serverId, server) ->
                    runServerTask(serverId, RECONNECT_TIMEOUT, "Reconnection") { reconnectServer(serverId, server) }
                }.joinAll()
            }
        }
    }

    private fun offlineRetryTargets(): Map<ServerId, PlexServerEntry> = plexServers.filterKeys { serverStatus[it] == false && it !in refused }

    // Endpoint exhaustion: a content request failing everywhere does not prove the server is down. Debounce the burst,
    // then confirm with the health probe before publishing offline.
    private fun onServerEndpointsExhausted(serverId: ServerId) {
        if (serverId in endpointHealthChecks) return
        exhaustionDebounce[serverId]?.cancel()
        exhaustionDebounce[serverId] = work.launch {
            delay(EXHAUSTION_DEBOUNCE)
            exhaustionDebounce.remove(serverId)
            verifyServerEndpointsExhausted(serverId)
        }
    }

    private suspend fun verifyServerEndpointsExhausted(serverId: ServerId) {
        val client = clients[serverId] ?: return
        if (!endpointHealthChecks.add(serverId)) return
        try {
            val health = client.checkHealth()
            if (clients[serverId] !== client) return
            if (client is MediaBrowserServerClient) mediaBrowserHealth[client.connection.id] = health
            applyHealth(serverId, health)
            if (health == HealthStatus.ONLINE) {
                Log.d(TAG) { "Endpoint exhaustion not confirmed for $serverId" }
                return
            }
            // The server answered: every other endpoint gets the same refusal.
            if (health == HealthStatus.AUTH_ERROR || health == HealthStatus.ACCESS_DENIED) return
            val plexServer = plexServers[serverId]
            val mediaBrowser = client as? MediaBrowserServerClient
            if (plexServer == null && mediaBrowser == null) return
            Log.i(TAG) { "Health probe confirmed $serverId offline, reconnecting" }
            runServerTask(serverId) {
                if (plexServer != null) reconnectServer(serverId, plexServer) else reconnectMediaBrowserServer(serverId, mediaBrowser!!)
            }
        } finally {
            endpointHealthChecks.remove(serverId)
        }
    }

    // Removal and teardown.

    /** Forgets [serverId] and closes its client (every user's client on a MediaBrowser machine). Always emits. */
    fun removeServer(serverId: ServerId) {
        val machineConnections = mediaBrowserByScope.filterValues { it.connection.serverId == serverId }.keys.toList()
        val activeClient = forgetServer(serverId)
        if (machineConnections.isNotEmpty()) {
            val closed = HashSet<MediaBackend>()
            for (connectionId in machineConnections) {
                val client = mediaBrowserByScope.remove(connectionId)
                mediaBrowserHealth.remove(connectionId)
                if (client != null && closed.add(client)) closeLater(client)
            }
        } else {
            activeClient?.let { closeLater(it) }
        }
        emitStatus()
        Log.i(TAG) { "Removed server $serverId" }
    }

    // Drops every registration under [serverId] and its pending timers; returns the client to close. In-flight tasks
    // keep their guards: they belong to the work that set them.
    private fun forgetServer(serverId: ServerId): MediaBackend? {
        exhaustionDebounce.remove(serverId)?.cancel()
        stopRelayEscape(serverId)
        val client = clients.remove(serverId)
        activeMediaBrowser.remove(serverId)
        plexServers.remove(serverId)
        clientIdByServer.remove(serverId)
        plexAccountByServer.remove(serverId)
        plexScopeByServer.remove(serverId)
        serverStatus.remove(serverId)
        refused.remove(serverId)
        return client
    }

    /** Disconnects every server now; the clients drain for 2 s in the background. */
    fun disconnectAll() {
        val detached = detachAllClients()
        scope.launch { closeAll(detached, 2.seconds) }
    }

    private fun detachAllClients(): Set<MediaBackend> {
        profileRefreshEpoch++
        profileRefreshGenerations.clear()
        stopNetworkMonitoring()
        exhaustionDebounce.values.forEach { it.cancel() }
        exhaustionDebounce.clear()
        relayEscapeTimers.values.forEach { it.cancel() }
        relayEscapeTimers.clear()
        relayEscapeAttempts.clear()
        offlineRetries?.cancel()
        offlineRetries = null
        activeHealthCheck = null
        activeReconnect = null
        val detached = LinkedHashSet<MediaBackend>().apply {
            addAll(clients.values)
            addAll(mediaBrowserByScope.values)
        }
        clients.clear()
        mediaBrowserByScope.clear()
        activeMediaBrowser.clear()
        mediaBrowserHealth.clear()
        plexServers.clear()
        serverStatus.clear()
        refused.clear()
        clientIdByServer.clear()
        plexAccountByServer.clear()
        plexScopeByServer.clear()
        plexServerListRefreshStartedAt.clear()
        activeTasks.clear()
        statusEvents.emit(emptyMap())
        return detached
    }

    /**
     * The app's exit: completes the flows without a last snapshot (an empty one would flip the still-visible UI to
     * offline), stops the manager's work, then drains every client for up to [drainTimeout].
     */
    suspend fun shutdown(drainTimeout: Duration = 5.seconds) {
        closeFlows()
        val detached = detachAllClients()
        work.cancel()
        closeAll(detached, drainTimeout)
    }

    /** Disconnects every server (the clients drain in the background), stops the manager's work, completes the flows. */
    fun dispose() {
        disconnectAll()
        closeFlows()
        work.cancel()
    }

    private fun closeFlows() {
        statusEvents.close()
        progressEvents.close()
        visibilityEvents.close()
    }

    private fun emitStatus() {
        statusEvents.emit(LinkedHashMap(serverStatus))
    }

    private fun closeLater(client: MediaBackend) {
        scope.launch { closeClient(client) }
    }

    private suspend fun closeClient(client: MediaBackend, drainTimeout: Duration = 2.seconds) {
        try {
            client.closeGracefully(drainTimeout)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "Closing the client of ${client.serverId} failed" }
        }
    }

    private suspend fun closeAll(detached: Collection<MediaBackend>, drainTimeout: Duration) = coroutineScope {
        for (client in detached) launch { closeClient(client, drainTimeout) }
    }

    private data class PlexAccountRef(val id: String, val token: String)

    companion object {
        val RESUME_PROBE_COOLDOWN_MOBILE: Duration = 10.seconds
        val RESUME_PROBE_COOLDOWN_DESKTOP: Duration = 2.minutes

        private val RELAY_ESCAPE_BASE_DELAY = 30.seconds
        private val RELAY_ESCAPE_MAX_DELAY = 2.minutes
        private val EXHAUSTION_DEBOUNCE = 5.seconds
        private val RECONNECT_TIMEOUT = 15.seconds
        private val OFFLINE_RETRY_DELAYS = listOf(2.seconds, 4.seconds, 8.seconds, 15.seconds, 30.seconds)
        private val PLEX_SERVER_LIST_REFRESH_INTERVAL = 30.seconds
        private const val TAG = "MultiServerManager"
    }
}

/**
 * The refusal a failed connect or token change carries: a rejected token (401, or a rejected sign-in) needs a new
 * sign-in; a 403 is the server refusing an account it knows. Null for any other failure.
 */
private fun refusalFor(error: Throwable): HealthStatus? = when {
    error is MediaServerAuthException -> HealthStatus.AUTH_ERROR
    error is MediaServerHttpException && error.statusCode == 401 -> HealthStatus.AUTH_ERROR
    error is MediaServerHttpException && error.statusCode == 403 -> HealthStatus.ACCESS_DENIED
    else -> null
}

/**
 * These items sorted by their server's place in [order] (the first place of a server listed twice); items of a server
 * outside it, or of none, follow, and items of one place keep their order.
 */
internal fun <T> Iterable<T>.sortedByServerOrder(order: List<ServerId>, serverId: (T) -> String?): List<T> {
    if (order.isEmpty()) return toList()
    val ranks = HashMap<String, Int>()
    order.forEachIndexed { index, id -> ranks.getOrPut(id.value) { index } }
    return sortedBy { item -> serverId(item)?.let(ranks::get) ?: Int.MAX_VALUE }
}

/**
 * An event stream that completes: every collector gets the values emitted while it collects, and finishes once
 * [close] is called (a collector arriving later finishes at once). Emitting after [close] does nothing.
 */
private class ClosableEvents<T : Any> {
    private val events = MutableSharedFlow<T?>(extraBufferCapacity = Int.MAX_VALUE)
    private var closed = false

    val flow: Flow<T> = flow {
        if (!closed) emitAll(events.takeWhile { it != null }.map { it!! })
    }

    fun emit(value: T) {
        if (!closed) events.tryEmit(value)
    }

    fun close() {
        if (closed) return
        closed = true
        events.tryEmit(null)
    }
}
