package com.edde746.plezy.downloads

import com.edde746.plezy.data.downloads.StoredTask
import com.edde746.plezy.plex.withPlexToken
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/** A server's token never lands in the task table: tasks are kept without it, and each request gets it back. */
class TaskCredentialsTest {
    private val signedUrl = "https://cdn.example/library/parts/1/file.mkv?download=1&X-Plex-Token=secret"

    /** Every column of every stored task, as the database holds it. */
    private suspend fun storedRows(h: DownloadsHarness): String =
        h.data.db.read { downloadQueries.selectAll().executeAsList() }.joinToString("\n")

    @Test
    fun aTaskIsStoredWithoutItsTokenAndItsRequestCarriesTheServersToken() = downloadsTest { h ->
        h.credentials = TaskCredentials { it.copy(url = withPlexToken(it.url, "fresh")) }
        val downloader = h.start()

        downloader.enqueue(task().copy(url = signedUrl, headers = mapOf("X-Plex-Token" to "secret", "Accept" to "video/*")))
        h.settle()

        val rows = storedRows(h)
        assertTrue("film" in rows, rows)
        assertFalse("secret" in rows, rows)
        assertFalse("X-Plex-Token" in rows, rows)
        val request = h.fakeTransport.started.single()
        assertEquals("https://cdn.example/library/parts/1/file.mkv?download=1&X-Plex-Token=fresh", request.url)
        assertEquals(mapOf("Accept" to "video/*"), request.headers)
        assertFalse(downloader.allTasks().any { "secret" in it.url || "secret" in it.headers.values })
    }

    @Test
    fun aTaskAnEarlierVersionStoredWithItsTokenLosesItWhenTheTasksAreRead() = downloadsTest { h ->
        val earlier = task().copy(url = signedUrl)
        h.data.downloadTasks.save(StoredTask(earlier, TaskStatus.ENQUEUED, 0.0, -1, null, 5, null, null, 1))

        h.start()

        val rows = storedRows(h)
        assertTrue("film" in rows, rows)
        assertFalse("secret" in rows, rows)
        assertEquals("secret", h.fakeTransport.started.single().headers["X-Plex-Token"])
    }

    @Test
    fun aRunWhoseServerHasNoCredentialsSendsNothingAndWaitsToRetry() = downloadsTest { h ->
        h.credentials = TaskCredentials { null }
        val downloader = h.start()

        downloader.enqueue(task())
        h.settle()

        assertTrue(h.fakeTransport.started.isEmpty())
        assertEquals(TaskStatus.WAITING_TO_RETRY, h.callbacks.statusesOf("film").last())
    }

    @Test
    fun theTokenParametersOfPlexJellyfinAndEmbyAreTakenOffAndTheRestKept() {
        assertEquals(
            "https://jf.example/Videos/1/stream?static=true&MediaSourceId=a#t",
            withoutCredentials("https://jf.example/Videos/1/stream?static=true&ApiKey=k&MediaSourceId=a#t"),
        )
        assertEquals("https://emby.example/Videos/1/stream", withoutCredentials("https://emby.example/Videos/1/stream?api_key=k"))
        assertEquals("https://plex.example/file.mkv?download=1", withoutCredentials("https://plex.example/file.mkv?x-plex-token=k&download=1"))
        assertEquals("https://plex.example/file.mkv", withoutCredentials("https://plex.example/file.mkv"))
    }
}
