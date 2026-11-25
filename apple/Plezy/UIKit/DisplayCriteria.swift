#if os(tvOS)
import AVFoundation
import AVKit
import CoreMedia
import OSLog
import PlezyKit

private let log = Logger(subsystem: "com.edde746.plezy", category: "display")

/// What `DisplayCriteria` asks of the display: the window's `AVDisplayManager`, or in debug builds the simulated one
/// (`SimulatedMatchContent`), since AVKit lets an app neither make nor subclass a display manager.
protocol DisplayManaging: AnyObject {
    var isDisplayCriteriaMatchingEnabled: Bool { get }
    var isDisplayModeSwitchInProgress: Bool { get }
    var preferredDisplayCriteria: AVDisplayCriteria? { get set }
}

extension AVDisplayManager: DisplayManaging {}

/// tvOS display-mode matching: asks the TV, through `AVDisplayManager`, for a dynamic range (SDR, HDR10, HLG, Dolby
/// Vision) and a refresh rate, as the shared `AppleDisplayCriteria` decided them for the decoded video (the surface
/// passes them in). tvOS honours them only when the user has turned on Match Content (Settings → Video and Audio); a
/// change blanks the HDMI link for a few seconds, so `apply` completes once the display has settled: any switch it
/// started, or one still under way, has ended, plus the user's display switch delay. One for the app (`VideoSurface`):
/// the TV has one mode, so the criteria stay between files and from a playback to the one that replaces it, and are
/// cleared when the playback ends.
///
/// The tvOS simulator's display manager reports matching off, so there `apply` only clears and completes; the
/// criteria written, the mode switch and the wait for it run on an Apple TV, and in debug builds on the simulated one
/// (`SimulatedMatchContent`).
@MainActor
final class DisplayCriteria {
    /// What was last asked of the display; the same request is not written twice.
    private struct Mode: Equatable {
        var range: DynamicRange
        var refreshRate: Float
        var width: Int
        var height: Int
        var doviProfile: Int
        var doviLevel: Int
        var doviCompatibility: Int?

        /// `HDR10@23.976 3840x2160 dovi=8.6/1` (the compatibility id `-` where unknown).
        var summary: String {
            let rate = String(format: "%.3f", refreshRate)
            return "\(range.name)@\(rate) \(width)x\(height) dovi=\(doviProfile).\(doviLevel)/\(doviCompatibility.map(String.init) ?? "-")"
        }
    }

    private var active: Mode?
    /// The display manager the criteria went to, which `clear` hands the TV's own mode back through.
    private weak var manager: (any DisplayManaging)?
    private var waiter: ModeSwitchWaiter?

    /// The dynamic range and refresh rate the TV was last asked for; nil while no criteria are out.
    var requested: (range: DynamicRange, refreshRate: Double)? {
        active.map { ($0.range, Double($0.refreshRate)) }
    }

    /// Logs the system's own account of the display beside the criteria written, cleared and waited for: each mode
    /// switch's start and end, and Match Content turned on or off, each with the manager's
    /// `isDisplayCriteriaMatchingEnabled` and `isDisplayModeSwitchInProgress` then. On an Apple TV the log then shows
    /// how often the TV switched for a playback, and that its file started after the switch.
    init() {
        for (name, event) in [
            (Notification.Name.AVDisplayManagerModeSwitchStart, "mode switch started"),
            (.AVDisplayManagerModeSwitchEnd, "mode switch ended"),
            (.AVDisplayManagerModeSwitchSettingsChanged, "Match Content settings changed"),
        ] {
            _ = NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { note in
                let manager = note.object as? any DisplayManaging
                let matching = manager.map { String($0.isDisplayCriteriaMatchingEnabled) } ?? "unknown"
                let switching = manager.map { String($0.isDisplayModeSwitchInProgress) } ?? "unknown"
                log.notice(
                    """
                    display \(event, privacy: .public) (matching \(matching, privacy: .public), \
                    switch in progress \(switching, privacy: .public))
                    """
                )
            }
        }
    }

