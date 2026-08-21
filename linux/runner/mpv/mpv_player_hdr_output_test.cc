// Focused test for MpvPlayer's output-colour-space transaction: the four
// properties that together say what mpv is emitting, applied as a unit, unwound
// as a unit, and escalated to SDR when they cannot be unwound.
//
// Nothing else covers it, and nothing about it is visible on screen. A renamed
// property, a reversed write order or a rollback that reports success without
// restoring all leave working-looking video behind while the plane's committed
// surface description says something the pixels do not — the single state the
// whole transaction exists to prevent. So the assertions here are on the
// recorded (name, value) stream, not only on the returned result.

#include <mpv/client.h>

#include <cstddef>
#include <iostream>
#include <set>
#include <stdexcept>
#include <string>
#include <utility>
#include <vector>

#include "mpv_player.h"

namespace mpv {
namespace {

void Check(bool condition, const char* message) {
  if (!condition) throw std::runtime_error(message);
}

struct PropertyWrite {
  std::string name;
  std::string value;
};

// Stands in for the core: records every property write in order and answers
// each with a scripted mpv status.
//
// Replies synchronously, which real mpv does not. That is sound here because
// the ladder awaits every reply before issuing the next write — the property
// stream a synchronous core sees is the one an asynchronous core would see, and
// no main loop has to be pumped to observe it.
class ScriptedCore {
 public:
  void Install(MpvPlayer& player) {
    player.ConfigurePropertyWritesForTesting(
        [this](const std::string& name, const std::string& value, MpvPlayer::StatusCallback callback) {
          const size_t position = writes_.size();
          writes_.push_back(PropertyWrite{name, value});
          const bool refused = refusals_.count(position) != 0;
          if (callback) callback(refused ? MPV_ERROR_PROPERTY_ERROR : MPV_ERROR_SUCCESS);
        });
  }

  // Drops the substituted writer, which is what makes the player look like a
  // core that can no longer be commanded: with no writer, the real
  // disposed_/mpv_ check underneath decides, and a player that never opened a
  // handle fails it.
  void Uninstall(MpvPlayer& player) { player.ConfigurePropertyWritesForTesting(nullptr); }

  // Refuses the write that lands at |position| in the recorded stream, counting
  // from the last Forget().
  void RefuseWrite(size_t position) { refusals_.insert(position); }

  void Forget() {
    writes_.clear();
    refusals_.clear();
  }

  const std::vector<PropertyWrite>& writes() const { return writes_; }

