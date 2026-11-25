package com.edde746.plezy.settings

import com.edde746.plezy.data.LocalData
import com.edde746.plezy.data.Tx
import com.edde746.plezy.data.db.Device_setting
import com.edde746.plezy.data.settings.readSetting
import com.edde746.plezy.data.settings.settingsJson
import com.edde746.plezy.data.settings.writeSetting
import com.edde746.plezy.log.Log
import kotlinx.serialization.SerializationException
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.booleanOrNull

/**
 * The changes Plezy makes to stored settings as it upgrades them. [applyStartupMigrations] runs as the app starts;
 * [applyLegacyMigrations] once on settings imported from Plezy's earlier releases, whose older shapes it rewrites
 * (both are safe to run again: what is migrated already stays).
 */
object SettingsMigrations {
    /**
     * Rewrites the shapes of Plezy's earlier releases into today's settings:
     * - `library_density` stored as a name: `compact` 2, `comfortable` 4, anything else 3;
     * - `use_season_poster` without `episode_poster_mode`: `seasonPoster` (true) or `seriesPoster` (false);
     * - the toggles [AppSettings.legacyBoolEnums] replaced: their enum value, unless the enum is stored already (it
     *   wins); the toggle is removed either way;
     * - `mpv_config_entries` (`[{key, value, isEnabled}]`) without `mpv_config_text`: `key=value` lines, `#key=value`
     *   for a disabled one;
     * - mpv presets with `entries` and no `text`: the text of their entries.
     */
    internal fun applyLegacyMigrations(tx: Tx) = with(tx) {
        migrateLibraryDensity()
        migrateEpisodePosterMode()
        migrateLegacyBools()
        migrateMpvConfig()
        migrateMpvPresets()
    }

    /**
     * What runs at every start: the former recent rooms and Watch Together relay go; once, the global values of player
     * options whose scope was already per library or title are reset, so they stop applying to libraries and titles
     * never tuned; the relay URL is stored canonical, or removed when it isn't a relay's; settings kept under a Plex
     * Home profile's full id move to its home user's scope.
     */
    suspend fun applyStartupMigrations(data: LocalData) {
        data.db.write { applyStartupMigrations(this) }
    }

    /** [applyStartupMigrations] in a transaction of the caller's. */
    internal fun applyStartupMigrations(tx: Tx) = with(tx) {
        for (key in listOf(LEGACY_RECENT_ROOMS, LEGACY_CUSTOM_RELAY_URL)) remove(key)
        if (raw(AppSettings.playerScopeGlobalsReset.key) == null) {
            for (scope in KEYED_SCOPE_REPAIR) {
                if (readSetting(scope).keysEntries) ScopedPlayerPrefs.globalsOf(scope).forEach { remove(it.key) }
            }
            writeSetting(AppSettings.playerScopeGlobalsReset, true)
        }
        canonicalizeRelay()
        rehomePlexHomeScopes()
    }

    private val KEYED_SCOPE_REPAIR = listOf(
        AppSettings.playbackSpeedScope,
        AppSettings.shaderPresetScope,
        AppSettings.boxFitScope,
        AppSettings.syncOffsetScope,
    )

    private const val LEGACY_RECENT_ROOMS = "watch_together_recent_rooms"
    private const val LEGACY_CUSTOM_RELAY_URL = "custom_relay_url"
    private const val LEGACY_USE_SEASON_POSTER = "use_season_poster"
    private const val LEGACY_MPV_CONFIG_ENTRIES = "mpv_config_entries"
    private const val TAG = "settings"

    private fun Tx.migrateLibraryDensity() {
        val stored = raw(AppSettings.libraryDensity.key) as? JsonPrimitive ?: return
        if (!stored.isString) return
        val density = when (stored.content) {
            "compact" -> 2
            "comfortable" -> 4
            else -> AppSettings.libraryDensity.default
        }
        writeSetting(AppSettings.libraryDensity, density)
    }

    private fun Tx.migrateEpisodePosterMode() {
        if (raw(AppSettings.episodePosterMode.key) != null) return
        val legacy = (raw(LEGACY_USE_SEASON_POSTER) as? JsonPrimitive)?.takeIf { !it.isString }?.booleanOrNull ?: return
        put(AppSettings.episodePosterMode.key, JsonPrimitive(if (legacy) "seasonPoster" else "seriesPoster"))
        remove(LEGACY_USE_SEASON_POSTER)
    }

