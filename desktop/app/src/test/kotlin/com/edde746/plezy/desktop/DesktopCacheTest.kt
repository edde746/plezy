package com.edde746.plezy.desktop

import java.nio.file.Path
import kotlin.test.Test
import kotlin.test.assertEquals

class DesktopCacheTest {
    private fun system(os: String, vararg env: Pair<String, String>) = DesktopSystem(osName = os, osVersion = "1", env = env.toMap()::get)

    @Test
    fun windowsCachesArtworkInTheUsersLocalAppDataNotTheRoamingOneOrTemp() {
        val windows = system("Windows 11", "LOCALAPPDATA" to "C:\\Users\\ann\\AppData\\Local", "APPDATA" to "C:\\Users\\ann\\AppData\\Roaming", "TEMP" to "C:\\Temp")

        assertEquals(Path.of("C:\\Users\\ann\\AppData\\Local", "com.edde746", "Plezy", "artwork"), desktopArtworkCacheDirectory(windows, home = "C:\\Users\\ann").toPath())
    }

    @Test
    fun linuxCachesArtworkInTheUsersXdgCacheHome() {
        val flatpak = system("Linux", "XDG_CACHE_HOME" to "/home/ann/.var/app/com.edde746.plezy/cache")

        assertEquals(Path.of("/home/ann/.var/app/com.edde746.plezy/cache/com.edde746.plezy/artwork"), desktopArtworkCacheDirectory(flatpak, home = "/home/ann").toPath())
    }

    @Test
    fun linuxWithoutXdgCacheHomeCachesInDotCache() {
        val expected = Path.of("/home/ann/.cache/com.edde746.plezy/artwork")

        assertEquals(expected, desktopArtworkCacheDirectory(system("Linux"), home = "/home/ann").toPath())
        assertEquals(expected, desktopArtworkCacheDirectory(system("Linux", "XDG_CACHE_HOME" to ""), home = "/home/ann").toPath())
    }

    @Test
    fun macCachesArtworkInTheUsersCaches() {
        assertEquals(Path.of("/Users/ann/Library/Caches/com.edde746.plezy/artwork"), desktopArtworkCacheDirectory(system("Mac OS X"), home = "/Users/ann").toPath())
    }
}
