import XCTest

/// The first run as a user meets it (`--dev-entry boot`: fresh data, the sign-in): Connect to Jellyfin, the test
/// server's URL, Find server, its user and password, Sign in, then Home with the server's hubs. On Apple TV Quick
/// Connect starts by itself once the server is found: it is cancelled and the form filled in. `--dev-plex fixture`
/// shows Plex's QR code with the code to enter at plex.tv/link (`expired`: the code expires at once). Past the sign-in
/// (a session signed in by `--dev-server`): on iPhone a second profile borrows
/// the first one's connection and the picker switches to it, a profile with a PIN asks for it (a wrong one is refused),
/// a profile's detail lists its connections and edits one, Settings adds a Plex account, and an offline device offers
/// Reconnect; on Apple TV the PIN's keypad.
final class OnboardingTests: PlezyUITestCase {
    /// The Jellyfin test server; on the Mac through the run's loopback tunnel, the app having no Local Network access
    /// there.
    #if os(macOS)
    private static let server = "http://127.0.0.1:28096"
    #else
    private static let server = "http://192.168.0.15:28096"
    #endif
    private static let user = "maestro"
    private static let password = "maestro"
    /// The same server and user signed in at the launch (`--dev-server`).
    private static let devServer = ["--dev-server", "jellyfin=\(user):\(password)@\(server)"]
    /// The Emby test server, a second connection for the same profile.
    private static let embyServer = ["--dev-server", "emby=\(user):\(password)@http://192.168.0.15:28097"]

    func testJellyfinSignIn() {
        launchDev(arguments: ["--dev-entry", "boot"])
        signInToJellyfin()
        // Home shows the server's libraries' hubs once their first page comes.
        let hub = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'hub.'")).firstMatch
        if !hub.exists(within: 60) { fail("Home shows none of the server's hubs") }
        // The hubs' artwork comes from the network, with no element marking it loaded.
        sleep(2)
        #if os(iOS)
        // AutoFill's Save Password? can come late, over Home.
        _ = waitUntil(5) { dismissSavePassword() }
        #endif
        shot("home hubs")
    }

    /// Show QR Code: the QR code with "plex.tv/link" and the short code to enter there, large, and the waiting line;
    /// Retry and Cancel one height (on Apple TV each measured at rest: focus grows the focused one).
    func testPlexQrCode() {
        launchDev(arguments: ["--dev-entry", "boot", "--dev-plex", "fixture"])
        let qr = require("signin.qr", timeout: 60, "the sign-in's Show QR Code")
        if !waitUntil(20, { qr.isEnabled }) { fail("Show QR Code stays disabled") }
        shot("sign-in")
        activate("signin.qr", "Show QR Code")
        require("signin.qrcode", timeout: 30, "the QR code, once its link is made")
        XCTAssertEqual(text(require("signin.link", "where to enter the code")), "plex.tv/link")
        XCTAssertEqual(text(require("signin.code", "the code to enter")), "6TWW", "the short PIN's code")
        require("signin.waiting", "the waiting line")
        let retry = require("signin.retry", "Retry")
        let cancel = require("signin.cancel", "Cancel")
        #if os(tvOS)
        requireFocus("signin.retry", "Retry, focused as the QR page shows")
        let cancelHeight = cancel.frame.height
        press(.right)
        requireFocus("signin.cancel", "Cancel, right of Retry")
        // Retry shrinks back from its focus a moment after Cancel takes it.
        _ = waitUntil(5) { abs(retry.frame.height - cancelHeight) <= 2 }
        shot("plex qr code cancel focused")
        // A prominent platter rests 2 pt taller than a glass one on Apple TV (68 against 66 pt).
        XCTAssertEqual(retry.frame.height, cancelHeight, accuracy: 2, "Retry and Cancel one height at rest")
        press(.left)
        #else
        XCTAssertEqual(retry.frame.height, cancel.frame.height, accuracy: 1, "Retry and Cancel one height")
        #endif
        XCTAssertEqual(retry.frame.midY, cancel.frame.midY, accuracy: 1, "Retry and Cancel on one line")
        shot("plex qr code")
    }

    /// A code that expires leaves the QR page with the expiry and Retry, the QR code, the code and the waiting line
    /// gone; Retry's new code expires likewise, the page staying.
    func testPlexQrCodeExpires() {
        launchDev(arguments: ["--dev-entry", "boot", "--dev-plex", "expired"])
        let qr = require("signin.qr", timeout: 60, "the sign-in's Show QR Code")
        if !waitUntil(20, { qr.isEnabled }) { fail("Show QR Code stays disabled") }
        activate("signin.qr", "Show QR Code")
        let expiry = require("signin.error", timeout: 30, "the expiry")
        _ = element("signin.qrcode").waitForNonExistence(timeout: 5)
        shot("plex qr code expired")
        XCTAssertFalse(element("signin.qrcode").exists, "no QR code of an expired code")
        XCTAssertLessThanOrEqual(expiry.frame.maxY, require("signin.retry", "Retry").frame.minY, "the expiry before Retry")
        XCTAssertFalse(element("signin.code").exists, "no expired code")
        XCTAssertFalse(element("signin.waiting").exists, "no waiting line once expired")
        XCTAssertFalse(element("signin.qr").exists, "the QR page stays: no sign-in buttons")
        activate("signin.retry", "Retry")
        // The first expiry goes before the new code's comes.
        _ = waitUntil(5) { !element("signin.error").exists }
        require("signin.error", timeout: 30, "the expiry again after Retry's new code expires")
        XCTAssertFalse(element("signin.qr").exists, "still the QR page after Retry")
    }