 private:
  std::vector<PropertyWrite> writes_;
  std::set<size_t> refusals_;
};

// Both sides of the comparison are printed on a mismatch: the failure mode this
// test guards against is a stream that is *almost* right, and "expected 5 writes,
// got 5 writes" would say nothing about which one moved.
void CheckWrites(const ScriptedCore& core, const std::vector<PropertyWrite>& expected, const char* message) {
  const std::vector<PropertyWrite>& actual = core.writes();
  bool matched = actual.size() == expected.size();
  for (size_t index = 0; matched && index < expected.size(); ++index) {
    matched = actual[index].name == expected[index].name && actual[index].value == expected[index].value;
  }
  if (matched) return;

  std::cerr << "  expected writes:\n";
  for (const PropertyWrite& write : expected) std::cerr << "    " << write.name << '=' << write.value << '\n';
  std::cerr << "  recorded writes:\n";
  for (const PropertyWrite& write : actual) std::cerr << "    " << write.name << '=' << write.value << '\n';
  Check(false, message);
}

void CheckApplied(
    const MpvPlayer& player, const char* target_trc, const char* target_prim, const char* tone_mapping,
    const char* target_peak, const char* message) {
  const MpvPlayer::AppliedOutputColourSpace applied = player.AppliedOutputColourSpaceForTesting();
  if (applied.target_trc == target_trc && applied.target_prim == target_prim && applied.tone_mapping == tone_mapping &&
      applied.target_peak == target_peak) {
    return;
  }
  std::cerr << "  expected applied: trc=" << target_trc << " prim=" << target_prim << " tone-mapping=" << tone_mapping
            << " peak=" << target_peak << '\n';
  std::cerr << "  recorded applied: trc=" << applied.target_trc << " prim=" << applied.target_prim
            << " tone-mapping=" << applied.tone_mapping << " peak=" << applied.target_peak << '\n';
  Check(false, message);
}

// One request, run to completion, with the outcome its caller would act on.
struct Outcome {
  int callbacks = 0;
  MpvPlayer::HdrOutputResult result = MpvPlayer::HdrOutputResult::kUnknown;
  int error = MPV_ERROR_SUCCESS;
};

Outcome Request(MpvPlayer& player, SourceTransfer transfer, uint32_t peak_nits) {
  Outcome outcome;
  player.SetHdrOutput(transfer, peak_nits, [&outcome](MpvPlayer::HdrOutputResult result, int error) {
    ++outcome.callbacks;
    outcome.result = result;
    outcome.error = error;
  });
  Check(outcome.callbacks == 1, "an output colour space request must complete exactly once");
  return outcome;
}

// Puts the player in a real HDR output state before the failure cases run, so
// the values a rollback restores are ones mpv genuinely held. From the default
// state every rollback target is "auto", which a rollback that wrote nothing at
// all would also produce.
void ApplyPqBaseline(MpvPlayer& player, ScriptedCore& core) {
  const Outcome outcome = Request(player, SourceTransfer::kPq, 0);
  Check(outcome.result == MpvPlayer::HdrOutputResult::kApplied, "the PQ baseline for the failure cases must apply");
  CheckApplied(player, "pq", "bt.2020", "auto", "auto", "the PQ baseline must be the state later rollbacks restore");
  core.Forget();
}

// The happy path, and the exact strings that are the contract with mpv. The
// order is a dependency order: target-peak is what decides whether a tone-map
// pass runs at all, so everything that pass reads is in place before it is
// named. Nothing else in the tree checks either the names or the ordering.
void TestHdrApplyWritesTheFourPropertiesPeakLast() {
  ScriptedCore core;
  MpvPlayer player;
  core.Install(player);

  const Outcome outcome = Request(player, SourceTransfer::kPq, 0);

  CheckWrites(
      core, {{"target-trc", "pq"}, {"target-prim", "bt.2020"}, {"tone-mapping", "auto"}, {"target-peak", "auto"}},
      "an HDR request must write all four properties in dependency order with the peak last");
  Check(outcome.result == MpvPlayer::HdrOutputResult::kApplied, "a fully applied sequence must report kApplied");
  Check(outcome.error == MPV_ERROR_SUCCESS, "a fully applied sequence must report no error");
  CheckApplied(player, "pq", "bt.2020", "auto", "auto", "the applied cache must hold exactly what was written");
}

// A display peak inside mpv's 10..10000 range moves the tone map into mpv, and
// the peak is the property that says so. The operator stays on mpv's own choice
// while the target is HDR — see the tone-mapping comment in RunPendingHdrOutput.
void TestHdrApplyWithADisplayPeakNamesThatPeak() {
  ScriptedCore core;
  MpvPlayer player;
  core.Install(player);

  const Outcome outcome = Request(player, SourceTransfer::kHlg, 1000);

  CheckWrites(
      core, {{"target-trc", "hlg"}, {"target-prim", "bt.2020"}, {"tone-mapping", "auto"}, {"target-peak", "1000"}},
      "an HLG request with a display peak must encode HLG and name that peak");
  Check(outcome.result == MpvPlayer::HdrOutputResult::kApplied, "a fully applied sequence must report kApplied");
  CheckApplied(player, "hlg", "bt.2020", "auto", "1000", "the applied cache must hold exactly what was written");
}

// The other half of the contract: an SDR decision withdraws the HDR request
// rather than leaving any part of it standing. A plane on BT.2020 primaries with
// an SDR curve is neither, and is exactly what a partial withdrawal produces.
void TestSdrRequestWithdrawsEveryHdrProperty() {
  ScriptedCore core;
  MpvPlayer player;
  core.Install(player);
  ApplyPqBaseline(player, core);

  const Outcome outcome = Request(player, SourceTransfer::kSdr, 0);

  CheckWrites(
      core, {{"target-trc", "auto"}, {"target-prim", "auto"}, {"tone-mapping", "auto"}, {"target-peak", "auto"}},
      "an SDR request must return every output property to auto");
  Check(outcome.result == MpvPlayer::HdrOutputResult::kApplied, "a fully applied SDR sequence must report kApplied");
  CheckApplied(player, "auto", "auto", "auto", "auto", "the applied cache must follow the SDR withdrawal");
}

// The measured SDR fallback: mpv tone-maps to the compositor's own reference
// white, in the surface's real terms rather than assumed ones. mobius is the
// operator that measurement selected, and it is applied here and nowhere else.
void TestSdrRequestWithAReferenceWhiteNamesTheMeasuredTerms() {
  ScriptedCore core;
  MpvPlayer player;
  core.Install(player);

  const Outcome outcome = Request(player, SourceTransfer::kSdr, 203);

  CheckWrites(
      core, {{"target-trc", "srgb"}, {"target-prim", "auto"}, {"tone-mapping", "mobius"}, {"target-peak", "203"}},
      "an SDR request with a reference white must name sRGB, mobius and that white");
  Check(outcome.result == MpvPlayer::HdrOutputResult::kApplied, "a fully applied SDR sequence must report kApplied");
  CheckApplied(player, "srgb", "auto", "mobius", "203", "the applied cache must hold exactly what was written");
}

// playback-restart re-applies on every seek, so most requests ask for the state
// mpv already holds; skipping those is what stops a seek costing four round
// trips. The skip has to be exact, though: it reports kApplied, and a caller
// commits a surface description against that word. A quad that differs anywhere
// and is skipped anyway leaves the description describing the previous one.
void TestIdenticalRequestIsSkippedButANarrowlyDifferentOneIsNot() {
  ScriptedCore core;
  MpvPlayer player;
  core.Install(player);
  ApplyPqBaseline(player, core);

  const Outcome repeat = Request(player, SourceTransfer::kPq, 0);
  CheckWrites(core, {}, "a request for the state already in force must write nothing");
  Check(repeat.result == MpvPlayer::HdrOutputResult::kApplied, "a skipped request must still report kApplied");
  Check(repeat.error == MPV_ERROR_SUCCESS, "a skipped request must report no error");

  // Differs from the state in force in target-peak alone.
  core.Forget();
  const Outcome peak_only = Request(player, SourceTransfer::kPq, 1000);
  CheckWrites(
      core, {{"target-trc", "pq"}, {"target-prim", "bt.2020"}, {"tone-mapping", "auto"}, {"target-peak", "1000"}},
      "a request differing only in the peak must not be skipped");
  Check(peak_only.result == MpvPlayer::HdrOutputResult::kApplied, "a re-applied sequence must report kApplied");
  CheckApplied(player, "pq", "bt.2020", "auto", "1000", "the applied cache must follow a peak-only change");

  // Differs from the state now in force in target-trc alone. The other two
  // cannot vary on their own: primaries move with the HDR decision and the
  // operator with the tone-map decision, and either decision also moves the
  // curve. So the comparison is exercised on the two that can.
  core.Forget();
  const Outcome curve_only = Request(player, SourceTransfer::kHlg, 1000);
  CheckWrites(
      core, {{"target-trc", "hlg"}, {"target-prim", "bt.2020"}, {"tone-mapping", "auto"}, {"target-peak", "1000"}},
      "a request differing only in the transfer curve must not be skipped");
  Check(curve_only.result == MpvPlayer::HdrOutputResult::kApplied, "a re-applied sequence must report kApplied");
  CheckApplied(player, "hlg", "bt.2020", "auto", "1000", "the applied cache must follow a curve-only change");
}

// A refused step unwinds what already landed, newest first, and reports
// kRestored — the one result that tells the caller its previously committed
// description is still true and must be left alone. Both halves matter: the
// order, because an unwind in apply order would restore a property the refused
// step's dependencies still contradict, and the values, because "restored" is a
// claim about what mpv now holds, not about how many writes were issued.
void TestRefusedStepUnwindsNewestFirstAndReportsRestored() {
  ScriptedCore core;
  MpvPlayer player;
  core.Install(player);
  ApplyPqBaseline(player, core);

  core.RefuseWrite(2);  // tone-mapping, two properties into the sequence
  const Outcome outcome = Request(player, SourceTransfer::kSdr, 203);

  CheckWrites(
      core,
      {{"target-trc", "srgb"},
       {"target-prim", "auto"},
       {"tone-mapping", "mobius"},
       {"target-prim", "bt.2020"},
       {"target-trc", "pq"}},
      "a refused step must restore each earlier property to its previous value, newest first");
  Check(outcome.result == MpvPlayer::HdrOutputResult::kRestored, "a cleanly unwound sequence must report kRestored");
  Check(outcome.error == MPV_ERROR_PROPERTY_ERROR, "the reported error must be the original refusal");
  CheckApplied(player, "pq", "bt.2020", "auto", "auto", "a refused sequence must leave the applied cache untouched");
}

// An unwinding step that is itself refused leaves mpv in a state that is neither
// the old colour space nor the new, and no surface description is correct for a
// signal nobody can name. The escalation drives every property to auto — always
// valid, always describable — and says so with kForcedSdr, which is the caller's
// cue that any HDR description it committed is now a lie about the pixels.
void TestRefusedRollbackForcesSdr() {
  ScriptedCore core;
  MpvPlayer player;
  core.Install(player);
  ApplyPqBaseline(player, core);

  core.RefuseWrite(2);  // tone-mapping
  core.RefuseWrite(3);  // the first unwinding write
  const Outcome outcome = Request(player, SourceTransfer::kSdr, 203);

  CheckWrites(
      core,
      {{"target-trc", "srgb"},
       {"target-prim", "auto"},
       {"tone-mapping", "mobius"},
       {"target-prim", "bt.2020"},
       {"target-trc", "auto"},
       {"target-prim", "auto"},
       {"tone-mapping", "auto"},
       {"target-peak", "auto"}},
      "a refused rollback must drive every output property to auto");
  Check(outcome.result == MpvPlayer::HdrOutputResult::kForcedSdr, "a forced SDR unwind must report kForcedSdr");
  Check(outcome.error == MPV_ERROR_PROPERTY_ERROR, "the reported error must still be the original refusal");
  CheckApplied(player, "auto", "auto", "auto", "auto", "forcing SDR must leave the applied cache describing SDR");
}

// `auto` is valid for all four, so a core that refuses even that is no longer
// taking orders — usually because it is being disposed. What the plane emits is
// then unknowable, and kUnknown is the result the plugin treats as "nothing can
// be said about these pixels", stopping the presentation rather than guessing.
// The applied cache must stay where it was: claiming SDR here would be a guess.
void TestRefusedForcedSdrReportsUnknown() {
  ScriptedCore core;
  MpvPlayer player;
  core.Install(player);
  ApplyPqBaseline(player, core);

  core.RefuseWrite(2);  // tone-mapping
  core.RefuseWrite(3);  // the first unwinding write
  core.RefuseWrite(5);  // the second write of the forced-SDR reset
  const Outcome outcome = Request(player, SourceTransfer::kSdr, 203);

  CheckWrites(
      core,
      {{"target-trc", "srgb"},
       {"target-prim", "auto"},
       {"tone-mapping", "mobius"},
       {"target-prim", "bt.2020"},
       {"target-trc", "auto"},
       {"target-prim", "auto"}},
      "a refused forced-SDR reset must stop rather than carry on down the list");
  Check(outcome.result == MpvPlayer::HdrOutputResult::kUnknown, "an uncommandable core must report kUnknown");
  Check(outcome.error == MPV_ERROR_PROPERTY_ERROR, "the reported error must still be the original refusal");
  CheckApplied(
      player, "auto", "bt.2020", "auto", "auto",
      "a reset step that landed must be recorded, even though a later one was refused");
}

// Two mechanisms that are each correct alone and wrong together. A forced-SDR
// reset refused on its *first* step records nothing, so the cache still names
// the pre-request state - while mpv holds neither that nor SDR: the sequence's
// own first write landed before it failed. The no-op short-circuit would then
// find that stale cache matching the next identical request, report kApplied
// without writing anything, and the plugin would commit a PQ image description
// over pixels mpv is emitting as sRGB. That is a wrong picture with no error
// anywhere, and it needs the two together, so neither one's tests can catch it.
void TestAnUnknownOutputStateIsNeverAnsweredFromTheCache() {
  ScriptedCore core;
  MpvPlayer player;
  core.Install(player);
  ApplyPqBaseline(player, core);

  core.RefuseWrite(2);  // tone-mapping, the request's own third write
  core.RefuseWrite(3);  // the rollback of target-prim
  core.RefuseWrite(4);  // the forced-SDR reset's first step, target-trc
  Check(
      Request(player, SourceTransfer::kSdr, 203).result == MpvPlayer::HdrOutputResult::kUnknown,
      "the setup for this case is a reset refused before it recorded anything");
  CheckApplied(
      player, "pq", "bt.2020", "auto", "auto",
      "nothing landed after the refusal, so the cache still names the pre-request state");

  // Exactly the request the baseline made, so the cache above matches it in all
  // four values. mpv does not: target-trc is srgb, from the write that landed
  // before the refusal. Refusing nothing this time isolates the gate - a skip
  // here could only come from trusting the cache.
  const size_t before = core.writes().size();
  const Outcome outcome = Request(player, SourceTransfer::kPq, 0);

  Check(core.writes().size() > before, "a request after an unknown output state must write, not skip");
  Check(outcome.result == MpvPlayer::HdrOutputResult::kApplied, "the re-applied sequence must succeed");
  CheckApplied(player, "pq", "bt.2020", "auto", "auto", "a clean apply must leave the cache naming what it wrote");
}

// A sequence refused on its very first write unwinds nothing - RollbackPropertySequence
// returns straight back out with nothing to undo - so it reports the untouched
// kRestored: "mpv is exactly where it was". True, and worthless once where it was
// is itself unknown. The caller reads kRestored as "the description you committed
// still holds" and puts the plane back on screen; after an unknown state there is
// no description, and mpv is in the half-reset colour space the last refusal left.
// The two mechanisms are each right alone: unwinding nothing really is a clean
// unwind, and kRestored really does mean the description stands - when the
// starting point was nameable.
void TestARefusalAfterAnUnknownStateIsNotReportedAsRestored() {
  ScriptedCore core;
  MpvPlayer player;
  core.Install(player);
  ApplyPqBaseline(player, core);

  core.RefuseWrite(2);
  core.RefuseWrite(3);
  core.RefuseWrite(4);
  Check(
      Request(player, SourceTransfer::kSdr, 203).result == MpvPlayer::HdrOutputResult::kUnknown,
      "the setup for this case is an output state that can no longer be named");

  // The next request's first write, refused. Nothing to unwind, so the unwind
  // result stays at its clean default - which is the trap.
  core.RefuseWrite(5);
  const Outcome outcome = Request(player, SourceTransfer::kPq, 0);

  Check(
      outcome.result != MpvPlayer::HdrOutputResult::kRestored,
      "a refusal on top of an unknown output state must not claim mpv was restored");
  Check(
      outcome.result == MpvPlayer::HdrOutputResult::kUnknown,
      "it must stay unknown, so the caller keeps the plane off screen rather than showing it undescribed");
}

// The third place a result is named: the early return taken when the core can no
// longer be commanded at all. It owes the same answer as the other two, or a
// request already queued when the core went away is answered kUnknown by the
// drain while an identical one arriving a moment later hears kRestored - two
// different claims about one output, decided by timing.
void TestAnUncommandableCoreInheritsTheUnknownState() {
  ScriptedCore core;
  MpvPlayer player;
  core.Install(player);
  ApplyPqBaseline(player, core);

  core.RefuseWrite(2);
  core.RefuseWrite(3);
  core.RefuseWrite(4);
  Check(
      Request(player, SourceTransfer::kSdr, 203).result == MpvPlayer::HdrOutputResult::kUnknown,
      "the setup for this case is an output state that can no longer be named");

  core.Uninstall(player);
  const Outcome outcome = Request(player, SourceTransfer::kPq, 0);

  Check(
      outcome.result == MpvPlayer::HdrOutputResult::kUnknown,
      "a core that cannot be commanded must not claim the unknown state was restored");
  Check(outcome.error == MPV_ERROR_UNINITIALIZED, "the early return still reports why it could not run");
}

}  // namespace
}  // namespace mpv

