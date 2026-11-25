import SwiftUI
import PlezyKit

// Watch Together in the player (`PlayerUiState.watch`): the session indicator in the controls, which opens the session
// sheet (`PlayerMenu.watchTogether`: a sheet on iOS and the Mac, the Options menu's page of the panel on Apple TV), the
// reconnecting pill and the locked-controls line over the video, the prompt card of a player that refused to start in a
// playing room, and the question when the room offers a copy of another length. The room's notices show as the player's
// transient message (the store's OSD); its play, pause, seek and speed controls show disabled while the room keeps them
// from this device (`PlayerUiState.canControl`, `canPlayPause`, `canSeek`).

/// The room's commands through the player's store.
private func send(_ command: any WatchCommand, to store: PlayerStore) {
    store.dispatch(command: PlayerCommandWatch(command: command))
}

/// The session indicator among the controls, while in a room and the playback's controls show: how many watch
/// together, the host's badge on the host's device (a crown where the badge doesn't fit), the sync symbol while not
/// connected, and "Reconnecting…" while the connection is down. It opens and closes the session sheet. VoiceOver hears
/// what it opens and the room's state. Accessibility identifier `player.watch`.
struct PlayerWatchIndicator: View {
    let state: PlayerUiState
    let store: PlayerStore

    @ScaledMetric(relativeTo: .body) private var symbolSize: CGFloat = PlayerMetrics.icon

    var body: some View {
        if state.showsPlaybackControls, let pill = state.watch?.pill {
            Button {
                let open = state.menu == .watchTogether
                store.dispatch(command: open ? PlayerCommandCloseMenu.shared : PlayerCommandOpenMenu(menu: .watchTogether))
            } label: {
                ViewThatFits(in: .horizontal) {
                    content(pill, host: .badge)
                    content(pill, host: .crown)
                    content(pill, host: nil)
                }
                .font(.system(size: symbolSize, weight: .semibold))
                #if !os(tvOS)
                .padding(.horizontal, 10)
                .frame(minHeight: PlayerMetrics.button)
                .contentShape(Capsule())
                #endif
            }
            #if os(tvOS)
            .buttonStyle(PlayerTVButtonStyle(shape: Capsule(), insets: EdgeInsets(top: 14, leading: 22, bottom: 14, trailing: 22)))
            #else
            .buttonStyle(PlayerPressStyle())
            #endif
            #if os(macOS)
            .tooltip(pill.label)
            #endif
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(pill.label)
            .accessibilityValue(pill.value)
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier("player.watch")
        }
    }

    /// How the host's device marks itself: the badge's text, or a crown where that doesn't fit.
    private enum HostMark { case badge, crown }

    private func content(_ pill: WatchPillUi, host mark: HostMark?) -> some View {
        HStack(spacing: mark == .badge ? 6 : 3) {
            Image(systemName: "person.2.fill")
            Text(pill.count).monospacedDigit()
            if pill.isHost {
                switch mark {
                case .badge:
                    Text(T.shared.watchTogether.hostBadge)
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Palette.onVideo.opacity(0.25)))
                case .crown:
                    Image(systemName: "crown.fill").font(.caption2.weight(.bold))
                case nil:
                    EmptyView()
                }
            }
            if !pill.connected {
                Image(systemName: "arrow.triangle.2.circlepath").font(.caption.weight(.bold))
            }
            if let status = pill.status { Text(status).font(.caption) }
        }
        .lineLimit(1)
        .fixedSize()
    }
}

/// Over the video, 120 pt above the bottom: "Reconnecting…" while the room's connection is down, in the player's
/// glass capsule (`player.watch.reconnecting`); and while the controls show, who controls playback while this device
/// may not, or that its player paused here alone, with a lock (`player.watch.locked`).
struct PlayerWatchStatus: View {
    let state: PlayerUiState

