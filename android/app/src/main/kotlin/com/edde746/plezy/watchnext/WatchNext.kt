package com.edde746.plezy.watchnext

import android.content.ContentProviderOperation
import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.database.Cursor
import android.media.tv.TvContract
import android.media.tv.TvContract.WatchNextPrograms
import android.net.Uri
import android.os.Build
import androidx.annotation.RequiresApi
import com.edde746.plezy.PlezyActivity
import com.edde746.plezy.log.Log
import com.edde746.plezy.presentation.homescreen.HomeScreen
import com.edde746.plezy.presentation.homescreen.HomeScreenArtwork
import com.edde746.plezy.presentation.homescreen.HomeScreenShelf
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicLong
import java.util.concurrent.atomic.AtomicReference

/**
 * Android TV's Watch Next row (Google TV's "Continue watching") as the TV's home screen ([HomeScreen]): the active
 * profile's Continue Watching as rows of the system's TV provider ([WatchNextPrograms]) that this app owns.
 *
 * Each publish writes only what changed ([planWatchNext]): a new item goes in, a changed one is updated in place (a
 * saved position touches its one row), an item that left goes out, and every row of another profile goes when the
 * owner changes. A shelf older than the last one written or published ([HomeScreenShelf.generation]) is dropped, also
 * between its poster downloads, so a newer shelf (a sign-out's clear) never waits behind an older one's. An item the user
 * removed from the home screen stays off it until it is watched again: the launcher hides its row
 * ([WatchNextPrograms.COLUMN_BROWSABLE]) or tells this app ([WatchNextRemovedReceiver]), and the removal is kept in
 * this app's preferences. A row opens [PlezyActivity] with `plezy://play?content_id=…` (an explicit intent: the test
 * builds' manifest has no link filters).
 *
 * Posters: the app downloads them ([ShelfArtwork]) and the rows point at its own copies, which the launchers read
 * through per-URI grants; a row whose poster fails keeps the one it had. After a write the grants of posters no row uses
 * any more are taken back and their files deleted. Grants don't survive a reboot or an update, so
 * [WatchNextGrantReceiver] grants the rows' posters again then.
 *
 * The provider's work runs on one background thread; publishes that pile up while it works collapse into the latest.
 */
@RequiresApi(Build.VERSION_CODES.O)
internal class WatchNext private constructor(context: Context) : HomeScreen {
    private val context: Context = context.applicationContext
    private val executor = Executors.newSingleThreadExecutor { Thread(it, "WatchNext") }
    private val pending = AtomicReference<HomeScreenShelf?>(null)
    private val preferences = this.context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
    private val posters = ShelfArtwork(this.context)

    /** The owner and generation of the last shelf written; worker thread only. */
    private var committedOwner: String? = null
    private var committedGeneration = Long.MIN_VALUE

    /** The newest generation published. */
    private val publishedGeneration = AtomicLong(Long.MIN_VALUE)

    override val artwork: HomeScreenArtwork get() = HomeScreenArtwork.LANDSCAPE

    override fun publish(shelf: HomeScreenShelf) {
        publishedGeneration.accumulateAndGet(shelf.generation, ::maxOf)
        if (pending.getAndSet(shelf) == null) executor.execute { pending.getAndSet(null)?.let(::write) }
    }

    /** The launcher reports that the user removed the row [programId]: it goes, and its item stays off the home screen. */
    fun removedByUser(programId: Long, done: () -> Unit) {
        executor.execute {
            try {
                val row = rows()?.firstOrNull { it.id == programId }
                if (row != null) {
                    saveRemoved(removed() + (row.program.key to row.program.lastEngagementMillis))
                    context.contentResolver.delete(programUri(programId), null, null)
                }
            } catch (e: RuntimeException) {
                Log.e(TAG) { "Removing a Watch Next row failed: ${e::class.simpleName}" }
            } finally {
                done()
            }
        }
    }

    /** Grants the launchers read access to the rows' posters again (after a reboot or an update dropped the grants). */
    fun grantAgain(done: () -> Unit) {
        executor.execute {
            try {
                rows()?.mapNotNull { it.program.posterUri }?.let(posters::grant)
            } finally {
                done()
            }
        }
    }

    private fun stale(shelf: HomeScreenShelf): Boolean {
        // Every committed shelf was published, so the newest published generation covers the committed one.
        val stale = shelf.generation < publishedGeneration.get() || (shelf.generation == committedGeneration && shelf.ownerId != committedOwner)
        if (stale) Log.i(TAG) { "Dropping a stale shelf (generation ${shelf.generation})" }
        return stale
    }

