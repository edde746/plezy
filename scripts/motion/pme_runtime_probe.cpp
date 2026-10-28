#include "pme_runtime.h"

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <cstdlib>
#include <iomanip>
#include <iostream>
#include <limits>
#include <numeric>
#include <random>
#include <stdexcept>
#include <string>
#include <vector>

namespace {

uint32_t parse_count(const char* value, uint32_t fallback, uint32_t minimum) {
  if (!value || !value[0]) return fallback;
  char* end = nullptr;
  const unsigned long parsed = std::strtoul(value, &end, 10);
  if (!end || *end || parsed < minimum || parsed > std::numeric_limits<uint32_t>::max()) {
    throw std::invalid_argument("warm-up and iteration counts must be valid integers");
  }
  return static_cast<uint32_t>(parsed);
}

double percentile(std::vector<double> values, double fraction) {
  std::sort(values.begin(), values.end());
  const double position = (values.size() - 1) * fraction;
  const size_t lower = static_cast<size_t>(position);
  const size_t upper = std::min(lower + 1, values.size() - 1);
  const double weight = position - lower;
  return values[lower] * (1.0 - weight) + values[upper] * weight;
}

std::string device_name(pme_device_kind kind) {
  switch (kind) {
    case PME_DEVICE_GPU:
      return "GPU";
    case PME_DEVICE_NPU:
      return "NPU";
    case PME_DEVICE_CPU:
      return "CPU";
    default:
      return "unknown";
  }
}

}  // namespace

