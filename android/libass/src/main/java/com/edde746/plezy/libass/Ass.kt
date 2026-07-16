package com.edde746.plezy.libass

import java.util.concurrent.locks.ReentrantLock
import kotlin.concurrent.withLock

class Ass {

  companion object {

    init {
      System.loadLibrary("asskt")
    }

    @JvmStatic
    external fun nativeAssInit(): Long

    @JvmStatic
    external fun nativeAssAddFont(ptr: Long, name: String, buffer: ByteArray)

    @JvmStatic
    external fun nativeAssDeinit(ptr: Long)
  }

  /** Single lock for all libass calls on this library instance. */
  val lock = ReentrantLock()

  private var nativeAss: Long = nativeAssInit()

  @Volatile
  var released = false
    private set

  private fun <T> create(block: (Long) -> T): T = lock.withLock {
    check(!released && nativeAss != 0L) { "Ass already released" }
    block(nativeAss)
  }

  fun createTrack(): AssTrack = create { AssTrack(it, lock) }

  fun createRender(): AssRender = create { AssRender(it, lock) }

  fun addFont(name: String, buffer: ByteArray) {
    lock.withLock {
      if (!released && nativeAss != 0L) nativeAssAddFont(nativeAss, name, buffer)
    }
  }

  fun release() {
    lock.withLock {
      if (released) return
      released = true
      if (nativeAss != 0L) {
        nativeAssDeinit(nativeAss)
        nativeAss = 0
      }
    }
  }

  protected fun finalize() {
    release()
  }
}
