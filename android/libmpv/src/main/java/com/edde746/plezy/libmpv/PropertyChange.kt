package com.edde746.plezy.libmpv

sealed interface PropertyChange {
  val name: String
  val sourceId: Long?

  data class None(
    override val name: String,
    override val sourceId: Long?
  ) : PropertyChange

  data class Flag(
    override val name: String,
    val value: Boolean,
    override val sourceId: Long?
  ) : PropertyChange

  data class Int64(
    override val name: String,
    val value: Long,
    override val sourceId: Long?
  ) : PropertyChange

  data class Double(
    override val name: String,
    val value: kotlin.Double,
    override val sourceId: Long?
  ) : PropertyChange

  data class Str(
    override val name: String,
    val value: String,
    override val sourceId: Long?
  ) : PropertyChange
}
