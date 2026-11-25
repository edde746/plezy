package com.edde746.plezy.data

import app.cash.sqldelight.Query
import app.cash.sqldelight.TransacterImpl
import app.cash.sqldelight.db.QueryResult
import app.cash.sqldelight.db.SqlSchema
import app.cash.sqldelight.driver.jdbc.ConnectionManager.Transaction
import app.cash.sqldelight.driver.jdbc.JdbcDriver
import java.sql.Connection
import java.sql.DriverManager
import java.sql.SQLException
import java.util.Properties
import java.util.concurrent.ConcurrentLinkedDeque
import java.util.concurrent.ConcurrentLinkedQueue

/**
 * The desktop's driver for a database file, through the SQLite JDBC driver. SQLDelight's JdbcSqliteDriver opens a
 * connection for every statement outside a transaction and closes it after, so each read opens the file and applies
 * [properties] again. This one keeps the connections it opens: a statement or a transaction takes an idle one (opening
 * one only when none is idle) and gives it back once done, so there are as many as ran at once. A transaction keeps its
 * connection, on its thread, until it ends; one that couldn't end closes its connection, which rolls it back, instead of
 * giving it back. [close] closes them all.
 */
internal class PooledSqliteDriver(private val url: String, private val properties: Properties) : JdbcDriver() {
    private val opened = ConcurrentLinkedQueue<Connection>()
    private val idle = ConcurrentLinkedDeque<Connection>()
    private val transactions = ThreadLocal<Transaction>()
    private val listeners = HashMap<String, MutableSet<Query.Listener>>()

    override var transaction: Transaction?
        get() = transactions.get()
        set(value) {
            val ended = transactions.get()
            transactions.set(value)
            if (value == null && ended != null) giveBack(ended.connection)
        }

    override fun getConnection(): Connection = idle.pollFirst() ?: DriverManager.getConnection(url, properties).also(opened::add)

    /** Called after each statement run outside a transaction. */
    override fun closeConnection(connection: Connection) = giveBack(connection)

    private fun giveBack(connection: Connection) {
        if (!connection.isClosed) idle.addFirst(connection)
    }

    override fun Connection.beginTransaction() = exec("BEGIN TRANSACTION")

    override fun Connection.endTransaction() = endOrClose("END TRANSACTION")

    override fun Connection.rollbackTransaction() = endOrClose("ROLLBACK TRANSACTION")

    private fun Connection.endOrClose(sql: String) {
        try {
            exec(sql)
        } catch (e: SQLException) {
            try {
                close()
            } catch (closing: SQLException) {
                e.addSuppressed(closing)
            }
            throw e
        }
    }

    private fun Connection.exec(sql: String) {
        prepareStatement(sql).use { it.execute() }
    }

    override fun close() {
        idle.clear()
        opened.forEach(Connection::close)
    }

    override fun addListener(vararg queryKeys: String, listener: Query.Listener) {
        synchronized(listeners) { queryKeys.forEach { listeners.getOrPut(it) { LinkedHashSet() }.add(listener) } }
    }

    override fun removeListener(vararg queryKeys: String, listener: Query.Listener) {
        synchronized(listeners) { queryKeys.forEach { listeners[it]?.remove(listener) } }
    }

    override fun notifyListeners(vararg queryKeys: String) {
        val notified = LinkedHashSet<Query.Listener>()
        synchronized(listeners) { queryKeys.forEach { listeners[it]?.let(notified::addAll) } }
        notified.forEach(Query.Listener::queryResultsChanged)
    }

    /**
     * Creates [schema] in a new database or migrates an older one, by its `user_version`, in one transaction; a newer
     * one (a later release's) is refused with [DatabaseNewerThanAppException].
     */
    fun createOrMigrate(schema: SqlSchema<QueryResult.Value<Unit>>) {
        object : TransacterImpl(this) {}.transaction {
            val version = executeQuery(null, "PRAGMA user_version", { QueryResult.Value(if (it.next().value) it.getLong(0) else null) }, 0).value ?: 0L
            if (version < schema.version) {
                if (version == 0L) schema.create(this@PooledSqliteDriver) else schema.migrate(this@PooledSqliteDriver, version, schema.version)
                execute(null, "PRAGMA user_version = ${schema.version}", 0)
            } else if (version > schema.version) {
                throw DatabaseNewerThanAppException(version, schema.version)
            }
        }
    }
}
