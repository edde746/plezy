package com.edde746.plezy.shared

interface PlayerDelegate {
  fun onPropertyChange(name: String, value: Any?)
  fun onPropertyChange(name: String, value: Any?, sourceId: Long?) {
    onPropertyChange(name, value)
  }

  fun onEvent(name: String, data: Map<String, Any>?)
}
