package com.edde746.plezy.plex

import kotlinx.serialization.json.JsonObject

private val SECTION_PATH = Regex("""/(?:library|hubs)/sections/(\d+)""")
private val SECTION_QUERY = Regex("""[?&](?:librarySectionID|sectionID)=(\d+)""")

/**
 * The library section a Plex row names: `librarySectionID` / `targetLibrarySectionID`, else parsed from
 * `librarySectionKey`, `key` or `hubKey` ([plexLibrarySectionIdFromString]).
 */
fun plexLibrarySectionIdFromJson(json: JsonObject?): Int? {
    if (json == null) return null
    (json["librarySectionID"].flexInt() ?: json["targetLibrarySectionID"].flexInt())?.let { return it }
    for (key in listOf("librarySectionKey", "key", "hubKey")) {
        plexLibrarySectionIdFromString(json[key].scalarString())?.let { return it }
    }
    return null
}

/** A plain number, a `/library|hubs/sections/N` path or a `librarySectionID=`/`sectionID=` query; `shared` is none. */
fun plexLibrarySectionIdFromString(value: String?): Int? {
    if (value == null || value == "shared") return null
    value.toIntOrNull()?.let { return it }
    SECTION_PATH.find(value)?.let { return it.groupValues[1].toIntOrNull() }
    return SECTION_QUERY.find(value)?.groupValues?.get(1)?.toIntOrNull()
}

fun plexLibrarySectionTitleFromJson(json: JsonObject?): String? = json?.get("librarySectionTitle").scalarString()
