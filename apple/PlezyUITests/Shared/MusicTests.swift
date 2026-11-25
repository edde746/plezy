import XCTest
#if os(iOS)
import UIKit
#endif

/// Music against the test servers' Jellyfin, signed in as maestro (`--dev-server`, the server's address from
/// `PLEZY_MUSIC_SERVER`, else the default; on the Mac its loopback tunnel): Plezy Test Artist → Sine Album → play Low Hum
/// → the mini-player → Now Playing → its lyrics → the queue, a screenshot of each. On Apple TV playing opens Now Playing
/// at once (no mini-player), the remote drives every step, and the tab bar shows Now Playing. On the Mac the playback
/// bar, its side panel (the queue, the lyrics) and the full-window player instead.
/// Now Playing's extras: the overflow and the sleep timer menu (everywhere), the queue's drag and swipe and the drag
/// down that closes the screen (iPhone), Space and Escape (Mac), and the seek bar's remote steps (Apple TV).
final class MusicTests: PlezyUITestCase {
    private static var server: String {
        let environment = ProcessInfo.processInfo.environment["PLEZY_MUSIC_SERVER"] ?? ""
        if !environment.isEmpty { return environment }
        #if os(macOS)
        // The Mac runs reach the test server through a loopback tunnel: the local network needs a prompt answered.
        return "jellyfin=maestro:maestro@http://127.0.0.1:28096"
        #else
        return "jellyfin=maestro:maestro@http://192.168.0.15:28096"
        #endif
    }

    /// Starts a dev session signed in to the test server on Plezy Test Artist (`--dev-open-music artist=…`) and waits for
    /// the artist's albums.
    private func openArtist(settings: [String] = ["theme_mode=dark"], arguments: [String] = []) {
        launchDev(settings: settings, arguments: ["--dev-server", Self.server, "--dev-open-music", "artist=Plezy Test Artist"] + arguments)
        // A dev launch that can't reach its server quits the app: say so, rather than lose it mid-query (with no app,
        // no tree or screenshot either).
        let artist = element("music.artist")
        let deadline = Date().addingTimeInterval(90)
        while true {
            if app.state == .notRunning { return XCTFail("Plezy quit at launch: its dev session couldn't reach \(Self.server)") }
            if artist.exists { break }
            if Date() > deadline { return fail("The artist screen (music.artist) didn't come in 90 s") }
            _ = waitUntil(0.5) { artist.exists || app.state == .notRunning }
        }
        require(label: "Sine Album", "the artist's Sine Album")
        // The artwork comes over the network.
        Thread.sleep(forTimeInterval: 4)
    }

