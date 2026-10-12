import AVFoundation
import Libmpv
import SpatialAudioBridge
import SpatialAudioPlayback
import Synchronization

/// Plays the TrueHD and DTS-HD passthrough of mpv's `spatial` output as Apple
/// spatial audio, rendered into the synchronizer mpv keeps its clock on.
///
/// The library converts only TrueHD Atmos and DTS:X and throws for anything
/// else once decoding starts; `has_failed` then has mpv decode it to PCM.
@available(iOS 26, tvOS 26, *)
final class SpatialAudioSink {
  /// The address mpv takes as `ao-spatial-sink`, valid while this lives.
  var address: Int64 { Int64(Int(bitPattern: callbacks)) }

  private let callbacks = UnsafeMutablePointer<mpv_spatial_audio_sink>.allocate(capacity: 1)
  private let state = Mutex(State())

  private struct State {
    var renderer: SpatialAudioRenderer?
    var activator: AtmosOutputActivator?
    /// Feeds the current timeline; replaced on every begin().
    var timeline: Timeline?
    var generation = 0
    var readyGeneration = -1
    var failed = false
    /// mpv's software volume, which never reaches the bitstream.
    var volume: Float = 1
    var volumeUpdate: Task<Void, Never>?
  }

  private struct Timeline {
    let bursts: AsyncStream<Data>.Continuation
    let feeder: Task<Void, Never>
  }

  init() {
    callbacks.initialize(
      to: mpv_spatial_audio_sink(
        version: Int32(MPV_SPATIAL_AUDIO_SINK_VERSION),
        ctx: nil,
        open: { ctx, codec, synchronizer in
          SpatialAudioSink.from(ctx).open(codec, synchronizer)
        },
        begin: { ctx, time in SpatialAudioSink.from(ctx).begin(at: time) },
        write: { ctx, data, size in
          guard let data else { return }
          SpatialAudioSink.from(ctx).write(Data(bytes: data, count: size))
        },
        is_ready: { ctx in
          SpatialAudioSink.from(ctx).state.withLock { $0.readyGeneration == $0.generation }
        },
        has_failed: { ctx in SpatialAudioSink.from(ctx).state.withLock { $0.failed } },
        close: { ctx in SpatialAudioSink.from(ctx).close() },
        end: { ctx in SpatialAudioSink.from(ctx).end() },
        set_volume: { ctx, volume in SpatialAudioSink.from(ctx).setVolume(volume) }
      ))
    callbacks.pointee.ctx = Unmanaged.passUnretained(self).toOpaque()
  }

  deinit {
    callbacks.deinitialize(count: 1)
    callbacks.deallocate()
  }

  private static func from(_ ctx: UnsafeMutableRawPointer?) -> SpatialAudioSink {
    Unmanaged<SpatialAudioSink>.fromOpaque(ctx!).takeUnretainedValue()
  }

  // MARK: - mpv's output, never concurrently except set_volume

  private func open(_ codec: mpv_spatial_audio_codec, _ synchronizerAddress: UnsafeMutableRawPointer?) -> Bool {
    guard let synchronizerAddress else { return false }
    let codec: SpatialAudioCodec = codec == MPV_SPATIAL_AUDIO_CODEC_TRUEHD ? .trueHDAtmos : .dtsX
    let synchronizer = Unmanaged<AVSampleBufferRenderSynchronizer>.fromOpaque(synchronizerAddress)
      .takeUnretainedValue()
    let renderer: SpatialAudioRenderer
    do {
      renderer = try SpatialAudioRenderer(codec: codec, synchronizer: synchronizer)
    } catch {
      MpvLog.error("[SpatialAudioSink] Cannot render \(codec): \(error)")
      return false
    }
    state.withLock { $0.renderer = renderer }
    // The activator follows the synchronizer's rate, which mpv starts only
    // once audio is queued.
    Task { @MainActor [weak self] in
      // Multichannel content, as avfoundation's compressed sink sets it.
      do {
        try AtmosOutputActivator.configureAudioSession()
      } catch {
        MpvLog.error("[SpatialAudioSink] Falling back to PCM: \(error)")
        self?.state.withLock { state in
          if state.renderer === renderer { state.failed = true }
        }
        return
      }
      let activator = AtmosOutputActivator()
      activator.attach(to: synchronizer)
      // mpv may have closed and reopened the output by now.
      let current =
        self?.state.withLock { state in
          guard state.renderer === renderer else { return false }
          state.activator = activator
          return true
        } ?? false
      if !current { activator.detach() }
    }
    MpvLog.debug("[SpatialAudioSink] Playing \(codec) as APAC")
    return true
  }

