package com.edde746.plezy.app

import com.edde746.plezy.log.Log
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.plex.PlexActivity
import com.edde746.plezy.presentation.home.ServerTaskServers
import com.edde746.plezy.servers.NamedServer
import io.ktor.client.request.header
import io.ktor.client.request.post
import io.ktor.http.isSuccess
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flowOf

/**
 * `--dev-server-tasks`: Home's Server Tasks from a made-up Plex server, "Dev Plex", running a thumbnail pass (which
 * moves on 5 % with each poll and can be cancelled), a library scan (which can't) and a credits detection (which can).
 * A cancelled task is gone from the next answer.
 */
class DevServerTasks : ServerTaskServers {
    private val tasks = mutableListOf(
        PlexActivity("dev-bif", "media.generate.bif", "Generating video preview thumbnails", "Big Buck Bunny", 35, cancellable = true),
        PlexActivity("dev-scan", "library.update.section", "Scanning Movies", null, 60, cancellable = false),
        PlexActivity("dev-credits", "media.generate.credits", "Detecting credits", "Sintel", 10, cancellable = true),
    )

    override val servers: Flow<List<NamedServer>> = flowOf(listOf(NamedServer(SERVER, "Dev Plex")))

    override suspend fun activities(serverId: ServerId): List<PlexActivity> {
        val bif = tasks.indexOfFirst { it.uuid == "dev-bif" }
        if (bif >= 0) tasks[bif] = tasks[bif].let { it.copy(progress = (it.progress + 5) % 100) }
        return tasks.toList()
    }

    override suspend fun cancel(serverId: ServerId, uuid: String) {
        tasks.removeAll { it.uuid == uuid }
    }

    private companion object {
        val SERVER = ServerId("dev-plex")
    }
}

/**
 * `--dev-revoke-token`: ends [server]'s sign-in on its server (`POST /Sessions/Logout` with its token), so the server
 * answers the token with 401 from then on, then probes the servers again: the app says the session expired.
 */
suspend fun AppSession.revokeDevToken(server: DevServerSession) {
    val connection = server.connection
    val response = graph.http.post("${connection.baseUrl.trimEnd('/')}/Sessions/Logout") { header("X-Emby-Token", connection.accessToken) }
    check(response.status.isSuccess()) { "Signing out of ${connection.serverName} answered ${response.status}" }
    Log.i(TAG) { "Signed out of ${connection.serverName} on the server: its token is refused from now on" }
    servers.manager.checkServerHealth()
}

private const val TAG = "DevHome"
