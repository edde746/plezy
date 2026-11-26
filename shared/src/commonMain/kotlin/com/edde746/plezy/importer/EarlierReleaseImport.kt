package com.edde746.plezy.importer

import com.edde746.plezy.data.LocalData
import com.edde746.plezy.data.Tx
import com.edde746.plezy.data.connections.ConnectionStore
import com.edde746.plezy.data.settings.writeSetting
import com.edde746.plezy.log.Log
import com.edde746.plezy.net.NetworkState
import com.edde746.plezy.plex.tv.PlexUserIdentity
import com.edde746.plezy.profiles.plexAccount
import com.edde746.plezy.profiles.stored
import com.edde746.plezy.secrets.SecretStore
import com.edde746.plezy.settings.AppSetting
import com.edde746.plezy.settings.SettingsMigrations
import com.edde746.plezy.trackers.TrackerTokenStore
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.withContext
import kotlinx.io.files.Path
import kotlinx.io.files.SystemFileSystem
import kotlinx.io.files.SystemPathSeparator
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.builtins.nullable

/** What the first launch found of Plezy's earlier releases on this device, and did with it ([EarlierReleaseImport]). */
@Serializable
enum class EarlierReleaseOutcome {
    /** No earlier release left data here: a new install. */
    @SerialName("nothing") NOTHING,

    /** The earlier release's data was imported. */
    @SerialName("imported") IMPORTED,

    /**
     * Apple TV: the system had purged the database; its accounts, profiles and unsent watch actions came back from
     * the recovery copy.
     */
    @SerialName("restored") RESTORED,

    /**
     * Apple TV: the system had purged the database and its recovery copy is missing or damaged, though the app had
     * been used: the settings were imported, and the accounts must be signed in again (not a first run).
     */
    @SerialName("recoveryRequired") RECOVERY_REQUIRED,
}

/**
 * Upgrades an install of Plezy's earlier releases in place: on the first launch, their preferences, credentials and
 * database become this app's settings, secrets and rows ([run]), once per install.
 *
 * The order: the preference store, the credential vault's key from it, the database (read from a private copy, older
 * schemas upgraded on the copy; on Apple TV the recovery copy of a purged one), then the mapping. Tokens go to
 * [secrets] first (writing them again is harmless); then every row, every setting and the done marker land in one
 * transaction, so an import that fails leaves nothing behind and runs again on the next launch. A token the secret
 * store refuses is lost as one that won't decrypt is: its account signs in again, and everything else is imported, so
 * a store that refuses every write (Windows' Credential Manager once this user's credentials fill it) never holds up
 * the start. The earlier release's files are never changed: reinstalling it keeps working.
 *
 * After the app's data was reset ([com.edde746.plezy.data.DataReset]) the earlier release is handled for good: the
 * reset's mark ([resetMarker] in the app's files directory, outside the database the reset replaced) makes the next
 * start a first run that imports nothing.
 *
 * @param filesDirectory the app's files directory ([com.edde746.plezy.data.DatabaseFactory.filesDirectory]), where a
 *   reset leaves its mark; null looks for none.
 */
class EarlierReleaseImport(private val data: LocalData, private val secrets: SecretStore, private val filesDirectory: String? = null) {
    /** What the import found and did, or null before it has run. */
    suspend fun outcome(): EarlierReleaseOutcome? = data.deviceSettings.value(MARKER)?.outcome

    /**
     * Imports what the earlier releases left at [locations] (null: nothing to look for) unless an import already ran
     * on this install or the app's data was reset, calling [onImport] first when one runs. [plexUser] (null offline)
     * asks plex.tv who a legacy Plex account is. Returns what it did, or null when it had run before. Throws when the
     * import fails; nothing of it is kept then, and the next call tries again.
     */
    suspend fun run(locations: EarlierReleaseLocations?, plexUser: PlexUserLookup? = null, onImport: () -> Unit = {}): EarlierReleaseOutcome? {
        if (done()) return null
        if (filesDirectory != null && SystemFileSystem.exists(resetMarker(filesDirectory))) {
            Log.i(TAG) { "the app's data was reset: the earlier release isn't imported again" }
            return importFound(null, plexUser)
        }
        onImport()
        val found = locations?.let { withContext(Dispatchers.IO) { readEarlierRelease(it) } }
        return importFound(found, plexUser)
    }

    private suspend fun done(): Boolean = data.db.read { deviceSettingQueries.selectByKey(MARKER.key).executeAsOneOrNull() } != null

