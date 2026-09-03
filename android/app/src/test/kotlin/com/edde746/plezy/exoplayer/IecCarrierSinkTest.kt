package com.edde746.plezy.exoplayer

import android.media.AudioDeviceInfo
import androidx.annotation.OptIn
import androidx.media3.common.AudioAttributes
import androidx.media3.common.AuxEffectInfo
import androidx.media3.common.C
import androidx.media3.common.Format
import androidx.media3.common.MimeTypes
import androidx.media3.common.PlaybackParameters
import androidx.media3.common.Timeline
import androidx.media3.common.util.Clock
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.analytics.PlayerId
import androidx.media3.exoplayer.audio.AudioSink
import androidx.media3.exoplayer.source.MediaSource
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Routing and back-pressure contract for the IEC 61937 carrier: TrueHD/MAT (#1804) and DTS-HD
 * (#1988).
 *
 * The carrier is bit-exact, so the two failure modes that matter here are losing bytes and letting
 * the wrong sink handle a carrier codec.
 */
@OptIn(UnstableApi::class)
class IecCarrierSinkTest {

  private val accessUnits: ByteArray =
    checkNotNull(javaClass.classLoader?.getResourceAsStream("truehd_access_units.bin"))
      .use { it.readBytes() }

  private val golden: ByteArray =
    checkNotNull(javaClass.classLoader?.getResourceAsStream("truehd_iec61937_golden.bin"))
      .use { it.readBytes() }

  private val dtsHdAccessUnits: ByteArray by lazy {
    checkNotNull(javaClass.classLoader?.getResourceAsStream("dtshd_ma_access_units.bin"))
      .use { it.readBytes() }
  }

  private val dtsHdGolden: ByteArray by lazy {
    checkNotNull(javaClass.classLoader?.getResourceAsStream("dtshd_ma_iec61937_golden.bin"))
      .use { it.readBytes() }
  }

  private fun trueHdFormat(sampleRate: Int = 48_000): Format = Format.Builder()
    .setSampleMimeType(MimeTypes.AUDIO_TRUEHD)
    .setChannelCount(6)
    .setSampleRate(sampleRate)
    .build()

  private fun dtsHdFormat(sampleRate: Int = 48_000): Format = Format.Builder()
    .setSampleMimeType(MimeTypes.AUDIO_DTS_HD)
    .setChannelCount(6)
    .setSampleRate(sampleRate)
    .build()

  private fun audioSinkConfig(format: Format = trueHdFormat()) = AudioSink.AudioSinkConfig.Builder(format).build()

  private fun sink(
    carrier: FakeSink = FakeSink(),
    normal: FakeSink = FakeSink(),
    routeAvailable: Boolean = true,
    blocked: Boolean = false
  ) = IecCarrierSink(normal, carrier, { routeAvailable }, { blocked })

  /**
   * TrueHD is the carrier or it is decoded. Falling through to the normal sink would hand media3
   * its raw ENCODING_DOLBY_TRUEHD path, which is the configuration that wedges on these devices.
   */
  @Test
  fun trueHdWithoutACarrierRouteIsReportedUnsupportedSoItDecodes() {
    val normal = FakeSink().apply { formatSupport = AudioSink.SINK_FORMAT_SUPPORTED_DIRECTLY }
    val carrierSink = sink(normal = normal, routeAvailable = false)

    assertFalse(carrierSink.supportsFormat(trueHdFormat()))
    assertEquals(AudioSink.SINK_FORMAT_UNSUPPORTED, carrierSink.getFormatSupport(trueHdFormat()))
  }

  @Test
  fun trueHdWithACarrierRouteIsSupportedDirectly() {
    val carrierSink = sink()
    assertTrue(carrierSink.supportsFormat(trueHdFormat()))
    assertEquals(AudioSink.SINK_FORMAT_SUPPORTED_DIRECTLY, carrierSink.getFormatSupport(trueHdFormat()))
  }

  @Test
  fun dtsHdWithACarrierRouteIsSupportedDirectly() {
    val carrierSink = sink()
    assertTrue(carrierSink.supportsFormat(dtsHdFormat()))
    assertEquals(AudioSink.SINK_FORMAT_SUPPORTED_DIRECTLY, carrierSink.getFormatSupport(dtsHdFormat()))
  }

  /**
   * The route that advertises the carrier and raw `ENCODING_DTS_HD` at once is the one whose raw
   * path renders silence (#1988), so while the carrier route exists DTS-HD is the carrier or it is
   * decoded — never the normal sink's raw path, even when policy declines the carrier.
   */
  @Test
  fun dtsHdOnACarrierRouteNeverFallsThroughToTheRawPath() {
    val normal = FakeSink().apply { formatSupport = AudioSink.SINK_FORMAT_SUPPORTED_DIRECTLY }
    val blockedSink = sink(normal = normal, blocked = true)

    assertFalse(blockedSink.supportsFormat(dtsHdFormat()))
    assertEquals(AudioSink.SINK_FORMAT_UNSUPPORTED, blockedSink.getFormatSupport(dtsHdFormat()))
  }

  /**
   * Routes without the IEC carrier never had it to lose, and some of them bitstream raw DTS-HD
   * genuinely; the pre-carrier behavior is preserved there.
   */
  @Test
  fun dtsHdWithoutACarrierRouteFallsThroughToTheNormalSink() {
    val normal = FakeSink().apply { formatSupport = AudioSink.SINK_FORMAT_SUPPORTED_DIRECTLY }
    val carrierSink = sink(normal = normal, routeAvailable = false)

    assertTrue(carrierSink.supportsFormat(dtsHdFormat()))
    assertEquals(AudioSink.SINK_FORMAT_SUPPORTED_DIRECTLY, carrierSink.getFormatSupport(dtsHdFormat()))
  }

  /** The tuple is shared, so the gate is per format: TrueHD keeps the carrier while DTS-HD leaves. */
  @Test
  fun theCarrierGateIsEvaluatedPerFormat() {
    val carrier = FakeSink()
    val normal = FakeSink()
    val carrierSink = IecCarrierSink(normal, carrier, { it.sampleMimeType != MimeTypes.AUDIO_DTS_HD }, { false })

    carrierSink.configure(audioSinkConfig(trueHdFormat()))
    assertEquals(IecCarrier.SAMPLE_RATE, checkNotNull(carrier.configuredConfig).format.sampleRate)

    carrierSink.configure(audioSinkConfig(dtsHdFormat()))
    assertEquals(MimeTypes.AUDIO_DTS_HD, checkNotNull(normal.configuredConfig).format.sampleMimeType)
  }

  /** DTS Express shares the DTS-HD mime prefix but carries `;profile=lbr`; it keeps decoding. */
  @Test
  fun dtsExpressIsLeftToTheNormalSink() {
    val normal = FakeSink().apply { formatSupport = AudioSink.SINK_FORMAT_SUPPORTED_DIRECTLY }
    val carrierSink = sink(normal = normal)
    val express = Format.Builder()
      .setSampleMimeType(MimeTypes.AUDIO_DTS_EXPRESS)
      .setSampleRate(48_000)
      .build()

    assertEquals(AudioSink.SINK_FORMAT_SUPPORTED_DIRECTLY, carrierSink.getFormatSupport(express))
    assertTrue(carrierSink.supportsFormat(express))
  }

  /** Downmix and normalization already force decoding; the carrier must not override that. */
  @Test
  fun blockedDirectOutputDeclinesTheCarrier() {
    val carrierSink = sink(blocked = true)
    assertEquals(AudioSink.SINK_FORMAT_UNSUPPORTED, carrierSink.getFormatSupport(trueHdFormat()))
  }

  /**
   * 44.1kHz-family streams ride a 176.4kHz carrier this path does not build. It has to be decided
   * from the format: the packer only learns the rate from the bitstream, long after selection, and
   * selecting the carrier for it would produce silence.
   */
  @Test
  fun theFortyFourPointOneFamilyDeclinesTheCarrierFromTheFormatAlone() {
    val carrierSink = sink()
    assertEquals(AudioSink.SINK_FORMAT_UNSUPPORTED, carrierSink.getFormatSupport(trueHdFormat(sampleRate = 44_100)))
    assertEquals(AudioSink.SINK_FORMAT_UNSUPPORTED, carrierSink.getFormatSupport(trueHdFormat(sampleRate = 176_400)))
    assertEquals(AudioSink.SINK_FORMAT_UNSUPPORTED, carrierSink.getFormatSupport(dtsHdFormat(sampleRate = 44_100)))
    assertEquals(AudioSink.SINK_FORMAT_UNSUPPORTED, carrierSink.getFormatSupport(dtsHdFormat(sampleRate = 88_200)))
  }

  /** A bitstream cannot be resampled, so any speed other than 1.0x decodes. */
  @Test
  fun aSpeedChangeDeclinesTheCarrier() {
    val carrierSink = sink()
    carrierSink.setPlaybackParameters(PlaybackParameters(1.5f))
    assertEquals(AudioSink.SINK_FORMAT_UNSUPPORTED, carrierSink.getFormatSupport(trueHdFormat()))
    assertEquals(AudioSink.SINK_FORMAT_UNSUPPORTED, carrierSink.getFormatSupport(dtsHdFormat()))
  }

  /**
   * The real UI path: speed changes while the carrier is already live. Querying support after
   * setting speed passes trivially; nothing re-asks the sink unless capabilities are invalidated,
   * so without this the carrier keeps running and is handed a speed it cannot apply.
   */
  @Test
  fun leavingUnitSpeedMidPlaybackInvalidatesCapabilities() {
    val carrier = FakeSink()
    val carrierSink = sink(carrier = carrier)
    val listener = RecordingSinkListener()
    carrierSink.setListener(listener)
    carrierSink.configure(audioSinkConfig())
    assertTrue("carrier should be live before the speed change", carrierSink.isCarrierActive)

    carrierSink.setPlaybackParameters(PlaybackParameters(1.5f))

    assertEquals("the renderer must be asked to re-evaluate", 1, listener.capabilityInvalidations)
    assertEquals(
      "the carrier delegate must never receive a speed it cannot apply",
      1f,
      carrier.lastPlaybackParameters.speed,
      0f
    )
    assertEquals(AudioSink.SINK_FORMAT_UNSUPPORTED, carrierSink.getFormatSupport(trueHdFormat()))
  }

  /** Returning to 1x has to re-offer the carrier, or Atmos is lost until the next open. */
  @Test
  fun returningToUnitSpeedInvalidatesCapabilitiesAgain() {
    val carrierSink = sink()
    val listener = RecordingSinkListener()
    carrierSink.setListener(listener)
    carrierSink.configure(audioSinkConfig())

    carrierSink.setPlaybackParameters(PlaybackParameters(1.5f))
    carrierSink.setPlaybackParameters(PlaybackParameters(1f))

    assertEquals(2, listener.capabilityInvalidations)
    assertEquals(AudioSink.SINK_FORMAT_SUPPORTED_DIRECTLY, carrierSink.getFormatSupport(trueHdFormat()))
  }

  /** A speed change that stays at 1x is not a transition and must not disturb selection. */
  @Test
  fun aNoOpSpeedChangeDoesNotInvalidateCapabilities() {
    val carrierSink = sink()
    val listener = RecordingSinkListener()
    carrierSink.setListener(listener)
    carrierSink.configure(audioSinkConfig())

    carrierSink.setPlaybackParameters(PlaybackParameters(1f))

    assertEquals(0, listener.capabilityInvalidations)
  }

  /**
   * Selection reads Format.sampleRate; the rate family is only certain once a major sync is parsed.
   * When they disagree the packer emits nothing, so consuming the input would turn the stream into
   * silence. The unit has to survive for whoever takes over.
   */
  @Test
  fun aRateFamilyMismatchLeavesTheCarrierInsteadOfGoingSilent() {
    val carrier = FakeSink()
    val carrierSink = sink(carrier = carrier)
    val listener = RecordingSinkListener()
    carrierSink.setListener(listener)
    carrierSink.configure(audioSinkConfig())

    val buffer = ByteBuffer.wrap(fortyFourFamilyAccessUnits())
    val accepted = carrierSink.handleBuffer(buffer, 0L, 1)

    assertFalse("a mismatch must apply back pressure, not report success", accepted)
    assertEquals("the offending access unit must stay in the buffer", 0, buffer.position())
    assertEquals("the renderer must be asked to reselect", 1, listener.capabilityInvalidations)
    assertEquals(
      "TrueHD must now decode rather than ride the carrier",
      AudioSink.SINK_FORMAT_UNSUPPORTED,
      carrierSink.getFormatSupport(trueHdFormat())
    )
    assertEquals("nothing may reach the carrier delegate", 0, carrier.written.size())
  }

  /**
   * The DTS-HD equivalent: a bitstream whose framing the carrier cannot ride (an S/PDIF-style
   * little-endian capture) must latch onto the decoder, and the offending unit must survive.
   */
  @Test
  fun aDtsHdFramingMismatchLeavesTheCarrierInsteadOfGoingSilent() {
    val carrier = FakeSink()
    val carrierSink = sink(carrier = carrier)
    val listener = RecordingSinkListener()
    carrierSink.setListener(listener)
    carrierSink.configure(audioSinkConfig(dtsHdFormat()))

    val littleEndianCapture = byteArrayOf(0xFE.toByte(), 0x7F, 0x01, 0x80.toByte()) + ByteArray(64)
    val buffer = ByteBuffer.wrap(littleEndianCapture)
    val accepted = carrierSink.handleBuffer(buffer, 0L, 1)

    assertFalse("a mismatch must apply back pressure, not report success", accepted)
    assertEquals("the offending unit must stay in the buffer", 0, buffer.position())
    assertEquals("the renderer must be asked to reselect", 1, listener.capabilityInvalidations)
    assertEquals(
      "DTS-HD must now decode rather than ride the carrier or the raw path",
      AudioSink.SINK_FORMAT_UNSUPPORTED,
      carrierSink.getFormatSupport(dtsHdFormat())
    )
    assertEquals("nothing may reach the carrier delegate", 0, carrier.written.size())
  }

  /**
   * media3 resets every renderer disabled by a new selection before enabling the replacement, and
   * both audio renderers share this sink. That reset lands mid-handover, so a latch cleared there
   * would re-offer the carrier and loop straight back into the mismatch.
   */
  @Test
  fun theMismatchLatchSurvivesTheResetThatAccompaniesTheHandover() {
    val carrierSink = sink()
    carrierSink.setListener(RecordingSinkListener())
    carrierSink.configure(audioSinkConfig())
    carrierSink.handleBuffer(ByteBuffer.wrap(fortyFourFamilyAccessUnits()), 0L, 1)

    carrierSink.flush()
    carrierSink.reset()

    assertEquals(
      "the carrier must stay off across the handover",
      AudioSink.SINK_FORMAT_UNSUPPORTED,
      carrierSink.getFormatSupport(trueHdFormat())
    )
  }

  /** The latch is scoped to the sink, so a released sink starts clean. */
  @Test
  fun releasingTheSinkClearsTheMismatchLatch() {
    val carrierSink = sink()
    carrierSink.setListener(RecordingSinkListener())
    carrierSink.configure(audioSinkConfig())
    carrierSink.handleBuffer(ByteBuffer.wrap(fortyFourFamilyAccessUnits()), 0L, 1)

    carrierSink.release()

    assertEquals(
      AudioSink.SINK_FORMAT_SUPPORTED_DIRECTLY,
      carrierSink.getFormatSupport(trueHdFormat())
    )
  }

  /**
   * Genuine 44.1kHz TrueHD access units, encoder-produced. Flipping the rate nibble in a 48kHz
   * stream would invalidate the major sync checksum, which is not the case being modelled.
   */
  private val fortyFourFamilyUnits by lazy {
    checkNotNull(javaClass.classLoader?.getResourceAsStream("truehd_441_access_units.bin"))
      .use { it.readBytes() }
  }

  private fun fortyFourFamilyAccessUnits(): ByteArray = fortyFourFamilyUnits

  /**
   * The mismatch is a property of one stream. The owner signals the real boundary, because the sink
   * cannot see it: renderer resets and flushes happen constantly within a single item.
   */
  @Test
  fun aNewMediaItemClearsTheMismatchLatch() {
    val carrierSink = sink()
    carrierSink.setListener(RecordingSinkListener())
    carrierSink.configure(audioSinkConfig())
    carrierSink.handleBuffer(ByteBuffer.wrap(fortyFourFamilyAccessUnits()), 0L, 1)
    assertEquals(
      AudioSink.SINK_FORMAT_UNSUPPORTED,
      carrierSink.getFormatSupport(trueHdFormat())
    )

    carrierSink.beginMediaItem()

    assertEquals(
      "a new item must be able to bitstream again",
      AudioSink.SINK_FORMAT_SUPPORTED_DIRECTLY,
      carrierSink.getFormatSupport(trueHdFormat())
    )
  }

  /**
   * The boundary hook runs on the app thread while the mismatch is found on the playback thread, so
   * a buffer from the outgoing stream can be handled after the new item began. That write must name
   * the stream it came from rather than disabling the carrier for its successor.
   */
  @Test
  fun aLateMismatchFromThePreviousItemDoesNotPoisonTheNewOne() {
    val carrierSink = sink()
    carrierSink.setListener(RecordingSinkListener())
    carrierSink.configure(audioSinkConfig())

    // The new item starts before the outgoing stream's last buffer is handled.
    carrierSink.beginMediaItem()
    carrierSink.handleBuffer(ByteBuffer.wrap(fortyFourFamilyAccessUnits()), 0L, 1)

    assertEquals(
      "the stale mismatch belongs to the previous item",
      AudioSink.SINK_FORMAT_SUPPORTED_DIRECTLY,
      carrierSink.getFormatSupport(trueHdFormat())
    )
  }

  /** Everything that is not a carrier codec keeps going to the existing processed sink. */
  @Test
  fun otherFormatsAreLeftToTheNormalSink() {
    val normal = FakeSink().apply { formatSupport = AudioSink.SINK_FORMAT_SUPPORTED_DIRECTLY }
    val carrierSink = sink(normal = normal)
    val ac3 = Format.Builder().setSampleMimeType(MimeTypes.AUDIO_AC3).setSampleRate(48_000).build()

    assertEquals(AudioSink.SINK_FORMAT_SUPPORTED_DIRECTLY, carrierSink.getFormatSupport(ac3))
    assertTrue(carrierSink.supportsFormat(ac3))
  }

  /**
   * The regression this exists for: a delegate that refuses a burst part-way through a sample must
   * not cost the access units behind it. media3 re-delivers the same buffer after a false return,
   * so the carrier has to resume from where it stopped and come out byte-identical.
   */
  @Test
  fun aRefusedBurstMidSampleLosesNoAccessUnits() {
    val carrier = FakeSink()
    val carrierSink = sink(carrier = carrier)
    carrierSink.configure(audioSinkConfig())

    // Refuse every third burst once, so rejections land inside samples rather than between them.
    carrier.refuseEveryNth = 3

    val produced = feedWholeStream(carrierSink, accessUnits)
    assertArrayEquals("carrier output must survive back pressure unchanged", golden, produced)
    assertTrue("the fake must actually have exercised the refusal path", carrier.refusals > 0)
  }

  /** With no back pressure the same stream must produce exactly the same bytes. */
  @Test
  fun theCarrierOutputMatchesTheGoldenStream() {
    val carrier = FakeSink()
    val carrierSink = sink(carrier = carrier)
    carrierSink.configure(audioSinkConfig())

    assertArrayEquals(golden, feedWholeStream(carrierSink, accessUnits))
  }

  /** A DTS-HD stream must select the DTS packer and come out matching FFmpeg's bytes. */
  @Test
  fun theDtsHdCarrierOutputMatchesTheGoldenStream() {
    val carrier = FakeSink()
    val carrierSink = sink(carrier = carrier)
    carrierSink.configure(audioSinkConfig(dtsHdFormat()))

    assertArrayEquals(dtsHdGolden, feedWholeStream(carrierSink, dtsHdAccessUnits))
  }

  /** Back pressure must not cost DTS-HD units either; bursts and units are one-to-one there. */
  @Test
  fun aRefusedDtsHdBurstLosesNoAccessUnits() {
    val carrier = FakeSink()
    val carrierSink = sink(carrier = carrier)
    carrierSink.configure(audioSinkConfig(dtsHdFormat()))
    carrier.refuseEveryNth = 3

    val produced = feedWholeStream(carrierSink, dtsHdAccessUnits)
    assertArrayEquals(dtsHdGolden, produced)
    assertTrue(carrier.refusals > 0)
  }

  /**
   * Burst timestamps come from the carrier cadence, not the closing access unit. A DTS-HD burst is
   * 10666.67us of carrier — not a whole number — so the cadence must be derived from cumulative
   * carrier frames; per-burst rounding would drift ~62ms over a movie.
   */
  @Test
  fun dtsHdBurstTimestampsFollowTheExactCarrierCadence() {
    val carrier = FakeSink()
    val carrierSink = sink(carrier = carrier)
    carrierSink.configure(audioSinkConfig(dtsHdFormat()))

    feedWholeStream(carrierSink, dtsHdAccessUnits)

    val framesPerBurst = 32768L / IecCarrier.BYTES_PER_FRAME
    carrier.bufferTimesUs.forEachIndexed { index, timeUs ->
      assertEquals(
        "burst $index timestamp",
        index * framesPerBurst * 1_000_000L / IecCarrier.SAMPLE_RATE,
        timeUs
      )
    }
  }

  /** A refused burst must be re-offered before any further input is taken. */
  @Test
  fun aPendingBurstIsPlacedBeforeMoreInputIsConsumed() {
    val carrier = FakeSink()
    val carrierSink = sink(carrier = carrier)
    carrierSink.configure(audioSinkConfig())
    carrier.refuseNext = true

    val buffer = ByteBuffer.wrap(accessUnits)
    // Drive until the first refusal is observed.
    while (buffer.hasRemaining() && carrierSink.handleBuffer(buffer, 0L, 1)) Unit

    assertTrue("expected a refusal to leave input unconsumed", buffer.hasRemaining())
    assertTrue(carrierSink.hasPendingData())
  }

  @Test
  fun persistentControlsReachBothDelegates() {
    val carrier = FakeSink()
    val normal = FakeSink()
    val carrierSink = sink(carrier = carrier, normal = normal)

    carrierSink.setVolume(0.5f)
    carrierSink.setAudioSessionId(7)

    assertEquals(0.5f, carrier.lastVolume, 0f)
    assertEquals(0.5f, normal.lastVolume, 0f)
    assertEquals(7, carrier.sessionId)
    assertEquals(7, normal.sessionId)
  }

  /** Silence skipping deletes "silent" bytes, which would break the carrier's frame cadence. */
  @Test
  fun silenceSkippingNeverReachesTheCarrier() {
    val carrier = FakeSink()
    val normal = FakeSink()
    val carrierSink = sink(carrier = carrier, normal = normal)

    carrierSink.setSkipSilenceEnabled(true)

    assertTrue(normal.skipSilence)
    assertFalse("the carrier delegate must never skip silence", carrier.skipSilence)
  }

  @Test
  fun theCarrierDelegateIsConfiguredAsAFixedRatePcmCarrier() {
    val carrier = FakeSink()
    val carrierSink = sink(carrier = carrier)
    val inputConfig = AudioSink.AudioSinkConfig.Builder(trueHdFormat())
      .setPreferredBufferSizeOverride(4_096)
      .setTimeline(Timeline.EMPTY)
      .setMediaPeriodId(MediaSource.MediaPeriodId("period"))
      .build()

    carrierSink.configure(inputConfig)

    val configured = checkNotNull(carrier.configuredConfig)
    assertEquals(inputConfig.preferredBufferSizeOverride, configured.preferredBufferSizeOverride)
    assertSame(inputConfig.timeline, configured.timeline)
    assertEquals(inputConfig.mediaPeriodId, configured.mediaPeriodId)
    assertEquals(MimeTypes.AUDIO_RAW, configured.format.sampleMimeType)
    assertEquals(C.ENCODING_PCM_16BIT, configured.format.pcmEncoding)
    assertEquals(IecCarrier.SAMPLE_RATE, configured.format.sampleRate)
    assertEquals(IecCarrier.CHANNEL_COUNT, configured.format.channelCount)
  }

  /** DTS-HD rides the same PCM-shaped carrier tuple TrueHD does. */
  @Test
  fun theDtsHdCarrierDelegateIsConfiguredAsAFixedRatePcmCarrier() {
    val carrier = FakeSink()
    val carrierSink = sink(carrier = carrier)

    carrierSink.configure(audioSinkConfig(dtsHdFormat()))

    val configured = checkNotNull(carrier.configuredConfig)
    assertEquals(MimeTypes.AUDIO_RAW, configured.format.sampleMimeType)
    assertEquals(C.ENCODING_PCM_16BIT, configured.format.pcmEncoding)
    assertEquals(IecCarrier.SAMPLE_RATE, configured.format.sampleRate)
    assertEquals(IecCarrier.CHANNEL_COUNT, configured.format.channelCount)
  }

  @Test
  fun nonCarrierAudioIsConfiguredOnTheNormalSink() {
    val carrier = FakeSink()
    val normal = FakeSink()
    val carrierSink = sink(carrier = carrier, normal = normal)
    val ac3 = Format.Builder().setSampleMimeType(MimeTypes.AUDIO_AC3).setSampleRate(48_000).build()
    val config = audioSinkConfig(ac3)

    carrierSink.configure(config)

    assertSame(config, normal.configuredConfig)
    assertSame(ac3, normal.configuredConfig?.format)
    assertEquals(null, carrier.configuredConfig)
  }

  private fun feedWholeStream(carrierSink: IecCarrierSink, units: ByteArray): ByteArray {
    val buffer = ByteBuffer.wrap(units)
    var guard = 0
    // media3 retries handleBuffer until it returns true, even once the buffer is fully consumed;
    // a refusal of the stream's final burst leaves it pending with nothing remaining to read.
    while ((buffer.hasRemaining() || carrierSink.hasPendingData()) && guard++ < 10_000) {
      carrierSink.handleBuffer(buffer, 0L, 1)
    }
    val carrier = carrierSinkDelegate(carrierSink)
    return carrier.written.toByteArray()
  }

  private fun carrierSinkDelegate(sink: IecCarrierSink): FakeSink {
    val field = IecCarrierSink::class.java.getDeclaredField("carrierSink")
    field.isAccessible = true
    return field.get(sink) as FakeSink
  }

  private class RecordingSinkListener : AudioSink.Listener {
    var capabilityInvalidations = 0
    override fun onPositionDiscontinuity() = Unit
    override fun onPositionAdvancing(playoutStartSystemTimeMs: Long) = Unit
    override fun onUnderrun(bufferSize: Int, bufferSizeMs: Long, elapsedSinceLastFeedMs: Long) = Unit
    override fun onSkipSilenceEnabledChanged(skipSilenceEnabled: Boolean) = Unit
    override fun onAudioSinkError(audioSinkError: Exception) = Unit
    override fun onAudioCapabilitiesChanged() {
      capabilityInvalidations++
    }
  }

  /** Minimal AudioSink that records what it was handed and can apply back pressure. */
  private class FakeSink : AudioSink {
    val written = ByteArrayOutputStream()
    val bufferTimesUs = mutableListOf<Long>()
    var configuredConfig: AudioSink.AudioSinkConfig? = null
    var formatSupport: Int = AudioSink.SINK_FORMAT_UNSUPPORTED
    var lastVolume: Float = -1f
    var sessionId: Int = -1
    var skipSilence: Boolean = false
    var refuseNext: Boolean = false
    var refuseEveryNth: Int = 0
    var refusals: Int = 0
    var lastPlaybackParameters: PlaybackParameters = PlaybackParameters.DEFAULT
    private var offered = 0

    override fun handleBuffer(buffer: ByteBuffer, presentationTimeUs: Long, encodedAccessUnitCount: Int): Boolean {
      offered++
      val refuse = refuseNext || (refuseEveryNth > 0 && offered % refuseEveryNth == 0)
      if (refuse) {
        refuseNext = false
        refusals++
        // Refuse once per burst: the retry must be accepted or the stream cannot progress.
        offered++
        return false
      }
      val copy = ByteArray(buffer.remaining())
      buffer.duplicate().get(copy)
      written.write(copy)
      bufferTimesUs.add(presentationTimeUs)
      buffer.position(buffer.limit())
      return true
    }

    override fun configure(audioSinkConfig: AudioSink.AudioSinkConfig) {
      configuredConfig = audioSinkConfig
    }

    override fun supportsFormat(format: Format) = formatSupport == AudioSink.SINK_FORMAT_SUPPORTED_DIRECTLY
    override fun getFormatSupport(format: Format) = formatSupport
    override fun setVolume(volume: Float) {
      lastVolume = volume
    }
    override fun setAudioSessionId(audioSessionId: Int) {
      sessionId = audioSessionId
    }
    override fun setSkipSilenceEnabled(skipSilenceEnabled: Boolean) {
      skipSilence = skipSilenceEnabled
    }
    override fun getSkipSilenceEnabled() = skipSilence

    override fun setListener(listener: AudioSink.Listener) = Unit
    override fun setPlayerId(playerId: PlayerId?) = Unit
    override fun setClock(clock: Clock) = Unit
    override fun getCurrentPositionUs(sourceEnded: Boolean) = 0L
    override fun play() = Unit
    override fun handleDiscontinuity() = Unit
    override fun playToEndOfStream() = Unit
    override fun isEnded() = false
    override fun hasPendingData() = false
    override fun setPlaybackParameters(playbackParameters: PlaybackParameters) {
      lastPlaybackParameters = playbackParameters
    }
    override fun getPlaybackParameters(): PlaybackParameters = PlaybackParameters.DEFAULT
    override fun setAudioAttributes(audioAttributes: AudioAttributes) = Unit
    override fun getAudioAttributes(): AudioAttributes? = null
    override fun setAuxEffectInfo(auxEffectInfo: AuxEffectInfo) = Unit
    override fun setPreferredDevice(audioDeviceInfo: AudioDeviceInfo?) = Unit
    override fun getAudioTrackBufferSizeUs() = 0L
    override fun enableTunnelingV21() = Unit
    override fun disableTunneling() = Unit
    override fun pause() = Unit
    override fun flush() = Unit
    override fun reset() = Unit
  }
}
