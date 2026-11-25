package com.edde746.plezy.settings.export

import com.edde746.plezy.data.Db
import com.edde746.plezy.data.Tx
import com.edde746.plezy.data.db.Device_setting
import com.edde746.plezy.data.db.Profile_setting
import com.edde746.plezy.data.settings.DeviceSetting
import com.edde746.plezy.data.settings.settingsJson
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.settings.LibraryPrefs
import com.edde746.plezy.settings.isBuiltInShaderPreset
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.SerializationException
import kotlinx.serialization.descriptors.PrimitiveKind
import kotlinx.serialization.descriptors.SerialKind
import kotlinx.serialization.descriptors.StructureKind
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.doubleOrNull
import kotlinx.serialization.json.longOrNull
import kotlinx.serialization.json.put
import kotlin.time.Instant

/** What an import did: the settings it wrote and the entries it passed over. */
data class ImportResult(val keysImported: Int, val keysSkipped: Int)

/** A settings file that can't be imported, or an import that can't run. */
open class SettingsBackupException(message: String) : Exception(message)

/** The file isn't a Plezy settings export: not UTF-8, not JSON, not an object, or of a newer format. */
class InvalidExportFileException(message: String) : SettingsBackupException(message)

/** An import needs the active profile, whose scope the library settings are written to. */
class NoActiveProfileException : SettingsBackupException("No profile is active")

/**
 * The settings file: export, import and Reset All Settings over this device's settings and the active profile's
 * library settings.
 *
 * The file is the one Plezy's earlier releases read and wrote, so a backup moves either way between them: UTF-8 JSON
 * indented two spaces, `{"formatVersion":1,"appVersion","exportedAt","platform","prefs":{key:{"type","value"}}}` with
 * `type` one of `bool`, `int`, `double`, `string`, `stringList`. Enums travel as their name, JSON settings as their
 * JSON text in a `string`. Only exportable settings (`AppSetting.policy`) and the active profile's library
 * settings, without the profile's scope, are in it; credentials, paths, history and other profiles' settings never are.
 */
class SettingsBackup internal constructor(private val db: Db) {
    /**
     * The settings file of this device's exportable settings and the library settings of [profileScope] (none without
     * a profile). An earlier release's on/off choice not yet migrated goes out as the setting that replaced it; storage
     * is left as it is.
     */
    suspend fun export(profileScope: String?, appVersion: String, platform: String, now: Instant): ByteArray {
        val (device, profile) = db.read {
            val device = deviceSettingQueries.selectAll().executeAsList().associate { it.setting_key to it.value_json }
            val profile = profileScope?.takeIf { it.isNotEmpty() }
                ?.let { scope -> deviceSettingQueries.selectProfileSettings(scope).executeAsList() }
                .orEmpty()
            device to profile
        }
        val prefs = LinkedHashMap<String, JsonObject>()
        for ((key, setting) in portableSettings) {
            val json = device[key] ?: continue
            val stored = parseOrNull(json) ?: continue
            val value = if (key == AppSettings.globalShaderPreset.key) shaderExportValue(stored) else stored
            exportEntry(setting, value)?.let { prefs[key] = it }
        }
        for (row in profile.sortedBy { it.setting_key }) {
            if (!isProfileLibraryKey(row.setting_key)) continue
            val text = when (val stored = parseOrNull(row.value_json)) {
                is JsonPrimitive -> stored.takeIf { it.isString }?.content
                is JsonArray, is JsonObject -> stored.toString()
                null -> null
            } ?: continue
            prefs[row.setting_key] = entry(TYPE_STRING, JsonPrimitive(text))
        }
        for (legacy in AppSettings.legacyBoolEnums) {
            if (legacy.setting.key in device) continue
            val choice = device[legacy.legacyKey]?.let(::parseOrNull)?.boolean() ?: continue
            prefs[legacy.setting.key] = entry(TYPE_STRING, JsonPrimitive(if (choice) legacy.whenTrue else legacy.whenFalse))
        }
        val file = buildJsonObject {
            put("formatVersion", FORMAT_VERSION)
            put("appVersion", appVersion)
            put("exportedAt", now.toString())
            put("platform", platform)
            put("prefs", JsonObject(prefs))
        }
        return fileJson.encodeToString(JsonElement.serializer(), file).encodeToByteArray()
    }

