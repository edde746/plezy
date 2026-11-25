package com.edde746.plezy.trackers.client

import com.edde746.plezy.model.ExternalIds
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonObjectBuilder
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.doubleOrNull
import kotlinx.serialization.json.longOrNull
import kotlinx.serialization.json.put

/*
 * Lenient readers for tracker answers: services disagree on whether an id is a number or
 * a numeric string (Simkl sends every external id as a string), and a field of the wrong type reads as absent.
 */

internal val JsonElement?.obj: JsonObject? get() = this as? JsonObject

internal val JsonElement?.arr: JsonArray? get() = this as? JsonArray

/** The objects of an array; anything else in it is skipped. */
internal val JsonElement?.objects: List<JsonObject> get() = arr?.mapNotNull { it as? JsonObject }.orEmpty()

/** A string, or `null` for any other value. */
internal val JsonElement?.string: String?
    get() = (this as? JsonPrimitive)?.takeIf { it.isString }?.content

/** A whole number from a JSON number or a numeric string (`12`, `"12"`, `12.0`). */
internal val JsonElement?.flexibleLong: Long?
    get() {
        val p = this as? JsonPrimitive ?: return null
        if (p is JsonNull) return null
        return p.longOrNull ?: p.doubleOrNull?.takeIf { it == kotlin.math.floor(it) }?.toLong() ?: p.content.trim().toLongOrNull()
    }

internal val JsonElement?.flexibleInt: Int? get() = flexibleLong?.takeIf { it in Int.MIN_VALUE..Int.MAX_VALUE }?.toInt()

internal val JsonElement?.flexibleDouble: Double?
    get() = (this as? JsonPrimitive)?.takeUnless { it is JsonNull }?.let { it.doubleOrNull ?: it.content.trim().toDoubleOrNull() }

/** `true`, `"true"`, `1`; anything else is false. */
internal val JsonElement?.flexibleBool: Boolean
    get() {
        val p = this as? JsonPrimitive ?: return false
        return p.booleanOrNull ?: (p.content == "1" || p.content.equals("true", ignoreCase = true))
    }

internal fun JsonObjectBuilder.putIfNotNull(key: String, value: String?) {
    if (value != null) put(key, value)
}

internal fun JsonObjectBuilder.putIfNotNull(key: String, value: Number?) {
    if (value != null) put(key, value)
}

/** `{"imdb": …, "tmdb": …, "tvdb": …}` with the ids [ids] has: the id block Trakt takes. */
internal fun ExternalIds.toJson(): JsonObject = buildJsonObject {
    putIfNotNull("imdb", imdb)
    putIfNotNull("tmdb", tmdb)
    putIfNotNull("tvdb", tvdb)
}
