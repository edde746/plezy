package com.edde746.plezy.importer

import com.edde746.plezy.data.Tx
import com.edde746.plezy.data.connections.StoredConnection
import com.edde746.plezy.data.connections.strip
import com.edde746.plezy.data.db.Api_cache
import com.edde746.plezy.data.db.Connections
import com.edde746.plezy.data.db.Device_setting
import com.edde746.plezy.data.db.Download_collection_syncs
import com.edde746.plezy.data.db.Download_collections
import com.edde746.plezy.data.db.Download_owners
import com.edde746.plezy.data.db.Download_queue
import com.edde746.plezy.data.db.Downloaded_media
import com.edde746.plezy.data.db.Live_tv_favorite
import com.edde746.plezy.data.db.Music_sessions
import com.edde746.plezy.data.db.Offline_watch_progress
import com.edde746.plezy.data.db.Profile_connections
import com.edde746.plezy.data.db.Profile_setting
import com.edde746.plezy.data.db.Profiles
import com.edde746.plezy.data.db.Server_setting
import com.edde746.plezy.data.db.Sync_rule_downloads
import com.edde746.plezy.data.db.Sync_rules
import com.edde746.plezy.data.db.Tracker_account
import com.edde746.plezy.data.livetv.parseFavoriteChannelList
import com.edde746.plezy.data.settings.settingsJson
import com.edde746.plezy.importer.EarlierReleasePrefValue.BoolValue
import com.edde746.plezy.importer.EarlierReleasePrefValue.DoubleValue
import com.edde746.plezy.importer.EarlierReleasePrefValue.LongValue
import com.edde746.plezy.importer.EarlierReleasePrefValue.StringListValue
import com.edde746.plezy.importer.EarlierReleasePrefValue.StringValue
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.plex.tv.PlexUserIdentity
import com.edde746.plezy.profiles.PlexHomeUser
import com.edde746.plezy.profiles.ProfileKind
import com.edde746.plezy.profiles.decodePlexHomeUsers
import com.edde746.plezy.profiles.encodePlexHomeUsers
import com.edde746.plezy.profiles.plexHomeProfileId
import com.edde746.plezy.profiles.profileConnectionTokenKey
import com.edde746.plezy.profiles.profileUserScope
import com.edde746.plezy.profiles.repairMissingDefaults
import com.edde746.plezy.seerr.SEERR_SESSION_SECRET_PREFIX
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.settings.LibraryPreference
import com.edde746.plezy.settings.LibraryPrefs
import com.edde746.plezy.settings.ProfileSettings
import com.edde746.plezy.settings.ServerSetting
import com.edde746.plezy.settings.ServerSettings
import com.edde746.plezy.trackers.StoredSession
import com.edde746.plezy.trackers.TrackerService
import com.edde746.plezy.trackers.TrackerSession
import kotlinx.coroutines.CancellationException
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.KSerializer
import kotlinx.serialization.descriptors.PrimitiveKind
import kotlinx.serialization.descriptors.SerialKind
import kotlinx.serialization.descriptors.StructureKind
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.doubleOrNull
import kotlinx.serialization.json.put
import kotlin.uuid.Uuid

// How the earlier releases' rows and preferences become this app's: [planImport] maps everything first, decrypting the
// credentials, so the import can store the secrets and then write every row in one transaction ([ImportPlan]).

/** A profile scope's tracker session to keep in the secret store ([profileUserScope]: a Plex Home user's profiles share it). */
internal class ImportedTrackerSession(val scope: String, val service: TrackerService, val stored: StoredSession)

/** plex.tv's `/user` (an account's uuid, username and email) for a Plex [token], asked as this device ([clientIdentifier]). */
typealias PlexUserLookup = suspend (token: String, clientIdentifier: String) -> JsonObject

/**
 * Everything an import keeps: the [secrets] and [trackerSessions] it stores first, then the rows ([writeRows]).
 * [unidentifiedPlexAccount] is the legacy Plex account made without plex.tv's word on who it is, if one was.
 */
