package com.edde746.plezy.settings

import com.edde746.plezy.data.settings.DeviceSetting
import com.edde746.plezy.data.settings.DeviceSettingsRepository
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.model.buildGlobalKey
import com.edde746.plezy.playback.VideoFit
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.doubleOrNull
import kotlinx.serialization.json.intOrNull
import kotlinx.serialization.json.longOrNull

/**
 * One option of the player whose persistence the user chooses ([scope]): its values per library or title live in
 * [AppSettings.scopedPlayerPrefValues] under [id]; [global] is the value everywhere, and every scope's fallback.
 */
class ScopedPlayerPref<T> internal constructor(
    val id: String,
    val scope: DeviceSetting<PlayerSettingScope>,
    val global: DeviceSetting<T>,
    private val decode: (JsonElement) -> T?,
    private val encode: (T) -> JsonElement,
) {
    /** A stored entry's value, or null when it doesn't read as one (the global value then applies). */
    internal fun decodeEntry(value: JsonElement): T? = decode(value)

    internal fun encodeEntry(value: T): JsonElement = encode(value)
}

/**
 * Where changes made in the player's options persist ([PlayerSettingScope]). [PlayerSettingScope.OFF] keeps nothing,
 * [PlayerSettingScope.GLOBAL] the option's global setting, and a keyed scope an entry per library
 * (`library:{libraryGlobalKey}`) or title (`title:{serverId}:{showId or id}`, server-scoped since Plex's rating keys
 * repeat across servers). An item without that identity (live TV, a Jellyfin download without its library) writes the
 * global setting, so a change never vanishes. A playback applies the configured scope's entry, else the global
 * setting: entries of another scope stay, inert, until that scope is chosen again. The entries are this device's,
 * shared by every profile, at most [MAX_ENTRIES_PER_PROPERTY] per option (the oldest written go first).
 */
object ScopedPlayerPrefs {
    const val MIN_SYNC_OFFSET_MS: Int = -60_000
    const val MAX_SYNC_OFFSET_MS: Int = 60_000
    const val MAX_ENTRIES_PER_PROPERTY: Int = 300

    val playbackSpeed = ScopedPlayerPref(
        "playback_speed",
        AppSettings.playbackSpeedScope,
        AppSettings.defaultPlaybackSpeed,
        { number(it)?.coerceIn(AppSettings.PLAYBACK_SPEED_RANGE) },
        { JsonPrimitive(it) },
    )

    /** A shader preset's id, as [AppSettings.globalShaderPreset]. */
    val shaderPreset = ScopedPlayerPref(
        "shader_preset",
        AppSettings.shaderPresetScope,
        AppSettings.globalShaderPreset,
        { (it as? JsonPrimitive)?.takeIf { value -> value.isString }?.content },
        { JsonPrimitive(it) },
    )

    /** Stored as the box-fit index (0 contain, 1 cover, 2 fill). */
    val boxFitMode = ScopedPlayerPref(
        "box_fit_mode",
        AppSettings.boxFitScope,
        AppSettings.defaultBoxFitMode,
        { integer(it)?.let { index -> VideoFit.entries[index.coerceIn(0, VideoFit.entries.lastIndex)] } },
        { JsonPrimitive(it.ordinal) },
    )

    val videoZoom = ScopedPlayerPref(
        "video_zoom",
        AppSettings.videoZoomScope,
        AppSettings.defaultVideoZoom,
        { number(it)?.coerceIn(AppSettings.VIDEO_ZOOM_RANGE) },
        { JsonPrimitive(it) },
    )

    val audioSyncOffset = ScopedPlayerPref(
        "audio_sync_offset",
        AppSettings.syncOffsetScope,
        AppSettings.audioSyncOffset,
        ::integer,
        { JsonPrimitive(it) },
    )

    val subtitleSyncOffset = ScopedPlayerPref(
        "subtitle_sync_offset",
        AppSettings.syncOffsetScope,
        AppSettings.subtitleSyncOffset,
        ::integer,
        { JsonPrimitive(it) },
    )

    /** The value [pref] has for [item]: its entry in the configured scope, else the global setting. */
    suspend fun <T> resolve(settings: DeviceSettingsRepository, pref: ScopedPlayerPref<T>, item: MediaItem?): T {
        val key = scopeKeyFor(settings.value(pref.scope), item)
        if (key != null) {
            val entry = entriesOf(settings.value(AppSettings.scopedPlayerPrefValues), pref.id)[key] as? JsonObject
            entry?.get("v")?.let(pref::decodeEntry)?.let { return it }
        }
        return settings.value(pref.global)
    }

