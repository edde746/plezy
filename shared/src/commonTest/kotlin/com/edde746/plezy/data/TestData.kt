package com.edde746.plezy.data

import kotlinx.coroutines.Dispatchers

/** A private in-memory database on the platform running the test. */
internal expect fun inMemoryDatabase(): DatabaseFactory

/** A wall clock the test moves by hand, in epoch milliseconds. */
internal class TestClock(var now: Long = 1_790_000_000_000L)

internal fun testData(clock: TestClock = TestClock(), factory: DatabaseFactory = inMemoryDatabase()): LocalData =
    LocalData(factory, { clock.now }, Dispatchers.Default)

/** Stores bare Jellyfin connection rows named [ids], for bindings that need a connection to refer to. */
internal fun LocalData.withConnections(vararg ids: String): LocalData = apply {
    for (id in ids) db.database.connectionQueries.insertRow(com.edde746.plezy.data.db.Connections(id, "jellyfin", "{}", 1, null, null))
}
