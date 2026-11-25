package com.edde746.plezy.settings

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

// The choices of Plezy's settings. Each value is stored as the name Plezy's earlier releases gave it: never rename one.

/**
 * The app's theme ([AppSettings.themeMode]). [SYSTEM] follows the platform between [LIGHT] and [DARK]; every other
 * value is one fixed palette, [CUSTOM] the one in [AppSettings.customThemePalette].
 */
@Serializable
enum class ThemeMode {
    @SerialName("system") SYSTEM,
    @SerialName("light") LIGHT,
    @SerialName("dark") DARK,
    @SerialName("oled") OLED,
    @SerialName("ember") EMBER,
    @SerialName("glacier") GLACIER,
    @SerialName("forest") FOREST,
    @SerialName("plum") PLUM,
    @SerialName("paper") PAPER,
    @SerialName("custom") CUSTOM,
    ;

    /** The presets and Custom are Supporter perks; the built-in four are free in every build. */
    val isSupporterPerk: Boolean get() = when (this) {
        SYSTEM, LIGHT, DARK, OLED -> false
        else -> true
    }
}

/** The section the app opens in ([AppSettings.startupSection]). */
@Serializable
enum class StartupSection {
    @SerialName("discover") DISCOVER,
    @SerialName("libraries") LIBRARIES,
    @SerialName("liveTv") LIVE_TV,
    @SerialName("explore") EXPLORE,
    @SerialName("search") SEARCH,
}

/** The gap between cards in media grids ([AppSettings.gridSpacing]). */
@Serializable
enum class GridSpacing {
    @SerialName("tight") TIGHT,
    @SerialName("normal") NORMAL,
    @SerialName("spacious") SPACIOUS,
}

/** How libraries and lists show their items ([AppSettings.viewMode]). */
@Serializable
enum class ViewMode {
    @SerialName("grid") GRID,
    @SerialName("list") LIST,
}

/** What selecting a Continue Watching item does ([AppSettings.continueWatchingAction]). */
@Serializable
enum class ContinueWatchingAction {
    @SerialName("play") PLAY,
    @SerialName("details") DETAILS,
}

/** What selecting an episode does ([AppSettings.episodeAction]). */
@Serializable
enum class EpisodeAction {
    @SerialName("play") PLAY,
    @SerialName("details") DETAILS,
}

/** mpv's `sub-ass-override` ([AppSettings.subAssOverride]). */
@Serializable
enum class SubAssOverride {
    @SerialName("no") NO,
    @SerialName("yes") YES,
    @SerialName("scale") SCALE,
    @SerialName("force") FORCE,
    @SerialName("strip") STRIP,
}

/**
 * The resolution styled and image subtitles are drawn at ([AppSettings.subtitleRenderResolution]): Apple platforms
 * choose between [SCREEN] and [VIDEO]; Android between [SCREEN] and the fractions of it.
 */
@Serializable
enum class SubtitleRenderResolution(val androidRenderScale: Double) {
    @SerialName("screen") SCREEN(1.0),
    @SerialName("video") VIDEO(1.0),
    @SerialName("threeQuarter") THREE_QUARTER(0.75),
    @SerialName("half") HALF(0.5),
    @SerialName("third") THIRD(1.0 / 3),
    @SerialName("quarter") QUARTER(0.25),
}

/** Who reduces HDR to what the display shows on Linux's native video plane ([AppSettings.hdrToneMapping]). */
@Serializable
enum class HdrToneMapping {
    @SerialName("compositor") COMPOSITOR,
    @SerialName("player") PLAYER,
}

/** Who converts HDR for a display without HDR output on Android's mpv ([AppSettings.hdrSdrConversion]); [wire] is the engine's name. */
@Serializable
enum class HdrSdrConversion(val wire: String) {
    @SerialName("auto") AUTO("auto"),
    @SerialName("device") DEVICE("device"),
    @SerialName("player") PLAYER("player"),
}

/** What mpv does with interlaced video ([AppSettings.deinterlaceMode]); [mpvValue] is mpv's `deinterlace`. */
@Serializable
enum class DeinterlaceMode(val mpvValue: String) {
    @SerialName("off") OFF("no"),
    @SerialName("video") VIDEO("auto"),

    /** Interlaced 29.97 and 30 fps video rebuilt into its film frames: field-rate video stutters, so it is opt-in. */
    @SerialName("film") FILM("ivtc"),
}

/** Android's visual effects budget ([AppSettings.visualEffects]). */
@Serializable
enum class VisualEffects {
    @SerialName("auto") AUTO,
    @SerialName("full") FULL,
    @SerialName("reduced") REDUCED,
}

/** Which libraries a tracker scrobbles ([AppSettings.trackerFilterMode]): all but the listed ones, or only them. */
@Serializable
enum class TrackerLibraryFilterMode {
    @SerialName("blacklist") BLACKLIST,
    @SerialName("whitelist") WHITELIST,
}

/**
 * Where a change made in the player's options persists and is applied from again ([ScopedPlayerPrefs]): nowhere
 * ([OFF], the session only), one value everywhere ([GLOBAL]), one per library or one per show or movie.
 */
@Serializable
enum class PlayerSettingScope {
    @SerialName("off") OFF,
    @SerialName("global") GLOBAL,
    @SerialName("library") LIBRARY,
    @SerialName("title") TITLE,
    ;

    /** Whether values are kept per library or title; the global value is then only the fallback. */
    val keysEntries: Boolean get() = this == LIBRARY || this == TITLE
}

/**
 * The interface languages a user can choose ([AppSettings.appLocale]), stored by name; [tag] is the language's BCP 47
 * tag.
 */
enum class AppLocale(val tag: String) {
    EN("en"),
    AZ("az"),
    BG("bg"),
    DA("da"),
    DE("de"),
    ES("es"),
    FR("fr"),
    HU("hu"),
    IT("it"),
    JA("ja"),
    KK("kk"),
    KO("ko"),
    NB("nb"),
    NL("nl"),
    PL("pl"),
    PT("pt"),
    PT_PT("pt-PT"),
    RU("ru"),
    SV("sv"),
    TR("tr"),
    UZ("uz"),
    ZH("zh"),
    ZH_HANT("zh-Hant"),
    ;

    /** The stored name: `zh`, `zhHant`. */
    val storedName: String get() = camelName(this)

    companion object {
        /**
         * The language a stored [AppSettings.appLocale] names: null for none (the device's languages decide), English
         * for a name this build doesn't know.
         */
        fun fromStored(stored: String?): AppLocale? {
            if (stored.isNullOrEmpty()) return null
            return entries.firstOrNull { it.storedName == stored } ?: EN
        }
    }
}
