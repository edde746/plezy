package com.edde746.plezy.backend

import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class DownloadArtworkTest {
    @Test
    fun buildsAllStandardArtworkWithTokenFreeLocalKeys() {
        val item = MediaItem(
            id = "item-1",
            backend = BackendKind.JELLYFIN,
            kind = MediaKind.MOVIE,
            thumbPath = "https://jf/Items/1/Images/Primary?tag=p&api_key=secret",
            clearLogoPath = "https://jf/Items/1/Images/Logo?tag=l&api_key=secret",
            artPath = "https://jf/Items/1/Images/Backdrop/0?tag=b&api_key=secret",
            backgroundSquarePath = "https://jf/Items/1/Images/Thumb?tag=s&api_key=secret",
        )
        val specs = buildArtworkSpecs(item) { it }
        assertEquals(4, specs.size)
        assertTrue(specs.none { "api_key" in it.localKey })
        assertTrue(specs.all { "api_key=secret" in it.url })
        assertEquals("https://jf/Items/1/Images/Primary?tag=p", specs.first().localKey)
    }

    @Test
    fun skipsMissingPathsAndUnresolvableUrls() {
        val item = MediaItem(
            id = "item-1",
            backend = BackendKind.PLEX,
            kind = MediaKind.MOVIE,
            thumbPath = "/library/metadata/1/thumb/1",
            clearLogoPath = "",
            artPath = "/library/metadata/1/art/1",
        )
        val specs = buildArtworkSpecs(item) { path -> if ("art" in path) null else "https://plex$path?X-Plex-Token=t" }
        assertEquals(listOf(DownloadArtworkSpec("/library/metadata/1/thumb/1", "https://plex/library/metadata/1/thumb/1?X-Plex-Token=t")), specs)
    }

    /**
     * Each raw path or URL and the key the earlier releases made of it (their URI parsing: `Uri.parse`, the query
     * parameters without `api_key`, `Uri.replace(queryParameters:)`), produced by running that code.
     */
    private val earlierReleaseKeys = listOf(
        "/library/metadata/1/thumb/123" to "/library/metadata/1/thumb/123",
        "/library/metadata/1/thumb/123?" to "/library/metadata/1/thumb/123?",
        "/library/metadata/1/thumb/123?&" to "/library/metadata/1/thumb/123?&",
        "/library/metadata/1/thumb/123?X-Plex-Token=abc" to "/library/metadata/1/thumb/123?X-Plex-Token=abc",
        "https://jf.example/Items/abc/Images/Primary?tag=t1&api_key=SECRET" to "https://jf.example/Items/abc/Images/Primary?tag=t1",
        "https://jf.example/i?name=a%20b&api_key=x" to "https://jf.example/i?name=a+b",
        "https://jf.example/i?name=a+b&api_key=x" to "https://jf.example/i?name=a+b",
        "https://jf.example/i?a=1&b=2&a=3&api_key=k" to "https://jf.example/i?a=3&b=2",
        "https://jf.example/i?title=Amélie&api_key=k" to "https://jf.example/i?title=Am%C3%A9lie",
        "https://jf.example/i?title=Am%c3%a9lie&api_key=k" to "https://jf.example/i?title=Am%C3%A9lie",
        "https://jf.example/i?tag=😀&api_key=k" to "https://jf.example/i?tag=%F0%9F%98%80",
        "https://jf.example/i?q=a/b:c@d?e&x=~*'()!$,;&api_key=k" to "https://jf.example/i?q=a%2Fb%3Ac%40d%3Fe&x=~%2A%27%28%29%21%24%2C%3B",
        "https://jf.example/i?a-b_c.d~e=f-g_h.i~j&api_key=k" to "https://jf.example/i?a-b_c.d~e=f-g_h.i~j",
        "https://jf.example/i?flag&tag=1&api_key=k" to "https://jf.example/i?flag&tag=1",
        "https://jf.example/i?flag=&tag=1&api_key=k" to "https://jf.example/i?flag&tag=1",
        "https://jf.example/i?=v&tag=1&api_key=k" to "https://jf.example/i?tag=1",
        "https://jf.example/i?&&tag=1&&api_key=k" to "https://jf.example/i?tag=1",
        "https://jf.example/i?tag=a%2Bb&api_key=k" to "https://jf.example/i?tag=a%2Bb",
        "https://jf.example/i?tag=a=b=c&api_key=k" to "https://jf.example/i?tag=a%3Db%3Dc",
        "https://jf.example/i?t%61g=1&api_key=k" to "https://jf.example/i?tag=1",
        "https://jf.example/i?ta%20g=1&api_key=k" to "https://jf.example/i?ta+g=1",
        "https://jf.example/i?tag=1&api%5Fkey=k" to "https://jf.example/i?tag=1",
        "https://jf.example/i?API_KEY=k&tag=1" to "https://jf.example/i?API_KEY=k&tag=1",
        "https://jf.example/i?a=1;b=2&api_key=k" to "https://jf.example/i?a=1%3Bb%3D2",
        "https://jf.example/i?tag=50%&api_key=k" to "https://jf.example/i?tag=50%25",
        "https://jf.example/i?tag=%zz&api_key=k" to "https://jf.example/i?tag=%25zz",
        "https://jf.example/i?tag=[1]&api_key=k" to "https://jf.example/i?tag=%5B1%5D",
        "https://jf.example/i?x=%2B%26%3D&api_key=k" to "https://jf.example/i?x=%2B%26%3D",
        "HTTPS://JF.Example:443/Items/A%7e%41%2f%2F?tag=1&api_key=k" to "https://jf.example/Items/A~A%2F%2F?tag=1",
        "https://jf.example/%41%2d%5F%7E%2E%21%3a?x=1&api_key=k" to "https://jf.example/A-_~.%21%3A?x=1",
        "http://JF.Example:80/x?tag=1&api_key=k" to "http://jf.example/x?tag=1",
        "https://jf.example:80/i?tag=1&api_key=k" to "https://jf.example:80/i?tag=1",
        "ws://jf.example:80/i?tag=1&api_key=k" to "ws://jf.example:80/i?tag=1",
        "https://jf.example:/i?tag=1&api_key=k" to "https://jf.example/i?tag=1",
        "https://jf.example:08096/i?tag=1&api_key=k" to "https://jf.example:8096/i?tag=1",
        "http://jf.example:8096/base/Items/1/Images/Primary?tag=1&api_key=k" to "http://jf.example:8096/base/Items/1/Images/Primary?tag=1",
        "https://JF%2Eexample%41/i?tag=1&api_key=k" to "https://jf.examplea/i?tag=1",
        "http://[::1]:8096/i?tag=1&api_key=k" to "http://[::1]:8096/i?tag=1",
        "http://[::FFFF:1]/i?tag=1&api_key=k" to "http://[::ffff:1]/i?tag=1",
        "https://user:Pa%73s@jf.example/i?tag=1&api_key=k" to "https://user:Pass@jf.example/i?tag=1",
        "https://us er@jf.example/i?x=1&api_key=k" to "https://us%20er@jf.example/i?x=1",
        "https://jf.example?tag=1&api_key=k" to "https://jf.example?tag=1",
        "https://jf.example/thumb?tag=1&api_key=k#frag ment" to "https://jf.example/thumb?tag=1#frag%20ment",
        "https://jf.example/i?x=1&api_key=k#a%7eb%2fc d" to "https://jf.example/i?x=1#a~b%2Fc%20d",
        "https://jf.example/i?tag=1&api_key=k#" to "https://jf.example/i?tag=1#",
        "https://jf.example/library/parts/1/file name.jpg?tag=1&api_key=k" to "https://jf.example/library/parts/1/file%20name.jpg?tag=1",
        "https://jf.example/library/parts/1/Amélie.jpg?tag=1&api_key=k" to "https://jf.example/library/parts/1/Am%C3%A9lie.jpg?tag=1",
        "https://jf.example/i%20j?tag=1&api_key=k" to "https://jf.example/i%20j?tag=1",
        "https://jf.example/i[1]?tag=1&api_key=k" to "https://jf.example/i%5B1%5D?tag=1",
        "https://jf.example/i|x?tag=1&api_key=k" to "https://jf.example/i%7Cx?tag=1",
        "https://h/a/../b/./c?x=1&api_key=k" to "https://h/b/c?x=1",
        "https://h/a/b/../../../c?x=1&api_key=k" to "https://h/c?x=1",
        "https://h/a//b/?x=1&api_key=k" to "https://h/a//b/?x=1",
        "/a/../b?x=1&api_key=k" to "/b?x=1",
        "a/../b?x=1&api_key=k" to "b?x=1",
        "../x/./y?tag=1&api_key=k" to "../x/y?tag=1",
        "./a:b/c?tag=1&api_key=k" to "a%3Ab/c?tag=1",
        "file:///tmp/a?tag=1&api_key=k" to "file:///tmp/a?tag=1",
        "https://JF.example/i?tag=1" to "https://jf.example/i?tag=1",
        // What doesn't parse as a URI stays as it is.
        "http://[::1" to "http://[::1",
        "1http://h/i?x=1&api_key=k" to "1http://h/i?x=1&api_key=k",
    )

    @Test
    fun storageKeysAreTheKeysTheEarlierReleasesMade() {
        for ((raw, expected) in earlierReleaseKeys) {
            assertEquals(expected, artworkStorageKey(raw), raw)
            assertEquals(expected, artworkStorageKey(expected), "keying $expected again")
        }
    }

    @Test
    fun aQueryOfNothingButTheTokenGoesWhole() {
        // The earlier releases kept such a query, token included; a key never holds it now.
        val bare = "https://jf.example/Items/abc/Images/Primary"
        assertEquals(bare, artworkStorageKey("$bare?api_key=SECRET"))
        assertEquals(bare, artworkStorageKey("$bare?api_key=SECRET&api_key=OTHER"))
        assertEquals("https://jf.example/I~#F%20r", artworkStorageKey("HTTPS://JF.Example:443/I%7e?api_key=a b#F r"))
        assertEquals(bare, artworkStorageKey(bare))
    }
}
