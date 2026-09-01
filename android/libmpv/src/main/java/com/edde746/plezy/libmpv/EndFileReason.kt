package com.edde746.plezy.libmpv

enum class EndFileReason(val id: Int) {
  Eof(0),
  Stop(2),
  Quit(3),
  Error(4),
  Redirect(5);

  companion object {
    fun fromId(id: Int): EndFileReason? = entries.find { it.id == id }
  }
}
