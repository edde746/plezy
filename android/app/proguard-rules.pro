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

# MatroskaExtractor.init is final and its ExtractorOutput / subtitle scratch buffer live
# in private fields, so the extractor wrappers reach both by name: AssMatroskaExtractor
# (android/libass/.../media/extractor/AssMatroskaExtractor.kt) resolves extractorOutput
# and subtitleSample with getDeclaredField to redirect ASS subtitle samples, and
# MatroskaLatmSupport (android/app/.../exoplayer/MatroskaLatmSupport.kt) resolves
# extractorOutput the same way to wrap LATM tracks.
#
# R8 renaming either field makes getDeclaredField throw; AssMatroskaExtractor resolves
# them in its companion object, so the throw surfaces as ExceptionInInitializerError
# while constructing the extractor — every MKV direct-play, release builds only. Only
# the *names* need pinning: MatroskaExtractor uses both fields itself, so they survive
# shrinking through the compile-time subclass references.
-keepclassmembernames class androidx.media3.extractor.mkv.MatroskaExtractor {
  private androidx.media3.extractor.ExtractorOutput extractorOutput;
  private androidx.media3.common.util.ParsableByteArray subtitleSample;
}