    private fun write(shelf: HomeScreenShelf) {
        if (stale(shelf)) return
        val rows = rows() ?: return
        val owner = shelf.ownerId
        val budget = ShelfArtwork.Budget()
        val previousPosters = rows.associate { it.program.key to it.program.posterUri }
        val programs = if (owner == null) {
            emptyList()
        } else {
            shelf.items.map { item ->
                if (stale(shelf)) return
                // A poster that fails keeps the one the row had.
                if (item.posterSource == null) Log.i(TAG) { "${item.contentId} has no poster" }
                val poster = item.posterSource?.let { posters.fetch(owner, it, budget)?.toString() }
                    ?: previousPosters[watchNextKey(owner, item.contentId)]?.takeIf { posters.file(Uri.parse(it))?.isFile == true }
                item.toWatchNextProgram(owner, intentUri(item.playUrl), poster)
            }
        }
        val plan = planWatchNext(owner, programs, rows, removed())
        val deleted = plan.delete.toHashSet()
        val updated = plan.update.toMap()
        val shown = rows.filter { it.id !in deleted }.map { updated[it.id] ?: it.program } + plan.insert
        val shownPosters = shown.mapNotNullTo(HashSet()) { it.posterUri }
        if (stale(shelf)) return
        if (!posters.grant(shownPosters)) Log.w(TAG) { "A Watch Next poster reached no launcher" }

        val operations = ArrayList<ContentProviderOperation>()
        plan.delete.forEach { operations += ContentProviderOperation.newDelete(programUri(it)).build() }
        plan.update.forEach { (id, program) -> operations += ContentProviderOperation.newUpdate(programUri(id)).withValues(program.values()).build() }
        plan.insert.forEach { operations += ContentProviderOperation.newInsert(WatchNextPrograms.CONTENT_URI).withValues(it.values()).build() }
        try {
            if (operations.isNotEmpty()) context.contentResolver.applyBatch(TvContract.AUTHORITY, operations)
            saveRemoved(plan.removed)
            committedOwner = owner
            committedGeneration = shelf.generation
            Log.i(TAG) { "Watch Next: ${shown.size} row(s), ${shownPosters.size} poster(s)" }
        } catch (e: Exception) {
            // The provider refused (a launcher's provider gone, a full disk): the next publish starts from what is there.
            Log.e(TAG) { "Writing the Watch Next rows failed: ${e::class.simpleName}" }
            return
        }
        posters.revoke(previousPosters.values.filterNotNull().filter { it !in shownPosters })
        posters.prune(shownPosters)
    }

    /** This app's rows (the provider shows each app its own), or null when the provider can't be read. */
    private fun rows(): List<PublishedRow>? = try {
        context.contentResolver.query(WatchNextPrograms.CONTENT_URI, COLUMNS, null, null, null)?.use { cursor ->
            buildList { while (cursor.moveToNext()) cursor.row()?.let(::add) }
        }
    } catch (e: RuntimeException) {
        Log.e(TAG) { "Reading the Watch Next rows failed: ${e::class.simpleName}" }
        null
    }

    private fun Cursor.row(): PublishedRow? {
        val contentId = string(WatchNextPrograms.COLUMN_INTERNAL_PROVIDER_ID) ?: return null
        val owner = getColumnIndexOrThrow(WatchNextPrograms.COLUMN_INTERNAL_PROVIDER_DATA).let { if (isNull(it)) null else getBlob(it)?.decodeToString() }
        val program = WatchNextProgram(
            ownerId = owner.orEmpty(),
            contentId = contentId,
            type = int(WatchNextPrograms.COLUMN_TYPE) ?: return null,
            watchNextType = int(WatchNextPrograms.COLUMN_WATCH_NEXT_TYPE) ?: return null,
            title = string(WatchNextPrograms.COLUMN_TITLE) ?: "",
            episodeTitle = string(WatchNextPrograms.COLUMN_EPISODE_TITLE),
            description = string(WatchNextPrograms.COLUMN_SHORT_DESCRIPTION),
            seasonNumber = string(WatchNextPrograms.COLUMN_SEASON_DISPLAY_NUMBER),
            episodeNumber = string(WatchNextPrograms.COLUMN_EPISODE_DISPLAY_NUMBER),
            posterUri = string(WatchNextPrograms.COLUMN_POSTER_ART_URI),
            posterAspectRatio = int(WatchNextPrograms.COLUMN_POSTER_ART_ASPECT_RATIO),
            durationMillis = int(WatchNextPrograms.COLUMN_DURATION_MILLIS) ?: 0,
            lastPlaybackPositionMillis = int(WatchNextPrograms.COLUMN_LAST_PLAYBACK_POSITION_MILLIS) ?: 0,
            lastEngagementMillis = getLong(getColumnIndexOrThrow(WatchNextPrograms.COLUMN_LAST_ENGAGEMENT_TIME_UTC_MILLIS)),
            intentUri = string(WatchNextPrograms.COLUMN_INTENT_URI) ?: "",
        )
        return PublishedRow(getLong(getColumnIndexOrThrow(WatchNextPrograms._ID)), program, int(WatchNextPrograms.COLUMN_BROWSABLE) != 0)
    }

    private fun Cursor.string(column: String): String? = getColumnIndexOrThrow(column).let { if (isNull(it)) null else getString(it) }

