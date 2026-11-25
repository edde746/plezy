package com.edde746.plezy.app

import com.edde746.plezy.backend.net.canonicalizeBaseUrl
import com.edde746.plezy.jellyfin.JellyfinConnection
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.MediaBrowserDialect
import com.edde746.plezy.model.MediaLibrary
import com.edde746.plezy.profiles.BootRoute
import com.edde746.plezy.profiles.MediaBrowserAddResult
import com.edde746.plezy.profiles.ProfileSwitchResult
import com.edde746.plezy.profiles.mediaBrowser
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.first
import kotlin.coroutines.cancellation.CancellationException

/**
 * A media server a development session signs into (`--dev-server`, [DevLaunch]), as given on the command line:
 * `<kind>=<user>:<password>@<url>` ([parse]), the kind `jellyfin` or `emby`
 * (`jellyfin=maestro:maestro@http://192.168.0.15:28096`). The password may be empty (`guest:@http://…`); the URL is
 * everything after the last `@`, an `http(s)` one. A Plex server signs in through a plex.tv account, which no
 * development option holds: `plex=…` fails the launch saying so.
 *
 * [signInDevServers] signs the session in.
 */
data class DevServer(val dialect: MediaBrowserDialect, val username: String, val password: String, val url: String) {
    /** Without the password: a launch's options may be logged. */
    override fun toString(): String = "${dialect.id}=$username@$url"

    companion object {
        /** [spec] as `<kind>=<user>:<password>@<url>`; IllegalArgumentException with the message to show otherwise. */
        @Throws(IllegalArgumentException::class)
        fun parse(spec: String): DevServer {
            val kind = spec.substringBefore('=', missingDelimiterValue = "")
            require(kind != "plex") {
                "can't sign into Plex: a Plex server signs in through a plex.tv account; jellyfin=… or emby=… sign in by name"
            }
            val dialect = MediaBrowserDialect.entries.firstOrNull { it.id == kind }
                ?: throw IllegalArgumentException("needs <kind>=<user>:<password>@<url>, the kind jellyfin or emby, got '$kind'")
            val rest = spec.substringAfter('=')
            val at = rest.lastIndexOf('@')
            val credentials = if (at < 0) "" else rest.substring(0, at)
            val url = rest.substring(at + 1)
            val colon = credentials.indexOf(':')
            require(colon > 0) { "needs <user>:<password>@ before the URL (the password may be empty)" }
            require((url.startsWith("http://") || url.startsWith("https://")) && url.substringAfter("://").isNotEmpty()) {
                "needs an http(s) URL after the @, got '$url'"
            }
            return DevServer(dialect, credentials.substring(0, colon), credentials.substring(colon + 1), url)
        }
    }
}

/**
 * A server [signInDevServers] signed the session into: its [connection] and the [libraries] its user sees (none while
 * the device is offline: they aren't fetched).
 */
class DevServerSession(val connection: JellyfinConnection, val libraries: List<MediaLibrary>)

/**
 * Signs this session into [servers], in order, once its profiles have started: each user signs in by name and is added
 * to the active profile ([com.edde746.plezy.profiles.ProfileServices.addMediaBrowserConnection]; on a first run, a new
 * local profile named after the first user, made active). A connection already stored for the user at that URL, bound
 * to the active profile with its tokens (a kept database, `--dev-data`, whose tokens are still held) is used as it is;
 * one whose tokens are gone (a development session holds them in memory) is signed in again, into the same profile.
 * Then it waits for the profile's bind and logs each server's name, id and libraries. With "ask for profile on app
 * open" on and more than one profile, the picker holds the active profile's first bind: entered at boot ([entry]) the
 * sign-in goes on once the profile the user picks there has bound and the servers are online, while the picker shows;
 * entered at main, where no picker shows, it picks the active profile itself, as the picker would. While the device is
 * offline (`offline=true`) nothing can sign in: a stored connection of the user at that URL is kept whether or not its
 * tokens are held, so the session opens on what the device keeps (its downloads), and neither the bind nor the
 * libraries are awaited. The device held offline once the users signed in (a UI test's `offline=true` as soon as Home
 * shows, which it does before the sign-in ends) ends it there the same way: the bind or the libraries that failed for
 * it are let go, and the connections are kept.
 *
 * @throws IllegalStateException when the profile doesn't bind, or a server isn't online after it, while the device is
 * online: the launch fails.
 */
