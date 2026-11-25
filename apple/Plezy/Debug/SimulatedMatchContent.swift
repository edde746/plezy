#if os(tvOS)
import AVKit
import Observation

/// Debug builds started with `-simulateMatchContent YES` (UserDefaults' argument domain; the UI tests'
/// `launchDev(matchContent: true)`): the display manager of an Apple TV on an HDR TV with Match Content on, for the tvOS
/// simulator, whose own manager reports matching off. The surfaces use it instead of their window's, so the criteria
/// `DisplayCriteria` writes, the mode switches they start and the waits for them run on the simulator too.
///
/// Each change of the criteria (a write or a clear) switches the display, as one to another mode does on an Apple TV:
/// `AVDisplayManagerModeSwitchStart` on the next main-queue turn, `isDisplayModeSwitchInProgress` 30 ms after the
/// change (it lags the notification on an Apple TV too), `AVDisplayManagerModeSwitchEnd` 2 s after it. A change
/// during a switch switches again once that one has ended. `DisplaySwitchReading` counts what happened.
///
/// Main thread only, as `AVDisplayManager` is used.
final class SimulatedMatchContent: DisplayManaging, @unchecked Sendable {
    /// The one the surfaces use; nil without the launch argument.
    static let shared: SimulatedMatchContent? =
        UserDefaults.standard.bool(forKey: "simulateMatchContent") ? SimulatedMatchContent() : nil

    private static let flagLag: TimeInterval = 0.03
    private static let switchTime: TimeInterval = 2

    private var criteria: AVDisplayCriteria?
    private var inProgress = false
    /// From a change of the criteria until its switch has ended.
    private(set) var switching = false
    private var changedWhileSwitching = false

    var isDisplayCriteriaMatchingEnabled: Bool { true }

    var isDisplayModeSwitchInProgress: Bool { inProgress }

    var preferredDisplayCriteria: AVDisplayCriteria? {
        get { criteria }
        set {
            criteria = newValue
            MainActor.assumeIsolated { DisplaySwitchReading.shared.criteriaChanged(cleared: newValue == nil) }
            if switching {
                changedWhileSwitching = true
            } else {
                beginSwitch()
            }
        }
    }

    private func beginSwitch() {
        switching = true
        MainActor.assumeIsolated { DisplaySwitchReading.shared.switches += 1 }
        DispatchQueue.main.async { NotificationCenter.default.post(name: .AVDisplayManagerModeSwitchStart, object: self) }
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.flagLag) { self.inProgress = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.switchTime) { self.endSwitch() }
    }

    private func endSwitch() {
        inProgress = false
        switching = false
        NotificationCenter.default.post(name: .AVDisplayManagerModeSwitchEnd, object: self)
        guard changedWhileSwitching else { return }
        changedWhileSwitching = false
        beginSwitch()
    }
}

/// What the simulated display (`SimulatedMatchContent`) went through since the launch, for the UI tests' probe
/// `player.display` (`PlayerProbes`): `writes=<n> clears=<n> switches=<n> readyWhileSwitching=<n> rate=<mHz>
/// criteria=<range>@<Hz> <w>x<h> dovi=<profile>.<level>/<compatibility>`, the criteria written and cleared, the mode
/// switches, how often the surface told the player the display was ready (the player starts the file then) while a
/// switch was under way, the refresh rate the criteria last written asked for in millihertz (0 before any) and those
/// criteria (`DisplayCriteria` sets both as it writes them: `AVDisplayCriteria` shows neither).
@MainActor
@Observable
final class DisplaySwitchReading {
    static let shared = DisplaySwitchReading()

    private(set) var writes = 0
    private(set) var clears = 0
    fileprivate(set) var switches = 0
    private(set) var readyWhileSwitching = 0
    var rate = 0
    var criteria = "none"

    var summary: String {
        "writes=\(writes) clears=\(clears) switches=\(switches) readyWhileSwitching=\(readyWhileSwitching) rate=\(rate) criteria=\(criteria)"
    }

    fileprivate func criteriaChanged(cleared: Bool) {
        if cleared { clears += 1 } else { writes += 1 }
    }

    /// The surface told the player the display is ready for its video.
    func displayReady() {
        if SimulatedMatchContent.shared?.switching == true { readyWhileSwitching += 1 }
    }

    /// `completion`, the surface's call once the display is ready (`VideoSurface.present`), counted as such first
    /// (`displayReady`).
    nonisolated static func countingReady(_ completion: @escaping @Sendable () -> Void) -> @Sendable () -> Void {
        {
            MainActor.assumeIsolated { DisplaySwitchReading.shared.displayReady() }
            completion()
        }
    }
}
#endif
