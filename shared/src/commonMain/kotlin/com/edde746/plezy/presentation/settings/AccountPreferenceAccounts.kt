package com.edde746.plezy.presentation.settings

import com.edde746.plezy.backend.Connection
import com.edde746.plezy.jellyfin.JellyfinClient
import com.edde746.plezy.jellyfin.JellyfinConnection
import com.edde746.plezy.model.AccountPreferenceTarget
import com.edde746.plezy.model.AccountPreferences
import com.edde746.plezy.model.AccountPreferencesCapabilities
import com.edde746.plezy.model.AccountPreferencesPatch
import com.edde746.plezy.model.AccountPreferencesSource
import com.edde746.plezy.model.AccountRef
import com.edde746.plezy.plex.tv.PlexAccountConnection
import com.edde746.plezy.profiles.PlexHomeProfile
import com.edde746.plezy.profiles.Profile
import com.edde746.plezy.profiles.ProfileConnection

/**
 * One account the active profile may edit preferences of: the picker's [target], its [connection], and for
 * Plex the token that reads and writes them: the Home user's own, or the owner's for a local profile signed in as the
 * owner, never the owner's for a managed Home user. Jellyfin and Emby accounts go through their live client.
 */
internal class ResolvedAccount(val target: AccountPreferenceTarget, val connection: Connection, val plexToken: String?)

/** The editable accounts in picker order, and the one playback answers to ([playbackRef], null when none). */
internal class AccountResolution(val accounts: List<ResolvedAccount>, val playbackRef: AccountRef?)

/**
 * The accounts whose preferences [profile] may edit: only its own connection [rows] count, among
 * [connections]. A Plex Home profile edits only its parent account with its switched token; a local profile a Plex
 * account with the row's token, else the owner's. The playback account is the Home profile's parent, else the
 * profile's default row; no other account is ever promoted to it. Sorted default first, then by label.
 */
internal fun resolveAccountPreferenceAccounts(profile: Profile?, rows: List<ProfileConnection>, connections: List<Connection>): AccountResolution {
    if (profile == null || rows.isEmpty()) return AccountResolution(emptyList(), null)
    val byId = connections.associateBy { it.id }
    val home = profile as? PlexHomeProfile
    val accounts = mutableListOf<ResolvedAccount>()
    var playbackRef: AccountRef? = null
    for (row in rows) {
        if (row.profileId != profile.id) continue
        val connection = byId[row.connectionId]
        val account = when (connection) {
            is JellyfinConnection -> ResolvedAccount(
                AccountPreferenceTarget(
                    AccountRef.mediaBrowser(connection.kind, connection.id),
                    connection.displayLabel,
                    connection.displaySubtitle,
                    row.isDefault,
                ),
                connection,
                plexToken = null,
            )
            is PlexAccountConnection -> plexAccount(profile, home, row, connection)
            else -> null
        } ?: continue
        accounts += account
        val playbackRow = if (home != null) connection is PlexAccountConnection && row.connectionId == home.parentConnectionId else row.isDefault
        if (playbackRow) playbackRef = account.target.ref
    }
    accounts.sortWith(compareBy<ResolvedAccount> { !it.target.isDefaultConnection }.thenBy { it.target.label.lowercase() })
    return AccountResolution(accounts, playbackRef)
}

private fun plexAccount(profile: Profile, home: PlexHomeProfile?, row: ProfileConnection, connection: PlexAccountConnection): ResolvedAccount? {
    val homeUserUuid: String?
    val token: String?
    if (home != null) {
        if (home.parentConnectionId != connection.id) return null
        homeUserUuid = home.plexHomeUserUuid?.takeIf { it.isNotEmpty() } ?: return null
        if (row.userIdentifier != homeUserUuid || !row.hasToken) return null
        token = row.userToken
    } else {
        homeUserUuid = if (row.hasToken) row.userIdentifier else connection.activeProfile?.uuid
        token = (if (row.hasToken) row.userToken else connection.accountToken)?.takeIf { it.isNotEmpty() } ?: return null
    }
    val homeUserTitle = if (home != null) profile.displayName else connection.activeProfile?.title
    return ResolvedAccount(
        AccountPreferenceTarget(
            AccountRef.plex(connection.id, homeUserUuid),
            connection.accountLabel,
            homeUserTitle?.takeIf { it.isNotEmpty() },
            row.isDefault,
        ),
        connection,
        token,
    )
}

/** A Jellyfin or Emby account's preferences through its live [client]. */
internal class JellyfinAccountPreferencesSource(private val client: JellyfinClient) : AccountPreferencesSource {
    override val capabilities: AccountPreferencesCapabilities get() = client.accountPreferencesCapabilities

    override suspend fun read(): AccountPreferences = client.fetchAccountPreferences()

    override suspend fun write(patch: AccountPreferencesPatch, checkCurrent: (() -> Unit)?): AccountPreferences {
        capabilities.validate(patch)
        return client.updateAccountPreferences(patch, checkCurrent)
    }
}
