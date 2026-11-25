package com.edde746.plezy.ui.theme

import androidx.compose.foundation.LocalIndication
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.ColorScheme
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.LocalContentColor
import androidx.compose.material3.MaterialExpressiveTheme
import androidx.compose.material3.MotionScheme
import androidx.compose.material3.Shapes
import androidx.compose.material3.Typography
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.Immutable
import androidx.compose.runtime.ReadOnlyComposable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.compositeOver
import androidx.compose.ui.graphics.lerp
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.intl.LocaleList
import androidx.compose.ui.text.style.Hyphens
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextDirection
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.edde746.plezy.presentation.theme.Palette
import com.edde746.plezy.strings.InterfaceLocale
import com.edde746.plezy.ui.focus.FocusVisibleRipple

/**
 * The colours the UI draws with, derived from a theme's [palette]: its six colours, and the tones built from them (a
 * raised fill a step from the background, faint and hover tints of the text). [PlezyColors] reads the current set.
 */
@Immutable
class PlezyColorSet(val palette: Palette) {
    val background = Color(palette.bg)
    val surface = Color(palette.surface)
    val outline = Color(palette.outline)
    val text = Color(palette.text)
    val textMuted = Color(palette.textMuted)
    val accent = Color(palette.accent)
    val onAccent = Color(palette.onAccent)

    /**
     * On TV, the rest of a text button: the text a little over whatever lies under it, see-through, so it shows as
     * [surfaceHigh] on the background and a step lighter on a sheet or a grouped row.
     */
    val tonalRest = text.copy(alpha = 0.118f)

    /** Solid chips, secondary buttons, icon buttons, grouped rows: the text a little over the background. */
    val surfaceHigh = tonalRest.compositeOver(background)

    /** Dropdown menus, hovered or pressed raised fills: a step past [surfaceHigh]. */
    val surfaceHighest = text.copy(alpha = 0.177f).compositeOver(background)
    val textFaint = text.copy(alpha = 0.38f)
    val hoverTint = text.copy(alpha = 0.12f)
    val isDark: Boolean = palette.isDark

    /**
     * A focused control's fill: the accent, where a keyboard moves focus; on TV ([tv]) the text colour, as a remote's
     * focus never takes the accent. [onFocusFill] is the content on it.
     */
    fun focusFill(tv: Boolean): Color = if (tv) text else accent

    fun onFocusFill(tv: Boolean): Color = if (tv) background else onAccent

    /**
     * Secondary text in [content]: it at 70 % (the monochrome themes' [textMuted]), at 85 % where [content] is the
     * label colour on the accent (a keyboard-focused control's fill: Paper's teal and Ember's orange leave it less room),
     * so it reads at least 4.5:1 on the background, surfaces and raised fills of every built-in theme and on a focused
     * control's fill.
     */
    fun muted(content: Color): Color = content.copy(alpha = if (content == onAccent) 0.85f else 0.7f)

    /**
     * On TV, the rest of a selected chip: the accent as a tint over the background, in [text], so only the focused
     * control is ever a solid [focusFill].
     */
    val accentRest = accent.copy(alpha = 0.3f).compositeOver(background)

    /**
     * On TV, the rest of a primary button: the accent as a solid tint over the background, stronger than [accentRest]
     * (40 % on a dark theme, 50 % on a light one), in [text] set semibold, so it reads apart from a secondary's
     * [surfaceHigh] (at least 1.5:1 between the fills in every built-in theme) with its label at least 4.5:1 on it,
     * while only the focused control is ever a solid [focusFill].
     */
    val primaryRest = accent.copy(alpha = if (isDark) 0.4f else 0.5f).compositeOver(background)

    /** Errors: Apple's dark red on a dark theme; on a light one a deeper red that keeps 4.5:1 on its background. */
    val error = if (isDark) Color(0xFFFF453A) else Color(0xFFD70015)

    override fun equals(other: Any?): Boolean = other is PlezyColorSet && other.palette == palette

    override fun hashCode(): Int = palette.hashCode()
}

/** The colours of where the composition draws: the app's theme, or the player's white over the video. */
val LocalPlezyColors = staticCompositionLocalOf { PlezyColorSet(Palette.OLED) }

