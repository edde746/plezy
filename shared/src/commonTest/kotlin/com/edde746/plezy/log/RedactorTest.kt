package com.edde746.plezy.log

import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/** All keys below are made up; they only have the shape of real ones. */
class RedactorTest {
    private val accountToken = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567ABCDEFGHIJKLMNOPQRST"
    private val uuidKey = "0f8fad5b-d9cb-469f-a165-70867728950e"
    private val jwt = "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ0b3J0dWdhIn0.c2lnbmF0dXJlLW5vdC1yZWFs"

    @Test
    fun urlsKeepOnlyTheirOrigin() {
        assertEquals(
            "GET https://addon.example/… failed",
            Redactor.redact("GET https://addon.example/key=$accountToken|sort=size/stream/movie/tt0111161.json failed"),
        )
        assertEquals("see https://example.com/… and http://127.x.x.1:11470/…", Redactor.redact("see https://user:pass@example.com and http://127.0.0.1:11470/x?token=1"))
        assertEquals("(https://download.example.com/…)", Redactor.redact("(https://download.example.com/d/ABC/file.mkv#t=1)"))
        assertEquals("plezy://addon.example/…", Redactor.redact("plezy://addon.example/token=$uuidKey/manifest.json"))
        assertEquals("https://v3-cinemeta.strem.io and https://v3-cinemeta.strem.io/", Redactor.redact("https://v3-cinemeta.strem.io and https://v3-cinemeta.strem.io/"))
        assertEquals("magnet:…", Redactor.redact("magnet:?xt=example"))
    }

    /** mpv's and FFmpeg's log lines as the engines get them (mpv `stream.c`, `loadfile.c`; FFmpeg `hls.c`, `http.c`). */
    @Test
    fun mpvLogLinesKeepNoKey() {
        // A key with no recognisable shape: no key pattern knows it, only its place in the URL gives it away.
        val key = "fakeAccountKey42"
        val lines = listOf(
            "Failed to open https://addon.example/resolve/$key/0123456789abcdef0123456789abcdef01234567/null/0/Example.Film.mkv."
                to "Failed to open https://addon.example/….",
            "Failed to open https://addon.example/key=$key|sort=size/stream/movie/tt0111161.json."
                to "Failed to open https://addon.example/….",
            "Can not open external file https://subs.example.com/sub.srt?apikey=$key."
                to "Can not open external file https://subs.example.com/….",
            "Error when loading first segment 'https://cdn.example.com/hls/$key/seg0.ts'"
                to "Error when loading first segment 'https://cdn.example.com/…'",
            "parse_playlist error Server returned 403 Forbidden (access denied) [https://cdn.example.com/$key/index.m3u8]"
                to "parse_playlist error Server returned 403 Forbidden (access denied) [https://cdn.example.com/…]",
            // File names in stream URLs keep their apostrophes, and the URL goes on after one.
            "Failed to open https://cdn.example.com/dl/Bob's.Example.Film.2001.mkv?k=$key."
                to "Failed to open https://cdn.example.com/….",
            "Opening 'https://cdn.example.com/Bob's.Example.Film/$key/seg0.ts' for reading"
                to "Opening 'https://cdn.example.com/…' for reading",
            "https: HTTP error 403 Forbidden" to "https: HTTP error 403 Forbidden",
        )
        for ((line, redacted) in lines) assertEquals(redacted, Redactor.redact(line))
    }

    @Test
    fun keyShapesAreRemovedFromFreeText() {
        assertEquals("account …, uuid …, jwt …", Redactor.redact("account $accountToken, uuid $uuidKey, jwt $jwt"))
        assertEquals("key=…|sort=size, apikey: …, \"token\":\"…\"", Redactor.redact("key=abc123|sort=size, apikey: s3cr3t, \"token\":\"xyz\""))
        assertEquals("Authorization: Bearer …", Redactor.redact("Authorization: Bearer abc.def-ghi"))
        assertEquals("hash …", Redactor.redact("hash 0123456789abcdef0123456789abcdef01234567"))
        assertEquals("token …", Redactor.redact("token Zx9Qm2Lp8Rt4Vw6Yb1Nc3Hd5Jf7Kg0Ms"))
    }

    @Test
    fun ordinaryTextIsKept() {
        val text = "Loaded 49 items from Cinemeta in 120 ms: tt0111161 tt7366338:1:1 S01E02 " +
            "Example.Film.1994.UHD.BluRay.2160p.DTS-HD.MA.5.1.DV.HEVC.HYBRID.REMUX-NOVA.mkv 54.33 GB " +
            "videoHash 8e245d9679d31e12, bingeGroup addon-a|4k|BluRay REMUX|hevc|DV"
        assertEquals(text, Redactor.redact(text))
    }

    private val originalSink = Log.sink
    private val originalLevel = Log.minLevel

    @AfterTest
    fun restoreLog() {
        Log.sink = originalSink
        Log.minLevel = originalLevel
        LogRedaction.clear()
    }

    @Test
    fun logSinksOnlySeeRedactedText() {
        val lines = mutableListOf<String>()
        Log.sink = Log.Sink { level, tag, message, error -> lines += "$level $tag $message ${error.orEmpty()}" }
        Log.minLevel = Log.Level.INFO
        var built = false
        Log.d("addons") { built = true; "debug" }
        Log.w("addons", IllegalStateException("fetching https://addon.example/key=$accountToken/manifest.json")) {
            "install of https://addon.example/key=$accountToken/manifest.json failed"
        }
        assertFalse(built)
        assertEquals(1, lines.size)
        assertTrue(lines.single().startsWith("WARN addons install of https://addon.example/… failed "))
        assertTrue("IllegalStateException: fetching https://addon.example/…" in lines.single())
        assertFalse(accountToken in lines.single())
    }

    @Test
    fun aRegisteredValueIsRedactedWhereverItAppears() {
        // A session cookie and a password: no key shape knows them.
        LogRedaction.registerCustomValue("  s%3Aregistered-cookie.value  ")
        LogRedaction.registerCustomValue("correct horse")
        // Too short to register: replacing it everywhere would shred every log line.
        LogRedaction.registerCustomValue("abc")

        assertEquals(
            "Session … sent, login with … failed for abc",
            Redactor.redact("Session s%3Aregistered-cookie.value sent, login with correct horse failed for abc"),
        )
    }
}
