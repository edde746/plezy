import Foundation
import PlezyKit
import SwiftUI

/// Debug builds: the music player's gapless proof on this device's MPVKit, run once at launch when the launch argument
/// `-musicGaplessProbe` names two consecutive tracks as `<url>,<url>`, or `tones` for two 6-s WAV tones of one format
/// written to the temporary folder (a Mac's UI-test app may not reach the LAN: macOS asks the user before an app talks
/// to it), with `-mpvMute YES` muted. The first opens near its end with the second armed (`setNext`); it passes when
/// mpv advances into the second without a new open: the transition names the second, the first played to its end, the
/// boundary came when the first's rest had played out, and the second plays on from 0. `result` is `none`, `running`,
/// `pass: …` or `fail: …`.
@MainActor
@Observable
final class MusicGaplessProof {
    static let shared = MusicGaplessProof()

    private(set) var result = "none"

    func startIfAsked() {
        guard result == "none", let asked = UserDefaults.standard.string(forKey: "musicGaplessProbe") else { return }
        let tracks: [String]
        do {
            tracks = asked == "tones" ? [try Self.tone(440), try Self.tone(660)] : asked.split(separator: ",").map(String.init)
        } catch {
            result = "fail: tones not written: \(error.localizedDescription)"
            return
        }
        guard tracks.count >= 2 else {
            result = "fail: -musicGaplessProbe names \(tracks.count) tracks"
            return
        }
        result = "running"
        let (first, second) = (tracks[tracks.count - 2], tracks[tracks.count - 1])
        Task { result = await Self.run(first: first, second: second) }
    }

    /// A 6-s 48 kHz 16-bit stereo WAV of a `frequency` tone in the temporary folder; its path.
    private static func tone(_ frequency: Double) throws -> String {
        let rate = 48_000
        let frames = rate * 6
        var data = Data()
        func append<T: FixedWidthInteger>(_ value: T) { withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) } }
        data.append(contentsOf: Array("RIFF".utf8)); append(UInt32(36 + frames * 4)); data.append(contentsOf: Array("WAVE".utf8))
        data.append(contentsOf: Array("fmt ".utf8)); append(UInt32(16)); append(UInt16(1)); append(UInt16(2))
        append(UInt32(rate)); append(UInt32(rate * 4)); append(UInt16(4)); append(UInt16(16))
        data.append(contentsOf: Array("data".utf8)); append(UInt32(frames * 4))
        for i in 0..<frames {
            let sample = Int16((sin(2 * Double.pi * frequency * Double(i) / Double(rate)) * 8000).rounded())
            append(sample)
            append(sample)
        }
        let url = FileManager.default.temporaryDirectory.appending(path: "plezy-gapless-\(Int(frequency)).wav")
        try data.write(to: url)
        return url.path(percentEncoded: false)
    }

    /// The proof on a new player, bounded to a minute; the player is disposed after.
    private nonisolated static func run(first: String, second: String) async -> String {
        let player = UncheckedBox(AppleMpvAudioCore.player())
        let outcome = await withTaskGroup(of: String.self) { group in
            group.addTask { await prove(player.value, first: first, second: second) }
            group.addTask {
                try? await Task.sleep(for: .seconds(60))
                return "fail: no result within 60 s"
            }
            let first = await group.next() ?? "fail: no result"
            group.cancelAll()
            return first
        }
        try? await player.value.dispose()
        return outcome
    }

    private nonisolated static func prove(_ player: any AudioPlayer, first: String, second: String) async -> String {
        let headers = ["X-Plex-Product": "Plezy"]
        let lead = 3.0
        let clock = ContinuousClock()
        var duration = 0.0
        var seekedAt: ContinuousClock.Instant?
        var boundary: Swift.Duration?
        var after: [Double] = []
        do {
            try await player.open(media: AudioMedia(uri: first, headers: headers, start: nil), play: true)
            for await event in player.events {
                if Task.isCancelled { return "fail: cancelled" }
                switch onEnum(of: event) {
                case .durationChanged(let changed):
                    let seconds = Self.seconds(changed.duration)
                    guard seekedAt == nil, seconds > lead else { continue }
                    duration = seconds
                    try await player.setNext(media: AudioMedia(uri: second, headers: headers, start: nil))
                    try await player.seek(position: Self.raw(seconds - lead))
                    seekedAt = clock.now
                case .trackTransition(let transition):
                    guard boundary == nil, let seekedAt else { return "fail: a transition before the boundary" }
                    guard transition.uri == second else { return "fail: transition to \(transition.uri)" }
                    boundary = clock.now - seekedAt
                case .position(let report):
                    guard boundary != nil else { continue }
                    let position = Self.seconds(report.position)
                    after.append(position)
                    if position >= 2 { return verdict(duration: duration, lead: lead, boundary: boundary, after: after) }
                case .error(let error):
                    return "fail: \(error.message)"
                default:
                    break
                }
            }
            return "fail: the events ended"
        } catch {
            return "fail: \(error.localizedDescription)"
        }
    }

    /// The first track played its rest out when the boundary came `lead` after the seek to `lead` before its end: not
    /// sooner (cut short), and not much later (a stall or a reopen at the boundary).
    private nonisolated static func verdict(duration: Double, lead: Double, boundary: Swift.Duration?, after: [Double]) -> String {
        let took = boundary.map { Double($0.components.seconds) + Double($0.components.attoseconds) / 1e18 } ?? .infinity
        let summary = String(format: "track %.2f s, boundary %.2f s after the seek to %.2f s, after %@",
                             duration, took, duration - lead, after.prefix(10).map { String(format: "%.2f", $0) }.joined(separator: " "))
        // mpv moves to the next entry as its decoder does, while the output's buffer still plays the first's last moments.
        if took < lead - 1.5 { return "fail: the first track stopped early; \(summary)" }
        if took > lead + 2 { return "fail: the boundary stalled; \(summary)" }
        if (after.first ?? .infinity) > 1 { return "fail: the second track didn't start at 0; \(summary)" }
        if after != after.sorted() { return "fail: the second track's position ran back; \(summary)" }
        return "pass: \(summary)"
    }

    /// Seconds of a `kotlin.time.Duration` as Swift gets it: its raw value, nanoseconds shifted left by one (milliseconds
    /// with the low bit set past about 146 years).
    private nonisolated static func seconds(_ raw: Int64) -> Double {
        raw & 1 == 0 ? Double(raw >> 1) / 1e9 : Double(raw >> 1) / 1e3
    }

    private nonisolated static func raw(_ seconds: Double) -> Int64 {
        Int64(seconds * 1e9) << 1
    }
}

/// Debug builds: the gapless proof's result (`MusicGaplessProof`) as the label of an element the UI tests read
/// (`music.gapless`; the Mac doesn't report a plain element's value). It starts the proof when the launch asks for it.
struct MusicGaplessProbe: View {
    var body: some View {
        Color.clear
            .frame(width: 1, height: 1)
            .accessibilityElement()
            .accessibilityLabel(Text(verbatim: MusicGaplessProof.shared.result))
            .accessibilityIdentifier("music.gapless")
            .allowsHitTesting(false)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .task { MusicGaplessProof.shared.startIfAsked() }
    }
}
