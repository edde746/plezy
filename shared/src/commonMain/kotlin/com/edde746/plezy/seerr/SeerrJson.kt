package com.edde746.plezy.seerr

import kotlinx.serialization.SerializationException
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.doubleOrNull

/** Tolerant reads of Seerr's JSON: a missing, null or wrongly typed field reads as null. */
internal fun JsonObject.str(key: String): String? = (this[key] as? JsonPrimitive)?.takeIf { it.isString }?.content

/** A JSON number as an int (a fraction truncated, as the web UI's `Number` would be). */
internal fun JsonObject.int(key: String): Int? = this[key].number()?.toInt()

internal fun JsonObject.long(key: String): Long? = this[key].number()?.toLong()

internal fun JsonObject.double(key: String): Double? = this[key].number()

internal fun JsonObject.bool(key: String): Boolean? =
    (this[key] as? JsonPrimitive)?.takeIf { !it.isString && it !is JsonNull }?.booleanOrNull

internal fun JsonObject.obj(key: String): JsonObject? = this[key] as? JsonObject

/** The object entries of the array at [key], each decoded by [decode]; null when it isn't an array. */
internal fun <T> JsonObject.objects(key: String, decode: (JsonObject) -> T?): List<T>? =
    (this[key] as? JsonArray)?.mapNotNull { (it as? JsonObject)?.let(decode) }

/** The string entries of the array at [key]; null when it isn't an array. */
internal fun JsonObject.strings(key: String): List<String>? =
    (this[key] as? JsonArray)?.mapNotNull { (it as? JsonPrimitive)?.takeIf { p -> p.isString }?.content }

/** The number entries of the array at [key], as ints; null when it isn't an array. */
internal fun JsonObject.ints(key: String): List<Int>? = (this[key] as? JsonArray)?.mapNotNull { it.number()?.toInt() }

private fun JsonElement?.number(): Double? =
    (this as? JsonPrimitive)?.takeIf { !it.isString && it !is JsonNull }?.doubleOrNull

/** [text] as JSON; null when it is empty or isn't JSON (an HTML login page, a proxy's plain-text error). */
internal fun parseJsonOrNull(text: String): JsonElement? = if (text.isBlank()) null else try {
    Json.parseToJsonElement(text)
} catch (_: SerializationException) {
    null
}
