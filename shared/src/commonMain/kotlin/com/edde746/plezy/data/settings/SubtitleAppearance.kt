package com.edde746.plezy.data.settings

import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.settings.SubAssOverride

/**
 * How this device draws subtitles, resolved against the defaults: the subtitle styling settings
 * ([AppSettings.subtitleFontSize] and the rest). The player gets it as `SubtitleStyle`.
 *
 * @param fontSize `subtitle_font_size`, mpv's `sub-font-size` (scaled pixels of a 720-line picture).
 * @param textColor / [borderColor] / [backgroundColor] the stored colours, `#RRGGBB` as the settings keep them (an
 *   unreadable one draws in the setting's default).
 * @param borderSize `subtitle_border_size`, mpv's `sub-outline-size`.
 * @param backgroundOpacity the opacity of a box behind the text in percent; 0 draws none.
 * @param assOverride mpv's `sub-ass-override` for styled (ASS/SSA) subtitles.
 * @param position `subtitle_position`, mpv's `sub-pos`: 100 is the bottom subtitles' own place, less lifts them by
 *   a share of the picture's height, more (up to 150) lowers them.
 * @param useMargins mpv's text subtitles may sit in the bands outside the picture (`sub-use-margins`).
 */
data class SubtitleAppearance(
    val fontSize: Int,
    val textColor: String,
    val borderSize: Int,
    val borderColor: String,
    val backgroundColor: String,
    val backgroundOpacity: Int,
    val bold: Boolean,
    val italic: Boolean,
    val assOverride: SubAssOverride,
    val position: Int,
    val useMargins: Boolean,
) {
    companion object {
        val DEFAULT: SubtitleAppearance get() = DeviceSettings.DEFAULT.subtitles
    }
}
