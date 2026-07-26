#include "mpv_player_common.h"

#ifdef NDEBUG
#undef NDEBUG
#endif

#include <atomic>
#include <cassert>
#include <chrono>
#include <string>
#include <thread>
#include <vector>

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

void TestConcurrentRequestCompletion() {
  for (int iteration = 0; iteration < 200; ++iteration) {
    plezy::mpv_common::AsyncRequestRegistry registry;
    std::atomic<int> completions{0};
    const auto id = registry.RegisterStatus([&](int) { completions.fetch_add(1); });
    std::atomic<bool> start{false};

    std::thread taker([&]() {
      while (!start.load(std::memory_order_acquire)) {
      }
      auto callback = registry.TakeStatus(id);
      if (callback) callback(0);
    });
    std::thread canceller([&]() {
      while (!start.load(std::memory_order_acquire)) {
      }
      auto cancelled = registry.CancelAll();
      for (auto& callback : cancelled.status) {
        callback(MPV_ERROR_UNINITIALIZED);
      }
    });

    start.store(true, std::memory_order_release);
    taker.join();
    canceller.join();
    assert(completions.load() == 1);
  }
}

void TestSetPropertyResultContract() {
  using namespace plezy::mpv_common;

  assert(std::string(kSetPropertyFailedCode) == "SET_PROPERTY_FAILED");
  assert(std::string(kSetPropertyNotInitializedCode) == "NOT_INITIALIZED");
  assert(SetPropertyStatusSucceeded(MPV_ERROR_SUCCESS));
  assert(SetPropertyStatusSucceeded(1));

  assert(!SetPropertyStatusSucceeded(MPV_ERROR_UNINITIALIZED));

  assert(std::string(SetPropertyErrorCode(MPV_ERROR_UNINITIALIZED)) == kSetPropertyNotInitializedCode);

  constexpr int kRejectedStatuses[] = {
      MPV_ERROR_INVALID_PARAMETER,
      MPV_ERROR_PROPERTY_ERROR,
      -1,
  };
  for (const int status : kRejectedStatuses) {
    assert(!SetPropertyStatusSucceeded(status));
    assert(std::string(SetPropertyErrorCode(status)) == kSetPropertyFailedCode);
  }

  constexpr int kDescribedStatuses[] = {
      MPV_ERROR_INVALID_PARAMETER,
      MPV_ERROR_PROPERTY_ERROR,
      -1,
      MPV_ERROR_UNINITIALIZED,
  };
  for (const int status : kDescribedStatuses) {
    const std::string description = SetPropertyErrorDescription(status);
    assert(!description.empty());
    assert(description.size() <= kSetPropertyErrorDescriptionLimit);
    assert(description.find("caller-secret") == std::string::npos);
  }
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

void TestConcurrentPropertyObservationRegistry() {
  constexpr int kPropertyCount = 512;
  constexpr int kClearRounds = 32;
  plezy::mpv_common::PropertyObservationRegistry registry;
  std::vector<std::string> names;
  names.reserve(kPropertyCount);
  for (int i = 0; i < kPropertyCount; ++i) {
    names.push_back("property-" + std::to_string(i));
  }

  std::atomic<bool> start{false};
  std::atomic<bool> writer_done{false};
  std::thread writer([&]() {
    while (!start.load(std::memory_order_acquire)) {
    }
    for (int round = 0; round < kClearRounds; ++round) {
      for (int i = 0; i < kPropertyCount; ++i) {
        registry.Register(names[i], "int64", 1000 + i);
      }
    }
    writer_done.store(true, std::memory_order_release);
  });
  std::thread reader([&]() {
    while (!start.load(std::memory_order_acquire)) {
    }
    while (!writer_done.load(std::memory_order_acquire)) {
      for (int i = 0; i < kPropertyCount; ++i) {
        int id = 0;
        if (registry.LookupId(names[i], &id)) {
          assert(id == 1000 + i);
        }
      }
    }
  });
  std::thread clearer([&]() {
    while (!start.load(std::memory_order_acquire)) {
    }
    for (int round = 0; round < kClearRounds; ++round) {
      registry.Clear();
      std::this_thread::yield();
    }
  });

  start.store(true, std::memory_order_release);
  writer.join();
  reader.join();
  clearer.join();

  registry.Clear();
  for (int i = 0; i < kPropertyCount; ++i) {
    const auto request = registry.Register(names[i], "int64", 1000 + i);
    assert(request.added);
  }
  for (int i = 0; i < kPropertyCount; ++i) {
    int id = 0;
    assert(registry.LookupId(names[i], &id));
    assert(id == 1000 + i);
  }
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
  assert(state.CompleteReload(first.request_generation));

  const auto second = state.NextReload(start + std::chrono::milliseconds(6000));
  assert(second.reason == AudioReloadReason::kResume);
  assert(second.attempt == 2);
  assert(state.CompleteReload(second.request_generation));
  assert(!state.HasPendingWork());
}

void TestConcurrentAudioRecoveryState() {
  AudioRecoveryState state;
  const auto start = AudioRecoveryState::Clock::time_point{};
  state.SetFileLoaded(true);
  std::atomic<bool> begin{false};

  std::thread resume([&]() {
    while (!begin.load(std::memory_order_acquire)) {
    }
    for (int i = 0; i < 1000; ++i) state.RequestResume();
  });
  std::thread device([&]() {
    while (!begin.load(std::memory_order_acquire)) {
    }
    for (int i = 0; i < 1000; ++i) {
      state.SetCurrentAudioOutputNull(true, start);
      state.OnAudioDeviceListChanged(start);
    }
  });
  std::thread timer([&]() {
    while (!begin.load(std::memory_order_acquire)) {
    }
    for (int i = 0; i < 1000; ++i) {
      const auto action = state.NextReload(start + std::chrono::hours(1));
      if (action.reason != AudioReloadReason::kNone) {
        state.CompleteReload(action.request_generation);
      }
    }
  });

  begin.store(true, std::memory_order_release);
  resume.join();
  device.join();
  timer.join();
  state.SetFileLoaded(false);
  assert(!state.HasPendingWork());
}

void TestFileBoundaryRestartsNullRecoveryOnlyAfterLoad() {
  AudioRecoveryState state;
  const auto start = AudioRecoveryState::Clock::time_point{};
  state.SetFileLoaded(true, start);
  assert(state.SetCurrentAudioOutputNull(true, start) == AudioOutputTransition::kFellBackToNull);
  assert(state.HasPendingWork());

  state.SetFileLoaded(false, start + std::chrono::milliseconds(100));
  assert(!state.HasPendingWork());
  assert(!state.OnAudioDeviceListChanged(start + std::chrono::milliseconds(200)));

  state.SetFileLoaded(true, start + std::chrono::milliseconds(300));
  assert(state.HasPendingWork());
  assert(state.NextReload(start + std::chrono::milliseconds(799)).reason == AudioReloadReason::kNone);
  const auto retry = state.NextReload(start + std::chrono::milliseconds(800));
  assert(retry.reason == AudioReloadReason::kNullFallback);
  assert(retry.attempt == 1);
}

void TestNullFallbackRecoverySchedule() {
  AudioRecoveryState state;
  const auto start = AudioRecoveryState::Clock::time_point{};
  state.SetFileLoaded(true);
  assert(state.SetCurrentAudioOutputNull(true, start) == AudioOutputTransition::kFellBackToNull);

  auto action = state.NextReload(start + std::chrono::milliseconds(500));
  assert(action.reason == AudioReloadReason::kNullFallback);
  assert(action.attempt == 1);
  assert(state.CompleteReload(action.request_generation));

  action = state.NextReload(start + std::chrono::milliseconds(1000));
  assert(action.reason == AudioReloadReason::kNullFallback);
  assert(action.attempt == 2);
  assert(state.CompleteReload(action.request_generation));

  action = state.NextReload(start + std::chrono::milliseconds(2000));
  assert(action.reason == AudioReloadReason::kNullFallback);
  assert(action.attempt == 3);
  assert(state.CompleteReload(action.request_generation));

  action = state.NextReload(start + std::chrono::milliseconds(4000));
  assert(action.reason == AudioReloadReason::kNullFallback);
  assert(action.attempt == 4);
  assert(state.CompleteReload(action.request_generation));

  action = state.NextReload(start + std::chrono::milliseconds(8000));
  assert(action.reason == AudioReloadReason::kNullFallback);
  assert(action.attempt == 5);
  assert(action.exhausted);
  assert(state.CompleteReload(action.request_generation));
  assert(!state.HasPendingWork());

  assert(state.OnAudioDeviceListChanged(start + std::chrono::milliseconds(9000)));
  action = state.NextReload(start + std::chrono::milliseconds(9250));
  assert(action.reason == AudioReloadReason::kNullFallback);
  assert(action.attempt == 1);
  assert(state.CompleteReload(action.request_generation));

  assert(
      state.SetCurrentAudioOutputNull(false, start + std::chrono::milliseconds(9300)) ==
      AudioOutputTransition::kRecovered);
  assert(!state.HasPendingWork());
}

void TestUnloadedResumeIsConsumed() {
  AudioRecoveryState state;
  const auto start = AudioRecoveryState::Clock::time_point{};

  state.RequestResume();
  assert(!state.HasPendingWork());
  assert(state.NextReload(start + std::chrono::hours(1)).reason == AudioReloadReason::kNone);

  state.SetFileLoaded(true, start);
  assert(!state.HasPendingWork());
}

void TestStaleReloadCompletionCannotClearCurrentRequest() {
  AudioRecoveryState state;
  const auto start = AudioRecoveryState::Clock::time_point{};
  state.SetFileLoaded(true, start);
  assert(state.SetCurrentAudioOutputNull(true, start) == AudioOutputTransition::kFellBackToNull);
  const auto old_request = state.NextReload(start + std::chrono::milliseconds(500));
  assert(old_request.reason == AudioReloadReason::kNullFallback);

  state.SetFileLoaded(false, start + std::chrono::milliseconds(600));
  state.SetFileLoaded(true, start + std::chrono::milliseconds(700));
  const auto current_request = state.NextReload(start + std::chrono::milliseconds(1200));
  assert(current_request.reason == AudioReloadReason::kNullFallback);
  assert(current_request.request_generation != old_request.request_generation);

  assert(!state.CompleteReload(old_request.request_generation));
  assert(state.NextReload(start + std::chrono::hours(1)).reason == AudioReloadReason::kNone);
  assert(state.CompleteReload(current_request.request_generation));
}

// Renders the shared node walk into text so its bounds can be asserted on
// every platform, without a platform value type in the way.
struct TextNodeBuilder {
  using Value = std::string;
  using ListBuilder = std::string;
  using MapBuilder = std::string;

  static Value Null() { return "null"; }
  static Value Bool(bool value) { return value ? "true" : "false"; }
  static Value Int(int64_t value) { return std::to_string(value); }
  static Value Double(double value) { return std::to_string(value); }
  static Value String(const char* value, size_t length) { return "'" + std::string(value, length) + "'"; }

  static ListBuilder NewList() { return std::string("["); }
  static void Append(ListBuilder& list, Value value) { list += value + ","; }
  static Value FinishList(ListBuilder list) { return list + "]"; }

  static MapBuilder NewMap() { return std::string("{"); }
  static void Insert(MapBuilder& map, const char* key, size_t key_length, Value value) {
    map += std::string(key, key_length) + ":" + value + ",";
  }
  static Value FinishMap(MapBuilder map) { return map + "}"; }
  static void AbandonMap(MapBuilder& map) { map += "<abandoned>"; }
};

void TestNodeConversionBounds() {
  using plezy::mpv_common::ConvertNode;
  using plezy::mpv_common::NodeConversionBudget;

  char value[] = "hello";
  mpv_node text{};
  text.format = MPV_FORMAT_STRING;
  text.u.string = value;
  assert(ConvertNode<TextNodeBuilder>(&text) == "'hello'");

  // Missing storage is never trusted: no node, no string, no list.
  assert(ConvertNode<TextNodeBuilder>(nullptr) == "null");
  text.u.string = nullptr;
  assert(ConvertNode<TextNodeBuilder>(&text) == "null");

  mpv_node array{};
  array.format = MPV_FORMAT_NODE_ARRAY;
  array.u.list = nullptr;
  assert(ConvertNode<TextNodeBuilder>(&array) == "null");

  // Neither a negative nor an implausible length reaches the builder.
  mpv_node entry{};
  entry.format = MPV_FORMAT_INT64;
  entry.u.int64 = 7;
  mpv_node_list negative{-1, &entry, nullptr};
  array.u.list = &negative;
  assert(ConvertNode<TextNodeBuilder>(&array) == "null");
  mpv_node_list oversized{plezy::mpv_common::kMaxNodeEntries + 1, &entry, nullptr};
  array.u.list = &oversized;
  assert(ConvertNode<TextNodeBuilder>(&array) == "null");

  mpv_node_list single{1, &entry, nullptr};
  array.u.list = &single;
  assert(ConvertNode<TextNodeBuilder>(&array) == "[7,]");

  // A map with a null key is voided rather than half-converted.
  char* missing_key[] = {nullptr};
  mpv_node_list keyless{1, &entry, missing_key};
  mpv_node map{};
  map.format = MPV_FORMAT_NODE_MAP;
  map.u.list = &keyless;
  assert(ConvertNode<TextNodeBuilder>(&map) == "null");

  // Depth, entry, and byte budgets each stop the walk.
  std::vector<mpv_node> chain(plezy::mpv_common::kMaxNodeDepth + 1);
  std::vector<mpv_node_list> links(chain.size());
  chain.back() = entry;
  for (size_t i = chain.size() - 1; i > 0; --i) {
    links[i - 1] = mpv_node_list{1, &chain[i], nullptr};
    chain[i - 1].format = MPV_FORMAT_NODE_ARRAY;
    chain[i - 1].u.list = &links[i - 1];
  }
  assert(ConvertNode<TextNodeBuilder>(&chain[0]).find('7') == std::string::npos);

  NodeConversionBudget entries{2, 1024};
  assert(ConvertNode<TextNodeBuilder>(&array, 0, &entries) == "[7,]");
  assert(entries.remaining_entries == 0);
  assert(ConvertNode<TextNodeBuilder>(&array, 0, &entries) == "null");

  NodeConversionBudget bytes{8, 4};
  text.u.string = value;
  assert(ConvertNode<TextNodeBuilder>(&text, 0, &bytes) == "null");
  assert(bytes.remaining_bytes == 4);
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
  TestConcurrentRequestCompletion();
  TestSetPropertyResultContract();
  TestPropertyObservationRegistry();
  TestConcurrentPropertyObservationRegistry();
  TestResumeRecoverySchedule();
  TestConcurrentAudioRecoveryState();
  TestNullFallbackRecoverySchedule();
  TestFileBoundaryRestartsNullRecoveryOnlyAfterLoad();
  TestUnloadedResumeIsConsumed();
  TestStaleReloadCompletionCannotClearCurrentRequest();
  TestNodeConversionBounds();
  TestHdrHelpers();
  return 0;
}
