#include "video_params.h"

#include <iostream>
#include <vector>

namespace {

int failures = 0;

void Expect(bool condition, const char* expression, int line) {
  if (condition) return;
  std::cerr << "line " << line << ": check failed: " << expression << '\n';
  ++failures;
}

#define EXPECT(condition) Expect(static_cast<bool>(condition), #condition, __LINE__)

mpv_node Text(const char* value) {
  mpv_node node{};
  node.format = MPV_FORMAT_STRING;
  node.u.string = const_cast<char*>(value);
  return node;
}

mpv_node Number(double value) {
  mpv_node node{};
  node.format = MPV_FORMAT_DOUBLE;
  node.u.double_ = value;
  return node;
}

mpv_node Whole(int64_t value) {
  mpv_node node{};
  node.format = MPV_FORMAT_INT64;
  node.u.int64 = value;
  return node;
}

// Builds the node shape mpv delivers for an observed `video-params`: a map whose
// absent fields are missing keys rather than zeroed ones. Node() borrows the
// builder's storage, so nothing may be added after it is called.
class Params {
 public:
  Params& Add(const char* key, mpv_node value) {
    keys_.push_back(const_cast<char*>(key));
    values_.push_back(value);
    return *this;
  }

  mpv_node Node() {
    list_.num = static_cast<int>(values_.size());
    list_.keys = keys_.empty() ? nullptr : keys_.data();
    list_.values = values_.empty() ? nullptr : values_.data();
    mpv_node node{};
    node.format = MPV_FORMAT_NODE_MAP;
    node.u.list = &list_;
    return node;
  }

