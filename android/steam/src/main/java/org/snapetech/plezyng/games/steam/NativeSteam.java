// SPDX-License-Identifier: GPL-3.0-or-later
package org.snapetech.plezyng.games.steam;

final class NativeSteam {
  static {
    System.loadLibrary("plezy_steam");
  }
  static native long create();
  static native void cancel(long handle);
  static native void destroy(long handle);
  static native boolean pyrowaveSupported();
  static native byte[] pair(long handle, String address, int port, long host, long device, byte[] key, String pin);
  static native void run(
      long handle, String address, int port, long host, long device, long user, byte[] key, long game, boolean hevc,
      boolean pyrowave, int width, int height, int fps, int bitrateKbps, SteamDecoder decoder);
  static native void runWithControllers(
      long handle, String address, int port, long host, long device, long user, byte[] key, long game, boolean hevc,
      boolean pyrowave, int width, int height, int fps, int bitrateKbps, int controllerCount, SteamDecoder decoder);
  static native void runWithAudio(
      long handle, String address, int port, long hostId, long deviceId, long userId, byte[] key, long game,
      boolean hevc, boolean pyrowave, int width, int height, int fps, int bitrateKbps, int controllerCount,
      int audioChannels, SteamDecoder decoder);
  static native boolean pyrowaveStart(long handle, int width, int height, byte[] initial);
  static native byte[] pyrowaveDecode(long handle, byte[] bytes);
  static native void pyrowaveStop(long handle);
  static native byte[][] h26xStart(long handle, int codec, byte[] initial);
  static native byte[] h26xFrame(long handle, byte[] bytes);
  static native void pad(long handle, short[] axes, int buttons);
  static native void padSeat(long handle, int seat, short[] axes, int buttons);
  static native void key(long handle, int usage, boolean down);
  static native void mouse(long handle, float x, float y, int button, boolean down);
  static native void text(long handle, String text);
  static native void frameComplete(long handle, int id, boolean displayed);
  static native long[] metrics(long handle);
  private NativeSteam() {}
}