internal class ImportPlan(
    val secrets: Map<String, ByteArray>,
    val trackerSessions: List<ImportedTrackerSession>,
    private val connections: List<Connections>,
    private val profiles: List<Profiles>,
    private val bindings: List<Profile_connections>,
    private val database: EarlierReleaseDatabaseSnapshot,
    private val deviceSettings: Map<String, JsonElement>,
    private val profileSettings: List<Profile_setting>,
    private val serverSettings: List<Server_setting>,
    private val liveTvFavorites: List<Live_tv_favorite>,
    private val trackerAccounts: List<Tracker_account>,
    val unidentifiedPlexAccount: String?,
) {
    /** Inserts every row and setting in [tx]; a row already there fails the transaction. */
    fun writeRows(tx: Tx) {
        val q = tx.q
        connections.forEach { q.connectionQueries.insertRow(it) }
        profiles.forEach { q.profileQueries.insertRow(it) }
        bindings.forEach { q.profileQueries.insertBinding(it) }
        tx.repairMissingDefaults()
        for (row in database.downloadedMedia) {
            q.downloadedMediaQueries.insertRow(
                Downloaded_media(
                    row.id, row.serverId, row.clientScopeId, row.ratingKey, row.globalKey, row.type, row.parentRatingKey,
                    row.grandparentRatingKey, row.status, row.progress, row.totalBytes, row.downloadedBytes, row.videoFilePath,
                    row.additionalPartPaths, row.safRootUri, row.thumbPath, row.downloadedAt, row.errorMessage, row.retryCount,
                    row.bgTaskId, row.mediaIndex, row.mediaSourceId, row.libraryId, row.libraryTitle,
                    // Earlier releases downloaded original files only.
                    transcode_quality = null,
                ),
            )
        }
        for (row in database.downloadOwners) {
            q.downloadedMediaQueries.insertOwnerRow(Download_owners(row.profileId, row.globalKey, row.backend, row.clientScopeId, row.createdAt))
        }
        for (row in database.downloadQueue) {
            q.downloadedMediaQueries.insertQueueRow(
                Download_queue(row.id, row.mediaGlobalKey, row.priority, row.addedAt, row.downloadSubtitles, row.downloadArtwork),
            )
        }
        // The pinned responses: the metadata of downloads, read offline.
        for (row in database.pinnedApiCache) {
            q.apiCacheQueries.insertRow(Api_cache(row.cacheKey, row.data, row.cachedAt * 1000, true))
        }
        for (row in database.offlineWatchProgress) {
            q.offlineWatchQueries.insertRow(
                Offline_watch_progress(
                    row.id, row.profileId, row.serverId, row.clientScopeId, row.ratingKey, row.globalKey, row.actionType,
                    row.viewOffset, row.duration, row.shouldMarkWatched, row.createdAt, row.updatedAt, row.syncAttempts, row.lastError,
                ),
            )
        }
        for (row in database.syncRules) {
            q.syncRuleQueries.insertRow(
                Sync_rules(
                    row.id, row.profileId, row.serverId, row.ratingKey, row.globalKey, row.targetType, row.episodeCount, row.enabled,
                    row.createdAt, row.lastExecutedAt, row.mediaIndex, row.downloadFilter, row.includeSpecials,
                    row.downloadLinksInitialized, transcode_quality = null,
                ),
            )
        }
        for (row in database.syncRuleDownloads) {
            q.syncRuleQueries.insertDownloadRow(Sync_rule_downloads(row.syncRuleId, row.profileId, row.downloadGlobalKey))
        }
        for (row in database.downloadCollections) {
            q.syncRuleQueries.insertCollectionRow(Download_collections(row.profileId, row.serverId, row.collectionId, row.memberIds))
        }
        for (row in database.downloadCollectionSyncs) {
            q.syncRuleQueries.insertCollectionSyncRow(Download_collection_syncs(row.profileId, row.serverId, row.syncedAt, row.checkedIds))
        }
        for (row in database.musicSessions) {
            q.musicSessionQueries.insertRow(
                Music_sessions(
                    row.profileId, row.queueJson, row.orderJson, row.cursor, row.shuffled, row.repeatMode, row.contextTitle,
                    row.contextKind, row.positionMs, row.updatedAt,
                ),
            )
        }
        for ((key, value) in deviceSettings) q.deviceSettingQueries.upsert(Device_setting(key, value.toString()))
        profileSettings.forEach { q.deviceSettingQueries.upsertProfileSetting(it) }
        serverSettings.forEach { q.deviceSettingQueries.upsertServerSetting(it) }
        liveTvFavorites.forEach { q.liveTvFavoriteQueries.insertRow(it) }
        trackerAccounts.forEach { q.trackerQueries.upsertAccount(it) }
    }

    /** Counts of what the import keeps, for the log. */
    fun summary(): String =
        "${connections.size} connections, ${profiles.size} profiles, ${bindings.size} bindings, " +
            "${database.downloadedMedia.size} downloads, ${deviceSettings.size} settings, ${profileSettings.size} profile settings, " +
            "${serverSettings.size} server settings, ${trackerAccounts.size} tracker accounts"
}

/**
 * Maps what an earlier release left ([found]) to this app's rows, settings and secrets, at [now] (epoch milliseconds:
 * the tracker accounts' sign-in time, and a migrated legacy account's). Credentials are decrypted with the vault key
 * from the preferences: one that won't decrypt is lost, and its account signs in again. [plexUser] (null offline)
 * names a legacy Plex account.
 */
