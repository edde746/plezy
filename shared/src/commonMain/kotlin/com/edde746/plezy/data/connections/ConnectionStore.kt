package com.edde746.plezy.data.connections

import com.edde746.plezy.data.LocalData
import com.edde746.plezy.data.db.Connections
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.profiles.mediaBrowser
import com.edde746.plezy.profiles.plexAccount
import com.edde746.plezy.profiles.repairMissingDefaults
import com.edde746.plezy.profiles.secretKey
import com.edde746.plezy.secrets.SecretStore
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.jsonObject

/**
 * A media-server connection the user added: a Plex account with its servers, or a Jellyfin/Emby server and user.
 * [config] is the connection's configuration in Plezy's connection format, tokens included (the account's
 * `accountToken` and each `servers[].accessToken` for Plex, `accessToken` for Jellyfin/Emby). Times are epoch
 * milliseconds.
 */
data class StoredConnection(
    val id: String,
    val kind: BackendKind,
    val config: JsonObject,
    val createdAt: Long,
    val lastAuthenticatedAt: Long? = null,
)

/**
 * What a stored connection says without its tokens: its [id], [kind] and the names of its servers by server id (a Plex
 * server's client identifier, a Jellyfin/Emby server's machine id).
 */
data class ConnectionSummary(val id: String, val kind: BackendKind, val serverNames: Map<String, String>)

/**
 * The connections (`connections`). Their tokens are taken out of the configuration into [secrets] as they're stored
 * (under a new secret version each time, [IdentitySecrets]) and put back as they're read, so none reaches the database.
 * Changes run one at a time, in the order they're asked for.
 */
class ConnectionStore(localData: LocalData, private val secrets: SecretStore) {
    private val db = localData.db
    private val identity = IdentitySecrets(db, secrets)
    private val mutations = Mutex()

    /** The connections by creation; one whose row doesn't read is left out (and logged). */
    suspend fun list(): List<StoredConnection> = db.read { connectionQueries.selectAll().executeAsList() }.mapNotNull { it.toConnection() }

    /** [list] now and after every change. */
    fun observe(): Flow<List<StoredConnection>> =
        db.observeList(db.database.connectionQueries.selectAll()).map { rows -> rows.mapNotNull { it.toConnection() } }

    /**
     * The connections' summaries by creation, now and after every change, read without a secret. A row whose kind or
     * JSON doesn't read is left out (and logged); one whose backend model doesn't read is still there.
     */
    fun observeSummaries(): Flow<List<ConnectionSummary>> =
        db.observeList(db.database.connectionQueries.selectAll()).map { rows -> rows.mapNotNull { it.toSummary() } }

    suspend fun get(id: String): StoredConnection? = db.read { connectionQueries.selectById(id).executeAsOneOrNull() }?.toConnection()

    /**
     * Stores [connection]. A connection stored before keeps its creation time: it orders the connections list and picks
     * the connection a profile takes its picture from, and signing in again rebuilds the connection with a new one.
     *
     * With [expected] (the connection as it was validated), throws IllegalStateException when the stored configuration,
     * tokens included, is no longer [expected]'s.
     */
    suspend fun upsert(connection: StoredConnection, expected: StoredConnection? = null): Unit = mutations.withLock {
        val before = if (expected == null) null else db.read { connectionQueries.selectById(connection.id).executeAsOneOrNull() }
        if (expected != null) {
            val current = before?.toConnection()
            check(current != null && current.config == expected.config) { CHANGED }
        }
        val staged = connection.staged()
        identity.write(staged.secrets) {
            if (expected != null) {
                // The same secret version holds the same tokens: they never change under it.
                val existing = tx.q.connectionQueries.selectById(connection.id).executeAsOneOrNull()
                check(existing != null && existing.config_json == before?.config_json && existing.secret_version == before.secret_version) { CHANGED }
            }
            putConnection(staged)
        }
    }

    /**
     * Removes the connection [id], its profile bindings with it; a profile left without a default binding gets its
     * lowest connection id as one. Its tokens and its bindings' tokens go too.
     */
    suspend fun remove(id: String): Unit = mutations.withLock {
        identity.write(emptyMap()) { removeConnection(id) }
    }

