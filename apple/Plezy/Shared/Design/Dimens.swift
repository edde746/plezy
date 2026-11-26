import SwiftUI
import PlezyKit

/// How a window is used, which decides its navigation and sizes: a phone (compact width), a regular-width window
/// (iPad, Mac), or a TV (10-foot viewing, focus engine).
enum FormFactor: Sendable {
    case compact
    case regular
    case tv

    #if os(iOS)
    /// An iPhone, or an iPad window as narrow as one, for `horizontalSizeClass` compact; otherwise regular.
    static func current(_ horizontalSizeClass: UserInterfaceSizeClass?) -> FormFactor {
        horizontalSizeClass == .compact ? .compact : .regular
    }
    #endif
}

/// Size tokens for the window at hand, Apple's own metrics made denser: phones tight, iPad and Mac a
/// step roomier, TV large. Screens read them from the environment (`@Environment(\.dimens)`); the app shell sets
/// them for the window's form factor.
struct Dimens: Sendable {
    /// The horizontal inset of screen content, inside the safe area. Screens take it at each side as `screenSides`,
    /// which leaves it out beside iOS 27.1's vertical bar. On tvOS the safe area already keeps content 80 pt from the
    /// screen's edges, so screens add nothing to it.
    var screenPadding: CGFloat
    /// The gap between items in a row or list.
    var gutter: CGFloat
    /// The gap between sections (shelves, groups).
    var sectionSpacing: CGFloat
    /// A shelf's heading to its cards' artwork (`ShelfRow`), well under the gap between shelves (`focusRoom` and
    /// `sectionSpacing` under a row's captions), so a heading reads as its row's. At least `focusRoom`: the room over
    /// the cards for their lift or focus ring.
    var headingGap: CGFloat
    /// Room around a row of cards for what grows out of them: the tvOS card lift, the keyboard focus ring.
    var focusRoom: CGFloat
    /// The width of a portrait (2:3) poster; wide and square cards derive from it.
    var posterWidth: CGFloat
    /// Lists and text columns stay this narrow on wide windows.
    var contentMaxWidth: CGFloat
    /// The QR code's width: larger on TV (read across a room), smaller on phones.
    var qrSize: CGFloat
    /// A PIN pad key's diameter.
    var pinKey: CGFloat
    /// A profile avatar on the picker.
    var avatar: CGFloat
    /// Points per unit of the shared layouts sized for a TV of 960 × 540 units (`GuideLayout`, the side rail's
    /// metrics): 2 on an Apple TV, which lays out 1920 × 1080 points; 1 elsewhere.
    var unit: CGFloat = 1
    /// On TV, the widest a grid's poster is at the middle density (nil elsewhere): TV grids round their columns up under
    /// a most width instead of fitting columns of at least the card width (`grid`).
    var gridPosterMaxWidth: CGFloat?

    /// The width of a card in a row for `shape`: wide cards are wider so rows keep a similar height.
    func cardWidth(_ shape: CardShape_) -> CGFloat {
        switch shape {
        case .poster: posterWidth
        case .square: posterWidth * 1.2
        case .wide: posterWidth * 1.9
        }
    }

    /// A grid of `shape` cards across `width` points of content: as many columns of about the card width as fit, the
    /// library density (1–5, 3 the card width itself) scaling that minimum from 0.7 to 1.3 of it; on TV as few columns as
    /// keep each at most `gridPosterMaxWidth` (a square card as wide, an episode thumbnail 1.9 times), the density
    /// scaling it from 2/3 to 4/3, so a TV screen holds 7 posters or 4 thumbnails across. The cell width fills the width
    /// exactly, so the grid starts and ends at the content edges. The gutter follows the grid
    /// spacing setting (`GridLayout.spacing`: tight 0, normal 6, spacious 12, square cells at least 8) plus the shared
    /// layout's card padding at both sides (`GridLayout.CARD_PADDING_START`, `_END`), which these cards draw without, so
    /// tight cards still stand apart; the cards' title gap follows it too (`GridSpacing.titleGap`: 2, 4, 6), both in
    /// `unit`s. On tvOS the title keeps the focused card's lift clear (`PosterCard.captionGap`). The cards' titles take
    /// two lines at the compact densities, one from the default up (`GridLayout.titleLines`).
    func grid(width: CGFloat, shape: CardShape_, appearance: Appearance) -> GridCells {
        let setting = appearance.gridSpacing
        let layout = GridLayout.shared
        let spacing = layout.spacing(gridSpacing: setting, shape: shape, fullBleed: false, tvScale: 1)
        let gutter = CGFloat(spacing + layout.CARD_PADDING_START + layout.CARD_PADDING_END) * unit
        let density = CGFloat(min(max(appearance.libraryDensity, 1), 5) - 1)
        let available = max(width, 0)
        let columns: Int
        if let poster = gridPosterMaxWidth {
            let most = poster * (2 + density / 2) / 3 * (shape == .wide ? 1.9 : 1)
            columns = max(Int((available / (most + gutter)).rounded(.up)), 1)
        } else {
            let minimum = cardWidth(shape) * (0.7 + 0.15 * density)
            columns = max(Int((available + gutter) / (minimum + gutter)), 1)
        }
        let cell = max((available - CGFloat(columns - 1) * gutter) / CGFloat(columns), 0)
        #if os(tvOS)
        let titleGap = PosterCard.captionGap
        #else
        let titleGap = CGFloat(setting.titleGap) * unit
        #endif
        let titleLines = Int(layout.titleLines(density: appearance.libraryDensity))
        return GridCells(columns: columns, cell: cell, spacing: gutter, titleGap: titleGap, titleLines: titleLines)
    }

