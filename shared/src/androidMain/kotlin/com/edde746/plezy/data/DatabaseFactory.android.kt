package com.edde746.plezy.data

import android.content.Context
import androidx.sqlite.db.SupportSQLiteDatabase
import app.cash.sqldelight.db.QueryResult
import app.cash.sqldelight.db.SqlDriver
import app.cash.sqldelight.db.SqlSchema
import app.cash.sqldelight.driver.android.AndroidSqliteDriver
import com.edde746.plezy.data.recovery.PurgeableDatabase
import kotlinx.io.files.Path

/**
 * The Android database, in the app's private databases directory ([Context.getDatabasePath]). Android's backups and
 * device-to-device transfers carry it (`res/xml/backup_rules.xml`); it holds no tokens, which stay in the secret store.
 */
actual class DatabaseFactory private constructor(context: Context, private val name: String?) {
    private val context: Context = context.applicationContext ?: context

    constructor(context: Context) : this(context, DATABASE_FILE_NAME)

    internal actual fun createDriver(schema: SqlSchema<QueryResult.Value<Unit>>): SqlDriver {
        if (name != null) {
            val file = Path(context.getDatabasePath(name).path)
            removeOrphanedSidecars(file)
            prepareOpen(file, schema.version)
        }
        return driver(schema)
    }

    private fun driver(schema: SqlSchema<QueryResult.Value<Unit>>): SqlDriver = AndroidSqliteDriver(
        schema = schema,
        context = context,
        name = name,
        callback = object : AndroidSqliteDriver.Callback(schema) {
            // WAL lets query flows read while a write is in progress (in-memory databases stay in memory mode); every
            // connection enforces the schema's foreign keys.
            override fun onConfigure(db: SupportSQLiteDatabase) {
                if (name != null) db.enableWriteAheadLogging()
                db.setForeignKeyConstraintsEnabled(true)
            }

            // The framework's default deletes a database it finds corrupt, and the open goes on with an empty one: the
            // user's data gone without a word. Kept, the open fails, and the start offers the reset (DataFault).
            override fun onCorruption(db: SupportSQLiteDatabase) = Unit
        },
    )

    /** Never: the app's databases directory isn't purged. */
    internal actual fun purgeable(): PurgeableDatabase? = null

    internal actual fun filesDirectory(): String = context.filesDir.path

    internal actual fun file(): Path? = name?.let { Path(context.getDatabasePath(it).path) }

    internal actual fun scratch(): DatabaseFactory = inMemory(context)

    internal actual val opensOnFirstStatement: Boolean get() = true

    companion object {
        /** A private in-memory database, gone when [LocalData.close] closes it. */
        fun inMemory(context: Context): DatabaseFactory = DatabaseFactory(context, null)

        /**
         * A database of its own named [name] in the same directory, apart from the app's (a debug build's kept
         * development session); the app's data going (a reset, an uninstall) takes it along.
         */
        fun named(context: Context, name: String): DatabaseFactory {
            require(name != DATABASE_FILE_NAME) { "$name is the app's own database" }
            return DatabaseFactory(context, name)
        }
    }
}
