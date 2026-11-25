package com.edde746.plezy.data.tracker

import com.edde746.plezy.data.Db
import com.edde746.plezy.data.db.SelectConnections
import com.edde746.plezy.data.db.Tracker_account
import com.edde746.plezy.profiles.profileUserScope
import com.edde746.plezy.trackers.TrackerService
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

/** A connected tracker account. Its session is in the SecretStore. */
data class TrackerAccount(
    val service: TrackerService,
    val username: String?,
    /**
     * When this device signed it in, epoch milliseconds. It names the binding: a reconnect moves it, so work begun
     * under one sign-in can tell that the account it was for is gone.
     */
    val connectedAt: Long,
)

/**
 * A profile's connected trackers on this device, one per service. They are kept per profile scope
 * ([profileUserScope]): a Plex Home user's profiles on every account share theirs. Every call takes a profile id.
 */
class TrackerAccountRepository internal constructor(private val db: Db) {
    fun observeAccounts(profileId: String): Flow<List<TrackerAccount>> =
        db.observeList(db.database.trackerQueries.selectAccounts(profileUserScope(profileId))).map { rows -> rows.mapNotNull { it.toModel() } }

    suspend fun accounts(profileId: String): List<TrackerAccount> =
        db.read { trackerQueries.selectAccounts(profileUserScope(profileId)).executeAsList().mapNotNull { it.toModel() } }

    /**
     * Every scope's connections on this device, as `scope to service`; it changes whenever one is made or goes.
     * Services this build doesn't know are left out.
     */
    fun observeConnections(): Flow<Set<Pair<String, TrackerService>>> =
        db.observeList(db.database.trackerQueries.selectConnections()).map { rows -> rows.toConnections() }

    suspend fun connections(): Set<Pair<String, TrackerService>> =
        db.read { trackerQueries.selectConnections().executeAsList().toConnections() }

    suspend fun account(profileId: String, service: TrackerService): TrackerAccount? =
        db.read { trackerQueries.selectAccount(profileUserScope(profileId), service.id).executeAsOneOrNull()?.toModel() }

    /**
     * Records the [connectedAt] sign-in as the profile's [service] connection. Reconnecting the same service (a new
     * sign-in, maybe to another account) updates the username and starts a new binding: writes queued under the
     * previous sign-in are dropped, since a queued row carries no account identity and would otherwise replay through
     * the new one, unless [keepQueuedWrites] (the new sign-in is verifiably the same account).
     */
    suspend fun connect(
        profileId: String,
        service: TrackerService,
        username: String?,
        connectedAt: Long,
        keepQueuedWrites: Boolean = false,
    ): TrackerAccount = db.write {
        val scope = profileUserScope(profileId)
        val stored = q.trackerQueries.selectAccount(scope, service.id).executeAsOneOrNull()
        val row = Tracker_account(profile_id = scope, service = service.id, username = username, connected_at = connectedAt)
        q.trackerQueries.upsertAccount(row)
        if (stored?.connected_at != connectedAt && !keepQueuedWrites) q.trackerQueries.deleteQueuedForService(scope, service.id)
        checkNotNull(row.toModel())
    }

    /**
     * Forgets the connection and every write queued for it: a queued row carries no account identity, so it would
     * otherwise replay through whichever account connects to the service next.
     *
     * With [connectedAt], only that binding is forgotten (a session found dead must not sign out the account that
     * replaced it). Returns whether a connection was forgotten.
     */
    suspend fun disconnect(profileId: String, service: TrackerService, connectedAt: Long? = null): Boolean = db.write {
        val scope = profileUserScope(profileId)
        val stored = q.trackerQueries.selectAccount(scope, service.id).executeAsOneOrNull()
        if (connectedAt != null && stored?.connected_at != connectedAt) return@write false
        q.trackerQueries.deleteAccount(scope, service.id)
        q.trackerQueries.deleteQueuedForService(scope, service.id)
        stored != null
    }

    /**
     * The connections earlier builds kept under a Plex Home profile's full id instead of its scope, as
     * `full id to account`.
     */
    internal suspend fun legacyConnections(): List<Pair<String, TrackerAccount>> = db.read {
        trackerQueries.selectAllAccounts().executeAsList()
            .filter { profileUserScope(it.profile_id) != it.profile_id }
            .mapNotNull { row -> row.toModel()?.let { row.profile_id to it } }
    }

    /**
     * Moves the [service] connections earlier builds kept under the full Plex Home profile ids [legacyIds] (all of one
     * scope) to that scope: [kept]'s connection and queued writes replace the scope's own, or with [kept] `null` the
     * scope keeps its own. The other full ids' connections go with their queued writes: a queued row carries no
     * account identity, so it would otherwise replay through the account kept.
     */
    internal suspend fun adoptLegacy(service: TrackerService, legacyIds: List<String>, kept: String?) = db.write {
        val scope = profileUserScope(legacyIds.first())
        if (kept != null) {
            val row = q.trackerQueries.selectAccount(kept, service.id).executeAsOne()
            q.trackerQueries.deleteQueuedForService(scope, service.id)
            q.trackerQueries.upsertAccount(row.copy(profile_id = scope))
            q.trackerQueries.moveQueuedForService(scope, kept, service.id)
        }
        for (id in legacyIds) {
            q.trackerQueries.deleteAccount(id, service.id)
            q.trackerQueries.deleteQueuedForService(id, service.id)
        }
    }

    /** Drops the writes earlier builds left queued under a full Plex Home profile id with no connection to replay them. */
    internal suspend fun dropLegacyQueuedWrites() = db.write {
        for (id in q.trackerQueries.selectQueuedProfileIds().executeAsList()) {
            if (profileUserScope(id) == id) continue
            for (row in q.trackerQueries.selectQueued(id).executeAsList()) q.trackerQueries.deleteQueued(row.id)
        }
    }

    /**
     * Forgets the connections and queued writes of every profile whose scope ([profileUserScope]) is in [scopes]: a
     * removed local profile's, or a signed-out Plex Home user's, which every account's profile of that user shares.
     * Their sessions go after them ([com.edde746.plezy.trackers.TrackerHub] clears those no connection uses).
     */
    suspend fun forgetScopes(scopes: Set<String>) {
        if (scopes.isEmpty()) return
        db.write {
            for (profileId in q.trackerQueries.selectProfileIds().executeAsList()) {
                if (profileUserScope(profileId) !in scopes) continue
                q.trackerQueries.deleteAccountsForProfile(profileId)
                q.trackerQueries.deleteQueuedForProfile(profileId)
            }
        }
    }

    /** Forgets every profile's connections and queued writes (a full logout); their sessions go after them. */
    suspend fun clear() {
        db.write {
            q.trackerQueries.deleteAllAccounts()
            q.trackerQueries.deleteAllQueued()
        }
    }
}

private fun List<SelectConnections>.toConnections() =
    mapNotNull { row -> TrackerService.fromId(row.service)?.let { row.profile_id to it } }.toSet()

private fun Tracker_account.toModel() = TrackerService.fromId(service)?.let { known ->
    TrackerAccount(service = known, username = username, connectedAt = connected_at)
}
