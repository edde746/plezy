#include "plane_geometry.h"

#include <iostream>
#include <limits>

namespace {

int failures = 0;

void Expect(bool condition, const char* expression, int line) {
  if (condition) return;
  std::cerr << "line " << line << ": check failed: " << expression << '\n';
  ++failures;
}

#define EXPECT(condition) Expect(static_cast<bool>(condition), #condition, __LINE__)

constexpr int32_t kInt32Max = std::numeric_limits<int32_t>::max();

// The common case: a rect Flutter already sized to a whole number of physical
// pixels must pass through untouched, at every scale. Rounding a legal size is
// not free - it grows the plane past the hole in the UI - so it must not happen
// when there is nothing to round.
void TestExactMultiplesAreUnchanged() {
  EXPECT(mpv::PlaneBufferExtent(0, 1920, 1) == 1920);
  EXPECT(mpv::PlaneBufferExtent(0, 1920, 2) == 1920);
  EXPECT(mpv::PlaneBufferExtent(0, 1920, 3) == 1920);
  EXPECT(mpv::PlaneBufferExtent(0, 1080, 2) == 1080);
  EXPECT(mpv::PlaneBufferExtent(0, 1083, 3) == 1083);
}

// The rule the compositor kills us over: a size that is not a whole multiple of
// the buffer scale is a fatal invalid_size on commit. It must round *up* - a
// size rounded down is smaller than the region Flutter cut out, and the desktop
// shows through the seam.
void TestSizesOnePixelOverRoundUpNeverDown() {
  EXPECT(mpv::PlaneBufferExtent(0, 1921, 2) == 1922);
  EXPECT(mpv::PlaneBufferExtent(0, 1921, 3) == 1923);
  EXPECT(mpv::PlaneBufferExtent(0, 1922, 3) == 1923);
  // One short of a multiple is the other side of the same boundary.
  EXPECT(mpv::PlaneBufferExtent(0, 1919, 2) == 1920);
  EXPECT(mpv::PlaneBufferExtent(0, 1919, 3) == 1920);
  // Scale 1 makes every size legal, so nothing may move.
  EXPECT(mpv::PlaneBufferExtent(0, 1921, 1) == 1921);
}

// Dart sends a 0x0 layout before the first real one, and a rect can be scrolled
// down to a sliver. Zero is not a legal buffer size and neither is anything
// below one whole scale unit, so the floor has to hold at every scale.
void TestDegenerateSizesYieldOneScaleUnit() {
  EXPECT(mpv::PlaneBufferExtent(0, 0, 1) == 1);
  EXPECT(mpv::PlaneBufferExtent(0, 0, 2) == 2);
  EXPECT(mpv::PlaneBufferExtent(0, 0, 3) == 3);
  EXPECT(mpv::PlaneBufferExtent(0, 1, 2) == 2);
  EXPECT(mpv::PlaneBufferExtent(0, 2, 3) == 3);
  // A negative extent is not reachable from a sane layout, but it is reachable
  // from an int32 cast of an unvalidated channel argument, and it must not
  // become a negative buffer size.
  EXPECT(mpv::PlaneBufferExtent(0, -4096, 2) == 2);
}

// The round-up adds up to scale-1 to its input, so a size near the type's
// maximum overflows unless it is clamped first - and a negative width reaching
// wl_egl_window_resize is exactly the corruption the clamp exists to stop.
void TestSizesNearIntMaxDoNotOverflow() {
  EXPECT(mpv::PlaneBufferExtent(0, kInt32Max, 1) == kInt32Max);
  EXPECT(mpv::PlaneBufferExtent(0, kInt32Max, 2) == kInt32Max - 1);
  EXPECT(mpv::PlaneBufferExtent(0, kInt32Max, 3) == kInt32Max - 1);
  EXPECT(mpv::PlaneBufferExtent(0, kInt32Max - 1, 3) == kInt32Max - 1);
}

// Every size the function can return must still be legal to commit: positive, a
// whole multiple of the scale, and never smaller than what was asked for. The
// individual cases above pin the interesting numbers; this pins the rule.
void TestBufferExtentInvariantsHold() {
  // Up to 16 because that is what the plugin clamps devicePixelRatio to before
  // handing it over as the buffer scale, so every one of these is reachable.
  for (int32_t scale = 1; scale <= 16; ++scale) {
    for (int32_t extent = -8; extent <= 64; ++extent) {
      const int32_t rounded = mpv::PlaneBufferExtent(0, extent, scale);
      EXPECT(rounded >= scale);
      EXPECT(rounded % scale == 0);
      EXPECT(rounded >= extent);
      // Rounding up, not up-and-then-some: the plane grows by less than a scale
      // unit, never a whole one.
      EXPECT(extent < scale || rounded - extent < scale);
    }
  }
}

// The one that matters, and the one neither rule can promise alone: wherever
// Flutter put the rect, the plane has to cover all of it. Flooring the origin
// moves the near edge outward and does nothing for the far edge, so an extent
// rounded from the width on its own leaves the far edge short by whatever the
// floor gave away - and the toplevel is transparent, so that strip shows the
// desktop rather than black.
//
// Swept over every scale the plugin accepts and both signs of origin, at rect
// sizes a window can actually have. Coverage is not universal and cannot be: a
// rect whose far edge needs more than INT32_MAX physical pixels is not
// representable, and TestAnUnrepresentableRectStaysLegal below pins what
// happens there instead.
void TestThePlaneAlwaysCoversTheRect() {
  for (int32_t scale = 1; scale <= 16; ++scale) {
    for (int32_t x = -40; x <= 40; ++x) {
      for (int32_t width = 1; width <= 80; ++width) {
        // Physical pixels, which is the frame the rect itself is in.
        const int64_t origin = static_cast<int64_t>(mpv::PlaneSurfacePosition(x, scale, 0)) * scale;
        const int64_t extent = mpv::PlaneBufferExtent(x, width, scale);

        EXPECT(origin <= x);
        EXPECT(origin + extent >= static_cast<int64_t>(x) + width);
        // Still legal to commit, which the far-edge rounding must not cost.
        EXPECT(extent % scale == 0);
        // And no more generous than it has to be: the cover is tight to within
        // one scale unit at each edge.
        EXPECT(x - origin < scale);
        EXPECT((origin + extent) - (static_cast<int64_t>(x) + width) < scale);
      }
    }
  }
}

// Past the end of int32 the plane cannot cover the rect, because the rect is
// not representable. What still has to hold is the one whose failure is fatal:
// a buffer size that is not a whole multiple of the scale makes wl_surface
// .commit an invalid_size protocol error and disconnects the whole client. So
// this asserts legality rather than coverage, and pins the largest legal answer
// so a future clamp cannot quietly give away a whole scale unit.
void TestAnUnrepresentableRectStaysLegal() {
  const int32_t huge = std::numeric_limits<int32_t>::max();
  for (int32_t scale = 1; scale <= 16; ++scale) {
    for (const int32_t x : {-1, 0, 1, 40}) {
      const int32_t extent = mpv::PlaneBufferExtent(x, huge, scale);
      EXPECT(extent > 0);
      EXPECT(extent % scale == 0);
      // The largest multiple of the scale that fits, not one block less.
      // Recomputing `(huge / scale) * scale` here would just be the cap
      // expression from the header again, so the interesting scales carry
      // literals: an oracle that is a copy of the code cannot fail with it.
      if (scale == 1) EXPECT(extent == 2147483647);
      if (scale == 2) EXPECT(extent == 2147483646);
      if (scale == 3) EXPECT(extent == 2147483646);
      if (scale == 8) EXPECT(extent == 2147483640);
      if (scale == 16) EXPECT(extent == 2147483632);
    }
  }
}

// An origin already on a scale boundary converts exactly, so the plane lands
// where Flutter put it.
void TestExactPositionMultiplesConvertExactly() {
  EXPECT(mpv::PlaneSurfacePosition(0, 2, 0) == 0);
  EXPECT(mpv::PlaneSurfacePosition(640, 1, 0) == 640);
  EXPECT(mpv::PlaneSurfacePosition(640, 2, 0) == 320);
  EXPECT(mpv::PlaneSurfacePosition(639, 3, 0) == 213);
  EXPECT(mpv::PlaneSurfacePosition(-640, 2, 0) == -320);
  EXPECT(mpv::PlaneSurfacePosition(-639, 3, 0) == -213);
}

// A positive origin off the boundary floors down, which for positives is what
// plain integer division already does. Pinned so the flooring below cannot be
// "fixed" into rounding.
void TestPositivePositionsFloorDown() {
  EXPECT(mpv::PlaneSurfacePosition(641, 2, 0) == 320);
  EXPECT(mpv::PlaneSurfacePosition(1, 2, 0) == 0);
  EXPECT(mpv::PlaneSurfacePosition(2, 3, 0) == 0);
  EXPECT(mpv::PlaneSurfacePosition(641, 3, 0) == 213);
  EXPECT(mpv::PlaneSurfacePosition(641, 1, 0) == 641);
}

// The case C gets wrong. A video rect scrolled partly off the left or top has a
// negative origin, and integer division truncates *toward zero* - which moves
// the plane inward by up to scale-1 physical pixels while the size deliberately
// grows outward, uncovering the very edge the size was widened to cover.
void TestNegativePositionsFloorAwayFromZero() {
  EXPECT(mpv::PlaneSurfacePosition(-1, 2, 0) == -1);  // truncation gives 0
  EXPECT(mpv::PlaneSurfacePosition(-3, 2, 0) == -2);  // truncation gives -1
  EXPECT(mpv::PlaneSurfacePosition(-1, 3, 0) == -1);  // truncation gives 0
  EXPECT(mpv::PlaneSurfacePosition(-4, 3, 0) == -2);  // truncation gives -1
  EXPECT(mpv::PlaneSurfacePosition(-641, 2, 0) == -321);
  // Scale 1 divides evenly, so there is nothing to floor and negatives survive.
  EXPECT(mpv::PlaneSurfacePosition(-641, 1, 0) == -641);
}

// The flooring must never place the plane's origin to the right of, or below,
// the rect it is covering: converted back to physical pixels the result is at
// or before the requested origin, and within one scale unit of it.
void TestPositionNeverBiasesInward() {
  for (int32_t scale = 1; scale <= 16; ++scale) {
    for (int32_t position = -32; position <= 32; ++position) {
      const int32_t local = mpv::PlaneSurfacePosition(position, scale, 0);
      EXPECT(local * scale <= position);
      EXPECT(position - local * scale < scale);
    }
  }
}

// The FlView is inset inside the toplevel whenever GTK draws client-side
// decorations, and wl_subsurface_set_position is relative to the toplevel. The
// offset is already in logical units, so it is added *after* the divide - adding
// it before would scale it and slide the plane by the wrong amount.
void TestViewOffsetIsAddedInSurfaceLocalUnits() {
  EXPECT(mpv::PlaneSurfacePosition(640, 2, 37) == 357);
  EXPECT(mpv::PlaneSurfacePosition(641, 2, 37) == 357);
  EXPECT(mpv::PlaneSurfacePosition(-3, 2, 37) == 35);
  EXPECT(mpv::PlaneSurfacePosition(639, 3, 8) == 221);
  EXPECT(mpv::PlaneSurfacePosition(640, 1, 8) == 648);
  // Had the offset been scaled instead of added straight, this would be 320+18.
  EXPECT(mpv::PlaneSurfacePosition(640, 2, 36) != 338);
}

// Server-side decorations - a KWin session, which is what this is developed on -
// make the offset zero. That path must be indistinguishable from having no
// offset at all, or the CSD fix would have quietly moved the plane everywhere it
// was already correct.
void TestZeroViewOffsetChangesNothing() {
  for (int32_t scale = 1; scale <= 16; ++scale) {
    for (int32_t position = -32; position <= 32; ++position) {
      const int32_t zero = mpv::PlaneSurfacePosition(position, scale, 0);
      // Stated as a property rather than by recomputing the implementation's own
      // formula: an oracle that is a copy of the code cannot fail for any change
      // made to both, including the flooring direction this is named for. The
      // property is that the origin lands on or before the rect and within one
      // scale unit of it.
      EXPECT(static_cast<int64_t>(zero) * scale <= position);
      EXPECT(position - static_cast<int64_t>(zero) * scale < scale);
      // And an offset really is just an addition on top of that answer.
      for (const int32_t offset : {-37, -1, 0, 1, 37}) {
        EXPECT(mpv::PlaneSurfacePosition(position, scale, offset) == zero + offset);
      }
    }
  }
}

// Scale reaches both rules as an int32 cast of an unvalidated channel argument.
// Zero would divide by zero and a negative would invert the rounding, so both
// collapse to the identity scale instead.
void TestNonPositiveScaleIsTreatedAsOne() {
  EXPECT(mpv::NormalizePlaneScale(0) == 1);
  EXPECT(mpv::NormalizePlaneScale(-4) == 1);
  EXPECT(mpv::NormalizePlaneScale(1) == 1);
  EXPECT(mpv::NormalizePlaneScale(3) == 3);
  EXPECT(mpv::PlaneBufferExtent(0, 1921, 0) == 1921);
  EXPECT(mpv::PlaneBufferExtent(0, 0, -4) == 1);
  EXPECT(mpv::PlaneSurfacePosition(-641, 0, 0) == -641);
  EXPECT(mpv::PlaneSurfacePosition(-641, -4, 7) == -634);
}

}  // namespace

int main() {
  TestExactMultiplesAreUnchanged();
  TestSizesOnePixelOverRoundUpNeverDown();
  TestDegenerateSizesYieldOneScaleUnit();
  TestSizesNearIntMaxDoNotOverflow();
  TestBufferExtentInvariantsHold();
  TestThePlaneAlwaysCoversTheRect();
  TestAnUnrepresentableRectStaysLegal();
  TestExactPositionMultiplesConvertExactly();
  TestPositivePositionsFloorDown();
  TestNegativePositionsFloorAwayFromZero();
  TestPositionNeverBiasesInward();
  TestViewOffsetIsAddedInSurfaceLocalUnits();
  TestZeroViewOffsetChangesNothing();
  TestNonPositiveScaleIsTreatedAsOne();
  return failures == 0 ? 0 : 1;
}
