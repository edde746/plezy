package com.edde746.plezy.presentation.settings

import com.edde746.plezy.data.settings.DeviceSettingsRepository
import com.edde746.plezy.log.Log
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.settings.Hotkey
import com.edde746.plezy.settings.HotkeyModifier
import com.edde746.plezy.settings.Hotkeys
import com.edde746.plezy.settings.ShortcutAction
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
import kotlinx.serialization.json.JsonObject

/**
 * Settings → Video Player Controls → Keyboard Shortcuts: one row per action in default order,
 * each with its shortcut ([Hotkeys.format], a Mac's symbols on [mac]) or "No shortcut set". A shortcut another
 * action has is refused; clearing leaves the action without one, which survives restarts; Reset restores every
 * default. Edits are stored one after another, each over the one before.
 */
class KeyboardShortcutsPage internal constructor(
    private val settings: DeviceSettingsRepository,
    private val mac: Boolean,
    parentScope: CoroutineScope,
) {
    private val scope = parentScope.childScope()
    private val mutableMessages = Channel<SettingsEvent.Message>(Channel.BUFFERED)
    val messages: Flow<SettingsEvent.Message> = mutableMessages.receiveAsFlow()

    private var hotkeys: Map<String, Hotkey?> = Hotkeys.effective(JsonObject(emptyMap()))
    private var seekSmall = AppSettings.seekTimeSmall.default
    private var seekLarge = AppSettings.seekTimeLarge.default

    private val mutableState = MutableStateFlow(buildState())
    val state: StateFlow<KeyboardShortcutsUiState> = mutableState.asStateFlow()

    init {
        scope.launch {
            combine(
                settings.observe(AppSettings.keyboardHotkeys),
                settings.observe(AppSettings.seekTimeSmall),
                settings.observe(AppSettings.seekTimeLarge),
            ) { stored, small, large ->
                hotkeys = Hotkeys.effective(stored)
                seekSmall = small
                seekLarge = large
            }.collect { mutableState.value = buildState() }
        }
    }

    /**
     * Stores [actionId]'s new hotkey: [hidUsage] the USB HID usage (`0x00070004` for A), [modifiers] of
     * `alt|control|shift|meta`. Returns once stored ([ShortcutResult.SAVED], "Shortcut updated for …"), at once when
     * another action has it ([ShortcutResult.CONFLICT], "Shortcut already assigned to …", nothing changes), or when
     * storing it failed ([ShortcutResult.FAILED], "Error").
     */
    suspend fun record(actionId: String, hidUsage: Long, modifiers: Set<String>): ShortcutResult {
        val action = ShortcutAction.fromId(actionId) ?: throw IllegalArgumentException("No shortcut action $actionId")
        require(hidUsage != 0L) { "A shortcut needs a key" }
        val hotkey = Hotkey(hidUsage, modifiers.map { HotkeyModifier.fromId(it) ?: throw IllegalArgumentException("No modifier $it") }.toSet())
        Hotkeys.conflict(hotkeys, hotkey, action.id)?.let { other ->
            send(T.settings.shortcutAlreadyAssigned(label(other)), error = true)
            return ShortcutResult.CONFLICT
        }
        return when (store(action.id, hotkey)) {
            null -> {
                send(T.settings.shortcutUpdated(label(action.id)))
                ShortcutResult.SAVED
            }
            Outcome.CONFLICT -> ShortcutResult.CONFLICT
            Outcome.FAILED -> {
                send(T.common.error, error = true)
                ShortcutResult.FAILED
            }
        }
    }

    /** Leaves [actionId] without a shortcut, until a reset: [ShortcutResult.SAVED], or [ShortcutResult.FAILED] ("Error"). */
    suspend fun clear(actionId: String): ShortcutResult {
        require(ShortcutAction.fromId(actionId) != null) { "No shortcut action $actionId" }
        if (store(actionId, null) == Outcome.FAILED) {
            send(T.common.error, error = true)
            return ShortcutResult.FAILED
        }
        return ShortcutResult.SAVED
    }

    /** The recorder dialog for [actionId], from its shortcut now. */
    fun recorder(actionId: String): ShortcutRecorder {
        require(ShortcutAction.fromId(actionId) != null) { "No shortcut action $actionId" }
        return ShortcutRecorder(actionId, hotkeys[actionId], mac, this)
    }

    fun resetAll() {
        scope.launch {
            try {
                settings.reset(AppSettings.keyboardHotkeys)
                send(T.settings.shortcutsReset)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.e("settings", e) { "resetting the keyboard shortcuts failed" }
                send(T.common.error, error = true)
            }
        }
    }

    fun release() {
        scope.cancel()
        mutableMessages.close()
    }

    private enum class Outcome { CONFLICT, FAILED }

    /**
     * Stores [actionId]'s shortcut over the stored ones, read in the same transaction: every action is written, the
     * retired ones dropped. Null when stored.
     */
    private suspend fun store(actionId: String, hotkey: Hotkey?): Outcome? {
        var conflict = false
        return try {
            settings.update(AppSettings.keyboardHotkeys) { stored ->
                val current = Hotkeys.effective(stored)
                if (hotkey != null && Hotkeys.conflict(current, hotkey, actionId) != null) {
                    conflict = true
                    stored
                } else {
                    Hotkeys.encode(current + (actionId to hotkey))
                }
            }
            if (conflict) Outcome.CONFLICT else null
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.e("settings", e) { "storing the shortcut of $actionId failed" }
            Outcome.FAILED
        }
    }

    private fun label(actionId: String): String = ShortcutAction.fromId(actionId)?.label(seekSmall, seekLarge) ?: actionId

    private fun send(text: String, error: Boolean = false) {
        mutableMessages.trySend(SettingsEvent.Message(text, error))
    }

    private fun buildState() = KeyboardShortcutsUiState(
        ShortcutAction.entries.map { action ->
            val hotkey = hotkeys[action.id]
            ShortcutRowUi(action.id, action.label(seekSmall, seekLarge), Hotkeys.format(hotkey, mac), unset = hotkey == null)
        },
    )
}
