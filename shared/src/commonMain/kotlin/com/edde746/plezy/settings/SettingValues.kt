package com.edde746.plezy.settings

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * The Custom theme's six colours ([AppSettings.customThemePalette]), each `#AARRGGBB`. [accent] carries interactive
 * and selected state; body text stays [text].
 */
@Serializable
data class CustomThemePalette(
    val bg: String,
    val surface: String,
    val outline: String,
    val text: String,
    val textMuted: String,
    val accent: String,
) {
    /**
     * This palette with every colour as upper-case `#AARRGGBB` (`#RRGGBB` and a missing `#` are read as opaque), or
     * null when any colour isn't one: a partial or corrupt palette never mixes stored and made-up colours.
     */
    fun canonical(): CustomThemePalette? = CustomThemePalette(
        bg = canonicalArgb(bg) ?: return null,
        surface = canonicalArgb(surface) ?: return null,
        outline = canonicalArgb(outline) ?: return null,
        text = canonicalArgb(text) ?: return null,
        textMuted = canonicalArgb(textMuted) ?: return null,
        accent = canonicalArgb(accent) ?: return null,
    )
}

private val HEX_COLOR = Regex("^#?([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$")

/** [value] as upper-case `#AARRGGBB` (`#RRGGBB` and a missing `#` read as opaque), or null when it isn't a colour. */
private fun canonicalArgb(value: String): String? {
    val digits = HEX_COLOR.matchEntire(value.trim())?.groupValues?.get(1) ?: return null
    return "#" + (if (digits.length == 6) "FF$digits" else digits).uppercase()
}

/** A saved mpv configuration ([AppSettings.mpvConfigPresets]): its [text] in mpv.conf lines, [createdAt] ISO 8601. */
@Serializable
data class MpvPreset(val name: String, val text: String, val createdAt: String)

/**
 * The external player plays open in ([AppSettings.selectedExternalPlayer]), or one the user added
 * ([AppSettings.customExternalPlayers]): a built-in one by [id], or a custom one ([isCustom]) launched through its
 * [customValue] as [customType].
 */
@Serializable
data class ExternalPlayerChoice(
    val id: String,
    val name: String,
    val isCustom: Boolean = false,
    val customValue: String? = null,
    val customType: CustomPlayerType? = null,
) {
    companion object {
        /** The platform's own handler for the video's URL. */
        val SYSTEM_DEFAULT = ExternalPlayerChoice(id = "system_default", name = "System Default")
    }
}

/** How a custom external player is launched. */
@Serializable
enum class CustomPlayerType {
    @SerialName("urlScheme") URL_SCHEME,
    @SerialName("command") COMMAND,
}
