#ifndef PLEZY_LINUX_MPV_HDR_METADATA_H_
#define PLEZY_LINUX_MPV_HDR_METADATA_H_

#include <cstdint>

// Source HDR10 static metadata, and the rules for turning it into a set of
// colour-management-v1 luminance requests the compositor will accept.
//
// This header is deliberately free of Wayland and GTK: the interesting logic is
// the validation, the penalty for getting it wrong is severe, and neither
// deserves a display server to test. Header-only is deliberate as well: pure
// functions over plain structs, no dependencies, every one of them inline, and
// five translation units include it.

namespace mpv {

// The source's transfer function, so far as describing the plane cares. Every
// SDR curve collapses to kSdr: the plane is then left undescribed and mpv's
// normal output is already right, so there is nothing to distinguish.
enum class SourceTransfer { kSdr, kPq, kHlg };

// The source's container primaries. Only BT.2020 has a named counterpart worth
// describing for video; everything else is treated as "not a wide gamut" and
// leaves the plane undescribed.
enum class SourcePrimaries { kOther, kBt2020 };

// What the current source actually is, plus its HDR10 static metadata, as
// reported by mpv's video-params. A zero luminance field means the source did
// not carry it.
//
// The colorimetry fields matter as much as the luminances: describing a plane as
// PQ / BT.2020 because a *setting* is on, rather than because the stream is,
// tells the compositor to undo a transform that was never applied.
struct HdrMetadata {
  SourceTransfer transfer = SourceTransfer::kSdr;
  SourcePrimaries primaries = SourcePrimaries::kOther;
  uint32_t max_cll = 0;        // nits, maximum content light level
  uint32_t max_fall = 0;       // nits, maximum frame-average light level
  uint32_t max_luminance = 0;  // nits, mastering display maximum
  double min_luminance = 0.0;  // nits, mastering display minimum
};

// Whether two snapshots describe the same source. Both the plane's
// no-op-transition check and the plugin's log-on-change need this, and they must
// agree on what "the same" means or one will act on a change the other ignored.
inline bool operator==(const HdrMetadata& a, const HdrMetadata& b) {
  return a.transfer == b.transfer && a.primaries == b.primaries && a.max_cll == b.max_cll && a.max_fall == b.max_fall &&
         a.max_luminance == b.max_luminance && a.min_luminance == b.min_luminance;
}

inline bool operator!=(const HdrMetadata& a, const HdrMetadata& b) { return !(a == b); }

// True when the source carries an HDR transfer function, i.e. when there is
// anything to pass through at all.
inline bool SourceIsHdr(const HdrMetadata& metadata) { return metadata.transfer != SourceTransfer::kSdr; }

// Who reduces the source's dynamic range to what the display can show.
//
// kCompositor is passthrough: the source's own metadata is declared and the
// compositor's tone curve does the work. Simplest, adapts to monitor changes
// with no re-render, and is what Kodi does — but its quality is entirely the
// compositor's, and a source that declares no metadata is assumed to reach the
// curve's maximum, which makes the roll-off far harsher than the content needs.
//
// kPlayer tone-maps in mpv to the display's real peak (learned from the
// compositor's preferred description) and then declares *that* peak, leaving the
// compositor an identity transform. This is mpv's own default behaviour and what
// the compositor developers recommend.
enum class HdrToneMapping { kCompositor, kPlayer };

// The primary colour volume maxima the protocol attaches to each named transfer
// function. These are not interchangeable: PQ's EOTF swings to 10000 cd/m²,
// while HLG is a *relative* signal whose absolute luminances are all defined
// against a 1000 cd/m² peak display. Getting this wrong is not cosmetic — an
// HLG stream declaring a 4000-nit MaxCLL with no mastering range passes a
// PQ-shaped check and then trips a fatal invalid_luminance at create().
constexpr uint32_t kPqMaxLuminanceNits = 10000;
constexpr uint32_t kHlgMaxLuminanceNits = 1000;

// The protocol carries the mastering minimum scaled by this to keep four
// decimals of a value that is normally a small fraction of a nit.
constexpr uint32_t kMinLuminanceScale = 10000;

// Both PQ and HLG declare the same primary colour volume *floor*, 0.005 cd/m²,
// already in the protocol's scaled units. Containment is two-sided: a mastering
// range reaching below this leaves the primary colour volume just as surely as
// one reaching above its maximum, and needs the same extended_target_volume
// feature. Sources routinely declare 0.0001 or nothing at all, so this is the
// common case rather than the exotic one.
constexpr uint32_t kPrimaryVolumeMinScaled = 50;

// The implied primary colour volume maximum for a transfer function. This is
// also the range light levels are bounded by when no mastering luminance is
// sent, because the protocol says an unset mastering range takes the primary
// colour volume's own range.
inline uint32_t PrimaryVolumeMaxNits(SourceTransfer transfer) {
  switch (transfer) {
    case SourceTransfer::kHlg:
      return kHlgMaxLuminanceNits;
    case SourceTransfer::kPq:
    case SourceTransfer::kSdr:
      break;
  }
  return kPqMaxLuminanceNits;
}

// What the compositor told us it can accept, which decides how much of the
// source's metadata may legally be forwarded.
struct CompositorLuminanceSupport {
  // feature.set_mastering_display_primaries. Without it, set_mastering_luminance
  // raises unsupported_feature.
  bool mastering = false;
  // feature.extended_target_volume. Without it, the mastering advertisement
  // only promises target volumes *fully contained* within the primary colour
  // volume; exceeding it is implementation-defined and may fail the description.
  bool extended_target_volume = false;
  // Bound wp_color_manager_v1 version. What the versions differ about is spelled
  // out at the branch that acts on it, in PlanHdrLuminance.
  uint32_t interface_version = 1;
};

// Which luminance requests to actually emit. A false flag means the field is
// left unset so the compositor applies its own default, which is always safer
// than a value the protocol would reject.
struct HdrLuminancePlan {
  bool send_mastering = false;
  uint32_t mastering_min_scaled = 0;
  uint32_t mastering_max = 0;
  bool send_max_cll = false;
  uint32_t max_cll = 0;
  bool send_max_fall = false;
  uint32_t max_fall = 0;
};

// Converts a mastering minimum in nits to the protocol's scaled units.
inline uint32_t ScaleMinLuminance(double nits) {
  if (!(nits > 0.0)) return 0;
  const double scaled = nits * static_cast<double>(kMinLuminanceScale) + 0.5;
  if (scaled >= static_cast<double>(UINT32_MAX)) return UINT32_MAX;
  return static_cast<uint32_t>(scaled);
}

// True when `value_nits` sits inside the mastering range, which version 1
// spells as strictly greater than min L and less than or equal to max L. The
// comparison against the minimum happens in scaled units and in 64 bits, since
// a corrupt max-luma would otherwise overflow the multiply.
inline bool LuminanceInMasteringRange(uint32_t value_nits, uint32_t min_lum_scaled, uint32_t max_lum_nits) {
  if (value_nits > max_lum_nits) return false;
  return static_cast<uint64_t>(value_nits) * kMinLuminanceScale > min_lum_scaled;
}

// Decides which of set_mastering_luminance / set_max_cll / set_max_fall may be
// sent for `metadata`, given what the compositor advertised.
//
// Every constraint enforced here is a *protocol error* on create(), not a
// failed image description: the compositor disconnects the client, taking the
// whole app down rather than just HDR. Badly authored HDR content does violate
// these — a MaxCLL above the mastering display's own peak is common, and MaxFALL
// above MaxCLL happens — so the stream is never trusted.
inline HdrLuminancePlan PlanHdrLuminance(const HdrMetadata& metadata, const CompositorLuminanceSupport& support) {
  HdrLuminancePlan plan;

  // The ceiling everything is judged against.
  const uint32_t volume_max = PrimaryVolumeMaxNits(metadata.transfer);

  // Mastering luminance carries two error cases: unsupported_feature unless the
  // compositor advertised set_mastering_display_primaries, and invalid_luminance
  // unless max L is strictly greater than min L.
  //
  // Beyond those, the mastering advertisement only promises target volumes
  // *fully contained* within the primary colour volume, and containment is
  // two-sided. Both ends are therefore clamped into it unless
  // extended_target_volume was advertised:
  //
  //  - The maximum down to the curve's own ceiling. For HLG that is also
  //    semantically right, since its absolute luminances are defined against a
  //    1000-nit display and a larger figure is outside the model. The clamp
  //    doubles as overflow protection for the scaled comparison below.
  //  - The minimum up to the 0.005-nit floor. Sources overwhelmingly declare
  //    0.0001 or nothing at all, both of which sit below it.
  //
  // Clamping rather than dropping matters: the mastering maximum is the
  // compositor's fallback peak when the source carries no MaxCLL, and dropping
  // it there would leave the compositor assuming the curve's full range —
  // exactly the over-compression this whole exercise is about avoiding.
  const uint32_t mastering_ceiling = support.extended_target_volume ? kPqMaxLuminanceNits : volume_max;
  const uint32_t mastering_floor_scaled = support.extended_target_volume ? 0 : kPrimaryVolumeMinScaled;
  uint32_t mastering_max = metadata.max_luminance;
  if (mastering_max > mastering_ceiling) mastering_max = mastering_ceiling;
  uint32_t mastering_min_scaled = ScaleMinLuminance(metadata.min_luminance);
  if (mastering_min_scaled < mastering_floor_scaled) mastering_min_scaled = mastering_floor_scaled;
  if (support.mastering && mastering_max > 0 &&
      static_cast<uint64_t>(mastering_max) * kMinLuminanceScale > mastering_min_scaled) {
    plan.send_mastering = true;
    plan.mastering_min_scaled = mastering_min_scaled;
    plan.mastering_max = mastering_max;
  }

  plan.send_max_cll = metadata.max_cll > 0;
  plan.max_cll = metadata.max_cll;
  plan.send_max_fall = metadata.max_fall > 0;
  plan.max_fall = metadata.max_fall;

  // The range both light levels must sit inside. With no mastering request the
  // primary colour volume applies, which is why volume_max is used and not PQ's
  // ceiling: an HLG stream is bounded at 1000 either way.
  const uint32_t range_max = plan.send_mastering ? plan.mastering_max : volume_max;
  const uint32_t range_min_scaled = plan.send_mastering ? plan.mastering_min_scaled : 0;

  // The curve has no code point above its own volume maximum, which is true of
  // both interface versions: with extended_target_volume the mastering range may
  // legally reach 10000 even for HLG, so range_max alone would let a v1
  // compositor accept an HLG light level of 2000 that a v2 one refuses. Drop the
  // offending light level rather than the mastering range: mastering metadata is
  // the more trustworthy of the two, and dropping max_cll leaves the compositor
  // falling back to the mastering maximum, which is the better answer anyway.
  if (plan.send_max_cll && plan.max_cll > volume_max) plan.send_max_cll = false;
  if (plan.send_max_fall && plan.max_fall > volume_max) plan.send_max_fall = false;

  // Version 1 additionally requires both to sit inside the mastering range;
  // version 2 dropped that.
  if (support.interface_version < 2) {
    if (plan.send_max_cll && !LuminanceInMasteringRange(plan.max_cll, range_min_scaled, range_max)) {
      plan.send_max_cll = false;
    }
    if (plan.send_max_fall && !LuminanceInMasteringRange(plan.max_fall, range_min_scaled, range_max)) {
      plan.send_max_fall = false;
    }
  }

  // Every version requires max_fall <= max_cll, but only while *both* are set,
  // so this has to be judged after the drops above. max_fall is the one to go:
  // it is the less trustworthy field and no compositor tone curve consults it.
  if (plan.send_max_cll && plan.send_max_fall && plan.max_fall > plan.max_cll) {
    plan.send_max_fall = false;
  }
  return plan;
}

// Rewrites the metadata to describe a signal *we* tone-mapped to `peak_nits`,
// rather than the source's original range.
//
// This is the whole point of player-side tone mapping: once mpv has mapped the
// content down to the display's peak, telling the compositor the source's
// original 4000- or 10000-nit range would have it compress a signal that no
// longer contains those levels. The curve and gamut are unchanged — the pixels
// are still PQ or HLG over BT.2020 — but every luminance now describes what we
// produced. The mastering floor is kept: it did not move.
inline HdrMetadata DescribeTonemappedTo(const HdrMetadata& source, uint32_t peak_nits) {
  HdrMetadata described = source;
  if (peak_nits == 0) return described;
  const uint32_t volume_max = PrimaryVolumeMaxNits(source.transfer);
  if (peak_nits > volume_max) peak_nits = volume_max;
  described.max_luminance = peak_nits;
  described.max_cll = peak_nits;
  // MaxFALL must stay at or below MaxCLL, and a frame average equal to the peak
  // would be a claim about the content we have not measured. The source's own
  // figure is kept when it still fits, since it remains the better estimate.
  described.max_fall = (source.max_fall > 0 && source.max_fall <= peak_nits) ? source.max_fall : 0;
  return described;
}

// Whether an output's reported luminances leave enough room above its own
// diffuse white to be worth passing HDR through instead of tone-mapping here.
//
// This is deliberately a headroom question rather than "is the HDR toggle on",
// because no colour-management-v1 signal answers the latter. The transfer
// function used to: KWin 6.4 preferred PQ for an HDR output. KWin 6.7 does not
// — a window's preferred description became the compositor's *blending* space,
// which is gamma 2.2 with an extended range whether or not HDR is on, and the
// output-scoped description followed it. Reading the curve there now reports
// SDR on every HDR output on current Plasma.
//
// Headroom survives that change because it describes the panel rather than the
// encoding. It is also the question that actually bears on the decision: if
// nothing can be shown above reference white, a PQ plane only invites the
// compositor to squash it back down, and mpv's own curve does that better.
//
// The margin is what keeps this honest. A bare `max > reference` is true for an
// SDR output too, because KWin dims SDR white in software and reports the
// undimmed maximum: at 80% brightness that is 200 over 161. Headroom that small
// is not worth switching pipelines for, so require half a stop. Every HDR
// output clears it comfortably — a 400-nit panel reports 400 over 203 — and
// dimming down to about 70% does not.
//
// Below roughly 60% the margin is met by an SDR output, and that is the right
// answer rather than a leak: KWin has genuinely dimmed white to 122 nits while
// the panel still reaches 200, so highlights really can go above white, and
// tone-mapping to 122 would throw that away. What the margin rejects is the
// case where the headroom is too slight to be worth the compositor squashing a
// 1000-nit source into it.
//
// Stated as 2*max >= 3*reference rather than max >= reference * 1.5, because
// these arrive unvalidated from the compositor: integer division would put the
// boundary half a nit low, and the addition form overflows on a reference white
// near the type's maximum, which would read as *no* headroom.
inline bool OutputHasHdrHeadroom(uint32_t max_luminance, uint32_t reference_luminance) {
  if (reference_luminance == 0) return false;
  return static_cast<uint64_t>(max_luminance) * 2 >= static_cast<uint64_t>(reference_luminance) * 3;
}

// What the compositor advertised it will accept, as named curves and primaries.
struct CompositorColorSupport {
  bool bt2020 = false;
  bool pq = false;
  bool hlg = false;
};

// Whether this source can be described to the compositor at all.
//
// Getting this wrong is not a degraded picture: naming a curve the compositor
// never advertised is a fatal invalid_tf on create(), which disconnects the
// whole client rather than failing the description. So the rule lives here,
// beside the gate it feeds and away from the Wayland types, where it can be
// tested without a compositor.
inline bool SourceIsDescribable(const HdrMetadata& metadata, const CompositorColorSupport& support) {
  if (!SourceIsHdr(metadata)) return false;
  // A wide-gamut container is part of what makes this worth doing, and the named
  // primaries have to be ones the compositor accepts.
  if (metadata.primaries != SourcePrimaries::kBt2020 || !support.bt2020) return false;
  switch (metadata.transfer) {
    case SourceTransfer::kPq:
      return support.pq;
    case SourceTransfer::kHlg:
      return support.hlg;
    case SourceTransfer::kSdr:
      break;
  }
  return false;
}

// Everything outside the source that bears on whether the plane carries HDR.
struct HdrInputs {
  bool allowed = false;              // the app's permission (the hdr-enabled setting)
  bool client_can_describe = false;  // 10-bit plane, colour-managed surface, advertised curve
  bool output_is_hdr = false;        // the output offers headroom above reference white
  bool source_describable = false;   // this source's curve and gamut are both advertised
  HdrToneMapping requested = HdrToneMapping::kCompositor;
  uint32_t display_peak_nits = 0;  // the output's peak while in HDR; 0 means unknown
  // The output's diffuse-white luminance, which is the most an SDR signal can
  // reach on it. Distinct from display_peak_nits: this panel reports a 600-nit
  // peak but 200-nit reference white, and only the latter is reachable without
  // an HDR description attached. 0 means unknown.
  uint32_t sdr_reference_nits = 0;
};

// What to do about it.
struct HdrDecision {
  bool describe = false;            // attach an image description at all
  bool tone_map_in_player = false;  // mpv reduces the range rather than the compositor
  // The peak mpv aims at. While a description is attached it is also the peak
  // declared to the compositor — deliberately one number, because the two
  // disagreeing is what makes a compositor remap a signal twice. Zero means
  // target-peak stays on auto.
  uint32_t target_peak_nits = 0;
};

// mpv's target-peak option accepts 10..10000; outside that there is nothing
// sensible to aim at and auto is the honest answer.
inline uint32_t UsableTargetPeak(uint32_t nits, uint32_t volume_max) {
  if (nits > volume_max) nits = volume_max;
  return nits >= 10 ? nits : 0;
}

// The single gate. Four independent conditions must hold before a plane is
// described as HDR, and they come from four different places: the user's
// setting, the compositor's advertised capabilities, the output's current state,
// and the file. Any one of them failing means falling back to mpv's ordinary
// tone-mapped SDR output, which is always safe.
//
// Both branches tell mpv what it is mapping to, from different fields. Left on
// auto mpv does pick its own defaults for an SDR curve and does tone-map against
// them, so this is about naming the output's real terms rather than assumed
// ones, measurably so at the bottom of the range. It is not what fixes the
// roll-off; that is mpv's `tone-mapping` operator, set in
// MpvPlayer::SetHdrOutput, and naming the peak alone left the highlights exactly
// where they were.
//
// Which field is right depends on what the plane will carry. Described, the
// output is in HDR and its peak is reachable. Undescribed, the buffer is an
// ordinary SDR signal whose maximum is the output's diffuse white, and claiming
// the HDR peak there would ask for range the encoding cannot express.
//
// The undescribed target applies only to an HDR *source*. An ordinary BT.709 file
// has nothing to map down: naming a peak for it would change plain SDR playback,
// which this has no business touching.
inline HdrDecision DecideHdr(const HdrInputs& inputs, const HdrMetadata& source) {
  HdrDecision decision;
  decision.describe = inputs.allowed && inputs.client_can_describe && inputs.output_is_hdr &&
                      inputs.source_describable && SourceIsHdr(source);
  if (!decision.describe) {
    if (SourceIsHdr(source)) {
      // No curve is being declared, so nothing constrains this to a primary
      // colour volume; the only ceiling is what the option accepts.
      decision.target_peak_nits = UsableTargetPeak(inputs.sdr_reference_nits, kPqMaxLuminanceNits);
      // mpv is the one reducing the range here, which is exactly what this flag
      // says. `describe` independently keeps any metadata off the surface, so
      // recording it truthfully costs nothing and keeps the decision coherent.
      decision.tone_map_in_player = decision.target_peak_nits > 0;
    }
    return decision;
  }

  if (inputs.requested == HdrToneMapping::kPlayer && inputs.display_peak_nits > 0) {
    // Clamped to the curve's primary colour volume here rather than at the two
    // call sites, so the peak handed to mpv and the peak in the description are
    // the same number by construction.
    const uint32_t peak = UsableTargetPeak(inputs.display_peak_nits, PrimaryVolumeMaxNits(source.transfer));
    if (peak > 0) {
      decision.tone_map_in_player = true;
      decision.target_peak_nits = peak;
    }
  }
  return decision;
}

}  // namespace mpv

#endif  // PLEZY_LINUX_MPV_HDR_METADATA_H_