/**
 * The current theme's colours by role ([LocalPlezyColors]), and the few that never follow the theme (what is drawn on
 * artwork and over the video). Outlines only on text inputs, dividers only as hairlines.
 */
object PlezyColors {
    /** Every screen, bar and rail. */
    val Background: Color @Composable @ReadOnlyComposable get() = LocalPlezyColors.current.background

    /** Sheets, panels, cards. */
    val Surface: Color @Composable @ReadOnlyComposable get() = LocalPlezyColors.current.surface

    /** Solid chips, secondary buttons, icon buttons, grouped rows, badges. */
    val SurfaceHigh: Color @Composable @ReadOnlyComposable get() = LocalPlezyColors.current.surfaceHigh

    /** Dropdown menus; hovered or pressed [SurfaceHigh] elements; selected-but-not-primary states. */
    val SurfaceHighest: Color @Composable @ReadOnlyComposable get() = LocalPlezyColors.current.surfaceHighest

    /** Text and icons. */
    val Text: Color @Composable @ReadOnlyComposable get() = LocalPlezyColors.current.text

    /** Secondary text: captions, hints, values. */
    val TextMuted: Color @Composable @ReadOnlyComposable get() = LocalPlezyColors.current.textMuted

    /**
     * Secondary text in whatever colour the content around it takes ([LocalContentColor]: the theme's text, a focused
     * control's content, white over the video), at its muted level ([PlezyColorSet.muted]).
     */
    val MutedContent: Color @Composable @ReadOnlyComposable get() = LocalPlezyColors.current.muted(LocalContentColor.current)

    /** Disabled text and placeholder icons. */
    val TextFaint: Color @Composable @ReadOnlyComposable get() = LocalPlezyColors.current.textFaint

    /**
     * Hovered or pressed, a control that rests transparent or translucent takes this tint over what lies under it,
     * never a solid surface.
     */
    val HoverTint: Color @Composable @ReadOnlyComposable get() = LocalPlezyColors.current.hoverTint

    /**
     * The accent: primary buttons, selected chips, progress, focused controls under a keyboard (on TV focus takes the
     * text colour, [PlezyColorSet.focusFill]); [OnPrimary] on it.
     */
    val Primary: Color @Composable @ReadOnlyComposable get() = LocalPlezyColors.current.accent
    val OnPrimary: Color @Composable @ReadOnlyComposable get() = LocalPlezyColors.current.onAccent

    /** A selected chip's rest on TV ([PlezyColorSet.accentRest]), with [Text] on it. */
    val AccentRest: Color @Composable @ReadOnlyComposable get() = LocalPlezyColors.current.accentRest

    /** A text button's rest on TV ([PlezyColorSet.tonalRest]), with [Text] on it. */
    val TonalRest: Color @Composable @ReadOnlyComposable get() = LocalPlezyColors.current.tonalRest

    /** Dividers only: never an outline on a chip, button or badge. */
    val Hairline: Color @Composable @ReadOnlyComposable get() = LocalPlezyColors.current.outline

    /** Errors: failed states, destructive actions. */
    val Error: Color @Composable @ReadOnlyComposable get() = LocalPlezyColors.current.error

    /** The player's live dot, beside LIVE in [OnVideo]: the one red of a live playback. */
    val Live = Color(0xFFE5251B)

    /** The track under the player's timeline and volume, filled in [OnVideo]. */
    val ProgressTrack = Color.White.copy(alpha = 0.24f)

    /** Progress on artwork (posters, thumbnails): [ArtworkProgressFill] on [ArtworkProgressTrack], over [ArtworkScrim]. */
    val ArtworkProgressFill = Color.White
    val ArtworkProgressTrack = Color.White.copy(alpha = 0.3f)
    val ArtworkScrim = Color.Black.copy(alpha = 0.6f)

    /**
     * The rest of a control over a picture: near-black at 85 %, the picture showing through faintly, with no outline.
     * White content on it stands well past 3:1 over any picture, light or dark.
     */
    val PictureButton = Color(0xFF1F1F1F).copy(alpha = 0.85f)

    /** Behind a dialog. */
    val Scrim = Color.Black.copy(alpha = 0.6f)

    /** Text, icons and primary fills over the video (the player's controls, menus and panels, through [OnVideoTheme]). */
    val OnVideo = Color.White

