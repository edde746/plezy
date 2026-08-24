# Flutter turns minification on for every release build (FlutterPlugin sets
# releaseBuildType.isMinifyEnabled), and appends this file when it exists. Anything the
# app reaches only by name — reflection or JNI — therefore needs an explicit keep here.

# The bundled Media3 FFmpeg audio decoder (ALAC, DTS, DTS-HD, TrueHD, ...).
#
# DefaultRenderersFactory instantiates FfmpegAudioRenderer through Class.forName and no
# app code references it, so R8 shrinks the class away; media3's own consumer rules only
# -keepclassmembers its constructor, which neither keeps the class nor pins its name.
# ffmpeg_jni.cc separately resolves FfmpegAudioDecoder and its growOutputBuffer callback
# by name in JNI_OnLoad, and returns JNI_ERR when either is missing, which fails the whole
# System.loadLibrary("ffmpegJNI") call.
#
# Without these keeps a release build silently loses every codec this decoder adds:
# TrueHD/DTS-HD land on MediaCodecAudioRenderer, which has no decoder for them, and
# playback bails to the mpv fallback and loses ExoPlayer's Dolby Vision handling (#1703).
-keep class androidx.media3.decoder.ffmpeg.** { *; }

# growOutputBuffer's JNI descriptor names this type, so it may not be renamed either.
-keep class androidx.media3.decoder.SimpleDecoderOutputBuffer { *; }

# ffmpeg_demuxer_jni.cc resolves the AVIO input proxy's callbacks by name
# (FindClass on the interface, GetMethodID for position/read/length). Keeping
# the interface members pins the names on every implementation, including the
# anonymous proxy inside FfmpegExtractor.
-keep interface com.edde746.plezy.exoplayer.FfmpegDemuxerJni$Input {
  long position();
  int read(byte[], int);
  long length();
}
