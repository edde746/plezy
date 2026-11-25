package com.edde746.plezy.image

import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.settings.VisualEffects
import kotlin.math.min
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * Artwork sizing: the transcode box per kind, its 40×60 buckets and clamps, the display's density with its supersample,
 * TV floor and budget, the reduced tier, and the URL each kind of path becomes.
 */
class ArtworkTest {
    /** Only the image URLs are scripted: a sized request shows its size and cover flag. */
    private class SizedUrlBackend(kind: BackendKind = BackendKind.PLEX) : FakeMediaBackend("server-a", kind) {
        override fun thumbnailUrl(path: String?, width: Int?, height: Int?, cover: Boolean): String =
            if (width == null && height == null) "unsized:$path" else "sized:$path?w=$width&h=$height&cover=$cover"

        override fun externalImageUrl(url: String, width: Int?, height: Int?, cover: Boolean): String = "proxied:$url?w=$width&h=$height&cover=$cover"
    }

    private val full = ArtworkDisplay()
    private val backend = SizedUrlBackend()

    /** The URL for [path] in a [width]×[height] slot at [ratio] device pixels per logical pixel. */
    private fun url(path: String, width: Double, height: Double, ratio: Double, kind: ImageKind = ImageKind.POSTER, client: FakeMediaBackend? = backend) =
        sizedImageUrl(client, path, kind, full.pixels(kind, width, height, ratio))

    /** The display a UI reporting [reported] device pixels per logical pixel gets on a 1920×1080 display. */
    private fun display(reported: Double, tv: Boolean = false, effects: VisualEffects = VisualEffects.FULL) =
        ArtworkDisplay.of(reported, tv, effects, ArtworkDevice(displayWidth = 1920, displayHeight = 1080))

    // Absolute URLs.

    @Test
    fun `a Jellyfin or Emby server sizes absolute URLs through its own image route`() {
        for (kind in listOf(BackendKind.JELLYFIN, BackendKind.EMBY)) {
            val original = "https://jf.example/Items/item-1/Images/Primary?tag=abc"
            assertEquals("sized:$original?w=240&h=360&cover=true", url(original, 120.0, 180.0, 2.0, client = SizedUrlBackend(kind)), "$kind")
        }
    }

    @Test
    fun `leaves other external URLs unchanged without a backend and proxies them through one`() {
        val original = "https://images.example/poster.jpg"
        assertEquals(original, url(original, 120.0, 180.0, 2.0, client = null))
        assertEquals("proxied:$original?w=240&h=360&cover=true", url(original, 120.0, 180.0, 2.0))
    }

    @Test
    fun `a server path needs a backend and a transcode is not transcoded again`() {
        assertEquals("", url("/library/metadata/1/thumb/2", 200.0, 300.0, 1.0, client = null))
        assertEquals("", url("", 200.0, 300.0, 1.0))
        assertEquals("unsized:/photo/:/transcode?url=x", url("/photo/:/transcode?url=x", 200.0, 300.0, 1.0))
    }

    // Sized transcodes.

    @Test
    fun `tiny slots still request a sized transcode at the minimum bucket`() {
        assertEquals("sized:/library/metadata/1/thumb/2?w=160&h=240&cover=true", url("/library/metadata/1/thumb/2", 40.0, 60.0, 1.0))
    }

    @Test
    fun `regular slots request the given density bucketed`() {
        assertEquals("sized:/library/metadata/1/thumb/2?w=600&h=900&cover=true", url("/library/metadata/1/thumb/2", 200.0, 300.0, 3.0))
    }

    @Test
    fun `backdrops keep their 10 percent cover overshoot and nothing more`() {
        assertEquals("sized:/library/metadata/1/art/2?w=880&h=540&cover=false", url("/library/metadata/1/art/2", 800.0, 450.0, 1.0, ImageKind.ART))
    }

    @Test
    fun `logos ask the server to fit inside the slot`() {
        for (kind in listOf(ImageKind.LOGO, ImageKind.HERO_LOGO)) {
            assertTrue(url("/library/metadata/1/clearLogo", 400.0, 120.0, 3.0, kind).endsWith("cover=false"), "$kind fits its slot")
        }
    }

    @Test
    fun `slot filling artwork keeps covering the requested box`() {
        for (kind in listOf(ImageKind.POSTER, ImageKind.THUMB, ImageKind.SQUARE, ImageKind.AVATAR)) {
            assertTrue(url("/library/metadata/1/thumb/2", 200.0, 300.0, 2.0, kind).endsWith("cover=true"), "$kind fills its slot")
        }
    }

