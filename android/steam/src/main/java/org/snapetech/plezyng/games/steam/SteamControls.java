// SPDX-License-Identifier: GPL-3.0-or-later
package org.snapetech.plezyng.games.steam;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.util.DisplayMetrics;
import android.util.SparseArray;
import android.view.MotionEvent;
import android.view.View;
import java.util.ArrayList;
import java.util.List;

/** Multi-pointer controls: each finger owns its initial button or stick. */
final class SteamControls extends View {
  interface Listener {
    void pad(short[] axes, int buttons);
    void mouse(float x, float y, int button, boolean down);
  }
  private static final class Control {
    float x, y, radius;
    int bit, axis;
    String label;
    Control(float x, float y, float radius, String label, int bit, int axis) {
      this.x = x;
      this.y = y;
      this.radius = radius;
      this.label = label;
      this.bit = bit;
      this.axis = axis;
    }
  }
  private static final class Finger {
    Control control;
    float x, y;
  }
  private final int surface;
  private final int text;
  private final int accent;
  private final int onPressed;
  private final int outline;
  private final Listener listener;
  private final String accessibilityDescription;
  private final float minimumHitRadius;
  private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
  private final List<Control> controls = new ArrayList<>();
  private final SparseArray<Finger> fingers = new SparseArray<>();
  private boolean enabled;
  private boolean inputEnabled;
  private int mousePointer = -1;
  private float mouseX = .5f, mouseY = .5f;
  SteamControls(Context context, boolean enabled, String accessibilityDescription, Listener listener) {
    super(context);
    this.enabled = enabled;
    this.listener = listener;
    this.accessibilityDescription = accessibilityDescription;
    surface = withAlpha(context.getResources().getColor(R.color.plezy_steam_surface), 0xCC);
    text = context.getResources().getColor(R.color.plezy_steam_text);
    accent = context.getResources().getColor(R.color.plezy_steam_focus);
    onPressed = context.getResources().getColor(R.color.plezy_steam_background);
    outline = context.getResources().getColor(R.color.plezy_steam_outline);
    DisplayMetrics metrics = context.getResources().getDisplayMetrics();
    minimumHitRadius = 24f * metrics.density;
    setFocusable(false);
    setImportantForAccessibility(View.IMPORTANT_FOR_ACCESSIBILITY_YES);
    updateAccessibilityDescription();
  }
  private static int withAlpha(int color, int alpha) {
    return (color & 0x00FFFFFF) | (alpha << 24);
  }
  void reset() {
    if (mousePointer != -1)
      listener.mouse(mouseX, mouseY, 1, false);
    mousePointer = -1;
    fingers.clear();
    listener.pad(new short[6], 0);
    invalidate();
  }
  void toggle() {
    reset();
    enabled = !enabled;
    updateAccessibilityDescription();
    invalidate();
  }
  @Override
  public void setEnabled(boolean value) {
    if (enabled == value)
      return;
    reset();
    enabled = value;
    updateAccessibilityDescription();
    invalidate();
  }