    #if os(iOS)
    func testSecondProfileBorrowsAndSwitches() {
        // Settings is the session's destination, so the app enters there once signed in.
        launchDev(arguments: ["--dev-entry", "boot", "--dev-open", "settings"])
        signInToJellyfin(chrome: "settings.screen")
        openProfiles()
        require("picker.tile.0", "the picker's first profile")
        activate("picker.add", "Add profile")
        type("Guest", into: "addprofile.name", "the new profile's name")
        activate("addprofile.continue", "Continue")
        activate("addconnection.option.3", "Borrow from another profile")
        activate("borrow.option.0", "the first profile's connection")
        require("picker.tile.1", timeout: 30, "the picker's second profile once the connection is borrowed")
        let guest = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'picker.tile.' AND label CONTAINS 'Guest'")).firstMatch
        if !guest.exists(within: 10) { fail("no Guest tile in the picker") }
        shot("picker two profiles")
        guest.tap()
        require("settings.screen", timeout: 30, "Settings once Guest is the active profile")
        let summary = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS 'active: Guest'")).firstMatch
        if !summary.exists(within: 10) { fail("Settings → Profiles doesn't name Guest as the active profile") }
        shot("settings guest active")
    }

    /// A new profile with PIN 1234 borrows the first one's connection; picking it asks for its PIN, refuses 0000 and
    /// switches with 1234.
    func testPinProtectedProfile() {
        launchDev(arguments: Self.devServer + ["--dev-open", "settings"])
        require("settings.screen", timeout: 60, "Settings")
        openProfiles()
        activate("picker.add", "Add profile")
        type("Kid", into: "addprofile.name", "the new profile's name")
        activate("profile.pin.set", "Set PIN")
        enterPin("1234", "the new PIN")
        // The PIN is asked a second time to confirm it, on an empty pad.
        _ = waitUntil(3) { element("pin.entered").label == "0/4" }
        enterPin("1234", "the new PIN again")
        requireGone("pin.dialog", "the PIN dialog once the PIN is set")
        require("profile.pin.change", "PIN set, with Change")
        shot("add profile pin set")
        activate("addprofile.continue", "Continue")
        activate("addconnection.option.3", "Borrow from another profile")
        activate("borrow.option.0", "the first profile's connection")
        let kid = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'picker.tile.' AND label CONTAINS 'Kid'")).firstMatch
        if !kid.exists(within: 30) { fail("no Kid tile in the picker") }
        shot("picker with pin profile")
        kid.tap()
        require("pin.dialog", "the PIN dialog for Kid")
        enterPin("0000", "a wrong PIN")
        if !waitUntil(10, { !element("pin.error").label.trimmingCharacters(in: .whitespaces).isEmpty }) {
            fail("the wrong PIN shows no error")
        }
        shot("wrong pin")
        enterPin("1234", "Kid's PIN")
        require("settings.screen", timeout: 30, "Settings once Kid is the active profile")
        let summary = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS 'active: Kid'")).firstMatch
        if !summary.exists(within: 10) { fail("Settings → Profiles doesn't name Kid as the active profile") }
        // Manage Libraries keeps its place through the switch, not seconds later once Kid's libraries load.
        let manage = element("settings.row.manage_libraries")
        if !manage.exists(within: 2) { fail("Manage Libraries is missing right after the switch to Kid") }
        shot("settings kid active")
    }

