import SwiftUI
import PlezyKit

/// The file info sheet's content (`FileInfoSections.page`) for the item named `title`, in the foreground style of where
/// it sits (the item menu's sheet, the player's page): the title, then each version's cards,
/// their fields in one or two columns (`FileInfoGrid`). A path copies on a tap or click and says so in a toast (Apple TV
/// has no pasteboard: there it is text). On Apple TV each field takes focus, so the remote walks (and scrolls) through
/// them; `first` marks the first that does (the player's initial focus). Identifiers under `probe`:
/// `.path.<version>.<file>`, `.copied`, `.noStreams`. Sizes are in the shared layouts' units; the text's follow Dynamic
/// Type as the subheadline does.
struct FileInfoContent<First: ViewModifier>: View {
    let info: MediaFileInfo
    let title: String
    let probe: String
    let first: First

    @Environment(\.dimens) private var dimens
    @ScaledMetric(relativeTo: .subheadline) private var textScale: CGFloat = 1
    @State private var clock = LiveTvClock.uses24Hour
    @State private var copied: String?

    init(info: MediaFileInfo, title: String, probe: String, first: First) {
        self.info = info
        self.title = title
        self.probe = probe
        self.first = first
    }

    var body: some View {
        let unit = dimens.unit
        let page = FileInfoSections.shared.page(info: info, title: title, use24HourClock: clock)
        let firstCard = page.versions.first.flatMap(\.cards.first)
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 0) {
                if !page.title.isEmpty {
                    Text(page.title)
                        .font(.system(size: 16 * unit * textScale, weight: .semibold))
                        .accessibilityAddTraits(.isHeader)
                    Spacer().frame(height: 20 * unit)
                }
                ForEach(Array(page.versions.enumerated()), id: \.offset) { index, version in
                    VersionBlock(
                        version: version, index: index, probe: probe, firstCard: firstCard, first: first,
                        copy: copy
                    )
                    .padding(.top, index > 0 ? 20 * unit : 0)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16 * unit)
            .padding(.top, 12 * unit)
            .padding(.bottom, 24 * unit)
        }
        .scrollBounceBehavior(.basedOnSize)
        // The toast at the sheet's bottom edge, not under a short page's last card: in a band of its own (on the Mac
        // above the sheet's Close bar), never over a field.
        .frame(maxHeight: .infinity, alignment: .top)
        .toast(copied, id: "\(probe).copied") { copied = nil }
        .onClockChange { clock = $0 }
    }

    private func copy(_ path: String) {
        #if !os(tvOS)
        Pasteboard.copy(path)
        copied = T.shared.fileInfo.pathCopied
        #endif
    }
}

extension FileInfoContent where First == EmptyModifier {
    init(info: MediaFileInfo, title: String, probe: String) {
        self.init(info: info, title: title, probe: probe, first: EmptyModifier())
    }
}

private extension FileInfoVersion {
    /// Its cards in the order they show.
    var cards: [FileInfoCard] {
        var cards: [FileInfoCard] = []
        if let overview { cards.append(overview) }
        for file in files {
            if let card = file.card { cards.append(card) }
            cards.append(contentsOf: file.streams)
        }
        if let attachments { cards.append(attachments) }
        if let delivery { cards.append(delivery) }
        return cards
    }
}

private struct VersionBlock<First: ViewModifier>: View {
    let version: FileInfoVersion
    let index: Int
    let probe: String
    let firstCard: FileInfoCard?
    let first: First
    let copy: (String) -> Void

    @Environment(\.dimens) private var dimens
    @ScaledMetric(relativeTo: .subheadline) private var textScale: CGFloat = 1

