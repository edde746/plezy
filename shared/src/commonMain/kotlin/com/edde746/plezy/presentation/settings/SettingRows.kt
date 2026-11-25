package com.edde746.plezy.presentation.settings

/**
 * One row of a settings page ([SettingsPageUiState]): what both UIs draw, bound to one stored setting or one action.
 * Every row has an [id], unique on its page: what the page's store takes back with an intent ([SettingsPageStore]).
 * A hidden row is left out of its group, never sent disabled-and-empty, so grouped corners stay right.
 */
sealed interface SettingRow {
    val id: String
    val title: String
    val icon: SettingIcon?
}

/**
 * A setting that is on or off. Not [enabled], the switch keeps [checked] and takes no change: it shows dimmed and takes
 * no focus.
 */
data class SettingToggleRow(
    override val id: String,
    override val title: String,
    val subtitle: String?,
    val checked: Boolean,
    val enabled: Boolean = true,
    override val icon: SettingIcon? = null,
) : SettingRow

/**
 * A row that shows its setting's current value: beside the title while the value is short ([trailingValue], at most
 * [SHORT_VALUE_LENGTH] characters), else under it, as the first line of [subtitle], over the row's caption (what the
 * setting does). A value never shows twice.
 */
sealed interface SettingValueRow : SettingRow {
    /** The value beside the title; null when it shows under it, or there is none. */
    val trailingValue: String?

    /** The row's second line: the value when it doesn't sit beside the title, then the caption; null for neither. */
    val subtitle: String?
}

/** The longest value, in characters, that sits beside its row's title; a longer one shows under it. */
const val SHORT_VALUE_LENGTH = 11

/**
 * [value] where a row shows it beside its title: non-empty and at most [SHORT_VALUE_LENGTH] characters; else null. Every
 * row that shows a setting's value places it by this and [valueSubtitleOf], in Settings' own rows and elsewhere.
 */
fun trailingValueOf(value: String?): String? = value?.takeIf { it.isNotEmpty() && it.length <= SHORT_VALUE_LENGTH }

/** A value row's second line: [value] when it doesn't sit beside the title ([trailingValueOf]), then [caption]. */
fun valueSubtitleOf(value: String?, caption: String?): String? =
    listOfNotNull(value?.takeIf { it.isNotEmpty() && trailingValueOf(it) == null }, caption).joinToString("\n").ifEmpty { null }

/**
 * A setting with a fixed list of values: a row whose value opens a menu of them (the selected option focused in
 * keyboard mode). Not [enabled], it shows its value dimmed and doesn't open. Dismissing the menu chooses nothing.
 *
 * @param caption what the setting does, under the title.
 * @param unselectedLabel the value shown while no option is selected (a stored value the list doesn't offer).
 */
data class SettingChoiceRow(
    override val id: String,
    override val title: String,
    val caption: String?,
    val options: List<SettingChoiceOption>,
    val unselectedLabel: String = "",
    val enabled: Boolean = true,
    override val icon: SettingIcon? = null,
) : SettingValueRow {
    /** The value as shown: the selected option's label, else [unselectedLabel]. */
    val valueLabel: String get() = options.firstOrNull { it.selected }?.label ?: unselectedLabel
    override val trailingValue: String? get() = trailingValueOf(valueLabel)
    override val subtitle: String? get() = valueSubtitleOf(valueLabel, caption)
}

/** One value of a [SettingChoiceRow]; [id] is what the store's `choose` takes. [subtitle] is the menu's second line. */
data class SettingChoiceOption(val id: String, val label: String, val selected: Boolean, val subtitle: String? = null)

/**
 * A bounded number typed into a dialog (touch: a number field; keyboard mode: a D-pad spinner). The dialog shows
 * [hint] and checks the typed text with the store ([SettingsPageStore.setNumber] returns the error to show, the dialog
 * staying open); [valueLabel] is the formatted value ("10 seconds", "80%"), never a sentence around it.
 */
data class SettingNumberRow(
    override val id: String,
    override val title: String,
    val valueLabel: String,
    val value: Int,
    val min: Int,
    val max: Int,
    val suffix: String,
    val hint: String,
    override val icon: SettingIcon? = null,
) : SettingValueRow {
    override val trailingValue: String? get() = trailingValueOf(valueLabel)
    override val subtitle: String? get() = valueSubtitleOf(valueLabel, null)
}

/**
 * A continuous value on a slider from [min] to [max] in [steps] divisions (0: continuous), [startLabel] and
 * [endLabel] under its ends, [valueLabel] beside it. Every move writes ([SettingsPageStore.setSlider]).
 */
data class SettingSliderRow(
    override val id: String,
    override val title: String,
    val value: Double,
    val min: Double,
    val max: Double,
    val steps: Int,
    val valueLabel: String?,
    val startLabel: String?,
    val endLabel: String?,
    override val icon: SettingIcon? = null,
) : SettingRow

/**
 * A row that does something when activated ([SettingsPageStore.activate]): opens a page, a dialog or a link.
 * [caption] says what; [valueLabel], where the row opens a setting, is that setting's current value (Theme: "Dark").
 * [trailing] is what sits at its end; [busy] replaces it with a spinner and taps are ignored. [destructive] paints
 * the title in the error colour. [accent] paints the icon in the warning colour (an update available).
 */
data class SettingLinkRow(
    override val id: String,
    override val title: String,
    val caption: String?,
    override val icon: SettingIcon? = null,
    val trailing: LinkTrailing = LinkTrailing.CHEVRON,
    val enabled: Boolean = true,
    val busy: Boolean = false,
    val destructive: Boolean = false,
    val accent: Boolean = false,
    val subtitleLines: Int = 1,
    val valueLabel: String? = null,
) : SettingValueRow {
    override val trailingValue: String? get() = trailingValueOf(valueLabel)
    override val subtitle: String? get() = valueSubtitleOf(valueLabel, caption)
}