  /// A new timeline after open, a seek or a reset.
  private func begin(at nanoseconds: Int64) {
    let time = CMTime(value: nanoseconds, timescale: 1_000_000_000)
    let (bursts, input) = AsyncStream<Data>.makeStream()
    state.withLock { state in
      state.generation += 1
      let generation = state.generation
      let previous = state.timeline
      previous?.bursts.finish()
      previous?.feeder.cancel()
      guard let renderer = state.renderer else { return }
      let feeder = Task { [weak self] in
        guard let self else { return }
        await self.feed(bursts, into: renderer, from: time, after: previous?.feeder, generation: generation)
      }
      state.timeline = Timeline(bursts: input, feeder: feeder)
    }
  }

  private func write(_ bursts: Data) {
    _ = state.withLock { $0.timeline }?.bursts.yield(bursts)
  }

  /// mpv's volume and mute as one gain; the renderer clamps it to 1.
  private func setVolume(_ volume: Float) {
    state.withLock { state in
      state.volume = volume
      guard let renderer = state.renderer else { return }
      // Each update waits for the previous one, so the latest volume lands last.
      let previous = state.volumeUpdate
      state.volumeUpdate = Task { [weak self] in
        await previous?.value
        guard let volume = self?.state.withLock({ $0.volume }) else { return }
        await renderer.setVolume(volume)
      }
    }
  }

  /// The feeder then flushes what the renderer holds back.
  private func end() {
    state.withLock { $0.timeline }?.bursts.finish()
  }

  private func close() {
    let (timeline, renderer, activator) = state.withLock { state in
      defer {
        // This session's feeders must not pass for the next one.
        state = State(generation: state.generation + 1)
      }
      return (state.timeline, state.renderer, state.activator)
    }
    timeline?.bursts.finish()
    timeline?.feeder.cancel()
    // Releases an enqueue the feeder may still be waiting in.
    if let renderer {
      Task { try? await renderer.begin(at: .zero) }
    }
    if let activator {
      Task { @MainActor in activator.detach() }
    }
  }

  // MARK: - Feeding the renderer

  private func feed(
    _ bursts: AsyncStream<Data>, into renderer: SpatialAudioRenderer, from time: CMTime,
    after previous: Task<Void, Never>?, generation: Int
  ) async {
    do {
      // Release an enqueue the previous feeder may be waiting in, then drop
      // what it queued before it stopped.
      try await renderer.begin(at: time)
      await previous?.value
      try await renderer.begin(at: time)
      var unpacker = IEC61937Unpacker()
      var ready = false
      var enqueued = false
      for await chunk in bursts {
        let stream = try unpacker.unpack(chunk)
        guard !stream.isEmpty else { continue }
        // The unpacker drops TrueHD before the first major sync, which mpv's
        // clock still counts.
        try await renderer.enqueue(stream, time: time + unpacker.skippedDuration)
        enqueued = true
        if !ready, await renderer.isReadyToPlay {
          ready = true
          markReady(generation)
          let outputs = AVAudioSession.sharedInstance().currentRoute.outputs
            .map { "\($0.portType.rawValue) spatial=\($0.isSpatialAudioEnabled)" }
          MpvLog.debug("[SpatialAudioSink] Rendering to \(outputs)")
        }
      }
      // The encoder holds back its last 1.5 s until flushed.
      guard !Task.isCancelled, enqueued else { return }
      do {
        try unpacker.finish()
      } catch {
        // What arrived still plays.
        MpvLog.debug("[SpatialAudioSink] The stream ended mid-unit: \(error)")
      }
      try await renderer.endOfStream()
      markReady(generation)
    } catch is CancellationError {
    } catch {
      let current = state.withLock { state in
        guard state.generation == generation else { return false }
        state.failed = true
        return true
      }
      if current { MpvLog.error("[SpatialAudioSink] Falling back to PCM: \(error)") }
    }
  }

  private func markReady(_ generation: Int) {
    state.withLock { state in
      if state.generation == generation { state.readyGeneration = generation }
    }
  }
}
