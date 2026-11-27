import XCTest

/// Subtitles draw over the picture at their cues' times, as the video plays with the controls down. Signed in with
/// `PLEZY_SERVER` (`--dev-server`'s `<kind>=<user>:<password>@<url>`), the two test-pattern films each name: their
/// picture (16:9, a dark grey ground) leaves its top tenth and bottom fifth empty, so whatever shows there is a
/// subtitle.
/// - `PLEZY_ASS_PLAY` (`--dev-play`'s `<server>:<item>`): a styled ASS track, on by default, whose second event is a
///   bold yellow sign at the top from 0:04 to 0:07 and whose fourth sits on a blue box at the bottom from 0:10 to 0:13.
/// - `PLEZY_FORCED_PLAY`: SRT tracks in three languages and a forced English one, the default, with two cues: 0:05 to
///   0:08 at the bottom, 0:15 to 0:18 at the top. The full tracks have cues at 0:11 to 0:14 too, which the forced
///   track doesn't: the playback picks the forced track with no menu pick, and only its cues show.
/// - `PLEZY_COVER_PLAY`: a 4:3 film (a dark grey ground below its middle) with an English SRT track, the default, whose
///   lines sit at the picture's foot throughout (Tortuga's matrix `h264-4x3.mkv`), played transcoded at the lowest
///   quality with the picture filling the screen, which crops the 4:3 picture's foot off a wide screen: the lines still
///   show in the screen's bottom fifth.
final class SubtitleTests: PlezyUITestCase {
    private var notes = 0

    func testStyledAssEventsDrawAtTheirTimes() throws {
        guard let samples = try play("PLEZY_ASS_PLAY", until: 13) else { return }
        expect(samples, in: 4.3...6.7, "the yellow sign at the top (0:04 to 0:07)") { $0.top.yellow > 0.003 }
        expect(samples, in: 7.3...9.7, "no sign at the top once it ended (0:07)") { $0.top.yellow < 0.0005 }
        expect(samples, in: 10.3...12.7, "the blue box at the bottom (0:10 to 0:13)") { $0.bottom.blue > 0.01 }
        expect(samples, in: 7.3...9.7, "no box at the bottom before it starts (0:10)") { $0.bottom.blue < 0.0005 }
    }

    func testForcedTrackShowsOnlyItsCues() throws {
        guard let samples = try play("PLEZY_FORCED_PLAY", until: 18) else { return }
        expect(samples, in: 5.3...7.7, "the forced cue at the bottom (0:05 to 0:08)") { $0.bottom.white > 0.003 }
        expect(samples, in: 11.3...13.7, "no text at 0:11 to 0:14, where only the full tracks have a cue") {
            $0.bottom.white < 0.0005 && $0.top.white < 0.0005
        }
        expect(samples, in: 15.3...17.7, "the forced cue at the top (0:15 to 0:18)") { $0.top.white > 0.003 }
    }

    func testTranscodedSubtitleStaysOnScreenWhenThePictureFillsIt() throws {
        let settings = ["default_box_fit_mode=cover", "default_quality_preset=p240_320"]
        guard let samples = try play("PLEZY_COVER_PLAY", until: 18, settings: settings, cover: true) else { return }
        expect(samples, in: 2.0...17.5, "the lines at the foot of the screen (0:00.5 to 0:20)") { $0.bottom.white > 0.003 }
    }

    // MARK: - Playing and sampling

    /// What a sample saw in one band of the screen: the shares (0–1) of its pixels that are yellow, blue and white.
    private struct Band {
        var yellow = 0.0, blue = 0.0, white = 0.0
    }

    /// The bands at a position of the video, with the controls down.
    private struct Sample {
        let from: Double, to: Double
        let top: Band, bottom: Band
    }