    var body: some View {
        let unit = dimens.unit
        let type = unit * textScale
        VStack(alignment: .leading, spacing: 0) {
            if let heading = version.heading {
                HStack(spacing: 8 * unit) {
                    Image(systemName: "square.stack.3d.up.fill").font(.system(size: 16 * type)).foregroundStyle(Palette.primary)
                    Text(heading).font(.system(size: 14 * type, weight: .semibold)).foregroundStyle(Palette.primary)
                    if let title = version.title {
                        Text(title).font(.system(size: 14 * type)).foregroundStyle(.secondary).lineLimit(1)
                    }
                }
                .padding(.bottom, 10 * unit)
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isHeader)
            }
            if let overview = version.overview { card(overview) }
            ForEach(Array(version.files.enumerated()), id: \.offset) { fileIndex, file in
                if let fileCard = file.card {
                    card(fileCard, pathId: "\(probe).path.\(index).\(fileIndex)")
                }
                ForEach(Array(file.streams.enumerated()), id: \.offset) { _, stream in card(stream) }
                if file.noStreams {
                    Text(T.shared.fileInfo.noStreams)
                        .font(.system(size: 12 * type))
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 12 * unit)
                        .accessibilityIdentifier("\(probe).noStreams")
                }
            }
            if let attachments = version.attachments { card(attachments) }
            if let delivery = version.delivery { card(delivery) }
        }
    }

    private func card(_ card: FileInfoCard, pathId: String? = nil) -> some View {
        FileInfoCardView(card: card, pathId: pathId, isFirst: card === firstCard, first: first, copy: copy)
    }
}

/// A tonal card: a step off whatever it sits on (`Tone`), so it reads on any theme and on video.
private struct FileInfoCardView<First: ViewModifier>: View {
    let card: FileInfoCard
    let pathId: String?
    let isFirst: Bool
    let first: First
    let copy: (String) -> Void

    @Environment(\.dimens) private var dimens
    @ScaledMetric(relativeTo: .subheadline) private var textScale: CGFloat = 1
    @State private var width: CGFloat = 0

