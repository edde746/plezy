// SPDX-License-Identifier: GPL-3.0-or-later
package org.snapetech.plezyng.games.steam;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.res.ColorStateList;
import android.graphics.Color;
import android.graphics.drawable.GradientDrawable;
import android.graphics.drawable.StateListDrawable;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.Gravity;
import android.view.InputDevice;
import android.view.KeyEvent;
import android.view.MotionEvent;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.View;
import android.view.WindowManager;
import android.widget.FrameLayout;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.TextView;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;

/** Private, in-process Steam player. Leaving disconnects without stopping the game. */
public final class SteamStreamActivity extends Activity implements SurfaceHolder.Callback, SteamDecoder.Events {
  private final Handler main = new Handler(Looper.getMainLooper());
  private final short[] physical = new short[6];
  private short[] touch = new short[6];
  private int physicalButtons, touchButtons;
  private final Set<Integer> heldKeys = new HashSet<>();
  private volatile long handle;
  private SurfaceView surface;
  private FrameLayout root;
  private TextView status;
  private SteamControls controls;
  private volatile SteamDecoder decoder;
  private boolean started, shown, failed;
  private volatile boolean stopping;
  @Override
  public void onCreate(Bundle state) {
    super.onCreate(state);
    getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
    getWindow().getDecorView().setSystemUiVisibility(
        View.SYSTEM_UI_FLAG_FULLSCREEN | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY);
    root = new FrameLayout(this);
    root.setBackgroundColor(Color.BLACK);
    setContentView(root);
    surface = new SurfaceView(this);
    root.addView(surface, new FrameLayout.LayoutParams(-1, -1, Gravity.CENTER));
    surface.getHolder().addCallback(this);
    controls = new SteamControls(
        this,
        getIntent().getBooleanExtra("touch", true),
        label("touchDescription", "On-screen game controller"),
        new SteamControls.Listener() {
          public void pad(short[] axes, int buttons) {
            touch = axes;
            touchButtons = buttons;
            sendPad();
          }
          public void mouse(float x, float y, int button, boolean down) {
            if (handle == 0)
              return;
            float sx = (x * root.getWidth() - surface.getLeft()) / Math.max(1, surface.getWidth());
            float sy = (y * root.getHeight() - surface.getTop()) / Math.max(1, surface.getHeight());
            NativeSteam.mouse(handle, sx, sy, button, down);
          }
        });
    root.addView(controls, new FrameLayout.LayoutParams(-1, -1));
    status = new TextView(this);
    status.setText(label("connecting", "Connecting…"));
    status.setTextColor(getResources().getColor(R.color.plezy_steam_text));
    status.setGravity(Gravity.CENTER);
    root.addView(status, new FrameLayout.LayoutParams(-1, -1));
    ImageButton menu = new ImageButton(this);
    menu.setImageResource(R.drawable.ic_stream_more);
    menu.setScaleType(ImageView.ScaleType.CENTER_INSIDE);
    menu.setPadding(dp(12), dp(12), dp(12), dp(12));
    menu.setContentDescription(label("menu", "Stream controls"));
    menu.setFocusable(true);
    menu.setClickable(true);
    menu.setBackground(menuButtonBackground());
    int text = getResources().getColor(R.color.plezy_steam_text);
    int onAccent = getResources().getColor(R.color.plezy_steam_background);
    menu.setImageTintList(new ColorStateList(
        new int[][] {{android.R.attr.state_pressed}, {android.R.attr.state_focused}, {}},
        new int[] {onAccent, text, text}));
    int targetSize = dp(48);
    menu.setMinWidth(targetSize);
    menu.setMinHeight(targetSize);
    FrameLayout.LayoutParams menuLayout = new FrameLayout.LayoutParams(targetSize, targetSize, Gravity.TOP | Gravity.END);
    menuLayout.setMargins(0, dp(12), dp(12), 0);
    root.addView(menu, menuLayout);
    menu.setOnClickListener(v -> showMenu());
  }
  private int dp(float value) {
    return Math.round(value * getResources().getDisplayMetrics().density);
  }
  private GradientDrawable menuShape(int fillColor, int outlineColor, int outlineWidth) {
    GradientDrawable shape = new GradientDrawable();
    shape.setShape(GradientDrawable.RECTANGLE);
    shape.setColor(fillColor);
    shape.setCornerRadius(dp(24));
    shape.setStroke(outlineWidth, outlineColor);
    return shape;
  }
  private StateListDrawable menuButtonBackground() {
    StateListDrawable states = new StateListDrawable();
    states.addState(
        new int[] {android.R.attr.state_pressed},
        menuShape(getResources().getColor(R.color.plezy_steam_focus), getResources().getColor(R.color.plezy_steam_focus), dp(1)));
    states.addState(
        new int[] {android.R.attr.state_focused},
        menuShape(getResources().getColor(R.color.plezy_steam_surface), getResources().getColor(R.color.plezy_steam_focus), dp(2)));
    states.addState(
        new int[0],
        menuShape(getResources().getColor(R.color.plezy_steam_surface), getResources().getColor(R.color.plezy_steam_outline), dp(1)));
    return states;
  }
  private String label(String key, String fallback) {
    String s = getIntent().getStringExtra(key);
    return s == null ? fallback : s;
  }
  @Override
  public void surfaceCreated(SurfaceHolder holder) {
    if (started || stopping)
      return;
    started = true;
    handle = NativeSteam.create();
    new Thread(() -> {
      long session = handle;
      byte[] record = null, key = null;
      try {
        String address = EmbeddedSteam.resolve(getIntent().getStringExtra("address"));
        if (stopping)
          return;
        SteamTrust trust = new SteamTrust(this);
        record = trust.load(getIntent().getStringExtra("host"));
        long user = ByteBuffer.wrap(record).order(ByteOrder.LITTLE_ENDIAN).getLong();
        key = Arrays.copyOfRange(record, 8, 40);
        SteamDecoder sink = new SteamDecoder(session, holder, this);
        decoder = sink;
        if (stopping) {
          sink.close();
          return;
        }
        boolean pyrowave = NativeSteam.pyrowaveSupported();
        NativeSteam.run(
            session, address, getIntent().getIntExtra("port", 27036), getIntent().getLongExtra("hostId", 0),
            trust.device(), user, key, getIntent().getLongExtra("game", 0), SteamDecoder.supportsHevc(), pyrowave, sink);
        if (pyrowave && sink.consumePyrowaveFallback() && !stopping) {
          sink.close();
          NativeSteam.destroy(session);
          session = NativeSteam.create();
          handle = session;
          if (session == 0)
            throw new IllegalStateException("Steam compatibility reconnect failed");
          if (stopping)
            return;
          SteamDecoder fallback = new SteamDecoder(session, holder, this);
          decoder = fallback;
          main.post(() -> {
            if (!stopping) {
              status.setText(label("connecting", "Connecting…"));
              status.setVisibility(View.VISIBLE);
            }
          });
          NativeSteam.run(
              session, address, getIntent().getIntExtra("port", 27036), getIntent().getLongExtra("hostId", 0),
              trust.device(), user, key, getIntent().getLongExtra("game", 0), SteamDecoder.supportsHevc(), false, fallback);
        }
      } catch (Exception e) {
        failed();
      } finally {
        if (record != null)
          Arrays.fill(record, (byte) 0);
        if (key != null)
          Arrays.fill(key, (byte) 0);
        SteamDecoder sink = decoder;
        if (sink != null)
          sink.close();
        NativeSteam.destroy(session);
        main.post(() -> {
          if (!failed && !isFinishing())
            finish();
        });
      }
    }, "PlezySteamSession").start();
    main.postDelayed(() -> {
      if (stopping || shown)
        return;
      SteamDecoder current = decoder;
      if (current != null)
        current.requestPyrowaveFallback();
    }, 12000);
    main.postDelayed(() -> {
      if (!shown && !stopping)
        failed();
    }, 30000);
  }
  @Override
  public void surfaceChanged(SurfaceHolder holder, int format, int width, int height) {}
  @Override
  public void surfaceDestroyed(SurfaceHolder holder) {
    stop();
  }
  @Override
  public void size(int width, int height) {
    main.post(() -> {
      if (stopping)
        return;
      int w = root.getWidth(), h = root.getHeight();
      float scale = Math.min((float) w / width, (float) h / height);
      surface.setLayoutParams(
          new FrameLayout.LayoutParams(Math.round(width * scale), Math.round(height * scale), Gravity.CENTER));
    });
  }
  @Override
  public void firstFrame() {
    main.post(() -> {
      shown = true;
      status.setVisibility(View.GONE);
    });
  }
  @Override
  public void failed() {
    main.post(() -> {
      if (stopping || failed)
        return;
      failed = true;
      stop();
      new AlertDialog.Builder(this, R.style.PlezySteamDialog)
          .setMessage(label("error", "The stream could not start. Check pairing and the host."))
          .setPositiveButton(label("ok", "OK"), (d, w) -> finish())
          .setOnCancelListener(d -> finish())
          .show();
    });
  }
  @Override
  public void pyrowaveFailed() {
    main.post(() -> {
      if (stopping)
        return;
      status.setText(label("connecting", "Connecting…"));
      status.setVisibility(View.VISIBLE);
      if (handle != 0)
        NativeSteam.cancel(handle);
    });
  }
  private void stop() {
    if (stopping)
      return;
    stopping = true;
    main.removeCallbacksAndMessages(null);
    releaseInput();
    if (handle != 0)
      NativeSteam.cancel(handle);
    SteamDecoder sink = decoder;
    if (sink != null)
      sink.close();
  }
  @Override
  protected void onPause() {
    super.onPause();
    stop();
    if (!failed)
      finish();
  }
  @Override
  protected void onDestroy() {
    stop();
    super.onDestroy();
  }
  @Override
  public void onBackPressed() {
    showMenu();
  }
  private void showMenu() {
    releaseInput();
    new AlertDialog.Builder(this, R.style.PlezySteamDialog)
        .setTitle(label("menu", "Stream controls"))
        .setItems(
            new String[] {label("touchLabel", "On-screen controller"), label("disconnect", "Disconnect")},
            (d, which) -> {
              if (which == 0)
                controls.toggle();
              else {
                stop();
                finish();
              }
            })
        .setNegativeButton(label("cancel", "Cancel"), null)
        .show();
  }
  private void releaseInput() {
    if (controls != null)
      controls.reset();
    Arrays.fill(physical, (short) 0);
    physicalButtons = 0;
    if (handle != 0)
      for (int usage : heldKeys) NativeSteam.key(handle, usage, false);
    heldKeys.clear();
    sendPad();
  }
  @Override
  public void onWindowFocusChanged(boolean focused) {
    super.onWindowFocusChanged(focused);
    if (!focused)
      releaseInput();
  }
  private void sendPad() {
    if (handle == 0)
      return;
    short[] combined = new short[6];
    for (int i = 0; i < 6; i++)
      combined[i] = Math.abs((int) touch[i]) > Math.abs((int) physical[i]) ? touch[i] : physical[i];
    NativeSteam.pad(handle, combined, physicalButtons | touchButtons);
  }
  private static int button(int key) {
    switch (key) {
      case KeyEvent.KEYCODE_BUTTON_A:
        return 0;
      case KeyEvent.KEYCODE_BUTTON_B:
        return 1;
      case KeyEvent.KEYCODE_BUTTON_X:
        return 2;
      case KeyEvent.KEYCODE_BUTTON_Y:
        return 3;
      case KeyEvent.KEYCODE_BUTTON_SELECT:
        return 4;
      case KeyEvent.KEYCODE_BUTTON_MODE:
        return 5;
      case KeyEvent.KEYCODE_BUTTON_START:
        return 6;
      case KeyEvent.KEYCODE_BUTTON_THUMBL:
        return 7;
      case KeyEvent.KEYCODE_BUTTON_THUMBR:
        return 8;
      case KeyEvent.KEYCODE_BUTTON_L1:
        return 9;
      case KeyEvent.KEYCODE_BUTTON_R1:
        return 10;
      case KeyEvent.KEYCODE_DPAD_UP:
        return 11;
      case KeyEvent.KEYCODE_DPAD_DOWN:
        return 12;
      case KeyEvent.KEYCODE_DPAD_LEFT:
        return 13;
      case KeyEvent.KEYCODE_DPAD_RIGHT:
        return 14;
      case KeyEvent.KEYCODE_DPAD_CENTER:
        return 0;
      default:
        return -1;
    }
  }
  private static int usage(int key) {
    if (key >= KeyEvent.KEYCODE_A && key <= KeyEvent.KEYCODE_Z)
      return key - KeyEvent.KEYCODE_A + 4;
    if (key >= KeyEvent.KEYCODE_1 && key <= KeyEvent.KEYCODE_9)
      return key - KeyEvent.KEYCODE_1 + 30;
    if (key >= KeyEvent.KEYCODE_F1 && key <= KeyEvent.KEYCODE_F12)
      return key - KeyEvent.KEYCODE_F1 + 58;
    switch (key) {
      case KeyEvent.KEYCODE_0:
        return 39;
      case KeyEvent.KEYCODE_ENTER:
        return 40;
      case KeyEvent.KEYCODE_ESCAPE:
        return 41;
      case KeyEvent.KEYCODE_DEL:
        return 42;
      case KeyEvent.KEYCODE_TAB:
        return 43;
      case KeyEvent.KEYCODE_SPACE:
        return 44;
      case KeyEvent.KEYCODE_SHIFT_LEFT:
        return 225;
      case KeyEvent.KEYCODE_SHIFT_RIGHT:
        return 229;
      case KeyEvent.KEYCODE_CTRL_LEFT:
        return 224;
      case KeyEvent.KEYCODE_CTRL_RIGHT:
        return 228;
      case KeyEvent.KEYCODE_ALT_LEFT:
        return 226;
      case KeyEvent.KEYCODE_ALT_RIGHT:
        return 230;
      case KeyEvent.KEYCODE_DPAD_RIGHT:
        return 79;
      case KeyEvent.KEYCODE_DPAD_LEFT:
        return 80;
      case KeyEvent.KEYCODE_DPAD_DOWN:
        return 81;
      case KeyEvent.KEYCODE_DPAD_UP:
        return 82;
      default:
        return 0;
    }
  }
  @Override
  public boolean dispatchKeyEvent(KeyEvent event) {
    if (handle == 0 || stopping || event.getKeyCode() == KeyEvent.KEYCODE_BACK)
      return super.dispatchKeyEvent(event);
    boolean down = event.getAction() == KeyEvent.ACTION_DOWN;
    int bit = button(event.getKeyCode());
    boolean gamepad = event.isFromSource(InputDevice.SOURCE_GAMEPAD) || event.isFromSource(InputDevice.SOURCE_DPAD)
        || event.isFromSource(InputDevice.SOURCE_JOYSTICK);
    if (bit >= 0 && gamepad) {
      if (down)
        physicalButtons |= 1 << bit;
      else
        physicalButtons &= ~(1 << bit);
      sendPad();
      return true;
    }
    if (gamepad
        && (event.getKeyCode() == KeyEvent.KEYCODE_BUTTON_L2 || event.getKeyCode() == KeyEvent.KEYCODE_BUTTON_R2)) {
      physical[event.getKeyCode() == KeyEvent.KEYCODE_BUTTON_L2 ? 4 : 5] = (short) (down ? 32767 : 0);
      sendPad();
      return true;
    }
    int usage = usage(event.getKeyCode());
    if (usage != 0) {
      if (down)
        heldKeys.add(usage);
      else
        heldKeys.remove(usage);
      NativeSteam.key(handle, usage, down);
      return true;
    }
    return super.dispatchKeyEvent(event);
  }
  @Override
  public boolean onGenericMotionEvent(MotionEvent event) {
    if (handle != 0 && !stopping && event.isFromSource(InputDevice.SOURCE_JOYSTICK)) {
      int[] axes = {MotionEvent.AXIS_X,  MotionEvent.AXIS_Y,        MotionEvent.AXIS_Z,
                    MotionEvent.AXIS_RZ, MotionEvent.AXIS_LTRIGGER, MotionEvent.AXIS_RTRIGGER};
      for (int i = 0; i < 6; i++) {
        float value = event.getAxisValue(axes[i]);
        if (Math.abs(value) < .12f)
          value = 0;
        physical[i] = (short) (Math.max(i < 4 ? -1 : 0, Math.min(1, value)) * 32767);
      }
      physicalButtons &= ~(15 << 11);
      float x = event.getAxisValue(MotionEvent.AXIS_HAT_X), y = event.getAxisValue(MotionEvent.AXIS_HAT_Y);
      if (y < -.5f)
        physicalButtons |= 1 << 11;
      if (y > .5f)
        physicalButtons |= 1 << 12;
      if (x < -.5f)
        physicalButtons |= 1 << 13;
      if (x > .5f)
        physicalButtons |= 1 << 14;
      sendPad();
      return true;
    }
    return super.onGenericMotionEvent(event);
  }
}