internal suspend fun planImport(found: EarlierRelease, now: Long, plexUser: PlexUserLookup? = null): ImportPlan {
    val prefs = found.prefs
    val vault = EarlierReleaseCredentialVault.from(prefs)
    val database = found.database ?: EMPTY_EARLIER_RELEASE_SNAPSHOT
    val secrets = LinkedHashMap<String, ByteArray>()

    val connections = ArrayList<StoredConnection>()
    for (row in database.connections) {
        val kind = BackendKind.entries.firstOrNull { it.id == row.kind }
        val config = jsonOrNull(row.configJson) as? JsonObject
        if (kind == null || config == null) {
            Log.w(TAG) { "connection ${row.id} (${row.kind}) doesn't read: it isn't imported" }
            continue
        }
        connections += StoredConnection(row.id, kind, vault.revealConnectionConfig(row.kind, config), row.createdAt, row.lastAuthenticatedAt)
    }

    val mapped = mapPreferences(prefs)
    val retiredPlexHomeRows = database.profiles.any { it.kind == ProfileKind.PLEX_HOME.id }
    val unidentifiedPlexAccount = migrateLegacyProfiles(prefs, connections, retiredPlexHomeRows, mapped.device, now, plexUser)

    val connectionRows = connections.map { connection ->
        // Unversioned keys and rows (a null secret version), as every earlier release's import writes them.
        val stripped = connection.kind.strip(connection.id, null, connection.config)
        for ((key, token) in stripped.secrets) secrets[key] = token.encodeToByteArray()
        Connections(connection.id, connection.kind.id, stripped.config.toString(), connection.createdAt, connection.lastAuthenticatedAt, null)
    }
    val connectionIds = connections.map { it.id }.toSet()

    val profiles = database.profiles.filter { it.kind == ProfileKind.LOCAL.id }.map {
        Profiles(it.id, it.kind, it.displayName, it.avatarThumbUrl, it.configJson, it.sortOrder, it.createdAt, it.lastUsedAt)
    }

    val bindings = ArrayList<Profile_connections>()
    for (row in database.profileConnections) {
        if (row.connectionId !in connectionIds) {
            Log.w(TAG) { "the binding of ${row.profileId} to ${row.connectionId} has no connection: it isn't imported" }
            continue
        }
        // An empty token is fetched when the binding is next used, as is one that won't decrypt.
        val token = row.userToken.takeIf { it.isNotEmpty() }?.let { vault.reveal(it) }
        if (!token.isNullOrEmpty()) secrets[profileConnectionTokenKey(row.profileId, row.connectionId, null)] = token.encodeToByteArray()
        bindings += Profile_connections(row.profileId, row.connectionId, row.userIdentifier, row.isDefault, row.tokenAcquiredAt, row.lastUsedAt, null)
    }

    val sessions = mapSessions(mapped, vault, profiles.map { it.id }.toSet(), connections, now)
    for ((scope, session) in sessions.seerr) secrets[SEERR_SESSION_SECRET_PREFIX + scope] = session.toString().encodeToByteArray()

    return ImportPlan(
        secrets = secrets,
        trackerSessions = sessions.trackers,
        connections = connectionRows,
        profiles = profiles,
        bindings = bindings,
        database = database,
        deviceSettings = mapped.device,
        profileSettings = mapped.profile.map { (key, value) -> Profile_setting(key.first, key.second, value.toString()) },
        serverSettings = mapped.server.map { (key, value) -> Server_setting(key.first, key.second, value.toString()) },
        liveTvFavorites = liveTvFavorites(prefs, connections),
        trackerAccounts = sessions.trackers.map {
            Tracker_account(it.scope, it.service.id, it.stored.session.username, it.stored.connectedAt)
        },
        unidentifiedPlexAccount = unidentifiedPlexAccount,
    )
}

/** A database with no rows, for an install whose database is gone. */
internal val EMPTY_EARLIER_RELEASE_SNAPSHOT = EarlierReleaseDatabaseSnapshot(
    schemaVersion = EARLIER_RELEASE_SCHEMA_VERSION,
    downloadedMedia = emptyList(),
    downloadOwners = emptyList(),
    downloadQueue = emptyList(),
    pinnedApiCache = emptyList(),
    offlineWatchProgress = emptyList(),
    syncRules = emptyList(),
    syncRuleDownloads = emptyList(),
    downloadCollections = emptyList(),
    downloadCollectionSyncs = emptyList(),
    connections = emptyList(),
    profiles = emptyList(),
    profileConnections = emptyList(),
    musicSessions = emptyList(),
)

// ---- Preferences ----------------------------------------------------------------------------------------------------

/** A tracker or Seerr session preference: [scope] is null for the bare key (no profile was active). */
private class SessionPref(val scope: String?, val baseKey: String, val value: String)

/** The preferences as this app keeps them: settings by key (device), by scope and key (profile), by server and key. */
private class MappedPreferences {
    val device = LinkedHashMap<String, JsonElement>()
    val profile = LinkedHashMap<Pair<String, String>, JsonElement>()
    val server = LinkedHashMap<Pair<String, String>, JsonElement>()
    val sessions = ArrayList<SessionPref>()
}

/**
 * Sorts [prefs] into this app's settings: a global setting [AppSettings] declares (its keyed families too) as its
 * stored JSON, a JSON-text preference as the structure it holds; `user_<scope>_<key>` as the profile setting `<key>` of
 * `<scope>`; the per-server keys as server settings; the shapes the legacy migrations rewrite as they are. A value
 * the setting can't hold, credentials and keys this app doesn't keep are left out.
 */
