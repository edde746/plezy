import XCTest

/// Live TV against the Jellyfin test server (`--dev-server`, its three M3U/XMLTV channels): the guide, a focused
/// program (Apple TV: the remote's presses), the program details sheet, the Recordings tab and its rules, the reorder
/// favourites sheet and a show's schedule, each kept as a screenshot. The server's address and account are
/// `PLEZY_LIVETV_SERVER`'s (`jellyfin=<user>:<password>@<url>`), else the default test server; what a test adds there
/// (favourites, a recording rule) its teardown takes away through the server's API.
final class LiveTvTests: PlezyUITestCase {
    private static var server: String {
        let value = ProcessInfo.processInfo.environment["PLEZY_LIVETV_SERVER"] ?? ""
        guard value.isEmpty else { return value }
        #if os(macOS)
        // The Mac app gets no local network access unattended: the test server comes through a loopback tunnel.
        return "jellyfin=maestro:maestro@http://127.0.0.1:28096"
        #else
        return "jellyfin=maestro:maestro@http://192.168.0.15:28096"
        #endif
    }

    /// Starts a dev session signed in to the test server on Live TV and waits for its guide.
    private func openGuide() {
        launchDev(arguments: ["--dev-server", Self.server, "--dev-open", "live_tv"])
        require("livetv.screen", timeout: 90, "the Live TV screen")
        // The guide's channels, then the first channel's blocks.
        require("livetv.guide.channel.0", timeout: 60, "the guide's channels")
        let programs = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'livetv.guide.program.0.'"))
        if !programs.firstMatch.exists(within: 30) { fail("the guide's programs") }
        // The logos come over the network.
        Thread.sleep(forTimeInterval: 3)
    }

    /// The guide shows its spinner alone until its programs are in (the test's proxy holds them), then its grid.
    func testGuideShowsASpinnerUntilItsPrograms() {
        guard let upstream = ServerProxy.upstream(of: Self.server), let proxy = ServerProxy(upstream: upstream) else {
            return fail("no proxy on the loopback in front of \(Self.server)")
        }
        addTeardownBlock {
            let log = XCTAttachment(string: proxy.log)
            log.name = "proxy requests"
            log.lifetime = .keepAlways
            self.add(log)
            proxy.stop()
        }
        proxy.hold(path: "/LiveTv/Programs")
        launchDev(arguments: ["--dev-server", proxy.server(for: Self.server), "--dev-open", "live_tv"])
        if proxy.heldPath(within: 90) == nil { fail("the guide asked for no programs") }
        _ = element("livetv.guide.loading").exists(within: 10)
        shot("livetv loading")
        require("livetv.guide.loading", "the guide's spinner while its programs load")
        XCTAssertFalse(element("livetv.guide.channel.0").exists, "no guide beside the spinner")
        proxy.release()
        require("livetv.guide.channel.0", timeout: 60, "the guide's channels once the programs are in")
        XCTAssertFalse(element("livetv.guide.loading").exists, "the spinner gone with the guide shown")
        #if os(tvOS)
        // Focus lands on the first channel once the programs are in.
        let first = element("livetv.guide.channel.0")
        if !waitUntil(10, { hasFocus(first) }) { fail("the first channel takes no focus once the programs are in") }
        #endif
        // The logos come over the network.
        Thread.sleep(forTimeInterval: 3)
        shot("livetv loaded")
    }

    func testGuideDetailsAndRecordings() {
        openGuide()
        shot("livetv guide")

        #if os(tvOS)
        // The guide takes focus on the first channel once its channels load; Right moves to an airing.
        focus(element("livetv.guide.channel.0"), pressing: .left, limit: 2, "the first channel")
        XCUIRemote.shared.press(.right)
        // Focus on an airing whose block isn't known ahead: the focus animation settles before the shot.
        Thread.sleep(forTimeInterval: 1.5)
        shot("livetv guide focused program")
        // A hold of Select opens the details.
        XCUIRemote.shared.press(.select, forDuration: 1.2)
        require("livetv.details", timeout: 10, "the program details")
        // The sheet's presentation animation.
        Thread.sleep(forTimeInterval: 1)
        shot("livetv program details")
        XCUIRemote.shared.press(.menu)
        XCTAssertTrue(element("livetv.details").waitForNonExistence(timeout: 10), "the details close")

        // The first channel's menu (Select held): View details opens what it airs now, and Back from them gives focus
        // back to the channel, not to the header.
        let channel = element("livetv.guide.channel.0")
        focus(channel, pressing: .left, limit: 3, "the first channel, back from the details")
        XCUIRemote.shared.press(.select, forDuration: 1.5)
        _ = waitUntil(5) { self.element("livetv.guide.details").exists || self.app.buttons["View details"].exists }
        focus(entry("livetv.guide.details", "View details"), pressing: .down, "the channel menu's View details")
        shot("livetv channel menu details focused")
        XCUIRemote.shared.press(.select)
        require("livetv.details", timeout: 10, "the details of what the channel airs")
        // The sheet's presentation animation.
        Thread.sleep(forTimeInterval: 1)
        shot("livetv channel menu details")
        XCUIRemote.shared.press(.menu)
        XCTAssertTrue(element("livetv.details").waitForNonExistence(timeout: 10), "the channel's details close")
        _ = waitUntil(5) { hasFocus(channel) }
        shot("livetv channel menu details closed")
        if !waitUntil(5, { hasFocus(channel) }) { fail("Back from the channel menu's details focuses no channel") }
        #else
        // The first block of the first channel in view (the guide opens at the start of a half hour), clear of
        // the channel column pinned over the blocks that scrolled under it: a tap there tunes the channel.
        let channelEnd = element("livetv.guide.channel.0").frame.maxX
        guard let program = (0..<16).lazy.map({ self.element("livetv.guide.program.0.\($0)") })
            .first(where: { $0.exists && $0.frame.minX >= channelEnd - 1 && $0.isHittable }) else {
            return fail("a program in view")
        }
        activate(program)
        let details = require("livetv.details", timeout: 10, "the program details")
        // The sheet's presentation animation.
        Thread.sleep(forTimeInterval: 1)
        shot("livetv program details")
        XCTAssertTrue(element("livetv.details.title").exists, "the details' title")
        closeSheet("livetv.details.close")
        XCTAssertTrue(details.waitForNonExistence(timeout: 5), "the details close")
        #endif

        let recordings = element("livetv.tab.recordings")
        if recordings.exists(within: 5) {
            #if os(tvOS)
            // Up past the time navigation to the tab chips, along them to Recordings.
            focusHeader(recordings, "the Recordings chip")
            shot("livetv tab chips focused")
            #endif
            activate(recordings)
            _ = waitUntil(5) { recordings.isSelected || (recordings.value as? NSNumber)?.intValue == 1 }
            shot("livetv recordings")
            // Recordings is the tab picked, and the header keeps both tabs and the actions every tab has.
            XCTAssertTrue(recordings.isSelected || (recordings.value as? NSNumber)?.intValue == 1, "Recordings shows as picked")
            for id in ["livetv.tab.guide", "livetv.tab.recordings", "livetv.action.search", "livetv.action.refresh"] {
                XCTAssertTrue(element(id).exists, "\(id) stays in the header on Recordings")
            }
            #if os(macOS) || os(tvOS)
            // With something scheduled, its rows start where the header's tabs do, not in a column of their own (on
            // Apple TV the form's card, whose button keeps 20 pt inside it, at the chips' edge).
            let firstRow = element("livetv.recordings.grab.0")
            if firstRow.exists(within: 10) {
                #if os(macOS)
                let tabs = element("livetv.tabs")
                let inset: CGFloat = 0
                #else
                let tabs = element("livetv.tab.guide")
                let inset: CGFloat = 20
                #endif
                XCTAssertEqual(firstRow.frame.minX, tabs.frame.minX + inset, accuracy: 2, "the first scheduled row starts under the tabs")
            }
            #endif
        }
    }

