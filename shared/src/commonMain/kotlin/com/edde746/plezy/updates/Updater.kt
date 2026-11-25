package com.edde746.plezy.updates

import com.edde746.plezy.app.BuildFlavor

/** How this install of the app is updated from inside the app. */
enum class Updater {
    /** Not from inside the app: a store build, or a Microsoft Store (MSIX) install, whose package the Store owns. */
    NONE,

    /**
     * The platform's own updater downloads and installs the update: Sparkle in the Mac's DMG install, the installer
     * updater in a Windows copy installed by Plezy's installer.
     */
    NATIVE,

    /** The check of the latest GitHub release ([AppUpdates]), whose dialog opens the release's page. */
    GITHUB,
}

/** Where the running app is installed, as far as its updater depends on it. */
sealed interface Installation {
    /**
     * Windows: the executable's path, whether Plezy's installer's uninstaller (`unins000.exe`) is beside it, and
     * whether the installer's `.winget` marker is (an install made by WinGet, which updates it).
     */
    data class Windows(val executablePath: String, val hasUninstaller: Boolean, val hasWingetMarker: Boolean) : Installation

    /** macOS: the app bundle's path. */
    data class Mac(val bundlePath: String) : Installation

    /** Linux, Android, iOS: the GitHub check is the only updater there. */
    data object Other : Installation
}

/**
 * The updater of [installation] in a [flavor] build. Only the GitHub release's builds ([BuildFlavor.SIDELOADED]) update
 * themselves, and never inside an MSIX package (its executable is under `\WindowsApps\`). Of those, the Mac uses Sparkle
 * unless Homebrew installed it (the bundle under `/Caskroom/` or `/homebrew/`), and Windows its installer updater in a
 * copy Plezy's installer installed (the uninstaller beside the executable) unless WinGet did; everything else (Linux, a
 * portable Windows copy, a Homebrew or WinGet install, Android's APKs, the IPA) checks the GitHub release.
 */
fun updaterFor(flavor: BuildFlavor, installation: Installation): Updater {
    if (flavor != BuildFlavor.SIDELOADED) return Updater.NONE
    return when (installation) {
        is Installation.Windows -> when {
            "\\windowsapps\\" in installation.executablePath.lowercase() -> Updater.NONE
            installation.hasUninstaller && !installation.hasWingetMarker -> Updater.NATIVE
            else -> Updater.GITHUB
        }
        is Installation.Mac ->
            if ("/Caskroom/" in installation.bundlePath || "/homebrew/" in installation.bundlePath) Updater.GITHUB else Updater.NATIVE
        Installation.Other -> Updater.GITHUB
    }
}
