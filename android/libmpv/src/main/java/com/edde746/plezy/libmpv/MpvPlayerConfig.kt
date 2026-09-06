package com.edde746.plezy.libmpv

class MpvPlayerConfig internal constructor() {
  fun setOption(name: String, value: String) {
    val result = MpvPlayer.setOptionString(name, value)
    if (result < 0) {
      throw MpvException("Failed to set option '$name' to '$value': error $result")
    }
  }

  fun setLogLevel(level: String) {
    MpvPlayer.requestLogMessages(level)
  }
}
