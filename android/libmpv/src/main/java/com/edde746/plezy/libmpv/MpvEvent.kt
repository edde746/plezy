package com.edde746.plezy.libmpv

sealed interface MpvEvent {
  data object Shutdown : MpvEvent
  data object StartFile : MpvEvent
  data class EndFile(val reason: EndFileReason?) : MpvEvent
  data object FileLoaded : MpvEvent
  data object VideoReconfig : MpvEvent
  data object AudioReconfig : MpvEvent
  data object Seek : MpvEvent
  data object PlaybackRestart : MpvEvent
  data object QueueOverflow : MpvEvent
  data class Other(val eventId: Int) : MpvEvent

  companion object {
    internal fun fromId(id: Int): MpvEvent? = when (id) {
      1 -> Shutdown
      6 -> StartFile
      8 -> FileLoaded
      17 -> VideoReconfig
      18 -> AudioReconfig
      20 -> Seek
      21 -> PlaybackRestart
      24 -> QueueOverflow
      // 0=NONE, 2=LOG_MESSAGE, 7=END_FILE, 22=PROPERTY_CHANGE handled separately
      0, 2, 7, 22 -> null
      else -> Other(id)
    }
  }
}
