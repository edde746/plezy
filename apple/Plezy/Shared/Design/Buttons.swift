import SwiftUI
import PlezyKit

/// How much a button stands out. Every button is a native one: Liquid Glass on iOS, macOS and tvOS 26 and later
/// (`.glassProminent`, `.glass`), the bordered styles before.
enum ButtonProminence {
    /// The one main action of a screen or sheet: a white fill with black text (iOS, macOS). On tvOS, where only focus
    /// turns a control white, a prominent button in a solid tint of the accent (`Palette.primaryRest`), stronger than a
    /// secondary's glass, in a heavier weight.
    case primary
    /// Other actions: a glass (bordered, a solid grey) fill.
    case secondary
    /// A text button (iOS, macOS): Cancel, "Use your own server". tvOS has no text buttons: a glass one.
    case plain
    /// Sign out, delete, reset: `secondary` in the system's destructive red.
    case destructive
}

extension View {
    /// The native button style for `prominence`; `menu` for a menu in it (Play's chevron), which keeps taking touches
    /// while a menu is open.
    func buttonProminence(_ prominence: ButtonProminence, menu: Bool = false) -> some View {
        modifier(ProminenceStyle(prominence: prominence, menu: menu))
    }

    /// `.glass` on 26 and later, `.bordered` before: a secondary action, a link pill, an icon button. The Mac fills a
    /// glass button with the tint, and the app's tint is white (`plezyTheme`): there these drop it, so they stay
    /// neutral glass and don't look like the primary action.
    func glassButtonStyle() -> some View {
        modifier(GlassButtonStyle())
    }

    /// A link pill or a chip (a genre, a cast member, a filter): a glass (bordered) capsule, solid, never outlined.
    func pillButtonStyle() -> some View {
        glassButtonStyle().buttonBorderShape(.capsule)
    }

    /// A round glass control, a button or a menu (`IconButton`, Detail's download, trailers and ⋯, `FilterMenu`): the
    /// glass button style in `shape` (`.circle` or `.capsule`). The Mac draws the glass button style on a menu as a flat
    /// grey shape and gives a menu no border shape, so there menus and buttons alike are plain in Liquid Glass of that
    /// shape (the system's regular material before macOS 26; `glassCapsule` for a capsule), their symbol white in an
    /// active and an inactive window alike. iOS 26 sizes a button-styled menu as a capsule whatever its border shape
    /// (Detail's ⋯ was 58×48 pt around its 48 pt circle; iOS 27 sizes it as a circle), so on iOS a circle that is a
    /// `menu` is drawn as the Mac's are. A capsule (a filter, a header row's titled action) is drawn so on iOS too: the
    /// glass button style pads a menu more than a button, and a symbol alone less than a line of text, so Library's sort
    /// menu stood 31 pt tall beside its 25 pt Filters button on iPhone (iOS 27.0). Its label takes
    /// `roundGlassLabel(shape, menu:)`.
    func roundGlassControl(_ shape: ButtonBorderShape = .circle, menu: Bool = false) -> some View {
        modifier(RoundGlassControl(shape: shape, menu: menu))
    }

    /// The label of a `roundGlassControl` in `shape`. The Mac's pads itself into the glass, so the whole shape takes the
    /// click: a circle's symbol by `IconButton.circleInset`, a capsule's text as the toolbar's is
    /// (`glassCapsuleLabel`). On iOS a round `menu`'s symbol pads itself into its circle alike, and a capsule's line (a
    /// line of text tall, `FilterCapsule`) by the header row's insets, so every capsule and every header row's circle
    /// (`screenHeader`) has one height. In an action row (`ActionRow`) a circle's symbol sits in the row's square
    /// (`ActionLabel`), so every circle is as tall as the row's pills.
    func roundGlassLabel(_ shape: ButtonBorderShape = .circle, menu: Bool = false) -> some View {
        modifier(RoundGlassLabel(shape: shape, menu: menu))
    }

    /// A pill's label (Play, Shuffle, a page's button): in an action row (`ActionRow`) exactly the row's line, so the
    /// pills and the circles beside them are one height; elsewhere at the large control size at least that tall
    /// (`ActionLabel`).
    func actionLabel() -> some View {
        modifier(ActionLabel(round: false))
    }

