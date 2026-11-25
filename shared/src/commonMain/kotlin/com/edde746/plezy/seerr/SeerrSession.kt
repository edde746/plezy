package com.edde746.plezy.seerr

import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.put

/** How a session was signed in: it decides how a silent re-login is done when Seerr forgets the session. */
enum class SeerrAuthMethod(val wire: String) {
    /** `POST /auth/plex` with the profile's Plex token, read live at re-auth time and never copied into the session. */
    PLEX("plex"),

    /** `POST /auth/jellyfin` with the stored username and password, server type 2. */
    JELLYFIN("jellyfin"),

    /** `POST /auth/jellyfin` with the stored username and password, server type 3. */
    EMBY("emby"),

    /** `POST /auth/local` with the stored email and password. */
    LOCAL("local"),

    /**
     * `POST /auth/jellyfin/quickconnect/authenticate` (Seerr 3.4+). Stores no secret: approving again needs the user
     * in front of Jellyfin, so an expired cookie unlinks the session and the user connects again.
     */
    QUICK_CONNECT("quickConnect");

    companion object {
        fun fromWire(wire: String?): SeerrAuthMethod? = entries.firstOrNull { it.wire == wire }
    }
}

/**
 * The product the instance runs. Overseerr and Jellyseerr disagree on `MediaStatus` codes 6 and 7
 * ([SeerrMediaStatus.resolve]). Told apart by the presence of `mediaServerType` in `/settings/public`, never by titles,
 * URLs or versions, which admins edit.
 */
enum class SeerrProduct(val wire: String) {
    OVERSEERR("overseerr"),
    JELLYSEERR("jellyseerr"),

    /** A session kept before the product was recorded, until the next `/settings/public` fetch. */
    UNKNOWN("unknown");

    companion object {
        fun fromWire(wire: String?): SeerrProduct = entries.firstOrNull { it.wire == wire } ?: UNKNOWN
    }
}

/**
 * A profile's Seerr session: the instance URL, the `connect.sid` cookie, what a silent re-login needs, and the Seerr
 * user it maps to. Kept in the secret store ([SeerrSessionStore]); [toString] leaves the cookie and secret out.
 *
 * @param identifier the username (Jellyfin, Emby) or email (local); empty for Plex and Quick Connect.
 * @param secret the password; empty for Plex and Quick Connect.
 * @param cookie the bare `connect.sid` value.
 * @param permissions Seerr's permission mask ([SeerrPermission]).
 * @param instanceLabel the instance's `applicationTitle`.
 * @param createdAt epoch seconds.
 */
data class SeerrSession(
    val baseUrl: String,
    val method: SeerrAuthMethod,
    val identifier: String,
    val secret: String,
    val cookie: String,
    val userId: Int,
    val permissions: Int,
    val displayName: String,
    val instanceLabel: String,
    val product: SeerrProduct = SeerrProduct.UNKNOWN,
    val createdAt: Long,
) {
    fun toJson(): JsonObject = buildJsonObject {
        put("base_url", baseUrl)
        put("method", method.wire)
        put("identifier", identifier)
        put("secret", secret)
        put("cookie", cookie)
        put("user_id", userId)
        put("permissions", permissions)
        put("display_name", displayName)
        put("instance_label", instanceLabel)
        put("product", product.wire)
        put("created_at", createdAt)
    }

    fun encode(): String = toJson().toString()

    override fun toString(): String =
        "SeerrSession(baseUrl=$baseUrl, method=${method.wire}, userId=$userId, permissions=$permissions, product=${product.wire})"

    companion object {
        /**
         * The session in [json]. An unknown method throws rather than fall back to another (a re-auth would post the
         * wrong credentials); a missing product is [SeerrProduct.UNKNOWN].
         *
         * @throws IllegalArgumentException when `base_url`, `method` or `user_id` is missing or wrong.
         */
        fun fromJson(json: JsonObject): SeerrSession = SeerrSession(
            baseUrl = requireNotNull(json.str("base_url")) { "Seerr session without base_url" },
            method = requireNotNull(SeerrAuthMethod.fromWire(json.str("method"))) { "Unknown Seerr auth method" },
            identifier = json.str("identifier").orEmpty(),
            secret = json.str("secret").orEmpty(),
            cookie = json.str("cookie").orEmpty(),
            userId = requireNotNull(json.int("user_id")) { "Seerr session without user_id" },
            permissions = json.int("permissions") ?: 0,
            displayName = json.str("display_name").orEmpty(),
            instanceLabel = json.str("instance_label").orEmpty(),
            product = SeerrProduct.fromWire(json.str("product")),
            createdAt = json.long("created_at") ?: 0,
        )

        /** @throws IllegalArgumentException when [raw] isn't a session's JSON (SerializationException included). */
        fun decode(raw: String): SeerrSession = fromJson(Json.parseToJsonElement(raw).jsonObject)
    }
}

/** The signed-in Seerr user as `GET /auth/me` reports it (never a login body: `/auth/local`'s says permissions 0). */
data class SeerrUser(val id: Int, val displayName: String?, val permissions: Int) {
    companion object {
        /** Null when the body has no numeric `id` or `permissions`: unusable authority, not a zero-permission user. */
        fun fromJson(json: JsonObject): SeerrUser? {
            val id = json.int("id") ?: return null
            val permissions = json.int("permissions") ?: return null
            return SeerrUser(id, json.str("displayName"), permissions)
        }
    }
}
