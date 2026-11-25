import XCTest
#if os(iOS)
import UIKit
#endif

/// Search and the screens it opens, against the development Jellyfin server (`--dev-server`, `PLEZY_DEV_SERVER` or the
/// default): a movie's title typed into Search lists it, its result opens its detail with its metadata line, scores,
/// download button, track status and overview (More opening the rest), its ⋯'s Rate opening the rating sheet, and (iOS)
/// its navigation bar steady as it scrolls past its hero title (no title there, no height change); a show's detail
/// lists its season chips and episodes and offers Shuffle; on Apple TV the hero follows the focused episode and opens
/// the details sheet;
/// a cast member opens the actor's screen; an album's result opens its music screen and a track's plays it; a query of
/// several kinds lists each under its kind's heading. Each screen
/// is kept as a screenshot.
final class DetailSearchTests: PlezyUITestCase {
    private static let movie = "Maestro Movie"
    private static let show = "Maestro Show"

    private static var server: String {
        let value = ProcessInfo.processInfo.environment["PLEZY_DEV_SERVER"] ?? ""
        guard value.isEmpty else { return value }
        #if os(macOS)
        // The Mac runs reach the test server through a loopback tunnel: the local network needs a prompt answered.
        return "jellyfin=maestro:maestro@http://127.0.0.1:28096"
        #else
        return "jellyfin=maestro:maestro@http://192.168.0.15:28096"
        #endif
    }

    func testMovieDetailFromSearch() {
        openDetail(of: Self.movie)
        require("detail.play", "the movie's Play")
        #if os(tvOS)
        require("detail.info", "the movie's information block")
        XCTAssertFalse(element("detail.download").exists, "Apple TV's detail has no download button")
        #else
        require("detail.overview", "the movie's overview")
        require("detail.facts", "the movie's metadata line")
        require("ratings.strip", timeout: 30, "the movie's scores")
        require("detail.download", "the movie's download button")
        #endif
        require("detail.tracks", timeout: 30, "the movie's track status")
        // Right under the action row it describes: at its leading edge (Play's, give or take Play's focus lift), or centred
        // under it where the page centres its details (phones, narrow windows).
        let play = element("detail.play").frame, tracks = element("detail.tracks").frame
        XCTAssertGreaterThanOrEqual(tracks.minY, play.maxY, "the track status sits under the action row")
        XCTAssertLessThanOrEqual(tracks.minY - play.maxY, 40, "the track status sits right under the action row")
        let row = element("detail.download").exists ? play.union(element("detail.download").frame) : play
        XCTAssertTrue(
            abs(tracks.minX - play.minX) <= 24 || abs(tracks.midX - row.midX) <= 60,
            "the track status starts at the action row's leading edge or is centred under it: \(tracks) under \(row)"
        )
        shot("movie detail")
        #if os(iOS)
        let barHeight = requireSteadyScroll(Self.movie, hero: element("detail.title"), anchor: element("detail.play"), "the movie's detail")
        shot("movie detail past title")
        #endif
        #if os(tvOS)
        requireFocus("detail.play", "Play has focus once the detail shows")
        press(.down)
        shot("movie detail down")
        #else
        tap(require("detail.more", "the movie's ⋯"))
        require("menu.fileinfo", "⋯ opens the movie's shared menu")
        // Settle: the menu finishes presenting before its screenshot.
        Thread.sleep(forTimeInterval: 1)
        shotOfMenu("movie more menu")
        tap(require("menu.rate", "the menu's Rate"))
        require("ratingSheet", "Rate's rating sheet")
        // Settle: the sheet finishes presenting before its screenshot.
        Thread.sleep(forTimeInterval: 1)
        shot("movie rating sheet")
        dismissSheet(element("ratingSheet"), close: "ratingSheet.close")
        if !waitUntil(5, { !element("ratingSheet").exists }) { fail("the rating sheet doesn't close") }
        let more = element("detail.overview.toggle")
        if more.exists {
            #if os(iOS)
            XCTAssertGreaterThanOrEqual(more.frame.height, 44, "More is a 44 pt target")
            #endif
            tap(more)
            // Settle: the overview finishes expanding before its screenshot.
            Thread.sleep(forTimeInterval: 1)
            shot("movie overview opened")
        }
        scrollDown()
        shot("movie detail scrolled")
        #if os(iOS)
        requireSteadyBar(Self.movie, height: barHeight, "the movie's detail scrolled")
        #endif
        #endif
    }

    func testShowDetailListsEpisodes() {
        openDetail(of: Self.show)
        require("detail.episodes", "the show's episodes")
        let episode = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'detail.episode.'")).firstMatch
        if !episode.exists(within: 30) { fail("the show's detail lists no episode") }
        require("detail.shuffle", "the show's Shuffle")
        shot("show detail")
        #if os(tvOS)
        moveFocus(ids: ["detail.more"], with: .right, "Right moves focus along the actions to ⋯")
        press(.select)
        require("menu.rate", "⋯ opens the show's shared menu")
        XCTAssertFalse(element("menu.shuffle_play").exists, "⋯ leaves out Shuffle Play: the row shows Shuffle")
        shot("show more menu")
        dismissMenu()
        requireFocus("detail.more", timeout: 5, "Focus comes back to ⋯ as the menu closes")
        // Its first entry (Play from Beginning, where the show resumes) has focus while the menu is open: each close
        // gives focus back to ⋯, never leaving it on an entry, while the detail's menu resolves again behind it.
        for round in 1...5 {
            press(.select)
            require("menu.rate", "⋯ opens the show's shared menu again (round \(round))")
            dismissMenu()
            requireFocus("detail.more", timeout: 5, "Focus comes back to ⋯ as the menu closes (round \(round))")
        }
        moveFocus(prefix: "detail.episode.", with: .down, "Down moves focus from the actions to the episodes")
        shot("show detail episodes")
        #else
        tap(require("detail.more", "the show's ⋯"))
        require("menu.rate", "⋯ opens the show's shared menu")
        XCTAssertFalse(element("menu.shuffle_play").exists, "⋯ leaves out Shuffle Play: the row shows Shuffle")
        #if os(iOS)
        require("menu.title", "the menu names the show it acts on")
        #endif
        // Settle: the menu finishes presenting before its screenshot.
        Thread.sleep(forTimeInterval: 1)
        shotOfMenu("show more menu")
        dismissMenu()
        require("detail.shuffle", "the show's Shuffle once ⋯'s menu closes")
        require("detail.season.0", "the show's season tabs")
        scrollDown()
        shot("show detail episodes")
        #endif
    }