    private fun Tx.migrateLegacyBools() {
        for (legacy in AppSettings.legacyBoolEnums) {
            val value = raw(legacy.legacyKey) ?: continue
            if (raw(legacy.setting.key) == null) {
                val toggle = (value as? JsonPrimitive)?.takeIf { !it.isString }?.booleanOrNull
                if (toggle != null) put(legacy.setting.key, JsonPrimitive(if (toggle) legacy.whenTrue else legacy.whenFalse))
            }
            remove(legacy.legacyKey)
        }
    }

    private fun Tx.migrateMpvConfig() {
        if (raw(AppSettings.mpvConfigText.key) != null) return
        val entries = raw(LEGACY_MPV_CONFIG_ENTRIES)?.let(::unwrapped) ?: return
        if (entries !is JsonArray) {
            Log.w(TAG) { "the stored mpv configuration entries aren't a list: they aren't migrated" }
            return
        }
        writeSetting(AppSettings.mpvConfigText, legacyEntriesText(entries))
    }

    private fun Tx.migrateMpvPresets() {
        val stored = raw(AppSettings.mpvConfigPresets.key) ?: return
        val presets = unwrapped(stored) as? JsonArray ?: return
        val migrated = JsonArray(
            presets.map { preset ->
                if (preset !is JsonObject || "text" in preset) return@map preset
                val entries = preset["entries"] as? JsonArray ?: return@map preset
                JsonObject(preset + ("text" to JsonPrimitive(legacyEntriesText(entries))))
            },
        )
        if (migrated != stored) put(AppSettings.mpvConfigPresets.key, migrated)
    }

    private fun Tx.canonicalizeRelay() {
        val relay = AppSettings.watchPartyRelayUrl
        val stored = (raw(relay.key) as? JsonPrimitive)?.takeIf { it.isString }?.content ?: return
        val canonical = relay.normalize(stored)
        when {
            canonical == null -> remove(relay.key)
            canonical != stored -> writeSetting(relay, canonical)
        }
    }

    /** The mpv.conf lines of `[{key, value, isEnabled}]`: `key=value`, `#key=value` when disabled; keyless ones skipped. */
    private fun legacyEntriesText(entries: JsonArray): String = entries.mapNotNull { entry ->
        if (entry !is JsonObject) return@mapNotNull null
        val key = (entry["key"] as? JsonPrimitive)?.takeIf { it.isString }?.content.orEmpty()
        val value = (entry["value"] as? JsonPrimitive)?.takeIf { it.isString }?.content.orEmpty()
        val enabled = (entry["isEnabled"] as? JsonPrimitive)?.booleanOrNull ?: true
        if (key.isEmpty()) null else if (enabled) "$key=$value" else "#$key=$value"
    }.joinToString("\n")

    /** [value], or the list or map a string holds as JSON (how Plezy's earlier releases stored them). */
    private fun unwrapped(value: JsonElement): JsonElement {
        if (value !is JsonPrimitive || !value.isString) return value
        val inner = try {
            settingsJson.parseToJsonElement(value.content)
        } catch (_: SerializationException) {
            return value
        }
        return if (inner is JsonArray || inner is JsonObject) inner else value
    }

    private fun Tx.raw(key: String): JsonElement? {
        val json = q.deviceSettingQueries.selectByKey(key).executeAsOneOrNull() ?: return null
        return try {
            settingsJson.parseToJsonElement(json)
        } catch (e: SerializationException) {
            Log.w(TAG, e) { "the stored value of $key isn't JSON" }
            null
        }
    }

    private fun Tx.put(key: String, value: JsonElement) {
        q.deviceSettingQueries.upsert(Device_setting(key, settingsJson.encodeToString(JsonElement.serializer(), value)))
    }

    private fun Tx.remove(key: String) {
        q.deviceSettingQueries.delete(key)
    }
}

/**
 * The options of [AppSettings.mpvConfigText]: one `key=value` per non-blank line that isn't a `#` comment, a later
 * key replacing an earlier one. As mpv's own config parser does, one pair of matching quotes around a value goes: the
 * values are applied as properties, which take strings verbatim. The stored text keeps its quotes.
 */
fun parseMpvConfigText(text: String): Map<String, String> {
    val result = linkedMapOf<String, String>()
    for (line in text.split('\n')) {
        val trimmed = line.trim()
        if (trimmed.isEmpty() || trimmed.startsWith('#')) continue
        val eq = trimmed.indexOf('=')
        if (eq <= 0) continue
        val key = trimmed.substring(0, eq).trim()
        var value = trimmed.substring(eq + 1).trim()
        if (value.length >= 2 && (value[0] == '\'' || value[0] == '"') && value.last() == value[0]) {
            value = value.substring(1, value.length - 1)
        }
        if (key.isNotEmpty()) result[key] = value
    }
    return result
}
