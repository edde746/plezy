package com.edde746.plezy.importer

import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonPrimitive
import org.w3c.dom.Element
import java.io.ByteArrayInputStream
import java.io.InputStream
import java.io.ObjectInputStream
import java.io.ObjectStreamClass
import java.math.BigInteger
import javax.xml.parsers.DocumentBuilderFactory
import kotlin.io.encoding.Base64

/** A string list, as a string: this prefix, `!` and the JSON array; or this prefix and base64 of a serialized list. */
private const val LIST_PREFIX = "VGhpcyBpcyB0aGUgcHJlZml4IGZvciBhIGxpc3Qu"
private const val JSON_LIST_PREFIX = "$LIST_PREFIX!"
private const val DOUBLE_PREFIX = "VGhpcyBpcyB0aGUgcHJlZml4IGZvciBEb3VibGUu"
private const val BIG_INTEGER_PREFIX = "VGhpcyBpcyB0aGUgcHJlZml4IGZvciBCaWdJbnRlZ2Vy"

/**
 * Reads the Android preference stores of Plezy's earlier releases (same application id, so the same data directory):
 * the Jetpack DataStore file `files/datastore/FlutterSharedPreferences.preferences_pb` ([dataStore], bare keys) and the
 * older SharedPreferences file `shared_prefs/FlutterSharedPreferences.xml` ([legacyXml], `flutter.` keys). Null when
 * neither exists.
 */
fun readAndroidEarlierReleasePrefs(dataStore: String, legacyXml: String): EarlierReleasePrefs? {
    val dataStoreBytes = readFileOrNull(dataStore)
    val xmlBytes = readFileOrNull(legacyXml)
    if (dataStoreBytes == null && xmlBytes == null) return null
    val stored = LinkedHashMap<String, EarlierReleasePrefValue>()
    xmlBytes?.let { stored.putAll(decodeLegacyAndroidPrefs(it)) }
    dataStoreBytes?.let { stored.putAll(decodeAndroidDataStorePrefs(it)) }
    return EarlierReleasePrefs.resolve(stored)
}

/**
 * The entries of a DataStore preferences file as the app read them. The plugin wrote bools, longs (every Dart int),
 * doubles and strings and reads back only those types; a string can carry a list or, from older writes, a double
 * (see the prefixes above).
 */
fun decodeAndroidDataStorePrefs(bytes: ByteArray): Map<String, EarlierReleasePrefValue> {
    val entries = LinkedHashMap<String, EarlierReleasePrefValue>()
    for ((key, value) in decodeDataStorePreferences(bytes)) {
        entries[key] = when (value) {
            is DataStoreValue.BoolValue -> EarlierReleasePrefValue.BoolValue(value.value)
            is DataStoreValue.LongValue -> EarlierReleasePrefValue.LongValue(value.value)
            is DataStoreValue.DoubleValue -> EarlierReleasePrefValue.DoubleValue(value.value)
            is DataStoreValue.StringValue -> decodeStoredString(value.value)
            else -> continue
        }
    }
    return entries
}

/**
 * The `flutter.` entries of the SharedPreferences XML file. Ints and longs are Dart ints, floats doubles, a string
 * set a list (the release that read it converted sets to lists); strings carry lists, doubles and big integers behind
 * the prefixes above.
 */
fun decodeLegacyAndroidPrefs(bytes: ByteArray): Map<String, EarlierReleasePrefValue> {
    // Android's own parser supports few factory features; the file is the app's private one either way.
    val root = DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(ByteArrayInputStream(bytes)).documentElement
    require(root.tagName == "map") { "Not a SharedPreferences file" }
    val entries = LinkedHashMap<String, EarlierReleasePrefValue>()
    val children = root.childNodes
    for (index in 0 until children.length) {
        val element = children.item(index) as? Element ?: continue
        val key = element.getAttribute("name")
        if (!key.startsWith(EarlierReleasePrefs.LEGACY_PREFIX)) continue
        val value = element.getAttribute("value")
        entries[key] = when (element.tagName) {
            "string" -> decodeStoredString(element.textContent, legacy = true)
            "boolean" -> EarlierReleasePrefValue.BoolValue(value.toBoolean())
            "int", "long" -> EarlierReleasePrefValue.LongValue(value.toLong())
            "float" -> EarlierReleasePrefValue.DoubleValue(value.toFloat().toDouble())
            "set" -> EarlierReleasePrefValue.StringListValue(
                (0 until element.childNodes.length).mapNotNull { element.childNodes.item(it) as? Element }
                    .filter { it.tagName == "string" }.map { it.textContent },
            )
            else -> continue
        }
    }
    return entries
}

private fun decodeStoredString(value: String, legacy: Boolean = false): EarlierReleasePrefValue = when {
    value.startsWith(JSON_LIST_PREFIX) -> {
        val list = parseStrictJson(value.removePrefix(JSON_LIST_PREFIX)) as JsonArray
        EarlierReleasePrefValue.StringListValue(
            list.map { item ->
                require(item is JsonPrimitive && item !is JsonNull && item.isString) { "A stored string list holds a non-string" }
                item.content
            },
        )
    }
    value.startsWith(LIST_PREFIX) -> EarlierReleasePrefValue.StringListValue(decodeSerializedStringList(value.removePrefix(LIST_PREFIX)))
    value.startsWith(DOUBLE_PREFIX) -> EarlierReleasePrefValue.DoubleValue(value.removePrefix(DOUBLE_PREFIX).toDouble())
    legacy && value.startsWith(BIG_INTEGER_PREFIX) -> {
        val number = BigInteger(value.removePrefix(BIG_INTEGER_PREFIX), Character.MAX_RADIX)
        require(number.bitLength() < 64) { "A stored integer exceeds 64 bits" }
        EarlierReleasePrefValue.LongValue(number.toLong())
    }
    else -> EarlierReleasePrefValue.StringValue(value)
}

/**
 * The list behind [LIST_PREFIX] without `!`: Android base64 (line-wrapped) of a Java-serialized `List<String>`. Only
 * the list and string classes may be deserialized, as the plugin that wrote it allowed, so a planted value can't
 * instantiate anything else.
 */
internal fun decodeSerializedStringList(encoded: String): List<String> {
    val bytes = Base64.Mime.decode(encoded)
    val list = StringListObjectInputStream(ByteArrayInputStream(bytes)).use { it.readObject() } as List<*>
    return list.filterIsInstance<String>()
}

private class StringListObjectInputStream(input: InputStream) : ObjectInputStream(input) {
    override fun resolveClass(desc: ObjectStreamClass): Class<*> {
        if (desc.name !in ALLOWED) throw ClassNotFoundException(desc.name)
        return super.resolveClass(desc)
    }

    private companion object {
        val ALLOWED = setOf("java.util.Arrays\$ArrayList", "java.util.ArrayList", "java.lang.String", "[Ljava.lang.String;")
    }
}