    @Test
    fun `each kind takes its own box inside the slot`() {
        // A poster at 2:3 inside the slot, a thumb no wider than 16:9, a square at its shorter side, a logo at the slot.
        assertEquals(PixelSize(400, 600), full.pixels(ImageKind.POSTER, 400.0, 900.0, 1.0))
        assertEquals(PixelSize(400, 600), full.pixels(ImageKind.POSTER, 900.0, 600.0, 1.0))
        assertEquals(PixelSize(320, 240), full.pixels(ImageKind.THUMB, 1000.0, 180.0, 1.0))
        assertEquals(PixelSize(640, 360), full.pixels(ImageKind.THUMB, 640.0, 360.0, 1.0))
        assertEquals(PixelSize(240, 240), full.pixels(ImageKind.SQUARE, 240.0, 500.0, 1.0))
        assertEquals(PixelSize(240, 240), full.pixels(ImageKind.AVATAR, 500.0, 240.0, 1.0))
        assertEquals(PixelSize(400, 240), full.pixels(ImageKind.LOGO, 400.0, 120.0, 1.0))
        // An unbounded side counts as a 300×450 slot.
        assertEquals(PixelSize(320, 480), full.pixels(ImageKind.LOGO, Double.POSITIVE_INFINITY, Double.POSITIVE_INFINITY, 1.0))
    }

    @Test
    fun `a small resize asks for the same image`() {
        val artwork = Artwork.of(backend, "/library/metadata/1/thumb/2", ImageKind.POSTER)!!
        assertEquals(artwork.url(161.0, 241.5, full), artwork.url(170.0, 260.0, full))
        assertEquals("sized:/library/metadata/1/thumb/2?w=280&h=420&cover=true", artwork.url(170.0, 260.0, full))
        // 800 × 1.1 is 880.0000000000001: noise above a bucket edge stays in the bucket.
        assertEquals(PixelSize(880, 480), full.rounded(800 * 1.1, 480.0))
    }

    @Test
    fun `a tiny slot still asks for at least 160 by 240 and a huge one at most the 1080p box`() {
        assertEquals(PixelSize(160, 240), full.pixels(ImageKind.AVATAR, 24.0, 24.0, 1.0))
        assertEquals(PixelSize(160, 240), full.rounded(1.0, 1.0))
        assertEquals(PixelSize(1920, 1080), full.rounded(5000.0, 5000.0))
    }

    // Backdrops.

    @Test
    fun `a 16 by 9 backdrop fills hero slots of any shape without upscaling`() {
        // A portrait phone hero, an ultra-wide desktop hero and a 16:9 one: the 16:9 image fitted into the box asked
        // for still covers the slot, so it is never drawn larger than it came.
        for ((width, height) in listOf(400 to 600, 1200 to 500, 960 to 540)) {
            val box = full.pixels(ImageKind.ART, width.toDouble(), height.toDouble(), 1.0)
            val fit = min(box.width / 16.0, box.height / 9.0)
            assertTrue(16 * fit >= width, "box $box for ${width}x$height")
            assertTrue(9 * fit >= height, "box $box for ${width}x$height")
        }
    }

    @Test
    fun `backdrops fit inside their frame instead of covering it`() {
        assertTrue(url("/library/metadata/1/art/2", 400.0, 600.0, 1.0, ImageKind.ART).endsWith("cover=false"))
    }

    @Test
    fun `the reduced tier caps backdrops at 720p without the overshoot`() {
        val reduced = ArtworkDisplay(reduced = true)
        assertEquals(PixelSize(1280, 720), reduced.pixels(ImageKind.ART, 1920.0, 1080.0, 2.0))
        assertEquals(PixelSize(800, 480), reduced.pixels(ImageKind.ART, 800.0, 450.0, 1.0))
        // Tiles keep their full size on the reduced tier.
        assertEquals(PixelSize(600, 900), reduced.pixels(ImageKind.POSTER, 200.0, 300.0, 3.0))
    }

    // Density.

    @Test
    fun `a low density display supersamples so the paint is a real minification`() {
        assertEquals(1.5, display(1.0).fetchRatio(ImageKind.POSTER))
        assertEquals(2.25, display(1.5).fetchRatio(ImageKind.POSTER))
    }

    @Test
    fun `the headroom tapers away as the display outruns the eye`() {
        assertEquals(3.0, display(2.0).fetchRatio(ImageKind.POSTER))
        assertEquals(3.0, display(2.625).fetchRatio(ImageKind.POSTER), 0.001)
        assertEquals(3.0, display(3.0).fetchRatio(ImageKind.POSTER))
        assertEquals(3.5, display(3.5).fetchRatio(ImageKind.POSTER))
    }