    /** Imports [found] (null: nothing was found), whether or not an import ran before. */
    internal suspend fun importFound(found: EarlierRelease?, plexUser: PlexUserLookup? = null): EarlierReleaseOutcome {
        if (found == null) {
            data.db.write { mark(EarlierReleaseOutcome.NOTHING) }
            Log.i(TAG) { "no earlier release on this device" }
            return EarlierReleaseOutcome.NOTHING
        }
        val plan = planImport(found, data.db.wallClock(), plexUser)
        var lost = 0
        for ((key, value) in plan.secrets) {
            if (!stored(key) { secrets.put(key, value) }) lost++
        }
        val tokens = TrackerTokenStore(secrets)
        val trackerSessions = plan.trackerSessions.filter { session ->
            stored("the ${session.service.id} session of ${session.scope}") { tokens.save(session.scope, session.service, session.stored) }
        }
        lost += plan.trackerSessions.size - trackerSessions.size
        data.db.write {
            plan.writeRows(this, trackerSessions)
            SettingsMigrations.applyLegacyMigrations(this)
            SettingsMigrations.applyStartupMigrations(this)
            mark(found.outcome, plan.unidentifiedPlexAccount)
        }
        Log.i(TAG) { "earlier release imported (${found.outcome}): ${plan.summary()}, ${trackerSessions.size} tracker accounts" }
        if (lost > 0) Log.w(TAG) { "$lost credentials weren't stored: their accounts sign in again" }
        return found.outcome
    }

    /** Runs [write], which stores the credential [what]; false (logged) when the secret store refuses it. */
    private suspend fun stored(what: String, write: suspend () -> Unit): Boolean = try {
        write()
        true
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        Log.w(TAG, e) { "the secret store refused $what" }
        false
    }

    /**
     * Labels the legacy Plex account the import made without plex.tv (offline, or plex.tv didn't answer) as plex.tv
     * names it ([plexUser]: its username, else its email), once the [network] is online. The account keeps its id: its
     * profiles and caches are keyed by it. A failed lookup, or an account that changed meanwhile, tries again at the
     * next start; an account that's gone needs no name.
     */
    suspend fun nameImportedPlexAccount(connections: ConnectionStore, network: StateFlow<NetworkState>, plexUser: PlexUserLookup) {
        val marker = data.deviceSettings.value(MARKER) ?: return
        val accountId = marker.unidentifiedPlexAccount ?: return
        network.first { it.online }
        val stored = connections.get(accountId)
        val account = stored?.plexAccount()
        if (stored != null && account != null) {
            val label = try {
                PlexUserIdentity.of(plexUser(account.accountToken, account.clientIdentifier)).label
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "plex.tv didn't name $accountId: it's asked again at the next start" }
                return
            }
            try {
                connections.upsert(account.copy(accountLabel = label).stored(), expected = stored)
            } catch (e: IllegalStateException) {
                Log.i(TAG) { "$accountId changed while plex.tv was asked: it's named at the next start (${e.message})" }
                return
            }
        }
        data.deviceSettings.set(MARKER, marker.copy(unidentifiedPlexAccount = null))
    }

    private fun Tx.mark(outcome: EarlierReleaseOutcome, unidentifiedPlexAccount: String? = null) {
        writeSetting(MARKER, EarlierReleaseImportMarker(now(), outcome, unidentifiedPlexAccount))
    }

    internal companion object {
        /** Set by the import that ran: when, and what it did. */
        val MARKER = AppSetting("earlier_release_import_v1", null, EarlierReleaseImportMarker.serializer().nullable)
    }
}

/**
 * The mark a reset of the app's data leaves in its [filesDirectory]: the earlier release was handled, and isn't
 * imported again into the new database.
 */
internal fun resetMarker(filesDirectory: String): Path = Path(filesDirectory, "earlier-release-handled")

/**
 * The import's done marker: when it completed (epoch milliseconds), what it did, and the legacy Plex account it made
 * that plex.tv hasn't named yet ([EarlierReleaseImport.nameImportedPlexAccount]).
 */
@Serializable
internal data class EarlierReleaseImportMarker(
    val completedAt: Long,
    val outcome: EarlierReleaseOutcome,
    val unidentifiedPlexAccount: String? = null,
)

/** What an earlier release left: its preferences, its database's rows (if there was one) and what the import makes of it. */
internal class EarlierRelease(
    val prefs: EarlierReleasePrefs,
    val database: EarlierReleaseDatabaseSnapshot?,
    val outcome: EarlierReleaseOutcome,
)

/**
 * What the earlier releases left at [locations], or null when there is nothing; on Windows, at the support directory
 * of builds from before the company name was set when only that holds their data ([orphanedInstead]). Blocking.
 */
