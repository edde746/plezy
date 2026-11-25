package com.edde746.plezy.settings

import com.edde746.plezy.data.Db
import com.edde746.plezy.data.Tx
import com.edde746.plezy.data.db.Device_setting
import com.edde746.plezy.data.db.Profile_setting
import com.edde746.plezy.data.settings.readSetting
import com.edde746.plezy.data.settings.settingsJson
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.LibraryFilter
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.model.decodeLibraryFilterSelection
import com.edde746.plezy.model.LibrarySort
import com.edde746.plezy.model.LibrarySortDirection
import com.edde746.plezy.profiles.profileUserScope
import com.edde746.plezy.servers.LibraryPreferences
import com.edde746.plezy.servers.withoutServer
import kotlinx.serialization.SerializationException
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.booleanOrNull

/** The per-library choices [LibraryPrefs.resetPreference] resets, with their keys' prefix. */
enum class LibraryPreference(internal val prefix: String) {
    FILTERS("library_filters_"),
    SORT("library_sort_"),
    GROUPING("library_grouping_"),
    TAB("library_tab_"),
}

/**
 * Each profile's library choices: the library last opened, filters, sort, grouping and tab per library (a section id
 * is the library's global key `{serverId}:{libraryId}`, or a downloads tab: `downloads:tv`, `downloads:movies`,
 * `downloads:music`), the hidden libraries and the libraries' order.
 *
 * Without an explicit profile id, reads and writes are the active profile's ([AppSettings.activeAppProfileId]), or the
 * unscoped settings while no profile is active. Plezy's releases before profiles kept these unscoped: a read for the
 * active profile that finds nothing of its own adopts the unscoped value (moves it into the profile), except the tab;
 * a read for another profile never does.
 */
class LibraryPrefs internal constructor(private val db: Db) : LibraryPreferences {
    suspend fun selectedLibraryKey(): String? = db.write { readAdopting(SELECTED_LIBRARY_KEY, activeScope(), ::stringOf) }

    suspend fun setSelectedLibraryKey(key: String, profileId: String? = null) =
        db.write { put(scopeFor(profileId), SELECTED_LIBRARY_KEY, JsonPrimitive(key)) }

    /**
     * The filter clauses of [sectionId], or of the legacy filters every library shared ([sectionId] null). A library
     * without its own takes the shared ones unless [legacyGlobalFallback] is off (the downloads tabs). A clause with
     * an operator this build doesn't know is dropped; the flat `{field: "v1,v2"}` map of older releases reads as
     * equality clauses.
     */
    suspend fun filters(sectionId: String? = null, legacyGlobalFallback: Boolean = true): List<LibraryFilter> = db.write {
        val scope = activeScope()
        val stored = readAdopting(filtersKey(sectionId), scope, { it })
            ?: if (sectionId != null && legacyGlobalFallback) readAdopting(LIBRARY_FILTERS, scope, { it }) else null
        stored?.let(::filtersOf).orEmpty()
    }

    suspend fun setFilters(filters: List<LibraryFilter>, sectionId: String? = null, profileId: String? = null) = db.write {
        put(scopeFor(profileId), filtersKey(sectionId), JsonArray(filters.map { it.toStorageJson() }))
    }

    /** [sectionId]'s sort; a sort key stored alone by older releases reads as ascending. */
    suspend fun sort(sectionId: String): LibrarySort? = db.write {
        readAdopting(LibraryPreference.SORT.prefix + sectionId, activeScope(), ::sortOf, ::sortJson)
    }

    suspend fun setSort(sectionId: String, key: String, descending: Boolean = false, profileId: String? = null) = db.write {
        put(scopeFor(profileId), LibraryPreference.SORT.prefix + sectionId, sortJson(sortFor(key, descending)))
    }

    /** Removes [sectionId]'s sort, the unscoped one too, so it can't come back by adoption. */
    suspend fun clearSort(sectionId: String) = db.write {
        val key = LibraryPreference.SORT.prefix + sectionId
        activeScope()?.let { delete(it, key) }
        delete(null, key)
    }

    suspend fun grouping(sectionId: String): String? =
        db.write { readAdopting(LibraryPreference.GROUPING.prefix + sectionId, activeScope(), ::stringOf) }

    suspend fun setGrouping(sectionId: String, grouping: String, profileId: String? = null) =
        db.write { put(scopeFor(profileId), LibraryPreference.GROUPING.prefix + sectionId, JsonPrimitive(grouping)) }

    /** The tab last open in [sectionId]; never adopted, and a tab index of older releases reads as none. */
    suspend fun tab(sectionId: String): String? = db.write { read(activeScope(), LibraryPreference.TAB.prefix + sectionId)?.let(::stringOf) }

    suspend fun setTab(sectionId: String, tab: String, profileId: String? = null) =
        db.write { put(scopeFor(profileId), LibraryPreference.TAB.prefix + sectionId, JsonPrimitive(tab)) }

