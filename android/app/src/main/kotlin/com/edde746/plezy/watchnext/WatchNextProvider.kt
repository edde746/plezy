package com.edde746.plezy.watchnext

import android.content.ContentProviderOperation
import android.content.ContentUris
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.util.Log
import androidx.tvprovider.media.tv.TvContractCompat
import androidx.tvprovider.media.tv.WatchNextProgram

/** Owns Plezy's durable Android TV Watch Next rows and their local artwork. */
class WatchNextProvider(private val context: Context) {
  companion object {
    private const val TAG = "WatchNextProvider"
    private const val PREFS = "system_shelf_state"
    private const val GRANTED_URIS = "granted_uris"
  }

  data class WatchNextItem(
    val contentId: String,
    val title: String,
    val episodeTitle: String?,
    val description: String?,
    val posterSourceUri: String?,
    val type: Int,
    val duration: Long,
    val lastPlaybackPosition: Long,
    val lastEngagementTime: Long,
    val seriesTitle: String?,
    val seasonNumber: Int?,
    val episodeNumber: Int?
  )

  internal data class PreparedWatchNextItem(val metadata: WatchNextItem, val localPosterUri: Uri?)

  private val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
  private val artwork = SystemShelfArtworkStore(context.cacheDir)
  private var currentOwner = ""
  private var currentGeneration = 0L

  /** Materializes transient art, then atomically replaces the durable rows. */
  fun syncWatchNextPrograms(ownerId: String, generation: Long, items: List<WatchNextItem>): Boolean {
    if (!accepts(ownerId, generation) || items.size > SystemShelfArtworkStore.MAX_ITEMS) return false

    val oldUris = prefs.getStringSet(GRANTED_URIS, emptySet()).orEmpty().mapNotNull(Uri::parse).toSet()
    val oldFiles = oldUris.mapNotNullTo(HashSet()) { artwork.resolve(it) }
    val budget = SystemShelfArtworkStore.Budget()
    val prepared = items.map { item ->
      val materialized = item.posterSourceUri?.let { artwork.materialize(ownerId, it, budget) }
      PreparedWatchNextItem(item, materialized?.uri)
    }
    if (!accepts(ownerId, generation)) {
      artwork.deleteExcept(oldFiles)
      return false
    }

    val newUris = prepared.mapNotNullTo(LinkedHashSet()) { it.localPosterUri }
    grantReadAccess(newUris)
    val committed = replaceRows(prepared)
    if (!committed) {
      revokeReadAccess(newUris - oldUris)
      artwork.deleteExcept(oldFiles)
      return false
    }

    prefs.edit()
      .putStringSet(GRANTED_URIS, newUris.mapTo(LinkedHashSet(), Uri::toString))
      .commit()
    currentOwner = ownerId
    currentGeneration = generation
    revokeReadAccess(oldUris - newUris)
    artwork.deleteExcept(prepared.mapNotNullTo(HashSet()) { it.localPosterUri?.let(artwork::resolve) })
    return true
  }

  /** Deletes rows first, then grants, then owned files. */
  fun clearAll(ownerId: String, generation: Long): Boolean {
    if (!acceptsClear(ownerId, generation)) return false
    val rowsCleared = deleteRows()
    if (!rowsCleared) return false
    val uris = prefs.getStringSet(GRANTED_URIS, emptySet()).orEmpty().mapNotNull(Uri::parse).toSet()
    revokeReadAccess(uris)
    artwork.deleteAll()
    prefs.edit().remove(GRANTED_URIS).commit()
    currentOwner = ""
    currentGeneration = generation
    return true
  }

  /** Package replacement is a clean cutover: remote legacy rows cannot survive. */
  fun clearLegacyOnPackageUpdate(): Boolean {
    val rowsCleared = deleteRows()
    val uris = prefs.getStringSet(GRANTED_URIS, emptySet()).orEmpty().mapNotNull(Uri::parse).toSet()
    revokeReadAccess(uris)
    artwork.deleteAll()
    prefs.edit().clear().commit()
    currentOwner = ""
    currentGeneration = 0
    return rowsCleared
  }

  fun removeItem(ownerId: String, generation: Long, contentId: String): Boolean {
    if (!accepts(ownerId, generation)) return false
    return try {
      val cursor = context.contentResolver.query(
        TvContractCompat.WatchNextPrograms.CONTENT_URI,
        arrayOf(
          TvContractCompat.WatchNextPrograms._ID,
          TvContractCompat.WatchNextPrograms.COLUMN_INTERNAL_PROVIDER_ID,
          TvContractCompat.PreviewPrograms.COLUMN_POSTER_ART_URI
        ),
        null,
        null,
        null
      )
      cursor?.use {
        val idIndex = it.getColumnIndex(TvContractCompat.WatchNextPrograms._ID)
        val providerIdIndex = it.getColumnIndex(TvContractCompat.WatchNextPrograms.COLUMN_INTERNAL_PROVIDER_ID)
        val posterIndex = it.getColumnIndex(TvContractCompat.PreviewPrograms.COLUMN_POSTER_ART_URI)
        if (idIndex < 0 || providerIdIndex < 0) return false
        while (it.moveToNext()) {
          if (it.getString(providerIdIndex) == contentId) {
            val deleteUri = ContentUris.withAppendedId(TvContractCompat.WatchNextPrograms.CONTENT_URI, it.getLong(idIndex))
            context.contentResolver.delete(deleteUri, null, null)
            if (posterIndex >= 0) {
              val poster = it.getString(posterIndex)?.let(Uri::parse)
              if (poster != null) {
                revokeReadAccess(setOf(poster))
                artwork.resolve(poster)?.delete()
                val remaining = prefs.getStringSet(GRANTED_URIS, emptySet()).orEmpty() - poster.toString()
                prefs.edit().putStringSet(GRANTED_URIS, remaining).commit()
              }
            }
            return true
          }
        }
      }
      false
    } catch (_: Exception) {
      Log.e(TAG, "Failed to remove Watch Next item")
      false
    }
  }