    /**
     * Imports the settings file [bytes]: every entry this build accepts replaces its setting, library settings in
     * [profileScope]'s; the rest are counted as skipped and settings the file leaves out stay as they are. An entry is
     * accepted when its key is exportable, its type is the setting's, and its value is one the settings screens could
     * have saved. Every write lands in one transaction: a failing one leaves every setting as it was.
     *
     * @throws NoActiveProfileException without [profileScope], before the file is read.
     * @throws InvalidExportFileException when [bytes] aren't a settings file this build reads.
     */
    suspend fun import(bytes: ByteArray, profileScope: String?): ImportResult =
        import(bytes, profileScope) {}

    /** [import], with [beforeWrite] called with each key just before it is written or removed. */
    internal suspend fun import(bytes: ByteArray, profileScope: String?, beforeWrite: (String) -> Unit): ImportResult {
        if (profileScope.isNullOrEmpty()) throw NoActiveProfileException()
        val text = try {
            bytes.decodeToString(throwOnInvalidSequence = true)
        } catch (e: CharacterCodingException) {
            throw InvalidExportFileException("The file is not UTF-8: ${e.message}")
        }
        val parsed = try {
            Json.parseToJsonElement(text)
        } catch (e: SerializationException) {
            throw InvalidExportFileException("The file is not JSON: ${e.message}")
        }
        val file = parsed as? JsonObject ?: throw InvalidExportFileException("The file is not a JSON object")
        return apply(file, profileScope, beforeWrite)
    }

    private suspend fun apply(file: JsonObject, scope: String, beforeWrite: (String) -> Unit): ImportResult {
        val version = (file["formatVersion"] as? JsonPrimitive)?.int()
            ?: throw InvalidExportFileException("Missing formatVersion")
        if (version > FORMAT_VERSION) throw InvalidExportFileException("Unsupported formatVersion: $version")
        val prefs = file["prefs"] as? JsonObject ?: throw InvalidExportFileException("Missing prefs object")

        val pending = mutableListOf<PendingWrite>()
        var skipped = 0
        for ((fileKey, rawEntry) in prefs) {
            if (rawEntry !is JsonObject) {
                skipped++
                continue
            }
            var key = fileKey
            var type = (rawEntry["type"] as? JsonPrimitive)?.takeIf { it.isString }?.content
            var value = rawEntry["value"] ?: JsonNull
            val legacy = legacyByKey[key]
            if (version == 1L && legacy != null) {
                if (legacy.setting.key in prefs) {
                    skipped++
                    continue
                }
                val choice = value.boolean()
                if (type == TYPE_BOOL && choice != null) {
                    key = legacy.setting.key
                    type = TYPE_STRING
                    value = JsonPrimitive(if (choice) legacy.whenTrue else legacy.whenFalse)
                }
            }

            val setting = portableSettings[key]
            val profileKey = setting == null && isProfileLibraryKey(key)
            if (setting == null && !profileKey) {
                skipped++
                continue
            }
            // The first format-1 files wrote these two JSON lists as native string lists.
            if (version == 1L && key in JSON_LIST_PROFILE_KEYS && type == TYPE_STRING_LIST && value.isStringList()) {
                type = TYPE_STRING
                value = JsonPrimitive(value.toString())
            }
            val expected = setting?.entryType() ?: TYPE_STRING
            if (type != expected || !value.isOfType(expected)) {
                skipped++
                continue
            }
            if (setting == null) {
                val stored = profileValue(key, (value as JsonPrimitive).content)
                if (LibraryPrefs.readsAs(key, stored)) pending += PendingWrite(key, stored, profile = true) else skipped++
                continue
            }
            if (key == AppSettings.globalShaderPreset.key && !isBuiltInShaderPreset((value as JsonPrimitive).content)) {
                skipped++
                continue
            }
            val stored = acceptedValue(setting, expected, value)
            if (stored == null) {
                skipped++
                continue
            }
            pending += PendingWrite(key, stored, profile = false, obsoleteKey = legacyBySettingKey[key]?.legacyKey)
        }

        db.write {
            for (write in pending) {
                beforeWrite(write.key)
                if (write.profile) {
                    q.deviceSettingQueries.upsertProfileSetting(Profile_setting(scope, write.key, write.value.toString()))
                } else {
                    q.deviceSettingQueries.upsert(Device_setting(write.key, write.value.toString()))
                }
                write.obsoleteKey?.let { obsolete ->
                    beforeWrite(obsolete)
                    q.deviceSettingQueries.delete(obsolete)
                }
            }
        }
        return ImportResult(keysImported = pending.size, keysSkipped = skipped)
    }

