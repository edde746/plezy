import XCTest

/// Settings → Services against the fake tracker server (which approves a device code, and the sign-in relay's link,
/// by itself after a couple of polls) and the test Jellyfin server, whose sign-in makes the active profile: on iPhone,
/// iPad and the Mac a Trakt sign-in the fake holds open shows its code sheet back from the browser, and Cancel ends it;
/// connecting Trakt shows its code sheet until the fake approves, then Trakt's row says it is connected as the fake's
/// user; its settings disconnect it after the confirmation; connecting AniList shows the relay's link sheet until it
/// connects. By touch on iPhone and iPad, the pointer on the Mac (where Open also goes to the browser, which the test
/// leaves), and the remote on Apple TV. Each test talks to runs of its own on the fake tracker server and the fake Seerr
/// (their `/run/<id>`), which other test runs sharing the fakes (other platforms, other checkouts) can't reset or write
/// to.
final class TrackersTests: PlezyUITestCase {
    #if os(macOS)
    // The Mac's test runs reach the test servers through tunnels on its loopback: an app started there unattended gets
    // no local network access.
    private nonisolated static let host = "127.0.0.1"
    #else
    private nonisolated static let host = "192.168.0.15"
    #endif
    private let fakeTrackers = "http://\(TrackersTests.host):28100/run/\(UUID().uuidString)"
    private static let testServer = "jellyfin=maestro:maestro@http://\(host):28096"
    private static let fakeUser = "plezy-tester"
    private nonisolated static let fakeSeerr = "http://\(host):28099"
    private let seerrAccount = "maestro@plezy.test:maestro@\(TrackersTests.fakeSeerr)/run/\(UUID().uuidString)"

