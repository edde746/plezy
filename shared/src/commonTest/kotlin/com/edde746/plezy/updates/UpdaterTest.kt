package com.edde746.plezy.updates

import com.edde746.plezy.app.BuildFlavor
import kotlin.test.Test
import kotlin.test.assertEquals

class UpdaterTest {
    private val installedWindows = Installation.Windows("C:\\Users\\me\\AppData\\Local\\Programs\\Plezy\\Plezy.exe", hasUninstaller = true, hasWingetMarker = false)

    @Test
    fun `only the builds of the GitHub release update themselves`() {
        for (flavor in listOf(BuildFlavor.STORE, BuildFlavor.AMAZON)) {
            assertEquals(Updater.NONE, updaterFor(flavor, Installation.Other))
            assertEquals(Updater.NONE, updaterFor(flavor, Installation.Mac("/Applications/Plezy.app")))
            assertEquals(Updater.NONE, updaterFor(flavor, installedWindows))
        }
        assertEquals(Updater.GITHUB, updaterFor(BuildFlavor.SIDELOADED, Installation.Other))
    }

    @Test
    fun `an MSIX install never updates itself whatever the case of its letters`() {
        val msix = "C:\\Program Files\\WindowsApps\\edde746.Plezy_2.26.0.0_x64__abc\\Plezy.exe"
        assertEquals(Updater.NONE, updaterFor(BuildFlavor.SIDELOADED, Installation.Windows(msix, hasUninstaller = false, hasWingetMarker = false)))
        assertEquals(Updater.NONE, updaterFor(BuildFlavor.SIDELOADED, Installation.Windows(msix.uppercase(), hasUninstaller = true, hasWingetMarker = false)))
    }

    @Test
    fun `an installed Windows copy uses the installer updater unless WinGet installed it`() {
        assertEquals(Updater.NATIVE, updaterFor(BuildFlavor.SIDELOADED, installedWindows))
        assertEquals(Updater.GITHUB, updaterFor(BuildFlavor.SIDELOADED, installedWindows.copy(hasWingetMarker = true)))
        // A portable copy: no uninstaller beside it.
        assertEquals(Updater.GITHUB, updaterFor(BuildFlavor.SIDELOADED, installedWindows.copy(hasUninstaller = false)))
    }

    @Test
    fun `the Mac uses Sparkle unless Homebrew installed it`() {
        assertEquals(Updater.NATIVE, updaterFor(BuildFlavor.SIDELOADED, Installation.Mac("/Applications/Plezy.app")))
        assertEquals(Updater.GITHUB, updaterFor(BuildFlavor.SIDELOADED, Installation.Mac("/opt/homebrew/Caskroom/plezy/2.26.0/Plezy.app")))
        assertEquals(Updater.GITHUB, updaterFor(BuildFlavor.SIDELOADED, Installation.Mac("/usr/local/Caskroom/plezy/2.26.0/Plezy.app")))
        assertEquals(Updater.GITHUB, updaterFor(BuildFlavor.SIDELOADED, Installation.Mac("/opt/homebrew/Applications/Plezy.app")))
    }
}
