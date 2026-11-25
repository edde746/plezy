package com.edde746.plezy.jellyfin

import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.doubleOrNull
import kotlinx.serialization.json.longOrNull

/** Tolerant reads of `BaseItemDto`-shaped JSON: a missing or wrongly typed field reads as null. */
internal fun JsonObject.str(key: String): String? = (this[key] as? JsonPrimitive)?.takeIf { it.isString }?.content

internal fun JsonObject.long(key: String): Long? = (this[key] as? JsonPrimitive)?.takeIf { !it.isString }?.let { it.longOrNull ?: it.doubleOrNull?.toLong() }

internal fun JsonObject.int(key: String): Int? = long(key)?.toInt()

internal fun JsonObject.double(key: String): Double? = (this[key] as? JsonPrimitive)?.takeIf { !it.isString }?.doubleOrNull

internal fun JsonObject.bool(key: String): Boolean? = (this[key] as? JsonPrimitive)?.takeIf { !it.isString }?.booleanOrNull

internal fun JsonObject.obj(key: String): JsonObject? = this[key] as? JsonObject

internal fun JsonObject.array(key: String): JsonArray? = this[key] as? JsonArray

/** The object elements of the array at [key]; other elements are skipped. */
internal fun JsonObject.objects(key: String): List<JsonObject> = array(key)?.filterIsInstance<JsonObject>().orEmpty()

/** The string elements of the array at [key]. */
internal fun JsonObject.strings(key: String): List<String>? =
    array(key)?.mapNotNull { (it as? JsonPrimitive)?.takeIf { p -> p.isString }?.content }

/** An int from a number or a numeric string (`"42"`), as servers send both. */
internal fun JsonElement?.flexibleLong(): Long? = (this as? JsonPrimitive)?.let { it.longOrNull ?: it.doubleOrNull?.toLong() ?: it.content.toLongOrNull() }
