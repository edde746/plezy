package com.edde746.plezy.mpv

import android.app.Activity
import android.os.Bundle
import android.view.WindowManager
import android.widget.FrameLayout
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat

class MpvLifecycleTestActivity : Activity() {
  override fun onCreate(savedInstanceState: Bundle?) {
    window.addFlags(
      WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
        WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
        WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
    )
    super.onCreate(savedInstanceState)
    setContentView(FrameLayout(this))
    // Match the production player's immersive viewport so system bars cannot
    // cover the picture or subtitles measured by the native pixel regressions.
    WindowCompat.setDecorFitsSystemWindows(window, false)
    WindowCompat.getInsetsController(window, window.decorView).apply {
      systemBarsBehavior = WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
      hide(WindowInsetsCompat.Type.systemBars())
    }
  }
}
