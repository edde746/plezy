package com.edde746.plezy.presentation.player

import java.io.File

/** Linux's resident set (`VmRSS` of `/proc/self/status`, in kB) in bytes; null where there is no such file. */
internal fun procResidentBytes(): Long? {
    val status = File("/proc/self/status").takeIf { it.canRead() } ?: return null
    val line = status.useLines { lines -> lines.firstOrNull { it.startsWith("VmRSS:") } } ?: return null
    return line.removePrefix("VmRSS:").trim().substringBefore(' ').toLongOrNull()?.times(1024)
}