    /// Asks for `criteria` (nil: the TV's own mode) and calls `completion` once the display has settled for it, then
    /// `extraDelay` milliseconds more after a switch (the display switch delay, 0 to 10 000). A Dolby Vision request
    /// the system can't describe asks for the video's base layer range instead. A request doesn't end the wait of one
    /// before it: asking for the same mode, it waits with it (a switch that mode started may not show as in progress
    /// yet); asking for another, the earlier callers wait for the new switch too. So nobody starts during either
    /// switch.
    func apply(
        _ criteria: AppleDisplayCriteria?,
        extraDelay: Int,
        manager: any DisplayManaging,
        completion: @escaping @Sendable () -> Void
    ) {
        self.manager = manager
        guard manager.isDisplayCriteriaMatchingEnabled else {
            log.notice("Match Content is off (isDisplayCriteriaMatchingEnabled false): the display mode stays as it is")
            clear(reason: "matching disabled")
            return completion()
        }
        guard let criteria else {
            clear(reason: "no display metadata")
            return completion()
        }
        var range = criteria.range
        var description = Self.formatDescription(range: range, criteria: criteria)
        if description == nil, range == .dolbyVision {
            range = criteria.baseRange
            description = Self.formatDescription(range: range, criteria: criteria)
        }
        guard let description else {
            clear(reason: "format description failed")
            return completion()
        }
        let refreshRate = Float(criteria.refreshRate)
        let mode = Mode(
            range: range,
            refreshRate: refreshRate,
            width: Int(criteria.width),
            height: Int(criteria.height),
            doviProfile: Int(criteria.doviProfile),
            doviLevel: Int(criteria.doviLevel),
            doviCompatibility: criteria.doviCompatibility?.intValue
        )
        let extraDelay = min(max(extraDelay, 0), 10_000)
        if mode == active, manager.preferredDisplayCriteria != nil {
            if let waiter, waiter.join(completion) { return }
            let waiter = ModeSwitchWaiter(manager: manager, extraDelay: extraDelay, completions: [completion])
            self.waiter = waiter
            waiter.start(afterWrite: false)
            return
        }
        manager.preferredDisplayCriteria = AVDisplayCriteria(refreshRate: refreshRate, formatDescription: description)
        active = mode
        #if DEBUG
        DisplaySwitchReading.shared.rate = Int((Double(refreshRate) * 1000).rounded())
        DisplaySwitchReading.shared.criteria = mode.summary
        #endif
        log.notice("preferredDisplayCriteria \(mode.summary, privacy: .public) (source \(criteria.range.name, privacy: .public))")
        let waiter = ModeSwitchWaiter(manager: manager, extraDelay: extraDelay, completions: (self.waiter?.handOver() ?? []) + [completion])
        self.waiter = waiter
        waiter.start(afterWrite: true)
    }

    /// Gives the TV its own mode back (the playback ended, or matching is off or impossible); whoever waits for the
    /// display is completed at once.
    func clear(reason: String) {
        waiter?.cancel()
        waiter = nil
        guard active != nil || manager?.preferredDisplayCriteria != nil else { return }
        manager?.preferredDisplayCriteria = nil
        active = nil
        log.notice("preferredDisplayCriteria cleared (\(reason, privacy: .public))")
    }

    /// A format description that only describes the mode wanted (it is never enqueued): HEVC with the range's
    /// colour tags, or a synthetic `dvh1` with a Dolby Vision configuration record.
    private static func formatDescription(range: DynamicRange, criteria: AppleDisplayCriteria) -> CMVideoFormatDescription? {
        let width = criteria.width
        let height = criteria.height
        var codec = kCMVideoCodecType_HEVC
        var extensions: [CFString: Any]
        switch range {
        case .sdr:
            extensions = [
                kCMFormatDescriptionExtension_ColorPrimaries: kCMFormatDescriptionColorPrimaries_ITU_R_709_2,
                kCMFormatDescriptionExtension_TransferFunction: kCMFormatDescriptionTransferFunction_ITU_R_709_2,
                kCMFormatDescriptionExtension_YCbCrMatrix: kCMFormatDescriptionYCbCrMatrix_ITU_R_709_2,
            ]
        case .hdr10, .hlg:
            extensions = [
                kCMFormatDescriptionExtension_ColorPrimaries: kCMFormatDescriptionColorPrimaries_ITU_R_2020,
                kCMFormatDescriptionExtension_TransferFunction: range == .hlg
                    ? kCMFormatDescriptionTransferFunction_ITU_R_2100_HLG
                    : kCMFormatDescriptionTransferFunction_SMPTE_ST_2084_PQ,
                kCMFormatDescriptionExtension_YCbCrMatrix: kCMFormatDescriptionYCbCrMatrix_ITU_R_2020,
            ]
        case .dolbyVision:
            let profile = Int(criteria.doviProfile)
            guard profile > 0 else { return nil }
            // Profile 8 without a known compatibility id is almost always HDR10-based (mpv does not expose the id).
            let compatibility = criteria.doviCompatibility?.intValue ?? (profile == 8 ? 1 : 0)
            let record = doviConfigurationRecord(profile: profile, level: Int(criteria.doviLevel), compatibility: compatibility)
            codec = kCMVideoCodecType_DolbyVisionHEVC
            extensions = [
                kCMFormatDescriptionExtension_SampleDescriptionExtensionAtoms:
                    [(profile > 7 ? "dvvC" : "dvcC") as CFString: record as CFData] as CFDictionary,
                kCMFormatDescriptionExtension_ColorPrimaries: kCMFormatDescriptionColorPrimaries_ITU_R_2020,
                kCMFormatDescriptionExtension_TransferFunction: kCMFormatDescriptionTransferFunction_SMPTE_ST_2084_PQ,
                kCMFormatDescriptionExtension_YCbCrMatrix: kCMFormatDescriptionYCbCrMatrix_ITU_R_2020,
            ]
        }
        var description: CMVideoFormatDescription?
        let status = CMVideoFormatDescriptionCreate(
            allocator: kCFAllocatorDefault,
            codecType: codec,
            width: width,
            height: height,
            extensions: extensions as CFDictionary,
            formatDescriptionOut: &description
        )
        return status == noErr ? description : nil
    }

