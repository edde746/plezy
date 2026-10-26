package org.snapetech.plezyng.games;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.graphics.BitmapFactory;
import android.os.SystemClock;
import android.preference.PreferenceManager;
import android.util.Base64;
import com.limelight.Game;
import com.limelight.binding.PlatformBinding;
import com.limelight.computers.IdentityManager;
import com.limelight.nvstream.http.ComputerDetails;
import com.limelight.nvstream.http.HostHttpResponseException;
import com.limelight.nvstream.http.NvApp;
import com.limelight.nvstream.http.NvHTTP;
import com.limelight.nvstream.http.PairingManager;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.security.cert.CertificateFactory;
import java.security.cert.X509Certificate;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/** Small adapter over the pinned upstream engine. No external packages or intents. */
public final class EmbeddedGameStream {
  private static final Object LOCK = new Object();
  private static int generation;
  private static NvHTTP active;
  private static final Set<NvHTTP> artworkRequests = new HashSet<>();
  private static final String TRUST_STORE = "plezy_games_trust";

  private EmbeddedGameStream() {}

  public static void cancel() {
    synchronized (LOCK) {
      generation++;
      if (active != null)
        active.cancelPendingRequests();
      for (NvHTTP http : artworkRequests) http.cancelPendingRequests();
    }
  }

  public static Object execute(Context context, String operation, Map<?, ?> args) throws Exception {
    String hostId = text(args, "hostId", 256);
    String address = address(args);
    int port = port(args);
    String pin = "pair".equals(operation) ? text(args, "pin", 4) : null;
    if (pin != null && !pin.matches("[0-9]{4}"))
      throw new IllegalArgumentException();
    X509Certificate trusted = "pair".equals(operation) ? null : certificate(context, hostId);
    if (!"pair".equals(operation) && trusted == null)
      throw new SecurityException();
    int epoch;
    NvHTTP http;
    synchronized (LOCK) {
      epoch = generation;
      http = new NvHTTP(
          new ComputerDetails.AddressTuple(address, port), 0, new IdentityManager(context).getUniqueId(), trusted,
          PlatformBinding.getCryptoProvider(context));
      active = http;
    }
    try {
      if ("pair".equals(operation)) {
        String info = http.getServerInfo(true);
        if (!hostId.equalsIgnoreCase(http.getComputerDetails(info).uuid))
          throw new SecurityException();
        if (trusted == null || http.getPairState(info) != PairingManager.PairState.PAIRED) {
          PairingManager pairing = http.getPairingManager();
          if (pairing.pair(info, pin) != PairingManager.PairState.PAIRED)
            throw new SecurityException();
          trusted = pairing.getPairedCert();
        }
        if (trusted == null)
          throw new SecurityException();
        synchronized (LOCK) {
          if (epoch != generation || Thread.currentThread().isInterrupted())
            throw new InterruptedException();
          // App-private trust is excluded from cloud backup and device transfer.
          if (!preferences(context)
                   .edit()
                   .putString(hostId, Base64.encodeToString(trusted.getEncoded(), Base64.NO_WRAP))
                   .commit()) {
            throw new IllegalStateException("Trust could not be saved");
          }
        }
        return Boolean.TRUE;
      }
      if ("games".equals(operation)) {
        List<Map<String, Object>> result = new ArrayList<>();
        for (NvApp app : http.getAppList()) {
          if (result.size() >= 2000)
            break;
          String name = app.getAppName();
          if (app.getAppId() <= 0 || name == null || name.isBlank() || name.length() > 256)
            continue;
          Map<String, Object> row = new HashMap<>();
          row.put("id", Integer.toString(app.getAppId()));
          row.put("name", name);
          row.put("hdr", app.isHdrSupported());
          result.add(row);
        }
        synchronized (LOCK) {
          if (epoch != generation)
            throw new InterruptedException();
        }
        return result;
      }
      throw new IllegalArgumentException();
    } catch (HostHttpResponseException error) {
      if (error.getErrorCode() == 401 || error.getErrorCode() == 403)
        throw new SecurityException();
      throw error;
    } finally {
      synchronized (LOCK) {
        if (active == http)
          active = null;
      }
    }
  }

