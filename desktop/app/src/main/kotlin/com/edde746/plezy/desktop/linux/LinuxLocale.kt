package com.edde746.plezy.desktop.linux

import java.util.Locale

/**
 * The system's languages as gettext takes them from [env], as BCP 47 tags, most preferred first: `LANGUAGE`'s list
 * (`en_US:es`; KDE Plasma writes the user's language list there), which gettext ignores while the messages locale
 * (`LC_ALL`, else `LC_MESSAGES`, else `LANG`) is C or POSIX; else [default], the JVM's locale, which holds one language.
 */
internal fun systemLanguages(env: Map<String, String>, default: Locale): List<String> {
    val messages = listOf("LC_ALL", "LC_MESSAGES", "LANG").firstNotNullOfOrNull { env[it]?.takeIf(String::isNotEmpty) }.orEmpty()
    val list = env["LANGUAGE"].orEmpty().split(':').map { it.substringBefore('.').substringBefore('@').replace('_', '-') }.filter { it.isNotEmpty() }
    return if (list.isEmpty() || messages.substringBefore('.') in setOf("", "C", "POSIX")) listOf(default.toLanguageTag()) else list
}