    /// Settings → Services' Seerr row with the profile signed in to the fake Seerr: its settings (who, how, where), then
    /// Disconnect (asked first) leaves the row not connected, and the row opens the connect form's address step; on
    /// iPhone, iPad and the Mac the fake's address (its root: any instance that answers) then reaches its sign-in step.
    func testSeerrSettingsAndConnect() {
        launchDev(arguments: ["--dev-open", "settings", "--dev-server", Self.testServer, "--dev-seerr", seerrAccount])
        require("settings.screen", timeout: 60, "Settings")
        openServices()
        require("settings.seerr", "Services lists Seerr")
        // The development session signs in to the fake Seerr as it starts: the row opens its settings once it has.
        _ = waitUntil(10) { element("settings.seerr").label.contains("Maestro") }
        select("settings.seerr", "Seerr's row")
        require("seerrSettings.screen", "a connected Seerr's row opens its settings")
        settledShot("seerr settings")
        select("seerrSettings.disconnect", "Seerr's settings offer Disconnect")
        require("seerrSettings.confirm", timeout: 5, "Disconnect asks first")
        settledShot("seerr disconnect asked")
        press(answer: "seerrSettings.confirm")
        require("services.screen", timeout: 10, "the settings close once Seerr is disconnected")
        select("settings.seerr", "Seerr's row")
        require("seerrConnect.url", "the connect form asks for the address")
        settledShot("seerr connect")
        #if !os(tvOS)
        let field = element("seerrConnect.url")
        press(field)
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            // The iPad simulator ends the app when typeText switches it to the hardware keyboard while the software one
            // shows: the software keyboard's keys instead.
            if !app.keyboards.firstMatch.exists(within: 10) { fail("the address field opens no keyboard") }
            tapKeys(Self.fakeSeerr)
            press(require("seerrConnect.continue", "the address step's Continue"))
        } else {
            // Keys typed while the keyboard still slides in are lost ("h:/92.168…").
            if !app.keyboards.firstMatch.exists(within: 10) { fail("the address field opens no keyboard") }
            Thread.sleep(forTimeInterval: 1)
            field.typeText(Self.fakeSeerr + "\n")
        }
        #else
        field.typeText(Self.fakeSeerr + "\n")
        #endif
        require("seerrConnect.change", timeout: 30, "the instance answers with its sign-in step")
        settledShot("seerr sign in")
        #endif
    }

    /// Return pressed with the last key (`typeText("…\n")`) acts on all that was typed: the Seerr address reaches the
    /// sign-in step with its last character (the run's id ends it, and a run cut short is another run that also
    /// answers), and the local sign-in's email and password connect the profile. iPhone and the Mac (the iPad
    /// simulator ends the app when typeText brings up the hardware keyboard; Apple TV types on a screen of its own).
    func testSeerrReturnSubmitsAllTyped() throws {
        #if os(tvOS)
        throw XCTSkip("Apple TV's keyboard is a screen of its own")
        #else
        #if os(iOS)
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .phone, "typeText on the iPad simulator ends the app")
        #endif
        let run = UUID().uuidString
        let address = "\(Self.fakeSeerr)/run/\(run)"
        launchDev(arguments: ["--dev-open", "settings", "--dev-server", Self.testServer])
        require("settings.screen", timeout: 60, "Settings")
        openServices()
        select("settings.seerr", "Services lists Seerr")
        let field = require("seerrConnect.url", "the connect form asks for the address")
        typeAtOnce(address + "\n", into: field)
        require("seerrConnect.change", timeout: 30, "the instance answers with its sign-in step")
        // Its text is the label on iPhone, the value on the Mac.
        let shown = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@ OR value CONTAINS %@", "/run/\(run)", "/run/\(run)")).firstMatch
        if !shown.exists(within: 5) { fail("the sign-in step's address is not all of \(address)") }
        press(require("seerrConnect.method.local", "the instance offers its local sign-in"))
        typeAtOnce("maestro@plezy.test\n", into: require("seerrConnect.identifier", "the local sign-in's email"))
        typeAtOnce("maestro\n", into: require("seerrConnect.password", "the local sign-in's password"))
        requireSignedIn(after: "Return in the password")
        #endif
    }

    /// A sign-in form switched to another clears its fields, as the store does: an email typed under the local
    /// sign-in is gone once Jellyfin's form shows, and Jellyfin's username and password then connect the profile.
    /// iPhone and the Mac, as above.
    func testSeerrFormSwitchClearsFields() throws {
        #if os(tvOS)
        throw XCTSkip("Apple TV's keyboard is a screen of its own")
        #else
        #if os(iOS)
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .phone, "typeText on the iPad simulator ends the app")
        #endif
        launchDev(arguments: ["--dev-open", "settings", "--dev-server", Self.testServer])
        require("settings.screen", timeout: 60, "Settings")
        openServices()
        select("settings.seerr", "Services lists Seerr")
        typeAtOnce("\(Self.fakeSeerr)/run/\(UUID().uuidString)\n", into: require("seerrConnect.url", "the connect form asks for the address"))
        require("seerrConnect.change", timeout: 30, "the instance answers with its sign-in step")
        press(require("seerrConnect.method.local", "the instance offers its local sign-in"))
        let identifier = require("seerrConnect.identifier", "the local sign-in's email")
        typeAtOnce("someone@plezy.test", into: identifier)
        press(require("seerrConnect.method.jellyfin", "the local form offers Jellyfin's"))
        _ = waitUntil(5) { !((identifier.value as? String) ?? "").contains("someone") }
        settledShot("seerr jellyfin form after local")
        let shown = (identifier.value as? String) ?? ""
        XCTAssertFalse(shown.contains("someone"), "Jellyfin's username field still shows the local email: \(shown)")
        typeAtOnce("maestro\n", into: identifier)
        typeAtOnce("maestro\n", into: require("seerrConnect.password", "Jellyfin's password"))
        requireSignedIn(after: "Jellyfin's sign-in")
        #endif
    }

    #if !os(tvOS)
    /// The connect form closes on Services and Seerr's row names Maestro. AutoFill's Save Password? card can come up over
    /// the form as Return signs in: Not Now, until the form closes; the row is read, not pressed.
    private func requireSignedIn(after what: String) {
        let services = element("services.screen")
        #if os(iOS)
        let notNow = [app.buttons["Not Now"].firstMatch, XCUIApplication(bundleIdentifier: "com.apple.springboard").buttons["Not Now"].firstMatch]
        #else
        let notNow = [app.buttons["Not Now"].firstMatch]
        #endif
        let closed = waitUntil(30) {
            if let button = notNow.first(where: { $0.exists }), button.isHittable { press(button) }
            return services.exists
        }
        if !closed { fail("the connect form stays open after \(what)") }
        let row = element("settings.seerr")
        if !waitUntil(10, { row.label.contains("Maestro") }) { fail("Seerr's row is not connected as Maestro: \(row.label)") }
    }
    #endif

    #if !os(tvOS)
    /// Focuses `field` and types `text` into it in one go, once the keyboard is up (keys typed while the iPhone's
    /// keyboard still slides in are lost).
    private func typeAtOnce(_ text: String, into field: XCUIElement) {
        press(field)
        #if os(iOS)
        if !app.keyboards.firstMatch.exists(within: 10) { fail("the field opens no keyboard") }
        Thread.sleep(forTimeInterval: 1)
        #endif
        field.typeText(text)
    }
    #endif

    #if os(iOS)
    /// Types `text` with the software keyboard's keys (iPad's full keyboard: its digits, "." and "/" on keys of their
    /// own; the keys are labelled with what they type now, so ":" shows once Shift is down).
    private func tapKeys(_ text: String) {
        func key(_ name: String) -> XCUIElement {
            app.keyboards.keys.matching(NSPredicate(format: "label ==[c] %@ OR identifier ==[c] %@", name, name)).firstMatch
        }
        for character in text.lowercased() {
            let name = character == " " ? "space" : String(character)
            if character == ":", !key(":").exists {
                let shift = key("shift")
                if !shift.exists(within: 5) { fail("the keyboard has no shift key") }
                shift.tap()
            }
            let target = key(name)
            if !target.exists(within: 5) { fail("the keyboard has no \(name) key") }
            target.tap()
        }
    }
    #endif

    /// Explore over the fake Seerr: the requestable movie's Request opens the request form (its Request in the bar; on
    /// Apple TV the form's button), and Cancel closes it.
    func testSeerrRequestSheet() {
        openUnrequestedUtopia()
        require("catalogDetail.screen", "Unrequested Utopia's detail")
        reach(require("catalogDetail.request", timeout: 20, "the Request action"), "the Request action")
        require("seerrRequest.sheet", timeout: 30, "the request sheet")
        require("seerrRequest.submit", timeout: 30, "the sheet's Request")
        settledShot("seerr request")
        reach(require("seerrRequest.cancel", "the sheet's Cancel"), "the sheet's Cancel")
        requireGone("seerrRequest.sheet", timeout: 10, "Cancel closes the request sheet")
    }

    #if !os(tvOS)
    /// Request pressed the moment it shows, right after the card opens the detail, opens the request form: the button
    /// shows where it stays, not where the detail filling in above it moves it from under the press.
    func testSeerrRequestPressedAsTheDetailOpens() {
        openUnrequestedUtopia()
        let request = element("catalogDetail.request")
        if !request.exists(within: 20) { fail("no Request action") }
        press(request)
        require("seerrRequest.sheet", timeout: 10, "the request sheet")
    }
    #endif

    /// Explore over the fake Seerr with the requestable movie's card pressed.
    private func openUnrequestedUtopia() {
        launchDev(arguments: ["--dev-open", "explore", "--dev-server", Self.testServer, "--dev-seerr", seerrAccount])
        require("explore.screen", timeout: 60, "Explore")
        let card = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'card.' AND label == 'Unrequested Utopia'")).firstMatch
        if !card.exists(within: 30) { fail("no card Unrequested Utopia") }
        #if os(iOS)
        // Its shelf scrolls sideways: dragged until the card is on screen.
        let width = app.windows.firstMatch.frame.width
        for _ in 0..<8 where card.frame.maxX > width || card.frame.minX < 0 {
            let start = app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: width * 0.8, dy: card.frame.midY))
            start.press(forDuration: 0.05, thenDragTo: start.withOffset(CGVector(dx: -width * 0.5, dy: 0)))
            _ = waitUntil(1) { card.frame.maxX <= width && card.frame.minX >= 0 }
        }
        #endif
        reach(card, "Unrequested Utopia's card")
    }

    /// Presses `target`: a tap or a click; on Apple TV focus walked to it (each press the way it lies from the focused
    /// element, out of the tab bar first), then Select.
    private func reach(_ target: XCUIElement, _ what: String) {
        #if os(tvOS)
        for _ in 0..<30 where !holdsFocus(target) {
            let focusedNow = focused
            let to = target.frame, from = focusedNow.exists ? focusedNow.frame : .zero
            let direction: XCUIRemote.Button = if focusedNow.exists, focusedNow.identifier.hasPrefix("nav.") {
                .down
            } else if to.minY >= from.maxY - 1 {
                .down
            } else if to.maxY <= from.minY + 1 {
                .up
            } else {
                to.midX > from.midX ? .right : .left
            }
            XCUIRemote.shared.press(direction)
            _ = waitUntil(0.5) { holdsFocus(target) }
        }
        if !holdsFocus(target) { fail("\(what): focus never reached it; it is on \(focusedId ?? "nothing")") }
        XCUIRemote.shared.press(.select)
        #else
        press(target)
        #endif
    }

    /// A movie's detail with every service connected to the fake: Rate in its ⋯ menu opens the rating sheet with a row
    /// per tracker, and its watchlist button opens the watchlist sheet (on Apple TV the sources' menu on the button),
    /// whose Simkl row puts the movie on Simkl's watchlist and closes it.
    func testRatingAndWatchlistSheetsOnDetail() {
        launchDev(arguments: ["--dev-open", "search", "--dev-server", Self.testServer, "--dev-trackers", fakeTrackers, "--dev-trackers-connected"])
        require("search.screen", timeout: 90, "the Search screen")
        search("Subtitled Movie")
        let result = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'search.result.' AND label == 'Subtitled Movie'")).firstMatch
        if !result.exists(within: 30) { fail("Search lists no Subtitled Movie") }
        // The results list again for the last keys typed: a tap on the first list's row goes nowhere.
        Thread.sleep(forTimeInterval: 2)
        #if os(macOS)
        // The row's own frame, not its hittability: the right-click catcher over it hides its activation point.
        result.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).click()
        #else
        reach(result, "Subtitled Movie's result")
        #endif
        require("detail.screen", timeout: 30, "Subtitled Movie's detail")
        _ = waitUntil(20) { element("detail.more").isHittable }

        let more = require("detail.more", timeout: 20, "the detail's ⋯")
        #if os(tvOS)
        // Along the row from Play, where the detail opens, to ⋯: in some sessions the row's buttons (Play, Cast,
        // Watched) don't tell XCUITest they have the focus while its menus (⋯ among them) do, so the way to ⋯ can't
        // be read off the focused element.
        for _ in 0..<8 where !holdsFocus(more) {
            XCUIRemote.shared.press(.right)
            _ = waitUntil(1) { holdsFocus(more) }
        }
        if !holdsFocus(more) { fail("Right along the row never reaches the detail's ⋯; focus is on \(focusedId ?? "nothing")") }
        XCUIRemote.shared.press(.select)
        #else
        reach(more, "the detail's ⋯")
        #endif
        let rate = require("menu.rate", timeout: 10, "the menu's Rate")
        #if os(tvOS)
        reach(rate, "the menu's Rate")
        #else
        tapSettled(rate)
        #endif
        require("ratingSheet", timeout: 15, "the rating sheet")
        require("ratingSheet.row.trakt", timeout: 15, "the sheet's Trakt row")
        require("ratingSheet.row.simkl", "the sheet's Simkl row")
        settledShot("rating sheet")
        dismissSheet(element("ratingSheet"), close: "ratingSheet.close")
        requireGone("ratingSheet", timeout: 10, "the sheet closes")

        let button = require("detail.watchlist", timeout: 30, "the detail's watchlist button")
        #if !os(tvOS)
        XCTAssertTrue(button.wait(for: \.isEnabled, toEqual: true, timeout: 15), "the watchlists load and the button can be pressed")
        #endif
        reach(button, "the detail's watchlist button")
        let simkl = require("detail.watchlist.option.1", timeout: 15, "the watchlist's second source")
        requireLabel(simkl, containing: "Simkl", "Simkl is the second source")
        settledShot("watchlist sheet")
        reach(simkl, "the watchlist's Simkl")
        #if os(tvOS)
        requireGone("detail.watchlist.option.1", timeout: 10, "the menu closes")
        if !waitUntil(5, { holdsFocus(button) }) { fail("focus doesn't come back to the watchlist button: it is on \(focusedId ?? "nothing")") }
        #else
        requireGone("detail.watchlist.option.sheet", timeout: 10, "the sheet closes")
        #endif
        requireLabel(element("detail.watchlist"), containing: "Remove", "the movie is on a watchlist now")
    }

    #if !os(tvOS)
    /// Yume Anime, the test servers' anime, with every service connected to the fake: its NFO carries a real anime's
    /// ids, which the anime mappings map to MyAnimeList and AniList entry 339, which the fake starts completed and
    /// scored 8 on MyAnimeList, 7 on AniList. Its detail's rating sheet shows both rows matched with those scores, 4
    /// and 3.5 stars.
    func testAnimeRatingSheetReadsTheAnimeListsScores() {
        launchDev(arguments: ["--dev-open", "libraries", "--dev-server", Self.testServer, "--dev-trackers", fakeTrackers, "--dev-trackers-connected"])
        require("libraries.screen", timeout: 90, "Libraries")
        let steps = LibrarySteps(test: self)
        steps.pickLibrary("Shows")
        steps.showLibraryTab("browse")
        let show = steps.card(prefix: "Yume Anime")
        if !show.exists(within: 30) { return fail("the Shows library lists no Yume Anime") }
        #if os(macOS)
        show.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).click()
        #else
        show.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        #endif
        require("detail.screen", timeout: 30, "Yume Anime's detail")
        _ = waitUntil(20) { element("detail.more").isHittable }
        settledShot("anime detail")
        press(require("detail.more", timeout: 20, "the detail's ⋯"))
        press(require("menu.rate", timeout: 10, "the menu's Rate"))
        require("ratingSheet", timeout: 15, "the rating sheet")
        let mal = require("ratingSheet.row.mal", timeout: 15, "the sheet's MyAnimeList row")
        let anilist = require("ratingSheet.row.anilist", "the sheet's AniList row")
        let stars = { (row: XCUIElement) in row.value as? String ?? "" }
        if !waitUntil(30, { stars(mal).hasPrefix("4") && stars(anilist).hasPrefix("3.5") }) {
            fail("the anime lists' rows read no scores: \(mal.label) \(stars(mal)), \(anilist.label) \(stars(anilist))")
        }
        settledShot("anime rating sheet")
    }
    #endif

    /// Types `text` into Search's field: on Apple TV into the system search field's keyboard, Down from the field; on
    /// iPad with the software keyboard's keys (the simulator ends the app when typeText switches to the hardware keyboard).
    private func search(_ text: String) {
        #if os(tvOS)
        // The system's search field (`searchable`): Down from it reaches its keyboard, which takes the text. Down
        // pressed before the screen settles its focus moves nothing: pressed again until the keyboard has the focus.
        let field = app.searchFields.firstMatch
        if !field.exists(within: 20) { fail("Search shows no search field") }
        let keyboardFocus = app.descendants(matching: .any).matching(NSPredicate(format: "hasKeyboardFocus == 1"))
        for _ in 0..<3 where keyboardFocus.count == 0 {
            XCUIRemote.shared.press(.down)
            _ = waitUntil(3) { keyboardFocus.count > 0 }
        }
        if keyboardFocus.count == 0 { fail("Down from the search field reaches no keyboard") }
        field.typeText(text)
        #elseif os(macOS)
        let field = require("search.field", "the search field")
        field.click()
        field.typeText(text)
        #else
        let field = require("search.field", "the search field")
        field.tap()
        // The keyboard slides in: keys typed before it settles are lost.
        Thread.sleep(forTimeInterval: 1)
        if UIDevice.current.userInterfaceIdiom == .pad {
            tapKeys(text)
        } else {
            field.typeText(text)
        }
        #endif
    }

    func testConnectTraktDisconnectAndConnectAniList() {
        launchDev(arguments: ["--dev-open", "settings", "--dev-server", Self.testServer, "--dev-trackers", fakeTrackers])
        require("settings.screen", timeout: 60, "Settings")
        openServices()
        let trakt = require("services.row.trakt", "Services lists Trakt")
        require("services.row.anilist", "Services lists AniList")
        shot("services")

        #if !os(tvOS)
        // Touch and the pointer open the link in the browser as the sheet shows, and the fake approves before the test
        // is back: held open (the fake approves no device code until its reset), the sheet is shot back in the app,
        // and Cancel ends the sign-in.
        postToFake("/_config?approveAfter=1000")
        select("services.row.trakt", "Trakt's row")
        require("services.dialog.code", "connecting Trakt shows its device code")
        backToApp()
        require("services.dialog.code", timeout: 10, "the code sheet is still up back in the app")
        settledShot("trakt code")
        select("services.dialog.cancel", "the code sheet offers Cancel")
        requireGone("services.dialog", timeout: 10, "Cancel closes the code sheet")
        requireLabel(trakt, containing: "Not connected", "a cancelled sign-in leaves Trakt not connected")
        postToFake("/_reset")
        #endif

        select("services.row.trakt", "Trakt's row")
        // Touch and the pointer open the link in the browser as the sheet shows: the sheet is checked at once, and shot
        // back in the app while the fake hasn't approved yet.
        let code = require("services.dialog.code", "connecting Trakt shows its device code")
        require("services.dialog.qr", timeout: 5, "the code comes with its QR code")
        if code.label.isEmpty { fail("the device code shows no code") }
        backToApp()
        shotIfShown("services.dialog", "trakt code")
        requireGone("services.dialog", timeout: 90, "the fake approves the code and the sheet closes")
        requireLabel(trakt, containing: "Connected as @\(Self.fakeUser)", "Trakt's row says it is connected")
        settledShot("trakt connected")

        select("services.row.trakt", "Trakt's row")
        require("trackerSettings.screen", "a connected Trakt's row opens its settings")
        settledShot("trakt settings")
        select("trackerSettings.disconnect", "Trakt's settings offer Disconnect")
        require("trackerSettings.disconnect.confirm", timeout: 5, "Disconnect asks first")
        settledShot("disconnect asked")
        confirmDisconnect()
        require("services.screen", timeout: 10, "the settings close once Trakt is disconnected")
        requireLabel(element("services.row.trakt"), containing: "Not connected", "Trakt's row says it is not connected")

        #if os(tvOS)
        // The relay signs in after two polls, which can come before the sheet is checked: held until it is, then let go.
        postToFake("/_config?approveAfter=1000")
        #endif
        select("services.row.anilist", "AniList's row")
        #if os(tvOS)
        require("services.dialog", "connecting AniList shows the relay's link")
        require("services.dialog.qr", timeout: 5, "the link comes with its QR code")
        require("services.dialog.url", timeout: 5, "the link shows to type")
        settledShot("anilist link")
        postToFake("/_config?approveAfter=2")
        #else
        // The link opens in the browser, where the relay may sign in before the test is back in the app.
        backToApp()
        shotIfShown("services.dialog", "anilist link")
        #endif
        requireGone("services.dialog", timeout: 90, "the relay signs in and the sheet closes")
        requireLabel(element("services.row.anilist"), containing: "Connected", "AniList's row says it is connected")
        settledShot("anilist connected")
    }

    #if os(iOS)
    /// A movie's menu (its Search result's) with every service connected to the fake: Add to Watchlist asks which of
    /// Trakt, Simkl and MDBList (the sources that can hold it) and adds it to Trakt, which a toast says above the tab
    /// bar; the reopened menu says Remove from Watchlist and removes it; Rate opens the rating sheet, whose Trakt row
    /// saves a score. Then the movie's detail: its watchlist button opens the same chooser and adds it to Simkl,
    /// filling the bookmark. The fake records each write. First Home a little way down, under the status bar's fade.
    func testRatesAndWatchlistsAMovieFromItsMenu() throws {
        launchDev(arguments: ["--dev-server", Self.testServer, "--dev-trackers", fakeTrackers, "--dev-trackers-connected"])
        require("home.screen", timeout: 60, "after the launch")
        let window = app.windows.firstMatch
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.6))
            .press(forDuration: 0.1, thenDragTo: window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.42)))
        // The drag's deceleration ends with nothing to wait on before the shot.
        sleep(1)
        shot("home scrolled")

        require("nav.search", "the Search tab").tap()
        require("search.screen", timeout: 30, "the Search screen")
        var card = try movieResult()
        shot("search")

        openMenu(on: card)
        require("menu.watchlist_add", timeout: 10, "the movie's menu offers Add to Watchlist")
        require("menu.rate", "the movie's menu offers Rate")
        shot("menu")
        element("menu.watchlist_add").tap()
        require("menu.option.sheet", "Add to Watchlist asks which source")
        requireLabel(element("menu.option.0"), containing: "Trakt", "Trakt is the first source")
        shot("watchlist chooser")
        element("menu.option.0").tap()
        requireLabel(require("menu.message", timeout: 15, "the add's message"), containing: "Added", "the movie went on the watchlist")
        shot("added")

        // A fresh launch, whose menus know nothing yet: the card's first long press already offers Remove (the screen
        // loads the watchlist once, ahead of the menus).
        launchDev(arguments: ["--dev-server", Self.testServer, "--dev-trackers", fakeTrackers, "--dev-trackers-connected"])
        require("home.screen", timeout: 60, "after the relaunch")
        require("nav.search", "the Search tab").tap()
        require("search.screen", timeout: 30, "the Search screen")
        card = try movieResult()
        _ = waitUntil(5) { card.isHittable }
        openMenu(on: card)
        require("menu.watchlist_remove", timeout: 10, "the first menu after a relaunch offers Remove from Watchlist")
        shot("first menu on the watchlist")
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.02, dy: 0.5)).tap()
        _ = element("menu.watchlist_remove").waitForNonExistence(timeout: 5)

        openMenu(on: card)
        require("menu.watchlist_remove", timeout: 10, "the reopened menu offers Remove from Watchlist")
        element("menu.watchlist_remove").tap()
        requireLabel(require("menu.option.0", "the chooser again"), containing: "Remove", "Trakt's entry removes it")
        element("menu.option.0").tap()
        requireLabel(require("menu.message", timeout: 15, "the removal's message"), containing: "Removed", "the movie left the watchlist")

        openMenu(on: card)
        require("menu.rate", timeout: 10, "Rate").tap()
        require("ratingSheet", timeout: 15, "Rate opens the rating sheet")
        let trakt = require("ratingSheet.row.trakt", "the sheet's Trakt row")
        require("ratingSheet.row.simkl", "the sheet's Simkl row")
        // The sheet's presentation ends with nothing to wait on before the shot.
        sleep(2)
        shot("rating sheet")
        let unrated = trakt.value as? String ?? ""
        trakt.coordinate(withNormalizedOffset: CGVector(dx: 0.75, dy: 0.5)).tap()
        _ = waitUntil(5) { (trakt.value as? String ?? "") != unrated }
        shot("rated")
        dismissSheet(element("ratingSheet"), close: "ratingSheet.close")
        requireGone("ratingSheet", timeout: 10, "the sheet closes")

        card.tap()
        let button = require("detail.watchlist", timeout: 30, "the detail's watchlist button")
        requireLabel(button, containing: "Add", "not on any watchlist")
        XCTAssertTrue(button.wait(for: \.isEnabled, toEqual: true, timeout: 15), "the watchlists load and the button can be pressed")
        button.tap()
        requireLabel(require("detail.watchlist.option.1", timeout: 10, "the detail's chooser"), containing: "Simkl", "Simkl is the second source")
        shot("detail chooser")
        element("detail.watchlist.option.1").tap()
        requireGone("detail.watchlist.option.1", timeout: 10, "the chooser closes")
        requireLabel(element("detail.watchlist"), containing: "Remove", "the movie is on a watchlist now")
        shot("detail on watchlist")

        let log = request("/_log", method: "GET")
        let json = try XCTUnwrap(log.body.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] }, "the fake's log")
        let watchlist = (json["watchlistWrites"] as? [[String: Any]] ?? []).map { "\($0["service"] ?? "") \($0["op"] ?? "")" }
        XCTAssertEqual(watchlist, ["trakt add", "trakt remove", "simkl add"], "the fake's watchlist writes")
        let ratings = (json["ratingWrites"] as? [[String: Any]] ?? []).compactMap { $0["service"] as? String }
        XCTAssertEqual(ratings, ["trakt"], "the fake's rating writes")
    }

    /// Subtitled Movie's Search result, the keyboard gone (Home's shelves hold it only while it is among the newest).
    private func movieResult() throws -> XCUIElement {
        search("Subtitled Movie")
        let result = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'search.result.' AND label == 'Subtitled Movie'")).firstMatch
        if !result.exists(within: 30) { fail("Search lists no Subtitled Movie") }
        let hide = app.keyboards.buttons["Hide keyboard"]
        if hide.exists {
            hide.tap()
        } else {
            // The keyboard's own Search key, as a user does: on the iPhone Duo a Return typed by the test leaves the
            // keyboard up once the field lets go, which the key the keyboard shows doesn't.
            let search = app.keyboards.buttons["Search"]
            if search.exists(within: 5) { search.tap() } else { fail("the keyboard shows no Search key") }
        }
        if !app.keyboards.firstMatch.waitForNonExistence(timeout: 5) { fail("the keyboard stays") }
        // The results lay out again as the keyboard leaves, with nothing to wait on.
        Thread.sleep(forTimeInterval: 1)
        return result
    }

    private func openMenu(on target: XCUIElement) {
        target.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4)).press(forDuration: 1.0)
    }
    #endif

    /// A tap or a click; on Apple TV Select on what has focus.
    private func press(_ target: XCUIElement) {
        #if os(macOS)
        target.click()
        #elseif os(tvOS)
        XCUIRemote.shared.press(.select)
        #else
        target.tap()
        #endif
    }

    /// A question's answer `id`: on Apple TV focused first (the alert's buttons side by side, Cancel focused first; the
    /// focus is on the button around the identified one), then taken with Select.
    private func press(answer id: String) {
        let target = element(id)
        #if os(tvOS)
        let button = app.buttons.matching(NSPredicate(format: "label == %@", target.label)).firstMatch
        let held = { self.holdsFocus(target) || button.hasFocus }
        _ = waitUntil(1) { held() }
        for direction in [XCUIRemote.Button.right, .left, .down, .up] {
            for _ in 0..<2 where !held() {
                XCUIRemote.shared.press(direction)
                _ = waitUntil(0.5) { held() }
            }
        }
        if !held() { fail("\(id) never takes focus; focus is on \(focusedId ?? "nothing")") }
        XCUIRemote.shared.press(.select)
        #else
        press(target)
        #endif
    }

    /// Back to the app where a sign-in opened its link in the browser (touch and the pointer: not on Apple TV).
    private func backToApp() {
        #if !os(tvOS)
        app.activate()
        #endif
    }

    /// A shot once the screen's transition has ended.
    private func settledShot(_ name: String) {
        Thread.sleep(forTimeInterval: 1)
        shot(name)
    }

    /// A shot of `id` while it is still up (a sign-in the fake approved while the test was in the browser has closed).
    private func shotIfShown(_ id: String, _ name: String) {
        // The app comes back from the browser with nothing to wait on before the shot.
        Thread.sleep(forTimeInterval: 1)
        if element(id).exists { shot(name) }
    }

    /// Settings' Services row, then Services. A development session makes its shell anew once its profile is active
    /// (`SessionShell`), a moment after Settings first shows: a press on the first shell's row goes nowhere, and the
    /// row of the new one is pressed again.
    private func openServices() {
        select("settings.row.services", "Settings lists Services")
        if !element("services.screen").exists(within: 8) {
            select("settings.row.services", "Settings still lists Services")
        }
        require("services.screen", "Services opens")
    }

    /// A tap, a click, or on Apple TV Down (else Up) to the element, then Select.
    private func select(_ id: String, _ what: String) {
        let target = require(id, what)
        #if os(tvOS)
        if focusedId?.hasPrefix("nav.") == true { XCUIRemote.shared.press(.right) }
        for button in [XCUIRemote.Button.down, .up] {
            for _ in 0..<12 where !holdsFocus(target) {
                XCUIRemote.shared.press(button)
                _ = waitUntil(0.4) { holdsFocus(target) }
            }
        }
        if !holdsFocus(target) { fail("\(what): the remote doesn't reach \(id); focus is on \(focusedId ?? "nothing")") }
        XCUIRemote.shared.press(.select)
        #elseif os(macOS)
        target.click()
        #else
        target.tap()
        #endif
    }

    /// The confirmation's Disconnect.
    private func confirmDisconnect() {
        press(answer: "trackerSettings.disconnect.confirm")
    }

    #if os(tvOS)
    private var focused: XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "hasFocus == true")).firstMatch
    }

    private var focusedId: String? {
        (try? focused.snapshot())?.identifier
    }

    /// The element or the focused form row around it has focus.
    private func holdsFocus(_ target: XCUIElement) -> Bool {
        guard let snapshot = try? target.snapshot() else { return false }
        if snapshot.hasFocus { return true }
        guard let here = try? focused.snapshot(), !here.frame.isEmpty else { return false }
        return here.frame.insetBy(dx: -4, dy: -4).contains(snapshot.frame)
    }
    #endif

    /// POSTs `path` to the fake tracker server (`/_config?…`, `/_reset`); fails the test unless it answers 2xx.
    private func postToFake(_ path: String) {
        let answer = request(path, method: "POST")
        if !(200..<300).contains(answer.status ?? 0) {
            fail("the fake answered POST \(path) with \(answer.status.map(String.init) ?? answer.error ?? "nothing")")
        }
    }

    /// Sends `method` `path` to the test's run on the fake tracker server and waits for its answer.
    private func request(_ path: String, method: String) -> FakeAnswer {
        var request = URLRequest(url: URL(string: fakeTrackers + path)!, timeoutInterval: 10)
        request.httpMethod = method
        let answer = FakeAnswer()
        URLSession.shared.dataTask(with: request) { data, response, error in
            answer.status = (response as? HTTPURLResponse)?.statusCode
            answer.body = data
            answer.error = error.map { "\($0)" }
            answer.done.signal()
        }.resume()
        answer.done.wait()
        return answer
    }

    private func requireGone(_ id: String, timeout: TimeInterval, _ what: String) {
        let gone = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: element(id))
        if XCTWaiter.wait(for: [gone], timeout: timeout) != .completed { fail("\(what): \(id) still there after \(Int(timeout)) s") }
    }

    private func requireLabel(_ target: XCUIElement, containing text: String, _ what: String) {
        let shows = expectation(for: NSPredicate(format: "label CONTAINS %@", text), evaluatedWith: target)
        if XCTWaiter.wait(for: [shows], timeout: 30) != .completed { fail("\(what): the label is \"\(target.label)\"") }
    }
}

/// The fake's answer to one request, filled in on URLSession's queue before `done` is signalled.
private final class FakeAnswer: @unchecked Sendable {
    let done = DispatchSemaphore(value: 0)
    var status: Int?
    var error: String?
    var body: Data?
}