    /// Neighbouring glass (a row or column of glass buttons, capsules or cards: the header row's filters, Home's
    /// shortcuts, Streams' chips, Detail's actions on Apple TV, the player's buttons, a page's buttons) rendered
    /// together, on iOS and tvOS 26 and later, in a `GlassEffectContainer`: each shape samples the glass beside it rather
    /// than drawing over it alone. `spacing` is the closest two of its shapes sit at rest, so they blend only where a
    /// press swells one towards its neighbour, never at rest. On tvOS, where focus lifts a button towards its
    /// neighbours, they never blend. Glass drawn on glass (a card's buttons) takes a group of its own inside the card,
    /// never the card's: overlapping shapes in one group merge. On the Mac each shape draws alone: macOS 27.2
    /// reports one control of a group with the whole group's accessibility frame (Library's view menu spanned the type
    /// and sort beside it, the rating sheet's Close spanned Remove rating), so what aims at that control's
    /// centre reaches its neighbour. Before 26 the view as it is.
    @ViewBuilder
    func glassGroup(spacing: CGFloat) -> some View {
        #if os(macOS)
        self
        #else
        if #available(iOS 26, tvOS 26, *) {
            #if os(tvOS)
            GlassEffectContainer(spacing: 0) { self }
            #else
            GlassEffectContainer(spacing: spacing) { self }
            #endif
        } else {
            self
        }
        #endif
    }

    /// The large control size where the platform has one (iOS, macOS): page and sheet buttons, and every action row
    /// (`ActionRow`).
    func largeControl() -> some View {
        #if os(tvOS)
        self
        #else
        controlSize(.large)
        #endif
    }

    /// A button that is a whole form row (a link row, a language or a player to add, a recent room): the form's own row
    /// on iOS and tvOS; on the Mac, whose form draws a button as a push button, a plain one.
    func formRowButtonStyle() -> some View {
        #if os(macOS)
        buttonStyle(.plain)
        #else
        self
        #endif
    }
}

#if !os(tvOS)
extension View {
    /// A plain button or menu in the round glass control's glass (`roundGlassControl`: regular, interactive but on iOS
    /// while a menu is open, `OpenItemMenu`; the regular material before iOS and macOS 26) in a capsule. The header
    /// row's filters and search fields (`screenHeader`), and its actions, the Mac's in one capsule as the toolbar's
    /// buttons are, their labels padding themselves from the capsule's ends (`roundGlassLabel`); the app's chips on iOS
    /// and macOS 26 and later (`ChipStyle`: Home's shortcuts, Live TV's chips), at the app's chip size: the glass lights
    /// up and swells under a finger or a click. `filled`, the glass tinted white and the label
    /// black as the primary fill's: Filters while a filter is set (`FilterButton`), and a Mac's menu in the primary fill,
    /// which takes no button style (Detail's Play chevron).
    func glassCapsule(filled: Bool = false) -> some View {
        modifier(GlassShape(shape: Capsule(), filled: filled))
    }

    /// `glassCapsule`'s glass in a circle: a round glass control on the Mac and a round menu on iOS (`roundGlassControl`),
    /// an icon alone among iPhone's header row actions (`screenHeader`), which pads itself as
    /// tall as the filters' capsules.
    func glassCircle() -> some View {
        modifier(GlassShape(shape: Circle()))
    }
}
#endif

#if os(macOS)
extension View {
    /// The label of a `glassCapsule` control: its text and symbol in the toolbar's font, 12 pt in from the capsule's
    /// rounded `ends`, 28 pt tall as a compact toolbar's buttons are. A lone control takes both ends; actions sharing one
    /// capsule take half the inset each side, the capsule the other half at its ends.
    func glassCapsuleLabel(ends: Edge.Set = .horizontal) -> some View {
        let inset: CGFloat = 12
        return font(.body)
            .padding(.leading, ends.contains(.leading) ? inset : inset / 2)
            .padding(.trailing, ends.contains(.trailing) ? inset : inset / 2)
            .frame(minHeight: 28)
            .contentShape(Rectangle())
    }
}
#endif

