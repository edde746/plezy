import SwiftUI
import PlezyKit

/// The feedback over the video that is no control: the transient message's symbols, the play/pause flash and the seek
/// badge (both drawn as the transient message is, on the player's glass), and a scrub preview's thumbnail.
extension OsdIcon {
    /// The transient message's symbol (`PlayerOsdMessage`).
    var systemImage: String {
        switch self {
        case .fastForward: "forward.fill"
        case .slowMotion: "tortoise.fill"
        case .volumeUp: "speaker.wave.2.fill"
        case .volumeDown: "speaker.wave.1.fill"
        case .volumeOff: "speaker.slash.fill"
        case .screenshot: "camera.fill"
        case .subtitles: "captions.bubble.fill"
        case .audio: "music.note"
        case .zoom: "plus.magnifyingglass"
        }
    }
}

/// The play or pause glyph that flashes in the middle when a play or pause by the viewer lands while the controls are
/// hidden (`PlayerUiState.transportFlash`), on a glass circle: in over 150 ms, held 500 ms, out over 150 ms. Each flash
/// (`TransportFlash.serial`) runs it again.
struct PlayerTransportFlash: View {
    let flash: TransportFlash

    @State private var shown = false

    var body: some View {
        Image(systemName: flash.paused ? "pause.fill" : "play.fill")
            .font(.system(size: PlayerMetrics.transportPlayIcon))
            .frame(width: PlayerMetrics.transportPlay, height: PlayerMetrics.transportPlay)
            .playerGlass(in: Circle())
            .scaleEffect(shown ? 1 : 0.8)
            .opacity(shown ? 1 : 0)
            .task(id: flash.serial) {
                shown = false
                withAnimation(.easeOut(duration: 0.15)) { shown = true }
                try? await Task.sleep(for: .milliseconds(650))
                withAnimation(.easeIn(duration: 0.15)) { shown = false }
            }
            .accessibilityHidden(true)
    }
}

/// The seek badge (`PlayerUiState.skipBadge`): on the side it went, the seconds summed ("30") beside a chevron pointing
/// the way, on a glass capsule as the transient message is. Each stack (`SkipBadge.serial`) shows it again for 1200 ms
/// before it fades. Its inset from the side is `SkipBadge.inset`: 60 pt (TV: 5 % of the width, 60 to 160), less on a
/// player too narrow for it. Left and right as seen, in every language, as the taps that seek.
struct PlayerSkipBadge: View {
    let badge: SkipBadge
    let width: CGFloat

    @State private var shown = false

    var body: some View {
        Label {
            Text(badge.label).monospacedDigit()
        } icon: {
            Image(systemName: badge.forward ? "forward.fill" : "backward.fill")
        }
        .labelStyle(.titleAndIcon)
        .environment(\.layoutDirection, badge.forward ? .rightToLeft : .leftToRight)
        .font(.headline)
        .padding(.horizontal, 18)
        .padding(.vertical, 8)
        .playerGlass(in: Capsule())
        .padding(.horizontal, CGFloat(SkipBadge.companion.inset(width: Float(width), tv: Self.tv)))
        .frame(maxWidth: .infinity, alignment: badge.forward ? .trailing : .leading)
        .environment(\.layoutDirection, .leftToRight)
        .opacity(shown ? 1 : 0)
        .task(id: badge.serial) {
            withAnimation(.easeOut(duration: 0.15)) { shown = true }
            try? await Task.sleep(for: .milliseconds(1200))
            withAnimation(.easeOut(duration: 0.3)) { shown = false }
        }
        .accessibilityHidden(true)
    }

    #if os(tvOS)
    private static let tv = true
    #else
    private static let tv = false
    #endif
}

/// A scrub preview's thumbnail (`ScrubState.frame`): the server's frame image, or its tile of a sprite sheet (BIF,
/// trickplay), `width` wide at the frame's aspect ratio, in a black rounded box with a shadow.
struct ScrubThumbnail: View {
    let frame: ScrubFrame
    let width: CGFloat

    var body: some View {
        let height = width / CGFloat(frame.aspectRatio)
        content(height: height)
            .frame(width: width, height: height)
            .background(Color.black)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .shadow(color: .black.opacity(0.5), radius: 8)
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private func content(height: CGFloat) -> some View {
        switch onEnum(of: frame) {
        case .bytes(let bytes):
            if let image = ScrubThumbnail.image(bytes.bytes) {
                image.resizable().aspectRatio(contentMode: .fill)
            }
        case .sheetTile(let tile):
            if let url = URL(string: tile.sheetUrl) {
                let scale = width / CGFloat(tile.tileWidth)
                AsyncImage(url: url) { image in
                    image.resizable()
                        .frame(width: CGFloat(tile.sheetColumns * tile.tileWidth) * scale, height: CGFloat(tile.sheetRows * tile.tileHeight) * scale)
                        .offset(x: -CGFloat(tile.tileColumn * tile.tileWidth) * scale, y: -CGFloat(tile.tileRow * tile.tileHeight) * scale)
                        .frame(width: width, height: height, alignment: .topLeading)
                } placeholder: {
                    Color.clear
                }
            }
        }
    }

    /// The frame's encoded image (JPEG from the server's BIF).
    private static func image(_ bytes: KotlinByteArray) -> Image? {
        let count = Int(bytes.size)
        var data = Data(count: count)
        data.withUnsafeMutableBytes { buffer in
            for index in 0..<count { buffer[index] = UInt8(bitPattern: bytes.get(index: Int32(index))) }
        }
        #if os(macOS)
        return NSImage(data: data).map(Image.init(nsImage:))
        #else
        return UIImage(data: data).map(Image.init(uiImage:))
        #endif
    }
}
