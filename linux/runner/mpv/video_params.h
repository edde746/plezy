#ifndef PLEZY_LINUX_MPV_VIDEO_PARAMS_H_
#define PLEZY_LINUX_MPV_VIDEO_PARAMS_H_

#include <mpv/client.h>

#include <cstring>
#include <string>

// What mpv's `video-params` says about the current source's colour space and
// HDR10 static metadata.
//
// This is a pure function of one mpv_node, and deliberately so: it is the sole
// input to the whole HDR decision, the absent-versus-zero rules below are what
// keeps a source that stated nothing from being described as if it stated zero,
// and getting either wrong describes the plane in a colour space the pixels are
// not in. None of that needs a running mpv core to test. Header-only for the
// same reasons as the other pure headers here: one function over plain structs,
// no dependency beyond libmpv's own type.

namespace mpv {

// The source's colour space under mpv's own names, plus its HDR10 static
// metadata. A zero luminance means the source did not state it — mpv omits the
// field rather than reporting a zero — and the strings are empty when nothing
// is loaded.
struct SourceHdrMetadata {
  std::string transfer;        ///< mpv trc name, e.g. "pq", "hlg", "bt.1886"
  std::string primaries;       ///< mpv primaries name, e.g. "bt.2020"
  double max_cll = 0.0;        ///< nits, maximum content light level
  double max_fall = 0.0;       ///< nits, maximum frame-average light level
  double max_luminance = 0.0;  ///< nits, mastering display maximum
  double min_luminance = 0.0;  ///< nits, mastering display minimum
};

// Reads the fields the HDR decision needs out of a `video-params` node.
//
// Anything that is not the map mpv documents — a node of another type, a null
// list, a key of an unexpected format — yields the default, which reads as "no
// stream" everywhere downstream and describes no plane. Unrecognised names are
// carried through verbatim: what counts as an HDR curve is the caller's
// judgement, not this parse's.
inline SourceHdrMetadata ParseSourceHdrMetadata(const mpv_node* params) {
  SourceHdrMetadata metadata;
  if (params == nullptr || params->format != MPV_FORMAT_NODE_MAP || params->u.list == nullptr) return metadata;
  const mpv_node_list& entries = *params->u.list;
  if (entries.keys == nullptr || entries.values == nullptr) return metadata;

  auto name = [](const mpv_node& value, std::string* out) {
    if (value.format != MPV_FORMAT_STRING || value.u.string == nullptr) return;
    out->assign(value.u.string);
  };

  // mpv writes every luminance as a double. Integers are accepted as well
  // because the sub-property read this replaced asked for MPV_FORMAT_DOUBLE,
  // which libmpv would have converted for us.
  auto number = [](const mpv_node& value, double* out) {
    if (value.format == MPV_FORMAT_DOUBLE) {
      *out = value.u.double_;
      return true;
    }
    if (value.format == MPV_FORMAT_INT64) {
      *out = static_cast<double>(value.u.int64);
      return true;
    }
    return false;
  };

  // A luminance the source did not state stays absent rather than becoming a
  // zero-valued claim, and zero is exactly how the rest of the pipeline spells
  // "not stated" — so a zero here would be indistinguishable anyway.
  auto positive = [&number](const mpv_node& value, double* out) {
    double parsed = 0.0;
    if (!number(value, &parsed) || !(parsed > 0.0)) return;
    *out = parsed;
  };

  for (int i = 0; i < entries.num; ++i) {
    const char* key = entries.keys[i];
    if (key == nullptr) continue;
    const mpv_node& value = entries.values[i];
    // The two names decide whether the plane may be described as HDR at all, so
    // they are taken whether or not any luminance came with them: plenty of
    // HDR10 carries a PQ curve and no static metadata whatsoever.
    if (std::strcmp(key, "gamma") == 0) {
      name(value, &metadata.transfer);
    } else if (std::strcmp(key, "primaries") == 0) {
      name(value, &metadata.primaries);
    } else if (std::strcmp(key, "max-cll") == 0) {
      positive(value, &metadata.max_cll);
    } else if (std::strcmp(key, "max-fall") == 0) {
      positive(value, &metadata.max_fall);
    } else if (std::strcmp(key, "max-luma") == 0) {
      positive(value, &metadata.max_luminance);
    } else if (std::strcmp(key, "min-luma") == 0) {
      // The mastering floor is the one luminance a source may legitimately
      // state as zero — a display whose black is unmeasurably low — so it is
      // taken on its own terms and only a negative is refused.
      double parsed = 0.0;
      if (number(value, &parsed) && parsed >= 0.0) metadata.min_luminance = parsed;
    }
  }
  return metadata;
}

}  // namespace mpv

#endif  // PLEZY_LINUX_MPV_VIDEO_PARAMS_H_
