package com.edde746.plezy.desktop

import com.edde746.plezy.desktop.windows.WindowsRegistry
import com.edde746.plezy.log.Log
import java.io.IOException
import java.nio.file.Files
import java.nio.file.Path
import kotlin.io.path.invariantSeparatorsPathString

/**
 * Registers Plezy with the OS as the app that opens `plezy://` links, where no package did: the OS then starts the app
 * with the link as its last argument ([Cli.link]), and a start while Plezy runs hands it to the running app
 * ([SingleInstance]).
 *
 * The packages register the scheme themselves: the MSIX in its manifest, the Windows installer in the registry, the
 * Linux packages (deb, rpm, pacman, AppImage, Flatpak) in their desktop file. What is left is a copy of the app image
 * run as it is (the Windows portable zip, the Linux tarball), which registers itself at every start, so a moved copy
 * points the links at its new place:
 * - Windows: `HKCU\Software\Classes\plezy` as a URL protocol whose `shell\open\command` runs this launcher with the link;
 *   skipped for an MSIX (under `WindowsApps`) and an installed copy (its uninstaller beside it).
 * - Linux: `~/.local/share/applications/plezy-url-handler.desktop` (`MimeType=x-scheme-handler/plezy`, hidden from
 *   menus) made the default handler with `xdg-mime`; skipped in a Flatpak, an AppImage and a package's `/opt/plezy`.
 *
 * Only the app image's launcher is registered (`jpackage.app-path`), or on Linux the tarball's `plezy.sh` beside its
 * `bin/`, which finds the libraries libmpv needs; a run from class directories (a development run) registers nothing.
 */
internal object LinkRegistration {
    private const val TAG = "LinkRegistration"
    private const val SCHEME = "plezy"

    fun register() {
        val launcher = System.getProperty("jpackage.app-path")?.let(Path::of) ?: return
        val os = System.getProperty("os.name")
        try {
            when {
                os.startsWith("Windows") -> if (isPortableWindowsCopy(launcher)) registerWindows(launcher)
                os.startsWith("Linux") -> if (isPortableLinuxCopy(launcher, System.getenv())) registerLinux(launcher)
            }
        } catch (e: Exception) {
            Log.w(TAG, e) { "Registering the plezy:// links failed" }
        }
    }

    /** A Windows app image run as it is: neither the MSIX's nor one the installer put there. */
    fun isPortableWindowsCopy(launcher: Path): Boolean =
        !launcher.toString().lowercase().contains("\\windowsapps\\") && !Files.exists(launcher.resolveSibling("unins000.exe"))

    /** A Linux app image run as it is: not in a Flatpak or an AppImage, not a package's `/opt/plezy`. */
    fun isPortableLinuxCopy(launcher: Path, env: Map<String, String>): Boolean =
        env["FLATPAK_ID"].isNullOrEmpty() && env["APPIMAGE"].isNullOrEmpty() &&
            !launcher.normalize().invariantSeparatorsPathString.startsWith("/opt/plezy/")

    /** The `shell\open\command` of the Windows URL protocol: the launcher, then the link, each quoted. */
    fun windowsCommand(launcher: Path): String = "\"$launcher\" \"%1\""

    /**
     * The desktop file of the Linux link handler for [launcher] (`bin/Plezy`): it runs the `plezy.sh` beside `bin/` when
     * there is one. The path is quoted and escaped as the Desktop Entry spec's `Exec` key wants it.
     */
    fun linuxDesktopFile(launcher: Path): String {
        val target = launcher.parent?.resolveSibling("plezy.sh")?.takeIf(Files::isRegularFile) ?: launcher
        val quoted = target.invariantSeparatorsPathString.replace(Regex("""[\\"`$]"""), """\\$0""").replace("%", "%%")
        val exec = "\"$quoted\" %u".replace("\\", "\\\\")
        return """
            |[Desktop Entry]
            |Type=Application
            |Name=Plezy
            |Exec=$exec
            |MimeType=x-scheme-handler/$SCHEME;
            |NoDisplay=true
            |Terminal=false
            |
        """.trimMargin()
    }

    private fun registerWindows(launcher: Path) {
        val root = WindowsRegistry.Root.CURRENT_USER
        val key = "Software\\Classes\\$SCHEME"
        if (WindowsRegistry.string(root, "$key\\shell\\open\\command", "") == windowsCommand(launcher)) return
        fun write(path: String, value: String, data: String) = check(WindowsRegistry.setString(root, path, value, data)) { "Couldn't write $path" }
        write(key, "", "URL:Plezy")
        write(key, "URL Protocol", "")
        write("$key\\DefaultIcon", "", "\"$launcher\",0")
        write("$key\\shell\\open\\command", "", windowsCommand(launcher))
        Log.i(TAG) { "Registered plezy:// links" }
    }

    private fun registerLinux(launcher: Path) {
        val dataHome = System.getenv("XDG_DATA_HOME")?.takeIf { it.isNotEmpty() }?.let(Path::of)
            ?: Path.of(System.getProperty("user.home"), ".local", "share")
        val applications = dataHome.resolve("applications")
        val file = applications.resolve("plezy-url-handler.desktop")
        val content = linuxDesktopFile(launcher)
        if (Files.isRegularFile(file) && Files.readString(file) == content) return
        Files.createDirectories(applications)
        Files.writeString(file, content)
        try {
            val process = ProcessBuilder("xdg-mime", "default", file.fileName.toString(), "x-scheme-handler/$SCHEME")
                .redirectErrorStream(true).redirectOutput(ProcessBuilder.Redirect.DISCARD).start()
            if (process.waitFor() != 0) Log.w(TAG) { "xdg-mime refused the plezy:// handler: ${process.exitValue()}" }
        } catch (e: IOException) {
            Log.w(TAG) { "No xdg-mime to make Plezy open plezy:// links: ${e.message}" }
        }
        Log.i(TAG) { "Registered plezy:// links" }
    }
}
