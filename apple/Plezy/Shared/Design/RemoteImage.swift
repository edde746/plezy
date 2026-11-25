import Accelerate
import Nuke
import NukeUI
import PlezyKit
import SwiftUI

/// A server's artwork (poster, thumbnail, background, logo) loaded and cached by Nuke (`ArtworkPipeline`; image loading
/// is native, not shared). Shows `placeholder` while loading, on failure and for no `artwork` or a malformed address,
/// told whether it stands for artwork that isn't there (`failed`: the load failed, or there is no address) rather than
/// one still loading; the image fills the frame the caller gives it, cropped (`.fill`, keeping its `alignment` part in
/// view) or letterboxed (`.fit`). A cropped image stays inside that frame for touches as well as drawing: clipping
/// alone leaves the overflow hit-testable, so a wide poster in a row would take its neighbour's taps. Smart Invert
/// leaves the image as it is, as it does photos.
///
/// The server is asked for the artwork at the frame's size on this display (`Artwork.url`, [ArtworkScreen]), bucketed
/// so a small resize asks for the same image. The image is made at the frame's size in pixels ([ArtworkResize]), so the
/// screen draws it pixel for pixel: drawn from a larger bitmap, the screen shrank it bilinearly from one pixel in
/// several and an episode's thumbnail looked jagged. A frame that changes size loads it again at the new size (from
/// Nuke's caches, or the server in another bucket), the image last made for the artwork showing until it comes
/// ([LastMade]). `blurred` blurs `artwork`'s image past recognition (an unwatched episode's still, so it gives nothing
/// away): a Gaussian a tenth of the frame's width, its edges kept opaque; the placeholder stays sharp.
///
/// `fallback`, when set, is loaded in `artwork`'s place once `artwork` fails (or has no address), sharp (a series' art
/// in place of an episode's still gives nothing away); without one nothing more is requested.
///
/// A `logo` on a light theme is recoloured to read on it (`LogoInk`); a title's on a dark one gets a thin light halo, so
/// dark lettering in it (a network's name in black) still reads on the dark page.
///
/// `onResult`, where given, hears what became of `artwork`'s image (`ArtworkOutcome`).
struct RemoteImage<Placeholder: View>: View {
    let artwork: Artwork?
    var fallback: Artwork?
    var contentMode: ContentMode = .fill
    var alignment: Alignment = .center
    var blurred = false
    /// The frame's size where the caller sets it (a card's artwork): the image is asked for as the view is first made,
    /// not a layout pass later once the frame is measured.
    var size: CGSize?
    var logo: LogoRecolour? = nil
    @ViewBuilder var placeholder: (_ failed: Bool) -> Placeholder
    var onResult: ((ArtworkOutcome) -> Void)?

    @Environment(\.displayScale) private var displayScale
    @Environment(\.formFactor) private var formFactor
    @Environment(\.layoutDirection) private var layoutDirection
    @Environment(\.visualEffects) private var visualEffects
    @Environment(\.colorScheme) private var colorScheme
    /// The frame as measured, in points (without `size`); zero until it is laid out, and nothing loads till then.
    @State private var measured = CGSize.zero

    var body: some View {
        let frame = self.frame
        let laidOut = frame.width > 0 && frame.height > 0
        let url = address()
        let request = url.map(imageRequest)
        measuring
            .overlay(alignment: alignment) {
                LazyImage(request: request) { state in
                    if let image = state.image ?? LastMade.image(for: artwork?.key) {
                        image.resizable().aspectRatio(contentMode: contentMode)
                            .blur(radius: blurred ? frame.width / 10 : 0, opaque: true)
                            .shadow(color: logo == .title && colorScheme == .dark ? .white.opacity(0.7) : .clear, radius: 1)
                            .accessibilityIgnoresInvertColors()
                    } else if let fallback, laidOut, request == nil || state.error.map(Self.failed) == true {
                        RemoteImage(artwork: fallback, contentMode: contentMode, alignment: alignment, size: size, placeholder: placeholder)
                    } else {
                        placeholder(artwork == nil || (laidOut && url == nil) || state.error.map(Self.failed) == true)
                    }
                }
                .onCompletion { result in
                    switch result {
                    case .success(let response):
                        if let key = artwork?.key { LastMade.keep(response, for: key) }
                        onResult?(.loaded)
                    case .failure(let error):
                        if Self.failed(error) { onResult?(.failed) }
                    }
                }
            }
            .clipped()
            .onChange(of: laidOut && url == nil, initial: true) { _, missing in
                if missing, artwork != nil { onResult?(.unresolved) }
            }
            .contentShape(Rectangle())
    }