#if !os(tvOS)
private struct GlassShape<S: Shape>: ViewModifier {
    let shape: S
    /// The primary fill: white (glass tinted white), the label black.
    var filled = false

    @Environment(\.isEnabled) private var enabled

    func body(content: Content) -> some View {
        let styled = content
            .buttonStyle(.plain)
            .foregroundStyle(filled ? Palette.onPrimary : Palette.onBackground)
            // Disabled, the label fades; the glass stays.
            .opacity(enabled ? 1 : 0.45)
        if #available(iOS 26, macOS 26, *) {
            styled.glassEffect(glass, in: shape)
            #if os(iOS)
                // The app's glass is the first a menu can open over: from it on, touches look for one.
                .onAppear { OpenItemMenu.shared.look() }
            #endif
        } else {
            styled.background(filled ? AnyShapeStyle(Palette.primary) : AnyShapeStyle(.regularMaterial), in: shape)
        }
    }

    /// Regular, interactive but on iOS while a menu is open (`OpenItemMenu`): regular alone looks the same at rest, and
    /// interactive took the taps of a menu's entries drawn over it. Tinted white while `filled`.
    @available(iOS 26, macOS 26, *)
    private var glass: Glass {
        #if os(iOS)
        let glass: Glass = OpenItemMenu.shared.isOpen ? .regular : .regular.interactive()
        #else
        let glass: Glass = .regular.interactive()
        #endif
        return filled ? glass.tint(Palette.primary) : glass
    }
}
#endif

/// On Apple TV in a light theme the glass rests white, as a focused control does: there the bordered style instead, which
/// rests in a grey fill under dark text, so only focus turns a control white.
private struct GlassButtonStyle: ViewModifier {
    #if os(tvOS)
    @Environment(\.colorScheme) private var colorScheme
    #endif

    func body(content: Content) -> some View {
        #if os(iOS)
        if #available(iOS 26, *) {
            content.buttonStyle(.glass)
        } else {
            content.buttonStyle(.bordered)
        }
        #elseif os(macOS)
        if #available(macOS 26, *) {
            content.buttonStyle(.glass).tint(Color?.none)
        } else {
            content.buttonStyle(.bordered)
        }
        #else
        if #available(tvOS 26, *), colorScheme != .light {
            content.buttonStyle(.glass)
        } else {
            content.buttonStyle(.bordered)
        }
        #endif
    }
}

extension View {
    /// The label of a destructive control: a glass pill's (`pill`: Remove PIN, Delete downloads) or a form row's
    /// (Disconnect, Delete profile, a settings row's title). Apple TV draws a focused one at 1.6–3.5:1, a row's red
    /// paled on the white focus platter and a pill's white label on a red fill: there, focused, it reads in a deep red
    /// on the focus platter (a row's white 8:1, a pill's light grey 5:1), which a pill shows once it drops the
    /// destructive role (`destructiveRole`); at rest a pill's reads pale red on dark glass (7.7:1) and deep red on a light
    /// theme's grey, a row's in `rest` (the error colour; nil, the role's). Elsewhere, or not `destructive`, it takes
    /// `rest`.
    func destructiveLabel(_ destructive: Bool = true, pill: Bool = false, rest: Color? = nil) -> some View {
        modifier(DestructiveLabel(destructive: destructive, pill: pill, rest: rest))
    }
}

/// The role of a destructive control (`destructiveLabel`): `.destructive`, but for a pill on Apple TV, where the role
/// fills the focused pill red under the label instead of the white focus platter.
func destructiveRole(pill: Bool = false) -> ButtonRole? {
    #if os(tvOS)
    pill ? nil : .destructive
    #else
    .destructive
    #endif
}

private struct DestructiveLabel: ViewModifier {
    let destructive: Bool
    let pill: Bool
    let rest: Color?
    #if os(tvOS)
    @Environment(\.isFocused) private var focused
    @Environment(\.colorScheme) private var colorScheme
    #endif

