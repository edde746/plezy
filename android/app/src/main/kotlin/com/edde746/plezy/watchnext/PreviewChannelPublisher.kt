package com.edde746.plezy.watchnext

import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.net.Uri
import android.util.Log
import androidx.tvprovider.media.tv.PreviewChannel
import androidx.tvprovider.media.tv.PreviewChannelHelper
import androidx.tvprovider.media.tv.PreviewProgram
import androidx.tvprovider.media.tv.TvContractCompat
import java.io.File

/**
 * Publishes Android TV Preview Channels (Recently Added / New Releases) that
 * Projectivy and other launchers surface as browsable rows. Artwork reuses
 * [SystemShelfArtworkStore]; URI grants are unioned with Watch Next via
 * [SystemShelfUriLedger] so neither surface revokes the other's posters.
 */
internal class PreviewChannelPublisher(
  private val context: Context,
  private val lifecycleLease: SystemShelfLifecycle.Lease?,
  private val syncDurationMillis: Long = SystemShelfArtworkStore.MAX_CHANNEL_SYNC_DURATION_MS
) {
  companion object {
    private const val TAG = "PreviewChannelPublisher"
    internal const val CHANNEL_RECENTLY_ADDED_MOVIES = "recently_added_movies"
    internal const val CHANNEL_RECENTLY_ADDED_TV = "recently_added_tv"
    internal const val CHANNEL_NEW_RELEASES_MOVIES = "new_releases_movies"
    internal const val CHANNEL_NEW_RELEASES_TV = "new_releases_tv"
    internal const val CHANNEL_LIVE_TV = "live_tv"

    /** Pre-split mixed rows — deleted when a split channel publishes. */
    private val LEGACY_CHANNELS = listOf("recently_added", "new_releases")
    private val ACTIVE_CHANNELS = listOf(
      CHANNEL_RECENTLY_ADDED_MOVIES,
      CHANNEL_RECENTLY_ADDED_TV,
      CHANNEL_NEW_RELEASES_MOVIES,
      CHANNEL_NEW_RELEASES_TV,
      CHANNEL_LIVE_TV
    )
    private val KNOWN_CHANNELS = ACTIVE_CHANNELS + LEGACY_CHANNELS

    /** Artwork files currently referenced by preview-channel programs. */
    fun referencedArtworkFiles(context: Context, artwork: SystemShelfArtworkStore): Set<File> = SystemShelfUriLedger(context).channelUris().mapNotNullTo(LinkedHashSet()) { artwork.resolve(it) }

    /** Union of intended grants and posters still visible to launchers. */
    internal fun mergeGrantUris(intended: Set<Uri>, livePublished: Set<Uri>): Set<Uri> = mergeGrantSets(intended, livePublished)

    /** Package-visible for JVM unit tests that cannot construct [Uri] stubs. */
    internal fun <T> mergeGrantSets(intended: Set<T>, livePublished: Set<T>): Set<T> = LinkedHashSet<T>(intended.size + livePublished.size).apply {
      addAll(intended)
      addAll(livePublished)
    }
  }

  data class ChannelItem(
    val contentId: String,
    val title: String,
    val episodeTitle: String?,
    val description: String?,
    val posterSourceUri: String?,
    val type: Int,
    val duration: Long,
    val seriesTitle: String?,
    val seasonNumber: Int?,
    val episodeNumber: Int?,
    /** Higher weight sorts earlier in the channel (launcher-dependent). */
    val weight: Int,
    /** Optional deep link; defaults to `plezy://play?content_id=...`. */
    val intentUri: String? = null
  )

  private data class PreparedChannelItem(val metadata: ChannelItem, val localPosterUri: Uri?)

  private val ledger = SystemShelfUriLedger(context)
  private val artwork = SystemShelfArtworkStore(context.cacheDir)
  private val helper = PreviewChannelHelper(context)

  internal fun claimOwnership(ownerId: String, generation: Long): SystemShelfLifecycle.Ownership? = lifecycleLease?.let { SystemShelfLifecycle.claim(it, ownerId, generation) }

  internal fun syncChannel(
    ownerId: String,
    generation: Long,
    channelKey: String,
    channelTitle: String,
    items: List<ChannelItem>,
    ownership: SystemShelfLifecycle.Ownership? = null,
    isOperationActive: () -> Boolean = { true }
  ): Boolean {
    if (channelKey !in ACTIVE_CHANNELS) return false
    if (items.size > SystemShelfArtworkStore.MAX_ITEMS) return false
    val operationOwnership = ownership ?: claimOwnership(ownerId, generation) ?: return false
    if (!isOperationActive()) return false
    purgeLegacyChannelsUnlocked()
    val session = SystemShelfSyncSession(
      operationOwnership,
      syncDurationMillis,
      budget = SystemShelfArtworkStore.Budget(SystemShelfArtworkStore.MAX_CHANNEL_SYNC_BYTES)
    )

    val oldUnion = ledger.grantedUris()
    val oldPackages = ledger.grantedPackages()
    val previousChannelUris = ledger.channelUris()
    val preparedArtwork = LinkedHashSet<SystemShelfArtworkStore.Prepared>()
    val preparedBySource = HashMap<String, SystemShelfArtworkStore.Prepared?>()

    try {
      val preparedItems = items.map { item ->
        val source = item.posterSourceUri
        val local = if (source == null) {
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
          candidate?.materialized
        }
        PreparedChannelItem(item, local?.uri)
      }
      if (!isOperationActive() || !session.isActive()) return false

      return SystemShelfLifecycle.whileCurrent(session.ownership) {
        if (!isOperationActive() || session.isExpired()) return@whileCurrent false

        val publishedFiles = LinkedHashSet<File>()
        preparedArtwork.forEach { candidate ->
          val publication = artwork.publish(candidate)
          if (publication == null) {
            artwork.delete(publishedFiles)
            return@whileCurrent false
          }
          if (publication.newlyPublished) publishedFiles += publication.materialized.file
        }

        val channelUris = preparedItems.mapNotNullTo(LinkedHashSet()) { it.localPosterUri }
        val watchNextUris = ledger.watchNextUris()
        val unionUris = LinkedHashSet<Uri>().apply {
          addAll(watchNextUris)
          addAll(channelUris)
        }
        val packages = consumerPackages()
        if (!grantReadAccess(unionUris, packages)) {
          reconcileReadAccess(unionUris, packages, oldUnion, oldPackages)
          artwork.delete(publishedFiles)
          return@whileCurrent false
        }
        if (session.isExpired()) {
          reconcileReadAccess(unionUris, packages, oldUnion, oldPackages)
          artwork.delete(publishedFiles)
          return@whileCurrent false
        }

        if (!ledger.commitChannelPublication(channelUris, unionUris, packages)) {
          reconcileReadAccess(unionUris, packages, oldUnion, oldPackages)
          artwork.delete(publishedFiles)
          return@whileCurrent false
        }

        val channelId = ensureChannel(channelKey, channelTitle) ?: run {
          ledger.rollbackGrants(oldUnion, oldPackages, previousChannelUris)
          reconcileReadAccess(unionUris, packages, oldUnion, oldPackages)
          artwork.delete(publishedFiles)
          return@whileCurrent false
        }

        if (!replacePrograms(channelId, preparedItems)) {
          ledger.rollbackGrants(oldUnion, oldPackages, previousChannelUris)
          reconcileReadAccess(unionUris, packages, oldUnion, oldPackages)
          artwork.delete(publishedFiles)
          return@whileCurrent false
        }

        // Fire OS may leave prior preview_program rows after a "successful" replace.
        // Never revoke or delete artwork still referenced by live TvProvider posters.
        val grantUris = mergeGrantUris(unionUris, liveChannelPosterUris())
        if (!ledger.persistGranted(grantUris, packages)) {
          ledger.rollbackGrants(oldUnion, oldPackages, previousChannelUris)
          reconcileReadAccess(grantUris, packages, oldUnion, oldPackages)
          artwork.delete(publishedFiles)
          return@whileCurrent false
        }
        reconcileReadAccess(oldUnion, oldPackages, grantUris, packages)
        val keepFiles = LinkedHashSet<File>()
        grantUris.mapNotNullTo(keepFiles) { artwork.resolve(it) }
        // Preserve Watch Next posters that share the store.
        keepFiles += WatchNextProvider.referencedArtworkFiles(context, artwork)
        artwork.deleteExcept(keepFiles)
        true
      } ?: false
    } finally {
      artwork.discard(preparedArtwork)
    }
  }

  internal fun clearAll(
    ownerId: String,
    generation: Long,
    ownership: SystemShelfLifecycle.Ownership? = null,
    isOperationActive: () -> Boolean = { true }
  ): Boolean {
    val operationOwnership = ownership ?: claimOwnership(ownerId, generation) ?: return false
    return SystemShelfLifecycle.whileCurrent(operationOwnership) {
      if (!isOperationActive()) return@whileCurrent false
      clearChannelsUnlocked()
    } ?: false
  }

  /**
   * Drop every preview channel and its URI ledger entries. Caller must already
   * hold [SystemShelfLifecycle.whileCurrent] — used from Watch Next [clearAll]
   * so the two surfaces share one ownership fence without re-entering the lock.
   */
  /** Deletes pre-split Recently Added / New Releases rows if they still exist. */
  private fun purgeLegacyChannelsUnlocked() {
    LEGACY_CHANNELS.forEach { key ->
      val channelId = ledger.channelId(key) ?: findPublishedChannelId(key) ?: return@forEach
      runCatching { helper.deletePreviewChannel(channelId) }
      ledger.clearChannelId(key)
    }
  }

  internal fun clearChannelsUnlocked(): Boolean {
    KNOWN_CHANNELS.forEach { key ->
      val channelId = ledger.channelId(key) ?: findPublishedChannelId(key)
      if (channelId != null) {
        runCatching { helper.deletePreviewChannel(channelId) }
      }
      ledger.clearChannelId(key)
    }
    val oldUnion = ledger.grantedUris()
    val oldPackages = ledger.grantedPackages()
    val watchNextUris = ledger.watchNextUris()
    val packages = consumerPackages()
    ledger.commitChannelPublication(emptySet(), watchNextUris, packages)
    reconcileReadAccess(oldUnion, oldPackages, watchNextUris, packages)
    return true
  }

  fun restoreReadGrants(): Boolean {
    val previous = ledger.grantedUris()
    val keep = retainedPosterUris(previous)
    val packages = consumerPackages()
    reconcileReadAccess(previous, ledger.grantedPackages(), keep, packages)
    return ledger.persistGranted(keep, packages)
  }

  /** Resolvable Watch Next, channel, and still-published poster URIs. */
  internal fun retainedPosterUris(candidates: Set<Uri>): Set<Uri> = LinkedHashSet<Uri>().apply {
    addAll(candidates)
    addAll(ledger.channelUris())
    addAll(liveChannelPosterUris())
  }.filterTo(LinkedHashSet()) { artwork.resolve(it) != null }

  private fun ensureChannel(channelKey: String, title: String): Long? {
    val existingId = ledger.channelId(channelKey) ?: findPublishedChannelId(channelKey)
    if (existingId != null) {
      val existing = runCatching { helper.getPreviewChannel(existingId) }.getOrNull()
      if (existing != null) {
        if (existing.displayName?.toString() != title) {
          val updated = PreviewChannel.Builder(existing)
            .setDisplayName(title)
            .build()
          runCatching { helper.updatePreviewChannel(existingId, updated) }
        }
        ledger.setChannelId(channelKey, existingId)
        return existingId
      }
    }

    val appLink = Uri.Builder().scheme("plezy").authority("home").build()
    val builder = PreviewChannel.Builder()
      .setDisplayName(title)
      .setInternalProviderId(providerIdFor(channelKey))
      .setAppLinkIntent(Intent(Intent.ACTION_VIEW, appLink).setPackage(context.packageName))
      .setLogo(channelLogoBitmap())
    return try {
      val id = helper.publishChannel(builder.build())
      if (id <= 0L) {
        null
      } else {
        ledger.setChannelId(channelKey, id)
        id
      }
    } catch (e: Exception) {
      Log.e(TAG, "Failed to publish preview channel $channelKey", e)
      null
    }
  }

  private fun findPublishedChannelId(channelKey: String): Long? {
    val wanted = providerIdFor(channelKey)
    return runCatching {
      helper.allChannels.firstOrNull { it.internalProviderId == wanted }?.id
    }.getOrNull()
  }

  private fun providerIdFor(channelKey: String) = "plezy_channel_$channelKey"

  private fun replacePrograms(channelId: Long, items: List<PreparedChannelItem>): Boolean = try {
    // Fire OS TvProvider rejects delete/query with a SQL selection on the base
    // preview_program table ("Selection not allowed"). Prefer the channel-scoped
    // URI (no selection), then per-row deletes, then stock Android selection.
    deleteProgramsForChannel(channelId)
    items.forEach { item ->
      val program = buildProgram(channelId, item)
      helper.publishPreviewProgram(program)
    }
    true
  } catch (e: Exception) {
    Log.e(TAG, "Failed to replace preview programs", e)
    false
  }

  private fun deleteProgramsForChannel(channelId: Long) {
    val channelProgramsUri = TvContractCompat.buildPreviewProgramsUriForChannel(channelId)
    // Fire OS often returns 0 from the channel-scoped bulk delete without removing
    // rows. Always follow with a query + per-row delete so stale poster URIs do not
    // outlive the grants we are about to revoke.
    runCatching { context.contentResolver.delete(channelProgramsUri, null, null) }

    val projection = arrayOf(TvContractCompat.PreviewPrograms._ID)
    val queried = runCatching {
      context.contentResolver.query(channelProgramsUri, projection, null, null, null)
    }.getOrNull()
    if (queried != null) {
      queried.use { cursor ->
        val idIndex = cursor.getColumnIndexOrThrow(TvContractCompat.PreviewPrograms._ID)
        while (cursor.moveToNext()) {
          val programId = cursor.getLong(idIndex)
          runCatching {
            context.contentResolver.delete(
              TvContractCompat.buildPreviewProgramUri(programId),
              null,
              null
            )
          }
        }
      }
      return
    }

    runCatching {
      context.contentResolver.delete(
        TvContractCompat.PreviewPrograms.CONTENT_URI,
        "${TvContractCompat.PreviewPrograms.COLUMN_CHANNEL_ID}=?",
        arrayOf(channelId.toString())
      )
    }
  }

  /**
   * Poster URIs still published on our Preview Channels. Used so grant revoke /
   * artwork GC cannot drop tiles Fire OS failed to delete during replace.
   */
  internal fun liveChannelPosterUris(): Set<Uri> {
    val uris = LinkedHashSet<Uri>()
    KNOWN_CHANNELS.forEach { key ->
      val channelId = ledger.channelId(key) ?: findPublishedChannelId(key) ?: return@forEach
      val channelProgramsUri = TvContractCompat.buildPreviewProgramsUriForChannel(channelId)
      val cursor = runCatching {
        context.contentResolver.query(
          channelProgramsUri,
          arrayOf(TvContractCompat.PreviewPrograms.COLUMN_POSTER_ART_URI),
          null,
          null,
          null
        )
      }.getOrNull() ?: return@forEach
      cursor.use { rows ->
        val index = rows.getColumnIndex(TvContractCompat.PreviewPrograms.COLUMN_POSTER_ART_URI)
        if (index < 0) return@use
        while (rows.moveToNext()) {
          val raw = rows.getString(index) ?: continue
          val uri = runCatching { Uri.parse(raw) }.getOrNull() ?: continue
          val posterAuthority = uri.authority
          if (
            posterAuthority == SystemShelfArtworkProvider.AUTHORITY ||
            posterAuthority?.endsWith(SystemShelfArtworkProvider.AUTHORITY_SUFFIX) == true
          ) {
            uris += uri
          }
        }
      }
    }
    return uris
  }

  private fun buildProgram(channelId: Long, item: PreparedChannelItem): PreviewProgram {
    val metadata = item.metadata
    val builder = PreviewProgram.Builder()
      .setChannelId(channelId)
      .setWeight(metadata.weight)
      .setType(metadata.type)
      .setTitle(metadata.title)
      .setInternalProviderId(metadata.contentId)
      .setContentId(metadata.contentId)
      .setBrowsable(true)

    metadata.description?.let(builder::setDescription)
    item.localPosterUri?.let { uri ->
      builder.setPosterArtUri(uri)
      val aspect = if (metadata.type == TvContractCompat.PreviewPrograms.TYPE_CHANNEL) {
        TvContractCompat.PreviewPrograms.ASPECT_RATIO_1_1
      } else {
        TvContractCompat.PreviewPrograms.ASPECT_RATIO_16_9
      }
      builder.setPosterArtAspectRatio(aspect)
    }
    if (metadata.duration > 0) {
      builder.setDurationMillis(metadata.duration.coerceAtMost(Int.MAX_VALUE.toLong()).toInt())
    }
    if (metadata.type == TvContractCompat.PreviewPrograms.TYPE_TV_EPISODE) {
      metadata.episodeTitle?.let(builder::setEpisodeTitle)
      metadata.seasonNumber?.let { builder.setSeasonNumber(it) }
      metadata.episodeNumber?.let { builder.setEpisodeNumber(it) }
    }
    val intentUri = metadata.intentUri?.let(Uri::parse)
      ?: Uri.Builder().scheme("plezy").authority("play")
        .appendQueryParameter("content_id", metadata.contentId).build()
    builder.setIntent(Intent(Intent.ACTION_VIEW, intentUri).setPackage(context.packageName))
    return builder.build()
  }

  private fun channelLogoBitmap(): Bitmap {
    val size = 160
    val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
    val canvas = Canvas(bitmap)
    canvas.drawColor(Color.parseColor("#121212"))
    val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
      color = Color.parseColor("#E8E8E8")
      textAlign = Paint.Align.CENTER
      textSize = 48f
      isFakeBoldText = true
    }
    val x = size / 2f
    val y = size / 2f - (paint.descent() + paint.ascent()) / 2f
    canvas.drawText("P", x, y, paint)
    return bitmap
  }

  internal fun consumerPackages(): Set<String> {
    val homeIntent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
    return context.packageManager
      .queryIntentActivities(homeIntent, android.content.pm.PackageManager.MATCH_ALL)
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

  private fun grantReadAccess(uris: Set<Uri>, packages: Set<String>): Boolean {
    if (uris.isEmpty() || packages.isEmpty()) return true
    val flags = Intent.FLAG_GRANT_READ_URI_PERMISSION
    var unreadable = 0
    uris.forEach { uri ->
      var granted = 0
      packages.forEach { packageName ->
        if (runCatching { context.grantUriPermission(packageName, uri, flags) }.isSuccess) {
          granted++
        }
      }
      if (granted == 0) unreadable++
    }
    return unreadable == 0
  }

  private fun revokeReadAccess(packageName: String, uri: Uri, flags: Int) {
    runCatching {
      if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
        context.revokeUriPermission(packageName, uri, flags)
      } else {
        context.revokeUriPermission(uri, flags)
      }
    }
  }
}