    @Test
    fun `backdrops never supersample at any density`() {
        assertEquals(1.0, display(1.0).fetchRatio(ImageKind.ART))
        assertEquals(2.0, display(2.0).fetchRatio(ImageKind.ART))
    }

    @Test
    fun `the reduced tier fetches at the display density without supersampling`() {
        assertEquals(2.0, display(2.0, effects = VisualEffects.REDUCED).fetchRatio(ImageKind.POSTER))
    }

    @Test
    fun `a reduced tier TV keeps the sharp artwork density floor`() {
        assertEquals(2.0, display(1.0, tv = true, effects = VisualEffects.REDUCED).fetchRatio(ImageKind.POSTER))
        assertEquals(2.0, display(1.0, tv = true).pixelRatio)
    }

    @Test
    fun `a display denser than the reported ratio raises it`() {
        // A 4K display under compositor scaling that reports 1.
        val display = ArtworkDisplay.of(1.0, false, VisualEffects.FULL, ArtworkDevice(displayWidth = 3840, displayHeight = 2160))
        assertEquals(2.0, display.pixelRatio)
    }

    // Tier and budget.

    @Test
    fun `low end hardware takes the reduced tier unless the setting says otherwise`() {
        val low = listOf(
            ArtworkDevice(is64Bit = false),
            ArtworkDevice(lowRamDevice = true),
            ArtworkDevice(totalMemoryBytes = 2252L shl 20),
        )
        for (device in low) {
            assertTrue(ArtworkDisplay.of(1.0, false, VisualEffects.AUTO, device).reduced, "$device")
            assertEquals(false, ArtworkDisplay.of(1.0, false, VisualEffects.FULL, device).reduced, "$device")
        }
        assertEquals(false, ArtworkDisplay.of(1.0, false, VisualEffects.AUTO, ArtworkDevice(totalMemoryBytes = (2252L shl 20) + 1)).reduced)
        assertTrue(ArtworkDisplay.of(1.0, false, VisualEffects.REDUCED, ArtworkDevice()).reduced)
    }

    @Test
    fun `a 4K display raises the transcode clamp to the panel size`() {
        val display = ArtworkDisplay.of(2.0, false, VisualEffects.FULL, ArtworkDevice(displayWidth = 3840, displayHeight = 2160))
        assertEquals(2.0, display.budget)
        assertEquals(PixelSize(3840, 2160), display.rounded(3840.0, 2160.0))
        assertEquals(PixelSize(400, 600), display.rounded(400.0, 600.0))
    }

    @Test
    fun `a 4K display leaves the reduced tier at the 1080p baseline`() {
        val display = ArtworkDisplay.of(2.0, false, VisualEffects.REDUCED, ArtworkDevice(displayWidth = 3840, displayHeight = 2160))
        assertEquals(PixelSize(1920, 1080), display.rounded(3840.0, 2160.0))
    }

    @Test
    fun `without a display size the 1080p clamps still apply`() {
        assertEquals(PixelSize(1920, 1080), ArtworkDisplay.of(1.0, false, VisualEffects.FULL, ArtworkDevice()).rounded(3840.0, 2160.0))
    }

    @Test
    fun `less than two and a half GiB of memory holds a 4K display at one and a half times the budget`() {
        val device = ArtworkDevice(displayWidth = 3840, displayHeight = 2160, totalMemoryBytes = (2560L shl 20) - 1)
        assertEquals(1.5, ArtworkDisplay.of(2.0, false, VisualEffects.FULL, device).budget)
        assertEquals(PixelSize(2880, 1620), ArtworkDisplay.of(2.0, false, VisualEffects.FULL, device).rounded(3840.0, 2160.0))
    }

    // Artwork.

    @Test
    fun `fixed artwork keeps its address at every size`() {
        val artwork = Artwork.fixed("/downloads/1/poster.jpg")!!
        assertEquals("/downloads/1/poster.jpg", artwork.url(100.0, 150.0, full))
        assertEquals("/downloads/1/poster.jpg", artwork.url(1000.0, 1500.0, display(3.0)))
        assertNull(Artwork.fixed(""))
        assertNull(Artwork.of(backend, null, ImageKind.POSTER))
        assertNull(Artwork.of(null, "/library/metadata/1/thumb/2", ImageKind.POSTER))
    }
}
