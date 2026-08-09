package com.edde746.plezy.watchnext

import android.content.ContentProviderOperation
import android.content.ContentUris
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.database.Cursor
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
  private var leaseHeld = false

  fun acquire(): Lease = acquireIf { true }!!

  fun acquireIf(isActive: () -> Boolean): Lease? = synchronized(operationLock) {
    if (!isActive()) return@synchronized null
    synchronized(lock) {
      token += 1
      claimToken += 1
      currentOwner = ""
      currentGeneration = 0
      leaseHeld = true
      Lease(token)
    }
  }

  fun invalidate(lease: Lease) {
    synchronized(operationLock) {
      synchronized(lock) {
        if (token == lease.token) {
          token += 1
          claimToken += 1
          leaseHeld = false
        }
      }
    }
  }

  /**
   * True while the most recently acquired engine lease has not been
   * invalidated — i.e. a live engine (normally the UI) currently owns the
   * shelf. ShelfRefreshWorker checks this before booting a headless engine.
   */
  fun hasLiveLease(): Boolean = synchronized(lock) { leaseHeld }

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

  private data class CommittedRow(
    val id: Long,
    val contentId: String,
    val posterUri: Uri?
  )

  private val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
  private val artwork = SystemShelfArtworkStore(context.cacheDir)

  internal fun claimOwnership(ownerId: String, generation: Long): SystemShelfLifecycle.Ownership? = lifecycleLease?.let { SystemShelfLifecycle.claim(it, ownerId, generation) }

  /**
   * Whether a prior sync's committed state is still on disk. Cleared rows
   * ([clearAll]) and schema-migration wipes remove the granted-URI key, so
   * this distinguishes "user had a shelf" from "never synced / cleared".
   */
  internal fun hasPersistedShelfState(): Boolean = prefs.contains(GRANTED_URIS)

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
    val session = SystemShelfSyncSession(
      operationOwnership,
      syncDurationMillis
    )

    val previousArtwork = snapshotCommittedArtwork(ownerId) ?: return false
    if (!isOperationActive() || !session.isActive()) return false
    val oldUris = prefs.getStringSet(GRANTED_URIS, emptySet()).orEmpty().mapNotNull(Uri::parse).toSet()
    val oldPackages = storedPackages()
    val oldSchemaVersion = prefs.getInt(SHELF_SCHEMA_VERSION_KEY, 0)
    val preparedArtwork = LinkedHashSet<SystemShelfArtworkStore.Prepared>()
    val preparedBySource = HashMap<String, SystemShelfArtworkStore.Prepared?>()
    try {
      val preparedItems = items.map { item ->
        val source = item.posterSourceUri
        val localArtwork = if (source == null) {
          null
        } else {
          val candidate = if (preparedBySource.containsKey(source)) {
            preparedBySource[source]
          } else {
            artwork.prepare(ownerId, source, session).also { prepared ->
              preparedBySource[source] = prepared
              prepared?.let(preparedArtwork::add)
            }
          }
          candidate?.materialized ?: previousArtwork[item.contentId]
        }
        PreparedWatchNextItem(item, localArtwork?.uri)
      }
      val newUris = preparedItems.mapNotNullTo(LinkedHashSet()) { it.localPosterUri }
      val newPackages = consumerPackages()
      if (!isOperationActive() || !session.isActive()) return false

      return SystemShelfLifecycle.whileCurrent(session.ownership) {
        if (!isOperationActive() || session.isExpired()) return@whileCurrent false
        val publishedFiles = LinkedHashSet<java.io.File>()
        preparedArtwork.forEach { candidate ->
          val publication = artwork.publish(candidate)
          if (publication == null) {
            artwork.delete(publishedFiles)
            return@whileCurrent false
          }
          if (publication.newlyPublished) publishedFiles += publication.materialized.file
        }

        val referencedFiles = LinkedHashSet<java.io.File>()
        preparedItems.forEach { item ->
          val posterUri = item.localPosterUri ?: return@forEach
          val file = artwork.resolveOwned(ownerId, posterUri)
          if (file == null) {
            artwork.delete(publishedFiles)
            return@whileCurrent false
          }
          referencedFiles += file
        }
        if (session.isExpired()) {
          artwork.delete(publishedFiles)
          return@whileCurrent false
        }

        // The provider is not exported, so an ungranted row publishes artwork no launcher can
        // open. Refuse to commit that rather than leave a broken tile on the home screen.
        if (!grantReadAccess(newUris, newPackages)) {
          reconcileReadAccess(newUris, newPackages, oldUris, oldPackages)
          artwork.delete(publishedFiles)
          return@whileCurrent false
        }
        if (session.isExpired()) {
          reconcileReadAccess(newUris, newPackages, oldUris, oldPackages)
          artwork.delete(publishedFiles)
          return@whileCurrent false
        }
        val preferencesCommitted = prefs.edit()
          .putStringSet(GRANTED_URIS, newUris.mapTo(LinkedHashSet(), Uri::toString))
          .putStringSet(GRANTED_PACKAGES, newPackages)
          .putInt(SHELF_SCHEMA_VERSION_KEY, SHELF_SCHEMA_VERSION)
          .commit()
        if (!preferencesCommitted) {
          reconcileReadAccess(newUris, newPackages, oldUris, oldPackages)
          artwork.delete(publishedFiles)
          return@whileCurrent false
        }
        if (session.isExpired() || !replaceRows(preparedItems)) {
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
          artwork.delete(publishedFiles)
          return@whileCurrent false
        }

        reconcileReadAccess(oldUris, oldPackages, newUris, newPackages)
        artwork.deleteExcept(referencedFiles)
        true
      } ?: false
    } finally {
      artwork.discard(preparedArtwork)
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

  private fun snapshotCommittedArtwork(
    ownerId: String
  ): Map<String, SystemShelfArtworkStore.Materialized>? {
    val rows = queryCommittedRows() ?: return null
    val snapshot = LinkedHashMap<String, SystemShelfArtworkStore.Materialized>()
    rows.forEach { row ->
      val uri = row.posterUri ?: return@forEach
      val file = artwork.resolveOwned(ownerId, uri) ?: return@forEach
      if (row.contentId !in snapshot) {
        snapshot[row.contentId] = SystemShelfArtworkStore.Materialized(uri, file)
      }
    }
    return snapshot
  }

  private fun queryCommittedRows(): List<CommittedRow>? {
    return try {
      val cursor = context.contentResolver.query(
        TvContractCompat.WatchNextPrograms.CONTENT_URI,
        arrayOf(
          TvContractCompat.WatchNextPrograms._ID,
          TvContractCompat.WatchNextPrograms.COLUMN_INTERNAL_PROVIDER_ID,
          TvContractCompat.WatchNextPrograms.COLUMN_INTERNAL_PROVIDER_DATA,
          TvContractCompat.WatchNextPrograms.COLUMN_INTENT_URI,
          TvContractCompat.PreviewPrograms.COLUMN_POSTER_ART_URI
        ),
        null,
        null,
        null
      ) ?: return null
      cursor.use {
        val idIndex = it.getColumnIndex(TvContractCompat.WatchNextPrograms._ID)
        val providerIdIndex = it.getColumnIndex(
          TvContractCompat.WatchNextPrograms.COLUMN_INTERNAL_PROVIDER_ID
        )
        val providerDataIndex = it.getColumnIndex(
          TvContractCompat.WatchNextPrograms.COLUMN_INTERNAL_PROVIDER_DATA
        )
        val intentIndex = it.getColumnIndex(
          TvContractCompat.WatchNextPrograms.COLUMN_INTENT_URI
        )
        val posterIndex = it.getColumnIndex(TvContractCompat.PreviewPrograms.COLUMN_POSTER_ART_URI)
        if (
          idIndex < 0 ||
          posterIndex < 0 ||
          providerIdIndex < 0 &&
          providerDataIndex < 0 &&
          intentIndex < 0
        ) {
          return null
        }
        val rows = ArrayList<CommittedRow>(it.count)
        while (it.moveToNext()) {
          val providerId = cursorString(it, providerIdIndex)
            ?.takeIf(String::isNotBlank)
          val providerData = cursorString(it, providerDataIndex)
            ?.takeIf(String::isNotBlank)
          val contentId = providerId
            ?: providerData
            ?: contentIdFromIntent(cursorString(it, intentIndex))
            ?: continue
          val posterUri = it.getString(posterIndex)
            ?.takeIf(String::isNotBlank)
            ?.let(Uri::parse)
          rows += CommittedRow(it.getLong(idIndex), contentId, posterUri)
        }
        rows
      }
    } catch (_: Exception) {
      Log.e(TAG, "Failed to query committed Watch Next programs")
      null
    }
  }

  private fun cursorString(cursor: Cursor, index: Int): String? {
    if (index < 0 || cursor.isNull(index)) return null
    return if (cursor.getType(index) == Cursor.FIELD_TYPE_BLOB) {
      cursor.getBlob(index)?.toString(Charsets.UTF_8)
    } else {
      cursor.getString(index)
    }
  }

  private fun contentIdFromIntent(value: String?): String? {
    val uri = value?.let { runCatching { Uri.parse(it) }.getOrNull() } ?: return null
    if (uri.scheme != "plezy" || uri.authority != "play") return null
    return uri.getQueryParameter("content_id")?.takeIf(String::isNotBlank)
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
      removeItemOwned(ownerId, contentId)
    } ?: false
  }

  private fun removeItemOwned(ownerId: String, contentId: String): Boolean {
    return try {
      val rows = queryCommittedRows() ?: return false
      val target = rows.firstOrNull { it.contentId == contentId } ?: return false
      val deleteUri = ContentUris.withAppendedId(
        TvContractCompat.WatchNextPrograms.CONTENT_URI,
        target.id
      )
      if (context.contentResolver.delete(deleteUri, null, null) <= 0) return false

      val poster = target.posterUri ?: return true
      if (rows.any { it.id != target.id && it.posterUri == poster }) return true
      revokeReadAccess(setOf(poster))
      val remaining = prefs.getStringSet(GRANTED_URIS, emptySet()).orEmpty() - poster.toString()
      prefs.edit().putStringSet(GRANTED_URIS, remaining).commit()
      artwork.resolveOwned(ownerId, poster)?.let { artwork.delete(setOf(it)) }
      true
    } catch (_: Exception) {
      Log.e(TAG, "Failed to remove Watch Next item")
      false
    }
  }

  private fun replaceRows(items: List<PreparedWatchNextItem>): Boolean = try {
    val operations = ArrayList<ContentProviderOperation>(items.size + 1)
    operations += ContentProviderOperation.newDelete(TvContractCompat.WatchNextPrograms.CONTENT_URI).build()
    items.forEach { item ->
      val values = buildProgram(item).toContentValues().apply {
        put(
          TvContractCompat.WatchNextPrograms.COLUMN_INTERNAL_PROVIDER_DATA,
          item.metadata.contentId.toByteArray(Charsets.UTF_8)
        )
      }
      operations += ContentProviderOperation.newInsert(TvContractCompat.WatchNextPrograms.CONTENT_URI)
        .withValues(values)
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

  /**
   * Every installed launcher, not just the resolved default. `MATCH_DEFAULT_ONLY` names one
   * package, which is wrong wherever the launcher rendering the shelf is not the system's default
   * HOME: Fire OS pins its own launcher, and a device with several launchers and no chosen default
   * resolves to the resolver activity instead. Both cases left the real consumer without a grant.
   */
  internal fun consumerPackages(): Set<String> {
    val homeIntent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
    return context.packageManager
      .queryIntentActivities(homeIntent, PackageManager.MATCH_ALL)
      .mapNotNullTo(LinkedHashSet()) { candidate ->
        candidate.activityInfo?.packageName?.takeIf(String::isNotBlank)
      }
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
    grantReadAccess(currentUris, currentPackages)
  }

  /**
   * Grants read access and reports whether every poster reached at least one consumer. Losing one
   * launcher is tolerated, because consumers are discovered per sync and one of them disappearing
   * mid-sync must not cost the others their shelf. A poster that reached nobody would render as a
   * broken tile, so it fails the sync instead.
   */
  private fun grantReadAccess(uris: Set<Uri>, packages: Set<String>): Boolean {
    if (uris.isEmpty() || packages.isEmpty()) return true
    val flags = Intent.FLAG_GRANT_READ_URI_PERMISSION
    var failed = 0
    var unreadable = 0
    uris.forEach { uri ->
      var granted = 0
      packages.forEach { packageName ->
        if (runCatching { context.grantUriPermission(packageName, uri, flags) }.isSuccess) {
          granted++
        } else {
          failed++
        }
      }
      if (granted == 0) unreadable++
    }
    if (failed > 0) {
      Log.w(
        TAG,
        "Failed to grant $failed of ${uris.size * packages.size} shelf artwork reads; " +
          "$unreadable of ${uris.size} posters reached no launcher"
      )
    }
    return unreadable == 0
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