    /// The 24-byte Dolby Vision decoder configuration record (ETSI TS 103 572 §7.1.1; the packing FFmpeg's
    /// VideoToolbox patch in mpv-build uses): version 1.0, then profile, level and the RPU/BL present flags, then the
    /// base layer's compatibility id.
    private static func doviConfigurationRecord(profile: Int, level: Int, compatibility: Int) -> Data {
        var record = [UInt8](repeating: 0, count: 24)
        record[0] = 1
        let flags = UInt16(profile & 0x7f) << 9 | UInt16(level & 0x3f) << 3 | 1 << 2 | 1 << 0
        record[2] = UInt8(flags >> 8)
        record[3] = UInt8(flags & 0xff)
        record[4] = UInt8(compatibility & 0x0f) << 4
        return Data(record)
    }
}

/// Completes its callers once a display mode switch that may follow a criteria write has ended, plus a short settle and
/// the display switch delay (`extraDelay`, in milliseconds); at
/// once when none is coming. `isDisplayModeSwitchInProgress` lags the start notification (measured 26 ms on tvOS
/// 26), so after a write the waiter listens for the start for a short window before trusting the flag, and a watchdog
/// ends any wait. Callers join it until it completes them, settle included, or until it hands them on to the wait for a
/// newer write; cancelled, it completes them at once. Each caller completes exactly once.
@MainActor
private final class ModeSwitchWaiter {
    private static let startWindow: DispatchTimeInterval = .milliseconds(500)
    private static let watchdog: DispatchTimeInterval = .seconds(8)
    private static let settle = 200

    private weak var manager: (any DisplayManaging)?
    private let extraDelay: Int
    /// Who waits for the display; empty once they are completed or handed on.
    private var completions: [@Sendable () -> Void]
    private var observers: [NSObjectProtocol] = []
    private var timers: [DispatchWorkItem] = []

    init(manager: any DisplayManaging, extraDelay: Int, completions: [@Sendable () -> Void]) {
        self.manager = manager
        self.extraDelay = extraDelay
        self.completions = completions
    }

    func start(afterWrite: Bool) {
        if manager?.isDisplayModeSwitchInProgress == true { return waitForEnd(reason: "already switching") }
        guard afterWrite else { return finish(waited: false, reason: "no switch") }
        observe(.AVDisplayManagerModeSwitchStart) { $0.waitForEnd(reason: "start notification") }
        schedule(after: Self.startWindow) { waiter in
            if waiter.manager?.isDisplayModeSwitchInProgress == true {
                waiter.waitForEnd(reason: "in progress")
            } else {
                waiter.finish(waited: false, reason: "no switch started")
            }
        }
    }

    /// `completion` waits with the callers waiting already; false once they are completed or handed on.
    func join(_ completion: @escaping @Sendable () -> Void) -> Bool {
        guard !completions.isEmpty else { return false }
        completions.append(completion)
        return true
    }

    /// Stops waiting without completing anyone: the callers wait for a newer write's switch instead.
    func handOver() -> [@Sendable () -> Void] {
        stopListening()
        defer { completions = [] }
        return completions
    }

    func cancel() {
        finish(waited: false, reason: "cleared")
    }

    private func waitForEnd(reason: String) {
        guard !completions.isEmpty else { return }
        stopListening()
        log.notice("display mode switch: waiting for its end (\(reason, privacy: .public))")
        observe(.AVDisplayManagerModeSwitchEnd) { $0.finish(waited: true, reason: "end notification") }
        schedule(after: Self.startWindow) { waiter in
            if waiter.manager?.isDisplayModeSwitchInProgress != true { waiter.finish(waited: true, reason: "ended") }
        }
        schedule(after: Self.watchdog) { $0.finish(waited: true, reason: "watchdog") }
    }

    private func finish(waited: Bool, reason: String) {
        guard !completions.isEmpty else { return }
        stopListening()
        log.notice("display mode switch wait done (\(reason, privacy: .public))")
        guard waited else { return complete() }
        schedule(after: .milliseconds(Self.settle + extraDelay)) { $0.complete() }
    }

    private func complete() {
        let completions = self.completions
        self.completions = []
        for completion in completions { completion() }
    }

    private func observe(_ name: Notification.Name, _ action: @escaping @MainActor (ModeSwitchWaiter) -> Void) {
        let observer = NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                action(self)
            }
        }
        observers.append(observer)
    }

    private func schedule(after delay: DispatchTimeInterval, _ action: @escaping @MainActor (ModeSwitchWaiter) -> Void) {
        let item = DispatchWorkItem { [weak self] in
            MainActor.assumeIsolated {
                guard let self else { return }
                action(self)
            }
        }
        timers.append(item)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
    }

    private func stopListening() {
        for observer in observers { NotificationCenter.default.removeObserver(observer) }
        observers = []
        timers.forEach { $0.cancel() }
        timers = []
    }
}
#endif
