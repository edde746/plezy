package com.edde746.plezy.desktop

import java.nio.file.Path

/**
 * The desktop app's command line: the product (the device's database) with mpv's diagnostics and a `plezy://` link as
 * its last argument. The OS starts the app that way for a link the user opens (Windows' MSIX
 * protocol passes it alone as `"%1"`, the Linux .desktop file's `%u`), and the app follows it. Nothing may follow the
 * link, so a link with a `"` in it, which Windows would split into more arguments, can't add an option (`--mpv-opt`).
 * The test-only options (a dev session, the test report) are the harness launcher's (desktop/app/src/harness).
 */
internal data class Cli(
    /** mpv's debug log goes to this file (a later playback's next to it, numbered). */
    val mpvLog: Path? = null,
    /** Extra mpv options, by name. */
    val mpvOptions: Map<String, String> = emptyMap(),
    /** A `plezy://` link to hand to the app once it runs. */
    val link: String? = null,
) {
    class Error(message: String) : Exception(message)

    companion object {
        val USAGE = """
            usage: plezy [--mpv-log <file>] [--mpv-opt <name>=<value>]... [<plezy:// link>]
              <plezy:// link>
                            hand this link to the app once it runs (the OS passes the links it opens this way); the
                            last argument
              --mpv-log     write mpv's debug log, links redacted, to this file
              --mpv-opt     extra mpv option, repeatable (e.g. mute=yes)
        """.trimIndent()

        /**
         * Reads [args]. [testOption] is the harness launcher's (desktop/app/src/harness, TestOptions.kt): it takes a
         * test-only option [name] it knows, reading its value through `value`, and returns true; false for any other
         * argument. The product's main passes none, so a test-only option is an unknown argument there.
         */
        fun parse(args: Array<String>, testOption: (name: String, value: () -> String) -> Boolean = { _, _ -> false }): Cli {
            var mpvLog: Path? = null
            val mpvOptions = linkedMapOf<String, String>()
            var link: String? = null
            var i = 0
            fun value(name: String): String = args.getOrNull(++i) ?: throw Error("$name needs a value")
            while (i < args.size) {
                if (link != null) throw Error("nothing may follow the plezy:// link, got '${args[i]}'")
                when (val a = args[i]) {
                    "--mpv-log" -> mpvLog = Path.of(value(a))
                    "--mpv-opt" -> {
                        val kv = value(a)
                        val eq = kv.indexOf('=')
                        if (eq <= 0) throw Error("$a needs <name>=<value>, got '$kv'")
                        mpvOptions[kv.substring(0, eq)] = kv.substring(eq + 1)
                    }
                    else -> when {
                        testOption(a) { value(a) } -> Unit
                        a.startsWith("plezy:", ignoreCase = true) -> link = a
                        else -> throw Error("unknown argument '$a'")
                    }
                }
                i++
            }
            return Cli(mpvLog, mpvOptions, link)
        }
    }
}