    /// Apple TV: the day pill names what is in view. It opens on "Now"; walking the airings hours on scrolls now out of
    /// view, and the pill names the day and time the view starts at.
    func testDayPillFollowsTheView() throws {
        #if os(tvOS)
        openGuide()
        let day = element("livetv.guide.day")
        focus(element("livetv.guide.channel.0"), pressing: .left, limit: 2, "the first channel")
        shot("livetv guide pill now")
        XCTAssertEqual(day.label, "Now", "the live window opens showing now")
        for _ in 0..<12 {
            XCUIRemote.shared.press(.right)
            Thread.sleep(forTimeInterval: 0.4)
        }
        // The scroll to the last block settles.
        Thread.sleep(forTimeInterval: 1.5)
        shot("livetv guide pill scrolled")
        if !waitUntil(5, { day.label != "Now" }) { fail("the day pill still says Now with now out of view: \(day.label)") }
        #else
        throw XCTSkip("the remote walks the airings on Apple TV alone")
        #endif
    }

    /// The first channel tuned into the player, on the Mac the next channel zapped to with Shift+N, then back out to the
    /// guide.
    func testTuneAndZap() {
        openGuide()
        let channel = element("livetv.guide.channel.0")
        #if os(tvOS)
        // Focus starts on the first channel's cell.
        focus(channel, pressing: .left, limit: 2, "the first channel")
        #endif
        activate(channel)
        // The video's label names what plays: the channel.
        let video = require("player.video", timeout: 30, "the player")
        let tuned = video.label
        XCTAssertFalse(tuned.isEmpty, "the channel's name on the video")
        // The video's first frames: nothing signals them.
        Thread.sleep(forTimeInterval: 5)
        shot("livetv playing")

        // The next channel: Shift+N (next episode, the next channel live) on the Mac. The live controls have no next
        // button on any device, as Plezy's never had: elsewhere the zap comes from the OS media controls, which a UI
        // test can't press.
        #if os(macOS)
        app.typeKey("n", modifierFlags: [.shift])
        let zapped = NSPredicate(format: "label != %@", tuned)
        XCTAssertEqual(XCTWaiter.wait(for: [expectation(for: zapped, evaluatedWith: video)], timeout: 30), .completed, "the next channel plays")
        Thread.sleep(forTimeInterval: 5)
        shot("livetv zapped")
        #endif

        closePlayer()
        require("livetv.guide.channel.0", timeout: 15, "the guide again")
        shot("livetv back from player")
    }

