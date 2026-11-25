import PlezyKit
import SwiftUI

#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// The playback info (`PlaybackInfoState`): one card over the video, the store's sections (`PlayerModel.playbackInfo`)
/// as label: value rows under a symbol and a heading each, never taking a touch or the focus and hidden from VoiceOver.
///
/// Its text keeps one size (`Sizes`): never under the idiom's floor (11 pt on an iPhone, 12 on an iPad and the Mac,
/// 23 on Apple TV, read from across the room), growing with Dynamic Type, never scaled down to fit. A row is one line,
/// so the card's size is known before it lays out, and no data value is cut (`InfoRow.freeText`: only a file's name,
/// a track's title and the audio output's device may end in "…"): its columns are as wide as the widest row's label
/// and data (`Sizes.width`).
///
/// It covers none of the controls that show. Its rooms (`rooms`) are the free rectangles inside the controls' margins
/// that start at the leading edge and keep a gap from every control marked `playbackInfoObstacle`: on iPhone and iPad
/// the top bar, the centre transport and the bottom bar (the title over the timeline); on the Mac the title row and the
/// control bar; on Apple TV the transport bar (the title, the buttons, the timeline) and an open menu's card or panel;
/// everywhere the corner's cards and prompt button, and the error. With the controls up that is beside the transport
/// (tall and narrow) and above it (wide and short), or on the Mac and Apple TV above the bottom controls; with them
/// down, the whole picture inside its margins. `PlaybackInfoLayout.arrange` picks the room and what goes in it: as many
/// sections as fit, the least useful left out first, in at most a third of the picture, its columns narrowing in a
/// narrow room only as far as their data reads whole; with no room even for the first, there is no card.
///
/// The card sits in its room's top-leading corner (the top left in every language) and moves there in 200 ms; with
/// auto-hide it fades out with the controls in as long, its last reading still on it. While it shows it counts the
/// frames drawn (the UI FPS row, `PlaybackInfoReader.onFrame`).
struct PlaybackInfoCard: View {
    let info: PlaybackInfoState
    let playback: PlayerModel
    /// The frames of the controls that show (`PlaybackInfoObstacles`).
    let obstacles: [Anchor<CGRect>]

    /// Dynamic Type's scale of the text at the caption's size: the floor holds at the smaller sizes.
    @ScaledMetric(relativeTo: .caption) private var textScale: CGFloat = 1

    var body: some View {
        let sizes = Sizes(scale: max(1, textScale))
        GeometryReader { proxy in
            if let placed = place(in: proxy, sizes: sizes) {
                ZStack(alignment: .topLeading) {
                    // Nothing of the card reaches VoiceOver (the UI tests read it from `player.infoCard`).
                    let drawn = card(placed.layout, sizes).accessibilityHidden(true)
                    #if DEBUG
                    drawn.overlayPreferenceValue(PlaybackInfoCutValues.self) { cut in
                        PlaybackInfoCardProbe(reading: Self.reading(placed.layout, sizes, cut: cut))
                    }
                    #else
                    drawn
                    #endif
                }
                .frame(width: CGFloat(placed.layout.width), height: CGFloat(placed.layout.height), alignment: .topLeading)
                .offset(x: placed.origin.x, y: placed.origin.y)
                .animation(.easeInOut(duration: 0.2), value: placed.origin)
            }
        }
        .opacity(info.visible ? 1 : 0)
        .animation(.linear(duration: 0.2), value: info.visible)
        .environment(\.layoutDirection, .leftToRight)
        .allowsHitTesting(false)
        .background {
            if info.visible { FrameCounter(reader: playback.store.playbackInfo).accessibilityHidden(true) }
        }
        .task { await playback.playbackInfo.observe() }
    }

    /// The card's sections and columns, and its top-leading corner in `proxy`'s space: its room's.
    private func place(in proxy: GeometryProxy, sizes: Sizes) -> (layout: InfoCardLayout, origin: CGPoint)? {
        let area = CGRect(origin: .zero, size: proxy.size).insetBy(dx: Self.margin.width, dy: Self.margin.height)
        let rooms = Self.rooms(in: area, clearing: obstacles.map { proxy[$0] }, gap: PlayerMetrics.overlayGap)
        let sections = playback.playbackInfo.state
        let layout = PlaybackInfoLayout.shared.arrange(
            sections: sections,
            rooms: rooms.map { InfoRoom(width: Float($0.width), height: Float($0.height)) },
            picture: Float(proxy.size.width * proxy.size.height),
            metrics: sizes.metrics,
            widths: { sizes.width($0) }
        )
        guard let layout else { return nil }
        return (layout, rooms[Int(layout.room)].origin)
    }

