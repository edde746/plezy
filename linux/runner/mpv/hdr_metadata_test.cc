#include "hdr_metadata.h"

#include <iostream>

namespace {

int failures = 0;

void Expect(bool condition, const char* expression, int line) {
  if (condition) return;
  std::cerr << "line " << line << ": check failed: " << expression << '\n';
  ++failures;
}

#define EXPECT(condition) Expect(static_cast<bool>(condition), #condition, __LINE__)

// Defaults to PQ / BT.2020, since that is what the luminance rules are usually
// exercised against. HLG cases override the transfer explicitly.
mpv::HdrMetadata Metadata(
    uint32_t max_cll, uint32_t max_fall, uint32_t max_luminance, double min_luminance,
    mpv::SourceTransfer transfer = mpv::SourceTransfer::kPq) {
  mpv::HdrMetadata metadata;
  metadata.transfer = transfer;
  metadata.primaries = mpv::SourcePrimaries::kBt2020;
  metadata.max_cll = max_cll;
  metadata.max_fall = max_fall;
  metadata.max_luminance = max_luminance;
  metadata.min_luminance = min_luminance;
  return metadata;
}

mpv::CompositorLuminanceSupport Support(
    bool mastering, uint32_t interface_version, bool extended_target_volume = false) {
  mpv::CompositorLuminanceSupport support;
  support.mastering = mastering;
  support.interface_version = interface_version;
  support.extended_target_volume = extended_target_volume;
  return support;
}

// Well-formed HDR10 keeps every field: this is the common case and it must not
// be degraded by the validation.
void TestWellFormedMetadataSurvives() {
  const auto plan = mpv::PlanHdrLuminance(Metadata(1000, 400, 1000, 0.0001), Support(true, 1));
  EXPECT(plan.send_mastering);
  EXPECT(plan.mastering_max == 1000);
  // 0.0001 nits sits below the primary colour volume's 0.005 floor, so it is
  // clamped up to stay contained; see TestMasteringFloorClampedIntoPrimaryVolume.
  EXPECT(plan.mastering_min_scaled == mpv::kPrimaryVolumeMinScaled);
  EXPECT(plan.send_max_cll);
  EXPECT(plan.max_cll == 1000);
  EXPECT(plan.send_max_fall);
  EXPECT(plan.max_fall == 400);
}

// The 10000-nit synthetic clip. The volume cap drops anything strictly above
// the curve's maximum, so max_cll sitting exactly on PQ's 10000 is the boundary
// case that must survive it.
void TestMaxCllAtPqCeilingIsKept() {
  const auto plan = mpv::PlanHdrLuminance(Metadata(10000, 600, 10000, 0.0001), Support(true, 1));
  EXPECT(plan.send_mastering);
  EXPECT(plan.mastering_max == 10000);
  EXPECT(plan.send_max_cll);
  EXPECT(plan.max_cll == 10000);
  EXPECT(plan.send_max_fall);
  EXPECT(plan.max_fall == 600);
}

// A MaxCLL above the mastering display's own peak is common in badly authored
// files and is a fatal invalid_luminance on version 1. The light level goes,
// not the mastering range.
void TestMaxCllAboveMasteringMaxIsDroppedOnV1() {
  const auto plan = mpv::PlanHdrLuminance(Metadata(4000, 400, 1000, 0.005), Support(true, 1));
  EXPECT(plan.send_mastering);
  EXPECT(plan.mastering_max == 1000);
  EXPECT(!plan.send_max_cll);
  EXPECT(plan.send_max_fall);
  EXPECT(plan.max_fall == 400);
}

// Version 2 dropped that requirement, so the same metadata keeps max_cll.
void TestMaxCllAboveMasteringMaxIsKeptOnV2() {
  const auto plan = mpv::PlanHdrLuminance(Metadata(4000, 400, 1000, 0.005), Support(true, 2));
  EXPECT(plan.send_mastering);
  EXPECT(plan.send_max_cll);
  EXPECT(plan.max_cll == 4000);
  EXPECT(plan.send_max_fall);
}

// The same version-1 range rule applies to MaxFALL independently, and this is
// the case where nothing else would catch a regression: MaxCLL is unset, so the
// pair rule cannot fire and drop MaxFALL for the wrong reason. Getting it wrong
// sends a request set that is a *fatal* invalid_luminance, which disconnects the
// whole client rather than just failing the description.
void TestMaxFallAboveMasteringMaxIsDroppedOnV1() {
  const auto plan = mpv::PlanHdrLuminance(Metadata(0, 1001, 1000, 0.005), Support(true, 1));
  EXPECT(plan.send_mastering);
  EXPECT(plan.mastering_max == 1000);
  EXPECT(!plan.send_max_cll);
  EXPECT(!plan.send_max_fall);
}

// max_fall > max_cll is a protocol error in *every* version. max_fall is the
// one dropped.
void TestMaxFallAboveMaxCllIsDropped() {
  for (uint32_t version = 1; version <= 3; ++version) {
    const auto plan = mpv::PlanHdrLuminance(Metadata(600, 900, 1000, 0.0001), Support(true, version));
    EXPECT(plan.send_max_cll);
    EXPECT(plan.max_cll == 600);
    EXPECT(!plan.send_max_fall);
  }
}

// When max_cll is dropped for being outside the range, the pair rule no longer
// applies and a legal max_fall survives on its own.
void TestMaxFallSurvivesWhenMaxCllIsDropped() {
  const auto plan = mpv::PlanHdrLuminance(Metadata(4000, 900, 1000, 0.0001), Support(true, 1));
  EXPECT(!plan.send_max_cll);
  EXPECT(plan.send_max_fall);
  EXPECT(plan.max_fall == 900);
}

// Without the advertised feature the mastering request would be
// unsupported_feature, so it is never sent. The light levels are then bounded by
// PQ's ceiling instead of the stream's mastering range.
void TestMasteringSuppressedWithoutCompositorSupport() {
  const auto plan = mpv::PlanHdrLuminance(Metadata(4000, 400, 1000, 0.0001), Support(false, 1));
  EXPECT(!plan.send_mastering);
  EXPECT(plan.send_max_cll);
  EXPECT(plan.max_cll == 4000);
  EXPECT(plan.send_max_fall);
}

// max L <= min L is invalid_luminance on set_mastering_luminance itself.
void TestInvertedMasteringRangeIsSuppressed() {
  const auto plan = mpv::PlanHdrLuminance(Metadata(500, 100, 1, 5.0), Support(true, 1));
  EXPECT(!plan.send_mastering);
  // With no mastering range the bound is PQ's ceiling, so both survive.
  EXPECT(plan.send_max_cll);
  EXPECT(plan.send_max_fall);
}

// Equal min and max is also rejected: the protocol wants strictly greater.
void TestEqualMasteringRangeIsSuppressed() {
  const auto plan = mpv::PlanHdrLuminance(Metadata(0, 0, 1, 1.0), Support(true, 1));
  EXPECT(!plan.send_mastering);
}

// A corrupt mastering maximum must not overflow the scaled comparison, and must
// not describe a display brighter than PQ can encode.
void TestMasteringMaxIsCappedAtPqCeiling() {
  const auto plan = mpv::PlanHdrLuminance(Metadata(0, 0, 4000000000u, 0.0001), Support(true, 1));
  EXPECT(plan.send_mastering);
  EXPECT(plan.mastering_max == mpv::kPqMaxLuminanceNits);
}

// A light level PQ has no code point for is dropped on every version.
void TestLightLevelsAbovePqCeilingAreDropped() {
  for (uint32_t version = 1; version <= 3; ++version) {
    const auto plan = mpv::PlanHdrLuminance(Metadata(4000000000u, 3000000000u, 0, 0.0), Support(true, version));
    EXPECT(!plan.send_max_cll);
    EXPECT(!plan.send_max_fall);
  }
}

// A source that carried nothing sends nothing, leaving the compositor on its
// own defaults.
void TestEmptyMetadataSendsNothing() {
  const auto plan = mpv::PlanHdrLuminance(mpv::HdrMetadata(), Support(true, 1));
  EXPECT(!plan.send_mastering);
  EXPECT(!plan.send_max_cll);
  EXPECT(!plan.send_max_fall);
}

// A mastering minimum coarser than one scaled unit must still round to a
// non-zero floor rather than silently becoming "unset".
void TestMinLuminanceScaling() {
  EXPECT(mpv::ScaleMinLuminance(0.0001) == 1);
  // Half a scaled unit. Without the rounding term this truncates to 0, i.e. the
  // floor silently becomes "unset" instead of the smallest expressible value.
  EXPECT(mpv::ScaleMinLuminance(0.00005) == 1);
  EXPECT(mpv::ScaleMinLuminance(0.005) == 50);
  EXPECT(mpv::ScaleMinLuminance(1.0) == 10000);
  EXPECT(mpv::ScaleMinLuminance(0.0) == 0);
  EXPECT(mpv::ScaleMinLuminance(-1.0) == 0);
  // An out-of-range float-to-uint32 conversion is undefined behaviour rather than
  // a wrap, and mpv's video-params is untrusted input, so saturating is part of
  // the contract rather than an implementation detail.
  EXPECT(mpv::ScaleMinLuminance(1e30) == 4294967295u);
}

// The range predicate itself: strictly above min L, at or below max L.
void TestRangePredicateBoundaries() {
  // min L = 0.0001 nits, so any whole nit clears it.
  EXPECT(mpv::LuminanceInMasteringRange(1, 1, 1000));
  EXPECT(mpv::LuminanceInMasteringRange(1000, 1, 1000));
  EXPECT(!mpv::LuminanceInMasteringRange(1001, 1, 1000));
  // min L = 5 nits: 5 is not strictly greater, 6 is.
  EXPECT(!mpv::LuminanceInMasteringRange(5, 50000, 1000));
  EXPECT(mpv::LuminanceInMasteringRange(6, 50000, 1000));
  // An absurd value is rejected by the max bound, before the scaled multiply.
  EXPECT(!mpv::LuminanceInMasteringRange(4000000000u, 1, 1000));
}

// The mastering floor is a bound in its own right: on version 1 a light level at
// or below min L is invalid_luminance just as surely as one above max L. This
// drives it through PlanHdrLuminance rather than the predicate alone, so it
// covers the wiring of mastering_min_scaled into the range test.
void TestLightLevelsBelowTheMasteringFloorAreDropped() {
  const auto plan = mpv::PlanHdrLuminance(Metadata(3, 2, 1000, 5.0), Support(true, 1));
  EXPECT(plan.send_mastering);
  EXPECT(plan.mastering_min_scaled == 50000);
  EXPECT(!plan.send_max_cll);
  EXPECT(!plan.send_max_fall);
}

// HLG's primary colour volume tops out at 1000 nits, not PQ's 10000. A 4000-nit
// MaxCLL with no mastering range is inside PQ's volume but outside HLG's, and on
// version 1 that is a fatal invalid_luminance, so it must be dropped.
void TestHlgLightLevelsBoundedAtThousand() {
  const auto hlg = mpv::PlanHdrLuminance(Metadata(4000, 400, 0, 0.0, mpv::SourceTransfer::kHlg), Support(false, 1));
  EXPECT(!hlg.send_mastering);
  EXPECT(!hlg.send_max_cll);
  EXPECT(hlg.send_max_fall);
  EXPECT(hlg.max_fall == 400);

  // The identical numbers are legal under PQ, which is the whole point.
  const auto pq = mpv::PlanHdrLuminance(Metadata(4000, 400, 0, 0.0, mpv::SourceTransfer::kPq), Support(false, 1));
  EXPECT(pq.send_max_cll);
  EXPECT(pq.max_cll == 4000);
}

// Both interface versions must agree about the same stream. extended_target_volume
// lets the mastering range reach 10000 even for HLG, so a version-1 range check
// alone would accept a 2000-nit HLG light level that version 2 refuses — the
// curve's own volume bound has to apply regardless of version.
void TestVolumeCapIsVersionIndependent() {
  const auto metadata = Metadata(2000, 1500, 4000, 0.01, mpv::SourceTransfer::kHlg);
  const auto v1 = mpv::PlanHdrLuminance(metadata, Support(true, 1, true));
  const auto v2 = mpv::PlanHdrLuminance(metadata, Support(true, 2, true));
  EXPECT(!v1.send_max_cll);
  EXPECT(!v2.send_max_cll);
  EXPECT(v1.send_max_cll == v2.send_max_cll);
  EXPECT(v1.send_max_fall == v2.send_max_fall);
}

// Exactly 1000 is inside HLG's volume; 1001 is not.
void TestHlgVolumeBoundary() {
  const auto inside = mpv::PlanHdrLuminance(Metadata(1000, 0, 0, 0.0, mpv::SourceTransfer::kHlg), Support(false, 1));
  EXPECT(inside.send_max_cll);
  const auto outside = mpv::PlanHdrLuminance(Metadata(1001, 0, 0, 0.0, mpv::SourceTransfer::kHlg), Support(false, 1));
  EXPECT(!outside.send_max_cll);
  EXPECT(mpv::PrimaryVolumeMaxNits(mpv::SourceTransfer::kHlg) == 1000);
  EXPECT(mpv::PrimaryVolumeMaxNits(mpv::SourceTransfer::kPq) == 10000);
}

// An HLG mastering display brighter than 1000 nits exceeds the primary colour
// volume, which needs extended_target_volume. Without it the value is clamped
// down rather than sent as-is.
void TestHlgMasteringClampedWithoutExtendedVolume() {
  const auto clamped = mpv::PlanHdrLuminance(Metadata(0, 0, 4000, 0.005, mpv::SourceTransfer::kHlg), Support(true, 1));
  EXPECT(clamped.send_mastering);
  EXPECT(clamped.mastering_max == mpv::kHlgMaxLuminanceNits);

  // With the feature advertised the source's own figure is honoured.
  const auto extended =
      mpv::PlanHdrLuminance(Metadata(0, 0, 4000, 0.005, mpv::SourceTransfer::kHlg), Support(true, 1, true));
  EXPECT(extended.send_mastering);
  EXPECT(extended.mastering_max == 4000);
}

// PQ mastering is never clamped by the extended-volume gate, because 10000 is
// already its primary colour volume maximum.
void TestPqMasteringUnaffectedByExtendedVolumeGate() {
  const auto plan = mpv::PlanHdrLuminance(Metadata(0, 0, 10000, 0.0001), Support(true, 1));
  EXPECT(plan.send_mastering);
  EXPECT(plan.mastering_max == 10000);
}

// Player-side tone mapping: the description must claim the peak we produced, not
// the source's original range, or the compositor compresses levels that are no
// longer present.
void TestDescribeTonemappedTo() {
  const auto source = Metadata(10000, 600, 10000, 0.0001);
  const auto described = mpv::DescribeTonemappedTo(source, 600);
  EXPECT(described.transfer == mpv::SourceTransfer::kPq);
  EXPECT(described.primaries == mpv::SourcePrimaries::kBt2020);
  EXPECT(described.max_cll == 600);
  EXPECT(described.max_luminance == 600);
  // The source's 600-nit MaxFALL still fits, so it survives.
  EXPECT(described.max_fall == 600);
  // The floor is untouched.
  EXPECT(described.min_luminance == source.min_luminance);

  // A MaxFALL above the produced peak would violate max_fall <= max_cll, so it
  // is dropped rather than clamped to a figure we never measured.
  const auto dropped = mpv::DescribeTonemappedTo(Metadata(10000, 900, 10000, 0.0001), 600);
  EXPECT(dropped.max_fall == 0);

  // Zero peak means "not known"; nothing is rewritten.
  const auto untouched = mpv::DescribeTonemappedTo(source, 0);
  EXPECT(untouched.max_cll == 10000);

  // HLG is clamped to its own volume, not PQ's.
  const auto hlg = mpv::DescribeTonemappedTo(Metadata(0, 0, 0, 0.005, mpv::SourceTransfer::kHlg), 4000);
  EXPECT(hlg.max_cll == mpv::kHlgMaxLuminanceNits);
}

// The whole reason the rewrite exists: what it produces must itself survive the
// planner, on version 1, with no mastering support.
void TestTonemappedDescriptionIsSendable() {
  const auto described = mpv::DescribeTonemappedTo(Metadata(10000, 600, 10000, 0.0001), 600);
  const auto plan = mpv::PlanHdrLuminance(described, Support(true, 1));
  EXPECT(plan.send_mastering);
  EXPECT(plan.mastering_max == 600);
  EXPECT(plan.send_max_cll);
  EXPECT(plan.max_cll == 600);
  EXPECT(plan.send_max_fall);
  EXPECT(plan.max_fall == 600);
}

// Containment is two-sided. A 0.0001-nit mastering floor is below the primary
// colour volume's 0.005, so without extended_target_volume it is clamped up
// rather than sent as-is — and the maximum, which is the compositor's fallback
// peak, is preserved instead of dropping the whole request.
void TestMasteringFloorClampedIntoPrimaryVolume() {
  const auto plan = mpv::PlanHdrLuminance(Metadata(0, 0, 1000, 0.0001), Support(true, 1));
  EXPECT(plan.send_mastering);
  EXPECT(plan.mastering_min_scaled == mpv::kPrimaryVolumeMinScaled);
  EXPECT(plan.mastering_max == 1000);

  // An absent floor reads as zero and is clamped the same way.
  const auto absent = mpv::PlanHdrLuminance(Metadata(0, 0, 1000, 0.0), Support(true, 1));
  EXPECT(absent.send_mastering);
  EXPECT(absent.mastering_min_scaled == mpv::kPrimaryVolumeMinScaled);

  // With extended_target_volume the source's true floor goes out untouched.
  const auto extended = mpv::PlanHdrLuminance(Metadata(0, 0, 1000, 0.0001), Support(true, 1, true));
  EXPECT(extended.send_mastering);
  EXPECT(extended.mastering_min_scaled == 1);
}

// A floor already inside the volume is left exactly as the source stated it.
void TestMasteringFloorInsideVolumeIsUntouched() {
  const auto plan = mpv::PlanHdrLuminance(Metadata(0, 0, 1000, 0.05), Support(true, 1));
  EXPECT(plan.send_mastering);
  EXPECT(plan.mastering_min_scaled == 500);
}

// Both HDR curves, so every peak-clamping case is exercised against each.
const mpv::SourceTransfer kHdrTransfers[] = {mpv::SourceTransfer::kPq, mpv::SourceTransfer::kHlg};

// Every gate passing, in compositor mode with no peak or reference reported.
// Each case starts here and mutates only the field it is about.
mpv::HdrInputs AllGatesPass() {
  mpv::HdrInputs inputs;
  inputs.allowed = true;
  inputs.client_can_describe = true;
  inputs.output_is_hdr = true;
  inputs.source_describable = true;
  return inputs;
}

// Each of the four gates must be able to veto on its own, and an SDR source
// vetoes regardless of the rest.
void TestEachGateCanVeto() {
  const auto pq = Metadata(1000, 400, 1000, 0.0001);
  EXPECT(mpv::DecideHdr(AllGatesPass(), pq).describe);

  auto not_allowed = AllGatesPass();
  not_allowed.allowed = false;
  EXPECT(!mpv::DecideHdr(not_allowed, pq).describe);

  auto client_cannot_describe = AllGatesPass();
  client_cannot_describe.client_can_describe = false;
  EXPECT(!mpv::DecideHdr(client_cannot_describe, pq).describe);

  auto output_is_sdr = AllGatesPass();
  output_is_sdr.output_is_hdr = false;
  EXPECT(!mpv::DecideHdr(output_is_sdr, pq).describe);

  auto source_not_describable = AllGatesPass();
  source_not_describable.source_describable = false;
  EXPECT(!mpv::DecideHdr(source_not_describable, pq).describe);

  const auto sdr = Metadata(0, 0, 0, 0.0, mpv::SourceTransfer::kSdr);
  EXPECT(!mpv::DecideHdr(AllGatesPass(), sdr).describe);
}

// Compositor mode never sets a target peak, whatever the display reports.
void TestCompositorModeLeavesPeakAuto() {
  auto inputs = AllGatesPass();
  inputs.display_peak_nits = 600;
  const auto decision = mpv::DecideHdr(inputs, Metadata(10000, 600, 10000, 0.0001));
  EXPECT(decision.describe);
  EXPECT(!decision.tone_map_in_player);
  EXPECT(decision.target_peak_nits == 0);
}

void TestPlayerModeAdoptsDisplayPeak() {
  auto inputs = AllGatesPass();
  inputs.requested = mpv::HdrToneMapping::kPlayer;
  inputs.display_peak_nits = 600;
  const auto decision = mpv::DecideHdr(inputs, Metadata(10000, 600, 10000, 0.0001));
  EXPECT(decision.describe);
  EXPECT(decision.tone_map_in_player);
  EXPECT(decision.target_peak_nits == 600);
}

// An HDR source on an SDR output is the fallback path, and mpv still has to be
// told what it is mapping to. Left on auto with no window it does not tone-map at
// all, so the peak has to come from the output's diffuse white - not from the
// HDR-mode peak, which an SDR signal cannot reach.
void TestUndescribedHdrSourceAdoptsSdrReference() {
  for (const mpv::SourceTransfer transfer : kHdrTransfers) {
    const auto source = Metadata(1000, 400, 1000, 0.0001, transfer);
    auto inputs = AllGatesPass();
    // The one gate that puts us on this path on an SDR panel.
    inputs.output_is_hdr = false;
    inputs.display_peak_nits = 600;
    inputs.sdr_reference_nits = 200;
    const auto decision = mpv::DecideHdr(inputs, source);
    EXPECT(!decision.describe);
    // mpv reduces the range here, so the flag says so; `describe` is what keeps
    // metadata off the surface.
    EXPECT(decision.tone_map_in_player);
    EXPECT(decision.target_peak_nits == 200);

    // Player mode changes nothing on this path: the undescribed branch never
    // reads `requested` and never reads the HDR-mode peak, so the 600-nit peak
    // does not displace the 200-nit reference.
    auto player = inputs;
    player.requested = mpv::HdrToneMapping::kPlayer;
    const auto player_decision = mpv::DecideHdr(player, source);
    EXPECT(!player_decision.describe);
    EXPECT(player_decision.tone_map_in_player);
    EXPECT(player_decision.target_peak_nits == 200);
  }
}

// Without a reference white there is nothing to aim at, and inventing one would
// be worse than mpv's own default.
void TestUndescribedWithoutSdrReferenceStaysAuto() {
  const auto source = Metadata(1000, 400, 1000, 0.0001);
  auto inputs = AllGatesPass();
  inputs.output_is_hdr = false;
  inputs.display_peak_nits = 600;
  EXPECT(mpv::DecideHdr(inputs, source).target_peak_nits == 0);
  // Below the option's floor is the same as unknown.
  inputs.sdr_reference_nits = 9;
  EXPECT(mpv::DecideHdr(inputs, source).target_peak_nits == 0);
  inputs.sdr_reference_nits = 10;
  EXPECT(mpv::DecideHdr(inputs, source).target_peak_nits == 10);
}

// The regression this guard exists for: an ordinary BT.709 file has nothing to
// map down, so naming a peak would change plain SDR playback.
void TestUndescribedSdrSourceKeepsPeakAuto() {
  const auto sdr = Metadata(0, 0, 0, 0.0, mpv::SourceTransfer::kSdr);
  auto inputs = AllGatesPass();
  inputs.output_is_hdr = false;
  inputs.display_peak_nits = 600;
  inputs.sdr_reference_nits = 200;
  const auto decision = mpv::DecideHdr(inputs, sdr);
  EXPECT(!decision.describe);
  EXPECT(decision.target_peak_nits == 0);
  // Also true when every other gate would have passed.
  auto every_gate = AllGatesPass();
  every_gate.requested = mpv::HdrToneMapping::kPlayer;
  every_gate.display_peak_nits = 600;
  every_gate.sdr_reference_nits = 200;
  EXPECT(mpv::DecideHdr(every_gate, sdr).target_peak_nits == 0);
}

// On an HDR output the described peak still comes from the HDR-mode peak; the SDR
// reference must not displace it.
void TestDescribedPlayerModeIgnoresSdrReference() {
  const auto source = Metadata(10000, 600, 10000, 0.0001);
  auto inputs = AllGatesPass();
  inputs.requested = mpv::HdrToneMapping::kPlayer;
  inputs.display_peak_nits = 600;
  inputs.sdr_reference_nits = 200;
  const auto decision = mpv::DecideHdr(inputs, source);
  EXPECT(decision.describe);
  EXPECT(decision.tone_map_in_player);
  EXPECT(decision.target_peak_nits == 600);
}

// Without a usable peak there is nothing to aim at, so player mode degrades to
// passthrough rather than inventing a target.
void TestPlayerModeWithoutPeakFallsBack() {
  auto inputs = AllGatesPass();
  inputs.requested = mpv::HdrToneMapping::kPlayer;
  const auto absent = mpv::DecideHdr(inputs, Metadata(10000, 600, 10000, 0.0001));
  EXPECT(absent.describe);
  EXPECT(!absent.tone_map_in_player);
  EXPECT(absent.target_peak_nits == 0);
  // mpv's target-peak option starts at 10.
  inputs.display_peak_nits = 5;
  const auto tiny = mpv::DecideHdr(inputs, Metadata(10000, 600, 10000, 0.0001));
  EXPECT(!tiny.tone_map_in_player);
}

// The invariant that keeps mpv's target equal to the declared peak: whatever
// DecideHdr returns must survive DescribeTonemappedTo unchanged.
void TestDecidedPeakMatchesDescribedPeak() {
  const uint32_t reported[] = {600, 1000, 1500, 4000, 12000};
  for (const uint32_t peak : reported) {
    for (const mpv::SourceTransfer transfer : kHdrTransfers) {
      const auto source = Metadata(0, 0, 0, 0.0001, transfer);
      auto inputs = AllGatesPass();
      inputs.requested = mpv::HdrToneMapping::kPlayer;
      inputs.display_peak_nits = peak;
      const auto decision = mpv::DecideHdr(inputs, source);
      EXPECT(decision.tone_map_in_player);
      EXPECT(decision.target_peak_nits <= mpv::PrimaryVolumeMaxNits(transfer));
      const auto described = mpv::DescribeTonemappedTo(source, decision.target_peak_nits);
      EXPECT(described.max_luminance == decision.target_peak_nits);
      EXPECT(described.max_cll == decision.target_peak_nits);
    }
  }
  // HLG specifically: a 1500-nit panel still yields 1000.
  auto hlg_inputs = AllGatesPass();
  hlg_inputs.requested = mpv::HdrToneMapping::kPlayer;
  hlg_inputs.display_peak_nits = 1500;
  const auto hlg = mpv::DecideHdr(hlg_inputs, Metadata(0, 0, 0, 0.0001, mpv::SourceTransfer::kHlg));
  EXPECT(hlg.target_peak_nits == mpv::kHlgMaxLuminanceNits);
}

// And the decided peak, once described, must still be legal to send.
void TestDecidedPeakIsSendable() {
  for (const mpv::SourceTransfer transfer : kHdrTransfers) {
    const auto source = Metadata(4000, 2000, 4000, 0.0001, transfer);
    auto inputs = AllGatesPass();
    inputs.requested = mpv::HdrToneMapping::kPlayer;
    inputs.display_peak_nits = 700;
    const auto decision = mpv::DecideHdr(inputs, source);
    const auto plan =
        mpv::PlanHdrLuminance(mpv::DescribeTonemappedTo(source, decision.target_peak_nits), Support(true, 1));
    EXPECT(plan.send_max_cll);
    EXPECT(plan.max_cll == decision.target_peak_nits);
    EXPECT(plan.send_mastering);
    EXPECT(plan.mastering_max == decision.target_peak_nits);
    EXPECT(!plan.send_max_fall || plan.max_fall <= plan.max_cll);
  }
}

// The numbers here are what KWin actually reports, because the risk this guards
// against is a plausible-looking rule that mistakes one state for another.
void TestHdrOutputsAreRecognisedByHeadroom() {
  // A 400-nit HDR panel over 203-nit reference white, measured on hardware.
  EXPECT(mpv::OutputHasHdrHeadroom(400, 203));
  // KWin's own default HDR peak when the EDID declares none.
  EXPECT(mpv::OutputHasHdrHeadroom(800, 200));
  // An HDR output whose reference white was raised by the brightness slider
  // still clears the margin.
  EXPECT(mpv::OutputHasHdrHeadroom(465, 208));
}

void TestSdrOutputsAreRejectedEvenWhenDimmed() {
  // Undimmed SDR: the compositor reports its reference white as the maximum.
  EXPECT(!mpv::OutputHasHdrHeadroom(200, 200));
  // Dimmed SDR is the trap. KWin scales reference white in software and keeps
  // reporting the undimmed maximum, so a bare `max > reference` reads as HDR
  // on an output that is not: at 80% brightness reference white is
  // 5 + (200 - 5) * 0.8 = 161.
  EXPECT(!mpv::OutputHasHdrHeadroom(200, 161));
  // The same at 70%, which is 1.46x and still under the margin.
  EXPECT(!mpv::OutputHasHdrHeadroom(200, 137));
}

void TestUnknownLuminancesAreNotHdr() {
  // Nothing reported at all, and a maximum without a reference to measure it
  // against: neither is evidence of headroom.
  EXPECT(!mpv::OutputHasHdrHeadroom(0, 0));
  EXPECT(!mpv::OutputHasHdrHeadroom(800, 0));
  // A reference white above the maximum is incoherent, not headroom.
  EXPECT(!mpv::OutputHasHdrHeadroom(100, 203));
}

// The margin is exactly 1.5x, so both sides of it are worth pinning: truncating
// integer arithmetic would put the boundary half a nit low and let a 304-nit
// peak over 203-nit white read as headroom.
void TestHeadroomBoundaryIsExact() {
  EXPECT(!mpv::OutputHasHdrHeadroom(304, 203));  // 1.4975x - just under
  EXPECT(mpv::OutputHasHdrHeadroom(305, 203));   // 1.5025x - just over
  EXPECT(mpv::OutputHasHdrHeadroom(300, 200));   // exactly 1.5x counts
  EXPECT(!mpv::OutputHasHdrHeadroom(299, 200));
  // Small values must not round their way into headroom either.
  EXPECT(!mpv::OutputHasHdrHeadroom(1, 1));
  EXPECT(!mpv::OutputHasHdrHeadroom(2, 2));
}

// Naming a curve the compositor never advertised is a *fatal* invalid_tf on
// create(), which disconnects the client. So each arm is pinned separately: a
// swap between the two, or one standing in for the other, would otherwise pass.
void TestOnlyAdvertisedCurvesAreDescribable() {
  const mpv::CompositorColorSupport pq_only{true, true, false};
  const mpv::CompositorColorSupport hlg_only{true, false, true};
  const mpv::CompositorColorSupport both{true, true, true};

  auto pq = Metadata(1000, 400, 1000, 0.005);
  pq.transfer = mpv::SourceTransfer::kPq;
  pq.primaries = mpv::SourcePrimaries::kBt2020;
  auto hlg = pq;
  hlg.transfer = mpv::SourceTransfer::kHlg;

  EXPECT(mpv::SourceIsDescribable(pq, pq_only));
  EXPECT(!mpv::SourceIsDescribable(hlg, pq_only));
  EXPECT(mpv::SourceIsDescribable(hlg, hlg_only));
  EXPECT(!mpv::SourceIsDescribable(pq, hlg_only));
  EXPECT(mpv::SourceIsDescribable(pq, both));
  EXPECT(mpv::SourceIsDescribable(hlg, both));
}

void TestSdrAndNarrowGamutSourcesAreNotDescribable() {
  const mpv::CompositorColorSupport all{true, true, true};

  // An SDR source has nothing to describe, whatever the compositor accepts.
  auto sdr = Metadata(0, 0, 0, 0.0);
  sdr.transfer = mpv::SourceTransfer::kSdr;
  sdr.primaries = mpv::SourcePrimaries::kBt2020;
  EXPECT(!mpv::SourceIsDescribable(sdr, all));

  // An HDR curve in a non-BT.2020 container is not worth the switch, and the
  // container primaries would be a claim we cannot make.
  auto narrow = Metadata(1000, 400, 1000, 0.005);
  narrow.transfer = mpv::SourceTransfer::kPq;
  narrow.primaries = mpv::SourcePrimaries::kOther;
  EXPECT(!mpv::SourceIsDescribable(narrow, all));

  // And a compositor that never advertised BT.2020 cannot be told about it,
  // however describable the curve is.
  auto pq = Metadata(1000, 400, 1000, 0.005);
  pq.transfer = mpv::SourceTransfer::kPq;
  pq.primaries = mpv::SourcePrimaries::kBt2020;
  EXPECT(!mpv::SourceIsDescribable(pq, mpv::CompositorColorSupport{false, true, true}));
}

// These arrive unvalidated from the compositor, so the comparison has to hold
// at the top of the range rather than wrapping into the wrong answer.
void TestHeadroomSurvivesExtremeLuminances() {
  const uint32_t huge = 0xFFFFFFFFu;
  EXPECT(!mpv::OutputHasHdrHeadroom(huge, huge));
  EXPECT(mpv::OutputHasHdrHeadroom(huge, 1));
  // A reference white so large that reference + reference/2 would overflow:
  // the answer is still "no headroom", not an accidental yes.
  EXPECT(!mpv::OutputHasHdrHeadroom(1000, huge));
}

}  // namespace

