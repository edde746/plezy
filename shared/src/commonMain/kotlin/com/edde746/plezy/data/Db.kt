package com.edde746.plezy.data

import app.cash.sqldelight.Query
import app.cash.sqldelight.coroutines.asFlow
import app.cash.sqldelight.db.SqlDriver
import com.edde746.plezy.data.db.PlezyDatabase
import com.edde746.plezy.data.recovery.RecoveryImage
import com.edde746.plezy.log.Log
import com.edde746.plezy.net.Backoff
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.delay
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.emitAll
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.flow.retryWhen
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import kotlin.concurrent.atomics.AtomicInt
import kotlin.concurrent.atomics.ExperimentalAtomicApi
import kotlin.concurrent.atomics.decrementAndFetch
import kotlin.concurrent.atomics.incrementAndFetch
import kotlin.coroutines.CoroutineContext

/**
 * What every repository shares: the database, the I/O context, the write lock and the wall clock.
 *
 * Writes run one at a time ([write]): each is a read-modify-write transaction, and SQLite can't upgrade two
 * concurrent read transactions to writes without failing one of them. Reads and query flows run concurrently. Every
 * read ([read]) and query flow ([observeList], [observeOneOrNull], [observeOne]) is read again when it finds the
 * database busy ([readAgain]); any other failure goes to its caller. Each of them uses the driver through [useDriver],
 * so [close] waits for the ones running.
 *
 * On a database the system may delete ([recovery], Apple TV), each write keeps the recovery image in step with the
 * rows it changes ([RecoveryImage.durable]); elsewhere [recovery] is null and writes are plain transactions.
 */
@OptIn(ExperimentalAtomicApi::class)
internal class Db(
    val database: PlezyDatabase,
    val io: CoroutineContext,
    val wallClock: () -> Long,
    private val recovery: RecoveryImage? = null,
) {
    private val writeLock = Mutex()

    // The blocks using the driver now (useDriver), plus CLOSING once close has begun.
    private val users = AtomicInt(0)

    // Completed when the last block using the driver after close began is done.
    private val idle = CompletableDeferred<Unit>()

    /**
     * Runs [block] in one transaction, after every earlier write. [at] is the write's wall time ([Tx.now], epoch
     * milliseconds) when the caller gives one.
     */
    suspend fun <R> write(at: Long? = null, block: Tx.() -> R): R = writeLock.withLock {
        useDriver {
            val transaction = { database.transactionWithResult { Tx(this@Db, at).block() } }
            if (recovery == null) transaction() else recovery.durable(transaction)
        }
    }

    /** [RecoveryImage.acknowledgeRecoveryRequired] after every earlier write; nothing where there is no recovery image. */
    suspend fun acknowledgeRecoveryRequired() {
        val image = recovery ?: return
        writeLock.withLock { useDriver { image.acknowledgeRecoveryRequired() } }
    }

    /** [block] on [io]; one that finds the database busy runs again ([readAgain]). */
    suspend fun <R> read(block: PlezyDatabase.() -> R): R {
        var failures = 0
        while (true) {
            try {
                return useDriver { database.block() }
            } catch (e: Exception) {
                if (!readAgain(e, ++failures)) throw e
            }
        }
    }

    /** [query]'s rows, now and after every change to its tables; a read that finds the database busy runs again. */
    fun <T : Any> observeList(query: Query<T>): Flow<List<T>> = query.asFlow().map { useDriver { it.executeAsList() } }.busyRetried()

    /** [query]'s row or null, now and after every change to its tables; a read that finds the database busy runs again. */
    fun <T : Any> observeOneOrNull(query: Query<T>): Flow<T?> = query.asFlow().map { useDriver { it.executeAsOneOrNull() } }.busyRetried()

    /** [query]'s one row, now and after every change to its tables; a read that finds the database busy runs again. */
    fun <T : Any> observeOne(query: Query<T>): Flow<T> = query.asFlow().map { useDriver { it.executeAsOne() } }.busyRetried()

    /**
     * [block], which uses the driver, on [io]; [close] waits for it to finish. Once [close] has begun, [block] doesn't
     * run: a cancelled caller (a graph's work as the graph closes) gets its cancellation, any other an
     * IllegalStateException.
     */
    suspend fun <R> useDriver(block: () -> R): R = withContext(io) {
        if (users.incrementAndFetch() >= CLOSING) {
            leave()
            ensureActive()
            throw IllegalStateException("The database is closed")
        }
        try {
            block()
        } finally {
            leave()
        }
    }

    private fun leave() {
        if (users.decrementAndFetch() == CLOSING) idle.complete(Unit)
    }

    /**
     * Closes [driver] once the blocks using it ([useDriver]) are done, starting no other. A read or a query flow whose
     * coroutine is cancelled still runs on [io] until its statement is done: closing the driver under it would free the
     * statement it steps, which crashes the native driver. Later calls do nothing.
     */
    fun close(driver: SqlDriver) {
        var running: Int
        do {
            running = users.load()
            if (running >= CLOSING) return
        } while (!users.compareAndSet(running, running + CLOSING))
        if (running > 0) runBlocking { idle.await() }
        driver.close()
    }

    /**
     * A query flow that subscribes again when a read finds the database busy ([readAgain], the busy reads counted since
     * its last value), so its readers (a screen, the downloads engine) see the next change instead of keeping the last
     * rows for good. Any other failure ends it with that error.
     */
    private fun <T> Flow<T>.busyRetried(): Flow<T> = flow {
        var failures = 0
        emitAll(onEach { failures = 0 }.retryWhen { cause, _ -> readAgain(cause, ++failures) })
    }

    /**
     * Whether a read that failed with [cause], [failures] times in a row, runs again: only when it found the database
     * busy ([isDatabaseBusy]: another connection's lock held past the busy timeout while the disk is saturated), at most
     * [BUSY_RETRIES] times, after [Backoff.equalJitter] of [BUSY_RETRY_MIN_MILLIS] (logged). Any other failure, a busy
     * one past those, and a cancellation are the caller's.
     */
    private suspend fun readAgain(cause: Throwable, failures: Int): Boolean {
        if (cause is CancellationException || !cause.isDatabaseBusy() || failures > BUSY_RETRIES) return false
        val wait = Backoff.equalJitter(failures, BUSY_RETRY_MIN_MILLIS, BUSY_RETRY_MAX_MILLIS)
        Log.w(TAG, cause) { "a database read found the database busy; reading again in $wait ms ($failures of $BUSY_RETRIES)" }
        delay(wait)
        return true
    }

    private companion object {
        const val TAG = "db"
        const val BUSY_RETRIES = 5
        const val BUSY_RETRY_MIN_MILLIS = 1_000L
        const val BUSY_RETRY_MAX_MILLIS = 30_000L

        /** Added to [users] as [close] begins: far above any count of blocks using the driver at once. */
        const val CLOSING = 1 shl 30
    }
}

/** A write transaction: the queries, and the write's wall time when its caller set one. */
internal class Tx(private val db: Db, private val at: Long?) {
    val q: PlezyDatabase get() = db.database

    fun now(): Long = at ?: db.wallClock()
}
