package com.edde746.plezy.exoplayer

import android.net.Uri
import android.os.SystemClock
import androidx.annotation.OptIn
import androidx.media3.common.C
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.DataSpec
import androidx.media3.datasource.HttpDataSource
import androidx.media3.datasource.TransferListener
import java.io.IOException
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicLong

/**
 * An [HttpDataSource] decorator that transparently recycles degraded or idle-aged progressive HTTP
 * streams at the exact current byte offset (`Range: bytes=<offset>-`).
 *
 * Media3's `ProgressiveMediaPeriod$ExtractingLoadable` opens a single `HttpDataSource` at byte 0
 * and holds it open for the lifetime of the file — blocking inside `loadCondition.block()` whenever
 * `LoadControl.shouldContinueLoading` returns `false`, and never closing or re-opening the socket
 * even when the playback buffer drains to zero (`STATE_BUFFERING`), unless the user seeks.
 *
 * On Fire TV / Android TV over 10–15 minutes of continuous progressive playback, that single
 * long-lived HTTP/2 (Cronet) or HTTP/1.1 connection can suffer TCP receive-window / HTTP/2
 * stream flow-control clamping or server/CDN per-stream shaping after repeated loader pauses,
 * dropping throughput below 1x playback rate until a seek forces a new Range request.
 *
 * Because `DefaultExtractorInput` only interacts with the `DataSource` via sequential
 * `read(buffer, offset, length)` calls after `open`, this wrapper can close a degraded underlying
 * [HttpDataSource] and open a fresh one at `initialDataSpec.position + totalBytesRead` without
 * disturbing the extractor or decoders.
 */
