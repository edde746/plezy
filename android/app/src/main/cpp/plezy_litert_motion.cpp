#include <android/log.h>
#include <dirent.h>
#include <dlfcn.h>
#include <sys/stat.h>

#include <algorithm>
#include <cerrno>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <mutex>
#include <new>
#include <string>
#include <vector>

#include "litert/c/litert_compiled_model.h"
#include "litert/c/litert_environment.h"
#include "litert/c/litert_environment_options.h"
#include "litert/c/litert_model.h"
#include "litert/c/litert_model_types.h"
#include "litert/c/litert_options.h"
#include "litert/c/litert_tensor_buffer.h"
#include "litert/c/litert_tensor_buffer_requirements.h"

namespace {

constexpr char kLogTag[] = "PlezyLiteRT";
constexpr size_t kHostAlignment = 64;
constexpr size_t kMaxRank = LITERT_TENSOR_MAX_RANK;

struct MotionSession {
  LiteRtEnvironment environment = nullptr;
  LiteRtModel model = nullptr;
  LiteRtCompiledModel compiled = nullptr;
  LiteRtTensorBuffer input_buffer = nullptr;
  LiteRtTensorBuffer output_buffer = nullptr;
  LiteRtRankedTensorType input_type{};
  LiteRtRankedTensorType output_type{};
  LiteRtElementType input_element = kLiteRtElementTypeNone;
  LiteRtElementType output_element = kLiteRtElementTypeNone;
  LiteRtQuantizationPerTensor input_quant{};
  LiteRtQuantizationPerTensor output_quant{};
  void* input_memory = nullptr;
  void* output_memory = nullptr;
  size_t input_buffer_bytes = 0;
  size_t output_buffer_bytes = 0;
  size_t input_elements = 0;
  size_t output_elements = 0;
  size_t input_bytes = 0;
  size_t output_bytes = 0;
  std::string provider;
  std::vector<void*> provider_dependencies;
  std::mutex run_mutex;
};

void LogStatus(const char* operation, LiteRtStatus status) {
  __android_log_print(ANDROID_LOG_WARN, kLogTag, "%s failed: LiteRT status %d", operation, static_cast<int>(status));
}

bool Check(LiteRtStatus status, const char* operation) {
  if (status == kLiteRtStatusOk) return true;
  LogStatus(operation, status);
  return false;
}

bool SetStringOption(LiteRtEnvOption* option, LiteRtEnvOptionTag tag, const char* value) {
  if (!value || !value[0]) return false;
  option->tag = tag;
  option->value.type = kLiteRtAnyTypeString;
  option->value.str_value = value;
  return true;
}

bool GetQuantization(LiteRtTensor tensor, LiteRtQuantizationPerTensor* quant) {
  LiteRtQuantizationTypeId type = kLiteRtQuantizationNone;
  if (!Check(LiteRtGetQuantizationTypeId(tensor, &type), "LiteRtGetQuantizationTypeId")) return false;
  if (type != kLiteRtQuantizationPerTensor) return false;
  return Check(LiteRtGetPerTensorQuantization(tensor, quant), "LiteRtGetPerTensorQuantization") && quant->scale > 0.0f;
}

size_t ElementBytes(LiteRtElementType type) {
  switch (type) {
    case kLiteRtElementTypeFloat32:
    case kLiteRtElementTypeInt32:
    case kLiteRtElementTypeUInt32:
      return 4;
    case kLiteRtElementTypeFloat16:
    case kLiteRtElementTypeInt16:
    case kLiteRtElementTypeUInt16:
      return 2;
    case kLiteRtElementTypeInt8:
    case kLiteRtElementTypeUInt8:
    case kLiteRtElementTypeBool:
      return 1;
    default:
      return 0;
  }
}

bool LayoutElements(const LiteRtRankedTensorType& type, size_t* count) {
  if (type.layout.rank == 0 || type.layout.rank > kMaxRank) return false;
  size_t elements = 1;
  for (unsigned int i = 0; i < type.layout.rank; ++i) {
    const int32_t dimension = type.layout.dimensions[i];
    if (dimension <= 0 || static_cast<size_t>(dimension) > SIZE_MAX / elements) return false;
    elements *= static_cast<size_t>(dimension);
  }
  *count = elements;
  return true;
}

bool AllocateAligned(size_t alignment, size_t size, void** address) {
  alignment = std::max(alignment, kHostAlignment);
  if ((alignment & (alignment - 1)) != 0) return false;
  return posix_memalign(address, alignment, size) == 0 && *address != nullptr;
}

void PreloadOpenVinoDependencies(const char* library_dir, std::vector<void*>* handles) {
  if (!library_dir || !library_dir[0]) return;
  const std::string core_path = std::string(library_dir) + "/libopenvino.so";
  struct stat core_info{};
  if (stat(core_path.c_str(), &core_info) != 0 || !S_ISREG(core_info.st_mode)) return;

  // LiteRT's Intel provider AAR has DT_NEEDED references to OpenVINO and its
  // TFLite frontends, but Android's app linker namespace does not search the
  // staged files directory. Load those exact-version libraries by absolute
  // path first so the provider can resolve them by SONAME.
  constexpr const char* dependencies[] = {
      "libtbb.so",
      "libopenvino.so",
      "libopenvino_ir_frontend.so",
      "libopenvino_tensorflow_lite_frontend.so",
  };
  for (const char* name : dependencies) {
    const std::string path = std::string(library_dir) + "/" + name;
    void* handle = dlopen(path.c_str(), RTLD_NOW | RTLD_GLOBAL);
    if (handle) {
      handles->push_back(handle);
      continue;
    }

    __android_log_print(
        ANDROID_LOG_WARN, kLogTag, "Could not preload optional OpenVINO library %s: %s", name, dlerror());
    for (auto it = handles->rbegin(); it != handles->rend(); ++it) dlclose(*it);
    handles->clear();
    return;
  }
}

bool PrepareSamsungLiteCore(const char* library_dir, std::vector<void*>* handles) {
  if (!library_dir || !library_dir[0]) return false;
  const std::string litecore_root = std::string(library_dir) + "/litecore";
  const std::string litecore_library_dir = litecore_root + "/lib/arm64-v8a";
  const char* required[] = {"libgraph_wrapper.so", "libgraphgen_api.so"};
  for (const char* name : required) {
    const std::string path = litecore_library_dir + "/" + name;
    struct stat info{};
    if (stat(path.c_str(), &info) != 0 || !S_ISREG(info.st_mode)) return false;
  }

  if (setenv("EXYNOS_AI_LITECORE_ROOT", litecore_root.c_str(), 1) != 0) {
    __android_log_print(ANDROID_LOG_WARN, kLogTag, "Could not set EXYNOS_AI_LITECORE_ROOT: %s", std::strerror(errno));
    return false;
  }

  DIR* directory = opendir(litecore_library_dir.c_str());
  if (!directory) {
    __android_log_print(
        ANDROID_LOG_WARN, kLogTag, "Could not open Samsung LiteCore library directory: %s", std::strerror(errno));
    return false;
  }
  std::vector<std::string> libraries;
  while (dirent* entry = readdir(directory)) {
    const std::string name(entry->d_name);
    if (name.size() > 3 && name.compare(name.size() - 3, 3, ".so") == 0) {
      libraries.push_back(name);
    }
  }
  closedir(directory);
  std::sort(libraries.begin(), libraries.end());

  // LiteCore's two entry libraries can depend on other .so files shipped in
  // the same SDK directory. Android does not search an app-private folder for
  // DT_NEEDED dependencies, so load the package by absolute path and retry
  // unresolved dependencies after their siblings have been made global.
  std::vector<bool> loaded(libraries.size(), false);
  for (size_t pass = 0; pass < libraries.size(); ++pass) {
    bool progress = false;
    for (size_t index = 0; index < libraries.size(); ++index) {
      if (loaded[index]) continue;
      const std::string path = litecore_library_dir + "/" + libraries[index];
      void* handle = dlopen(path.c_str(), RTLD_NOW | RTLD_GLOBAL);
      if (!handle) {
        dlerror();
        continue;
      }
      loaded[index] = true;
      progress = true;
      handles->push_back(handle);
    }
    if (!progress) break;
  }

  for (const char* name : required) {
    const auto it = std::find(libraries.begin(), libraries.end(), name);
    if (it == libraries.end() || !loaded[static_cast<size_t>(it - libraries.begin())]) {
      __android_log_print(ANDROID_LOG_WARN, kLogTag, "Samsung LiteCore library %s could not be loaded", name);
      return false;
    }
  }
  return true;
}

bool TensorBufferRequirements(LiteRtCompiledModel compiled, bool input, size_t* alignment, size_t* buffer_bytes) {
  LiteRtTensorBufferRequirements requirements = nullptr;
  const LiteRtStatus status = input ? LiteRtGetCompiledModelInputBufferRequirements(compiled, 0, 0, &requirements)
                                    : LiteRtGetCompiledModelOutputBufferRequirements(compiled, 0, 0, &requirements);
  if (!Check(status, input ? "input buffer requirements" : "output buffer requirements")) return false;
  const bool aligned =
      Check(LiteRtGetTensorBufferRequirementsAlignment(requirements, alignment), "tensor buffer alignment");
  const bool sized =
      Check(LiteRtGetTensorBufferRequirementsBufferSize(requirements, buffer_bytes), "tensor buffer size");
  // Requirements returned by CompiledModel are borrowed and stay owned by
  // that model. Destroying this handle here invalidates the runtime's buffer
  // contract before inference starts.
  return aligned && sized;
}

bool BuildEnvironment(
    const char* plugin_dir, const char* dispatch_dir, const char* runtime_dir, const char* cache_dir,
    LiteRtEnvironment* environment) {
  LiteRtEnvOption options[4]{};
  int count = 0;
  if (plugin_dir && plugin_dir[0])
    SetStringOption(&options[count++], kLiteRtEnvOptionTagCompilerPluginLibraryDir, plugin_dir);
  if (dispatch_dir && dispatch_dir[0])
    SetStringOption(&options[count++], kLiteRtEnvOptionTagDispatchLibraryDir, dispatch_dir);
  if (runtime_dir && runtime_dir[0])
    SetStringOption(&options[count++], kLiteRtEnvOptionTagRuntimeLibraryDir, runtime_dir);
  if (cache_dir && cache_dir[0]) {
    mkdir(cache_dir, 0700);
    SetStringOption(&options[count++], kLiteRtEnvOptionTagCompilerCacheDir, cache_dir);
  }
  return Check(LiteRtCreateEnvironment(count, options, environment), "LiteRtCreateEnvironment");
}

void ClearCompiledAttempt(MotionSession* session) {
  if (session->input_buffer) LiteRtDestroyTensorBuffer(session->input_buffer);
  if (session->output_buffer) LiteRtDestroyTensorBuffer(session->output_buffer);
  session->input_buffer = nullptr;
  session->output_buffer = nullptr;
  std::free(session->input_memory);
  std::free(session->output_memory);
  session->input_memory = nullptr;
  session->output_memory = nullptr;
  session->input_buffer_bytes = 0;
  session->output_buffer_bytes = 0;
  if (session->compiled) LiteRtDestroyCompiledModel(session->compiled);
  session->compiled = nullptr;
  if (session->model) LiteRtDestroyModel(session->model);
  session->model = nullptr;
  session->input_elements = 0;
  session->output_elements = 0;
  session->input_bytes = 0;
  session->output_bytes = 0;
  session->provider.clear();
}

void DestroySession(MotionSession* session) {
  if (!session) return;
  ClearCompiledAttempt(session);
  if (session->environment) LiteRtDestroyEnvironment(session->environment);
  for (auto it = session->provider_dependencies.rbegin(); it != session->provider_dependencies.rend(); ++it) {
    dlclose(*it);
  }
  delete session;
}

bool CreateCompiledModel(
    MotionSession* session, LiteRtHwAccelerators accelerator, int32_t expected_width, int32_t expected_height) {
  LiteRtOptions options = nullptr;
  if (!Check(LiteRtCreateOptions(&options), "LiteRtCreateOptions")) return false;
  const int accelerator_mask = static_cast<int>(accelerator);
  const bool selected =
      Check(LiteRtSetOptionsHardwareAccelerators(options, accelerator_mask), "LiteRtSetOptionsHardwareAccelerators");
  const LiteRtStatus create_status =
      selected ? LiteRtCreateCompiledModel(session->environment, session->model, options, &session->compiled)
               : kLiteRtStatusErrorRuntimeFailure;
  LiteRtDestroyOptions(options);
  if (!Check(create_status, "LiteRtCreateCompiledModel")) return false;

  bool fully_hardware = false;
  if (!Check(
          LiteRtCompiledModelIsNonCpuFullyAccelerated(session->compiled, &fully_hardware),
          "LiteRtCompiledModelIsNonCpuFullyAccelerated") ||
      !fully_hardware) {
    __android_log_print(
        ANDROID_LOG_INFO, kLogTag, "LiteRT rejected %s session because it would use a CPU subgraph",
        accelerator == kLiteRtHwAcceleratorNpu ? "NPU" : "GPU");
    LiteRtDestroyCompiledModel(session->compiled);
    session->compiled = nullptr;
    return false;
  }

  LiteRtSignature signature = nullptr;
  LiteRtParamIndex input_count = 0;
  LiteRtParamIndex output_count = 0;
  if (!Check(LiteRtGetModelSignature(session->model, 0, &signature), "LiteRtGetModelSignature") ||
      !Check(LiteRtGetNumSignatureInputs(signature, &input_count), "LiteRtGetNumSignatureInputs") ||
      !Check(LiteRtGetNumSignatureOutputs(signature, &output_count), "LiteRtGetNumSignatureOutputs") ||
      input_count != 1 || output_count != 1) {
    return false;
  }
  LiteRtTensor input_tensor = nullptr;
  LiteRtTensor output_tensor = nullptr;
  if (!Check(LiteRtGetSignatureInputTensorByIndex(signature, 0, &input_tensor), "model input") ||
      !Check(LiteRtGetSignatureOutputTensorByIndex(signature, 0, &output_tensor), "model output") ||
      !Check(LiteRtGetRankedTensorType(input_tensor, &session->input_type), "input type") ||
      !Check(LiteRtGetRankedTensorType(output_tensor, &session->output_type), "output type")) {
    return false;
  }
  const auto has_image_shape = [expected_width, expected_height](const LiteRtRankedTensorType& type, int32_t channels) {
    return type.layout.rank == 4 && type.layout.dimensions[0] == 1 && type.layout.dimensions[1] == expected_height &&
           type.layout.dimensions[2] == expected_width && type.layout.dimensions[3] == channels;
  };
  if (!has_image_shape(session->input_type, 6) || !has_image_shape(session->output_type, 3)) {
    __android_log_print(
        ANDROID_LOG_WARN, kLogTag, "LiteRT model shape mismatch for %dx%d ANVIL tensors", expected_width,
        expected_height);
    return false;
  }
  session->input_element = session->input_type.element_type;
  session->output_element = session->output_type.element_type;
  if (!LayoutElements(session->input_type, &session->input_elements) ||
      !LayoutElements(session->output_type, &session->output_elements)) {
    return false;
  }

  size_t input_alignment = 0;
  size_t output_alignment = 0;
  if (!TensorBufferRequirements(session->compiled, true, &input_alignment, &session->input_buffer_bytes) ||
      !TensorBufferRequirements(session->compiled, false, &output_alignment, &session->output_buffer_bytes)) {
    return false;
  }
  const size_t input_element_bytes = ElementBytes(session->input_element);
  const size_t output_element_bytes = ElementBytes(session->output_element);
  if ((session->input_element != kLiteRtElementTypeFloat32 && session->input_element != kLiteRtElementTypeInt8 &&
       session->input_element != kLiteRtElementTypeUInt8) ||
      (session->output_element != kLiteRtElementTypeFloat32 && session->output_element != kLiteRtElementTypeInt8 &&
       session->output_element != kLiteRtElementTypeUInt8) ||
      !input_element_bytes || !output_element_bytes || session->input_elements > SIZE_MAX / input_element_bytes ||
      session->output_elements > SIZE_MAX / output_element_bytes) {
    return false;
  }
  session->input_bytes = session->input_elements * input_element_bytes;
  session->output_bytes = session->output_elements * output_element_bytes;
  session->input_buffer_bytes = std::max(session->input_buffer_bytes, session->input_bytes);
  session->output_buffer_bytes = std::max(session->output_buffer_bytes, session->output_bytes);
  if (!AllocateAligned(input_alignment, session->input_buffer_bytes, &session->input_memory) ||
      !AllocateAligned(output_alignment, session->output_buffer_bytes, &session->output_memory)) {
    return false;
  }
  std::memset(session->input_memory, 0, session->input_bytes);
  std::memset(session->output_memory, 0, session->output_bytes);
  if (!Check(
          LiteRtCreateTensorBufferFromHostMemory(
              &session->input_type, session->input_memory, session->input_buffer_bytes, nullptr,
              &session->input_buffer),
          "LiteRtCreateTensorBufferFromHostMemory(input)") ||
      !Check(
          LiteRtCreateTensorBufferFromHostMemory(
              &session->output_type, session->output_memory, session->output_buffer_bytes, nullptr,
              &session->output_buffer),
          "LiteRtCreateTensorBufferFromHostMemory(output)")) {
    return false;
  }
  if (session->input_element == kLiteRtElementTypeInt8 || session->input_element == kLiteRtElementTypeUInt8) {
    if (!GetQuantization(input_tensor, &session->input_quant)) return false;
  }
  if (session->output_element == kLiteRtElementTypeInt8 || session->output_element == kLiteRtElementTypeUInt8) {
    if (!GetQuantization(output_tensor, &session->output_quant)) return false;
  }
  session->provider = accelerator == kLiteRtHwAcceleratorNpu ? "litert-npu" : "litert-gpu";
  __android_log_print(ANDROID_LOG_INFO, kLogTag, "ANVIL model opened with %s", session->provider.c_str());
  return true;
}

template <typename T>
void Quantize(
    const float* source, T* destination, size_t count, const LiteRtQuantizationPerTensor& quant, int64_t low,
    int64_t high) {
  const float inverse_scale = 1.0f / quant.scale;
  for (size_t i = 0; i < count; ++i) {
    const int64_t value = static_cast<int64_t>(std::lrint(source[i] * inverse_scale)) + quant.zero_point;
    destination[i] = static_cast<T>(std::clamp(value, low, high));
  }
}

template <typename T>
void Dequantize(const T* source, float* destination, size_t count, const LiteRtQuantizationPerTensor& quant) {
  for (size_t i = 0; i < count; ++i) {
    destination[i] = (static_cast<int64_t>(source[i]) - quant.zero_point) * quant.scale;
  }
}

bool WriteInput(MotionSession* session, const float* input) {
  switch (session->input_element) {
    case kLiteRtElementTypeFloat32:
      std::memcpy(session->input_memory, input, session->input_bytes);
      return true;
    case kLiteRtElementTypeInt8:
      Quantize(
          input, static_cast<int8_t*>(session->input_memory), session->input_elements, session->input_quant, -128, 127);
      return true;
    case kLiteRtElementTypeUInt8:
      Quantize(
          input, static_cast<uint8_t*>(session->input_memory), session->input_elements, session->input_quant, 0, 255);
      return true;
    default:
      return false;
  }
}

bool ReadOutput(MotionSession* session, float* output) {
  switch (session->output_element) {
    case kLiteRtElementTypeFloat32:
      std::memcpy(output, session->output_memory, session->output_bytes);
      return true;
    case kLiteRtElementTypeInt8:
      Dequantize(
          static_cast<const int8_t*>(session->output_memory), output, session->output_elements, session->output_quant);
      return true;
    case kLiteRtElementTypeUInt8:
      Dequantize(
          static_cast<const uint8_t*>(session->output_memory), output, session->output_elements, session->output_quant);
      return true;
    default:
      return false;
  }
}

}  // namespace

