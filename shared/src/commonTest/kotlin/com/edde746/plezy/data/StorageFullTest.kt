package com.edde746.plezy.data

import kotlin.test.Test
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class StorageFullTest {
    @Test
    fun diskFullFailuresAreRecognisedInAnyCase() {
        for (message in listOf(
            "[SQLITE_FULL] database or disk is full",
            "Database Or Disk Is Full (code 13)",
            "write failed: No space left on device",
            "ENOSPC",
            "OS Error: There is not enough space on the disk., errno = 112",
            "Not enough space on the disk",
            "Insufficient space to store the file",
            "The volume is out of space",
            "NSFileWriteOutOfSpaceError",
        )) {
            assertTrue(isStorageFullMessage(message), message)
        }
        for (message in listOf(null, "", "database is locked", "errno = 13", "connection reset")) {
            assertFalse(isStorageFullMessage(message), message.toString())
        }
    }

    @Test
    fun anErrorIsDiskFullWhenItOrACauseSaysSo() {
        assertTrue(isStorageFullError(IllegalStateException("SQLITE_FULL")))
        assertTrue(isStorageFullError(RuntimeException("the write failed", IllegalStateException("No space left on device"))))
        assertFalse(isStorageFullError(RuntimeException("the write failed", IllegalStateException("database is locked"))))
        assertFalse(isStorageFullError(null))
    }
}
