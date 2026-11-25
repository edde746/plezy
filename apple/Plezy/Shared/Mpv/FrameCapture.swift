#if !os(tvOS)
import AVFoundation
import CoreImage
import ImageIO
import QuartzCore
import UniformTypeIdentifiers

/// A screenshot of a hardware-decoded video (`MpvPlayerEngine.screenshot`). mpv can't take one itself there: the frame
/// vo_avfoundation holds is a VideoToolbox buffer mpv's screenshot code doesn't download, so its writer fails on it
/// ("Input image format videotoolbox not supported by libswscale"). This takes the frame on the display layer
/// (`displayedPixelBuffer`) at the video's display aspect and draws over it the frame on vo_avfoundation's subtitle
/// layer, another sample buffer layer beside or inside it, as mpv's `screenshot subtitles` would.
@MainActor
enum FrameCapture {
    /// The frame on `layer`, the surface's display layer, with the subtitles' over it; nil without a frame on screen
    /// (or before macOS 14.4 and iOS 17.4, which can't read it).
    static func image(displayLayer layer: CALayer) -> CGImage? {
        guard #available(iOS 17.4, macOS 14.4, *),
              let displayLayer = layer as? AVSampleBufferDisplayLayer, let space = displayLayer.superlayer,
              let buffer = displayLayer.sampleBufferRenderer.displayedPixelBuffer(), let frame = image(buffer)
        else { return nil }
        let size = displaySize(buffer)
        guard let drawing = CGContext(
            data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else { return nil }
        drawing.draw(frame, in: CGRect(origin: .zero, size: size))
        // The picture's place among the layers: where the display layer fits it. The subtitle layer's frame maps from
        // there into the shot.
        let picture = AVMakeRect(aspectRatio: size, insideRect: displayLayer.frame)
        let scale = CGSize(width: size.width / picture.width, height: size.height / picture.height)
        let subtitleLayers = ((space.sublayers ?? []) + (displayLayer.sublayers ?? []))
            .compactMap { $0 as? AVSampleBufferDisplayLayer }
            .filter { $0 !== displayLayer && !$0.isHidden }
        for subtitles in subtitleLayers {
            guard let overlay = subtitles.sampleBufferRenderer.displayedPixelBuffer().flatMap({ image($0) }) else { continue }
            let rect = subtitles.convert(subtitles.bounds, to: space)
            let x = (rect.minX - picture.minX) * scale.width
            #if os(iOS)
            // UIKit's layers lay out top down, the bitmap bottom up.
            let y = size.height - (rect.maxY - picture.minY) * scale.height
            #else
            let y = (rect.minY - picture.minY) * scale.height
            #endif
            drawing.draw(overlay, in: CGRect(x: x, y: y, width: rect.width * scale.width, height: rect.height * scale.height))
        }
        return drawing.makeImage()
    }

    private static func image(_ buffer: CVPixelBuffer) -> CGImage? {
        context.createCGImage(CIImage(cvPixelBuffer: buffer), from: CGRect(
            x: 0, y: 0, width: CVPixelBufferGetWidth(buffer), height: CVPixelBufferGetHeight(buffer)
        ))
    }

    /// Writes `image` as a JPEG (mpv's default format and quality) to `directory` under mpv's default name, the first
    /// free `mpv-shotNNNN.jpg`; whether it was written.
    nonisolated static func write(_ image: CGImage, to directory: String) -> Bool {
        let folder = URL(fileURLWithPath: (directory as NSString).expandingTildeInPath, isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        guard let file = (1...9999).lazy
            .map({ folder.appendingPathComponent(String(format: "mpv-shot%04d.jpg", $0)) })
            .first(where: { !FileManager.default.fileExists(atPath: $0.path) }),
            let destination = CGImageDestinationCreateWithURL(file as CFURL, UTType.jpeg.identifier as CFString, 1, nil)
        else { return false }
        CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: 0.9] as CFDictionary)
        return CGImageDestinationFinalize(destination)
    }

    private static let context = CIContext()

    /// The buffer's size at its pixel aspect ratio (an anamorphic video's wider than it is stored).
    private static func displaySize(_ buffer: CVPixelBuffer) -> CGSize {
        let width = CGFloat(CVPixelBufferGetWidth(buffer))
        let height = CGFloat(CVPixelBufferGetHeight(buffer))
        guard let aspect = CVBufferCopyAttachment(buffer, kCVImageBufferPixelAspectRatioKey, nil) as? [CFString: Int],
              let across = aspect[kCVImageBufferPixelAspectRatioHorizontalSpacingKey],
              let down = aspect[kCVImageBufferPixelAspectRatioVerticalSpacingKey], across > 0, down > 0
        else { return CGSize(width: width, height: height) }
        return CGSize(width: (width * CGFloat(across) / CGFloat(down)).rounded(), height: height)
    }
}
#endif