int main() {
  TestWellFormedMetadataSurvives();
  TestMaxCllAtPqCeilingIsKept();
  TestMaxCllAboveMasteringMaxIsDroppedOnV1();
  TestMaxCllAboveMasteringMaxIsKeptOnV2();
  TestMaxFallAboveMasteringMaxIsDroppedOnV1();
  TestMaxFallAboveMaxCllIsDropped();
  TestMaxFallSurvivesWhenMaxCllIsDropped();
  TestMasteringSuppressedWithoutCompositorSupport();
  TestInvertedMasteringRangeIsSuppressed();
  TestEqualMasteringRangeIsSuppressed();
  TestMasteringMaxIsCappedAtPqCeiling();
  TestLightLevelsAbovePqCeilingAreDropped();
  TestEmptyMetadataSendsNothing();
  TestMinLuminanceScaling();
  TestRangePredicateBoundaries();
  TestLightLevelsBelowTheMasteringFloorAreDropped();
  TestHlgLightLevelsBoundedAtThousand();
  TestHlgVolumeBoundary();
  TestVolumeCapIsVersionIndependent();
  TestHlgMasteringClampedWithoutExtendedVolume();
  TestPqMasteringUnaffectedByExtendedVolumeGate();
  TestDescribeTonemappedTo();
  TestTonemappedDescriptionIsSendable();
  TestMasteringFloorClampedIntoPrimaryVolume();
  TestMasteringFloorInsideVolumeIsUntouched();
  TestEachGateCanVeto();
  TestCompositorModeLeavesPeakAuto();
  TestPlayerModeAdoptsDisplayPeak();
  TestUndescribedHdrSourceAdoptsSdrReference();
  TestUndescribedWithoutSdrReferenceStaysAuto();
  TestUndescribedSdrSourceKeepsPeakAuto();
  TestDescribedPlayerModeIgnoresSdrReference();
  TestPlayerModeWithoutPeakFallsBack();
  TestDecidedPeakMatchesDescribedPeak();
  TestDecidedPeakIsSendable();
  TestHdrOutputsAreRecognisedByHeadroom();
  TestSdrOutputsAreRejectedEvenWhenDimmed();
  TestUnknownLuminancesAreNotHdr();
  TestHeadroomBoundaryIsExact();
  TestHeadroomSurvivesExtremeLuminances();
  TestOnlyAdvertisedCurvesAreDescribable();
  TestSdrAndNarrowGamutSourcesAreNotDescribable();
  return failures == 0 ? 0 : 1;
}
