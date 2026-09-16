package com.edde746.plezy.mpv

/**
 * The session-owned `vd-lavc-o` list.
 *
 * mpv exposes the decoder's AVOptions as one key=value list with no append
 * form through the property interface, so every writer replaces the whole
 * list. Three writers exist: the session's own keys (`ndk_codec`, `ndk_async`,
 * `priority`, the per-file Dolby Vision routing and stream rate), the
 * per-file updates to those, and the user's custom mpv config line. The list
 * mpv sees is always composed here as the app's keys followed by the user's
 * text: FFmpeg keeps the last duplicate key, so a user entry wins over the
 * app's for that key while every app key the user did not name survives. A
 * raw user write used to discard `ndk_async` and the DV routing along with
 * everything else.
 */
internal class DecoderOptions {
  private val app = LinkedHashMap<String, String>()
  private var user: String? = null

  /** Set or replace app-owned keys; a null value removes the key. */
  fun put(vararg entries: Pair<String, String?>) = putAll(entries.asIterable())

  fun putAll(entries: Iterable<Pair<String, String?>>) {
    for ((key, value) in entries) {
      if (value == null) app.remove(key) else app[key] = value
    }
  }

  /** The user's own `vd-lavc-o` text, verbatim; blank clears it. */
  fun setUser(text: String?) {
    user = text?.trim()?.takeIf { it.isNotEmpty() }
  }

  /** The app's keys, then the user's text: the later duplicate is the one FFmpeg keeps. */
  fun compose(): String {
    val own = app.entries.joinToString(",") { "${it.key}=${it.value}" }
    return listOfNotNull(own.takeIf { it.isNotEmpty() }, user).joinToString(",")
  }
}
