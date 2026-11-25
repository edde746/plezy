package com.edde746.plezy.desktop.updates

import com.edde746.plezy.ui.updates.PlatformUpdates
import com.edde746.plezy.updates.Installation
import io.ktor.client.HttpClient
import java.nio.file.Files
import java.nio.file.Path

/**
 * The product app's updates on this desktop: on Windows, where the running executable is installed, and with this
 * build's number ([build], null when the app runs from class directories) the installer updater ([WindowsUpdater]) over
 * [http], ending the app with [exit]; elsewhere (Linux) the GitHub release check alone.
 */
internal fun desktopUpdates(http: HttpClient, build: Long?, exit: () -> Unit): PlatformUpdates {
    if (!System.getProperty("os.name").startsWith("Windows")) return PlatformUpdates(Installation.Other)
    val executable = Path.of(ProcessHandle.current().info().command().orElseThrow())
    val folder = executable.parent
    val installation = Installation.Windows(
        executablePath = executable.toString(),
        hasUninstaller = Files.exists(folder.resolve("unins000.exe")),
        hasWingetMarker = Files.exists(folder.resolve(".winget")),
    )
    val installer = build?.let {
        WindowsUpdater(
            http = http,
            currentBuild = it,
            feedUrl = WindowsUpdater.FEED_URL,
            publicKey = UpdateSignature.PUBLIC_KEY,
            directory = Path.of(System.getProperty("java.io.tmpdir"), "plezy-update"),
            start = WindowsUpdater::startDetached,
            exit = exit,
        )
    }
    return PlatformUpdates(installation, installer)
}
