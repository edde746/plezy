#if !os(tvOS)
#if os(macOS)
import AppKit
#else
import UIKit
#endif
import XCTest

/// The scroll edge the app draws itself over Library's grid (the system's soft edge never reaches its paged tabs; the
/// Mac's toolbar band) and under the Mac's toolbar on pushed pages, against the test Jellyfin server
/// (`PLEZY_DEV_SERVER`, else the default): posters scrolled up under the top of the window fade into the screen's black
/// there, in the dark theme.
final class ScrollEdgeTests: PlezyUITestCase {
    #if os(macOS)
    // The Mac runs reach the test servers through loopback tunnels.
    private nonisolated static let host = "127.0.0.1"
    #else
    private nonisolated static let host = "192.168.0.15"
    #endif

    private static var server: String {
        let value = ProcessInfo.processInfo.environment["PLEZY_DEV_SERVER"] ?? ""
        return value.isEmpty ? "jellyfin=maestro:maestro@http://\(host):28096" : value
    }

    /// A strip across the middle of the window's top, under the status bar's or the band's empty middle.
    private func topStrip(_ window: CGRect) -> CGRect {
        CGRect(x: window.minX + window.width * 0.35, y: window.minY + 2, width: window.width * 0.3, height: 4)
    }

    func testLibraryGridFadesUnderTheTop() {
        launchDev(settings: ["theme_mode=dark"], arguments: ["--dev-server", Self.server, "--dev-open", "libraries"])
        require("libraries.screen", timeout: 60, "Libraries")
        let steps = LibrarySteps(test: self)
        steps.pickLibrary("Movies")
        steps.showLibraryTab("browse")
        require("libraries.grid", timeout: 30, "the Browse grid")
        if !steps.card(prefix: "Alpha Archive").exists(within: 30) { fail("Movies lists no Alpha Archive") }
        // Lets the posters' artwork load before the shot; nothing signals it.
        sleep(3)
        shot("library grid at rest")

        let window = app.windows.firstMatch
        let strip = topStrip(window.frame)
        let cards = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'card.'"))
        let under = { cards.allElementsBoundByIndex.prefix(40).contains { $0.exists && $0.frame.intersects(strip) } }
        for _ in 0..<4 where !under() { scrollDown() }
        shot("library grid scrolled")
        if !under() { fail("no poster lies under the top of the window after scrolling") }
        let brightness = self.brightness(of: strip, in: window)
        XCTAssertLessThan(brightness, 0.1, "posters under the top of the window fade into the black there (brightness \(brightness))")
    }

    #if os(macOS)
    /// A pushed page's toolbar (Back, the title, the page's actions) over posters scrolled up under it: View all of
    /// Home's first library hub, whose grid scrolls far enough to put a poster under the toolbar's middle, which fades
    /// into the black there. The collection's and the actor's pages are shot scrolled alike.
    func testPushedPagesFadeUnderTheToolbar() {
        launchDev(settings: ["theme_mode=dark"], arguments: ["--dev-server", Self.server, "--dev-open", "home"])
        require("home.screen", timeout: 60, "Home")
        let viewAll = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'hub.' AND identifier ENDSWITH '.viewAll'")).firstMatch
        if !viewAll.exists(within: 30) { fail("Home shows no View all") }
        viewAll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).click()
        require("hubDetail", timeout: 20, "the hub's View all")
        let window = app.windows.firstMatch
        let strip = toolbarStrip(window.frame)
        let cards = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'card.'"))
        if !cards.firstMatch.exists(within: 30) { fail("View all lists no posters") }
        sleep(2)
        let under = { cards.allElementsBoundByIndex.prefix(40).contains { $0.exists && $0.frame.intersects(strip) } }
        for _ in 0..<4 where !under() { scrollDown() }
        shot("view all scrolled")
        if !under() { fail("no poster lies under the toolbar after scrolling View all") }
        let brightness = self.brightness(of: strip, in: window)
        XCTAssertLessThan(brightness, 0.1, "posters under the toolbar fade into the black there (brightness \(brightness))")

        app.terminate()
        launchDev(settings: ["theme_mode=dark"], arguments: ["--dev-server", Self.server, "--dev-open", "libraries"])
        require("libraries.screen", timeout: 60, "Libraries")
        let steps = LibrarySteps(test: self)
        steps.pickLibrary("Movies")
        steps.showLibraryTab("collections")
        let picks = steps.card(prefix: "Plezy Picks")
        if !picks.exists(within: 30) { fail("Movies lists no Plezy Picks") }
        steps.press(picks)
        require("collection.screen", timeout: 20, "Plezy Picks' screen")
        sleep(3)
        scrollDown()
        scrollDown()
        shot("collection scrolled")

        app.terminate()
        launchDev(settings: ["theme_mode=dark"], arguments: ["--dev-server", Self.server, "--dev-open", "search"])
        let field = require("search.field", timeout: 90, "the search field")
        field.click()
        field.typeText("Maestro Movie")
        let result = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'search.result.' AND label == %@", "Maestro Movie")).firstMatch
        if !result.exists(within: 30) { fail("Search lists no Maestro Movie") }
        result.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).click()
        require("detail.cast", timeout: 30, "Maestro Movie's cast")
        let member = element("detail.cast.0")
        for _ in 0..<4 where !member.isHittable { scrollDown() }
        member.click()
        require("person.screen", timeout: 20, "the actor's screen")
        sleep(3)
        scrollDown()
        scrollDown()
        shot("actor scrolled")
    }

    /// A strip across the toolbar's middle, past its title and before its trailing items.
    private func toolbarStrip(_ window: CGRect) -> CGRect {
        CGRect(x: window.minX + window.width * 0.45, y: window.minY + 24, width: window.width * 0.3, height: 4)
    }
    #endif

    /// The content moved up by about a third of the window, without a fling (the Mac: a scroll over the grid), then
    /// left to settle.
    private func scrollDown() {
        #if os(macOS)
        app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.6, dy: 0.6)).scroll(byDeltaX: 0, deltaY: -250)
        #else
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.6, dy: 0.7))
        start.press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.6, dy: 0.4)), withVelocity: .slow, thenHoldForDuration: 0.3)
        #endif
        sleep(2)
    }

    /// The mean brightness (0 black to 1 white) of `rect` (window points) in a screenshot of `window`.
    private func brightness(of rect: CGRect, in window: XCUIElement) -> Double {
        let shot = window.screenshot()
        #if os(macOS)
        guard let image = shot.image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return 1 }
        #else
        guard let image = shot.image.cgImage else { return 1 }
        #endif
        let frame = window.frame
        let scale = CGFloat(image.width) / frame.width
        let crop = CGRect(x: (rect.minX - frame.minX) * scale, y: (rect.minY - frame.minY) * scale,
                          width: rect.width * scale, height: rect.height * scale).integral
        guard let part = image.cropping(to: crop) else { return 1 }
        let width = part.width, height = part.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let drawn = pixels.withUnsafeMutableBytes { bytes in
            CGContext(
                data: bytes.baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ).map { $0.draw(part, in: CGRect(x: 0, y: 0, width: width, height: height)); return true } ?? false
        }
        guard drawn, width * height > 0 else { return 1 }
        var sum = 0
        for pixel in 0..<(width * height) {
            sum += Int(pixels[pixel * 4]) + Int(pixels[pixel * 4 + 1]) + Int(pixels[pixel * 4 + 2])
        }
        return Double(sum) / Double(width * height * 3 * 255)
    }
}
#endif
