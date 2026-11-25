package com.edde746.plezy.data.recovery

import app.cash.sqldelight.db.SqlDriver
import com.edde746.plezy.data.LocalData
import com.edde746.plezy.data.TestClock
import com.edde746.plezy.data.db.Connections
import com.edde746.plezy.data.db.Profile_connections
import com.edde746.plezy.data.db.Profiles
import com.edde746.plezy.data.inMemoryDatabase
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.servers.OfflineWatchActionType
import kotlinx.coroutines.Dispatchers

/** [RecoveryStore] in memory; [failing] keys throw on write or removal, as a full or broken store would. */
internal class MemoryRecoveryStore(initial: Map<String, Any> = emptyMap()) : RecoveryStore {
    val values = LinkedHashMap(initial)
    var failing: (String) -> Boolean = { false }
    var writes = 0

    override fun contains(key: String) = key in values

    override fun string(key: String) = values[key] as? String

    override fun boolean(key: String) = values[key] as? Boolean

    override fun putString(key: String, value: String) = write(key) { values[key] = value }

    override fun putBoolean(key: String, value: Boolean) = write(key) { values[key] = value }

    override fun remove(key: String) = write(key) { values.remove(key) }

    private fun write(key: String, change: () -> Unit) {
        writes++
        if (failing(key)) throw IllegalStateException("injected store failure")
        change()
    }
}

/** A process stopping at a [RecoveryCrashPoint]: an [Error], which no recovery path catches. */
internal class SimulatedCrash : Error("simulated process stop")

/**
 * An Apple TV across launches: its user defaults ([store]) and its database, which [purge] deletes. Each [open] is a
 * launch: the database as the last one left it, or a new one after a purge.
 */
internal class Device(val store: MemoryRecoveryStore = MemoryRecoveryStore()) {
    var priorInstall = false
    val clock = TestClock()
    private var database: SqlDriver? = null

    fun open(ceiling: Int = RECOVERY_BYTE_CEILING, recovery: Boolean = true): LocalData {
        val kept = database
        val purgeable = if (recovery) PurgeableDatabase(store, { priorInstall }, ceiling) else null
        return LocalData(
            { schema -> KeptOpen(kept ?: inMemoryDatabase().createDriver(schema).also { database = it }) },
            { clock.now },
            Dispatchers.Default,
            {},
            purgeable,
        )
    }

    /** The system deletes the database. */
    fun purge() {
        database?.close()
        database = null
    }

    /** A crash hook stopping the process at [point] while [armed]. */
    fun crashAt(data: LocalData, point: RecoveryCrashPoint, armed: () -> Boolean) {
        data.recoveryImage!!.crashAt = { if (armed() && it == point) throw SimulatedCrash() }
    }
}

/** A driver a launch closes without closing the database under it, which the next launch opens again. */
private class KeptOpen(private val delegate: SqlDriver) : SqlDriver by delegate {
    override fun close() {}
}

/** Every row of the four critical tables, all columns. */
internal suspend fun LocalData.criticalRows(): Pair<IdentityRows, PendingRows> {
    val driver = driver
    return db.read { identityRows(driver) to pendingRows() }
}

internal fun Pair<IdentityRows, PendingRows>.isEmpty() =
    first.connections.isEmpty() && first.profiles.isEmpty() && first.profileConnections.isEmpty() && second.offlineWatchProgress.isEmpty()

internal suspend fun LocalData.profileIds(): Set<String> = criticalRows().first.profiles.map { it.id }.toSet()

internal suspend fun LocalData.addConnection(id: String, config: String = """{"baseUrl":"https://media.invalid/$id"}""") {
    db.write { q.connectionQueries.insertRow(Connections(id, "jellyfin", config, 1_000, null, null)) }
}

internal suspend fun LocalData.addProfile(id: String) {
    db.write { q.profileQueries.insertRow(Profiles(id, "local", "Profile $id", null, "{}", 0, 2_000, null)) }
}

/** Rows in every critical table, with every column type and nulls among them. */
internal suspend fun LocalData.seedCriticalRows() {
    db.write {
        q.connectionQueries.insertRow(Connections("server-1", "jellyfin", """{"baseUrl":"https://media.invalid"}""", 1_000, null, null))
        q.connectionQueries.insertRow(Connections("plex.account", "plex", "{}", 1_001, 2_002, null))
        q.profileQueries.insertRow(Profiles("local-1", "local", "Profile 1", null, """{"pinHash":"x"}""", 0, 2_000, null))
        q.profileQueries.insertRow(Profiles("plex-home-1", "plex_home", "Home \"quoted\" ✓", "https://thumb.invalid", "{}", 3, 2_001, 3_000))
        q.profileQueries.insertBinding(Profile_connections("local-1", "server-1", "user-1", true, 1_500, null, null))
        q.profileQueries.insertBinding(Profile_connections("local-1", "plex.account", "uuid", false, null, 1_600, null))
    }
    offlineWatch.upsertProgress("local-1", ServerId("server-1"), "server-1/user-1", "progress", 1_234, 9_999, false)
    offlineWatch.insertMark("local-1", ServerId("server-1"), "server-1/user-1", "watched", OfflineWatchActionType.WATCHED)
    val legacy = offlineWatch.insertMark(null, ServerId("server-1"), null, "legacy", OfflineWatchActionType.UNWATCHED)
    offlineWatch.recordFailedAttemptIfUnchanged(legacy.rowId, legacy.revision, "retry")
}
