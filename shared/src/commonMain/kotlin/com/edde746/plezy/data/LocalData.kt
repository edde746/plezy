package com.edde746.plezy.data

import app.cash.sqldelight.db.AfterVersion
import app.cash.sqldelight.db.QueryResult
import app.cash.sqldelight.db.SqlDriver
import app.cash.sqldelight.db.SqlSchema
import com.edde746.plezy.data.cache.ApiCacheRepository
import com.edde746.plezy.data.db.PlezyDatabase
import com.edde746.plezy.data.downloads.DownloadCollectionRepository
import com.edde746.plezy.data.downloads.DownloadLibraryRepository
import com.edde746.plezy.data.downloads.DownloadTaskRepository
import com.edde746.plezy.data.downloads.SyncRuleRepository
import com.edde746.plezy.data.livetv.LiveTvFavoriteRepository
import com.edde746.plezy.data.music.MusicSessionRepository
import com.edde746.plezy.data.recovery.DatabaseRecovery
import com.edde746.plezy.data.recovery.PurgeableDatabase
import com.edde746.plezy.data.recovery.RecoveryDriver
import com.edde746.plezy.data.recovery.RecoveryImage
import com.edde746.plezy.data.settings.DeviceSettingsRepository
import com.edde746.plezy.data.tracker.TrackerAccountRepository
import com.edde746.plezy.data.tracker.TrackerWriteQueue
import com.edde746.plezy.data.watch.OfflineWatchRepository
import com.edde746.plezy.profiles.ProfileRegistry
import com.edde746.plezy.settings.export.SettingsBackup
import com.edde746.plezy.settings.LibraryPrefs
import com.edde746.plezy.settings.ProfileSettingsRepository
import com.edde746.plezy.settings.ServerSettingsRepository
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlin.concurrent.Volatile
import kotlin.coroutines.CoroutineContext
import kotlin.time.Clock

/**
 * The app's local data: one SQLite database and its repositories. Create one per process in the
 * composition root and [close] it on shutdown.
 *
 * Opening the database (creating or migrating it) happens here, on the calling thread, on desktop and Apple platforms;
 * do it off the main thread. Android's driver opens it at its first statement, on the I/O context ([open]). A database
 * that can't be used throws a [DatabaseUnreadableException] (damaged, its migration failed, or its schema isn't this
 * version's) or a [DatabaseNewerThanAppException]: the start offers to reset the app's data ([DataFault]).
 *
 * @param onMigrate called as an older database starts its migration to this version's schema (the start's progress,
 *   [com.edde746.plezy.app.StartupStep.MIGRATION]).
 * @param referenceSchema a fresh database's [schemaShape], which [open] compares the opened database's with; null
 *   compares nothing (a test's database).
 */
