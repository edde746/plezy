import os
import PlezyKit

/// One playback's output on Apple platforms (the shared `PlaybackOutput` drives it: the policy is shared, the switching
/// native). tvOS's `AVDisplayManager` picks the TV's mode from the criteria the surface writes, and iOS hands an app no
/// display modes; iOS and macOS show HDR per layer (EDR) without a display switch. So the display reports its HDR as on
/// wherever it can show HDR, and modes only on the Mac (the refresh-rate variants of the window's display's current
/// mode, `DisplayModeSwitch`). Each plan goes to the surface, which turns its HDR and frame-rate decisions into criteria
/// (tvOS), EDR (iOS) or EDR and the plan's mode (macOS) for the video on it, and to the engine: its HDR output
/// (`target-colorspace-hint`) and its passthrough (the formats the system's outputs take undecoded).
@MainActor
final class ApplePlaybackOutput: @preconcurrency PlaybackOutputHost {
    private let surface: VideoSurface
    private let engine: MpvPlayerEngine
    /// Bumped by every `restore`. A plan whose engine step straddles a restore (the player closed or the video was
    /// suspended while mpv took the HDR output) would otherwise set its mode after the restore found nothing to undo,
    /// and the display would keep the playback's rate.
    private nonisolated let restores = OSAllocatedUnfairLock(initialState: 0)

    init(surface: VideoSurface, engine: MpvPlayerEngine) {
        self.surface = surface
        self.engine = engine
    }

    /// Apple switches at the first frame: tvOS from the criteria the surface writes for the video, the Mac with its
    /// video held (`apply`).
    nonisolated var switchesBeforeOpen: Bool { false }

    /// Nothing switches before the open here, so no decoder is held for a switch.
    nonisolated func holdDecoder() -> (any DecoderHold)? { nil }

    /// The display (SKIE exposes the Kotlin `suspend fun display` as this async requirement), read on the main actor.
    nonisolated func __display() async throws -> DisplayInfo {
        #if os(macOS)
        let (hdr, modes) = await MainActor.run { (ApplePlatform.hdrOutputSupported, self.surface.modes()) }
        return DisplayInfo(modes: modes?.variants.map(\.displayMode) ?? [], current: modes?.current.displayMode, hdrSupported: hdr, hdrEnabled: hdr)
        #else
        let hdr = await MainActor.run { ApplePlatform.hdrOutputSupported }
        return DisplayInfo(modes: [], current: nil, hdrSupported: hdr, hdrEnabled: hdr)
        #endif
    }

    /// Follows `plan` and returns once the display has settled for it: on tvOS once a switch of the TV's mode the
    /// criteria started has ended (and the display switch delay after it, `DisplayCriteria`); on the Mac once the plan's
    /// mode is set, and after a switch the display switch delay later, the playing video held meanwhile
    /// (`MpvPlayerEngine.holdForDisplaySwitch`); on iOS at once. The engine's HDR output goes first; the answer is whether
    /// mpv took it (the player's HDR switch, an input to the plan, goes back on a refusal). A plan that a restore overtook
    /// (`restores`) or that was cancelled before it reached the surface leaves the display alone.
    nonisolated func __apply(plan: OutputPlan) async throws -> KotlinBoolean {
        let box = UncheckedBox(plan)
        // Read before the cancellation check: the playback cancels its plans before it restores, so a restore that came
        // first shows as the cancellation.
        let epoch = restores.withLock { $0 }
        if Task.isCancelled { return KotlinBoolean(value: false) }
        let hdrTaken = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            engine.setHdrOutput(enabled: plan.hdrOutput) { continuation.resume(returning: $0.boolValue) }
        }
        #if os(macOS)
        let switched = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            Task { @MainActor in
                guard self.restores.withLock({ $0 }) == epoch else { return continuation.resume(returning: false) }
                self.follow(box.value)
                self.surface.apply(box.value) { continuation.resume(returning: $0) }
            }
        }
        let delay = Int(plan.switchDelaySeconds)
        if switched, delay > 0 {
            engine.holdForDisplaySwitch(seconds: delay)
            try await Task.sleep(for: .seconds(delay))
        }
        #else
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            Task { @MainActor in
                guard self.restores.withLock({ $0 }) == epoch else { return continuation.resume() }
                self.follow(box.value)
                self.surface.apply(box.value) { continuation.resume() }
            }
        }
        #endif
        return KotlinBoolean(value: hdrTaken)
    }

    /// The engine's side of `plan` past its HDR output (`__apply` writes that first, and answers with mpv's reply): its
    /// passthrough and its Dolby Vision conversion.
    private func follow(_ plan: OutputPlan) {
        engine.setAudioPassthrough(plan.audioPassthrough)
        engine.setDolbyVisionConversion(mode: plan.dolbyVisionConversion)
    }

    func restore() {
        restores.withLock { $0 += 1 }
        surface.resetDisplay()
    }
}
