package com.edde746.plezy.profiles

import com.edde746.plezy.data.connections.StoredConnection
import com.edde746.plezy.model.BackendKind
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonObject
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

class ProfileAvatarSourceTest {
    private fun jellyfin(id: String, createdAt: Long, tag: String? = null) = StoredConnection(
        id,
        BackendKind.JELLYFIN,
        Json.parseToJsonElement(
            """{"baseUrl":"https://jelly.example/","userId":"jf-user","primaryImageTag":${tag?.let { "\"$it\"" } ?: "null"}}""",
        ).jsonObject,
        createdAt,
    )

    private fun plex(id: String, createdAt: Long) =
        StoredConnection(id, BackendKind.PLEX, Json.parseToJsonElement("""{"accountToken":"t"}""").jsonObject, createdAt)

    private fun homeUser(uuid: String, thumb: String = "") = PlexHomeUser(id = 1, uuid = uuid, title = "Home $uuid", thumb = thumb)

    private fun link(connectionId: String, profileId: String = "local-1", user: String = "jf-user") =
        ProfileConnection(profileId, connectionId, userIdentifier = user)

    private val local = LocalProfile("local-1", "Owner", createdAt = 1)

    private fun resolve(
        links: List<ProfileConnection>,
        connections: List<StoredConnection>,
        plexHome: Map<String, List<PlexHomeUser>> = emptyMap(),
        profile: Profile = local,
    ): String? = resolveProfileAvatarUrls(
        listOf(profile),
        mapOf(profile.id to links),
        connections.associateBy { it.id },
        plexHome,
    )[profile.id]

    @Test
    fun theOldestLinkedConnectionGivesThePicture() {
        val url = resolve(
            listOf(link("jf-newer"), link("jf-older")),
            listOf(jellyfin("jf-older", 1, "older-tag"), jellyfin("jf-newer", 6, "newer-tag")),
        )
        assertEquals("https://jelly.example/Users/jf-user/Images/Primary?tag=older-tag&maxWidth=240&maxHeight=240", url)
    }

    @Test
    fun aFirstConnectionWithoutAPictureMeansInitials() {
        assertNull(resolve(listOf(link("jf-first"), link("jf-second")), listOf(jellyfin("jf-first", 1), jellyfin("jf-second", 6, "second-tag"))))
    }

    @Test
    fun aCreationTieGoesToTheLowerConnectionId() {
        val url = resolve(listOf(link("jf-b"), link("jf-a")), listOf(jellyfin("jf-b", 1, "b-tag"), jellyfin("jf-a", 1, "a-tag")))
        assertTrue(url!!.contains("tag=a-tag"))
    }

    @Test
    fun linksToRemovedConnectionsDoNotCount() {
        val url = resolve(listOf(link("jf-removed"), link("jf-survivor")), listOf(jellyfin("jf-survivor", 6, "survivor-tag")))
        assertTrue(url!!.contains("tag=survivor-tag"))
    }

    @Test
    fun aPlexLinkShowsTheHomeUserItPointsAt() {
        val users = mapOf("plex-1" to listOf(homeUser("home-a", "https://plex.tv/a"), homeUser("home-b", "https://plex.tv/b")))
        assertEquals("https://plex.tv/b", resolve(listOf(link("plex-1", user = "home-b")), listOf(plex("plex-1", 1)), users))
        assertNull(resolve(listOf(link("plex-1", user = "")), listOf(plex("plex-1", 1)), users), "no Home user chosen")
        assertNull(resolve(listOf(link("plex-1", user = "home-c")), listOf(plex("plex-1", 1)), mapOf("plex-1" to listOf(homeUser("home-c")))))
    }

    @Test
    fun mixedLinksStillGoByCreation() {
        val url = resolve(
            listOf(link("jf-1"), link("plex-1", user = "home-a")),
            listOf(plex("plex-1", 1), jellyfin("jf-1", 6, "jf-tag")),
            mapOf("plex-1" to listOf(homeUser("home-a", "https://plex.tv/a"))),
        )
        assertEquals("https://plex.tv/a", url)
    }

    @Test
    fun aPlexHomeProfileKeepsItsOwnPictureOrInitials() {
        val withThumb = PlexHomeProfile.virtualPlexHome("plex-1", homeUser("home-a", "https://plex.tv/a"))
        val borrowed = listOf(jellyfin("jf-1", 1, "jf-tag"))
        assertEquals("https://plex.tv/a", resolve(listOf(link("jf-1", withThumb.id)), borrowed, profile = withThumb))
        val withoutThumb = PlexHomeProfile.virtualPlexHome("plex-1", homeUser("home-a"))
        assertNull(resolve(listOf(link("jf-1", withoutThumb.id)), borrowed, profile = withoutThumb))
    }

    @Test
    fun everyProfileIsCoveredAndOneWithoutLinksGetsInitials() {
        val map = resolveProfileAvatarUrls(listOf(local, local.copy(id = "local-2")), emptyMap(), emptyMap(), emptyMap())
        assertEquals(mapOf("local-1" to null, "local-2" to null), map)
    }
}
