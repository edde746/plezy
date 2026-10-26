// SPDX-License-Identifier: GPL-3.0-or-later
package org.snapetech.plezyng.games.steam;

import android.content.Context;
import android.content.SharedPreferences;
import android.security.keystore.KeyGenParameterSpec;
import android.security.keystore.KeyProperties;
import android.util.Base64;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.StandardCharsets;
import java.security.KeyStore;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.util.Arrays;
import javax.crypto.Cipher;
import javax.crypto.KeyGenerator;
import javax.crypto.SecretKey;
import javax.crypto.spec.GCMParameterSpec;

/** Host-specific pairing secrets, encrypted with a non-exportable device key. */
final class SteamTrust {
  private static final String ALIAS = "plezy.steam.pairing.v1";
  private static final Object IDENTITY_LOCK = new Object();
  private final SharedPreferences preferences;
  SteamTrust(Context context) {
    preferences = context.getSharedPreferences("plezy_steam_trust", Context.MODE_PRIVATE);
  }
  long device() {
    synchronized (IDENTITY_LOCK) {
      long value = preferences.getLong("device", 0);
      if (value != 0)
        return value;
      do {
        value = new SecureRandom().nextLong();
      } while (value == 0);
      if (!preferences.edit().putLong("device", value).commit())
        throw new IllegalStateException("Cannot save device identity");
      return value;
    }
  }
  private static synchronized SecretKey key() throws Exception {
    KeyStore store = KeyStore.getInstance("AndroidKeyStore");
    store.load(null);
    if (store.containsAlias(ALIAS))
      return (SecretKey) store.getKey(ALIAS, null);
    KeyGenerator generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore");
    generator.init(new KeyGenParameterSpec.Builder(ALIAS, KeyProperties.PURPOSE_ENCRYPT | KeyProperties.PURPOSE_DECRYPT)
                       .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                       .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                       .setKeySize(256)
                       .build());
    return generator.generateKey();
  }
  private static String slot(String host) throws Exception {
    return Base64.encodeToString(
        MessageDigest.getInstance("SHA-256").digest(host.getBytes(StandardCharsets.UTF_8)), Base64.NO_WRAP);
  }
  byte[] load(String host) {
    try {
      String value = preferences.getString(slot(host), null);
      if (value == null)
        throw new SecurityException("Pair this computer first");
      byte[] bytes = Base64.decode(value, Base64.NO_WRAP);
      if (bytes.length != 68)
        throw new SecurityException("Invalid pairing record");
      Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
      cipher.init(Cipher.DECRYPT_MODE, key(), new GCMParameterSpec(128, bytes, 0, 12));
      cipher.updateAAD(host.getBytes(StandardCharsets.UTF_8));
      byte[] result = cipher.doFinal(bytes, 12, bytes.length - 12);
      if (result.length != 40 || ByteBuffer.wrap(result).order(ByteOrder.LITTLE_ENDIAN).getLong() == 0)
        throw new SecurityException("Pair again");
      return result;
    } catch (Exception e) {
      throw new SecurityException("Pair this computer again", e);
    }
  }
  void save(String host, byte[] record) throws Exception {
    if (record == null || record.length != 40 || ByteBuffer.wrap(record).order(ByteOrder.LITTLE_ENDIAN).getLong() == 0)
      throw new SecurityException("Invalid pairing response");
    Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
    cipher.init(Cipher.ENCRYPT_MODE, key());
    cipher.updateAAD(host.getBytes(StandardCharsets.UTF_8));
    byte[] encrypted = cipher.doFinal(record);
    byte[] bytes =
        ByteBuffer.allocate(cipher.getIV().length + encrypted.length).put(cipher.getIV()).put(encrypted).array();
    if (!preferences.edit().putString(slot(host), Base64.encodeToString(bytes, Base64.NO_WRAP)).commit())
      throw new IllegalStateException("Cannot save pairing");
    Arrays.fill(encrypted, (byte) 0);
  }
  void forget(String host) throws Exception {
    preferences.edit().remove(slot(host)).commit();
  }
}
