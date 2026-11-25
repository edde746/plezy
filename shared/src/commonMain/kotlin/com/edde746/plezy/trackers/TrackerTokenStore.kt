package com.edde746.plezy.trackers

import com.edde746.plezy.log.Log
import com.edde746.plezy.secrets.SecretStore
import kotlin.coroutines.cancellation.CancellationException
import kotlinx.serialization.Serializable
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.json.Json

/**
 * A connection's session as this device keeps it. [connectedAt] names the sign-in it belongs to
 * ([com.edde746.plezy.data.tracker.TrackerAccount.connectedAt]).
 */
@Serializable
internal data class StoredSession(val connectedAt: Long, val session: TrackerSession) {
    override fun toString(): String = "StoredSession(connectedAt=$connectedAt, $session)"
}

/**
 * This device's tracker sessions, per profile scope and service: the tokens the service issued, refresh token
 * included, which only this device holds and refreshes. A scope is [com.edde746.plezy.profiles.profileUserScope]'s:
 * a Plex Home user's profiles on every account share one session. Earlier builds kept a Plex Home profile's under its
 * full id; [TrackerAccounts.adoptLegacyScopes] moves those.
 *
 * One `SecretStore` entry per scope and service, JSON-encoded, plus an index of those entries (the store can't list
 * its keys), so sessions whose connection is gone can be cleared.
 *
 * The store's own failures (Android's Keystore or a failed `commit()`, a Keychain status, libsecret, Credential
 * Manager) come out of [load], [save] and [clear] as [TrackerException.SecretStore]s: they say nothing about a write,
 * so it stays queued with its attempts, and a list shows its error. [stored] throws the store's failure as it is: only
 * the cleanup of unused sessions lists them, and it logs it.
 */
internal class TrackerTokenStore(private val secrets: SecretStore) {
    /**
     * The stored session, or `null` when there is none, it no longer decodes, or it lacks what [service]'s sessions
     * always have ([TrackerSession.isValidFor]): a broken session is a clean sign-in again, never one that can't renew.
     */
    suspend fun load(scope: String, service: TrackerService): StoredSession? {
        val bytes = guarded(service, "read") { secrets.get(key(scope, service)) } ?: return null
        val stored = try {
            json.decodeFromString(StoredSession.serializer(), bytes.decodeToString())
        } catch (e: IllegalArgumentException) {
            // SerializationException included.
            Log.w(TAG) { "stored ${service.id} session unreadable" }
            return null
        }
        if (!stored.session.isValidFor(service)) {
            Log.w(TAG) { "stored ${service.id} session incomplete, sign in again" }
            return null
        }
        return stored
    }

    suspend fun save(scope: String, service: TrackerService, session: StoredSession) = guarded(service, "write") {
        secrets.put(key(scope, service), json.encodeToString(StoredSession.serializer(), session).encodeToByteArray())
        val index = index()
        val entry = IndexEntry(scope, service.id)
        if (entry !in index) writeIndex(index + entry)
    }

    suspend fun clear(scope: String, service: TrackerService) = guarded(service, "delete") {
        secrets.delete(key(scope, service))
        val index = index()
        val entry = IndexEntry(scope, service.id)
        if (entry in index) writeIndex(index - entry)
    }

    /** Every scope and service with a stored session. */
    suspend fun stored(): Set<Pair<String, TrackerService>> =
        index().mapNotNull { entry -> TrackerService.fromId(entry.service)?.let { entry.profileId to it } }.toSet()

    private suspend fun index(): List<IndexEntry> {
        val bytes = secrets.get(INDEX_KEY) ?: return emptyList()
        return try {
            json.decodeFromString(indexSerializer, bytes.decodeToString())
        } catch (e: IllegalArgumentException) {
            Log.w(TAG) { "tracker session index unreadable, starting over" }
            emptyList()
        }
    }

    private suspend fun writeIndex(index: List<IndexEntry>) {
        if (index.isEmpty()) secrets.delete(INDEX_KEY) else secrets.put(INDEX_KEY, json.encodeToString(indexSerializer, index).encodeToByteArray())
    }

    private suspend fun <T> guarded(service: TrackerService, operation: String, call: suspend () -> T): T = try {
        call()
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        Log.e(TAG, e) { "the secret store's $operation of the ${service.id} session failed" }
        throw TrackerException.SecretStore(service, e)
    }

    /** [profileId] names the scope: the field name is the earlier builds'. */
    @Serializable
    private data class IndexEntry(val profileId: String, val service: String)

    internal companion object {
        private const val TAG = "trackers"
        private const val INDEX_KEY = "tracker.index"
        // Every session key is written, an absent value as null, as the earlier releases stored it.
        private val json = Json {
            ignoreUnknownKeys = true
            encodeDefaults = true
        }
        private val indexSerializer = ListSerializer(IndexEntry.serializer())

        /** `tracker.<service>.<scope>`: short ASCII, as `SecretStore` keys must be. */
        fun key(scope: String, service: TrackerService): String = "tracker.${service.id}.$scope"
    }
}
