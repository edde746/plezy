package com.edde746.plezy.data

import app.cash.sqldelight.db.QueryResult
import app.cash.sqldelight.db.SqlDriver
import app.cash.sqldelight.db.SqlSchema
import app.cash.sqldelight.driver.jdbc.sqlite.JdbcSqliteDriver
import com.edde746.plezy.data.recovery.PurgeableDatabase
import java.nio.file.Files
import java.nio.file.Path
import java.util.Properties

/** The desktop database (Windows, Linux), through the SQLite JDBC driver. */
actual class DatabaseFactory private constructor(private val file: Path?, @Suppress("unused") inMemory: Boolean) {
    /** The database at [file]; missing parent directories are created on open. */
    constructor(file: Path) : this(file, inMemory = false)

    internal actual fun createDriver(schema: SqlSchema<QueryResult.Value<Unit>>): SqlDriver {
        // WAL lets query flows read while a write is in progress. Each connection waits up to BUSY_TIMEOUT_MILLIS for
        // another's lock and enforces the schema's foreign keys.
        val properties = Properties().apply {
            setProperty("journal_mode", "WAL")
            setProperty("busy_timeout", BUSY_TIMEOUT_MILLIS.toString())
            setProperty("foreign_keys", "true")
        }
        if (file == null) return JdbcSqliteDriver("jdbc:sqlite::memory:", properties, schema)
        val path = file.toAbsolutePath()
        path.parent?.let { Files.createDirectories(it) }
        val databaseFile = kotlinx.io.files.Path(path.toString())
        removeOrphanedSidecars(databaseFile)
        prepareOpen(databaseFile, schema.version)
        val driver = PooledSqliteDriver("jdbc:sqlite:$path", properties)
        try {
            driver.createOrMigrate(schema)
        } catch (e: Throwable) {
            driver.close()
            throw e
        }
        return driver
    }

    /** Never: desktop storage isn't purged. */
    internal actual fun purgeable(): PurgeableDatabase? = null

    internal actual fun filesDirectory(): String =
        (file?.toAbsolutePath()?.parent ?: Path.of(System.getProperty("java.io.tmpdir")).resolve("plezy")).toString()

    internal actual fun file(): kotlinx.io.files.Path? = file?.let { kotlinx.io.files.Path(it.toAbsolutePath().toString()) }

    internal actual fun scratch(): DatabaseFactory = inMemory()

    internal actual val opensOnFirstStatement: Boolean get() = false

    companion object {
        /** A private in-memory database, gone when [LocalData.close] closes it. */
        fun inMemory(): DatabaseFactory = DatabaseFactory(null, inMemory = true)

        /**
         * Plezy's per-user application data location, the one its earlier releases used: `%APPDATA%\com.edde746\Plezy`
         * on Windows, `$XDG_DATA_HOME/com.edde746.plezy` (`~/.local/share/com.edde746.plezy`) on Linux, which a
         * Flatpak maps into its sandbox, and `~/Library/Application Support/com.edde746.plezy` on macOS.
         */
        fun defaultDirectory(): Path {
            val os = System.getProperty("os.name").lowercase()
            val home = Path.of(System.getProperty("user.home"))
            return when {
                os.startsWith("windows") -> {
                    val roaming = System.getenv("APPDATA")?.takeIf { it.isNotBlank() }?.let { Path.of(it) }
                    (roaming ?: home.resolve("AppData").resolve("Roaming")).resolve("com.edde746").resolve("Plezy")
                }
                os.startsWith("mac") -> home.resolve("Library").resolve("Application Support").resolve("com.edde746.plezy")
                else -> {
                    val data = System.getenv("XDG_DATA_HOME")?.takeIf { it.isNotBlank() }?.let { Path.of(it) }
                    (data ?: home.resolve(".local").resolve("share")).resolve("com.edde746.plezy")
                }
            }
        }
    }
}