    /// The frame in points: `size`, else as measured.
    private var frame: CGSize { size ?? measured }

    /// Without `size`, the frame measured as it is laid out (`measured`).
    @ViewBuilder
    private var measuring: some View {
        if size == nil {
            Color.clear.onGeometryChange(for: CGSize.self) { $0.size } action: { measured = $0 }
        } else {
            Color.clear
        }
    }

    /// The load failed, rather than having no request yet (no frame laid out).
    private static func failed(_ error: Error) -> Bool {
        if case .imageRequestMissing? = error as? ImagePipeline.Error { return false }
        return true
    }

    /// `artwork`'s address for the frame on this display: a web address, or a file of the device (a download's
    /// artwork, stored as its absolute path); nil before the frame is laid out, or while it is under a pixel.
    private func address() -> URL? {
        guard let artwork, ArtworkResize.drawable(pixels) else { return nil }
        let display = ArtworkScreen.display(scale: displayScale, tv: formFactor == .tv, visualEffects: visualEffects)
        let url = artwork.url(width: Double(frame.width), height: Double(frame.height), display: display)
        return url.hasPrefix("/") ? URL(fileURLWithPath: url) : URL(string: url)
    }

    /// The frame's size in pixels on this display.
    private var pixels: CGSize {
        CGSize(width: (frame.width * displayScale).rounded(), height: (frame.height * displayScale).rounded())
    }

    private func imageRequest(_ url: URL) -> ImageRequest {
        var anchor = UnitPoint(x: alignment.horizontal == .leading ? 0 : alignment.horizontal == .trailing ? 1 : 0.5,
                               y: alignment.vertical == .top ? 0 : alignment.vertical == .bottom ? 1 : 0.5)
        if layoutDirection == .rightToLeft { anchor.x = 1 - anchor.x }
        var request = ArtworkResize(pixels: pixels, fill: contentMode == .fill, anchor: anchor).request(url)
        if let logo, colorScheme == .light, let theme = ThemeState.shared.theme,
           let ink = LogoToneKt.logoInk(palette: theme.palette ?? theme.light) {
            request.processors.append(LogoInk(ink: ink.int64Value, remapMixed: logo == .cell))
        }
        return request
    }
}

extension RemoteImage {
    /// The image at `url` as it is (`Artwork.fixed`): a download's file, an image its host already sized.
    init(url: String?, fallbackUrl: String? = nil, contentMode: ContentMode = .fill, alignment: Alignment = .center, blurred: Bool = false,
         @ViewBuilder placeholder: @escaping (_ failed: Bool) -> Placeholder) {
        self.init(artwork: Artwork.companion.fixed(url: url), fallback: Artwork.companion.fixed(url: fallbackUrl), contentMode: contentMode,
                  alignment: alignment, blurred: blurred, placeholder: placeholder)
    }
}

extension RemoteImage where Placeholder == EmptyView {
    init(artwork: Artwork?, fallback: Artwork? = nil, contentMode: ContentMode = .fill, alignment: Alignment = .center,
         onResult: ((ArtworkOutcome) -> Void)? = nil) {
        self.init(artwork: artwork, fallback: fallback, contentMode: contentMode, alignment: alignment,
                  placeholder: { _ in EmptyView() }, onResult: onResult)
    }