    /// The day picker (the system's menu, whose days are submenus of their time slots), a channel made a favourite (and
    /// back) through its context menu, the guide search and, on Apple TV, Back out of the guide: Live TV, pushed over
    /// Home, pops to Home and on to its tab in the tab bar.
    func testMenuFavoriteSearchAndTabBar() {
        openGuide()
        let channel = element("livetv.guide.channel.0")
        let day = element("livetv.guide.day")

        // The day picker, closed with "Now"; on Apple TV first Tomorrow's Morning from its submenu.
        #if os(tvOS)
        focus(day, pressing: .up, limit: 2, "the day chip")
        #endif
        activate(day)
        let now = require("livetv.guide.menu.0", timeout: 10, "the day picker")
        // The menu's opening animation.
        Thread.sleep(forTimeInterval: 1)
        shot("livetv day picker")
        #if os(tvOS)
        let tomorrow = element("livetv.guide.menu.2")
        focus(tomorrow, pressing: .down, limit: 4, "Tomorrow")
        activate(tomorrow)
        let morning = require("livetv.guide.menu.2.2", timeout: 10, "Tomorrow's time slots")
        // The submenu's opening animation.
        Thread.sleep(forTimeInterval: 1)
        shot("livetv day slots")
        focus(morning, pressing: .down, limit: 4, "Morning")
        activate(morning)
        XCTAssertTrue(morning.waitForNonExistence(timeout: 5), "the slots close")
        let tomorrowShown = NSPredicate(format: "label BEGINSWITH 'Tomorrow'")
        if XCTWaiter.wait(for: [expectation(for: tomorrowShown, evaluatedWith: day)], timeout: 10) != .completed {
            fail("the guide shows no Tomorrow: \(day.label)")
        }
        focus(day, pressing: .up, limit: 2, "the day chip, back from its menu")
        activate(day)
        require("livetv.guide.menu.0", timeout: 10, "the day picker again")
        focus(now, pressing: .up, limit: 3, "Now")
        #endif
        activate(now)
        XCTAssertTrue(now.waitForNonExistence(timeout: 5), "the day picker closes")
        _ = waitUntil(5) { channel.isHittable }

        // The first channel's context menu adds it to the favourites: its star shows. Again takes it off.
        let favorites = "Favorites"
        #if os(tvOS)
        // Focus is back on the day chip: down to the grid, left to the first channel.
        XCUIRemote.shared.press(.down)
        _ = waitUntil(5) { !hasFocus(day) }
        focus(channel, pressing: .left, limit: 4, "the first channel")
        #endif
        toggleFavorite(channel)
        let starred = NSPredicate(format: "value == %@", favorites)
        if XCTWaiter.wait(for: [expectation(for: starred, evaluatedWith: channel)], timeout: 10) != .completed {
            fail("the first channel's star")
        }
        shot("livetv favorite channel")
        toggleFavorite(channel)
        let plain = NSPredicate(format: "value != %@", favorites)
        XCTAssertEqual(XCTWaiter.wait(for: [expectation(for: plain, evaluatedWith: channel)], timeout: 10), .completed, "the star goes")

        #if os(tvOS)
        // Back from the guide: Live TV pops to Home, whose tab bar shows again; Menu from Home's content goes up to
        // Home's tab.
        let home = element("nav.home")
        for _ in 0..<3 where !hasFocus(home) {
            XCUIRemote.shared.press(.menu)
            _ = waitUntil(1.5) { hasFocus(home) }
        }
        shot("livetv back to tab bar")
        XCTAssertFalse(element("livetv.screen").exists, "Live TV pops")
        XCTAssertTrue(hasFocus(home), "Home's tab has focus")
        #else
        // The search: "tone" finds the channels and the airings.
        activate(element("livetv.action.search"))
        require("livetv.search", timeout: 10, "the search sheet")
        let field = app.searchFields.firstMatch
        if !field.exists(within: 10) { fail("the search field") }
        activate(field)
        // The field can take a stray key while the keyboard comes up (a run left "Ftone"): typed again until it holds
        // just the query.
        for _ in 0..<3 {
            field.typeText("tone")
            if (field.value as? String) == "tone" { break }
            let clear = field.buttons.firstMatch
            if clear.exists { clear.tap() }
        }
        XCTAssertEqual(field.value as? String, "tone", "the search field holds the query")
        let result = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'livetv.search.program.'")).firstMatch
        if !result.exists(within: 15) { fail("a program found") }
        // More results fill in after the first: the list settles before the shot.
        Thread.sleep(forTimeInterval: 1)
        shot("livetv search tone")
        #endif
    }

