package com.edde746.plezy.data.recovery

import app.cash.sqldelight.db.QueryResult
import app.cash.sqldelight.db.SqlDriver
import com.edde746.plezy.crypto.cryptoProvider
import com.edde746.plezy.data.db.Device_setting
import com.edde746.plezy.data.db.PlezyDatabase
import com.edde746.plezy.data.settings.settingsJson
import com.edde746.plezy.importer.EarlierReleaseImport
import com.edde746.plezy.importer.EarlierReleaseImportMarker
import com.edde746.plezy.importer.EarlierReleaseOutcome
import com.edde746.plezy.log.Log
import dev.whyoleg.cryptography.algorithms.SHA256
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlin.concurrent.Volatile

/** The recovery image's keys in the [RecoveryStore]. */
internal object RecoveryKeys {
    /**
     * `{"version":3,"state":"invalidated"|"committed","identityDigest":…,"settingsDigest":…,"pendingDigest":…}`,
     * written last.
     */
    const val MANIFEST = "plezy_db_recovery_manifest_v1"

    /** The identity group ([IdentityRows]). */
    const val IDENTITY = "plezy_db_recovery_identity_v1"

    /** The settings group ([SettingsRows]). */
    const val SETTINGS = "plezy_db_recovery_settings_v1"

    /** The pending group ([PendingRows]). */
    const val PENDING = "plezy_db_recovery_pending_v1"

    /** `true` while recovery is required and not yet acknowledged. */
    const val REQUIRED = "plezy_db_recovery_required_v1"

    /** The image's keys, which its byte ceiling counts. */
    val ALL = listOf(MANIFEST, IDENTITY, SETTINGS, PENDING, REQUIRED)

    /**
     * `true` once the database first held accounts or profiles on this install: evidence of use that outlives the
     * database and the image. Not part of the image.
     */
    const val INSTALL = "plezy_db_recovery_install_v1"
}

/** Where a test stops the process during the commit protocol ([RecoveryImage.crashAt]). */
internal enum class RecoveryCrashPoint { AFTER_INVALIDATION, AFTER_DATABASE_MUTATION, AFTER_PAYLOAD_WRITE, AFTER_FINAL_MANIFEST }

/**
 * Keeps a bounded copy of the rows the system's deletion of the database would lose for good, accounts, profiles and
 * their bindings (identity), the settings of the device, the profiles and the servers with the profiles' bookkeeping
 * among them (settings: the earlier releases kept all of these in the user defaults, which the system never deletes)
 * and unsent watch actions (pending), in [PurgeableDatabase.store], and restores them at the next open when the
 * database is gone ([reconcile]). Over the image's budget the pending group goes first, then the settings but the
 * bookkeeping ([SettingsRows.bookkeeping]); identity and the bookkeeping never go ([commit]).
 *
 * Every write of the database ([durable], around [com.edde746.plezy.data.Db.write]'s transaction) that changes one of
 * those tables ([beforeStatement] sees each statement first, [RecoveryDriver]) follows a two-phase protocol:
 * 1. before its first statement changing one runs, the manifest is rewritten `invalidated` (keeping the old digests);
 *    a write that can't do so while a committed image exists is refused and rolls back; a write changing settings
 *    alone while there is no committed image to keep (recovery is required) runs as it is, as settings aren't gated;
 * 2. the transaction commits;
 * 3. the changed groups are read again and their payloads written;
 * 4. the manifest is written `committed` with their digests: always the last write.
 * Writes run one at a time (the database's write lock), so the image always follows the database's order. The process
 * stopping anywhere leaves either the previous committed image (before 2) or an invalidated one, which restores
 * nothing: a missing database is then reported, never replaced by stale rows. A failure after the commit leaves the
 * image invalidated and turns recovery off for the rest of the process; the database stays authoritative, and the
 * next start publishes a fresh image from it.
 *
 * Detecting writes at the statement inside the transaction, rather than by the tables SQLDelight notifies after the
 * commit, is what makes step 1 precede the commit; it needs no repository to declare the tables it writes.
 */
