import SwiftUI
import PlezyKit

// The parts of a Watch Together room (`WatchRoomUi`) that the screen stacks as cards and the player's session sheet
// gives a row or a page each: the room code, the media and this user's copy, the offset, the participants, the host's
// settings, and the questions asked before leaving, ending, handing over and removing. Every text comes from the
// shared state.

/// A page of a room's sheet: the media, the participants, one participant's actions, the offset, the copies.
enum WatchPage: Hashable {
    case media
    case participants
    case participant(String)
    case offset
    case copies
}

extension WatchRoomUi {
    /// `page`'s title in this room.
    func title(of page: WatchPage) -> String {
        switch page {
        case .media: media.heading
        case .participants: participantsTitle
        case .participant(let peerId): participants.first { $0.peerId == peerId }?.actions?.title ?? participantsTitle
        case .offset: offset.title
        case .copies: media.copies.title
        }
    }
}

/// What a room's controls do: `execute` runs the room's commands (the screen's store, or the player's
/// `PlayerCommandWatch`), `copy` puts text on the pasteboard and says what it did ("Room code copied"), `open` opens a
/// page (in the open sheet, or as a sheet of its own).
struct WatchRoomActions {
    let execute: (any WatchCommand) -> Void
    let copy: (_ text: String, _ done: String) -> Void
    let open: (WatchPage) -> Void
}

extension Confirmation {
    /// The question asked before `confirm`'s action, its answers identified `<id>.confirm` and `<id>.cancel`. On Apple
    /// TV Leave Room's (`watch.leave`) Leave is drawn destructive: the system's alert there starts focus on the answer
    /// unless it is destructive, and the question then opens on Cancel.
    init(_ confirm: WatchConfirmUi, id: String) {
        #if os(tvOS)
        let destructive = confirm.destructive || id == "watch.leave"
        #else
        let destructive = confirm.destructive
        #endif
        self.init(
            title: confirm.question,
            message: confirm.message,
            confirmLabel: confirm.confirm,
            cancelLabel: confirm.cancel,
            destructive: destructive,
            confirmId: "\(id).confirm",
            cancelId: "\(id).cancel"
        )
    }
}

/// A room's button: native, with its symbol; while `busy` a spinner in the symbol's place ("Creating room…").
struct WatchButton: View {
    let title: String
    var systemImage: String?
    let id: String
    var prominence: ButtonProminence = .secondary
    var fullWidth = false
    var enabled = true
    var busy = false
    let action: () -> Void

    var body: some View {
        if busy {
            ActionButton(title: title, id: id, prominence: prominence, fullWidth: fullWidth, enabled: false, icon: ProgressView().controlSize(.small), action: action)
        } else {
            ActionButton(title: title, id: id, prominence: prominence, systemImage: systemImage, fullWidth: fullWidth, enabled: enabled, action: action)
        }
    }
}

/// Muted text: a label over a value, a description under a title.
struct WatchMuted: View {
    let text: String
    var large = false

