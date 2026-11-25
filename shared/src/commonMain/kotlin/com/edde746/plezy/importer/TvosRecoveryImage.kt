package com.edde746.plezy.importer

import com.edde746.plezy.crypto.cryptoProvider
import dev.whyoleg.cryptography.algorithms.SHA256
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive

// On Apple TV the earlier releases' database lived in purgeable storage, so they kept a bounded copy of the rows that
// can't be fetched again in the user defaults: accounts, profiles and their bindings (the identity group) and
// unsent watch actions (the pending group). Each group is a JSON string `{"version":1,"rows":{…}}` of the rows as
// camelCase maps; a manifest `{"version":1,"state":…,"identityDigest":…,"pendingDigest":…}` names their SHA-256
// digests and is written last, so only a manifest in state `committed` whose digests match describes a complete copy.

const val TVOS_RECOVERY_MANIFEST_KEY = "tvos_db_recovery_manifest_v1"
const val TVOS_RECOVERY_IDENTITY_KEY = "tvos_db_recovery_identity_v1"
const val TVOS_RECOVERY_PENDING_KEY = "tvos_db_recovery_pending_v1"
const val TVOS_RECOVERY_REQUIRED_KEY = "tvos_db_recovery_required_v1"
const val TVOS_RECOVERY_KEY_PREFIX = "tvos_db_recovery_"

/** The most the recovery keys may take together, as UTF-8 JSON; a larger image is not trusted. */
const val TVOS_RECOVERY_BYTE_CEILING = 400_000

/** The rows of a valid committed tvOS recovery image. */
data class TvosRecoveryRows(
    val connections: List<EarlierReleaseConnectionRow>,
    val profiles: List<EarlierReleaseProfileRow>,
    val profileConnections: List<EarlierReleaseProfileConnectionRow>,
    val offlineWatchProgress: List<EarlierReleaseOfflineWatchProgressRow>,
)

/** What an earlier release would have done with its Apple TV data at startup. */
sealed interface TvosRecoveryDecision {
    /**
     * Restore accounts, profiles, their bindings and unsent watch actions from [rows], replacing those tables; any
     * other table comes from the database if there is one.
     */
    data class Restore(val rows: TvosRecoveryRows) : TvosRecoveryDecision

    /** The database exists and is authoritative. */
    data object UseDatabase : TvosRecoveryDecision

    /** The data is gone and the image can't replace it, but the app was used before: ask to sign in again. */
    data object RecoveryRequired : TvosRecoveryDecision

    /** Nothing was ever stored: a first launch. */
    data object Fresh : TvosRecoveryDecision
}

/**
 * Classifies an Apple TV install the way the earlier releases did on launch, from their user defaults [prefs] and
 * whether `plezy_downloads.db` still exists ([databaseExists]):
 * - a recovery-required marker (`tvos_db_recovery_required_v1` true) means restore from a valid image, else
 *   [TvosRecoveryDecision.RecoveryRequired];
 * - otherwise an existing database is used;
 * - a missing database with no recovery keys is [TvosRecoveryDecision.Fresh], or
 *   [TvosRecoveryDecision.RecoveryRequired] when the app was used before (a non-empty `active_app_profile_id` or
 *   `credential_vault_key_v1`, or `profile_migration_v1_done`);
 * - a missing database with recovery keys restores a valid image, else requires recovery.
 */