    /// Plays the item `variable` names with this device's `settings` and samples the screen while the controls are down,
    /// until the video passes `end` seconds; `cover`: the picture fills the screen, so the bands are the screen's. Nil
    /// (failed) when no frame comes.
    private func play(_ variable: String, until end: Double, settings: [String] = [], cover: Bool = false) throws -> [Sample]? {
        let env = ProcessInfo.processInfo.environment
        guard let server = env["PLEZY_SERVER"], let play = env[variable]?.removingPercentEncoding else {
            throw XCTSkip("PLEZY_SERVER and \(variable) name the server and the item to play")
        }
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone {
            XCUIDevice.shared.orientation = .landscapeLeft
            addTeardownBlock { XCUIDevice.shared.orientation = .portrait }
        }
        #endif
        launchDev(settings: settings, arguments: ["--dev-server", server, "--dev-play", play])
        let frame = require("player.video", timeout: 90, "the player opening on \(play)").frame
        if !waitUntil(30, { self.state("firstFrame") == "true" }) {
            fail("no first frame on \(play): \(stateReading)")
            return nil
        }
        #if os(macOS)
        // The pointer off the window: over it the controls come up.
        let window = app.windows.firstMatch.frame
        app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 1)).withOffset(CGVector(dx: 0, dy: 60)).hover()
        #else
        let window = CGRect(x: 0, y: 0, width: app.windows.allElementsBoundByIndex.map(\.frame.width).max() ?? 0, height: 0)
        #endif
        var samples: [Sample] = []
        var kept = 0
        // When the controls were last seen up: they fade out for a moment after they report going down.
        var controlsSeen = Date()
        let deadline = Date().addingTimeInterval(end + 30)
        while Date() < deadline {
            let from = position()
            if from > end { break }
            guard state("controls") == "false" else {
                controlsSeen = Date()
                continue
            }
            guard Date().timeIntervalSince(controlsSeen) > 1, let screen = screenImage(window), let bands = bands(of: frame, on: screen, cover: cover) else { continue }
            let to = position()
            guard to >= from, state("controls") == "false" else {
                controlsSeen = Date()
                continue
            }
            samples.append(Sample(from: from, to: to, top: bands.top, bottom: bands.bottom))
            // The screen as sampled every few seconds, to look at: the bands' readings are the test's.
            if Int(from) / 3 >= kept {
                kept = Int(from) / 3 + 1
                keep(screen.image, String(format: "at %.1f s", from))
            }
        }
        note("samples", samples.map {
            String(format: "%.1f–%.1f s top y%.4f b%.4f w%.4f bottom y%.4f b%.4f w%.4f",
                   $0.from, $0.to, $0.top.yellow, $0.top.blue, $0.top.white, $0.bottom.yellow, $0.bottom.blue, $0.bottom.white)
        }.joined(separator: "\n"))
        return samples
    }

    /// Fails unless some sample lies wholly in `window` (seconds) and every such sample passes `check`.
    private func expect(_ samples: [Sample], in window: ClosedRange<Double>, _ what: String, _ check: (Sample) -> Bool) {
        let inside = samples.filter { window.contains($0.from) && window.contains($0.to) }
        if inside.isEmpty { return fail("\(what): no sample with the controls down in \(window) s") }
        for sample in inside where !check(sample) {
            fail(String(format: "%@: at %.1f–%.1f s top yellow %.4f blue %.4f white %.4f, bottom yellow %.4f blue %.4f white %.4f",
                        what, sample.from, sample.to, sample.top.yellow, sample.top.blue, sample.top.white,
                        sample.bottom.yellow, sample.bottom.blue, sample.bottom.white))
        }
    }

    /// The top and bottom bands of `screen` over the video (`frame`, in points): the picture's top tenth and bottom
    /// fifth, each with the bar beside it where the picture is letterboxed, clear of the picture's sides (the Mac
    /// window's buttons). `cover`: the picture fills `frame`, cropped, so the bands are `frame`'s.
    private func bands(of frame: CGRect, on screen: (image: CGImage, scale: CGFloat, origin: CGPoint), cover: Bool) -> (top: Band, bottom: Band)? {
        let scale = min(frame.width / 16, frame.height / 9)
        let picture = cover
            ? frame.insetBy(dx: frame.width * 0.1, dy: 0)
            : CGRect(x: frame.midX - 8 * scale, y: frame.midY - 4.5 * scale, width: 16 * scale, height: 9 * scale).insetBy(dx: 1.6 * scale, dy: 0)
        let top = CGRect(x: picture.minX, y: frame.minY, width: picture.width, height: picture.minY - frame.minY + picture.height * 0.10)
        let bottomY = picture.minY + picture.height * 0.82
        let bottom = CGRect(x: picture.minX, y: bottomY, width: picture.width, height: frame.maxY - bottomY)
        guard let topBand = band(screen, top), let bottomBand = band(screen, bottom) else { return nil }
        return (topBand, bottomBand)
    }

    /// The screen as the device shows it (the Mac: `window`, its frame), with the scale from points to its pixels and
    /// the origin of the points; `window`'s width is the screen's in points elsewhere.
    private func screenImage(_ window: CGRect) -> (image: CGImage, scale: CGFloat, origin: CGPoint)? {
        guard window.width > 0 else { return nil }
        #if os(macOS)
        guard let image = app.windows.firstMatch.screenshot().image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        return (image, CGFloat(image.width) / window.width, window.origin)
        #else
        var shot = XCUIScreen.main.screenshot().image
        #if os(iOS)
        shot = Self.upright(shot)
        #endif
        guard let image = shot.cgImage else { return nil }
        return (image, CGFloat(image.width) / window.width, .zero)
        #endif
    }

    /// `image` kept in the run's report as `name`.
    private func keep(_ image: CGImage, _ name: String) {
        #if os(macOS)
        let attachment = XCTAttachment(image: NSImage(cgImage: image, size: .zero))
        #else
        let attachment = XCTAttachment(image: UIImage(cgImage: image))
        #endif
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    #if os(iOS)
    /// `image` as the device shows it: a portrait-shaped capture of a landscape screen turned a quarter.
    private static func upright(_ image: UIImage) -> UIImage {
        let orientation = XCUIDevice.shared.orientation
        guard orientation.isLandscape, let cgImage = image.cgImage, cgImage.height > cgImage.width else { return image }
        let turned = UIImage(cgImage: cgImage, scale: image.scale, orientation: orientation == .landscapeLeft ? .left : .right)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let size = CGSize(width: turned.size.width * image.scale, height: turned.size.height * image.scale)
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in turned.draw(in: CGRect(origin: .zero, size: size)) }
    }
    #endif

    /// The shares of yellow (the sign's), blue (the box's) and white (text) pixels in `area` (points) of `screen`.
    private func band(_ screen: (image: CGImage, scale: CGFloat, origin: CGPoint), _ area: CGRect) -> Band? {
        let pixels = area.offsetBy(dx: -screen.origin.x, dy: -screen.origin.y)
            .applying(CGAffineTransform(scaleX: screen.scale, y: screen.scale)).integral
            .intersection(CGRect(x: 0, y: 0, width: screen.image.width, height: screen.image.height))
        guard !pixels.isEmpty, let crop = screen.image.cropping(to: pixels) else { return nil }
        let width = crop.width, height = crop.height
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        let drawn = bytes.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            context.draw(crop, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard drawn else { return nil }
        var yellow = 0, blue = 0, white = 0
        for pixel in 0..<(width * height) {
            let r = Int(bytes[pixel * 4]), g = Int(bytes[pixel * 4 + 1]), b = Int(bytes[pixel * 4 + 2])
            if r > 170, g > 140, b < 90 { yellow += 1 }
            if b > 120, r < 60, g < 130 { blue += 1 }
            if r > 200, g > 200, b > 200 { white += 1 }
        }
        let count = Double(width * height)
        return Band(yellow: Double(yellow) / count, blue: Double(blue) / count, white: Double(white) / count)
    }

    // MARK: - Probes

    /// A probe's reading: its value, else (the Mac reports no plain element's value) its label.
    private func reading(_ probe: XCUIElement) -> String {
        guard let found = try? probe.snapshot() else { return "absent" }
        if let value = found.value as? String, !value.isEmpty { return value }
        return found.label
    }

    private var stateReading: String { reading(element("player.state")) }

    private func state(_ key: String) -> String {
        stateReading.components(separatedBy: "; ").first { $0.hasPrefix("\(key)=") }.map { String($0.dropFirst(key.count + 1)) } ?? ""
    }

    /// The position in seconds (`player.livePosition`: `position=12.3`).
    private func position() -> Double {
        Double(reading(element("player.livePosition")).dropFirst("position=".count)) ?? -1
    }

    /// A note in the run's report, `name` numbered in the order taken.
    private func note(_ name: String, _ text: String) {
        notes += 1
        let attachment = XCTAttachment(string: text)
        attachment.name = "note \(notes) \(name)"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