private fun mapPreferences(prefs: EarlierReleasePrefs): MappedPreferences {
    val mapped = MappedPreferences()
    var skipped = 0
    for ((key, value) in prefs.values) {
        if (key in NOT_IMPORTED || key.startsWith(TVOS_RECOVERY_KEY_PREFIX) || key.startsWith(FAVORITE_CHANNELS_PREFIX)) continue
        val scoped = PROFILE_SCOPED_KEY.matchEntire(key)
        val server = serverSettingOf(key)
        val setting = globalSettingOf(key)
        when {
            scoped != null -> {
                val (scope, baseKey) = scoped.destructured
                when {
                    baseKey in SESSION_KEYS -> (value as? StringValue)?.let { mapped.sessions += SessionPref(scope, baseKey, it.value) }
                    isProfileKey(baseKey) -> mapped.profile[scope to baseKey] = jsonValue(value, decodeText = isJsonProfileKey(baseKey))
                    else -> skipped++
                }
            }
            key in SESSION_KEYS -> (value as? StringValue)?.let { mapped.sessions += SessionPref(null, key, it.value) }
            server != null -> {
                val (serverId, serverSetting) = server
                typedJson(serverSetting.serializer, value)?.let { mapped.server[serverId to serverSetting.key] = it } ?: unreadable(key)
            }
            // Releases before profiles kept the library choices unscoped; the active profile adopts them as it reads them.
            isUnscopedLibraryKey(key) -> mapped.device[key] = jsonValue(value, decodeText = isJsonProfileKey(key))
            key in LEGACY_SHAPED_KEYS -> mapped.device[key] = jsonValue(value, decodeText = true)
            setting != null -> {
                val json = typedJson(setting.serializer, value)
                    ?: jsonValue(value, decodeText = true).takeIf { key in LEGACY_SHAPED_SETTINGS }
                if (json != null) mapped.device[key] = json else unreadable(key)
            }
            else -> skipped++
        }
    }
    if (skipped > 0) Log.d(TAG) { "$skipped preferences this app doesn't keep were left out" }
    return mapped
}

private fun unreadable(key: String) {
    Log.w(TAG) { "the stored value of $key isn't one its setting holds: it isn't imported" }
}

/** The global setting [key] is: one [AppSettings] declares, or a profile's last use or a Plex account's Home users. */
private fun globalSettingOf(key: String) = GLOBAL_SETTINGS[key] ?: when {
    key.startsWith(AppSettings.PROFILE_LAST_USED_PREFIX) -> AppSettings.profileLastUsed(key.removePrefix(AppSettings.PROFILE_LAST_USED_PREFIX))
    key.startsWith(AppSettings.PLEX_HOME_USERS_PREFIX) -> AppSettings.plexHomeUsers(key.removePrefix(AppSettings.PLEX_HOME_USERS_PREFIX))
    else -> null
}

/** The server and server setting of a per-server key: `watched_threshold_<id>`, `server_endpoint_<id>`, `dvr_target_section_<type>_<id>`. */
private fun serverSettingOf(key: String): Pair<String, ServerSetting<*>>? {
    val (serverId, setting) = when {
        key.startsWith(WATCHED_THRESHOLD_PREFIX) -> key.removePrefix(WATCHED_THRESHOLD_PREFIX) to ServerSettings.watchedThreshold
        key.startsWith(SERVER_ENDPOINT_PREFIX) -> key.removePrefix(SERVER_ENDPOINT_PREFIX) to ServerSettings.serverEndpoint
        key.startsWith(DVR_TARGET_SECTION_PREFIX) -> {
            val rest = key.removePrefix(DVR_TARGET_SECTION_PREFIX)
            val type = rest.substringBefore('_', "").toIntOrNull() ?: return null
            rest.substringAfter('_') to ServerSettings.dvrTargetSection(type)
        }
        else -> return null
    }
    return if (serverId.isEmpty()) null else serverId to setting
}

private fun isProfileKey(baseKey: String) =
    isUnscopedLibraryKey(baseKey) || baseKey in PROFILE_TEXT_KEYS || baseKey in PROFILE_JSON_KEYS

private fun isUnscopedLibraryKey(key: String) =
    key in LIBRARY_KEYS || LibraryPreference.entries.any { key.startsWith(it.prefix) }

/** Whether the earlier releases kept [baseKey] as JSON text: lists and maps, stored here as the structure. */
private fun isJsonProfileKey(baseKey: String) =
    baseKey in PROFILE_JSON_KEYS || baseKey in LIBRARY_JSON_KEYS ||
        baseKey.startsWith(LibraryPreference.FILTERS.prefix) || baseKey.startsWith(LibraryPreference.SORT.prefix)

/**
 * [value] as JSON: a bool, a number, a list of strings, a string; with [decodeText], a string holding a JSON list or
 * map is that structure (a legacy plain-text value stays a string).
 */
