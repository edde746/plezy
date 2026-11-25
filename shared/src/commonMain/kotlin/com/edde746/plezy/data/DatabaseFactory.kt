package com.edde746.plezy.data

import app.cash.sqldelight.db.QueryResult
import app.cash.sqldelight.db.SqlDriver
import app.cash.sqldelight.db.SqlSchema
import com.edde746.plezy.data.recovery.PurgeableDatabase
import com.edde746.plezy.log.Log
import kotlinx.io.IOException
import kotlinx.io.buffered
import kotlinx.io.files.Path
import kotlinx.io.files.SystemFileSystem
import kotlinx.io.readByteArray

/**
 * Where the app's SQLite database lives, and how to open it. Opening creates the database or migrates it to the
 * current schema version through the schema [LocalData] passes (`PlezyDatabase.Schema`, whose migrations are
 * `src/commonMain/sqldelight/migrations`).
 *
 * Each platform constructs it its own way: a file under the platform's app-data location, a caller-chosen location,
 * or a private in-memory database for tests. [LocalData] opens it.
 */
expect class DatabaseFactory {
    internal fun createDriver(schema: SqlSchema<QueryResult.Value<Unit>>): SqlDriver

    /**
     * Where the system may delete this database (Apple TV's purgeable storage), the store its recovery image goes to
     * ([com.edde746.plezy.data.recovery.RecoveryImage]); null everywhere else.
     */
    internal fun purgeable(): PurgeableDatabase?

    /**
     * Where the app keeps files of its own beside the database (the anime mappings dataset): the database's
     * directory's parent, Android's files directory; the system's temporary directory for an in-memory database.
     */
    internal fun filesDirectory(): String

    /** The database's file; null for an in-memory database. */
    internal fun file(): Path?

    /** A private in-memory database on this platform: a fresh schema to compare an opened database's with. */
    internal fun scratch(): DatabaseFactory

    /**
     * Whether the driver opens the database at its first statement rather than as it's created (Android's), so
     * [LocalData.open] opens it.
     */
    internal val opensOnFirstStatement: Boolean
}

/** File name of the database on every platform. */
internal const val DATABASE_FILE_NAME = "plezy.db"

/**
 * Deletes the write-ahead log's files (`-wal`, `-shm`) beside a [database] file that doesn't exist. Left without their
 * database (it was deleted, a restore brought the file back without them, or a crash during the first open), SQLite
 * would read them into a new one and fail the open, so every platform calls this before opening its database; a
 * database that exists keeps them (they hold its last commits). A file that can't be deleted is logged, and the open
 * goes on.
 */
internal fun removeOrphanedSidecars(database: Path) {
    if (SystemFileSystem.exists(database)) return
    for (suffix in listOf("-wal", "-shm")) {
        val sidecar = Path("$database$suffix")
        try {
            if (!SystemFileSystem.exists(sidecar)) continue
            SystemFileSystem.delete(sidecar)
            Log.w(TAG) { "Deleted ${sidecar.name}, left without its database" }
        } catch (e: IOException) {
            Log.w(TAG, e) { "Couldn't delete ${sidecar.name}, left without its database" }
        }
    }
}

/**
 * Thrown before opening a database whose schema version ([stored]) is newer than this build's ([supported]): a later
 * release wrote it, and this one can't read it. The file is left as it is, for that release.
 */
class DatabaseNewerThanAppException(val stored: Long, val supported: Long) :
    IllegalStateException("The database is schema version $stored, newer than this build's $supported: a later release wrote it")

/**
 * Readies the [database] file for an open at [schemaVersion], with no connection to it open. A database a later
 * release wrote is refused ([DatabaseNewerThanAppException]). One an earlier release wrote is copied aside first,
 * with its write-ahead log, as `<name>.v<version>.bak` (and `-wal`): the drivers migrate in one transaction, so a
 * failed migration leaves the database at its version, and the copy is there besides. A database at [schemaVersion]
 * (its migration done) has its copies deleted.
 */
internal fun prepareOpen(database: Path, schemaVersion: Long) {
    val stored = storedSchemaVersion(database) ?: return
    if (stored > schemaVersion) throw DatabaseNewerThanAppException(stored, schemaVersion)
    val dir = database.parent ?: return
    val prefix = "${database.name}.v"
    if (stored == schemaVersion) {
        for (old in SystemFileSystem.list(dir)) {
            if (!old.name.startsWith(prefix) || !(old.name.endsWith(".bak") || old.name.endsWith(".bak-wal"))) continue
            try {
                SystemFileSystem.delete(old)
            } catch (e: IOException) {
                Log.w(TAG, e) { "Couldn't delete ${old.name}" }
            }
        }
        return
    }
    if (stored == 0L) return
    val aside = Path(dir, "$prefix$stored.bak")
    copy(database, aside)
    val wal = Path("$database-wal")
    val asideWal = Path("$aside-wal")
    if (SystemFileSystem.exists(wal)) copy(wal, asideWal) else SystemFileSystem.delete(asideWal, mustExist = false)
    Log.i(TAG) { "Copied the version $stored database to ${aside.name} before migrating it to $schemaVersion" }
}

/**
 * The schema version stored in the SQLite [database] file's header (`user_version`, bytes 60–63, big-endian); null when
 * there's no file, or it's no SQLite database (shorter than a header, or without its `SQLite format 3` mark): opening
 * it then fails as SQLite reports it. A database in WAL mode whose last change is still in its log stores the earlier
 * header there; the drivers read the log, and refuse a newer version themselves.
 */
internal fun storedSchemaVersion(database: Path): Long? {
    if (!SystemFileSystem.exists(database)) return null
    val header = SystemFileSystem.source(database).buffered().use { source ->
        if (!source.request(SQLITE_HEADER_SIZE)) return null
        source.readByteArray(SQLITE_HEADER_SIZE.toInt())
    }
    if (!header.copyOf(SQLITE_MAGIC.size).contentEquals(SQLITE_MAGIC)) return null
    return (60..63).fold(0L) { value, i -> (value shl 8) or (header[i].toLong() and 0xFF) }
}

private fun copy(from: Path, to: Path) {
    SystemFileSystem.source(from).use { source -> SystemFileSystem.sink(to).buffered().use { it.transferFrom(source) } }
}

private const val SQLITE_HEADER_SIZE = 100L

/** The first 16 bytes of every SQLite database file. */
private val SQLITE_MAGIC = "SQLite format 3\u0000".encodeToByteArray()

/**
 * How long a statement waits for another connection's lock before SQLITE_BUSY, on the drivers that let the app set
 * it (desktop's sqlite-jdbc, 3 s by default; Apple's SQLiter, 5 s). A commit takes longer than those while the disk is
 * saturated (12 s on a Windows PC with a 61 GB file written beside it). Android's framework fixes its own
 * 2.5 s per connection, and its connection pool queues the app's writers, so they don't meet each other's locks.
 */
internal const val BUSY_TIMEOUT_MILLIS = 60_000

private const val TAG = "DatabaseFactory"
