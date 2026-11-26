package com.edde746.plezy.ui.image

import androidx.compose.foundation.layout.Box
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.isSpecified
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalDensity
import coil3.Bitmap
import coil3.ComponentRegistry
import coil3.ImageLoader
import coil3.annotation.ExperimentalCoilApi
import coil3.compose.AsyncImage
import coil3.compose.AsyncImagePainter
import coil3.compose.LocalPlatformContext
import coil3.compose.setSingletonImageLoaderFactory
import coil3.map.Mapper
import coil3.PlatformContext
import coil3.SingletonImageLoader
import coil3.request.ImageRequest
import coil3.request.Options
import coil3.request.crossfade
import coil3.request.transformations
import com.edde746.plezy.image.logoInk
import com.edde746.plezy.ui.theme.LocalPlezyColors
import coil3.size.Dimension
import com.edde746.plezy.image.Artwork
import com.edde746.plezy.image.ArtworkDisplay
import com.edde746.plezy.image.ImageMemoryBudget
import com.edde746.plezy.ui.probe.perfImage
import io.ktor.client.HttpClient
import coil3.request.Disposable
import java.io.File

/**
 * Makes Coil load images as [artworkImageLoader] does: through the app's [http] client, cached without their tokens on
 * disk in [directory] (the platform's, for this user and this app alone), at most six downloads at once (three on the
 * [reduced] effects tier), decoded images within [memory]; all as they are when the first image loads. Artwork is
 * asked for at the size Coil measures for its bounds ([SizedArtworkMapper]). Call once, at the root of the app, before
 * any [RemoteImage].
 */
// setSingletonImageLoaderFactory is Coil's documented Compose Multiplatform setup; it is marked experimental.
@OptIn(ExperimentalCoilApi::class)
@Composable
fun ProvideImageLoader(http: HttpClient, reduced: Boolean, memory: ImageMemoryBudget, directory: File) {
    setSingletonImageLoaderFactory { context -> artworkImageLoader(context, http, reduced, memory, directory) }
}

/**
 * Loads [artwork] into Coil's caches as a [RemoteImage] of [width] × [height] pixels asks for it on [display] at
 * [density], without drawing it, so the card scrolled to shows it at once. Disposing the result cancels it.
 */
fun prefetchImage(context: PlatformContext, artwork: Artwork, display: ArtworkDisplay, density: Float, width: Int, height: Int): Disposable =
    SingletonImageLoader.get(context).enqueue(ImageRequest.Builder(context).data(SizedArtwork(artwork, display, density)).size(width, height).build())

/** This platform's decoders, ahead of Coil's own: each image decoded at the size it is drawn, shrunk without aliasing. */
internal expect fun ComponentRegistry.Builder.addDecoders()

/** The bitmaps this platform decodes into on the [reduced] tier. */
internal expect fun ImageLoader.Builder.tierBitmaps(reduced: Boolean): ImageLoader.Builder

/** An image from [url] as it is: [RemoteImage] of [Artwork.fixed]. */
@Composable
fun RemoteImage(
    url: String?,
    contentDescription: String?,
    modifier: Modifier = Modifier,
    contentScale: ContentScale = ContentScale.Crop,
    alignment: Alignment = Alignment.Center,
    blank: Color = Color.Unspecified,
    fallbackUrl: String? = null,
    blurred: Boolean = false,
    onAspect: ((Float) -> Unit)? = null,
    error: (@Composable () -> Unit)? = null,
    fallback: (@Composable () -> Unit)? = null,
) = RemoteImage(
    Artwork.fixed(url), contentDescription, modifier, contentScale, alignment, blank, Artwork.fixed(fallbackUrl), blurred,
    onAspect = onAspect, error = error, fallback = fallback,
)

/**
 * [artwork] (posters, backgrounds, logos), asked for at the size of the bounds on this display ([LocalArtworkDisplay]),
 * cropped to the bounds by default, placed by [alignment] where it doesn't fill them; without [artwork], or once it
 * fails to load, [fallbackArtwork] instead (unless it is the same). [fallback] shows while there is no artwork, while
 * it loads and when it fails, so a card is never an empty box; [blank] (a card's own fill) fills the bounds under it.
 * With [error], [fallback] shows only while an image loads, and [error] once there is none to show (no artwork, or
 * every one failed: a card's fallback icon). An image loaded before shows from the start of its request, while the
 * loader looks it up off the main thread ([LoadedImageKeys]): a card composed again shows its picture at once. A loaded
 * image shows at once, without a fade, wherever it came from (the network, the disk or the memory cache), and [blank]
 * goes with it: nothing is drawn under an image once it is in. With [blankUnderAlpha] [blank] stays under a loaded image
 * that has transparency (a card's fill under a logo) and goes only under an opaque one, which must fill the bounds (the
 * default crop). A load redraws the image without composing it again, unless a [fallback] has to go. [blurred] shows
 * [artwork] blurred past recognition ([StillBlur]); [fallbackArtwork] stays sharp. A [logo] on a light theme is
 * recoloured to read on it ([ToneLogo]). Its first successful load marks `image` to the perf probe ([perfImage]); each
 * gives [onAspect] the image's width over height, and [onResult] whether the artwork it tried loaded.
 */
