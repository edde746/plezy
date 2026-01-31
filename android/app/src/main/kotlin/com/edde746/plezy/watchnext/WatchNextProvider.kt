package com.edde746.plezy.watchnext

import android.content.ContentProviderOperation
import android.content.ContentUris
import android.content.Context
import android.net.Uri
import android.util.Log
import androidx.tvprovider.media.tv.TvContractCompat
import androidx.tvprovider.media.tv.WatchNextProgram

/**
 * Wraps Android TvProvider API for Watch Next row integration.
 * Manages WatchNextProgram entries for Plex "On Deck" content.
 */
class WatchNextProvider(private val context: Context) {

    companion object {
        private const val TAG = "WatchNextProvider"
    }

    data class WatchNextItem(
        val contentId: String,
        val title: String,
        val episodeTitle: String?,
        val description: String?,
        val posterUri: String?,
        val type: Int,
        val duration: Long,
        val lastPlaybackPosition: Long,
        val lastEngagementTime: Long,
        val seriesTitle: String?,
        val seasonNumber: Int?,
        val episodeNumber: Int?
    )

    /**
     * Sync items to Watch Next row.
     * Uses applyBatch to delete + insert in a single transaction so the
     * launcher receives one content-change notification with the full set.
     */
    fun syncWatchNextPrograms(items: List<WatchNextItem>): Boolean {
        return try {
            val ops = ArrayList<ContentProviderOperation>()

            ops.add(
                ContentProviderOperation.newDelete(
                    TvContractCompat.WatchNextPrograms.CONTENT_URI
                ).build()
            )

            for (item in items) {
                val program = buildProgram(item)
                ops.add(
                    ContentProviderOperation.newInsert(
                        TvContractCompat.WatchNextPrograms.CONTENT_URI
                    ).withValues(program.toContentValues()).build()
                )
            }

            context.contentResolver.applyBatch(TvContractCompat.AUTHORITY, ops)
            Log.d(TAG, "Synced ${items.size} Watch Next entries")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to sync Watch Next programs", e)
            false
        }
    }

    fun clearAll(): Boolean {
        return try {
            context.contentResolver.delete(
                TvContractCompat.WatchNextPrograms.CONTENT_URI,
                null,
                null
            )
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to clear Watch Next entries", e)
            false
        }
    }

    fun removeItem(contentId: String): Boolean {
        return try {
            val cursor = context.contentResolver.query(
                TvContractCompat.WatchNextPrograms.CONTENT_URI,
                arrayOf(
                    TvContractCompat.WatchNextPrograms._ID,
                    TvContractCompat.WatchNextPrograms.COLUMN_INTERNAL_PROVIDER_ID
                ),
                null,
                null,
                null
            )

            cursor?.use {
                val idIndex = it.getColumnIndex(TvContractCompat.WatchNextPrograms._ID)
                val providerIdIndex = it.getColumnIndex(TvContractCompat.WatchNextPrograms.COLUMN_INTERNAL_PROVIDER_ID)

                if (idIndex < 0 || providerIdIndex < 0) return false

                while (it.moveToNext()) {
                    if (it.getString(providerIdIndex) == contentId) {
                        val id = it.getLong(idIndex)
                        val deleteUri = ContentUris.withAppendedId(
                            TvContractCompat.WatchNextPrograms.CONTENT_URI,
                            id
                        )
                        context.contentResolver.delete(deleteUri, null, null)
                        return true
                    }
                }
            }
            false
        } catch (e: Exception) {
            Log.e(TAG, "Failed to remove Watch Next item: $contentId", e)
            false
        }
    }

    private fun buildProgram(item: WatchNextItem): WatchNextProgram {
        val watchNextType = if (item.lastPlaybackPosition > 0)
            TvContractCompat.WatchNextPrograms.WATCH_NEXT_TYPE_CONTINUE
        else
            TvContractCompat.WatchNextPrograms.WATCH_NEXT_TYPE_NEXT

        val builder = WatchNextProgram.Builder()
            .setType(item.type)
            .setWatchNextType(watchNextType)
            .setTitle(item.title)
            .setInternalProviderId(item.contentId)
            .setLastEngagementTimeUtcMillis(item.lastEngagementTime)

        item.description?.let { builder.setDescription(it) }

        item.posterUri?.let { uri ->
            try {
                builder.setPosterArtUri(Uri.parse(uri))
                builder.setPosterArtAspectRatio(TvContractCompat.PreviewPrograms.ASPECT_RATIO_16_9)
            } catch (e: Exception) {
                Log.w(TAG, "Failed to parse poster URI: $uri", e)
            }
        }

        if (item.duration > 0) {
            builder.setDurationMillis(item.duration.toInt())
            if (item.lastPlaybackPosition > 0) {
                builder.setLastPlaybackPositionMillis(item.lastPlaybackPosition.toInt())
            }
        }

        if (item.type == TvContractCompat.WatchNextPrograms.TYPE_TV_EPISODE) {
            item.episodeTitle?.let { builder.setEpisodeTitle(it) }
            item.seasonNumber?.let { builder.setSeasonNumber(it) }
            item.episodeNumber?.let { builder.setEpisodeNumber(it) }
        }

        val intentUri = Uri.Builder()
            .scheme("plezy")
            .authority("play")
            .appendQueryParameter("content_id", item.contentId)
            .build()
        builder.setIntentUri(intentUri)

        return builder.build()
    }
}
