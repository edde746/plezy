package com.edde746.plezy.watchnext

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import java.util.concurrent.Executor
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/** Scrubs unversioned rows that may contain legacy authenticated poster URLs. */
class SystemShelfUpdateReceiver private constructor(
  private val executor: Executor,
  private val ownsExecutor: Boolean
) : BroadcastReceiver() {
  constructor() : this(Executors.newSingleThreadExecutor(), true)
  internal constructor(executor: Executor) : this(executor, false)

  override fun onReceive(context: Context, intent: Intent) {
    if (intent.action != Intent.ACTION_MY_PACKAGE_REPLACED) return
    val pending = goAsync()
    executor.execute {
      try {
        WatchNextProvider(context.applicationContext).clearLegacyOnPackageUpdate()
      } finally {
        pending?.finish()
        if (ownsExecutor) (executor as ExecutorService).shutdown()
      }
    }
  }
}
