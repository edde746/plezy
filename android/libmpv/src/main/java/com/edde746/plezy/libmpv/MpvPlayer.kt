package com.edde746.plezy.libmpv

import android.content.Context
import android.os.Looper
import android.view.Surface
import java.util.concurrent.atomic.AtomicReference
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.filter
import kotlinx.coroutines.flow.filterIsInstance
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeoutOrNull

class MpvPlayer private constructor() : AutoCloseable {

  companion object {
    /** Upper bound for a hook handler; longer stalls playback start. */
    private const val HOOK_TIMEOUT_MS = 3_000L

    init {
      System.loadLibrary("mpv")
      System.loadLibrary("player")
    }

    private val instance = AtomicReference<MpvPlayer?>(null)

    /**
     * Creates and initializes the process-global native player off the Android
     * main thread. A predecessor may still be terminating under the native
     * lifecycle lock, so this call must remain safe to suspend behind it.
     */
    suspend fun create(
      context: Context,
      configure: MpvPlayerConfig.() -> Unit = {}
    ): MpvPlayer = withContext(Dispatchers.IO) {
      checkNotMainThread("MPV initialization")
      val player = MpvPlayer()
      // Atomically replace; mark old as closed so its background close() skips nativeDestroy
      synchronized(instance) {
        instance.getAndSet(player)?.also { it.closed = true }
      }
      // nativeCreate's safety net handles any leaked native session
      try {
        nativeCreate(context.applicationContext)
        MpvPlayerConfig().apply(configure)
        nativeInit()
        ensureActive()
        player
      } catch (e: Throwable) {
        instance.compareAndSet(player, null)
        try {
          nativeDestroy()
        } catch (_: Throwable) {}
        throw e
      }
    }

    // JNI callbacks — called from native event thread

    @JvmStatic
    fun onPropertyChanged(name: String, sourceId: Long, hasSourceId: Boolean) {
      instance.get()?.rawPropertyChanges?.trySend(
        PropertyChange.None(name, sourceId.takeIf { hasSourceId })
      )
    }

    @JvmStatic
    fun onPropertyChanged(name: String, value: Boolean, sourceId: Long, hasSourceId: Boolean) {
      instance.get()?.rawPropertyChanges?.trySend(
        PropertyChange.Flag(name, value, sourceId.takeIf { hasSourceId })
      )
    }

    @JvmStatic
    fun onPropertyChanged(name: String, value: Long, sourceId: Long, hasSourceId: Boolean) {
      instance.get()?.rawPropertyChanges?.trySend(
        PropertyChange.Int64(name, value, sourceId.takeIf { hasSourceId })
      )
    }

    @JvmStatic
    fun onPropertyChanged(name: String, value: Double, sourceId: Long, hasSourceId: Boolean) {
      instance.get()?.rawPropertyChanges?.trySend(
        PropertyChange.Double(name, value, sourceId.takeIf { hasSourceId })
      )
    }

    @JvmStatic
    fun onPropertyChanged(name: String, value: String, sourceId: Long, hasSourceId: Boolean) {
      instance.get()?.rawPropertyChanges?.trySend(
        PropertyChange.Str(name, value, sourceId.takeIf { hasSourceId })
      )
    }

    @JvmStatic
    fun onEvent(
      eventId: Int,
      sourceId: Long,
      hasSourceId: Boolean,
      positionSeconds: Double,
      hasPositionSeconds: Boolean
    ) {
      val event = MpvEvent.fromId(
        eventId,
        sourceId.takeIf { hasSourceId },
        positionSeconds.takeIf { hasPositionSeconds && it.isFinite() }
      ) ?: return
      instance.get()?.rawEvents?.trySend(event)
    }

    @JvmStatic
    fun onEndFile(reason: Int, sourceId: Long, hasSourceId: Boolean) {
      instance.get()?.rawEvents?.trySend(
        MpvEvent.EndFile(
          EndFileReason.fromId(reason),
          sourceId.takeIf { hasSourceId }
        )
      )
    }

    @JvmStatic
    fun onLogMessage(prefix: String, level: Int, text: String) {
      val logLevel = LogLevel.fromNative(level) ?: return
      instance.get()?.rawLogMessages?.trySend(LogMessage(prefix, logLevel, text.trimEnd()))
    }

    @JvmStatic
    fun onHook(name: String, id: Long) {
      val player = instance.get()
      if (player == null || player.closed || !player.rawHooks.trySend(Hook(name, id)).isSuccess) {
        // Nobody will answer: release mpv rather than leave it waiting.
        nativeHookContinue(id)
      }
    }

    private fun checkNotMainThread(operation: String) {
      check(Looper.myLooper() != Looper.getMainLooper()) {
        "$operation must not run on the Android main thread"
      }
    }

    // JNI native declarations — private to avoid internal name mangling

    @JvmStatic private external fun nativeCreate(appctx: Context)

    @JvmStatic private external fun nativeInit()

    @JvmStatic private external fun nativeDestroy()

    @JvmStatic private external fun nativeCommand(cmd: Array<out String>)

    @JvmStatic private external fun nativeSetLogLevel(level: String): Int

    @JvmStatic private external fun nativeHookContinue(id: Long)

    @JvmStatic private external fun nativeSetOptionString(name: String, value: String): Int

    @JvmStatic private external fun nativeAttachSurface(surface: Surface)

    @JvmStatic private external fun nativeDetachSurface()

    @JvmStatic private external fun nativeAttachOsdSurface(surface: Surface)

    @JvmStatic private external fun nativeDetachOsdSurface()

    @JvmStatic private external fun nativeGetPropertyInt(name: String): Int?

    @JvmStatic private external fun nativeGetPropertyDouble(name: String): Double?

    @JvmStatic private external fun nativeGetPropertyBoolean(name: String): Boolean?

    @JvmStatic private external fun nativeGetPropertyString(name: String): String?

    @JvmStatic private external fun nativeSetPropertyInt(name: String, value: Int)

    @JvmStatic private external fun nativeSetPropertyDouble(name: String, value: Double)

    @JvmStatic private external fun nativeSetPropertyBoolean(name: String, value: Boolean)

    @JvmStatic private external fun nativeSetPropertyString(name: String, value: String)

    @JvmStatic private external fun nativeObserveProperty(name: String, format: Int)

    internal fun setOptionString(name: String, value: String): Int = nativeSetOptionString(name, value)

    internal fun requestLogMessages(level: String) {
      checkNotMainThread("MPV log level change")
      val result = nativeSetLogLevel(level)
      if (result < 0) {
        throw MpvException("Failed to set log level: error $result")
      }
    }
  }