    /// Settings → General's "ask for a profile on open", switched on once a second profile exists, makes the next start
    /// show the picker, the launch's sign-in waiting for the pick; the picked profile then opens Home with the server's
    /// hubs. The session's data is kept between the launches (`--dev-data`). The picker from Settings' Manage profiles
    /// row is titled Manage profiles, from the profile card Switch Profile, Manage under each tile in both; the start's
    /// asks "Who's watching?", with no Manage.
    func testAskForProfileOnOpen() {
        let data = ["--dev-data", "askprofile\(Int(Date().timeIntervalSince1970))"]
        launchDev(arguments: Self.devServer + data + ["--dev-open", "settings"])
        require("settings.screen", timeout: 60, "Settings")
        openProfiles()
        activate("picker.add", "Add profile")
        type("Guest", into: "addprofile.name", "the new profile's name")
        activate("addprofile.continue", "Continue")
        activate("addconnection.option.3", "Borrow from another profile")
        activate("borrow.option.0", "the first profile's connection")
        require("picker.tile.1", timeout: 30, "the picker's second profile")
        // The title in the navigation bar: the hub beside it (iPad) shows the row and the card's own words too.
        if !app.navigationBars.staticTexts["Manage profiles"].exists(within: 10) { fail("the picker from Manage profiles isn't titled Manage profiles") }
        XCTAssertFalse(app.staticTexts["Who's watching?"].exists, "the picker from Settings doesn't ask who's watching")
        require("picker.tile.1.manage", "Manage under the second profile")
        // The push's animation settles before the shot.
        sleep(1)
        shot("picker from manage profiles")
        // Back to the hub where the picker covers it (iPhone); on iPad the hub's list stays beside it.
        if backButton.exists { backButton.tap() }
        // The hub keeps where it was scrolled to (down at Manage profiles); the card is its first row.
        for _ in 0..<8 where !element("settings.profile.switch").exists(within: 2) { app.swipeDown() }
        activate("settings.profile.switch", "the profile card")
        require("picker.tile.1", timeout: 30, "the picker from the profile card")
        if !app.navigationBars.staticTexts["Switch Profile"].exists(within: 10) { fail("the picker from the profile card isn't titled Switch Profile") }
        XCTAssertFalse(app.navigationBars.staticTexts["Manage profiles"].exists, "the picker from the profile card isn't titled Manage profiles")
        require("picker.tile.1.manage", "Manage under the second profile")
        // The push's animation settles before the shot.
        sleep(1)
        shot("picker from profile card")
        app.terminate()

        launchDev(arguments: Self.devServer + data + ["--dev-open", "settings"])
        require("settings.screen", timeout: 60, "Settings again")
        activate("settings.row.general", "Settings → General")
        let ask = require("settings.row.require_profile_selection_on_open", timeout: 20, "Ask for profile on app open")
        activate("settings.row.require_profile_selection_on_open", "Ask for profile on app open")
        let on = { (ask.value as? String) == "1" || (ask.value as? NSNumber)?.intValue == 1 }
        #if os(iOS)
        // A tap on the switch's middle can miss its knob: then on its right half.
        if !waitUntil(3, on) { ask.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.5)).tap() }
        #endif
        if !waitUntil(10, on) { fail("the switch stays off") }
        shot("ask for profile on")
        app.terminate()

        launchDev(arguments: Self.devServer + data + ["--dev-entry", "boot"])
        require("picker.tile.1", timeout: 60, "the picker at the start")
        if !app.staticTexts["Who's watching?"].exists(within: 10) { fail("the start's picker doesn't ask who's watching") }
        XCTAssertFalse(element("picker.tile.0.manage").exists, "the start's picker offers no Manage")
        shot("picker on open")
        activate("picker.tile.0", "the first profile")
        require("home.screen", timeout: 60, "Home once a profile is picked")
        let hub = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'hub.'")).firstMatch
        if !hub.exists(within: 60) { fail("Home shows none of the server's hubs after the pick") }
        shot("home after pick")
    }

    /// Manage opens the profile's detail with its connection; the connection's Edit shows its URLs, and Save keeps them.
    func testProfileDetailAndEditConnection() {
        launchDev(arguments: Self.devServer + ["--dev-open", "settings"])
        require("settings.screen", timeout: 60, "Settings")
        openProfiles()
        activate("picker.tile.0.manage", "the profile's Manage")
        require("profile.screen", "the profile's detail")
        require("profile.connection.0", timeout: 30, "the profile's connection")
        shot("profile detail")
        activate("profile.connection.0.menu", "the connection's menu")
        tapMenuEntry(of: "profile.connection.0.menu", "Edit")
        let urls = require("editconnection.urls", "the connection's URLs")
        if !waitUntil(10, { (urls.value as? String ?? "").contains("28096") }) { fail("the URLs field doesn't hold the server's URL") }
        shot("edit connection")
        activate("editconnection.save", "Save")
        requireGone("editconnection.screen", timeout: 30, "Save closes the connection's URLs")
        require("profile.connection.0", "the profile's detail again")
        shot("profile detail after save")
    }

    /// Settings → Add connection → Sign in with Plex, then Show QR Code: the recorded plex.tv makes the link. The
    /// session has no server (the recorded plex.tv refuses every other host).
    func testAddPlexAccount() {
        launchDev(arguments: ["--dev-open", "settings", "--dev-plex", "fixture"])
        require("settings.screen", timeout: 60, "Settings")
        activate("settings.row.add_connection", "Settings → Add connection")
        activate("addconnection.option.0", "Sign in with Plex")
        let qr = require("signin.qr", timeout: 60, "Add Plex account's Show QR Code")
        if !waitUntil(20, { qr.isEnabled }) { fail("Show QR Code stays disabled") }
        shot("add plex account")
        activate("signin.qr", "Show QR Code")
        require("signin.qrcode", timeout: 30, "the QR code, once its link is made")
        shot("add plex qr code")
    }

    /// A device held offline offers Reconnect; pressing it tries, and says how that went. The session goes offline once
    /// signed in: Home shows before the launch's sign-in ends, its hubs once the profile is bound to the server, and a
    /// sign-in held offline would end the launch.
    func testReconnect() {
        launchDev(arguments: Self.devServer)
        require("home.screen", timeout: 60, "Home")
        let hub = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'hub.'")).firstMatch
        if !hub.exists(within: 60) { fail("Home shows none of the server's hubs") }
        changeDevSetting("offline=true")
        let reconnect = require("offline.reconnect", timeout: 60, "Reconnect while offline")
        shot("offline")
        reconnect.tap()
        let message = element("shell.reconnect.message")
        let spinner = app.activityIndicators.firstMatch
        if !waitUntil(30, { spinner.exists || message.exists }) { fail("Reconnect shows neither a spinner nor a message") }
        shot("reconnecting")
        if !message.exists(within: 60) { fail("Reconnect says nothing of how it went") }
        shot("reconnect message")
    }

    /// The picker's tile offers Manage as a button under it and its other actions in its menu, a long press on the tile
    /// (the dev profile is local: Show profile link, Delete), and each does what it says: Manage opens the profile's
    /// detail, Show profile link its link, Delete asks first.
    func testProfileTileMenu() {
        launchDev(arguments: Self.devServer + ["--dev-open", "settings"])
        require("settings.screen", timeout: 60, "Settings")
        openProfiles()
        activate("picker.tile.0.manage", "the profile's Manage")
        require("profile.screen", "Manage opens the profile's detail")
        backButton.tap()
        require("picker.tile.0", "the picker again")
        openTileMenu()
        for label in ["Show profile link", "Delete"] {
            if !menuEntry(of: "picker.tile.0.menu", label).exists(within: 10) { fail("the tile's context menu has no \(label)") }
        }
        if menuEntry(of: "picker.tile.0.menu", "Manage").exists { fail("the tile's menu repeats Manage, its button") }
        shot("picker context menu")
        tapMenuEntry(of: "picker.tile.0.menu", "Show profile link")
        require("picker.link", timeout: 10, "Show profile link opens the link")
        shot("profile link")
        activate("picker.link.close", "Close")
        requireGone("picker.link", timeout: 10, "Close closes the link")
        openTileMenu()
        tapMenuEntry(of: "picker.tile.0.menu", "Delete")
        require("confirm.ok", timeout: 10, "Delete asks first")
        shot("delete profile asks")
        activate("confirm.cancel", "Cancel")
        require("picker.tile.0", "the profile, kept")
    }

    /// The tile's menu, opened with a long press, closes on a tap outside it, as the system's menus do.
    func testProfileTileMenuClosesOnATapOutside() {
        launchDev(arguments: Self.devServer + ["--dev-open", "settings"])
        require("settings.screen", timeout: 60, "Settings")
        openProfiles()
        openTileMenu()
        shot("tile menu open")
        app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8)).tap()
        if !waitUntil(5, { !menuEntry(of: "picker.tile.0.menu", "Show profile link").exists }) {
            fail("a tap outside leaves the tile's menu open")
        }
        shot("tile menu closed")
        require("picker.tile.0", "the picker under the menu")
    }

    /// A profile with a second connection (the Emby test server): its tile names both connections, a line each; the
    /// detail's Make default on the one that isn't the default makes it so (its menu then has no Make default), and
    /// Delete profile asks first.
    func testMakeDefaultAndDeleteProfile() {
        launchDev(arguments: Self.devServer + Self.embyServer + ["--dev-open", "settings"])
        require("settings.screen", timeout: 60, "Settings")
        openProfiles()
        let tile = require("picker.tile.0", timeout: 20, "the picker's profile")
        if !waitUntil(30, { tile.label.contains("Plezy Test Jellyfin") && tile.label.contains("Plezy Test Emby") }) {
            fail("the profile's tile doesn't name both connections: \(tile.label)")
        }
        shot("picker two connections")
        activate("picker.tile.0.manage", "the profile's Manage")
        require("profile.connection.1", timeout: 60, "the profile's second connection")
        shot("profile detail two connections")
        // The connection that isn't the default (its row doesn't say Default): its menu offers Make default.
        let rows = (0..<2).map { element("profile.connection.\($0)") }
        guard let index = rows.firstIndex(where: { !$0.label.contains("Default") }) else {
            return fail("both connections say Default")
        }
        let probe = "profile.connection.\(index).menu"
        // The default comes first: the rows follow the connection, not their place.
        let name = rows[index].label
        activate(probe, "connection \(index)'s menu")
        shot("make default menu")
        tapMenuEntry(of: probe, "Make default")
        let isDefault = { (row: XCUIElement) in row.label.hasPrefix(name) && row.label.contains("Default") }
        if !waitUntil(20, { rows.contains(where: isDefault) }) { fail("Make default leaves \(name) not the default") }
        if rows.filter({ $0.label.contains("Default") }).count != 1 { fail("not exactly one connection says Default") }
        shot("made default")
        activate("profile.delete", "Delete profile")
        require("confirm.ok", timeout: 10, "Delete profile asks first")
        shot("delete profile confirm")
        activate("confirm.cancel", "Cancel")
        require("profile.screen", "the profile, kept")
    }
    #endif

    #if os(tvOS)
    /// Set PIN on a new profile opens the PIN's keypad, focus on its 1, which shows it; Menu closes it.
    func testPinKeypad() {
        launchDev(arguments: Self.devServer + ["--dev-open", "settings"])
        require("settings.screen", timeout: 60, "Settings")
        openProfiles()
        activate("picker.add", "Add profile")
        type("Kid", into: "addprofile.name", "the new profile's name")
        activate("profile.pin.set", "Set PIN")
        require("pin.dialog", "the PIN dialog")
        requireFocus("pin.digit.1", "the pad's 1 takes focus")
        requireFocusShows(on: element("pin.digit.1"), beside: element("pin.digit.5"), "the pad's focused 1")
        shot("pin keypad")
        press(.menu)
        requireGone("pin.dialog", "Menu closes the PIN dialog")
    }

    /// A new profile's PIN set with the remote, twice to confirm it: once the pad closes, focus is on the PIN row's
    /// Change (where Set PIN was), drawn focused beside Remove, as Remove is beside Change once Right moves there; Down
    /// from the row reaches Continue, and Select there goes on to the connection's choice.
    func testPinThenContinue() {
        launchDev(arguments: Self.devServer + ["--dev-open", "settings"])
        require("settings.screen", timeout: 60, "Settings")
        openProfiles()
        activate("picker.add", "Add profile")
        type("Kid", into: "addprofile.name", "the new profile's name")
        activate("profile.pin.set", "Set PIN")
        for round in ["the new PIN", "the new PIN again"] {
            require("pin.dialog", round)
            // The PIN is asked a second time on an empty pad.
            _ = waitUntil(3) { element("pin.entered").label == "0/4" }
            for digit in "1234" { activate("pin.digit.\(digit)", "\(round): the key \(digit)") }
        }
        requireGone("pin.dialog", "the PIN dialog once the PIN is set")
        require("profile.pin.change", "PIN set, with Change")
        requireFocus("profile.pin.change", "the pad closing gives focus back to the PIN row")
        requireFocusShows(on: element("profile.pin.change"), beside: element("profile.pin.remove"), "the focused Change")
        shot("pin set focus")
        press(.right)
        requireFocus("profile.pin.remove", "Right from Change reaches Remove")
        requireFocusShows(on: element("profile.pin.remove"), beside: element("profile.pin.change"), "the focused Remove")
        shot("pin remove focus")
        press(.left)
        requireFocus("profile.pin.change", "Left from Remove goes back to Change")
        // Down, as a remote user goes: the rows below lie across the form from Change, at its trailing end.
        for _ in 0..<3 where !holdsFocus("addprofile.continue") { press(.down) }
        requireFocus("addprofile.continue", "Down from the PIN row reaches Continue")
        press(.select)
        require("addconnection.option.3", timeout: 10, "Continue goes on to the connection's choice")
        shot("after continue")
    }

    /// Manage under the focused tile opens the profile's detail; the tile's context menu, a long press of Select on it,
    /// offers its other actions (the dev profile is local: Show profile link, Delete). The profile has two connections,
    /// whose names under the tile once made it too tall for the menu.
    func testProfileTileMenu() {
        launchDev(arguments: Self.devServer + Self.embyServer + ["--dev-open", "settings"])
        require("settings.screen", timeout: 60, "Settings")
        openProfiles()
        require("picker.tile.0", timeout: 20, "the picker's profile")
        requireFocus("picker.tile.0", "the picker's first tile takes focus")
        XCUIRemote.shared.press(.select, forDuration: 1.5)
        for label in ["Show profile link", "Delete"] {
            if !menuEntry(of: "picker.tile.0.menu", label).exists(within: 10) { fail("the tile's context menu has no \(label)") }
        }
        shot("picker context menu")
        press(.menu)
        walkFocus(to: "picker.tile.0.manage", "Manage under the tile")
        press(.select)
        require("profile.screen", timeout: 10, "Manage opens the profile's detail")
    }

    /// Ask for a profile on open with two profiles: the start's picker gives its first tile focus, and picking it, after
    /// more than 4 s on the picker, hands focus to Home's first card, not leaving it nowhere or on the tab bar.
    func testPickerFocusAfterSwitch() {
        let data = ["--dev-data", "tvpick\(Int(Date().timeIntervalSince1970))"]
        launchDev(arguments: Self.devServer + data + ["--dev-open", "settings"])
        require("settings.screen", timeout: 60, "Settings")
        openProfiles()
        activate("picker.add", "Add profile")
        type("Guest", into: "addprofile.name", "the new profile's name")
        activate("addprofile.continue", "Continue")
        activate("addconnection.option.3", "Borrow from another profile")
        activate("borrow.option.0", "the first profile's connection")
        require("picker.tile.1", timeout: 30, "the picker's second profile")
        app.terminate()

        launchDev(arguments: Self.devServer + data + ["--dev-open", "settings"])
        require("settings.screen", timeout: 60, "Settings again")
        activate("settings.row.general", limit: 40, "Settings → General")
        let ask = require("settings.row.require_profile_selection_on_open", timeout: 20, "Ask for profile on app open")
        activate("settings.row.require_profile_selection_on_open", limit: 40, "Ask for profile on app open")
        let on = { (ask.value as? String) == "1" || (ask.value as? NSNumber)?.intValue == 1 }
        if !waitUntil(10, on) { fail("the switch stays off") }
        app.terminate()

        launchDev(arguments: Self.devServer + data + ["--dev-entry", "boot"])
        require("picker.tile.1", timeout: 60, "the picker at the start")
        requireFocus("picker.tile.0", "the start's picker gives its first tile focus")
        shot("picker first focus")
        // Longer than a first focus's own 4 s of trying: Home's waits for the picker to go, however long it stays.
        sleep(6)
        press(.select)
        let home = require("home.screen", timeout: 60, "Home once a profile is picked")
        let inSession = waitUntil(15) {
            guard let here = try? focused.snapshot(), let screen = try? home.snapshot() else { return false }
            let bar = app.tabBars.firstMatch
            let onBar = bar.exists && bar.frame.intersects(here.frame)
            return !onBar && screen.frame.intersects(here.frame) && here.identifier.hasPrefix("card.")
        }
        shot("home focus after pick")
        if !inSession { fail("after the pick focus is on \(focusedId ?? "nothing"), not on Home's first card") }
    }
    #endif

    #if !os(macOS)
    /// With "ask for a profile on open" and a second profile, a return to the app shows the picker over the open player,
    /// which stays up and paused under it: Apple TV's Play/Pause doesn't start it. Picking the same profile leaves the
    /// player paused. On iPhone the video is paused before the app leaves (a playing one goes to picture in picture, and
    /// a video that stayed in sight asks for no profile). The video is `PLEZY_MEDIA_URL`, else Apple's public HLS sample.
    func testProfilePickerOverTheOpenPlayer() throws {
        let data = ["--dev-data", "pickerhold\(Int(Date().timeIntervalSince1970))"]
        launchDev(arguments: Self.devServer + data + ["--dev-open", "settings"])
        require("settings.screen", timeout: 60, "Settings")
        openProfiles()
        activate("picker.add", "Add profile")
        type("Guest", into: "addprofile.name", "the new profile's name")
        activate("addprofile.continue", "Continue")
        activate("addconnection.option.3", "Borrow from another profile")
        activate("borrow.option.0", "the first profile's connection")
        require("picker.tile.1", timeout: 30, "the picker's second profile")
        app.terminate()

        let media = ProcessInfo.processInfo.environment["PLEZY_MEDIA_URL"]
            ?? "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8"
        launchDev(arguments: Self.devServer + data + ["--dev-setting", "require_profile_selection_on_open=true", "--url", media])
        let nowPlaying = require("player.nowPlaying", timeout: 60, "the player's Now Playing probe")
        let state = { Self.probeField("state", nowPlaying) }
        let playing = { state() == "playing" && Self.probeField("rate", nowPlaying) == "1.0" }
        if !waitUntil(60, playing) { return fail("the video never played: \(nowPlaying.value ?? "")") }
        shot("playing")
        #if os(iOS)
        let pause = element("player.playPause")
        for _ in 0..<5 where !(pause.exists && pause.isHittable) {
            element("player.video").tap()
            _ = pause.exists(within: 3)
        }
        if !(pause.exists && pause.isHittable) { return fail("the controls never showed Pause") }
        pause.tap()
        if !waitUntil(15, { state() == "paused" }) { return fail("the video didn't pause: \(nowPlaying.value ?? "")") }
        XCUIDevice.shared.press(.home)
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let onHomeScreen = waitUntil(5) { springboard.icons.allElementsBoundByIndex.contains(where: { $0.exists && $0.isHittable }) }
        // Home shows the home screen, the app leaving the screen. On the iPhone Duo's cover the app stays on screen (no
        // home screen icon shows there), so it never leaves and comes back for the picker to show over.
        if !onHomeScreen {
            XCTAssertTrue(element("player.video").exists, "the player stays on screen after Home")
            XCTAssertEqual(state(), "paused", "the paused video stays paused")
            throw XCTSkip("Home leaves the app on screen here: no home screen icon shows")
        }
        #else
        XCUIRemote.shared.press(.home)
        #endif
        // The app stays away a while, so its return counts as one.
        sleep(3)
        app.activate()
        require("picker.tile.1", timeout: 30, "the picker over the player on the return")
        if !element("player.video").exists { fail("the player went from under the picker") }
        // The video must stay paused over a period, not just at one moment.
        sleep(2)
        if state() != "paused" { fail("the video plays under the picker: \(nowPlaying.value ?? "")") }
        shot("picker over the player")
        #if os(tvOS)
        XCUIRemote.shared.press(.playPause)
        // The video must stay paused over a period after the press.
        sleep(3)
        if state() != "paused" { fail("Play/Pause started the video under the picker: \(nowPlaying.value ?? "")") }
        #endif

        activate("picker.tile.0", "the same profile")
        requireGone("picker.tile.0", "the picker once the profile is picked")
        require("player.video", "the player, still up")
        // The video must stay paused over a period after the pick.
        sleep(2)
        if state() != "paused" { fail("the pick started the video: \(nowPlaying.value ?? "")") }
        shot("player paused after the pick")
    }

    /// The Now Playing probe's `<name>=<value>` field (`title=…; state=…; rate=…; …`).
    private static func probeField(_ name: String, _ probe: XCUIElement) -> String {
        for part in (probe.value as? String ?? "").components(separatedBy: "; ") where part.hasPrefix(name + "=") {
            return String(part.dropFirst(name.count + 1))
        }
        return ""
    }
    #endif

    /// The account screens on every platform, signed in to the test server: the picker with a tile's menu open, the
    /// profile's detail (Manage under the tile), Add profile and its PIN pad (Set PIN).
    func testAccountScreensTour() {
        launchDev(arguments: Self.devServer + ["--dev-open", "settings"])
        require("settings.screen", timeout: 60, "Settings")
        openProfiles()
        require("picker.tile.0", timeout: 20, "the picker's profile")
        // The picker's animation settles before the shot.
        sleep(1)
        shot("picker")
        #if os(tvOS)
        requireFocus("picker.tile.0", "the picker's first tile takes focus")
        XCUIRemote.shared.press(.select, forDuration: 1.5)
        #elseif os(macOS)
        require("picker.tile.0", "the picker's profile").rightClick()
        #else
        openTileMenu()
        #endif
        if !menuEntry(of: "picker.tile.0.menu", "Show profile link").exists(within: 10) { fail("the tile's menu has no Show profile link") }
        // The menu's opening animation settles before the shot.
        sleep(1)
        shot("picker menu", of: XCUIScreen.main)
        #if os(tvOS)
        press(.menu)
        walkFocus(to: "picker.tile.0.manage", "Manage under the tile")
        press(.select)
        #elseif os(macOS)
        app.typeKey(.escape, modifierFlags: [])
        require("picker.tile.0.manage", "Manage under the tile").click()
        #else
        // The menu closes as one of its entries is picked: Show profile link, whose link then closes.
        tapMenuEntry(of: "picker.tile.0.menu", "Show profile link")
        activate("picker.link.close", "Close")
        requireGone("picker.link", timeout: 10, "Close closes the link")
        activate("picker.tile.0.manage", "Manage under the tile")
        #endif
        require("profile.connection.0", timeout: 30, "the profile's detail")
        // The push's animation settles before the shot.
        sleep(1)
        shot("profile detail")
        app.terminate()

        launchDev(arguments: Self.devServer + ["--dev-open", "settings"])
        require("settings.screen", timeout: 60, "Settings again")
        openProfiles()
        activate("picker.add", "Add profile")
        require("addprofile.name", "Add profile")
        // The push's animation settles before the shot.
        sleep(1)
        shot("add profile")
        activate("profile.pin.set", "Set PIN")
        require("pin.dialog", "the PIN pad")
        // The PIN pad's animation settles before the shot.
        sleep(1)
        shot("pin pad")
    }

    #if os(macOS)
    /// Escape goes back one screen from the profile's detail pushed over the picker, then from the picker pushed over
    /// Settings, as the toolbar's Back does.
    func testEscapeGoesBackFromTheProfileScreens() {
        launchDev(arguments: Self.devServer + ["--dev-open", "settings"])
        require("settings.screen", timeout: 60, "Settings")
        openProfiles()
        require("picker.tile.0.manage", timeout: 20, "the profile's Manage").click()
        require("profile.connection.0", timeout: 30, "the profile's detail")
        sleep(1)
        app.typeKey(.escape, modifierFlags: [])
        requireGone("profile.screen", timeout: 10, "Escape leaves the profile's detail")
        require("picker.screen", "Escape goes back to the picker")
        shot("escape back to the picker")
        app.typeKey(.escape, modifierFlags: [])
        requireGone("picker.screen", timeout: 10, "Escape leaves the picker")
        require("settings.row.profiles", "Escape goes back to Settings")
        shot("escape back to settings")
    }
    #endif

    /// Settings → Profiles, once the launch's sign-in has ended (Settings offers Manage Libraries once the server's
    /// libraries are in). Until then Settings changes under the press: the profile the sign-in makes active makes the
    /// shell anew (a press is lost with the screen it was on, or fails XCUITest's hittability as that screen goes), and
    /// Manage Libraries comes in above Profiles (a press lands on the row that took Profiles' place).
    private func openProfiles() {
        require("settings.row.manage_libraries", timeout: 60, "Settings once the launch's sign-in has ended")
        #if os(tvOS)
        activate("settings.row.profiles", limit: 40, "Settings → Profiles")
        #else
        activate("settings.row.profiles", "Settings → Profiles")
        #endif
        #if os(iOS)
        // AutoFill's Save Password?, come up after a sign-in, takes the tap that was the row's.
        if !element("picker.screen").exists(within: 10), dismissSavePassword() { activate("settings.row.profiles", "Settings → Profiles") }
        #endif
        require("picker.screen", "Settings → Profiles opens the picker")
    }

    /// From the sign-in to the app's chrome (`chrome`, Home by default) through Connect to Jellyfin.
    private func signInToJellyfin(chrome: String = "home.screen") {
        require("signin.jellyfin", timeout: 60, "the sign-in")
        shot("sign-in")
        activate("signin.jellyfin", "Connect to Jellyfin")
        type(Self.server + "\n", into: "addserver.url", "the server's URL")
        // Return finds the server; on the Mac and iPhone Find server is pressed too where Return didn't.
        let username = element("addserver.username")
        let quickConnect = element("addserver.qc.cancel")
        if !waitUntil(30, { username.exists || quickConnect.exists }) {
            if element("addserver.find").exists { activate("addserver.find", "Find server") }
            if !waitUntil(30, { username.exists || quickConnect.exists }) { fail("Find server doesn't find \(Self.server)") }
        }
        #if os(tvOS)
        if quickConnect.exists(within: 10) {
            shot("quick connect")
            requireFocus("addserver.qc.cancel", "Quick Connect's Cancel takes focus")
            press(.select)
            requireGone("addserver.qc.cancel", "Cancel closes Quick Connect")
        }
        #endif
        require("addserver.username", "the username field")
        type(Self.user, into: "addserver.username", "the username")
        shot("username typed")
        type(Self.password, into: "addserver.password", "the password")
        shot("credentials")
        activate("addserver.signin", "Sign in")
        require(chrome, timeout: 60, "the app after signing in")
        #if os(iOS)
        // AutoFill offers to save the password typed, a moment after the form goes, over the tab bar: not now.
        let tabs = element("nav.home")
        if !waitUntil(40, { _ = dismissSavePassword(); return tabs.exists && !app.buttons["Not Now"].exists }) { fail("the tab bar: no nav.home") }
        #elseif os(tvOS)
        require("nav.home", "the tab bar")
        #else
        let split = app.splitGroups.matching(NSPredicate(format: "identifier CONTAINS 'SidebarNavigationSplitView'")).firstMatch
        if !split.exists(within: 20) { fail("Home isn't in the sidebar's split view") }
        #endif
    }

    /// Presses `id` as each platform does: a tap (swiped into view first while a list hasn't made it yet, or it lies past
    /// the window's foot, under the tab bar or under the software keyboard), a click, or the remote's focus walked there
    /// (at most `limit` presses) and Select.
    private func activate(_ id: String, limit: Int = 12, _ what: String) {
        #if os(iOS)
        // The list scrolled a third of the window and held there (a swipe's fling passes rows on a tall screen).
        func drag(up: Bool) {
            let window = app.windows.firstMatch
            let low = window.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.7))
            let high = window.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.4))
            (up ? low : high).press(forDuration: 0.05, thenDragTo: up ? high : low, withVelocity: .slow, thenHoldForDuration: 0.3)
        }
        // A list makes its rows as they scroll in: on a short screen (the iPhone Duo's cover) a row lies below it.
        if !element(id).exists(within: 15) {
            for _ in 0..<4 where !element(id).exists(within: 3) { drag(up: true) }
        }
        #endif
        let target = require(id, what)
        #if os(tvOS)
        _ = target
        walkFocus(to: id, limit: limit, what)
        press(.select)
        #elseif os(macOS)
        if !waitUntil(10, { target.isHittable }) { fail("\(what): \(id) can't be clicked") }
        target.click()
        #else
        let tabBar = app.tabBars.firstMatch
        let tappable = waitUntil(10) {
            _ = dismissSavePassword()
            guard let frame = (try? target.snapshot())?.frame else { return false }
            // Asked of an element past the window's foot, XCUITest's hittability fails the test rather than answer no.
            if frame.midY > app.frame.maxY {
                app.swipeUp()
                return false
            }
            // Under the floating tab bar along the screen's foot (its Home and Settings side by side), which XCUITest
            // counts as hittable though the bar takes the tap; or scrolled up past the window's top.
            if let home = (try? element("nav.home").snapshot())?.frame, let settings = (try? element("nav.settings").snapshot())?.frame,
               abs(home.midY - settings.midY) < home.height / 2, home.minY > app.frame.midY, frame.midY > home.minY - 8 {
                drag(up: true)
                return false
            }
            if frame.maxY < app.frame.minY + 50 {
                drag(up: false)
                return false
            }
            if target.isHittable { return true }
            // Under a tab bar at the screen's foot.
            if let bar = (try? tabBar.snapshot())?.frame, bar.minY > app.frame.midY, frame.midY > bar.minY { app.swipeUp() }
            // Under the software keyboard, which takes a tap aimed at what lies under it, and which a form as short as the
            // iPhone Duo's cover doesn't scroll past: a tap off the field (the screen's title) puts it away, as in the
            // system's apps.
            if let keyboard = (try? app.keyboards.firstMatch.snapshot())?.frame, frame.midY > keyboard.minY {
                app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.07)).tap()
            }
            return false
        }
        if !tappable { fail("\(what): \(id) can't be tapped") }
        target.tap()
        #endif
    }

    /// The entry `label` of the open menu of `probe` (its entries are `<probe>.<index>`).
    private func menuEntry(of probe: String, _ label: String) -> XCUIElement {
        app.descendants(matching: .any)
                        // A Mac's menu item reads as its title.
            .matching(NSPredicate(format: "identifier BEGINSWITH %@ AND (label == %@ OR title == %@)", "\(probe).", label, label))
            .firstMatch
    }

    #if os(iOS)
    /// Answers AutoFill's Save Password? with Not Now; whether it was up.
    private func dismissSavePassword() -> Bool {
        // In a sheet or in a card over the app, as the system shows it, from the app or from SpringBoard.
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let notNow = [app.buttons["Not Now"].firstMatch, springboard.buttons["Not Now"].firstMatch].first { $0.exists }
            ?? app.buttons["Not Now"].firstMatch
        guard notNow.exists else { return false }
        notNow.tap()
        _ = waitUntil(5) { !notNow.exists }
        return true
    }

    /// Taps the entry `label` of the open menu of the button `probe` (its entries are `<probe>.<index>`), once the
    /// menu's opening animation has stopped moving it (a tap while it grows lands on a neighbour entry).
    private func tapMenuEntry(of probe: String, _ label: String) {
        let entry = menuEntry(of: probe, label)
        if !entry.exists(within: 10) { fail("\(probe)'s menu has no \(label)") }
        var last = CGRect.null
        _ = waitUntil(5) {
            let frame = entry.frame
            defer { last = frame }
            return entry.isHittable && frame == last
        }
        entry.tap()
    }

    /// Opens the first tile's context menu with a long press, once Show profile link, its first entry, shows.
    private func openTileMenu() {
        require("picker.tile.0", timeout: 20, "the picker's profile").press(forDuration: 1.2)
        if !menuEntry(of: "picker.tile.0.menu", "Show profile link").exists(within: 10) {
            fail("a long press on the tile opens no menu with Show profile link")
        }
    }

    /// Taps `pin`'s digits on the PIN pad that is up.
    private func enterPin(_ pin: String, _ what: String) {
        require("pin.dialog", what)
        for digit in pin {
            let key = require("pin.digit.\(digit)", "\(what): the key \(digit)")
            if !waitUntil(5, { key.isHittable }) { fail("\(what): the key \(digit) can't be tapped") }
            key.tap()
        }
    }
    #endif

    /// Types `text` into the field `id`: tapped or clicked first; on Apple TV its keyboard opened with Select, and put
    /// away after.
    private func type(_ text: String, into id: String, _ what: String) {
        let field = require(id, what)
        #if os(tvOS)
        _ = field
        walkFocus(to: id, what)
        press(.select)
        if !app.keyboards.firstMatch.exists(within: 5) { fail("\(what): Select on \(id) opens no keyboard") }
        app.typeText(text)
        let keyboard = app.keyboards.firstMatch
        for _ in 0..<3 where keyboard.exists && !waitUntil(2, { !keyboard.exists }) {
            press(.menu)
        }
        #elseif os(macOS)
        field.click()
        field.typeText(text)
        #else
        // XCUITest's own attribute, which its API doesn't name: the field takes the keys only once it has the focus.
        let focused = { field.value(forKey: "hasKeyboardFocus") as? Bool == true }
        for _ in 0..<3 where !focused() {
            // AutoFill's Save Password? can come up well after a sign-in, over whatever screen is next.
            if !waitUntil(10, { _ = dismissSavePassword(); return field.isHittable }) { fail("\(what): \(id) can't be tapped") }
            field.tap()
            _ = waitUntil(3, focused)
        }
        if !focused() { fail("\(what): \(id) doesn't take the keyboard focus") }
        field.typeText(text)
        #endif
    }

    /// A Mac's text reads as its value, elsewhere as its label.
    private func text(_ element: XCUIElement) -> String {
        element.label.isEmpty ? (element.value as? String ?? "") : element.label
    }

    private func requireGone(_ id: String, timeout: TimeInterval = 10, _ what: String) {
        if !waitUntil(timeout, { !element(id).exists }) { fail("\(what): \(id) still there after \(Int(timeout)) s") }
    }

    #if os(tvOS)
    /// The element that has focus.
    private var focused: XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "hasFocus == true")).firstMatch
    }

    private var focusedId: String? { (try? focused.snapshot())?.identifier }

    /// Whether `id` has focus: the element itself, one inside it, or the focused element around it (a form's row).
    private func holdsFocus(_ id: String) -> Bool {
        guard let target = try? element(id).snapshot() else { return false }
        if target.hasFocus { return true }
        guard let here = try? focused.snapshot() else { return false }
        return here.frame.insetBy(dx: -4, dy: -4).contains(target.frame) && !here.frame.isEmpty
            && here.frame.height < app.frame.height / 2
    }

    private func requireFocus(_ id: String, _ what: String) {
        require(id, what)
        if !waitUntil(5, { holdsFocus(id) }) { fail("\(what): focus is on \(focusedId ?? "nothing"), not \(id)") }
    }

    /// Presses the remote's `button`, then waits for the focus engine to settle (the focused frame read the same twice).
    private func press(_ button: XCUIRemote.Button) {
        XCUIRemote.shared.press(button)
        var last: CGRect??
        _ = waitUntil(3) {
            let frame = (try? focused.snapshot())?.frame
            defer { last = .some(frame) }
            return last == .some(frame)
        }
    }

    /// Presses the arrow towards `id` from the focused element, frame to frame, until `id` has focus.
    private func walkFocus(to id: String, limit: Int = 12, _ what: String) {
        let target = require(id, what)
        for _ in 0..<limit {
            if holdsFocus(id) { return }
            let here = focused
            if !here.exists(within: 5) { return fail("\(what): nothing has focus") }
            press(Self.direction(from: here.frame, to: target.frame))
        }
        if !waitUntil(2, { holdsFocus(id) }) { fail("\(what): \(limit) presses left focus on \(focusedId ?? "nothing"), not \(id)") }
    }

    /// The arrow from frame `here` towards frame `there`: sideways when they share a row, or share no column and lie
    /// further apart across than down; else up or down.
    private static func direction(from here: CGRect, to there: CGRect) -> XCUIRemote.Button {
        let columnsOverlap = there.minX < here.maxX && here.minX < there.maxX
        let rowsOverlap = there.minY < here.maxY && here.minY < there.maxY
        let across = there.midX - here.midX
        let down = there.midY - here.midY
        if rowsOverlap || (!columnsOverlap && abs(across) > abs(down)) { return across > 0 ? .right : .left }
        return down > 0 ? .down : .up
    }
    #endif
}