    init(url: String?, fallbackUrl: String? = nil, contentMode: ContentMode = .fill, alignment: Alignment = .center) {
        self.init(url: url, fallbackUrl: fallbackUrl, contentMode: contentMode, alignment: alignment) { _ in EmptyView() }
    }
}

/// What became of a `RemoteImage`'s artwork: its image came, its load failed, or it has no address to load from (a
/// server's path before its client is known), which isn't a failure of the image.
enum ArtworkOutcome {
    case loaded, failed, unresolved
}

/// The display artwork is fetched for on this device ([ArtworkDisplay.of]): `scale` pixels per point, at least 2 on a
/// TV, the budget scaled to the screen's pixels, in the tier `visualEffects` picks (the user's choice; Auto is Full, as
/// Apple devices report none of the low-end hardware signals).
@MainActor
enum ArtworkScreen {
    static func display(scale: CGFloat, tv: Bool, visualEffects: VisualEffects) -> ArtworkDisplay {
        ArtworkDisplay.companion.of(reportedPixelRatio: Double(scale), tv: tv, visualEffects: visualEffects, device: device)
    }

    /// The screen's size in pixels, read once: the budgets stay the same for the session.
    private static let device: ArtworkDevice = {
        #if os(macOS)
        let screen = NSScreen.main
        let size = screen.map { CGSize(width: $0.frame.width * $0.backingScaleFactor, height: $0.frame.height * $0.backingScaleFactor) }
        #else
        let size = UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.screen.nativeBounds.size }.first
        #endif
        return ArtworkDevice(
            displayWidth: size.map { KotlinInt(int: Int32($0.width)) },
            displayHeight: size.map { KotlinInt(int: Int32($0.height)) },
            is64Bit: true,
            lowRamDevice: false,
            totalMemoryBytes: nil
        )
    }()
}

/// Artwork fetched ahead of its cards (a grid's next rows), asked for and made as `RemoteImage` asks for and makes it
/// for a centred, filled frame of `size` points on this display, so the cards find it in Nuke's caches.
@MainActor
enum ArtworkPrefetch {
    private static let prefetcher = ImagePrefetcher()

    static func start(_ artworks: [Artwork], size: CGSize, displayScale: CGFloat, tv: Bool, visualEffects: VisualEffects) {
        let pixels = CGSize(width: (size.width * displayScale).rounded(), height: (size.height * displayScale).rounded())
        guard ArtworkResize.drawable(pixels), !artworks.isEmpty else { return }
        let display = ArtworkScreen.display(scale: displayScale, tv: tv, visualEffects: visualEffects)
        let resize = ArtworkResize(pixels: pixels, fill: true)
        prefetcher.startPrefetching(with: artworks.compactMap { artwork in
            let url = artwork.url(width: Double(size.width), height: Double(size.height), display: display)
            return (url.hasPrefix("/") ? URL(fileURLWithPath: url) : URL(string: url)).map(resize.request)
        })
    }
}

extension EnvironmentValues {
    /// The user's visual effects choice (`Appearance.visualEffects`), the tier artwork is fetched in (`RemoteImage`).
    @Entry var visualEffects: VisualEffects = .auto
    /// The reduced visual effects tier: `ArtworkScreen.display`'s for `visualEffects` (the shell sets both). Focus loses
    /// its glow and snaps, press and shape changes snap, backdrops neither rotate nor crossfade, blurred artwork
    /// backgrounds give way to the plain background and the equalizer stands still.
    @Entry var reducedEffects = false
}

extension View {
    /// `animation(_:value:)` that the reduced tier (`reducedEffects`) leaves out: what `value` changes snaps there.
    func effectsAnimation<Value: Equatable>(_ animation: Animation, value: Value) -> some View {
        modifier(EffectsAnimation(animation: animation, value: value))
    }
}

private struct EffectsAnimation<Value: Equatable>: ViewModifier {
    let animation: Animation
    let value: Value
    @Environment(\.reducedEffects) private var reduced

    func body(content: Content) -> some View {
        content.animation(reduced ? nil : animation, value: value)
    }
}

