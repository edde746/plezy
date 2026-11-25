package com.edde746.plezy.catalog

import com.edde746.plezy.model.asBooleanOrNull
import com.edde746.plezy.model.asStringOrNull
import kotlin.time.Instant
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonObjectBuilder
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.put

// Catalog objects round-trip through `MediaItem.raw` within one session. Null fields are omitted; a value of the wrong
// JSON type reads as missing.

/** A catalog enum whose [id] is its JSON name. */
interface CatalogWireEnum {
    val id: String
}

/** The entry of [E] whose [CatalogWireEnum.id] is exactly [id]; null for anything else. */
inline fun <reified E> catalogEnumOf(id: String?): E? where E : Enum<E>, E : CatalogWireEnum =
    if (id == null) null else enumValues<E>().firstOrNull { it.id == id }

/**
 * The objects of a JSON list that [decode] accepts; null when [raw] is not a list or nothing survives. Non-object
 * entries and entries [decode] rejects are dropped without failing their siblings.
 */
fun <T : Any> decodeCatalogList(raw: JsonElement?, decode: (JsonObject) -> T?): List<T>? {
    if (raw !is JsonArray) return null
    return raw.mapNotNull { (it as? JsonObject)?.let(decode) }.ifEmpty { null }
}

/**
 * An ISO-8601 instant; a value without an offset reads as UTC and a bare `YYYY-MM-DD` as UTC midnight. Null when
 * missing, blank or unparseable.
 */
fun parseCatalogInstant(raw: String?): Instant? {
    val value = raw?.trim()
    if (value.isNullOrEmpty()) return null
    return Instant.parseOrNull(value) ?: Instant.parseOrNull(value + "Z") ?: Instant.parseOrNull(value + "T00:00:00Z")
}

internal fun JsonObject.catalogString(key: String): String? = this[key].asStringOrNull

internal fun JsonObject.catalogInt(key: String): Int? = number(key)?.toIntOrNull()

internal fun JsonObject.catalogLong(key: String): Long? = number(key)?.toLongOrNull()

internal fun JsonObject.catalogDouble(key: String): Double? = number(key)?.toDoubleOrNull()

internal fun JsonObject.catalogBool(key: String): Boolean? = this[key].asBooleanOrNull

internal fun JsonObject.catalogObject(key: String): JsonObject? = this[key] as? JsonObject

internal fun JsonObject.catalogStrings(key: String): List<String>? = (this[key] as? JsonArray)?.mapNotNull { it.asStringOrNull }

internal fun JsonObject.catalogInstant(key: String): Instant? = parseCatalogInstant(catalogString(key))

internal inline fun <reified E> JsonObject.catalogEnum(key: String): E? where E : Enum<E>, E : CatalogWireEnum =
    catalogEnumOf<E>(catalogString(key))

private fun JsonObject.number(key: String): String? = (this[key] as? JsonPrimitive)?.takeIf { !it.isString }?.content

internal fun JsonObjectBuilder.putOpt(key: String, value: String?) {
    if (value != null) put(key, value)
}

internal fun JsonObjectBuilder.putOpt(key: String, value: Number?) {
    if (value != null) put(key, value)
}

internal fun JsonObjectBuilder.putOpt(key: String, value: Boolean?) {
    if (value != null) put(key, value)
}

internal fun JsonObjectBuilder.putOpt(key: String, value: JsonElement?) {
    if (value != null) put(key, value)
}

internal fun JsonObjectBuilder.putOpt(key: String, value: CatalogWireEnum?) {
    if (value != null) put(key, value.id)
}

internal fun JsonObjectBuilder.putOpt(key: String, value: Instant?) {
    if (value != null) put(key, value.toString())
}

internal fun JsonObjectBuilder.putStrings(key: String, values: List<String>?) {
    if (values != null) put(key, JsonArray(values.map(::JsonPrimitive)))
}

internal fun <T> JsonObjectBuilder.putObjects(key: String, values: List<T>?, toJson: (T) -> JsonObject) {
    if (values != null) put(key, JsonArray(values.map(toJson)))
}
