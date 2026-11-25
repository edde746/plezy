package com.edde746.plezy.desktop.players

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/**
 * What a player on Windows gets of each argument: a Windows program gets one command line, which the JDK writes from
 * the argument list ([jdkCommandLine]) and the program splits back itself ([windowsArgv]).
 */
class WindowsCommandLineTest {
    private val playExe = "C:\\My Tools\\play.exe"

    @Test
    fun everyArgumentReachesTheProgramWhole() {
        // What a URL can hold: quotes, backslashes before them and at the end, spaces, options.
        val texts = listOf(
            "https://cdn.example/v/a b.mkv?t=\"k\"\\", "http://srv/v.mkv?X-Plex-Token=t&download=1",
            "", "\"", "\"\"", "a\"b", "\"quoted\"", "Say \"Hi\" now", "\" --script=evil.lua \"", "\\", "\\\\", "C:\\subs\\",
            "C:\\My Subs\\\\", "\\\\nas\\share", "a\\\"b", "a\\\\\"b c", "x\\\\\\\" y", " leading and trailing ", "tab\there\nline",
            "é \"ü\" 中",
        )
        for (text in texts) {
            assertEquals(listOf(playExe, text), windowsArgv(jdkCommandLine(listOf(playExe, windowsArgument(text)))), text)
        }
    }

    @Test
    fun batchFilesAreToldApart() {
        // cmd.exe would run a batch file with the URL's & as its own commands: it isn't started.
        for (program in listOf("C:\\tools\\play.bat", "C:\\tools\\WRAP.CMD", "C:\\tools\\play.bat.", "play.cmd ")) {
            assertTrue(DesktopSystem.isBatchFile(program), program)
        }
        for (program in listOf("C:\\bin\\play.exe", "vlc", "C:\\bat\\mpv.exe")) assertFalse(DesktopSystem.isBatchFile(program), program)
    }

    /**
     * The command line the JDK's Windows `ProcessImpl` writes for [command] in its default mode
     * (`jdk.lang.Process.allowAmbiguousCommands` unset), from OpenJDK 25's source: the program and each argument with
     * whitespace, or empty, in quotes, an argument's trailing backslashes doubled and nothing else escaped; an argument
     * that starts and ends with a quote, and any other, as it is.
     */
    private fun jdkCommandLine(command: List<String>): String {
        fun quoted(text: String) = text.length >= 2 && text.startsWith('"') && text.endsWith('"')
        fun needsQuotes(text: String) = text.isEmpty() || (!quoted(text) && text.any { Character.isSpaceChar(it) || Character.isWhitespace(it) })
        val program = command.first().let { if (needsQuotes(it)) "\"$it\"" else it }
        val arguments = command.drop(1).map { argument ->
            if (!needsQuotes(argument)) argument else "\"" + argument + "\\".repeat(argument.length - argument.trimEnd('\\').length) + "\""
        }
        return (listOf(program) + arguments).joinToString(" ")
    }

    /**
     * [commandLine] split into arguments as a Windows program's C runtime does (Microsoft's "Parsing C command-line
     * arguments"; `CommandLineToArgvW`, which mpv and VLC call, differs only in a `""` inside quotes): the program up to
     * whitespace, its quotes grouping; then arguments at spaces and tabs outside quotes, where 2n backslashes and a `"`
     * are n backslashes and a quote that opens or closes, 2n+1 backslashes and a `"` are n backslashes and a `"`, other
     * backslashes are themselves, and `""` inside quotes is a `"`.
     */
    private fun windowsArgv(commandLine: String): List<String> {
        fun blank(c: Char) = c == ' ' || c == '\t'
        val argv = mutableListOf<String>()
        var i = 0
        val program = StringBuilder()
        var inQuotes = false
        while (i < commandLine.length && (inQuotes || !blank(commandLine[i]))) {
            if (commandLine[i] == '"') inQuotes = !inQuotes else program.append(commandLine[i])
            i++
        }
        argv += program.toString()
        while (true) {
            while (i < commandLine.length && blank(commandLine[i])) i++
            if (i == commandLine.length) return argv
            val argument = StringBuilder()
            inQuotes = false
            while (i < commandLine.length && (inQuotes || !blank(commandLine[i]))) {
                val c = commandLine[i]
                when {
                    c == '\\' -> {
                        var end = i
                        while (end < commandLine.length && commandLine[end] == '\\') end++
                        val count = end - i
                        if (end < commandLine.length && commandLine[end] == '"') {
                            repeat(count / 2) { argument.append('\\') }
                            // An odd one escapes the quote; after an even number the quote is read next.
                            if (count % 2 == 1) argument.append('"')
                            i = if (count % 2 == 1) end + 1 else end
                        } else {
                            repeat(count) { argument.append('\\') }
                            i = end
                        }
                    }
                    c == '"' && inQuotes && i + 1 < commandLine.length && commandLine[i + 1] == '"' -> {
                        argument.append('"')
                        i += 2
                    }
                    c == '"' -> {
                        inQuotes = !inQuotes
                        i++
                    }
                    else -> {
                        argument.append(c)
                        i++
                    }
                }
            }
            argv += argument.toString()
        }
    }
}
