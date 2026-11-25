import CoreImage
import CoreImage.CIFilterBuiltins
import OSLog
import SwiftUI
import PlezyKit

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

private let log = Logger(subsystem: "com.edde746.plezy", category: "qr")

/// `payload` as a QR code (CoreImage's generator, medium error correction), black modules on a white square
/// (phone cameras read that reliably, so Smart Invert leaves it so), with CoreImage's quiet zone, `size` wide and drawn
/// without smoothing so the modules stay sharp. A payload no QR code can hold (past about 2.3 KB) shows an error line in its place, `size` wide, read out as itself rather than as `description`.
/// The code is drawn once per payload, as it shows or changes, not on each pass of the parent's body (a countdown's
/// second, the player's updates); until it is, the square is empty.
struct QRCodeImage: View {
    let payload: String
    let description: String
    let size: CGFloat

    @State private var code: RenderedCode?

    var body: some View {
        drawn.onChange(of: payload, initial: true) {
            code = RenderedCode(payload: payload, image: Self.render(payload))
        }
    }

    @ViewBuilder
    private var drawn: some View {
        if let code, code.payload == payload {
            if let image = code.image {
                Image(decorative: image, scale: 1)
                    .interpolation(.none)
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                    .frame(width: size, height: size)
                    .accessibilityIgnoresInvertColors()
                    .accessibilityElement()
                    .accessibilityLabel(description)
            } else {
                ErrorLine(text: T.shared.nav.qrFailed)
                    .frame(width: size)
                    .accessibilityElement(children: .combine)
            }
        } else {
            Color.clear.frame(width: size, height: size)
        }
    }

    /// One context for every code: making one is the costly part.
    private static let context = CIContext(options: [.useSoftwareRenderer: false])

    /// One pixel per module; the view scales it up.
    private static func render(_ payload: String) -> CGImage? {
        let generator = CIFilter.qrCodeGenerator()
        generator.message = Data(payload.utf8)
        generator.correctionLevel = "M"
        let colored = CIFilter.falseColor()
        colored.inputImage = generator.outputImage
        colored.color0 = CIColor(red: 0, green: 0, blue: 0)
        colored.color1 = CIColor(red: 1, green: 1, blue: 1)
        guard let output = colored.outputImage else {
            log.error("no QR code for a payload of \(payload.utf8.count, privacy: .public) bytes: past the code's capacity")
            return nil
        }
        guard let image = context.createCGImage(output, from: output.extent) else {
            log.error("the QR code of \(payload.utf8.count, privacy: .public) bytes didn't render")
            return nil
        }
        return image
    }
}

/// A payload's QR code as drawn: nil where none could be.
private struct RenderedCode {
    let payload: String
    let image: CGImage?
}

/// The system pasteboard (iOS, macOS; tvOS has none).
enum Pasteboard {
    /// How long a sensitive copy stays on an iOS pasteboard.
    private static let sensitiveLifetime: TimeInterval = 120

    /// Copies `text`; `sensitive` (a secret): iOS keeps it on this device (no Universal
    /// Clipboard) for two minutes, macOS marks it concealed so clipboard managers skip it (nspasteboard.org).
    @MainActor
    static func copy(_ text: String, sensitive: Bool = false) {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        if sensitive {
            NSPasteboard.general.setString("", forType: NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType"))
        }
        #elseif os(iOS)
        if sensitive {
            UIPasteboard.general.setItems(
                [["public.utf8-plain-text": text]],
                options: [.localOnly: true, .expirationDate: Date().addingTimeInterval(sensitiveLifetime)]
            )
        } else {
            UIPasteboard.general.string = text
        }
        #endif
    }
}