  // The native event thread hands everything to unbounded channels: trySend
  // on them cannot fail (until close) and cannot block mpv's event loop. A
  // pump per stream re-emits into the SharedFlow, whose SUSPEND overflow
  // parks the pump - not the native thread - while a collector catches up.
  // The previous design tryEmit-ed straight into the 64-slot SharedFlow
  // buffer, which silently dropped whatever arrived during a burst; losing
  // e.g. the one cplayer log line that signals a failed video chain.
  private val rawEvents = Channel<MpvEvent>(Channel.UNLIMITED)
  private val rawHooks = Channel<Hook>(Channel.UNLIMITED)
  private val rawPropertyChanges = Channel<PropertyChange>(Channel.UNLIMITED)
  private val rawLogMessages = Channel<LogMessage>(Channel.UNLIMITED)

  private val events = MutableSharedFlow<MpvEvent>(extraBufferCapacity = 64)
  private val propertyChanges = MutableSharedFlow<PropertyChange>(extraBufferCapacity = 64)
  private val logMessages = MutableSharedFlow<LogMessage>(extraBufferCapacity = 64)

  private val pumpScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)

  private class Hook(val name: String, val id: Long)

  /**
   * Handler for mpv hooks the native side registered (`on_preloaded`). mpv
   * holds playback until the handler returns; a handler that throws or
   * overruns [HOOK_TIMEOUT_MS] is abandoned and playback continues. Set it
   * before loading a file; unset, hooks continue immediately.
   */
  @Volatile var hookHandler: (suspend (name: String) -> Unit)? = null

  init {
    pumpScope.launch { for (e in rawEvents) events.emit(e) }
    pumpScope.launch {
      for (hook in rawHooks) {
        try {
          val handler = hookHandler
          if (handler != null) {
            withTimeoutOrNull(HOOK_TIMEOUT_MS) { handler(hook.name) }
              ?: android.util.Log.w("MpvPlayer", "Hook ${hook.name} handler overran; continuing playback")
          }
        } catch (e: Exception) {
          android.util.Log.w("MpvPlayer", "Hook ${hook.name} handler failed; continuing playback", e)
        } finally {
          if (!closed) nativeHookContinue(hook.id)
        }
      }
    }
    pumpScope.launch { for (c in rawPropertyChanges) propertyChanges.emit(c) }
    pumpScope.launch { for (m in rawLogMessages) logMessages.emit(m) }
  }

  val eventFlow: SharedFlow<MpvEvent> = events.asSharedFlow()
  val propertyFlow: SharedFlow<PropertyChange> = propertyChanges.asSharedFlow()
  val logFlow: SharedFlow<LogMessage> = logMessages.asSharedFlow()

  // Commands

  suspend fun command(vararg args: String) {
    checkNotClosed()
    withContext(Dispatchers.IO) { nativeCommand(args) }
  }

  /** Called on the core's ordered IO writer, without suspending between writes. */
  fun setLogLevel(level: String) {
    // Hold ownership through the native call: a retiring player's queued write
    // must never change the subscription of the process-global successor.
    synchronized(instance) {
      checkNotClosed()
      check(instance.get() === this) { "MpvPlayer is no longer active" }
      requestLogMessages(level)
    }
  }

  // Surface — not suspend, called from SurfaceHolder.Callback

  fun attachSurface(surface: Surface) {
    checkNotClosed()
    nativeAttachSurface(surface)
  }

  fun detachSurface() {
    checkNotClosed()
    nativeDetachSurface()
  }

  /** OSD/subtitle plane for `vo=mediacodec`; attach before selecting the VO. */
  fun attachOsdSurface(surface: Surface) {
    checkNotClosed()
    nativeAttachOsdSurface(surface)
  }

  fun detachOsdSurface() {
    checkNotClosed()
    nativeDetachOsdSurface()
  }

  // Property getters

  suspend fun getInt(name: String): Int? {
    checkNotClosed()
    return withContext(Dispatchers.IO) { nativeGetPropertyInt(name) }
  }

  suspend fun getDouble(name: String): Double? {
    checkNotClosed()
    return withContext(Dispatchers.IO) { nativeGetPropertyDouble(name) }
  }

  suspend fun getFlag(name: String): Boolean? {
    checkNotClosed()
    return withContext(Dispatchers.IO) { nativeGetPropertyBoolean(name) }
  }

  suspend fun getString(name: String): String? {
    checkNotClosed()
    return withContext(Dispatchers.IO) { nativeGetPropertyString(name) }
  }

  // Property setters

  suspend fun setProperty(name: String, value: Int) {
    checkNotClosed()
    withContext(Dispatchers.IO) { nativeSetPropertyInt(name, value) }
  }

  suspend fun setProperty(name: String, value: Double) {
    checkNotClosed()
    withContext(Dispatchers.IO) { nativeSetPropertyDouble(name, value) }
  }

  suspend fun setProperty(name: String, value: Boolean) {
    checkNotClosed()
    withContext(Dispatchers.IO) { nativeSetPropertyBoolean(name, value) }
  }

  suspend fun setProperty(name: String, value: String) {
    checkNotClosed()
    withContext(Dispatchers.IO) { nativeSetPropertyString(name, value) }
  }

  // Property observation

  fun observeProperty(name: String, format: PropertyFormat): Flow<PropertyChange> {
    checkNotClosed()
    nativeObserveProperty(name, format.nativeValue)
    return propertyFlow.filter { it.name == name }
  }

  fun observeFlag(name: String): Flow<Boolean> {
    checkNotClosed()
    nativeObserveProperty(name, PropertyFormat.Flag.nativeValue)
    return propertyFlow
      .filterIsInstance<PropertyChange.Flag>()
      .filter { it.name == name }
      .map { it.value }
  }

  fun observeInt(name: String): Flow<Long> {
    checkNotClosed()
    nativeObserveProperty(name, PropertyFormat.Int64.nativeValue)
    return propertyFlow
      .filterIsInstance<PropertyChange.Int64>()
      .filter { it.name == name }
      .map { it.value }
  }

  fun observeDouble(name: String): Flow<Double> {
    checkNotClosed()
    nativeObserveProperty(name, PropertyFormat.Double.nativeValue)
    return propertyFlow
      .filterIsInstance<PropertyChange.Double>()
      .filter { it.name == name }
      .map { it.value }
  }

  fun observeString(name: String): Flow<String> {
    checkNotClosed()
    nativeObserveProperty(name, PropertyFormat.String.nativeValue)
    return propertyFlow
      .filterIsInstance<PropertyChange.Str>()
      .filter { it.name == name }
      .map { it.value }
  }

  // Lifecycle

  @Volatile
  private var closed = false

  /**
   * Blocks until native teardown finishes. Callers must keep this off the
   * Android main thread so a slow vendor decoder cannot stall the UI.
   */
  override fun close() {
    val ownsNative = synchronized(instance) {
      if (closed) return
      checkNotMainThread("MPV destruction")
      closed = true
      // If create() replaced us, nativeCreate handles the leaked native session.
      instance.compareAndSet(this, null)
    }
    if (ownsNative) {
      nativeDestroy()
    }
    // After nativeDestroy no callback can produce: closing the channels
    // lets each pump drain what is already queued and then complete.
    rawEvents.close()
    rawHooks.close()
    rawPropertyChanges.close()
    rawLogMessages.close()
  }

  private fun checkNotClosed() {
    check(!closed) { "MpvPlayer has been closed" }
  }
}
