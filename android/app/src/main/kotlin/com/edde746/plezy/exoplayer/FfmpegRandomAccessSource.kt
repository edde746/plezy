package com.edde746.plezy.exoplayer

import android.net.Uri
import androidx.annotation.OptIn
import androidx.media3.common.C
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.DataSource
import androidx.media3.datasource.DataSpec
import androidx.media3.datasource.TransferListener
import java.io.IOException

/**
 * Random-access byte source for the libavformat demuxer.
 *
 * libavformat demuxers own their own IO: they jump to the end of the file for an
 * index (matroska Cues, MP4 moov, AVI idx1), back to the header, and binary
 * search (MPEG-PS) whenever they please. media3's [
 * androidx.media3.extractor.ExtractorInput] is forward-only — an extractor may
 * only ask the loader to re-open elsewhere and be invoked again — so serving
 * libavformat from the loader alone means every backward jump has to unwind the
 * in-flight libavformat call and replay it, which is what the demuxer shim used
 * to do (and what made a matroska Cues read unrecoverable, #2096).
 *
 * This class removes the mismatch instead of working around it: reads outside
 * the loader's window open a second [DataSource] from the same factory media3
 * uses, positioned exactly where libavformat asked. Cronet, download caches,
 * SAF and the item's own request headers therefore still apply, because the
 * [DataSpec] is cloned from the one media3 opened for this item.
 *
 * Sequential sample delivery deliberately does not come through here: it stays
 * on the loader's connection so media3 keeps its byte accounting, back-pressure
 * and load-error policy (see [FfmpegExtractor]). This source is opened for
 * header/index bursts and closed again as soon as the loader is back in step.
 */
@OptIn(UnstableApi::class)
internal class FfmpegRandomAccessSource(
  private val factory: DataSource.Factory,
  private val specProvider: () -> DataSpec?
) {
  private var source: DataSource? = null

  /** Absolute position the open handle returns next; [C.INDEX_UNSET] when closed. */
  private var handlePosition = C.INDEX_UNSET.toLong()

  private var resolvedLength = C.LENGTH_UNSET.toLong()

  private var opens = 0

  /** Handles opened so far; the tests assert an index seek does not walk the file. */
  val openCount: Int
    get() = synchronized(this) { opens }

  val isOpen: Boolean
    get() = synchronized(this) { source != null }

  /**
   * Reads up to [length] bytes at absolute [position]. Returns the number of
   * bytes read, or 0 at end of input. Reopens the underlying source whenever
   * the requested position is not where the current handle stands, which is the
   * only way to move backwards on a byte stream.
   */
  fun readAt(position: Long, buffer: ByteArray, length: Int): Int = synchronized(this) {
    if (length <= 0) return 0
    val handle = handleAt(position)
    val read = handle.read(buffer, 0, length)
    if (read == C.RESULT_END_OF_INPUT) return 0
    handlePosition = position + read
    read
  }

  /**
   * Total resource length once some open has resolved it, else
   * [C.LENGTH_UNSET]. Never performs IO of its own: the extractor prefers the
   * length media3 already resolved for the loader.
   */
  fun length(): Long = synchronized(this) { resolvedLength }

  fun close() = synchronized(this) {
    closeHandle()
    handlePosition = C.INDEX_UNSET.toLong()
  }

  private fun handleAt(position: Long): DataSource {
    val existing = source
    if (existing != null && handlePosition == position) return existing
    closeHandle()
    val spec = specProvider() ?: throw IOException("ffmpeg demuxer has no data spec for random access")
    // Clone rather than subrange: the recorded spec carries the loader's own
    // position, and subrange() is relative to it.
    val positioned = spec.buildUpon()
      .setPosition(position)
      .setLength(C.LENGTH_UNSET.toLong())
      .build()
    val created = factory.createDataSource()
    val remaining = try {
      created.open(positioned)
    } catch (e: Throwable) {
      closeQuietly(created)
      throw e
    }
    source = created
    handlePosition = position
    opens++
    if (remaining != C.LENGTH_UNSET.toLong()) resolvedLength = position + remaining
    return created
  }

  private fun closeHandle() {
    source?.let { closeQuietly(it) }
    source = null
  }

  private fun closeQuietly(dataSource: DataSource) {
    try {
      dataSource.close()
    } catch (_: IOException) {
      // Closing a handle we are abandoning cannot fail the read that replaces it.
    }
  }
}

/**
 * [DataSource.Factory] that remembers the [DataSpec] media3 opened for each
 * item, so [FfmpegRandomAccessSource] can clone it — same URI, cache key, flags
 * and request headers — instead of re-deriving one and silently losing, say, a
 * download's cache key.
 *
 * Keyed by URI because ExoPlayer prepares the next item's period while the
 * current one is still loading; the demuxer must never read the next item's
 * bytes.
 */
@OptIn(UnstableApi::class)
internal class RecordingDataSourceFactory(private val delegate: DataSource.Factory) : DataSource.Factory {

  private val specs = object : LinkedHashMap<Uri, DataSpec>(8, 0.75f, false) {
    override fun removeEldestEntry(eldest: MutableMap.MutableEntry<Uri, DataSpec>): Boolean = size > MAX_TRACKED_ITEMS
  }

  fun specFor(uri: Uri): DataSpec? = synchronized(specs) { specs[uri] }

  override fun createDataSource(): DataSource = RecordingDataSource(delegate.createDataSource())

  private fun record(dataSpec: DataSpec) {
    synchronized(specs) { specs[dataSpec.uri] = dataSpec }
  }

  private inner class RecordingDataSource(private val inner: DataSource) : DataSource {
    override fun open(dataSpec: DataSpec): Long {
      record(dataSpec)
      return inner.open(dataSpec)
    }

    override fun read(buffer: ByteArray, offset: Int, length: Int): Int = inner.read(buffer, offset, length)

    override fun addTransferListener(transferListener: TransferListener) = inner.addTransferListener(transferListener)

    override fun getUri(): Uri? = inner.uri

    override fun getResponseHeaders(): Map<String, List<String>> = inner.responseHeaders

    override fun close() = inner.close()
  }

  private companion object {
    const val MAX_TRACKED_ITEMS = 4
  }
}
