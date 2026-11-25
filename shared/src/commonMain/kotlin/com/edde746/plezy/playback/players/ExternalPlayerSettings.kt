package com.edde746.plezy.playback.players

import com.edde746.plezy.data.settings.DeviceSettingsRepository
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.settings.ExternalPlayerChoice

/**
 * The external player settings' rules (`selected_external_player`, `custom_external_players`), as the external player
 * settings page changes them.
 */
object ExternalPlayerSettings {
    /** A custom player needs a name and a command, package or URL scheme. */
    fun validCustomPlayerFields(name: String, value: String): Boolean = name.isNotBlank() && value.isNotBlank()

    /**
     * Throws IllegalArgumentException unless every one of [players] is a custom player with its own id (no known
     * player's), a type, a name and a value.
     */
    fun validateCustomPlayers(players: List<ExternalPlayerChoice>) {
        val ids = mutableSetOf<String>()
        for (player in players) {
            require(
                player.isCustom && player.id.isNotBlank() && KnownPlayers.findById(player.id) == null && ids.add(player.id) &&
                    player.customType != null && validCustomPlayerFields(player.name, player.customValue.orEmpty()),
            ) { "Invalid custom player definition" }
        }
    }

    /**
     * Stores [players] as the custom players. A selected custom player follows its new definition, or, when it is gone,
     * the selection goes back to the system default.
     */
    suspend fun replaceCustomPlayers(settings: DeviceSettingsRepository, players: List<ExternalPlayerChoice>) {
        validateCustomPlayers(players)
        val selected = settings.value(AppSettings.selectedExternalPlayer)
        settings.set(AppSettings.customExternalPlayers, players)
        if (selected.isCustom) {
            settings.set(AppSettings.selectedExternalPlayer, players.firstOrNull { it.id == selected.id } ?: AppSettings.selectedExternalPlayer.default)
        }
    }

    suspend fun removeCustomPlayer(settings: DeviceSettingsRepository, id: String) =
        replaceCustomPlayers(settings, settings.value(AppSettings.customExternalPlayers).filter { it.id != id })

    /** Selects [player]; a custom one must be among the custom players (IllegalArgumentException otherwise). */
    suspend fun selectPlayer(settings: DeviceSettingsRepository, player: ExternalPlayerChoice) {
        require(!player.isCustom || settings.value(AppSettings.customExternalPlayers).any { it.id == player.id }) { "Unknown custom player" }
        settings.set(AppSettings.selectedExternalPlayer, player)
    }

    /**
     * The known players the settings list: the [detected] ones, plus the selected one ([selectedId]) when detection
     * missed it but it is offered on [platform], so a false negative can't leave the list with nothing selected.
     */
    fun listed(detected: List<KnownPlayer>, selectedId: String, platform: ExternalPlayerPlatform): List<KnownPlayer> {
        if (detected.any { it.id == selectedId }) return detected
        val selected = KnownPlayers.findById(selectedId)?.takeIf { it.availableOn(platform) } ?: return detected
        return detected + selected
    }
}