    func body(content: Content) -> some View {
        #if os(tvOS)
        if destructive, focused {
            content.foregroundStyle(Self.deepRed)
        } else if destructive, pill {
            content.foregroundStyle(colorScheme == .light ? Self.deepRed : Color(rgb: 0xFF9C9C))
        } else if destructive, let rest {
            content.foregroundStyle(rest)
        } else {
            content
        }
        #else
        if destructive, let rest {
            content.foregroundStyle(rest)
        } else {
            content
        }
        #endif
    }

    #if os(tvOS)
    /// A red that reads on the focus platter: 5:1 on a focused glass pill's light grey (#CACACA), 8:1 on white.
    private static let deepRed = Color(rgb: 0xA00012)
    #endif
}

private struct RoundGlassControl: ViewModifier {
    let shape: ButtonBorderShape
    let menu: Bool

    func body(content: Content) -> some View {
        #if os(macOS)
        if shape == .capsule {
            content.glassCapsule()
        } else {
            content.glassCircle()
        }
        #elseif os(iOS)
        if shape == .capsule {
            content.glassCapsule()
        } else if menu {
            content.glassCircle()
        } else {
            // A button under a menu doesn't take the menu's entries' taps.
            content.glassButtonStyle().buttonBorderShape(shape).modifier(DisabledUnderOpenItemMenu())
        }
        #else
        content.glassButtonStyle().buttonBorderShape(shape)
        #endif
    }
}

private struct RoundGlassLabel: ViewModifier {
    let shape: ButtonBorderShape
    let menu: Bool

    func body(content: Content) -> some View {
        #if os(macOS)
        if shape == .capsule {
            content.glassCapsuleLabel()
        } else {
            content.modifier(ActionLabel(round: true)).padding(IconButton.circleInset).contentShape(Circle())
        }
        #elseif os(iOS)
        if shape == .capsule {
            content.padding(.vertical, HeaderMetrics.controlInset)
                .padding(.horizontal, HeaderMetrics.capsuleInset)
                .contentShape(Capsule())
        } else if menu {
            content.modifier(ActionLabel(round: true)).padding(IconButton.circleInset).contentShape(Circle())
        } else if shape == .circle {
            content.modifier(ActionLabel(round: true))
        } else {
            content
        }
        #else
        if shape == .circle {
            content.modifier(ActionLabel(round: true))
        } else {
            content
        }
        #endif
    }
}

private struct ProminenceStyle: ViewModifier {
    let prominence: ButtonProminence
    let menu: Bool

    @Environment(\.isEnabled) private var enabled
    #if os(macOS)
    @Environment(\.controlActiveState) private var activeState
    #endif

    func body(content: Content) -> some View {
        switch prominence {
        case .primary:
            #if os(tvOS)
            tvPrimary(content).fontWeight(.semibold)
            #else
            // Disabled, or on the Mac in a window that isn't key (an alert over it), the system greys the fill: black
            // text would vanish into it.
            prominent(content).foregroundStyle(enabled && filled ? Palette.onPrimary : Palette.onSurfaceVariant)
            #endif
        case .secondary, .destructive:
            #if os(iOS)
            if #available(iOS 26, *), !menu, OpenItemMenu.shared.isOpen {
                // `.glass` takes the taps of a menu's entries drawn over it as `.glassProminent` does (a music
                // playlist's Delete Playlist over its Shuffle, iPhone): while a menu is open, the same pill in glass
                // that doesn't.
                content.buttonStyle(MenuOpenPillStyle()).modifier(GlassShape(shape: Capsule()))
            } else {
                content.glassButtonStyle()
            }
            #else
            content.glassButtonStyle()
            #endif
        case .plain:
            #if os(tvOS)
            content.glassButtonStyle()
            #else
            content.buttonStyle(.borderless)
            #endif
        }
    }

    #if os(tvOS)
    @ViewBuilder
    private func tvPrimary(_ content: Content) -> some View {
        if #available(tvOS 26, *) {
            content.buttonStyle(.glassProminent).tint(Palette.primaryRest)
        } else {
            content.buttonStyle(.borderedProminent).tint(Palette.primaryRest)
        }
    }
    #else
    /// The system draws the prominent fill in the accent: on the Mac only while the window is key.
    private var filled: Bool {
        #if os(macOS)
        activeState == .key
        #else
        true
        #endif
    }
    @ViewBuilder
    private func prominent(_ content: Content) -> some View {
        #if os(iOS)
        if #available(iOS 26, *) {
            if !menu && OpenItemMenu.shared.isOpen {
                // `.glassProminent` took the taps of a menu's entries drawn over it (Detail's Play under an episode's
                // menu), whatever its hit testing: while a menu is open, the same white pill in glass that doesn't.
                content.buttonStyle(MenuOpenPillStyle()).modifier(GlassShape(shape: Capsule(), filled: true))
            } else {
                content.buttonStyle(.glassProminent)
            }
        } else {
            content.buttonStyle(.borderedProminent)
        }
        #else
        if #available(macOS 26, *) {
            content.buttonStyle(.glassProminent)
        } else {
            content.buttonStyle(.borderedProminent)
        }
        #endif
    }
    #endif
}

