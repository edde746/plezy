package com.edde746.plezy.data.recovery

import app.cash.sqldelight.db.QueryResult
import app.cash.sqldelight.db.SqlDriver
import com.edde746.plezy.data.db.Connections
import com.edde746.plezy.data.db.Device_setting
import com.edde746.plezy.data.db.Offline_watch_progress
import com.edde746.plezy.data.db.PlezyDatabase
import com.edde746.plezy.data.db.Profile_connections
import com.edde746.plezy.data.db.Profile_setting
import com.edde746.plezy.data.db.Profiles
import com.edde746.plezy.data.db.Server_setting
import com.edde746.plezy.importer.EarlierReleaseImport
import com.edde746.plezy.settings.AppSettings
import kotlinx.serialization.KSerializer
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json

// The image's three groups, each a JSON string `{"version":3,"rows":{…}}` of its tables' rows (every column, camelCase),
// in primary-key order: identity is `connections`, `profiles` and `profile_connections`; settings is `device_setting`,
// `profile_setting` and `server_setting`; pending is `offline_watch_progress`. No secret is among them: tokens live in
// the secret store, which a purge leaves alone, under the keys of each row's `secretVersion`.
// Decoding is strict: an unknown or missing field, a value of the wrong type or another version rejects the group.

/** The rows a mutation of a group changes, and so the payload it rewrites. */
internal enum class RecoveryGroup { IDENTITY, SETTINGS, PENDING }

@Serializable
internal data class RecoveryPayload<T>(val version: Int, val rows: T)

@Serializable
internal data class IdentityRows(
    val connections: List<ConnectionRecord>,
    val profiles: List<ProfileRecord>,
    val profileConnections: List<BindingRecord>,
)

@Serializable
internal data class PendingRows(val offlineWatchProgress: List<OfflineWatchRecord>)

@Serializable
internal data class SettingsRows(
    val deviceSettings: List<DeviceSettingRecord>,
    val profileSettings: List<ProfileSettingRecord>,
    val serverSettings: List<ServerSettingRecord>,
) {
    /**
     * The device settings that are the profiles' bookkeeping rather than preferences: the client identifier, the active
     * profile, the profiles' recency, each Plex account's Home users (its profiles while offline) and the earlier
     * releases' import and profile migration markers. Over the image's budget they are all the settings it keeps.
     */
    fun bookkeeping(): SettingsRows = SettingsRows(deviceSettings.filter { isBookkeeping(it.key) }, emptyList(), emptyList())
}

private val BOOKKEEPING_KEYS = setOf(
    AppSettings.clientIdentifier.key,
    AppSettings.activeAppProfileId.key,
    AppSettings.profileMigrationDone.key,
    EarlierReleaseImport.MARKER.key,
)

private fun isBookkeeping(key: String) = key in BOOKKEEPING_KEYS ||
    key.startsWith(AppSettings.PROFILE_LAST_USED_PREFIX) || key.startsWith(AppSettings.PLEX_HOME_USERS_PREFIX)

@Serializable
internal data class DeviceSettingRecord(val key: String, val valueJson: String)

@Serializable
internal data class ProfileSettingRecord(val profileScope: String, val key: String, val valueJson: String)

@Serializable
internal data class ServerSettingRecord(val serverId: String, val key: String, val valueJson: String)

@Serializable
internal data class ConnectionRecord(
    val id: String,
    val kind: String,
    val configJson: String,
    val createdAt: Long,
    val lastAuthenticatedAt: Long?,
    val secretVersion: String?,
)

@Serializable
internal data class ProfileRecord(
    val id: String,
    val kind: String,
    val displayName: String,
    val avatarThumbUrl: String?,
    val configJson: String,
    val sortOrder: Long,
    val createdAt: Long,
    val lastUsedAt: Long?,
)

