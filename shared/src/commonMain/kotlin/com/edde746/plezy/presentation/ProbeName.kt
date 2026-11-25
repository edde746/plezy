package com.edde746.plezy.presentation

/**
 * An enum entry's name in test ids and accessibility identifiers: its name in camel case (`MARK_WATCHED` is
 * `markWatched`). Compose names its elements with it and Swift reads it on the entry's Kotlin class
 * (`(section as __SettingsSection).probeName`), so both UIs give an element one name.
 */
val Enum<*>.probeName: String
    get() = name.lowercase().split('_').mapIndexed { index, word -> if (index == 0) word else word.replaceFirstChar(Char::uppercaseChar) }.joinToString("")
