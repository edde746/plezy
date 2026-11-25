import SwiftUI
import PlezyKit

/// The cast button: the picker's opener (`CastSender.openPicker`), its symbol filled and tinted while this device casts.
/// In the look of where it sits (`Look`): a detail's action row, a page's navigation bar (`castInTopBar`), the player's
/// top bar, Now Playing's. A detail's, a navigation bar's and Now Playing's present the picker themselves: a popover
/// anchored to the button on iPad and the Mac, the app's sheet on iPhone, a `TrailingPanel` on Apple TV; the player's
/// leaves it to the player's own host (`castPlayerPicker`), as its controls hide while the picker is up. Accessibility
/// identifier `id`; while casting, selected, its value "Casting to <device>".
struct CastButton: View {
    enum Look {
        /// A round glass button beside a detail's or music's Play.
        case detail
        /// A button of a page's navigation bar, across from Back (`castInTopBar`).
        case toolbar
        /// A button of the video player's top bar (`PlayerIconButton`).
        case player
        /// A button of Now Playing's top bar.
        case nowPlaying
    }

    let look: Look
    let id: String

    @Environment(\.cast) private var cast
    @Environment(\.formFactor) private var formFactor
    /// This button opened the picker that shows: of the cast buttons on screen (a detail's under Now Playing too), it
    /// alone presents it.
    @State private var opened = false

    var body: some View {
        if let cast {
            let state = cast.senderState.state
            let casting = state.casting
            let fromPlayer = look == .player || look == .nowPlaying
            let button = button(cast: cast, casting: casting) {
                opened = look != .player
                cast.sender.openPicker(fromPlayer: fromPlayer)
            }
            .accessibilityValue(casting ? T.shared.cast.bar.castingTo(name: state.receiverName) : "")
            .accessibilityAddTraits(casting ? .isSelected : [])
            if look == .player {
                button
            } else {
                button
                    .castPicker(cast, compact: formFactor == .compact, isPresented: Binding(
                        get: { opened && state.picker != nil },
                        set: { shown in
                            guard !shown else { return }
                            opened = false
                            if cast.senderState.state.picker != nil { cast.sender.closePicker() }
                        }
                    ))
                    .onChange(of: state.picker == nil) { _, closed in if closed { opened = false } }
            }
        }
    }

    @ViewBuilder
    private func button(cast: CastModel, casting: Bool, action: @escaping () -> Void) -> some View {
        let symbol = castSymbol(casting: casting)
        let label = T.shared.cast.title
        switch look {
        case .detail:
            IconButton(systemImage: symbol, label: label, id: id, action: action)
                .symbolStyle(casting ? AnyShapeStyle(Palette.primary) : AnyShapeStyle(.primary))
        case .toolbar:
            // The bar draws its own glass around it.
            Button(action: action) {
                Image(systemName: symbol).foregroundStyle(casting ? AnyShapeStyle(Palette.primary) : AnyShapeStyle(.primary))
            }
            .accessibilityLabel(label)
            .accessibilityIdentifier(id)
        case .player:
            PlayerIconButton(systemImage: symbol, label: label, id: id, selected: casting, action: action)
        case .nowPlaying:
            #if os(macOS)
            Button(action: action) {
                Image(systemName: symbol)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(casting ? Palette.primary : Palette.onBackground)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PressDimButtonStyle())
            .tooltip(label)
            .accessibilityLabel(label)
            .accessibilityIdentifier(id)
            #else
            MusicIconButton(systemImage: symbol, label: label, size: 20, tint: casting ? Palette.primary : nil, id: id, action: action)
            #endif
        }
    }
}

extension View {
    /// On phones (`FormFactor.compact`, iOS) the page's cast button in its navigation bar, across from Back, out of its
    /// action row, so the row stays the same whether a cast device is there or not. `id` the button's identifier.
    func castInTopBar(id: String) -> some View {
        modifier(CastTopBar(id: id))
    }
}

private struct CastTopBar: ViewModifier {
    let id: String

