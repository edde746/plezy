#!/usr/bin/env python3

import importlib.util
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).with_name("check_shrinker_rules.py")
SPEC = importlib.util.spec_from_file_location("check_shrinker_rules", SCRIPT)
CHECKER = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(CHECKER)

# The descriptor is split across two literals exactly as ffmpeg_jni.cc has it, so the
# fixture also covers C string concatenation.
JNI_SOURCE = """
JNIEXPORT jint JNI_OnLoad(JavaVM* vm, void* reserved) {
  jclass clazz = env->FindClass("androidx/media3/decoder/ffmpeg/FfmpegAudioDecoder");
  growOutputBufferMethod = env->GetMethodID(
      clazz, "growOutputBuffer",
      "(Landroidx/media3/decoder/"
      "SimpleDecoderOutputBuffer;I)Ljava/nio/ByteBuffer;");
  return JNI_VERSION_1_6;
}
"""

FULL_RULES = (
    "-keep class androidx.media3.decoder.ffmpeg.** { *; }\n"
    "-keep class androidx.media3.decoder.SimpleDecoderOutputBuffer { *; }\n"
)

# Mirrors the production rule: MatroskaExtractor is referenced at compile time, so only
# the member names need pinning for the getDeclaredField lookups.
MATROSKA_KEEP = (
    "-keepclassmembernames class androidx.media3.extractor.mkv.MatroskaExtractor {\n"
    "  private androidx.media3.extractor.ExtractorOutput extractorOutput;\n"
    "  private androidx.media3.common.util.ParsableByteArray subtitleSample;\n"
    "}\n"
)

# The shape AssMatroskaExtractor.kt uses: import + Type::class.java receivers.
KOTLIN_REFLECTION_SOURCE = """
package com.edde746.plezy.libass

import androidx.media3.extractor.mkv.MatroskaExtractor

internal val extractorOutputField = MatroskaExtractor::class.java.getDeclaredField("extractorOutput").apply {
  isAccessible = true
}
internal val subtitleSampleField = MatroskaExtractor::class.java.getDeclaredField("subtitleSample").apply {
  isAccessible = true
}
"""

# The Java receiver spelling of the same lookup.
JAVA_REFLECTION_SOURCE = """
package com.edde746.plezy.exoplayer;

import androidx.media3.extractor.mkv.MatroskaExtractor;

class MatroskaFields {
  static final java.lang.reflect.Field OUTPUT;
  static {
    try {
      OUTPUT = MatroskaExtractor.class.getDeclaredField("extractorOutput");
    } catch (NoSuchFieldException error) {
      throw new ExceptionInInitializerError(error);
    }
  }
}
"""


class ShrinkerRulesCheckerTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        java_path = self.root / "android/app/src/main/java/androidx/media3/decoder/ffmpeg"
        java_path.mkdir(parents=True)
        (java_path / "FfmpegAudioRenderer.java").write_text("// fixture\n", encoding="utf-8")
        (java_path / "FfmpegAudioDecoder.java").write_text("// fixture\n", encoding="utf-8")
        self.cpp_path = self.root / "android/app/src/main/cpp/media3_ffmpeg_decoder"
        self.cpp_path.mkdir(parents=True)
        self.jni_path = self.cpp_path / "ffmpeg_jni.cc"
        self.jni_path.write_text(JNI_SOURCE, encoding="utf-8")
        self.rules_path = self.root / "android/app/proguard-rules.pro"
        self.rules_path.parent.mkdir(parents=True, exist_ok=True)

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def _write_rules(self, rules: str) -> None:
        self.rules_path.write_text(rules, encoding="utf-8")

    def _write_source(self, relative: str, text: str) -> None:
        path = self.root / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")

    @staticmethod
    def _failure_kinds(errors: list[str]) -> set[str]:
        kinds = set()
        for error in errors:
            for marker in ("reflected namespace", "with FindClass", "from native code", "in the descriptor"):
                if marker in error:
                    kinds.add(marker)
        return kinds

    @staticmethod
    def _every_failure_kind() -> set[str]:
        return {"reflected namespace", "with FindClass", "from native code", "in the descriptor"}

    def test_repository_rules_cover_every_name_reached_class_and_member(self) -> None:
        self.assertEqual([], CHECKER.validate(Path(__file__).resolve().parents[2]))

    def test_package_keep_plus_descriptor_keep_passes(self) -> None:
        self._write_rules(FULL_RULES)

        self.assertEqual([], CHECKER.validate(self.root))

    def test_missing_rules_file_is_reported(self) -> None:
        errors = CHECKER.validate(self.root)

        self.assertEqual(1, len(errors))
        self.assertIn("proguard-rules.pro is missing", errors[0])

    def test_uncovered_reflected_class_is_reported(self) -> None:
        self._write_rules(
            "-keep class androidx.media3.decoder.ffmpeg.FfmpegAudioDecoder { *; }\n"
            "-keep class androidx.media3.decoder.SimpleDecoderOutputBuffer { *; }\n"
        )

        self.assertEqual(
            ["androidx.media3.decoder.ffmpeg.FfmpegAudioRenderer lives in a reflected namespace "
             "but no -keep in android/app/proguard-rules.pro covers it"],
            CHECKER.validate(self.root),
        )

    def test_single_star_does_not_span_packages(self) -> None:
        self._write_rules("-keep class androidx.media3.* { *; }\n")

        self.assertEqual(self._every_failure_kind(), self._failure_kinds(CHECKER.validate(self.root)))

    def test_keepclassmembers_alone_does_not_count_as_a_keep(self) -> None:
        # media3's consumer rules only keep the constructor, which neither keeps the class
        # nor pins its name. That is the state that shipped a release without the decoder.
        self._write_rules(
            "-keepclassmembers class androidx.media3.decoder.ffmpeg.FfmpegAudioRenderer {\n"
            "  <init>(android.os.Handler);\n"
            "}\n"
        )

        self.assertEqual(self._every_failure_kind(), self._failure_kinds(CHECKER.validate(self.root)))

    def test_class_keep_without_the_native_callback_member_is_reported(self) -> None:
        self._write_rules(
            "-keep class androidx.media3.decoder.ffmpeg.** {\n"
            "  <init>(android.os.Handler);\n"
            "}\n"
            "-keep class androidx.media3.decoder.SimpleDecoderOutputBuffer { *; }\n"
        )

        self.assertEqual(
            ["android/app/src/main/cpp/media3_ffmpeg_decoder/ffmpeg_jni.cc resolves "
             "androidx.media3.decoder.ffmpeg.FfmpegAudioDecoder.growOutputBuffer from native code "
             "but no -keep retains that member"],
            CHECKER.validate(self.root),
        )

    def test_renamable_descriptor_class_is_reported(self) -> None:
        self._write_rules("-keep class androidx.media3.decoder.ffmpeg.** { *; }\n")

        errors = CHECKER.validate(self.root)

        self.assertEqual(1, len(errors))
        self.assertIn("names androidx.media3.decoder.SimpleDecoderOutputBuffer in the descriptor", errors[0])

    def test_includedescriptorclasses_satisfies_the_descriptor_requirement(self) -> None:
        self._write_rules("-keep,includedescriptorclasses class androidx.media3.decoder.ffmpeg.** { *; }\n")

        self.assertEqual([], CHECKER.validate(self.root))

    def test_platform_descriptor_types_need_no_keep(self) -> None:
        # java.nio.ByteBuffer is in the return descriptor and must not be demanded.
        self._write_rules(FULL_RULES)

        self.assertEqual([], CHECKER.validate(self.root))

    def test_untraceable_member_lookup_fails_loudly(self) -> None:
        self.jni_path.write_text(
            'growOutputBufferMethod = env->GetMethodID(someClass, "growOutputBuffer", "()V");\n',
            encoding="utf-8",
        )
        self._write_rules(FULL_RULES)

        errors = CHECKER.validate(self.root)

        self.assertEqual(1, len(errors))
        self.assertIn("cannot trace", errors[0])

    def test_kotlin_field_reflection_without_a_member_name_pin_is_reported(self) -> None:
        self._write_source("android/libass/src/main/java/com/edde746/plezy/libass/AssProbe.kt", KOTLIN_REFLECTION_SOURCE)
        self._write_rules(FULL_RULES)

        self.assertEqual(
            ["android/libass/src/main/java/com/edde746/plezy/libass/AssProbe.kt resolves "
             "androidx.media3.extractor.mkv.MatroskaExtractor.extractorOutput with "
             "getDeclaredField/getDeclaredMethod but no -keep rule pins that member name",
             "android/libass/src/main/java/com/edde746/plezy/libass/AssProbe.kt resolves "
             "androidx.media3.extractor.mkv.MatroskaExtractor.subtitleSample with "
             "getDeclaredField/getDeclaredMethod but no -keep rule pins that member name"],
            CHECKER.validate(self.root),
        )

    def test_keepclassmembernames_satisfies_reflective_field_lookups(self) -> None:
        self._write_source("android/libass/src/main/java/com/edde746/plezy/libass/AssProbe.kt", KOTLIN_REFLECTION_SOURCE)
        self._write_source(
            "android/app/src/main/java/com/edde746/plezy/exoplayer/MatroskaFields.java", JAVA_REFLECTION_SOURCE
        )
        self._write_rules(FULL_RULES + MATROSKA_KEEP)

        self.assertEqual([], CHECKER.validate(self.root))

    def test_class_forname_is_not_satisfied_by_a_member_name_pin(self) -> None:
        self._write_source(
            "android/app/src/main/kotlin/com/edde746/plezy/boot/PluginLoader.kt",
            'package com.edde746.plezy.boot\n\n'
            'internal fun loadPlugin(): Class<*> = Class.forName("com.example.ReflectedPlugin")\n',
        )
        self._write_rules(FULL_RULES + "-keepclassmembernames class com.example.ReflectedPlugin { *; }\n")

        self.assertEqual(
            ["android/app/src/main/kotlin/com/edde746/plezy/boot/PluginLoader.kt resolves "
             "com.example.ReflectedPlugin with Class.forName but no -keep covers it"],
            CHECKER.validate(self.root),
        )

    def test_class_keep_satisfies_class_forname(self) -> None:
        self._write_source(
            "android/app/src/main/kotlin/com/edde746/plezy/boot/PluginLoader.kt",
            'package com.edde746.plezy.boot\n\n'
            'internal fun loadPlugin(): Class<*> = Class.forName("com.example.ReflectedPlugin")\n',
        )
        self._write_rules(FULL_RULES + "-keep class com.example.ReflectedPlugin { *; }\n")

        self.assertEqual([], CHECKER.validate(self.root))

    def test_reflection_in_test_sources_needs_no_keep(self) -> None:
        # Unit and instrumentation sources never run under R8, so their reflection
        # helpers must not demand keep rules.
        self._write_source("android/app/src/test/kotlin/com/edde746/plezy/Probe.kt", KOTLIN_REFLECTION_SOURCE)
        self._write_source("android/app/src/androidTest/kotlin/com/edde746/plezy/Probe.kt", KOTLIN_REFLECTION_SOURCE)
        self._write_rules(FULL_RULES)

        self.assertEqual([], CHECKER.validate(self.root))

    def test_unresolvable_reflective_receiver_fails_loudly(self) -> None:
        self._write_source(
            "android/app/src/main/kotlin/com/edde746/plezy/Probe.kt",
            'package com.edde746.plezy\n\n'
            'internal fun grab(target: Any) = target.javaClass.getDeclaredField("pendingResult")\n',
        )
        self._write_rules(FULL_RULES)

        errors = CHECKER.validate(self.root)

        self.assertEqual(1, len(errors))
        self.assertIn("cannot resolve", errors[0])

    def test_non_literal_class_for_name_fails_loudly(self) -> None:
        # A concatenated or constant name is invisible to the literal-matching
        # patterns; staying silent would green-light a release R8 may break.
        self._write_source(
            "android/app/src/main/kotlin/com/edde746/plezy/boot/PluginLoader.kt",
            'package com.edde746.plezy.boot\n\n'
            'internal fun loadPlugin(name: String): Class<*> = Class.forName("com.example." + name)\n',
        )
        self._write_rules(FULL_RULES + "-keep class com.example.** { *; }\n")

        errors = CHECKER.validate(self.root)

        self.assertEqual(1, len(errors))
        self.assertIn("cannot trace to a single string", errors[0])

    def test_non_literal_member_lookup_fails_loudly(self) -> None:
        self._write_source(
            "android/app/src/main/kotlin/com/edde746/plezy/Probe.kt",
            'package com.edde746.plezy\n\n'
            'private const val FIELD_NAME = "pendingResult"\n\n'
            'internal fun grab(target: Any) = target.javaClass.getDeclaredField(FIELD_NAME)\n',
        )
        self._write_rules(FULL_RULES)

        errors = CHECKER.validate(self.root)

        self.assertEqual(1, len(errors))
        self.assertIn("cannot trace to a single string", errors[0])

    def test_same_package_receiver_resolves_against_the_file_package(self) -> None:
        self._write_source(
            "android/app/src/main/kotlin/com/example/app/Host.kt",
            'package com.example.app\n\n'
            'internal fun poke() = Helper::class.java.getDeclaredMethod("secret")\n',
        )
        self._write_rules(FULL_RULES)

        errors = CHECKER.validate(self.root)

        self.assertEqual(1, len(errors))
        self.assertIn("com.example.app.Helper.secret", errors[0])

    def test_keepclassmembernames_does_not_satisfy_a_native_member_lookup(self) -> None:
        # A natively-reached member has no compile-time reference at all, so a rule that
        # allows shrinking (-keepclassmembernames) must not count as covering it.
        self._write_rules(
            "-keep class androidx.media3.decoder.ffmpeg.** {\n"
            "  <init>(android.os.Handler);\n"
            "}\n"
            "-keep class androidx.media3.decoder.SimpleDecoderOutputBuffer { *; }\n"
            "-keepclassmembernames class androidx.media3.decoder.ffmpeg.FfmpegAudioDecoder { growOutputBuffer; }\n"
        )

        self.assertEqual(
            ["android/app/src/main/cpp/media3_ffmpeg_decoder/ffmpeg_jni.cc resolves "
             "androidx.media3.decoder.ffmpeg.FfmpegAudioDecoder.growOutputBuffer from native code "
             "but no -keep retains that member"],
            CHECKER.validate(self.root),
        )


if __name__ == "__main__":
    unittest.main()