private fun jsonValue(value: EarlierReleasePrefValue, decodeText: Boolean): JsonElement = when (value) {
    is BoolValue -> JsonPrimitive(value.value)
    is LongValue -> JsonPrimitive(value.value)
    is DoubleValue -> JsonPrimitive(value.value)
    is StringListValue -> JsonArray(value.value.map { JsonPrimitive(it) })
    is StringValue -> value.value.takeIf { decodeText }?.let(::jsonOrNull)?.takeIf { it is JsonArray || it is JsonObject }
        ?: JsonPrimitive(value.value)
}

/**
 * [value] as the stored JSON of a setting of [serializer]'s type, or null when the setting can't hold it: another type
 * (Plezy's earlier releases read such a value as unset too), or a value that doesn't decode (an unknown enum name, a
 * JSON text that isn't the setting's structure). A string goes to a string or enum setting as it is, to any other
 * setting as the JSON it holds.
 */
@OptIn(ExperimentalSerializationApi::class)
private fun typedJson(serializer: KSerializer<*>, value: EarlierReleasePrefValue): JsonElement? {
    val kind = serializer.descriptor.kind
    val json = when (value) {
        is BoolValue -> JsonPrimitive(value.value).takeIf { kind == PrimitiveKind.BOOLEAN }
        is LongValue -> JsonPrimitive(value.value).takeIf { kind in INTEGER_KINDS || kind in FRACTION_KINDS }
        is DoubleValue -> JsonPrimitive(value.value).takeIf { kind in FRACTION_KINDS }
        is StringListValue -> JsonArray(value.value.map { JsonPrimitive(it) }).takeIf { kind == StructureKind.LIST }
        is StringValue -> when {
            kind == PrimitiveKind.STRING || kind == SerialKind.ENUM -> JsonPrimitive(value.value)
            kind is PrimitiveKind -> null
            else -> jsonOrNull(value.value)
        }
    } ?: return null
    return try {
        settingsJson.decodeFromJsonElement(serializer, json)
        json
    } catch (_: IllegalArgumentException) {
        // SerializationException is one: a value the setting doesn't decode.
        null
    }
}

private fun jsonOrNull(text: String): JsonElement? = try {
    parseStrictJson(text)
} catch (_: IllegalArgumentException) {
    // SerializationException is one: not JSON.
    null
}

// ---- Legacy single-account installs --------------------------------------------------------------------------------

/**
 * The earliest releases' single Plex account, moved to profiles as the releases after them did on their first start
 * (when `profile_migration_v1_done` isn't set): a legacy `plex_token` becomes a Plex account connection (the one
 * already holding that token, else a new one, [legacyPlexAccount]); the Home users cached in `home_users_cache` become
 * that account's cache, and the profile chosen is the legacy `current_user_uuid`'s, else the admin's. A profile is
 * chosen only when legacy state exists (a token, a current user or Home users cache, retired `plex_home` rows): a fresh
 * install, or a preference store that lost only the flag, picks none. Installs already migrated whose legacy profile
 * state came back choose again. Without cached Home users no profile is chosen: the account's Home users are listed
 * once it's online. Returns the id of a new account plex.tv didn't name, if one was made.
 */
private suspend fun migrateLegacyProfiles(
    prefs: EarlierReleasePrefs,
    connections: MutableList<StoredConnection>,
    retiredPlexHomeRows: Boolean,
    device: MutableMap<String, JsonElement>,
    now: Long,
    plexUser: PlexUserLookup?,
): String? {
    val legacyToken = prefs.string(LEGACY_PLEX_TOKEN)?.takeIf { it.isNotEmpty() }
    val legacyProfileState = !prefs.string(AppSettings.currentUserUuid.key).isNullOrEmpty() ||
        !prefs.string(AppSettings.homeUsersCache.key).isNullOrEmpty()
    fun firstPlexAccount() = connections.firstOrNull { it.kind == BackendKind.PLEX }
    var unidentified: String? = null
    if (prefs.bool(AppSettings.profileMigrationDone.key) != true) {
        val migrated = legacyToken?.let { token ->
            connections.firstOrNull { it.kind == BackendKind.PLEX && (it.config["accountToken"] as? JsonPrimitive)?.content == token }
                ?: legacyPlexAccount(token, prefs, device, now, plexUser).let { (account, identified) ->
                    connections.removeAll { it.id == account.id }
                    connections += account
                    if (!identified) unidentified = account.id
                    account
                }
        }
        val account = migrated ?: firstPlexAccount()
        if (account != null && (legacyToken != null || legacyProfileState || retiredPlexHomeRows)) selectPlexHomeProfile(account.id, prefs, device)
    } else if (legacyProfileState) {
        firstPlexAccount()?.let { selectPlexHomeProfile(it.id, prefs, device) }
    }
    device[AppSettings.profileMigrationDone.key] = JsonPrimitive(true)
    return unidentified
}

/**
 * The Plex account of a legacy [token], and whether plex.tv named it: online ([plexUser]), keyed by the Plex account's
 * uuid and labelled with its username, else its email; offline, or when plex.tv doesn't answer, keyed by the device's
 * client identifier (made now if there is none) and labelled "Plex". Its servers are the legacy `servers_list`'s.
 */