    /// Two channels made favourites, the favourites filter on, Reorder favorites: the first moved below the second
    /// (the remote picks it up and moves it on Apple TV, the list's reorder control or a drag elsewhere); the guide and
    /// the reopened sheet keep the new order; both removed in the sheet, which closes with the last, then all channels
    /// shown again.
    func testReorderFavorites() throws {
        let api = try JellyfinApi(server: Self.server)
        let favoritesBefore = try api.favoriteChannels()
        addTeardownBlock {
            XCTAssertNoThrow(try api.favoriteChannels().subtracting(favoritesBefore).forEach { try api.setFavorite($0, false) }, "the favourites taken off")
        }
        openGuide()
        let first = element("livetv.guide.channel.0")
        let second = element("livetv.guide.channel.1")
        let names = (first.label, second.label)
        XCTAssertNotEqual(names.0, names.1, "two channels")

        // Each channel's context menu makes it a favourite.
        let starred = NSPredicate(format: "value == %@", "Favorites")
        for (index, channel) in [first, second].enumerated() {
            #if os(tvOS)
            focus(channel, pressing: index == 0 ? .left : .down, limit: 3, "channel \(index)")
            #endif
            toggleFavorite(channel)
            if XCTWaiter.wait(for: [expectation(for: starred, evaluatedWith: channel)], timeout: 10) != .completed {
                fail("channel \(index) made a favourite")
            }
        }

        // The favourites filter on: Reorder favorites shows beside its star.
        let filter = element("livetv.action.favorites")
        _ = waitUntil(5) { filter.isHittable }
        focusHeader(filter, "the favourites filter")
        activate(filter)
        let reorder = require("livetv.action.reorder", timeout: 10, "Reorder favorites with the filter on")
        _ = waitUntil(5) { !self.element("livetv.guide.channel.2").exists && self.element("livetv.guide.channel.0").label == names.0 }
        shot("livetv favorites filter")
        XCTAssertEqual(element("livetv.guide.channel.0").label, names.0, "the first favourite first")
        XCTAssertFalse(element("livetv.guide.channel.2").exists, "only the favourites in the guide")

        openReorder(reorder)
        let row0 = require("livetv.reorder.row.0", timeout: 10, "the first favourite's row")
        let row1 = require("livetv.reorder.row.1", timeout: 5, "the second favourite's row")
        if !(shows(row0, names.0) && shows(row1, names.1)) { fail("the favourites in their order: \(row0.debugDescription)") }
        shot("livetv reorder favorites")
        #if os(tvOS)
        // Select picks the first row up, Down moves it, Select puts it down.
        focus(row0, pressing: .up, "the first row")
        XCUIRemote.shared.press(.select)
        // The row's pick-up animation: nothing signals it.
        Thread.sleep(forTimeInterval: 1)
        shot("livetv reorder picked up")
        XCUIRemote.shared.press(.down)
        // A gap between the presses so the focus engine takes both.
        Thread.sleep(forTimeInterval: 1)
        XCUIRemote.shared.press(.select)
        #elseif os(macOS)
        // The row dragged, slowly, held over the lower half of the second row until it moves.
        row0.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.5))
            .click(forDuration: 0.6, thenDragTo: row1.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.9)), withVelocity: .slow, thenHoldForDuration: 1)
        #else
        // By the list's reorder control at the row's trailing end, held over the lower half of the second row.
        let cell0 = app.cells.containing(.any, identifier: "livetv.reorder.row.0").firstMatch
        let cell1 = app.cells.containing(.any, identifier: "livetv.reorder.row.1").firstMatch
        cell0.coordinate(withNormalizedOffset: CGVector(dx: 0.96, dy: 0.5))
            .press(forDuration: 0.6, thenDragTo: cell1.coordinate(withNormalizedOffset: CGVector(dx: 0.96, dy: 0.9)), withVelocity: .slow, thenHoldForDuration: 1)
        #endif
        _ = waitUntil(10) { shows(element("livetv.reorder.row.0"), names.1) }
        if !shows(element("livetv.reorder.row.0"), names.1) { fail("the second favourite moved first") }
        XCTAssertTrue(shows(element("livetv.reorder.row.1"), names.0), "the first favourite second")
        // The rows' move animation.
        Thread.sleep(forTimeInterval: 1)
        shot("livetv reorder moved")

        // Closed, the guide lists the favourites in the new order; reopened, so does the sheet.
        closeSheet("livetv.reorder.close")
        XCTAssertTrue(element("livetv.reorder").waitForNonExistence(timeout: 10), "the reorder sheet closes")
        let guideFirst = NSPredicate(format: "label == %@", names.1)
        XCTAssertEqual(XCTWaiter.wait(for: [expectation(for: guideFirst, evaluatedWith: element("livetv.guide.channel.0"))], timeout: 10), .completed, "the guide in the new order")
        shot("livetv guide reordered")
        openReorder(reorder)
        XCTAssertTrue(shows(require("livetv.reorder.row.0", timeout: 10, "the reopened sheet"), names.1), "the new order kept")
        shot("livetv reorder reopened")

        // Remove takes a favourite off (on Apple TV the row's context menu, Select held); the last one removed closes
        // the sheet.
        removeFavorite(0)
        XCTAssertTrue(element("livetv.reorder.row.1").waitForNonExistence(timeout: 10), "one favourite left")
        XCTAssertTrue(shows(element("livetv.reorder.row.0"), names.0), "the other favourite left")
        shot("livetv reorder removed one")
        removeFavorite(0)
        XCTAssertTrue(element("livetv.reorder").waitForNonExistence(timeout: 10), "the sheet closes with the last favourite")
        let showAll = require("livetv.favorites.showAll", timeout: 10, "no favourites left")
        shot("livetv no favorites")
        XCTAssertTrue(try api.favoriteChannels().subtracting(favoritesBefore).isEmpty, "the server's favourites removed")
        #if os(tvOS)
        focus(showAll, pressing: .down, "Show all channels")
        #endif
        activate(showAll)
        require("livetv.guide.channel.2", timeout: 10, "every channel again")
    }

    /// A series rule recorded from a show's schedule (Record show → Record series, at its time of day only), then in the
    /// Recordings tab: Edit changes a setting and saves ("Recording rule updated", the server's rule changed), Delete
    /// asks and removes it ("Recording rule deleted", gone from the server). The show is one not on now, so that the
    /// rule starts no recording, and one no rule records yet, so that Recordings lists its rule alone under its title.
    func testEditRule() throws {
        let api = try JellyfinApi(server: Self.server)
        let before = try api.seriesTimers()
        let rulesBefore = before.map(\.id)
        let show = try api.seriesNotAiringNow(excluding: Set(before.map(\.name)))
        let added: @Sendable () throws -> [JellyfinApi.SeriesTimer] = {
            try api.seriesTimers().filter { !rulesBefore.contains($0.id) && $0.name == show }
        }
        addTeardownBlock {
            XCTAssertNoThrow(try added().forEach { try api.deleteSeriesTimer($0.id) }, "the rule deleted")
            XCTAssertEqual(try added().count, 0, "no rule left on the server")
        }
        launchDev(arguments: ["--dev-server", Self.server, "--dev-open", "live_tv", "--dev-open-show-schedule", show])
        let record = require("livetv.schedule.record", timeout: 90, "Record show in the schedule of \(show)")
        // The airings come in and take focus.
        require("livetv.schedule.row.0", timeout: 30, "the schedule's airings")
        // Their focus lands with no signal across platforms; Record show is reached after it.
        Thread.sleep(forTimeInterval: 2.5)
        #if os(tvOS)
        focus(record, pressing: .up, "Record show")
        #endif
        activate(record)
        require("livetv.record.save", timeout: 15, "the Record Options sheet")
        let series = require("livetv.record.entry.1", timeout: 10, "the Record series entry")
        #if os(tvOS)
        focus(series, pressing: .down, "Record series")
        #endif
        activate(series)
        _ = waitUntil(5) {
            self.element("livetv.record.setting.RecordNewOnly").exists || self.element("livetv.record.setting.RecordAnyTime").exists
        }
        // At its time of day only: a handful of scheduled airings above the rule in Recordings, not one per airing.
        let anyTime = element("livetv.record.setting.RecordAnyTime")
        #if os(tvOS)
        // Down through the settings, which scroll it into view.
        focus(anyTime, pressing: .down, limit: 15, "Record at any time")
        #else
        // Further down the settings, scrolled into view a few rows at a time, so that on a short screen (the iPhone
        // Duo's cover, whose sheet opens at half height and lists none of the rows below yet) the row isn't passed.
        // Dragged at the form's left edge, clear of its switches and fields.
        for _ in 0..<8 where !(anyTime.exists && anyTime.isHittable) {
            #if os(macOS)
            let newOnlyRow = element("livetv.record.setting.RecordNewOnly")
            guard newOnlyRow.exists else { break }
            newOnlyRow.scroll(byDeltaX: 0, deltaY: -300)
            #else
            let visible = element("livetv.record").frame.intersection(app.windows.firstMatch.frame)
            let start = app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: visible.minX + 30, dy: visible.maxY - 40))
            start.press(forDuration: 0.05, thenDragTo: start.withOffset(CGVector(dx: 0, dy: -min(150, visible.height / 2))))
            #endif
            _ = waitUntil(0.5) { anyTime.exists && anyTime.isHittable }
        }
        if !anyTime.exists { fail("the rule's Record at any time") }
        #endif
        activate(anyTime)
        // The switch's animation.
        Thread.sleep(forTimeInterval: 1)
        shot("livetv record series")
        saveRecordOptions()
        _ = waitUntil(20, every: 1) { (try? added().first) != nil }
        guard let rule = try added().first else { return fail("no series rule on the server") }
        XCTAssertEqual(rule.name, show, "the rule records the show")

        // Back to Live TV, its Recordings tab: the rule.
        goBack()
        let tab = require("livetv.tab.recordings", timeout: 15, "the Live TV screen under the schedule")
        #if os(tvOS)
        focusHeader(tab, "the Recordings chip")
        #endif
        activate(tab)
        // The show's rule (the server may hold others), once the reload the tab starts as it's selected brings it.
        guard let ruleRow = recordingRule(show) else { return fail("the rule of \(show) in Recordings") }
        // The list's scroll to the row settles before the shot.
        Thread.sleep(forTimeInterval: 1)
        shot("livetv recordings rule")

        // Edit: Record new only flipped and saved.
        openRuleMenu(ruleRow)
        let edit = entry("livetv.recordings.ruleMenu.0", "Edit")
        shot("livetv rule menu")
        #if os(tvOS)
        if !edit.hasFocus { focus(edit, pressing: .up, limit: 3, "the rule's Edit") }
        #endif
        activate(edit)
        require("livetv.record.save", timeout: 15, "the Edit rule sheet")
        let newOnly = require("livetv.record.setting.RecordNewOnly", timeout: 10, "the rule's Record new only")
        #if os(tvOS)
        focus(newOnly, pressing: .down, "Record new only")
        #endif
        activate(newOnly)
        // The switch's animation.
        Thread.sleep(forTimeInterval: 1)
        shot("livetv edit rule")
        saveRecordOptions()
        waitForMessage("Recording rule updated")
        shot("livetv rule updated")
        let edited = try api.seriesTimers().first { $0.id == rule.id }
        XCTAssertEqual(edited?.recordNewOnly, !rule.recordNewOnly, "the server's rule changed")

        // Delete: confirmed, the rule goes.
        guard let deleteRow = recordingRule(show) else { return fail("the edited rule of \(show) in Recordings") }
        openRuleMenu(deleteRow)
        let delete = entry("livetv.recordings.ruleMenu.1", "Delete")
        #if os(tvOS)
        focus(delete, pressing: .down, "the rule's Delete")
        #endif
        activate(delete)
        let confirm = entry("livetv.confirm", "Delete rule")
        if !confirm.exists(within: 10) { fail("the delete confirmation") }
        shot("livetv delete rule confirm")
        #if os(tvOS)
        // The dialog's buttons side by side, Cancel focused first; the focus is on the button around the identified one.
        let focusable = app.buttons.matching(NSPredicate(format: "label == %@", "Delete rule")).firstMatch
        focus(focusable, pressing: .right, limit: 3, "the confirmation's Delete")
        #endif
        activate(confirm)
        waitForMessage("Recording rule deleted")
        shot("livetv rule deleted")
        let left = try api.seriesTimers().map(\.id)
        XCTAssertFalse(left.contains(rule.id), "the server's rule deleted")
    }

    /// A show's schedule (`--dev-open-show-schedule`, a series on now): its title and airings, Record show reached and
    /// its sheet cancelled, a later airing's details, the airing on now tuned into the player, then Back to Live TV.
    func testShowSchedule() throws {
        let show = try JellyfinApi(server: Self.server).seriesAiringNow()
        launchDev(arguments: ["--dev-server", Self.server, "--dev-open", "live_tv", "--dev-open-show-schedule", show])
        require("livetv.schedule.row.0", timeout: 90, "the schedule's airings of \(show)")
        XCTAssertTrue(app.staticTexts[show].exists, "the show's title")
        let onNow = NSPredicate(format: "identifier BEGINSWITH 'livetv.schedule.row.' AND label CONTAINS 'min left'")
        _ = app.descendants(matching: .any).matching(onNow).firstMatch.exists(within: 5)
        shot("livetv show schedule")
        let rows = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'livetv.schedule.row.'"))
        let labels = (0..<rows.count).map { element("livetv.schedule.row.\($0)").label }
        guard let live = labels.firstIndex(where: { $0.contains("min left") }) else { return fail("an airing on now in \(labels)") }
        guard let later = labels.indices.first(where: { $0 > live }) else { return fail("a later airing in \(labels)") }

        // Record show opens the Record Options sheet; Cancel closes it.
        let record = require("livetv.schedule.record", timeout: 5, "Record show")
        #if os(tvOS)
        focus(record, pressing: .up, "Record show")
        shot("livetv schedule record focused")
        #endif
        activate(record)
        let sheet = require("livetv.record.save", timeout: 15, "the Record Options sheet")
        // The sheet's presentation animation.
        Thread.sleep(forTimeInterval: 1)
        shot("livetv schedule record options")
        #if os(tvOS)
        XCUIRemote.shared.press(.menu)
        #else
        activate(element("livetv.record.cancel"))
        #endif
        XCTAssertTrue(sheet.waitForNonExistence(timeout: 10), "the sheet cancelled")

        // A later airing opens its details.
        let laterRow = element("livetv.schedule.row.\(later)")
        #if os(tvOS)
        focus(laterRow, pressing: .down, "the later airing")
        #endif
        activate(laterRow)
        let details = require("livetv.details", timeout: 10, "the later airing's details")
        // The sheet's presentation animation.
        Thread.sleep(forTimeInterval: 1)
        shot("livetv schedule details")
        closeSheet("livetv.details.close")
        XCTAssertTrue(details.waitForNonExistence(timeout: 10), "the details close")

        // The airing on now tunes its channel.
        let liveRow = element("livetv.schedule.row.\(live)")
        #if os(tvOS)
        focus(liveRow, pressing: .up, "the airing on now")
        #endif
        activate(liveRow)
        require("player.video", timeout: 30, "the player")
        // The video's first frames: nothing signals them.
        Thread.sleep(forTimeInterval: 5)
        shot("livetv schedule playing")
        closePlayer()
        require("livetv.schedule.row.0", timeout: 15, "the schedule again")

        // Back pops the schedule to Live TV.
        goBack()
        XCTAssertTrue(element("livetv.schedule").waitForNonExistence(timeout: 10), "the schedule pops")
        require("livetv.screen", timeout: 10, "Live TV under the schedule")
        shot("livetv schedule popped")
    }

    // MARK: Steps

    /// Presses or clicks `target`; on Apple TV Select on what has focus, which the test has put on `target`.
    private func activate(_ target: XCUIElement) {
        #if os(tvOS)
        XCUIRemote.shared.press(.select)
        #elseif os(macOS)
        target.click()
        #else
        target.tap()
        #endif
        // Lets the press land before the next one, which the focus engine would otherwise drop.
        Thread.sleep(forTimeInterval: 0.5)
    }

    #if os(tvOS)
    /// Presses `direction` until `target` has focus, at most `limit` times, `pause` seconds apart.
    private func focus(
        _ target: XCUIElement, pressing direction: XCUIRemote.Button, limit: Int = 8, pause: TimeInterval = 0.8, _ what: String
    ) {
        for _ in 0..<limit where !hasFocus(target) {
            XCUIRemote.shared.press(direction)
            _ = waitUntil(pause) { hasFocus(target) }
        }
        if !hasFocus(target) { fail("\(what) takes no focus") }
    }

    /// Whether `target` has focus, or the list row (cell) it sits in does, as a list's and a form's rows take it, or a
    /// view inside it does (a list row's menu, the system's element in a menu or a menu's entry).
    private func hasFocus(_ target: XCUIElement) -> Bool {
        guard target.exists else { return false }
        if target.hasFocus || LibrarySteps(test: self).inside(target) { return true }
        if target.descendants(matching: .any).matching(NSPredicate(format: "hasFocus == true")).firstMatch.exists { return true }
        let cell = app.cells.containing(.any, identifier: target.identifier).firstMatch
        return cell.exists && cell.hasFocus
    }
    #endif

    /// On Apple TV, focus on `target` in the header row (a tab chip, an action): up to the row, then along it, right
    /// first, then left.
    private func focusHeader(_ target: XCUIElement, _ what: String) {
        #if os(tvOS)
        let header = ["livetv.tab.guide", "livetv.tab.recordings", "livetv.action.search", "livetv.action.favorites", "livetv.action.refresh"]
            .map(element)
        for _ in 0..<5 where !header.contains(where: hasFocus) {
            XCUIRemote.shared.press(.up)
            _ = waitUntil(0.8) { header.contains(where: hasFocus) }
        }
        for _ in 0..<6 where !hasFocus(target) {
            XCUIRemote.shared.press(.right)
            _ = waitUntil(0.8) { hasFocus(target) }
        }
        focus(target, pressing: .left, what)
        #endif
    }

    /// Removes the favourite at `index` in the reorder sheet: its remove button; on Apple TV the row's context menu.
    private func removeFavorite(_ index: Int) {
        #if os(tvOS)
        focus(element("livetv.reorder.row.\(index)"), pressing: .up, "the row \(index)")
        XCUIRemote.shared.press(.select, forDuration: 1.5)
        // The context menu opens with no signal on its Remove: the next Select would otherwise be dropped.
        Thread.sleep(forTimeInterval: 1)
        XCUIRemote.shared.press(.select)
        #else
        activate(element("livetv.reorder.remove.\(index)"))
        #endif
    }

    /// An entry of a menu or a dialog: by its identifier, else (where the system's menus and dialogs drop it) by its
    /// label.
    private func entry(_ id: String, _ label: String) -> XCUIElement {
        let byId = element(id)
        if byId.exists(within: 3) { return byId }
        #if os(macOS)
        let item = app.menuItems[label].firstMatch
        if item.exists { return item }
        #endif
        let menuButton = app.collectionViews.buttons[label].firstMatch
        if menuButton.exists { return menuButton }
        return app.buttons.matching(NSPredicate(format: "label == %@", label)).allElementsBoundByIndex.last ?? byId
    }

    /// The channel `channel` added to the favourites or taken off through its context menu's Favorite (after Watch
    /// Channel); on Apple TV it has focus.
    private func toggleFavorite(_ channel: XCUIElement) {
        #if os(tvOS)
        XCUIRemote.shared.press(.select, forDuration: 1.5)
        _ = waitUntil(5) { self.element("livetv.guide.favorite").exists || self.app.buttons["Favorite"].exists }
        focus(entry("livetv.guide.favorite", "Favorite"), pressing: .down, "the menu's Favorite")
        XCUIRemote.shared.press(.select)
        #elseif os(macOS)
        channel.rightClick()
        entry("livetv.guide.favorite", "Favorite").click()
        #else
        channel.press(forDuration: 1.2)
        entry("livetv.guide.favorite", "Favorite").tap()
        #endif
    }

    /// Closes the sheet up: the remote's Menu, Escape on the Mac, its Close where it has one on touch, else a tap above
    /// it (a resizable sheet has no Close).
    private func closeSheet(_ closeId: String) {
        #if os(tvOS)
        XCUIRemote.shared.press(.menu)
        #elseif os(macOS)
        app.typeKey(.escape, modifierFlags: [])
        #else
        let close = element(closeId)
        if close.exists && close.isHittable {
            close.tap()
        } else {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.08)).tap()
        }
        #endif
    }

    /// Back: the remote's Menu, the window's back button on the Mac, the navigation bar's back button on touch.
    private func goBack() {
        #if os(tvOS)
        XCUIRemote.shared.press(.menu)
        #elseif os(macOS)
        app.buttons.matching(identifier: "chevron.backward").firstMatch.click()
        #else
        backButton.tap()
        #endif
    }

    /// The reorder favourites sheet from its action (`reorder`).
    private func openReorder(_ reorder: XCUIElement) {
        focusHeader(reorder, "Reorder favorites")
        activate(reorder)
        require("livetv.reorder", timeout: 10, "the reorder favourites sheet")
    }

    /// The Edit / Delete menu of the recording rule `row`.
    private func openRuleMenu(_ row: XCUIElement) {
        #if os(tvOS)
        // Down past the scheduled recordings, other rules' included.
        focus(row, pressing: .down, limit: 30, pause: 0.5, "the rule")
        #endif
        activate(row)
        _ = waitUntil(5) { self.element("livetv.recordings.ruleMenu.0").exists || self.app.buttons["Edit"].exists }
    }

    /// The Recordings tab's row of the rule recording `name`, once the tab shows it: selecting the tab reloads it, over
    /// the lists it loaded before, without a rule made since. Under the scheduled recordings, the row may be past the
    /// list's end: it scrolls into view (Apple TV's focus moves to it, `openRuleMenu`).
    private func recordingRule(_ name: String) -> XCUIElement? {
        let rows = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'livetv.recordings.rule.'"))
        let named = [
            // The Mac reports the row's lines as menu buttons titled with them.
            rows.matching(NSPredicate(format: "label CONTAINS %@ OR title CONTAINS %@", name, name)).firstMatch,
            rows.containing(NSPredicate(format: "label == %@", name)).firstMatch,
        ]
        let list = element("livetv.recordings")
        for _ in 0..<20 {
            if let row = named.first(where: \.exists) {
                #if os(tvOS)
                return row
                #else
                if row.isHittable { return row }
                #endif
            }
            #if os(iOS)
            if list.exists { list.swipeUp() }
            #elseif os(macOS)
            if list.exists { list.scroll(byDeltaX: 0, deltaY: -300) }
            #endif
            _ = waitUntil(1) { named.contains { $0.exists && $0.isHittable } }
        }
        return nil
    }

    /// Record (or Save) in the Record Options sheet; the sheet closes.
    private func saveRecordOptions() {
        let save = element("livetv.record.save")
        #if os(tvOS)
        focus(save, pressing: .down, limit: 20, "the sheet's save")
        #endif
        activate(save)
        XCTAssertTrue(save.waitForNonExistence(timeout: 15), "the sheet closes on save")
    }

    /// Whether the row `row` (a favourite, a rule) names `name`.
    private func shows(_ row: XCUIElement, _ name: String) -> Bool {
        // The Mac reports a dragged row as text whose value is what it says.
        [row.label, row.title, row.value as? String ?? ""].contains { $0.contains(name) } || row.staticTexts[name].exists
    }

    /// Waits for the snackbar to have said `text` (the app's announcements: the snackbar announces what it shows).
    private func waitForMessage(_ text: String) {
        let said = NSPredicate(format: "label CONTAINS %@", text)
        if XCTWaiter.wait(for: [expectation(for: said, evaluatedWith: element("app.announcements"))], timeout: 15) != .completed {
            fail("the message \"\(text)\"")
        }
    }

    /// Out of the player: the remote's Menu, Escape on the Mac, its close button on touch.
    private func closePlayer() {
        #if os(tvOS)
        XCUIRemote.shared.press(.menu)
        _ = element("player.video").waitForNonExistence(timeout: 2)
        if element("player.video").exists { XCUIRemote.shared.press(.menu) }
        #elseif os(macOS)
        app.typeKey(.escape, modifierFlags: [])
        Thread.sleep(forTimeInterval: 1)
        if element("player.video").exists { app.typeKey(.escape, modifierFlags: []) }
        #else
        let close = element("player.back")
        if !close.exists { app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap() }
        if close.exists(within: 5) { close.tap() }
        #endif
        XCTAssertTrue(element("player.video").waitForNonExistence(timeout: 15), "the player closes")
    }
}

