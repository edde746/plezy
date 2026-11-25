package com.edde746.plezy.desktop.updates

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertTrue

class AppcastTest {
    /** The feed as the release workflow writes it: one item, a macOS and a Windows enclosure. */
    private val feed = """
        <?xml version="1.0" encoding="utf-8"?>
        <rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
          <channel>
            <title>Plezy Updates</title>
            <item>
              <title>Version 2.26.0</title>
              <sparkle:version>160</sparkle:version>
              <sparkle:shortVersionString>2.26.0</sparkle:shortVersionString>
              <sparkle:releaseNotesLink>https://gh-html.edde746.dev/edde746/plezy/2.26.0</sparkle:releaseNotesLink>
              <enclosure url="https://github.com/edde746/plezy/releases/download/2.26.0/plezy-macos.dmg"
                         length="98765432" type="application/octet-stream"
                         sparkle:edSignature="bWFjb3Mtc2lnbmF0dXJl"
                         sparkle:os="macos" />
              <enclosure url="https://github.com/edde746/plezy/releases/download/2.26.0/plezy-windows-installer.exe"
                         length="123456789" type="application/octet-stream"
                         sparkle:edSignature="d2luZG93cy1zaWduYXR1cmU="
                         sparkle:installerArguments="/SILENT /SP-"
                         sparkle:os="windows" />
            </item>
          </channel>
        </rss>
    """.trimIndent()

    @Test
    fun theWindowsEnclosureOfTheReleaseWorkflowsFeedIsRead() {
        assertEquals(
            listOf(
                AppcastItem(
                    build = 160,
                    version = "2.26.0",
                    notesUrl = "https://gh-html.edde746.dev/edde746/plezy/2.26.0",
                    installer = AppcastEnclosure(
                        url = "https://github.com/edde746/plezy/releases/download/2.26.0/plezy-windows-installer.exe",
                        length = 123456789,
                        signature = "d2luZG93cy1zaWduYXR1cmU=",
                    ),
                ),
            ),
            Appcast.parse(feed, "windows"),
        )
    }

    @Test
    fun aReleaseWithoutAWindowsInstallerIsNotOffered() {
        val macOnly = feed.replace(Regex("""<enclosure[^>]*plezy-windows-installer[^>]*/>""", RegexOption.DOT_MATCHES_ALL), "")
        assertTrue(Appcast.parse(macOnly, "windows").isEmpty())
    }

    @Test
    fun itemsComeNewestBuildFirst() {
        val older = feed.substringAfter("<channel>").substringBefore("</channel>").substringAfter("</title>")
            .replace("<sparkle:version>160<", "<sparkle:version>159<").replace("2.26.0", "2.25.9")
        val two = feed.replace("</channel>", "$older</channel>")
        assertEquals(listOf(160L, 159L), Appcast.parse(two, "windows").map { it.build })
        val reversed = feed.replace("<title>Plezy Updates</title>", "<title>Plezy Updates</title>$older")
        assertEquals(listOf(160L, 159L), Appcast.parse(reversed, "windows").map { it.build })
    }

    @Test
    fun aWindowsItemMissingWhatInstallingNeedsIsRefused() {
        val broken = listOf(
            feed.replace("<sparkle:version>160</sparkle:version>", ""),
            feed.replace("<sparkle:version>160<", "<sparkle:version>1.6.0<"),
            feed.replace("<sparkle:shortVersionString>2.26.0</sparkle:shortVersionString>", ""),
            feed.replace("sparkle:edSignature=\"d2luZG93cy1zaWduYXR1cmU=\"", ""),
            feed.replace("length=\"123456789\"", "length=\"0\""),
        )
        for (xml in broken) assertFailsWith<AppcastException> { Appcast.parse(xml, "windows") }
        assertFailsWith<AppcastException> { Appcast.parse("<html>not a feed", "windows") }
    }

    @Test
    fun aFeedWithADoctypeIsRefused() {
        val entity = feed.replace("<rss", "<!DOCTYPE rss [<!ENTITY x SYSTEM \"file:///etc/passwd\">]><rss")
        assertFailsWith<AppcastException> { Appcast.parse(entity, "windows") }
    }
}
