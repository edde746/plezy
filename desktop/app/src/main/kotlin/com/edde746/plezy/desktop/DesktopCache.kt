package com.edde746.plezy.desktop

import java.io.File
import java.nio.file.Path

/**
 * Where the desktop app caches artwork, a folder of this user's alone: `%LOCALAPPDATA%\com.edde746\Plezy\artwork` on
 * Windows, `~/Library/Caches/com.edde746.plezy/artwork` on macOS, and `$XDG_CACHE_HOME/com.edde746.plezy/artwork`
 * (`~/.cache` without it) on Linux, where a Flatpak's sandbox sets it to its own.
 */
internal fun desktopArtworkCacheDirectory(system: DesktopSystem = DesktopSystem(), home: String = System.getProperty("user.home")): File {
    fun env(name: String) = system.env(name)?.takeIf { it.isNotBlank() }
    val directory = when {
        system.osName.startsWith("Windows") -> Path.of(env("LOCALAPPDATA") ?: Path.of(home, "AppData", "Local").toString(), "com.edde746", "Plezy")
        system.osName.startsWith("Mac") -> Path.of(home, "Library", "Caches", "com.edde746.plezy")
        else -> Path.of(env("XDG_CACHE_HOME") ?: Path.of(home, ".cache").toString(), "com.edde746.plezy")
    }
    return directory.resolve("artwork").toFile()
}