/// The test server's Jellyfin API, signed in as the tests' account: what the tests set up there and take away again.
private struct JellyfinApi: Sendable {
    struct SeriesTimer {
        let id: String
        let name: String
        let recordNewOnly: Bool
    }

    struct Failure: Error, CustomStringConvertible {
        let description: String
    }

    private let url: String
    private let token: String
    private let userId: String

    /// `server`: `jellyfin=<user>:<password>@<url>`.
    init(server: String) throws {
        let value = server.drop { $0 != "=" }.dropFirst()
        guard let at = value.range(of: "@http") else { throw Failure(description: "no url in \(server)") }
        let account = value[..<at.lowerBound].split(separator: ":", maxSplits: 1).map(String.init)
        guard account.count == 2 else { throw Failure(description: "no account in \(server)") }
        let url = String(value[value.index(after: at.lowerBound)...])
        let auth = try Self.call(url, nil, "POST", "/Users/AuthenticateByName", body: ["Username": account[0], "Pw": account[1]])
        guard let token = auth?["AccessToken"] as? String, let user = auth?["User"] as? [String: Any], let id = user["Id"] as? String else {
            throw Failure(description: "no sign-in to \(url)")
        }
        self.url = url
        self.token = token
        userId = id
    }

    /// The ids of the channels that are the account's favourites.
    func favoriteChannels() throws -> Set<String> {
        let items = try call("GET", "/LiveTv/Channels?UserId=\(userId)")?["Items"] as? [[String: Any]] ?? []
        return Set(items.compactMap { item in
            (item["UserData"] as? [String: Any])?["IsFavorite"] as? Bool == true ? item["Id"] as? String : nil
        })
    }

