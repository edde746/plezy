import CoreGraphics
import Nuke
import SwiftUI

/// Debug builds, with the launch argument `-artworkResizeProbe YES`: `ArtworkResize` run on drawn images against
/// targets it must leave the image alone for (empty, one side empty, under a pixel, negative, not finite, and a fit
/// that would come under a pixel) and against ones it must make, as the label of an element the UI tests read
/// (`app.artworkResize`): `<case>=<width>x<height>` per case, the size of the image it returned, or `kept` when it
/// returned the image as it was. A target that traps ends the app instead.
struct ArtworkResizeProbe: View {
    var body: some View {
        if UserDefaults.standard.bool(forKey: "artworkResizeProbe") {
            Color.clear
                .frame(width: 1, height: 1)
                .accessibilityElement()
                .accessibilityLabel(Text(verbatim: Self.summary))
                .accessibilityIdentifier("app.artworkResize")
                .allowsHitTesting(false)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        }
    }

    private static let summary: String = {
        let square = image(width: 400, height: 400)
        let long = image(width: 4000, height: 2)
        let cases: [(String, PlatformImage?, ArtworkResize)] = [
            ("zero-fill", square, ArtworkResize(pixels: .zero, fill: true)),
            ("zero-fit", square, ArtworkResize(pixels: .zero, fill: false)),
            ("width-zero", square, ArtworkResize(pixels: CGSize(width: 0, height: 300), fill: true)),
            ("height-zero", square, ArtworkResize(pixels: CGSize(width: 300, height: 0), fill: true)),
            ("subpixel", square, ArtworkResize(pixels: CGSize(width: 0.4, height: 0.4), fill: true)),
            ("negative", square, ArtworkResize(pixels: CGSize(width: -10, height: -10), fill: true)),
            ("nan", square, ArtworkResize(pixels: CGSize(width: CGFloat.nan, height: 100), fill: true)),
            ("infinite", square, ArtworkResize(pixels: CGSize(width: CGFloat.infinity, height: 100), fill: false)),
            ("fit-under-pixel", long, ArtworkResize(pixels: CGSize(width: 10, height: 10), fill: false)),
            ("one-pixel", square, ArtworkResize(pixels: CGSize(width: 1, height: 1), fill: true)),
            ("fill", square, ArtworkResize(pixels: CGSize(width: 200, height: 100), fill: true)),
            ("fit", square, ArtworkResize(pixels: CGSize(width: 200, height: 100), fill: false)),
        ]
        return cases.map { name, source, resize in
            guard let source else { return "\(name)=no-source" }
            let made = resize.process(source)
            guard let made, made !== source else { return "\(name)=kept" }
            guard let cg = made.uprightCGImage else { return "\(name)=unreadable" }
            return "\(name)=\(cg.width)x\(cg.height)"
        }.joined(separator: " ")
    }()

    /// A `width` × `height` image of one opaque colour.
    private static func image(width: Int, height: Int) -> PlatformImage? {
        guard let space = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: space,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
        else { return nil }
        context.setFillColor(CGColor(srgbRed: 0.2, green: 0.4, blue: 0.8, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage().map { PlatformImage(upright: $0) }
    }
}
