package com.edde746.plezy.importer

/**
 * One value of a Jetpack DataStore preferences file, the `androidx.datastore.preferences.Value` message: a oneof of
 * `boolean` (1), `float` (2), `integer` (3), `long` (4), `string` (5), `string_set` (6), `double` (7), `bytes` (8).
 */
internal sealed interface DataStoreValue {
    data class BoolValue(val value: Boolean) : DataStoreValue
    data class FloatValue(val value: Float) : DataStoreValue
    data class IntValue(val value: Int) : DataStoreValue
    data class LongValue(val value: Long) : DataStoreValue
    data class StringValue(val value: String) : DataStoreValue
    data class StringSetValue(val value: List<String>) : DataStoreValue
    data class DoubleValue(val value: Double) : DataStoreValue
    class BytesValue(val value: ByteArray) : DataStoreValue
}

/**
 * Decodes a DataStore `.preferences_pb` file: the protobuf `PreferenceMap` message, `map<string, Value>
 * preferences = 1`, written without a length prefix. An entry whose value sets no field is left out. Throws
 * [IllegalArgumentException] for bytes that aren't such a message.
 */
internal fun decodeDataStorePreferences(bytes: ByteArray): Map<String, DataStoreValue> {
    val entries = LinkedHashMap<String, DataStoreValue>()
    ProtoReader(bytes, 0, bytes.size).forEachField { field, reader ->
        if (field == 1) {
            var key = ""
            var value: DataStoreValue? = null
            reader.message().forEachField { entryField, entry ->
                when (entryField) {
                    1 -> key = entry.string()
                    2 -> value = decodeValue(entry.message())
                    else -> entry.skip()
                }
            }
            value?.let { entries[key] = it }
        } else {
            reader.skip()
        }
    }
    return entries
}

private fun decodeValue(reader: ProtoReader): DataStoreValue? {
    var value: DataStoreValue? = null
    reader.forEachField { field, r ->
        value = when (field) {
            1 -> DataStoreValue.BoolValue(r.varint() != 0L)
            2 -> DataStoreValue.FloatValue(Float.fromBits(r.fixed32()))
            3 -> DataStoreValue.IntValue(r.varint().toInt())
            4 -> DataStoreValue.LongValue(r.varint())
            5 -> DataStoreValue.StringValue(r.string())
            6 -> {
                val strings = ArrayList<String>()
                r.message().forEachField { setField, set -> if (setField == 1) strings += set.string() else set.skip() }
                DataStoreValue.StringSetValue(strings)
            }
            7 -> DataStoreValue.DoubleValue(Double.fromBits(r.fixed64()))
            8 -> DataStoreValue.BytesValue(r.bytes())
            else -> {
                r.skip()
                value
            }
        }
    }
    return value
}

/** Reads protobuf fields from [bytes] between [start] and [end]. */
private class ProtoReader(private val bytes: ByteArray, start: Int, private val end: Int) {
    private var position = start
    private var wireType = 0

    /** Calls [action] with each field number, positioned at its payload, which [action] must consume. */
    fun forEachField(action: (Int, ProtoReader) -> Unit) {
        while (position < end) {
            val tag = varint()
            wireType = (tag and 7).toInt()
            val field = (tag ushr 3).toInt()
            require(field > 0) { "Not a protobuf message" }
            action(field, this)
        }
        require(position == end) { "Truncated protobuf message" }
    }

    fun varint(): Long {
        var result = 0L
        var shift = 0
        while (true) {
            require(position < end && shift < 64) { "Truncated protobuf varint" }
            val byte = bytes[position++].toInt()
            result = result or ((byte and 0x7F).toLong() shl shift)
            if (byte and 0x80 == 0) return result
            shift += 7
        }
    }

    fun fixed32(): Int {
        require(wireType == 5 && position + 4 <= end) { "Malformed protobuf fixed32" }
        var result = 0
        for (i in 0 until 4) result = result or ((bytes[position + i].toInt() and 0xFF) shl (8 * i))
        position += 4
        return result
    }

    fun fixed64(): Long {
        require(wireType == 1 && position + 8 <= end) { "Malformed protobuf fixed64" }
        var result = 0L
        for (i in 0 until 8) result = result or ((bytes[position + i].toLong() and 0xFF) shl (8 * i))
        position += 8
        return result
    }

    fun bytes(): ByteArray {
        val (from, to) = delimited()
        return bytes.copyOfRange(from, to)
    }

    fun string(): String {
        val (from, to) = delimited()
        return bytes.decodeToString(from, to)
    }

    fun message(): ProtoReader {
        val (from, to) = delimited()
        return ProtoReader(bytes, from, to)
    }

    fun skip() {
        when (wireType) {
            0 -> varint()
            1 -> fixed64()
            2 -> delimited()
            5 -> fixed32()
            else -> throw IllegalArgumentException("Unsupported protobuf wire type $wireType")
        }
    }

    private fun delimited(): Pair<Int, Int> {
        require(wireType == 2) { "Malformed protobuf field" }
        val length = varint()
        require(length >= 0 && position + length <= end) { "Truncated protobuf field" }
        val from = position
        position += length.toInt()
        return from to position
    }
}