  private fun accepts(ownerId: String, generation: Long): Boolean {
    if (ownerId.isBlank() || generation <= 0) return false
    return generation > currentGeneration || generation == currentGeneration && currentOwner == ownerId
  }

  private fun acceptsClear(ownerId: String, generation: Long): Boolean {
    if (ownerId.isBlank() || generation <= 0 || generation < currentGeneration) return false
    return generation > currentGeneration || currentOwner.isEmpty() || currentOwner == ownerId
  }

  private fun replaceRows(items: List<PreparedWatchNextItem>): Boolean = try {
    val operations = ArrayList<ContentProviderOperation>(items.size + 1)
    operations += ContentProviderOperation.newDelete(TvContractCompat.WatchNextPrograms.CONTENT_URI).build()
    items.forEach { item ->
      operations += ContentProviderOperation.newInsert(TvContractCompat.WatchNextPrograms.CONTENT_URI)
        .withValues(buildProgram(item).toContentValues())
        .build()
    }
    context.contentResolver.applyBatch(TvContractCompat.AUTHORITY, operations)
    true
  } catch (_: Exception) {
    Log.e(TAG, "Failed to sync Watch Next programs")
    false
  }

  private fun deleteRows(): Boolean = try {
    context.contentResolver.delete(TvContractCompat.WatchNextPrograms.CONTENT_URI, null, null)
    true
  } catch (_: Exception) {
    Log.e(TAG, "Failed to clear Watch Next entries")
    false
  }

  private fun consumerPackages(): Set<String> {
    val packages = LinkedHashSet<String>()
    context.packageManager.resolveContentProvider(TvContractCompat.AUTHORITY, PackageManager.MATCH_ALL)?.packageName
      ?.let(packages::add)
    val launcherIntent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LEANBACK_LAUNCHER)
    context.packageManager.queryIntentActivities(launcherIntent, PackageManager.MATCH_ALL)
      .mapTo(packages) { it.activityInfo.packageName }
    return packages
  }

  private fun grantReadAccess(uris: Set<Uri>) {
    val flags = Intent.FLAG_GRANT_READ_URI_PERMISSION
    consumerPackages().forEach { packageName ->
      uris.forEach { uri ->
        runCatching { context.grantUriPermission(packageName, uri, flags) }
      }
    }
  }

  private fun revokeReadAccess(uris: Set<Uri>) {
    val flags = Intent.FLAG_GRANT_READ_URI_PERMISSION
    uris.forEach { uri -> runCatching { context.revokeUriPermission(uri, flags) } }
  }

  internal fun buildProgram(item: PreparedWatchNextItem): WatchNextProgram {
    val metadata = item.metadata
    val watchNextType = if (metadata.lastPlaybackPosition > 0) {
      TvContractCompat.WatchNextPrograms.WATCH_NEXT_TYPE_CONTINUE
    } else {
      TvContractCompat.WatchNextPrograms.WATCH_NEXT_TYPE_NEXT
    }
    val builder = WatchNextProgram.Builder()
      .setType(metadata.type)
      .setWatchNextType(watchNextType)
      .setTitle(metadata.title)
      .setInternalProviderId(metadata.contentId)
      .setLastEngagementTimeUtcMillis(metadata.lastEngagementTime)

    metadata.description?.let(builder::setDescription)
    item.localPosterUri?.let { uri ->
      builder.setPosterArtUri(uri)
      builder.setPosterArtAspectRatio(TvContractCompat.PreviewPrograms.ASPECT_RATIO_16_9)
    }
    if (metadata.duration > 0) {
      builder.setDurationMillis(metadata.duration.coerceAtMost(Int.MAX_VALUE.toLong()).toInt())
      if (metadata.lastPlaybackPosition > 0) {
        builder.setLastPlaybackPositionMillis(metadata.lastPlaybackPosition.coerceAtMost(Int.MAX_VALUE.toLong()).toInt())
      }
    }
    if (metadata.type == TvContractCompat.WatchNextPrograms.TYPE_TV_EPISODE) {
      metadata.episodeTitle?.let(builder::setEpisodeTitle)
      metadata.seasonNumber?.let(builder::setSeasonNumber)
      metadata.episodeNumber?.let(builder::setEpisodeNumber)
    }
    builder.setIntentUri(
      Uri.Builder().scheme("plezy").authority("play")
        .appendQueryParameter("content_id", metadata.contentId).build()
    )
    return builder.build()
  }
}