    static func of(_ formFactor: FormFactor) -> Dimens {
        switch formFactor {
        case .tv:
            #if os(tvOS)
            // tvOS lays out 1920×1080 points inside an 80 pt safe area at the sides.
            return Dimens(
                screenPadding: 0, gutter: 40, sectionSpacing: 24, headingGap: 24, focusRoom: 24, posterWidth: 240,
                contentMaxWidth: 1400, qrSize: 420, pinKey: 110, avatar: 200, unit: 2, gridPosterMaxWidth: 240
            )
            #else
            // Force TV mode on iPad or the Mac: the TV's layout inside the window's padding.
            return Dimens(
                screenPadding: 24, gutter: 16, sectionSpacing: 20, headingGap: 12, focusRoom: 12, posterWidth: 150,
                contentMaxWidth: 1200, qrSize: 320, pinKey: 80, avatar: 120, gridPosterMaxWidth: 120
            )
            #endif
        case .compact:
            return Dimens(
                screenPadding: 16, gutter: 8, sectionSpacing: 16, headingGap: 8, focusRoom: 4, posterWidth: 104,
                contentMaxWidth: 600, qrSize: 200, pinKey: 64, avatar: 96
            )
        case .regular:
            return Dimens(
                screenPadding: 24, gutter: 12, sectionSpacing: 20, headingGap: 8, focusRoom: 6, posterWidth: 132,
                contentMaxWidth: 960, qrSize: 232, pinKey: 64, avatar: 96
            )
        }
    }
}

/// A grid's fixed columns (`Dimens.grid`): `columns` cells `cell` wide, `spacing` apart, each card's caption
/// `titleGap` under its artwork, its title on `titleLines` lines.
struct GridCells: Equatable {
    let columns: Int
    let cell: CGFloat
    let spacing: CGFloat
    let titleGap: CGFloat
    let titleLines: Int

    var items: [GridItem] {
        Array(repeating: GridItem(.fixed(cell), spacing: spacing, alignment: .top), count: columns)
    }
}

extension View {
    /// The cards inside take `cells`' title gap (`cardTitleGap`) and title lines (`cardTitleLines`).
    func gridCards(_ cells: GridCells) -> some View {
        environment(\.cardTitleGap, cells.titleGap)
            .environment(\.cardTitleLines, cells.titleLines)
    }
}

extension EnvironmentValues {
    @Entry var dimens: Dimens = .of(.regular)
    @Entry var formFactor: FormFactor = .regular

    /// The page's sides (`ScreenSides`): the form factor's screen padding, none at the vertical bar's side.
    var screenSides: ScreenSides {
        ScreenSides(padding: dimens.screenPadding, bar: verticalBarEdge)
    }
}

/// Where a page's content (its cards, chips, rows and headings) starts and ends, inside its safe area at each side: the
/// screen padding, but none at the side of iOS 27.1's vertical bar (`verticalBarEdge`). The system ends the safe area
/// beside the bar's column with the gap it leaves after the column, and its forms start their cards right there: on the
/// iPhone Duo's cover, 14 pt from the tabs, where the pages kept 30 pt from them with the padding added. A side's safe area without the bar (a phone's sensor housing,
/// turned) is the housing's alone, and the forms start past it by their margin, as the padding does. A readable column
/// narrower than the page (`readableColumn`) has no bar beside it, so its content has the padding at both sides.
/// Screens read it as `@Environment(\.screenSides)` (`ScreenSidesReader` where they put the view in a readable column)
/// and take it as padding (`insets`) or out of their width (`horizontal`); a page that lines something up with a
/// form's cards rather than its own content takes its own padding by the same rule.
struct ScreenSides: Equatable {
    let leading: CGFloat
    let trailing: CGFloat

    /// `padding` at each side, none at the side of the vertical bar (`bar`, `verticalBarEdge`).
    init(padding: CGFloat, bar: HorizontalEdge?) {
        leading = bar == .leading ? 0 : padding
        trailing = bar == .trailing ? 0 : padding
    }

    /// Both sides: what they take from the page's width.
    var horizontal: CGFloat { leading + trailing }

    /// The sides as padding.
    var insets: EdgeInsets { EdgeInsets(top: 0, leading: leading, bottom: 0, trailing: trailing) }
}

/// Hands `content` the page's sides where it is (`screenSides`): put in a readable column, it gets the column's.
struct ScreenSidesReader<Content: View>: View {
    @ViewBuilder var content: (ScreenSides) -> Content

    @Environment(\.screenSides) private var sides

    var body: some View {
        content(sides)
    }
}

extension View {
    /// Sets `formFactor` and its `dimens` for everything below, from the window's size class, or the TV's
    /// wherever `tv` (Force TV mode: the session's appearance says the layout is a TV's).
    func formFactorEnvironment(tv: Bool = false) -> some View {
        modifier(FormFactorEnvironment(tv: tv))
    }
}

private struct FormFactorEnvironment: ViewModifier {
    let tv: Bool
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    func body(content: Content) -> some View {
        #if os(tvOS)
        let formFactor = FormFactor.tv
        #elseif os(macOS)
        let formFactor = tv ? FormFactor.tv : .regular
        #else
        let formFactor = tv ? FormFactor.tv : FormFactor.current(horizontalSizeClass)
        #endif
        return content
            .environment(\.formFactor, formFactor)
            .environment(\.dimens, .of(formFactor))
    }
}