    private fun Cursor.int(column: String): Int? = getColumnIndexOrThrow(column).let { if (isNull(it)) null else getInt(it) }

    private fun WatchNextProgram.values() = ContentValues().apply {
        put(WatchNextPrograms.COLUMN_INTERNAL_PROVIDER_ID, contentId)
        put(WatchNextPrograms.COLUMN_INTERNAL_PROVIDER_DATA, ownerId.encodeToByteArray())
        put(WatchNextPrograms.COLUMN_TYPE, type)
        put(WatchNextPrograms.COLUMN_WATCH_NEXT_TYPE, watchNextType)
        put(WatchNextPrograms.COLUMN_TITLE, title)
        put(WatchNextPrograms.COLUMN_EPISODE_TITLE, episodeTitle)
        put(WatchNextPrograms.COLUMN_SHORT_DESCRIPTION, description)
        put(WatchNextPrograms.COLUMN_SEASON_DISPLAY_NUMBER, seasonNumber)
        put(WatchNextPrograms.COLUMN_EPISODE_DISPLAY_NUMBER, episodeNumber)
        put(WatchNextPrograms.COLUMN_POSTER_ART_URI, posterUri)
        put(WatchNextPrograms.COLUMN_POSTER_ART_ASPECT_RATIO, posterAspectRatio)
        put(WatchNextPrograms.COLUMN_DURATION_MILLIS, durationMillis)
        put(WatchNextPrograms.COLUMN_LAST_PLAYBACK_POSITION_MILLIS, lastPlaybackPositionMillis)
        put(WatchNextPrograms.COLUMN_LAST_ENGAGEMENT_TIME_UTC_MILLIS, lastEngagementMillis)
        put(WatchNextPrograms.COLUMN_INTENT_URI, intentUri)
    }

    private fun intentUri(link: String): String =
        Intent(Intent.ACTION_VIEW, Uri.parse(link), context, PlezyActivity::class.java).toUri(Intent.URI_INTENT_SCHEME)

    private fun programUri(id: Long): Uri = ContentUris.withAppendedId(WatchNextPrograms.CONTENT_URI, id)

    /** The user's removals in force: each item's key, with the last engagement it had when it was removed. */
    private fun removed(): Map<String, Long> =
        preferences.getStringSet(REMOVED, emptySet()).orEmpty().associate { it.substringAfter(':') to it.substringBefore(':').toLong() }

    private fun saveRemoved(removed: Map<String, Long>) {
        preferences.edit().putStringSet(REMOVED, removed.mapTo(HashSet()) { (key, at) -> "$at:$key" }).apply()
    }

    companion object {
        private const val TAG = "WatchNext"
        private const val PREFERENCES = "watch_next"
        private const val REMOVED = "removed"
        private val COLUMNS = arrayOf(
            WatchNextPrograms._ID,
            WatchNextPrograms.COLUMN_BROWSABLE,
            WatchNextPrograms.COLUMN_INTERNAL_PROVIDER_ID,
            WatchNextPrograms.COLUMN_INTERNAL_PROVIDER_DATA,
            WatchNextPrograms.COLUMN_TYPE,
            WatchNextPrograms.COLUMN_WATCH_NEXT_TYPE,
            WatchNextPrograms.COLUMN_TITLE,
            WatchNextPrograms.COLUMN_EPISODE_TITLE,
            WatchNextPrograms.COLUMN_SHORT_DESCRIPTION,
            WatchNextPrograms.COLUMN_SEASON_DISPLAY_NUMBER,
            WatchNextPrograms.COLUMN_EPISODE_DISPLAY_NUMBER,
            WatchNextPrograms.COLUMN_POSTER_ART_URI,
            WatchNextPrograms.COLUMN_POSTER_ART_ASPECT_RATIO,
            WatchNextPrograms.COLUMN_DURATION_MILLIS,
            WatchNextPrograms.COLUMN_LAST_PLAYBACK_POSITION_MILLIS,
            WatchNextPrograms.COLUMN_LAST_ENGAGEMENT_TIME_UTC_MILLIS,
            WatchNextPrograms.COLUMN_INTENT_URI,
        )

        /**
         * The Watch Next row on an Android TV; null on phones and tablets, which have none, and on Fire TV: Fire OS's
         * launcher (`com.amazon.tv.launcher`) never reads the Watch Next table (its code names neither the table nor
         * its columns, where Google TV's launcher reads both) and fills its rows from Amazon's own catalog
         * integration, so rows written there would show nowhere. Android 8 and later only: before it there is no Watch
         * Next row.
         */
        fun create(context: Context): WatchNext? {
            val packages = context.packageManager
            if (!packages.hasSystemFeature(PackageManager.FEATURE_LEANBACK) || packages.hasSystemFeature(FIRE_TV)) return null
            return WatchNext(context)
        }

        /** The system feature every Fire TV device declares. */
        private const val FIRE_TV = "amazon.hardware.fire_tv"
    }
}
