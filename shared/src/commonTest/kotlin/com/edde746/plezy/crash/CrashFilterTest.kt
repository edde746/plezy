package com.edde746.plezy.crash

import com.edde746.plezy.plex.PlexMappers
import com.edde746.plezy.servers.OperationTimeoutException
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonArray
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds

class CrashFilterTest {
    @AfterTest
    fun reset() {
        CrashCapture.sink = null
    }

    @Test
    fun `the unactionable failures are dropped`() {
        val dropped = listOf(
            "FileSystemException" to "Cannot delete file, path = 'C:/plexImageCache/a' (OS Error: errno = 32)",
            "FileSystemException" to "Cached_Network_Image_CE: lock failed",
            "FileSystemException" to "cached_network_image_ce writeFrom failed",
            "DBusServiceUnknownException" to null,
            "SocketException" to "connect to /run/dbus/system_bus_socket failed",
            "SQLiteFullException" to "database or disk is full (code 13 SQLITE_FULL)",
            "IOException" to "No space left on device",
            "IOException" to "There is not enough space on the disk",
            "HTTPClientError" to "500",
            "PlatformException" to "No active stream to cancel",
            "DiscordStateException" to "Discord is not running",
        )
        for ((type, value) in dropped) assertTrue(CrashFilter.drops(type, value), "$type: $value")
    }

    @Test
    fun `other failures are kept`() {
        assertFalse(CrashFilter.drops("FileSystemException", "Cannot open file, path = 'a'"))
        assertFalse(CrashFilter.drops("PlatformException", "something else"))
        assertFalse(CrashFilter.drops("IllegalStateException", "boom"))
        assertFalse(CrashFilter.drops(null, null))
    }

    @Test
    fun `a timeout is tagged and grouped by its operation`() {
        val (tags, fingerprint) = CrashFilter.timeoutTags(IllegalStateException("wrapped", OperationTimeoutException("fetchHubs", 5.seconds)))!!
        assertEquals(mapOf("timeout.operation" to "fetchHubs", "timeout.duration" to "0:00:05.000000"), tags)
        assertEquals(listOf("TimeoutException", "fetchHubs"), fingerprint)
        assertNull(CrashFilter.timeoutTags(IllegalStateException("boom")))
    }

    @Test
    fun `a survived failure that timed out is reported with its operations tags and grouping`() {
        val report = CrashReport.of(IllegalStateException("wrapped", OperationTimeoutException("fetchHubs", 5.seconds)))
        assertEquals(mapOf("timeout.operation" to "fetchHubs", "timeout.duration" to "0:00:05.000000"), report.tags)
        assertEquals(listOf("TimeoutException", "fetchHubs"), report.fingerprint)
        val other = CrashReport.of(IllegalStateException("boom"))
        assertTrue(other.tags.isEmpty())
        assertNull(other.fingerprint)
    }

    @Test
    fun `durations read as hours minutes seconds and microseconds`() {
        assertEquals("1:02:03.004000", CrashFilter.clockText(3723.seconds + 4.milliseconds))
    }

    @Test
    fun `malformed plex metadata is reported with only a closed projection and thrown on`() {
        val markers = listOf("cc004-rating-marker", "cc004-title-marker", "cc004-summary-marker", "cc004-unmodeled-key-marker", "cc004-nested-marker")
        val malformed = buildJsonObject {
            put("ratingKey", markers[0])
            put("title", markers[1])
            put("summary", markers[2])
            put(markers[3], buildJsonObject { put("value", markers[4]) })
            put("type", buildJsonArray { add(JsonPrimitive(7)) })
        }
        val reports = mutableListOf<CrashReport>()
        CrashCapture.sink = CrashCapture.Sink { reports += it; true }
        assertFailsWith<IllegalArgumentException> { PlexMappers.mediaItem(malformed) }
        val report = reports.single()
        assertEquals(mapOf("plex_mapper" to mapOf("backend" to "plex", "dto" to "PlexMetadataDto", "topLevelFieldCount" to 5)), report.contexts)
        val text = report.contexts.toString() + report.error?.message
        for (marker in markers) assertFalse(marker in text, marker)
    }
}