    var body: some View {
        VStack(spacing: 12) {
            if let text = state.watch?.reconnecting {
                Label(text, systemImage: "arrow.triangle.2.circlepath")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .playerGlass(in: Capsule())
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("player.watch.reconnecting")
                    .announcing(text)
            }
            if state.showsPlaybackControls, let locked = state.watch?.controlsLocked {
                PlayerControlsLockedLine(text: locked)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .padding(.bottom, 120)
        .allowsHitTesting(false)
    }
}

/// Who controls playback while this device may not ("Only Sam controls playback in this room"), or that its player
/// paused here alone while the room plays on (`player.watch.locked`).
struct PlayerControlsLockedLine: View {
    let text: String

    var body: some View {
        Label(text, systemImage: "lock.fill")
            .font(.footnote.weight(.semibold))
            .playerMuted()
            .lineLimit(2)
            .shadow(color: .black.opacity(0.4), radius: 6)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("player.watch.locked")
    }
}

/// The player refused to start in a playing room: "Playback didn't start", what it means, and Play, which starts the
/// player (`WatchCommandPlayBlockedPlayer`), as the player's prompt card. Play takes the remote's focus while it shows
/// (`PlayerFocus.watchPrompt`). Accessibility identifiers `player.watch.blocked`, `player.watch.blocked.play`.
struct PlayerWatchPromptCard: View {
    let blocked: WatchPlayBlockedUi
    let store: PlayerStore
    let focus: FocusState<PlayerFocus?>.Binding

    @ScaledMetric(relativeTo: .title) private var symbolSize: CGFloat = 36

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.2.fill")
                .font(.system(size: symbolSize))
            Text(blocked.title)
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
            Text(blocked.description_)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                send(WatchCommandPlayBlockedPlayer.shared, to: store)
            } label: {
                Label(blocked.play, systemImage: "play.fill")
            }
            .playerActionStyle(prominent: true)
            .focused(focus, equals: .watchPrompt)
            .accessibilityIdentifier("player.watch.blocked.play")
            .padding(.top, 4)
        }
        .padding(24)
        .frame(maxWidth: PlayerMetrics.promptMaxWidth)
        .playerGlass(in: RoundedRectangle(cornerRadius: PlayerMetrics.promptRadius, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("player.watch.blocked")
        .announcing(blocked.title)
    }
}

#if !os(tvOS)
/// The session sheet on iOS (half height on iPhone, pulled up to full) and the Mac: the room at a glance, a row each:
/// the room code with the connection and the count, Copy Code, the reconnecting banner, the media (its page: this
/// user's copy), Join Current Playback, the participants (their page: the host's actions on each), the offset (its
/// page), the host's settings, Leave Room and the host's End Room (each asked first). Pages open in the sheet with
/// their back button; Close (Escape; an iPhone's sheet has the grabber instead) closes it, and so does the room ending.
/// Accessibility identifiers `watch.sheet.code`, `watch.sheet.copy`, `watch.sheet.media`, `watch.sheet.joinPlayback`,
/// `watch.sheet.participants`, `watch.sheet.offset`, `watch.leave`, `watch.end`, `watch.sheet.close`.
struct WatchSessionSheet: View {
    let watch: PlayerWatchUi
    let store: PlayerStore

    @State private var path: [WatchPage] = []
    @State private var toast: String?