class LocalData internal constructor(
    createDriver: (SqlSchema<QueryResult.Value<Unit>>) -> SqlDriver,
    wallClock: () -> Long,
    io: CoroutineContext,
    onMigrate: () -> Unit,
    purgeable: PurgeableDatabase?,
    private val referenceSchema: (() -> Map<String, String>)? = null,
) : AutoCloseable {
    constructor(factory: DatabaseFactory, onMigrate: () -> Unit = {}) : this(
        factory,
        { Clock.System.now().toEpochMilliseconds() },
        Dispatchers.IO,
        onMigrate,
    )

    internal constructor(factory: DatabaseFactory, wallClock: () -> Long, io: CoroutineContext, onMigrate: () -> Unit = {}) :
        this(factory::createDriver, wallClock, io, onMigrate, factory.purgeable(), { freshSchema(factory) })

    private val schema = ReportingSchema(PlezyDatabase.Schema, onMigrate)
    private val openedDriver = try {
        createDriver(schema)
    } catch (e: Throwable) {
        throw unreadableOrItself(e)
    }

    /** The recovery image of a database the system may delete; null elsewhere. */
    internal val recoveryImage: RecoveryImage? = purgeable?.let { RecoveryImage(it, openedDriver, wallClock) }
    internal val driver: SqlDriver = recoveryImage?.let { RecoveryDriver(openedDriver, it) } ?: openedDriver
    internal val db = Db(PlezyDatabase(driver), io, wallClock, recoveryImage)

    // Whether the opened database's schema was compared with [referenceSchema] and found the same.
    @Volatile private var schemaChecked = false

    /**
     * What opening found of a database the system may delete, and did about it ([DatabaseRecovery]); settled before
     * anything reads the database. [DatabaseRecovery.NOT_APPLICABLE] wherever the database stays.
     */
    val recovery: DatabaseRecovery = try {
        recoveryImage?.let { image ->
            // Its rows are read next: the schema is checked first.
            checkSchema()
            image.reconcile { !schema.created }
        } ?: DatabaseRecovery.NOT_APPLICABLE
    } catch (e: Throwable) {
        openedDriver.close()
        throw unreadableOrItself(e)
    }

    val deviceSettings: DeviceSettingsRepository = DeviceSettingsRepository(db)
    val profileSettings: ProfileSettingsRepository = ProfileSettingsRepository(db)
    val serverSettings: ServerSettingsRepository = ServerSettingsRepository(db)
    val libraryPrefs: LibraryPrefs = LibraryPrefs(db)
    val trackerAccounts: TrackerAccountRepository = TrackerAccountRepository(db)
    val trackerWriteQueue: TrackerWriteQueue = TrackerWriteQueue(db)
    val settingsBackup: SettingsBackup = SettingsBackup(db)
    internal val downloadTasks: DownloadTaskRepository = DownloadTaskRepository(db)
    internal val downloadLibrary: DownloadLibraryRepository = DownloadLibraryRepository(db)
    val profiles: ProfileRegistry = ProfileRegistry(db)
    val apiCache: ApiCacheRepository = ApiCacheRepository(db)
    val offlineWatch: OfflineWatchRepository = OfflineWatchRepository(db)
    val syncRules: SyncRuleRepository = SyncRuleRepository(db)
    val downloadCollections: DownloadCollectionRepository = DownloadCollectionRepository(db)
    val musicSessions: MusicSessionRepository = MusicSessionRepository(db)
    val liveTvFavorites: LiveTvFavoriteRepository = LiveTvFavoriteRepository(db)

    /**
     * Returns once the database is open and its schema is this version's: at once where it opened with this object,
     * after Android's driver opened it (creating or migrating it) otherwise. A database that can't open throws here, a
     * [DatabaseUnreadableException] or [DatabaseNewerThanAppException] when it can't be used ([DataFault]).
     */
    suspend fun open() {
        try {
            db.useDriver {
                driver.executeQuery(null, "SELECT 1", { QueryResult.Value(Unit) }, 0)
                checkSchema()
            }
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            throw unreadableOrItself(e)
        }
    }

    /**
     * Throws a [DatabaseUnreadableException] when the database's schema differs from a fresh one's: one an unreleased
     * build of the same schema version changed in place. A database this open created is fresh; one checked once is
     * not checked again.
     */
    private fun checkSchema() {
        if (schemaChecked) return
        val reference = referenceSchema
        if (reference != null && !schema.created) requireSchema(schemaShape(openedDriver), reference())
        schemaChecked = true
    }

    /**
     * The user started a new sign-in after [DatabaseRecovery.RECOVERY_REQUIRED]: what the database holds now becomes
     * the recovery image, and accounts, profiles and watch actions can be changed again. Call it before the sign-in
     * writes them. Nothing happens where the database has no recovery image. Throws
     * [com.edde746.plezy.data.recovery.DatabaseDurabilityException] when the image can't be written.
     */
    suspend fun acknowledgeRecoveryRequired() = db.acknowledgeRecoveryRequired()

    /**
     * Closes the database once the reads and writes running are done (a cancelled coroutine's read still running on the
     * I/O context among them); one asked for afterwards throws.
     */
    override fun close() = db.close(driver)
}

/** A fresh database's [schemaShape] on [factory]'s platform: an in-memory one made by this version's schema. */
private fun freshSchema(factory: DatabaseFactory): Map<String, String> {
    val driver = factory.scratch().createDriver(PlezyDatabase.Schema)
    try {
        return schemaShape(driver)
    } finally {
        driver.close()
    }
}

/**
 * [schema], calling [onMigrate] before it migrates an older database, and telling whether it created one ([created]).
 * A migration that fails throws a [DatabaseUnreadableException] (the database stays at its version), but for a full
 * disk, which the start recovers from.
 */
internal class ReportingSchema(
    private val schema: SqlSchema<QueryResult.Value<Unit>>,
    private val onMigrate: () -> Unit,
) : SqlSchema<QueryResult.Value<Unit>> by schema {
    /** Whether this open created the database: there was none. */
    var created = false
        private set

    override fun create(driver: SqlDriver): QueryResult.Value<Unit> {
        created = true
        return schema.create(driver)
    }

    override fun migrate(driver: SqlDriver, oldVersion: Long, newVersion: Long, vararg callbacks: AfterVersion): QueryResult.Value<Unit> {
        onMigrate()
        return try {
            schema.migrate(driver, oldVersion, newVersion, *callbacks)
        } catch (e: Exception) {
            if (isStorageFullError(e)) throw e
            throw DatabaseUnreadableException("Migrating the database from version $oldVersion to $newVersion failed", e)
        }
    }
}
