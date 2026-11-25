import XCTest

/// Artwork resizing (`ArtworkResize`, run in the app by `ArtworkResizeProbe`, `-artworkResizeProbe YES`): a target
/// that is empty, empty one way, under a pixel, negative or not finite, or a fit that would come under a pixel, leaves
/// the image as it is (vImage traps on an empty bitmap, which ended the app when Now Playing's artwork had no height);
/// a one-pixel target, a fill and a fit are made at their sizes.
final class ArtworkResizeTests: PlezyUITestCase {
    func testEmptyOrInvalidTargetsKeepTheImage() {
        launchDev(arguments: ["-artworkResizeProbe", "YES"])
        let probe = require("app.artworkResize", timeout: 30, "the artwork resize probe")
        XCTAssertEqual(
            probe.label,
            [
                "zero-fill=kept", "zero-fit=kept", "width-zero=kept", "height-zero=kept", "subpixel=kept", "negative=kept",
                "nan=kept", "infinite=kept", "fit-under-pixel=kept", "one-pixel=1x1", "fill=200x100", "fit=100x100",
            ].joined(separator: " ")
        )
    }
}
