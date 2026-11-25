package com.edde746.plezy.presentation.settings

import com.edde746.plezy.data.settings.DeviceSettingsRepository
import com.edde746.plezy.log.Log
import com.edde746.plezy.presentation.theme.AppTheme
import com.edde746.plezy.presentation.theme.Palette
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.settings.CustomThemePalette
import com.edde746.plezy.settings.ThemeMode
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.cancel
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.receiveAsFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlin.math.abs
import kotlin.math.floor
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToLong

/**
 * The Custom theme editor: a draft of the six colours, opened from the saved Custom palette, else from the
 * palette on screen ([systemDark] says which half of System that is). One slot is edited at a time, by hex, by hue,
 * saturation, brightness and opacity (kept apart from the colour so a hue survives grey, each move 8-bit quantised) or
 * by another theme's colour; Start from replaces the whole draft. Contrast below WCAG's bar warns, never blocks Save.
 * Save stores the palette, then makes Custom the theme ([CustomThemeEditorUiState.saved] once both are stored).
 */
class CustomThemeEditorPage internal constructor(
    private val settings: DeviceSettingsRepository,
    perks: StateFlow<ThemePerks>,
    facts: StateFlow<SettingsFacts>,
    systemDark: Boolean,
    parentScope: CoroutineScope,
) {
    private val scope = parentScope.childScope()
    private var initial: Palette = Palette.DARK
    private var draft: Palette = initial
    private var slot = 0
    private var hsv = Hsv.of(initial.bg)
    private var hexText = hexFor(initial.bg)
    private var opened = false
    private var saving = false
    private var saved = false
    private val mutableMessages = Channel<SettingsEvent.Message>(Channel.BUFFERED)

    /** "Could not save changes. Try again." when Save failed (the editor stays). */
    val messages: Flow<SettingsEvent.Message> = mutableMessages.receiveAsFlow()

    private val mutableState = MutableStateFlow(buildState())
    val state: StateFlow<CustomThemeEditorUiState> = mutableState.asStateFlow()

    init {
        scope.launch {
            val custom = settings.value(AppSettings.customThemePalette)?.let(Palette::of)
            val stored = settings.value(AppSettings.themeMode)
            initial = custom ?: AppTheme.resolve(stored, null, perks.value.unlocked, facts.value.tv).paletteFor(systemDark)
            draft = initial
            opened = true
            sync()
        }
    }

    fun selectSlot(index: Int) {
        require(index in SLOTS.indices) { "No colour slot $index" }
        slot = index
        sync()
    }

    /** The hex field as typed: `#` and hex digits, upper case, at most 9 characters; a colour updates the draft. */
    fun editHex(text: String) {
        hexText = text.filter { it == '#' || it.isDigit() || it.lowercaseChar() in 'a'..'f' }.uppercase().take(9)
        Palette.parseHex(hexText)?.let { color ->
            draft = draft.with(slot, color)
            hsv = Hsv.of(color)
        }
        publish()
    }

    /** Submitting the hex field writes the edited colour back in its canonical form. */
    fun submitHex() {
        hexText = hexFor(draft.at(slot))
        publish()
    }

    fun setHsv(hue: Float, saturation: Float, brightness: Float, opacity: Float) {
        hsv = Hsv(hue.coerceIn(0f, 360f), saturation.coerceIn(0f, 1f), brightness.coerceIn(0f, 1f), opacity.coerceIn(0f, 1f))
        val color = hsv.toArgb()
        draft = draft.with(slot, color)
        hexText = hexFor(color)
        publish()
    }

    fun pickSwatch(hex: String) {
        val color = requireNotNull(Palette.parseHex(hex)) { "Not a colour: $hex" }
        draft = draft.with(slot, color)
        sync()
    }

    fun startFrom(optionId: String) {
        val mode = SOURCES.firstOrNull { it.name == optionId } ?: throw IllegalArgumentException("No theme $optionId")
        draft = checkNotNull(ThemePickerPage.paletteOf(mode))
        sync()
    }

    fun reset() {
        draft = initial
        sync()
    }

    /** Saves the palette as Custom and makes Custom the theme. */
    fun save() {
        if (saving || !opened) return
        saving = true
        publish()
        val palette = draft
        scope.launch {
            try {
                settings.set(AppSettings.customThemePalette, palette.stored())
                settings.set(AppSettings.themeMode, ThemeMode.CUSTOM)
                saved = true
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.e("settings", e) { "saving the custom theme failed" }
                mutableMessages.trySend(SettingsEvent.Message(T.settings.saveFailed, error = true))
            }
            saving = false
            publish()
        }
    }

    fun release() {
        mutableMessages.close()
        scope.cancel()
    }

    /** The edited colour read again after something other than the sliders changed it. */
    private fun sync() {
        val color = draft.at(slot)
        hsv = Hsv.of(color)
        hexText = hexFor(color)
        publish()
    }

    private fun publish() {
        mutableState.value = buildState()
    }

    private fun buildState(): CustomThemeEditorUiState {
        return CustomThemeEditorUiState(
            draft = draft,
            slots = SLOTS.mapIndexed { index, (id, label) -> ColorSlotUi(id, label(), Palette.toHex(draft.at(index))) },
            selectedSlot = slot,
            hexText = hexText,
            hexInvalid = Palette.parseHex(hexText) == null,
            hue = hsv.hue,
            saturation = hsv.saturation,
            brightness = hsv.value,
            opacity = hsv.alpha,
            quickSwatches = SOURCES.mapNotNull { ThemePickerPage.paletteOf(it)?.at(slot) }.distinct().map(Palette::toHex),
            startFromOptions = SOURCES.map { SettingChoiceOption(it.name, themeLabel(it), selected = false) },
            warnings = ContrastCheck.entries.mapNotNull { check ->
                val ratio = check.ratio(draft)
                if (ratio >= check.minimum) null else T.themeEditor.lowContrast(check.label(), formatRatio(ratio), formatMinimum(check.minimum))
            },
            dirty = draft != initial,
            saving = saving,
            saved = saved,
        )
    }

    /** A colour as the hex field shows it: `#RRGGBB` when opaque, else `#AARRGGBB`. */
    private fun hexFor(color: Long): String = Palette.toHex(color).let { if (color ushr 24 == 0xFFL) "#" + it.substring(3) else it }

    /** A colour in hue (0..360), saturation, value and alpha (0..1). */
    internal data class Hsv(val hue: Float, val saturation: Float, val value: Float, val alpha: Float) {
        /** The colour, each channel rounded to 8 bits. */
        fun toArgb(): Long {
            val c = value * saturation
            val h = (hue % 360f) / 60f
            val x = c * (1 - abs(h % 2 - 1))
            val (r, g, b) = when (floor(h).toInt()) {
                0 -> Triple(c, x, 0f)
                1 -> Triple(x, c, 0f)
                2 -> Triple(0f, c, x)
                3 -> Triple(0f, x, c)
                4 -> Triple(x, 0f, c)
                else -> Triple(c, 0f, x)
            }
            val m = value - c
            fun channel(v: Float) = ((v + m) * 255).roundToLong().coerceIn(0, 255)
            return ((alpha * 255).roundToLong().coerceIn(0, 255) shl 24) or (channel(r) shl 16) or (channel(g) shl 8) or channel(b)
        }

        companion object {
            fun of(argb: Long): Hsv {
                val a = ((argb ushr 24) and 0xFF) / 255f
                val r = ((argb ushr 16) and 0xFF) / 255f
                val g = ((argb ushr 8) and 0xFF) / 255f
                val b = (argb and 0xFF) / 255f
                val maxC = max(r, max(g, b))
                val minC = min(r, min(g, b))
                val delta = maxC - minC
                val hue = when {
                    delta == 0f -> 0f
                    maxC == r -> 60f * (((g - b) / delta) % 6f)
                    maxC == g -> 60f * ((b - r) / delta + 2f)
                    else -> 60f * ((r - g) / delta + 4f)
                }.let { if (it < 0) it + 360f else it }
                return Hsv(hue, if (maxC == 0f) 0f else delta / maxC, maxC, a)
            }
        }
    }

    /**
     * The pairs whose contrast is checked (WCAG 2): text and secondary text on the background and on surfaces 4.5:1,
     * the accent 3:1, the label on the accent 4.5:1. Translucent colours are composited first: the background over
     * black, surfaces over the background.
     */
    internal enum class ContrastCheck(val minimum: Double) {
        TEXT_ON_BG(4.5),
        TEXT_ON_SURFACE(4.5),
        TEXT_MUTED_ON_BG(4.5),
        TEXT_MUTED_ON_SURFACE(4.5),
        ACCENT_ON_BG(3.0),
        ACCENT_ON_SURFACE(3.0),
        LABEL_ON_ACCENT(4.5),
        ;

        fun ratio(palette: Palette): Double {
            val bg = alphaBlend(palette.bg, 0xFF000000)
            val surface = alphaBlend(palette.surface, bg)
            val (foreground, background) = when (this) {
                TEXT_ON_BG -> palette.text to bg
                TEXT_ON_SURFACE -> palette.text to surface
                TEXT_MUTED_ON_BG -> palette.textMuted to bg
                TEXT_MUTED_ON_SURFACE -> palette.textMuted to surface
                ACCENT_ON_BG -> palette.accent to bg
                ACCENT_ON_SURFACE -> palette.accent to surface
                LABEL_ON_ACCENT -> palette.onAccent to alphaBlend(palette.accent, bg)
            }
            return Palette.contrastRatio(alphaBlend(foreground, background), background)
        }

        fun label(): String = when (this) {
            TEXT_ON_BG -> T.themeEditor.contrast.textOnBg
            TEXT_ON_SURFACE -> T.themeEditor.contrast.textOnSurface
            TEXT_MUTED_ON_BG -> T.themeEditor.contrast.textMutedOnBg
            TEXT_MUTED_ON_SURFACE -> T.themeEditor.contrast.textMutedOnSurface
            ACCENT_ON_BG -> T.themeEditor.contrast.accentOnBg
            ACCENT_ON_SURFACE -> T.themeEditor.contrast.accentOnSurface
            LABEL_ON_ACCENT -> T.themeEditor.contrast.labelOnAccent
        }
    }

    companion object {
        /** The themes Start from and the quick swatches take colours from. */
        private val SOURCES = listOf(
            ThemeMode.LIGHT, ThemeMode.DARK, ThemeMode.OLED, ThemeMode.EMBER, ThemeMode.GLACIER, ThemeMode.FOREST, ThemeMode.PLUM, ThemeMode.PAPER,
        )

        private val SLOTS: List<Pair<String, () -> String>> = listOf(
            "bg" to { T.themeEditor.slots.bg },
            "surface" to { T.themeEditor.slots.surface },
            "outline" to { T.themeEditor.slots.outline },
            "text" to { T.themeEditor.slots.text },
            "textMuted" to { T.themeEditor.slots.textMuted },
            "accent" to { T.themeEditor.slots.accent },
        )

        /** Truncated, not rounded: a pair just under the bar never reads as meeting it (4.46 shows 4.4). */
        internal fun formatRatio(value: Double): String {
            val tenths = floor(value * 10).toLong()
            return "${tenths / 10}.${tenths % 10}"
        }

        internal fun formatMinimum(value: Double): String = if (value == floor(value)) value.toLong().toString() else value.toString()

        /** [foreground] drawn over [background], both `0xAARRGGBB`. */
        internal fun alphaBlend(foreground: Long, background: Long): Long {
            val alpha = (foreground ushr 24) and 0xFF
            if (alpha == 0L) return background
            val inverse = 255 - alpha
            val backAlpha = (background ushr 24) and 0xFF
            fun channel(color: Long, shift: Int) = (color ushr shift) and 0xFF
            if (backAlpha == 255L) {
                fun blend(shift: Int) = (channel(foreground, shift) * alpha + channel(background, shift) * inverse) / 255
                return (0xFFL shl 24) or (blend(16) shl 16) or (blend(8) shl 8) or blend(0)
            }
            val back = backAlpha * inverse / 255
            val outAlpha = back + alpha
            fun blend(shift: Int) = (channel(foreground, shift) * alpha + channel(background, shift) * back) / outAlpha
            return (outAlpha shl 24) or (blend(16) shl 16) or (blend(8) shl 8) or blend(0)
        }

        private fun Palette.at(slot: Int): Long = when (slot) {
            0 -> bg
            1 -> surface
            2 -> outline
            3 -> text
            4 -> textMuted
            else -> accent
        }

        private fun Palette.with(slot: Int, color: Long): Palette = when (slot) {
            0 -> copy(bg = color)
            1 -> copy(surface = color)
            2 -> copy(outline = color)
            3 -> copy(text = color)
            4 -> copy(textMuted = color)
            else -> copy(accent = color)
        }

        private fun Palette.stored() = CustomThemePalette(
            Palette.toHex(bg), Palette.toHex(surface), Palette.toHex(outline), Palette.toHex(text), Palette.toHex(textMuted), Palette.toHex(accent),
        )
    }
}
