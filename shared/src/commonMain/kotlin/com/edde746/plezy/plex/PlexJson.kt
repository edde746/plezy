package com.edde746.plezy.plex

import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.doubleOrNull
import kotlinx.serialization.json.longOrNull

/*
 * Tolerant readers for Plex JSON. Plex (and plex.tv) send the same field as a number, a numeric string or a boolean
 * depending on server version and the XML-to-JSON path, and a one-element list as a bare object.
 */

/** A number (truncated) or a decimal string; anything else is null. */
internal fun JsonElement?.flexInt(): Int? = flexLong()?.toInt()

internal fun JsonElement?.flexLong(): Long? {
    val p = this as? JsonPrimitive ?: return null
    if (p is JsonNull) return null
    if (p.isString) return p.content.toLongOrNull()
    p.longOrNull?.let { return it }
    return p.doubleOrNull?.toLong()
}

internal fun JsonElement?.flexDouble(): Double? {
    val p = this as? JsonPrimitive ?: return null
    if (p is JsonNull) return null
    if (p.isString) return p.content.toDoubleOrNull()
    return p.doubleOrNull
}

/** `true`, `1`, `"1"` or `"true"` (any case); anything else, null included, is false. */
internal fun JsonElement?.flexBool(): Boolean = flexBoolOrNull() ?: false

/** As [flexBool], but null when the value is missing or not a boolean, number or string. */
internal fun JsonElement?.flexBoolOrNull(): Boolean? {
    val p = this as? JsonPrimitive ?: return null
    if (p is JsonNull) return null
    if (p.isString) return p.content == "1" || p.content.equals("true", ignoreCase = true)
    p.booleanOrNull?.let { return it }
    return p.longOrNull?.let { it == 1L }
}

/** A string as is; a number or boolean as its text; anything else null. */
internal fun JsonElement?.scalarString(): String? {
    val p = this as? JsonPrimitive ?: return null
    if (p is JsonNull) return null
    return p.content
}

/** Only a JSON string. */
internal fun JsonElement?.stringOrNull(): String? {
    val p = this as? JsonPrimitive ?: return null
    return if (p.isString) p.content else null
}

/** The object entries of a value that may be one object, a list of mixed values or null. */
internal fun JsonElement?.objectList(): List<JsonObject> = when (this) {
    is JsonObject -> listOf(this)
    is JsonArray -> filterIsInstance<JsonObject>()
    else -> emptyList()
}

internal fun JsonElement?.firstObject(): JsonObject? = objectList().firstOrNull()

/** `MediaContainer` of a Plex response body, or null when the body is not an object holding an object there. */
internal fun JsonElement?.mediaContainer(): JsonObject? = (this as? JsonObject)?.get("MediaContainer") as? JsonObject
