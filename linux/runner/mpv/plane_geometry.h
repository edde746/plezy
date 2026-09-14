#ifndef PLEZY_LINUX_MPV_PLANE_GEOMETRY_H_
#define PLEZY_LINUX_MPV_PLANE_GEOMETRY_H_

#include <cstdint>
#include <limits>

// How large the video plane's buffer is and where its subsurface sits, given
// the rect Flutter cut out for it and the output's buffer scale.
//
// This header is deliberately free of Wayland and GTK: both rules bias the
// plane *outward* on purpose, the penalty for getting either wrong is severe —
// an undersized plane shows the desktop through the seam, and a buffer size
// that is not a whole multiple of the buffer scale is a fatal protocol error
// that disconnects the client — and neither deserves a display server to test.
// Header-only is deliberate as well: pure functions over int32, no
// dependencies, every one of them inline.

namespace mpv {

// The buffer scale to actually divide and round by. Scale arrives as an int32
// cast of an unvalidated channel argument, and anything below 1 is not a scale:
// 0 would divide by zero and a negative would inflate the plane instead of
// shrinking it. One physical pixel per logical one is the identity, so it is
// also the safe floor.
inline int32_t NormalizePlaneScale(int32_t scale) { return scale < 1 ? 1 : scale; }

// Where one axis of the plane starts, in whole surface-local units.
//
// Floor, not truncate. C integer division rounds toward zero, which for a
// negative origin - a video rect scrolled partly off the left or top - would
// bias the plane *inward*, while the extent below deliberately rounds outward.
// Flooring makes both ends bias the same way.
inline int32_t PlaneOriginUnits(int32_t position, int32_t scale) {
  const int32_t divisor = NormalizePlaneScale(scale);
  const int32_t quotient = position / divisor;
  return (position % divisor != 0 && position < 0) ? quotient - 1 : quotient;
}

// One dimension of the plane's buffer, in physical pixels, for the rect
// [position, position + extent).
//
// Measured from the floored origin rather than from the extent alone, and this
// is the whole point: the two roundings have to compose. Flooring the origin
// moves the plane's left/top edge outward but does nothing for its right/bottom
// edge, so sizing from the extent on its own leaves the far edge short by
// whatever the floor gave away - at scale 2 a rect at x=1 of width 100 rounds to
// a 100-pixel buffer placed at 0, covering [0,100) while the hole is [1,101).
// The toplevel is an RGBA visual cleared to transparent, so that strip is not
// black: the desktop shows through it. Taking the far edge to the next whole
// unit and subtracting the floored origin covers the rect on both sides by
// construction, for every scale and either sign.
//
// The buffer size must also be an integer multiple of the buffer scale, or
// wl_surface.commit raises the fatal invalid_size error and the compositor
// disconnects us - the process dies with nothing in our own logs. A whole
// number of units times the scale is one by construction.
//
// Arithmetic in 64 bits because position and extent are int32 casts of
// unvalidated channel arguments: their sum, and the rounding added to it, both
// overflow int32 near the ends of the range, and a negative product would reach
// wl_egl_window_resize.
inline int32_t PlaneBufferExtent(int32_t position, int32_t extent, int32_t scale) {
  const int64_t block = NormalizePlaneScale(scale);
  const int64_t start = PlaneOriginUnits(position, scale);
  const int64_t far = static_cast<int64_t>(position) + extent;
  // Ceiling division that is correct for negatives too.
  const int64_t end = far >= 0 ? (far + block - 1) / block : -((-far) / block);
  int64_t span = (end - start) * block;
  // The floor of one whole block is what keeps a degenerate rect legal: a zero
  // or sub-scale extent would otherwise round to zero, which is not a multiple
  // the compositor accepts either. Callers that care whether the rect is worth
  // showing must ask before rounding, not after.
  if (span < block) span = block;
  // The largest multiple of the block that still fits in an int32. Rounding the
  // far edge up can carry the span past INT32_MAX, and the result has to remain
  // both representable and a whole multiple - taking the cap from the ceiling
  // rather than from INT32_MAX would throw away a whole block at odd scales.
  const int64_t cap = (static_cast<int64_t>(std::numeric_limits<int32_t>::max()) / block) * block;
  if (span > cap) span = cap;
  return static_cast<int32_t>(span);
}

// One axis of the subsurface's position, in the toplevel's surface-local frame.
//
// Positions are surface-local, i.e. logical units in the parent's frame.
// Floor, not truncate. C integer division rounds toward zero, which for a
// negative origin - a video rect scrolled partly off the left or top - would
// bias the plane *inward* by up to scale-1 physical pixels while the size
// above deliberately rounds outward. Flooring makes both ends bias the same
// way, so the plane always covers at least the rect Flutter cut out for it.
//
// `view_offset` is where the FlView sits inside the toplevel, and is added
// after the divide because GTK widget coordinates are already logical units,
// the same frame wl_subsurface_set_position expects.
//
// Summed in 64 bits and clamped, for the same reason PlaneBufferExtent is: the
// position is an int32 cast of an unvalidated channel argument, which setVideoRect
// clamps to INT32_MAX rather than rejecting. At scale 1 the floored origin is
// then INT32_MAX, and adding a non-zero offset - which is exactly what a
// client-side-decorated window supplies - is signed overflow. That is undefined
// behaviour, and the reliability builds run under -fsanitize=undefined.
inline int32_t PlaneSurfacePosition(int32_t position, int32_t scale, int32_t view_offset) {
  const int64_t sum = static_cast<int64_t>(PlaneOriginUnits(position, scale)) + view_offset;
  constexpr int64_t kMin = std::numeric_limits<int32_t>::min();
  constexpr int64_t kMax = std::numeric_limits<int32_t>::max();
  return static_cast<int32_t>(sum < kMin ? kMin : (sum > kMax ? kMax : sum));
}

}  // namespace mpv

#endif  // PLEZY_LINUX_MPV_PLANE_GEOMETRY_H_