    /** Removes every connection, its bindings and their tokens. */
    suspend fun clear(): Unit = mutations.withLock {
        identity.write(emptyMap()) {
            val queries = tx.q
            queries.connectionQueries.selectAll().executeAsList().forEach { unreference(it.secretKeys()) }
            queries.profileQueries.selectAllBindings().executeAsList().forEach { unreference(listOf(it.secretKey())) }
            queries.connectionQueries.deleteAll()
        }
    }

    /**
     * Deletes the tokens a change interrupted by the app's end left behind. Runs at start, before any connection or
     * binding changes.
     */
    suspend fun sweepUnreferencedSecrets() = identity.sweep()

    /** This row's kind and stored configuration, or null (logged) when either won't read. */
    private fun Connections.decode(): Pair<BackendKind, JsonObject>? = try {
        BackendKind.fromId(kind) to Json.parseToJsonElement(config_json).jsonObject
    } catch (e: IllegalArgumentException) {
        // SerializationException is one too.
        Log.e(TAG, e) { "connection $id doesn't decode; it's left out" }
        null
    }

    private fun Connections.toSummary(): ConnectionSummary? {
        val (kind, stored) = decode() ?: return null
        val serverNames = when (kind) {
            BackendKind.PLEX -> (stored["servers"] as? JsonArray).orEmpty().mapNotNull { server ->
                val obj = server as? JsonObject ?: return@mapNotNull null
                val clientId = obj.stringOrNull("clientIdentifier") ?: return@mapNotNull null
                clientId to (obj.stringOrNull("name") ?: return@mapNotNull null)
            }.toMap()
            BackendKind.JELLYFIN, BackendKind.EMBY -> {
                val machineId = stored.stringOrNull("serverMachineId")
                val name = stored.stringOrNull("serverName")
                if (machineId == null || name == null) emptyMap() else mapOf(machineId to name)
            }
        }
        return ConnectionSummary(id, kind, serverNames)
    }

    /** This row's connection, its tokens put back, or null (logged) when its kind, JSON or backend model won't read. */
    private suspend fun Connections.toConnection(): StoredConnection? {
        val (kind, stored) = decode() ?: return null
        val config = when (kind) {
            BackendKind.PLEX -> {
                val withServers = stored["servers"].let { servers ->
                    if (servers !is JsonArray) return@let stored
                    val revealed = servers.map { server ->
                        val obj = server as? JsonObject ?: return@map server
                        val clientId = obj.stringOrNull("clientIdentifier") ?: return@map server
                        val token = secrets.get(serverTokenKey(id, secret_version, clientId))?.decodeToString() ?: return@map server
                        JsonObject(obj + (ACCESS_TOKEN to JsonPrimitive(token)))
                    }
                    JsonObject(stored + ("servers" to JsonArray(revealed)))
                }
                withServers.withSecret(ACCOUNT_TOKEN, connectionTokenKey(id, secret_version))
            }
            BackendKind.JELLYFIN, BackendKind.EMBY -> stored.withSecret(ACCESS_TOKEN, connectionTokenKey(id, secret_version))
        }
        val connection = StoredConnection(id, kind, config, created_at, last_authenticated_at)
        try {
            connection.plexAccount() ?: connection.mediaBrowser()
        } catch (e: IllegalArgumentException) {
            Log.e(TAG, e) { "connection $id doesn't read as a ${kind.id} connection; it's left out" }
            return null
        }
        return connection
    }

    private suspend fun JsonObject.withSecret(field: String, key: String): JsonObject {
        val token = secrets.get(key)?.decodeToString() ?: return this
        return JsonObject(this + (field to JsonPrimitive(token)))
    }

    private companion object {
        const val TAG = "connections"
        const val CHANGED = "The connection changed after validation."
    }
}

/** A connection ready to store: its configuration without tokens, and the tokens under a new secret [version]. */
internal class StagedConnection(val connection: StoredConnection, val version: String, val config: JsonObject, val secrets: Map<String, String>)

internal fun StoredConnection.staged(): StagedConnection {
    val version = newSecretVersion()
    val stripped = kind.strip(id, version, config)
    return StagedConnection(this, version, stripped.config, stripped.secrets)
}