enum class LinkTrailing { CHEVRON, EXTERNAL, NONE }

/**
 * Several values checked at once, in a dialog with Save and Cancel ([SettingsPageStore.setChecked] receives the
 * checked ids in option order). A [SettingCheckOption.locked] option shows checked and disabled. [valueLabel] names the
 * checked ones.
 */
data class SettingChecklistRow(
    override val id: String,
    override val title: String,
    val valueLabel: String,
    val caption: String?,
    val options: List<SettingCheckOption>,
    override val icon: SettingIcon? = null,
) : SettingValueRow {
    override val trailingValue: String? get() = trailingValueOf(valueLabel)
    override val subtitle: String? get() = valueSubtitleOf(valueLabel, caption)
}

data class SettingCheckOption(val id: String, val label: String, val checked: Boolean, val locked: Boolean = false, val subtitle: String? = null)

/**
 * A text setting edited in a dialog: a field labelled [fieldLabel] with [hint], prefilled with [value], which the row
 * shows; [SettingsPageStore.submitText] stores it or returns the inline error (the dialog stays open). [resetLabel],
 * when set, adds a leading action that calls [SettingsPageStore.resetText]. [caption] says what the setting does. A
 * [monospace] row (a pattern) shows its value alone as its subtitle, however short, in a monospace face; its caption
 * shows in its dialog only.
 */
data class SettingTextRow(
    override val id: String,
    override val title: String,
    val caption: String?,
    val value: String,
    val fieldLabel: String,
    val hint: String,
    val resetLabel: String?,
    val monospace: Boolean = false,
    override val icon: SettingIcon? = null,
) : SettingValueRow {
    override val trailingValue: String? get() = if (monospace) null else trailingValueOf(value)
    override val subtitle: String? get() = if (monospace) value.ifEmpty { null } else valueSubtitleOf(value, caption)
}

/** A colour setting: [hex] is `#RRGGBB`; the dialog (touch: colour wheel; keyboard: D-pad picker) saves one. */
data class SettingColorRow(
    override val id: String,
    override val title: String,
    val hex: String,
    override val icon: SettingIcon? = null,
) : SettingRow

/**
 * A slot another slice fills ([SettingSlot]): the UI draws the provider's row there, or nothing when none is
 * installed. The Supporter tile, the Services entry.
 */
data class SettingSlotRow(override val id: String, val slot: SettingSlot) : SettingRow {
    override val title: String get() = ""
    override val icon: SettingIcon? get() = null
}

/**
 * The slots: SUPPORTER (hub top: the Supporter or donation tile), APP_ICON (Appearance, below Theme), DOWNLOAD_LOCATION
 * and BACKGROUND_DOWNLOADS (the hub's Downloads group). The provider draws nothing where its row is hidden.
 */
enum class SettingSlot { SUPPORTER, APP_ICON, DOWNLOAD_LOCATION, BACKGROUND_DOWNLOADS }

/**
 * The icon a row leads with, named after the Material icon the UI draws (an SF Symbol on Apple); each UI maps every
 * value.
 */
enum class SettingIcon {
    VOLUNTEER_ACTIVISM, FAVORITE, TUNE, PALETTE, PLAY_CIRCLE, VIDEO_LIBRARY, SYNC, ADD_LINK, GROUP, MANAGE_ACCOUNTS,
    FOLDER, WIFI, DELETE_SWEEP, BATTERY, KEYBOARD, GAMEPAD, PHONE_ANDROID, DNS, BUG_REPORT, ARTICLE, IMAGE, RESTORE,
    SYSTEM_UPDATE, CHECK_CIRCLE, UPLOAD, DOWNLOAD, INFO, LANGUAGE, HOME, PERSON, TV, FULLSCREEN, BRIGHTNESS, GRID,
    VIEW_LIST, SPACING, IMAGE_ASPECT, NUMBERS, VISIBILITY, BLUR, CHECK, NAVIGATION, LABEL, EXPLORE, PLAY_ARROW, LAYERS,
    MEMORY, VISIBILITY_OFF, HD, HDR, AUDIO, SURROUND, VOLUME, SUBTITLES, TIMER, REPLAY, SKIP_NEXT, SHUFFLE, BOOKMARK, SWIPE,
    ZOOM, TOUCH, CODE, OPEN_IN_NEW, SAVE, FONT, COLOR, BORDER, LOCK, CLOUD_OFF, SYNC_PROBLEM, DISPLAY, MOVIE, MUSIC,
    LIVE_TV, SCOPE, SHADER, ASPECT, SYNC_OFFSET, POSITION, BOLD, ITALIC, OPACITY, SPEAKER, CHAPTERS, ORDER, MOUSE,
    EXIT_FULLSCREEN, ADD, REMOVE, SHOW_CHART, LOGOUT, REPLAY_10, REPLAY_30, FAST_FORWARD, PLAYLIST_PLAY, HDR_OFF, HDR_STRONG,
    TONALITY, GRAPHIC_EQ, VOICE, SPEED, BEDTIME, HOURGLASS, SCHEDULE, CROP_FREE, TEXT_SELECT_START, TEXT_SELECT_END,
    CELLULAR,
}

/**
 * A titled (or untitled) run of rows, drawn as one grouped list ([header] null: no header); [footer] says what every
 * row of it does, once, under the group.
 */
data class SettingsGroup(val id: String, val header: String?, val rows: List<SettingRow>, val footer: String? = null)
