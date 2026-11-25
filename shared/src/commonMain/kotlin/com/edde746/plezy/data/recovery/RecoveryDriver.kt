package com.edde746.plezy.data.recovery

import app.cash.sqldelight.db.QueryResult
import app.cash.sqldelight.db.SqlDriver
import app.cash.sqldelight.db.SqlPreparedStatement

/**
 * [delegate], telling [image] of every statement that changes the database before it runs ([RecoveryImage.beforeStatement]).
 * SQLDelight runs inserts, updates and deletes through [execute] (and only reads through `executeQuery`), so no write of
 * a critical table gets past it, whichever repository, importer or test issues it.
 */
internal class RecoveryDriver(private val delegate: SqlDriver, private val image: RecoveryImage) : SqlDriver by delegate {
    override fun execute(
        identifier: Int?,
        sql: String,
        parameters: Int,
        binders: (SqlPreparedStatement.() -> Unit)?,
    ): QueryResult<Long> {
        image.beforeStatement(sql)
        return delegate.execute(identifier, sql, parameters, binders)
    }
}

/**
 * Which groups a statement may change: those of every table it names. A statement naming a table only to read it
 * counts too; publishing a group that didn't change costs a rewrite, missing one would leave a stale image.
 */
internal class CriticalTables(private val tables: Map<String, Set<RecoveryGroup>>) {
    fun groupsOf(sql: String): Set<RecoveryGroup> {
        var groups: Set<RecoveryGroup> = emptySet()
        for (word in WORD.findAll(sql)) {
            val named = tables[word.value.lowercase()] ?: continue
            if (!groups.containsAll(named)) groups = groups + named
        }
        return groups
    }

    companion object {
        private val WORD = Regex("[A-Za-z0-9_]+")
        private val REFERENCES = Regex("REFERENCES\\s+[\"`\\[]?([A-Za-z0-9_]+)", RegexOption.IGNORE_CASE)

        /** The tables whose rows the image holds. */
        val OWN: Map<String, Set<RecoveryGroup>> = mapOf(
            "connections" to setOf(RecoveryGroup.IDENTITY),
            "profiles" to setOf(RecoveryGroup.IDENTITY),
            "profile_connections" to setOf(RecoveryGroup.IDENTITY),
            "device_setting" to setOf(RecoveryGroup.SETTINGS),
            "profile_setting" to setOf(RecoveryGroup.SETTINGS),
            "server_setting" to setOf(RecoveryGroup.SETTINGS),
            "offline_watch_progress" to setOf(RecoveryGroup.PENDING),
        )

        /**
         * [OWN], plus every table whose change reaches theirs through the schema of [driver]: a trigger on it naming one
         * of them, or a foreign key of theirs referencing it (a cascade), until no table gains a group.
         */
        fun of(driver: SqlDriver): CriticalTables {
            val schema = driver.executeQuery(
                null,
                "SELECT type, tbl_name, sql FROM sqlite_master WHERE type IN ('table', 'trigger') AND sql IS NOT NULL",
                { cursor ->
                    QueryResult.Value(
                        buildList {
                            while (cursor.next().value) add(Triple(cursor.getString(0)!!, cursor.getString(1)!!.lowercase(), cursor.getString(2)!!))
                        },
                    )
                },
                0,
            ).value
            val tables = OWN.toMutableMap()
            fun join(table: String, groups: Set<RecoveryGroup>): Boolean {
                val current = tables[table].orEmpty()
                if (current.containsAll(groups)) return false
                tables[table] = current + groups
                return true
            }
            do {
                var changed = false
                for ((type, table, sql) in schema) {
                    if (type == "table") {
                        val groups = tables[table] ?: continue
                        for (parent in REFERENCES.findAll(sql)) changed = join(parent.groupValues[1].lowercase(), groups) || changed
                    } else {
                        val groups = CriticalTables(tables).groupsOf(sql)
                        if (groups.isNotEmpty()) changed = join(table, groups) || changed
                    }
                }
            } while (changed)
            return CriticalTables(tables)
        }
    }
}
