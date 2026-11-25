import Darwin
import Foundation
import PlezyKit
#if os(iOS) || os(tvOS)
import UIKit
#endif

/// The system's requests to release memory: iOS's and tvOS's memory warning, macOS's memory pressure source (warning
/// and critical). The decoded artwork goes (`ArtworkPipeline.images`), recorded with the process's resident memory now
/// and at its peak, the image cache before and after and the playback's state (`MemoryPressure`) for a crash report.
/// Nuke empties its memory cache on the kernel's pressure event as well, which may come first.
@MainActor
enum MemoryWarnings {
    private static let pressure = MemoryPressure()
    #if os(macOS)
    private static var source: DispatchSourceMemoryPressure?
    #endif

    /// Records the warnings from now on: once, as the app starts.
    static func observe() {
        #if os(macOS)
        guard source == nil else { return }
        let source = DispatchSource.makeMemoryPressureSource(eventMask: [.warning, .critical], queue: .main)
        source.setEventHandler { MainActor.assumeIsolated { record() } }
        source.activate()
        self.source = source
        #else
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification, object: nil, queue: .main
        ) { _ in
            MainActor.assumeIsolated { record() }
        }
        #endif
    }

    private static func record() {
        let before = residentMemory()
            .merging(ArtworkPipeline.pressureData(after: false)) { $1 }
            .merging(MemoryPressure.companion.currentPlayback()) { $1 }
        _ = pressure.onPressure(before: before) {
            ArtworkPipeline.images.removeAll()
            return ArtworkPipeline.pressureData(after: true)
        }
    }

    /// `rssMb` and `maxRssMb`, the task's resident size now and at its peak; none when the kernel doesn't answer.
    private static func residentMemory() -> [String: Any] {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size / MemoryLayout<natural_t>.size)
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return [:] }
        return ["rssMb": Int64(info.resident_size >> 20), "maxRssMb": Int64(info.resident_size_max >> 20)]
    }
}
