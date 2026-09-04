package com.edde746.plezy.libmpv

sealed interface PropertyChange {
  val name: String

  data class None(override val name: String) : PropertyChange
  data class Flag(override val name: String, val value: Boolean) : PropertyChange
  data class Int64(override val name: String, val value: Long) : PropertyChange
  data class Double(override val name: String, val value: kotlin.Double) : PropertyChange
  data class Str(override val name: String, val value: String) : PropertyChange
}
