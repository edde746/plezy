package com.edde746.plezy.importer

/** A plain SQLite connection to a private copy of `plezy_downloads.db`, through each platform's SQLite. */
internal interface EarlierReleaseSqlite : AutoCloseable {
    /** Runs [sql], binding [args] to its `?` placeholders in order. */
    fun execute(sql: String, args: List<String> = emptyList())

    /** The rows [sql] returns, each column name → its value: a Long, Double, String, ByteArray or null. */
    fun query(sql: String): List<Map<String, Any?>>
}

/** Opens the database file at [path] for reading and writing, foreign keys unenforced (SQLite's default). */
internal expect fun openEarlierReleaseSqlite(path: String): EarlierReleaseSqlite

/** Makes a new directory, under the temporary directory, that no other user of the device can open; returns its path. */
internal expect fun createPrivateDirectory(): String