    /** Secondary text over the video: [OnVideo] at the muted alpha. */
    val OnVideoMuted = OnVideo.copy(alpha = 0.6f)
}

/** The player's colours: the OLED theme with pure white in every role of text, icons and primary fills. */
private val OnVideoPalette = Palette(0xFF000000, 0xFF0F0F0F, 0x1FFFFFFF, 0xFFFFFFFF, 0x99FFFFFF, 0xFFFFFFFF)

/**
 * Material's roles mapped onto [colors] as the dark theme maps its own palette: the background under every surface
 * role, the palette's surface as `surfaceContainer` and the two raised steps above it, the accent as primary, the text
 * in every other role of text and icons; every role set so no Material baseline tone leaks into a component's defaults
 * (menus, switches, text fields). Text fields are the one outlined element; dividers are the palette's hairline.
 */
private fun colorScheme(colors: PlezyColorSet): ColorScheme {
    val base = if (colors.isDark) darkColorScheme() else lightColorScheme()
    return base.copy(
        primary = colors.accent,
        onPrimary = colors.onAccent,
        primaryContainer = colors.surfaceHighest,
        onPrimaryContainer = colors.text,
        inversePrimary = colors.onAccent,
        secondary = colors.text,
        onSecondary = colors.background,
        secondaryContainer = colors.surfaceHighest,
        onSecondaryContainer = colors.text,
        tertiary = colors.text,
        onTertiary = colors.background,
        tertiaryContainer = colors.surfaceHighest,
        onTertiaryContainer = colors.text,
        background = colors.background,
        onBackground = colors.text,
        surface = colors.background,
        onSurface = colors.text,
        surfaceVariant = colors.surfaceHigh,
        onSurfaceVariant = colors.textMuted,
        surfaceTint = Color.Transparent,
        inverseSurface = colors.text,
        inverseOnSurface = colors.background,
        error = colors.error,
        onError = if (colors.isDark) Color.Black else Color.White,
        errorContainer = colors.error.copy(alpha = 0.24f).compositeOver(colors.background),
        onErrorContainer = colors.text,
        outline = colors.text.copy(alpha = 0.38f),
        outlineVariant = colors.outline,
        scrim = Color.Black,
        surfaceBright = colors.surfaceHighest,
        surfaceDim = colors.background,
        surfaceContainerLowest = colors.background,
        surfaceContainerLow = lerp(colors.background, colors.surface, 0.5f),
        surfaceContainer = colors.surface,
        surfaceContainerHigh = colors.surfaceHigh,
        surfaceContainerHighest = colors.surfaceHighest,
    )
}

/** Material's type scale with heavier titles, which read better over video and from across a room. */
private val typography = Typography().let { base ->
    base.copy(
        displaySmall = base.displaySmall.copy(fontWeight = FontWeight.SemiBold),
        headlineLarge = base.headlineLarge.copy(fontWeight = FontWeight.SemiBold),
        headlineMedium = base.headlineMedium.copy(fontWeight = FontWeight.SemiBold),
        headlineSmall = base.headlineSmall.copy(fontWeight = FontWeight.SemiBold),
        titleLarge = base.titleLarge.copy(fontWeight = FontWeight.SemiBold),
        titleMedium = base.titleMedium.copy(fontWeight = FontWeight.SemiBold),
        labelSmall = base.labelSmall.copy(fontSize = 11.sp, letterSpacing = 0.4.sp),
    )
}

/**
 * [this] with every style's text in [locales]: Compose shapes a style's text and picks its fallback fonts by the
 * platform's locales unless the style names its own, and the interface language needn't be the device's (Japanese
 * kanji in their Japanese forms, not Chinese, on a device set to English).
 */
private fun Typography.inLocale(locales: LocaleList): Typography {
    fun TextStyle.localized() = copy(localeList = locales)
    return copy(
        displayLarge = displayLarge.localized(), displayMedium = displayMedium.localized(), displaySmall = displaySmall.localized(),
        headlineLarge = headlineLarge.localized(), headlineMedium = headlineMedium.localized(), headlineSmall = headlineSmall.localized(),
        titleLarge = titleLarge.localized(), titleMedium = titleMedium.localized(), titleSmall = titleSmall.localized(),
        bodyLarge = bodyLarge.localized(), bodyMedium = bodyMedium.localized(), bodySmall = bodySmall.localized(),
        labelLarge = labelLarge.localized(), labelMedium = labelMedium.localized(), labelSmall = labelSmall.localized(),
    )
}