/// The image last made for each artwork ([Artwork.key], its tokens blanked: `ArtworkPipeline.redacted`), at whichever
/// size: shown instead of the placeholder until the image for the frame's size comes, by the view that showed it (its
/// frame changed) and by any that shows the artwork anew. A screen opened again may lay a frame out a pass after it
/// appears (a phone's Detail backdrop, whose height takes the top inset then): its first request, at the size before,
/// misses Nuke's memory cache, which keys each size apart, and the backdrop would be missing for a frame. At most 64 MB
/// of bitmaps, most of them Nuke's own as well.
@MainActor
private enum LastMade {
    private static let images: NSCache<NSString, PlatformImage> = {
        let cache = NSCache<NSString, PlatformImage>()
        cache.totalCostLimit = 64 << 20
        return cache
    }()

    static func image(for key: String?) -> Image? {
        guard let key, let image = images.object(forKey: ArtworkPipeline.redacted(key) as NSString) else { return nil }
        return Image(platformImage: image)
    }

    static func keep(_ response: ImageResponse, for key: String) {
        let key = ArtworkPipeline.redacted(key)
        let bytes = response.image.uprightCGImage.map { $0.bytesPerRow * $0.height } ?? 0
        images.setObject(response.image, forKey: key as NSString, cost: bytes)
    }
}

/// Where a clear logo sits, which decides whether a mark with significant colour is recoloured too: a title's logo keeps
/// its look, a small channel cell's is recoloured whatever it is.
enum LogoRecolour {
    case title, cell
}

/// A light clear logo recoloured towards `ink`, the light theme's text colour (`toneLogo`), so a white mark made for
/// dark screens reads on a light page; art with its own contrast keeps its pixels.
struct LogoInk: ImageProcessing, Hashable {
    let ink: Int64
    let remapMixed: Bool

    var identifier: String { "plezy/logo-ink?\(String(ink, radix: 16)),\(remapMixed)" }

    func process(_ image: PlatformImage) -> PlatformImage? {
        guard let source = image.uprightCGImage,
              let toned = LogoTone_appleKt.toneLogo(image: Unmanaged.passUnretained(source).toOpaque(), ink: ink, remapMixed: remapMixed)
        else { return image }
        // Kotlin/Native hands Core Graphics references over as opaque pointers; the made image comes retained.
        return PlatformImage(upright: Unmanaged<CGImage>.fromOpaque(toned).takeRetainedValue())
    }
}

/// Artwork made at the size it is drawn: `pixels` filled (`fill`: cropped to its shape, keeping the `anchor` part:
/// (0, 0) the top leading corner) or fitted, by vImage's high-quality resampling (Lanczos), which comes within 0.5 %
/// RMSE of ImageMagick's Lanczos on the app's thumbnails, posters and backdrops. An image smaller than that is cropped
/// to the shape only and drawn larger by the screen, never made larger here; one whose orientation isn't up is left
/// as it is, and so is any image when `pixels` isn't a drawable size (`drawable`) or what it would make comes under a
/// pixel (a very long image fitted in a small frame): vImage traps on an empty bitmap.
struct ArtworkResize: ImageProcessing, Hashable {
    let pixels: CGSize
    let fill: Bool
    var anchor = UnitPoint.center

    var identifier: String {
        let size = Self.drawable(pixels) ? "\(Int(pixels.width))x\(Int(pixels.height))" : "none"
        return "plezy/artwork?\(size),\(fill ? "fill" : "fit"),\(anchor.x),\(anchor.y)"
    }

    /// At least a pixel each way, and finite: a size an image can be made at.
    static func drawable(_ size: CGSize) -> Bool {
        size.width.isFinite && size.height.isFinite && size.width >= 1 && size.height >= 1
    }

