package com.edde746.plezy.importer

import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive

private val NUMBER = Regex("-?(0|[1-9][0-9]*)(\\.[0-9]+)?([eE][+-]?[0-9]+)?")

/**
 * Parses [text] as standard JSON, rejecting what Plezy's earlier releases' parser rejected. kotlinx's parser accepts
 * unquoted words where a value goes (`{"a": yes}`); those fail here, as they did there.
 */
internal fun parseStrictJson(text: String): JsonElement {
    val element = Json.parseToJsonElement(text)
    requireStandardLiterals(element)
    return element
}

private fun requireStandardLiterals(element: JsonElement) {
    when (element) {
        is JsonObject -> element.values.forEach(::requireStandardLiterals)
        is JsonArray -> element.forEach(::requireStandardLiterals)
        is JsonNull -> Unit
        is JsonPrimitive -> if (!element.isString) {
            val content = element.content
            require(content == "true" || content == "false" || NUMBER.matches(content)) { "Not a JSON value" }
        }
    }
}

/** Whether the JSON number [primitive] decoded as a Dart `double` (a fraction or an exponent), not an `int`. */
internal fun isDartDouble(primitive: JsonPrimitive): Boolean = primitive.content.any { it == '.' || it == 'e' || it == 'E' }

/**
 * The Dart value a JSON number decoded to: an `int` ([Long]) for an integer that fits 64 bits, a `double` otherwise.
 * Null for strings, booleans and null.
 */
internal fun dartNumber(primitive: JsonPrimitive): Any? {
    if (primitive.isString || primitive is JsonNull) return null
    val content = primitive.content
    if (content == "true" || content == "false") return null
    if (isDartDouble(primitive)) return content.toDouble()
    return content.toLongOrNull() ?: content.toDouble()
}

/** [primitive] as a Dart `bool`, or null when it is another type. */
internal fun dartBool(primitive: JsonPrimitive): Boolean? =
    if (primitive.isString || primitive is JsonNull) null else primitive.content.toBooleanStrictOrNull()
