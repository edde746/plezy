package com.edde746.plezy.profiles

import com.edde746.plezy.crypto.cryptoProvider
import dev.whyoleg.cryptography.algorithms.SHA256

/**
 * Who is using the app: a [LocalProfile] the user made in Plezy, or a [PlexHomeProfile], one per Plex Home user of a
 * signed-in Plex account. A profile uses its connections through [ProfileConnection] bindings.
 */
sealed interface Profile {
    val id: String
    val displayName: String
    val avatarThumbUrl: String?
    val sortOrder: Long

    /** Epoch milliseconds. */
    val createdAt: Long

    /** Epoch milliseconds, or null while never used. */
    val lastUsedAt: Long?

    val kind: ProfileKind

    /** Whether entering the profile needs a PIN: a local profile's own, a Plex Home user's Plex one. */
    val isPinProtected: Boolean

    /** The Plex account a Plex Home profile belongs to; null for a local profile. */
    val parentConnectionId: String? get() = null

    fun withLastUsedAt(at: Long?): Profile
}

/** A profile made in Plezy, stored in `profiles`; [pinHash] is [computePinHash] of its optional PIN. */
data class LocalProfile(
    override val id: String,
    override val displayName: String,
    override val avatarThumbUrl: String? = null,
    val pinHash: String? = null,
    override val sortOrder: Long = 0,
    override val createdAt: Long,
    override val lastUsedAt: Long? = null,
) : Profile {
    override val kind: ProfileKind get() = ProfileKind.LOCAL
    override val isPinProtected: Boolean get() = !pinHash.isNullOrEmpty()

    override fun withLastUsedAt(at: Long?): LocalProfile = copy(lastUsedAt = at)
}

/**
 * A Plex Home user of a signed-in Plex account, built from the account's cached Home users ([virtualPlexHome]) and
 * never stored. Plex checks its PIN ([plexProtected]) when the app switches to the user.
 *
 * [displayName] is blank when Plex gives the user neither a friendly name nor a title; the UI shows "Unknown" then.
 */
data class PlexHomeProfile(
    override val id: String,
    override val displayName: String,
    override val avatarThumbUrl: String? = null,
    override val parentConnectionId: String?,
    val plexHomeUserUuid: String?,
    val plexRestricted: Boolean = false,
    val plexAdmin: Boolean = false,
    val plexProtected: Boolean = false,
    override val sortOrder: Long = 0,
    override val createdAt: Long = 0,
    override val lastUsedAt: Long? = null,
) : Profile {
    override val kind: ProfileKind get() = ProfileKind.PLEX_HOME
    override val isPinProtected: Boolean get() = plexProtected

    override fun withLastUsedAt(at: Long?): PlexHomeProfile = copy(lastUsedAt = at)

    companion object {
        /** The profile of [homeUser] of the Plex account [connectionId]. */
        fun virtualPlexHome(connectionId: String, homeUser: PlexHomeUser, lastUsedAt: Long? = null): PlexHomeProfile =
            PlexHomeProfile(
                id = plexHomeProfileId(connectionId, homeUser.uuid),
                displayName = homeUser.displayName,
                avatarThumbUrl = homeUser.thumb.ifEmpty { null },
                parentConnectionId = connectionId,
                plexHomeUserUuid = homeUser.uuid,
                plexRestricted = homeUser.restricted,
                plexAdmin = homeUser.admin,
                plexProtected = homeUser.protected,
                sortOrder = if (homeUser.admin) 0 else 1,
                createdAt = 0,
                lastUsedAt = lastUsedAt,
            )
    }
}

/** A profile's kind; [id] is the `profiles.kind` value. Plex Home profiles are no longer stored. */
enum class ProfileKind(val id: String) {
    LOCAL("local"),
    PLEX_HOME("plex_home"),
}

/**
 * The stored hash of a profile PIN: lowercase hex SHA-256 of `plezy-app-profile-pin-v1:<pin>`. The fixed salt keeps a
 * child out of a parent's profile; it isn't meant to stand up to someone holding the device.
 */
fun computePinHash(rawPin: String): String =
    cryptoProvider.get(SHA256).hasher().hashBlocking("$PIN_SALT:$rawPin".encodeToByteArray()).toHexString()

/** Whether [rawPin] is the PIN [hash] was made from. */
fun verifyPin(rawPin: String, hash: String): Boolean = computePinHash(rawPin) == hash

private const val PIN_SALT = "plezy-app-profile-pin-v1"

/** The id of a Plex Home user's profile: the same for the same account and user every time it's built. */
fun plexHomeProfileId(accountConnectionId: String, homeUserUuid: String): String =
    "$PLEX_HOME_PREFIX$accountConnectionId-$homeUserUuid"

/** The parts of a Plex Home profile id ([plexHomeProfileId]). */
data class PlexHomeProfileIdParts(val accountConnectionId: String, val homeUserUuid: String)

/**
 * The account and Home user of a Plex Home profile id, or null when [id] isn't one. The Home user's uuid is the
 * trailing 16 hex digits plex.tv uses (or a dashed RFC 4122 uuid); the account id before it may itself hold hyphens
 * and hex.
 */
fun parsePlexHomeProfileId(id: String): PlexHomeProfileIdParts? {
    if (!id.startsWith(PLEX_HOME_PREFIX)) return null
    val rest = id.substring(PLEX_HOME_PREFIX.length)
    val match = TRAILING_HOME_USER_UUID.find(rest) ?: return null
    val accountId = rest.substring(0, match.range.first)
    if (accountId.isEmpty()) return null
    return PlexHomeProfileIdParts(accountId, match.groupValues[1])
}

private const val PLEX_HOME_PREFIX = "plex-home-"

private val TRAILING_HOME_USER_UUID =
    Regex("-([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}|[0-9a-fA-F]{16})$")

/**
 * The settings scope of a profile: a Plex Home profile's bare Home user uuid (so one Home user shares its settings
 * across the accounts it appears on), any other profile's full id.
 */
fun profileUserScope(profileId: String): String = parsePlexHomeProfileId(profileId)?.homeUserUuid ?: profileId
