package com.edde746.plezy.desktop

import com.edde746.plezy.log.Log
import com.edde746.plezy.net.WebUrl
import java.awt.Desktop
import java.net.URI
import java.net.URISyntaxException
import java.util.concurrent.CompletableFuture
import java.util.concurrent.TimeUnit
import java.util.concurrent.TimeoutException

/**
 * Opens the web link [url] in the system browser, percent-encoded as `java.net.URI` takes it ([browserUri]): AWT's
 * desktop integration, or `xdg-open` on Linux sessions where AWT has none. Either runs off the calling thread, since the
 * OS handler can block; true once it has handed the link over, or when it is still at work after [BROWSE_WAIT_MILLIS]
 * (a later failure is only logged). False for anything but an `http`/`https` link ([WebUrl.isWeb]), for one that
 * doesn't parse even encoded, and when the handler fails in time: the app then offers the link to a phone. Logs never
 * hold the URL: it can carry a token.
 */
internal fun browse(url: String): Boolean {
    if (!WebUrl.isWeb(url)) {
        Log.w(BROWSE_TAG) { "Not opening a link with scheme ${WebUrl.scheme(url)}" }
        return false
    }
    val uri = browserUri(url) ?: run {
        Log.w(BROWSE_TAG) { "The link doesn't parse as a URI" }
        return false
    }
    val awt = Desktop.isDesktopSupported() && Desktop.getDesktop().isSupported(Desktop.Action.BROWSE)
    val opened = CompletableFuture<Boolean>()
    Thread({
        val failure = try {
            if (awt) {
                Desktop.getDesktop().browse(uri)
                null
            } else {
                ProcessBuilder("xdg-open", uri.toString()).start().waitFor().takeIf { it != 0 }?.let { "xdg-open exited with $it" }
            }
        } catch (e: Exception) {
            e::class.simpleName
        }
        if (failure != null) Log.w(BROWSE_TAG) { "The browser doesn't open: $failure" }
        opened.complete(failure == null)
    }, "open-url").apply { isDaemon = true }.start()
    return try {
        opened.get(BROWSE_WAIT_MILLIS, TimeUnit.MILLISECONDS)
    } catch (_: TimeoutException) {
        true
    }
}

/**
 * [url] as `java.net.URI` takes it, which is stricter than browsers: every character it rejects percent-encoded as
 * UTF-8 (`|`, `^`, `{`, `}`, `` ` ``, `\`, `"`, `<`, `>`, a space, `[` and `]` outside the host, a `#` after the
 * first, a `%` that starts no escape, anything outside ASCII); existing escapes are kept. Null when it still doesn't parse.
 */
internal fun browserUri(url: String): URI? {
    val hostStart = url.indexOf("://").let { if (it < 0) url.length else it + 3 }
    val hostEnd = url.indexOfAny(charArrayOf('/', '?', '#'), hostStart).let { if (it < 0) url.length else it }
    val encoded = StringBuilder(url.length + 16)
    var fragment = false
    var i = 0
    while (i < url.length) {
        val c = url[i]
        val keep = when (c) {
            in 'a'..'z', in 'A'..'Z', in '0'..'9', in URI_KEPT -> true
            '#' -> !fragment
            '%' -> i + 2 < url.length && url[i + 1].isHexDigit() && url[i + 2].isHexDigit()
            '[', ']' -> i in hostStart until hostEnd
            else -> false
        }
        if (c == '#') fragment = true
        val end = if (c.isHighSurrogate() && i + 1 < url.length && url[i + 1].isLowSurrogate()) i + 2 else i + 1
        if (keep) {
            encoded.append(c)
        } else {
            for (byte in url.substring(i, end).encodeToByteArray()) {
                encoded.append('%').append(HEX[(byte.toInt() shr 4) and 0xF]).append(HEX[byte.toInt() and 0xF])
            }
        }
        i = end
    }
    return try {
        URI(encoded.toString())
    } catch (_: URISyntaxException) {
        null
    }
}

private fun Char.isHexDigit() = this in '0'..'9' || this in 'a'..'f' || this in 'A'..'F'

/** What `java.net.URI` takes as written besides letters and digits: RFC 2396's marks and reserved characters. */
private const val URI_KEPT = "-._~!$&'()*+,;=:@/?"
private const val HEX = "0123456789ABCDEF"

/** How long [browse] waits for the OS handler to take a link before it counts it as opened. */
private const val BROWSE_WAIT_MILLIS = 1500L
private const val BROWSE_TAG = "Browse"