/**
 * Shared SharedPreferences ledger so Watch Next and Preview Channels grant the
 * union of their poster URIs and never revoke each other's launcher access.
 */
internal class SystemShelfUriLedger(context: Context) {
  companion object {
    private const val PREFS = "system_shelf_state"
    private const val GRANTED_URIS = "granted_uris"
    private const val GRANTED_PACKAGES = "granted_packages"
    private const val WATCH_NEXT_URIS = "watch_next_uris"
    private const val CHANNEL_URIS = "channel_uris"
    private const val CHANNEL_ID_PREFIX = "preview_channel_id_"
  }

  private val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

  fun grantedUris(): Set<Uri> = prefs.getStringSet(GRANTED_URIS, emptySet()).orEmpty().mapNotNullTo(LinkedHashSet(), Uri::parse)

  fun grantedPackages(): Set<String> = prefs.getStringSet(GRANTED_PACKAGES, emptySet()).orEmpty()

  fun watchNextUris(): Set<Uri> {
    val stored = prefs.getStringSet(WATCH_NEXT_URIS, null)
    if (stored != null) {
      return stored.mapNotNullTo(LinkedHashSet(), Uri::parse)
    }
    // Pre-channel installs only tracked the union key; treat it as Watch Next.
    return grantedUris()
  }

