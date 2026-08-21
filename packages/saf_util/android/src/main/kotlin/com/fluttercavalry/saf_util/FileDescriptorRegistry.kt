package com.fluttercavalry.saf_util

import android.os.ParcelFileDescriptor

/** Owns descriptors for exactly one attached Flutter engine at a time. */
internal class FileDescriptorRegistry {
  private val lock = Any()
  private val descriptors = mutableMapOf<Int, ParcelFileDescriptor>()
  private var attached = false

  fun attach() {
    synchronized(lock) {
      attached = true
    }
  }

  /** Returns the borrowed descriptor number, or null after closing a late descriptor. */
  fun register(descriptor: ParcelFileDescriptor): Int? {
    val fd = descriptor.fd
    synchronized(lock) {
      if (attached) {
        descriptors[fd] = descriptor
        return fd
      }
    }

    closeBestEffort(descriptor)
    return null
  }

  /** Removes ownership before closing, making repeated and unknown closes idempotent. */
  fun close(fd: Int) {
    val descriptor = synchronized(lock) { descriptors.remove(fd) }
    descriptor?.close()
  }

  /** Rejects future registrations, then drains all current ownership best effort. */
  fun detach() {
    val owned =
      synchronized(lock) {
        attached = false
        val snapshot = descriptors.values.toList()
        descriptors.clear()
        snapshot
      }
    owned.forEach(::closeBestEffort)
  }

  internal val trackedCount: Int
    get() = synchronized(lock) { descriptors.size }

  private fun closeBestEffort(descriptor: ParcelFileDescriptor) {
    try {
      descriptor.close()
    } catch (_: Exception) {
      // Continue draining the remaining plugin-owned descriptors.
    }
  }
}
