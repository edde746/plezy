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

/**
 * Kotlin face of the process-global native player. Each instance is bound to
 * one immutable native [session]; the JNI layer refuses any call that names
 * a session it has retired and Kotlin drops any callback stamped with a
 * session other than the published wrapper's. Together they make a retired
 * wrapper's in-flight work (a hook handler still reshaping tracks, a queued
 * property write, a late hook continuation) inert against its successor,
 * and keep a retiring core's tail events out of the successor's flows.
 */
class MpvPlayer private constructor(
  /** Identity of the native session this wrapper owns; see nativeCreate. */
  val session: Long
) : AutoCloseable {

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
      // Retires any leaked predecessor natively and mints the new session.
      val player = MpvPlayer(nativeCreate(context.applicationContext))
      synchronized(instance) {
        val current = instance.get()
        // Sessions are monotonic: a concurrent create that already published a
        // newer one has retired this native session underneath us.
        if (current != null && current.session > player.session) {
          player.closed = true
          throw MpvException("MPV session ${player.session} was superseded before it initialized")
        }
        instance.set(player)
        // The predecessor's native session is gone; its close() finds nothing to destroy.
        current?.closed = true
      }
      try {
        MpvPlayerConfig(player.session).apply(configure)
        val result = nativeInit(player.session)
        if (result < 0) throw MpvException("Failed to initialize mpv: error $result")
        ensureActive()
        player
      } catch (e: Throwable) {
        player.close()
        throw e
      }
    }

    // JNI callbacks — called from the native event thread. Each names the
    // session it originated from; only the wrapper published for that
    // session may receive it.

    private fun target(session: Long): MpvPlayer? = instance.get()?.takeIf { it.session == session }

    @JvmStatic
    fun onPropertyChanged(session: Long, name: String, sourceId: Long, hasSourceId: Boolean) {
      target(session)?.rawPropertyChanges?.trySend(
        PropertyChange.None(name, sourceId.takeIf { hasSourceId })
      )
    }

    @JvmStatic
    fun onPropertyChanged(session: Long, name: String, value: Boolean, sourceId: Long, hasSourceId: Boolean) {
      target(session)?.rawPropertyChanges?.trySend(
        PropertyChange.Flag(name, value, sourceId.takeIf { hasSourceId })
      )
    }

    @JvmStatic
    fun onPropertyChanged(session: Long, name: String, value: Long, sourceId: Long, hasSourceId: Boolean) {
      target(session)?.rawPropertyChanges?.trySend(
        PropertyChange.Int64(name, value, sourceId.takeIf { hasSourceId })
      )
    }

    @JvmStatic
    fun onPropertyChanged(session: Long, name: String, value: Double, sourceId: Long, hasSourceId: Boolean) {
      target(session)?.rawPropertyChanges?.trySend(
        PropertyChange.Double(name, value, sourceId.takeIf { hasSourceId })
      )
    }

    @JvmStatic
    fun onPropertyChanged(session: Long, name: String, value: String, sourceId: Long, hasSourceId: Boolean) {
      target(session)?.rawPropertyChanges?.trySend(
        PropertyChange.Str(name, value, sourceId.takeIf { hasSourceId })
      )
    }

    @JvmStatic
    fun onEvent(
      session: Long,
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
      target(session)?.rawEvents?.trySend(event)
    }

    @JvmStatic
    fun onEndFile(session: Long, reason: Int, sourceId: Long, hasSourceId: Boolean) {
      target(session)?.rawEvents?.trySend(
        MpvEvent.EndFile(
          EndFileReason.fromId(reason),
          sourceId.takeIf { hasSourceId }
        )
      )
    }

    @JvmStatic
    fun onLogMessage(session: Long, prefix: String, level: Int, text: String) {
      val logLevel = LogLevel.fromNative(level) ?: return
      target(session)?.rawLogMessages?.trySend(LogMessage(prefix, logLevel, text.trimEnd()))
    }

    @JvmStatic
    fun onHook(session: Long, name: String, id: Long) {
      val player = target(session)
      if (player == null || player.closed || !player.rawHooks.trySend(Hook(name, id)).isSuccess) {
        // Nobody will answer: release mpv rather than leave it waiting. The
        // native side drops this if the session has since been retired.
        nativeHookContinue(session, id)
      }
    }

    private fun checkNotMainThread(operation: String) {
      check(Looper.myLooper() != Looper.getMainLooper()) {
        "$operation must not run on the Android main thread"
      }
    }

    // JNI native declarations — private to avoid internal name mangling.
    // Every entry after nativeCreate names the session it acts for; the
    // native side refuses a retired one.

    /** Retires any leaked native session and returns the new session's identity. */
    @JvmStatic private external fun nativeCreate(appctx: Context): Long

    /** 0 on success, otherwise a negative mpv error. */
    @JvmStatic private external fun nativeInit(session: Long): Int

    @JvmStatic private external fun nativeDestroy(session: Long)

    /** Negative mpv error, the playlist entry id a `loadfile` created, or 0 when the command returned none. */
    @JvmStatic private external fun nativeCommand(session: Long, cmd: Array<out String>): Long

    @JvmStatic private external fun nativeSetLogLevel(session: Long, level: String): Int

    @JvmStatic private external fun nativeHookContinue(session: Long, id: Long)

    @JvmStatic private external fun nativeSetOptionString(session: Long, name: String, value: String): Int

    @JvmStatic private external fun nativeAttachSurface(session: Long, surface: Surface)

    @JvmStatic private external fun nativeDetachSurface(session: Long)

    @JvmStatic private external fun nativeAttachOsdSurface(session: Long, surface: Surface)

    @JvmStatic private external fun nativeDetachOsdSurface(session: Long)

    @JvmStatic private external fun nativeGetPropertyInt(session: Long, name: String): Int?

    @JvmStatic private external fun nativeGetPropertyDouble(session: Long, name: String): Double?

    @JvmStatic private external fun nativeGetPropertyBoolean(session: Long, name: String): Boolean?

    @JvmStatic private external fun nativeGetPropertyString(session: Long, name: String): String?

    @JvmStatic private external fun nativeSetPropertyInt(session: Long, name: String, value: Int)

    @JvmStatic private external fun nativeSetPropertyDouble(session: Long, name: String, value: Double)

    @JvmStatic private external fun nativeSetPropertyBoolean(session: Long, name: String, value: Boolean)

    @JvmStatic private external fun nativeSetPropertyString(session: Long, name: String, value: String)

    @JvmStatic private external fun nativeObserveProperty(session: Long, name: String, format: Int)

    internal fun setOptionString(session: Long, name: String, value: String): Int = nativeSetOptionString(session, name, value)

    internal fun requestLogMessages(session: Long, level: String) {
      checkNotMainThread("MPV log level change")
      val result = nativeSetLogLevel(session, level)
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
          val handler = if (closed) null else hookHandler
          if (handler != null) {
            withTimeoutOrNull(HOOK_TIMEOUT_MS) { handler(hook.name) }
              ?: android.util.Log.w("MpvPlayer", "Hook ${hook.name} handler overran; continuing playback")
          }
        } catch (e: Exception) {
          android.util.Log.w("MpvPlayer", "Hook ${hook.name} handler failed; continuing playback", e)
        } finally {
          // Validated natively against this session, atomically with its
          // retirement: a continuation that lost the race is dropped, never
          // delivered to a successor's core.
          nativeHookContinue(session, hook.id)
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

  /**
   * Runs an mpv command. `loadfile` returns the id of the playlist entry it created — the
   * `sourceId` carried by that source's start-file / playback-restart / end-file events; every
   * other command returns null. A command mpv rejects throws [MpvException]: a rejected load
   * never produces a source, so the caller must not wait for one.
   */
  suspend fun command(vararg args: String): Long? {
    checkNotClosed()
    val status = withContext(Dispatchers.IO) { nativeCommand(session, args) }
    if (status < 0) throw MpvException("Command '${args.firstOrNull() ?: ""}' failed: error $status")
    return if (status > 0) status else null
  }

  /** Called on the core's ordered IO writer, without suspending between writes. */
  fun setLogLevel(level: String) {
    checkNotClosed()
    requestLogMessages(session, level)
  }

  // Surface — not suspend, called from SurfaceHolder.Callback

  fun attachSurface(surface: Surface) {
    checkNotClosed()
    nativeAttachSurface(session, surface)
  }

  fun detachSurface() {
    checkNotClosed()
    nativeDetachSurface(session)
  }

  /** OSD/subtitle plane for `vo=mediacodec`; attach before selecting the VO. */
  fun attachOsdSurface(surface: Surface) {
    checkNotClosed()
    nativeAttachOsdSurface(session, surface)
  }

  fun detachOsdSurface() {
    checkNotClosed()
    nativeDetachOsdSurface(session)
  }

  // Property getters

  suspend fun getInt(name: String): Int? {
    checkNotClosed()
    return withContext(Dispatchers.IO) { nativeGetPropertyInt(session, name) }
  }

  suspend fun getDouble(name: String): Double? {
    checkNotClosed()
    return withContext(Dispatchers.IO) { nativeGetPropertyDouble(session, name) }
  }

  suspend fun getFlag(name: String): Boolean? {
    checkNotClosed()
    return withContext(Dispatchers.IO) { nativeGetPropertyBoolean(session, name) }
  }

  suspend fun getString(name: String): String? {
    checkNotClosed()
    return withContext(Dispatchers.IO) { nativeGetPropertyString(session, name) }
  }

  // Property setters

  suspend fun setProperty(name: String, value: Int) {
    checkNotClosed()
    withContext(Dispatchers.IO) { nativeSetPropertyInt(session, name, value) }
  }

  suspend fun setProperty(name: String, value: Double) {
    checkNotClosed()
    withContext(Dispatchers.IO) { nativeSetPropertyDouble(session, name, value) }
  }

  suspend fun setProperty(name: String, value: Boolean) {
    checkNotClosed()
    withContext(Dispatchers.IO) { nativeSetPropertyBoolean(session, name, value) }
  }

  suspend fun setProperty(name: String, value: String) {
    checkNotClosed()
    withContext(Dispatchers.IO) { nativeSetPropertyString(session, name, value) }
  }

  // Property observation

  fun observeProperty(name: String, format: PropertyFormat): Flow<PropertyChange> {
    checkNotClosed()
    nativeObserveProperty(session, name, format.nativeValue)
    return propertyFlow.filter { it.name == name }
  }

  fun observeFlag(name: String): Flow<Boolean> {
    checkNotClosed()
    nativeObserveProperty(session, name, PropertyFormat.Flag.nativeValue)
    return propertyFlow
      .filterIsInstance<PropertyChange.Flag>()
      .filter { it.name == name }
      .map { it.value }
  }

  fun observeInt(name: String): Flow<Long> {
    checkNotClosed()
    nativeObserveProperty(session, name, PropertyFormat.Int64.nativeValue)
    return propertyFlow
      .filterIsInstance<PropertyChange.Int64>()
      .filter { it.name == name }
      .map { it.value }
  }

  fun observeDouble(name: String): Flow<Double> {
    checkNotClosed()
    nativeObserveProperty(session, name, PropertyFormat.Double.nativeValue)
    return propertyFlow
      .filterIsInstance<PropertyChange.Double>()
      .filter { it.name == name }
      .map { it.value }
  }

  fun observeString(name: String): Flow<String> {
    checkNotClosed()
    nativeObserveProperty(session, name, PropertyFormat.String.nativeValue)
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
    synchronized(instance) {
      if (closed) return
      checkNotMainThread("MPV destruction")
      closed = true
      hookHandler = null
      instance.compareAndSet(this, null)
    }
    // A no-op natively when a later create() already retired this session;
    // the successor is never ours to destroy.
    nativeDestroy(session)
    // After nativeDestroy no callback can produce for this session: closing
    // the channels lets each pump drain what is already queued and complete.
    rawEvents.close()
    rawHooks.close()
    rawPropertyChanges.close()
    rawLogMessages.close()
  }

  private fun checkNotClosed() {
    check(!closed) { "MpvPlayer has been closed" }
  }
}
