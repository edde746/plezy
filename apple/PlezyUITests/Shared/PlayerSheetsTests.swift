import XCTest

/// The player's controls and each of its menus and sheets, shot over a test server's episode: a `--dev` session signed
/// in with `PLEZY_SERVER` (`--dev-server`'s `<kind>=<user>:<password>@<url>`) playing `PLEZY_PLAY` (`--dev-play`'s
/// `<server>:<item>`, percent-encoded so a title's spaces survive the run's environment). Skipped without them.
///
/// iPhone, iPad and the Mac: the audio and subtitle buttons open native menus listing the track playing, the audio's
/// with the audio settings after its sync; the options button (`player.more`) a native menu with the speed, version and
/// quality, and sleep timer submenus, and the file info sheet; the subtitle menu's Search Subtitles the search sheet;
/// the chapters and queue buttons their list sheets, where a chapter's row seeks and closes the sheet. Apple TV: the
/// same buttons open their cards over the bottom, the options card's rows their pages; Down from the timeline opens the
/// panel of chapters and queue on its first tab, Up from its tabs closes it.
final class PlayerSheetsTests: PlezyUITestCase {
    func testControlsAndSheets() throws {
        try openPlayer()
        trackMenu("player.audio", "audio", sync: "Audio Sync")
        trackMenu("player.subtitles", "subtitles", sync: "Subtitle Sync")
        subtitleSearch()
        options()
        #if os(tvOS)
        panel()
        #else
        listSheet("player.chapters", sheet: "player.chapters.sheet", "chapters")
        queueSheet(picks: false)
        #endif
    }

    /// The audio menu holds the audio settings after its tracks and sync (Normalize loudness, Audio channels, whose page
    /// offers the channel limits) and the options menu none of them. Apple TV: Menu on Audio channels' page goes back to
    /// its row in the audio card.
    func testAudioMenuHoldsTheAudioSettings() throws {
        try openPlayer()
        raiseControls()
        guard element("player.audio").exists(within: 3) else { return fail("the episode shows no audio button") }
        activate("player.audio")
        #if os(tvOS)
        require("player.menu", timeout: 5, "the audio button opens its card")
        require("player.option.audioNormalization", timeout: 3, "the audio card holds Normalize loudness")
        let channels = require("player.option.audioChannels", timeout: 3, "the audio card holds Audio channels")
        var downs = 0
        while downs < 20, !channels.hasFocus {
            XCUIRemote.shared.press(.down)
            downs += 1
        }
        // The focus look's animation ends before the shot.
        sleep(1)
        shot("audio settings")
        XCUIRemote.shared.press(.select)
        _ = waitUntil(5) { (0..<3).contains { self.element("player.menu.item.\($0)").label.hasPrefix("Up to 5.1") } }
        let limits = (0..<3).map { element("player.menu.item.\($0)").label }
        if !limits.contains(where: { $0.hasPrefix("Up to 5.1") }) { fail("Audio channels' page doesn't offer Up to 5.1: \(limits)") }
        shot("audio channels")
        XCUIRemote.shared.press(.menu)
        if !waitUntil(3, { channels.exists && channels.hasFocus }) { fail("Menu on Audio channels' page doesn't go back to its row") }
        openOptionsMenu()
        require("player.menu", timeout: 5, "the options button opens its card")
        // The card's slide-in ends before the shot.
        sleep(1)
        shot("options without audio")
        for id in ["player.option.audioNormalization", "player.option.audioChannels", "player.option.audioOutput"] where element(id).exists {
            fail("the options card still holds \(id)")
        }
        dismissMenu()
        #else
        _ = entry("Normalize Loudness", "the audio menu holds Normalize Loudness")
        shotOfMenu("audio settings")
        open(entry("Audio Channels", "the audio menu holds Audio Channels"))
        _ = entry("Up to 5.1", "Audio channels offers Up to 5.1")
        shotOfMenu("audio channels")
        dismissMenu()
        openOptionsMenu()
        // The menu's opening animation ends before the shot.
        sleep(1)
        shotOfMenu("options without audio")
        for label in ["Normalize Loudness", "Audio Channels"] where optionalEntry(label) != nil {
            fail("the options menu still holds \(label)")
        }
        dismissMenu()
        #endif
    }

    #if os(macOS)
    /// In German the audio menu's entries keep the German strings' own casing: title case is for English alone.
    func testGermanMenuEntriesKeepTheirCasing() throws {
        let env = ProcessInfo.processInfo.environment
        guard let server = env["PLEZY_SERVER"], let play = env["PLEZY_PLAY"]?.removingPercentEncoding else {
            throw XCTSkip("PLEZY_SERVER and PLEZY_PLAY name the server and the item to play")
        }
        launchDev(languages: ["de"], arguments: ["--dev-server", server, "--dev-play", play])
        require("player.video", timeout: 90, "the player opening on \(play)")
        sleep(8)
        raiseControls()
        activate("player.audio")
        _ = entry("Audio-Synchronisation", "the audio menu holds Audio-Synchronisation")
        _ = entry("Lautstärke normalisieren", "the audio menu holds Lautstärke normalisieren")
        shotOfMenu("audio settings german")
        dismissMenu()
    }
    #endif

    #if os(tvOS)
    /// File Info's first field, which takes focus as the page opens, reads focused: dark on the focused surface, not
    /// white on a pale highlight over the video.
    func testFileInfoFieldStaysReadableFocused() throws {
        try openPlayer()
        activate("player.more")
        require("player.menu", timeout: 5, "the options card")
        activate("player.option.fileInfo")
        // The page comes in place of the options' rows, focus on its first field.
        _ = element("player.option.fileInfo").waitForNonExistence(timeout: 10)
        // The focus look's animation ends before the shot and the colour reads.
        sleep(2)
        let field = app.descendants(matching: .any).matching(NSPredicate(format: "hasFocus == true")).firstMatch
        guard field.exists(within: 10) else { return fail("no field of File Info took focus") }
        shot("file info field focused")
        requireReadable(field, "File Info's first field")
    }
    #endif

    #if !os(tvOS)
    /// The queue sheet's item after the one playing, picked, plays: the title turns to it.
    func testQueuePickPlaysTheNextItem() throws {
        try openPlayer()
        queueSheet(picks: true)
    }

    /// A queue longer than its sheet (the Movies library shuffled, `PLEZY_DEV_SERVER`'s), twelve Nexts in: the queue
    /// sheet opens scrolled so the entry playing shows whole under the sheet's header (`requireCurrentRowInView`), not
    /// half under it.
    func testQueueOpensWithThePlayingEntryWhole() throws {
        executionTimeAllowance = 600
        let steps = LibrarySteps(test: self)
        launchDev(arguments: ["--dev-server", try steps.libraryServer(), "--dev-open", "libraries"])
        require("libraries.screen", timeout: 60, "Libraries")
        steps.pickLibrary("Movies")
        let shuffle = element("libraries.shuffle")
        if !shuffle.exists(within: 10) {
            activate("libraries.more")
            require("libraries.shuffle", timeout: 10, "Shuffle in the ⋯ menu")
        }
        steps.press(shuffle)
        require("player.video", timeout: 60, "the player on the shuffled Movies")
        for step in 1...12 {
            let before = state("item")
            raiseControls()
            activate("player.next")
            if !waitUntil(30, { let now = self.state("item"); return !now.isEmpty && now != before }) {
                return fail("Next \(step) doesn't move on from '\(before)'")
            }
        }
        raiseControls()
        activate("player.queue")
        require("player.queue.sheet", timeout: 5, "the queue button opens its sheet")
        // The sheet's presentation and its scroll to the current row end before the shot and the frame reads.
        sleep(2)
        shot("long queue")
        let current = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'player.menu.item.' AND value BEGINSWITH 'Now playing'")).firstMatch
        guard current.exists else { return fail("the queue shows no row playing") }
        if current.identifier != "player.menu.item.12" { fail("the queue's playing row is \(current.identifier), not the 13th") }
        requireCurrentRowInView(current, sheet: "player.queue.sheet", "long queue")
        closeSheet("player.queue.sheet")
    }

    /// The timeline's preview of a place on the bar (here 40 %, `-timelinePreview`: XCUITest's pointer doesn't reach the
    /// Mac's bar, and a drag's preview goes as the drag ends), its thumbnail and its time over the glass that holds the
    /// timeline, above its top edge. Shot for the eye: no edge of the glass crosses it, and it covers no control.
    func testTimelinePreviewShowsOverTheControls() throws {
        try openPlayer(arguments: ["-timelinePreview", "0.4"])
        raiseControls()
        if !element("player.bar.bottom").exists(within: 3) { return fail("no controls to show the preview over") }
        #if os(macOS)
        // Of the window: `shot` alone would move the pointer, which would end the preview.
        shot("timeline preview", of: app.windows.firstMatch)
        #else
        shot("timeline preview")
        #endif
    }
    #endif

    /// The sleep timer (fast timers: a minute lasts 6 s): 5 minutes picked from the options' Sleep timer says so in a
    /// message and starts the timer; the page then shows the banner ("Playback will pause in …") with its extension,
    /// which adds to the time left; 5 minutes again, played on, ends in "Still watching?" over the video, whose Continue
    /// plays on and takes it away. The question comes some two minutes into the playback, so `PLEZY_PLAY` must play on
    /// that long (`requirePlaysOn`): an item that ends sooner with nothing after it closes the player first.
    func testSleepTimerBannerExtendAndStillWatching() throws {
        executionTimeAllowance = 600
        try openPlayer(settings: ["player.fastTimers=true"])
        guard requirePlaysOn(seconds: 180) else { return }
        pickOption(label: "Sleep Timer", id: "player.option.sleepTimer", choice: "5 minutes")
        if !waitUntil(5, { self.state("sleep") != "none" }) { fail("picking 5 minutes starts no sleep timer: \(stateReading)") }
        if !waitUntil(3, { self.state("lastOsd").hasPrefix("Sleep timer set for 5 minutes") }) {
            fail("setting the sleep timer says nothing: \(stateReading)")
        }
        shot("sleep timer set")
        let banner = state("sleep")
        let extend = state("extend")
        if extend == "none" { fail("the running sleep timer offers no extension: \(stateReading)") }
        openOption(label: "Sleep Timer", id: "player.option.sleepTimer")
        // The page's animation ends before the shot.
        sleep(1)
        #if os(tvOS)
        shot("sleep timer active")
        #else
        shotOfMenu("sleep timer active")
        #endif
        pickEntry(extend, id: "player.sleep.extend")
        if !waitUntil(5, { self.minutes(self.state("sleep")) > self.minutes(banner) }) {
            fail("the extension leaves the timer at '\(state("sleep"))' (was '\(banner)')")
        }
        dismissMenu()
        pickOption(label: "Sleep Timer", id: "player.option.sleepTimer", choice: "5 minutes")
        raiseControls()
        activate(transport)
        if !element("player.stillWatching").exists(within: 60) { return fail("the sleep timer ran out without asking: \(stateReading)") }
        shot("still watching")
        let keepWatching = element("player.stillWatching.keepWatching")
        #if os(tvOS)
        if focus(on: "player.stillWatching.keepWatching", at: keepWatching.frame) { XCUIRemote.shared.press(.select) }
        #else
        tap(keepWatching)
        #endif
        if !waitUntil(5, { !self.element("player.stillWatching").exists }) { fail("Continue leaves the question up") }
    }

