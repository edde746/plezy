package com.edde746.plezy.seerr

import kotlinx.serialization.json.JsonObject

/**
 * `GET /settings/public`: the instance's unauthenticated metadata. The connect flow offers sign-in methods by it, the
 * request sheet its 4K toggle and per-season choice, the catalog its artwork host ([tmdbImageProxyPath]).
 *
 * @param localLogin whether `/auth/local` is enabled.
 * @param mediaServerLogin whether signing in through the linked media server is enabled.
 * @param mediaServerType the linked media server ([SeerrMediaServerType]; 4 is "not configured"); absent on Overseerr.
 * @param partialRequestsEnabled whether users may request single seasons rather than whole shows.
 * @param cacheImages the admin's "Enable Image Caching": artwork then loads through the instance's `/imageproxy`.
 * @param youtubeUrl the trailer host override, read only for its presence ([tmdbImageProxyPath]).
 */
data class SeerrPublicSettings(
    val initialized: Boolean = false,
    val applicationTitle: String? = null,
    val localLogin: Boolean = true,
    val mediaServerLogin: Boolean = true,
    val mediaServerType: Int? = null,
    val movie4kEnabled: Boolean = false,
    val series4kEnabled: Boolean = false,
    val partialRequestsEnabled: Boolean = true,
    val cacheImages: Boolean = false,
    val youtubeUrl: String? = null,
) {
    /** The instance's name: its `applicationTitle`, else "Seerr". */
    val instanceLabel: String get() = applicationTitle?.takeIf { it.isNotEmpty() } ?: "Seerr"

    /**
     * Jellyseerr and Seerr always send a numeric `mediaServerType` (4 before setup); Overseerr has no such key, so its
     * presence is the only trustworthy discriminator.
     */
    val product: SeerrProduct get() = if (mediaServerType != null) SeerrProduct.JELLYSEERR else SeerrProduct.OVERSEERR

    /**
     * The path under the base URL that serves TMDB artwork (append `/t/p/<size>/<file>`), or null when image caching is
     * off and artwork loads from TMDB, as the web UI does. Jellyseerr 2.6.0 moved the route to `/imageproxy/:type/…`;
     * no setting names the route, so the release is read off `youtubeUrl`, a public key that first shipped in it.
     * Overseerr never adopted the typed form.
     */
    val tmdbImageProxyPath: String?
        get() = when {
            !cacheImages -> null
            product == SeerrProduct.JELLYSEERR && youtubeUrl != null -> "/imageproxy/tmdb"
            else -> "/imageproxy"
        }

    companion object {
        fun fromJson(json: JsonObject): SeerrPublicSettings = SeerrPublicSettings(
            initialized = json.bool("initialized") ?: false,
            applicationTitle = json.str("applicationTitle"),
            localLogin = json.bool("localLogin") ?: true,
            mediaServerLogin = json.bool("mediaServerLogin") ?: true,
            mediaServerType = json.int("mediaServerType"),
            movie4kEnabled = json.bool("movie4kEnabled") ?: false,
            series4kEnabled = json.bool("series4kEnabled") ?: false,
            partialRequestsEnabled = json.bool("partialRequestsEnabled") ?: true,
            cacheImages = json.bool("cacheImages") ?: false,
            youtubeUrl = json.str("youtubeUrl"),
        )
    }
}
