package com.edde746.plezy.importer

import co.touchlab.sqliter.DatabaseConfiguration
import co.touchlab.sqliter.DatabaseConnection
import co.touchlab.sqliter.FieldType
import co.touchlab.sqliter.NO_VERSION_CHECK
import co.touchlab.sqliter.createDatabaseManager
import kotlinx.io.files.Path
import kotlinx.io.files.SystemFileSystem
import kotlinx.io.files.SystemTemporaryDirectory
import kotlin.random.Random

/** Apple: the system SQLite through SQLiter, the app database's driver; no schema version check, no create step. */
internal actual fun openEarlierReleaseSqlite(path: String): EarlierReleaseSqlite {
    val configuration = DatabaseConfiguration(
        path.substringAfterLast('/'),
        NO_VERSION_CHECK,
        {},
        extendedConfig = DatabaseConfiguration.Extended(basePath = path.substringBeforeLast('/')),
    )
    return SqliterEarlierReleaseSqlite(createDatabaseManager(configuration).createSingleThreadedConnection())
}

private class SqliterEarlierReleaseSqlite(private val connection: DatabaseConnection) : EarlierReleaseSqlite {
    override fun execute(sql: String, args: List<String>) {
        val statement = connection.createStatement(sql)
        try {
            args.forEachIndexed { index, arg -> statement.bindString(index + 1, arg) }
            statement.execute()
        } finally {
            statement.finalizeStatement()
        }
    }

    override fun query(sql: String): List<Map<String, Any?>> {
        val statement = connection.createStatement(sql)
        try {
            val cursor = statement.query()
            return buildList {
                while (cursor.next()) {
                    add(
                        (0 until cursor.columnCount).associate { index ->
                            cursor.columnName(index) to when (cursor.getType(index)) {
                                FieldType.TYPE_NULL -> null
                                FieldType.TYPE_INTEGER -> cursor.getLong(index)
                                FieldType.TYPE_FLOAT -> cursor.getDouble(index)
                                FieldType.TYPE_BLOB -> cursor.getBytes(index)
                                FieldType.TYPE_TEXT -> cursor.getString(index)
                            }
                        },
                    )
                }
            }
        } finally {
            statement.finalizeStatement()
        }
    }

    override fun close() = connection.close()
}

/** Apple: the temporary directory is the user's own (the app's, in its sandbox), which no other user can open. */
internal actual fun createPrivateDirectory(): String =
    Path(SystemTemporaryDirectory, "plezy-flutter-import-${Random.nextLong().toULong().toString(16)}")
        .also { SystemFileSystem.createDirectories(it) }
        .toString()