@Serializable
internal data class BindingRecord(
    val profileId: String,
    val connectionId: String,
    val userIdentifier: String,
    val isDefault: Boolean,
    val tokenAcquiredAt: Long?,
    val lastUsedAt: Long?,
    val secretVersion: String?,
)

@Serializable
internal data class OfflineWatchRecord(
    val id: Long,
    val profileId: String?,
    val serverId: String,
    val clientScopeId: String?,
    val ratingKey: String,
    val globalKey: String,
    val actionType: String,
    val viewOffset: Long?,
    val duration: Long?,
    val shouldMarkWatched: Boolean,
    val createdAt: Long,
    val updatedAt: Long,
    val syncAttempts: Long,
    val lastError: String?,
)

/** The image's format version; another one is rejected. 2 added the rows' secret versions, 3 the settings group. */
internal const val RECOVERY_FORMAT_VERSION = 3

private val identitySerializer: KSerializer<RecoveryPayload<IdentityRows>> = RecoveryPayload.serializer(IdentityRows.serializer())
private val settingsSerializer: KSerializer<RecoveryPayload<SettingsRows>> = RecoveryPayload.serializer(SettingsRows.serializer())
private val pendingSerializer: KSerializer<RecoveryPayload<PendingRows>> = RecoveryPayload.serializer(PendingRows.serializer())

internal fun encodeIdentity(rows: IdentityRows): String = Json.encodeToString(identitySerializer, RecoveryPayload(RECOVERY_FORMAT_VERSION, rows))

internal fun encodeSettings(rows: SettingsRows): String = Json.encodeToString(settingsSerializer, RecoveryPayload(RECOVERY_FORMAT_VERSION, rows))

internal fun encodePending(rows: PendingRows): String = Json.encodeToString(pendingSerializer, RecoveryPayload(RECOVERY_FORMAT_VERSION, rows))

/** The identity rows of [raw]; throws unless it is a valid identity group of this version. */
internal fun decodeIdentity(raw: String): IdentityRows =
    Json.decodeFromString(identitySerializer, raw).also { require(it.version == RECOVERY_FORMAT_VERSION) }.rows

/** The settings rows of [raw]; throws unless it is a valid settings group of this version. */
internal fun decodeSettings(raw: String): SettingsRows =
    Json.decodeFromString(settingsSerializer, raw).also { require(it.version == RECOVERY_FORMAT_VERSION) }.rows

/** The pending rows of [raw]; throws unless it is a valid pending group of this version. */
internal fun decodePending(raw: String): PendingRows =
    Json.decodeFromString(pendingSerializer, raw).also { require(it.version == RECOVERY_FORMAT_VERSION) }.rows

/** The identity tables' rows now, in primary-key order. */
internal fun PlezyDatabase.identityRows(driver: SqlDriver): IdentityRows = IdentityRows(
    connections = connectionQueries.selectAll().executeAsList().sortedBy { it.id }.map {
        ConnectionRecord(it.id, it.kind, it.config_json, it.created_at, it.last_authenticated_at, it.secret_version)
    },
    profiles = driver.allProfiles().sortedBy { it.id }.map {
        ProfileRecord(it.id, it.kind, it.display_name, it.avatar_thumb_url, it.config_json, it.sort_order, it.created_at, it.last_used_at)
    },
    profileConnections = profileQueries.selectAllBindings().executeAsList()
        .sortedWith(compareBy({ it.profile_id }, { it.connection_id }))
        .map { BindingRecord(it.profile_id, it.connection_id, it.user_identifier, it.is_default, it.token_acquired_at, it.last_used_at, it.secret_version) },
)

/** The settings tables' rows now, in primary-key order. */
internal fun PlezyDatabase.settingsRows(): SettingsRows = SettingsRows(
    deviceSettings = deviceSettingQueries.selectAll().executeAsList().sortedBy { it.setting_key }.map {
        DeviceSettingRecord(it.setting_key, it.value_json)
    },
    profileSettings = deviceSettingQueries.selectAllProfileSettings().executeAsList()
        .sortedWith(compareBy({ it.profile_scope }, { it.setting_key }))
        .map { ProfileSettingRecord(it.profile_scope, it.setting_key, it.value_json) },
    serverSettings = deviceSettingQueries.selectAllServerSettings().executeAsList()
        .sortedWith(compareBy({ it.server_id }, { it.setting_key }))
        .map { ServerSettingRecord(it.server_id, it.setting_key, it.value_json) },
)