    /**
     * Reset All Settings: removes every setting Reset clears (`AppSetting.policy`) and the keys of earlier releases'
     * settings, keeping the exported-only ones. An earlier release's on/off choice for a kept setting is first written
     * as that setting, as reading it would have. Returns the keys whose stored value went away, whose effects the
     * caller replays; moving the downloads location back is the caller's too.
     */
    suspend fun resetAll(): List<String> = db.write {
        val stored = q.deviceSettingQueries.selectAll().executeAsList().associate { it.setting_key to it.value_json }
        val resettable = AppSettings.all.filter { it.policy.reset }.map { it.key }
        val removed = mutableListOf<String>()
        for (legacy in AppSettings.legacyBoolEnums) {
            val kept = legacy.setting.key !in resettable
            if (kept && legacy.setting.key !in stored) {
                stored[legacy.legacyKey]?.let(::parseOrNull)?.boolean()?.let { choice ->
                    val name = if (choice) legacy.whenTrue else legacy.whenFalse
                    q.deviceSettingQueries.upsert(Device_setting(legacy.setting.key, JsonPrimitive(name).toString()))
                }
            }
            removeIfStored(legacy.legacyKey, stored, removed)
        }
        for (key in resettable + RESET_LEGACY_KEYS) removeIfStored(key, stored, removed)
        removed
    }

    private fun Tx.removeIfStored(key: String, stored: Map<String, String>, removed: MutableList<String>) {
        if (key !in stored || key in removed) return
        q.deviceSettingQueries.delete(key)
        removed += key
    }

    private class PendingWrite(val key: String, val value: JsonElement, val profile: Boolean, val obsoleteKey: String? = null)