    var body: some View {
        let unit = dimens.unit
        let type = unit * textScale
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8 * unit) {
                Image(systemName: card.kind.systemImage).font(.system(size: 16 * type)).foregroundStyle(Palette.primary)
                Text(card.title).font(.system(size: 14 * type, weight: .semibold))
                if let subtitle = card.subtitle {
                    Text(subtitle)
                        .font(.system(size: 12 * type))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            if !card.chips.isEmpty {
                FileInfoChips(labels: card.chips, fill: Tone.stepOnCard).padding(.top, 10 * unit)
            }
            if let path = card.path {
                PathRow(path: path, copy: copy)
                    .modifier(FirstFocus(active: isFirst, first: first))
                    .accessibilityIdentifier(pathId ?? "")
                    .padding(.top, 8 * unit)
            }
            if !card.fields.isEmpty {
                fieldGrid(firstField: isFirst && card.path == nil)
                    .padding(.top, 4 * unit)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14 * unit)
        .padding(.top, 12 * unit)
        .padding(.bottom, 14 * unit)
        .background(Tone.step, in: RoundedRectangle(cornerRadius: Radius.large * unit, style: .continuous))
        .padding(.bottom, 12 * unit)
    }

    /// `FileInfoGrid`'s rows at the card's inner width, in the shared layouts' units.
    private func fieldGrid(firstField: Bool) -> some View {
        let unit = dimens.unit
        let gap = CGFloat(FileInfoGrid.shared.COLUMN_GAP) * unit
        let columns = Int(FileInfoGrid.shared.columns(width: Float(width / unit)))
        let rows = FileInfoGrid.shared.rows(fields: card.fields, columns: Int32(columns))
        return VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { rowIndex, row in
                HStack(alignment: .top, spacing: gap) {
                    ForEach(Array(row.enumerated()), id: \.offset) { fieldIndex, field in
                        FieldView(field: field)
                            .modifier(FirstFocus(active: firstField && rowIndex == 0 && fieldIndex == 0, first: first))
                    }
                    if row.count < columns, row.first?.fullWidth == false {
                        Color.clear.frame(maxWidth: .infinity, maxHeight: 0)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onGeometryChange(for: CGFloat.self, of: { $0.size.width }, action: { width = $0 })
    }
}

/// `first` on the content's first focusable element; nothing elsewhere.
private struct FirstFocus<First: ViewModifier>: ViewModifier {
    let active: Bool
    let first: First

    func body(content: Content) -> some View {
        if active { content.modifier(first) } else { content }
    }
}

/// A label over its value. On Apple TV it takes focus, with nothing to activate, so the remote scrolls through them;
/// focused, it turns to the app's focused surface (`SurfaceButtonStyle`'s white platter, its text dark).
private struct FieldView: View {
    let field: FileInfoField

    @Environment(\.dimens) private var dimens
    @ScaledMetric(relativeTo: .subheadline) private var textScale: CGFloat = 1

    var body: some View {
        let unit = dimens.unit
        let type = unit * textScale
        VStack(alignment: .leading, spacing: 2 * unit) {
            Text(field.label).font(.system(size: 11 * type, weight: .medium)).foregroundStyle(.secondary)
            Text(field.value)
                .font(field.monospace ? .system(size: 12 * type, design: .monospaced) : .system(size: 14 * type))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 6 * unit)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        #if os(tvOS)
        .modifier(FocusableField())
        #endif
    }
}

#if os(tvOS)
private struct FocusableField: ViewModifier {
    @FocusState private var focused: Bool

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 6)
            .foregroundStyle(focused ? AnyShapeStyle(Palette.onFocusedSurface) : AnyShapeStyle(.primary))
            .background(
                focused ? AnyShapeStyle(Palette.focusedSurface) : AnyShapeStyle(Color.clear),
                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
            )
            .focusable()
            .focused($focused)
    }
}
#endif

/// The file's path, whole and monospace; a tap or click copies it (Apple TV: text only).
private struct PathRow: View {
    let path: String
    let copy: (String) -> Void

    @Environment(\.dimens) private var dimens
    @ScaledMetric(relativeTo: .subheadline) private var textScale: CGFloat = 1

    var body: some View {
        Group {
            #if os(tvOS)
            label(icon: false).modifier(FocusableField())
            #else
            Button { copy(path) } label: { label(icon: true) }
                .buttonStyle(PressDimButtonStyle())
                .focusRing(radius: 8 * dimens.unit)
                .accessibilityHint(T.shared.fileInfo.copyPath)
            #endif
        }
        // The label's inset gives the focus ring and the press room around the text; the row reaches out by as much,
        // so its text starts where the other values' does.
        .padding(.horizontal, -4 * dimens.unit)
    }

    private func label(icon: Bool) -> some View {
        let unit = dimens.unit
        let type = unit * textScale
        return HStack(alignment: .top, spacing: 8 * unit) {
            VStack(alignment: .leading, spacing: 2 * unit) {
                Text(T.shared.fileInfo.path).font(.system(size: 11 * type, weight: .medium)).foregroundStyle(.secondary)
                Text(path)
                    .font(.system(size: 12 * type, design: .monospaced))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if icon {
                Image(systemName: "doc.on.doc").font(.system(size: 14 * type)).foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 4 * unit)
        .padding(.vertical, 8 * unit)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

private struct FileInfoChips: View {
    let labels: [String]
    /// A step off what the chips sit on: the sheet (`Tone.step`) or a card, itself a step (`Tone.stepOnCard`).
    let fill: Color

    @Environment(\.dimens) private var dimens
    @ScaledMetric(relativeTo: .subheadline) private var textScale: CGFloat = 1

    var body: some View {
        let unit = dimens.unit
        FlowLayout(spacing: 6 * unit) {
            ForEach(Array(labels.enumerated()), id: \.offset) { _, label in
                Text(label)
                    .font(.system(size: 12 * unit * textScale, weight: .medium))
                    .padding(.horizontal, 10 * unit)
                    .padding(.vertical, 6 * unit)
                    .background(fill, in: RoundedRectangle(cornerRadius: 8 * unit, style: .continuous))
            }
        }
    }
}

/// The tonal steps of the cards and chips: the label colour, faint. Not the hierarchical fills (`.quinary`): in the
/// player's glass those are vibrant, lightening with the video under them, and the white text over them vanished.
private enum Tone {
    static let step = Color.primary.opacity(0.08)
    static let stepOnCard = Color.primary.opacity(0.16)
}

private extension FileInfoCardKind {
    var systemImage: String {
        switch self {
        case .overview: "info.circle.fill"
        case .file: "doc.text.fill"
        case .attachments: "paperclip"
        case .delivery: "antenna.radiowaves.left.and.right"
        case .video: "film.fill"
        case .audio: "waveform"
        case .subtitles: "captions.bubble.fill"
        case .lyrics: "music.note.list"
        case .images: "photo.fill"
        case .data: "curlybraces"
        }
    }
}
