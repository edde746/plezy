#pragma once

#include <stddef.h>
#include <stdint.h>

#if defined(_WIN32)
#if defined(PME_RUNTIME_BUILD)
#define PME_RUNTIME_API __declspec(dllexport)
#else
#define PME_RUNTIME_API __declspec(dllimport)
#endif
#else
#define PME_RUNTIME_API __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

#define PME_RUNTIME_ABI_VERSION 3u
#define PME_RUNTIME_MAX_TENSOR_RANK 8u

typedef struct pme_runtime_session pme_runtime_session;

typedef enum pme_device_kind {
  PME_DEVICE_ANY = 0,
  PME_DEVICE_GPU = 1,
  PME_DEVICE_NPU = 2,
  PME_DEVICE_CPU = 3,
} pme_device_kind;

/*
 * Plugin candidates name their provider library. Built-in ONNX Runtime
 * providers use provider-specific "builtin", "builtin-migraphx",
 * "builtin-dml", or "builtin-vitisai" markers; Windows ML catalog candidates
 * use "windows-ml". The built-in MIGraphX marker may use ORT C API v23 on
 * Linux; plugin and catalog providers require API v27 or newer. Candidates
 * are tried in order; CPU EP fallback is disabled for every accelerator.
 */
typedef struct pme_provider_candidate {
  uint32_t struct_size;
  const char* provider_name;
  const char* provider_library_path;
  pme_device_kind device_kind;
} pme_provider_candidate;

typedef int (*pme_runtime_cancelled_fn)(void* context);

typedef struct pme_runtime_config {
  uint32_t struct_size;
  uint32_t abi_version;
  const char* runtime_library_path;
  const char* model_path;
  const pme_provider_candidate* providers;
  size_t provider_count;
  uint32_t intra_op_threads;
  uint8_t allow_cpu_provider;
  /* QNN EP HTP mode: burst, balanced, or sustained_high_performance. */
  const char* htp_performance_mode;
  /* Optional cooperative cancellation during provider acquisition/setup. */
  pme_runtime_cancelled_fn is_cancelled;
  void* cancel_context;
} pme_runtime_config;

typedef struct pme_tensor_shape {
  uint32_t rank;
  int64_t dimensions[PME_RUNTIME_MAX_TENSOR_RANK];
  uint64_t element_count;
} pme_tensor_shape;

typedef struct pme_runtime_info {
  uint32_t struct_size;
  uint32_t abi_version;
  char provider_name[64];
  char provider_vendor[64];
  pme_device_kind device_kind;
  pme_tensor_shape input;
  pme_tensor_shape output;
} pme_runtime_info;

/*
 * Opens one-input/one-output float32 ONNX model session. Provider selection is
 * explicit and ordered; CPU is used only when allow_cpu_provider is set and no
 * accelerator candidate can own the complete graph.
 */
PME_RUNTIME_API int pme_runtime_open(
    const pme_runtime_config* config, pme_runtime_session** session_out, char* error_out, size_t error_capacity);

/* Opens using an ordered TSV manifest. Relative plugin paths resolve beside the manifest. */
PME_RUNTIME_API int pme_runtime_open_from_manifest(
    const pme_runtime_config* config, const char* provider_manifest_path, pme_runtime_session** session_out,
    char* error_out, size_t error_capacity);

PME_RUNTIME_API int pme_runtime_get_info(const pme_runtime_session* session, pme_runtime_info* info_out);

/* Runs a contiguous float32 input tensor and copies the float32 output. */
PME_RUNTIME_API int pme_runtime_run(
    pme_runtime_session* session, const float* input, uint64_t input_element_count, float* output,
    uint64_t output_capacity, uint64_t* output_element_count, char* error_out, size_t error_capacity);

PME_RUNTIME_API void pme_runtime_close(pme_runtime_session* session);

#ifdef __cplusplus
}
#endif
