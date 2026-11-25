package com.edde746.plezy.downloads

import app.cash.sqldelight.db.SqlDriver
import com.edde746.plezy.data.downloads.DownloadedMediaStatus
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.COMPLETED
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.servers.PlexProfileScopeId
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.async
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runTest
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

/**
 * Profile switches that land while a deletion waits on the database: [SelectGate] holds the first matching query
 * (outside a transaction) on its database thread until released.
 */
class DownloadsControllerProfileSwitchTest {
    private class SelectGate {
        @Volatile private var match: ((String, List<Any?>) -> Boolean)? = null
        private val latch = CountDownLatch(1)
        val started = CompletableDeferred<Unit>()

        fun wrap(delegate: SqlDriver): SqlDriver = ObservedDriver(delegate) { sql, args ->
            val armed = match
            if (armed != null && delegate.currentTransaction() == null && armed(sql, args)) {
                match = null
                started.complete(Unit)
                check(latch.await(10, TimeUnit.SECONDS)) { "The gate was never released" }
            }
        }

        fun arm(table: String, argument: String) {
            match = { sql, args -> table in sql && argument in args }
        }

        fun release() = latch.countDown()
    }

    private val gate = SelectGate()
    private var harness: ControllerHarness? = null

    @AfterTest
    fun close() {
        gate.release()
        harness?.close()
    }

    private val srv = ServerId("srv")
    private val movie = testMediaItem("1", MediaKind.MOVIE, "srv", title = "Owned Movie")

    private suspend fun dms() = DmsHarness.create(wrapDriver = gate::wrap)

    private suspend fun controller(dms: DmsHarness, profile: String) =
        ControllerHarness(dms, activeProfileId = profile).also { harness = it; it.controller.ensureInitialized() }

    private suspend fun TestScope.releasesTheInitiatingSharedOwner(status: DownloadedMediaStatus, operation: suspend DownloadsController.(String) -> Unit) {
        val key = "srv:profile-switch"
        val itemId = "profile-switch"
        val scopeA = PlexProfileScopeId.of(srv, "profile-a").value
        val scopeB = PlexProfileScopeId.of(srv, "profile-b").value
        val dms = dms()
        dms.connection("srv", "plex")
        dms.profile("profile-a")
        dms.profile("profile-b")
        dms.data.insertDownload("srv", itemId, status = status, clientScopeId = scopeA)
        dms.library.addDownloadOwner("profile-a", key, BackendKind.PLEX.id, scopeA)
        dms.library.addDownloadOwner("profile-b", key, BackendKind.PLEX.id, scopeB)
        for ((scope, title) in listOf(scopeA to "Profile A cache", scopeB to "Profile B cache")) {
            dms.putPlexMetadata(scope, itemId, plexFields("ratingKey" to itemId, "type" to "movie", "title" to title))
            dms.plexCache.pinForOffline(scope, itemId)
        }
        val h = controller(dms, "profile-a")
        h.load()

        gate.arm("download_owners", key)
        val deletion = async { h.controller.operation(key) }
        gate.started.await()
        h.controller.setActiveProfileId("profile-b")
        h.idle()
        gate.release()
        deletion.await()

        assertTrue(dms.library.getDownloadOwnerKeysForProfile("profile-a").isEmpty())
        assertEquals(setOf(key), dms.library.getDownloadOwnerKeysForProfile("profile-b"))
        assertEquals(setOf(key), h.controller.downloads.keys)
        assertEquals("Profile B cache", h.controller.getMetadata(key)?.title)
        assertEquals("Profile B cache", dms.plexCache.getMetadata(scopeB, itemId)?.title)
        assertTrue(dms.data.apiCache.isPinned(scopeB, "/library/metadata/$itemId"))
    }

    @Test
    fun deleteDownloadReleasesTheInitiatingOwnerWhenTheProfileSwitchesDuringOwnerLookup() = runTest {
        releasesTheInitiatingSharedOwner(COMPLETED) { deleteDownload(it) }
    }