    /// The playback info's switch shows its card over the video; with auto-hide (on by default) the card fades with the
    /// controls as they go down and the state says it is hidden, and the switch turns it off. Zoom 150 % from the
    /// options zooms; Reset goes back to 100 %. On iPhone and iPad a pinch on the video zooms too, with its message
    /// ("Zoom 150%"). On Apple TV Reset comes last: after its pick the focus system holds More (drawn focused,
    /// `player.state`'s uiFocus), which XCUITest's focus query doesn't report, so no step walks the remote after it.
    func testZoomMessageAndPlaybackInfo() throws {
        executionTimeAllowance = 600
        try openPlayer()
        toggleOption(label: "Show Playback Info", id: "player.option.playbackInfo")
        if !waitUntil(5, { self.state("playbackInfo") == "visible" }) { fail("the switch shows no playback info: \(stateReading)") }
        dismissMenu()
        raiseControls()
        // The card's fade-in ends before the shot.
        sleep(2)
        shot("playback info")
        // Played on, the controls go down by themselves, and the card with them.
        playPause()
        if !waitUntil(20, { self.state("controls") == "false" }) { fail("the controls never went down: \(stateReading)") }
        if !waitUntil(5, { self.state("playbackInfo") == "hidden" }) { fail("the playback info stays up as the controls go: \(stateReading)") }
        toggleOption(label: "Show Playback Info", id: "player.option.playbackInfo")
        if !waitUntil(5, { self.state("playbackInfo") == "off" }) { fail("the switch leaves the playback info on: \(stateReading)") }
        // Paused again, as the zoom steps below expect: playing, the controls and the menu go down under them, on their
        // timer, between any two looks. So Play/Pause is pressed only where the transport, brought up, says it plays.
        dismissMenu()
        for _ in 0..<3 where transportLabel != "Play" {
            raiseControls()
            if transportLabel == "Pause" { playPause() }
            _ = waitUntil(3) { self.transportLabel == "Play" }
        }
        if transportLabel != "Play" { fail("the video didn't pause again: \(stateReading)") }
        pickOption(label: "Zoom", id: "player.option.zoom", choice: "150%")
        if !waitUntil(5, { self.state("zoom") == "150%" }) { fail("picking 150% leaves the zoom at \(state("zoom"))") }
        // A pick in the open menu shows no message over it (the menu holds the value); a pinch does (below).
        let osd = element("player.osd")
        shot("zoom 150")
        pickOption(label: "Zoom", id: "player.option.zoom", choice: "Reset")
        if !waitUntil(5, { self.state("zoom") == "100%" }) { fail("Reset leaves the zoom at \(state("zoom"))") }
        #if os(iOS)
        dismissMenu()
        element("player.video").pinch(withScale: 1.8, velocity: 2)
        if !waitUntil(5, { self.state("zoom") != "100%" }) { fail("a pinch doesn't zoom: \(stateReading)") }
        // Read from one snapshot: the message can go between a look at it and a read of its label.
        if !waitUntil(3, { (try? osd.snapshot())?.label.contains("%") == true }) { fail("a pinch's zoom shows no message: \(stateReading)") }
        shot("pinch zoom")
        #endif
    }

    /// The speed menu: six common speeds and Custom. 1.5× picked plays at 1.5×. Custom opens the custom speed (a popover
    /// from the options button; on Apple TV a page of the card, focus on −): + steps a twentieth, the slider (not on Apple
    /// TV; on the Mac the arrow keys too) sets a speed off the presets, which the menu then shows checked under Custom;
    /// Normal goes back to 1×. On Apple TV, Menu from the custom speed returns to the speeds, focus on Custom.
    func testSpeedPresetAndCustomSpeed() throws {
        try openPlayer()
        pickOption(label: "Playback Speed", id: "player.option.speed", choice: "1.5×")
        if !waitUntil(5, { self.engineSetting("speed") == "1.50" }) { fail("picking 1.5× plays at \(engineSetting("speed"))") }
        openOption(label: "Playback Speed", id: "player.option.speed")
        #if os(tvOS)
        shot("speed menu")
        let labels = (0..<10).map { "player.menu.item.\($0)" }.prefix { element($0).exists }.map { element($0).label }
        XCTAssertEqual(labels, ["0.5×", "0.75×", "Normal", "1.25×", "1.5×", "2×", "Custom"], "the speeds")
        pickEntry("Custom", id: nil)
        #else
        shotOfMenu("speed menu")
        if optionalEntry("2.5×") != nil { fail("the speed menu still lists 2.5×") }
        pickEntry("Custom…", id: nil)
        #endif
        #if os(tvOS)
        _ = require("player.speed.increase", timeout: 5, "Custom opens the custom speed")
        if !waitUntil(3, { self.focusedId == "player.speed.decrease" }) { fail("the custom speed opens with focus on −, not \(focusedId)") }
        XCUIRemote.shared.press(.right)
        XCUIRemote.shared.press(.select)
        #else
        tap(require("player.speed.increase", timeout: 5, "Custom opens the custom speed"))
        #endif
        if !waitUntil(5, { self.engineSetting("speed") == "1.55" }) { fail("+ from 1.5× plays at \(engineSetting("speed"))") }
        // The Mac reports a text's string as its value, the others as its label.
        func shownSpeed() -> String {
            let text = element("player.speed")
            return (text.value as? String).flatMap { $0.isEmpty ? nil : $0 } ?? text.label
        }
        if !waitUntil(3, { shownSpeed() == "1.55×" }) { fail("the custom speed shows '\(shownSpeed())', not 1.55×") }
        #if os(tvOS)
        shot("custom speed")
        XCUIRemote.shared.press(.menu)
        if !waitUntil(3, { self.focusedId == "player.menu.item.6" }) { fail("Menu from the custom speed leaves focus on \(focusedId), not Custom") }
        XCTAssertEqual(element("player.menu.item.6").label, "Custom · 1.55×", "Custom shows the speed")
        XCTAssertTrue(element("player.menu.item.6").isSelected, "Custom is checked")
        shot("speed menu custom")
        XCUIRemote.shared.press(.select)
        if !waitUntil(3, { self.focusedId == "player.speed.decrease" }) { fail("Custom again opens with focus on \(focusedId), not −") }
        // Down from −, Normal lying between − and + under them.
        XCUIRemote.shared.press(.down)
        if !waitUntil(3, { self.focusedId == "player.speed.reset" }) { return fail("Down from − leaves focus on \(focusedId), not Normal") }
        shot("custom speed normal focused")
        XCUIRemote.shared.press(.select)
        #else
        let slider = require("player.speed.slider", timeout: 5, "the custom speed's slider")
        #if os(macOS)
        app.typeKey(.rightArrow, modifierFlags: [])
        if !waitUntil(5, { self.engineSetting("speed") == "1.60" }) { fail("→ from 1.55× plays at \(engineSetting("speed"))") }
        #endif
        // Two fifths of the way from half speed to eight times: 3.5×, off the presets.
        slider.adjust(toNormalizedSliderPosition: 0.4)
        // The drag's last steps reach the player after it ends: the speed once the popover shows the engine's and holds.
        var speed = ""
        let settled = waitUntil(5, every: 0.5) {
            let engine = Double(self.engineSetting("speed")) ?? 0
            let shown = shownSpeed()
            defer { speed = shown }
            return engine > 2.5 && shown == speed && Double(shown.dropLast()) == engine
        }
        if !settled { fail("the slider leaves the speed at \(engineSetting("speed")), shown as \(shownSpeed())") }
        shotOfMenu("custom speed")
        dismissMenu()
        openOption(label: "Playback Speed", id: "player.option.speed")
        guard let custom = optionalEntry("Custom · \(speed)") else { return fail("the speed menu shows no Custom · \(speed)") }
        shotOfMenu("speed menu custom")
        pick(custom)
        tap(require("player.speed.reset", timeout: 5, "Custom opens the custom speed again"))
        #endif
        if !waitUntil(5, { self.engineSetting("speed") == "1.00" }) { fail("Normal plays at \(engineSetting("speed"))") }
        dismissMenu()
    }

