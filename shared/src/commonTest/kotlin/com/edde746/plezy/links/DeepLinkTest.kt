package com.edde746.plezy.links

import com.edde746.plezy.livetv.LiveLink
import com.edde746.plezy.livetv.LiveTvStartPosition
import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.profiles.LocalProfile
import com.edde746.plezy.profiles.PlexHomeProfile
import com.edde746.plezy.profiles.Profile
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs
import kotlin.test.assertNull

/**
 * The `plezy://` grammar: what each host reads, the trimming and blank rules, the shelf content id, the catalogue ids,
 * the round trip of a written link, and which profile a link's `profile` names.
 */
class DeepLinkTest {
    @Test
    fun readsAnItemOnAServerOfAnyBackend() {
        val link = assertIs<DeepLink.Play>(DeepLink.parse("plezy://play?server=abc123&id=42&mode=shuffle&profile=Kids"))
        assertEquals(PlayTarget.Item(ServerId("abc123"), "42"), link.target)
        assertEquals(PlayMode.SHUFFLE, link.mode)
        assertEquals("Kids", link.profile)
    }

    @Test
    fun readsTheLauncherShelfContentId() {
        val link = assertIs<DeepLink.Play>(DeepLink.parse("plezy://play?content_id=plezy_abc123_42"))
        assertEquals(PlayTarget.Item(ServerId("abc123"), "42"), link.target)
        assertEquals(PlayMode.NEXT, link.mode)
    }

    @Test
    fun theModeIgnoresCase() {
        assertEquals(PlayMode.SHUFFLE, assertIs<DeepLink.Play>(DeepLink.parse("plezy://play?server=s&id=1&mode=SHUFFLE")).mode)
        assertEquals(PlayMode.NEXT, assertIs<DeepLink.Play>(DeepLink.parse("plezy://play?type=movie&tmdb=603&mode=Next")).mode)
        assertEquals("plezy://play?server=s&id=1", DeepLink.Play(PlayTarget.Item(ServerId("s"), "1"), PlayMode.NEXT).toUrl())
        assertEquals("plezy://play?server=s&id=1&mode=shuffle", DeepLink.Play(PlayTarget.Item(ServerId("s"), "1"), PlayMode.SHUFFLE).toUrl())
    }

    @Test
    fun theShelfContentIdSplitsAtTheFirstUnderscoreAndWinsOverServerAndId() {
        val link = assertIs<DeepLink.Play>(DeepLink.parse("plezy://play?server=other&id=1&content_id=plezy_srv_a_b_c"))
        assertEquals(PlayTarget.Item(ServerId("srv"), "a_b_c"), link.target)
        assertEquals("plezy_srv_a_b_c", ShelfContentId.build(ServerId("srv"), "a_b_c"))
        val shelfLink = assertIs<DeepLink.Play>(DeepLink.parse(ShelfContentId.playUrl(ShelfContentId.build(ServerId("s 1"), "x_y"))))
        assertEquals(PlayTarget.Item(ServerId("s 1"), "x_y"), shelfLink.target)
    }

    @Test
    fun readsACatalogueTitleAndNormalizesItsIds() {
        val link = assertIs<DeepLink.Play>(DeepLink.parse("plezy://play?type=Show&tvdb=81189&imdb=TT0903747&plex=5d9c086c46115600200aa2fe"))
        val target = PlayTarget.Catalog(MediaKind.SHOW, ExternalIds(tvdb = 81189, imdb = "tt0903747"), "5d9c086c46115600200aa2fe")
        assertEquals(target, link.target)
        assertEquals("plex://show/5d9c086c46115600200aa2fe", assertIs<PlayTarget.Catalog>(link.target).plexGuid)
    }

    @Test
    fun readsALiveChannel() {
        val link = assertIs<DeepLink.Live>(DeepLink.parse("plezy://live?channel=4.1&server=abc123&start=beginning"))
        assertEquals("4.1", link.channel)
        assertEquals(ServerId("abc123"), link.serverId)
        assertEquals(LiveTvStartPosition.BEGINNING, link.start)
        assertEquals(LiveLink("4.1", ServerId("abc123"), LiveTvStartPosition.BEGINNING), link.channelLink)
        assertEquals(LiveTvStartPosition.ASK, assertIs<DeepLink.Live>(DeepLink.parse("plezy://live?channel=KNTV")).start)
        assertEquals(LiveTvStartPosition.LIVE, assertIs<DeepLink.Live>(DeepLink.parse("plezy://live?channel=4&start=live")).start)
        assertEquals(LiveTvStartPosition.BEGINNING, assertIs<DeepLink.Live>(DeepLink.parse("plezy://live?channel=4&start=START")).start)
        assertEquals(LiveTvStartPosition.LIVE, assertIs<DeepLink.Live>(DeepLink.parse("plezy://live?channel=4&start=now")).start)
    }

    @Test
    fun readsOpenWithAndWithoutAProfile() {
        assertNull(assertIs<DeepLink.Open>(DeepLink.parse("plezy://open")).profile)
        assertEquals("Kids", assertIs<DeepLink.Open>(DeepLink.parse("plezy://open?profile=%20Kids%20")).profile)
        assertIs<DeepLink.Open>(DeepLink.parse("PLEZY://OPEN"))
        assertIs<DeepLink.Open>(DeepLink.parse("  plezy://open/  "))
        // A blank value counts as absent.
        assertNull(assertIs<DeepLink.Open>(DeepLink.parse("plezy://open?profile=+")).profile)
    }