int main(int argc, char** argv) {
  if (argc < 4 || argc > 9) {
    std::cerr << "Usage: pme_runtime_probe <runtime-library> <provider-manifest|-> <model> "
                 "[expected-provider] [warmups=3] [iterations=12] [--allow-cpu] [--cpu-only]\n"
                 "Use --cpu-only to open the explicit CPU provider without trying accelerators.\n";
    return 2;
  }

  pme_runtime_session* session = nullptr;
  try {
    bool allow_cpu = false;
    bool cpu_only = false;
    std::vector<const char*> positional{argv[1], argv[2], argv[3]};
    for (int i = 4; i < argc; ++i) {
      const std::string argument(argv[i]);
      if (argument == "--allow-cpu") {
        allow_cpu = true;
      } else if (argument == "--cpu-only") {
        cpu_only = true;
      } else {
        positional.push_back(argv[i]);
      }
    }
    if (positional.size() > 6) {
      throw std::invalid_argument("too many positional arguments");
    }
    const bool no_manifest = std::string(positional[1]) == "-";
    if (cpu_only && !no_manifest) {
      throw std::invalid_argument("--cpu-only requires '-' as the provider-manifest argument");
    }
    if (!cpu_only && no_manifest) {
      throw std::invalid_argument("a provider manifest is required unless --cpu-only is selected");
    }

    const uint32_t warmups = positional.size() > 4 ? parse_count(positional[4], 3, 0) : 3;
    const uint32_t iterations = positional.size() > 5 ? parse_count(positional[5], 12, 3) : 12;

    pme_runtime_config config{};
    config.struct_size = sizeof(config);
    config.abi_version = PME_RUNTIME_ABI_VERSION;
    config.runtime_library_path = positional[0];
    config.model_path = positional[2];
    config.intra_op_threads = 1;
    config.allow_cpu_provider = allow_cpu || cpu_only;

    char error[2048] = {};
    const auto session_started = std::chrono::steady_clock::now();
    const int open_result = cpu_only
                                ? pme_runtime_open(&config, &session, error, sizeof(error))
                                : pme_runtime_open_from_manifest(&config, positional[1], &session, error,
                                                                 sizeof(error));
    if (open_result != 0) {
      std::cerr << "PME session initialization failed: " << error << '\n';
      return 1;
    }
    const double session_open_ms = std::chrono::duration<double, std::milli>(
                                       std::chrono::steady_clock::now() - session_started)
                                       .count();

    pme_runtime_info info{};
    info.struct_size = sizeof(info);
    if (pme_runtime_get_info(session, &info) != 0) {
      std::cerr << "PME did not return runtime information\n";
      pme_runtime_close(session);
      return 1;
    }
    if (info.device_kind != PME_DEVICE_GPU && info.device_kind != PME_DEVICE_NPU &&
        info.device_kind != PME_DEVICE_CPU) {
      std::cerr << "PME selected an unknown device kind\n";
      pme_runtime_close(session);
      return 1;
    }
    if (cpu_only && info.device_kind != PME_DEVICE_CPU) {
      std::cerr << "Expected a CPU provider, received " << device_name(info.device_kind) << '\n';
      pme_runtime_close(session);
      return 1;
    }
    if (info.device_kind == PME_DEVICE_CPU && !allow_cpu && !cpu_only) {
      std::cerr << "PME selected CPU without an explicit CPU opt-in\n";
      pme_runtime_close(session);
      return 1;
    }
    if (positional.size() > 3 && std::string(info.provider_name) != positional[3]) {
      std::cerr << "Expected provider " << positional[3] << ", received " << info.provider_name << '\n';
      pme_runtime_close(session);
      return 1;
    }
    std::cerr << "PME session ready: " << info.provider_name << " on " << info.provider_vendor << ' '
              << device_name(info.device_kind) << " after " << std::fixed << std::setprecision(1) << session_open_ms
              << " ms\n";
    if (!info.input.element_count || !info.output.element_count ||
        info.input.element_count > std::numeric_limits<size_t>::max() ||
        info.output.element_count > std::numeric_limits<size_t>::max()) {
      std::cerr << "PME returned a missing or unsupported tensor shape\n";
      pme_runtime_close(session);
      return 1;
    }

    std::vector<float> input(static_cast<size_t>(info.input.element_count));
    std::vector<float> output(static_cast<size_t>(info.output.element_count));
    std::mt19937 random(0x504d45u);
    std::uniform_real_distribution<float> sample(0.0f, 1.0f);
    std::generate(input.begin(), input.end(), [&] { return sample(random); });

    uint64_t output_count = 0;
    for (uint32_t i = 0; i < warmups; ++i) {
      if (pme_runtime_run(session, input.data(), input.size(), output.data(), output.size(), &output_count,
                          error, sizeof(error)) != 0) {
        std::cerr << "PME warmup failed: " << error << '\n';
        pme_runtime_close(session);
        return 1;
      }
    }

    std::vector<double> timings_ms;
    timings_ms.reserve(iterations);
    for (uint32_t i = 0; i < iterations; ++i) {
      const auto started = std::chrono::steady_clock::now();
      if (pme_runtime_run(session, input.data(), input.size(), output.data(), output.size(), &output_count,
                          error, sizeof(error)) != 0) {
        std::cerr << "PME inference failed: " << error << '\n';
        pme_runtime_close(session);
        return 1;
      }
      const auto elapsed = std::chrono::duration<double, std::milli>(
                               std::chrono::steady_clock::now() - started)
                               .count();
      timings_ms.push_back(elapsed);
    }
    pme_runtime_close(session);
    session = nullptr;

    if (output_count != info.output.element_count ||
        !std::all_of(output.begin(), output.end(), [](float value) { return std::isfinite(value); })) {
      std::cerr << "PME returned an invalid output tensor\n";
      return 1;
    }

    const double total = std::accumulate(timings_ms.begin(), timings_ms.end(), 0.0);
    std::cout << std::fixed << std::setprecision(3)
              << "{\"provider\":\"" << info.provider_name << "\",\"vendor\":\"" << info.provider_vendor
              << "\",\"device\":\"" << device_name(info.device_kind)
              << "\",\"cpu_execution\":" << (info.device_kind == PME_DEVICE_CPU ? "true" : "false")
              << ",\"cpu_fallback\":"
              << (info.device_kind == PME_DEVICE_CPU && !cpu_only ? "true" : "false")
              << ",\"cpu_only\":" << (cpu_only ? "true" : "false")
              << ",\"input_elements\":" << info.input.element_count
              << ",\"output_elements\":" << info.output.element_count << ",\"warmups\":" << warmups
              << ",\"iterations\":" << iterations << ",\"session_open_ms\":" << session_open_ms
              << ",\"inference_ms\":{\"median\":"
              << percentile(timings_ms, 0.50) << ",\"p95\":" << percentile(timings_ms, 0.95)
              << ",\"mean\":" << total / timings_ms.size() << "}}\n";
  } catch (const std::exception& error) {
    if (session) pme_runtime_close(session);
    std::cerr << error.what() << '\n';
    return 2;
  }
  return 0;
}
