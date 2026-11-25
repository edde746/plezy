package com.edde746.plezy.presentation.settings

import com.edde746.plezy.data.settings.DeviceSettingsRepository
import com.edde746.plezy.log.Log
import com.edde746.plezy.playback.players.ExternalPlayerPlatform
import com.edde746.plezy.playback.players.ExternalPlayerSettings
import com.edde746.plezy.playback.players.KnownPlayer
import com.edde746.plezy.playback.players.KnownPlayers
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.settings.CustomPlayerType
import com.edde746.plezy.settings.ExternalPlayerChoice
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlin.time.Clock

/**
 * Video Playback → External Player: "Use External Player", then the known players [detect]
 * finds on [platform] (plus the selected one when detection missed it, [ExternalPlayerSettings.listed]) and the custom
 * ones, the one plays open in selected (`selected_external_player`). Deleting the selected custom player falls back to
 * System Default ([ExternalPlayerSettings.removeCustomPlayer]).
 */
class ExternalPlayerPage internal constructor(
    private val settings: DeviceSettingsRepository,
    private val platform: ExternalPlayerPlatform,
    private val detect: suspend () -> List<KnownPlayer>,
    private val facts: SettingsFacts,
    private val clock: Clock,
    parentScope: CoroutineScope,
) {
    private val scope = parentScope.childScope()
    private val detected = MutableStateFlow<List<KnownPlayer>>(emptyList())
    private var useExternal = false
    private var selected = AppSettings.selectedExternalPlayer.default
    private var custom = emptyList<ExternalPlayerChoice>()

    /** Changes to the custom players read the stored list then replace it: one at a time. */
    private val writes = Mutex()

    private val mutableState = MutableStateFlow(buildState())
    val state: StateFlow<ExternalPlayerUiState> = mutableState.asStateFlow()

    init {
        scope.launch {
            combine(
                settings.observe(AppSettings.useExternalPlayer),
                settings.observe(AppSettings.selectedExternalPlayer),
                settings.observe(AppSettings.customExternalPlayers),
                detected,
            ) { use, choice, customs, _ ->
                useExternal = use
                selected = choice
                custom = customs
            }.collect { mutableState.value = buildState() }
        }
        scope.launch {
            try {
                detected.value = detect()
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.e("settings", e) { "detecting external players failed" }
            }
        }
    }

    fun setEnabled(enabled: Boolean) {
        store { settings.set(AppSettings.useExternalPlayer, enabled) }
    }

    fun select(id: String) {
        val choice = KnownPlayers.findById(id)?.choice ?: custom.firstOrNull { it.id == id } ?: throw IllegalArgumentException("No player $id")
        store { ExternalPlayerSettings.selectPlayer(settings, choice) }
    }

    fun delete(id: String) {
        require(custom.any { it.id == id }) { "$id isn't a custom player" }
        store { writes.withLock { ExternalPlayerSettings.removeCustomPlayer(settings, id) } }
    }

    /** Adds a custom player; false (nothing stored) unless both fields are non-blank. */
    fun addCustom(name: String, type: String, value: String): Boolean {
        val kind = customTypes().firstOrNull { typeId(it) == type } ?: throw IllegalArgumentException("No custom player type $type here")
        val label = name.trim()
        val target = value.trim()
        if (!ExternalPlayerSettings.validCustomPlayerFields(label, target)) return false
        store {
            writes.withLock {
                val existing = settings.value(AppSettings.customExternalPlayers)
                val player = ExternalPlayerChoice(customId(existing), label, isCustom = true, customValue = target, customType = kind)
                ExternalPlayerSettings.replaceCustomPlayers(settings, existing + player)
            }
        }
        return true
    }

    fun release() {
        scope.cancel()
    }

    /** A new custom player's id: the time it was added, unique among [existing] (two added within a millisecond). */
    private fun customId(existing: List<ExternalPlayerChoice>): String {
        val base = "custom_${clock.now().toEpochMilliseconds()}"
        val taken = existing.map { it.id }.toSet()
        return generateSequence(0) { it + 1 }.map { if (it == 0) base else "${base}_$it" }.first { it !in taken }
    }

    private fun store(block: suspend () -> Unit) {
        scope.launch {
            try {
                block()
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.e("settings", e) { "storing the external player failed" }
            }
        }
    }

    /** Android's custom players are packages, Apple's mobile ones URL schemes, the desktop's either. */
    private fun customTypes(): List<CustomPlayerType> = when (platform) {
        ExternalPlayerPlatform.ANDROID -> listOf(CustomPlayerType.COMMAND)
        ExternalPlayerPlatform.IOS, ExternalPlayerPlatform.TVOS -> listOf(CustomPlayerType.URL_SCHEME)
        else -> listOf(CustomPlayerType.COMMAND, CustomPlayerType.URL_SCHEME)
    }

    private fun buildState(): ExternalPlayerUiState {
        val selectedId = selected.id
        val known = ExternalPlayerSettings.listed(detected.value, selectedId, platform).map { player ->
            val systemDefault = player.id == KnownPlayers.SYSTEM_DEFAULT_ID
            ExternalPlayerRowUi(
                id = player.id,
                name = if (systemDefault) T.externalPlayer.systemDefault else player.name,
                iconAsset = player.icon,
                selected = !selected.isCustom && player.id == selectedId,
                systemDefault = systemDefault,
            )
        }
        val types = customTypes()
        return ExternalPlayerUiState(
            enabled = AppSettings.useExternalPlayerOn(useExternal, facts.supportsExternalPlayers),
            players = known,
            custom = custom.map { ExternalPlayerRowUi(it.id, it.name, null, selected = selected.isCustom && it.id == selectedId, systemDefault = false) },
            customTypes = types.mapIndexed { i, type -> SettingChoiceOption(typeId(type), typeLabel(type), selected = i == 0) },
            customValueHint = types.associate { typeId(it) to hintOf(it) },
        )
    }

    private fun typeLabel(type: CustomPlayerType) = when {
        type == CustomPlayerType.URL_SCHEME -> T.externalPlayer.playerUrlScheme
        platform == ExternalPlayerPlatform.ANDROID -> T.externalPlayer.playerPackage
        else -> T.externalPlayer.playerCommand
    }

    private fun hintOf(type: CustomPlayerType) = when {
        type == CustomPlayerType.URL_SCHEME -> "myplayer://play?url="
        platform == ExternalPlayerPlatform.ANDROID -> "com.example.player"
        facts.macos -> "mpv"
        else -> "/usr/bin/player"
    }

    companion object {
        /** The custom player dialog's type ids ([CustomPlayerType]'s stored names). */
        internal const val COMMAND = "command"
        internal const val URL_SCHEME = "urlScheme"

        private fun typeId(type: CustomPlayerType) = if (type == CustomPlayerType.URL_SCHEME) URL_SCHEME else COMMAND
    }
}