internal class RecoveryImage(
    private val purgeable: PurgeableDatabase,
    private val driver: SqlDriver,
    private val wallClock: () -> Long,
) {
    private val store = purgeable.store
    private val ceiling = purgeable.byteCeiling

    // The database without the statement hook: reconciling and reading rows back don't count as writes.
    private val database = PlezyDatabase(driver)

    private var tables = CriticalTables(CriticalTables.OWN)

    // Set once the start's reconcile is done; before it, statements are the schema's and the restore's.
    @Volatile private var armed = false

    @Volatile private var disabled = false

    // The database write running now (Db.write holds the write lock while it is set).
    @Volatile private var current: Write? = null

    // How many parts the last commit left out to stay within the budget (commit).
    private var dropped = 0

    /** Test hook: called at each [RecoveryCrashPoint]; throwing an [Error] there stops the protocol as a crash would. */
    internal var crashAt: ((RecoveryCrashPoint) -> Unit)? = null

    private class Write {
        var previous: Manifest? = null
        var groups: Set<RecoveryGroup> = emptySet()

        // Settings changed while there was no committed image: nothing to publish for them.
        var ungated = false
    }

    /**
     * Brings the database and the image in line as the database opens, before anything else reads it. [databaseExisted]
     * is asked once the database is open (opening creates a missing one).
     *
     * - A recovery-required marker restores a valid committed image, else recovery stays required.
     * - An existing database is authoritative: a fresh image is published from it.
     * - A missing database with no image starts fresh, or requires recovery if the app was used here: the image's
     *   [RecoveryKeys.INSTALL] mark or [PurgeableDatabase.priorInstall] says so.
     * - A missing database with an image restores it if it is valid and committed, else requires recovery.
     *
     * A restore replaces the image's tables' rows exactly as captured (the earlier releases' import marker with them,
     * so an import that never ran still runs), publishes the image again and only then clears the marker. Throws when
     * the existing database can't be read, or the marker can't be written.
     */
    fun reconcile(databaseExisted: () -> Boolean): DatabaseRecovery {
        // Opens a driver that opens on its first statement (Android's), creating a missing database.
        driver.executeQuery(null, "SELECT 1", { QueryResult.Value(Unit) }, 0)
        val existed = databaseExisted()
        tables = CriticalTables.of(driver)
        val outcome = classify(existed)
        armed = true
        Log.i(TAG) { "purgeable database opened: $outcome" }
        return outcome
    }

    private fun classify(databaseExisted: Boolean): DatabaseRecovery {
        if (recoveryRequiredMarker()) {
            val snapshot = committedSnapshot() ?: return stillRequired()
            return try {
                restore(snapshot)
            } catch (e: Exception) {
                Log.w(TAG, e) { "restoring the recovery image failed" }
                stillRequired()
            }
        }
        if (databaseExisted) {
            // Read outside the publishing failure boundary: a database that can't be read is the open's failure.
            val rows = currentRows()
            try {
                publish(rows)
            } catch (e: InvalidationFailed) {
                // The old committed image may still restore: later writes retry the invalidation, or are refused.
                Log.w(TAG, e) { "the recovery image couldn't be invalidated at the start" }
            } catch (e: Exception) {
                disable(e)
            }
            return DatabaseRecovery.ADOPTED_EXISTING
        }
        if (RecoveryKeys.ALL.none { store.contains(it) }) {
            if (store.boolean(RecoveryKeys.INSTALL) == true || purgeable.priorInstall()) return markRequired()
            return try {
                publish(currentRows())
                DatabaseRecovery.FRESH
            } catch (e: BudgetExceeded) {
                disable(e)
                DatabaseRecovery.FRESH
            } catch (e: Exception) {
                Log.w(TAG, e) { "the first recovery image couldn't be written" }
                markRequired()
            }
        }
        val snapshot = committedSnapshot() ?: return markRequired()
        return try {
            restore(snapshot)
        } catch (e: Exception) {
            Log.w(TAG, e) { "restoring the recovery image failed" }
            markRequired()
        }
    }

    /**
     * Runs [transaction] (a database write) under the protocol: whatever it changed of the image's tables is published
     * after it commits. [transaction] runs as it is while recovery is off.
     */
    fun <R> durable(transaction: () -> R): R {
        if (!armed || disabled) return transaction()
        val write = Write()
        current = write
        try {
            val result = try {
                transaction()
            } catch (e: Exception) {
                // Rolled back, as far as the transaction knows: the database is authoritative either way, so the image
                // is published again from it.
                write.previous?.let { previous -> afterCommit(previous, write.groups, crash = false) }
                throw e
            }
            write.previous?.let { previous -> afterCommit(previous, write.groups, crash = true) }
            return result
        } finally {
            current = null
        }
    }

    /**
     * Called before every statement that may change the database runs: the first one in a write changing a table of
     * the image invalidates the image, and a write that can't do so is refused ([DatabaseDurabilityException]).
     */
    fun beforeStatement(sql: String) {
        if (!armed || disabled) return
        val groups = tables.groupsOf(sql)
        if (groups.isEmpty()) return
        val write = current
        if (write == null) {
            // A statement outside a database write has no commit to publish after: the image can't follow it.
            invalidateForMutation()
            disable(IllegalStateException("a critical table was changed outside a database write"))
            return
        }
        if (write.previous == null) {
            val settingsOnly = RecoveryGroup.IDENTITY !in groups && RecoveryGroup.PENDING !in groups
            if (settingsOnly && (write.ungated || committedManifest() == null)) {
                write.ungated = true
                return
            }
            write.previous = invalidateForMutation()
            crash(RecoveryCrashPoint.AFTER_INVALIDATION)
        }
        write.groups += groups
    }

    /**
     * The user started a new sign-in after [DatabaseRecovery.RECOVERY_REQUIRED]: the database as it is now becomes the
     * image, the marker is cleared and recovery is on again. Throws [DatabaseDurabilityException] when the image
     * can't be written. Runs under the database's write lock.
     */
    fun acknowledgeRecoveryRequired() {
        if (!armed) return
        try {
            publish(currentRows())
            clearRecoveryRequired()
            disabled = false
        } catch (e: BudgetExceeded) {
            disable(e)
            throw DatabaseDurabilityException()
        } catch (e: DatabaseDurabilityException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "the recovery image couldn't be replaced on acknowledgement" }
            throw DatabaseDurabilityException()
        }
    }

    // Reconcile.

    /** The marker, read tolerantly: a value of another type tells nothing, so it counts as absent and goes. */
    private fun recoveryRequiredMarker(): Boolean {
        if (!store.contains(RecoveryKeys.REQUIRED)) return false
        store.boolean(RecoveryKeys.REQUIRED)?.let { return it }
        try {
            store.remove(RecoveryKeys.REQUIRED)
        } catch (e: Exception) {
            Log.w(TAG, e) { "an unreadable recovery marker couldn't be removed" }
        }
        return false
    }

    private fun restore(snapshot: Snapshot): DatabaseRecovery {
        database.transaction { database.replaceCriticalRows(snapshot.identity, snapshot.settings, snapshot.pending) }
        publish(currentRows())
        clearRecoveryRequired()
        return DatabaseRecovery.RESTORED
    }

    private fun markRequired(): DatabaseRecovery {
        try {
            store.putBoolean(RecoveryKeys.REQUIRED, true)
        } catch (e: Exception) {
            throw DatabaseDurabilityException()
        }
        return stillRequired()
    }

    private fun stillRequired(): DatabaseRecovery {
        database.transaction { markImportHandled(EarlierReleaseOutcome.RECOVERY_REQUIRED) }
        return DatabaseRecovery.RECOVERY_REQUIRED
    }

    /**
     * Records the earlier releases' import as done, unless it is: the app ran here before the database went, so what
     * those releases left was dealt with then, and importing it again would bring back rows older than the image's.
     */
    private fun markImportHandled(outcome: EarlierReleaseOutcome) {
        val key = EarlierReleaseImport.MARKER.key
        if (database.deviceSettingQueries.selectByKey(key).executeAsOneOrNull() != null) return
        val marker = settingsJson.encodeToString(EarlierReleaseImport.MARKER.serializer, EarlierReleaseImportMarker(wallClock(), outcome))
        database.deviceSettingQueries.upsert(Device_setting(key, marker))
    }

    private fun clearRecoveryRequired() {
        // Always issued: the marker may be there whatever was read of it.
        try {
            store.remove(RecoveryKeys.REQUIRED)
        } catch (e: Exception) {
            throw DatabaseDurabilityException()
        }
    }

    // The protocol.

    /** Invalidates the committed image before a write changes its rows; throws [DatabaseDurabilityException] if it can't. */
    private fun invalidateForMutation(): Manifest {
        val previous = committedManifest() ?: throw DatabaseDurabilityException()
        try {
            invalidate(previous)
        } catch (e: Exception) {
            throw DatabaseDurabilityException()
        }
        return previous
    }

    private fun afterCommit(previous: Manifest, groups: Set<RecoveryGroup>, crash: Boolean) {
        if (crash) crash(RecoveryCrashPoint.AFTER_DATABASE_MUTATION)
        try {
            val payloads = LinkedHashMap<String, String>()
            var manifest = previous.copy(state = COMMITTED)
            if (RecoveryGroup.IDENTITY in groups) {
                val rows = database.identityRows(driver)
                markInstallUsed(rows)
                val identity = encodeIdentity(rows)
                payloads[RecoveryKeys.IDENTITY] = identity
                manifest = manifest.copy(identityDigest = digest(identity))
            }
            if (RecoveryGroup.SETTINGS in groups) {
                val settings = encodeSettings(database.settingsRows())
                payloads[RecoveryKeys.SETTINGS] = settings
                manifest = manifest.copy(settingsDigest = digest(settings))
            }
            if (RecoveryGroup.PENDING in groups) {
                val pending = encodePending(database.pendingRows())
                payloads[RecoveryKeys.PENDING] = pending
                manifest = manifest.copy(pendingDigest = digest(pending))
            }
            commit(payloads, manifest)
        } catch (e: Exception) {
            disable(e)
        }
    }

    /** Publishes [rows] as the whole image. */
    private fun publish(rows: Snapshot) {
        val previous = manifestOrNull()
        try {
            invalidate(previous)
        } catch (e: Exception) {
            if (previous?.state == COMMITTED) throw InvalidationFailed(e)
            throw e
        }
        markInstallUsed(rows.identity)
        val identity = encodeIdentity(rows.identity)
        val settings = encodeSettings(rows.settings)
        val pending = encodePending(rows.pending)
        commit(
            mapOf(RecoveryKeys.IDENTITY to identity, RecoveryKeys.SETTINGS to settings, RecoveryKeys.PENDING to pending),
            Manifest(RECOVERY_FORMAT_VERSION, COMMITTED, digest(identity), digest(settings), digest(pending)),
        )
    }

    private fun currentRows() = Snapshot(database.identityRows(driver), database.settingsRows(), database.pendingRows())

    private fun invalidate(previous: Manifest?) {
        val invalidated = Manifest(
            RECOVERY_FORMAT_VERSION, INVALIDATED, previous?.identityDigest.orEmpty(), previous?.settingsDigest.orEmpty(),
            previous?.pendingDigest.orEmpty(),
        )
        store.putString(RecoveryKeys.MANIFEST, encodeManifest(invalidated))
    }

    /** Sets [RecoveryKeys.INSTALL] the first time [identity] holds an account, a profile or a binding. */
    private fun markInstallUsed(identity: IdentityRows) {
        if (identity.connections.isEmpty() && identity.profiles.isEmpty() && identity.profileConnections.isEmpty()) return
        if (store.boolean(RecoveryKeys.INSTALL) != true) store.putBoolean(RecoveryKeys.INSTALL, true)
    }

    /**
     * Writes [payloads], then [manifest]. Over the byte ceiling, parts are left out until the image fits: first the
     * pending group's unsent watch actions, then every setting but the profiles' bookkeeping. Accounts, profiles and
     * that bookkeeping are never left out: still over the ceiling, [BudgetExceeded] and nothing is written.
     */
    private fun commit(payloads: Map<String, String>, manifest: Manifest) {
        val written = payloads.toMutableMap()
        var final = manifest
        var left = 0
        while (!fits(written + (RecoveryKeys.MANIFEST to encodeManifest(final)))) {
            when (left++) {
                0 -> {
                    val empty = encodePending(PendingRows(emptyList()))
                    written[RecoveryKeys.PENDING] = empty
                    final = final.copy(pendingDigest = digest(empty))
                }
                1 -> {
                    val bookkeeping = encodeSettings(database.settingsRows().bookkeeping())
                    written[RecoveryKeys.SETTINGS] = bookkeeping
                    final = final.copy(settingsDigest = digest(bookkeeping))
                }
                else -> throw BudgetExceeded()
            }
        }
        if (left > dropped) {
            Log.w(TAG) {
                if (left == 1) {
                    "the recovery image leaves unsent watch actions out to stay within its size"
                } else {
                    "the recovery image leaves unsent watch actions and the settings but the profiles' bookkeeping out to stay within its size"
                }
            }
        }
        dropped = left
        for ((key, value) in written) store.putString(key, value)
        crash(RecoveryCrashPoint.AFTER_PAYLOAD_WRITE)
        store.putString(RecoveryKeys.MANIFEST, encodeManifest(final))
        crash(RecoveryCrashPoint.AFTER_FINAL_MANIFEST)
    }

    private fun disable(cause: Exception) {
        if (disabled) return
        disabled = true
        Log.w(TAG, cause) { "recovery of the database is off for this process; the database stays authoritative" }
    }

    private fun crash(point: RecoveryCrashPoint) {
        crashAt?.invoke(point)
    }

    // Reading the image.

    private class Snapshot(val identity: IdentityRows, val settings: SettingsRows, val pending: PendingRows)

    /** The image's rows if it is complete and committed: manifest, digests, size and every group valid. */
    private fun committedSnapshot(): Snapshot? = try {
        val manifest = committedManifest()
        if (manifest == null || imageSize(emptyMap(), assumeRequired = false) > ceiling) {
            null
        } else {
            Snapshot(
                decodeIdentity(store.string(RecoveryKeys.IDENTITY)!!),
                decodeSettings(store.string(RecoveryKeys.SETTINGS)!!),
                decodePending(store.string(RecoveryKeys.PENDING)!!),
            )
        }
    } catch (e: Exception) {
        Log.w(TAG, e) { "the recovery image is unreadable" }
        null
    }

    /** The manifest of the committed image whose payloads match it, or null (none, invalidated, or damaged). */
    private fun committedManifest(): Manifest? = try {
        val manifest = manifestOrNull()
        val identity = store.string(RecoveryKeys.IDENTITY)
        val settings = store.string(RecoveryKeys.SETTINGS)
        val pending = store.string(RecoveryKeys.PENDING)
        manifest?.takeIf {
            it.state == COMMITTED && identity != null && settings != null && pending != null &&
                digest(identity) == it.identityDigest && digest(settings) == it.settingsDigest && digest(pending) == it.pendingDigest
        }
    } catch (e: Exception) {
        null
    }

    private fun manifestOrNull(): Manifest? = try {
        store.string(RecoveryKeys.MANIFEST)?.let(::decodeManifest)
    } catch (e: Exception) {
        null
    }

    /** Whether the image, with [replacements] and the marker set, stays within the ceiling. */
    private fun fits(replacements: Map<String, String>): Boolean = imageSize(replacements, assumeRequired = true) <= ceiling

    /** UTF-8 size of the JSON object of the recovery keys, sorted, with [replacements] in place. */
    private fun imageSize(replacements: Map<String, String>, assumeRequired: Boolean): Int {
        val image = LinkedHashMap<String, JsonElement>()
        for (key in RecoveryKeys.ALL.sorted()) {
            val value = replacements[key]?.let(::JsonPrimitive)
                ?: if (assumeRequired && key == RecoveryKeys.REQUIRED) JsonPrimitive(true) else stored(key)
            if (value != null) image[key] = value
        }
        return JsonObject(image).toString().encodeToByteArray().size
    }

    private fun stored(key: String): JsonPrimitive? =
        store.string(key)?.let(::JsonPrimitive) ?: store.boolean(key)?.let(::JsonPrimitive)

    private class BudgetExceeded : Exception("The recovery image is over its size")

    private class InvalidationFailed(cause: Exception) : Exception("The recovery image couldn't be invalidated", cause)

    private companion object {
        const val TAG = "recovery"
        const val INVALIDATED = "invalidated"
        const val COMMITTED = "committed"
    }
}

@Serializable
internal data class Manifest(
    val version: Int,
    val state: String,
    val identityDigest: String,
    val settingsDigest: String,
    val pendingDigest: String,
)

internal fun encodeManifest(manifest: Manifest): String = Json.encodeToString(Manifest.serializer(), manifest)

/** The manifest in [raw]; throws unless it is valid: this version, a known state, every digest when committed. */
internal fun decodeManifest(raw: String): Manifest {
    val manifest = Json.decodeFromString(Manifest.serializer(), raw)
    require(manifest.version == RECOVERY_FORMAT_VERSION) { "Unsupported recovery image version" }
    require(manifest.state == "invalidated" || manifest.state == "committed") { "Unknown recovery image state" }
    val digests = listOf(manifest.identityDigest, manifest.settingsDigest, manifest.pendingDigest)
    require(manifest.state != "committed" || digests.all { it.isNotEmpty() }) {
        "A committed recovery image without digests"
    }
    return manifest
}

/** Lowercase hex SHA-256 of [value]'s UTF-8 bytes. */
internal fun digest(value: String): String = cryptoProvider.get(SHA256).hasher().hashBlocking(value.encodeToByteArray()).toHexString()
