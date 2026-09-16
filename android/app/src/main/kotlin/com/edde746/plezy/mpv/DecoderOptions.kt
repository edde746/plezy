package com.edde746.plezy.mpv

/**
 * The session-owned `vd-lavc-o` list.
 *
 * mpv exposes the decoder's AVOptions as one key=value list with no append
 * form through the property interface, so every writer replaces the whole
 * list. Three writers exist: the session's own keys (`ndk_codec`, `ndk_async`,
 * the per-file Dolby Vision routing, the stream rate and priority the
 * MediaCodec decoder is told), the per-file updates to those, and the user's
 * custom mpv config line. The list mpv sees is always composed here as the
 * app's keys followed by the user's text: FFmpeg keeps the last duplicate
 * key, so a user entry wins over the app's for that key while every app key
 * the user did not name survives. A raw user write used to discard
 * `ndk_async` and the DV routing along with everything else.
 */
internal class DecoderOptions {
  private val app = LinkedHashMap<String, String>()
  private var user: String? = null

  /** Set or replace app-owned keys; a null value removes the key. */
  fun put(vararg entries: Pair<String, String?>): DecoderOptions = putAll(entries.asIterable())

  fun putAll(entries: Iterable<Pair<String, String?>>): DecoderOptions {
    for ((key, value) in entries) {
      if (value == null) app.remove(key) else app[key] = value
    }
    return this
  }

  /** The user's own `vd-lavc-o` text, verbatim; blank clears it. */
  fun setUser(text: String?): DecoderOptions {
    user = text?.trim()?.takeIf { it.isNotEmpty() }
    return this
  }

  fun compose(): String = compose(app.entries.joinToString(",") { "${it.key}=${it.value}" }, user)

  companion object {
    /** [app] first, then [user]: the later duplicate is the one FFmpeg keeps. */
    fun compose(app: String, user: String?): String {
      val userText = user?.trim().orEmpty()
      return when {
        userText.isEmpty() -> app
        app.isEmpty() -> userText
        else -> "$app,$userText"
      }
    }
  }
}