    #if os(tvOS)
    /// The hero follows the focused episode and gives the show back once focus leaves the episodes; Up from the actions
    /// reaches the information block, whose Select opens the details sheet.
    func testTvHeroFollowsEpisodeAndOpensDetails() {
        openDetail(of: Self.show)
        let info = require("detail.info", "the show's information block")
        requireFocus("detail.play", "Play has focus once the detail shows")
        let showInfo = info.label
        moveFocus(prefix: "detail.episode.", with: .down, "Down moves focus from the actions to the episodes")
        let card = focused.label
        let title = card.split(separator: ".", maxSplits: 1).last.map { $0.trimmingCharacters(in: .whitespaces) } ?? card
        if !waitUntil(10, { info.label != showInfo && info.label.contains(title) }) {
            fail("the hero doesn't follow the focused episode \(card): it reads \(info.label)")
        }
        // Settle: the hero's artwork comes in before its screenshot.
        Thread.sleep(forTimeInterval: 2)
        shot("tv hero follows episode")
        // Up lands on the action row's button nearest above, not always Play (through the season tabs between).
        let actions = ["detail.play", "detail.versions", "detail.castTo", "detail.trailer", "detail.shuffle", "detail.watched", "detail.more"]
        moveFocus(ids: actions, with: .up, "Up moves focus from the episodes back to the actions")
        if !waitUntil(10, { info.label == showInfo }) { fail("the hero keeps the episode after focus left it: \(info.label)") }
        press(.up)
        // The block's focus doesn't show in XCUITest's hasFocus: its Select opening the sheet shows Up reached it.
        shot("tv hero information focused")
        press(.select)
        require("detail.infoPanel", "Select on the information block (Up from the actions) opens the details sheet")
        // Settle: the sheet finishes presenting before its screenshot.
        Thread.sleep(forTimeInterval: 1)
        shot("details sheet")
        press(.down)
        shot("details sheet down")
        press(.menu)
        if !waitUntil(5, { !element("detail.infoPanel").exists }) { fail("Menu doesn't close the details sheet") }
        // Focus is back on the information block: Select opens the sheet again. Paced: focus there doesn't show in
        // XCUITest, so nothing to wait on before Select.
        Thread.sleep(forTimeInterval: 1)
        press(.select)
        require("detail.infoPanel", "Focus comes back to the information block as the details sheet closes")
        press(.menu)
        if !waitUntil(5, { !element("detail.infoPanel").exists }) { fail("Menu doesn't close the details sheet again") }
    }
    #endif

    #if os(iOS)
    /// At accessibility text size L on iPhone, in portrait and landscape, a movie's detail ends clear of the floating
    /// tab bar, and in landscape its Play, scrolled clear of the bar, opens the player.
    func testLargeTextDetailClearsTheTabBar() throws {
        guard UIDevice.current.userInterfaceIdiom == .phone else { throw XCTSkip("iPhone's floating tab bar") }
        let title = "Subtitled Movie"
        launchDev(arguments: [
            "--dev-open", "search", "--dev-server", Self.server,
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityL",
        ])
        require("search.screen", timeout: 90, "the Search screen")
        pickResult(title)
        waitForDetail(of: title)
        let detail = element("detail.screen")
        do {
            try requireBottomTabBar()
        } catch {
            // Tabs along the side leave no foot to clear (the iPhone Duo): Play still opens the player at large text.
            tap(scrollClearOfTabBar(require("detail.play", "the movie's Play"), in: detail, "Play at large text"))
            require("player.video", timeout: 60, "Play opens the player at large text")
            throw error
        }
        for (orientation, name) in [(UIDeviceOrientation.portrait, "portrait"), (.landscapeLeft, "landscape")] {
            XCUIDevice.shared.orientation = orientation
            // Settle: the rotation and relayout finish before the screenshot.
            Thread.sleep(forTimeInterval: 2)
            shot("large text \(name) detail")
            requireEndClearsTabBar(detail, "\(title)'s detail in \(name) at large text")
            shot("large text \(name) detail end")
            for _ in 0..<6 { detail.swipeDown() }
        }
        let play = scrollClearOfTabBar(require("detail.play", "the movie's Play"), in: detail, "Play in landscape at large text")
        shot("large text landscape play")
        tap(play)
        require("player.video", timeout: 60, "Play opens the player in landscape at large text")
    }
    #endif

    /// The actor's screen shows their name and portrait whole: the header lies inside the window and below the
    /// navigation bar, whose title would otherwise take its room (Apple TV) or cover it.
    func testCastOpensActor() {
        openDetail(of: Self.movie)
        openActor()
        require("person.name", "the actor's name")
        // Settle: the portrait comes over the network before the screenshot.
        Thread.sleep(forTimeInterval: 3)
        shot("actor")
        let header = require("person.header", "the actor's header").frame
        let window = app.windows.firstMatch.frame
        XCTAssertTrue(window.contains(header), "the header \(header) inside the window \(window)")
        let bar = app.navigationBars.firstMatch
        if bar.exists {
            XCTAssertGreaterThanOrEqual(header.minY, bar.frame.maxY, "the header \(header) below the navigation bar \(bar.frame)")
        }
    }

