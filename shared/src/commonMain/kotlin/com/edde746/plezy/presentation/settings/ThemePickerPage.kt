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
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.receiveAsFlow
import kotlinx.coroutines.launch

/**
 * Appearance → Theme: the free built-ins, then, where the Supporter perks are offered, the presets and
 * Custom. The radio follows what paints ([AppTheme.resolve]); a stored perk that is locked says it is still saved. A
 * pick applies at once. A locked perk asks for the Supporter sheet first and applies only if it unlocked the perks.
 * Custom is one row: it selects the custom theme (once one is saved) and opens its editor, which stores the theme on
 * Save.
 */
class ThemePickerPage internal constructor(
    private val settings: DeviceSettingsRepository,
    private val perks: StateFlow<ThemePerks>,
    private val facts: StateFlow<SettingsFacts>,
    parentScope: CoroutineScope,
) {
    private val scope = parentScope.childScope()
    private val mutableEvents = Channel<ThemePickerEvent>(Channel.BUFFERED)
    val events: Flow<ThemePickerEvent> = mutableEvents.receiveAsFlow()

    private var stored: ThemeMode? = null
    private var custom: CustomThemePalette? = null

    /** The locked perk picked, waiting on the Supporter sheet. */
    private var waiting: ThemeMode? = null

    private val mutableState = MutableStateFlow(buildState())
    val state: StateFlow<ThemePickerUiState> = mutableState.asStateFlow()

    init {
        scope.launch {
            combine(settings.observe(AppSettings.themeMode), settings.observe(AppSettings.customThemePalette), perks, facts) { mode, palette, _, _ ->
                stored = mode
                custom = palette
            }.collect { mutableState.value = buildState() }
        }
    }

    /** Picks [mode]; Custom also opens the editor ([ThemePickerEvent.OpenEditor]). */
    fun choose(mode: ThemeMode) {
        if (mode.isSupporterPerk && !perks.value.unlocked) {
            waiting = mode
            mutableEvents.trySend(ThemePickerEvent.OpenSupporter)
            return
        }
        apply(mode)
    }

    /** The Supporter sheet closed; [unlocked] whether it unlocked the perks (a pending pick then applies). */
    fun supporterClosed(unlocked: Boolean) {
        val mode = waiting
        waiting = null
        if (unlocked && mode != null) apply(mode)
    }

    fun release() {
        scope.cancel()
        mutableEvents.close()
    }

    /** Stores [mode]; Custom, once a palette is saved, and then opens the editor, which stores it on Save. */
    private fun apply(mode: ThemeMode) {
        if (mode == ThemeMode.CUSTOM) {
            mutableEvents.trySend(ThemePickerEvent.OpenEditor)
            if (custom?.let(Palette::of) == null) return
        }
        scope.launch {
            try {
                settings.set(AppSettings.themeMode, mode)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.e("settings", e) { "storing the theme failed" }
            }
        }
    }

    private fun buildState(): ThemePickerUiState {
        val perks = perks.value
        val tv = facts.value.tv
        val customPalette = custom?.let(Palette::of)
        val theme = AppTheme.resolve(stored, customPalette, perks.unlocked, tv)
        val locked = !perks.unlocked
        fun row(mode: ThemeMode) = ThemeRowUi(
            mode = mode,
            label = themeLabel(mode),
            palette = if (mode == ThemeMode.CUSTOM) customPalette else paletteOf(mode),
            splitPalette = if (mode == ThemeMode.SYSTEM) Palette.DARK else null,
            selected = theme.mode == mode,
            locked = locked && mode.isSupporterPerk,
            note = when {
                mode == theme.lockedStored -> T.themeEditor.savedLocked
                mode == ThemeMode.CUSTOM -> T.themeEditor.editCustomDescription
                else -> null
            },
            value = if (mode == ThemeMode.CUSTOM && customPalette == null) T.themeEditor.customEmpty else null,
        )
        val groups = buildList {
            add(ThemeGroup("built_in", if (perks.available) T.themeEditor.builtIn else null, BUILT_IN.map(::row)))
            if (perks.available) {
                add(ThemeGroup("presets", T.themeEditor.presets, PRESETS.map(::row)))
                // Its one row is named Custom: a heading would say it twice.
                add(ThemeGroup("custom", null, listOf(row(ThemeMode.CUSTOM))))
            }
        }
        return ThemePickerUiState(groups, theme.mode)
    }

    companion object {
        private val BUILT_IN = listOf(ThemeMode.SYSTEM, ThemeMode.LIGHT, ThemeMode.DARK, ThemeMode.OLED)
        private val PRESETS = listOf(ThemeMode.EMBER, ThemeMode.GLACIER, ThemeMode.FOREST, ThemeMode.PLUM, ThemeMode.PAPER)

        /** A built-in or preset theme's palette; System's is its light half ([ThemeRowUi.splitPalette] the dark). */
        internal fun paletteOf(mode: ThemeMode): Palette? = when (mode) {
            ThemeMode.SYSTEM, ThemeMode.LIGHT -> Palette.LIGHT
            ThemeMode.DARK -> Palette.DARK
            ThemeMode.OLED -> Palette.OLED
            ThemeMode.EMBER -> Palette.EMBER
            ThemeMode.GLACIER -> Palette.GLACIER
            ThemeMode.FOREST -> Palette.FOREST
            ThemeMode.PLUM -> Palette.PLUM
            ThemeMode.PAPER -> Palette.PAPER
            ThemeMode.CUSTOM -> null
        }
    }
}
