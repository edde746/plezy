package com.edde746.plezy.data

import app.cash.sqldelight.db.QueryResult
import app.cash.sqldelight.db.SqlDriver
import kotlinx.io.files.Path
import kotlinx.io.files.SystemFileSystem
import kotlin.test.assertEquals

/** A file database of the test's own on the platform running it, and its [file]; [delete] removes it and its copies. */
internal class FileDatabase(val factory: DatabaseFactory, val file: Path) {
    fun delete() {
        val dir = file.parent?.takeIf { SystemFileSystem.exists(it) } ?: return
        for (path in SystemFileSystem.list(dir)) {
            if (path.name.startsWith(file.name)) SystemFileSystem.delete(path, mustExist = false)
        }
    }
}

internal expect fun fileDatabase(): FileDatabase

/** Every row of every table: table → rows, each column → its value as text (null stays null). */
internal typealias Rows = Map<String, List<Map<String, String?>>>

/**
 * Puts one row in every table of the database [driver] has open, parents before the tables whose foreign keys refer to
 * them: each text column holds `k`, each number 1 (so a reference meets its parent's key), each blob one zero byte.
 */
internal fun seedEveryTable(driver: SqlDriver) {
    val pending = tables(driver).toMutableList()
    val seeded = mutableSetOf<String>()
    while (pending.isNotEmpty()) {
        val next = pending.first { table -> parents(driver, table).all { it == table || it in seeded } }
        val columns = columns(driver, next)
        val values = columns.joinToString { (_, type) ->
            when {
                type.contains("INT") -> "1"
                type.contains("REAL") || type.contains("FLOA") || type.contains("DOUB") -> "1.0"
                type.contains("BLOB") -> "x'00'"
                else -> "'k'"
            }
        }
        driver.execute(null, "INSERT INTO $next (${columns.joinToString { it.first }}) VALUES ($values)", 0)
        pending -= next
        seeded += next
    }
}

/** What [seedEveryTable] and the app put in the database: every row of every table. */
internal fun readEveryRow(driver: SqlDriver): Rows = tables(driver).associateWith { table ->
    val names = columns(driver, table).map { it.first }
    val select = names.joinToString { "CAST($it AS TEXT)" }
    driver.executeQuery(null, "SELECT $select FROM $table ORDER BY rowid", { cursor ->
        val rows = mutableListOf<Map<String, String?>>()
        while (cursor.next().value) rows += names.indices.associate { names[it] to cursor.getString(it) }
        QueryResult.Value(rows)
    }, 0).value
}

/**
 * Asserts the rows [before] a migration are in the migrated database ([after]): each table that's still there keeps
 * its rows, and each column that's still there its values.
 */
internal fun assertRowsSurvive(before: Rows, after: Rows) {
    for ((table, rows) in before) {
        val kept = after[table] ?: continue
        assertEquals(rows.size, kept.size, "rows of $table")
        rows.zip(kept).forEach { (old, new) ->
            assertEquals(old.filterKeys { it in new }, new.filterKeys { it in old }, "a row of $table")
        }
    }
}

/** The schema version stored in the database [driver] has open. */
internal fun userVersion(driver: SqlDriver): Long = rows(driver, "PRAGMA user_version", 1).single()[0]!!.toLong()

private fun tables(driver: SqlDriver): List<String> =
    rows(driver, "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%' ORDER BY name", 1).map { it[0]!! }

/** A table's columns: name and declared type, upper-cased. */
private fun columns(driver: SqlDriver, table: String): List<Pair<String, String>> =
    rows(driver, "PRAGMA table_info($table)", 3).map { it[1]!! to it[2].orEmpty().uppercase() }

private fun parents(driver: SqlDriver, table: String): List<String> = rows(driver, "PRAGMA foreign_key_list($table)", 3).map { it[2]!! }

private fun rows(driver: SqlDriver, sql: String, width: Int): List<List<String?>> = driver.executeQuery(null, sql, { cursor ->
    val rows = mutableListOf<List<String?>>()
    while (cursor.next().value) rows += (0 until width).map { cursor.getString(it) ?: cursor.getLong(it)?.toString() }
    QueryResult.Value(rows)
}, 0).value
