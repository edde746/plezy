package com.edde746.plezy.mpv

import com.edde746.mpv.MpvException

/**
 * What a refused property write may tell Dart, as the `details` of its
 * `SET_PROPERTY_FAILED`. Never the exception's message: a failure raised around
 * a write can carry the value written. Only what the bridge classified itself:
 *
 * - `failure`: `mpvError` (libmpv answered `mpvError`, named `mpvErrorName` as
 *   mpv_error_string() names it), `unresponsive` (the core did not answer
 *   `operation` in time) or `exception` (its type, as `exception`).
 * - `sessionFailed`: the write was refused because the session had already
 *   been condemned (an unanswered native call, a failed video output). The
 *   `failure` fields then describe what condemned it, and every later write is
 *   refused the same way until the core is replaced: a dead session, not a
 *   value mpv turned down.
 */
internal fun mpvPropertyFailureDetails(property: String, failure: Throwable, sessionFailure: Throwable?): Map<String, Any> {
  val details = linkedMapOf<String, Any>("property" to property, "sessionFailed" to (failure === sessionFailure))
  val mpvError = (failure as? MpvException)?.let(::mpvErrorCode)
  when {
    failure is MpvOperationTimeout -> {
      details["failure"] = "unresponsive"
      details["operation"] = failure.operation
    }
    mpvError != null -> {
      details["failure"] = "mpvError"
      details["mpvError"] = mpvError
      details["mpvErrorName"] = mpvErrorName(mpvError)
    }
    else -> {
      details["failure"] = "exception"
      details["exception"] = failure.javaClass.simpleName.ifEmpty { failure.javaClass.name }
    }
  }
  return details
}

// The pinned mpv-android wrapper keeps no code on [MpvException]; every message
// it raises ends in the mpv_error it got: `Failed to set property 'x': error -10`.
private val mpvErrorSuffix = Regex("""error (-\d+)$""")

private fun mpvErrorCode(error: MpvException): Int? = error.message?.let { mpvErrorSuffix.find(it) }?.groupValues?.get(1)?.toIntOrNull()

/** mpv_error_string(), so a report reads the same as mpv's own documentation. */
private fun mpvErrorName(code: Int): String = when (code) {
  -1 -> "event queue full"
  -2 -> "memory allocation failed"
  -3 -> "core not initialized"
  -4 -> "invalid parameter"
  -5 -> "option not found"
  -6 -> "unsupported format for accessing option"
  -7 -> "error setting option"
  -8 -> "property not found"
  -9 -> "unsupported format for accessing property"
  -10 -> "property unavailable"
  -11 -> "error accessing property"
  -12 -> "error running command"
  -13 -> "loading failed"
  -14 -> "audio output initialization failed"
  -15 -> "video output initialization failed"
  -16 -> "no audio or video data played"
  -17 -> "unrecognized file format"
  -18 -> "not supported"
  -19 -> "operation not implemented"
  -20 -> "something happened"
  else -> "unknown error"
}
