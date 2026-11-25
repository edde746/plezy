package com.edde746.plezy.crash

/** The system's family, then its name and version as the JVM reads them: `windows Windows 11 10.0`, `linux Linux 6.8.0`. */
internal actual fun osDescription(): String {
    val name = System.getProperty("os.name").orEmpty()
    val family = when {
        name.startsWith("Windows") -> "windows"
        name.startsWith("Mac") -> "macos"
        else -> name.lowercase()
    }
    return "$family $name ${System.getProperty("os.version")}"
}
