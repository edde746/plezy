# Subtitle model and runtime notices

This note records the model/runtime assets used by PR #53. Model files are fetched on demand into app-managed support storage; they are not bundled in the app release.

| Asset | Use | Source and license note |
| --- | --- | --- |
| Moonshine Tiny English, quantized ONNX | Sherpa ONNX CPU/Core ML/QNN/RKNN transcription requests | [sherpa-onnx model releases](https://github.com/k2-fsa/sherpa-onnx/releases/tag/asr-models) and [Moonshine documentation](https://github.com/moonshine-ai/moonshine). The upstream English Tiny model is MIT-licensed. The app pins the archive size and SHA-256 before extraction. |
| Silero VAD int8 ONNX | Voice activity segmentation for the Moonshine pipeline | [Silero VAD](https://github.com/snakers4/silero-vad), MIT license. The app pins the file size and SHA-256. |
| Whisper base Q5_1 | Multilingual CPU transcription, optional compiled desktop CUDA/Vulkan inference, and spoken-audio-to-English translation | Downloaded by [flutter_whisper_ggml](https://pub.dev/packages/flutter_whisper_ggml) from the whisper.cpp model registry; [whisper.cpp](https://github.com/ggml-org/whisper.cpp) and the OpenAI Whisper source/model repository use MIT licensing. The package verifies model metadata/checksum. The app does not redistribute the weight file. |
| Google ML Kit on-device Translation | Subtitle cue translation on eligible Android/iOS phones and tablets | Models are downloaded by Google's runtime when requested. Review the [Google ML Kit terms](https://developers.google.com/ml-kit/terms) and the package license before release. Embedded Android TV/automotive and tvOS use is gated off; translation execution placement is not exposed. |

The pinned dependency graph and model/runtime versions must be reviewed together during release qualification. The Flutter whisper.cpp integration is pinned to package version 0.0.2, which is pre-1.0 and may change its public API; recheck the package changelog before upgrading. If an upstream model asset, package version, checksum, or license changes, update this note and the in-app attribution/license surfaces before shipping. Do not assume that a model license also grants rights to the media being transcribed or translated.
