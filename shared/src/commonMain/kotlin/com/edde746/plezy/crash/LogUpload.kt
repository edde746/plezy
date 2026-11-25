package com.edde746.plezy.crash

import com.edde746.plezy.net.PlezyHttpClient
import io.ktor.client.HttpClient
import io.ktor.client.request.post
import io.ktor.client.request.setBody
import io.ktor.client.statement.bodyAsText
import io.ktor.http.ContentType
import io.ktor.http.contentType
import io.ktor.http.isSuccess
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive

/**
 * Plezy's log relay: it takes up to [MAX_BYTES] of plain text and answers with a short Log ID the user quotes in a
 * report. What is sent must already be redacted; nothing here sanitises it.
 */
object LogUpload {
    const val ENDPOINT = "https://ice.plezy.app/logs"
    const val MAX_BYTES = 1024 * 1024

    /** Uploads [text] on a client of its own (the startup failure screen has no app to borrow one from). */
    @Throws(Exception::class)
    suspend fun upload(text: String, appVersion: String): String =
        PlezyHttpClient.create(appVersion).use { upload(text, it) }

    /**
     * Posts [text], cut to its first [MAX_BYTES] bytes (never inside a character), as `text/plain`; the Log ID.
     *
     * @throws IllegalStateException when the relay refuses it or answers without an id.
     */
    @Throws(Exception::class)
    suspend fun upload(text: String, http: HttpClient): String {
        val response = http.post(ENDPOINT) {
            contentType(ContentType.Text.Plain)
            setBody(fit(text))
        }
        val body = response.bodyAsText()
        check(response.status.isSuccess()) { "The log relay answered ${response.status.value}" }
        val id = (Json.parseToJsonElement(body) as? JsonObject)?.get("id") as? JsonPrimitive
        return id?.takeIf { it.isString && it.content.isNotBlank() }?.content ?: error("The log relay answered without a Log ID")
    }

    /** [text]'s first [MAX_BYTES] bytes of UTF-8, ending before a cut character. */
    internal fun fit(text: String): String {
        val bytes = text.encodeToByteArray()
        if (bytes.size <= MAX_BYTES) return text
        var end = MAX_BYTES
        while (end > 0 && bytes[end].toInt() and 0xC0 == 0x80) end--
        return bytes.decodeToString(0, end)
    }
}
