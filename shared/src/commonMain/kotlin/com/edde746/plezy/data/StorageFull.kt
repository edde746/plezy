package com.edde746.plezy.data

/**
 * Whether [error], or an error that caused it, says the disk is full ([isStorageFullMessage] of its text). Opening the
 * database and the download queue react to it, and error reports leave it out.
 */
fun isStorageFullError(error: Throwable?): Boolean =
    generateSequence(error) { it.cause }.take(MAX_CAUSES).any { isStorageFullMessage(it.toString()) }

/**
 * Whether [message] is a disk-full failure as SQLite, POSIX, Windows or Apple's file APIs word it, in any letter case:
 * `SQLITE_FULL`, "database or disk is full", "No space left on device", `ENOSPC`, `errno = 112`, "not enough space on
 * the disk", "insufficient space to store", "volume is out of space", `NSFileWriteOutOfSpaceError`.
 */
fun isStorageFullMessage(message: String?): Boolean {
    if (message.isNullOrEmpty()) return false
    val value = message.lowercase()
    return STORAGE_FULL_NEEDLES.any { it in value }
}

private val STORAGE_FULL_NEEDLES = listOf(
    "sqlite_full",
    "database or disk is full",
    "no space left on device",
    "enospc",
    "errno = 112",
    "not enough space on the disk",
    "insufficient space to store",
    "volume is out of space",
    "nsfilewriteoutofspaceerror",
)

/** A cause chain longer than this is cyclic or pathological. */
private const val MAX_CAUSES = 16