@Throws(CancellationException::class, IllegalStateException::class)
suspend fun AppSession.signInDevServers(servers: List<DevServer>, entry: DevEntry): List<DevServerSession> {
    profiles.hydrated.first { it }
    val held = profiles.bootRoute() == BootRoute.PICK_PROFILE && profiles.active.value != null
    if (!graph.network.value.online) return keptOffline(servers)
    val signedIn = servers.map { server ->
        val stored = boundConnection(server)
        if (stored != null) {
            Log.i(TAG) { "Using the stored connection of ${stored.userName} on ${stored.serverName}" }
            return@map stored
        }
        val connection = profiles.jellyfinAuth(server.dialect).authenticateByName(server.url, server.username, server.password)
        val added = profiles.addMediaBrowserConnection(connection)
        check(added is MediaBrowserAddResult.Added) { "$server: the session has profiles but none is active, so none takes the server" }
        Log.i(TAG) { "Signed in as ${connection.userName} on ${connection.serverName}, profile ${added.profile.displayName}" }
        connection
    }
    return try {
        if (held) awaitPickedProfile(entry, signedIn)
        boundSessions(servers)
    } catch (e: Exception) {
        if (e is CancellationException || graph.network.value.online) throw e
        Log.i(TAG, e) { "Offline once signed in: the bind or the libraries failed" }
        keptOffline(servers)
    }
}

/**
 * The picker holds the first bind: entered at boot, until a profile picked there has bound and [signedIn]'s servers are
 * online to it (or the device is offline); entered at main, where no picker shows, the active profile is picked here as
 * the picker picks it. A profile with a PIN only the picker can open.
 */
private suspend fun AppSession.awaitPickedProfile(entry: DevEntry, signedIn: List<JellyfinConnection>) {
    when (entry) {
        DevEntry.BOOT -> {
            Log.i(TAG) { "Signed in: the bind waits for the profile picker" }
            combine(servers.store.state, graph.network) { state, network -> !network.online || signedIn.all { state.isServerOnline(it.serverId) } }
                .first { it }
        }
        DevEntry.MAIN -> {
            val active = checkNotNull(profiles.active.value) { "No profile is active to pick" }
            Log.i(TAG) { "No picker at the main screen: picking ${active.displayName} as the picker would" }
            val switched = profiles.switchProfile(active) { _, _ -> null }
            check(switched != ProfileSwitchResult.CANCELLED) { "${active.displayName} has a PIN, which only the picker asks: --dev-entry boot" }
        }
    }
}

/** Each of [servers] bound to the active profile, online, with its libraries. */
private suspend fun AppSession.boundSessions(servers: List<DevServer>): List<DevServerSession> {
    check(profiles.awaitBindingSettle()) { "The active profile didn't bind to ${servers.joinToString()}" }
    return servers.map { server ->
        val connection = checkNotNull(boundConnection(server)) { "$server isn't bound to the active profile" }
        val client = this.servers.manager.mediaBrowserClient(connection.id)
        check(client != null && this.servers.manager.isServerOnline(connection.serverId)) { "${connection.serverName} ($server) isn't online" }
        val libraries = client.fetchLibraries()
        Log.i(TAG) {
            "${connection.serverName} (${connection.serverMachineId}, ${connection.dialect.productName}) as ${connection.userName}: " +
                "libraries ${libraries.joinToString { it.title }}"
        }
        DevServerSession(connection, libraries)
    }
}

/** Each of [servers]' stored connection, without libraries: the device is offline. */
private suspend fun AppSession.keptOffline(servers: List<DevServer>): List<DevServerSession> = servers.map { server ->
    val stored = checkNotNull(boundConnection(server, tokensHeld = false)) { "$server: offline, and no connection of its user is stored" }
    Log.i(TAG) { "Offline: keeping the stored connection of ${stored.userName} on ${stored.serverName}" }
    DevServerSession(stored, emptyList())
}

/**
 * The stored connection of [server]'s user at its URL that the active profile is bound to, its tokens held unless
 * [tokensHeld] is false; null when there is none.
 */
private suspend fun AppSession.boundConnection(server: DevServer, tokensHeld: Boolean = true): JellyfinConnection? {
    val profile = profiles.active.value ?: return null
    val bound = servers.bindings.listForProfile(profile.id).filter { !tokensHeld || !it.userToken.isNullOrEmpty() }.mapTo(HashSet()) { it.connectionId }
    val url = canonicalizeBaseUrl(server.url)
    return servers.connections.list().firstNotNullOfOrNull { stored ->
        stored.mediaBrowser()?.takeIf {
            it.id in bound && (!tokensHeld || it.accessToken.isNotEmpty()) && url in it.baseUrls && it.userName.equals(server.username, ignoreCase = true)
        }
    }
}

private const val TAG = "DevServers"