suspend fun classifyTvosStartup(
    prefs: EarlierReleasePrefs,
    databaseExists: Boolean,
    byteCeiling: Int = TVOS_RECOVERY_BYTE_CEILING,
): TvosRecoveryDecision {
    if (prefs.bool(TVOS_RECOVERY_REQUIRED_KEY) == true) {
        return readTvosRecoveryImage(prefs, byteCeiling)?.let { TvosRecoveryDecision.Restore(it) } ?: TvosRecoveryDecision.RecoveryRequired
    }
    if (databaseExists) return TvosRecoveryDecision.UseDatabase
    // A marker of another type was dropped as unreadable, so it counts as absent here too.
    val markerUnreadable = prefs[TVOS_RECOVERY_REQUIRED_KEY] != null && prefs.bool(TVOS_RECOVERY_REQUIRED_KEY) == null
    if (prefs.keys.none { it.startsWith(TVOS_RECOVERY_KEY_PREFIX) && !(markerUnreadable && it == TVOS_RECOVERY_REQUIRED_KEY) }) {
        val usedBefore = !prefs.string("active_app_profile_id").isNullOrEmpty() ||
            prefs.bool("profile_migration_v1_done") == true ||
            !prefs.string(EarlierReleasePrefs.VAULT_KEY).isNullOrEmpty()
        return if (usedBefore) TvosRecoveryDecision.RecoveryRequired else TvosRecoveryDecision.Fresh
    }
    return readTvosRecoveryImage(prefs, byteCeiling)?.let { TvosRecoveryDecision.Restore(it) } ?: TvosRecoveryDecision.RecoveryRequired
}

/**
 * The rows of the committed recovery image in [prefs], or null if there is none or it is invalid: a manifest that
 * isn't exactly the four keys, version 1 and `committed` with both digests; recovery keys over [byteCeiling]; a group
 * missing or not matching its digest; a group that isn't exactly `version` and its row lists; a row whose fields
 * aren't exactly its table's columns with their types. A retired `isDefault` field of a connection row is ignored.
 */
suspend fun readTvosRecoveryImage(prefs: EarlierReleasePrefs, byteCeiling: Int = TVOS_RECOVERY_BYTE_CEILING): TvosRecoveryRows? {
    val manifest = runCatching { parseStrictJson(prefs.string(TVOS_RECOVERY_MANIFEST_KEY) ?: return null) }.getOrNull() as? JsonObject
        ?: return null
    if (manifest.size != 4 || !isVersionOne(manifest["version"])) return null
    val state = manifest.stringField("state")
    val identityDigest = manifest.stringField("identityDigest") ?: return null
    val pendingDigest = manifest.stringField("pendingDigest") ?: return null
    if (state != "committed" || identityDigest.isEmpty() || pendingDigest.isEmpty()) return null
    if (recoveryImageSize(prefs) > byteCeiling) return null
    val identityRaw = prefs.string(TVOS_RECOVERY_IDENTITY_KEY) ?: return null
    val pendingRaw = prefs.string(TVOS_RECOVERY_PENDING_KEY) ?: return null
    if (sha256Hex(identityRaw) != identityDigest || sha256Hex(pendingRaw) != pendingDigest) return null
    val identity = decodeGroup(identityRaw, setOf("connections", "profiles", "profileConnections")) ?: return null
    val pending = decodeGroup(pendingRaw, setOf("offlineWatchProgress")) ?: return null
    return runCatching {
        TvosRecoveryRows(
            connections = identity.getValue("connections").map { row ->
                RecoveryRow(JsonObject(row - "isDefault"), CONNECTION_COLUMNS).run {
                    EarlierReleaseConnectionRow(string("id"), string("kind"), string("displayName"), string("configJson"), long("createdAt"), longOrNull("lastAuthenticatedAt"))
                        .also { require(parseStrictJson(it.configJson) is JsonObject) { "Invalid connection configuration" } }
                }
            },
            profiles = identity.getValue("profiles").map { row ->
                RecoveryRow(row, PROFILE_COLUMNS).run {
                    EarlierReleaseProfileRow(
                        string("id"), string("kind"), string("displayName"), stringOrNull("avatarThumbUrl"), string("configJson"),
                        long("sortOrder"), long("createdAt"), longOrNull("lastUsedAt"),
                    )
                }
            },
            profileConnections = identity.getValue("profileConnections").map { row ->
                RecoveryRow(row, PROFILE_CONNECTION_COLUMNS).run {
                    EarlierReleaseProfileConnectionRow(
                        string("profileId"), string("connectionId"), string("userToken"), string("userIdentifier"), bool("isDefault"),
                        longOrNull("tokenAcquiredAt"), longOrNull("lastUsedAt"),
                    )
                }
            },
            offlineWatchProgress = pending.getValue("offlineWatchProgress").map { row ->
                RecoveryRow(row, OFFLINE_WATCH_COLUMNS).run {
                    EarlierReleaseOfflineWatchProgressRow(
                        long("id"), stringOrNull("profileId"), string("serverId"), stringOrNull("clientScopeId"), string("ratingKey"),
                        string("globalKey"), string("actionType"), longOrNull("viewOffset"), longOrNull("duration"),
                        bool("shouldMarkWatched"), long("createdAt"), long("updatedAt"), long("syncAttempts"), stringOrNull("lastError"),
                    )
                }
            },
        )
    }.getOrNull()
}

