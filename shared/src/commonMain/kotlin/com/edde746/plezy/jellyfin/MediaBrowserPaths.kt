package com.edde746.plezy.jellyfin

import com.edde746.plezy.model.MediaBrowserDialect

import com.edde746.plezy.net.UriComponent

/**
 * Routes where the dialects diverge: Jellyfin 10.9 renamed the user-scoped routes and added `/Users/Me`; Emby only has
 * the user-scoped spellings (it answers 500 on `Me`). Routes identical on both are not here.
 */
class MediaBrowserPaths(val dialect: MediaBrowserDialect, val userId: String) {
    private val user = "/Users/" + UriComponent.encode(userId)
    private val scoped = dialect.requiresUserScopedItemRoutes

    val currentUser: String get() = if (scoped) user else "/Users/Me"
    /** Whole-object configuration write; the legacy spelling is the one both dialects route. */
    val userConfiguration: String get() = "$user/Configuration"
    val resumeItems: String get() = if (scoped) "$user/Items/Resume" else "/UserItems/Resume"

    fun playedItem(itemId: String) = if (scoped) "$user/PlayedItems/${id(itemId)}" else "/UserPlayedItems/${id(itemId)}"
    fun userItemData(itemId: String) = if (scoped) "$user/Items/${id(itemId)}/UserData" else "/UserItems/${id(itemId)}/UserData"
    fun favoriteItem(itemId: String) = if (scoped) "$user/FavoriteItems/${id(itemId)}" else "/UserFavoriteItems/${id(itemId)}"
    fun itemRating(itemId: String) = if (scoped) "$user/Items/${id(itemId)}/Rating" else "/UserItems/${id(itemId)}/Rating"
    fun localTrailers(itemId: String) = if (scoped) "$user/Items/${id(itemId)}/LocalTrailers" else "/Items/${id(itemId)}/LocalTrailers"
    fun specialFeatures(itemId: String) =
        if (scoped) "$user/Items/${id(itemId)}/SpecialFeatures" else "/Items/${id(itemId)}/SpecialFeatures"
    /** Emby only; Jellyfin 404s on both spellings. */
    fun hideFromResume(itemId: String) = "$user/Items/${id(itemId)}/HideFromResume"

    companion object {
        fun displayPreferences(displayPreferencesId: String) = "/DisplayPreferences/" + UriComponent.encode(displayPreferencesId)
        private fun id(itemId: String) = UriComponent.encode(itemId)
    }
}
