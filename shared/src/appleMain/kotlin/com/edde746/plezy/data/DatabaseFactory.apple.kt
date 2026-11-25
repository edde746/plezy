package com.edde746.plezy.data

import app.cash.sqldelight.db.QueryResult
import app.cash.sqldelight.db.SqlDriver
import app.cash.sqldelight.db.SqlSchema
import app.cash.sqldelight.driver.native.NativeSqliteDriver
import com.edde746.plezy.data.recovery.PurgeableDatabase
import com.edde746.plezy.data.recovery.UserDefaultsRecoveryStore
import com.edde746.plezy.data.recovery.keychainHoldsSecrets
import kotlinx.cinterop.ExperimentalForeignApi
import kotlinx.io.files.Path
import platform.Foundation.NSApplicationSupportDirectory
import platform.Foundation.NSBundle
import platform.Foundation.NSCachesDirectory
import platform.Foundation.NSFileManager
import platform.Foundation.NSSearchPathDirectory
import platform.Foundation.NSSearchPathForDirectoriesInDomains
import platform.Foundation.NSTemporaryDirectory
import platform.Foundation.NSUserDomainMask
import kotlin.experimental.ExperimentalNativeApi

/**
 * The database on iOS, iPadOS, macOS and tvOS, through the system SQLite (`-lsqlite3`).
 *
 * The default location is `Application Support/databases` in the app's container on iPhone and iPad. The Mac app
 * isn't sandboxed, so its Application Support is every app's: the database goes to the app's own folder there,
 * `~/Library/Application Support/<bundle id>/databases`, beside its downloads. An Apple TV app keeps only purgeable
 * data locally (beyond 500 KB of user defaults), so on tvOS the database goes to `Caches/databases`; if the system
 * purges it, the next open restores accounts, profiles and unsent watch actions from a recovery image in the user
 * defaults ([purgeable], [com.edde746.plezy.data.recovery.RecoveryImage]); downloads and cached metadata are fetched
 * again. iPhone, iPad and Mac backups include the database; an Apple TV's Caches are in none.
 */
actual class DatabaseFactory private constructor(private val directory: String?, private val inMemory: Boolean) {
    /** The app's database at the platform's default location. */
    constructor() : this(null, inMemory = false)

    /** The database in [directory], created if missing. */
    constructor(directory: String) : this(directory, inMemory = false)

    internal actual fun createDriver(schema: SqlSchema<QueryResult.Value<Unit>>): SqlDriver {
        // Every connection enforces the schema's foreign keys.
        if (inMemory) {
            return NativeSqliteDriver(
                schema = schema,
                name = "memory",
                onConfiguration = { it.copy(name = null, inMemory = true, extendedConfig = it.extendedConfig.copy(foreignKeyConstraints = true)) },
            )
        }
        val dir = directory ?: defaultDirectory()
        createDirectory(dir)
        val file = Path(dir, DATABASE_FILE_NAME)
        removeOrphanedSidecars(file)
        prepareOpen(file, schema.version)
        return NativeSqliteDriver(
            schema = schema,
            name = DATABASE_FILE_NAME,
            // Query flows read concurrently with the one writer.
            maxReaderConnections = 4,
            onConfiguration = {
                it.copy(extendedConfig = it.extendedConfig.copy(basePath = dir, busyTimeout = BUSY_TIMEOUT_MILLIS, foreignKeyConstraints = true))
            },
        )
    }

    /** The app's own database on tvOS ([defaultDirectory] is Caches there): its image goes to the standard user defaults. */
    @OptIn(ExperimentalNativeApi::class)
    internal actual fun purgeable(): PurgeableDatabase? =
        if (!inMemory && directory == null && Platform.osFamily == OsFamily.TVOS) {
            PurgeableDatabase(UserDefaultsRecoveryStore(), priorInstall = ::keychainHoldsSecrets)
        } else {
            null
        }

    internal actual fun filesDirectory(): String =
        if (inMemory) "${NSTemporaryDirectory().trimEnd('/')}/plezy" else directory ?: defaultDirectory().substringBeforeLast('/')

    internal actual fun file(): Path? = if (inMemory) null else Path(directory ?: defaultDirectory(), DATABASE_FILE_NAME)

    internal actual fun scratch(): DatabaseFactory = inMemory()

    internal actual val opensOnFirstStatement: Boolean get() = false

    companion object {
        /** A private in-memory database, gone when [LocalData.close] closes it. */
        fun inMemory(): DatabaseFactory = DatabaseFactory(null, inMemory = true)

        @OptIn(ExperimentalNativeApi::class)
        private fun defaultDirectory(): String {
            val base: NSSearchPathDirectory =
                if (Platform.osFamily == OsFamily.TVOS) NSCachesDirectory else NSApplicationSupportDirectory
            val root = NSSearchPathForDirectoriesInDomains(base, NSUserDomainMask, true).first() as String
            if (Platform.osFamily != OsFamily.MACOSX) return "$root/databases"
            val app = checkNotNull(NSBundle.mainBundle.bundleIdentifier) { "The app has no bundle identifier" }
            return "$root/$app/databases"
        }

        @OptIn(ExperimentalForeignApi::class)
        private fun createDirectory(path: String) {
            val manager = NSFileManager.defaultManager
            if (!manager.fileExistsAtPath(path)) {
                check(manager.createDirectoryAtPath(path, withIntermediateDirectories = true, attributes = null, error = null)) {
                    "Couldn't create the database directory"
                }
            }
        }
    }
}
