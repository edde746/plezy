package com.edde746.plezy.data

/**
 * SQLite answered SQLITE_BUSY or SQLITE_LOCKED: another connection held its lock past the busy timeout
 * ([BUSY_TIMEOUT_MILLIS]; a commit while the disk is saturated). The one database failure that passes by itself, and
 * so the one [Db] reads again on.
 */
internal expect fun Throwable.isDatabaseBusy(): Boolean