private suspend fun legacyPlexAccount(
    token: String,
    prefs: EarlierReleasePrefs,
    device: MutableMap<String, JsonElement>,
    now: Long,
    plexUser: PlexUserLookup?,
): Pair<StoredConnection, Boolean> {
    val clientId = (device[AppSettings.clientIdentifier.key] as? JsonPrimitive)?.content?.takeIf { it.isNotEmpty() }
        ?: Uuid.random().toString().also { device[AppSettings.clientIdentifier.key] = JsonPrimitive(it) }
    val user = plexUser?.let { lookup ->
        try {
            PlexUserIdentity.of(lookup(token, clientId))
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "plex.tv didn't name the legacy Plex account: it's named at the next start online" }
            null
        }
    }
    val config = buildJsonObject {
        put("accountToken", token)
        put("clientIdentifier", clientId)
        put("accountLabel", (user ?: PlexUserIdentity.UNKNOWN).label)
        put("activeProfile", JsonNull)
        put("servers", JsonArray(legacyServers(prefs.string(AppSettings.serversList.key))))
    }
    val id = "plex.${user?.uuid?.ifEmpty { null } ?: clientId}"
    return StoredConnection(id, BackendKind.PLEX, config, now, now) to (user != null)
}

/** The servers of a legacy `servers_list`; none when any of them lacks its name, id, token or connections. */
private fun legacyServers(raw: String?): List<JsonObject> {
    if (raw.isNullOrEmpty()) return emptyList()
    val servers = (jsonOrNull(raw) as? JsonArray)?.map { it as? JsonObject }
    fun JsonObject.text(name: String) = (this[name] as? JsonPrimitive)?.takeIf { it.isString }?.content
    val valid = servers?.all { server ->
        server != null && listOf("name", "clientIdentifier", "accessToken").all { !server.text(it).isNullOrEmpty() } &&
            server["connections"] is JsonArray
    } == true
    if (!valid) {
        Log.w(TAG) { "the legacy server list doesn't read: the migrated account starts without servers" }
        return emptyList()
    }
    return servers.orEmpty().filterNotNull()
}

/** Chooses the Plex Home profile of the account [accountId], caching the legacy Home users for it first. */
private fun selectPlexHomeProfile(accountId: String, prefs: EarlierReleasePrefs, device: MutableMap<String, JsonElement>) {
    val cacheKey = AppSettings.plexHomeUsers(accountId).key
    val legacy = prefs.string(AppSettings.homeUsersCache.key)?.let(::legacyHomeUsers).orEmpty()
    if (legacy.isNotEmpty()) device[cacheKey] = encodePlexHomeUsers(legacy)
    val users = legacy.ifEmpty { (device[cacheKey] as? JsonArray)?.let(::decodePlexHomeUsers).orEmpty() }
    if (users.isEmpty()) {
        Log.w(TAG) { "no cached Plex Home users for $accountId: the profile is chosen once the account is online" }
        return
    }
    val legacyUuid = prefs.string(AppSettings.currentUserUuid.key)?.takeIf { it.isNotEmpty() }
    val selected = legacyUuid?.let { uuid -> users.firstOrNull { it.uuid == uuid } } ?: users.firstOrNull { it.admin } ?: users.first()
    device[AppSettings.activeAppProfileId.key] = JsonPrimitive(plexHomeProfileId(accountId, selected.uuid))
}

/** The users of a legacy `home_users_cache` (`{"id", "users": [...]}`); none when it doesn't read. */
private fun legacyHomeUsers(raw: String): List<PlexHomeUser> {
    val users = (jsonOrNull(raw) as? JsonObject)?.get("users") as? JsonArray ?: return emptyList()
    return decodePlexHomeUsers(users)
}

// ---- Sessions ---------------------------------------------------------------------------------------------------------

private class MappedSessions(val trackers: List<ImportedTrackerSession>, val seerr: Map<String, JsonObject>)

/**
 * The tracker and Seerr sessions, by the profile scopes they reach: a local profile's id is its scope; a Plex Home
 * user's uuid is the scope of every Plex Home profile of that user among the cached Home users of the Plex accounts.
 * A value kept under a Plex Home profile's full id is that user's, and wins (the earlier releases moved it so). A bare
 * session (kept while no profile was active) goes to the active profile's scope when that has none. A tracker session
 * the earlier releases would have refused to load (a missing refresh token or expiry where its service has them) is
 * left out.
 */