    @Test
    fun cancelDownloadReleasesTheInitiatingOwnerWhenTheProfileSwitchesDuringOwnerLookup() = runTest {
        releasesTheInitiatingSharedOwner(DownloadedMediaStatus.QUEUED) { cancelDownload(it) }
    }

    private suspend fun TestScope.releasesTheFinalOwner(status: DownloadedMediaStatus, operation: suspend DownloadsController.(String) -> Unit) {
        val deletingKey = "srv:final-owner"
        val profileBKey = "srv:profile-b"
        val dms = dms()
        dms.library.addDownloadOwner("profile-b", profileBKey)
        val h = controller(dms, "profile-a")
        h.seed(
            downloads = mapOf(deletingKey to DownloadProgress(deletingKey, status), profileBKey to DownloadProgress(profileBKey, COMPLETED)),
            metadata = mapOf(deletingKey to movie.copy(id = "final-owner", title = "Profile A cache")),
            owned = setOf(deletingKey),
        )
        // Profile B's reload loads its download's pinned metadata.
        dms.pin(listOf(movie.copy(id = "profile-b", title = "Profile B cache")))

        // The physical deletion reads the row first.
        gate.arm("downloaded_media", deletingKey)
        val deletion = async { h.controller.operation(deletingKey) }
        gate.started.await()
        h.controller.setActiveProfileId("profile-b")
        h.idle()
        gate.release()
        deletion.await()

        assertTrue(dms.library.getDownloadOwnerKeysForProfile("profile-a").isEmpty())
        assertEquals(setOf(profileBKey), dms.library.getDownloadOwnerKeysForProfile("profile-b"))
        assertEquals(setOf(profileBKey), h.controller.downloads.keys)
        assertEquals("Profile B cache", h.controller.getMetadata(profileBKey)?.title)
    }

    @Test
    fun deleteDownloadReleasesItsFinalOwnerAfterAProfileSwitchDuringPhysicalDeletion() = runTest {
        releasesTheFinalOwner(COMPLETED) { deleteDownload(it) }
    }

    @Test
    fun cancelDownloadReleasesItsFinalOwnerAfterAProfileSwitchDuringPhysicalDeletion() = runTest {
        releasesTheFinalOwner(DownloadedMediaStatus.QUEUED) { cancelDownload(it) }
    }

    @Test
    fun aProfileSwitchDuringAShowDeletionLeavesTheNewProfilesEpisodesAlone() = runTest {
        val dms = dms()
        dms.profile("profile-a")
        dms.profile("profile-b")
        for ((id, owner) in listOf("ep-a" to "profile-a", "ep-b" to "profile-b")) {
            dms.data.insertDownload("srv", id, type = "episode", status = COMPLETED, parentRatingKey = "season-1", grandparentRatingKey = "show-1")
            dms.library.addDownloadOwner(owner, "srv:$id")
        }
        val h = controller(dms, "profile-a")
        h.load()
        assertEquals(setOf("srv:ep-a"), h.controller.downloads.keys)

        // Hold the descendant row query, then switch profiles under it.
        gate.arm("downloaded_media", "show-1")
        val deletion = async { h.controller.deleteDownload("srv:show-1") }
        gate.started.await()
        h.controller.setActiveProfileId("profile-b")
        h.idle()
        assertEquals(setOf("srv:ep-b"), h.controller.downloads.keys)
        gate.release()
        deletion.await()

        assertNotNull(dms.library.getDownloadedMedia("srv:ep-b"))
        assertEquals(setOf("srv:ep-b"), dms.library.getDownloadOwnerKeysForProfile("profile-b"))
        assertEquals(setOf("srv:ep-b"), h.controller.downloads.keys)
        assertEquals(setOf("srv:ep-a"), dms.library.getDownloadOwnerKeysForProfile("profile-a"))
    }
}