    #if !os(tvOS)
    /// An actor's titles each open the shared item menu, as a collection's do (a long press, a right click); it closes
    /// back onto the actor's screen.
    func testActorTitleOpensItsMenu() {
        #if os(macOS)
        openDetailFromLibrary(of: Self.movie)
        #else
        openDetail(of: Self.movie)
        #endif
        openActor()
        let grid = require("grid.items", timeout: 30, "the actor's titles")
        let title = grid.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'card.'")).firstMatch
        if !title.exists(within: 10) { fail("the actor's grid lists no title") }
        for _ in 0..<4 where !title.isHittable {
            scrollDown()
        }
        #if os(macOS)
        title.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4)).rightClick()
        #else
        title.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4)).press(forDuration: 1.0)
        #endif
        let entry = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'menu.'")).firstMatch
        if !entry.exists(within: 10) { fail("the actor's title opens no item menu") }
        // Settle: the menu finishes presenting before its screenshot.
        Thread.sleep(forTimeInterval: 1)
        shot("actor title menu")
        dismissMenu()
        if !waitUntil(5, { !entry.exists }) { fail("the title's menu stays open") }
        require("person.screen", "the actor's screen once the menu closes")
    }

    /// A related title on a movie's detail (More Like This) opens the shared item menu (a long press, a right click),
    /// as Apple TV's held Select does; it closes back onto the detail.
    func testRelatedTitleOpensItsMenu() {
        #if os(macOS)
        openDetailFromLibrary(of: Self.movie)
        #else
        openDetail(of: Self.movie)
        #endif
        let related = require("detail.related", timeout: 30, "the movie's related titles")
        let title = related.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'card.'")).firstMatch
        if !title.exists(within: 10) { fail("the related shelf lists no title") }
        let window = app.windows.firstMatch
        for _ in 0..<8 where !(title.isHittable && window.frame.insetBy(dx: 0, dy: 40).contains(title.frame)) {
            #if os(macOS)
            window.coordinate(withNormalizedOffset: CGVector(dx: 0.6, dy: 0.5)).scroll(byDeltaX: 0, deltaY: -300)
            Thread.sleep(forTimeInterval: 1)
            #else
            scrollDown()
            #endif
        }
        #if os(macOS)
        title.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4)).rightClick()
        #else
        title.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4)).press(forDuration: 1.0)
        #endif
        let entry = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'menu.'")).firstMatch
        if !entry.exists(within: 10) { fail("the related title opens no item menu") }
        // Settle: the menu finishes presenting before its screenshot.
        Thread.sleep(forTimeInterval: 1)
        shot("related title menu")
        dismissMenu()
        if !waitUntil(5, { !entry.exists }) { fail("the related title's menu stays open") }
        require("detail.screen", "the movie's detail once the menu closes")
    }

    /// ⋯'s Delete on a movie's detail asks first, in the system's alert, once the server has said the item may be
    /// deleted (the busy sheet while it asks): Cancel keeps the movie, Delete deletes it and its detail leaves. The
    /// test's proxy answers the deletion itself, passing nothing on to the server.
    func testDetailDeleteAsksFirst() {
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
        proxy.respondNoContent(method: "DELETE", pathContaining: "/Items/")
        openDetail(of: Self.movie, server: proxy.server(for: Self.server))
        tap(require("detail.more", "the movie's ⋯"))
        tapSettled(require("menu.delete_media", "⋯'s Delete"))
        let ok = require("menu.confirm.ok", "Delete's confirmation")
        // Settle: the alert finishes presenting before its screenshot.
        Thread.sleep(forTimeInterval: 1)
        shot("delete confirmation")
        tap(require("menu.confirm.cancel", "the confirmation's Cancel"))
        if !waitUntil(5, { !ok.exists }) { fail("Cancel leaves the confirmation up") }
        XCTAssertTrue(element("detail.screen").exists, "Cancel keeps the movie's detail")
        XCTAssertFalse(proxy.log.contains("DELETE "), "Cancel deleted the movie")

        tap(require("detail.more", "the movie's ⋯ after Cancel"))
        tapSettled(require("menu.delete_media", "⋯'s Delete after Cancel"))
        tap(require("menu.confirm.ok", "Delete's confirmation, asked again"))
        if !waitUntil(20, { proxy.log.contains("DELETE /Items/") }) { fail("confirming sends no deletion") }
        if !element("detail.screen").waitForNonExistence(timeout: 20) { fail("the deleted movie's detail stays") }
        shot("after delete")
    }
    #endif

    /// The actor's screen shows its spinner alone until its titles are in (the test's proxy holds them), then
    /// the whole page at once, which stays where it first showed.
    func testActorShowsASpinnerUntilItsTitles() {
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
        openDetail(of: Self.movie, server: proxy.server(for: Self.server))
        // The actor's titles: the one request of the bare items path the screen makes.
        proxy.hold(path: "/Items")
        openActor()
        if proxy.heldPath(within: 30) == nil { fail("the actor's screen asked for no titles") }
        // Over a period: the spinner shows alone while the titles stay held.
        Thread.sleep(forTimeInterval: 2)
        shot("actor loading")
        require("person.loading", "the actor's spinner while the titles load")
        XCTAssertFalse(element("person.name").exists, "no page beside the spinner")
        proxy.release()
        let name = require("person.name", timeout: 30, "the actor's name once the titles are in")
        let shown = name.frame
        XCTAssertFalse(element("person.loading").exists, "the spinner gone with the page shown")
        // Over a period: the page stays where it first showed (checked below).
        Thread.sleep(forTimeInterval: 3)
        shot("actor loaded")
        XCTAssertEqual(name.frame, shown, "the page stays where it first showed")
    }

    /// A later page of the actor's titles that fails shows its error with Retry under the loaded cards, no
    /// blank cards waiting forever; Retry loads it. The test's proxy raises the first page's total, so a later page is
    /// asked for, and answers that later page 404 once.
    func testActorLaterPageErrorRetries() throws {
        #if os(tvOS)
        throw XCTSkip("Retry is reached by touch or click here")
        #else
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
        openDetail(of: Self.movie, server: proxy.server(for: Self.server))
        try proxy.rewriteJSON(#""TotalRecordCount":\d+"#, with: #""TotalRecordCount":40"#)
        // The first page (held, then let through) and the next one (404) are the bare items path's requests.
        proxy.hold(path: "/Items")
        proxy.respondNotFound(path: "/Items")
        openActor()
        if proxy.heldPath(within: 30) == nil { fail("the actor's screen asked for no titles") }
        proxy.release(path: "/Items")
        require("person.name", timeout: 30, "the actor's page")
        let retry = element("grid.retry")
        if !retry.exists(within: 30) { fail("the failed later page's Retry") }
        for _ in 0..<6 where !retry.isHittable {
            scrollDown()
        }
        // Settle: the scroll and the error row finish before the screenshot.
        Thread.sleep(forTimeInterval: 2)
        shot("actor later page failed")
        let cards = app.descendants(matching: .any).matching(identifier: "grid.items").firstMatch
        XCTAssertTrue(cards.exists, "the loaded cards stay above the error")
        proxy.clearRules()
        tap(retry)
        if !retry.waitForNonExistence(timeout: 30) { fail("Retry loaded the page") }
        // Settle: the loaded page's artwork before the screenshot.
        Thread.sleep(forTimeInterval: 2)
        shot("actor later page retried")
        XCTAssertTrue(cards.exists, "the cards still there")
        #endif
    }

    /// Search shows its spinner alone until its results are in; a detail opened from a result shows the result's
    /// title at once, with no spinner, while its item loads (the test's proxy holds both); off Apple TV the facts and
    /// the actions wait for the item, so nothing it brings moves the page.
    func testSearchShowsASpinnerUntilItsResultsAndADetailItsResultAtOnce() {
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
        launchDev(arguments: ["--dev-open", "search", "--dev-server", proxy.server(for: Self.server)])
        require("search.screen", timeout: 90, "the Search screen")
        // Paced: the screen's own startup requests go through before the proxy holds the items path.
        Thread.sleep(forTimeInterval: 3)
        // The search's results: the bare items path.
        proxy.hold(path: "/Items")
        pickResult(Self.movie, whileSearching: { [self] in
            if proxy.heldPath(within: 30) == nil { fail("Search asked for no results") }
            // Settle: the spinner shows before its screenshot.
            Thread.sleep(forTimeInterval: 2)
            shot("search loading")
            require("search.loading", "Search's spinner while its results load")
            proxy.release()
        }, beforeOpening: {
            // The item, its extras and its related titles: every path under an item once its result is picked.
            proxy.hold(everyPathContaining: "/Items/")
        })
        if proxy.heldPath(within: 30) == nil { fail("the detail asked for no item") }
        // Settle: the detail shows the result before its screenshot.
        Thread.sleep(forTimeInterval: 2)
        shot("detail while its item loads")
        #if os(tvOS)
        require("detail.info", "the result's information block while its item loads")
        #else
        require("detail.title", "the result's title while its item loads")
        XCTAssertFalse(element("detail.facts").exists, "the facts wait for the item")
        XCTAssertFalse(element("detail.play").exists, "the actions wait for the item")
        #endif
        XCTAssertFalse(element("detail.loading").exists, "no spinner: the result shows while its item loads")
        proxy.release()
        waitForDetail(of: Self.movie)
        shot("detail loaded")
    }

    /// Search's idle and empty states show their message alone under the magnifier.
    func testSearchStatesShowTheirMessageAlone() {
        launchDev(arguments: ["--dev-open", "search", "--dev-server", Self.server])
        require("search.screen", timeout: 90, "the Search screen")
        let prompt = require("search.prompt", timeout: 30, "Search's prompt")
        // Settle: the prompt finishes laying out before its screenshot.
        Thread.sleep(forTimeInterval: 2)
        shot("search idle")
        // A state's texts: on screen as text, or its label where it reads as one element.
        let shows = { [self] (state: XCUIElement, text: String) in app.staticTexts[text].exists || state.label.contains(text) }
        if !shows(prompt, "Enter a title, actor, or keyword") { fail("the prompt doesn't say Enter a title, actor, or keyword") }
        if shows(prompt, "Search your media") { fail("a title shows over the prompt's message") }
        type("zzqxvj")
        let empty = require("search.empty", timeout: 30, "no results for a term nothing matches")
        // Settle: the empty state finishes laying out before its screenshot.
        Thread.sleep(forTimeInterval: 1)
        shot("search empty")
        if !shows(empty, "No results found") { fail("the empty state doesn't say No results found") }
        if shows(empty, "Try a different search term") { fail("a second line shows under No results found") }
    }

    /// From the detail on screen, opens its first cast member's screen.
    private func openActor() {
        require("detail.cast", timeout: 30, "the movie's cast")
        #if os(tvOS)
        moveFocus(prefix: "detail.cast.", with: .down, "Down moves focus to the cast")
        press(.select)
        #else
        let member = element("detail.cast.0")
        if !member.exists(within: 10) { fail("the cast lists no one") }
        for _ in 0..<4 where !member.isHittable {
            scrollDown()
        }
        tap(member)
        #endif
        require("person.screen", "the actor's screen")
    }

    /// Back from a screen the detail pushed (the actor's) leaves that screen alone: the detail shows again and stays,
    /// no second pop takes it too.
    func testBackFromActorPopsOnlyTheActor() {
        testCastOpensActor()
        #if os(tvOS)
        press(.menu)
        #elseif os(macOS)
        app.typeKey(.escape, modifierFlags: [])
        #else
        let back = backButton
        if !back.exists(within: 5) { fail("the actor's screen shows no Back") }
        back.tap()
        #endif
        if !waitUntil(10, { !element("person.screen").exists }) { fail("Back leaves the actor's screen up") }
        require("detail.screen", timeout: 10, "Back from the actor shows the movie's detail")
        // A double pop would take the detail away a moment later.
        Thread.sleep(forTimeInterval: 3)
        XCTAssertTrue(element("detail.screen").exists, "the detail stays after Back: only the actor's screen popped")
        XCTAssertTrue(element("detail.play").exists, "the detail is the top screen, its Play there")
        shot("back from actor")
    }

    /// A movie's extras (Credits Movie has a trailer): the Extras shelf lists it; its menu (a long press, a right click,
    /// a held Select) is the shared media menu; selecting it plays it. On Apple TV focus moves down from the cast into
    /// the extras and back up.
    func testExtraOpensMenuAndPlays() {
        #if os(macOS)
        openDetailFromLibrary(of: "Credits Movie")
        #else
        openDetail(of: "Credits Movie")
        #endif
        let extras = require("detail.extras", timeout: 30, "the movie's Extras")
        let extra = extras.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'card.'")).firstMatch
        if !extra.exists(within: 10) { fail("the Extras shelf lists no extra") }
        #if os(tvOS)
        let focusedExtra = extras.descendants(matching: .any).matching(NSPredicate(format: "hasFocus == true")).firstMatch
        requireFocus("detail.play", "Play has focus once the detail shows")
        for _ in 0..<8 where !focusedExtra.exists { press(.down) }
        if !focusedExtra.exists { fail("Down doesn't move focus into the extras: focus is on \(focused.identifier)") }
        shot("tv extra focused")
        press(.up)
        if !waitUntil(5, { focused.exists && focused.identifier.hasPrefix("detail.cast.") }) {
            fail("Up from the extras doesn't move focus back to the cast: focus is on \(focused.exists ? focused.identifier : "nothing")")
        }
        press(.down)
        if !focusedExtra.exists { fail("Down from the cast doesn't move focus back into the extras") }
        XCUIRemote.shared.press(.select, forDuration: 1.2)
        #else
        // The Mac reports a card below the window hittable: its frame inside the window counts too. Its scroll goes to
        // a point over the page, which the window's own scroll misses.
        let window = app.windows.firstMatch
        for _ in 0..<6 where !(extra.isHittable && window.frame.contains(extra.frame)) {
            #if os(macOS)
            window.coordinate(withNormalizedOffset: CGVector(dx: 0.6, dy: 0.5)).scroll(byDeltaX: 0, deltaY: -300)
            Thread.sleep(forTimeInterval: 1)
            #else
            scrollDown()
            #endif
        }
        #if os(macOS)
        extra.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4)).rightClick()
        #else
        extra.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4)).press(forDuration: 1.0)
        #endif
        #endif
        let entry = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'menu.'")).firstMatch
        if !entry.exists(within: 10) { fail("the extra's menu doesn't open the shared media menu") }
        // Settle: the menu finishes presenting before its screenshot.
        Thread.sleep(forTimeInterval: 1)
        shot("extra menu")
        dismissMenu()
        if !waitUntil(5, { !entry.exists }) { fail("the extra's menu stays open") }
        #if os(tvOS)
        if !focusedExtra.exists(within: 5) { fail("focus doesn't come back to the extra as its menu closes") }
        press(.select)
        #elseif os(macOS)
        // The card's own frame: the right-click catcher over it hides its activation point.
        extra.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4)).click()
        #else
        tap(extra)
        #endif
        require("player.video", timeout: 90, "selecting the extra plays it")
        // Settle: the video's first frames before the screenshot.
        Thread.sleep(forTimeInterval: 2)
        shot("extra playing")
    }

    #if os(iOS)
    /// An episode's menu opens over the action row on iPhone (the second episode's Edit... over Play): the entry runs
    /// where it covers the row's glass, which doesn't take the tap while a menu is open (`OpenItemMenu`). iPad shows the
    /// episodes in a column beside the row, under no menu.
    func testEpisodeMenuEntryOverTheActionRowRuns() throws {
        openDetail(of: Self.show)
        let episodes = NSPredicate(format: "identifier BEGINSWITH 'detail.episode.' AND NOT identifier ENDSWITH '.menu'")
        if !app.descendants(matching: .any).matching(episodes).firstMatch.exists(within: 30) { fail("the show lists no episode") }
        let row = ["detail.play", "detail.versions", "detail.trailer", "detail.shuffle", "detail.download", "detail.watched", "detail.watchlist", "detail.more"]
        guard let entry = menuEntryOverGlass(row, pressing: episodes) else {
            if UIDevice.current.userInterfaceIdiom == .pad { throw XCTSkip("no episode's menu opens over the action row") }
            return fail("no episode's menu opens over the action row")
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
    /// A season chip's menu on Apple TV (Select held): the season's watched mark and its delete, no download (Apple TV
    /// has none).
    func testTvSeasonChipMenu() {
        openDetail(of: Self.show)
        requireFocus("detail.play", "Play has focus once the detail shows")
        moveFocus(prefix: "detail.season.", with: .down, "Down moves focus from the actions to the season chips")
        XCUIRemote.shared.press(.select, forDuration: 1.2)
        let watched = app.descendants(matching: .any).matching(NSPredicate(format: "identifier IN {'menu.watch', 'menu.unwatch'}")).firstMatch
        if !watched.exists(within: 10) { fail("a held season chip opens no menu with the season's watched mark") }
        require("menu.delete_media", "the season's menu offers its delete")
        XCTAssertFalse(element("menu.download").exists, "Apple TV's season menu offers no download")
        shot("tv season menu")
        press(.menu)
    }
    #endif

    /// Two Versions: Play's chevron opens the system's menu of the versions, the one Play plays checked, then the
    /// qualities; the shared menu leaves Play Version out (the row's chevron stands for it), and its Add to… is a submenu
    /// of Playlist and Collection. Closing each picks nothing; on Apple TV focus comes back to what opened it.
    func testVersionAndAddToMenus() {
        openDetail(of: "Two Versions")
        #if os(tvOS)
        let steps = LibrarySteps(test: self)
        requireFocus("detail.play", "Play has focus once the detail shows")
        moveFocus(ids: ["detail.versions"], with: .right, limit: 2, "Right moves focus from Play to its versions")
        press(.select)
        #else
        tap(require("detail.versions", "Play's chevron"))
        #endif
        let second = require("detail.version.1", timeout: 10, "the versions list the second")
        // Settle: the menu finishes presenting before its screenshot.
        Thread.sleep(forTimeInterval: 1)
        shotOfMenu("version menu")
        XCTAssertTrue(checked(element("detail.version.0")), "the version Play plays is checked")
        XCTAssertFalse(checked(second), "the other version isn't checked")
        let qualityMenu = require("detail.quality", "the versions' menu offers Quality")
        #if os(tvOS)
        steps.tvSelect(qualityMenu)
        #else
        tap(qualityMenu)
        #endif
        let original = submenuEntry("detail.quality.0", label: "label BEGINSWITH 'Original'", "Quality's submenu lists the original first")
        // Settle: the submenu finishes presenting before its screenshot.
        Thread.sleep(forTimeInterval: 1)
        shotOfMenu("quality menu")
        XCTAssertTrue(checked(original), "the quality Play plays at (the original by default) is checked")
        dismissMenu()
        #if os(tvOS)
        dismissMenu()
        #endif
        if !waitUntil(5, { !second.exists }) { fail("the versions' menu stays open") }
        #if os(tvOS)
        requireFocus("detail.versions", timeout: 5, "focus comes back to the versions as they close")
        moveFocus(ids: ["detail.more"], with: .right, "Right reaches ⋯")
        press(.select)
        let addTo = require("menu.add_to", timeout: 10, "the shared menu's Add to…")
        XCTAssertFalse(element("menu.play_version").exists, "⋯ leaves out Play Version: the row's chevron offers it")
        steps.tvSelect(addTo)
        #else
        tap(require("detail.more", "the movie's ⋯"))
        let addTo = require("menu.add_to", timeout: 10, "the shared menu's Add to…")
        XCTAssertFalse(element("menu.play_version").exists, "⋯ leaves out Play Version: the row's chevron offers it")
        tap(addTo)
        #if os(macOS)
        // A Mac's submenu shows while the pointer rests on its entry.
        addTo.hover()
        #endif
        #endif
        submenuEntry("menu.add_to_playlist", label: "label == 'Playlist'", "Add to… opens its submenu with Playlist")
        submenuEntry("menu.add_to_collection", label: "label == 'Collection'", "Add to…'s submenu offers Collection")
        // Settle: the submenu finishes presenting before its screenshot.
        Thread.sleep(forTimeInterval: 1)
        shotOfMenu("add to submenu")
        dismissMenu()
        #if os(tvOS)
        dismissMenu()
        requireFocus("detail.more", timeout: 5, "focus comes back to ⋯ as the menus close")
        #endif
    }

    #if os(iOS)
    /// The default quality set to 720p 4 Mbps: Play's chevron checks it in its Quality submenu, the menu read again as
    /// the quality is looked up.
    func testPlayVersionChecksTheDefaultQuality() {
        openDetail(of: "Two Versions", settings: ["default_quality_preset=p720_4mbps"])
        tap(require("detail.versions", "Play's chevron"))
        tap(require("detail.quality", timeout: 10, "the versions' menu offers Quality"))
        let quality = app.buttons.matching(NSPredicate(format: "label BEGINSWITH '720p 4'")).firstMatch
        if !quality.exists(within: 10) { fail("Quality's submenu lists no 720p 4 Mbps") }
        // Settle: the submenu finishes presenting before its screenshot.
        Thread.sleep(forTimeInterval: 1)
        shot("play version default quality")
        XCTAssertTrue(checked(quality), "Quality's submenu checks the default quality, 720p 4 Mbps")
        dismissMenu()
    }
    #endif

    /// An open submenu's entry: by `id`, else (iOS and the Mac drop a nested SwiftUI menu's identifiers) the button
    /// matching `label`, on the Mac the menu item whose title does.
    @discardableResult
    private func submenuEntry(_ id: String, label: String, _ what: String) -> XCUIElement {
        let byId = element(id)
        if byId.exists(within: 3) { return byId }
        #if os(macOS)
        let byLabel = app.menuItems.matching(NSPredicate(format: label.replacingOccurrences(of: "label ", with: "title "))).firstMatch
        #else
        let byLabel = app.buttons.matching(NSPredicate(format: label)).firstMatch
        #endif
        if !byLabel.exists(within: 7) { fail("\(what): no \(id)") }
        return byLabel
    }

    /// A menu choice is checked: selected, or (a nested menu's entry on iOS) its check shows; the Mac's menu items don't
    /// report their check, so there the chevron's value names it.
    private func checked(_ item: XCUIElement) -> Bool {
        #if os(macOS)
        let name = item.title.isEmpty ? item.label : item.title
        return ((element("detail.versions").value as? String) ?? "").components(separatedBy: ", ").contains(name)
        #else
        item.isSelected || item.images.matching(NSPredicate(format: "identifier == 'checkmark' OR label == 'selected'")).firstMatch.exists
        #endif
    }

    #if !os(tvOS)
    /// The detail's download button through its states, the app signed in through the test's own proxy
    /// (`ServerProxy`), which holds the 26 MB film's PlaybackInfo and answers its file 404:
    /// - Download, then Downloading... while the queue prepares the film (the request held);
    /// - a second film queued meanwhile reads Queued, the queue busy with the first; it ends done (Delete download)
    ///   once the hold lets go, and is deleted;
    /// - the first film's file answering 404, it reads Retry download; retried with the file served again, it ends
    ///   done;
    /// - hidden while the device is offline, back once online. The download is deleted again at the end.
    func testDownloadButtonStates() {
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
        let server = proxy.server(for: Self.server)
        openDetail(of: Self.bigMovie, server: server)
        var film = require("detail.download", timeout: 30, "the film's download button")
        resetDownload(film)
        shot("download idle", of: film)

        // The queue's pass stops at the film's PlaybackInfo, which it asks for once the film reads Downloading...
        proxy.hold(firstPathContaining: "/PlaybackInfo")
        tap(film)
        answerDownloadDialogs()
        guard let held = proxy.heldPath(within: 30) else { return fail("the film's download asked for no PlaybackInfo") }
        let parts = held.split(separator: "/")
        guard let at = parts.firstIndex(of: "PlaybackInfo"), at > 0 else { return fail("no item in the held request \(held)") }
        let filmId = parts[at - 1]
        requireLabel(film, "Downloading…", "the film being prepared")
        shot("download downloading", of: film)
        proxy.respondNotFound(pathContaining: "/Videos/\(filmId)/stream")

        searchAgain(for: Self.secondMovie)
        let second = require("detail.download", timeout: 30, "the second film's download button")
        resetDownload(second)
        tap(second)
        answerDownloadDialogs()
        requireLabel(second, "Queued", "the second film queued behind the first")
        shot("download queued", of: second)
        // Over a period: the second film stays Queued (checked below).
        Thread.sleep(forTimeInterval: 3)
        XCTAssertEqual(second.label, "Queued", "the second film stays queued while the queue prepares the first")
        proxy.release()
        requireLabel(second, Self.downloadDone, timeout: 180, "the second film downloaded once the first went through")
        shot("second download done", of: second)
        deleteDownload(second)

        searchAgain(for: Self.bigMovie)
        film = require("detail.download", timeout: 30, "the film's download button again")
        requireLabel(film, "Retry download", timeout: 60, "the film whose file answered 404")
        shot("download failed", of: film)
        proxy.clearRules()
        tap(film)
        answerDownloadDialogs()
        requireLabel(film, Self.downloadDone, timeout: 180, "the retried film, its file served again")
        shot("download done", of: film)

        changeDevSetting("offline=true")
        if !film.waitForNonExistence(timeout: 30) { fail("the download button stays while the device is offline") }
        shot("download hidden offline")
        changeDevSetting("offline=false")
        let back = require("detail.download", timeout: 60, "the download button back online")
        deleteDownload(back)
    }

    /// A download the device loses its network under (offline the moment it starts) shows Retry download, or Resume
    /// download, once back online, or had already finished (the failed state where the network allows).
    func testDownloadButtonAfterLosingTheNetwork() {
        openDetail(of: Self.bigMovie)
        let button = require("detail.download", timeout: 30, "the film's download button")
        if button.label == Self.downloadDone { deleteDownload(button) }
        tap(button)
        answerDownloadDialogs()
        changeDevSetting("offline=true")
        // On purpose: the device stays offline long enough for the download to lose its network.
        Thread.sleep(forTimeInterval: 10)
        changeDevSetting("offline=false")
        let back = require("detail.download", timeout: 60, "the download button back online")
        // Settle: the button may pass through several states after reconnecting; no single end state to wait for.
        Thread.sleep(forTimeInterval: 3)
        let state = downloadState(back)
        shot("download after the network came back \(state)", of: back)
        XCTAssertTrue(["Retry download", "Resume download", Self.downloadDone].contains(back.label)
            || back.label.hasPrefix("Downloading"), "after the network came back the button reads \(state)")
        if back.label != Self.downloadDone {
            // Retry or resume, so the film ends downloaded and can be deleted.
            tap(back)
            answerDownloadDialogs()
            let done = NSPredicate(format: "label == %@", Self.downloadDone)
            if XCTWaiter.wait(for: [expectation(for: done, evaluatedWith: back)], timeout: 180) != .completed {
                fail("the retried download never completed: \(downloadState(back))")
            }
        }
        deleteDownload(back)
    }

    private static let bigMovie = "Codec Numbered Chapters"
    /// A film of the Movies library apart from the collection OfflineCollectionTests downloads.
    private static let secondMovie = "Alpha Archive"
    private static let downloadDone = "Delete download"

    /// The button's label, with its value after it where it has one (the spinner's "Loading").
    private func downloadState(_ button: XCUIElement) -> String {
        [button.label, (button.value as? String) ?? ""].filter { !$0.isEmpty }.joined(separator: " ")
    }

    /// Takes the download's first option and confirms where the download asks (a version, the pre-flight).
    private func answerDownloadDialogs() {
        for _ in 0..<6 {
            let option = element("downloads.dialog.option.0"), confirm = element("downloads.dialog.confirm")
            if !waitUntil(1, { option.exists || confirm.exists }) { return }
            if option.exists {
                tap(option)
            } else if confirm.exists {
                tap(confirm)
            }
        }
    }

    /// Deletes the film's download (Delete download, then the alert's Delete) and waits for Download again.
    private func deleteDownload(_ button: XCUIElement) {
        tap(button)
        tap(require("downloads.dialog.confirm", timeout: 10, "Delete download's question"))
        let idle = NSPredicate(format: "label == 'Download'")
        if XCTWaiter.wait(for: [expectation(for: idle, evaluatedWith: button)], timeout: 30) != .completed {
            fail("the deleted download's button reads \(downloadState(button)), not Download")
        }
    }

    /// Brings a download an earlier run left back to Download: a done one deleted, a failed or paused one taken on to
    /// done (then deleted), a moving one waited for.
    private func resetDownload(_ button: XCUIElement) {
        let deadline = Date().addingTimeInterval(240)
        while button.label != "Download", Date() < deadline {
            switch button.label {
            case Self.downloadDone:
                deleteDownload(button)
            case "Retry download", "Resume download":
                tap(button)
                answerDownloadDialogs()
                _ = waitUntil(2) { !["Retry download", "Resume download"].contains(button.label) }
            case let label:
                _ = waitUntil(5) { button.label != label }
            }
        }
        if button.label != "Download" { fail("an earlier run's download stays at \(downloadState(button))") }
    }

    private func requireLabel(_ button: XCUIElement, _ label: String, timeout: TimeInterval = 30, _ what: String) {
        let shows = NSPredicate(format: "label == %@", label)
        if XCTWaiter.wait(for: [expectation(for: shows, evaluatedWith: button)], timeout: timeout) != .completed {
            fail("\(what): the download button reads \(downloadState(button)), not \(label)")
        }
    }

    /// Back from the detail to Search, whose field then takes `title`, and on to its result's detail.
    private func searchAgain(for title: String) {
        #if os(macOS)
        app.typeKey(.escape, modifierFlags: [])
        #else
        let back = backButton
        if !back.exists(within: 5) { fail("the detail shows no Back") }
        back.tap()
        #endif
        require("search.screen", timeout: 10, "Back from the detail shows Search")
        let clear = element("search.clear")
        if clear.exists(within: 5) { tap(clear) }
        pickResult(title)
        waitForDetail(of: title)
    }

    /// With Hide spoilers on, an unwatched episode's still (Maestro Episode 3) is blurred past recognition:
    /// the still in the row's screenshot keeps hardly any of the sharp edges the same still has with the setting off.
    /// The episode is marked unwatched first where another run left it watched. Both are kept as screenshots.
    func testSpoilerBlurOnUnwatchedEpisode() {
        let blurred = episodeStillEdges(hideSpoilers: true)
        app.terminate()
        let sharp = episodeStillEdges(hideSpoilers: false)
        XCTAssertGreaterThan(sharp, 50, "the still with spoilers shown has sharp edges to count (\(sharp))")
        XCTAssertLessThan(blurred, sharp / 5, "the unwatched episode's still is blurred with Hide spoilers on: \(blurred) sharp edges against \(sharp)")
    }

    /// Opens Maestro Show on Season 1 with `hide_spoilers` as given, Maestro Episode 3 unwatched, and counts the sharp
    /// edges of its still.
    private func episodeStillEdges(hideSpoilers: Bool) -> Int {
        openDetail(of: Self.show, settings: ["hide_spoilers=\(hideSpoilers)"])
        let row = app.descendants(matching: .any).matching(NSPredicate(
            format: "identifier BEGINSWITH 'detail.episode.' AND NOT (identifier ENDSWITH '.menu') AND label CONTAINS '3. Maestro Episode 3'"
        )).firstMatch
        // The show opens on its next episode's season; Season 1 is picked where it opened on another.
        let season = require("detail.season.1", timeout: 30, "the show's Season 1 chip")
        if !row.exists(within: 10), !season.isSelected {
            #if os(macOS)
            // The chip's own frame, not its hittability: the right-click catcher over it hides its activation point.
            season.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).click()
            #else
            tap(season)
            #endif
        }
        if !row.exists(within: 20) { fail("Season 1 lists no Maestro Episode 3") }
        for _ in 0..<6 where !app.windows.firstMatch.frame.insetBy(dx: 0, dy: 100).contains(row.frame) {
            #if os(macOS)
            app.windows.firstMatch.scroll(byDeltaX: 0, deltaY: -150)
            #else
            app.swipeUp(velocity: .slow)
            #endif
            // Settle: the scroll finishes before the frame is checked again.
            Thread.sleep(forTimeInterval: 1)
        }
        if row.label.hasPrefix("watched") {
            tap(element("\(row.identifier).menu"))
            tap(require("menu.unwatch", timeout: 10, "the episode's Mark as Unwatched"))
            if !waitUntil(15, { !row.label.hasPrefix("watched") }) { fail("Maestro Episode 3 stays watched: \(row.label)") }
        }
        // The still comes over the network.
        Thread.sleep(forTimeInterval: 4)
        let name = hideSpoilers ? "spoiler blur on" : "spoiler blur off"
        shot(name)
        let screenshot = row.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "\(name) row"
        attachment.lifetime = .keepAlways
        add(attachment)
        return Self.sharpEdges(of: screenshot, rowWidth: row.frame.width)
    }

    /// How many neighbouring pixels in the still differ by more than a tenth of the luminance range: the still 12 points
    /// in from the row's leading edge (its inset), 112 points of the narrowest still's width, the middle 50 points of
    /// the row's height. A blurred still has next to none; a test pattern's bars have hundreds.
    private static func sharpEdges(of screenshot: XCUIScreenshot, rowWidth: CGFloat) -> Int {
        #if os(macOS)
        guard let image = screenshot.image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return 0 }
        #else
        guard let image = screenshot.image.cgImage else { return 0 }
        #endif
        let scale = CGFloat(image.width) / rowWidth
        let crop = CGRect(x: 16 * scale, y: CGFloat(image.height) / 2 - 25 * scale, width: 112 * scale, height: 50 * scale).integral
        guard let region = image.cropping(to: crop) else { return 0 }
        let width = region.width, height = region.height
        var pixels = [UInt8](repeating: 0, count: width * height)
        guard let context = CGContext(
            data: &pixels, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width,
            space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return 0 }
        context.draw(region, in: CGRect(x: 0, y: 0, width: width, height: height))
        var edges = 0
        for y in 0..<(height - 1) {
            for x in 0..<(width - 1) {
                let here = Int(pixels[y * width + x])
                if abs(here - Int(pixels[y * width + x + 1])) > 25 || abs(here - Int(pixels[(y + 1) * width + x])) > 25 { edges += 1 }
            }
        }
        return edges
    }
    #endif

    /// An album among the results opens its music screen, as an album card does anywhere.
    func testAlbumResultOpensItsMusicScreen() {
        openResult("Sine Album")
        require("music.album", timeout: 30, "the album's music screen")
        // Settle: the album's artwork before the screenshot.
        Thread.sleep(forTimeInterval: 3)
        shot("album from search")
    }

    /// A track among the results plays in its album's queue in the music player.
    func testTrackResultPlaysInItsAlbum() {
        openResult("Low Hum")
        #if os(tvOS)
        require("music.np.title", timeout: 30, "Now Playing's track title")
        #elseif os(macOS)
        require("music.bar.open", timeout: 30, "the playback bar's track")
        #else
        require("music.mini.open", timeout: 30, "the mini-player's track")
        #endif
        // Settle: the player shows the track before the screenshot.
        Thread.sleep(forTimeInterval: 2)
        shot("track from search")
    }

    /// A query that finds titles of several kinds and a person lists them under All in groups headed by their kind;
    /// on Apple TV Down walks from the keyboard into the results and on past a heading.
    func testResultsOfSeveralKindsShowUnderTheirKind() {
        launchDev(arguments: ["--dev-open", "search", "--dev-server", Self.server])
        require("search.screen", timeout: 90, "the Search screen")
        type("Maestro")
        let movie = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'search.result.' AND label == %@", Self.movie)).firstMatch
        if !movie.exists(within: 30) { fail("typing Maestro lists no \(Self.movie)") }
        // Settle: the results' artwork before the screenshot.
        Thread.sleep(forTimeInterval: 3)
        shot("search maestro")
        // Before moving: the list is lazy, so a heading scrolled far off is gone from the tree.
        require("search.group.0", "the first kind's heading")
        require("search.group.1", "the second kind's heading")
        #if os(tvOS)
        moveFocus(prefix: "search.result.", with: .down, "Down moves focus from the keyboard to the results")
        press(.down)
        press(.down)
        shot("search maestro down")
        #else
        scrollDown()
        shot("search maestro scrolled")
        #endif
    }

    /// Starts on Search, types `title`, opens its result and waits for the detail to load. The app signs in to `server`
    /// (a `--dev-server` spec), the default test Jellyfin otherwise.
    private func openDetail(of title: String, settings: [String] = [], server: String = DetailSearchTests.server) {
        openResult(title, settings: settings, server: server)
        waitForDetail(of: title)
    }

    #if os(macOS)
    /// Opens `title`'s detail from the Movies library's grid, typing nothing (`LibrarySteps.openCard`).
    private func openDetailFromLibrary(of title: String) {
        launchDev(arguments: ["--dev-open", "libraries", "--dev-server", Self.server])
        require("libraries.screen", timeout: 60, "Libraries")
        LibrarySteps(test: self).openCard(title, in: "Movies")
        waitForDetail(of: title)
    }
    #endif

    private func waitForDetail(of title: String) {
        require("detail.screen", "\(title)'s detail")
        #if os(tvOS)
        require("detail.info", timeout: 30, "\(title)'s information block")
        #else
        require("detail.title", timeout: 30, "\(title)'s title")
        #endif
        // The artwork comes over the network.
        Thread.sleep(forTimeInterval: 4)
    }

    /// Starts on Search, types `title` and selects its result.
    private func openResult(_ title: String, settings: [String] = [], server: String = DetailSearchTests.server) {
        launchDev(settings: settings, arguments: ["--dev-open", "search", "--dev-server", server])
        require("search.screen", timeout: 90, "the Search screen")
        pickResult(title)
    }

    /// Types `title` into Search's field and selects its result: `whileSearching` runs once the title is typed,
    /// `beforeOpening` once its result shows.
    private func pickResult(_ title: String, whileSearching: (() -> Void)? = nil, beforeOpening: (() -> Void)? = nil) {
        type(title)
        whileSearching?()
        let result = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'search.result.' AND label == %@", title)).firstMatch
        if !result.exists(within: 30) { fail("typing \(title) lists no \(title)") }
        // Settle: the results' artwork before the screenshot.
        Thread.sleep(forTimeInterval: 2)
        shot("search \(title)")
        beforeOpening?()
        #if os(tvOS)
        moveFocus(label: title, with: .down, "Down moves focus from the keyboard to \(title)")
        shot("search \(title) focused")
        press(.select)
        #else
        #if os(macOS)
        // The row's own frame, not its hittability: the right-click catcher over it hides its activation point.
        result.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).click()
        #else
        tap(result)
        #endif
        #endif
    }

    /// Types `text` into Search's field: on Apple TV into the system's search field's keyboard; elsewhere into the field once it has the keyboard focus (the screen gives it as it opens).
    private func type(_ text: String) {
        #if os(tvOS)
        // The system's search field (`searchable`): Down from it reaches its keyboard, which takes the text. Down
        // pressed before the screen settles its focus moves nothing: pressed again until the keyboard has the focus.
        let field = app.searchFields.firstMatch
        if !field.exists(within: 10) { fail("Search shows no search field") }
        let keyboardFocus = app.descendants(matching: .any).matching(NSPredicate(format: "hasKeyboardFocus == 1"))
        for _ in 0..<3 where keyboardFocus.count == 0 {
            press(.down)
            _ = waitUntil(3) { keyboardFocus.count > 0 }
        }
        if keyboardFocus.count == 0 { fail("Down from the search field reaches no keyboard") }
        field.typeText(text)
        #else
        let field = require("search.field", "the search field")
        #if os(macOS)
        field.click()
        #else
        // XCUITest's own attribute, which its API doesn't name: the field takes the keys only once it has the focus.
        let hasFocus = { field.value(forKey: "hasKeyboardFocus") as? Bool == true }
        for _ in 0..<3 where !hasFocus() {
            field.tap()
            _ = waitUntil(3, hasFocus)
        }
        if !hasFocus() { fail("the search field doesn't take the keyboard focus") }
        if UIDevice.current.userInterfaceIdiom == .pad {
            // The iPad simulator (iOS 27.0) ends the app in UIKit when typeText switches it to the hardware keyboard
            // while the software one shows: the software keyboard's keys instead.
            for character in text.lowercased() {
                let name = character == " " ? "space" : String(character)
                let key = app.keyboards.keys.matching(NSPredicate(format: "label ==[c] %@ OR identifier ==[c] %@", name, name)).firstMatch
                if !key.exists(within: 5) { fail("the keyboard has no \(character) key") }
                key.tap()
            }
            return
        }
        #endif
        field.typeText(text)
        #endif
    }

    /// Closes the shared menu: Escape on the Mac, Menu on the remote, a tap beside the system's menu on touch.
    private func dismissMenu() {
        #if os(macOS)
        app.typeKey(.escape, modifierFlags: [])
        #elseif os(tvOS)
        XCUIRemote.shared.press(.menu)
        #else
        // Beside the system's menu (a card's context menu, a ⋯'s menu), which keeps clear of the screen's edges: a few
        // points in, since an iPad's versions menu starts 21 points in, where a tap at 2 % of its width lands on it.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0.5)).withOffset(CGVector(dx: 4, dy: 0)).tap()
        #endif
        // Settle: the menu finishes closing before the next input.
        Thread.sleep(forTimeInterval: 1)
    }

    #if !os(tvOS)
    private func scrollDown() {
        #if os(macOS)
        app.windows.firstMatch.scroll(byDeltaX: 0, deltaY: -400)
        #else
        app.swipeUp()
        #endif
        // Settle: the scroll finishes before its callers read frames or take screenshots.
        Thread.sleep(forTimeInterval: 2)
    }

    private func tap(_ element: XCUIElement) {
        #if os(macOS)
        element.click()
        #else
        element.tap()
        #endif
    }
    #endif

    #if os(tvOS)
    private func press(_ button: XCUIRemote.Button) {
        XCUIRemote.shared.press(button)
        // Paced on purpose: the focus engine finishes moving before the next press.
        Thread.sleep(forTimeInterval: 0.6)
    }

    private var focused: XCUIElement {
        app.descendants(matching: .any).element(matching: NSPredicate(format: "hasFocus == true"))
    }

    /// Whether focus is on `id`. A system menu's button reports focus on an unnamed element inside it, which counts when
    /// its frame is the button's.
    private func focusIs(_ id: String) -> Bool {
        guard focused.exists else { return false }
        if focused.identifier == id { return true }
        let button = app.buttons[id]
        return focused.identifier.isEmpty && button.exists && button.frame.insetBy(dx: -4, dy: -4).contains(focused.frame)
    }

    private func requireFocus(_ id: String, timeout: TimeInterval = 20, _ what: String) {
        if waitUntil(timeout, every: 0.5, { focusIs(id) }) { return }
        fail("\(what): focus is on \(focused.exists ? focused.identifier : "nothing"), not \(id)")
    }

    /// Presses `button` until the focused element matches, at most `limit` times.
    private func moveFocus(
        prefix: String? = nil, label: String? = nil, ids: [String] = [], with button: XCUIRemote.Button, limit: Int = 8, _ what: String
    ) {
        for _ in 0..<limit {
            press(button)
            guard focused.exists else { continue }
            if let prefix, focused.identifier.hasPrefix(prefix) { return }
            if let label, focused.label == label { return }
            if ids.contains(where: focusIs) { return }
        }
        fail("\(what): focus is on \(focused.exists ? focused.identifier : "nothing")")
    }
    #endif
}
