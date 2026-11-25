package com.edde746.plezy.data

import java.sql.SQLException

/** sqlite-jdbc's `SQLiteException` carries SQLite's primary result code as the vendor code. */
internal actual fun Throwable.isDatabaseBusy(): Boolean =
    this is SQLException && (errorCode and 0xff).let { it == SQLITE_BUSY || it == SQLITE_LOCKED }

/** SQLite's primary result codes for a lock another connection holds; extended codes keep them in their low byte. */
private const val SQLITE_BUSY = 5
private const val SQLITE_LOCKED = 6