/** The pending table's rows now, in primary-key order. */
internal fun PlezyDatabase.pendingRows(): PendingRows = PendingRows(
    offlineWatchQueries.selectPending().executeAsList().sortedBy { it.id }.map {
        OfflineWatchRecord(
            it.id, it.profile_id, it.server_id, it.client_scope_id, it.rating_key, it.global_key, it.action_type, it.view_offset,
            it.duration, it.should_mark_watched, it.created_at, it.updated_at, it.sync_attempts, it.last_error,
        )
    },
)

/**
 * Replaces the image's tables' rows with [identity], [settings] and [pending], every column as it was captured (ids
 * included), in the caller's transaction. Replacing rather than adding lets a start that was interrupted after it
 * replay it.
 */
internal fun PlezyDatabase.replaceCriticalRows(identity: IdentityRows, settings: SettingsRows, pending: PendingRows) {
    profileQueries.deleteAllBindings()
    profileQueries.deleteAllProfiles()
    connectionQueries.deleteAll()
    deviceSettingQueries.deleteAllDeviceSettings()
    deviceSettingQueries.deleteAllProfileSettings()
    deviceSettingQueries.deleteAllServerSettings()
    offlineWatchQueries.deleteAll()
    for (row in identity.connections) {
        connectionQueries.insertRow(Connections(row.id, row.kind, row.configJson, row.createdAt, row.lastAuthenticatedAt, row.secretVersion))
    }
    for (row in identity.profiles) {
        profileQueries.insertRow(
            Profiles(row.id, row.kind, row.displayName, row.avatarThumbUrl, row.configJson, row.sortOrder, row.createdAt, row.lastUsedAt),
        )
    }
    for (row in identity.profileConnections) {
        profileQueries.insertBinding(
            Profile_connections(row.profileId, row.connectionId, row.userIdentifier, row.isDefault, row.tokenAcquiredAt, row.lastUsedAt, row.secretVersion),
        )
    }
    for (row in settings.deviceSettings) deviceSettingQueries.upsert(Device_setting(row.key, row.valueJson))
    for (row in settings.profileSettings) deviceSettingQueries.upsertProfileSetting(Profile_setting(row.profileScope, row.key, row.valueJson))
    for (row in settings.serverSettings) deviceSettingQueries.upsertServerSetting(Server_setting(row.serverId, row.key, row.valueJson))
    for (row in pending.offlineWatchProgress) {
        offlineWatchQueries.insertRow(
            Offline_watch_progress(
                row.id, row.profileId, row.serverId, row.clientScopeId, row.ratingKey, row.globalKey, row.actionType, row.viewOffset,
                row.duration, row.shouldMarkWatched, row.createdAt, row.updatedAt, row.syncAttempts, row.lastError,
            ),
        )
    }
}

/** Every profile, whatever its kind (the schema's queries select one kind at a time). */
private fun SqlDriver.allProfiles(): List<Profiles> = executeQuery(
    null,
    "SELECT id, kind, display_name, avatar_thumb_url, config_json, sort_order, created_at, last_used_at FROM profiles",
    { cursor ->
        QueryResult.Value(
            buildList {
                while (cursor.next().value) {
                    add(
                        Profiles(
                            cursor.getString(0)!!, cursor.getString(1)!!, cursor.getString(2)!!, cursor.getString(3), cursor.getString(4)!!,
                            cursor.getLong(5)!!, cursor.getLong(6)!!, cursor.getLong(7),
                        ),
                    )
                }
            },
        )
    },
    0,
).value
