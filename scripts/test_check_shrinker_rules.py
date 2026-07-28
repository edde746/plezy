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
        self.assertEqual([], CHECKER.validate(Path(__file__).resolve().parents[1]))

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


if __name__ == "__main__":
    unittest.main()
