package com.edde746.plezy.jellyfin

import com.edde746.plezy.model.MediaBrowserDialect
import kotlin.test.Test
import kotlin.test.assertEquals

class MediaBrowserPathsTest {
    private val jellyfin = MediaBrowserPaths(MediaBrowserDialect.JELLYFIN, "user-1")
    private val emby = MediaBrowserPaths(MediaBrowserDialect.EMBY, "user-1")

    @Test fun jellyfinUsesUnprefixedRoutes() {
        assertEquals("/Users/Me", jellyfin.currentUser)
        assertEquals("/UserItems/Resume", jellyfin.resumeItems)
        assertEquals("/UserPlayedItems/item-9", jellyfin.playedItem("item-9"))
        assertEquals("/UserFavoriteItems/item-9", jellyfin.favoriteItem("item-9"))
        assertEquals("/UserItems/item-9/Rating", jellyfin.itemRating("item-9"))
        assertEquals("/UserItems/item-9/UserData", jellyfin.userItemData("item-9"))
        assertEquals("/Items/item-9/LocalTrailers", jellyfin.localTrailers("item-9"))
        assertEquals("/Items/item-9/SpecialFeatures", jellyfin.specialFeatures("item-9"))
    }

    @Test fun embyUsesUserScopedRoutes() {
        assertEquals("/Users/user-1", emby.currentUser)
        assertEquals("/Users/user-1/Items/Resume", emby.resumeItems)
        assertEquals("/Users/user-1/PlayedItems/item-9", emby.playedItem("item-9"))
        assertEquals("/Users/user-1/FavoriteItems/item-9", emby.favoriteItem("item-9"))
        assertEquals("/Users/user-1/Items/item-9/Rating", emby.itemRating("item-9"))
        assertEquals("/Users/user-1/Items/item-9/UserData", emby.userItemData("item-9"))
        assertEquals("/Users/user-1/Items/item-9/LocalTrailers", emby.localTrailers("item-9"))
        assertEquals("/Users/user-1/Items/item-9/SpecialFeatures", emby.specialFeatures("item-9"))
        assertEquals("/Users/user-1/Items/item-9/HideFromResume", emby.hideFromResume("item-9"))
    }

    @Test fun idsArePercentEncoded() {
        assertEquals("/Users/user-1/PlayedItems/a%2Fb%3Fc", emby.playedItem("a/b?c"))
        assertEquals("/UserPlayedItems/a%2Fb%3Fc", jellyfin.playedItem("a/b?c"))
        val hostile = MediaBrowserPaths(MediaBrowserDialect.EMBY, "u/1")
        assertEquals("/Users/u%2F1", hostile.currentUser)
        assertEquals("/Users/u%2F1/Items/Resume", hostile.resumeItems)
    }
}