    func setFavorite(_ id: String, _ favorite: Bool) throws {
        _ = try call(favorite ? "POST" : "DELETE", "/UserFavoriteItems/\(id)?userId=\(userId)")
    }

    /// The title of a series on now (the guide's series air again later).
    func seriesAiringNow() throws -> String {
        guard let name = try seriesNames(airing: true).min() else { throw Failure(description: "no series on now") }
        return name
    }

    /// The title of a series on later but not now, none of `excluding`.
    func seriesNotAiringNow(excluding: Set<String>) throws -> String {
        let later = try seriesNames(airing: false).subtracting(seriesNames(airing: true)).subtracting(excluding)
        guard let name = later.max() else { throw Failure(description: "no series on later but not now, none of \(excluding)") }
        return name
    }

    /// The titles of the series on now (`airing`), else of those still to end.
    private func seriesNames(airing: Bool) throws -> Set<String> {
        let filter = airing ? "IsAiring=true" : "HasAired=false"
        let items = try call("GET", "/LiveTv/Programs?UserId=\(userId)&\(filter)&IsSeries=true")?["Items"] as? [[String: Any]] ?? []
        return Set(items.compactMap { $0["Name"] as? String })
    }

    func seriesTimers() throws -> [SeriesTimer] {
        let items = try call("GET", "/LiveTv/SeriesTimers")?["Items"] as? [[String: Any]] ?? []
        return items.compactMap { item in
            guard let id = item["Id"] as? String else { return nil }
            return SeriesTimer(id: id, name: item["Name"] as? String ?? "", recordNewOnly: item["RecordNewOnly"] as? Bool ?? false)
        }
    }

