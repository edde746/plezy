package com.edde746.plezy.libmpv

enum class PropertyFormat(internal val nativeValue: Int) {
  None(0),
  String(1),
  Flag(3),
  Int64(4),
  Double(5)
}