@OptIn(UnstableApi::class)
internal class ReconnectingHttpDataSource(
  private val upstreamFactory: HttpDataSource.Factory,
  private val rebufferSignalEpoch: AtomicInteger,
  private val clockMs: () -> Long = { SystemClock.elapsedRealtime() },
  private val onReconnect: (reason: String, byteOffset: Long, reconnectCount: Int) -> Unit = { _, _, _ -> },
  private val onThroughputMeasured: (bytesPerSec: Long) -> Unit = {}
) : HttpDataSource {

  companion object {
    /** Minimum connection age (10s) before a mid-playback rebuffer triggers a Range reconnect. */
    const val MIN_STREAM_AGE_FOR_REBUFFER_RECONNECT_MS = 10_000L

    /** Minimum connection age (2 min) before a loader pause triggers proactive stream rotation. */
    const val MIN_STREAM_AGE_FOR_IDLE_RECONNECT_MS = 120_000L

    /** Minimum bytes read on the current connection (64 MiB) that also qualifies for idle rotation. */
    const val MIN_BYTES_FOR_IDLE_RECONNECT = 64L * 1024 * 1024

    /** Loader idle gap (4s) after which an aged connection is rotated before resuming reads. */
    const val IDLE_GAP_THRESHOLD_MS = 4_000L

    /** Read gap (1s) that resets the active throughput measurement window so loader pauses are excluded. */
    const val IDLE_WINDOW_RESET_MS = 1_000L

    /** Active read window duration (4s) for rolling throughput measurement. */
    const val THROUGHPUT_WINDOW_MS = 4_000L

    /** Minimum bytes read on a connection (4 MiB) before recording its burst peak throughput. */
    const val MIN_BYTES_FOR_PEAK_ESTABLISHMENT = 4L * 1024 * 1024

    /** Minimum established peak throughput (2 MiB/s) required before evaluating collapse ratios. */
    const val MIN_PEAK_THROUGHPUT_BYTES_PER_SEC = 2L * 1024 * 1024

    /** Ceiling (12 MiB/s) above which a stream is considered fast enough regardless of peak ratio. */
    const val MAX_DEGRADED_THROUGHPUT_BYTES_PER_SEC = 12L * 1024 * 1024

    /** Collapse factor (4x -> < 25% of established peak throughput). */
    const val THROUGHPUT_COLLAPSE_FACTOR = 4L

    /** Consecutive degraded active windows required before proactive throughput reconnection. */
    const val CONSECUTIVE_DEGRADED_WINDOWS_THRESHOLD = 2

    /** Minimum connection age (30s) before active throughput collapse triggers a reconnect. */
    const val MIN_STREAM_AGE_FOR_THROUGHPUT_RECONNECT_MS = 30_000L

    /** Cooldown (15s) between consecutive Range reconnects on the same open stream. */
    const val RECONNECT_COOLDOWN_MS = 15_000L

    internal fun supportsByteRanges(
      responseCode: Int,
      responseHeaders: Map<String, List<String>>
    ): Boolean {
      if (responseCode == 206) return true
      for ((key, values) in responseHeaders) {
        if (
          key.equals("Content-Range", ignoreCase = true) &&
          values.any { it.startsWith("bytes", ignoreCase = true) }
        ) {
          return true
        }
        if (
          key.equals("Accept-Ranges", ignoreCase = true) &&
          values.any { it.contains("bytes", ignoreCase = true) }
        ) {
          return true
        }
      }
      return false
    }
  }

  class Factory(
    private val upstreamFactory: HttpDataSource.Factory,
    private val clockMs: () -> Long = { SystemClock.elapsedRealtime() },
    private val log: (level: String, message: String) -> Unit = { _, _ -> }
  ) : HttpDataSource.Factory {

    private val defaultRequestProperties = HashMap<String, String>()
    private val rebufferSignalEpoch = AtomicInteger(0)
    private val totalReconnects = AtomicInteger(0)
    private val latestThroughputBytesPerSec = AtomicLong(0L)

    override fun createDataSource(): ReconnectingHttpDataSource {
      val snapshotProps: Map<String, String> = synchronized(defaultRequestProperties) {
        HashMap(defaultRequestProperties)
      }
      return ReconnectingHttpDataSource(
        upstreamFactory = upstreamFactory,
        rebufferSignalEpoch = rebufferSignalEpoch,
        clockMs = clockMs,
        onReconnect = { reason, byteOffset, count ->
          val sessionTotal = totalReconnects.incrementAndGet()
          log(
            "info",
            "Recycled HTTP stream at byte $byteOffset (reason=$reason, streamReconnects=$count, sessionTotal=$sessionTotal)"
          )
        },
        onThroughputMeasured = { bytesPerSec ->
          latestThroughputBytesPerSec.set(bytesPerSec)
        }
      ).also { source ->
        for ((k, v) in snapshotProps) {
          source.setRequestProperty(k, v)
        }
      }
    }

    override fun setDefaultRequestProperties(
      defaultRequestProperties: Map<String, String>
    ): HttpDataSource.Factory {
      synchronized(this.defaultRequestProperties) {
        this.defaultRequestProperties.clear()
        this.defaultRequestProperties.putAll(defaultRequestProperties)
      }
      upstreamFactory.setDefaultRequestProperties(defaultRequestProperties)
      return this
    }

    /** Signals active progressive HTTP streams that playback entered a mid-stream rebuffer. */
    fun notifyRebuffering() {
      rebufferSignalEpoch.incrementAndGet()
    }

    /** Resets per-item diagnostic counters when opening a new media item. */
    fun resetSession() {
      totalReconnects.set(0)
      latestThroughputBytesPerSec.set(0L)
    }

    fun totalReconnectCount(): Int = totalReconnects.get()

    fun currentThroughputBytesPerSec(): Long? = latestThroughputBytesPerSec.get().takeIf { it > 0L }
  }

  private val transferListeners = mutableListOf<TransferListener>()
  private val requestProperties = LinkedHashMap<String, String>()

  private var currentDelegate: HttpDataSource? = null
  private var initialDataSpec: DataSpec? = null
  private var rangeSupported: Boolean = false

  private var connectionOpenedAtMs: Long = 0L
  private var lastReadAtMs: Long = 0L
  private var lastReconnectAtMs: Long = 0L
  private var totalBytesRead: Long = 0L
  private var bytesReadOnCurrentConnection: Long = 0L

  private var activeWindowStartMs: Long = 0L
  private var activeWindowBytes: Long = 0L
  private var lastWindowThroughputBytesPerSec: Long = 0L
  private var peakThroughputBytesPerSec: Long = 0L
  private var consecutiveDegradedWindows: Int = 0
  private var throughputReconnectPending: Boolean = false
  private var rebufferSignalEpochSeen: Int = 0

  var reconnectCount: Int = 0
    private set

  override fun addTransferListener(transferListener: TransferListener) {
    if (!transferListeners.contains(transferListener)) {
      transferListeners.add(transferListener)
    }
    currentDelegate?.addTransferListener(transferListener)
  }

  override fun setRequestProperty(name: String, value: String) {
    requestProperties[name] = value
    currentDelegate?.setRequestProperty(name, value)
  }

  override fun clearRequestProperty(name: String) {
    requestProperties.remove(name)
    currentDelegate?.clearRequestProperty(name)
  }

  override fun clearAllRequestProperties() {
    requestProperties.clear()
    currentDelegate?.clearAllRequestProperties()
  }

  override fun getUri(): Uri? = currentDelegate?.uri

  override fun getResponseCode(): Int = currentDelegate?.responseCode ?: -1

  override fun getResponseHeaders(): Map<String, List<String>> = currentDelegate?.responseHeaders ?: emptyMap()

  @Throws(HttpDataSource.HttpDataSourceException::class)
  override fun open(dataSpec: DataSpec): Long {
    closeQuietly(currentDelegate)
    currentDelegate = null

    val delegate = createConfiguredDelegate()
    val openedLength = delegate.open(dataSpec)
    currentDelegate = delegate
    initialDataSpec = dataSpec

    val nowMs = clockMs()
    connectionOpenedAtMs = nowMs
    lastReadAtMs = nowMs
    lastReconnectAtMs = 0L
    totalBytesRead = 0L
    bytesReadOnCurrentConnection = 0L
    activeWindowStartMs = 0L
    activeWindowBytes = 0L
    lastWindowThroughputBytesPerSec = 0L
    peakThroughputBytesPerSec = 0L
    consecutiveDegradedWindows = 0
    throughputReconnectPending = false
    rebufferSignalEpochSeen = rebufferSignalEpoch.get()

    rangeSupported = dataSpec.httpMethod == DataSpec.HTTP_METHOD_GET &&
      supportsByteRanges(delegate.responseCode, delegate.responseHeaders)

    return openedLength
  }

  @Throws(HttpDataSource.HttpDataSourceException::class)
  override fun read(buffer: ByteArray, offset: Int, length: Int): Int {
    if (length == 0) return 0
    val baseSpec = initialDataSpec
    if (baseSpec != null && baseSpec.length != C.LENGTH_UNSET.toLong() && totalBytesRead >= baseSpec.length) {
      return C.RESULT_END_OF_INPUT
    }

    val nowMs = clockMs()
    val idleGapMs = if (lastReadAtMs > 0L) (nowMs - lastReadAtMs).coerceAtLeast(0L) else 0L
    val reason = reconnectReasonBeforeRead(nowMs, idleGapMs)
    if (reason != null) {
      reconnectInPlace(nowMs, reason)
    } else if (idleGapMs >= IDLE_WINDOW_RESET_MS) {
      // Exclude LoadControl pauses from active download throughput measurement.
      activeWindowStartMs = nowMs
      activeWindowBytes = 0L
    }

    val delegate = currentDelegate
      ?: throw HttpDataSource.HttpDataSourceException(
        IOException("DataSource is not open"),
        baseSpec ?: DataSpec(Uri.EMPTY),
        PlaybackExceptionCompat.ERROR_CODE_IO_UNSPECIFIED,
        HttpDataSource.HttpDataSourceException.TYPE_READ
      )

    val bytesRead = delegate.read(buffer, offset, length)
    if (bytesRead == C.RESULT_END_OF_INPUT) {
      return C.RESULT_END_OF_INPUT
    }

    if (bytesRead > 0) {
      val afterReadMs = clockMs()
      totalBytesRead += bytesRead
      bytesReadOnCurrentConnection += bytesRead
      lastReadAtMs = afterReadMs
      recordThroughputSample(bytesRead, nowMs, afterReadMs)
    }

    return bytesRead
  }

  @Throws(HttpDataSource.HttpDataSourceException::class)
  override fun close() {
    val delegate = currentDelegate
    currentDelegate = null
    initialDataSpec = null
    rangeSupported = false
    activeWindowStartMs = 0L
    activeWindowBytes = 0L
    consecutiveDegradedWindows = 0
    throughputReconnectPending = false
    delegate?.close()
  }

  private fun reconnectReasonBeforeRead(nowMs: Long, idleGapMs: Long): String? {
    val currentEpoch = rebufferSignalEpoch.get()
    val hasPendingRebufferSignal = currentEpoch != rebufferSignalEpochSeen
    if (hasPendingRebufferSignal) {
      rebufferSignalEpochSeen = currentEpoch
    }

    if (!rangeSupported || totalBytesRead <= 0L) return null
    val baseSpec = initialDataSpec ?: return null
    if (baseSpec.length != C.LENGTH_UNSET.toLong() && totalBytesRead >= baseSpec.length) {
      return null
    }
    if (lastReconnectAtMs > 0L && (nowMs - lastReconnectAtMs) < RECONNECT_COOLDOWN_MS) {
      return null
    }

    val connectionAgeMs = (nowMs - connectionOpenedAtMs).coerceAtLeast(0L)

    if (hasPendingRebufferSignal && connectionAgeMs >= MIN_STREAM_AGE_FOR_REBUFFER_RECONNECT_MS) {
      return "rebuffer(age=${connectionAgeMs}ms)"
    }

    if (
      idleGapMs >= IDLE_GAP_THRESHOLD_MS &&
      (
        connectionAgeMs >= MIN_STREAM_AGE_FOR_IDLE_RECONNECT_MS ||
          bytesReadOnCurrentConnection >= MIN_BYTES_FOR_IDLE_RECONNECT
        )
    ) {
      return "idle-gap(idle=${idleGapMs}ms,age=${connectionAgeMs}ms,bytes=$bytesReadOnCurrentConnection)"
    }

    if (throughputReconnectPending && connectionAgeMs >= MIN_STREAM_AGE_FOR_THROUGHPUT_RECONNECT_MS) {
      return "throughput-collapse(rate=${lastWindowThroughputBytesPerSec / 1024}KB/s," +
        "peak=${peakThroughputBytesPerSec / 1024}KB/s,age=${connectionAgeMs}ms)"
    }

    return null
  }

  @Throws(HttpDataSource.HttpDataSourceException::class)
  private fun reconnectInPlace(nowMs: Long, reason: String) {
    val baseSpec = initialDataSpec ?: return
    val resumeOffset = baseSpec.position + totalBytesRead
    val remainingLength = if (baseSpec.length == C.LENGTH_UNSET.toLong()) {
      C.LENGTH_UNSET.toLong()
    } else {
      (baseSpec.length - totalBytesRead).coerceAtLeast(1L)
    }
    val cleanedHeaders = baseSpec.httpRequestHeaders
      .filterKeys { !it.equals("Range", ignoreCase = true) }
    val reconnectSpec = baseSpec.buildUpon()
      .setPosition(resumeOffset)
      .setLength(remainingLength)
      .setHttpRequestHeaders(cleanedHeaders)
      .build()

    val oldDelegate = currentDelegate
    currentDelegate = null
    closeQuietly(oldDelegate)

    val nextDelegate = createConfiguredDelegate()
    nextDelegate.open(reconnectSpec)
    currentDelegate = nextDelegate

    connectionOpenedAtMs = nowMs
    lastReconnectAtMs = nowMs
    lastReadAtMs = nowMs
    bytesReadOnCurrentConnection = 0L
    activeWindowStartMs = nowMs
    activeWindowBytes = 0L
    // Reset peak on reconnect so the fresh connection establishes its own baseline. If the
    // slowdown was a stale socket/HTTP2 stream, the new stream bursts back up immediately; if the
    // link itself genuinely slowed down, the new baseline prevents repeated reconnects.
    peakThroughputBytesPerSec = 0L
    consecutiveDegradedWindows = 0
    throughputReconnectPending = false
    reconnectCount++
    onReconnect(reason, resumeOffset, reconnectCount)
  }

  private fun recordThroughputSample(bytesRead: Int, readStartMs: Long, readEndMs: Long) {
    if (activeWindowStartMs == 0L) {
      activeWindowStartMs = readStartMs
    }
    activeWindowBytes += bytesRead
    val elapsedMs = readEndMs - activeWindowStartMs
    if (elapsedMs < THROUGHPUT_WINDOW_MS) return

    val bytesPerSec = (activeWindowBytes * 1000L) / elapsedMs
    lastWindowThroughputBytesPerSec = bytesPerSec
    onThroughputMeasured(bytesPerSec)

    if (
      bytesReadOnCurrentConnection >= MIN_BYTES_FOR_PEAK_ESTABLISHMENT &&
      bytesPerSec > peakThroughputBytesPerSec
    ) {
      peakThroughputBytesPerSec = bytesPerSec
    }

    val connectionAgeMs = (readEndMs - connectionOpenedAtMs).coerceAtLeast(0L)
    val hasEstablishedPeak = peakThroughputBytesPerSec >= MIN_PEAK_THROUGHPUT_BYTES_PER_SEC
    val isCollapsed = hasEstablishedPeak &&
      bytesPerSec < MAX_DEGRADED_THROUGHPUT_BYTES_PER_SEC &&
      bytesPerSec * THROUGHPUT_COLLAPSE_FACTOR < peakThroughputBytesPerSec

    if (connectionAgeMs >= MIN_STREAM_AGE_FOR_THROUGHPUT_RECONNECT_MS && isCollapsed) {
      consecutiveDegradedWindows++
      if (consecutiveDegradedWindows >= CONSECUTIVE_DEGRADED_WINDOWS_THRESHOLD) {
        throughputReconnectPending = true
      }
    } else {
      consecutiveDegradedWindows = 0
    }

    activeWindowStartMs = readEndMs
    activeWindowBytes = 0L
  }

  private fun createConfiguredDelegate(): HttpDataSource {
    val delegate = upstreamFactory.createDataSource()
    for (listener in transferListeners) {
      delegate.addTransferListener(listener)
    }
    for ((name, value) in requestProperties) {
      delegate.setRequestProperty(name, value)
    }
    return delegate
  }

  private fun closeQuietly(source: HttpDataSource?) {
    if (source == null) return
    try {
      source.close()
    } catch (_: Exception) {
    }
  }

  private object PlaybackExceptionCompat {
    const val ERROR_CODE_IO_UNSPECIFIED = 2000
  }
}
