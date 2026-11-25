package com.edde746.plezy.strings

import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.jsonObject
import java.io.File
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotEquals
import kotlin.test.assertTrue

/**
 * The translations' completeness where a string missing or left empty, which shows in English, isn't good enough: read
 * from the strings files themselves (`shared/i18n/<tag>.i18n.json`), as an empty string and a missing key both fall back
 * to English in `T`.
 */
class TranslationCompletenessTest {
    private val english = read(File(I18N, "en.i18n.json"))
    private val translations: Map<String, JsonObject> = File(I18N).listFiles { file -> file.name.endsWith(SUFFIX) }!!
        .filter { it.name != "en$SUFFIX" }
        .associate { it.name.removeSuffix(SUFFIX) to read(it) }

    /** Strings whose English stand-in would be wrong on screen: each language has its own. */
    @Test
    fun completedEntriesOverrideTheEnglishFallback() {
        val paths = listOf("videoControls.showPlaybackControls", "videoControls.hidePlaybackControls")
        for (path in paths) {
            val base = english.stringAt(path)
            assertTrue(!base.isNullOrEmpty(), path)
            for ((tag, strings) in translations) assertNotEquals(base, strings.stringAt(path), "$tag must translate $path")
        }
    }

    /** Recovery and error messages: left out (English shows) or translated, never an empty string. */
    @Test
    fun recoveryAndErrorEntriesAreAbsentOrNonEmpty() {
        val paths = listOf(
            "auth.localDataRecoveryRequired", "settings.watchTogetherRelayInvalid", "settings.saveFailed",
            "messages.playbackAuthenticationRequired", "messages.playbackServerUnavailable", "messages.playbackDataInvalid",
            "messages.playbackCancelled", "messages.playbackFailed", "profiles.borrowLoadFailed", "liveTv.favoritesUpdateFailed",
            "settings.downloadLocationPickerUnavailable",
        )
        for (path in paths) {
            assertTrue(!english.stringAt(path).isNullOrEmpty(), "English $path must be usable")
            for ((tag, strings) in translations) {
                val value = strings.stringAt(path)
                assertTrue(value == null || value.isNotEmpty(), "$tag must omit or translate $path")
            }
        }
    }

    /** The background-download warning is translated whole in every language. */
    @Test
    fun theBackgroundWarningIsCompleteInEveryLanguage() {
        val base = leaves(english.objectAt("downloads.backgroundWarning")!!)
        assertTrue(base.values.all { it.isNotEmpty() }, "English warning copy must be usable")
        for ((tag, strings) in translations) {
            val warning = strings.objectAt("downloads.backgroundWarning")?.let(::leaves).orEmpty()
            assertEquals(base.keys, warning.keys, "$tag must contain every background warning key")
            assertTrue(warning.values.all { it.isNotEmpty() }, "$tag must translate every background warning")
        }
    }

    /** User-facing and accessibility labels: never blank, in any language. */
    @Test
    fun labelsArePopulatedInEveryLanguage() {
        val paths = listOf(
            "hotkeys.recordingShortcut", "watchTogether.openSessionControls", "watchTogether.copyCode", "services.deviceCode.copyCode",
            "services.pendingAuth.copyUrl",
        )
        for (path in paths) {
            assertTrue(!english.stringAt(path).isNullOrBlank(), "en: $path")
            for ((tag, strings) in translations) {
                val value = strings.stringAt(path)
                assertTrue(value == null || value.isNotBlank(), "$tag: $path")
            }
        }
    }

    private companion object {
        const val I18N = "i18n"
        const val SUFFIX = ".i18n.json"

        fun read(file: File): JsonObject = Json.parseToJsonElement(file.readText()).jsonObject

        fun JsonObject.elementAt(path: String): JsonElement? =
            path.split('.').fold(this as JsonElement?) { node, key -> (node as? JsonObject)?.get(key) }

        fun JsonObject.stringAt(path: String): String? = (elementAt(path) as? JsonPrimitive)?.takeIf { it.isString }?.content

        fun JsonObject.objectAt(path: String): JsonObject? = elementAt(path) as? JsonObject

        /** Every string under [node] by its dotted path. */
        fun leaves(node: JsonObject, prefix: String = ""): Map<String, String> = node.entries.flatMap { (key, value) ->
            when (value) {
                is JsonObject -> leaves(value, "$prefix$key.").entries.map { it.toPair() }
                else -> listOf("$prefix$key" to (value as JsonPrimitive).content)
            }
        }.toMap()
    }
}