 private:
  std::vector<char*> keys_;
  std::vector<mpv_node> values_;
  mpv_node_list list_{};
};

// A fully described HDR10 master: both names and all four luminances, mixed in
// among the fields the HDR decision has no use for, since mpv sends the whole
// map every time and the keys are in mpv's order, not ours.
void TestEveryFieldPresentIsRead() {
  Params params;
  params.Add("pixelformat", Text("yuv420p10"))
      .Add("w", Whole(3840))
      .Add("gamma", Text("pq"))
      .Add("primaries", Text("bt.2020"))
      .Add("min-luma", Number(0.0001))
      .Add("max-luma", Number(1000.0))
      .Add("max-cll", Number(999.0))
      .Add("max-fall", Number(400.0))
      .Add("chroma-location", Text("mpeg2/4/h264"));
  const mpv_node node = params.Node();
  const mpv::SourceHdrMetadata metadata = mpv::ParseSourceHdrMetadata(&node);

  EXPECT(metadata.transfer == "pq");
  EXPECT(metadata.primaries == "bt.2020");
  EXPECT(metadata.max_cll == 999.0);
  EXPECT(metadata.max_fall == 400.0);
  EXPECT(metadata.max_luminance == 1000.0);
  EXPECT(metadata.min_luminance == 0.0001);
}

// The common HDR10 case: a PQ / BT.2020 stream that states no static metadata at
// all. mpv omits the keys entirely, and every luminance has to stay at zero -
// which is how the rest of the pipeline spells "not stated" - while both names
// still come through, because they are what decides whether the plane may be
// described as HDR in the first place.
void TestNamesSurviveWithNoLuminances() {
  Params params;
  params.Add("gamma", Text("hlg")).Add("primaries", Text("bt.2020"));
  const mpv_node node = params.Node();
  const mpv::SourceHdrMetadata metadata = mpv::ParseSourceHdrMetadata(&node);

  EXPECT(metadata.transfer == "hlg");
  EXPECT(metadata.primaries == "bt.2020");
  EXPECT(metadata.max_cll == 0.0);
  EXPECT(metadata.max_fall == 0.0);
  EXPECT(metadata.max_luminance == 0.0);
  EXPECT(metadata.min_luminance == 0.0);
}

// Each luminance is independent: a source may state MaxCLL and nothing else, or
// a mastering range and no light levels. An absent field must never pick up its
// neighbour's value or a default.
void TestEachLuminanceIsAbsentOnItsOwn() {
  {
    Params params;
    params.Add("max-cll", Number(1200.0));
    const mpv_node node = params.Node();
    const mpv::SourceHdrMetadata metadata = mpv::ParseSourceHdrMetadata(&node);
    EXPECT(metadata.max_cll == 1200.0);
    EXPECT(metadata.max_fall == 0.0);
    EXPECT(metadata.max_luminance == 0.0);
    EXPECT(metadata.min_luminance == 0.0);
  }
  {
    Params params;
    params.Add("max-fall", Number(250.0));
    const mpv_node node = params.Node();
    const mpv::SourceHdrMetadata metadata = mpv::ParseSourceHdrMetadata(&node);
    EXPECT(metadata.max_cll == 0.0);
    EXPECT(metadata.max_fall == 250.0);
    EXPECT(metadata.max_luminance == 0.0);
  }
  {
    Params params;
    params.Add("min-luma", Number(0.005));
    const mpv_node node = params.Node();
    const mpv::SourceHdrMetadata metadata = mpv::ParseSourceHdrMetadata(&node);
    EXPECT(metadata.max_luminance == 0.0);
    EXPECT(metadata.min_luminance == 0.005);
  }
  {
    Params params;
    params.Add("max-luma", Number(4000.0));
    const mpv_node node = params.Node();
    const mpv::SourceHdrMetadata metadata = mpv::ParseSourceHdrMetadata(&node);
    EXPECT(metadata.max_luminance == 4000.0);
    EXPECT(metadata.min_luminance == 0.0);
  }
}

// The mastering floor is the one luminance a source may legitimately state as
// zero, so a present zero has to be taken rather than dropped. The others treat
// zero as no statement, which is the same thing they do with an absent key -
// and since the field's absent value *is* zero, only a negative can tell the
// two rules apart from the outside.
void TestMinLumaAcceptsAZeroTheOthersRefuse() {
  Params params;
  params.Add("gamma", Text("pq"))
      .Add("min-luma", Number(0.0))
      .Add("max-luma", Number(0.0))
      .Add("max-cll", Number(0.0))
      .Add("max-fall", Number(0.0));
  const mpv_node node = params.Node();
  const mpv::SourceHdrMetadata metadata = mpv::ParseSourceHdrMetadata(&node);

  EXPECT(metadata.min_luminance == 0.0);
  EXPECT(metadata.max_luminance == 0.0);
  EXPECT(metadata.max_cll == 0.0);
  EXPECT(metadata.max_fall == 0.0);

  // No luminance may be negative. The floor would scale into a mastering
  // minimum the protocol rejects, and a negative peak would sail through the
  // containment checks that only ever compare upwards.
  Params negative;
  negative.Add("min-luma", Number(-1.0))
      .Add("max-luma", Number(-4000.0))
      .Add("max-cll", Number(-1000.0))
      .Add("max-fall", Number(-400.0));
  const mpv_node negative_node = negative.Node();
  const mpv::SourceHdrMetadata refused = mpv::ParseSourceHdrMetadata(&negative_node);
  EXPECT(refused.min_luminance == 0.0);
  EXPECT(refused.max_luminance == 0.0);
  EXPECT(refused.max_cll == 0.0);
  EXPECT(refused.max_fall == 0.0);
}

// The names are mpv's own and this parse does not judge them: SDR curves, gamuts
// with no protocol counterpart, and anything a future mpv adds all pass through
// verbatim for the caller to classify. Copying them into an enum here would put
// the same table in two places.
void TestUnknownNamesPassThroughVerbatim() {
  Params params;
  params.Add("gamma", Text("bt.1886")).Add("primaries", Text("display-p3")).Add("max-cll", Number(120.0));
  const mpv_node node = params.Node();
  const mpv::SourceHdrMetadata metadata = mpv::ParseSourceHdrMetadata(&node);

  EXPECT(metadata.transfer == "bt.1886");
  EXPECT(metadata.primaries == "display-p3");
  EXPECT(metadata.max_cll == 120.0);
}

// Everything that is not the map mpv documents has to read as "no stream": the
// property is unavailable between files and while an audio-only core runs, and
// the event carries MPV_FORMAT_NONE then. Deciding from a half-read map would
// describe the plane in a colour space nothing is emitting.
void TestNonMapNodesYieldNothing() {
  EXPECT(mpv::ParseSourceHdrMetadata(nullptr).transfer.empty());

  mpv_node none{};
  none.format = MPV_FORMAT_NONE;
  EXPECT(mpv::ParseSourceHdrMetadata(&none).transfer.empty());

  // The shape an observation of the same property in another format delivers.
  const mpv_node string_node = Text("pq");
  const mpv::SourceHdrMetadata from_string = mpv::ParseSourceHdrMetadata(&string_node);
  EXPECT(from_string.transfer.empty());
  EXPECT(from_string.primaries.empty());

  // An array is a map's near neighbour and has no keys to walk.
  mpv_node_list list{};
  list.num = 1;
  mpv_node array_node{};
  array_node.format = MPV_FORMAT_NODE_ARRAY;
  array_node.u.list = &list;
  EXPECT(mpv::ParseSourceHdrMetadata(&array_node).transfer.empty());

  // A map claiming entries it does not carry, which is what a truncated or
  // hostile payload looks like.
  mpv_node empty_map{};
  empty_map.format = MPV_FORMAT_NODE_MAP;
  empty_map.u.list = &list;
  EXPECT(mpv::ParseSourceHdrMetadata(&empty_map).transfer.empty());

  mpv_node null_map{};
  null_map.format = MPV_FORMAT_NODE_MAP;
  EXPECT(mpv::ParseSourceHdrMetadata(&null_map).transfer.empty());
}

// A key whose value is not the format mpv documents for it is ignored rather
// than reinterpreted, and it must not stop the rest of the map being read. An
// integer luminance is the one exception: the blocking sub-property read this
// replaced asked for a double and libmpv would have converted it.
void TestMistypedValuesAreSkippedButIntegersAreNot() {
  Params params;
  params.Add("gamma", Number(2.2))
      .Add("primaries", Text("bt.2020"))
      .Add("max-cll", Text("1000"))
      .Add("max-luma", Whole(4000))
      .Add("min-luma", Text("0.0001"));
  const mpv_node node = params.Node();
  const mpv::SourceHdrMetadata metadata = mpv::ParseSourceHdrMetadata(&node);

  EXPECT(metadata.transfer.empty());
  EXPECT(metadata.primaries == "bt.2020");
  EXPECT(metadata.max_cll == 0.0);
  EXPECT(metadata.max_luminance == 4000.0);
  EXPECT(metadata.min_luminance == 0.0);

  // mpv owns the strings, and a null one is not a name.
  Params null_name;
  null_name.Add("gamma", Text(nullptr)).Add("primaries", Text("bt.2020"));
  const mpv_node null_name_node = null_name.Node();
  const mpv::SourceHdrMetadata from_null = mpv::ParseSourceHdrMetadata(&null_name_node);
  EXPECT(from_null.transfer.empty());
  EXPECT(from_null.primaries == "bt.2020");
}

}  // namespace

int main() {
  TestEveryFieldPresentIsRead();
  TestNamesSurviveWithNoLuminances();
  TestEachLuminanceIsAbsentOnItsOwn();
  TestMinLumaAcceptsAZeroTheOthersRefuse();
  TestUnknownNamesPassThroughVerbatim();
  TestNonMapNodesYieldNothing();
  TestMistypedValuesAreSkippedButIntegersAreNot();
  return failures == 0 ? 0 : 1;
}