    /** Keeps [value] for [item] in [pref]'s configured scope; [at] is the write's time, epoch ms. */
    suspend fun <T> write(settings: DeviceSettingsRepository, pref: ScopedPlayerPref<T>, item: MediaItem?, value: T, at: Long) {
        val scope = settings.value(pref.scope)
        if (scope == PlayerSettingScope.OFF) return
        val key = scopeKeyFor(scope, item)
        if (key == null) {
            settings.set(pref.global, value)
            return
        }
        val entry = JsonObject(mapOf("v" to pref.encodeEntry(value), "t" to JsonPrimitive(at)))
        settings.update(AppSettings.scopedPlayerPrefValues) { store ->
            JsonObject(store + (pref.id to JsonObject(pruned(entriesOf(store, pref.id) + (key to entry)))))
        }
    }

    /**
     * Writes [scope] for [pref], and resets the scope's global settings when it goes from [PlayerSettingScope.OFF] or
     * [PlayerSettingScope.GLOBAL] to a keyed scope: kept, the global value would apply to every library or title not
     * tuned yet. [AppSettings.syncOffsetScope] resets both offsets.
     */
    suspend fun setScope(settings: DeviceSettingsRepository, scopeSetting: DeviceSetting<PlayerSettingScope>, scope: PlayerSettingScope) {
        val entersKeyedScope = scope.keysEntries && !settings.value(scopeSetting).keysEntries
        settings.set(scopeSetting, scope)
        if (entersKeyedScope) resetGlobals(settings, scopeSetting)
    }

    /** Resets the global settings [scopeSetting] falls back to. */
    internal suspend fun resetGlobals(settings: DeviceSettingsRepository, scopeSetting: DeviceSetting<PlayerSettingScope>) {
        for (global in globalsOf(scopeSetting)) settings.reset(global)
    }

    /** The global settings of each scope setting. */
    internal fun globalsOf(scopeSetting: DeviceSetting<PlayerSettingScope>): List<DeviceSetting<*>> = when (scopeSetting) {
        AppSettings.playbackSpeedScope -> listOf(AppSettings.defaultPlaybackSpeed)
        AppSettings.shaderPresetScope -> listOf(AppSettings.globalShaderPreset)
        AppSettings.boxFitScope -> listOf(AppSettings.defaultBoxFitMode)
        AppSettings.videoZoomScope -> listOf(AppSettings.defaultVideoZoom)
        AppSettings.syncOffsetScope -> listOf(AppSettings.audioSyncOffset, AppSettings.subtitleSyncOffset)
        else -> throw IllegalArgumentException("$scopeSetting is not a player setting scope")
    }

    /** [item]'s entry key in [scope], or null when the scope isn't keyed or the item lacks the identity. */
    fun scopeKeyFor(scope: PlayerSettingScope, item: MediaItem?): String? {
        if (item == null) return null
        return when (scope) {
            PlayerSettingScope.OFF, PlayerSettingScope.GLOBAL -> null
            PlayerSettingScope.LIBRARY -> item.libraryGlobalKey?.let { "library:$it" }
            PlayerSettingScope.TITLE -> ServerId.tryParse(item.serverId)?.let { "title:${buildGlobalKey(it, item.grandparentId ?: item.id)}" }
        }
    }

    private fun entriesOf(store: JsonObject, propertyId: String): Map<String, JsonElement> =
        store[propertyId] as? JsonObject ?: emptyMap()

    private fun pruned(entries: Map<String, JsonElement>): Map<String, JsonElement> {
        if (entries.size <= MAX_ENTRIES_PER_PROPERTY) return entries
        return entries.entries.sortedByDescending { timestampOf(it.value) }.take(MAX_ENTRIES_PER_PROPERTY).associate { it.key to it.value }
    }

    private fun timestampOf(entry: JsonElement): Long =
        ((entry as? JsonObject)?.get("t") as? JsonPrimitive)?.takeIf { !it.isString }?.longOrNull ?: 0

    private fun number(value: JsonElement): Double? = (value as? JsonPrimitive)?.takeIf { !it.isString }?.doubleOrNull

    private fun integer(value: JsonElement): Int? = (value as? JsonPrimitive)?.takeIf { !it.isString }?.intOrNull
}