    /// The controls' own distance from the overlay's sides, and its top and bottom: the card keeps as far.
    private static var margin: CGSize {
        #if os(iOS)
        CGSize(width: PlayerMetrics.edge, height: PlayerMetrics.barInset)
        #else
        CGSize(width: PlayerMetrics.edge, height: PlayerMetrics.edge)
        #endif
    }

    /// The free rectangles of `area` whose top-leading corner is on its leading edge, `gap` clear of every one of
    /// `obstacles`: for each top (the area's, and `gap` under each obstacle) as wide as up to each obstacle's leading
    /// edge or the whole area, and as tall as down to the first obstacle across that width. None lies inside another;
    /// the highest come first, and at one top the narrower (and taller) first: beside the transport, then above it.
    static func rooms(in area: CGRect, clearing obstacles: [CGRect], gap: CGFloat) -> [CGRect] {
        let blocks = obstacles.map { $0.insetBy(dx: -gap, dy: -gap) }.filter { $0.intersects(area) }
        let tops = Set([area.minY] + blocks.map(\.maxY)).filter { $0 >= area.minY && $0 < area.maxY }.sorted()
        let widths = Set([area.width] + blocks.map { min($0.minX - area.minX, area.width) }).filter { $0 > 0 }.sorted()
        let candidates = tops.flatMap { top in
            widths.compactMap { width -> CGRect? in
                let across = blocks.filter { $0.minX < area.minX + width && $0.maxX > area.minX && $0.maxY > top }
                let bottom = min(across.map(\.minY).min() ?? area.maxY, area.maxY)
                return bottom > top ? CGRect(x: area.minX, y: top, width: width, height: bottom - top) : nil
            }
        }
        return candidates.filter { room in !candidates.contains { $0 != room && $0.contains(room) } }
    }

    private func card(_ layout: InfoCardLayout, _ sizes: Sizes) -> some View {
        HStack(alignment: .top, spacing: sizes.columnGap) {
            ForEach(Array(layout.columns.enumerated()), id: \.offset) { _, column in
                VStack(alignment: .leading, spacing: sizes.sectionGap) {
                    ForEach(column, id: \.id) { section in
                        InfoSectionView(section: section, sizes: sizes)
                    }
                }
                .frame(width: CGFloat(layout.column), alignment: .leading)
            }
        }
        .padding(sizes.padding)
        .frame(width: CGFloat(layout.width), height: CGFloat(layout.height), alignment: .topLeading)
        .background(Color.black.opacity(0.8), in: RoundedRectangle(cornerRadius: sizes.padding))
        .shadow(color: .black.opacity(0.3), radius: 2)
    }

    #if DEBUG
    /// `rows=<pt>; heading=<pt>; sections=<id>,…; cut=<label>,…`: the rows' and the headings' text size, the sections
    /// shown, in order, and the labels of the data values drawn cut short (`PlaybackInfoCutValues`).
    private static func reading(_ layout: InfoCardLayout, _ sizes: Sizes, cut: [String]) -> String {
        let sections = layout.columns.flatMap { $0 }.map { "\($0.id)" }.joined(separator: ",")
        return "rows=\(sizes.row); heading=\(sizes.heading); sections=\(sections); cut=\(cut.joined(separator: ","))"
    }
    #endif

    private struct InfoSectionView: View {
        let section: InfoSection
        let sizes: Sizes

        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: sizes.row * 0.35) {
                    Image(systemName: section.id.symbol)
                        .font(.system(size: sizes.row))
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(width: sizes.heading)
                    Text(section.title)
                        .font(.system(size: sizes.heading, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .lineLimit(1)
                .frame(height: sizes.headingLine)
                .padding(.bottom, sizes.headingGap)
                ForEach(Array(section.rows.enumerated()), id: \.offset) { _, row in
                    HStack(spacing: 0) {
                        Text(verbatim: "\(row.label): ")
                            .font(.system(size: sizes.row))
                            .foregroundStyle(.white.opacity(0.6))
                            .layoutPriority(1)
                        Text(row.value)
                            .font(sizes.valueFont)
                            .foregroundStyle(.white)
                            .truncationMode(.tail)
                            #if DEBUG
                            .background { if !row.freeText { PlaybackInfoCutProbe(label: row.label, value: row.value, font: sizes.valueFont) } }
                            #endif
                    }
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: sizes.rowLine)
                    .padding(.bottom, sizes.rowGap)
                }
            }
        }
    }
}

/// The card's text sizes and measures in points on this device: rows (label and value) of `row`, headings of `heading`,
/// columns `column` wide (wider where a row's data needs it: `width`), the gaps and the padding in proportion to the
/// rows' text. A phone's column is narrower, so its card fits beside the transport in landscape (about 180 pt there).
private struct Sizes {
    let row: CGFloat
    let heading: CGFloat
    let column: CGFloat

