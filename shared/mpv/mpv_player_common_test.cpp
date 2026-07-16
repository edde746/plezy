#include "mpv_player_common.h"

#include <cassert>
#include <chrono>
#include <string>

namespace {

using plezy::mpv_common::AudioOutputTransition;
using plezy::mpv_common::AudioRecoveryState;
using plezy::mpv_common::AudioReloadReason;

void TestRequestRegistry() {
  plezy::mpv_common::AsyncRequestRegistry registry;
  bool status_called = false;
  bool property_called = false;

  const auto status_id = registry.RegisterStatus([&](int error) { status_called = error == -7; });
  const auto property_id = registry.RegisterProperty(
      [&](int error, const std::string& value) { property_called = error == -8 && value == "value"; });

  auto status = registry.TakeStatus(status_id);
  auto property = registry.TakeProperty(property_id);
  assert(status);
  assert(property);
  status(-7);
  property(-8, "value");
  assert(status_called);
  assert(property_called);
  assert(!registry.TakeStatus(status_id));
  assert(!registry.TakeProperty(property_id));

  registry.RegisterStatus([](int) {});
  registry.RegisterProperty([](int, const std::string&) {});
  auto cancelled = registry.CancelAll();
  assert(cancelled.status.size() == 1);
  assert(cancelled.properties.size() == 1);
}

void TestPropertyObservationRegistry() {
  plezy::mpv_common::PropertyObservationRegistry registry;
  const auto first = registry.Register("pause", "bool", 17);
  const auto duplicate = registry.Register("pause", "string", 99);
  const auto node = registry.Register("track-list", "node", 18);

  assert(first.added);
  assert(first.format == MPV_FORMAT_FLAG);
  assert(!duplicate.added);
  assert(node.added);
  assert(node.format == MPV_FORMAT_NODE);

  int id = 0;
  assert(registry.LookupId("pause", &id));
  assert(id == 17);
  assert(!registry.LookupId("missing", &id));
  registry.Clear();
  assert(!registry.LookupId("pause", &id));
}

void TestResumeRecoverySchedule() {
  AudioRecoveryState state;
  const auto start = AudioRecoveryState::Clock::time_point{};
  state.SetFileLoaded(true);
  state.RequestResume();

  assert(state.NextReload(start).reason == AudioReloadReason::kNone);
  assert(state.HasPendingWork());
  assert(state.NextReload(start + std::chrono::milliseconds(1499)).reason == AudioReloadReason::kNone);

  const auto first = state.NextReload(start + std::chrono::milliseconds(1500));
  assert(first.reason == AudioReloadReason::kResume);
  assert(first.attempt == 1);
  assert(!first.exhausted);
  state.CompleteReload();

  const auto second = state.NextReload(start + std::chrono::milliseconds(6000));
  assert(second.reason == AudioReloadReason::kResume);
  assert(second.attempt == 2);
  state.CompleteReload();
  assert(!state.HasPendingWork());
}

void TestNullFallbackRecoverySchedule() {
  AudioRecoveryState state;
  const auto start = AudioRecoveryState::Clock::time_point{};
  state.SetFileLoaded(true);
  assert(state.SetCurrentAudioOutputNull(true, start) == AudioOutputTransition::kFellBackToNull);

  auto action = state.NextReload(start + std::chrono::milliseconds(500));
  assert(action.reason == AudioReloadReason::kNullFallback);
  assert(action.attempt == 1);
  state.CompleteReload();

  action = state.NextReload(start + std::chrono::milliseconds(1000));
  assert(action.reason == AudioReloadReason::kNullFallback);
  assert(action.attempt == 2);
  state.CompleteReload();

  action = state.NextReload(start + std::chrono::milliseconds(2000));
  assert(action.reason == AudioReloadReason::kNullFallback);
  assert(action.attempt == 3);
  state.CompleteReload();

  action = state.NextReload(start + std::chrono::milliseconds(4000));
  assert(action.reason == AudioReloadReason::kNullFallback);
  assert(action.attempt == 4);
  state.CompleteReload();

  action = state.NextReload(start + std::chrono::milliseconds(8000));
  assert(action.reason == AudioReloadReason::kNullFallback);
  assert(action.attempt == 5);
  assert(action.exhausted);
  state.CompleteReload();
  assert(!state.HasPendingWork());

  assert(state.OnAudioDeviceListChanged(start + std::chrono::milliseconds(9000)));
  action = state.NextReload(start + std::chrono::milliseconds(9250));
  assert(action.reason == AudioReloadReason::kNullFallback);
  assert(action.attempt == 1);
  state.CompleteReload();

  assert(
      state.SetCurrentAudioOutputNull(false, start + std::chrono::milliseconds(9300)) ==
      AudioOutputTransition::kRecovered);
  assert(!state.HasPendingWork());
}

void TestHdrHelpers() {
  assert(plezy::mpv_common::ParseEnabledFlag("yes"));
  assert(plezy::mpv_common::ParseEnabledFlag("true"));
  assert(plezy::mpv_common::ParseEnabledFlag("1"));
  assert(!plezy::mpv_common::ParseEnabledFlag("no"));
  assert(std::string(plezy::mpv_common::TargetColorspaceHint(true)) == "auto");
  assert(std::string(plezy::mpv_common::TargetColorspaceHint(false)) == "no");
}

}  // namespace

int main() {
  TestRequestRegistry();
  TestPropertyObservationRegistry();
  TestResumeRecoverySchedule();
  TestNullFallbackRecoverySchedule();
  TestHdrHelpers();
  return 0;
}
