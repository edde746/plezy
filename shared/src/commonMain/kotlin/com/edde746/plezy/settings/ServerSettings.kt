package com.edde746.plezy.settings

import com.edde746.plezy.data.Db
import com.edde746.plezy.data.db.Server_setting
import com.edde746.plezy.data.settings.decodeStored
import com.edde746.plezy.data.settings.settingsJson
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.servers.PreferredEndpointStore
import kotlinx.serialization.KSerializer
import kotlinx.serialization.builtins.nullable
import kotlinx.serialization.builtins.serializer

/** A setting each media server has on this device under [key], [default] while unset. */
class ServerSetting<T>(val key: String, val default: T, internal val serializer: KSerializer<T>) {
    internal fun decode(json: String?): T = json?.let { decodeStored(key, it, serializer) }?.value ?: default

    override fun toString(): String = "ServerSetting($key)"
}

/** The settings Plezy keeps per media server ([ServerSettingsRepository]). */
object ServerSettings {
    /**
     * The percentage of a video that marks it watched, as the Plex server's `LibraryVideoPlayedThreshold` last said:
     * read offline to mark queued progress watched.
     */
    val watchedThreshold = ServerSetting("watched_threshold", 90, Int.serializer())

    /** The base URL the server last answered on; never a relay. */
    val serverEndpoint = ServerSetting<String?>("server_endpoint", null, String.serializer().nullable)

    /** The library section a recording of Plex metadata [type] (movie, show) goes to; 0 while unset. */
    fun dvrTargetSection(type: Int): ServerSetting<Int> = ServerSetting("dvr_target_section_$type", 0, Int.serializer())
}

/**
 * Each media server's own settings ([ServerSetting]), by server id; also the store of the endpoint each server last
 * answered on ([ServerSettings.serverEndpoint]).
 */
class ServerSettingsRepository internal constructor(private val db: Db) : PreferredEndpointStore {
    suspend fun <T> value(serverId: String, setting: ServerSetting<T>): T =
        setting.decode(db.read { deviceSettingQueries.selectServerSetting(serverId, setting.key).executeAsOneOrNull() })

    /** [setting] of every server that has it set, by server id. */
    suspend fun <T> values(setting: ServerSetting<T>): Map<String, T> =
        db.read { deviceSettingQueries.selectAllServerSettings().executeAsList() }
            .filter { it.setting_key == setting.key }
            .associate { it.server_id to setting.decode(it.value_json) }

    /** Stores [value] for [serverId]; a nullable setting set to `null` is removed, as unset. */
    suspend fun <T> set(serverId: String, setting: ServerSetting<T>, value: T) {
        db.write {
            if (value == null) {
                q.deviceSettingQueries.deleteServerSetting(serverId, setting.key)
            } else {
                q.deviceSettingQueries.upsertServerSetting(
                    Server_setting(serverId, setting.key, settingsJson.encodeToString(setting.serializer, value)),
                )
            }
        }
    }

    suspend fun reset(serverId: String, setting: ServerSetting<*>) {
        db.write { q.deviceSettingQueries.deleteServerSetting(serverId, setting.key) }
    }

    /** Removes [setting] for every server (every remembered endpoint, as accounts sign out). */
    suspend fun resetEverywhere(setting: ServerSetting<*>) {
        db.write { q.deviceSettingQueries.deleteServerSettingsByKey(setting.key) }
    }

    override suspend fun read(serverId: ServerId): String? = value(serverId.value, ServerSettings.serverEndpoint)

    override suspend fun save(serverId: ServerId, url: String) = set(serverId.value, ServerSettings.serverEndpoint, url)

    override suspend fun clear(serverId: ServerId) = reset(serverId.value, ServerSettings.serverEndpoint)
}