    var body: some View {
        let room = watch.room
        let actions = WatchRoomActions(
            execute: { send($0, to: store) },
            copy: { text, done in
                Pasteboard.copy(text)
                toast = done
            },
            open: { path.append($0) }
        )
        NavigationStack(path: $path) {
            Form {
                Section {
                    SettingsControlRow(title: room.header.code, subtitle: room.status, systemImage: "number") { EmptyView() }
                        .accessibilityElement(children: .combine)
                        .accessibilityIdentifier("watch.sheet.code")
                    SettingsLinkRow(title: room.header.copyLabel, systemImage: "doc.on.doc", trailingSymbol: nil, id: "watch.sheet.copy") {
                        actions.copy(room.header.code, room.header.copied)
                    }
                    if let banner = room.reconnecting { WatchReconnectingBanner(banner: banner) }
                }
                Section {
                    SettingsLinkRow(title: room.media.title ?? room.media.idle, subtitle: room.media.summary, systemImage: "film", id: "watch.sheet.media") {
                        path.append(.media)
                    }
                    if let join = room.media.joinPlayback {
                        SettingsLinkRow(title: join.label, subtitle: join.description_, systemImage: "play.fill", trailingSymbol: nil, id: "watch.sheet.joinPlayback") {
                            actions.execute(WatchCommandJoinPlayback.shared)
                        }
                    }
                    SettingsLinkRow(title: room.participantsTitle, value: room.participantCount, systemImage: "person.2", id: "watch.sheet.participants") {
                        path.append(.participants)
                    }
                    SettingsLinkRow(title: room.offset.title, value: room.offset.value, systemImage: "timer", id: "watch.sheet.offset") {
                        path.append(.offset)
                    }
                }
                if let settings = room.settings {
                    Section(settings.title) { WatchHostSettings(settings: settings, actions: actions) }
                }
                Section {
                    WatchConfirmRow(confirm: room.leave, systemImage: "rectangle.portrait.and.arrow.right", id: "watch.leave") {
                        actions.execute(WatchCommandLeave.shared)
                    }
                    if let end = room.end {
                        WatchConfirmRow(confirm: end, systemImage: "xmark.circle", id: "watch.end") {
                            actions.execute(WatchCommandEnd.shared)
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .pageTitle(room.title)
            .sheetToolbar(close: SheetAction(title: T.shared.nav.close, id: "watch.sheet.close") {
                store.dispatch(command: PlayerCommandCloseMenu.shared)
            })
            .navigationDestination(for: WatchPage.self) { page in
                Form {
                    WatchPageForm(page: page, room: watch.room, actions: actions) { if !path.isEmpty { path.removeLast() } }
                }
                .formStyle(.grouped)
                .pageTitle(watch.room.title(of: page))
            }
        }
        .toast(toast, id: "watch.toast") { toast = nil }
        .accessibilityIdentifier("watch.sheet")
    }
}
#endif

#if os(tvOS)
/// The session on Apple TV: the Options menu's page of the panel (`PlayerMenu.watchTogether`), opened from its row or
/// the room pill. The room code large with the connection and the count, the reconnecting banner, then a row each: the
/// media (its page: this user's copy), Join Current Playback, the participants (their page: the host's actions on
/// each), the offset (its page), the host's switches (checked while on), Leave Room and the host's End Room (each asked
/// first). A page opens in place, its first row focused; Menu goes back a page, and on the first one closes the menu
/// (the store's Back). Focus keys: `PlayerFocus.menuItem`, the first row's 0.
struct WatchTVSessionPanel: View {
    let watch: PlayerWatchUi
    let store: PlayerStore
    let focus: FocusState<PlayerFocus?>.Binding

    @State private var pages: [WatchPage] = []
    @State private var asking: Asking?
    /// The count of copies the room took when the copies page's pick went out; nil before one.
    @State private var picked: Int32?

    /// A question the panel asks (`Confirmation`): its text, its answers' identifiers' stem, and what a yes does.
    private struct Asking {
        let confirm: WatchConfirmUi
        let id: String
        let action: () -> Void
    }

    /// The focus keys of the first page's rows that open a page, and of a page's first row.
    private enum Key {
        static let media = 0
        static let participants = 2
        static let offset = 3
        static let pageFirst = 100
    }

    var body: some View {
        let room = watch.room
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                if let page = pages.last {
                    pageRows(page, room: room).id(page)
                } else {
                    rootRows(room)
                }
            }
            // Rows in from the card's edges, as AVKit's menus have them.
            .padding(.horizontal, 12)
        }
        .frame(maxHeight: 600)
        .accessibilityIdentifier("watch.sheet")
        .backAction(pages.isEmpty ? nil : { pop() })
        .confirmation(asking.map { Confirmation($0.confirm, id: $0.id) }, onConfirm: {
            let action = asking?.action
            asking = nil
            action?()
        }, onCancel: { asking = nil })
        // A participant's page whose actions went (they left, this device hosts no more) goes back.
        .onChange(of: participantGone) { _, gone in if gone { pop() } }
        // The copies page closes once the room took this page's pick; a refused one leaves it open.
        .onChange(of: watch.room.media.copies.chosen) { _, chosen in
            if let at = picked, chosen > at, pages.last == .copies {
                picked = nil
                pop()
            }
        }
    }

    private var actions: WatchRoomActions {
        WatchRoomActions(execute: { send($0, to: store) }, copy: { _, _ in }, open: push)
    }

    @ViewBuilder
    private func rootRows(_ room: WatchRoomUi) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(room.header.code)
                .font(.system(.title, design: .monospaced).weight(.bold))
                .tracking(4)
                .accessibilityIdentifier("watch.sheet.code")
            Text(room.status).font(.caption).foregroundStyle(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
        if let banner = room.reconnecting { WatchReconnectingBanner(banner: banner).padding(.horizontal, 20) }
        PanelRow(label: room.media.title ?? room.media.idle, detail: room.media.summary, value: "", symbol: "film", selected: false) { push(.media) }
            .focused(focus, equals: .menuItem(Key.media))
            .accessibilityIdentifier("watch.sheet.media")
        if let join = room.media.joinPlayback {
            PanelRow(label: join.label, detail: join.description_, symbol: "play.fill", chevron: false, selected: false) {
                actions.execute(WatchCommandJoinPlayback.shared)
            }
            .focused(focus, equals: .menuItem(1))
            .accessibilityIdentifier("watch.sheet.joinPlayback")
        }
        PanelRow(label: room.participantsTitle, detail: nil, value: room.participantCount, symbol: "person.2", selected: false) { push(.participants) }
            .focused(focus, equals: .menuItem(Key.participants))
            .accessibilityIdentifier("watch.sheet.participants")
        PanelRow(label: room.offset.title, detail: nil, value: room.offset.value, symbol: "timer", selected: false) { push(.offset) }
            .focused(focus, equals: .menuItem(Key.offset))
            .accessibilityIdentifier("watch.sheet.offset")
        if let settings = room.settings {
            PanelRow(label: settings.everyone.label, detail: settings.everyone.detail, chevron: false, selected: settings.everyone.checked) {
                actions.execute(WatchCommandSetEveryoneControls(everyone: !settings.everyone.checked))
            }
            .accessibilityIdentifier("watch.everyone")
            PanelRow(label: settings.lock.label, detail: settings.lock.detail, chevron: false, selected: settings.lock.checked) {
                actions.execute(WatchCommandLock(locked: !settings.lock.checked))
            }
            .accessibilityIdentifier("watch.lock")
        }
        PanelRow(label: room.leave.label, detail: nil, symbol: "rectangle.portrait.and.arrow.right", chevron: false, selected: false) {
            asking = Asking(confirm: room.leave, id: "watch.leave") { actions.execute(WatchCommandLeave.shared) }
        }
        .accessibilityIdentifier("watch.leave")
        if let end = room.end {
            PanelRow(label: end.label, detail: nil, symbol: "xmark.circle", chevron: false, selected: false) {
                asking = Asking(confirm: end, id: "watch.end") { actions.execute(WatchCommandEnd.shared) }
            }
            .accessibilityIdentifier("watch.end")
        }
    }

    @ViewBuilder
    private func pageRows(_ page: WatchPage, room: WatchRoomUi) -> some View {
        Text(room.title(of: page))
            .font(.headline)
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
            .accessibilityIdentifier("watch.page.title")
        switch page {
        case .media:
            WatchMediaSection(media: room.media, actions: actions, heading: false)
                .padding(.horizontal, 20)
                .focusSection()
                .defaultFocus(focus, .menuItem(Key.pageFirst))
        case .participants:
            ForEach(Array(room.participants.enumerated()), id: \.element.peerId) { index, participant in
                // A row without actions is a row of its own all the same, which Select leaves alone: focus stays in
                // the page (Menu goes back), and the remote reads every participant.
                WatchPanelParticipantRow(participant: participant) {
                    if participant.actions != nil { push(.participant(participant.peerId)) }
                }
                .focused(focus, equals: .menuItem(Key.pageFirst + index))
                .accessibilityIdentifier("watch.participant.\(participant.peerId)")
            }
        case .participant(let peerId):
            if let participantActions = room.participants.first(where: { $0.peerId == peerId })?.actions {
                PanelRow(label: participantActions.makeHost.label, detail: nil, symbol: "star", chevron: false, selected: false) {
                    asking = Asking(confirm: participantActions.makeHost, id: "watch.makeHost") {
                        actions.execute(WatchCommandMakeHost(peerId: peerId))
                        pop()
                    }
                }
                .focused(focus, equals: .menuItem(Key.pageFirst))
                .accessibilityIdentifier("watch.makeHost")
                PanelRow(label: participantActions.remove.label, detail: nil, symbol: "person.badge.minus", chevron: false, selected: false) {
                    asking = Asking(confirm: participantActions.remove, id: "watch.kick") {
                        actions.execute(WatchCommandKick(peerId: peerId))
                        pop()
                    }
                }
                .accessibilityIdentifier("watch.kick")
            }
        case .offset:
            WatchOffsetSection(offset: room.offset, actions: actions, heading: false)
                .padding(.horizontal, 20)
                .focusSection()
        case .copies:
            let copies = room.media.copies
            ForEach(Array(copies.rows.enumerated()), id: \.element.id) { index, row in
                PanelRow(label: row.title, detail: row.subtitle, chevron: false, selected: row.current) {
                    picked = copies.chosen
                    actions.execute(WatchCommandChooseCopy(candidateId: row.id))
                }
                .focused(focus, equals: .menuItem(Key.pageFirst + index))
                .accessibilityIdentifier("watch.candidate.\(index)")
            }
            if let empty = copies.empty { Text(empty).padding(.horizontal, 20).accessibilityIdentifier("watch.copies.empty") }
            if let searching = copies.searching { ProgressLine(text: searching).padding(.horizontal, 20) }
            PanelRow(label: copies.searchAgain, detail: nil, symbol: "arrow.clockwise", chevron: false, selected: false) {
                actions.execute(WatchCommandSearchAgain.shared)
            }
            .disabled(!copies.searchAgainEnabled)
            .accessibilityIdentifier("watch.copies.searchAgain")
        }
    }

    /// The open participant's page has no actions any more.
    private var participantGone: Bool {
        guard case .participant(let peerId) = pages.last else { return false }
        return watch.room.participants.first { $0.peerId == peerId }?.actions == nil
    }

    private func push(_ page: WatchPage) {
        pages.append(page)
        focus.wrappedValue = .menuItem(Key.pageFirst)
    }

    private func pop() {
        guard let page = pages.popLast() else { return }
        focus.wrappedValue = switch page {
        case .media, .copies: .menuItem(Key.media)
        case .participants: .menuItem(Key.participants)
        case .participant: .menuItem(Key.pageFirst)
        case .offset: .menuItem(Key.offset)
        }
    }
}

/// A participant on the panel's page: the person symbol, the name with the host's badge beside it, the details; a
/// chevron where the host has actions on them.
private struct WatchPanelParticipantRow: View {
    let participant: ParticipantUi
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: participant.connected ? "person.fill" : "person.slash.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 36)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(participant.name).font(.body).lineLimit(1)
                        if let badge = participant.hostBadge { BadgeView(text: badge, emphasis: .strong) }
                    }
                    Text(participant.details)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 16)
                if participant.actions != nil {
                    Image(systemName: "chevron.forward")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(PanelRowStyle())
        .accessibilityElement(children: .combine)
    }
}
#endif

extension View {
    /// The player's question when the room offers a copy of another length (`PlayerWatchUi.mismatch`): a sheet with
    /// the copy, Play Anyway (focused), Choose Another Copy (its page in the sheet) and Don't Play. It opens once per
    /// mismatch (`WatchMismatchUi.key`) when no menu is open (it waits for that to close), and closes itself once that
    /// mismatch is settled, here or elsewhere. Close, a swipe down, Escape or Menu close it. Accessibility identifier
    /// `watch.mismatch`.
    func watchMismatchPrompt(_ state: PlayerUiState, store: PlayerStore) -> some View {
        modifier(WatchMismatchPrompt(watch: state.watch, menuOpen: state.menu != nil, store: store))
    }
}

private struct WatchMismatchPrompt: ViewModifier {
    let watch: PlayerWatchUi?
    let menuOpen: Bool
    let store: PlayerStore

