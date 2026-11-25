package com.edde746.plezy.presentation.settings

import com.edde746.plezy.data.settings.DeviceSetting
import com.edde746.plezy.data.settings.DeviceSettingsRepository
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.settings.SubAssOverride
import com.edde746.plezy.settings.SubtitleRenderResolution
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.StateFlow

/**
 * Settings → Video Playback → Subtitle Styling: Text (ASS override, render resolution on Apple and Android,
 * size, colour, position, margins, bold, italic), Border and Background.
 */
internal class SubtitleStylingPage(
    settings: DeviceSettingsRepository,
    private val facts: StateFlow<SettingsFacts>,
    parentScope: CoroutineScope,
) : RowPageStore(settings, parentScope, { T.screens.subtitleStyling }) {
    init {
        follow(facts) {}
        start(
            listOf(
                AppSettings.subAssOverride, AppSettings.subtitleRenderResolution, AppSettings.subtitleFontSize,
                AppSettings.subtitleTextColor, AppSettings.subtitlePosition, AppSettings.subtitleUseMargins,
                AppSettings.subtitleBold, AppSettings.subtitleItalic, AppSettings.subtitleBorderSize, AppSettings.subtitleBorderColor,
                AppSettings.subtitleBackgroundOpacity, AppSettings.subtitleBackgroundColor,
            ),
        )
    }

    override fun build(rows: Rows): List<SettingsGroup> {
        val facts = facts.value
        val resolutions = when {
            facts.ios || facts.macos -> listOf(SubtitleRenderResolution.SCREEN, SubtitleRenderResolution.VIDEO)
            facts.android -> SubtitleRenderResolution.entries - SubtitleRenderResolution.VIDEO
            else -> emptyList()
        }
        val text = listOfNotNull(
            rows.choice(ASS_OVERRIDE, AppSettings.subAssOverride, T.subtitlingStyling.assOverride, choices(SubAssOverride.entries, ::overrideLabel), SettingIcon.SUBTITLES),
            if (resolutions.isEmpty()) {
                null
            } else {
                rows.choice(
                    RENDER_RESOLUTION, AppSettings.subtitleRenderResolution, T.subtitlingStyling.renderResolution,
                    choices(resolutions, ::resolutionLabel), SettingIcon.ASPECT,
                )
            },
            rows.number(FONT_SIZE, AppSettings.subtitleFontSize, T.subtitlingStyling.fontSize, { it.toString() }, T.subtitlingStyling.fontSize, "", SettingIcon.FONT),
            rows.color(TEXT_COLOR, AppSettings.subtitleTextColor, T.subtitlingStyling.textColor, SettingIcon.COLOR),
            rows.number(POSITION, AppSettings.subtitlePosition, T.subtitlingStyling.position, ::positionLabel, T.subtitlingStyling.position, "%", SettingIcon.POSITION),
            rows.toggle(USE_MARGINS, AppSettings.subtitleUseMargins, T.subtitlingStyling.useMargins, T.subtitlingStyling.useMarginsDescription, SettingIcon.POSITION),
            rows.toggle(BOLD, AppSettings.subtitleBold, T.subtitlingStyling.bold, null, SettingIcon.BOLD),
            rows.toggle(ITALIC, AppSettings.subtitleItalic, T.subtitlingStyling.italic, null, SettingIcon.ITALIC),
        )
        val border = listOf(
            rows.number(BORDER_SIZE, AppSettings.subtitleBorderSize, T.subtitlingStyling.borderSize, { it.toString() }, T.subtitlingStyling.borderSize, "", SettingIcon.BORDER),
            rows.color(BORDER_COLOR, AppSettings.subtitleBorderColor, T.subtitlingStyling.borderColor, SettingIcon.COLOR),
        )
        val background = listOf(
            rows.number(
                BACKGROUND_OPACITY, AppSettings.subtitleBackgroundOpacity, T.subtitlingStyling.backgroundOpacity, { "$it%" },
                T.subtitlingStyling.backgroundOpacity, "%", SettingIcon.OPACITY,
            ),
            rows.color(BACKGROUND_COLOR, AppSettings.subtitleBackgroundColor, T.subtitlingStyling.backgroundColor, SettingIcon.COLOR),
        )
        return listOf(
            SettingsGroup("text", T.subtitlingStyling.text, text),
            SettingsGroup("border", T.subtitlingStyling.border, border),
            SettingsGroup("background", T.subtitlingStyling.background, background),
        )
    }

    companion object {
        const val ASS_OVERRIDE = "sub_ass_override"
        const val RENDER_RESOLUTION = "subtitle_render_resolution"
        const val FONT_SIZE = "subtitle_font_size"
        const val TEXT_COLOR = "subtitle_text_color"
        const val POSITION = "subtitle_position"
        const val USE_MARGINS = "subtitle_use_margins"
        const val BOLD = "subtitle_bold"
        const val ITALIC = "subtitle_italic"
        const val BORDER_SIZE = "subtitle_border_size"
        const val BORDER_COLOR = "subtitle_border_color"
        const val BACKGROUND_OPACITY = "subtitle_background_opacity"
        const val BACKGROUND_COLOR = "subtitle_background_color"

        private fun overrideLabel(value: SubAssOverride) = when (value) {
            SubAssOverride.NO -> T.common.no
            SubAssOverride.YES -> T.common.yes
            SubAssOverride.SCALE -> T.subtitlingStyling.overrideScale
            SubAssOverride.FORCE -> T.subtitlingStyling.overrideForce
            SubAssOverride.STRIP -> T.subtitlingStyling.overrideStrip
        }

        private fun resolutionLabel(value: SubtitleRenderResolution) = when (value) {
            SubtitleRenderResolution.SCREEN -> T.subtitlingStyling.renderResolutionScreen
            SubtitleRenderResolution.VIDEO -> T.subtitlingStyling.renderResolutionVideo
            SubtitleRenderResolution.THREE_QUARTER -> "¾"
            SubtitleRenderResolution.HALF -> "½"
            SubtitleRenderResolution.THIRD -> "⅓"
            SubtitleRenderResolution.QUARTER -> "¼"
        }

        /** 0 "Top", 100 "Bottom", else "{n}%". */
        private fun positionLabel(value: Int) = when (value) {
            0 -> T.subtitlingStyling.positionTop
            100 -> T.subtitlingStyling.positionBottom
            else -> "$value%"
        }
    }
}
