// SPDX-License-Identifier: GPL-3.0-or-later
package org.snapetech.plezyng.games.steam;

import android.app.Activity;
import android.app.AlertDialog;
import android.graphics.Color;
import android.os.Bundle;
import android.view.Gravity;
import android.view.View;
import android.view.WindowManager;
import android.widget.Button;
import android.widget.FrameLayout;
import java.lang.reflect.Constructor;
import java.lang.reflect.Method;
import java.util.HashMap;
import java.util.Map;

/** Full-screen host for the same retained stream view used by Multiview. */
public final class SteamStreamActivity extends Activity {
  private static final String VIEW_CLASS = "org.snapetech.plezyng.games.steam.SteamStreamView";
  private Object stream;
  private Class<?> streamClass;
  private boolean unavailable;

  @Override public void onCreate(Bundle state) {
    super.onCreate(state);
    getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
    getWindow().getDecorView().setSystemUiVisibility(
        View.SYSTEM_UI_FLAG_FULLSCREEN | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY);
    try {
      Map<String, Object> arguments = streamArguments();
      streamClass = Class.forName(VIEW_CLASS);
      Constructor<?> constructor = streamClass.getConstructor(android.content.Context.class, Map.class);
      stream = constructor.newInstance(this, arguments);
      View streamView = (View) stream;
      FrameLayout root = new FrameLayout(this);
      root.setBackgroundColor(Color.BLACK);
      root.addView(streamView, new FrameLayout.LayoutParams(-1, -1, Gravity.CENTER));
      setContentView(root);

      invoke("setOnFailure", new Class<?>[] {Runnable.class}, (Runnable) this::showFailure);
      invoke("setInputEnabled", new Class<?>[] {boolean.class}, true);

      Button menu = new Button(this);
      menu.setText("⋮");
      menu.setContentDescription(text("menu", "Stream controls"));
      menu.setAlpha(.65f);
      root.addView(menu, new FrameLayout.LayoutParams(64, 64, Gravity.TOP | Gravity.END));
      menu.setOnClickListener(v -> showMenu());
    } catch (Exception error) {
      unavailable = true;
      showFailure();
    }
  }

  private Map<String, Object> streamArguments() {
    Map<String, Object> args = new HashMap<>();
    args.put("hostKey", getIntent().getStringExtra("host"));
    args.put("hostId", getIntent().getStringExtra("hostId"));
    args.put("address", getIntent().getStringExtra("address"));
    args.put("port", getIntent().getIntExtra("port", 27036));
    args.put("appId", getIntent().getStringExtra("appId"));
    args.put("touchControls", getIntent().getBooleanExtra("touch", true));
    args.put("audioEnabled", true);
    args.put("connecting", text("connecting", "Connecting…"));
    args.put("error", text("error", "The stream could not start. Check pairing and the host."));
    return args;
  }

  private String text(String key, String fallback) {
    String value = getIntent().getStringExtra(key);
    return value == null ? fallback : value;
  }

  private void invoke(String name, Class<?>[] types, Object... args) throws Exception {
    Method method = streamClass.getMethod(name, types);
    method.invoke(stream, args);
  }

  private boolean isFailed() {
    try {
      return unavailable || Boolean.TRUE.equals(invokeResult("isFailed"));
    } catch (Exception error) {
      return unavailable;
    }
  }

  private Object invokeResult(String name) throws Exception {
    return streamClass.getMethod(name).invoke(stream);
  }

  private void showFailure() {
    if (isFinishing()) return;
    new AlertDialog.Builder(this)
        .setMessage(text("error", "The stream could not start. Check pairing and the host."))
        .setPositiveButton(android.R.string.ok, (dialog, which) -> finish())
        .setOnCancelListener(dialog -> finish())
        .show();
  }

  private void showMenu() {
    resetInput();
    new AlertDialog.Builder(this)
        .setItems(new String[] {text("touchLabel", "On-screen controller"), text("disconnect", "Disconnect")},
            (dialog, which) -> {
              if (which == 0) {
                try {
                  invoke("toggleTouchControls", new Class<?>[0]);
                } catch (Exception ignored) {
                  showFailure();
                }
              } else {
                closeStream();
                finish();
              }
            })
        .setNegativeButton(android.R.string.cancel, null)
        .show();
  }

  private void resetInput() {
    try {
      invoke("resetInput", new Class<?>[0]);
    } catch (Exception ignored) {
      // The surface may already be retiring.
    }
  }

  private void closeStream() {
    try {
      invoke("close", new Class<?>[0]);
    } catch (Exception ignored) {
      // Activity teardown is idempotent with native surface disposal.
    }
  }

  @Override protected void onPause() {
    super.onPause();
    closeStream();
    if (!isFailed()) finish();
  }

  @Override protected void onDestroy() {
    closeStream();
    super.onDestroy();
  }

  @Override public void onBackPressed() { showMenu(); }

  @Override public void onWindowFocusChanged(boolean focused) {
    super.onWindowFocusChanged(focused);
    if (!focused) resetInput();
  }
}