    /// The mismatches asked about: each once.
    @State private var asked: Set<String> = []
    /// The mismatch the sheet shows.
    @State private var showing: String?

    private struct Trigger: Equatable {
        let key: String?
        let menuOpen: Bool
    }

    func body(content: Content) -> some View {
        let key = watch?.mismatch?.key
        content
            .appSheet(isPresented: Binding(get: { showing != nil && showing == key }, set: { if !$0 { showing = nil } }), id: "watch.mismatch.panel", size: .player) {
                if let watch, let mismatch = watch.mismatch {
                    WatchMismatchSheet(watch: watch, mismatch: mismatch, store: store) { showing = nil }
                }
            }
            .onChange(of: Trigger(key: key, menuOpen: menuOpen), initial: true) { _, trigger in
                if showing != nil, showing != trigger.key { showing = nil }
                if let key = trigger.key, showing == nil, !trigger.menuOpen, !asked.contains(key) {
                    asked.insert(key)
                    showing = key
                }
            }
    }
}

/// The mismatch's sheet: the block under the mismatch's title, Choose Another Copy pushing the copies.
private struct WatchMismatchSheet: View {
    let watch: PlayerWatchUi
    let mismatch: WatchMismatchUi
    let store: PlayerStore
    let close: () -> Void

    @State private var path: [WatchPage] = []
    @FocusState private var playFocused: Bool

    var body: some View {
        let actions = WatchRoomActions(execute: { send($0, to: store) }, copy: { _, _ in }, open: { path.append($0) })
        NavigationStack(path: $path) {
            Form {
                Section {
                    WatchMismatchBlock(mismatch: mismatch, actions: actions, showsTitle: false, playFocus: $playFocused)
                        .padding(.vertical, 4)
                }
                SheetActionsSection(actions: [SheetAction(title: T.shared.nav.close, id: "watch.mismatch.close", action: close)])
            }
            .formStyle(.grouped)
            .pageTitle(mismatch.title)
            .sheetToolbar(close: SheetAction(title: T.shared.nav.close, id: "watch.mismatch.close", action: close))
            .navigationDestination(for: WatchPage.self) { page in
                Form {
                    WatchPageForm(page: page, room: watch.room, actions: actions) { if !path.isEmpty { path.removeLast() } }
                }
                .formStyle(.grouped)
                .pageTitle(watch.room.title(of: page))
            }
        }
        .accessibilityIdentifier("watch.mismatch")
        .task { playFocused = true }
    }
}
