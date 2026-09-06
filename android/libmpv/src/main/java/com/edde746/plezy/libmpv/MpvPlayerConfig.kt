package com.edde746.plezy.libmpv

/** Pre-initialize configuration of one native session; every write names it. */
class MpvPlayerConfig internal constructor(private val session: Long) {
  fun setOption(name: String, value: String) {
    val result = MpvPlayer.setOptionString(session, name, value)
    if (result < 0) {
      throw MpvException("Failed to set option '$name' to '$value': error $result")
    }
  }

  fun setLogLevel(level: String) {
    MpvPlayer.requestLogMessages(session, level)
  }
}
