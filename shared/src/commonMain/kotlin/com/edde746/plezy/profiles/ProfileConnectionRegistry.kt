package com.edde746.plezy.profiles

import com.edde746.plezy.data.LocalData
import com.edde746.plezy.data.Tx
import com.edde746.plezy.data.connections.IdentitySecrets
import com.edde746.plezy.data.connections.IdentityTx
import com.edde746.plezy.data.connections.StoredConnection
import com.edde746.plezy.data.connections.newSecretVersion
import com.edde746.plezy.data.connections.putConnection
import com.edde746.plezy.data.connections.removeConnection
import com.edde746.plezy.data.connections.staged
import com.edde746.plezy.data.db.Profile_connections
import com.edde746.plezy.secrets.SecretStore
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock

/**
 * A profile's use of a connection, as one user of it: a Plex Home user's uuid or a Jellyfin/Emby user id
 * ([userIdentifier]), with that user's token. A null or empty [userToken] means none is held: it's minted on the
 * binding's next use. Times are epoch milliseconds.
 */
data class ProfileConnection(
    val profileId: String,
    val connectionId: String,
    val userToken: String? = null,
    val userIdentifier: String,
    val isDefault: Boolean = false,
    val tokenAcquiredAt: Long? = null,
    val lastUsedAt: Long? = null,
) {
    val hasToken: Boolean get() = !userToken.isNullOrEmpty()
}

/**
 * Identity rows changed together, in one transaction ([ProfileConnectionRegistry.commit]): the removals first, then the
 * rows stored.
 */
internal class IdentityChange(
    val profiles: List<LocalProfile> = emptyList(),
    val connections: List<StoredConnection> = emptyList(),
    val bindings: List<ProfileConnection> = emptyList(),
    val removedProfileIds: List<String> = emptyList(),
    val removedConnectionIds: List<String> = emptyList(),
    /** (profile id, connection id) of each binding removed. */
    val removedBindings: List<Pair<String, String>> = emptyList(),
)

/**
 * The profiles' connection bindings (`profile_connections`), each profile with exactly one default among its
 * bindings. Their tokens are in [secrets] (under a new secret version each time, [IdentitySecrets]), never in the
 * database. Changes run one at a time, in the order they're asked for.
 */
class ProfileConnectionRegistry(localData: LocalData, private val secrets: SecretStore) {
    private val db = localData.db
    private val identity = IdentitySecrets(db, secrets)
    private val mutations = Mutex()

    /** [profileId]'s bindings, its default first, then by connection id. */
    suspend fun listForProfile(profileId: String): List<ProfileConnection> =
        db.read { profileQueries.selectBindingsForProfile(profileId).executeAsList() }.map { it.withToken() }

    /** [listForProfile] now and after every change. */
    fun observeForProfile(profileId: String): Flow<List<ProfileConnection>> =
        db.observeList(db.database.profileQueries.selectBindingsForProfile(profileId)).map { rows -> rows.map { it.withToken() } }

    suspend fun listForConnection(connectionId: String): List<ProfileConnection> =
        db.read { profileQueries.selectBindingsForConnection(connectionId).executeAsList() }.map { it.withToken() }

    suspend fun listAll(): List<ProfileConnection> = db.read { profileQueries.selectAllBindings().executeAsList() }.map { it.withToken() }

    /** Every binding now and after every change. */
    fun observeAll(): Flow<List<ProfileConnection>> =
        db.observeList(db.database.profileQueries.selectAllBindings()).map { rows -> rows.map { it.withToken() } }

    suspend fun get(profileId: String, connectionId: String): ProfileConnection? =
        db.read { profileQueries.selectBinding(profileId, connectionId).executeAsOneOrNull() }?.withToken()

    /**
     * Stores [binding] and its token. It becomes its profile's default when [makeDefault] or [ProfileConnection.isDefault]
     * says so (the profile's other bindings stop being it) or when it's the profile's first binding; otherwise a
     * stored binding keeps its default flag.
     */
    suspend fun upsert(binding: ProfileConnection, makeDefault: Boolean = false): Unit = mutations.withLock {
        val staged = binding.staged()
        identity.write(staged.secrets) { putBinding(staged, makeDefault) }
    }

    /**
     * Stores and removes profiles, connections and bindings ([change]) in one transaction: all of them or, when it
     * fails, none.
     */
    internal suspend fun commit(change: IdentityChange): Unit = mutations.withLock {
        val connections = change.connections.map { it.staged() }
        val bindings = change.bindings.map { it.staged() }
        val fresh = connections.flatMap { it.secrets.entries } + bindings.flatMap { it.secrets.entries }
        identity.write(fresh.associate { it.key to it.value }) {
            change.removedBindings.forEach { (profileId, connectionId) -> removeBinding(profileId, connectionId) }
            change.removedConnectionIds.forEach { removeConnection(it) }
            change.removedProfileIds.forEach { tx.q.profileQueries.deleteProfile(it) }
            change.profiles.forEach { tx.putProfile(it) }
            connections.forEach { putConnection(it) }
            bindings.forEach { putBinding(it, makeDefault = false) }
        }
    }

    /**
     * Keeps [token], just minted for the binding, and stamps its acquisition time; nothing is kept when the binding
     * doesn't exist.
     */
    suspend fun recordToken(profileId: String, connectionId: String, token: String): Unit = mutations.withLock {
        val version = newSecretVersion()
        val key = profileConnectionTokenKey(profileId, connectionId, version)
        identity.write(mapOf(key to token)) {
            val existing = tx.q.profileQueries.selectBinding(profileId, connectionId).executeAsOneOrNull()
            if (existing == null) {
                unreference(listOf(key))
            } else {
                unreference(listOf(existing.secretKey()))
                tx.q.profileQueries.setToken(tx.now(), version, profileId, connectionId)
            }
        }
    }