    @Environment(\.formFactor) private var formFactor

    func body(content: Content) -> some View {
        #if os(iOS)
        content.toolbar {
            if formFactor == .compact {
                ToolbarItem(placement: .topBarTrailing) { CastButton(look: .toolbar, id: id) }
            }
        }
        #else
        content
        #endif
    }
}

extension View {
    /// The video player's cast picker: the picker its top bar's cast button opened (`CastPickerUiState.fromPlayer`),
    /// presented over the player while it is open: a sheet on iPhone, iPad and the Mac, a `TrailingPanel` on Apple TV.
    func castPlayerPicker(_ cast: CastModel) -> some View {
        let state = cast.senderState.state
        let shown = Binding(
            get: { state.picker?.fromPlayer == true },
            set: { if !$0, cast.senderState.state.picker != nil { cast.sender.closePicker() } }
        )
        #if os(tvOS)
        return trailingPanel(isPresented: shown, id: "cast.picker.panel") { CastPicker(cast: cast) }
        #else
        return appSheet(isPresented: shown, id: "cast.picker.panel", size: .panel) {
            CastPicker(cast: cast)
                #if os(macOS)
                .frame(minHeight: 360)
                #endif
        }
        #endif
    }

    /// The picker anchored to this view (a cast button): a popover on iPad and the Mac, the app's sheet in a `compact`
    /// window (an iPhone: half height, pulled up to full), a `TrailingPanel` on Apple TV. Closed by the user (a tap
    /// outside, a swipe, Escape, the remote's Menu), `isPresented` goes false.
    @ViewBuilder
    fileprivate func castPicker(_ cast: CastModel, compact: Bool, isPresented: Binding<Bool>) -> some View {
        #if os(tvOS)
        trailingPanel(isPresented: isPresented, id: "cast.picker.panel") { CastPicker(cast: cast) }
        #else
        if compact {
            appSheet(isPresented: isPresented, id: "cast.picker.panel", size: .panel) { CastPicker(cast: cast) }
        } else {
            statePresentation(isPresented) { base, shown in
                base.popover(isPresented: shown) {
                    CastPicker(cast: cast)
                        #if os(iOS)
                        .frame(minWidth: 340, idealWidth: 380, minHeight: 300, idealHeight: 340)
                        #else
                        .frame(width: 340, height: 280)
                        #endif
                }
            }
        }
        #endif
    }
}

/// The device picker (`CastPickerUiState`): its title, a spinner and "Looking for devices…" while it looks, "This
/// device" first, then the receivers found, each with its kind's icon, its name and its platform ("Playing <title>"
/// where one already plays, "Connecting…" while its link opens); the target checked, a spinner in place of the check
/// while connecting. No receiver found: a line that says how to make one appear. While the chosen receiver asks its
/// user, the pairing code in its place (`CastPairingView`). It keeps showing the picker it last had while it animates
/// out.
///
/// Accessibility identifiers: `cast.picker`, `cast.picker.searching`, `cast.picker.empty`, `cast.picker.thisDevice`,
/// `cast.picker.device.<i>` (its value "selected" or "connecting" while it is), and the pairing view's.
struct CastPicker: View {
    let cast: CastModel

    @State private var last: CastPickerUiState?

    var body: some View {
        let picker = cast.senderState.state.picker ?? last
        Group {
            if let picker {
                if let pairing = picker.pairing {
                    CastPairingView(pairing: pairing, onCancel: cast.sender.closePicker)
                } else {
                    list(picker)
                }
            }
        }
        .onChange(of: cast.senderState.state.picker, initial: true) { _, picker in
            if let picker { last = picker }
        }
    }