    #if !os(tvOS)
    /// Taps `element` on touch, clicks it on the Mac: at its frame's centre, as the right-click catcher over a card or a
    /// track row (`mediaMenuTrigger`) hides its activation point.
    private func press(_ element: XCUIElement) {
        #if os(macOS)
        element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).click()
        #else
        element.tap()
        #endif
    }
    #endif

    /// The element labelled `label`; fails the test with `what` when it doesn't come.
    @discardableResult
    private func require(label: String, timeout: TimeInterval = 30, _ what: String) -> XCUIElement {
        let found = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", label)).firstMatch
        if !found.exists(within: timeout) { fail("No \(what) (\(label))") }
        return found
    }

    /// The album's first track rows each as tall as their ⋯ beside them, on one centre line.
    private func requireRowsAsTallAsTheirMenus() {
        for index in 0..<2 {
            let row = require("music.track.\(index)", "track \(index + 1)'s row").frame
            let more = require("music.track.\(index).more", "track \(index + 1)'s ⋯").frame
            XCTAssertEqual(more.height, row.height, accuracy: 1, "track \(index + 1)'s ⋯ \(more.size) is as tall as its row \(row.size)")
            XCTAssertEqual(more.midY, row.midY, accuracy: 1, "track \(index + 1)'s ⋯ \(more) is centred on its row \(row)")
        }
    }

    /// The seconds of a timestamp (`1:05`).
    private func seconds(_ text: String) -> Int? {
        let parts = text.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return nil }
        return parts[0] * 60 + parts[1]
    }

    /// Presses `element`: a tap, a click, or on Apple TV focus moved to it and Select.
    private func activate(_ element: XCUIElement, _ what: String) {
        #if os(tvOS)
        focus(element, what)
        XCUIRemote.shared.press(.select)
        #else
        if !element.exists(within: 30) { return fail("No \(what)") }
        press(element)
        #endif
    }

    /// Now Playing's overflow, the track's item menu (the music actions, File Info, and Download or Delete download but
    /// on Apple TV), closed again; then the sleep timer's menu, in the video player's groups (Off, End of track, then 5,
    /// 10, 15 … minutes): Off checked at first, 15 minutes chosen, which closes it, then checked alone when it opens
    /// again; the menu closed at the end.
    private func checkSleepTimer(_ device: String) {
        activate(element("music.np.more"), "the overflow button")
        let entry = element("menu.music_play")
        if !entry.exists(within: 10) { fail("The overflow showed no music actions") }
        if !element("menu.fileinfo").exists(within: 5) { fail("The overflow showed no File Info") }
        #if os(tvOS)
        XCTAssertFalse(element("menu.download").exists || element("menu.delete_download").exists, "Apple TV offers no download")
        #else
        requireDownloadEntry("the overflow")
        #endif
        shot("\(device) overflow")
        closeMenu()
        if !entry.waitForNonExistence(timeout: 5) { fail("The overflow didn't close") }
        activate(element("music.np.sleep"), "the sleep timer menu")
        if !sleepChoice(4, "15 minutes").exists(within: 10) { fail("The sleep timer showed no 15 minutes") }
        shot("\(device) sleep timer")
        XCTAssertTrue(checked(sleepChoice(0, "Off")), "Off is checked while no timer runs")
        XCTAssertFalse(checked(sleepChoice(4, "15 minutes")), "15 minutes isn't checked before it's chosen")
        #if os(tvOS)
        // The menu opens on its checked choice, Off; its items report no focus. End of track, 5 and 10 minutes, 15.
        for _ in 0..<4 {
            XCUIRemote.shared.press(.down)
            // Paced: the menu's items report no focus to wait on.
            Thread.sleep(forTimeInterval: 0.5)
        }
        XCUIRemote.shared.press(.select)
        #else
        activate(sleepChoice(4, "15 minutes"), "15 minutes")
        #endif
        if !sleepChoice(4, "15 minutes").waitForNonExistence(timeout: 5) { fail("Choosing 15 minutes didn't close the menu") }
        _ = waitUntil(5) { element("music.np.sleep").isHittable }
        activate(element("music.np.sleep"), "the sleep timer menu")
        if !sleepChoice(4, "15 minutes").exists(within: 10) { fail("The sleep timer's choices didn't show again") }
        shot("\(device) sleep timer 15 minutes")
        XCTAssertTrue(checked(sleepChoice(4, "15 minutes")), "15 minutes is checked once chosen")
        XCTAssertFalse(checked(sleepChoice(0, "Off")), "Off isn't checked while the timer runs")
        closeMenu()
        if !sleepChoice(4, "15 minutes").waitForNonExistence(timeout: 5) { fail("The sleep timer menu didn't close") }
        _ = waitUntil(5) { element("music.np.sleep").isHittable }
    }

    /// The sleep timer's choice at `index`: by its identifier, else (where the system's menu drops it under a titled
    /// section) by its label.
    private func sleepChoice(_ index: Int, _ label: String) -> XCUIElement {
        let byId = element("music.sleep.\(index)")
        if byId.exists { return byId }
        #if os(macOS)
        return app.menuItems[label].firstMatch
        #else
        return app.buttons.matching(NSPredicate(format: "label == %@", label)).firstMatch
        #endif
    }

    /// A menu choice is checked: selected (iOS, tvOS); the Mac's menu items don't report their mark, so there the
    /// choice the sleep timer button names.
    private func checked(_ item: XCUIElement) -> Bool {
        #if os(macOS)
        (element("music.np.sleep").value as? String) == (item.title.isEmpty ? item.label : item.title)
        #else
        item.isSelected
        #endif
    }

    /// An item menu that is open offers Download, or Delete download where the item is downloaded.
    private func requireDownloadEntry(_ what: String) {
        let download = element("menu.download")
        let delete = element("menu.delete_download")
        _ = waitUntil(10) { download.exists || delete.exists }
        if !download.exists, !delete.exists { fail("No Download or Delete download in \(what)") }
    }

    /// Closes an open menu: the remote's Menu, Escape on the Mac, on touch a tap beside it.
    private func closeMenu() {
        #if os(tvOS)
        XCUIRemote.shared.press(.menu)
        #elseif os(macOS)
        app.typeKey(XCUIKeyboardKey.escape, modifierFlags: [])
        #else
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.5)).tap()
        #endif
    }

    #if !os(tvOS)
    /// A Shuffle (`id`: Now Playing's, the Mac's playback bar's) tells its state, not only by its tint: "Off" and not
    /// selected, "On" and selected once pressed, "Off" again on the next press.
    private func checkShuffleState(_ id: String = "music.np.shuffle") {
        let shuffle = require(id, "the Shuffle \(id)")
        func expect(_ on: Bool, _ what: String) {
            let value = on ? "On" : "Off"
            _ = waitUntil(5) { (shuffle.value as? String) == value }
            XCTAssertEqual(shuffle.value as? String, value, what)
            #if os(iOS)
            // The Mac's accessibility has no selected state for a button; its value says it.
            XCTAssertEqual(shuffle.isSelected, on, what)
            #endif
        }
        expect(false, "Shuffle starts off")
        press(shuffle)
        expect(true, "Shuffle says it's on once pressed")
        press(shuffle)
        expect(false, "Shuffle says it's off again")
    }
    #endif

    /// Waits until Play/Pause offers `label` (Play while paused).
    private func waitForPlayPause(_ label: String, _ what: String) {
        let button = element("music.playPause")
        _ = waitUntil(10) { button.label == label }
        if button.label != label { fail("\(what): Play/Pause says \(button.label)") }
    }

    #if os(iOS) || os(macOS)
    private var device: String {
        #if os(macOS)
        "mac"
        #else
        UIDevice.current.userInterfaceIdiom == .pad ? "ipad" : "iphone"
        #endif
    }

    #if os(iOS)
    /// A toast while music plays sits over the tab bar and the mini-player, clear of both.
    func testToastClearsTheMiniPlayer() {
        openArtist()
        press(require(label: "Sine Album", "the album card"))
        require("music.album", "the album screen")
        press(require("music.track.1", "Low Hum's row"))
        let mini = require("music.mini", timeout: 30, "the mini-player")
        _ = waitUntil(5) { element("detail.download").isHittable }
        // The album's download answers with a toast.
        press(require("detail.download", "the album's download button"))
        let toast = require("music.message", timeout: 15, "the download's toast")
        shot("\(device) toast over the mini player")
        if toast.frame.maxY > mini.frame.minY + 1 {
            fail("the toast (\(toast.frame)) overlaps the mini-player (\(mini.frame))")
        }
    }
    #endif

    #if os(iOS)
    /// While music plays, every scrolling screen leaves room for the mini-player, wherever the tab view puts it (over
    /// the bottom tab bar, or floating at the foot where the tabs are a rail, as on the iPhone Duo): at the end of the
    /// album's tracks, an Explore grid, the Settings hub and Appearance nothing lies under it. The album's and the
    /// artist's headers and Watch Together's lobby name themselves, so their bars show no second title.
    func testMiniPlayerLeavesRoom() {
        executionTimeAllowance = 900
        let seerr = "maestro@plezy.test:maestro@http://192.168.0.15:28099/run/\(UUID().uuidString)"
        openArtist(arguments: ["--dev-seerr", seerr])
        // Every screen's findings, not the first alone.
        continueAfterFailure = true
        shot("\(device) artist header")
        requireNoBarTitle("Plezy Test Artist", "the artist")
        press(require(label: "Sine Album", "the album card"))
        let album = require("music.album", "the album screen")
        // The push and the header's artwork settle before the shot and the bar-title check; nothing signals their end.
        Thread.sleep(forTimeInterval: 2)
        shot("\(device) album header")
        requireNoBarTitle("Sine Album", "the album")
        press(require("music.track.0", "Morning Tone's row"))
        let mini = require("music.mini", timeout: 30, "the mini-player")
        _ = waitUntil(5) { mini.isHittable }
        requireEndClears(mini, album, "the album's tracks")
        shot("\(device) album tracks end")

        goTab("libraries")
        let steps = LibrarySteps(test: self)
        steps.pickLibrary("Music")
        steps.showLibraryTab("playlists")
        // The audio playlist opens its music page.
        press(require(label: "Plezy Mix", "the playlist Plezy Mix"))
        require("music.playlist", "Plezy Mix's music page")
        // The header's artwork comes over the network.
        Thread.sleep(forTimeInterval: 2)
        shot("\(device) playlist header")

        goTab("explore")
        require("hub.explore:seerr:popularMovies", timeout: 60, "Explore's Popular Movies")
        let viewAll = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'hub.explore:' AND identifier ENDSWITH '.viewAll'")).firstMatch
        if !viewAll.exists(within: 10) { return fail("Explore shows no shelf's View all") }
        press(viewAll)
        let grid = require("exploreRow.screen", timeout: 20, "the shelf's grid")
        _ = waitUntil(10) { grid.staticTexts.firstMatch.exists }
        requireEndClears(mini, grid, "the Explore grid")
        shot("\(device) explore grid end")

        // The artist opened on Home's stack: picked again, the tab pops to Home.
        goTab("home")
        if !element("home.watchTogether").exists(within: 5) { goTab("home") }
        let chip = require("home.watchTogether", timeout: 30, "Home's Watch Together action")
        for _ in 0..<4 where !chip.isHittable { app.swipeDown() }
        press(chip)
        require("watch.create", "the lobby's Create Room")
        // The push settles before the shot and the bar-title check; nothing signals its end.
        Thread.sleep(forTimeInterval: 1.5)
        shot("\(device) watch together")
        requireNoBarTitle("Watch Together", "Watch Together's lobby")

        goTab("settings")
        let hub = require("settings.screen", "the Settings hub")
        _ = waitUntil(5) { hub.staticTexts.firstMatch.exists }
        requireEndClears(mini, hub, "the Settings hub")
        shot("\(device) settings end")
        let appearance = element("settings.row.appearance")
        // Clear of the navigation bar and the mini-player, not only hittable: a row turns hittable with its middle still
        // under the bar, where the tap lands on the bar and opens nothing.
        func clear() -> Bool {
            appearance.isHittable && appearance.frame.midY > app.navigationBars.firstMatch.frame.maxY && appearance.frame.maxY < mini.frame.minY
        }
        for _ in 0..<8 where !clear() { hub.swipeDown() }
        // A list still moving takes a tap as the end of its scroll.
        Thread.sleep(forTimeInterval: 1)
        press(appearance)
        let page = require("settings.page.appearance", "Appearance")
        // The push animation finishes before the shot; nothing signals its end.
        Thread.sleep(forTimeInterval: 1.5)
        shot("\(device) appearance")
        requireEndClears(mini, page, "Appearance")
        shot("\(device) appearance end")
    }

    /// The tab `name` (`nav.<name>`): the tab bar's button, else the rail's or the sidebar's.
    private func goTab(_ name: String) {
        let bar = app.tabBars.buttons.matching(identifier: "nav.\(name)").firstMatch
        press(bar.exists(within: 5) ? bar : require("nav.\(name)", "the \(name) tab"))
    }

    /// Fails with `what` where the navigation bar shows `title`, which the page's header already shows.
    private func requireNoBarTitle(_ title: String, _ what: String) {
        let shown = app.navigationBars.staticTexts.matching(NSPredicate(format: "label == %@", title)).firstMatch
        if shown.exists { fail("\(what): the navigation bar shows its title '\(title)' over the header that shows it") }
    }

    /// Scrolls `container` to its end, then fails with `what` where a text or a switch of it lies under `cover` (the
    /// mini-player).
    private func requireEndClears(_ cover: XCUIElement, _ container: XCUIElement, _ what: String) {
        var last: [CGRect] = []
        for _ in 0..<20 {
            let frames = container.staticTexts.allElementsBoundByIndex.map(\.frame)
            if frames == last { break }
            last = frames
            container.swipeUp()
            // The scroll settles before its frames are compared: unchanged frames mean the end.
            Thread.sleep(forTimeInterval: 0.5)
        }
        // The last scroll's deceleration ends before the frames are read.
        Thread.sleep(forTimeInterval: 1)
        let covered = cover.frame
        let under = (container.staticTexts.allElementsBoundByIndex + container.switches.allElementsBoundByIndex)
            .first { $0.frame.intersects(covered) }
        if let under { fail("\(what): '\(under.label)' at \(under.frame) lies under the mini-player at \(covered) at the end of the scroll") }
    }
    #endif

    #if os(iOS)
    func testArtistToQueue() {
        openArtist()
        shot("\(device) artist")
        press(require(label: "Sine Album", "the album card"))
        require("music.album", "the album screen")
        // The album's artwork comes over the network.
        Thread.sleep(forTimeInterval: 2)
        shot("\(device) album")
        #if os(iOS)
        // The round glass ⋯ menu reads as one named button.
        requireSpokenNames(in: require("music.album.more", "the album's ⋯"), "the album's ⋯")
        #endif

        press(require("music.track.1", "Low Hum's row"))
        let mini = require("music.mini", timeout: 30, "the mini-player")
        // The equalizer moves on Low Hum's row once it plays.
        Thread.sleep(forTimeInterval: 4)
        shot("\(device) mini player")

        press(require("music.mini.open", "the mini-player's track"))
        require("music.np.screen", "Now Playing")
        XCTAssertFalse(mini.exists, "the mini-player hides under Now Playing")
        require("music.np.title", "the track's title")
        // The artwork comes over the network.
        Thread.sleep(forTimeInterval: 3)
        shot("\(device) now playing")
        checkShuffleState()

        press(require("music.np.lyrics", "the lyrics button"))
        require("music.lyrics", timeout: 30, "the synced lyrics")
        // The lyrics scroll to the playing line before the shot.
        Thread.sleep(forTimeInterval: 3)
        shot("\(device) lyrics")

        if element("music.np.queue").exists {
            // Portrait: the queue is a sheet.
            press(element("music.np.queue"))
            require("music.queue", "the queue")
            // The sheet's slide-in finishes before the shot.
            Thread.sleep(forTimeInterval: 2)
            shot("\(device) queue")
        } else {
            // Wide: the queue is inline beside the artwork (or lyrics).
            require("music.queue", "the inline queue")
        }
    }
    #endif

    /// Low Hum of Sine Album playing on Now Playing, opened from the mini-player (on the Mac the playback bar's track).
    private func openNowPlaying() {
        openArtist()
        press(require(label: "Sine Album", "the album card"))
        press(require("music.track.1", "Low Hum's row"))
        #if os(macOS)
        require("music.bar", timeout: 30, "the playback bar")
        Thread.sleep(forTimeInterval: 3)
        press(require("music.bar.open", "the playback bar's track"))
        #else
        require("music.mini", timeout: 30, "the mini-player")
        // Once it has slid in.
        _ = waitUntil(5) { element("music.mini.open").isHittable }
        press(require("music.mini.open", "the mini-player's track"))
        #endif
        require("music.np.screen", "Now Playing")
        require("music.np.title", "the track's title")
        _ = waitUntil(5) { element("music.playPause").isHittable }
    }

    /// The album's ⋯ and a track's ⋯ open the shared item menu: the music actions, Download (or Delete download) and,
    /// for the track, File Info; on its own album the track's has no Go to album.
    func testAlbumAndTrackMenusAreTheItemMenu() {
        openArtist()
        press(require(label: "Sine Album", "the album card"))
        require("music.album", "the album screen")
        requireRowsAsTallAsTheirMenus()
        press(require("music.album.more", "the album's ⋯"))
        require("menu.music_play_next", "Play next in the album's menu")
        require("menu.music_go_to_artist", "Go to artist in the album's menu")
        // Play, Instant Mix and the download are the album's row's own buttons: its ⋯ leaves them out.
        for entry in ["menu.music_play", "menu.music_instant_mix", "menu.download"] where element(entry).exists {
            fail("the album's menu offers \(entry), which its row shows")
        }
        shotOfMenu("\(device) album menu")
        closeMenu()
        if !element("menu.music_play_next").waitForNonExistence(timeout: 5) { fail("The album's menu didn't close") }
        press(require("music.track.1.more", "Low Hum's ⋯"))
        require("menu.fileinfo", "File Info in the track's menu")
        requireDownloadEntry("the track's menu")
        XCTAssertFalse(element("menu.music_go_to_album").exists, "No Go to album on the track's own album")
        shotOfMenu("\(device) track menu")
        closeMenu()
    }

    #if os(macOS)
    /// Space pauses and plays again on the full-window player; then the overflow and the sleep timer menu; Escape closes
    /// it, back to the album.
    func testSpaceAndSleepTimer() {
        openNowPlaying()
        waitForPlayPause("Pause", "Low Hum didn't play")
        app.typeKey(" ", modifierFlags: [])
        waitForPlayPause("Play", "Space didn't pause")
        Thread.sleep(forTimeInterval: 1)
        shot("mac space paused")
        app.typeKey(" ", modifierFlags: [])
        waitForPlayPause("Pause", "Space didn't play again")
        Thread.sleep(forTimeInterval: 1)
        shot("mac space playing")
        checkSleepTimer("mac")
        app.typeKey(XCUIKeyboardKey.escape, modifierFlags: [])
        if !element("music.np.screen").waitForNonExistence(timeout: 5) { fail("Escape didn't close the full-window player") }
        require("music.album", "the album under the full-window player")
    }

    /// The pane toggles `on` say they are selected, those `off` not (`what`: the panes shown), once they follow.
    private func expectSelected(_ on: [String], not off: [String], _ what: String) {
        let deadline = Date.now.addingTimeInterval(5)
        func settled() -> Bool { on.allSatisfy { element($0).isSelected } && !off.contains { element($0).isSelected } }
        while !settled(), Date.now < deadline { Thread.sleep(forTimeInterval: 0.3) }
        for id in on { XCTAssertTrue(element(id).isSelected, "\(id) is selected \(what)") }
        for id in off { XCTAssertFalse(element(id).isSelected, "\(id) isn't selected \(what)") }
    }

    /// Low Hum playing from Sine Album: the playback bar floats at the album's foot with its volume. Lyrics opens the side
    /// panel beside the album on the synced lyrics; Queue switches it to the queue, and again closes it, each toggle
    /// selected while its pane shows. The bar's Shuffle tells its state. The bar's track opens the full-window player over
    /// the window (the bar gone), with its volume and its own Shuffle's state; its Lyrics and Queue show beside the column,
    /// selected while they do, and Close goes back to the album with the bar. Last, in the panel's queue the first row
    /// dragged by its handle onto the third moves there (a click soon after the synthesized drag is lost, so nothing is
    /// clicked after it).
    func testBarPanelAndFullPlayer() {
        openArtist()
        press(require(label: "Sine Album", "the album card"))
        require("music.album", "the album screen")
        press(require("music.track.1", "Low Hum's row"))
        let bar = require("music.bar", timeout: 30, "the playback bar")
        require("music.bar.volume", "the bar's volume")
        XCTAssertFalse(element("music.mini").exists, "the Mac has the playback bar, no mini-player")
        // The equalizer moves on Low Hum's row once it plays.
        Thread.sleep(forTimeInterval: 4)
        shot("mac album playing")

        press(require("music.bar.lyrics", "the bar's Lyrics"))
        require("music.panel", "the side panel")
        require("music.lyrics", timeout: 30, "the synced lyrics in the panel")
        require("music.album", "the album beside the panel")
        Thread.sleep(forTimeInterval: 3)
        shot("mac lyrics panel")
        expectSelected(["music.bar.lyrics"], not: ["music.bar.queue"], "with the lyrics in the panel")
        press(require("music.bar.queue", "the bar's Queue"))
        let first = require("music.queue.0", "the queue's first row")
        XCTAssertFalse(element("music.lyrics").exists, "the queue takes the lyrics' place")
        XCTAssertTrue(first.label.contains("Morning Tone"), "the queue starts with Morning Tone: \(first.label)")
        Thread.sleep(forTimeInterval: 2)
        shot("mac queue panel")
        expectSelected(["music.bar.queue"], not: ["music.bar.lyrics"], "with the queue in the panel")
        press(element("music.bar.queue"))
        if !element("music.panel").waitForNonExistence(timeout: 5) { fail("Queue again didn't close the panel") }
        expectSelected([], not: ["music.bar.lyrics", "music.bar.queue"], "with the panel closed")
        checkShuffleState("music.bar.shuffle")

        press(require("music.bar.open", "the playback bar's track"))
        require("music.np.screen", "the full-window player")
        if !bar.waitForNonExistence(timeout: 5) { fail("The playback bar stayed over the full-window player") }
        require("music.np.title", "the track's title")
        require("music.np.volume", "the full-window player's volume")
        Thread.sleep(forTimeInterval: 3)
        shot("mac full player")
        checkShuffleState()
        expectSelected([], not: ["music.np.lyrics", "music.np.queue"], "with neither pane beside the column")
        press(require("music.np.lyrics", "the full-window player's Lyrics"))
        require("music.lyrics", timeout: 30, "the synced lyrics beside the column")
        Thread.sleep(forTimeInterval: 3)
        shot("mac full player lyrics")
        expectSelected(["music.np.lyrics"], not: ["music.np.queue"], "with the lyrics beside the column")
        press(require("music.np.queue", "the full-window player's Queue"))
        require("music.queue.0", "the queue beside the column")
        XCTAssertFalse(element("music.lyrics").exists, "the queue takes the lyrics' place")
        Thread.sleep(forTimeInterval: 1.5)
        shot("mac full player queue")
        expectSelected(["music.np.queue"], not: ["music.np.lyrics"], "with the queue beside the column")
        press(require("music.np.close", "the full-window player's Close"))
        if !element("music.np.screen").waitForNonExistence(timeout: 5) { fail("Close didn't leave the full-window player") }
        require("music.album", "the album under the full-window player")
        require("music.bar", "the playback bar back over the album")

        press(require("music.bar.queue", "the bar's Queue"))
        let moved = require("music.queue.0", "the queue's first row").label.components(separatedBy: ",")[0]
        let handle = require("music.queue.0.handle", "the first row's drag handle")
        handle.click(forDuration: 0.5, thenDragTo: require("music.queue.2", "the third row"))
        let third = element("music.queue.2")
        let deadline = Date.now.addingTimeInterval(5)
        while !third.label.hasPrefix(moved), Date.now < deadline { Thread.sleep(forTimeInterval: 0.3) }
        XCTAssertTrue(third.label.hasPrefix(moved), "the handle's drag moved \(moved) to the third place: \(third.label)")
        Thread.sleep(forTimeInterval: 1)
        shot("mac queue reordered")
    }
    #endif

    #if os(iOS)
    /// iPhone, paused on Low Hum: the overflow and the sleep timer menu; the queue's first row (Morning Tone) dragged
    /// after a long press to the third place and its last (Fifth Above) swiped away; then a short slow drag down that
    /// settles back and a long one that closes Now Playing.
    func testQueueEditsAndDragDown() {
        guard UIDevice.current.userInterfaceIdiom == .phone else { return }
        openNowPlaying()
        press(element("music.playPause"))
        waitForPlayPause("Play", "Low Hum didn't pause")
        checkSleepTimer("iphone")

        press(element("music.np.queue"))
        require("music.queue", "the queue")
        // The sheet's slide-in finishes before the shot.
        Thread.sleep(forTimeInterval: 2)
        shot("iphone queue")
        let first = require("music.queue.0", "the queue's first row")
        XCTAssertTrue(first.label.contains("Morning Tone"), "the queue starts with Morning Tone: \(first.label)")
        let marked = (0..<4).filter { (element("music.queue.\($0)").value as? String ?? "").hasPrefix("Now playing") }
        XCTAssertEqual(marked, [1], "the queue's now-playing mark is on the playing row (Low Hum) alone")
        // Slowly, held at the end, to the lower part of the third row: the list drops it there, not a row short.
        first.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).press(
            forDuration: 1.2, thenDragTo: element("music.queue.2").coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.85)),
            withVelocity: .slow, thenHoldForDuration: 0.5
        )
        waitForRow(2, "Morning Tone", "the long-press drag didn't move Morning Tone to the third place")
        shot("iphone queue reordered")
        XCTAssertTrue(element("music.queue.0").label.contains("Low Hum"), "Low Hum moved up to the first place")
        XCTAssertTrue(element("music.queue.0").isSelected, "Low Hum stays the current row")

        let last = require("music.queue.3", "the queue's last row")
        XCTAssertTrue(last.label.contains("Fifth Above"), "the queue ends with Fifth Above: \(last.label)")
        last.swipeLeft()
        if !element("music.queue.3").waitForNonExistence(timeout: 2) {
            // A partial swipe shows the delete action; the row's own × is labelled the same.
            let action = app.buttons.matching(NSPredicate(format: "label == %@ AND NOT (identifier ENDSWITH '.remove')", "Delete")).firstMatch
            if !action.exists(within: 5) { return fail("The swipe showed no delete action") }
            action.tap()
        }
        if !element("music.queue.3").waitForNonExistence(timeout: 5) { fail("The swipe didn't remove Fifth Above") }
        shot("iphone queue removed")
        for index in 0..<3 {
            XCTAssertFalse(element("music.queue.\(index)").label.contains("Fifth Above"), "Fifth Above is gone")
        }
        dismissSheet(element("music.queue"), close: "music.queue.close")
        if !element("music.queue").waitForNonExistence(timeout: 5) { fail("The queue didn't close") }
        _ = waitUntil(5) { element("music.np.screen").isHittable }

        let screen = element("music.np.screen")
        let title = element("music.np.title")
        let resting = title.frame.minY
        func drag(from: CGFloat, to: CGFloat) {
            screen.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: from)).press(
                forDuration: 0.1, thenDragTo: screen.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: to)),
                withVelocity: .slow, thenHoldForDuration: 0.5
            )
        }
        // An eighth of the screen, slowly and held: it settles back.
        drag(from: 0.3, to: 0.42)
        // Time for the drag to settle back, or to close the screen if it wrongly would.
        Thread.sleep(forTimeInterval: 1)
        if !screen.exists { return fail("A short drag closed Now Playing") }
        XCTAssertEqual(title.frame.minY, resting, accuracy: 2, "a short drag settles back")
        shot("iphone drag settled")
        // Half the screen: it closes onto the album, the mini-player back.
        drag(from: 0.25, to: 0.75)
        if !screen.waitForNonExistence(timeout: 5) { return fail("A drag past a quarter of the screen didn't close Now Playing") }
        require("music.mini", "the mini-player")
        shot("iphone drag closed")
    }

    /// Waits until the queue's row `index` holds `title`.
    private func waitForRow(_ index: Int, _ title: String, _ what: String) {
        let row = element("music.queue.\(index)")
        _ = waitUntil(5) { row.label.contains(title) }
        if !row.label.contains(title) { fail("\(what): the row holds \(row.label)") }
    }
    #endif

    #if os(iOS)
    /// The album's action row at an accessibility text size (the app's own content size, `UIPreferredContentSizeCategoryName`
    /// at launch): one row inside the window, Play with its label, Shuffle reached as a button or behind ⋯.
    func testAlbumActionsAtLargeText() {
        openArtist(arguments: ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityL"])
        press(require(label: "Sine Album", "the album card"))
        require("music.album", "the album screen")
        let play = require("music.play", "the album's Play")
        // The album's artwork comes over the network.
        Thread.sleep(forTimeInterval: 2)
        shot("\(device) album large text")
        let window = app.windows.firstMatch.frame
        let row = ["music.play", "music.shuffle", "music.instantMix", "detail.download", "music.album.more"]
            .map { element($0) }.filter(\.exists)
        for button in row {
            XCTAssertTrue(window.contains(button.frame), "\(button.identifier) sits inside the window: \(button.frame) in \(window)")
            XCTAssertEqual(button.frame.midY, play.frame.midY, accuracy: 2, "\(button.identifier) is on Play's row")
        }
        XCTAssertEqual(play.label, "Play", "Play keeps its label")
        if !element("music.shuffle").exists {
            press(require("music.album.more", "the album's ⋯"))
            require("menu.music_shuffle", "Shuffle behind ⋯")
            shot("\(device) album large text more")
            closeMenu()
        }
    }

    /// iPhone in landscape at accessibility text size AX3: Now Playing opens (the column scrolls rather than leave its
    /// artwork no height, an empty frame whose resize ended the app) and keeps the artwork's least side (120 pt)
    /// between the bar and the title. The artwork is hidden from accessibility: its room is read from its neighbours.
    func testNowPlayingLandscapeAtAX3Text() {
        guard UIDevice.current.userInterfaceIdiom == .phone else { return }
        addTeardownBlock { XCUIDevice.shared.orientation = .portrait }
        openArtist(arguments: ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXL"])
        XCUIDevice.shared.orientation = .landscapeLeft
        _ = waitUntil(5) { app.windows.firstMatch.frame.width > app.windows.firstMatch.frame.height }
        press(require(label: "Sine Album", "the album card"))
        press(require("music.track.1", "Low Hum's row"))
        require("music.mini", timeout: 30, "the mini-player")
        _ = waitUntil(5) { element("music.mini.open").isHittable }
        press(require("music.mini.open", "the mini-player's track"))
        require("music.np.screen", "Now Playing")
        let bar = require("music.np.playingFrom", "Playing from …")
        let title = require("music.np.title", "the track's title")
        _ = waitUntil(10) { element("music.nowPlaying").label.contains("artwork=true") }
        XCTAssertEqual(app.state, .runningForeground, "Plezy still runs with Now Playing open")
        XCTAssertTrue(element("music.nowPlaying").label.contains("artwork=true"), "the track has artwork to show")
        let room = title.frame.minY - bar.frame.maxY
        XCTAssertGreaterThanOrEqual(room, 120, "the artwork keeps its least side: \(bar.frame) over \(title.frame)")
        shot("iphone landscape ax3 now playing")
    }

    /// iPhone at accessibility text size AX3: the queue sheet opens scrolled to the current track, so the rows before it
    /// sit under the track count; the count is a bar of the sheet's, which those rows fade under, never printed over.
    func testQueueAtAX3Text() {
        guard UIDevice.current.userInterfaceIdiom == .phone else { return }
        openArtist(arguments: ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXL"])
        press(require(label: "Sine Album", "the album card"))
        press(require("music.track.1", "Low Hum's row"))
        require("music.mini", timeout: 30, "the mini-player")
        _ = waitUntil(5) { element("music.mini.open").isHittable }
        press(require("music.mini.open", "the mini-player's track"))
        require("music.np.screen", "Now Playing")
        press(require("music.np.queue", "the queue button"))
        require("music.queue", "the queue")
        let edit = require("music.queue.edit", "the queue's Edit")
        let close = element("music.queue.close")
        if close.exists { XCTAssertFalse(close.frame.intersects(edit.frame), "Close and Edit apart: \(close.frame) \(edit.frame)") }
        shot("iphone ax3 queue")
    }

    /// iPad in landscape: Now Playing's wide layout, the queue inline, then the album with the mini-player over it.
    func testLandscapeWide() {
        guard UIDevice.current.userInterfaceIdiom == .pad else { return }
        openArtist()
        XCUIDevice.shared.orientation = .landscapeLeft
        _ = waitUntil(5) { app.windows.firstMatch.frame.width > app.windows.firstMatch.frame.height }
        press(require(label: "Sine Album", "the album card"))
        press(require("music.track.1", "Low Hum's row"))
        require("music.mini", timeout: 30, "the mini-player")
        // The album's artwork comes over the network.
        Thread.sleep(forTimeInterval: 3)
        shot("ipad landscape album mini player")
        press(element("music.mini.open"))
        require("music.np.screen", "Now Playing")
        require("music.queue", "the inline queue")
        // The artwork comes over the network.
        Thread.sleep(forTimeInterval: 3)
        shot("ipad landscape now playing")
    }
    #endif

    /// Plezy Mix (`--dev-playlist`, maestro's) on its music page, each row led by its artwork. Edit gives every row its
    /// reorder and remove controls (iPhone and iPad: the list's own grip and minus; the Mac: a handle and a ×) and turns
    /// into Done; ⋯ offers Delete Playlist, closed again unpicked; Done takes the controls away. Nothing is moved,
    /// removed or deleted: Plezy Mix is the test server's shared playlist.
    func testPlaylistEditing() {
        launchDev(settings: ["theme_mode=dark"], arguments: ["--dev-server", Self.server, "--dev-playlist", "jellyfin:Plezy Mix"])
        require("music.playlist", timeout: 90, "Plezy Mix's music page")
        let first = require("music.track.0", timeout: 30, "Plezy Mix's first row")
        // The artwork comes over the network.
        Thread.sleep(forTimeInterval: 4)
        shot("\(device) playlist")
        XCTAssertFalse(element("music.track.0.remove").exists, "no × outside Edit mode")
        XCTAssertTrue(editControls(beside: first).isEmpty, "no edit controls outside Edit mode")

        let edit = require("music.playlist.edit", "the playlist's Edit")
        XCTAssertEqual(edit.label, "Edit", "Edit says what it does")
        press(edit)
        waitForLabel(edit, "Done", "Edit didn't turn into Done")
        _ = waitUntil(5) { element("music.track.0.remove").exists || !editControls(beside: first).isEmpty }
        shot("\(device) playlist editing")
        #if os(macOS)
        require("music.track.0.handle", "the first row's drag handle")
        require("music.track.0.remove", "the first row's ×")
        XCTAssertFalse(element("music.track.0.more").exists, "the × takes the row's ⋯ place in Edit mode")
        #else
        let controls = editControls(beside: first)
        XCTAssertTrue(controls.contains("minus.circle.fill"), "the first row offers the list's remove control: \(controls)")
        XCTAssertTrue(controls.contains { $0.hasPrefix("Reorder") }, "the first row offers the list's reorder grip: \(controls)")
        #endif

        press(require("music.playlist.more", "the playlist's ⋯"))
        let delete = require("music.playlist.delete", "Delete Playlist in ⋯")
        // The Mac's menu items carry their text as their title.
        XCTAssertEqual(delete.title.isEmpty ? delete.label : delete.title, "Delete Playlist")
        shotOfMenu("\(device) playlist menu")
        closeMenu()
        if !delete.waitForNonExistence(timeout: 5) { fail("⋯ didn't close") }
        require("music.track.0", "Plezy Mix's rows, still there")

        press(edit)
        waitForLabel(edit, "Edit", "Done didn't turn back into Edit")
        if !element("music.track.0.remove").waitForNonExistence(timeout: 5) { fail("the × stayed after Done") }
        XCTAssertFalse(element("music.track.0.handle").exists, "the handle goes with Done")
        XCTAssertTrue(editControls(beside: first).isEmpty, "the list's edit controls go with Done")
        shot("\(device) playlist done")
    }

    /// The list's own edit controls on `row`'s line: its minus (named by its symbol) and its grip ("Reorder …").
    private func editControls(beside row: XCUIElement) -> [String] {
        let frame = row.frame
        return app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier == 'minus.circle.fill' OR (elementType == %d AND label BEGINSWITH 'Reorder')", XCUIElement.ElementType.button.rawValue))
            .allElementsBoundByIndex
            .filter { $0.frame.midY > frame.minY && $0.frame.midY < frame.maxY }
            .map { $0.identifier.isEmpty ? $0.label : $0.identifier }
    }

    /// Waits until `button` says `label`.
    private func waitForLabel(_ button: XCUIElement, _ label: String, _ what: String) {
        _ = waitUntil(5) { button.label == label }
        if button.label != label { fail("\(what): it says \(button.label)") }
    }
    #endif

    #if os(iOS)
    /// A track's menu opens over the album's action row on iPhone (Fifth Above's Instant Mix over Play): the entry runs
    /// where it covers the row's glass, which doesn't take the tap while a menu is open (`OpenItemMenu`). iPad's taller
    /// screen opens it under the row.
    func testTrackMenuEntryOverTheActionRowRuns() throws {
        openArtist()
        press(require(label: "Sine Album", "the album card"))
        require("music.album", "the album screen")
        require("music.track.1", "the album's tracks")
        _ = waitUntil(5) { element("music.track.1").isHittable }
        let tracks = NSPredicate(format: "identifier BEGINSWITH 'music.track.' AND NOT identifier ENDSWITH '.more'")
        let row = ["music.play", "music.shuffle", "music.instantMix", "detail.download", "music.album.more"]
        guard let entry = menuEntryOverGlass(row, pressing: tracks) else {
            if UIDevice.current.userInterfaceIdiom == .pad { throw XCTSkip("no track's menu opens over the action row") }
            return fail("no track's menu opens over the action row")
        }
        shot("\(entry.id) over \(entry.glass)")
        tap(at: entry.point)
        if !element(entry.id).waitForNonExistence(timeout: 5) {
            fail("\(entry.id) over \(entry.glass) doesn't run: the menu stays open")
        }
        shot("after \(entry.id)")
    }
    #endif

    #if os(tvOS)
    func testArtistToQueue() {
        openArtist(settings: ["theme_mode=oled"])
        shot("tv artist")
        focus(label: "Sine Album", "the album card")
        XCUIRemote.shared.press(.select)
        require("music.album", "the album screen")
        // The album's artwork comes over the network.
        Thread.sleep(forTimeInterval: 2)
        shot("tv album")
        requireRowsAsTallAsTheirMenus()

        focus(id: "music.track.1", "Low Hum's row")
        XCUIRemote.shared.press(.select)
        // A TV opens Now Playing as playback starts, Play/Pause focused.
        require("music.np.screen", timeout: 30, "Now Playing")
        require("music.np.title", "the track's title")
        // The artwork comes over the network.
        Thread.sleep(forTimeInterval: 4)
        shot("tv now playing")

        focus(id: "music.np.lyrics", "the lyrics button")
        XCUIRemote.shared.press(.select)
        require("music.lyrics", timeout: 30, "the synced lyrics")
        // The lyrics scroll to the playing line before the shot.
        Thread.sleep(forTimeInterval: 3)
        shot("tv lyrics")

        focus(id: "music.np.queue", "the queue button")
        XCUIRemote.shared.press(.select)
        require("music.queue", "the queue")
        // The panel's slide-in finishes before the shot.
        Thread.sleep(forTimeInterval: 2)
        shot("tv queue")

        XCUIRemote.shared.press(.menu)
        if !element("music.queue").waitForNonExistence(timeout: 5) { fail("Menu didn't close the queue") }
        shot("tv queue closed")
        XCUIRemote.shared.press(.menu)
        // Back on the album.
        if !element("music.np.screen").waitForNonExistence(timeout: 10) { fail("Menu didn't close Now Playing") }
        require("music.album", "the album under Now Playing")
        // The pop back to the album finishes before the shot; nothing signals its end.
        Thread.sleep(forTimeInterval: 2)
        shot("tv album playing")
        // A pushed page has no tab bar on Apple TV: Menu goes back down the stack, and at its root brings the tab bar
        // up, where Now Playing shows while the music plays.
        // Menu stops once focus is in the tab bar: one more would leave the app.
        let tab = element("nav.nowPlaying")
        let inTabBar = app.descendants(matching: .any)
            .matching(NSPredicate(format: "hasFocus == true AND identifier BEGINSWITH 'nav.'")).firstMatch
        for _ in 0..<4 where !inTabBar.exists {
            XCUIRemote.shared.press(.menu)
            _ = waitUntil(1.5) { inTabBar.exists }
        }
        require("nav.nowPlaying", "the tab bar's Now Playing")
        // The tab bar's slide-in finishes before the shot.
        Thread.sleep(forTimeInterval: 2)
        shot("tv tab bar now playing")
        // Back into Now Playing from its tab: the tab's page, then its button.
        for _ in 0..<8 where !tab.hasFocus {
            XCUIRemote.shared.press(.right)
            _ = waitUntil(0.5) { tab.hasFocus }
        }
        if !tab.hasFocus { return fail("Focus never reached the Now Playing tab") }
        XCUIRemote.shared.press(.select)
        let open = require("nowPlaying.open", "the Now Playing tab's button")
        for _ in 0..<3 where !open.hasFocus {
            XCUIRemote.shared.press(.down)
            _ = waitUntil(0.5) { open.hasFocus }
        }
        XCUIRemote.shared.press(.select)
        require("music.np.screen", timeout: 15, "Now Playing opened again from its tab")
        require("music.np.title", "the playing track's title")
        shot("tv now playing from its tab")
    }

    /// Now Playing paused on Low Hum (a 30 s track): the seek bar focused, Left back to the start, then two quick
    /// Rights, which add up (10 s, then 10 or 15 s) and seek once they stop; then the overflow and the sleep timer menu.
    func testSeekStepsAndSleepTimer() {
        openArtist(settings: ["theme_mode=oled"])
        focus(label: "Sine Album", "the album card")
        XCUIRemote.shared.press(.select)
        require("music.album", "the album screen")
        focus(id: "music.track.1", "Low Hum's row")
        XCUIRemote.shared.press(.select)
        require("music.np.screen", timeout: 30, "Now Playing")
        require("music.np.title", "the track's title")
        _ = waitUntil(5) { element("music.playPause").hasFocus }
        // Play/Pause has focus.
        XCUIRemote.shared.press(.select)
        waitForPlayPause("Play", "Select on Play/Pause didn't pause")

        let seek = element("music.seekBar")
        focus(seek, "the seek bar")
        XCUIRemote.shared.press(.left)
        _ = waitUntil(5) { (seconds(seek.value as? String ?? "") ?? -1) <= 1 }
        let start = seconds(seek.value as? String ?? "") ?? -1
        XCTAssertLessThanOrEqual(start, 1, "Left from a few seconds in goes back to the start")
        shot("tv seek start")
        XCUIRemote.shared.press(.right)
        XCUIRemote.shared.press(.right)
        _ = waitUntil(6) { (seconds(seek.value as? String ?? "") ?? -1) - start >= 20 }
        let stepped = seconds(seek.value as? String ?? "") ?? -1
        shot("tv seek stepped")
        XCTAssertGreaterThanOrEqual(stepped - start, 20, "two Rights seek 20 s or more (\(start) s to \(stepped) s)")
        XCTAssertEqual(element("music.np.title").label, "Low Hum", "the steps stay on the track")

        checkSleepTimer("tv")
    }

    /// Moves focus with the remote toward `target` until it has it: each press goes the way the target lies from the
    /// focused element (out of the tab bar first, then up or down, then sideways).
    private func focus(_ target: XCUIElement, _ what: String) {
        guard target.exists(within: 30) else { return fail("No \(what)") }
        let focused = app.descendants(matching: .any).matching(NSPredicate(format: "hasFocus == true")).firstMatch
        // A system menu's button takes focus on an element inside it.
        func reached() -> Bool {
            target.hasFocus || target.descendants(matching: .any).matching(NSPredicate(format: "hasFocus == true")).firstMatch.exists
        }
        for _ in 0..<24 {
            if reached() { return }
            let to = target.frame, from = focused.exists ? focused.frame : .zero
            let direction: XCUIRemote.Button
            if focused.exists, focused.identifier.hasPrefix("nav.") {
                // Out of the tab bar first.
                direction = .down
            } else if to.minY >= from.maxY - 1 {
                direction = .down
            } else if to.maxY <= from.minY + 1 {
                direction = .up
            } else {
                direction = to.midX > from.midX ? .right : .left
            }
            XCUIRemote.shared.press(direction)
            _ = waitUntil(0.5) { reached() }
        }
        if !reached() { fail("Focus never reached \(what)") }
    }

    private func focus(id: String, _ what: String) {
        focus(element(id), what)
    }

    private func focus(label: String, _ what: String) {
        focus(app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", label)).firstMatch, what)
    }
    #endif
}
