package com.edde746.plezy.libmpv

sealed interface MpvEvent {
  data object StartFile : MpvEvent
  data class EndFile(val reason: EndFileReason?) : MpvEvent
  data object FileLoaded : MpvEvent
  data object PlaybackRestart : MpvEvent

  companion object {
    // Mirrors the ids event.cpp forwards; END_FILE arrives via its own JNI path.
    internal fun fromId(id: Int): MpvEvent? = when (id) {
      6 -> StartFile
      8 -> FileLoaded
      21 -> PlaybackRestart
      else -> null
    }
  }
}