  fun channelUris(): Set<Uri> = prefs.getStringSet(CHANNEL_URIS, emptySet()).orEmpty().mapNotNullTo(LinkedHashSet(), Uri::parse)

  fun channelId(channelKey: String): Long? {
    val raw = prefs.getLong(CHANNEL_ID_PREFIX + channelKey, -1L)
    return raw.takeIf { it > 0L }
  }

  fun setChannelId(channelKey: String, id: Long) {
    prefs.edit().putLong(CHANNEL_ID_PREFIX + channelKey, id).commit()
  }

  fun clearChannelId(channelKey: String) {
    prefs.edit().remove(CHANNEL_ID_PREFIX + channelKey).commit()
  }

  fun commitWatchNextPublication(watchNextUris: Set<Uri>, unionUris: Set<Uri>, packages: Set<String>): Boolean = prefs.edit()
    .putStringSet(WATCH_NEXT_URIS, watchNextUris.mapTo(LinkedHashSet(), Uri::toString))
    .putStringSet(GRANTED_URIS, unionUris.mapTo(LinkedHashSet(), Uri::toString))
    .putStringSet(GRANTED_PACKAGES, packages)
    .commit()

  fun commitChannelPublication(channelUris: Set<Uri>, unionUris: Set<Uri>, packages: Set<String>): Boolean = prefs.edit()
    .putStringSet(CHANNEL_URIS, channelUris.mapTo(LinkedHashSet(), Uri::toString))
    .putStringSet(GRANTED_URIS, unionUris.mapTo(LinkedHashSet(), Uri::toString))
    .putStringSet(GRANTED_PACKAGES, packages)
    .commit()

  fun persistGranted(uris: Set<Uri>, packages: Set<String>): Boolean = prefs.edit()
    .putStringSet(GRANTED_URIS, uris.mapTo(LinkedHashSet(), Uri::toString))
    .putStringSet(GRANTED_PACKAGES, packages)
    .commit()

  fun rollbackGrants(oldUnion: Set<Uri>, oldPackages: Set<String>, previousChannelUris: Set<Uri>) {
    prefs.edit()
      .putStringSet(GRANTED_URIS, oldUnion.mapTo(LinkedHashSet(), Uri::toString))
      .putStringSet(GRANTED_PACKAGES, oldPackages)
      .putStringSet(CHANNEL_URIS, previousChannelUris.mapTo(LinkedHashSet(), Uri::toString))
      .commit()
  }
}
