// SPDX-License-Identifier: GPL-3.0-or-later
package org.snapetech.plezyng.games.steam;

import android.content.Context;
import android.graphics.Color;
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
import java.util.HashSet;
import java.util.Map;
import java.util.Set;

/** A retained Steam stream surface used by Plezy's app-owned workspace. */
public final class SteamStreamView extends FrameLayout implements SurfaceHolder.Callback, SteamDecoder.Events {
  private final Context context;
  private final Map<?, ?> args;
  private final Handler main = new Handler(Looper.getMainLooper());
  private final short[] physical = new short[6];
  private short[] touch = new short[6];
  private int physicalButtons, touchButtons;
  private final Set<Integer> heldKeys = new HashSet<>();
  private final SteamControllerState controller = new SteamControllerState();
  private final SurfaceView surface;
  private final TextView status;
  private final SteamControls controls;
  private Runnable onFailure;
  private volatile long handle;
  private volatile SteamDecoder decoder;
  private volatile boolean stopping;
  private boolean started, shown, failed, inputEnabled;
  private volatile boolean requestedAudio;

  public SteamStreamView(Context context, Map<?, ?> args) {
    super(context);
    this.context = context;
    this.args = args;
    setBackgroundColor(Color.BLACK);
    setFocusable(true);
    setFocusableInTouchMode(true);
    surface = new SurfaceView(context);
    addView(surface, new FrameLayout.LayoutParams(-1, -1, Gravity.CENTER));
    surface.getHolder().addCallback(this);
    controls = new SteamControls(context, Boolean.TRUE.equals(args.get("touchControls")), new SteamControls.Listener() {
      @Override public void pad(short[] axes, int buttons) {
        if (!inputEnabled) {
          touch = new short[6];
          touchButtons = 0;
          sendPad();
          return;
        }
        touch = axes;
        touchButtons = buttons;
        sendPad();
      }
      @Override public void mouse(float x, float y, int button, boolean down) {
        long session = handle;
        // Allow a release during ownership handoff, but never start a click
        // from a pane that no longer owns game input.
        if (session == 0 || stopping || (down && !inputEnabled)) return;
        float sx = (x * getWidth() - surface.getLeft()) / Math.max(1, surface.getWidth());
        float sy = (y * getHeight() - surface.getTop()) / Math.max(1, surface.getHeight());
        NativeSteam.mouse(session, sx, sy, button, down);
      }
    });
    controls.setEnabled(false);
    addView(controls, new FrameLayout.LayoutParams(-1, -1));
    status = new TextView(context);
    status.setText(label("connecting", "Connecting…"));
    status.setTextColor(Color.WHITE);
    status.setGravity(Gravity.CENTER);
    status.setClickable(false);
    addView(status, new FrameLayout.LayoutParams(-1, -1));
    setAudioEnabled(Boolean.TRUE.equals(args.get("audioEnabled")));
  }

  public void setAudioEnabled(boolean enabled) {
    requestedAudio = enabled;
    SteamDecoder current = decoder;
    if (current != null) current.setVolume(enabled ? 1.0f : 0.0f);
  }

  public void setOnFailure(Runnable callback) { onFailure = callback; }
  public boolean isFailed() { return failed; }
  public void toggleTouchControls() { controls.toggle(); }

  public void setInputEnabled(boolean enabled) {
    if (inputEnabled == enabled) return;
    if (!enabled) releaseInput();
    inputEnabled = enabled;
    controls.setInputEnabled(enabled);
    controls.setEnabled(enabled && Boolean.TRUE.equals(args.get("touchControls")));
    if (enabled) requestFocus();
    else clearFocus();
  }