    /// The playback info's card (on from the launch, auto-hide off so it stays as the controls go) covers no control:
    /// with the controls up and down its frame meets none of the player's controls, takes at most a third of the window,
    /// its rows' text is no smaller than the idiom's floor (11 pt on an iPhone, 12 on an iPad and the Mac, 23 on Apple
    /// TV), and none of its data values is drawn cut short (only a file's name or a track's title may end in "…"). On an
    /// iPhone in landscape with the controls up (a short room beside the transport) it still shows the stream first.
    func testPlaybackInfoKeepsClearOfTheControls() throws {
        try openPlayer(settings: ["show_performance_overlay=true", "auto_hide_performance_overlay=false"])
        checkInfoCard("info controls shown", controls: true)
        // Played on, the controls go down by themselves (on the Mac with the pointer off them).
        playPause()
        #if os(macOS)
        element("player.video").coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4)).hover()
        #endif
        if !waitUntil(20, { self.state("controls") == "false" }) { return fail("the controls never went down: \(stateReading)") }
        checkInfoCard("info controls hidden", controls: false)
    }

    /// The playback info's card (`player.infoCard`, the probe of its frame and reading) with the controls up or down as
    /// `controls` says, shot as `name`: it meets none of the controls that show (every `player.` element but the video,
    /// its surface and the 1 pt probes), covers at most a third of the window, its rows' text is the floor or larger,
    /// and no data value in it is drawn narrower than its text (the reading's `cut`, `PlaybackInfoCutProbe`).
    private func checkInfoCard(_ name: String, controls: Bool) {
        #if os(tvOS)
        let floor = 23.0
        #elseif os(macOS)
        let floor = 12.0
        #else
        let floor = UIDevice.current.userInterfaceIdiom == .pad ? 12.0 : 11.0
        #endif
        // The controls can go down on their timer between the look and the reading: looked at again.
        for attempt in 0..<3 {
            if controls { raiseControls() }
            guard element("player.infoCard").exists(within: 5) else { return fail("\(name): no playback info card: \(stateReading)") }
            // Past its 200 ms move.
            Thread.sleep(forTimeInterval: 0.5)
            guard let tree = try? app.snapshot() else { continue }
            var nodes = [tree]
            var found: [any XCUIElementSnapshot] = []
            while let node = nodes.popLast() {
                nodes += node.children
                if node.identifier.hasPrefix("player.") { found.append(node) }
            }
            let shown = found.contains { $0.identifier == "player.title" }
            guard let card = found.first(where: { $0.identifier == "player.infoCard" }), shown == controls else {
                if attempt < 2 { continue }
                return fail("\(name): the controls \(controls ? "never stayed up" : "came up") for the card: \(stateReading)")
            }
            let reading = card.label
            let field = { (key: String) in
                reading.components(separatedBy: "; ").first { $0.hasPrefix("\(key)=") }.map { String($0.dropFirst(key.count + 1)) } ?? ""
            }
            if (Double(field("rows")) ?? 0) < floor { fail("\(name): the card's rows are \(field("rows")) pt, under \(floor)") }
            if !reading.contains("cut=") { fail("\(name): the card's reading says nothing of cut values: \(reading)") }
            if !field("cut").isEmpty { fail("\(name): the card cuts the data of \(field("cut")) short: \(reading)") }
            let window = element("player.video").frame
            if card.frame.width * card.frame.height > window.width * window.height / 3 + 1 {
                fail("\(name): the card \(card.frame) covers over a third of the window \(window)")
            }
            let skipped: Set = ["player.video", "player.surface", "player.infoCard"]
            for control in found where !skipped.contains(control.identifier) && control.frame.width > 2 && control.frame.height > 2 {
                let overlap = card.frame.intersection(control.frame)
                if !overlap.isNull, overlap.width > 0.5, overlap.height > 0.5 {
                    fail("\(name): the card \(card.frame) covers \(control.identifier) \(control.frame)")
                }
            }
            #if os(iOS)
            if controls, UIDevice.current.userInterfaceIdiom == .phone, !field("sections").hasPrefix("stream") {
                fail("\(name): beside the transport the card shows '\(field("sections"))', not the stream first")
            }
            #endif
            #if os(macOS)
            // With the controls down, not over the window: a pointer move would bring them up.
            if controls { shot(name) } else { shot(name, of: app.windows.firstMatch) }
            #else
            shot(name)
            #endif
            return
        }
        fail("\(name): no reading of the playback info card: \(stateReading)")
    }

    /// The options offer ambient lighting on every Apple player: its switch has mpv scale the picture to the whole
    /// surface for the shader (`keepaspect=no`, the engine probe `player.engine`), and off brings the letterbox back
    /// (`yes`). They offer the HDR switch everywhere too, Apple TV included.
    func testAmbientLightingReachesMpvAndHdrIsOffered() throws {
        try openPlayer()
        toggleOption(label: "Ambient Lighting", id: "player.option.ambientLighting")
        if !waitUntil(10, { self.engineSetting("keepaspect") == "no" }) { fail("ambient lighting on leaves keepaspect at \(engineSetting("keepaspect"))") }
        shot("ambient lighting on")
        toggleOption(label: "Ambient Lighting", id: "player.option.ambientLighting")
        if !waitUntil(10, { self.engineSetting("keepaspect") == "yes" }) { fail("ambient lighting off leaves keepaspect at \(engineSetting("keepaspect"))") }
        openOptionsMenu()
        #if os(tvOS)
        require("player.menu", timeout: 5, "the options button opens its card")
        if !element("player.option.hdr").exists(within: 3) { fail("the options card has no HDR switch") }
        #else
        // On an SDR video the entry is dimmed and says why on its second line ("Not HDR"), its title the switch's own.
        if optionalEntry("HDR") == nil { fail("the options menu has no HDR switch") }
        #endif
        shot("options with hdr")
        dismissMenu()
    }

    /// The video's surface stays black until the first frame: with mpv decoding no frame (`-mpvOption
    /// vd-lavc-skipframe=all`, a debug build's startup option) the player opens over a black surface, the state saying
    /// no frame has come (`player.state`'s firstFrame), the loading line over it, for as long as none comes.
    func testSurfaceStaysBlackUntilTheFirstFrame() throws {
        let env = ProcessInfo.processInfo.environment
        guard let server = env["PLEZY_SERVER"], let play = env["PLEZY_PLAY"]?.removingPercentEncoding else {
            throw XCTSkip("PLEZY_SERVER and PLEZY_PLAY name the server and the item to play")
        }
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone { XCUIDevice.shared.orientation = .landscapeLeft }
        #endif
        launchDev(arguments: ["--dev-server", server, "--dev-play", play, "-mpvOption", "vd-lavc-skipframe=all"])
        require("player.video", timeout: 90, "the player opening on \(play)")
        // Past the player's opening transition, and long after a frame would have come.
        sleep(6)
        if state("firstFrame") != "false" { return fail("a first frame came with no frame decoded: \(stateReading)") }
        shot("before the first frame")
    }

    #if !os(tvOS)
    /// Ctrl+S saves a screenshot with the device's own decoding (on the Mac VideoToolbox, whose frames mpv can't write
    /// itself; the simulators decode in software) and says so: "Screenshot saved". On the Mac the shot goes to a folder
    /// in /tmp (`-screenshotDirectory`), not the Pictures of whoever works at it; the simulators' Documents go with them.
    func testScreenshotWithHardwareDecoding() throws {
        #if os(macOS)
        try openPlayer(arguments: ["-screenshotDirectory", "/tmp/plezy-ui-screenshots"])
        #else
        try openPlayer()
        // Keys reach the player: Alt+= zooms in (then Alt+- back out). The iPhone Duo's simulator delivers no
        // hardware keyboard key to the app (not even to a focused text field), so no key can be tested there.
        app.typeKey("=", modifierFlags: .option)
        if !waitUntil(5, { self.state("zoom") != "100%" }) {
            throw XCTSkip("no hardware keyboard key reaches the app on the simulator \(UIDevice.current.name): \(stateReading)")
        }
        app.typeKey("-", modifierFlags: .option)
        if !waitUntil(5, { self.state("zoom") == "100%" }) { fail("Alt+- keeps the zoom: \(stateReading)") }
        #endif
        app.typeKey("s", modifierFlags: .control)
        if !waitUntil(10, { self.state("lastOsd").hasPrefix("Screenshot") }) { return fail("Ctrl+S shows no message: \(stateReading)") }
        shot("screenshot")
        if state("lastOsd") != "Screenshot saved" { fail("Ctrl+S: \(stateReading)") }
    }
    #endif

    /// With the controls up the timeline reads the position and the time left negative with the clock time the video
    /// ends at (`−1:21 · 21:43`), once the first frame has come.
    func testFirstFrameAndTimeline() throws {
        try openPlayer()
        if !waitUntil(30, { self.state("firstFrame") == "true" }) { fail("no first frame after the player opened: \(stateReading)") }
        let remaining = element("player.remaining")
        guard remaining.exists(within: 5) else { return fail("the timeline shows no time left") }
        let text = remaining.label.isEmpty ? (remaining.value as? String ?? "") : remaining.label
        // Shown `−1:21 · 21:43`; VoiceOver reads the clock in words on iPhone, iPad and the Mac (`−1:21, ends at 21:43`).
        if !(text.hasPrefix("−") || text.hasPrefix("-")) || !(text.contains(" · ") || text.contains(", ")) {
            fail("the time left reads '\(text)', not '−m:ss' with the clock time it ends at")
        }
        let position = element("player.position")
        if position.exists, position.label.isEmpty, (position.value as? String ?? "").isEmpty { fail("the position reads nothing") }
        shot("timeline")
        #if os(iOS)
        // An iPad on its side too: the title and the timeline over the scrim's bottom edge at that height.
        if UIDevice.current.userInterfaceIdiom == .pad {
            XCUIDevice.shared.orientation = .landscapeLeft
            addTeardownBlock { XCUIDevice.shared.orientation = .portrait }
            // The rotation's animation ends before the controls come up and the shot.
            sleep(2)
            raiseControls()
            shot("timeline-landscape")
        }
        #endif
    }

    #if os(tvOS)
    /// The Siri Remote's Play/Pause pauses the video and plays it again, one toggle per press, the engine's position
    /// holding or moving: as the player opens, the controls never shown (the video has the remote); with the controls
    /// up (the timeline has it); and once they went down by themselves (the video has it back).
    func testRemotePlayPauseWithTheControlsDownAndUp() throws {
        try openPlaying()
        playPauseToggles("as the player opens")
        raiseControls()
        playPauseToggles("with the controls up")
        if !waitUntil(20, { self.state("controls") == "false" }) { return fail("the controls never went down: \(stateReading)") }
        playPauseToggles("once the controls went down")
    }

    /// Once the controls went down by themselves, the remote brings them back, time after time: Up and Down (the video
    /// playing on), Select, which pauses it too, and Up again after Play/Pause played on and paused and played with
    /// the controls down.
    func testRemoteBringsTheControlsBackAfterTheyHide() throws {
        try openPlaying()
        let presses: [(XCUIRemote.Button, String)] = [(.up, "Up"), (.up, "Up"), (.up, "Up"), (.down, "Down"), (.select, "Select")]
        for (cycle, (button, name)) in presses.enumerated() {
            if !waitUntil(20, { self.state("controls") == "false" }) {
                return fail("cycle \(cycle): the controls never went down: \(stateReading)")
            }
            XCUIRemote.shared.press(button)
            if !waitUntil(3, { self.state("controls") == "true" }) {
                fail("cycle \(cycle): \(name) after the controls went down doesn't bring them back: \(stateReading)")
            }
        }
        if !enginePlays(false) { fail("Select after the controls went down doesn't pause: \(stateReading)") }
        // Played on with Play/Pause, and paused and played again with the controls down: the next time they go down,
        // Up still brings them back.
        XCUIRemote.shared.press(.playPause)
        if !enginePlays(true) { fail("Play/Pause doesn't play again: \(stateReading)") }
        if !waitUntil(20, { self.state("controls") == "false" }) { return fail("the controls never went down: \(stateReading)") }
        playPauseToggles("with the controls down")
        if !waitUntil(20, { self.state("controls") == "false" }) { return fail("the controls never went down: \(stateReading)") }
        XCUIRemote.shared.press(.up)
        if !waitUntil(3, { self.state("controls") == "true" }) {
            fail("Up after Play/Pause and the controls going down doesn't bring them back: \(stateReading)")
        }
    }

    /// Previous, focused, restarts what plays past its first seconds ("Restart"); back at the start of the queue's first
    /// item it turns off (dimmed, "Previous episode") and on again as "Restart" 3 s later, and focus stays on it all the
    /// while: an off episode button stays focusable, so the focus engine doesn't move focus to the timeline and on to
    /// the video. `PLEZY_PLAY` must start the queue (nothing before it), as `--dev-play` of an episode does.
    func testFocusStaysOnPreviousAsItTurnsOffAndOnAtARestart() throws {
        try openPlaying()
        raiseControls()
        let previous = element("player.previous")
        guard previous.exists(within: 5) else { return fail("no Previous with the controls up: \(stateReading)") }
        if !waitUntil(10, { previous.label == "Restart" && self.state("episodes").hasPrefix("on/") }) {
            return fail("Previous never reads Restart past the first seconds: '\(previous.label)', \(stateReading)")
        }
        // Focuses it and presses Select: the restart.
        activate("player.previous")
        var sawOff = false
        let end = Date().addingTimeInterval(8)
        while Date() < end {
            let focused = focusedId
            if focused != "player.previous" {
                shot("previous focus lost")
                return fail("focus left Previous for \(focused) \(sawOff ? "after it turned off" : "at the restart"): \(stateReading)")
            }
            if state("episodes").hasPrefix("off/") { sawOff = true }
            if sawOff, state("episodes").hasPrefix("on/"), previous.label == "Restart" { break }
            // Focus is sampled through the restart: it must stay on Previous the whole time.
            Thread.sleep(forTimeInterval: 0.3)
        }
        if !sawOff { fail("Previous never turned off back at the start (does PLEZY_PLAY start its queue?): \(stateReading)") }
        if !(state("episodes").hasPrefix("on/") && previous.label == "Restart") {
            fail("Previous didn't come back on as Restart within 8 s: '\(previous.label)', \(stateReading)")
        }
        shot("previous focused back on")
    }

    /// Opens the player on `PLEZY_PLAY` and waits for its first frame, playing.
    private func openPlaying() throws {
        let env = ProcessInfo.processInfo.environment
        guard let server = env["PLEZY_SERVER"], let play = env["PLEZY_PLAY"]?.removingPercentEncoding else {
            throw XCTSkip("PLEZY_SERVER and PLEZY_PLAY name the server and the item to play")
        }
        launchDev(arguments: ["--dev-server", server, "--dev-play", play])
        require("player.video", timeout: 90, "the player opening on \(play)")
        if !waitUntil(30, { self.state("firstFrame") == "true" }) { return fail("no first frame: \(stateReading)") }
        _ = waitUntil(10) { (self.enginePosition() ?? 0) >= 3 }
    }

    /// Play/Pause pauses the playing video, and a second press plays it again.
    private func playPauseToggles(_ when: String) {
        XCUIRemote.shared.press(.playPause)
        if !enginePlays(false) { fail("Play/Pause \(when) doesn't pause: \(stateReading)") }
        XCUIRemote.shared.press(.playPause)
        if !enginePlays(true) { fail("a second Play/Pause \(when) doesn't play: \(stateReading)") }
    }

    /// Whether the engine's position (`player.engine`) moves (`playing`) or holds over 2 s, a second after the press.
    private func enginePlays(_ playing: Bool) -> Bool {
        sleep(1)
        let before = enginePosition()
        sleep(2)
        guard let before, let after = enginePosition() else { return false }
        return playing ? after > before + 1 : after == before
    }

    private func enginePosition() -> Double? {
        let probe = element("player.engine")
        let text = probe.exists ? (probe.value as? String ?? probe.label) : ""
        return text.split(separator: " ").first { $0.hasPrefix("position=") }.flatMap { Double($0.dropFirst(9)) }
    }
    #endif

    #if os(macOS)
    /// Escape is Back on the Mac, staged as on the other desktops: with the controls up the first hides them, the next
    /// leaves. F fills the screen (the window goes full screen) and Escape still is Back, the full screen kept.
    func testEscapeLeavesThePlayerAfterFullScreen() throws {
        try openPlayer()
        let before = app.windows.firstMatch.frame
        app.typeKey("f", modifierFlags: [])
        if !waitUntil(10, { self.app.windows.firstMatch.frame != before }) { fail("F didn't fill the screen") }
        sleep(2)
        shot("full screen")
        escapeLeaves("after F", layers: ["controls"])
    }

    /// With Up Next's prompt showing (the credits, which Right arrows seek to), Escape dismisses the prompt, then hides
    /// the controls, then leaves.
    func testEscapeLeavesThePlayerFromUpNext() throws {
        try openPlayer()
        let prompt = element("player.upNext")
        for _ in 0..<12 where !prompt.exists {
            app.typeKey(.rightArrow, modifierFlags: [])
            _ = prompt.exists(within: 1)
        }
        guard prompt.exists(within: 5) else { return fail("no Up Next prompt at the credits: \(stateReading)") }
        shot("up next")
        escapeLeaves("from Up Next", layers: ["upNext", "controls"])
    }

    /// While the player is still opening (no frame decoded, `-mpvOption vd-lavc-skipframe=all`), the controls up, one
    /// Escape leaves it.
    func testEscapeLeavesThePlayerWhileOpening() throws {
        let env = ProcessInfo.processInfo.environment
        guard let server = env["PLEZY_SERVER"], let play = env["PLEZY_PLAY"]?.removingPercentEncoding else {
            throw XCTSkip("PLEZY_SERVER and PLEZY_PLAY name the server and the item to play")
        }
        launchDev(arguments: ["--dev-server", server, "--dev-play", play, "-mpvOption", "vd-lavc-skipframe=all"])
        require("player.video", timeout: 90, "the player opening on \(play)")
        sleep(3)
        if state("firstFrame") != "false" { return fail("a first frame came with no frame decoded: \(stateReading)") }
        escapeLeaves("while opening", layers: [])
    }

    /// Escape takes `layers` away one press each, those up at the time ("upNext": the prompt, "controls"), the player
    /// staying; the next Escape leaves it within 10 s.
    private func escapeLeaves(_ when: String, layers: [String]) {
        for layer in layers {
            let up = layer == "upNext" ? element("player.upNext").exists : state("controls") == "true"
            guard up else { continue }
            app.typeKey(.escape, modifierFlags: [])
            let gone = waitUntil(5) {
                layer == "upNext" ? !self.element("player.upNext").exists : self.state("controls") == "false"
            }
            if !gone { return fail("Escape \(when) didn't take the \(layer) away: \(stateReading)") }
            if !element("player.video").exists { return fail("Escape \(when) left the player with the \(layer) up") }
        }
        app.typeKey(.escape, modifierFlags: [])
        if !waitUntil(10, { !self.element("player.video").exists }) { fail("Escape \(when) left the player up: \(stateReading)") }
    }

    /// mpv's lines reach the app's log: after playing, Settings → View Logs lists them as "[MPV:<prefix>] <text>", and
    /// its header names the effects tier and the display ("Effects: …", "Display: … physical, … logical @ …"). Read off
    /// the page: Copy Logs would write the Mac's own pasteboard, which belongs to whoever works at it.
    func testMpvLinesReachTheAppLog() throws {
        try openPlayer()
        raiseControls()
        element("player.back").click()
        if !waitUntil(10, { !self.element("player.video").exists }) { return fail("Back left the player up") }
        app.typeKey(",", modifierFlags: .command)
        require("settings.screen", timeout: 20, "Settings")
        let row = element("settings.row.view_logs")
        for _ in 0..<10 where !row.isHittable { app.windows.firstMatch.scroll(byDeltaX: 0, deltaY: -300) }
        require("settings.row.view_logs", "Settings → View Logs").click()
        require("settings.logs.entry.0", timeout: 10, "the logs")
        shot("view logs")
        let header = text(containing: "Effects: ")
        guard header.exists(within: 5) else { return fail("the logs' header names no effects tier") }
        let headerText = [header.label, header.value as? String ?? ""].joined(separator: "\n")
        if !headerText.contains(" logical @ ") { fail("the logs' header names no display: \(headerText)") }
        // Newest first: the mpv lines lie under what Back and Settings logged since.
        let mpvLine = text(containing: "[MPV:")
        for _ in 0..<20 where !mpvLine.exists { app.windows.firstMatch.scroll(byDeltaX: 0, deltaY: -400) }
        if !mpvLine.exists { fail("the logs hold no mpv line") }
    }

    /// The first text whose label or value holds `part` (the Mac reports a text's string as its value).
    private func text(containing part: String) -> XCUIElement {
        app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@ OR value CONTAINS %@", part, part)).firstMatch
    }

    /// The Mac's timeline takes keyboard focus (Tab reaches it, its ring showing): Down moves focus to Play/Pause; Up
    /// goes to the skip prompt's button while one shows (the item's intro), else hides the controls, the video taking
    /// the keys back (Space then plays or pauses it). Needs the system's keyboard navigation (skipped without it).
    func testTimelineTakesKeyboardFocus() throws {
        try requireKeyboardNavigation()
        try openPlayer()
        guard tab(to: "player.scrub") else { return fail("Tab never reached the timeline: focus on \(keyboardFocus)") }
        shot("timeline focused")
        app.typeKey(.downArrow, modifierFlags: [])
        if !waitUntil(3, { self.keyboardFocus == "player.playPause" }) {
            fail("Down from the timeline moves focus to \(keyboardFocus), not Play/Pause")
        }
        shot("play pause focused by Down")
        guard tab(to: "player.scrub", backwards: true) else { return fail("Shift-Tab never reached the timeline: focus on \(keyboardFocus)") }
        if element("player.skip").exists {
            app.typeKey(.upArrow, modifierFlags: [])
            if !waitUntil(3, { self.keyboardFocus == "player.skip" }) {
                return fail("Up from the timeline under a skip prompt moves focus to \(keyboardFocus), not the prompt")
            }
            shot("skip prompt focused by Up")
            app.typeKey(" ", modifierFlags: [])
            if !element("player.skip").waitForNonExistence(timeout: 10) { return fail("Space on the focused skip prompt leaves it up") }
            raiseControls()
            guard tab(to: "player.scrub", backwards: true) else { return fail("Shift-Tab never reached the timeline again: focus on \(keyboardFocus)") }
        }
        let before = element("player.playPause").label
        app.typeKey(.upArrow, modifierFlags: [])
        if !waitUntil(5, { !self.element("player.bar.bottom").exists }) { fail("Up from the timeline leaves the controls up") }
        shot("controls hidden by Up")
        app.typeKey(" ", modifierFlags: [])
        raiseControls()
        if !waitUntil(5, { self.element("player.playPause").label != before }) {
            fail("Space after Up doesn't reach the video: Play/Pause still reads \(before)")
        }
    }

    /// Presses Tab (Shift-Tab `backwards`) until `id` has keyboard focus, once around the player's controls at most. The
    /// probe looks four times a second: each press waits for its next look.
    private func tab(to id: String, backwards: Bool = false) -> Bool {
        for _ in 0..<30 {
            if keyboardFocus == id { return true }
            app.typeKey(.tab, modifierFlags: backwards ? .shift : [])
            usleep(300_000)
        }
        return keyboardFocus == id
    }
    #endif

    // MARK: - Steps

    /// Opens the player (with this device's `settings` and the launch's extra `arguments`), waits for the first frame
    /// and the server's extras (chapters, markers, thumbnails), pauses and shoots the controls.
    private func openPlayer(settings: [String] = [], arguments: [String] = []) throws {
        let env = ProcessInfo.processInfo.environment
        guard let server = env["PLEZY_SERVER"], let play = env["PLEZY_PLAY"]?.removingPercentEncoding else {
            throw XCTSkip("PLEZY_SERVER and PLEZY_PLAY name the server and the item to play")
        }
        #if os(iOS)
        // The player holds landscape on a phone: the device turned to match, so the shots come out upright.
        if UIDevice.current.userInterfaceIdiom == .phone { XCUIDevice.shared.orientation = .landscapeLeft }
        #endif
        launchDev(settings: settings, arguments: ["--dev-server", server, "--dev-play", play] + arguments)
        require("player.video", timeout: 90, "the player opening on \(play)")
        // The first frame and the server's extras (chapters, markers, thumbnails) come in; the extras signal nothing.
        sleep(8)
        raiseControls()
        guard require(transport, "the controls").exists else { throw XCTSkip("no controls to drive") }
        // Read from snapshots (`transportLabel`): the controls go down on their timer (on a touch screen a few seconds
        // after they came up, paused too) between any look at the transport and a read of it.
        #if os(tvOS)
        // The timeline has focus as the controls come up: Select pauses, unless a skip prompt shows (an intro): then
        // Select is the skip shortcut and skips it, the controls going down; the next Select pauses.
        for _ in 0..<3 where transportLabel != "Play" {
            raiseControls()
            if transportLabel == "Play" { break }
            guard let frame = try? element(transport).snapshot().frame, focus(on: transport, at: frame) else { continue }
            XCUIRemote.shared.press(.select)
            _ = waitUntil(3) { self.transportLabel == "Play" }
        }
        #else
        // The reads before the tap are slow while the playback info's card is up (a third of a second each on an iPad),
        // so the tap can come after the controls hid on their 5 s timer: it lands on the video and brings them up
        // instead. Pressed again; paused, the controls stay up, so Play reads at once.
        for _ in 0..<3 where transportLabel != "Play" {
            activate(transport)
            if waitUntil(5, { self.transportLabel == "Play" }) { break }
        }
        #endif
        if !waitUntil(5, { self.transportLabel == "Play" }) {
            raiseControls()
            if transportLabel != "Play" { return fail("the video didn't pause: \(transport) reads '\(transportLabel)'") }
        }
        shot("controls-paused")
    }

    /// The audio or subtitle button's menu (`button`) lists the track playing (the button's value), shot as `name`, and
    /// leaves the paused video behind it as bright as it was (no dimming); its sync entry (`sync`) opens the delay
    /// control, whose + moves the delay a step, held moves it a second every 200 ms after the first half second, and
    /// Reset takes it back (iOS and macOS).
    private func trackMenu(_ button: String, _ name: String, sync: String) {
        raiseControls()
        guard element(button).exists(within: 3) else { return }
        let playing = element(button).value as? String ?? ""
        #if !os(tvOS)
        let lit = videoPatchLuminance()
        #endif
        activate(button)
        #if os(tvOS)
        require("player.menu", timeout: 5, "\(button) opens its card")
        let items = (0..<40).map { element("player.menu.item.\($0)") }.prefix { $0.exists }
        if !playing.isEmpty, !items.contains(where: { $0.label.hasPrefix(playing) }) {
            fail("the \(name) card doesn't list '\(playing)': \(items.map(\.label))")
        }
        shot(name)
        activate("player.menu.delay")
        require("player.delay", timeout: 5, "\(sync) in the \(name) card opens its control")
        shot("\(name) sync")
        XCUIRemote.shared.press(.menu)
        _ = element("player.delay").waitForNonExistence(timeout: 5)
        #else
        if !playing.isEmpty { _ = entry(playing, "the \(name) menu lists the track playing") }
        if let lit, let open = videoPatchLuminance(), open < lit * 0.85 {
            fail(String(format: "the video dims behind the open %@ menu: luminance %.3f, %.3f before it opened", name, open, lit))
        }
        shotOfMenu(name)
        pick(entry(sync, "the \(name) menu offers \(sync)"))
        require("player.delay", timeout: 5, "\(sync) opens its popover")
        shot("\(name) sync")
        // The delay's text: a static text's label on iOS, its value on the Mac.
        func delay() -> String {
            let text = element("player.delay")
            #if os(macOS)
            return text.value as? String ?? ""
            #else
            return text.label
            #endif
        }
        let before = delay()
        if before.isEmpty { fail("\(sync)'s popover shows no delay") }
        tap(element("player.delay.increase"))
        if !waitUntil(3, { delay() != before }) { fail("\(sync)'s + left the delay at \(before)") }
        shot("\(name) sync stepped")
        #if os(iOS)
        // The delay in seconds: "+0.05 s", "−1.2 s".
        func seconds() -> Double {
            let text = delay().replacingOccurrences(of: "\u{2212}", with: "-")
            return Double(text.filter { $0.isNumber || $0 == "." || $0 == "-" }) ?? .nan
        }
        let stepped = seconds()
        // Held 1.6 s: a second at 0.5 s and every 0.2 s after, some 6; one step would be hundredths. Not on the Mac yet:
        // a held click there steps once.
        element("player.delay.increase").press(forDuration: 1.6)
        if !waitUntil(3, { seconds() >= stepped + 3 }) {
            fail("\(sync)'s + held 1.6 s moved the delay from \(stepped) to \(seconds()) only, not a second every 200 ms")
        }
        let held = seconds()
        // The delay must hold still for a second once + is let go.
        sleep(1)
        if seconds() != held { fail("\(sync)'s delay kept moving after + was let go: \(held) → \(seconds())") }
        shot("\(name) sync held")
        #endif
        tap(element("player.delay.reset"))
        if !waitUntil(3, { delay() == before }) { fail("\(sync)'s Reset left \(delay())") }
        #endif
        dismissMenu()
    }

    #if !os(tvOS)
    /// The mean luminance of a patch of the video at its leading side, clear of the controls and the menus; nil where
    /// it can't be read alike before and after a menu opens: on an iPhone (its landscape screen shot in portrait
    /// pixels) or over a black patch.
    private func videoPatchLuminance() -> Double? {
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone { return nil }
        #endif
        let video = element("player.video").frame
        let patch = CGRect(x: video.minX + video.width * 0.05, y: video.minY + video.height * 0.35,
                           width: video.width * 0.15, height: video.height * 0.15)
        guard let values = luminances(in: patch, "video"), !values.isEmpty else { return nil }
        let mean = values.reduce(0, +) / Double(values.count)
        return mean > 0.02 ? mean : nil
    }
    #endif

    /// The subtitle menu's Search Subtitles, where the server offers a search: its sheet (Apple TV: its page).
    private func subtitleSearch() {
        raiseControls()
        guard element("player.subtitles").exists(within: 3) else { return }
        activate("player.subtitles")
        #if os(tvOS)
        guard element("player.menu.search").exists(within: 3) else { return dismissMenu() }
        activate("player.menu.search")
        require("player.search.title", timeout: 5, "Search Subtitles opens its page")
        // The search's results load from the network before the shot.
        sleep(3)
        shot("subtitle-search")
        dismissMenu()
        #else
        guard let search = optionalEntry("Search Subtitles") else { return dismissMenu() }
        pick(search)
        require("player.search.sheet", timeout: 5, "Search Subtitles opens its sheet")
        // The search's results load from the network before the shot.
        sleep(3)
        shot("subtitle-search")
        closeSheet("player.search.sheet")
        #endif
    }

    /// The options menu and its pages: playback speed, version and quality, the sleep timer and file info.
    private func options() {
        raiseControls()
        activate("player.more")
        #if os(tvOS)
        require("player.menu", timeout: 5, "the options button opens its card")
        shot("options")
        for (option, name) in [("speed", "speed"), ("versions", "quality"), ("sleepTimer", "sleep timer"), ("fileInfo", "file info")] {
            let id = "player.option.\(option)"
            if !element(id).exists(within: 2) {
                raiseControls()
                activate("player.more")
            }
            guard element(id).exists(within: 3) else { continue }
            activate(id)
            // The page's animation and contents settle before the shot.
            sleep(2)
            shot(name)
            // Back to the options card.
            XCUIRemote.shared.press(.menu)
            _ = element(id).exists(within: 5)
        }
        dismissMenu()
        #else
        shotOfMenu("options")
        dismissMenu()
        for (label, name) in [("Playback Speed", "speed"), ("Version & Quality", "quality"), ("Sleep Timer", "sleep timer")] {
            raiseControls()
            activate("player.more")
            guard let page = optionalEntry(label) else {
                dismissMenu()
                continue
            }
            open(page)
            // The submenu's opening animation ends before the shot.
            sleep(1)
            shotOfMenu(name)
            dismissMenu()
        }
        raiseControls()
        activate("player.more")
        if let info = optionalEntry("File Info") {
            pick(info)
            require("player.fileInfo.sheet", timeout: 5, "File Info opens its sheet")
            // The sheet's presentation ends before the shot.
            sleep(2)
            shot("file info")
            #if os(iOS)
            // A path copied says so in a toast at the sheet's bottom edge, not over the fields mid-sheet. (The Mac's copy
            // would write the host's own pasteboard: there the toast's place is read from the sheet's layout instead.)
            let path = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'player.fileInfo.path.'")).firstMatch
            if path.exists(within: 5) {
                tap(path)
                let toast = require("player.fileInfo.copied", timeout: 5, "the toast saying the path was copied")
                shot("file info path copied")
                let sheet = element("player.fileInfo.sheet").frame
                XCTAssertGreaterThan(toast.frame.maxY, sheet.maxY - 100, "the copied toast sits at the sheet's bottom edge (toast \(toast.frame), sheet \(sheet))")
            }
            #endif
            closeSheet("player.fileInfo.sheet")
        } else {
            dismissMenu()
        }
        #endif
    }

    #if os(tvOS)
    /// Down from the timeline opens the panel on its first tab; each tab is shot; a chapter's card seeks and closes the
    /// panel; Up from the tabs closes it.
    private func panel() {
        raiseControls()
        guard focus(on: transport, at: element(transport).frame) else { return fail("the timeline never took focus") }
        XCUIRemote.shared.press(.down)
        let tabs = ["chapters", "queue"].map { "player.panel.\($0)" }
        guard waitUntil(5, { tabs.contains { self.element($0).exists } }) else { return fail("Down from the timeline opens no panel") }
        // The panel's slide-in ends before its tabs are read.
        sleep(1)
        let shown = tabs.filter { element($0).exists }
        for tab in shown {
            guard focusTab(tab, among: shown) else { return fail("\(tab) never took focus: focus on \(focusedId)") }
            _ = element("player.menu.item.0").exists(within: 5)
            shot("panel \(tab.dropFirst("player.panel.".count))")
            // The chapters' and the queue's item playing carries the now-playing mark, one item only.
            let items = (0..<60).map { element("player.menu.item.\($0)") }.prefix { $0.exists }
            let marked = items.filter { ($0.value as? String ?? "").hasPrefix("Now playing") }
            if marked.count != 1 { fail("\(tab) marks \(marked.count) items as playing") }
        }
        if shown.contains("player.panel.chapters") {
            guard focusTab("player.panel.chapters", among: shown) else { return fail("the chapters tab never took focus") }
            _ = element("player.menu.item.0").exists(within: 5)
            // Down from the tab to the chapters' cards, then along to the second.
            XCUIRemote.shared.press(.down)
            let second = "player.menu.item.1"
            if element(second).exists(within: 2), focus(on: second, at: element(second).frame) {
                XCUIRemote.shared.press(.select)
                if !waitUntil(5, { !self.element("player.chapters.panel").exists }) { fail("picking a chapter leaves the panel open") }
                raiseControls()
                guard focus(on: transport, at: element(transport).frame) else { return }
                XCUIRemote.shared.press(.down)
                _ = element(shown[0]).exists(within: 5)
                _ = waitUntil(3) { self.element(second).isSelected }
                // The chapter picked is the current one now (its card selected, its check and bold name).
                if element(second).exists(within: 3), !element(second).isSelected {
                    fail("after picking the second chapter it isn't the current one")
                }
            }
        }
        // Up from the tabs closes the panel.
        guard focusTab(shown[0], among: shown) else { return fail("\(shown[0]) never took focus: focus on \(focusedId)") }
        XCUIRemote.shared.press(.up)
        if !waitUntil(5, { !tabs.contains { self.element($0).exists } }) { fail("Up from the panel's tabs leaves it open") }
    }

    private var focusedId: String {
        let focused = app.descendants(matching: .any).matching(NSPredicate(format: "hasFocus == true")).firstMatch
        return (try? focused.snapshot())?.identifier ?? "nothing"
    }

    /// Focus onto the panel's tab `tab`: Up from a card to the tab shown, then along the tabs (`shown`, in order).
    private func focusTab(_ tab: String, among shown: [String]) -> Bool {
        for _ in 0..<8 {
            let now = focusedId
            if now == tab { return true }
            if let from = shown.firstIndex(of: now), let to = shown.firstIndex(of: tab) {
                XCUIRemote.shared.press(to > from ? .right : .left)
            } else {
                XCUIRemote.shared.press(.up)
            }
            _ = waitUntil(0.5) { self.focusedId == tab }
        }
        return focusedId == tab
    }
    #else
    /// The chapters button opens its list sheet (`sheet`), shot as `name`, the current chapter's row selected: Close
    /// closes it; the second row seeks there and closes it, and the sheet opened again has that row as the current one.
    private func listSheet(_ button: String, sheet: String, _ name: String) {
        raiseControls()
        guard element(button).exists(within: 3) else { return }
        activate(button)
        require(sheet, timeout: 5, "\(button) opens its sheet")
        // The sheet's presentation and its scroll to the current row end before the shot and the frame reads.
        sleep(2)
        shot(name)
        let items = rows()
        guard let current = items.firstIndex(where: \.isSelected) else { return fail("the \(name) sheet marks no row as the current one") }
        requireNowPlayingMark(items, current, name)
        requireCurrentRowInView(items[current], sheet: sheet, name)
        requireEveryRowShownOnIPad(items, sheet: sheet, name)
        requireFirstRowNearTop(items, sheet: sheet, name)
        closeSheet(sheet)
        if !waitUntil(5, { !self.element(sheet).exists }) { fail("Close leaves the \(name) sheet open") }
        let row = element("player.menu.item.1")
        raiseControls()
        activate(button)
        guard element(sheet).exists(within: 5), row.exists(within: 2) else { return }
        tap(row)
        if !waitUntil(5, { !self.element(sheet).exists }) { fail("picking a row of \(name) leaves its sheet open") }
        raiseControls()
        activate(button)
        require(sheet, timeout: 5, "\(button) opens its sheet again")
        if !waitUntil(3, { row.exists && row.isSelected }) { fail("after picking its second row, \(name) marks another as current") }
        shot("\(name) after a pick")
        closeSheet(sheet)
    }

    /// The queue button opens its sheet, the current item's row selected; a pick of the item after it plays that item
    /// (the title changes) and closes the sheet.
    private func queueSheet(picks: Bool) {
        raiseControls()
        guard element("player.queue").exists(within: 3) else { return }
        let before = state("item")
        activate("player.queue")
        require("player.queue.sheet", timeout: 5, "the queue button opens its sheet")
        // The sheet's presentation and its scroll to the current row end before the shot and the frame reads.
        sleep(2)
        shot("queue")
        let items = rows()
        guard let current = items.firstIndex(where: \.isSelected) else { return fail("the queue marks no item as playing") }
        requireNowPlayingMark(items, current, "queue")
        requireCurrentRowInView(items[current], sheet: "player.queue.sheet", "queue")
        requireEveryRowShownOnIPad(items, sheet: "player.queue.sheet", "queue")
        requireFirstRowNearTop(items, sheet: "player.queue.sheet", "queue")
        guard picks, current + 1 < items.count else {
            closeSheet("player.queue.sheet")
            if !waitUntil(5, { !self.element("player.queue.sheet").exists }) { fail("Close leaves the queue sheet open") }
            return
        }
        tap(items[current + 1])
        if !waitUntil(5, { !self.element("player.queue.sheet").exists }) { fail("picking a queue item leaves the sheet open") }
        // The playing item as the state has it (`player.state`'s item: the title and the episode line the top bar shows).
        if !waitUntil(30, { let now = self.state("item"); return !now.isEmpty && now != before }) {
            fail("picking the next queue item doesn't play it: the player still plays '\(state("item"))'")
        }
        shot("queue item playing")
    }

    /// The current row of a list carries the now-playing mark (its value "Now playing"), the chapters' and the queue's
    /// alike, and no other row does.
    private func requireNowPlayingMark(_ items: [XCUIElement], _ current: Int, _ name: String) {
        let marked = items.indices.filter { (items[$0].value as? String ?? "").hasPrefix("Now playing") }
        if marked != [current] { fail("the \(name) sheet's now-playing mark is on rows \(marked), its current row is \(current)") }
    }

    /// On an iPad the form sheet shows a short list whole: with a few rows, every one inside the sheet without scrolling.
    private func requireEveryRowShownOnIPad(_ items: [XCUIElement], sheet: String, _ name: String) {
        #if os(iOS)
        guard UIDevice.current.userInterfaceIdiom == .pad else { return }
        // Every row the sheet holds, drawn or not, against those shown.
        let all = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'player.menu.item.'")).allElementsBoundByIndex
        guard all.count <= 6 else { return }
        let bounds = element(sheet).frame
        // Inside the sheet's frame, not just hittable: a row clipped at the sheet's foot reads as hittable.
        let hidden = all.filter { !bounds.contains($0.frame) }.map(\.identifier)
        if !hidden.isEmpty || all.count < items.count { fail("the \(name) sheet hides \(hidden) of \(all.count) rows on iPad") }
        #endif
    }

    /// The sheet opens with its current row whole on screen, however far down the list it is: inside the sheet, below
    /// its header (the Mac's title over the list, iOS's bar) and above the Mac's Close at the sheet's foot.
    private func requireCurrentRowInView(_ row: XCUIElement, sheet: String, _ name: String) {
        let frame = row.frame
        let sheetElement = element(sheet)
        let sheetFrame = sheetElement.frame
        let window = app.windows.firstMatch.frame
        // A sheet's element can be reported larger than the window (an iPad form sheet): the part on screen counts.
        let clipped = sheetFrame.intersection(window)
        var bounds = clipped.isNull ? sheetFrame : clipped
        guard !frame.isEmpty, !bounds.isNull, !bounds.isInfinite else { return fail("the \(name) sheet's current row or the sheet has no frame") }
        var top = bounds.minY
        let title = element("player.list.title")
        if title.exists { top = max(top, title.frame.maxY) }
        let bar = sheetElement.navigationBars.firstMatch
        if bar.exists { top = max(top, bar.frame.maxY) }
        let close = element("player.menu.close")
        if close.exists, close.frame.minY > frame.midY { bounds.size.height = min(bounds.height, close.frame.minY - bounds.minY) }
        // Half a point of rounding.
        if frame.minY < top - 0.5 || frame.maxY > bounds.maxY + 0.5 {
            fail("the \(name) sheet opens with its current row at \(Int(frame.minY))–\(Int(frame.maxY)) pt, outside its list's \(Int(top))–\(Int(bounds.maxY)) pt")
        }
    }

    /// On an iPhone on its side the list gets the sheet: its first row starts within a quarter of the window's height
    /// of the sheet's top (`sheet`), not under a stack of handle, title and tabs. Where the sheet starts is the system's:
    /// at the window's top on an iPhone, lower in the Duo's taller window.
    private func requireFirstRowNearTop(_ items: [XCUIElement], sheet: String, _ name: String) {
        #if os(iOS)
        guard UIDevice.current.userInterfaceIdiom == .phone, let first = items.first else { return }
        let window = app.windows.firstMatch.frame
        guard window.width > window.height else { return }
        let chrome = first.frame.minY - element(sheet).frame.minY
        if chrome > window.height * 0.25 {
            fail("the \(name) sheet's first row starts \(Int(chrome)) pt below its top in a \(Int(window.height)) pt landscape window")
        }
        #endif
    }

    /// The open sheet's rows, in order.
    private func rows() -> [XCUIElement] {
        (0..<60).map { element("player.menu.item.\($0)") }.prefix { $0.exists }.map { $0 }
    }
    #endif

    // MARK: - Helpers

    /// The control that plays and pauses: the timeline on Apple TV, the transport's button elsewhere.
    private var transport: String {
        #if os(tvOS)
        "player.scrub"
        #else
        "player.playPause"
        #endif
    }

    /// The transport's label ("Play" while paused, "Pause" while playing), "" while the controls are down: read from a
    /// snapshot, which a control gone with the controls' timer fails without failing the test.
    private var transportLabel: String {
        (try? element(transport).snapshot().label) ?? ""
    }

    /// Plays or pauses: on Apple TV the remote's Play/Pause, which the player hears with the controls up or down (a walk
    /// of the focus to the timeline races their timer while the video plays), elsewhere the transport's button.
    private func playPause() {
        #if os(tvOS)
        XCUIRemote.shared.press(.playPause)
        #else
        activate(transport)
        #endif
    }

    /// Shows the controls if they went down.
    private func raiseControls() {
        // Up only where the store says so (`player.state`'s controls): going down, they stay in the tree while they
        // fade, and a tap then would hide them rather than bring them up.
        if element(transport).exists, state("controls") != "false" { return }
        #if os(tvOS)
        // A press while the player is still busy starting (a 4K remux) can go unheard: pressed again.
        for _ in 0..<3 where !element(transport).exists {
            XCUIRemote.shared.press(.up)
            _ = element(transport).exists(within: 3)
        }
        #elseif os(macOS)
        // The pointer has to move over the video: a hover where it already rests is no move.
        let video = element("player.video")
        video.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.3)).hover()
        video.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).hover()
        #else
        // A tap toggles them: one only while the store has them down, then a wait until it has them up.
        for _ in 0..<3 where state("controls") == "false" || !element(transport).exists {
            if state("controls") == "false" { element("player.video").tap() }
            _ = waitUntil(3) { self.state("controls") == "true" && self.element(self.transport).exists }
        }
        #endif
        _ = element(transport).exists(within: 3)
    }

    /// Presses the control `id`: a tap or click, or on Apple TV focus walked onto it (`focus(on:)`) and Select.
    private func activate(_ id: String) {
        let target = element(id)
        #if os(tvOS)
        guard target.exists(within: 3) else { return fail("no \(id) to focus") }
        // Focus lands a moment after the move the snapshot saw: walked again until it holds there half a second, and
        // where nothing takes it (focus lost as a card went), Up gives it back first.
        var held = false
        for attempt in 0..<3 where !held {
            if attempt > 0 { XCUIRemote.shared.press(.up) }
            // The target's frame from a snapshot: the controls can go down on their timer since the look.
            guard let frame = try? target.snapshot().frame, focus(on: id, at: frame) else { continue }
            Thread.sleep(forTimeInterval: 0.5)
            held = focusedId == id
        }
        guard held else { return fail("\(id) never took focus: \(stateReading)") }
        XCUIRemote.shared.press(.select)
        #else
        // The controls can hide on their timer between the look and the tap: brought up again for a control gone.
        if !target.exists(within: 2) {
            raiseControls()
            guard target.exists(within: 3) else { return fail("no \(id) with the controls up: \(stateReading)") }
        }
        #if os(iOS)
        // On a touch screen they hide a few seconds after they came up, paused too (`PlayerChrome`), and a busy
        // simulator can take that long from the look to XCTest's own tap, which then finds nothing: tapped where the
        // control is, read from a snapshot right after the probe says they show (nothing there: brought up again with
        // a tap, as a user would). A menu button's tap that came as they went landed on the video and brought them up
        // again, the wait for the menu then using up their time: so again, once they hid, brought up afresh and
        // tapped at once.
        let opensMenu = ["player.more", "player.audio", "player.subtitles"].contains(id)
        for attempt in 0..<3 {
            if attempt > 0, state("controls") == "true" { _ = waitUntil(6) { self.state("controls") == "false" } }
            if state("controls") == "false" { raiseControls() }
            guard let frame = try? target.snapshot().frame else {
                _ = waitUntil(3) { self.state("controls") == "false" }
                raiseControls()
                continue
            }
            app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: frame.midX, dy: frame.midY)).tap()
            if !opensMenu || app.collectionViews.firstMatch.exists(within: 3) { return }
        }
        fail("no \(id) to tap with the controls up: \(stateReading)")
        #else
        tap(target)
        #endif
        #endif
    }

    /// Closes the open menu, card or popover: Escape on the Mac, a tap beside it on iOS, Menu on Apple TV (twice, from
    /// a page of a card).
    private func dismissMenu() {
        #if os(tvOS)
        for _ in 0..<2 where element("player.menu").exists {
            XCUIRemote.shared.press(.menu)
            _ = waitUntil(1) { !self.element("player.menu").exists }
        }
        #elseif os(macOS)
        app.typeKey(.escape, modifierFlags: [])
        sleep(1)
        if app.menuItems.allElementsBoundByIndex.contains(where: { $0.isHittable }) { app.typeKey(.escape, modifierFlags: []) }
        #else
        element("player.video").coordinate(withNormalizedOffset: CGVector(dx: 0.12, dy: 0.5)).tap()
        // A busy simulator reports the controls again a while after the menu went: until then the tree lacks them.
        _ = waitUntil(10) { self.state("controls") == "false" || self.element(self.transport).exists }
        #endif
        // The menu's closing animation ends before the next press or tap.
        sleep(1)
    }

    #if os(tvOS)
    /// Moves focus onto the element `id`, which lies at `goal`: each move goes from the focused element towards it, along
    /// its line first when the two share one, else across, and the other way where a move left focus where it was. One
    /// query a move, for the focused element's identifier and frame.
    private func focus(on id: String, at goal: CGRect) -> Bool {
        let focused = app.descendants(matching: .any).matching(NSPredicate(format: "hasFocus == true")).firstMatch
        var last: (id: String, frame: CGRect, move: XCUIRemote.Button)?
        var stuck: Set<XCUIRemote.Button> = []
        var unreported = 0
        for _ in 0..<40 {
            // Nothing reported focused: a card coming up or going, or focus lost as a card went (after a pick): the
            // remote's Up after a while, which a user presses to get focus back.
            guard let now = try? focused.snapshot() else {
                unreported += 1
                if unreported % 3 == 0 { XCUIRemote.shared.press(.up) }
                _ = waitUntil(0.5) { (try? focused.snapshot()) != nil }
                continue
            }
            if now.identifier == id { return true }
            if let last, last.id == now.identifier, last.frame == now.frame {
                stuck.insert(last.move)
            } else {
                stuck = []
            }
            let across: XCUIRemote.Button = goal.midY > now.frame.midY ? .down : .up
            let along: XCUIRemote.Button = goal.midX > now.frame.midX ? .right : .left
            let sameLine = abs(goal.midY - now.frame.midY) < max(goal.height, now.frame.height) / 2
            guard let move = (sameLine ? [along, across] : [across, along]).first(where: { !stuck.contains($0) }) else {
                return false
            }
            XCUIRemote.shared.press(move)
            last = (now.identifier, now.frame, move)
        }
        return false
    }
    #else
    /// The open menu's entry `label` (an entry with a second line counts by its first): a menu item on the Mac, a
    /// button of the open menu on iOS. Fails with `what` unless it comes within 5 s.
    private func entry(_ label: String, _ what: String) -> XCUIElement {
        let found = optionalEntry(label)
        if found == nil { fail("\(what): no menu entry '\(label)'") }
        return found ?? app.menuItems.firstMatch
    }

    /// The open menu's entry `label` (on the Mac the entry `id` where one is given: its items carry their identifiers,
    /// iOS's don't), nil unless it comes within 5 s. `label` is the entry as shown: in English the options' names are
    /// title-cased on Apple menus ("Sleep Timer").
    private func optionalEntry(_ label: String, id: String? = nil) -> XCUIElement? {
        #if os(macOS)
        let matches = app.menuItems.matching(id.map { NSPredicate(format: "identifier == %@", $0) }
            ?? NSPredicate(format: "title == %@ OR label == %@ OR title BEGINSWITH %@", label, label, "\(label)\n"))
        var found: XCUIElement?
        // A submenu opens a moment after the click on its entry (AppKit's hover delay).
        _ = waitUntil(10) {
            found = (0..<matches.count).lazy.map { matches.element(boundBy: $0) }.first { $0.isHittable }
            return found != nil
        }
        if let found { record("before picking '\(label)': \(stateReading)") }
        return found
        #else
        // An iPhone's menu holds only the entries it shows, so one not in the tree yet is
        // brought in by dragging the menu's list, the narrowest list on the screen (the screen's own span it), half its
        // view at a time: up, as far as the list's foot (where a drag stops moving its entries), for one below, then
        // down for one above (a menu opened again keeps its scroll, at the foot after a pick there). An iPad's menu
        // holds them all. An entry in the tree but out of the menu's view (a submenu opened scrolled) is dragged to the
        // view's middle. Slow drags held at their end: a swipe flings the list on a
        // page or more, from one end past an entry in the middle (the options' HDR) to the other, or back and forth
        // over it, never stopping with it in view.
        let match = app.buttons.matching(NSPredicate(format: "label == %@ OR label BEGINSWITH %@", label, "\(label),")).firstMatch
        let phone = UIDevice.current.userInterfaceIdiom == .phone
        let found = match.exists(within: 5)
        guard found || phone, let menu = app.collectionViews.allElementsBoundByIndex
            .filter({ $0.exists && $0.frame.width < app.frame.width }).min(by: { $0.frame.width < $1.frame.width }) else {
            return found ? match : nil
        }
        // A phone's menu in landscape shows less than its list's frame says: the list runs on below the menu's platter
        // (a fifth of it on an iPhone 17, a fifteenth on the Duo), and a tap there lands beside the menu and closes it.
        // What shows is the platter: the tallest plain element at the list's top and leading edge, as wide and shorter
        // (over half as tall: not the menu's header). An iPad's menu shows its whole list.
        let list = menu.frame
        var platter = list
        if let tree = try? app.snapshot() {
            var nodes = [tree]
            var tallest = list.height / 2
            while let node = nodes.popLast() {
                nodes += node.children
                let frame = node.frame
                let edge = abs(frame.minX - list.minX) < 0.5 && abs(frame.minY - list.minY) < 0.5 && abs(frame.width - list.width) < 0.5
                if node.elementType == .other, edge, frame.height < list.height, frame.height > tallest {
                    tallest = frame.height
                    platter = frame
                }
            }
        }
        let view = platter.insetBy(dx: 0, dy: 8)
        // Moves the list's entries up by `distance` points (down for a negative one) from the view's middle.
        func drag(_ distance: CGFloat) {
            let distance = max(-view.height * 0.8, min(view.height * 0.8, distance))
            let start = app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: view.midX, dy: view.midY + distance / 2))
            start.press(forDuration: 0.05, thenDragTo: start.withOffset(CGVector(dx: 0, dy: -distance)), withVelocity: .slow, thenHoldForDuration: 0.3)
            // The list's scroll settles before its entries are compared.
            Thread.sleep(forTimeInterval: 0.5)
        }
        // Where the list's entries lie: the same after a drag its end stopped.
        let entries = { (try? menu.snapshot().children.map(\.frame)) ?? [] }
        var downTheList = true
        for _ in 0..<16 {
            guard match.exists else {
                let before = entries()
                drag(downTheList ? view.height / 2 : -view.height / 2)
                if !match.exists, entries() == before {
                    // The list's end: up the list from here; both ends met, the menu doesn't hold it.
                    if !downTheList { return nil }
                    downTheList = false
                }
                continue
            }
            // In view where it lies whole inside the menu's list (UIKit reports no hittability for an entry scrolled out
            // of the list: asking throws). Read once it holds still: the menu opening moves it.
            var frame = match.frame
            for _ in 0..<10 {
                Thread.sleep(forTimeInterval: 0.2)
                guard match.exists, match.frame != frame else { break }
                frame = match.frame
            }
            if frame.height > 0, frame.minY >= view.minY, frame.maxY <= view.maxY { return match }
            drag(frame.midY - view.midY)
        }
        return match.exists ? match : nil
        #endif
    }

    /// Opens the submenu `entry` of the open menu.
    private func open(_ entry: XCUIElement) {
        tap(entry)
    }

    /// Picks the entry `entry` of the open menu, which closes it.
    private func pick(_ entry: XCUIElement) {
        tap(entry)
        // The menu's closing animation ends before the next tap.
        Thread.sleep(forTimeInterval: 0.3)
    }

    /// Closes the open sheet `id`: its Close where it shows one, else a drag down (`dismissSheet`).
    private func closeSheet(_ id: String) {
        let sheet = element(id)
        if sheet.exists(within: 2) { dismissSheet(sheet, close: "player.menu.close") }
        _ = sheet.waitForNonExistence(timeout: 5)
    }
    #endif

    private func tap(_ element: XCUIElement) {
        #if os(macOS)
        element.click()
        #elseif os(iOS)
        element.tap()
        #endif
    }

    // MARK: - The state probe and the options

    /// The player's state probe (`player.state`: `firstFrame=…; performance=…; zoom=…; sleep=…; extend=…; osd=…`).
    private var stateReading: String {
        let probe = element("player.state")
        guard probe.exists else { return "" }
        if let value = probe.value as? String, !value.isEmpty { return value }
        return probe.label
    }

    /// The probe's field `key`.
    private func state(_ key: String) -> String {
        stateReading.components(separatedBy: "; ").first { $0.hasPrefix("\(key)=") }.map { String($0.dropFirst(key.count + 1)) } ?? ""
    }

    /// Whether the playback goes on for `seconds` more: the item has that long left (Now Playing's `duration`, less the
    /// position, `player.livePosition`) or has an item after it (Now Playing's `next`). Fails naming the item's numbers
    /// otherwise: the item, not the player, is what doesn't suit the test.
    private func requirePlaysOn(seconds: Int) -> Bool {
        let nowPlaying = require("player.nowPlaying", timeout: 30, "the player's Now Playing probe")
        // The Mac reports no plain element's value: the probes carry their readings as their labels too.
        func reading(_ probe: XCUIElement) -> String {
            if let value = probe.value as? String, !value.isEmpty { return value }
            return probe.label
        }
        func field(_ key: String) -> String {
            reading(nowPlaying).components(separatedBy: "; ").first { $0.hasPrefix("\(key)=") }
                .map { String($0.dropFirst(key.count + 1)) } ?? ""
        }
        guard waitUntil(30, { (Int(field("duration")) ?? 0) > 0 }) else {
            fail("Now Playing has no duration: \(reading(nowPlaying))")
            return false
        }
        let position = Double(reading(element("player.livePosition")).dropFirst("position=".count)) ?? 0
        let left = (Int(field("duration")) ?? 0) - Int(position)
        if left < seconds && field("next") != "true" {
            fail("PLEZY_PLAY plays \(left) s more with nothing after it; this test needs \(seconds) s: a longer item or an episode with one after it")
            return false
        }
        return true
    }

    /// The engine probe's (`player.engine`) mpv value `name`, as `name=value` in it.
    private func engineSetting(_ name: String) -> String {
        let probe = element("player.engine")
        guard probe.exists else { return "" }
        let reading = (probe.value as? String).flatMap { $0.isEmpty ? nil : $0 } ?? probe.label
        return reading.components(separatedBy: " ").first { $0.hasPrefix("\(name)=") }.map { String($0.dropFirst(name.count + 1)) } ?? ""
    }

    /// The seconds in a banner's time left: `4:59`, `1:02:03`, or `1m 48s` / `29s` / `1h 2m` ("Playback will pause in
    /// 1m 48s"); 0 without one.
    private func minutes(_ banner: String) -> Int {
        if let clock = banner.split(separator: " ").last(where: { $0.contains(":") }) {
            return clock.split(separator: ":").compactMap { Int($0.filter(\.isNumber)) }.reduce(0) { $0 * 60 + $1 }
        }
        return banner.split(separator: " ").reduce(0) { total, word in
            guard let unit = word.last, let value = Int(word.dropLast()) else { return total }
            switch unit {
            case "h": return total + value * 3600
            case "m": return total + value * 60
            case "s": return total + value
            default: return total
            }
        }
    }

    /// A note in the run's report.
    private func record(_ text: String) {
        let note = XCTAttachment(string: text)
        note.name = "note"
        note.lifetime = .keepAlways
        add(note)
    }

    /// Opens the options' page `label` (Apple TV: its row `id`): a submenu of the options menu, a page of its card.
    private func openOption(label: String, id: String) {
        openOptionsMenu()
        #if os(tvOS)
        require("player.menu", timeout: 5, "the options button opens its card")
        activate(id)
        _ = element("player.menu.item.0").exists(within: 5)
        #else
        guard let page = optionalEntry(label, id: id) else { return fail("the options menu has no \(label)") }
        open(page)
        // The submenu's opening animation ends before its shot or pick.
        sleep(1)
        #endif
    }

    /// Picks `choice` on the options' page `label` (Apple TV: its row `id`).
    private func pickOption(label: String, id: String, choice: String) {
        openOption(label: label, id: id)
        pickEntry(choice, id: nil)
    }

    /// Opens the options menu (Apple TV: its card). On Apple TV a card left open by the last step closes first, and
    /// where nothing has focus as it goes (the card's row went with it), Up gives focus back and brings the controls up.
    private func openOptionsMenu() {
        #if os(tvOS)
        dismissMenu()
        _ = waitUntil(3) { !self.element("player.menu").exists }
        let focused = app.descendants(matching: .any).matching(NSPredicate(format: "hasFocus == true")).firstMatch
        if !element(transport).exists || (try? focused.snapshot()) == nil {
            XCUIRemote.shared.press(.up)
            _ = element("player.more").exists(within: 3)
        }
        #endif
        raiseControls()
        activate("player.more")
    }

    /// Turns the options' switch `label` (Apple TV: its row `id`) over.
    private func toggleOption(label: String, id: String) {
        openOptionsMenu()
        #if os(tvOS)
        require("player.menu", timeout: 5, "the options button opens its card")
        activate(id)
        // The switch's press lands before Menu closes the card.
        sleep(1)
        dismissMenu()
        #else
        guard let entry = optionalEntry(label, id: id) else { return fail("the options menu has no \(label)") }
        pick(entry)
        #endif
    }

    /// Picks the open menu's entry `label` (Apple TV: the card's row `id`, else the row whose name starts `label`).
    private func pickEntry(_ label: String, id: String?) {
        #if os(tvOS)
        let target = id ?? (0..<40).map { "player.menu.item.\($0)" }.prefix { element($0).exists }.first {
            element($0).label.hasPrefix(label)
        }
        guard let target, element(target).exists(within: 3) else { return fail("the card has no \(label)") }
        activate(target)
        // The pick lands before the next press: a Menu too soon would leave the player.
        sleep(1)
        #else
        guard let found = optionalEntry(label) else { return fail("the open menu has no \(label)") }
        pick(found)
        #endif
    }
}