    companion object {
        /** The file format this build writes and the newest it reads. */
        const val FORMAT_VERSION = 1

        /** The export's suggested file name for the local date: `plezy-settings-YYYYMMDD.json`. */
        fun defaultFileName(year: Int, month: Int, day: Int): String =
            "plezy-settings-${year.toString().padStart(4, '0')}${month.pad2()}${day.pad2()}.json"

        private fun Int.pad2() = toString().padStart(2, '0')

        private const val TYPE_BOOL = "bool"
        private const val TYPE_INT = "int"
        private const val TYPE_DOUBLE = "double"
        private const val TYPE_STRING = "string"
        private const val TYPE_STRING_LIST = "stringList"

        /** Keys Reset removes besides the settings: what earlier releases' settings left behind. */
        private val RESET_LEGACY_KEYS =
            listOf("use_season_poster", "mpv_config_entries", "buffer_size", "demuxer_mode", "buffer_size_migrated_to_auto")

        /** This device's own storage, never carried to another. */
        private val DEVICE_LOCAL_KEYS = setOf("custom_download_path", "custom_download_path_type")
        private const val TVOS_RECOVERY_PREFIX = "tvos_db_recovery_"

        private val PROFILE_LIBRARY_KEYS = setOf("hidden_libraries", "library_filters", "library_order")
        private val PROFILE_LIBRARY_PATTERN = Regex("^library_(?:filters|sort|grouping|tab)_.+$")
        private val JSON_LIST_PROFILE_KEYS = setOf("hidden_libraries", "library_order")

        @OptIn(ExperimentalSerializationApi::class)
        private val fileJson = Json {
            prettyPrint = true
            prettyPrintIndent = "  "
        }

        private val portableSettings: Map<String, DeviceSetting<*>> by lazy {
            AppSettings.all
                .filter { it.policy.export }
                .filterNot { it.key.startsWith(TVOS_RECOVERY_PREFIX) || it.key in DEVICE_LOCAL_KEYS }
                .associateBy { it.key }
        }
        private val legacyByKey by lazy { AppSettings.legacyBoolEnums.associateBy { it.legacyKey } }
        private val legacyBySettingKey by lazy { AppSettings.legacyBoolEnums.associateBy { it.setting.key } }

        private fun isProfileLibraryKey(key: String) = key in PROFILE_LIBRARY_KEYS || PROFILE_LIBRARY_PATTERN.matches(key)

        /** The profile library settings stored as JSON rather than as text. */
        private fun isJsonProfileKey(key: String) =
            key in PROFILE_LIBRARY_KEYS || key.startsWith("library_filters_") || key.startsWith("library_sort_")

        /** A profile library setting's stored value: its JSON where it is a JSON setting and [text] is JSON, else [text]. */
        private fun profileValue(key: String, text: String): JsonElement {
            if (isJsonProfileKey(key)) {
                val parsed = try {
                    Json.parseToJsonElement(text)
                } catch (_: SerializationException) {
                    null
                }
                if (parsed is JsonArray || parsed is JsonObject) return parsed
            }
            return JsonPrimitive(text)
        }

        private fun shaderExportValue(stored: JsonElement): JsonElement {
            val id = (stored as? JsonPrimitive)?.takeIf { it.isString }?.content
            return JsonPrimitive(if (id != null && isBuiltInShaderPreset(id)) id else "none")
        }

        /** The file's type for [this] setting: its stored JSON's kind, JSON settings and enums as `string`. */
        @OptIn(ExperimentalSerializationApi::class)
        private fun DeviceSetting<*>.entryType(): String {
            val descriptor = serializer.descriptor
            return when (descriptor.kind) {
                PrimitiveKind.BOOLEAN -> TYPE_BOOL
                PrimitiveKind.BYTE, PrimitiveKind.SHORT, PrimitiveKind.INT, PrimitiveKind.LONG -> TYPE_INT
                PrimitiveKind.FLOAT, PrimitiveKind.DOUBLE -> TYPE_DOUBLE
                StructureKind.LIST ->
                    if (descriptor.getElementDescriptor(0).kind == PrimitiveKind.STRING) TYPE_STRING_LIST else TYPE_STRING
                else -> TYPE_STRING
            }
        }

        /** Whether [this] setting is stored as JSON structure that the file carries as JSON text. */
        @OptIn(ExperimentalSerializationApi::class)
        private fun DeviceSetting<*>.isJsonSetting(): Boolean =
            entryType() == TYPE_STRING && serializer.descriptor.kind != PrimitiveKind.STRING &&
                serializer.descriptor.kind != SerialKind.ENUM

        /** The file entry for [setting]'s stored [value], or null when the stored value isn't of the setting's type. */
        private fun exportEntry(setting: DeviceSetting<*>, value: JsonElement): JsonObject? {
            val type = setting.entryType()
            val out: JsonElement = when (type) {
                TYPE_DOUBLE -> value.number()?.let { JsonPrimitive(it) }
                TYPE_STRING -> when {
                    setting.isJsonSetting() -> value.takeIf { it !is JsonNull }?.let { JsonPrimitive(it.toString()) }
                    else -> value.takeIf { it.isOfType(TYPE_STRING) }
                }
                else -> value.takeIf { it.isOfType(type) }
            } ?: return null
            return entry(type, out)
        }

        /**
         * The value to store for [setting] from a file's [value] of [type], or null when the setting can't hold it:
         * an enum name this build doesn't know, JSON its setting doesn't read, a number out of range, and the other
         * values the settings screens refuse ([AppSettings.validate]).
         */
        private fun acceptedValue(setting: DeviceSetting<*>, type: String, value: JsonElement): JsonElement? {
            val stored = when {
                type == TYPE_DOUBLE -> JsonPrimitive(value.number() ?: return null)
                type == TYPE_STRING && setting.isJsonSetting() -> try {
                    Json.parseToJsonElement((value as JsonPrimitive).content)
                } catch (_: SerializationException) {
                    return null
                }
                else -> value
            }
            return try {
                val decoded = settingsJson.decodeFromJsonElement(setting.serializer, stored)
                AppSettings.validate(setting, decoded)
                stored
            } catch (_: IllegalArgumentException) {
                // SerializationException is one too: a value the setting doesn't decode.
                null
            }
        }

        private fun entry(type: String, value: JsonElement) = buildJsonObject {
            put("type", type)
            put("value", value)
        }

        private fun parseOrNull(json: String): JsonElement? = try {
            Json.parseToJsonElement(json)
        } catch (_: SerializationException) {
            null
        }

        private fun JsonElement.boolean(): Boolean? = (this as? JsonPrimitive)?.takeIf { !it.isString }?.booleanOrNull

        private fun JsonPrimitive.int(): Long? = takeIf { !it.isString }?.longOrNull

        private fun JsonElement.number(): Double? =
            (this as? JsonPrimitive)?.takeIf { !it.isString && it !is JsonNull && it.booleanOrNull == null }?.doubleOrNull

        private fun JsonElement.isStringList() = this is JsonArray && all { it is JsonPrimitive && it.isString }

        private fun JsonElement.isOfType(type: String): Boolean = when (type) {
            TYPE_BOOL -> boolean() != null
            TYPE_INT -> (this as? JsonPrimitive)?.int() != null
            TYPE_DOUBLE -> number() != null
            TYPE_STRING -> this is JsonPrimitive && isString
            TYPE_STRING_LIST -> isStringList()
            else -> false
        }
    }
}
