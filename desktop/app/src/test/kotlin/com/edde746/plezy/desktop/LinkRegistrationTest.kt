package com.edde746.plezy.desktop

import java.io.File
import java.nio.file.Files
import java.nio.file.Path
import kotlin.io.path.createFile
import kotlin.io.path.invariantSeparatorsPathString
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/**
 * Which copies of the app register `plezy://` themselves (only the app image run as it is: the packages register it),
 * and what they register: the launcher with the link as one quoted argument.
 */
class LinkRegistrationTest {
    @Test
    fun onlyAPortableWindowsCopyRegistersItself() {
        val folder = Files.createTempDirectory("plezy-portable")
        val launcher = folder.resolve("Plezy.exe")
        assertTrue(LinkRegistration.isPortableWindowsCopy(launcher))
        assertFalse(LinkRegistration.isPortableWindowsCopy(Path.of("C:\\Program Files\\WindowsApps\\Plezy_1.0_x64\\Plezy.exe")))
        folder.resolve("unins000.exe").createFile()
        assertFalse(LinkRegistration.isPortableWindowsCopy(launcher))
    }

    @Test
    fun onlyALinuxCopyOutsideThePackagesRegistersItself() {
        val tarball = Path.of("/home/me/Plezy/bin/Plezy")
        assertTrue(LinkRegistration.isPortableLinuxCopy(tarball, emptyMap()))
        assertFalse(LinkRegistration.isPortableLinuxCopy(tarball, mapOf("FLATPAK_ID" to "com.edde746.plezy")))
        assertFalse(LinkRegistration.isPortableLinuxCopy(tarball, mapOf("APPIMAGE" to "/home/me/Plezy.AppImage")))
        assertFalse(LinkRegistration.isPortableLinuxCopy(Path.of("/opt/plezy/bin/Plezy"), emptyMap()))
    }

    @Test
    fun theLinkReachesTheLauncherAsOneArgument() {
        assertEquals("\"C:\\Users\\me\\Plezy\\Plezy.exe\" \"%1\"", LinkRegistration.windowsCommand(Path.of("C:\\Users\\me\\Plezy\\Plezy.exe")))
        val desktop = LinkRegistration.linuxDesktopFile(Path.of("/home/me/My Apps/Plezy/bin/Plezy"))
        assertTrue("Exec=\"/home/me/My Apps/Plezy/bin/Plezy\" %u\n" in desktop, desktop)
        assertTrue("MimeType=x-scheme-handler/plezy;\n" in desktop, desktop)
        assertTrue("NoDisplay=true\n" in desktop, desktop)
    }

    @Test
    fun aTarballLinkStartsPlezyShWithTheLink() {
        val root = Files.createTempDirectory("plezy-tarball").resolve("Plezy")
        val launcher = Files.createDirectories(root.resolve("bin")).resolve("Plezy").createFile()
        root.resolve("plezy.sh").createFile()
        assertEquals(listOf(root.resolve("plezy.sh").invariantSeparatorsPathString, LINK), exec(LinkRegistration.linuxDesktopFile(launcher)))
    }

    @Test
    fun anExecPathWithSpecialCharactersParsesBackToThePath() {
        val paths = listOf("/home/me/100% \$HOME `x`/Plezy/bin/Plezy", "/home/me/%u/bin/Plezy") +
            if (File.separatorChar == '/') listOf("/home/me/a\\b \"c\"/bin/Plezy", "/home/me/\\\\\$\\%/bin/Plezy") else emptyList()
        for (path in paths) assertEquals(listOf(path, LINK), exec(LinkRegistration.linuxDesktopFile(Path.of(path))), path)
    }

    /** The `Exec` key of [desktop] as the Desktop Entry spec reads it, with [LINK] for `%u`. */
    private fun exec(desktop: String): List<String> {
        val raw = desktop.lines().single { it.startsWith("Exec=") }.removePrefix("Exec=")
        val value = buildString {
            var i = 0
            while (i < raw.length) {
                val c = raw[i++]
                if (c != '\\') append(c) else when (val e = raw[i++]) {
                    's' -> append(' ')
                    'n' -> append('\n')
                    't' -> append('\t')
                    'r' -> append('\r')
                    else -> append(e)
                }
            }
        }
        val args = mutableListOf<String>()
        var i = 0
        while (i < value.length) {
            if (value[i] == ' ') { i++; continue }
            val arg = StringBuilder()
            if (value[i] == '"') {
                i++
                while (value[i] != '"') {
                    if (value[i] == '\\') i++
                    arg.append(value[i++])
                }
                i++
            } else {
                while (i < value.length && value[i] != ' ') arg.append(value[i++])
            }
            args += arg.toString()
        }
        return args.map { it.replace(Regex("%[%u]")) { m -> if (m.value == "%%") "%" else LINK } }
    }

    private companion object {
        const val LINK = "plezy://play?x=1"
    }
}