private enum class ColumnType { STRING, INT, BOOL }

private class Column(val type: ColumnType, val nullable: Boolean = false)

private val CONNECTION_COLUMNS = mapOf(
    "id" to Column(ColumnType.STRING), "kind" to Column(ColumnType.STRING), "displayName" to Column(ColumnType.STRING),
    "configJson" to Column(ColumnType.STRING), "createdAt" to Column(ColumnType.INT),
    "lastAuthenticatedAt" to Column(ColumnType.INT, nullable = true),
)
private val PROFILE_COLUMNS = mapOf(
    "id" to Column(ColumnType.STRING), "kind" to Column(ColumnType.STRING), "displayName" to Column(ColumnType.STRING),
    "avatarThumbUrl" to Column(ColumnType.STRING, nullable = true), "configJson" to Column(ColumnType.STRING),
    "sortOrder" to Column(ColumnType.INT), "createdAt" to Column(ColumnType.INT), "lastUsedAt" to Column(ColumnType.INT, nullable = true),
)
private val PROFILE_CONNECTION_COLUMNS = mapOf(
    "profileId" to Column(ColumnType.STRING), "connectionId" to Column(ColumnType.STRING), "userToken" to Column(ColumnType.STRING),
    "userIdentifier" to Column(ColumnType.STRING), "isDefault" to Column(ColumnType.BOOL),
    "tokenAcquiredAt" to Column(ColumnType.INT, nullable = true), "lastUsedAt" to Column(ColumnType.INT, nullable = true),
)
private val OFFLINE_WATCH_COLUMNS = mapOf(
    "id" to Column(ColumnType.INT), "profileId" to Column(ColumnType.STRING, nullable = true), "serverId" to Column(ColumnType.STRING),
    "clientScopeId" to Column(ColumnType.STRING, nullable = true), "ratingKey" to Column(ColumnType.STRING),
    "globalKey" to Column(ColumnType.STRING), "actionType" to Column(ColumnType.STRING),
    "viewOffset" to Column(ColumnType.INT, nullable = true), "duration" to Column(ColumnType.INT, nullable = true),
    "shouldMarkWatched" to Column(ColumnType.BOOL), "createdAt" to Column(ColumnType.INT), "updatedAt" to Column(ColumnType.INT),
    "syncAttempts" to Column(ColumnType.INT), "lastError" to Column(ColumnType.STRING, nullable = true),
)

/** A row map that must hold exactly [columns], each of its type (an int as a JSON integer); throws otherwise. */
private class RecoveryRow(private val row: JsonObject, columns: Map<String, Column>) {
    init {
        require(row.keys == columns.keys) { "Invalid tvOS recovery row" }
        for ((name, column) in columns) {
            val value = row.getValue(name)
            if (value is JsonNull) {
                require(column.nullable) { "Invalid tvOS recovery row" }
                continue
            }
            require(value is JsonPrimitive) { "Invalid tvOS recovery row" }
            val valid = when (column.type) {
                ColumnType.STRING -> value.isString
                ColumnType.INT -> !value.isString && dartNumber(value) is Long
                ColumnType.BOOL -> dartBool(value) != null
            }
            require(valid) { "Invalid tvOS recovery row" }
        }
    }

    private fun primitive(name: String): JsonPrimitive? = (row.getValue(name) as? JsonPrimitive)?.takeIf { it !is JsonNull }

