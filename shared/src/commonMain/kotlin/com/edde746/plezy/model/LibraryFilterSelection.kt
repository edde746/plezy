package com.edde746.plezy.model

import com.edde746.plezy.log.Log
import kotlinx.serialization.SerializationException
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive

// A library's filter selection: an ordered list of clauses that AND together. It is what persists and what the filter
// editor edits.

private const val TAG = "LibraryFilters"

/** Every clause on [field], in selection order. */
fun List<LibraryFilter>.clausesFor(field: String): List<LibraryFilter> = filter { it.field == field }

/** The first clause on [field], or null when the field is unset. Fields allowing several clauses (ranges) use [clausesFor]. */
fun List<LibraryFilter>.clauseFor(field: String): LibraryFilter? = firstOrNull { it.field == field }

/**
 * Every clause on [field] replaced by [clauses], at the field's first position so the editor's summary rows don't
 * reorder while edited; appended when the field was unset. An empty [clauses] clears the field.
 */
fun List<LibraryFilter>.withField(field: String, clauses: List<LibraryFilter>): List<LibraryFilter> {
    val result = mutableListOf<LibraryFilter>()
    var inserted = false
    for (existing in this) {
        if (existing.field != field) {
            result += existing
        } else if (!inserted) {
            result += clauses
            inserted = true
        }
    }
    if (!inserted) result += clauses
    return result
}

/** The selection as stored: a JSON list of storage clauses. */
fun encodeLibraryFilterSelection(filters: List<LibraryFilter>): String = JsonArray(filters.map { it.toStorageJson() }).toString()

/**
 * A stored selection; invalid clauses are dropped. Also reads the pre-clause form, a flat `{"genre": "42,43"}` map of
 * equality filters, so filters saved by older builds survive. Unreadable JSON reads as no filters (logged).
 */
fun decodeLibraryFilterSelection(json: String): List<LibraryFilter> {
    if (json.isEmpty()) return emptyList()
    val decoded = try {
        Json.parseToJsonElement(json)
    } catch (e: SerializationException) {
        Log.w(TAG, e) { "Discarding unreadable library filter selection" }
        return emptyList()
    }
    return when (decoded) {
        is JsonArray -> decoded.mapNotNull { LibraryFilter.fromStorageJson(it) }
        is JsonObject -> decoded.mapNotNull { (field, value) ->
            if (field.isEmpty() || value is JsonNull) return@mapNotNull null
            val values = legacyValueText(value).split(',').filter { it.isNotEmpty() }
            if (values.isEmpty()) null else LibraryFilter(field, values)
        }
        else -> emptyList()
    }
}

/** A legacy map value as text: a string's content, any other JSON as written. */
private fun legacyValueText(value: JsonElement): String = if (value is JsonPrimitive) value.content else value.toString()
