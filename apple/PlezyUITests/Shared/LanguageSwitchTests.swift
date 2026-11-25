import XCTest

/// The interface language follows the Language setting (`app_locale`) while the app runs: picked, every screen redraws
/// in it at once, without a restart. With `PLEZY_DEV_SERVER` the session signs into that server, so Home shows its rows
/// in both languages and, on iPhone, iPad and the Mac, Settings then titles itself and its rows in German; without it
/// the session has no profile, and Home nothing to load.
final class LanguageSwitchTests: PlezyUITestCase {
    func testTheRunningAppRedrawsInTheLanguagePicked() {
        let server = ProcessInfo.processInfo.environment["PLEZY_DEV_SERVER"] ?? ""
        // German is stored 25 s into the session, as a pick in Settings stores it.
        launchDev(settings: ["app_locale=de@25"], arguments: server.isEmpty ? [] : ["--dev-server", server])
        #if os(macOS)
        // The Mac's sidebar has no Libraries row online, its libraries standing for it: Settings' row.
        let (id, english, german) = ("nav.settings", "Settings", "Einstellungen")
        #else
        let (id, english, german) = ("nav.libraries", "Libraries", "Mediatheken")
        #endif
        let destination = require(id, timeout: 60, "the \(english) destination")
        if name(of: destination) != english { fail("before the pick \(english) reads '\(name(of: destination))'") }
        if !server.isEmpty, !text(beginningWith: "Recently Added in ").exists(within: 20) {
            fail("Home shows no 'Recently Added in …' row before the pick")
        }
        shot("english")
        if !waitUntil(60, { self.name(of: destination) == german }) {
            fail("after the pick \(english) reads '\(name(of: destination))', not '\(german)'")
        }
        guard !server.isEmpty else { return shot("german") }
        // Home's rows load again, titled in German.
        if !text(beginningWith: "Kürzlich hinzugefügt in ").exists(within: 30) {
            fail("Home shows no 'Kürzlich hinzugefügt in …' row after the pick")
        }
        if text(beginningWith: "Recently Added in ").exists { fail("Home still shows an English 'Recently Added in …' row") }
        shot("german")
        #if !os(tvOS)
        let settings = require("nav.settings", "the Settings destination")
        #if os(macOS)
        settings.click()
        #else
        settings.tap()
        #endif
        require("settings.screen", timeout: 20, "Settings")
        #if os(macOS)
        // The Mac titles the window: the toolbar shows no title of its own.
        if !waitUntil(10, { self.app.windows["main"].title == "Einstellungen" }) {
            fail("Settings' window is titled '\(app.windows["main"].title)', not 'Einstellungen'")
        }
        #else
        if !app.staticTexts["Einstellungen"].exists(within: 10) { fail("Settings isn't titled 'Einstellungen'") }
        #endif
        let general = require("settings.row.general", "the hub's General row")
        if !general.label.contains("Allgemein") { fail("the General row reads '\(general.label)'") }
        let services = require("settings.row.services", "the hub's Services row")
        if !services.label.contains("Trakt, MyAnimeList, Seerr und mehr verbinden") {
            fail("the Services row reads '\(services.label)', not its German description")
        }
        shot("settings german")
        #endif
    }

    #if !os(tvOS)
    /// The Language menu names both Portuguese, Brazil's first; the second run shows Settings' General page and its
    /// menu in European Portuguese.
    func testTheLanguageMenuNamesBothPortuguese() {
        // "Definições" is Portugal's word for Settings, Brazil's "Configurações".
        for (stored, title) in [("en", "Settings"), ("ptPt", "Definições")] {
            launchDev(settings: ["app_locale=\(stored)"], arguments: ["--dev-open", "settings"])
            press(require("settings.row.general", timeout: 60, "the hub's General row"))
            require("settings.page.general", "the General page")
            let titled = app.descendants(matching: .any)
                .matching(NSPredicate(format: "label == %@ OR title == %@ OR value == %@", title, title, title)).firstMatch
            if !titled.exists(within: 10) { fail("nothing reads '\(title)'") }
            let language = require("settings.row.language", "the Language row")
            shot("general \(stored)")
            press(language)
            let brazil = menuItem("Português (Brasil)"), portugal = menuItem("Português (Portugal)")
            if !portugal.exists(within: 5) || !brazil.exists { fail("the Language menu lacks a Portuguese") }
            if portugal.frame.minY <= brazil.frame.minY { fail("Português (Portugal) comes before Português (Brasil)") }
            shot("language menu \(stored)")
            app.terminate()
        }
    }

    /// The menu's item `label`: a menu item on the Mac, a button on iPhone and iPad.
    private func menuItem(_ label: String) -> XCUIElement {
        #if os(macOS)
        app.menuItems[label].firstMatch
        #else
        app.buttons[label].firstMatch
        #endif
    }

    private func press(_ element: XCUIElement) {
        #if os(macOS)
        element.click()
        #else
        element.tap()
        #endif
    }
    #endif

    /// The first element whose text starts with `prefix`: its label, or on the Mac a text's value.
    private func text(beginningWith prefix: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH %@ OR value BEGINSWITH %@", prefix, prefix)).firstMatch
    }

    /// What a destination reads as: on the Mac a sidebar row's text is its value (what VoiceOver reads there), its
    /// label empty; elsewhere the tab's label.
    private func name(of destination: XCUIElement) -> String {
        #if os(macOS)
        destination.label.isEmpty ? (destination.value as? String) ?? "" : destination.label
        #else
        destination.label
        #endif
    }
}
