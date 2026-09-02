#include "hdr_probe.h"

#include <cstdio>
#include <cstring>
#include <cwchar>
#include <vector>

namespace mpv {

namespace {

constexpr int kVerbatimChanges = 30;
constexpr int kSampleEvery = 50;

// Node keys that feed pl_tone_map_params_equal / gamut_map_signature.
constexpr const char* kStaticKeys[] = {
    "primaries",    "gamma",        "colormatrix", "colorlevels",
    "pixelformat",  "max-luma",     "min-luma",    "max-cll",
    "max-fall",     "sig-peak",     "prim-red-x",  "prim-red-y",
    "prim-green-x", "prim-green-y", "prim-blue-x", "prim-blue-y",
    "prim-white-x", "prim-white-y", "scene-max-r", "scene-max-g",
    "scene-max-b",  "scene-avg",    "w",           "h",
};
constexpr const char* kDynamicKeys[] = {"max-pq-y", "avg-pq-y"};

bool Wanted(const char* key, bool dynamic_fields) {
  if (dynamic_fields) {
    for (const char* k : kDynamicKeys) {
      if (std::strcmp(k, key) == 0) return true;
    }
    return false;
  }
  for (const char* k : kStaticKeys) {
    if (std::strcmp(k, key) == 0) return true;
  }
  return false;
}

void AppendValue(std::string& out, const mpv_node& node) {
  char buf[64];
  switch (node.format) {
    case MPV_FORMAT_STRING:
      out += node.u.string ? node.u.string : "";
      break;
    case MPV_FORMAT_INT64:
      snprintf(buf, sizeof(buf), "%lld", static_cast<long long>(node.u.int64));
      out += buf;
      break;
    case MPV_FORMAT_DOUBLE:
      // Exact float text: libplacebo compares these by exact equality, so a
      // last-digit wobble is a real LUT invalidation.
      snprintf(buf, sizeof(buf), "%.9g", node.u.double_);
      out += buf;
      break;
    case MPV_FORMAT_FLAG:
      out += node.u.flag ? "yes" : "no";
      break;
    default:
      out += "?";
      break;
  }
}

std::string SdrWhiteLevel(HMONITOR monitor) {
  MONITORINFOEXW mi{};
  mi.cbSize = sizeof(mi);
  if (!GetMonitorInfoW(monitor, &mi)) return "sdrwhite=?(monitorinfo)";

  UINT32 paths = 0, modes = 0;
  if (GetDisplayConfigBufferSizes(QDC_ONLY_ACTIVE_PATHS, &paths, &modes) != ERROR_SUCCESS) {
    return "sdrwhite=?(buffersizes)";
  }
  std::vector<DISPLAYCONFIG_PATH_INFO> path_info(paths);
  std::vector<DISPLAYCONFIG_MODE_INFO> mode_info(modes);
  if (QueryDisplayConfig(QDC_ONLY_ACTIVE_PATHS, &paths, path_info.data(), &modes, mode_info.data(), nullptr) !=
      ERROR_SUCCESS) {
    return "sdrwhite=?(querydisplayconfig)";
  }
  for (UINT32 i = 0; i < paths; ++i) {
    DISPLAYCONFIG_SOURCE_DEVICE_NAME source{};
    source.header.type = DISPLAYCONFIG_DEVICE_INFO_GET_SOURCE_NAME;
    source.header.size = sizeof(source);
    source.header.adapterId = path_info[i].sourceInfo.adapterId;
    source.header.id = path_info[i].sourceInfo.id;
    if (DisplayConfigGetDeviceInfo(&source.header) != ERROR_SUCCESS) continue;
    if (wcscmp(source.viewGdiDeviceName, mi.szDevice) != 0) continue;

    DISPLAYCONFIG_SDR_WHITE_LEVEL white{};
    white.header.type = DISPLAYCONFIG_DEVICE_INFO_GET_SDR_WHITE_LEVEL;
    white.header.size = sizeof(white);
    white.header.adapterId = path_info[i].targetInfo.adapterId;
    white.header.id = path_info[i].targetInfo.id;
    const LONG rc = DisplayConfigGetDeviceInfo(&white.header);
    char buf[64];
    if (rc != ERROR_SUCCESS) {
      snprintf(buf, sizeof(buf), "sdrwhite=?(rc=%ld)", rc);
    } else {
      snprintf(buf, sizeof(buf), "sdrwhite=%u(%.2fnits)", white.SDRWhiteLevel, white.SDRWhiteLevel / 1000.0 * 80.0);
    }
    return buf;
  }
  return "sdrwhite=?(no-path)";
}

}  // namespace

HdrProbe::HdrProbe(mpv_handle* mpv, HWND hwnd, Logger logger)
    : mpv_(mpv), hwnd_(hwnd), logger_(std::move(logger)), last_summary_(std::chrono::steady_clock::now()) {}

HdrProbe::~HdrProbe() {
  if (factory_) factory_->Release();
}

void HdrProbe::Stream::Observe(const std::string& now, const Logger& log) {
  if (now.empty() || now == last) return;
  const bool first = last.empty();
  last = now;
  if (first) {
    log(std::string(name) + " initial: " + now);
    return;
  }
  ++changes;
  if (changes <= kVerbatimChanges || changes % kSampleEvery == 0) {
    log(std::string(name) + " change #" + std::to_string(changes) + ": " + now);
  }
}

std::string HdrProbe::ReadParams(const char* property, bool dynamic_fields) {
  mpv_node node{};
  if (mpv_get_property(mpv_, property, MPV_FORMAT_NODE, &node) < 0) return {};
  std::string out;
  if (node.format == MPV_FORMAT_NODE_MAP) {
    for (int i = 0; i < node.u.list->num; ++i) {
      const char* key = node.u.list->keys[i];
      if (!Wanted(key, dynamic_fields)) continue;
      out += key;
      out += '=';
      AppendValue(out, node.u.list->values[i]);
      out += ' ';
    }
  }
  mpv_free_node_contents(&node);
  return out;
}

std::string HdrProbe::ReadDisplay() {
  HMONITOR monitor = MonitorFromWindow(hwnd_, MONITOR_DEFAULTTONULL);
  if (!monitor) return "monitor=none";

  // Mirrors mp_dxgi_output_desc_from_hwnd: mpv drops and recreates its factory
  // whenever IsCurrent() is false, and re-reads GetDesc1 on every frame.
  if (!factory_ || !factory_->IsCurrent()) {
    if (factory_) {
      factory_->Release();
      factory_ = nullptr;
      ++factory_recreations_;
    }
    if (FAILED(::CreateDXGIFactory1(IID_PPV_ARGS(&factory_)))) return "factory=failed";
  }

  std::string out;
  bool found = false;
  IDXGIAdapter1* adapter = nullptr;
  for (UINT a = 0; !found && SUCCEEDED(factory_->EnumAdapters1(a, &adapter)); ++a) {
    IDXGIOutput* output = nullptr;
    for (UINT o = 0; !found && SUCCEEDED(adapter->EnumOutputs(o, &output)); ++o) {
      DXGI_OUTPUT_DESC desc{};
      if (SUCCEEDED(output->GetDesc(&desc)) && desc.Monitor == monitor) {
        found = true;
        IDXGIOutput6* output6 = nullptr;
        DXGI_OUTPUT_DESC1 desc1{};
        if (SUCCEEDED(output->QueryInterface(IID_PPV_ARGS(&output6))) && SUCCEEDED(output6->GetDesc1(&desc1))) {
          char buf[320];
          snprintf(
              buf, sizeof(buf),
              "csp=%d bits=%u maxL=%.4g minL=%.4g maxFFL=%.4g R=%.5g,%.5g G=%.5g,%.5g B=%.5g,%.5g W=%.5g,%.5g",
              static_cast<int>(desc1.ColorSpace), desc1.BitsPerColor, desc1.MaxLuminance, desc1.MinLuminance,
              desc1.MaxFullFrameLuminance, desc1.RedPrimary[0], desc1.RedPrimary[1], desc1.GreenPrimary[0],
              desc1.GreenPrimary[1], desc1.BluePrimary[0], desc1.BluePrimary[1], desc1.WhitePoint[0],
              desc1.WhitePoint[1]);
          out = buf;
        } else {
          out = "desc1=unavailable";
        }
        if (output6) output6->Release();
      }
      output->Release();
      output = nullptr;
    }
    adapter->Release();
    adapter = nullptr;
  }
  if (!found) out = "output=not-found";
  out += ' ';
  out += SdrWhiteLevel(monitor);
  return out;
}

void HdrProbe::OnFileLoaded() {
  target_ = Stream{"target-params"};
  source_static_ = Stream{"source-params(static)"};
  source_dynamic_ = Stream{"source-params(dynamic)"};
  factory_recreations_ = 0;
  last_summary_ = std::chrono::steady_clock::now();
}

void HdrProbe::Tick() {
  ++tick_;
  // ~250 ms: fine enough to see per-frame churn, coarse enough to stay cheap.
  if (tick_ % 3 != 0) return;
  // Nothing to key on until a video is being rendered.
  int vo_configured = 0;
  if (mpv_get_property(mpv_, "vo-configured", MPV_FORMAT_FLAG, &vo_configured) < 0 || !vo_configured) return;

  target_.Observe(ReadParams("video-target-params", false), logger_);
  source_static_.Observe(ReadParams("video-out-params", false), logger_);
  source_dynamic_.Observe(ReadParams("video-out-params", true), logger_);
  // ~1 s: the DXGI enumeration is the expensive part.
  if (tick_ % 12 == 0) display_.Observe(ReadDisplay(), logger_);

  const auto now = std::chrono::steady_clock::now();
  if (now - last_summary_ >= std::chrono::seconds(10)) {
    last_summary_ = now;
    Summarize();
  }
}

void HdrProbe::Summarize() {
  char buf[256];
  snprintf(
      buf, sizeof(buf),
      "summary: target-params changes=%d source(static) changes=%d source(dynamic) changes=%d display "
      "changes=%d dxgi-factory-recreated=%d",
      target_.changes, source_static_.changes, source_dynamic_.changes, display_.changes, factory_recreations_);
  logger_(buf);
}

}  // namespace mpv
