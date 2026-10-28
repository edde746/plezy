// SPDX-License-Identifier: GPL-3.0-or-later
package org.snapetech.plezyng.games.steam;

import android.content.Context;
import android.graphics.Color;
import android.hardware.input.InputManager;
import android.os.Handler;
import android.os.Looper;
import android.view.Gravity;
import android.view.InputDevice;
import android.view.KeyEvent;
import android.view.MotionEvent;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.View;
import android.widget.FrameLayout;
import android.widget.TextView;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.Arrays;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;

/** A retained Steam stream surface used by Plezy's app-owned workspace. */
public final class SteamStreamView
    extends FrameLayout implements SurfaceHolder.Callback, InputManager.InputDeviceListener {
  private final Context context;
  private final Map<?, ?> args;
  private final SteamStreamOptions options;
  private final Handler main = new Handler(Looper.getMainLooper());
  private final SteamControllerSeats controllerSeats;
  private final InputManager inputManager;
  private short[] touch = new short[6];
  private int touchButtons;
  private final Set<Integer> heldKeys = new HashSet<>();
  private final SteamControllerState controller = new SteamControllerState();
  private final SurfaceView surface;
  private final TextView status;
  private final SteamControls controls;
  private Runnable onFailure;
  private Runnable onStateChanged;
  private String sessionState = "connecting";
  private volatile long handle;
  private volatile SteamDecoder decoder;
  private volatile Thread sessionThread;
  private volatile boolean stopping;
  private boolean started, shown, failed, inputEnabled;
  private volatile boolean requestedAudio;

  public SteamStreamView(Context context, Map<?, ?> args) {
    super(context);
    this.context = context;
    this.args = args;
    this.options = SteamStreamOptions.from(args);
    controllerSeats = new SteamControllerSeats(options.controllerCount);
    inputManager = (InputManager) context.getSystemService(Context.INPUT_SERVICE);
    if (inputManager != null)
      inputManager.registerInputDeviceListener(this, main);
    setBackgroundColor(Color.BLACK);
    setFocusable(true);
    setFocusableInTouchMode(true);
    surface = new SurfaceView(context);
    addView(surface, new FrameLayout.LayoutParams(-1, -1, Gravity.CENTER));
    surface.getHolder().addCallback(this);
    controls = new SteamControls(
        context, Boolean.TRUE.equals(args.get("touchControls")), label("touchLabel", "On-screen controller"),
        new SteamControls.Listener() {
          @Override
          public void pad(short[] axes, int buttons) {
            if (!inputEnabled) {
              touch = new short[6];
              touchButtons = 0;
              sendPad(0);
              return;
            }
            touch = axes;
            touchButtons = buttons;
            sendPad(0);
          }
          @Override
          public void mouse(float x, float y, int button, boolean down) {
            long session = handle;
            // Allow a release during ownership handoff, but never start a click
            // from a pane that no longer owns game input.
            if (session == 0 || stopping || (down && !inputEnabled))
              return;
            float sx = (x * getWidth() - surface.getLeft()) / Math.max(1, surface.getWidth());
            float sy = (y * getHeight() - surface.getTop()) / Math.max(1, surface.getHeight());
            NativeSteam.mouse(session, sx, sy, button, down);
          }
        });
    controls.setEnabled(false);
    addView(controls, new FrameLayout.LayoutParams(-1, -1));
    status = new TextView(context);
    status.setText(label("connecting", "Connecting…"));
    status.setTextColor(getResources().getColor(R.color.plezy_steam_text));
    status.setGravity(Gravity.CENTER);
    status.setClickable(false);
    addView(status, new FrameLayout.LayoutParams(-1, -1));
    setAudioEnabled(Boolean.TRUE.equals(args.get("audioEnabled")));
  }

  public void setAudioEnabled(boolean enabled) {
    requestedAudio = enabled;
    SteamDecoder current = decoder;
    if (current != null)
      current.setVolume(enabled ? 1.0f : 0.0f);
  }

  public void setOnFailure(Runnable callback) {
    onFailure = callback;
  }
  public void setOnStateChanged(Runnable callback) {
    onStateChanged = callback;
  }
  public String getSessionState() {
    return sessionState;
  }
  public Map<String, Object> getStreamMetrics() {
    long current = handle;
    long[] values = current == 0 || stopping ? null : NativeSteam.metrics(current);
    if (values == null || values.length != 24 || values[0] != 1)
      return null;
    String[] keys = {"version",         "sampledAtUs",     "receivedFrames",  "presentedFrames",
                     "droppedFrames",   "resetFrames",     "videoBytes",      "completionTotalUs",
                     "completedFrames", "width",           "height",          "codec",
                     "audioChannels",   "fpsNumerator",    "fpsDenominator",  "fpsReasons",
                     "targetBitrate",   "reliableRetries", "reliableGiveUps", "reliableOutstanding",
                     "maxAckLatencyMs", "hidPending",      "hidInFlight",     "epoch"};
    Map<String, Object> metrics = new HashMap<>();
    for (int i = 0; i < keys.length; i++) metrics.put(keys[i], values[i]);
    SteamDecoder currentDecoder = decoder;
    if (currentDecoder != null)
      currentDecoder.appendMetrics(metrics);
    return metrics;
  }
  private void state(String value) {
    sessionState = value;
    Runnable callback = onStateChanged;
    if (callback != null)
      callback.run();
  }
  public boolean isFailed() {
    return failed;
  }
  public void toggleTouchControls() {
    controls.toggle();
  }

  public void setInputEnabled(boolean enabled) {
    if (inputEnabled == enabled)
      return;
    if (!enabled)
      releaseInput();
    inputEnabled = enabled;
    controls.setInputEnabled(enabled);
    controls.setEnabled(enabled && Boolean.TRUE.equals(args.get("touchControls")));
    if (enabled)
      requestFocus();
    else
      clearFocus();
  }

  public void setControllerState(Map<?, ?> buttons, Map<?, ?> axes) {
    controller.reset();
    if (!inputEnabled || stopping) {
      sendPad(0);
      return;
    }
    if (buttons != null) {
      for (Map.Entry<?, ?> entry : buttons.entrySet()) {
        if (entry.getKey() instanceof String key && entry.getValue() instanceof Boolean pressed) {
          controller.setButton(key, pressed);
        }
      }
    }
    if (axes != null) {
      for (Map.Entry<?, ?> entry : axes.entrySet()) {
        if (entry.getKey() instanceof String key && entry.getValue() instanceof Number value) {
          controller.setAxis(key, value.doubleValue());
        }
      }
    }
    sendPad(0);
  }

  /**
   * Partial updates preserve native axes when Flutter only forwards a button.
   * Both paths use the Android device ID, so one controller never gets two seats.
   */
  public void setControllerDeviceState(int deviceId, Map<?, ?> buttons, Map<?, ?> axes) {
    if (!inputEnabled || stopping || buttons == null || axes == null || buttons.size() > 32 || axes.size() > 8)
      return;
    int seat = controllerSeats.seat(deviceId);
    if (seat < 0)
      return;
    SteamControllerState state = controllerSeats.state(seat);
    for (Map.Entry<?, ?> entry : buttons.entrySet()) {
      if (entry.getKey() instanceof String key && entry.getValue() instanceof Boolean pressed)
        state.setButton(key, pressed);
    }
    for (Map.Entry<?, ?> entry : axes.entrySet()) {
      if (entry.getKey() instanceof String key && entry.getValue() instanceof Number value)
        state.setAxis(key, value.doubleValue());
    }
    sendPad(seat);
  }

  public void disconnectController(int deviceId) {
    int seat = controllerSeats.disconnect(deviceId);
    // A composite device can supply both navigation keys and a gamepad.
    // Resend unchanged seats too, so both representations release together.
    if (seat >= 0)
      for (int i = 0; i < controllerSeats.count(); i++) sendPad(i);
  }

  @Override
  public void onInputDeviceAdded(int deviceId) {}
  @Override
  public void onInputDeviceChanged(int deviceId) {
    disconnectController(deviceId);
  }
  @Override
  public void onInputDeviceRemoved(int deviceId) {
    disconnectController(deviceId);
  }

  public void inputKey(String name, boolean down) {
    if (!inputEnabled || stopping)
      return;
    int usage = keyUsage(name);
    long session = handle;
    if (usage == 0 || session == 0)
      return;
    if (down)
      heldKeys.add(usage);
    else
      heldKeys.remove(usage);
    NativeSteam.key(session, usage, down);
  }

  public void resetInput() {
    releaseInput();
  }

  public void close() {
    stop();
    surface.getHolder().removeCallback(this);
  }

  /** Called off the UI thread after close; never start a replacement over a live worker. */
  public void awaitTermination() throws InterruptedException {
    Thread worker = sessionThread;
    if (worker == null)
      return;
    worker.join(5000);
    if (worker.isAlive())
      throw new IllegalStateException("Steam session is still stopping");
  }

  @Override
  protected void onDetachedFromWindow() {
    stop();
    super.onDetachedFromWindow();
  }

  private String label(String key, String fallback) {
    Object value = args.get(key);
    return value instanceof String ? (String) value : fallback;
  }

  @Override
  public void surfaceCreated(SurfaceHolder holder) {
    if (started || stopping)
      return;
    started = true;
    long created = NativeSteam.create();
    if (created == 0) {
      failOnMain();
      return;
    }
    handle = created;
    sessionThread = new Thread(() -> runSession(created, holder), "PlezySteamWorkspaceSession");
    sessionThread.setDaemon(true);
    sessionThread.start();
    main.postDelayed(() -> {
      // Bound DNS/trust/probe setup separately from a connected attempt.
      if (!shown && !stopping && handle == created && decoder == null)
        failOnMain(created);
    }, 30000);
  }

  private void runSession(long initialHandle, SurfaceHolder holder) {
    long session = initialHandle;
    byte[] record = null, key = null;
    try {
      String address = EmbeddedSteam.resolve(text("address"));
      if (stopping)
        return;
      SteamTrust trust = new SteamTrust(context);
      record = trust.load(text("hostKey"));
      long user = ByteBuffer.wrap(record).order(ByteOrder.LITTLE_ENDIAN).getLong();
      key = Arrays.copyOfRange(record, 8, 40);
      boolean pyrowave = Boolean.TRUE.equals(args.get("pyrowave")) && NativeSteam.pyrowaveSupported();
      boolean hevc = options.allowHevc && SteamDecoder.supportsHevc();
      int audioChannels = options.audioChannels;
      // Each fallback removes a capability; at most four attempts, never a
      // reconnect loop. The prior transport has returned before replacement.
      for (int attempt = 0; attempt < 4 && !stopping; attempt++) {
        SteamDecoder sink = new SteamDecoder(session, holder, decoderEvents(session));
        decoder = sink;
        sink.setVolume(requestedAudio ? 1.0f : 0.0f);
        if (stopping) {
          sink.close();
          break;
        }
        final long attemptHandle = session;
        main.postDelayed(() -> {
          // The native core bounds launch, connect and first frame separately.
          // An old attempt's UI timer must never cancel its replacement.
          if (!shown && !stopping && handle == attemptHandle)
            failOnMain(attemptHandle);
        }, 75000);
        Exception failure = null;
        try {
          NativeSteam.runWithAudio(
              session, address, port(), hostId(), trust.device(), user, key, gameId(), hevc, pyrowave, options.width,
              options.height, options.fps, options.bitrateKbps, options.controllerCount, audioChannels, sink);
        } catch (Exception error) {
          failure = error;
        }
        sink.close();
        sink.awaitTermination();
        long[] metrics = NativeSteam.metrics(session);
        boolean noFrames = metrics != null && metrics.length == 24 && metrics[3] == 0;
        boolean dropPyrowave =
            pyrowave && (sink.consumePyrowaveFallback() || (failure != null && noFrames && metrics[11] == 9));
        boolean dropHevc = hevc && (sink.consumeHevcFallback() || (failure != null && noFrames && metrics[11] == 5));
        boolean audioFailed = sink.consumeAudioFallback();
        boolean dropSurround = audioChannels > 2 && audioFailed;
        if (stopping || (!dropPyrowave && !dropHevc && !dropSurround)) {
          if (failure != null)
            throw failure;
          if (!stopping && audioFailed)
            throw new IllegalStateException("Steam audio output failed");
          break;
        }
        if (dropPyrowave)
          pyrowave = false;
        if (dropHevc)
          hevc = false;
        if (dropSurround)
          audioChannels = 2;
        NativeSteam.destroy(session);
        session = NativeSteam.create();
        handle = session;
        if (session == 0)
          throw new IllegalStateException("Steam compatibility reconnect failed");
        main.post(() -> {
          if (!stopping) {
            shown = false;
            releaseInput();
            state("reconnecting");
            status.setText(label("connecting", "Connecting…"));
            status.setVisibility(View.VISIBLE);
          }
        });
      }
    } catch (Exception error) {
      failOnMain();
    } finally {
      if (record != null)
        Arrays.fill(record, (byte) 0);
      if (key != null)
        Arrays.fill(key, (byte) 0);
      SteamDecoder current = decoder;
      if (current != null) {
        current.close();
        current.awaitTermination();
      }
      NativeSteam.destroy(session);
      if (handle == session)
        handle = 0;
      main.post(() -> {
        if (!failed && !stopping) {
          releaseInput();
          state("disconnected");
          status.setText(label("disconnected", "Disconnected"));
          status.setVisibility(View.VISIBLE);
        }
      });
    }
  }

  private String text(String key) {
    Object value = args.get(key);
    if (!(value instanceof String) || ((String) value).length() > 256)
      throw new IllegalArgumentException("Invalid argument");
    return (String) value;
  }
  private int port() {
    Object value = args.get("port");
    int port = value instanceof Number ? ((Number) value).intValue() : 27036;
    if (port < 1 || port > 65535)
      throw new IllegalArgumentException("Invalid port");
    return port;
  }
  private long hostId() {
    return Long.parseUnsignedLong(text("hostId"));
  }
  private long gameId() {
    return Long.parseUnsignedLong(text("appId"));
  }

  @Override
  public void surfaceChanged(SurfaceHolder holder, int format, int width, int height) {}
  @Override
  public void surfaceDestroyed(SurfaceHolder holder) {
    stop();
  }

  private SteamDecoder.Events decoderEvents(final long source) {
    return new SteamDecoder.Events() {
      @Override
      public void size(int width, int height) {
        streamSize(source, width, height);
      }
      @Override
      public void firstFrame() {
        streamFirstFrame(source);
      }
      @Override
      public void failed() {
        failOnMain(source);
      }
      @Override
      public void audioFailed() {
        compatibilityFallback(source);
      }
      @Override
      public void pyrowaveFailed() {
        compatibilityFallback(source);
      }
      @Override
      public void hevcFailed() {
        compatibilityFallback(source);
      }
    };
  }
  private void streamSize(long source, int width, int height) {
    main.post(() -> {
      if (stopping || source != handle || width < 1 || height < 1)
        return;
      int w = getWidth(), h = getHeight();
      if (w < 1 || h < 1)
        return;
      float scale = Math.min((float) w / width, (float) h / height);
      surface.setLayoutParams(
          new FrameLayout.LayoutParams(Math.round(width * scale), Math.round(height * scale), Gravity.CENTER));
    });
  }

  private void streamFirstFrame(long source) {
    main.post(() -> {
      if (stopping || source != handle)
        return;
      shown = true;
      status.setVisibility(View.GONE);
      state("playing");
    });
  }

  private void compatibilityFallback(long source) {
    main.post(() -> {
      if (stopping || source != handle)
        return;
      status.setText(label("connecting", "Connecting…"));
      status.setVisibility(View.VISIBLE);
      if (source != 0)
        NativeSteam.cancel(source);
    });
  }

  private void failOnMain() {
    failOnMain(handle);
  }
  private void failOnMain(long source) {
    main.post(() -> {
      if (stopping || failed || (source != 0 && source != handle))
        return;
      failed = true;
      state("failed");
      status.setText(label("error", "The stream could not start. Check pairing and the host."));
      status.setVisibility(View.VISIBLE);
      stop();
      Runnable callback = onFailure;
      if (callback != null)
        callback.run();
    });
  }

  private void stop() {
    if (stopping)
      return;
    // Send the neutral controller packet while the transport is still live.
    // Setting stopping first caused sendPad() to discard this release.
    releaseInput();
    stopping = true;
    if (inputManager != null)
      inputManager.unregisterInputDeviceListener(this);
    main.removeCallbacksAndMessages(null);
    if (!failed)
      state("disconnected");
    long session = handle;
    if (session != 0)
      NativeSteam.cancel(session);
    SteamDecoder current = decoder;
    if (current != null)
      current.close();
  }

  private void releaseInput() {
    controls.reset();
    controller.reset();
    controllerSeats.reset();
    Arrays.fill(touch, (short) 0);
    touchButtons = 0;
    long session = handle;
    if (session != 0)
      for (int usage : heldKeys) NativeSteam.key(session, usage, false);
    heldKeys.clear();
    for (int seat = 0; seat < controllerSeats.count(); seat++) sendPad(seat);
  }

  private void sendPad(int seat) {
    long session = handle;
    if (session == 0 || stopping)
      return;
    SteamControllerState state = controllerSeats.state(seat);
    short[] combined = state.axes();
    int buttons = state.buttons();
    if (seat == 0) {
      // Touch and the legacy single-pad API assist player one only.
      short[] external = controller.axes();
      for (int i = 0; i < combined.length; i++) {
        if (Math.abs((int) touch[i]) > Math.abs((int) combined[i]))
          combined[i] = touch[i];
        if (Math.abs((int) external[i]) > Math.abs((int) combined[i]))
          combined[i] = external[i];
      }
      buttons |= touchButtons | controller.buttons() | controllerSeats.navigation().buttons();
    }
    NativeSteam.padSeat(session, seat, combined, buttons);
  }

  @Override
  public boolean dispatchKeyEvent(KeyEvent event) {
    long session = handle;
    if (!inputEnabled || session == 0 || stopping)
      return super.dispatchKeyEvent(event);
    if (event.getKeyCode() == KeyEvent.KEYCODE_BACK)
      return super.dispatchKeyEvent(event);
    boolean down = event.getAction() == KeyEvent.ACTION_DOWN;
    int bit = button(event.getKeyCode());
    boolean gamepad = event.isFromSource(InputDevice.SOURCE_GAMEPAD) || event.isFromSource(InputDevice.SOURCE_DPAD)
        || event.isFromSource(InputDevice.SOURCE_JOYSTICK);
    if (gamepad
        && (bit >= 0 || event.getKeyCode() == KeyEvent.KEYCODE_BUTTON_L2
            || event.getKeyCode() == KeyEvent.KEYCODE_BUTTON_R2)) {
      InputDevice device = event.getDevice();
      int sources = device == null ? event.getSource() : device.getSources();
      boolean physicalPad = (sources & InputDevice.SOURCE_GAMEPAD) == InputDevice.SOURCE_GAMEPAD
          || (sources & InputDevice.SOURCE_JOYSTICK) == InputDevice.SOURCE_JOYSTICK;
      if (!physicalPad) {
        controllerSeats.navigationButton(event.getDeviceId(), bit, down);
        sendPad(0);
        return true;
      }
      int seat = controllerSeats.seat(event.getDeviceId());
      if (seat < 0)
        return true;
      SteamControllerState state = controllerSeats.state(seat);
      if (bit >= 0)
        state.setButtonBit(bit, down);
      else
        state.setAxis(event.getKeyCode() == KeyEvent.KEYCODE_BUTTON_L2 ? "leftTrigger" : "rightTrigger", down ? 1 : 0);
      sendPad(seat);
      return true;
    }
    int usage = keyUsage(event.getKeyCode());
    if (usage != 0) {
      if (down)
        heldKeys.add(usage);
      else
        heldKeys.remove(usage);
      NativeSteam.key(session, usage, down);
      return true;
    }
    return super.dispatchKeyEvent(event);
  }

  @Override
  public boolean onGenericMotionEvent(MotionEvent event) {
    if (inputEnabled && handle != 0 && !stopping && event.isFromSource(InputDevice.SOURCE_JOYSTICK)) {
      int seat = controllerSeats.seat(event.getDeviceId());
      if (seat < 0)
        return true;
      SteamControllerState state = controllerSeats.state(seat);
      int[] axes = {MotionEvent.AXIS_X,  MotionEvent.AXIS_Y,        MotionEvent.AXIS_Z,
                    MotionEvent.AXIS_RZ, MotionEvent.AXIS_LTRIGGER, MotionEvent.AXIS_RTRIGGER};
      String[] names = {"leftStickX", "leftStickY", "rightStickX", "rightStickY", "leftTrigger", "rightTrigger"};
      for (int i = 0; i < axes.length; i++) {
        float value = event.getAxisValue(axes[i]);
        if (Math.abs(value) < .12f)
          value = 0;
        state.setAxis(names[i], value);
      }
      float x = event.getAxisValue(MotionEvent.AXIS_HAT_X), y = event.getAxisValue(MotionEvent.AXIS_HAT_Y);
      state.setButtonBit(11, y < -.5f);
      state.setButtonBit(12, y > .5f);
      state.setButtonBit(13, x < -.5f);
      state.setButtonBit(14, x > .5f);
      sendPad(seat);
      return true;
    }
    return super.onGenericMotionEvent(event);
  }

  private static int button(int key) {
    return switch (key) {
      case KeyEvent.KEYCODE_BUTTON_A, KeyEvent.KEYCODE_DPAD_CENTER -> 0;
      case KeyEvent.KEYCODE_BUTTON_B -> 1;
      case KeyEvent.KEYCODE_BUTTON_X -> 2;
      case KeyEvent.KEYCODE_BUTTON_Y -> 3;
      case KeyEvent.KEYCODE_BUTTON_SELECT -> 4;
      case KeyEvent.KEYCODE_BUTTON_MODE -> 5;
      case KeyEvent.KEYCODE_BUTTON_START -> 6;
      case KeyEvent.KEYCODE_BUTTON_THUMBL -> 7;
      case KeyEvent.KEYCODE_BUTTON_THUMBR -> 8;
      case KeyEvent.KEYCODE_BUTTON_L1 -> 9;
      case KeyEvent.KEYCODE_BUTTON_R1 -> 10;
      case KeyEvent.KEYCODE_DPAD_UP -> 11;
      case KeyEvent.KEYCODE_DPAD_DOWN -> 12;
      case KeyEvent.KEYCODE_DPAD_LEFT -> 13;
      case KeyEvent.KEYCODE_DPAD_RIGHT -> 14;
      default -> -1;
    };
  }

  private static int keyUsage(int key) {
    if (key >= KeyEvent.KEYCODE_A && key <= KeyEvent.KEYCODE_Z) return key - KeyEvent.KEYCODE_A + 4;
    if (key >= KeyEvent.KEYCODE_1 && key <= KeyEvent.KEYCODE_9) return key - KeyEvent.KEYCODE_1 + 30;
    if (key >= KeyEvent.KEYCODE_F1 && key <= KeyEvent.KEYCODE_F12) return key - KeyEvent.KEYCODE_F1 + 58;
    return switch (key) {
      case KeyEvent.KEYCODE_0 -> 39;
      case KeyEvent.KEYCODE_ENTER -> 40;
      case KeyEvent.KEYCODE_ESCAPE -> 41;
      case KeyEvent.KEYCODE_DEL -> 42;
      case KeyEvent.KEYCODE_TAB -> 43;
      case KeyEvent.KEYCODE_SPACE -> 44;
      case KeyEvent.KEYCODE_SHIFT_LEFT -> 225;
      case KeyEvent.KEYCODE_SHIFT_RIGHT -> 229;
      case KeyEvent.KEYCODE_CTRL_LEFT -> 224;
      case KeyEvent.KEYCODE_CTRL_RIGHT -> 228;
      case KeyEvent.KEYCODE_ALT_LEFT -> 226;
      case KeyEvent.KEYCODE_ALT_RIGHT -> 230;
      case KeyEvent.KEYCODE_DPAD_RIGHT -> 79;
      case KeyEvent.KEYCODE_DPAD_LEFT -> 80;
      case KeyEvent.KEYCODE_DPAD_DOWN -> 81;
      case KeyEvent.KEYCODE_DPAD_UP -> 82;
      default -> 0;
    };
  }

  private static int keyUsage(String name) {
    if (name == null) return 0;
    String key = name.replaceAll("[^A-Za-z0-9]", "").toLowerCase(java.util.Locale.ROOT);
    if (key.length() == 1 && key.charAt(0) >= 'a' && key.charAt(0) <= 'z') return key.charAt(0) - 'a' + 4;
    if (key.length() == 1 && key.charAt(0) >= '1' && key.charAt(0) <= '9') return key.charAt(0) - '1' + 30;
    if (key.startsWith("key") && key.length() == 4 && key.charAt(3) >= 'a' && key.charAt(3) <= 'z') {
      return key.charAt(3) - 'a' + 4;
    }
    if (key.startsWith("digit") && key.length() == 6 && key.charAt(5) >= '1' && key.charAt(5) <= '9') {
      return key.charAt(5) - '1' + 30;
    }
    return switch (key) {
      case "key0", "digit0", "0" -> 39;
      case "enter", "numpadenter" -> 40;
      case "escape" -> 41;
      case "backspace", "delete" -> 42;
      case "tab" -> 43;
      case "space" -> 44;
      case "shiftleft" -> 225;
      case "shiftright" -> 229;
      case "controlleft", "ctrlleft" -> 224;
      case "controlright", "ctrlright" -> 228;
      case "altleft" -> 226;
      case "altright" -> 230;
      case "arrowright", "right" -> 79;
      case "arrowleft", "left" -> 80;
      case "arrowdown", "down" -> 81;
      case "arrowup", "up" -> 82;
      default -> 0;
    };
  }
}
