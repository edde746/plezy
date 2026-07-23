package com.edde746.plezy.watchnext

import android.content.ContentProviderOperation
import android.content.ContentUris
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.util.Log
import androidx.tvprovider.media.tv.TvContractCompat
import androidx.tvprovider.media.tv.WatchNextProgram

internal object SystemShelfLifecycle {
  data class Lease internal constructor(internal val token: Long)
  data class Ownership internal constructor(
    internal val engineToken: Long,
    internal val claimToken: Long
  )

  private val lock = Any()
  private val operationLock = Any()
  private var token = 0L
  private var claimToken = 0L
  private var currentOwner = ""
  private var currentGeneration = 0L

  fun acquire(): Lease = acquireIf { true }!!

  fun acquireIf(isActive: () -> Boolean): Lease? = synchronized(operationLock) {
    if (!isActive()) return@synchronized null
    synchronized(lock) {
      token += 1
      claimToken += 1
      currentOwner = ""
      currentGeneration = 0
      Lease(token)
    }
  }

  fun invalidate(lease: Lease) {
    synchronized(operationLock) {
      synchronized(lock) {
        if (token == lease.token) {
          token += 1
          claimToken += 1
        }
      }
    }
  }

  fun claim(lease: Lease, ownerId: String, generation: Long): Ownership? = synchronized(operationLock) {
    synchronized(lock) {
      if (
        token != lease.token ||
        ownerId.isBlank() ||
        generation <= 0 ||
        generation < currentGeneration ||
        generation == currentGeneration &&
        currentOwner.isNotEmpty() &&
        currentOwner != ownerId
      ) {
        null
      } else {
        currentOwner = ownerId
        currentGeneration = generation
        claimToken += 1
        Ownership(token, claimToken)
      }
    }
  }

  fun isCurrent(ownership: Ownership): Boolean = synchronized(lock) {
    token == ownership.engineToken && claimToken == ownership.claimToken
  }

  fun <T> whileCurrent(ownership: Ownership, block: () -> T): T? = synchronized(operationLock) {
    if (!isCurrent(ownership)) return@synchronized null
    val result = block()
    if (isCurrent(ownership)) result else null
  }

  fun <T> exclusive(block: () -> T): T = synchronized(operationLock, block)
}