#if os(iOS)
/// A `.glassProminent` pill's label as the style pads it at the large control size, for its stand-in while a menu is
/// open (`ProminenceStyle`): as tall as the action row's circles (`IconButton.circleInset` above and below).
private struct MenuOpenPillStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, IconButton.circleInset)
            .contentShape(Capsule())
    }
}
#endif

/// One height for every control of an action row (`ActionRow`): there a pill's label is exactly `box` tall and a
/// circle's symbol sits in a `box` square, and the glass around either is the same (the glass button style's room at
/// the large control size on iOS and Apple TV, `IconButton.circleInset` on a round menu on iOS and on every round
/// control and pill on the Mac), so a circle's diameter is a pill's height. `box` is the body text's line height, and
/// grows with the text size. Outside a row a pill at the large control size (a page's button) is at least `box` tall,
/// as many lines as its words take; smaller controls (a header's) keep their own size.
private struct ActionLabel: ViewModifier {
    let round: Bool

    @Environment(\.actionRow) private var actionRow
    @Environment(\.controlSize) private var controlSize
    #if os(macOS)
    @ScaledMetric(relativeTo: .body) private var box: CGFloat = 16
    #elseif os(tvOS)
    @ScaledMetric(relativeTo: .body) private var box: CGFloat = 36
    #else
    @ScaledMetric(relativeTo: .body) private var box: CGFloat = 22
    #endif

    func body(content: Content) -> some View {
        if round && (actionRow || controlSize == .large) {
            content.frame(width: box, height: box)
        } else if actionRow {
            content.frame(height: box)
        } else if controlSize == .large {
            content.frame(minHeight: box)
        } else {
            content
        }
    }
}

extension EnvironmentValues {
    /// Inside an action row (`ActionRow`): every pill and circle takes the row's one height (`ActionLabel`).
    @Entry var actionRow = false
}

/// A page header's row of actions (a detail's, a collection's, an album's, an artist's, a playlist's, a catalog
/// title's): the primary pill (Play, an `ActionButton` in `.primary`) and the round actions after it (`IconButton`,
/// the cast button, the download, the round menus), and any other pill (`ActionButton`), all one height on one centre
/// line, at every text size: each label is the row's line tall (`ActionLabel`) in the large control size's glass. One
/// line that never wraps, at its own width (a screen offers narrower rows through `ViewThatFits`), its glass rendered
/// together (`glassGroup`). A pill's words stay on one line.
struct ActionRow<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack(spacing: spacing) { content() }
            .lineLimit(1)
            .environment(\.actionRow, true)
            .largeControl()
            .glassGroup(spacing: spacing)
            .fixedSize()
    }
}

/// An action row's round glass ⋯ that opens `entries` in the system's menu, as Detail's ⋯: the actions a narrow row
/// has no room for, where the screen has no item menu (an audio playlist's Shuffle and Instant Mix, a playlist's
/// Shuffle and Delete). `probe` is its identifier and its entries' prefix.
struct ActionMenuButton: View {
    let entries: [ItemMenuEntry]
    let probe: String