    /** The hidden libraries; a value that isn't a list reads as none. */
    override suspend fun hiddenLibraries(profileId: String?): Set<String> = db.write {
        readAdopting(HIDDEN_LIBRARIES, scopeFor(profileId), { it }, allowAdoption = adopts(profileId))
    }?.let(::stringListOf).orEmpty().toSet()

    override suspend fun setHiddenLibraries(keys: Set<String>, profileId: String?) =
        db.write { put(scopeFor(profileId), HIDDEN_LIBRARIES, stringArray(keys)) }

    /** The libraries' order, or null for the servers' own. */
    override suspend fun libraryOrder(profileId: String?): List<String>? = db.write {
        readAdopting(LIBRARY_ORDER, scopeFor(profileId), ::stringListOf, ::stringArray, allowAdoption = adopts(profileId))
    }

    override suspend fun setLibraryOrder(keys: List<String>, profileId: String?) =
        db.write { put(scopeFor(profileId), LIBRARY_ORDER, stringArray(keys)) }

    /** Removes [profileId]'s [preference] for [sectionId], and the unscoped one when [profileId] is active. */
    suspend fun resetPreference(sectionId: String, preference: LibraryPreference, profileId: String) =
        db.write { resetScoped(preference.prefix + sectionId, profileId) }

    /** Clears the active profile's library choices and the unscoped ones (signing out). */
    suspend fun clearAll() = db.write {
        for (scope in setOf(activeScope(), null)) {
            for (key in listOf(LIBRARY_FILTERS, LIBRARY_ORDER, HIDDEN_LIBRARIES, SELECTED_LIBRARY_KEY)) delete(scope, key)
            for (key in keys(scope)) if (LibraryPreference.entries.any { key.startsWith(it.prefix) }) delete(scope, key)
        }
    }

    /**
     * Clears what [profileId] chose for the libraries of [serverId] (their global keys start `{serverId}:`), the
     * unscoped choices too with [includeLegacy]: a profile that loses a server mustn't see the old choices again if
     * the server comes back.
     */
    suspend fun clearForServer(serverId: String, profileId: String, includeLegacy: Boolean = false) = db.write {
        clearServer(profileUserScope(profileId), serverId)
        if (includeLegacy) clearServer(null, serverId)
    }

    /** [clearForServer] for every profile and the unscoped choices: no profile reaches [serverId] any more. */
    suspend fun clearForServerEverywhere(serverId: String) = db.write {
        clearServer(null, serverId)
        val scopes = q.deviceSettingQueries.selectAllProfileSettings().executeAsList().map { it.profile_scope }.toSet()
        for (scope in scopes) clearServer(scope, serverId)
    }

    override suspend fun removeServerEverywhere(serverId: ServerId) = clearForServerEverywhere(serverId.value)

    // A scope of null is the unscoped settings (device_setting under the bare key).

    private fun Tx.activeScope(): String? = readSetting(AppSettings.activeAppProfileId)?.let(::profileUserScope)

    private fun Tx.scopeFor(profileId: String?): String? = if (profileId == null) activeScope() else profileUserScope(profileId)

    /** Whether a read for [profileId] (null: the active profile) may adopt the unscoped value. */
    private fun Tx.adopts(profileId: String?): Boolean = profileId == null || readSetting(AppSettings.activeAppProfileId) == profileId

    private fun Tx.read(scope: String?, key: String): JsonElement? {
        val json = if (scope == null) {
            q.deviceSettingQueries.selectByKey(key).executeAsOneOrNull()
        } else {
            q.deviceSettingQueries.selectProfileSetting(scope, key).executeAsOneOrNull()
        }
        return json?.let { parse(key, it) }
    }

    private fun Tx.put(scope: String?, key: String, value: JsonElement) {
        val json = settingsJson.encodeToString(JsonElement.serializer(), value)
        if (scope == null) {
            q.deviceSettingQueries.upsert(Device_setting(key, json))
        } else {
            q.deviceSettingQueries.upsertProfileSetting(Profile_setting(scope, key, json))
        }
    }

    private fun Tx.delete(scope: String?, key: String) {
        if (scope == null) q.deviceSettingQueries.delete(key) else q.deviceSettingQueries.deleteProfileSetting(scope, key)
    }

    private fun Tx.keys(scope: String?): List<String> = if (scope == null) {
        q.deviceSettingQueries.selectByPrefix(LIBRARY_PREFIX).executeAsList().map { it.setting_key }
    } else {
        q.deviceSettingQueries.selectProfileSettings(scope).executeAsList().map { it.setting_key }
    }

    /**
     * [key] in [scope] as [decode] reads it; when it has none and [scope] is a profile's, the unscoped value, which
     * then moves into [scope] (as [encode] writes it, or as stored).
     */
    private fun <T : Any> Tx.readAdopting(
        key: String,
        scope: String?,
        decode: (JsonElement) -> T?,
        encode: ((T) -> JsonElement)? = null,
        allowAdoption: Boolean = true,
    ): T? {
        read(scope, key)?.let(decode)?.let { return it }
        if (scope == null || !allowAdoption) return null
        val stored = read(null, key) ?: return null
        val legacy = decode(stored) ?: return null
        put(scope, key, encode?.invoke(legacy) ?: stored)
        delete(null, key)
        return legacy
    }