private suspend fun mapSessions(
    mapped: MappedPreferences,
    vault: EarlierReleaseCredentialVault,
    localProfileIds: Set<String>,
    connections: List<StoredConnection>,
    now: Long,
): MappedSessions {
    val homeUsers = HashSet<String>()
    for (account in connections.filter { it.kind == BackendKind.PLEX }) {
        val users = (mapped.device[AppSettings.plexHomeUsers(account.id).key] as? JsonArray)?.let(::decodePlexHomeUsers).orEmpty()
        for (user in users) homeUsers += user.uuid
    }
    fun hasProfile(scope: String): Boolean = scope in localProfileIds || scope in homeUsers

    val scoped = LinkedHashMap<Pair<String, String>, String>()
    for (session in mapped.sessions.filter { it.scope != null }.sortedBy { it.scope!!.startsWith(PLEX_HOME_PREFIX) }) {
        scoped[profileUserScope(session.scope!!) to session.baseKey] = session.value
    }
    val trackers = LinkedHashMap<Pair<String, TrackerService>, TrackerSession>()
    val seerr = LinkedHashMap<String, JsonObject>()
    for ((key, raw) in scoped) {
        val (scope, baseKey) = key
        val service = TRACKER_SESSION_KEYS[baseKey]
        if (service == null) {
            vault.revealSeerrSession(raw)?.let { seerr[scope] = it } ?: Log.w(TAG) { "a Seerr session doesn't read: it isn't imported" }
            continue
        }
        val session = trackerSessionOf(service, raw) ?: continue
        if (!hasProfile(scope)) {
            Log.w(TAG) { "no profile has the scope of a ${service.id} session: it isn't imported" }
            continue
        }
        trackers[scope to service] = session
    }
    val bare = mapped.sessions.filter { it.scope == null }
    val active = (mapped.device[AppSettings.activeAppProfileId.key] as? JsonPrimitive)?.takeIf { it.isString }?.content
    if (active.isNullOrEmpty()) {
        if (bare.isNotEmpty()) Log.w(TAG) { "no profile is active: the sessions kept without one aren't imported" }
    } else {
        val activeScope = profileUserScope(active)
        for (session in bare) {
            val service = TRACKER_SESSION_KEYS[session.baseKey]
            if (service == null) {
                if (activeScope !in seerr) vault.revealSeerrSession(session.value)?.let { seerr[activeScope] = it }
            } else if ((activeScope to service) !in trackers) {
                trackerSessionOf(service, session.value)?.let { trackers[activeScope to service] = it }
            }
        }
    }
    return MappedSessions(
        trackers = trackers.map { (key, session) -> ImportedTrackerSession(key.first, key.second, StoredSession(now, session)) },
        seerr = seerr,
    )
}

/**
 * The earlier releases' `TrackerSession` JSON (`access_token`, `refresh_token`, `expires_at` and `created_at` in epoch
 * seconds, `username`) as [service]'s session, or null where they wouldn't load it: a field of the wrong type, no
 * access token or creation time; MyAnimeList, Trakt and MDBList without a refresh token or expiry, AniList without an
 * expiry, a Simkl AUTH V2 token (`simkl_at_…`) without either.
 */
private fun trackerSessionOf(service: TrackerService, raw: String): TrackerSession? {
    val session = (jsonOrNull(raw) as? JsonObject)?.let(::decodeTrackerSession)
    val loads = session != null && when (service) {
        TrackerService.MYANIMELIST, TrackerService.TRAKT, TrackerService.MDBLIST -> session.refreshable()
        TrackerService.ANILIST -> session.expiresAt != null
        TrackerService.SIMKL -> !session.accessToken.startsWith(SIMKL_V2_TOKEN_PREFIX) || session.refreshable()
    }
    if (!loads) {
        Log.w(TAG) { "a ${service.id} session the earlier release wouldn't load isn't imported" }
        return null
    }
    return session
}

private fun TrackerSession.refreshable() = !refreshToken.isNullOrEmpty() && expiresAt != null

/** The session in [json], or null when it lacks its access token or creation time, or holds a field of another type. */
private fun decodeTrackerSession(json: JsonObject): TrackerSession? {
    fun text(name: String): String? = when (val value = json[name]) {
        null, JsonNull -> null
        is JsonPrimitive -> if (value.isString) value.content else throw IllegalArgumentException(name)
        else -> throw IllegalArgumentException(name)
    }
    fun number(name: String): Long? = when (val value = json[name]) {
        null, JsonNull -> null
        is JsonPrimitive -> value.takeIf { !it.isString }?.doubleOrNull?.toLong() ?: throw IllegalArgumentException(name)
        else -> throw IllegalArgumentException(name)
    }
    return try {
        TrackerSession(
            accessToken = text("access_token") ?: return null,
            refreshToken = text("refresh_token"),
            expiresAt = number("expires_at"),
            username = text("username"),
            createdAt = number("created_at") ?: return null,
        )
    } catch (_: IllegalArgumentException) {
        // A field of another type: the earlier releases' cast failed, and they dropped the session.
        null
    }
}

// ---- Live TV favourites ---------------------------------------------------------------------------------------------

/**
 * Each Jellyfin and Emby connection's favourite channels: `jellyfin_fav_channels:<connectionId>`, else the first older
 * slot the earlier releases adopted in its place, in their order: the server-keyed `jellyfin_fav_channels:<serverId>`,
 * then the connection's and the server's key in the `flutter.`-prefixed store, which some releases kept writing after
 * the move to bare keys. An adopted slot is used up, as those releases cleared it: another connection to the same
 * server starts without favourites. A list that doesn't read is left out.
 */
