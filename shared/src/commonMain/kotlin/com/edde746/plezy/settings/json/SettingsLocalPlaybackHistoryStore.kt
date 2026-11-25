package com.edde746.plezy.settings.json

import com.edde746.plezy.data.settings.DeviceSettingsRepository
import com.edde746.plezy.servers.LocalPlaybackHistoryStore
import com.edde746.plezy.settings.AppSettings
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.longOrNull

/**
 * The local playback history kept in this device's settings (`local_last_played_at`, `{globalKey: epochMs}`). An entry
 * whose value isn't a number is left out.
 */
class SettingsLocalPlaybackHistoryStore(private val settings: DeviceSettingsRepository) : LocalPlaybackHistoryStore {
    override suspend fun read(): Map<String, Long> = decode(settings.value(AppSettings.localLastPlayedAt))

    override suspend fun write(history: Map<String, Long>) {
        settings.set(AppSettings.localLastPlayedAt, JsonObject(history.mapValues { JsonPrimitive(it.value) as JsonElement }))
    }

    internal companion object {
        fun decode(store: JsonObject): Map<String, Long> =
            store.mapNotNull { (k, v) -> (v as? JsonPrimitive)?.takeIf { !it.isString }?.longOrNull?.let { k to it } }.toMap()
    }
}