/** Owns Plezy's durable Android TV Watch Next rows and their local artwork. */
class WatchNextProvider internal constructor(
  private val context: Context,
  private val lifecycleLease: SystemShelfLifecycle.Lease?,
  private val syncDurationMillis: Long = SystemShelfArtworkStore.MAX_SYNC_DURATION_MS
) {
  constructor(context: Context) : this(context, SystemShelfLifecycle.acquire())
  companion object {
    private const val TAG = "WatchNextProvider"
    private const val PREFS = "system_shelf_state"
    private const val GRANTED_URIS = "granted_uris"
    private const val GRANTED_PACKAGES = "granted_packages"
    internal const val SHELF_SCHEMA_VERSION = 1
    private const val SHELF_SCHEMA_VERSION_KEY = "shelf_schema_version"

    internal fun forMaintenance(context: Context) = WatchNextProvider(context, null)
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

  internal fun claimOwnership(ownerId: String, generation: Long): SystemShelfLifecycle.Ownership? = lifecycleLease?.let { SystemShelfLifecycle.claim(it, ownerId, generation) }

  internal fun syncWatchNextPrograms(
    ownerId: String,
    generation: Long,
    items: List<WatchNextItem>,
    ownership: SystemShelfLifecycle.Ownership? = null,
    isOperationActive: () -> Boolean = { true }
  ): Boolean {
    if (items.size > SystemShelfArtworkStore.MAX_ITEMS) return false
    val operationOwnership = ownership ?: claimOwnership(ownerId, generation) ?: return false
    if (!isOperationActive()) return false

    val oldUris = prefs.getStringSet(GRANTED_URIS, emptySet()).orEmpty().mapNotNull(Uri::parse).toSet()
    val oldPackages = storedPackages()
    val oldSchemaVersion = prefs.getInt(SHELF_SCHEMA_VERSION_KEY, 0)
    val session = SystemShelfSyncSession(
      operationOwnership,
      syncDurationMillis
    )
    val materializedFiles = LinkedHashSet<java.io.File>()
    var committed = false
    try {
      val prepared = items.map { item ->
        if (!isOperationActive() || !session.isActive()) {
          PreparedWatchNextItem(item, null)
        } else {
          val materialized = item.posterSourceUri?.let { artwork.materialize(ownerId, it, session) }
          materialized?.file?.let(materializedFiles::add)
          PreparedWatchNextItem(item, materialized?.uri)
        }
      }
      val newUris = prepared.mapNotNullTo(LinkedHashSet()) { it.localPosterUri }
      val newPackages = consumerPackages()
      if (!isOperationActive() || !session.isActive()) return false
      committed = SystemShelfLifecycle.whileCurrent(session.ownership) {
        if (!isOperationActive() || session.isExpired()) return@whileCurrent false
        reconcileReadAccess(oldUris, oldPackages, newUris, newPackages)
        if (session.isExpired()) {
          reconcileReadAccess(newUris, newPackages, oldUris, oldPackages)
          return@whileCurrent false
        }
        val preferencesCommitted = prefs.edit()
          .putStringSet(GRANTED_URIS, newUris.mapTo(LinkedHashSet(), Uri::toString))
          .putStringSet(GRANTED_PACKAGES, newPackages)
          .putInt(SHELF_SCHEMA_VERSION_KEY, SHELF_SCHEMA_VERSION)
          .commit()
        if (!preferencesCommitted) {
          reconcileReadAccess(newUris, newPackages, oldUris, oldPackages)
          return@whileCurrent false
        }
        if (session.isExpired() || !replaceRows(prepared)) {
          val rollback = prefs.edit()
            .putStringSet(GRANTED_URIS, oldUris.mapTo(LinkedHashSet(), Uri::toString))
            .putStringSet(GRANTED_PACKAGES, oldPackages)
          if (oldSchemaVersion > 0) {
            rollback.putInt(SHELF_SCHEMA_VERSION_KEY, oldSchemaVersion)
          } else {
            rollback.remove(SHELF_SCHEMA_VERSION_KEY)
          }
          rollback.commit()
          reconcileReadAccess(newUris, newPackages, oldUris, oldPackages)
          return@whileCurrent false
        }

        artwork.deleteExcept(materializedFiles)
        true
      } ?: false
      return committed
    } finally {
      if (!committed) {
        materializedFiles.forEach { it.delete() }
      }
    }
  }

  /** Deletes rows first, then revokes grants and owned files. */
  internal fun clearAll(
    ownerId: String,
    generation: Long,
    ownership: SystemShelfLifecycle.Ownership? = null,
    isOperationActive: () -> Boolean = { true }
  ): Boolean {
    val operationOwnership = ownership ?: claimOwnership(ownerId, generation) ?: return false
    return SystemShelfLifecycle.whileCurrent(operationOwnership) {
      if (!isOperationActive()) return@whileCurrent false
      val rowsCleared = deleteRows()
      if (!rowsCleared) return@whileCurrent false
      val uris = storedUris()
      val packages = storedPackages()
      reconcileReadAccess(uris, packages, emptySet(), emptySet())
      artwork.deleteAll()
      prefs.edit()
        .remove(GRANTED_URIS)
        .remove(GRANTED_PACKAGES)
        .putInt(SHELF_SCHEMA_VERSION_KEY, SHELF_SCHEMA_VERSION)
        .commit()
      true
    } ?: false
  }

  /** Removes only data from a shelf schema older than the current on-device contract. */
  fun migrateShelfSchema(): Boolean = SystemShelfLifecycle.exclusive {
    if (prefs.getInt(SHELF_SCHEMA_VERSION_KEY, 0) >= SHELF_SCHEMA_VERSION) {
      return@exclusive restoreReadGrantsOwned()
    }
    val rowsCleared = deleteRows()
    if (!rowsCleared) return@exclusive false
    val uris = storedUris()
    val packages = storedPackages()
    reconcileReadAccess(uris, packages, emptySet(), emptySet())
    artwork.deleteAll()
    prefs.edit()
      .clear()
      .putInt(SHELF_SCHEMA_VERSION_KEY, SHELF_SCHEMA_VERSION)
      .commit()
  }

  /** Re-establishes reboot-volatile grants only for persisted, confined artwork files. */
  fun restoreReadGrants(): Boolean = SystemShelfLifecycle.exclusive {
    restoreReadGrantsOwned()
  }

  private fun restoreReadGrantsOwned(): Boolean {
    val previousUris = storedUris()
    val previousPackages = storedPackages()
    val validUris = previousUris.filterTo(LinkedHashSet()) { artwork.resolve(it) != null }
    val currentPackages = consumerPackages()
    reconcileReadAccess(previousUris, previousPackages, validUris, currentPackages)
    return prefs.edit()
      .putStringSet(GRANTED_URIS, validUris.mapTo(LinkedHashSet(), Uri::toString))
      .putStringSet(GRANTED_PACKAGES, currentPackages)
      .commit()
  }

  internal fun removeItem(
    ownerId: String,
    generation: Long,
    contentId: String,
    ownership: SystemShelfLifecycle.Ownership? = null,
    isOperationActive: () -> Boolean = { true }
  ): Boolean {
    val operationOwnership = ownership ?: claimOwnership(ownerId, generation) ?: return false
    return SystemShelfLifecycle.whileCurrent(operationOwnership) {
      if (!isOperationActive()) return@whileCurrent false
      removeItemOwned(contentId)
    } ?: false
  }

  private fun removeItemOwned(contentId: String): Boolean {
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

  internal fun consumerPackages(): Set<String> {
    val homeIntent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
    val packageManager = context.packageManager
    val selectedHome = packageManager.resolveActivity(homeIntent, PackageManager.MATCH_DEFAULT_ONLY)
      ?.activityInfo ?: return emptySet()
    val packageName = selectedHome.packageName?.takeIf(String::isNotBlank) ?: return emptySet()
    val activityName = selectedHome.name?.takeIf(String::isNotBlank) ?: return emptySet()
    val isHomeHandler = packageManager.queryIntentActivities(homeIntent, PackageManager.MATCH_ALL).any { candidate ->
      candidate.activityInfo?.let { it.packageName == packageName && it.name == activityName } == true
    }
    return if (isHomeHandler) setOf(packageName) else emptySet()
  }

  private fun reconcileReadAccess(
    previousUris: Set<Uri>,
    previousPackages: Set<String>,
    currentUris: Set<Uri>,
    currentPackages: Set<String>
  ) {
    val flags = Intent.FLAG_GRANT_READ_URI_PERMISSION
    if (previousPackages.isEmpty() && previousUris.isNotEmpty()) {
      previousUris.forEach { uri -> runCatching { context.revokeUriPermission(uri, flags) } }
    } else {
      previousPackages.forEach { packageName ->
        previousUris.forEach { uri ->
          if (packageName !in currentPackages || uri !in currentUris) {
            revokeReadAccess(packageName, uri, flags)
          }
        }
      }
    }
    currentPackages.forEach { packageName ->
      currentUris.forEach { uri ->
        runCatching { context.grantUriPermission(packageName, uri, flags) }
      }
    }
  }

  private fun revokeReadAccess(uris: Set<Uri>) {
    val flags = Intent.FLAG_GRANT_READ_URI_PERMISSION
    val packages = storedPackages()
    if (packages.isEmpty()) {
      uris.forEach { uri -> runCatching { context.revokeUriPermission(uri, flags) } }
      return
    }
    packages.forEach { packageName ->
      uris.forEach { uri -> revokeReadAccess(packageName, uri, flags) }
    }
  }

  private fun revokeReadAccess(packageName: String, uri: Uri, flags: Int) {
    runCatching {
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        context.revokeUriPermission(packageName, uri, flags)
      } else {
        context.revokeUriPermission(uri, flags)
      }
    }
  }

  private fun storedUris(): Set<Uri> = prefs.getStringSet(GRANTED_URIS, emptySet()).orEmpty().mapNotNullTo(LinkedHashSet(), Uri::parse)

  private fun storedPackages(): Set<String> = prefs.getStringSet(GRANTED_PACKAGES, emptySet()).orEmpty()

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