private fun liveTvFavorites(prefs: EarlierReleasePrefs, connections: List<StoredConnection>): List<Live_tv_favorite> {
    val rows = ArrayList<Live_tv_favorite>()
    val adopted = HashSet<Pair<Boolean, String>>()
    for (connection in connections) {
        if (connection.kind == BackendKind.PLEX) continue
        val key = FAVORITE_CHANNELS_PREFIX + connection.id
        val serverId = (connection.config["serverMachineId"] as? JsonPrimitive)?.takeIf { it.isString }?.content
        val serverKey = serverId?.let { FAVORITE_CHANNELS_PREFIX + it }
        // (whether the slot is in the prefixed store, its key)
        val slots = listOfNotNull(serverKey?.let { false to it }, true to key, serverKey?.let { true to it })
        val raw = prefs.string(key) ?: slots.firstNotNullOfOrNull { slot ->
            if (slot in adopted) return@firstNotNullOfOrNull null
            val value = if (slot.first) prefs.legacyString(slot.second) else prefs.string(slot.second)
            value?.also { adopted += slot }
        } ?: continue
        val channels = try {
            parseFavoriteChannelList(raw)
        } catch (e: IllegalArgumentException) {
            Log.w(TAG, e) { "the favourite channels of ${connection.id} don't read: they aren't imported" }
            continue
        }
        channels.distinctBy { it.source to it.id }.forEachIndexed { position, channel ->
            rows += Live_tv_favorite(connection.id, position.toLong(), channel.source, channel.id, channel.title, channel.thumb, channel.vcn)
        }
    }
    return rows
}

private const val TAG = "import"
private const val LEGACY_PLEX_TOKEN = "plex_token"
private const val PLEX_HOME_PREFIX = "plex-home-"
private const val FAVORITE_CHANNELS_PREFIX = "jellyfin_fav_channels:"
private const val WATCHED_THRESHOLD_PREFIX = "watched_threshold_"
private const val SERVER_ENDPOINT_PREFIX = "server_endpoint_"
private const val DVR_TARGET_SECTION_PREFIX = "dvr_target_section_"
private const val SIMKL_V2_TOKEN_PREFIX = "simkl_at_"

/** `user_<scope>_<key>`: profile ids hold no `_`. */
private val PROFILE_SCOPED_KEY = Regex("^user_([^_]+)_(.+)$")

private val TRACKER_SESSION_KEYS = TrackerService.entries.associateBy { "${it.id}_session" }
private val SESSION_KEYS = TRACKER_SESSION_KEYS.keys + "seerr_session"

/** Credentials and the earlier releases' bookkeeping: used by the import, never kept as settings. */
private val NOT_IMPORTED = setOf(
    EarlierReleasePrefs.VAULT_KEY,
    EarlierReleasePrefs.MIGRATION_SENTINEL,
    LEGACY_PLEX_TOKEN,
    AppSettings.profileMigrationDone.key,
    AppSettings.currentUserUuid.key,
    AppSettings.homeUsersCache.key,
    AppSettings.homeUsersCacheExpiry.key,
    AppSettings.serversList.key,
)

private val GLOBAL_SETTINGS by lazy { AppSettings.all.associateBy { it.key } }

/** Keys of the earlier releases' settings that the legacy migrations rewrite ([SettingsMigrations.applyLegacyMigrations]). */
private val LEGACY_SHAPED_KEYS by lazy { AppSettings.legacyBoolEnums.map { it.legacyKey }.toSet() + "use_season_poster" + "mpv_config_entries" }

/** Settings whose older shapes the legacy migrations rewrite: kept as stored when they don't decode as today's. */
private val LEGACY_SHAPED_SETTINGS by lazy { setOf(AppSettings.libraryDensity.key, AppSettings.mpvConfigPresets.key) }

private val LIBRARY_KEYS = setOf(LibraryPrefs.SELECTED_LIBRARY_KEY, LibraryPrefs.LIBRARY_FILTERS, LibraryPrefs.LIBRARY_ORDER, LibraryPrefs.HIDDEN_LIBRARIES)
private val LIBRARY_JSON_KEYS = setOf(LibraryPrefs.LIBRARY_FILTERS, LibraryPrefs.LIBRARY_ORDER, LibraryPrefs.HIDDEN_LIBRARIES)
private val PROFILE_TEXT_KEYS = setOf(ProfileSettings.catalogActiveSource.baseKey)
private val PROFILE_JSON_KEYS = setOf(
    ProfileSettings.watchTogetherRecentRooms.baseKey,
    ProfileSettings.metadataRecentTags.baseKey,
    ProfileSettings.trackerWriteQueue.baseKey,
    ProfileSettings.trackerWriteQueueCorrupt.baseKey,
    ProfileSettings.traktSyncQueue.baseKey,
)

private val INTEGER_KINDS = setOf<SerialKind>(PrimitiveKind.BYTE, PrimitiveKind.SHORT, PrimitiveKind.INT, PrimitiveKind.LONG)
private val FRACTION_KINDS = setOf<SerialKind>(PrimitiveKind.FLOAT, PrimitiveKind.DOUBLE)