  private void updateAccessibilityDescription() {
    setContentDescription(
        enabled && accessibilityDescription != null && !accessibilityDescription.trim().isEmpty()
            ? accessibilityDescription
            : null);
  }
  void setInputEnabled(boolean value) {
    inputEnabled = value;
  }
  @Override
  protected void onSizeChanged(int w, int h, int oldw, int oldh) {
    reset();
    controls.clear();
    float density = getResources().getDisplayMetrics().density;
    // The hit slop below is 1.3× the drawn radius; keep it at least 48dp on
    // compact landscape phones while letting larger screens scale naturally.
    float r = Math.max(density * 18.5f, Math.min(h * .07f, w * .035f)), stick = r * 1.65f;
    controls.add(new Control(w * .16f, h * .69f, stick, "L", -1, 0));
    controls.add(new Control(w * .72f, h * .74f, stick, "R", -1, 2));
    float x = w * .88f, y = h * .67f, d = r * 2.1f;
    controls.add(new Control(x, y + d, r, "A", 0, -1));
    controls.add(new Control(x + d, y, r, "B", 1, -1));
    controls.add(new Control(x - d, y, r, "X", 2, -1));
    controls.add(new Control(x, y - d, r, "Y", 3, -1));
    x = w * .34f;
    y = h * .74f;
    d = r * 1.6f;
    controls.add(new Control(x, y - d, r * .7f, "↑", 11, -1));
    controls.add(new Control(x, y + d, r * .7f, "↓", 12, -1));
    controls.add(new Control(x - d, y, r * .7f, "←", 13, -1));
    controls.add(new Control(x + d, y, r * .7f, "→", 14, -1));
    controls.add(new Control(w * .13f, h * .22f, r, "LB", 9, -1));
    controls.add(new Control(w * .24f, h * .22f, r, "LT", -1, 4));
    controls.add(new Control(w * .76f, h * .22f, r, "RT", -1, 5));
    controls.add(new Control(w * .87f, h * .22f, r, "RB", 10, -1));
    controls.add(new Control(w * .43f, h * .88f, r * .8f, "◁", 4, -1));
    controls.add(new Control(w * .57f, h * .88f, r * .8f, "▷", 6, -1));
    controls.add(new Control(w * .48f, h * .74f, r * .7f, "L3", 7, -1));
    controls.add(new Control(w * .55f, h * .74f, r * .7f, "R3", 8, -1));
    controls.add(new Control(w * .5f, h * .18f, r * .8f, "☰", 5, -1));
    fitHitTargets(w, h);
  }
  @Override
  protected void onDraw(Canvas canvas) {
    if (!enabled)
      return;
    for (Control c : controls) {
      boolean pressed = false;
      for (int i = 0; i < fingers.size(); i++)
        if (fingers.valueAt(i).control == c)
          pressed = true;
      paint.setStyle(Paint.Style.FILL);
      paint.setColor(pressed ? accent : surface);
      canvas.drawCircle(c.x, c.y, c.radius, paint);
      paint.setStyle(Paint.Style.STROKE);
      paint.setStrokeWidth(Math.max(1, getResources().getDisplayMetrics().density));
      paint.setColor(pressed ? text : outline);
      canvas.drawCircle(c.x, c.y, c.radius, paint);
      paint.setStyle(Paint.Style.FILL);
      paint.setColor(pressed ? onPressed : text);
      paint.setTextAlign(Paint.Align.CENTER);
      paint.setTextSize(c.radius * .63f);
      canvas.drawText(c.label, c.x, c.y - (paint.ascent() + paint.descent()) / 2, paint);
      if (c.axis == 0 || c.axis == 2)
        for (int i = 0; i < fingers.size(); i++) {
          Finger f = fingers.valueAt(i);
          if (f.control != c)
            continue;
          float dx = f.x - c.x, dy = f.y - c.y, len = (float) Math.hypot(dx, dy),
                scale = len > c.radius ? c.radius / len : 1;
          paint.setColor(text);
          canvas.drawCircle(c.x + dx * scale, c.y + dy * scale, c.radius * .35f, paint);
        }
    }
  }
  @Override
  public boolean onTouchEvent(MotionEvent event) {
    // The overlay spans the whole video surface. An unselected pane must let
    // touch events pass through without turning them into game mouse input.
    if (!inputEnabled)
      return false;
    int action = event.getActionMasked(), index = event.getActionIndex(), id = event.getPointerId(index);
    if (action == MotionEvent.ACTION_CANCEL) {
      reset();
      return true;
    }
    if (action == MotionEvent.ACTION_DOWN || action == MotionEvent.ACTION_POINTER_DOWN) {
      Finger f = new Finger();
      f.x = event.getX(index);
      f.y = event.getY(index);
      if (enabled)
        f.control = nearestControl(f.x, f.y);
      fingers.put(id, f);
      if (f.control == null && fingers.size() == 1) {
        mousePointer = id;
        mouseX = f.x / Math.max(1, getWidth());
        mouseY = f.y / Math.max(1, getHeight());
        listener.mouse(mouseX, mouseY, 1, true);
      }
    } else if (action == MotionEvent.ACTION_UP || action == MotionEvent.ACTION_POINTER_UP) {
      if (mousePointer == id) {
        listener.mouse(mouseX, mouseY, 1, false);
        mousePointer = -1;
      }
      fingers.remove(id);
    } else if (action == MotionEvent.ACTION_MOVE) {
      for (int i = 0; i < event.getPointerCount(); i++) {
        Finger f = fingers.get(event.getPointerId(i));
        if (f == null)
          continue;
        f.x = event.getX(i);
        f.y = event.getY(i);
        if (mousePointer == event.getPointerId(i)) {
          mouseX = f.x / Math.max(1, getWidth());
          mouseY = f.y / Math.max(1, getHeight());
          listener.mouse(mouseX, mouseY, 0, false);
        }
      }
    }
    short[] axes = new short[6];
    int buttons = 0;
    for (int i = 0; i < fingers.size(); i++) {
      Finger f = fingers.valueAt(i);
      Control c = f.control;
      if (c == null)
        continue;
      if (c.bit >= 0)
        buttons |= 1 << c.bit;
      else if (c.axis >= 4)
        axes[c.axis] = 32767;
      else {
        float dx = (f.x - c.x) / c.radius, dy = (f.y - c.y) / c.radius, len = (float) Math.hypot(dx, dy);
        if (len > 1) {
          dx /= len;
          dy /= len;
        }
        axes[c.axis] = (short) (dx * 32767);
        axes[c.axis + 1] = (short) (dy * 32767);
      }
    }
    listener.pad(axes, buttons);
    invalidate();
    return true;
  }

  private Control nearestControl(float x, float y) {
    Control nearest = null;
    double nearestDistanceSquared = Double.POSITIVE_INFINITY;
    for (Control c : controls) {
      float hitRadius = hitRadius(c);
      double dx = x - c.x, dy = y - c.y;
      double distanceSquared = dx * dx + dy * dy;
      if (distanceSquared <= hitRadius * hitRadius && distanceSquared < nearestDistanceSquared) {
        nearest = c;
        nearestDistanceSquared = distanceSquared;
      }
    }
    // Keep the earlier control in list order for exact-distance ties.
    return nearest;
  }

  private float hitRadius(Control control) {
    return Math.max(control.radius * 1.3f, minimumHitRadius);
  }

  private void fitHitTargets(int width, int height) {
    for (Control c : controls) {
      float radius = hitRadius(c);
      float horizontalInset = Math.min(radius, width / 2f);
      float verticalInset = Math.min(radius, height / 2f);
      c.x = Math.max(horizontalInset, Math.min(width - horizontalInset, c.x));
      c.y = Math.max(verticalInset, Math.min(height - verticalInset, c.y));
    }
  }
}