    func deleteSeriesTimer(_ id: String) throws {
        _ = try call("DELETE", "/LiveTv/SeriesTimers/\(id)")
    }

    private func call(_ method: String, _ path: String) throws -> [String: Any]? {
        try Self.call(url, token, method, path, body: nil)
    }

    private static let deviceId = "plezy-ui-tests-\(UUID().uuidString)"

    /// One request, waited for: the tests' steps are synchronous.
    private static func call(_ url: String, _ token: String?, _ method: String, _ path: String, body: [String: String]?) throws -> [String: Any]? {
        guard let endpoint = URL(string: url + path) else { throw Failure(description: "bad url \(url + path)") }
        var request = URLRequest(url: endpoint)
        request.httpMethod = method
        // A device of its own: the server ends a device's older session as it signs in again, and runs on other
        // devices sign in at the same time.
        var auth = #"MediaBrowser Client="PlezyUITests", Device="PlezyUITests", DeviceId="\#(deviceId)", Version="1""#
        if let token { auth += #", Token="\#(token)""# }
        request.setValue(auth, forHTTPHeaderField: "Authorization")
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        let reply = Reply()
        URLSession.shared.dataTask(with: request) { data, response, error in
            reply.finish(data, response, error)
        }.resume()
        reply.done.wait()
        if let error = reply.error { throw error }
        let data = reply.data ?? Data()
        let response = reply.response
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else { throw Failure(description: "\(method) \(path): \(status)") }
        return data.isEmpty ? nil : try JSONSerialization.jsonObject(with: data) as? [String: Any]
    }
}

/// A request's reply, handed from URLSession's queue to the test waiting on `done`.
private final class Reply: @unchecked Sendable {
    let done = DispatchSemaphore(value: 0)
    private(set) var data: Data?
    private(set) var response: URLResponse?
    private(set) var error: Error?

    func finish(_ data: Data?, _ response: URLResponse?, _ error: Error?) {
        self.data = data
        self.response = response
        self.error = error
        done.signal()
    }
}