/** Stores [staged]'s row, naming its secret version; the keys of the row it replaces are unreferenced. */
internal fun IdentityTx.putConnection(staged: StagedConnection) {
    val queries = tx.q.connectionQueries
    val connection = staged.connection
    val configJson = staged.config.toString()
    val existing = queries.selectById(connection.id).executeAsOneOrNull()
    if (existing == null) {
        queries.insertRow(Connections(connection.id, connection.kind.id, configJson, connection.createdAt, connection.lastAuthenticatedAt, staged.version))
    } else {
        unreference(existing.secretKeys())
        queries.update(connection.kind.id, configJson, connection.lastAuthenticatedAt, staged.version, connection.id)
    }
}

/** Removes the connection [id] and its bindings, unreferencing their keys; profiles left without a default get one. */
internal fun IdentityTx.removeConnection(id: String) {
    val queries = tx.q
    queries.connectionQueries.selectById(id).executeAsOneOrNull()?.let { unreference(it.secretKeys()) }
    queries.profileQueries.selectBindingsForConnection(id).executeAsList().forEach { unreference(listOf(it.secretKey())) }
    queries.connectionQueries.deleteById(id)
    tx.repairMissingDefaults()
}

private const val ACCOUNT_TOKEN = "accountToken"
private const val ACCESS_TOKEN = "accessToken"

/** The key of connection [id]'s account or access token under secret [version] (null: unversioned). */
private fun connectionTokenKey(id: String, version: String?) = if (version == null) "connection.$id.token" else "connection.$id.v$version.token"

private fun serverTokenKey(id: String, version: String?, serverClientId: String) =
    if (version == null) "connection.$id.server.$serverClientId.token" else "connection.$id.v$version.server.$serverClientId.token"

/** A configuration with its tokens taken out, and the tokens by SecretStore key. */
internal class Stripped(val config: JsonObject, val secrets: Map<String, String>)

/**
 * [config] of the connection [id] without its tokens, which are keyed under secret [version] (null: unversioned, as an
 * earlier release's import writes them); empty tokens are dropped, not kept.
 */
internal fun BackendKind.strip(id: String, version: String?, config: JsonObject): Stripped {
    val secrets = LinkedHashMap<String, String>()
    fun JsonObject.take(field: String, key: String): JsonObject {
        stringOrNull(field)?.takeIf { it.isNotEmpty() }?.let { secrets[key] = it }
        return JsonObject(this - field)
    }
    val stripped = when (this) {
        BackendKind.PLEX -> {
            val account = config.take(ACCOUNT_TOKEN, connectionTokenKey(id, version))
            val servers = account["servers"] as? JsonArray
            if (servers == null) {
                account
            } else {
                val strippedServers = servers.map { server ->
                    if (server !is JsonObject) return@map server
                    val clientId = server.stringOrNull("clientIdentifier")
                    if (clientId == null) JsonObject(server - ACCESS_TOKEN) else server.take(ACCESS_TOKEN, serverTokenKey(id, version, clientId))
                }
                JsonObject(account + ("servers" to JsonArray(strippedServers)))
            }
        }
        BackendKind.JELLYFIN, BackendKind.EMBY -> config.take(ACCESS_TOKEN, connectionTokenKey(id, version))
    }
    return Stripped(stripped, secrets)
}

/** The SecretStore keys this row's tokens are kept under. */
private fun Connections.secretKeys(): Set<String> {
    val keys = mutableSetOf(connectionTokenKey(id, secret_version))
    val config = try {
        Json.parseToJsonElement(config_json).jsonObject
    } catch (e: IllegalArgumentException) {
        Log.w("connections", e) { "connection $id doesn't decode; only its account token is cleared" }
        return keys
    }
    (config["servers"] as? JsonArray)?.forEach { server ->
        (server as? JsonObject)?.stringOrNull("clientIdentifier")?.let { keys += serverTokenKey(id, secret_version, it) }
    }
    return keys
}

private fun JsonObject.stringOrNull(field: String): String? = (this[field] as? JsonPrimitive)?.takeIf { it.isString }?.content