    @Test
    fun keepsAnExternalPlayerReturnLinkWhole() {
        val url = "plezy://external-player/success/s1?position=12.5&duration=1420.016"
        val link = assertIs<DeepLink.ExternalPlayerReturn>(DeepLink.parse(url))
        assertEquals(url, link.url)
        assertNull(link.profile)
    }

    @Test
    fun rejectsLinksThatDoNotSayWhatToPlay() {
        for (url in listOf(
            "https://example.com/play?server=a&id=1",
            "plezy:open",
            "plezy://unknown",
            "plezy://play",
            "plezy://play?id=42",
            "plezy://play?server=abc123",
            "plezy://play?server=abc123&id=42&mode=random",
            "plezy://play?content_id=garbage",
            "plezy://play?content_id=plezy_onlyserver",
            "plezy://play?type=movie",
            "plezy://play?type=episode&tmdb=1",
            "plezy://play?type=movie&tmdb=12a",
            "plezy://play?type=movie&tmdb=99999999999999999999999",
            "plezy://play?type=movie&imdb=0903747",
            "plezy://play?type=movie&plex=not-a-hash",
            "plezy://live",
            "plezy://live?channel=",
            "plezy://live?channel=4&start=sideways",
            "plezy://play?server=a&id=%E0%A4%A",
            "plezy://play?server=a&id=%ZZ",
            "plezy://play?server=a&id=%C3%28",
        )) {
            assertNull(DeepLink.parse(url), url)
        }
    }

    @Test
    fun aLinkWrittenOutParsesBackToTheSameLink() {
        val links = listOf(
            DeepLink.Open(),
            DeepLink.Open(profile = "Kids"),
            DeepLink.Play(PlayTarget.Item(ServerId("srv 1"), "a/b&c")),
            DeepLink.Play(PlayTarget.Catalog(MediaKind.MOVIE, ExternalIds(tmdb = 603, imdb = "tt0133093")), profile = "plex-home-1"),
            DeepLink.Play(PlayTarget.Catalog(MediaKind.SHOW, plexHash = "5d9c086c46115600200aa2fe"), PlayMode.SHUFFLE),
            DeepLink.Live("KNTV & co", ServerId("abc"), LiveTvStartPosition.LIVE),
            DeepLink.Live("4.1", start = LiveTvStartPosition.BEGINNING, profile = "Kids"),
        )
        for (link in links) {
            val url = link.toUrl()
            assertEquals(link, DeepLink.parse(url), url)
            assertEquals(url, DeepLink.parse(url)?.toUrl())
        }
    }

    @Test
    fun writesTheParametersInTheirOrderAndLeavesOutTheDefaults() {
        assertEquals("plezy://open", DeepLink.Open().toUrl())
        assertEquals("plezy://play?server=srv+1&id=a%2Fb%26c", DeepLink.Play(PlayTarget.Item(ServerId("srv 1"), "a/b&c")).toUrl())
        assertEquals(
            "plezy://play?type=show&tvdb=81189&mode=shuffle&profile=Kids",
            DeepLink.Play(PlayTarget.Catalog(MediaKind.SHOW, ExternalIds(tvdb = 81189)), PlayMode.SHUFFLE, "Kids").toUrl(),
        )
        assertEquals("plezy://live?channel=4.1&start=beginning", DeepLink.Live("4.1", start = LiveTvStartPosition.BEGINNING).toUrl())
        assertEquals("plezy://play?content_id=plezy_abc_42", ShelfContentId.playUrl("plezy_abc_42"))
    }

    private val max = home("plex-home-a-max", "Max", "AAAA1111")
    private val kids = local("local-1", "Kids")
    private val leo = home("plex-home-a-leo", "Leo", "BBBB2222")

    @Test
    fun matchesTheProfileIdThenThePlexHomeUuidThenTheName() {
        val profiles = listOf(max, kids, leo)
        assertEquals(kids, resolveLinkProfile(profiles, "local-1"))
        assertEquals(leo, resolveLinkProfile(profiles, "bbbb2222"))
        assertEquals(kids, resolveLinkProfile(profiles, " kids "))
    }

    @Test
    fun anIdBeatsADisplayNameThatHappensToEqualIt() {
        val named = local("local-2", "local-1")
        assertEquals(kids, resolveLinkProfile(listOf(named, kids), "local-1"))
    }

    @Test
    fun returnsNullForAnUnknownOrAmbiguousReference() {
        assertNull(resolveLinkProfile(listOf(max, kids), "Nobody"))
        assertNull(resolveLinkProfile(listOf(kids, local("local-3", "KIDS")), "kids"))
    }

    @Test
    fun generatedReferencesResolveToTheSameProfile() {
        val profiles = listOf(max, kids, leo)
        assertEquals("AAAA1111", linkProfileRef(max))
        assertEquals("local-1", linkProfileRef(kids))
        for (profile in profiles) assertEquals(profile, resolveLinkProfile(profiles, linkProfileRef(profile)))
    }

    private fun local(id: String, name: String): Profile = LocalProfile(id = id, displayName = name, createdAt = 0)

    private fun home(id: String, name: String, uuid: String): Profile =
        PlexHomeProfile(id = id, displayName = name, parentConnectionId = "plex-a", plexHomeUserUuid = uuid)
}