    /// `url`'s image decoded by ImageIO no larger than twice `pixels` (filling them or fitted in them, as this makes
    /// it), then made by this, cached under `ArtworkPipeline.key`. A server's image may be any size, and decoded whole
    /// one 30000 pixels square takes 3.6 GB, which ends the app; decoded near the size it is drawn at it costs that
    /// little whatever its own. Twice that, so what shows is resampled by the Lanczos here, not by ImageIO's
    /// thumbnailing, which never enlarges.
    @MainActor
    func request(_ url: URL) -> ImageRequest {
        var request = ImageRequest(url: url, processors: [self])
        request.imageID = ArtworkPipeline.key(url)
        request.thumbnail = ImageRequest.ThumbnailOptions(
            size: CGSize(width: pixels.width * 2, height: pixels.height * 2), unit: .pixels, contentMode: fill ? .aspectFill : .aspectFit
        )
        return request
    }

    func process(_ image: PlatformImage) -> PlatformImage? {
        guard Self.drawable(pixels), let source = image.uprightCGImage, source.width > 0, source.height > 0 else { return image }
        let width = Double(source.width), height = Double(source.height)
        let scale = fill ? max(pixels.width / width, pixels.height / height) : min(pixels.width / width, pixels.height / height)
        // The part of the source that shows: all of it when fitted, the target's shape when filled.
        let shown = fill ? CGSize(width: min(width, pixels.width / scale), height: min(height, pixels.height / scale)) : CGSize(width: width, height: height)
        let crop = CGRect(x: ((width - shown.width) * anchor.x).rounded(), y: ((height - shown.height) * anchor.y).rounded(),
                          width: shown.width.rounded(), height: shown.height.rounded())
        // Smaller than the frame: cropped to its shape only, when it needs that.
        guard scale < 1 || fill && (crop.width < width || crop.height < height) else { return image }
        let size = scale >= 1 ? crop.size : fill ? pixels : CGSize(width: (width * scale).rounded(), height: (height * scale).rounded())
        guard Self.drawable(size), Self.drawable(crop.size), let cropped = source.cropping(to: crop),
              let made = cropped.bitmap(width: Int(size.width), height: Int(size.height)) else {
            return image
        }
        return PlatformImage(upright: made)
    }
}

private extension CGImage {
    /// This image decoded into a bitmap of `width` × `height`, by vImage's Lanczos when that isn't its own size, in
    /// premultiplied BGRA in its own RGB colour space (else sRGB); nil when vImage can't take it. Decoded here, on
    /// Nuke's processing queue: Nuke decompresses only the images it decodes, so a cropped JPEG left as it is would
    /// decode on the main thread when first drawn.
    func bitmap(width: Int, height: Int) -> CGImage? {
        guard width > 0, height > 0 else { return nil }
        let space = colorSpace.flatMap { $0.model == .rgb ? $0 : nil } ?? CGColorSpace(name: CGColorSpace.sRGB)!
        let info = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
        guard let format = vImage_CGImageFormat(bitsPerComponent: 8, bitsPerPixel: 32, colorSpace: space, bitmapInfo: info),
              var input = try? vImage_Buffer(cgImage: self, format: format) else { return nil }
        defer { input.free() }
        guard width != self.width || height != self.height else { return try? input.createCGImage(format: format) }
        guard var output = try? vImage_Buffer(width: width, height: height, bitsPerPixel: 32) else { return nil }
        defer { output.free() }
        guard vImageScale_ARGB8888(&input, &output, nil, vImage_Flags(kvImageHighQualityResampling)) == kvImageNoError else { return nil }
        return try? output.createCGImage(format: format)
    }
}

#if os(macOS)
extension NSImage {
    var uprightCGImage: CGImage? { cgImage(forProposedRect: nil, context: nil, hints: nil) }
    convenience init(upright image: CGImage) { self.init(cgImage: image, size: NSSize(width: image.width, height: image.height)) }
}

private extension Image {
    init(platformImage: NSImage) { self.init(nsImage: platformImage) }
}
#else
extension UIImage {
    var uprightCGImage: CGImage? { imageOrientation == .up ? cgImage : nil }
    convenience init(upright image: CGImage) { self.init(cgImage: image, scale: 1, orientation: .up) }
}

private extension Image {
    init(platformImage: UIImage) { self.init(uiImage: platformImage) }
}
#endif
