import SwiftUI
import PlezyKit

/// The profile picker (`ProfilePickerStore`): a required pick (the app's start) asks "Who's watching?" over the tiles;
/// one opened later is a page titled in its navigation bar for the entry that opened it (Manage profiles from Manage
/// profiles, else Switch Profile). The profiles are avatar tiles (`ProfileTile`:
/// Manage under each outside a required pick, its menu of Show profile link, Delete and Sign out), then Add profile. A
/// tap switches; once the switch is past its PIN, "Switching profile…" covers the screen. Pushed over another screen,
/// it has the stack's own Back (leaving a pick the app waits for answers no); a required pick at the bottom of the stack
/// has no Back but the app's own. On Apple TV the first tile takes focus as the picker shows.
struct ProfilePickerScreen: View {
    let app: AppModel
    let route: any Route

    @State private var model: StoreModel<ProfilePickerStore, ProfilePickerUiState>?
    @FocusState private var focusedTile: Int?
    @Environment(\.dimens) private var dimens

    init(app: AppModel, route: any Route) {
        self.app = app
        self.route = route
        _model = State(initialValue: StoreModel(app.session.profilePicker(route: route)) { $0.state })
    }

    var body: some View {
        if let model {
            let state = model.state.state
            ZStack {
                content(model, state)
                if state.switching {
                    Palette.background.opacity(0.85).ignoresSafeArea()
                    ProgressLine(text: T.shared.profiles.switchingProfile)
                        .accessibilityIdentifier("picker.switching")
                }
            }
            .pageTitle(state.title, inContent: state.required)
            .confirmation(
                state.confirm?.dialog,
                onConfirm: { model.store.setConfirmToggle(checked: false); model.store.confirm() },
                onToggledConfirm: { model.store.setConfirmToggle(checked: true); model.store.confirm() },
                onCancel: { model.store.dismissConfirm() }
            )
            .toast(state.message, id: "picker.message") { model.store.messageShown() }
            .appSheet(
                isPresented: Binding(get: { state.link != nil }, set: { if !$0 { model.store.dismissLink() } }),
                id: "picker.linkPanel", size: .fullHeightPanel
            ) {
                if let link = state.link {
                    LinkDialog(
                        link: link.url,
                        hint: link.hint,
                        id: "picker.link",
                        onCopied: { model.store.linkCopied() },
                        onClose: { model.store.dismissLink() }
                    )
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("picker.screen")
            .task { await model.state.observe() }
        }
    }

    /// The focus id of Add profile.
    private static let addTile = -1

    /// Between a tile and its Manage: on Apple TV clear of the focused tile, which grows.
    #if os(tvOS)
    private static let manageGap: CGFloat = 20
    #else
    private static let manageGap: CGFloat = 4
    #endif

    @ViewBuilder
    private func content(_ model: StoreModel<ProfilePickerStore, ProfilePickerUiState>, _ state: ProfilePickerUiState) -> some View {
        if state.loading {
            LoadingStateView()
        } else {
            let menus = !state.required && !state.switching
            GeometryReader { proxy in
                ScrollView {
                    VStack(spacing: dimens.sectionSpacing) {
                        if state.required {
                            Text(state.title)
                                .font(.largeTitle.weight(.semibold))
                                .multilineTextAlignment(.center)
                                .accessibilityAddTraits(.isHeader)
                        }
                        if state.tiles.isEmpty {
                            Text(T.shared.messages.noProfilesAvailable).foregroundStyle(Palette.onSurfaceVariant)
                        }
                        FlowLayout(spacing: dimens.gutter * 2) {
                            ForEach(Array(state.tiles.enumerated()), id: \.element.id) { index, tile in
                                VStack(spacing: Self.manageGap) {
                                    ProfileTile(tile: tile, index: index, enabled: !state.switching, menu: menus) {
                                        model.store.select(id: tile.id)
                                    } act: {
                                        model.store.act(id: tile.id, action: $0)
                                    }
                                    .focused($focusedTile, equals: index)
                                    if !state.required, tile.actions.contains(.manage) {
                                        Button { model.store.act(id: tile.id, action: .manage) } label: {
                                            Label(T.shared.profiles.manage, systemImage: "slider.horizontal.3")
                                        }
                                        .buttonStyle(.bordered)
                                        #if os(iOS)
                                        // The primary label colour, not the window's grey tint (iPad's); Apple TV's
                                        // bordered button would fill with it.
                                        .tint(Palette.onBackground)
                                        #endif
                                        .controlSize(.small)
                                        .disabled(state.switching)
                                        .accessibilityIdentifier("picker.tile.\(index).manage")
                                    }
                                }
                            }
                            AddProfileTile(enabled: !state.switching) { model.store.addProfile() }
                                .focused($focusedTile, equals: Self.addTile)
                        }
                        .frame(maxWidth: 960)
                        .shelfFocusSection()
                        #if os(tvOS)
                        // A move into the tiles lands on the first, wherever it comes from.
                        .defaultFocus($focusedTile, state.tiles.isEmpty ? Self.addTile : 0, priority: .userInitiated)
                        #endif
                    }
                    .padding(dimens.screenPadding)
                    .padding(.vertical, 24)
                    .frame(maxWidth: .infinity, minHeight: proxy.size.height)
                }
            }
            .task {
                #if os(tvOS)
                await FocusRestore.restore($focusedTile, to: state.tiles.isEmpty ? Self.addTile : 0, hold: 1)
                #endif
            }
        }
    }
}

/// A profile: its avatar (a lock badge where a PIN guards it, a check on the active one), its name and its
/// connections (or "No connections" in the error colour) under it; the whole tile is the button that picks it. Manage is
/// the button under it (`ProfilePickerScreen`); its other entries (Show profile link, Delete, Sign out) are its context
/// menu (a long press, a right click, a long press of Select on the remote) and VoiceOver's actions on it; neither while
/// switching or in a required pick (`menu`).
private struct ProfileTile: View {
    let tile: ProfileTileUi
    let index: Int
    let enabled: Bool
    let menu: Bool
    let pick: () -> Void
    let act: (ProfileAction) -> Void

    @Environment(\.dimens) private var dimens

    var body: some View {
        let entries = menu ? tile.actions.filter { $0 != .manage }.map(entry) : []
        Button {
            // The active profile is the one in use: picking it again does nothing.
            if !tile.active { pick() }
        } label: {
            VStack(spacing: 10) {
                ProfileAvatar(name: tile.name, url: tile.avatarUrl, size: dimens.avatar)
                    .overlay(alignment: .bottomTrailing) {
                        if let badge {
                            Image(systemName: badge)
                                .font(.footnote.weight(.semibold))
                                .frame(width: 32, height: 32)
                                .background(Palette.surfaceContainerHighest, in: Circle())
                        }
                    }
                    .focusRing(radius: dimens.avatar / 2)
                Text(tile.name).font(.headline).lineLimit(1)
                #if os(tvOS)
                // One line: a tile grown by a second line in the picker's scroll view gets no context menu from a
                // held Select. VoiceOver still reads the whole caption.
                Text(captionLines.joined(separator: " · "))
                    .font(.footnote)
                    .foregroundStyle(captionColor)
                    .lineLimit(1)
                #else
                // A line each, cut short alone: a long server name never hides the connection after it.
                VStack(spacing: 2) {
                    ForEach(Array(captionLines.enumerated()), id: \.offset) { _, line in
                        Text(line).lineLimit(1)
                    }
                }
                .font(.footnote)
                .foregroundStyle(captionColor)
                #endif
            }
            .frame(width: dimens.avatar + 24)
            .padding(12)
        }
        .buttonStyle(TileButtonStyle())
        .disabled(!enabled)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(tile.active ? .isSelected : [])
        .accessibilityActions(entries)
        .accessibilityIdentifier("picker.tile.\(index)")
        .itemMenu(entries: entries, probe: "picker.tile.\(index).menu")
    }

    private var badge: String? {
        if tile.active { return "checkmark" }
        return tile.locked ? "lock.fill" : nil
    }

    /// The connections' labels, or "No connections".
    private var captionLines: [String] {
        tile.hasConnections ? tile.chips.map(\.label) : [T.shared.profiles.noConnections]
    }

    private var captionColor: Color {
        tile.hasConnections ? Palette.onSurfaceVariant : Palette.error
    }

    private func entry(_ action: ProfileAction) -> ItemMenuEntry {
        let profiles = T.shared.profiles
        return switch action {
        case .manage: ItemMenuEntry(label: profiles.manage, systemImage: "slider.horizontal.3") { act(action) }
        case .showLink: ItemMenuEntry(label: T.shared.deepLinks.showProfileLink, systemImage: "qrcode") { act(action) }
        case .delete: ItemMenuEntry(label: profiles.delete, systemImage: "trash", destructive: true) { act(action) }
        case .signOut: ItemMenuEntry(label: profiles.signOut, systemImage: "rectangle.portrait.and.arrow.right", destructive: true) {
            act(action)
        }
        }
    }
}

/// Add profile: an empty avatar with a plus.
private struct AddProfileTile: View {
    let enabled: Bool
    let action: () -> Void

    @Environment(\.dimens) private var dimens

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Circle()
                    .fill(Palette.surfaceContainerHigh)
                    .frame(width: dimens.avatar, height: dimens.avatar)
                    .overlay { Image(systemName: "plus").font(.largeTitle).accessibilityHidden(true) }
                    .focusRing(radius: dimens.avatar / 2)
                Text(T.shared.profiles.addProfile)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(width: dimens.avatar + 24)
            .padding(12)
        }
        .buttonStyle(TileButtonStyle())
        .disabled(!enabled)
        .accessibilityIdentifier("picker.add")
    }
}