    fun string(name: String): String = primitive(name)!!.content
    fun stringOrNull(name: String): String? = primitive(name)?.content
    fun long(name: String): Long = dartNumber(primitive(name)!!) as Long
    fun longOrNull(name: String): Long? = primitive(name)?.let { dartNumber(it) as Long }
    fun bool(name: String): Boolean = dartBool(primitive(name)!!)!!
}

/** A group's row lists, or null unless [raw] is exactly `{"version":1,"rows":{…}}` with [expected] lists of maps. */
private fun decodeGroup(raw: String, expected: Set<String>): Map<String, List<JsonObject>>? {
    val group = runCatching { parseStrictJson(raw) }.getOrNull() as? JsonObject ?: return null
    if (group.size != 2 || !isVersionOne(group["version"])) return null
    val rows = group["rows"] as? JsonObject ?: return null
    if (rows.keys != expected) return null
    return rows.mapValues { (_, list) ->
        if (list !is JsonArray || list.any { it !is JsonObject }) return null
        list.map { it as JsonObject }
    }
}

private fun JsonObject.stringField(name: String): String? = (this[name] as? JsonPrimitive)?.takeIf { it.isString }?.content

/** Whether [element] is the number 1 (`1` or `1.0`; the earlier releases compared numbers by value). */
private fun isVersionOne(element: JsonElement?): Boolean =
    element is JsonPrimitive && !element.isString && dartNumber(element).let { it == 1L || it == 1.0 }

private suspend fun sha256Hex(value: String): String =
    cryptoProvider.get(SHA256).hasher().hash(value.encodeToByteArray()).joinToString("") { (it.toInt() and 0xFF).toString(16).padStart(2, '0') }

/** UTF-8 size of the recovery keys as the earlier releases measured it: the JSON object of them, sorted by key. */
internal fun recoveryImageSize(prefs: EarlierReleasePrefs): Int {
    val json = prefs.keys.filter { it.startsWith(TVOS_RECOVERY_KEY_PREFIX) }.sorted()
        .joinToString(",", "{", "}") { "${dartJsonString(it)}:${dartJsonValue(prefs[it]!!)}" }
    return json.encodeToByteArray().size
}

private fun dartJsonValue(value: EarlierReleasePrefValue): String = when (value) {
    is EarlierReleasePrefValue.BoolValue -> value.value.toString()
    is EarlierReleasePrefValue.LongValue -> value.value.toString()
    is EarlierReleasePrefValue.DoubleValue -> dartDoubleString(value.value)
    is EarlierReleasePrefValue.StringValue -> dartJsonString(value.value)
    is EarlierReleasePrefValue.StringListValue -> value.value.joinToString(",", "[", "]") { dartJsonString(it) }
}

/** A double as Dart prints one: a whole number keeps `.0`; exponents (from 1e21) are lowercase with a sign. */
private fun dartDoubleString(value: Double): String {
    if (value % 1.0 == 0.0 && kotlin.math.abs(value) < 1e21) return "${value.toLong()}.0"
    val text = value.toString()
    return if ('E' in text) text.replace("E-", "e-").replace("E", "e+") else text
}

/** A string as Dart's JSON encoder writes it: quotes, backslashes, control characters and lone surrogates escaped. */
private fun dartJsonString(value: String): String = buildString {
    append('"')
    var i = 0
    while (i < value.length) {
        val c = value[i]
        when {
            c == '"' -> append("\\\"")
            c == '\\' -> append("\\\\")
            c == '\b' -> append("\\b")
            c == '\t' -> append("\\t")
            c == '\n' -> append("\\n")
            c == '\u000C' -> append("\\f")
            c == '\r' -> append("\\r")
            c < ' ' -> append("\\u").append(c.code.toString(16).padStart(4, '0'))
            c.isHighSurrogate() && i + 1 < value.length && value[i + 1].isLowSurrogate() -> {
                append(c).append(value[i + 1])
                i++
            }
            c.isSurrogate() -> append("\\u").append(c.code.toString(16))
            else -> append(c)
        }
        i++
    }
    append('"')
}