    /** Drops the binding's token (Plex refused it), so its next use mints a new one. */
    suspend fun invalidateToken(profileId: String, connectionId: String): Unit = mutations.withLock {
        identity.write(emptyMap()) {
            val existing = tx.q.profileQueries.selectBinding(profileId, connectionId).executeAsOneOrNull() ?: return@write
            unreference(listOf(existing.secretKey()))
            // A version nothing was written under: no token.
            tx.q.profileQueries.setToken(null, newSecretVersion(), profileId, connectionId)
        }
    }

    suspend fun markUsed(profileId: String, connectionId: String): Unit = mutations.withLock {
        db.write { q.profileQueries.markBindingUsed(now(), profileId, connectionId) }
    }

    /** Makes [connectionId] [profileId]'s only default; throws IllegalStateException when there's no such binding. */
    suspend fun setDefault(profileId: String, connectionId: String): Unit = mutations.withLock {
        db.write {
            val queries = q.profileQueries
            checkNotNull(queries.selectBinding(profileId, connectionId).executeAsOneOrNull()) { "The profile connection is unavailable." }
            queries.clearDefaults(profileId)
            queries.setDefaultFlag(profileId, connectionId)
        }
    }

    /** Removes the binding; a profile left without a default gets its lowest connection id as one. */
    suspend fun remove(profileId: String, connectionId: String): Unit = mutations.withLock {
        identity.write(emptyMap()) { removeBinding(profileId, connectionId) }
    }

    /** Removes every binding to [connectionId], repairing the defaults it leaves missing; returns how many went. */
    suspend fun removeAllForConnection(connectionId: String): Int = mutations.withLock {
        identity.write(emptyMap()) {
            val queries = tx.q.profileQueries
            queries.selectBindingsForConnection(connectionId).executeAsList().forEach { unreference(listOf(it.secretKey())) }
            queries.deleteBindingsForConnection(connectionId)
            val removed = queries.changes().executeAsOne().toInt()
            tx.repairMissingDefaults()
            removed
        }
    }

    /** Removes every binding and its token. */
    suspend fun clear(): Unit = mutations.withLock {
        identity.write(emptyMap()) {
            val queries = tx.q.profileQueries
            queries.selectAllBindings().executeAsList().forEach { unreference(listOf(it.secretKey())) }
            queries.deleteAllBindings()
        }
    }

    private suspend fun Profile_connections.withToken() = ProfileConnection(
        profileId = profile_id,
        connectionId = connection_id,
        userToken = secrets.get(secretKey())?.decodeToString()?.ifEmpty { null },
        userIdentifier = user_identifier,
        isDefault = is_default,
        tokenAcquiredAt = token_acquired_at,
        lastUsedAt = last_used_at,
    )
}

/** A binding ready to store: its token, if any, under a new secret [version]. */
private class StagedBinding(val binding: ProfileConnection, val version: String) {
    val secrets: Map<String, String> = binding.userToken?.takeIf { it.isNotEmpty() }
        ?.let { mapOf(profileConnectionTokenKey(binding.profileId, binding.connectionId, version) to it) }
        .orEmpty()
}

private fun ProfileConnection.staged() = StagedBinding(this, newSecretVersion())

private fun IdentityTx.putBinding(staged: StagedBinding, makeDefault: Boolean) {
    val queries = tx.q.profileQueries
    val binding = staged.binding
    val existing = queries.selectBinding(binding.profileId, binding.connectionId).executeAsOneOrNull()
    val isDefault = when {
        makeDefault || binding.isDefault -> {
            queries.clearDefaults(binding.profileId)
            true
        }
        existing != null -> existing.is_default
        else -> queries.selectBindingsForProfile(binding.profileId).executeAsList().isEmpty()
    }
    if (existing == null) {
        queries.insertBinding(
            Profile_connections(
                binding.profileId,
                binding.connectionId,
                binding.userIdentifier,
                isDefault,
                binding.tokenAcquiredAt,
                binding.lastUsedAt,
                staged.version,
            ),
        )
    } else {
        unreference(listOf(existing.secretKey()))
        queries.updateBinding(
            binding.userIdentifier,
            isDefault,
            binding.tokenAcquiredAt,
            binding.lastUsedAt,
            staged.version,
            binding.profileId,
            binding.connectionId,
        )
    }
}

private fun IdentityTx.removeBinding(profileId: String, connectionId: String) {
    val queries = tx.q.profileQueries
    queries.selectBinding(profileId, connectionId).executeAsOneOrNull()?.let { unreference(listOf(it.secretKey())) }
    queries.deleteBinding(profileId, connectionId)
    tx.promoteDefaultIfMissing(profileId)
}

/** The SecretStore key of a binding's user token under secret [version] (null: unversioned). */
internal fun profileConnectionTokenKey(profileId: String, connectionId: String, version: String?): String =
    if (version == null) "profile_connection.$profileId.$connectionId.token" else "profile_connection.$profileId.$connectionId.v$version.token"

/** The SecretStore key this binding's token is kept under. */
internal fun Profile_connections.secretKey(): String = profileConnectionTokenKey(profile_id, connection_id, secret_version)

/** Gives every profile with bindings but no default one its lowest connection id as default. */
internal fun Tx.repairMissingDefaults() {
    q.profileQueries.selectProfilesMissingDefault().executeAsList().forEach { promoteDefaultIfMissing(it) }
}

private fun Tx.promoteDefaultIfMissing(profileId: String) {
    val rows = q.profileQueries.selectBindingsForProfile(profileId).executeAsList()
    if (rows.isEmpty() || rows.any { it.is_default }) return
    q.profileQueries.setDefaultFlag(profileId, rows.minOf { it.connection_id })
}
