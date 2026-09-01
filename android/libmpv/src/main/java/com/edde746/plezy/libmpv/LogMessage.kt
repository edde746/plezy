package com.edde746.plezy.libmpv

data class LogMessage(
  val prefix: String,
  val level: LogLevel,
  val text: String
)