    /// At `scale` times the idiom's floor.
    init(scale: CGFloat) {
        #if os(tvOS)
        (row, heading, column) = (23 * scale, 26 * scale, 23 * scale * 18)
        #elseif os(macOS)
        (row, heading, column) = (12, 14, 12 * 18)
        #else
        let pad = UIDevice.current.userInterfaceIdiom == .pad
        let size = (pad ? 12 : 11) * scale
        (row, heading, column) = (size, size + 2 * scale, size * (pad ? 18 : 14.5))
        #endif
    }

    var padding: CGFloat { row * 0.75 }
    var columnGap: CGFloat { row * 1.25 }
    var headingGap: CGFloat { row * 0.25 }
    var rowGap: CGFloat { row * 0.15 }
    var sectionGap: CGFloat { row * 0.75 }

    /// A row's value's font: digits of one width, so a live value's digits change in place.
    var valueFont: Font { .system(size: row, weight: .medium, design: .monospaced) }

    /// A row's line: the taller of its label's font and its value's.
    var rowLine: CGFloat { max(Self.line(labelPlatformFont), Self.line(valuePlatformFont)) }

    var headingLine: CGFloat { Self.line(.systemFont(ofSize: heading, weight: .semibold)) }

    /// The measures `PlaybackInfoLayout.arrange` lays the card out by, as the views above draw it: a row's label and
    /// value on one line with no gap between (`width`).
    var metrics: InfoCardMetrics {
        InfoCardMetrics(
            column: Float(column),
            columnGap: Float(columnGap),
            maxColumns: 3,
            labelGap: 0,
            padding: Float(padding),
            title: 0,
            heading: Float(headingLine + headingGap),
            row: Float(rowLine),
            rowGap: Float(rowGap),
            sectionGap: Float(sectionGap)
        )
    }

    /// How wide `section`'s rows are drawn: its widest "label: value" of data, and of free text (which may end in "…")
    /// its label and the ellipsis, as one run (`InfoWidth.data`), a point over for the rounding.
    func width(_ section: InfoSection) -> InfoWidth {
        let ellipsis = Self.width("…", valuePlatformFont)
        let widest = section.rows.map { row in
            Self.width("\(row.label): ", labelPlatformFont) + (row.freeText ? ellipsis : Self.width(row.value, valuePlatformFont))
        }.max() ?? 0
        return InfoWidth(label: 0, data: Float(ceil(widest) + 1))
    }

    #if os(macOS)
    private var labelPlatformFont: NSFont { .systemFont(ofSize: row) }
    private var valuePlatformFont: NSFont { .monospacedSystemFont(ofSize: row, weight: .medium) }
    private static func line(_ font: NSFont) -> CGFloat { font.ascender - font.descender + font.leading }
    private static func width(_ text: String, _ font: NSFont) -> CGFloat { (text as NSString).size(withAttributes: [.font: font]).width }
    #else
    private var labelPlatformFont: UIFont { .systemFont(ofSize: row) }
    private var valuePlatformFont: UIFont { .monospacedSystemFont(ofSize: row, weight: .medium) }
    private static func line(_ font: UIFont) -> CGFloat { font.lineHeight }
    private static func width(_ text: String, _ font: UIFont) -> CGFloat { (text as NSString).size(withAttributes: [.font: font]).width }
    #endif
}

/// The frames of the controls that show, which the playback info's card keeps clear of (`PlaybackInfoCard.rooms`).
struct PlaybackInfoObstacles: PreferenceKey {
    static var defaultValue: [Anchor<CGRect>] { [] }

    static func reduce(value: inout [Anchor<CGRect>], nextValue: () -> [Anchor<CGRect>]) {
        value += nextValue()
    }
}

extension View {
    /// A control the playback info's card keeps clear of while it shows (`PlaybackInfoObstacles`).
    func playbackInfoObstacle() -> some View {
        anchorPreference(key: PlaybackInfoObstacles.self, value: .bounds) { [$0] }
    }
}

/// Tells the reader each frame the display draws while it is in the view (`PlaybackInfoReader.onFrame`).
private struct FrameCounter: View {
    let reader: PlaybackInfoReader

    var body: some View {
        TimelineView(.animation) { context in
            Color.clear.onChange(of: context.date) { _, date in
                reader.onFrame(frameTimeNanos: Int64(date.timeIntervalSinceReferenceDate * 1_000_000_000))
            }
        }
    }
}

private extension InfoSectionId {
    var symbol: String {
        switch self {
        case .stream: "antenna.radiowaves.left.and.right"
        case .video: "video.fill"
        case .color: "paintpalette.fill"
        case .hdr: "sun.max.fill"
        case .audio: "speaker.wave.2.fill"
        case .subtitles: "captions.bubble.fill"
        case .performance: "speedometer"
        case .app: "square.grid.2x2.fill"
        case .buffer: "memorychip.fill"
        }
    }
}