/**
 * [this] for content text: text from outside the app (an addon's titles, descriptions and names, a file's track and
 * chapter titles, a name someone typed), which can be in any script whatever the interface's language. Each paragraph
 * takes its direction from its first letter ([TextDirection.Content]; the interface's where it has none), so an English
 * description reads left to right in Arabic with its full stop at its end, and its lines keep to the interface's start
 * edge, level with the text around it ([TextAlign.Start] and [TextAlign.End] become the layout's left or right). The
 * typography's own direction, the interface's, stays on our strings and on those we build around content text: an
 * Arabic sentence that opens on "Trakt" or on a name still reads right to left.
 */
@Composable
@ReadOnlyComposable
fun TextStyle.contentDirection(): TextStyle {
    val rtl = LocalLayoutDirection.current == LayoutDirection.Rtl
    val align = when (textAlign) {
        TextAlign.Unspecified, TextAlign.Start -> if (rtl) TextAlign.Right else TextAlign.Left
        TextAlign.End -> if (rtl) TextAlign.Left else TextAlign.Right
        else -> textAlign
    }
    return copy(textAlign = align, textDirection = TextDirection.Content)
}

/**
 * [this] for text that wraps in a narrow card (a poster's title and caption, a profile tile's name): a word wider than
 * the card ("Осталось" at Android's largest font scale on a phone's 104 dp card) breaks between its syllables with a
 * hyphen, by the rules of the app's language, rather than at whichever letter fills the line. Android only: Compose
 * Desktop's Skia paragraphs don't read [Hyphens] (1.12.1), so there such a word still breaks at any letter.
 */
fun TextStyle.hyphenated(): TextStyle = copy(hyphens = Hyphens.Auto)
private val shapes = Shapes(
    extraSmall = RoundedCornerShape(6.dp),
    small = RoundedCornerShape(10.dp),
    medium = RoundedCornerShape(12.dp),
    large = RoundedCornerShape(20.dp),
    extraLarge = RoundedCornerShape(28.dp),
)

/** The app's theme in [palette] (the OLED one where none is given: tests, the desktop's splash). */
@Composable
fun PlezyTheme(palette: Palette = Palette.OLED, content: @Composable () -> Unit) {
    val colors = remember(palette) { PlezyColorSet(palette) }
    ColorsTheme(colors, content)
}

/**
 * [PlezyTheme] for what is drawn over the video (the player's overlay, and the sheets it opens): pure white in every
 * role that has the text colour elsewhere, so the text, icons, timeline, primary and focus fills in it, Material's
 * components and every [PlezySurface][com.edde746.plezy.ui.components.PlezySurface] are white without naming a colour.
 */
@Composable
fun OnVideoTheme(content: @Composable () -> Unit) = ColorsTheme(onVideoColors, content)

/** The colours over the video ([OnVideoTheme]). */
internal val onVideoColors = PlezyColorSet(OnVideoPalette)

/**
 * The app's type, shapes and motion in [colors] ([LocalPlezyColors] and Material's scheme from them), with their text
 * colour as the content colour wherever no Surface sets its own, the type in the interface language
 * ([InterfaceLocale]). A sheet or dialog, which the app's root composes, takes the [colors] of where it opens through
 * it. Clickable elements without an indication of their own get Material's ripple, its focus layer drawn only while
 * focus shows ([FocusVisibleRipple]).
 */
@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun ColorsTheme(colors: PlezyColorSet, content: @Composable () -> Unit) {
    val language by InterfaceLocale.tag.collectAsState()
    val localized = remember(language) { typography.inLocale(LocaleList(InterfaceLocale.glyphTag(language))) }
    val scheme = remember(colors) { colorScheme(colors) }
    MaterialExpressiveTheme(colorScheme = scheme, motionScheme = MotionScheme.expressive(), typography = localized, shapes = shapes) {
        CompositionLocalProvider(
            LocalPlezyColors provides colors,
            LocalContentColor provides colors.text,
            LocalIndication provides FocusVisibleRipple,
            content = content,
        )
    }
}
