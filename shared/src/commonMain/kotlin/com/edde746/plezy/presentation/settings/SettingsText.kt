package com.edde746.plezy.presentation.settings

import com.edde746.plezy.backend.AudioQualityPreset
import com.edde746.plezy.backend.TranscodeQualityPreset
import com.edde746.plezy.settings.AppLocale
import com.edde746.plezy.settings.PlayerSettingScope
import com.edde746.plezy.settings.ThemeMode
import com.edde746.plezy.strings.T

// Labels the settings pages share.

/** A theme's name: System, Light, …, Custom. */
internal fun themeLabel(mode: ThemeMode): String = when (mode) {
    ThemeMode.SYSTEM -> T.settings.systemTheme
    ThemeMode.LIGHT -> T.settings.lightTheme
    ThemeMode.DARK -> T.settings.darkTheme
    ThemeMode.OLED -> T.settings.oledTheme
    ThemeMode.EMBER -> T.settings.emberTheme
    ThemeMode.GLACIER -> T.settings.glacierTheme
    ThemeMode.FOREST -> T.settings.forestTheme
    ThemeMode.PLUM -> T.settings.plumTheme
    ThemeMode.PAPER -> T.settings.paperTheme
    ThemeMode.CUSTOM -> T.themeEditor.custom
}

/** "Original", or "{height}p {Mbps} Mbps" with one decimal under 10 Mbps where it isn't whole. */
internal fun qualityLabel(preset: TranscodeQualityPreset): String {
    if (preset.isOriginal) return T.videoControls.qualityOriginal
    val kbps = checkNotNull(preset.videoBitrateKbps)
    val bitrate = when {
        kbps >= 10_000 || kbps % 1000 == 0 -> ((kbps + 500) / 1000).toString()
        else -> "${(kbps + 50) / 1000}.${(kbps + 50) % 1000 / 100}"
    }
    return T.videoControls.qualityPresetLabel(preset.resolutionHeight?.toString().orEmpty(), bitrate)
}

/** "Original", or "{kbps} kbps". */
internal fun musicQualityLabel(preset: AudioQualityPreset): String =
    if (preset.isOriginal) T.videoControls.qualityOriginal else "${preset.bitrateKbps} kbps"

internal fun scopeLabel(scope: PlayerSettingScope): String = when (scope) {
    PlayerSettingScope.OFF -> T.settings.playerScopeOff
    PlayerSettingScope.GLOBAL -> T.settings.playerScopeGlobal
    PlayerSettingScope.LIBRARY -> T.settings.playerScopeLibrary
    PlayerSettingScope.TITLE -> T.settings.playerScopeTitle
}

/** The interface languages in the order the language dialog lists them (the locales' order, English first), each named in itself. */
internal val LANGUAGE_CHOICES: List<Pair<AppLocale, String>> = listOf(
    AppLocale.EN to "English",
    AppLocale.AZ to "Azərbaycanca",
    AppLocale.BG to "Български",
    AppLocale.DA to "Dansk",
    AppLocale.DE to "Deutsch",
    AppLocale.ES to "Español",
    AppLocale.FR to "Français",
    AppLocale.HU to "Magyar",
    AppLocale.IT to "Italiano",
    AppLocale.JA to "日本語",
    AppLocale.KK to "Қазақша",
    AppLocale.KO to "한국어",
    AppLocale.NB to "Norsk bokmål",
    AppLocale.NL to "Nederlands",
    AppLocale.PL to "Polski",
    AppLocale.PT to "Português (Brasil)",
    AppLocale.PT_PT to "Português (Portugal)",
    AppLocale.RU to "Русский",
    AppLocale.SV to "Svenska",
    AppLocale.TR to "Türkçe",
    AppLocale.UZ to "Oʻzbekcha",
    AppLocale.ZH to "简体中文",
    AppLocale.ZH_HANT to "繁體中文",
)
