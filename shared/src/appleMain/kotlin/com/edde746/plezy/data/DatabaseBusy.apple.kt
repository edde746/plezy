package com.edde746.plezy.data

import co.touchlab.sqliter.interop.SQLiteExceptionErrorCode
import co.touchlab.sqliter.interop.SqliteErrorType

/** SQLiter, under the native driver, throws SQLite's primary result code with the error ([SQLiteExceptionErrorCode.errorType]). */
internal actual fun Throwable.isDatabaseBusy(): Boolean =
    this is SQLiteExceptionErrorCode && (errorType == SqliteErrorType.SQLITE_BUSY || errorType == SqliteErrorType.SQLITE_LOCKED)