  public static byte[] artwork(Context context, Map<?, ?> args) throws Exception {
    X509Certificate trusted = certificate(context, text(args, "hostId", 256));
    if (trusted == null)
      return null;
    int appId = Integer.parseInt(text(args, "appId", 10));
    if (appId <= 0)
      return null;
    NvHTTP http = new NvHTTP(
        new ComputerDetails.AddressTuple(address(args), port(args)), 0, new IdentityManager(context).getUniqueId(),
        trusted, PlatformBinding.getCryptoProvider(context));
    synchronized (LOCK) {
      artworkRequests.add(http);
    }
    try (InputStream input = http.getBoxArt(new NvApp("", appId, false));
         ByteArrayOutputStream output = new ByteArrayOutputStream()) {
      long deadline = SystemClock.elapsedRealtime() + 10000;
      byte[] buffer = new byte[8192];
      int count;
      while ((count = input.read(buffer)) != -1) {
        if (output.size() + count > 512 * 1024 || SystemClock.elapsedRealtime() > deadline)
          return null;
        output.write(buffer, 0, count);
      }
      byte[] bytes = output.toByteArray();
      BitmapFactory.Options bounds = new BitmapFactory.Options();
      bounds.inJustDecodeBounds = true;
      BitmapFactory.decodeByteArray(bytes, 0, bytes.length, bounds);
      if (bounds.outWidth <= 0 || bounds.outHeight <= 0 || bounds.outWidth > 4096 || bounds.outHeight > 8192
          || (long) bounds.outWidth * bounds.outHeight > 16000000)
        return null;
      return bytes;
    } finally {
      synchronized (LOCK) {
        artworkRequests.remove(http);
      }
    }
  }

  public static boolean open(Activity activity, Map<?, ?> args) throws Exception {
    String hostId = text(args, "hostId", 256);
    X509Certificate trusted = certificate(activity, hostId);
    if (trusted == null)
      throw new SecurityException();
    int appId = Integer.parseInt(text(args, "appId", 10));
    if (appId <= 0)
      throw new IllegalArgumentException();
    String host = address(args);
    int servicePort = port(args);
    String name = text(args, "appName", 256);
    String pcName = text(args, "hostName", 256);
    PreferenceManager.getDefaultSharedPreferences(activity)
        .edit()
        .putBoolean("checkbox_show_onscreen_controls", Boolean.TRUE.equals(args.get("touchControls")))
        .apply();
    Intent intent = new Intent(activity, Game.class);
    intent.putExtra(Game.EXTRA_HOST, host);
    intent.putExtra(Game.EXTRA_PORT, servicePort);
    intent.putExtra(Game.EXTRA_HTTPS_PORT, 0);
    intent.putExtra(Game.EXTRA_APP_ID, appId);
    intent.putExtra(Game.EXTRA_APP_NAME, name);
    intent.putExtra(Game.EXTRA_APP_HDR, Boolean.TRUE.equals(args.get("hdr")));
    intent.putExtra(Game.EXTRA_UNIQUEID, new IdentityManager(activity).getUniqueId());
    intent.putExtra(Game.EXTRA_PC_UUID, hostId);
    intent.putExtra(Game.EXTRA_PC_NAME, pcName);
    intent.putExtra(Game.EXTRA_SERVER_CERT, trusted.getEncoded());
    activity.startActivity(intent);
    return true;
  }

  private static SharedPreferences preferences(Context context) {
    return context.getSharedPreferences(TRUST_STORE, Context.MODE_PRIVATE);
  }

  private static X509Certificate certificate(Context context, String hostId) throws Exception {
    String value = preferences(context).getString(hostId, null);
    if (value == null)
      return null;
    if (value.length() > 32768)
      throw new SecurityException();
    return (X509Certificate) CertificateFactory.getInstance("X.509").generateCertificate(
        new ByteArrayInputStream(Base64.decode(value, Base64.NO_WRAP)));
  }

  private static String text(Map<?, ?> args, String key, int limit) {
    Object value = args.get(key);
    if (!(value instanceof String))
      throw new IllegalArgumentException();
    String text = (String) value;
    if (text.isEmpty() || text.length() > limit || text.chars().anyMatch(c -> c < 32 || c == 127)) {
      throw new IllegalArgumentException();
    }
    return text;
  }

  private static String address(Map<?, ?> args) {
    String value = text(args, "address", 253);
    // URI syntax is not accepted; hostnames and IPv4/IPv6 literals only.
    if (!value.matches("[A-Za-z0-9:.%-]+") || value.startsWith("-"))
      throw new IllegalArgumentException();
    return value;
  }

  private static int port(Map<?, ?> args) {
    Object value = args.get("port");
    if (!(value instanceof Number))
      throw new IllegalArgumentException();
    int port = ((Number) value).intValue();
    if (port < 1 || port > 65534)
      throw new IllegalArgumentException();
    return port;
  }
}