    /// The list under the title: the app's sheet header on iOS (`SheetPage`, its Close where the sheet has no grabber),
    /// a line of its own in the Mac's popover and Apple TV's panel.
    @ViewBuilder
    private func list(_ picker: CastPickerUiState) -> some View {
        #if os(iOS)
        SheetPage(
            id: "cast.picker",
            title: T.shared.cast.picker.title,
            close: SheetAction(title: T.shared.common.close, id: "cast.picker.close", action: cast.sender.closePicker)
        ) {
            rows(picker).listStyle(.insetGrouped)
        }
        #else
        VStack(alignment: .leading, spacing: 0) {
            Text(T.shared.cast.picker.title)
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 8)
            rows(picker)
                #if os(macOS)
                .listStyle(.inset)
                #endif
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("cast.picker")
        #endif
    }

    /// This device, then the receivers found, under a spinner while the picker looks.
    private func rows(_ picker: CastPickerUiState) -> some View {
        List {
            Section {
                CastPickerRow(
                    symbol: thisDeviceSymbol, title: T.shared.cast.picker.thisDevice, subtitle: nil,
                    selected: picker.thisDeviceSelected, connecting: false, id: "cast.picker.thisDevice",
                    action: cast.sender.chooseThisDevice
                )
                ForEach(Array(picker.devices.enumerated()), id: \.element.device.id) { index, row in
                    CastPickerRow(
                        symbol: row.device.kind.systemImage,
                        title: row.device.name,
                        subtitle: row.connecting ? T.shared.cast.picker.connecting : row.nowPlaying ?? row.device.platform,
                        selected: row.selected,
                        connecting: row.connecting,
                        id: "cast.picker.device.\(index)"
                    ) { cast.sender.choose(deviceId: row.device.id) }
                }
            } header: {
                if picker.searching {
                    HStack(spacing: 8) {
                        ProgressView()
                            #if !os(tvOS)
                            .controlSize(.small)
                            #endif
                        Text(T.shared.cast.picker.searching)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("cast.picker.searching")
                }
            } footer: {
                if picker.devices.isEmpty {
                    Text(T.shared.cast.picker.empty)
                        .accessibilityIdentifier("cast.picker.empty")
                }
            }
        }
    }
}

/// A row of the picker: the device's icon, its name and a second line, and the check (a spinner while connecting).
private struct CastPickerRow: View {
    let symbol: String
    let title: String
    let subtitle: String?
    let selected: Bool
    let connecting: Bool
    let id: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: symbol)
                    .font(.title3)
                    .frame(width: 32)
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .lineLimit(1)
                    if let subtitle {
                        Text(subtitle)
                            .font(.footnote)
                            .mutedForeground()
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
                if connecting {
                    ProgressView()
                        #if !os(tvOS)
                        .controlSize(.small)
                        #endif
                } else if selected {
                    Image(systemName: "checkmark")
                        .font(.body.weight(.semibold))
                }
            }
            .contentShape(Rectangle())
        }
        #if !os(tvOS)
        .buttonStyle(.plain)
        #endif
        .accessibilityElement(children: .combine)
        .accessibilityValue(connecting ? "connecting" : selected ? "selected" : "")
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier(id)
    }
}

/// The picker while the chosen receiver asks its user (`CastPairingCode`): "Confirm on <device>", the 4-digit code
/// both show, what to check, and Cancel, which closes the picker and cancels the pairing (as the remote's Menu,
/// Escape and a swipe down do).
///
/// Accessibility identifiers: `cast.pairing`, `cast.pairing.code`, `cast.pairing.cancel`.
struct CastPairingView: View {
    let pairing: CastPairingCode
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield")
                .font(.largeTitle)
                .foregroundStyle(Palette.onSurfaceVariant)
                .accessibilityHidden(true)
            Text(pairing.title)
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
            CodeText(code: pairing.code, id: "cast.pairing.code")
            Text(pairing.message)
                .font(.subheadline)
                .foregroundStyle(Palette.onSurfaceVariant)
                .multilineTextAlignment(.center)
            Button(T.shared.common.cancel, action: onCancel)
                #if !os(tvOS)
                .buttonStyle(.bordered)
                .keyboardShortcut(.cancelAction)
                #endif
                .accessibilityIdentifier("cast.pairing.cancel")
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("cast.pairing")
        .announcing(pairing.title)
    }
}