    /** A reset mustn't let the unscoped value come back by adoption: it goes too while [profileId] is active. */
    private fun Tx.resetScoped(key: String, profileId: String) {
        if (readSetting(AppSettings.activeAppProfileId) == profileId) delete(null, key)
        delete(profileUserScope(profileId), key)
    }

    private fun Tx.clearServer(scope: String?, serverId: String) {
        val serverPrefix = "$serverId:"
        for (key in listOf(LIBRARY_ORDER, HIDDEN_LIBRARIES)) {
            val values = read(scope, key)?.let(::stringListOf) ?: continue
            val kept = values.withoutServer(ServerId(serverId))
            when {
                kept.size == values.size -> Unit
                kept.isEmpty() -> delete(scope, key)
                else -> put(scope, key, stringArray(kept))
            }
        }
        if (read(scope, SELECTED_LIBRARY_KEY)?.let(::stringOf)?.startsWith(serverPrefix) == true) delete(scope, SELECTED_LIBRARY_KEY)
        for (key in keys(scope)) {
            val preference = LibraryPreference.entries.firstOrNull { key.startsWith(it.prefix) } ?: continue
            if (key.removePrefix(preference.prefix).startsWith(serverPrefix)) delete(scope, key)
        }
    }

    internal companion object {
        const val SELECTED_LIBRARY_KEY = "selected_library_key"
        const val LIBRARY_FILTERS = "library_filters"
        const val LIBRARY_ORDER = "library_order"
        const val HIDDEN_LIBRARIES = "hidden_libraries"
        private const val LIBRARY_PREFIX = "library_"
        private const val TAG = "settings"

        fun filtersKey(sectionId: String?) = if (sectionId == null) LIBRARY_FILTERS else LibraryPreference.FILTERS.prefix + sectionId

        /**
         * Whether [value] reads as a setting of the profile library [key], as the reads decode it (a filter selection
         * always reads, an unreadable one as no filters).
         */
        fun readsAs(key: String, value: JsonElement): Boolean = when {
            key == LIBRARY_ORDER || key == HIDDEN_LIBRARIES -> stringListOf(value) != null
            key.startsWith(LibraryPreference.SORT.prefix) -> sortOf(value) != null
            key == LIBRARY_FILTERS || key.startsWith(LibraryPreference.FILTERS.prefix) -> true
            else -> stringOf(value) != null
        }

        private fun parse(key: String, json: String): JsonElement? = try {
            settingsJson.parseToJsonElement(json)
        } catch (e: SerializationException) {
            Log.w(TAG, e) { "the stored value of $key isn't JSON: it reads as unset" }
            null
        }

        /**
         * [value], or the JSON a string holds: Plezy's earlier releases kept these lists and maps as JSON in a string,
         * which an import may have kept as it was.
         */
        private fun unwrapped(value: JsonElement): JsonElement {
            if (value !is JsonPrimitive || !value.isString) return value
            val inner = try {
                settingsJson.parseToJsonElement(value.content)
            } catch (_: SerializationException) {
                return value
            }
            return if (inner is JsonArray || inner is JsonObject) inner else value
        }

        fun stringOf(value: JsonElement): String? = (value as? JsonPrimitive)?.takeIf { it.isString }?.content

        fun stringListOf(value: JsonElement): List<String>? =
            (unwrapped(value) as? JsonArray)?.map { (it as? JsonPrimitive)?.content ?: it.toString() }

        fun stringArray(values: Collection<String>): JsonArray = JsonArray(values.map { JsonPrimitive(it) })

        /** A stored selection: the clause list, a JSON string holding it, or the flat map of older releases. */
        fun filtersOf(value: JsonElement): List<LibraryFilter> =
            decodeLibraryFilterSelection(if (value is JsonPrimitive && value.isString) value.content else value.toString())

        /** A stored sort: `{key, descending}`, or the bare sort key older releases stored (ascending). */
        fun sortOf(value: JsonElement): LibrarySort? = when (val sort = unwrapped(value)) {
            is JsonObject -> stringOf(sort["key"] ?: JsonNull)?.let {
                sortFor(it, (sort["descending"] as? JsonPrimitive)?.booleanOrNull ?: false)
            }
            is JsonPrimitive -> stringOf(sort)?.let { sortFor(it, false) }
            else -> null
        }

        fun sortFor(key: String, descending: Boolean): LibrarySort =
            LibrarySort(key, if (descending) LibrarySortDirection.DESCENDING else LibrarySortDirection.ASCENDING)

        fun sortJson(sort: LibrarySort): JsonElement = JsonObject(
            mapOf(
                "key" to JsonPrimitive(sort.field),
                "descending" to JsonPrimitive(sort.direction == LibrarySortDirection.DESCENDING),
            ),
        )
    }
}