extern "C" {

void* plezy_litert_motion_open(
    const char* model_path, const char* gpu_model_path, const char* library_dir, const char* cache_dir,
    int32_t expected_width, int32_t expected_height, char* provider, size_t provider_capacity) {
  if ((!model_path || !model_path[0]) && (!gpu_model_path || !gpu_model_path[0])) return nullptr;
  MotionSession* session = new (std::nothrow) MotionSession();
  if (!session) return nullptr;
  PrepareSamsungLiteCore(library_dir, &session->provider_dependencies);
  PreloadOpenVinoDependencies(library_dir, &session->provider_dependencies);
  if (!BuildEnvironment(library_dir, library_dir, library_dir, cache_dir, &session->environment)) {
    DestroySession(session);
    return nullptr;
  }

  const auto try_provider = [&](const char* candidate, LiteRtHwAccelerators accelerator) {
    if (!candidate || !candidate[0]) return false;
    if (!Check(
            LiteRtCreateModelFromFile(session->environment, candidate, &session->model), "LiteRtCreateModelFromFile")) {
      ClearCompiledAttempt(session);
      return false;
    }
    if (CreateCompiledModel(session, accelerator, expected_width, expected_height)) return true;
    ClearCompiledAttempt(session);
    return false;
  };

  bool opened = try_provider(model_path, kLiteRtHwAcceleratorNpu);
  if (!opened) {
    // NPU artifacts are statically quantized for mobile NPUs; GPU artifacts
    // remain float32. Keeping those model variants separate avoids an
    // undocumented provider conversion or CPU subgraph fallback.
    opened = try_provider(gpu_model_path, kLiteRtHwAcceleratorGpu);
  }
  if (!opened) {
    DestroySession(session);
    return nullptr;
  }
  if (provider && provider_capacity) {
    std::snprintf(provider, provider_capacity, "%s", session->provider.c_str());
  }
  return session;
}

int plezy_litert_motion_run(void* opaque_session, const float* input, float* output) {
  auto* session = static_cast<MotionSession*>(opaque_session);
  if (!session || !input || !output) return 0;
  std::lock_guard<std::mutex> lock(session->run_mutex);
  if (!WriteInput(session, input)) return 0;
  if (!Check(
          LiteRtRunCompiledModel(session->compiled, 0, 1, &session->input_buffer, 1, &session->output_buffer),
          "LiteRtRunCompiledModel")) {
    return 0;
  }
  return ReadOutput(session, output) ? 1 : 0;
}

void plezy_litert_motion_close(void* opaque_session) { DestroySession(static_cast<MotionSession*>(opaque_session)); }

}  // extern "C"
