package com.edde746.plezy.mpv

import android.app.Activity
import android.os.Bundle
import android.view.WindowManager
import android.widget.FrameLayout

class MpvLifecycleTestActivity : Activity() {
  override fun onCreate(savedInstanceState: Bundle?) {
    window.addFlags(
      WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
        WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
        WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
    )
    super.onCreate(savedInstanceState)
    setContentView(FrameLayout(this))
  }
}
