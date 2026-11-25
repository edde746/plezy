package com.edde746.plezy.data

import android.database.sqlite.SQLiteDatabaseLockedException
import android.database.sqlite.SQLiteTableLockedException

/** The framework throws SQLITE_BUSY as [SQLiteDatabaseLockedException] and SQLITE_LOCKED as [SQLiteTableLockedException]. */
internal actual fun Throwable.isDatabaseBusy(): Boolean = this is SQLiteDatabaseLockedException || this is SQLiteTableLockedException
