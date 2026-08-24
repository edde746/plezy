package com.edde746.plezy.exoplayer;

import android.content.ContentProvider;
import android.content.ContentValues;
import android.content.Context;
import android.database.Cursor;
import android.net.Uri;
import android.os.ParcelFileDescriptor;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

/**
 * Serves a test asset over a {@code content://} URI so instrumentation can exercise media3's
 * {@code ContentDataSource} read path.
 *
 * <p>A download stored through SAF reaches the player as {@code content://} and is read with
 * {@code openAssetFileDescriptor} — a different reopen story than a plain file:
 * {@code FfmpegRandomAccessSource} has to open a <em>second</em> descriptor on the document while
 * the loader still holds one. Nothing else in the app produces that shape on demand, and MediaStore
 * would leave rows on the device.
 *
 * <p>The provider owns the whole fixture: a test body runs in the <em>app's</em> process and cannot
 * write into this APK's data directory, so handing it a path could never work. It copies the named
 * asset into its own cache and returns a read-only descriptor, which crosses the uid boundary fine.
 *
 * <p>Java rather than Kotlin on purpose: hosting this provider starts a process for the test APK
 * alone, and the Kotlin stdlib the instrumentation normally borrows from the app is not on that
 * process's classpath.
 */
public final class FixtureContentProvider extends ContentProvider {

  public static final String AUTHORITY = "com.edde746.plezy.test.fixtures";

  /** @param asset path inside this APK's assets, e.g. {@code ffmpeg/seek_cued.mkv}. */
  public static Uri uriFor(String asset) {
    return new Uri.Builder().scheme("content").authority(AUTHORITY).path(asset).build();
  }

  @Override
  public boolean onCreate() {
    return true;
  }

  @Override
  public ParcelFileDescriptor openFile(Uri uri, String mode) throws FileNotFoundException {
    String path = uri.getPath();
    if (path == null || path.length() <= 1) {
      throw new FileNotFoundException("no asset in " + uri);
    }
    String asset = path.substring(1);
    Context context = getContext();
    if (context == null) {
      throw new FileNotFoundException("provider has no context");
    }
    File cached = new File(context.getCacheDir(), asset.replace('/', '-'));
    if (!cached.isFile()) {
      copyAsset(context, asset, cached);
    }
    return ParcelFileDescriptor.open(cached, ParcelFileDescriptor.MODE_READ_ONLY);
  }

  private static void copyAsset(Context context, String asset, File target) throws FileNotFoundException {
    File staging = null;
    try {
      context.getCacheDir().mkdirs();
      staging = File.createTempFile("fixture-", null, context.getCacheDir());
      try (InputStream source = context.getAssets().open(asset);
          OutputStream sink = new FileOutputStream(staging)) {
        byte[] buffer = new byte[64 * 1024];
        for (int read = source.read(buffer); read != -1; read = source.read(buffer)) {
          sink.write(buffer, 0, read);
        }
      }
      // Publish atomically so a concurrent open never sees a short file.
      if (!staging.renameTo(target) && !target.isFile()) {
        throw new IOException("could not publish " + target);
      }
    } catch (IOException e) {
      FileNotFoundException failure = new FileNotFoundException("could not stage asset " + asset);
      failure.initCause(e);
      throw failure;
    } finally {
      if (staging != null && staging.isFile()) {
        staging.delete();
      }
    }
  }

  @Override
  public String getType(Uri uri) {
    return "video/x-matroska";
  }

  @Override
  public Cursor query(Uri uri, String[] projection, String selection, String[] selectionArgs, String sortOrder) {
    return null;
  }

  @Override
  public Uri insert(Uri uri, ContentValues values) {
    return null;
  }

  @Override
  public int update(Uri uri, ContentValues values, String selection, String[] selectionArgs) {
    return 0;
  }

  @Override
  public int delete(Uri uri, String selection, String[] selectionArgs) {
    return 0;
  }
}
