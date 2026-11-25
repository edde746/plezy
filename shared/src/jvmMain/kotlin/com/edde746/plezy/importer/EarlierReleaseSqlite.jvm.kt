package com.edde746.plezy.importer

import java.nio.file.Files
import java.sql.Connection
import java.sql.DriverManager

/** Desktop: the SQLite JDBC driver the app's own database uses. */
internal actual fun openEarlierReleaseSqlite(path: String): EarlierReleaseSqlite = JdbcEarlierReleaseSqlite(DriverManager.getConnection("jdbc:sqlite:$path"))

private class JdbcEarlierReleaseSqlite(private val connection: Connection) : EarlierReleaseSqlite {
    override fun execute(sql: String, args: List<String>) {
        connection.prepareStatement(sql).use { statement ->
            args.forEachIndexed { index, arg -> statement.setString(index + 1, arg) }
            statement.execute()
        }
    }

    override fun query(sql: String): List<Map<String, Any?>> = connection.createStatement().use { statement ->
        statement.executeQuery(sql).use { rows ->
            val columns = (1..rows.metaData.columnCount).map { rows.metaData.getColumnLabel(it) }
            buildList {
                while (rows.next()) {
                    add(
                        columns.withIndex().associate { (index, name) ->
                            name to when (val value = rows.getObject(index + 1)) {
                                // The driver hands back INTEGER values that fit an Int as Integer.
                                is Int -> value.toLong()
                                null, is Long, is Double, is String, is ByteArray -> value
                                else -> error("Unexpected SQLite value ${value::class}")
                            }
                        },
                    )
                }
            }
        }
    }

    override fun close() = connection.close()
}

/**
 * Desktop: the temporary directory (`/tmp` on Linux) is open to every user, so the directory is made owner-only (0700
 * where the file system has POSIX permissions; Windows' temporary directory is the user's own).
 */
internal actual fun createPrivateDirectory(): String = Files.createTempDirectory("plezy-flutter-import-").toString()