  public void setControllerState(Map<?, ?> buttons, Map<?, ?> axes) {
    controller.reset();
    if (!inputEnabled || stopping) {
      sendPad();
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
    sendPad();
  }

  public void inputKey(String name, boolean down) {
    if (!inputEnabled || stopping) return;
    int usage = keyUsage(name);
    long session = handle;
    if (usage == 0 || session == 0) return;
    if (down) heldKeys.add(usage);
    else heldKeys.remove(usage);
    NativeSteam.key(session, usage, down);
  }

  public void resetInput() {
    releaseInput();
  }

  public void close() {
    stop();
    surface.getHolder().removeCallback(this);
  }

  @Override protected void onDetachedFromWindow() {
    stop();
    super.onDetachedFromWindow();
  }

  private String label(String key, String fallback) {
    Object value = args.get(key);
    return value instanceof String ? (String) value : fallback;
  }

  @Override public void surfaceCreated(SurfaceHolder holder) {
    if (started || stopping) return;
    started = true;
    long created = NativeSteam.create();
    if (created == 0) {
      failOnMain();
      return;
    }
    handle = created;
    Thread sessionThread = new Thread(() -> runSession(created, holder), "PlezySteamWorkspaceSession");
    sessionThread.setDaemon(true);
    sessionThread.start();
    main.postDelayed(() -> {
      if (stopping || shown) return;
      SteamDecoder current = decoder;
      if (current != null) current.requestPyrowaveFallback();
    }, 12000);
    main.postDelayed(() -> {
      if (!shown && !stopping) failOnMain();
    }, 30000);
  }

  private void runSession(long initialHandle, SurfaceHolder holder) {
    long session = initialHandle;
    byte[] record = null, key = null;
    try {
      String address = EmbeddedSteam.resolve(text("address"));
      if (stopping) return;
      SteamTrust trust = new SteamTrust(context);
      record = trust.load(text("hostKey"));
      long user = ByteBuffer.wrap(record).order(ByteOrder.LITTLE_ENDIAN).getLong();
      key = Arrays.copyOfRange(record, 8, 40);
      SteamDecoder sink = new SteamDecoder(session, holder, this);
      decoder = sink;
      sink.setVolume(requestedAudio ? 1.0f : 0.0f);
      if (stopping) {
        sink.close();
        return;
      }
      boolean pyrowave = NativeSteam.pyrowaveSupported();
      NativeSteam.run(session, address, port(), hostId(), trust.device(), user, key, gameId(),
          SteamDecoder.supportsHevc(), pyrowave, sink);
      if (pyrowave && sink.consumePyrowaveFallback() && !stopping) {
        sink.close();
        NativeSteam.destroy(session);
        session = NativeSteam.create();
        handle = session;
        if (session == 0) throw new IllegalStateException("Steam compatibility reconnect failed");
        SteamDecoder fallback = new SteamDecoder(session, holder, this);
        decoder = fallback;
        fallback.setVolume(requestedAudio ? 1.0f : 0.0f);
        main.post(() -> {
          if (!stopping) {
            status.setText(label("connecting", "Connecting…"));
            status.setVisibility(View.VISIBLE);
          }
        });
        NativeSteam.run(session, address, port(), hostId(), trust.device(), user, key, gameId(),
            SteamDecoder.supportsHevc(), false, fallback);
      }
    } catch (Exception error) {
      failOnMain();
    } finally {
      if (record != null) Arrays.fill(record, (byte) 0);
      if (key != null) Arrays.fill(key, (byte) 0);
      SteamDecoder current = decoder;
      if (current != null) current.close();
      NativeSteam.destroy(session);
      if (handle == session) handle = 0;
      main.post(() -> {
        if (!failed && !stopping) {
          status.setText("Disconnected");
          status.setVisibility(View.VISIBLE);
        }
      });
    }
  }

  private String text(String key) {
    Object value = args.get(key);
    if (!(value instanceof String) || ((String) value).length() > 256) throw new IllegalArgumentException("Invalid argument");
    return (String) value;
  }
  private int port() {
    Object value = args.get("port");
    int port = value instanceof Number ? ((Number) value).intValue() : 27036;
    if (port < 1 || port > 65535) throw new IllegalArgumentException("Invalid port");
    return port;
  }
  private long hostId() { return Long.parseUnsignedLong(text("hostId")); }
  private long gameId() { return Long.parseUnsignedLong(text("appId")); }

  @Override public void surfaceChanged(SurfaceHolder holder, int format, int width, int height) {}
  @Override public void surfaceDestroyed(SurfaceHolder holder) { stop(); }

  @Override public void size(int width, int height) {
    main.post(() -> {
      if (stopping || width < 1 || height < 1) return;
      int w = getWidth(), h = getHeight();
      if (w < 1 || h < 1) return;
      float scale = Math.min((float) w / width, (float) h / height);
      surface.setLayoutParams(new FrameLayout.LayoutParams(Math.round(width * scale), Math.round(height * scale), Gravity.CENTER));
    });
  }

  @Override public void firstFrame() {
    main.post(() -> {
      if (stopping) return;
      shown = true;
      status.setVisibility(View.GONE);
    });
  }

  @Override public void failed() { failOnMain(); }
  @Override public void pyrowaveFailed() {
    main.post(() -> {
      if (stopping) return;
      status.setText(label("connecting", "Connecting…"));
      status.setVisibility(View.VISIBLE);
      long session = handle;
      if (session != 0) NativeSteam.cancel(session);
    });
  }

  private void failOnMain() {
    main.post(() -> {
      if (stopping || failed) return;
      failed = true;
      status.setText(label("error", "The stream could not start. Check pairing and the host."));
      status.setVisibility(View.VISIBLE);
      stop();
      Runnable callback = onFailure;
      if (callback != null) callback.run();
    });
  }

  private void stop() {
    if (stopping) return;
    stopping = true;
    main.removeCallbacksAndMessages(null);
    releaseInput();
    long session = handle;
    if (session != 0) NativeSteam.cancel(session);
    SteamDecoder current = decoder;
    if (current != null) current.close();
  }

  private void releaseInput() {
    controls.reset();
    controller.reset();
    Arrays.fill(physical, (short) 0);
    physicalButtons = 0;
    long session = handle;
    if (session != 0) for (int usage : heldKeys) NativeSteam.key(session, usage, false);
    heldKeys.clear();
    sendPad();
  }

  private void sendPad() {
    long session = handle;
    if (session == 0 || stopping) return;
    short[] external = controller.axes();
    int externalButtons = controller.buttons();
    short[] combined = new short[6];
    for (int i = 0; i < combined.length; i++) {
      short best = Math.abs((int) touch[i]) > Math.abs((int) physical[i]) ? touch[i] : physical[i];
      combined[i] = Math.abs((int) external[i]) > Math.abs((int) best) ? external[i] : best;
    }
    NativeSteam.pad(session, combined, physicalButtons | touchButtons | externalButtons);
  }

  @Override public boolean dispatchKeyEvent(KeyEvent event) {
    long session = handle;
    if (!inputEnabled || session == 0 || stopping) return super.dispatchKeyEvent(event);
    if (event.getKeyCode() == KeyEvent.KEYCODE_BACK) return super.dispatchKeyEvent(event);
    boolean down = event.getAction() == KeyEvent.ACTION_DOWN;
    int bit = button(event.getKeyCode());
    boolean gamepad = event.isFromSource(InputDevice.SOURCE_GAMEPAD) || event.isFromSource(InputDevice.SOURCE_DPAD)
        || event.isFromSource(InputDevice.SOURCE_JOYSTICK);
    if (bit >= 0 && gamepad) {
      if (down) physicalButtons |= 1 << bit;
      else physicalButtons &= ~(1 << bit);
      sendPad();
      return true;
    }
    if (gamepad && (event.getKeyCode() == KeyEvent.KEYCODE_BUTTON_L2 || event.getKeyCode() == KeyEvent.KEYCODE_BUTTON_R2)) {
      physical[event.getKeyCode() == KeyEvent.KEYCODE_BUTTON_L2 ? 4 : 5] = (short) (down ? 32767 : 0);
      sendPad();
      return true;
    }
    int usage = keyUsage(event.getKeyCode());
    if (usage != 0) {
      if (down) heldKeys.add(usage);
      else heldKeys.remove(usage);
      NativeSteam.key(session, usage, down);
      return true;
    }
    return super.dispatchKeyEvent(event);
  }

  @Override public boolean onGenericMotionEvent(MotionEvent event) {
    if (inputEnabled && handle != 0 && !stopping && event.isFromSource(InputDevice.SOURCE_JOYSTICK)) {
      int[] axes = {MotionEvent.AXIS_X, MotionEvent.AXIS_Y, MotionEvent.AXIS_Z,
          MotionEvent.AXIS_RZ, MotionEvent.AXIS_LTRIGGER, MotionEvent.AXIS_RTRIGGER};
      for (int i = 0; i < physical.length; i++) {
        float value = event.getAxisValue(axes[i]);
        if (Math.abs(value) < .12f) value = 0;
        physical[i] = (short) (Math.max(i < 4 ? -1 : 0, Math.min(1, value)) * 32767);
      }
      physicalButtons &= ~(15 << 11);
      float x = event.getAxisValue(MotionEvent.AXIS_HAT_X), y = event.getAxisValue(MotionEvent.AXIS_HAT_Y);
      if (y < -.5f) physicalButtons |= 1 << 11;
      if (y > .5f) physicalButtons |= 1 << 12;
      if (x < -.5f) physicalButtons |= 1 << 13;
      if (x > .5f) physicalButtons |= 1 << 14;
      sendPad();
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
