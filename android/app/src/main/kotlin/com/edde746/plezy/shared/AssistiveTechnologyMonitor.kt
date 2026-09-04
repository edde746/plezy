package com.edde746.plezy.shared

import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Context
import android.os.Build
import android.view.accessibility.AccessibilityManager

/**
 * Reports whether an enabled accessibility service can consume the app's semantics tree.
 *
 * Flutter compiles a semantics tree for every frame while [AccessibilityManager.isEnabled], which
 * Android sets for any bound service. On TV that is routinely a utility that never reads app
 * content (a launcher's foreground-app hook, a key remapper), so Dart gates the tree on this
 * verdict. The verdict errs towards keeping the tree:
 *
 * - touch exploration is a screen reader, full stop;
 * - an empty enabled list while accessibility is on means a [android.app.UiAutomation] client
 *   (instrumentation, Maestro), which is not listed but reads the tree;
 * - on API 33+ a service flagged `isAccessibilityTool`, or one giving spoken, braille, audible or
 *   visual feedback, consumes; a non-tool with only generic/haptic feedback does not;
 * - below 33 only a haptic-only service is treated as not consuming, since `feedbackGeneric` is
 *   what Switch Access-style tools declare.
 */
class AssistiveTechnologyMonitor(context: Context) {
  private val manager = context.getSystemService(Context.ACCESSIBILITY_SERVICE) as AccessibilityManager
  private var onChanged: (() -> Unit)? = null
  private val stateListener = AccessibilityManager.AccessibilityStateChangeListener { onChanged?.invoke() }
  private val touchExplorationListener =
    AccessibilityManager.TouchExplorationStateChangeListener { onChanged?.invoke() }
  private var servicesListener: AccessibilityManager.AccessibilityServicesStateChangeListener? = null

  fun start(onChanged: () -> Unit) {
    if (this.onChanged != null) return
    this.onChanged = onChanged
    manager.addAccessibilityStateChangeListener(stateListener)
    manager.addTouchExplorationStateChangeListener(touchExplorationListener)
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
      val listener = AccessibilityManager.AccessibilityServicesStateChangeListener { onChanged() }
      servicesListener = listener
      manager.addAccessibilityServicesStateChangeListener(listener)
    }
  }

  fun release() {
    if (onChanged == null) return
    onChanged = null
    manager.removeAccessibilityStateChangeListener(stateListener)
    manager.removeTouchExplorationStateChangeListener(touchExplorationListener)
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
      servicesListener?.let { manager.removeAccessibilityServicesStateChangeListener(it) }
      servicesListener = null
    }
  }

  fun signals(): Map<String, Any> {
    val services = manager.getEnabledAccessibilityServiceList(AccessibilityServiceInfo.FEEDBACK_ALL_MASK)
    return mapOf(
      "accessibilityEnabled" to manager.isEnabled,
      "touchExplorationEnabled" to manager.isTouchExplorationEnabled,
      "enabledServiceCount" to services.size,
      "consumesSemantics" to consumesSemantics(services)
    )
  }

  private fun consumesSemantics(services: List<AccessibilityServiceInfo>): Boolean {
    if (manager.isTouchExplorationEnabled) return true
    if (services.isEmpty()) return true
    return services.any { info -> consumesSemantics(info) }
  }

  private fun consumesSemantics(info: AccessibilityServiceInfo): Boolean {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
      if (info.isAccessibilityTool) return true
      return info.feedbackType and READER_FEEDBACK != 0
    }
    return info.feedbackType and AccessibilityServiceInfo.FEEDBACK_HAPTIC.inv() != 0
  }

  private companion object {
    const val READER_FEEDBACK =
      AccessibilityServiceInfo.FEEDBACK_SPOKEN or
        AccessibilityServiceInfo.FEEDBACK_BRAILLE or
        AccessibilityServiceInfo.FEEDBACK_AUDIBLE or
        AccessibilityServiceInfo.FEEDBACK_VISUAL
  }
}
