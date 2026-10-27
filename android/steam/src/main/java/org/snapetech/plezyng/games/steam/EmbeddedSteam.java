// SPDX-License-Identifier: GPL-3.0-or-later
package org.snapetech.plezyng.games.steam;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import java.net.InetAddress;
import java.security.SecureRandom;
import java.util.Arrays;
import java.util.Collections;
import java.util.Map;
import java.util.concurrent.atomic.AtomicLong;

/** Reflective Flutter boundary; no external application or Steam password. */
public final class EmbeddedSteam {
  private static final AtomicLong pairing = new AtomicLong();
  private static final AtomicLong generation = new AtomicLong();
  public static Object execute(Context context, String method, Map<?, ?> args) throws Exception {
    String host = hostKey(args);
    SteamTrust trust = new SteamTrust(context);
    if ("games".equals(method)) {
      byte[] record = trust.load(host);
      Arrays.fill(record, (byte) 0);
      // A device pairing is not an account-library grant. The interface entry is
      // rendered by Dart with a localized title; no fabricated owned-game list.
      return Collections.emptyList();
    }
    if ("forget".equals(method)) {
      trust.forget(host);
      return true;
    }
    if (!"pair".equals(method))
      throw new IllegalArgumentException("Unsupported operation");
    long epoch = generation.get();
    String address = resolve(args);
    if (epoch != generation.get())
      throw new IllegalStateException("Connection cancelled");
    long handle = NativeSteam.create();
    pairing.set(handle);
    if (epoch != generation.get())
      NativeSteam.cancel(handle);
    byte[] seed = new byte[32];
    new SecureRandom().nextBytes(seed);
    byte[] record = null;
    try {
      record = NativeSteam.pair(handle, address, port(args), id(args), trust.device(), seed, text(args, "pin"));
      if (epoch != generation.get())
        throw new IllegalStateException("Connection cancelled");
      trust.save(host, record);
      return true;
    } finally {
      Arrays.fill(seed, (byte) 0);
      if (record != null)
        Arrays.fill(record, (byte) 0);
      pairing.compareAndSet(handle, 0);
      NativeSteam.destroy(handle);
    }
  }
  public static boolean open(Activity activity, Map<?, ?> args) {
    String host = hostKey(args);
    id(args);
    byte[] record = new SteamTrust(activity).load(host);
    Arrays.fill(record, (byte) 0);
    Long.parseUnsignedLong(text(args, "appId"));
    Intent intent = new Intent(activity, SteamStreamActivity.class)
                        .putExtra("host", host)
                        .putExtra("address", text(args, "address"))
                        .putExtra("port", port(args))
                        .putExtra("hostId", text(args, "hostId"))
                        .putExtra("appId", text(args, "appId"))
                        .putExtra("pyrowave", Boolean.TRUE.equals(args.get("pyrowave")))
                        .putExtra("touch", Boolean.TRUE.equals(args.get("touchControls")));
    for (String label : new String[] {
      "connecting", "error", "disconnect", "menu", "touchLabel", "touchDescription", "ok", "cancel"
    }) {
      Object value = args.get(label);
      if (value instanceof String)
        intent.putExtra(label, (String) value);
    }
    activity.startActivity(intent);
    return true;
  }
  public static void cancel() {
    generation.incrementAndGet();
    long handle = pairing.get();
    if (handle != 0)
      NativeSteam.cancel(handle);
  }
  static String text(Map<?, ?> args, String key) {
    Object value = args.get(key);
    if (!(value instanceof String) || ((String) value).length() > 256)
      throw new IllegalArgumentException("Invalid argument");
    return (String) value;
  }
  static String hostKey(Map<?, ?> args) {
    return "steam:" + text(args, "hostId");
  }
  static int port(Map<?, ?> args) {
    Object value = args.get("port");
    int port = value instanceof Number ? ((Number) value).intValue() : 27036;
    if (port < 1 || port > 65535)
      throw new IllegalArgumentException("Invalid port");
    return port;
  }
  static long id(Map<?, ?> args) {
    long value = Long.parseUnsignedLong(text(args, "hostId"));
    if (value == 0)
      throw new IllegalArgumentException("Identify this computer first");
    return value;
  }
  static String resolve(Map<?, ?> args) throws Exception {
    return resolve(text(args, "address"));
  }
  static String resolve(String host) throws Exception {
    if (host.isEmpty() || host.length() > 253 || host.matches(".*[\\s/@?#\\\\].*"))
      throw new IllegalArgumentException("Invalid host");
    for (InetAddress address : InetAddress.getAllByName(host)) {
      if (!address.isAnyLocalAddress() && !address.isMulticastAddress() && address.getAddress().length == 4)
        return address.getHostAddress();
    }
    throw new IllegalArgumentException("Steam transport requires an IPv4 address");
  }
  private EmbeddedSteam() {}
}
