package com.edde746.plezy.model

import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive

// Lenient readers for server JSON, where a number may arrive as a string (Plex's XML-to-JSON conversion), a boolean as
// 0/1, and a one-element list as the bare element. JSON `null` reads like a missing value everywhere.

private val JsonElement?.primitive: JsonPrimitive? get() = this as? JsonPrimitive

private val JsonElement?.isAbsent: Boolean get() = this == null || this is JsonNull

/** A string value's content; null for anything that isn't a JSON string. */
internal val JsonElement?.asStringOrNull: String? get() = primitive?.takeIf { it.isString }?.content

/** A JSON boolean's value; null for anything else (a `"true"` string included). */
internal val JsonElement?.asBooleanOrNull: Boolean?
    get() {
        val p = primitive?.takeIf { !it.isString && it !is JsonNull } ?: return null
        return when (p.content) {
            "true" -> true
            "false" -> false
            else -> null
        }
    }

/** A JSON number's value; null for strings, booleans and non-primitives. */
private val JsonElement?.numberOrNull: Double?
    get() {
        val p = primitive?.takeIf { !it.isString && it !is JsonNull } ?: return null
        if (p.content == "true" || p.content == "false") return null
        return p.content.toDoubleOrNull()
    }

/** A JSON number written without a fraction or exponent, as a whole number. */
private val JsonElement?.integerOrNull: Long?
    get() {
        val p = primitive?.takeIf { !it.isString && it !is JsonNull } ?: return null
        return p.content.toLongOrNull()
    }

/** A number (truncated) or a numeric string as a Long; null otherwise. */
fun flexibleLong(v: JsonElement?): Long? {
    val p = v.primitive ?: return null
    if (p.isString) return p.content.trim().toLongOrNull()
    if (p is JsonNull) return null
    return p.content.toLongOrNull() ?: v.numberOrNull?.toLong()
}

/** A number (truncated) or a numeric string as an Int; null otherwise. */
fun flexibleInt(v: JsonElement?): Int? = flexibleLong(v)?.toInt()

fun flexibleIntOrZero(v: JsonElement?): Int = flexibleInt(v) ?: 0

/** A number or a numeric string as a Double; null otherwise. */
fun flexibleDouble(v: JsonElement?): Double? {
    val p = v.primitive ?: return null
    if (p.isString) return p.content.trim().toDoubleOrNull()
    return v.numberOrNull
}

/** The value printed as a string (`42` → `"42"`); empty for missing or null. */
fun stringOrEmpty(v: JsonElement?): String = printed(v) ?: ""

private fun printed(v: JsonElement?): String? = when {
    v.isAbsent -> null
    v is JsonPrimitive -> v.content
    else -> v.toString()
}

/** `true`, `1`, `"1"` or `"true"` (any case) are true; everything else, null included, false. */
fun flexibleBool(v: JsonElement?): Boolean = flexibleBoolNullable(v) ?: false

/**
 * Like [flexibleBool], but null for a missing value or an unsupported non-string (a fractional number, an object).
 * Any string other than `"1"`/`"true"` is false.
 */
fun flexibleBoolNullable(v: JsonElement?): Boolean? {
    v.asBooleanOrNull?.let { return it }
    v.asStringOrNull?.let { return it == "1" || it.lowercase() == "true" }
    return v.integerOrNull?.let { it == 1L }
}

/** The field printed as a string: for string fields some endpoints send as numbers. Null when missing or null. */
fun readStringField(json: JsonObject, key: String): String? = printed(json[key])

/** A list as-is, a single value wrapped in a list, null for missing or null: Plex's one-or-many `Part` shape. */
fun flexibleList(v: JsonElement?): List<JsonElement>? = when {
    v.isAbsent -> null
    v is JsonArray -> v
    else -> listOf(v!!)
}

/** The JSON objects among one object, a mixed list, or nothing. */
fun flexibleMapList(value: JsonElement?): List<JsonObject> = flexibleList(value).orEmpty().filterIsInstance<JsonObject>()

/** The first JSON object of one object or a mixed list. */
fun firstFlexibleMap(value: JsonElement?): JsonObject? = flexibleList(value)?.firstNotNullOfOrNull { it as? JsonObject }

/** Every object [parse] accepts; a malformed row is dropped without discarding its siblings. */
fun <T> parseFlexibleJsonList(value: JsonElement?, parse: (JsonObject) -> T): List<T> =
    flexibleMapList(value).mapNotNull { json ->
        try {
            parse(json)
        } catch (_: Exception) {
            null
        }
    }

/** The first object parsed; null when there is none or [parse] rejects it. */
fun <T> parseFlexibleJsonObject(value: JsonElement?, parse: (JsonObject) -> T): T? {
    val json = firstFlexibleMap(value) ?: return null
    return try {
        parse(json)
    } catch (_: Exception) {
        null
    }
}

/** The strings of one string or a list (other elements dropped); null when none remain. */
fun flexibleStringList(v: JsonElement?): List<String>? =
    flexibleList(v)?.mapNotNull { it.asStringOrNull }?.takeIf { it.isNotEmpty() }

/**
 * Like [flexibleStringList], but each string is also split at commas, parts trimmed and blanks dropped. The Plex
 * account API sends profile language lists as CSV strings or as arrays.
 */
fun flexibleCsvStringList(v: JsonElement?): List<String>? =
    flexibleStringList(v)
        ?.flatMap { s -> s.split(',').map { it.trim() }.filter { it.isNotEmpty() } }
        ?.takeIf { it.isNotEmpty() }

/**
 * The strings of a JSON array; null when [raw] isn't one. With [mapKey], object elements contribute that field. With
 * [stringify], any non-null value is printed as a string; without, non-strings are dropped. [nullIfEmpty] turns an
 * empty result into null.
 */
fun stringListFromRaw(raw: JsonElement?, mapKey: String? = null, stringify: Boolean = false, nullIfEmpty: Boolean = false): List<String>? {
    if (raw !is JsonArray) return null
    val result = raw.mapNotNull { value ->
        val source = if (mapKey != null && value is JsonObject) value[mapKey] else value
        if (stringify) printed(source) else source.asStringOrNull
    }
    if (result.isEmpty() && nullIfEmpty) return null
    return result
}

fun <T> nullIfEmptyList(values: List<T>): List<T>? = values.ifEmpty { null }

/**
 * The first value not blank after trimming, trimmed. TMDB answers an untranslated field with an empty string rather
 * than omitting it, so a plain `?:` chain would pick the blank.
 */
fun firstNonBlank(values: Iterable<String?>): String? = values.firstNotNullOfOrNull { it?.trim()?.takeIf { t -> t.isNotEmpty() } }
