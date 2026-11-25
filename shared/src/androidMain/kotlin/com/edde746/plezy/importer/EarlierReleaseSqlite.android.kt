package com.edde746.plezy.importer

import android.database.Cursor
import android.database.sqlite.SQLiteDatabase
import kotlinx.io.files.Path
import kotlinx.io.files.SystemFileSystem
import kotlinx.io.files.SystemTemporaryDirectory
import kotlin.random.Random

/**
 * Android: the framework's SQLite, without its localized collators: those make it create its own `android_metadata`
 * table in the file, and an empty database from the earlier releases would then no longer read as empty.
 */
internal actual fun openEarlierReleaseSqlite(path: String): EarlierReleaseSqlite = AndroidEarlierReleaseSqlite(
    SQLiteDatabase.openDatabase(
        path,
        null,
        SQLiteDatabase.OPEN_READWRITE or SQLiteDatabase.ENABLE_WRITE_AHEAD_LOGGING or SQLiteDatabase.NO_LOCALIZED_COLLATORS,
    ),
)

private class AndroidEarlierReleaseSqlite(private val database: SQLiteDatabase) : EarlierReleaseSqlite {
    override fun execute(sql: String, args: List<String>) {
        if (args.isEmpty()) database.execSQL(sql) else database.execSQL(sql, args.toTypedArray())
    }

    override fun query(sql: String): List<Map<String, Any?>> = database.rawQuery(sql, null).use { cursor ->
        buildList {
            while (cursor.moveToNext()) {
                add(
                    (0 until cursor.columnCount).associate { index ->
                        cursor.getColumnName(index) to when (cursor.getType(index)) {
                            Cursor.FIELD_TYPE_NULL -> null
                            Cursor.FIELD_TYPE_INTEGER -> cursor.getLong(index)
                            Cursor.FIELD_TYPE_FLOAT -> cursor.getDouble(index)
                            Cursor.FIELD_TYPE_BLOB -> cursor.getBlob(index)
                            else -> cursor.getString(index)
                        }
                    },
                )
            }
        }
    }

    override fun close() = database.close()
}

/** Android: the temporary directory is the app's cache directory, which no other app can open. */
internal actual fun createPrivateDirectory(): String =
    Path(SystemTemporaryDirectory, "plezy-flutter-import-${Random.nextLong().toULong().toString(16)}")
        .also { SystemFileSystem.createDirectories(it) }
        .toString()