internal suspend fun readEarlierRelease(locations: EarlierReleaseLocations): EarlierRelease? {
    val used = locations.orphanedInstead() ?: locations
    return readEarlierRelease(readPreferenceStore(used.preferences), used.existingDatabase(), used.purgeableDatabase)
}

/**
 * The locations in [EarlierReleaseLocations.orphanedSupportDirectory] (Windows builds from before the company name was set),
 * when it holds the preference store or the database and the current support directory holds neither; else null.
 */
internal fun EarlierReleaseLocations.orphanedInstead(): EarlierReleaseLocations? {
    val orphaned = orphanedSupportDirectory ?: return null
    val store = preferences as? EarlierReleasePreferencesLocation.JsonFile ?: return null
    fun exists(path: String) = SystemFileSystem.exists(Path(path))
    if (exists(store.path) || exists(database)) return null
    val orphanedStore = orphaned.trimEnd(SystemPathSeparator) + SystemPathSeparator + DESKTOP_PREFERENCES_FILE_NAME
    val moved = copy(
        baseDirectory = orphaned,
        supportDirectory = orphaned,
        orphanedSupportDirectory = null,
        preferences = EarlierReleasePreferencesLocation.JsonFile(orphanedStore),
    )
    return moved.takeIf { exists(orphanedStore) || exists(moved.database) }
}

/** The earlier desktop releases' preference store, in their support directory. */
internal const val DESKTOP_PREFERENCES_FILE_NAME = "shared_preferences.json"

/**
 * What the earlier releases left: the preference store [prefs] (null when there is none) and the database file
 * [database] (null when there is none). With a [purgeableDatabase] (Apple TV) a missing database is restored from the
 * recovery copy in the preferences, as those releases did at their start ([classifyTvosStartup]). Blocking.
 */
internal suspend fun readEarlierRelease(prefs: EarlierReleasePrefs?, database: String?, purgeableDatabase: Boolean): EarlierRelease? {
    if (!purgeableDatabase) {
        if (prefs == null && database == null) return null
        return EarlierRelease(prefs ?: EMPTY_PREFS, database?.let(::readEarlierReleaseDatabase), EarlierReleaseOutcome.IMPORTED)
    }
    val stored = prefs ?: EMPTY_PREFS
    return when (val decision = classifyTvosStartup(stored, databaseExists = database != null)) {
        TvosRecoveryDecision.Fresh ->
            if (prefs == null) null else EarlierRelease(stored, null, EarlierReleaseOutcome.IMPORTED)
        TvosRecoveryDecision.UseDatabase ->
            EarlierRelease(stored, database?.let(::readEarlierReleaseDatabase), EarlierReleaseOutcome.IMPORTED)
        TvosRecoveryDecision.RecoveryRequired ->
            EarlierRelease(stored, database?.let(::readEarlierReleaseDatabase), EarlierReleaseOutcome.RECOVERY_REQUIRED)
        is TvosRecoveryDecision.Restore -> {
            val rows = decision.rows
            val snapshot = (database?.let(::readEarlierReleaseDatabase) ?: EMPTY_EARLIER_RELEASE_SNAPSHOT).copy(
                connections = rows.connections,
                profiles = rows.profiles,
                profileConnections = rows.profileConnections,
                offlineWatchProgress = rows.offlineWatchProgress,
            )
            EarlierRelease(stored, snapshot, EarlierReleaseOutcome.RESTORED)
        }
    }
}

/**
 * The preference store at [location]. A damaged desktop store gives up its credentials alone (the vault key, the
 * legacy Plex token, tracker and Seerr sessions), as the earlier releases' repair did; its settings are lost.
 */
private fun readPreferenceStore(location: EarlierReleasePreferencesLocation): EarlierReleasePrefs? = try {
    readEarlierReleasePrefs(location)
} catch (e: CorruptPreferenceStoreException) {
    val path = (location as? EarlierReleasePreferencesLocation.JsonFile)?.path ?: throw e
    val salvaged = salvageDesktopPrefs(checkNotNull(readFileOrNull(path)) { "The preference store went away" })
    Log.w(TAG, e) { "the earlier release's preference store is damaged; its credentials alone are imported ($salvaged)" }
    val values = LinkedHashMap<String, EarlierReleasePrefValue>()
    salvaged.vaultKey?.let { values[EarlierReleasePrefs.VAULT_KEY] = EarlierReleasePrefValue.StringValue(it) }
    for ((key, value) in salvaged.sessions) values[key] = EarlierReleasePrefValue.StringValue(value)
    EarlierReleasePrefs(values)
}

private const val TAG = "import"

private val EMPTY_PREFS = EarlierReleasePrefs(emptyMap())