    var body: some View {
        Menu {
            ItemMenuEntries(entries: entries, probe: probe)
        } label: {
            Image(systemName: "ellipsis")
                .font(.body.weight(.semibold))
                .roundGlassLabel(.circle, menu: true)
        }
        .menuIndicator(.hidden)
        .roundGlassControl(.circle, menu: true)
        #if os(macOS)
        .tooltip(T.shared.common.options)
        #endif
        .accessibilityLabel(T.shared.common.options)
        .accessibilityIdentifier(probe)
    }
}

/// A native button with a title (and an icon: an SF Symbol, or a mark), full width or
/// content-wide (`fullWidth`), in `prominence`; its title on one line, at the accessibility text sizes on as many as it
/// takes but in an action row (`ActionRow`). `id` is its accessibility identifier, the Compose UI's probe name for the
/// same button (`watch.create`). tvOS draws a disabled button just like an enabled one without focus, so there a
/// disabled one drops its platter and shows its title and icon in the secondary colour from the platter's leading edge
/// (in line with the content below), in the room its platter would take. A `status` (a state shown in an action's
/// place: Available, Requested) is no button at all: its title and icon in the text colour, in that room, at its leading
/// edge or, where the text around it is centred, its centre.
/// `widthOf` lists the titles (and icons) the button takes in turn: it keeps the widest one's width, so what sits
/// beside it stays put as it changes.
struct ActionButton<Icon: View>: View {
    let title: String
    let id: String
    var prominence: ButtonProminence = .secondary
    var fullWidth = true
    var enabled = true
    var status = false
    let icon: Icon?
    var widthOf: [(title: String, icon: Icon?)] = []
    let action: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.actionRow) private var actionRow
    @Environment(\.multilineTextAlignment) private var textAlignment

    var body: some View {
        #if os(tvOS)
        let bare = status || !enabled
        #else
        let bare = status
        #endif
        if widthOf.isEmpty && !bare {
            platter(title: title, icon: icon, prominence: prominence, fill: fullWidth)
                .disabled(!enabled)
                .accessibilityIdentifier(id)
        } else {
            // Unseen platters of each title size it: as prominent and as plain, as the row's first action and not.
            ZStack {
                ForEach(Array(sizingTitles.enumerated()), id: \.offset) { _, sized in
                    platter(title: sized.title, icon: sized.icon, prominence: .primary, fill: false)
                    platter(title: sized.title, icon: sized.icon, prominence: .secondary, fill: false)
                }
            }
            .disabled(true)
            .hidden()
            .accessibilityHidden(true)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .overlay {
                if status {
                    // One element, read as its title (not a button).
                    label(title: title, icon: icon)
                        .foregroundStyle(Palette.onBackground)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: textAlignment == .center ? .center : .leading)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(title)
                        .accessibilityIdentifier(id)
                } else {
                    Group {
                        if bare {
                            Button(action: action) { label(title: title, icon: icon) }
                                .buttonStyle(BareLabelStyle())
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                        } else {
                            platter(title: title, icon: icon, prominence: prominence, fill: true)
                        }
                    }
                    .disabled(!enabled)
                    .accessibilityIdentifier(id)
                }
            }
        }
    }

    /// The titles the button is sized by: `widthOf`, and its own.
    private var sizingTitles: [(title: String, icon: Icon?)] {
        widthOf.contains { $0.title == title } ? widthOf : widthOf + [(title, icon)]
    }

    private func label(title: String, icon: Icon?) -> some View {
        Group {
            if let icon {
                // Its title always: the automatic style shows the icon alone in some containers (a list row),
                // which left a wide pill with a lone icon where a narrower row (`ViewThatFits`) belonged.
                Label { Text(title) } icon: { icon }
                    .labelStyle(.titleAndIcon)
            } else {
                Text(title)
            }
        }
        .lineLimit(dynamicTypeSize.isAccessibilitySize && !actionRow ? nil : 1)
        .actionLabel()
    }

    private func platter(title: String, icon: Icon?, prominence: ButtonProminence, fill: Bool) -> some View {
        Button(role: prominence == .destructive ? destructiveRole(pill: true) : nil, action: action) {
            label(title: title, icon: icon).frame(maxWidth: fill ? .infinity : nil).destructiveLabel(prominence == .destructive, pill: true)
        }
        .buttonProminence(prominence)
        .largeControl()
    }
}