@Composable
fun RemoteImage(
    artwork: Artwork?,
    contentDescription: String?,
    modifier: Modifier = Modifier,
    contentScale: ContentScale = ContentScale.Crop,
    alignment: Alignment = Alignment.Center,
    blank: Color = Color.Unspecified,
    fallbackArtwork: Artwork? = null,
    blurred: Boolean = false,
    logo: LogoRecolour? = null,
    blankUnderAlpha: Boolean = false,
    onAspect: ((Float) -> Unit)? = null,
    onResult: ((Artwork, Boolean) -> Unit)? = null,
    error: (@Composable () -> Unit)? = null,
    fallback: (@Composable () -> Unit)? = null,
) {
    var failed by remember(artwork, fallbackArtwork) { mutableStateOf(false) }
    val shown = if (failed || artwork == null) fallbackArtwork else artwork
    var gone by remember(shown) { mutableStateOf(shown == null) }
    val blur = blurred && shown == artwork
    // An image to draw: the result's, or one loaded before that the request starts on.
    var loaded by remember(shown) { mutableStateOf(false) }
    // The loaded image is opaque: nothing under it shows.
    var opaque by remember(shown) { mutableStateOf(false) }
    val under = if (blank.isSpecified) Modifier.drawBehind { if (!loaded || blankUnderAlpha && !opaque) drawRect(blank) } else Modifier
    Box(modifier.perfImage { loaded }.then(under)) {
        when {
            error != null && gone -> error()
            fallback != null && !loaded -> fallback()
        }
        if (shown != null) {
            // The loader crossfades by default (for its other images); this one shows at once.
            val context = LocalPlatformContext.current
            val display = LocalArtworkDisplay.current
            val sized = SizedArtwork(shown, display, LocalDensity.current.density)
            val ink = logo?.let { logoInk(LocalPlezyColors.current.palette) }
            val request = remember(sized, context, blur, ink, logo) {
                val transformations = when {
                    blur -> listOf(StillBlur)
                    ink != null && logo != null -> listOf(ToneLogo(ink, logo.remapMixed))
                    else -> emptyList()
                }
                ImageRequest.Builder(context)
                    .data(sized)
                    .crossfade(false)
                    .apply { if (transformations.isNotEmpty()) transformations(transformations) }
                    .placeholderMemoryCacheKey(LoadedImageKeys[sized, transformations])
                    .build()
            }
            AsyncImage(
                model = request,
                contentDescription = contentDescription,
                modifier = Modifier.matchParentSize(),
                alignment = alignment,
                contentScale = contentScale,
                onState = {
                    loaded = it is AsyncImagePainter.State.Success || it is AsyncImagePainter.State.Loading && it.painter != null
                    opaque = it is AsyncImagePainter.State.Success && it.result.image.opaque
                    if (it is AsyncImagePainter.State.Success) {
                        onResult?.invoke(shown, true)
                        if (onAspect != null) {
                            val image = it.result.image
                            if (image.width > 0 && image.height > 0) onAspect(image.width.toFloat() / image.height)
                        }
                    }
                    if (it is AsyncImagePainter.State.Error) {
                        onResult?.invoke(shown, false)
                        // The artwork failed and a fallback is left to try; otherwise (the fallback itself, with or
                        // without artwork before it) nothing is left.
                        if (shown == artwork && fallbackArtwork != null && fallbackArtwork != artwork) failed = true else gone = true
                    }
                },
            )
        }
    }
}

/** [artwork] for bounds Coil measures in pixels at [density] pixels per dp, on [display] ([SizedArtworkMapper]). */
internal data class SizedArtwork(val artwork: Artwork, val display: ArtworkDisplay, val density: Float)

/**
 * A [SizedArtwork]'s URL for the size Coil resolved for the image's bounds, turned back into dp ([Artwork.url]); an
 * unbounded side counts as unknown. Coil maps the data before it looks in its caches, so the same bucket hits them.
 */
internal object SizedArtworkMapper : Mapper<SizedArtwork, String> {
    override fun map(data: SizedArtwork, options: Options): String {
        fun dp(dimension: Dimension) = if (dimension is Dimension.Pixels) dimension.px / data.density.toDouble() else Double.POSITIVE_INFINITY
        return data.artwork.url(dp(options.size.width), dp(options.size.height), data.display)
    }
}

/** Coil's software bitmap (a [coil3.transform.Transformation]'s input) as Compose's, to draw it into another. */
internal expect fun Bitmap.toComposeBitmap(): ImageBitmap

/** Compose's bitmap as Coil's (a [coil3.transform.Transformation]'s output); on Android a hardware bitmap. */
internal expect fun ImageBitmap.toCoilBitmap(): Bitmap

/** A Coil bitmap holding straight-alpha `0xAARRGGBB` [pixels], [width] wide. */
internal expect fun argbBitmap(pixels: IntArray, width: Int, height: Int): Bitmap

/** The image has no transparency: every pixel is opaque. */
internal expect val coil3.Image.opaque: Boolean
