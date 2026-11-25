package com.edde746.plezy.ui

import java.io.File

/**
 * The interface's languages, as `T.locale` tags (`pt-BR`): one per file in shared/i18n/, read from the module's folder
 * (Gradle's working directory for its tests), sorted.
 */
internal val interfaceLanguages: List<String> by lazy {
    val folder = File("../shared/i18n")
    val files = folder.listFiles { file -> file.name.endsWith(".i18n.json") }
    check(!files.isNullOrEmpty()) { "no interface languages in ${folder.canonicalPath}" }
    files.map { it.name.removeSuffix(".i18n.json") }.sorted()
}