/// A button's label alone, without a platter: a disabled action on Apple TV.
private struct BareLabelStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

extension ActionButton where Icon == Image {
    init(
        title: String,
        id: String,
        prominence: ButtonProminence = .secondary,
        systemImage: String? = nil,
        fullWidth: Bool = true,
        enabled: Bool = true,
        status: Bool = false,
        widthOf: [(title: String, systemImage: String?)] = [],
        action: @escaping () -> Void
    ) {
        self.init(
            title: title,
            id: id,
            prominence: prominence,
            fullWidth: fullWidth,
            enabled: enabled,
            status: status,
            icon: systemImage.map(Image.init(systemName:)),
            widthOf: widthOf.map { (title: $0.title, icon: $0.systemImage.map(Image.init(systemName:))) },
            action: action
        )
    }
}

/// A round button with an SF Symbol and a spoken `label` (move up, remove, copy), on the Mac its tooltip too: a glass
/// (bordered) circle, as round menus are (`roundGlassControl`), so a row of round buttons and menus (Detail's actions)
/// shares one look. In an action row (`ActionRow`) the circle is as tall as the row's pills, its symbol in the row's
/// square (`roundGlassLabel`) so the row's circles are one size whatever each symbol's shape.
struct IconButton: View {
    let systemImage: String
    let label: String
    let id: String
    var enabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .roundGlassLabel()
        }
        .roundGlassControl()
        .disabled(!enabled)
        .accessibilityLabel(label)
        #if os(macOS)
        .tooltip(label)
        #endif
        .accessibilityIdentifier(id)
    }

    #if os(macOS)
    /// A glass circle's room around its symbol: the glass pill's around its label at the large control size, so an
    /// action row's circles and pills are one height.
    static let circleInset: CGFloat = 6
    #elseif os(iOS)
    /// A round menu's room around its symbol (`roundGlassLabel`): the glass button style's around a label at the large
    /// control size, so an action row's round menus match the round buttons and pills beside them.
    static let circleInset: CGFloat = 15
    #else
    /// The glass button style's room around a label on Apple TV, so Detail's split Play capsule is as tall as the
    /// action row's other controls.
    static let circleInset: CGFloat = 15
    #endif
}

extension View {
    /// A round button's symbol in its own colour (`style`: Delete's red, the cast symbol's), which tvOS keeps on a
    /// disabled button while it greys a plain symbol: there a disabled one's symbol greys as well.
    func symbolStyle<S: ShapeStyle>(_ style: S) -> some View {
        modifier(SymbolStyle(style: AnyShapeStyle(style)))
    }
}

private struct SymbolStyle: ViewModifier {
    let style: AnyShapeStyle

    @Environment(\.isEnabled) private var enabled

    func body(content: Content) -> some View {
        #if os(tvOS)
        content.foregroundStyle(enabled ? style : AnyShapeStyle(.tertiary))
        #else
        content.foregroundStyle(style)
        #endif
    }
}

/// The watched toggle's symbol wherever "Mark as watched" shows (a detail's action row, the item menus): an eye, filled
/// once watched.
func watchedSymbol(_ watched: Bool) -> String {
    watched ? "eye.fill" : "eye"
}

/// A heading's text action (a shelf's View all): the title and a chevron, borderless, as a section heading's link is.
struct HeadingButton: View {
    let title: String
    let id: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                Image(systemName: "chevron.forward").font(.footnote.weight(.semibold)).accessibilityHidden(true)
            }
            // At least 44 pt tall to the tap (the body's line and 11 pt over and under it), as tall as its line to the
            // heading's layout, which would otherwise push the shelf's cards down from their heading.
            .padding(.vertical, 11)
            .contentShape(Rectangle())
            .padding(.vertical, -11)
        }
        .buttonStyle(.borderless)
        .accessibilityIdentifier(id)
    }
}