int main() {
  GMainContext* context = g_main_context_new();
  g_main_context_push_thread_default(context);

  // The escalation cases provoke the ladder's own g_warning on purpose, and
  // every apply logs its decision. Swallow both: a passing run that prints
  // "could not restore target-prim" reads like a failing one, and the next
  // person to see it will try to fix the wrong thing. Real failures come back
  // through Check, not through the log.
  g_log_set_default_handler([](const gchar*, GLogLevelFlags, const gchar*, gpointer) {}, nullptr);

  try {
    mpv::TestHdrApplyWritesTheFourPropertiesPeakLast();
    mpv::TestHdrApplyWithADisplayPeakNamesThatPeak();
    mpv::TestSdrRequestWithdrawsEveryHdrProperty();
    mpv::TestSdrRequestWithAReferenceWhiteNamesTheMeasuredTerms();
    mpv::TestIdenticalRequestIsSkippedButANarrowlyDifferentOneIsNot();
    mpv::TestRefusedStepUnwindsNewestFirstAndReportsRestored();
    mpv::TestRefusedRollbackForcesSdr();
    mpv::TestRefusedForcedSdrReportsUnknown();
    mpv::TestAnUnknownOutputStateIsNeverAnsweredFromTheCache();
    mpv::TestARefusalAfterAnUnknownStateIsNotReportedAsRestored();
    mpv::TestAnUncommandableCoreInheritsTheUnknownState();
  } catch (const std::exception& error) {
    g_main_context_pop_thread_default(context);
    g_main_context_unref(context);
    std::cerr << "mpv_player_hdr_output_test: " << error.what() << '\n';
    return 1;
  }

  g_main_context_pop_thread_default(context);
  g_main_context_unref(context);
  std::cout << "mpv_player_hdr_output_test: PASS\n";
  return 0;
}