    var body: some View {
        Text(text)
            .font(large ? .subheadline : .footnote)
            .mutedForeground()
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// "Reconnecting…": the connection dropped, and the room comes back by itself (`watch.reconnecting`).
struct WatchReconnectingBanner: View {
    let banner: WatchBannerUi

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.arrow.triangle.2.circlepath").accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(banner.title).font(.headline)
                Text(banner.description_).font(.footnote)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Palette.primary.opacity(0.16), in: RoundedRectangle(cornerRadius: Radius.medium, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("watch.reconnecting")
        .announcing(banner.title)
    }
}

/// The room code and who runs the room: the code under its label, Copy Code and Share Invite (each putting text on
/// the pasteboard; Apple TV has none, so neither shows there and the code stands alone, very large, for a phone to
/// type), the host, who controls playback (to a guest; the host's setting says it), the lock.
/// Accessibility identifiers `watch.code`, `watch.copy`, `watch.share`, `watch.role`, `watch.locked`.
struct WatchRoomHeader: View {
    let header: WatchHeaderUi
    let actions: WatchRoomActions
    /// The screen's focus, which Copy Code takes as `.code` (the screen's first control in a room).
    var focus: FocusState<WatchScreenFocus?>.Binding?

    var body: some View {
        VStack(spacing: 4) {
            WatchMuted(text: header.codeLabel, large: true)
            Text(header.code)
                #if os(tvOS)
                .font(.system(size: 140, weight: .bold, design: .monospaced))
                .tracking(12)
                #else
                .font(.system(.largeTitle, design: .monospaced).weight(.bold))
                .textSelection(.enabled)
                .tracking(4)
                #endif
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .accessibilityIdentifier("watch.code")
            #if !os(tvOS)
            WatchButtonRow(centred: true) {
                WatchButton(title: header.copyLabel, systemImage: "doc.on.doc", id: "watch.copy") {
                    actions.copy(header.code, header.copied)
                }
                .modifier(OptionalScreenFocus(focus: focus, value: .code))
                WatchButton(title: header.share, systemImage: "square.and.arrow.up", id: "watch.share") {
                    actions.copy(header.invite, header.invited)
                }
            }
            .padding(.vertical, 8)
            #endif
            if !header.role.isEmpty {
                Text(header.role).font(.subheadline).accessibilityIdentifier("watch.role")
            }
            if let control = header.control { WatchMuted(text: control) }
            if let locked = header.locked {
                Label(locked, systemImage: "lock.fill")
                    .font(.footnote)
                    .mutedForeground()
                    .accessibilityIdentifier("watch.locked")
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }
}

/// `focused` where a binding is given.
private struct OptionalFocus: ViewModifier {
    let focus: FocusState<Bool>.Binding?

    func body(content: Content) -> some View {
        if let focus { content.focused(focus) } else { content }
    }
}

/// `focused(_:equals:)` where the screen's focus is given.
private struct OptionalScreenFocus: ViewModifier {
    let focus: FocusState<WatchScreenFocus?>.Binding?
    let value: WatchScreenFocus

    func body(content: Content) -> some View {
        if let focus { content.focused(focus, equals: value) } else { content }
    }
}

/// Now Playing: the room's media (or that nothing plays), whether others can find it, this user's copy, Join Current
/// Playback and the host's Stop Video for Everyone. Accessibility identifiers `watch.media`, `watch.joinPlayback`,
/// `watch.stop`.
struct WatchMediaSection: View {
    let media: WatchMediaUi
    let actions: WatchRoomActions
    /// The heading shows (the screen's card); a page's title already says it.
    var heading = true

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if heading { WatchMuted(text: media.heading, large: true) }
            if let title = media.title {
                Text(title).font(.headline).lineLimit(1).accessibilityIdentifier("watch.media")
                if let note = media.notShareable {
                    Label { WatchMuted(text: note) } icon: { Image(systemName: "info.circle").foregroundStyle(Palette.onSurfaceVariant) }
                        .padding(.top, 4)
                        .accessibilityIdentifier("watch.notShareable")
                }
                if let match = media.match {
                    WatchMatchSection(match: match, actions: actions).padding(.top, 8)
                }
                if let join = media.joinPlayback {
                    WatchMuted(text: join.description_).padding(.top, 12)
                    WatchButton(title: join.label, systemImage: "play.fill", id: "watch.joinPlayback", prominence: .primary) {
                        actions.execute(WatchCommandJoinPlayback.shared)
                    }
                    .padding(.top, 4)
                }
                if let stop = media.stop {
                    WatchButton(title: stop, systemImage: "stop.fill", id: "watch.stop") {
                        actions.execute(WatchCommandStopMedia.shared)
                    }
                    .padding(.top, 8)
                }
            } else {
                Text(media.idle).font(.headline).accessibilityIdentifier("watch.media")
                WatchMuted(text: media.idleDetail)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// This user's copy of the room's media: shared, searched for, of another length, playing, or not found.
private struct WatchMatchSection: View {
    let match: WatchMatchUi
    let actions: WatchRoomActions

    var body: some View {
        switch onEnum(of: match) {
        case .sharing(let sharing):
            WatchCopySummary(copy: sharing.copyUi)
        case .searching(let searching):
            ProgressLine(text: searching.text).accessibilityIdentifier("watch.searching")
        case .mismatch(let mismatch):
            WatchMismatchBlock(mismatch: mismatch.mismatch, actions: actions, showsTitle: true)
        case .playing(let playing):
            VStack(alignment: .leading, spacing: 8) {
                if let copy = playing.copyUi {
                    WatchCopySummary(copy: copy, label: playing.label)
                } else {
                    Text(playing.label).font(.subheadline)
                }
                if let choose = playing.chooseAnother {
                    WatchButton(title: choose, systemImage: "arrow.left.arrow.right", id: "watch.chooseAnother") { actions.open(.copies) }
                }
            }
        case .unavailable(let unavailable):
            VStack(alignment: .leading, spacing: 4) {
                Text(unavailable.title).font(.subheadline.weight(.semibold))
                WatchMuted(text: unavailable.description_)
                WatchButtonRow {
                    WatchButton(title: unavailable.choose, systemImage: "film.stack", id: "watch.chooseCopy") { actions.open(.copies) }
                    WatchButton(title: unavailable.searchAgain, systemImage: "arrow.clockwise", id: "watch.searchAgain") {
                        actions.execute(WatchCommandSearchAgain.shared)
                    }
                }
                .padding(.top, 4)
            }
        }
    }
}

/// Buttons side by side at their whole widths, starting a new line where the width runs out (never cut short), each
/// with its title beside its symbol.
struct WatchButtonRow<Content: View>: View {
    var centred = false
    @ViewBuilder let content: () -> Content

    var body: some View {
        FlowLayout(spacing: 8, alignment: centred ? .center : .leading) { content() }
            .labelStyle(.titleAndIcon)
            .frame(maxWidth: .infinity, alignment: centred ? .center : .leading)
    }
}

/// The closest copy differs in length: what that means, the copy, Play Anyway (`.primary`), Choose Another Copy and
/// Don't Play. `showsTitle` off where the page's title already says it (the player's prompt). Accessibility
/// identifiers `watch.playAnyway`, `watch.mismatchChoose`, `watch.dontPlay`.
struct WatchMismatchBlock: View {
    let mismatch: WatchMismatchUi
    let actions: WatchRoomActions
    let showsTitle: Bool
    var playFocus: FocusState<Bool>.Binding?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if showsTitle { Text(mismatch.title).font(.subheadline.weight(.semibold)) }
            WatchMuted(text: mismatch.description_, large: true)
            WatchCopySummary(copy: mismatch.copyUi)
            WatchButtonRow {
                WatchButton(title: mismatch.playAnyway, systemImage: "play.fill", id: "watch.playAnyway", prominence: .primary) {
                    actions.execute(WatchCommandPlayAnyway.shared)
                }
                .modifier(OptionalFocus(focus: playFocus))
                WatchButton(title: mismatch.chooseAnother, systemImage: "arrow.left.arrow.right", id: "watch.mismatchChoose") {
                    actions.open(.copies)
                }
                WatchButton(title: mismatch.dontPlay, systemImage: "nosign", id: "watch.dontPlay") {
                    actions.execute(WatchCommandDontPlay.shared)
                }
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A copy: `label` (its own unless given), its title, then version, server and length.
struct WatchCopySummary: View {
    let copy: WatchCopyUi
    var label: String?

    init(copy: WatchCopyUi, label: String? = nil) {
        self.copy = copy
        self.label = label ?? copy.label
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let label { Text(label).font(.caption.weight(.medium)).foregroundStyle(Palette.onSurfaceVariant) }
            Text(copy.title).font(.body)
            if !copy.details.isEmpty { WatchMuted(text: copy.details) }
        }
        .accessibilityElement(children: .combine)
    }
}

/// Sync Offset: the value, what it does, the steps and Reset, and the copy's length difference offered as the offset.
/// Accessibility identifiers `watch.offset.value`, `watch.offset.<i>` for the steps, `watch.offset.reset`,
/// `watch.offset.apply`.
struct WatchOffsetSection: View {
    let offset: WatchOffsetUi
    let actions: WatchRoomActions
    var heading = true

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                if heading { Text(offset.title).font(.subheadline.weight(.semibold)) }
                Spacer(minLength: 8)
                Text(offset.value).font(.headline.monospacedDigit()).accessibilityIdentifier("watch.offset.value")
            }
            WatchMuted(text: offset.description_)
            WatchButtonRow {
                ForEach(Array(offset.steps.enumerated()), id: \.offset) { index, step in
                    WatchButton(title: step.label, id: "watch.offset.\(index)", enabled: step.enabled) {
                        actions.execute(WatchCommandSetOffset(offsetMs: step.offsetMs))
                    }
                }
                WatchButton(title: offset.reset.label, systemImage: "arrow.counterclockwise", id: "watch.offset.reset", enabled: offset.reset.enabled) {
                    actions.execute(WatchCommandSetOffset(offsetMs: offset.reset.offsetMs))
                }
            }
            .padding(.top, 4)
            if let hint = offset.hint, let apply = offset.apply {
                WatchMuted(text: hint).padding(.top, 8)
                WatchButton(title: apply.label, systemImage: "slider.horizontal.3", id: "watch.offset.apply", enabled: apply.enabled) {
                    actions.execute(WatchCommandSetOffset(offsetMs: apply.offsetMs))
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A participant: the person symbol (crossed out once dropped), the name with the host's badge, then app, connection,
/// player, match and offset. The host opens another's actions (`onOpen`, a chevron); without actions it is no control.
/// Accessibility identifier `watch.participant.<peer id>`.
struct WatchParticipantRow: View {
    let participant: ParticipantUi
    let onOpen: (() -> Void)?

    var body: some View {
        if let onOpen {
            Button(action: onOpen) {
                content(chevron: true).contentShape(Rectangle())
            }
            .formRowButtonStyle()
            .accessibilityIdentifier("watch.participant.\(participant.peerId)")
        } else {
            content(chevron: false)
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("watch.participant.\(participant.peerId)")
        }
    }

    private func content(chevron: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: participant.connected ? "person.fill" : "person.slash.fill")
                .frame(width: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(participant.name).lineLimit(1)
                    if let badge = participant.hostBadge { BadgeView(text: badge, emphasis: .strong) }
                }
                if !participant.details.isEmpty { WatchMuted(text: participant.details) }
            }
            Spacer(minLength: 8)
            if chevron {
                Image(systemName: "chevron.forward")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, 4)
    }
}

/// The host's room settings: who controls playback, and the lock (`watch.everyone`, `watch.lock`).
struct WatchHostSettings: View {
    let settings: WatchHostSettingsUi
    let actions: WatchRoomActions

    var body: some View {
        SettingsToggleRow(title: settings.everyone.label, subtitle: settings.everyone.detail, checked: settings.everyone.checked, id: "watch.everyone") {
            actions.execute(WatchCommandSetEveryoneControls(everyone: $0))
        }
        SettingsToggleRow(title: settings.lock.label, subtitle: settings.lock.detail, checked: settings.lock.checked, id: "watch.lock") {
            actions.execute(WatchCommandLock(locked: $0))
        }
    }
}

/// A row that asks first (`confirm`): its label, then the question once chosen (the system alert, `confirmation`);
/// `onConfirmed` once answered yes. Accessibility identifier `id`, the question's answers `<id>.confirm`
/// and `<id>.cancel`.
struct WatchConfirmRow: View {
    let confirm: WatchConfirmUi
    let systemImage: String
    let id: String
    let onConfirmed: () -> Void

    @State private var asking = false

    var body: some View {
        Button(role: confirm.destructive ? .destructive : nil) {
            asking = true
        } label: {
            Label(confirm.label, systemImage: systemImage)
                .destructiveLabel(confirm.destructive)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
        }
        .formRowButtonStyle()
        .accessibilityIdentifier(id)
        .confirmation(asking ? Confirmation(confirm, id: id) : nil, onConfirm: {
            asking = false
            onConfirmed()
        }, onCancel: { asking = false })
    }
}

/// A button that asks first: Leave Room and End Room under the room's cards.
struct WatchConfirmButton: View {
    let confirm: WatchConfirmUi
    let systemImage: String
    let id: String
    let onConfirmed: () -> Void

    @State private var asking = false

    var body: some View {
        WatchButton(title: confirm.label, systemImage: systemImage, id: id) { asking = true }
            .confirmation(asking ? Confirmation(confirm, id: id) : nil, onConfirm: {
                asking = false
                onConfirmed()
            }, onCancel: { asking = false })
    }
}

/// A page's content as a form's sections: the media and this user's copy, the participants, one participant's
/// actions (closed once they have none: gone, or no longer the host's to act on), the offset, the copies. `onClose`
/// closes the page (a copy chosen, the room handed over, a participant removed).
struct WatchPageForm: View {
    let page: WatchPage
    let room: WatchRoomUi
    let actions: WatchRoomActions
    let onClose: () -> Void

    var body: some View {
        switch page {
        case .media:
            Section { WatchMediaSection(media: room.media, actions: actions, heading: false).padding(.vertical, 4) }
        case .participants:
            Section {
                ForEach(room.participants, id: \.peerId) { participant in
                    WatchParticipantRow(participant: participant, onOpen: participant.actions.map { _ in { actions.open(.participant(participant.peerId)) } })
                }
            }
        case .participant(let peerId):
            let participant = room.participants.first { $0.peerId == peerId }
            if let participantActions = participant?.actions {
                Section {
                    WatchConfirmRow(confirm: participantActions.makeHost, systemImage: "star", id: "watch.makeHost") {
                        actions.execute(WatchCommandMakeHost(peerId: peerId))
                        onClose()
                    }
                    WatchConfirmRow(confirm: participantActions.remove, systemImage: "person.badge.minus", id: "watch.kick") {
                        actions.execute(WatchCommandKick(peerId: peerId))
                        onClose()
                    }
                }
            } else {
                Section {}.task { onClose() }
            }
        case .offset:
            Section { WatchOffsetSection(offset: room.offset, actions: actions, heading: false).padding(.vertical, 4) }
        case .copies:
            WatchCopiesSection(copies: room.media.copies, actions: actions, onChosen: onClose)
        }
    }
}

/// Choose a Copy: this user's copies, closest length first (a check on the one playing); none found or the search that
/// runs; Search Again. A pick plays it for the room, and `onChosen` closes the page once the room took it
/// (`WatchCopiesUi.chosen` grew); a pick the room refused leaves the page open (the store says why). Accessibility
/// identifiers `watch.candidate.<i>`, `watch.copies.empty`, `watch.copies.searchAgain`.
struct WatchCopiesSection: View {
    let copies: WatchCopiesUi
    let actions: WatchRoomActions
    let onChosen: () -> Void

    /// The count of copies taken when this page's pick went out; nil before one.
    @State private var picked: Int32?

    var body: some View {
        Section {
            ForEach(Array(copies.rows.enumerated()), id: \.element.id) { index, row in
                SettingsLinkRow(
                    title: row.title,
                    subtitle: row.subtitle,
                    systemImage: row.current ? "checkmark.circle.fill" : "film",
                    trailingSymbol: nil,
                    id: "watch.candidate.\(index)"
                ) {
                    picked = copies.chosen
                    actions.execute(WatchCommandChooseCopy(candidateId: row.id))
                }
                .accessibilityAddTraits(row.current ? .isSelected : [])
            }
            if let empty = copies.empty {
                Text(empty).accessibilityIdentifier("watch.copies.empty")
            }
            if let searching = copies.searching {
                ProgressLine(text: searching)
            }
            SettingsLinkRow(title: copies.searchAgain, systemImage: "arrow.clockwise", trailingSymbol: nil, id: "watch.copies.searchAgain") {
                actions.execute(WatchCommandSearchAgain.shared)
            }
            .disabled(!copies.searchAgainEnabled)
        }
        .onChange(of: copies.chosen) { _, chosen in
            if let at = picked, chosen > at {
                picked = nil
                onChosen()
            }
        }
    }
}

/// A page of a room as a sheet of its own (the screen's participant actions and copies): its title, its form, Close.
/// Pages it opens replace it.
struct WatchPageSheet: View {
    let page: WatchPage
    let room: WatchRoomUi
    let actions: WatchRoomActions
    let onClose: () -> Void

    var body: some View {
        let close = SheetAction(title: T.shared.nav.close, id: "watch.sheet.close", action: onClose)
        SheetPage(id: "watch.sheet", title: room.title(of: page), close: close) {
            Form {
                WatchPageForm(page: page, room: room, actions: actions, onClose: onClose)
                SheetActionsSection(actions: [close])
            }
            .settingsForm()
        }
    }
}
