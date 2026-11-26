package com.edde746.plezy.watchnext

import android.content.ContentProvider
import android.content.ContentValues
import android.content.pm.PackageManager
import android.database.Cursor
import android.database.MatrixCursor
import android.media.tv.TvContract
import android.net.Uri
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.presentation.homescreen.HomeScreenItem
import com.edde746.plezy.presentation.homescreen.HomeScreenShelf
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import java.net.ServerSocket
import java.net.Socket
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import kotlin.concurrent.thread
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

/** A profile's shelf that a newer one replaced while its posters download never reaches the home screen. */
@RunWith(RobolectricTestRunner::class)
class WatchNextTest {
    /** The TV provider's Watch Next table, holding nothing: what this app inserts is counted, not kept. */
    class Provider : ContentProvider() {
        @Volatile var inserts = 0

        override fun onCreate() = true

        override fun query(uri: Uri, projection: Array<out String>?, selection: String?, args: Array<out String>?, sort: String?): Cursor =
            MatrixCursor(projection)

        override fun insert(uri: Uri, values: ContentValues?): Uri {
            inserts++
            return Uri.withAppendedPath(uri, "$inserts")
        }

        override fun update(uri: Uri, values: ContentValues?, selection: String?, args: Array<out String>?) = 0

        override fun delete(uri: Uri, selection: String?, args: Array<out String>?) = 0

        override fun getType(uri: Uri): String? = null
    }

    private fun item(id: String, poster: String) = HomeScreenItem(
        contentId = "plezy_srv_$id", kind = MediaKind.MOVIE, title = "Movie $id", episodeTitle = null, description = null,
        posterSource = poster, durationMillis = 2_900_000, positionMillis = 600_000, lastEngagedMillis = 1_000,
        seriesTitle = null, seasonNumber = null, episodeNumber = null,
    )

    @Test
    fun theClearAfterASignOutLandsWithoutWaitingForTheOldProfilesPosters() {
        val context = RuntimeEnvironment.getApplication()
        shadowOf(context.packageManager).setSystemFeature(PackageManager.FEATURE_LEANBACK, true)
        val provider = Robolectric.buildContentProvider(Provider::class.java).create(TvContract.AUTHORITY).get()
        // A poster server that takes connections and never answers.
        val stalled = ServerSocket(0)
        val asked = CountDownLatch(1)
        val held = mutableListOf<Socket>()
        thread(isDaemon = true) {
            while (!stalled.isClosed) {
                runCatching { held += stalled.accept() }
                asked.countDown()
            }
        }
        try {
            val watchNext = assertNotNull(WatchNext.create(context))
            val items = (1..5).map { item("m$it", "http://127.0.0.1:${stalled.localPort}/m$it.jpg") }
            watchNext.publish(HomeScreenShelf("alice", 1, "Continue Watching", items))
            assertTrue(asked.await(5, TimeUnit.SECONDS), "alice's posters are downloading")

            val start = System.nanoTime()
            watchNext.publish(HomeScreenShelf(null, 2, "Continue Watching", emptyList()))
            val written = CountDownLatch(1)
            // Runs on the Watch Next thread after the clear: no row has this id.
            watchNext.removedByUser(-1) { written.countDown() }
            assertTrue(written.await(30, TimeUnit.SECONDS))
            val millis = (System.nanoTime() - start) / 1_000_000

            assertEquals(0, provider.inserts, "alice's rows never reach the home screen")
            assertTrue(millis < 5_000, "the clear landed after $millis ms")
        } finally {
            stalled.close()
            held.forEach { it.close() }
        }
    }
}
