package com.edde746.plezy.data

import app.cash.sqldelight.db.QueryResult
import app.cash.sqldelight.db.SqlDriver

/**
 * Why the app's saved data can't be used, as the startup failure screen tells the user and offers to reset it
 * ([com.edde746.plezy.crash.StartupFailureRecord.dataFault]). The ids are stable: persisted records carry them.
 */
enum class DataFault(val id: String) {
    /** The database is damaged, its migration failed, or its schema isn't the one this version expects. */
    UNREADABLE("unreadable"),

    /** A later release wrote the database ([DatabaseNewerThanAppException]): updating the app opens it. */
    NEWER("newer"),
    ;

    companion object {
        fun fromId(id: String?): DataFault? = entries.firstOrNull { it.id == id }

        /** The fault [error] (or one of its causes) reports; null for any other failure, a full disk among them. */
        fun of(error: Throwable): DataFault? {
            for (cause in generateSequence(error) { it.cause }.take(MAX_CAUSES)) {
                if (cause is DatabaseNewerThanAppException) return NEWER
                if (cause is DatabaseUnreadableException) return UNREADABLE
            }
            return null
        }
    }
}

/** The database can't be used as it is: damaged, its migration failed, or its schema differs from this version's. */
class DatabaseUnreadableException(message: String, cause: Throwable? = null) : IllegalStateException(message, cause)

/**
 * [error] from opening or migrating the database, as the start reports it: a [DatabaseUnreadableException] when SQLite
 * found the file damaged or unreadable (not a database, a malformed image, an I/O error reading it), else [error]
 * itself. A full disk ([isStorageFullError]) stays as it is: the start recovers from it, and its data is sound.
 */
internal fun unreadableOrItself(error: Throwable): Throwable = when {
    DataFault.of(error) != null || isStorageFullError(error) -> error
    generateSequence(error) { it.cause }.take(MAX_CAUSES).any { cause -> cause.toString().lowercase().let { text -> UNREADABLE_NEEDLES.any { it in text } } } ->
        DatabaseUnreadableException("The database can't be read", error)
    else -> error
}

/**
 * SQLite's own words for a file it can't read (its result codes' names and `sqlite3_errstr` texts), which every
 * driver's exceptions carry: Android's `SQLiteDatabaseCorruptException`, sqlite-jdbc's and SQLiter's.
 */
private val UNREADABLE_NEEDLES = listOf(
    "sqlite_corrupt",
    "sqlite_notadb",
    "sqlite_ioerr",
    "file is not a database",
    "file is encrypted or is not a database",
    "database disk image is malformed",
    "disk i/o error",
)

/**
 * The database's schema as SQLite resolves it, apart from how its statements were written: each table's columns in
 * order (name, type, not null, default, primary key), its foreign keys and indexes, and each trigger's statement.
 * SQLite's own tables (`sqlite_sequence`, the statistics) are left out.
 */
internal fun schemaShape(driver: SqlDriver): Map<String, String> = buildMap {
    for (table in rows(driver, "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%' ORDER BY name", 1).map { it[0]!! }) {
        put("table $table", rows(driver, "PRAGMA table_info($table)", 6).map { it.drop(1) }.toString())
        put("foreign keys $table", rows(driver, "PRAGMA foreign_key_list($table)", 8).map { it.drop(2) }.sortedBy { it.toString() }.toString())
        for (index in rows(driver, "PRAGMA index_list($table)", 3)) {
            put("index ${index[1]}", "on $table unique ${index[2]} " + rows(driver, "PRAGMA index_info(${index[1]})", 3).map { it[2] })
        }
    }
    for (trigger in rows(driver, "SELECT name, sql FROM sqlite_master WHERE type = 'trigger'", 2)) {
        put("trigger ${trigger[0]}", trigger[1]!!.replace(Regex("\\s+"), " "))
    }
}

/**
 * Throws a [DatabaseUnreadableException] naming what differs when [actual] (the database's [schemaShape]) isn't
 * [expected] (a fresh database's): a database of this schema version that an unreleased build changed in place.
 */
internal fun requireSchema(actual: Map<String, String>, expected: Map<String, String>) {
    val differences = (actual.keys + expected.keys).filter { actual[it] != expected[it] }.sorted()
    if (differences.isEmpty()) return
    val described = differences.joinToString { key ->
        when {
            key !in actual -> "$key missing"
            key !in expected -> "$key unexpected"
            else -> "$key differs"
        }
    }
    throw DatabaseUnreadableException("The database's schema isn't this version's: $described")
}

private fun rows(driver: SqlDriver, sql: String, width: Int): List<List<String?>> = driver.executeQuery(null, sql, { cursor ->
    val rows = mutableListOf<List<String?>>()
    while (cursor.next().value) rows += (0 until width).map { cursor.getString(it) ?: cursor.getLong(it)?.toString() }
    QueryResult.Value(rows)
}, 0).value

/** A cause chain longer than this is cyclic or pathological. */
private const val MAX_CAUSES = 16
