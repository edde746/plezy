package com.edde746.plezy.model

/**
 * Identity of one media-server account whose preferences are stored on the server (or on plex.tv) rather than on
 * this device.
 *
 * Not a scoped client id: one Plex account reachable through three servers is still one account, because plex.tv
 * stores one preference set per Home user.
 *
 * - MediaBrowser: one account per connection, `{serverMachineId}/{userId}`.
 * - Plex: one account per (account connection, Home user) pair; the owner's token must never read or write a
 *   managed user's preferences.
 */
data class AccountRef private constructor(
    val backend: BackendKind,
    /** The owning connection id: `plex.<accountUuid>` or `{machineId}/{userId}`. */
    val connectionId: String,
    /** Plex Home user uuid when used through a managed user; always null for MediaBrowser accounts. */
    val plexHomeUserUuid: String?,
) {
    /** Stable cache/storage key. Holds identifiers only, no credentials, so it is safe to log. */
    val key: String
        get() = plexHomeUserUuid?.takeIf { it.isNotEmpty() }?.let { "$connectionId/~home/$it" } ?: connectionId

    override fun toString(): String = "AccountRef(${backend.id}, $key)"

    companion object {
        /** A Jellyfin or Emby account; [connectionId] is the compound `{serverMachineId}/{userId}`. */
        fun mediaBrowser(backend: BackendKind, connectionId: String): AccountRef =
            AccountRef(backend, connectionId, null)

        /** A Plex account. [homeUserUuid] names the Home user; null means the owner signed in without Home. */
        fun plex(accountConnectionId: String, homeUserUuid: String? = null): AccountRef =
            AccountRef(BackendKind.PLEX, accountConnectionId, homeUserUuid)
    }
}

/**
 * Read/write access to one account's server-stored preferences. One instance per [AccountRef]; implementations own
 * the wire mapping and throw the media-server exception hierarchy on failure.
 */
interface AccountPreferencesSource {
    /** What this backend can store. */
    val capabilities: AccountPreferencesCapabilities

    /** Fetches the authoritative current values. */
    suspend fun read(): AccountPreferences

    /**
     * Applies [patch] and returns the account's state afterwards. Sends only what [patch] names (Jellyfin merges it
     * into a freshly read configuration before its whole-object write; Plex puts exactly those keys in the query).
     * Callers validate against [capabilities] first. [checkCurrent] is invoked before every commit and throws to
     * abort when the write has become stale.
     */
    suspend fun write(patch: AccountPreferencesPatch, checkCurrent: (() -> Unit)? = null): AccountPreferences
}

/**
 * One selectable account in the account preferences section, built from the active profile's connections only.
 */
data class AccountPreferenceTarget(
    val ref: AccountRef,
    /** Server name (MediaBrowser) or account label (Plex). */
    val label: String,
    /** User · URL (MediaBrowser) or Home user (Plex). */
    val subtitle: String? = null,
    /** Whether the profile designated this connection as its picker default. Presentation only. */
    val isDefaultConnection: Boolean = false,
) {
    val backend: BackendKind get() = ref.backend
}
