// Host regression test: compile with secure_storage.cc and SQLite, without the
// Flutter engine or LG logging runtime. No production database is accessed.
#include "secure_storage.h"
#include "log.h"

#include <atomic>
#include <cassert>
#include <cstdlib>
#include <filesystem>
#include <iostream>
#include <thread>

Log::Log(uint32_t level, const std::string& tag) : level_(level), tag_(tag) {}
Log::~Log() {}

namespace {
void Race(const SecureStorage::Row& expected) {
  static int generation = 0;
  const auto suffix = std::to_string(++generation);
  std::atomic<int> ready{0};
  std::atomic<int> stored{0};
  std::atomic<int> conflicts{0};
  auto compete = [&](const char* value) {
    SecureStorage db;
    SecureStorage::Row loaded;
    assert(db.Load(&loaded));
    assert(loaded.keys == expected.keys && loaded.datas == expected.datas);
    ready++;
    while (ready.load() != 2) std::this_thread::yield();
    const auto next = std::string(value) + suffix;
    const auto result = db.CompareAndStore(expected, next, next);
    assert(result.has_value());
    if (*result) stored++; else conflicts++;
  };
  std::thread a(compete, "first");
  std::thread b(compete, "second");
  a.join();
  b.join();
  assert(stored == 1 && conflicts == 1);
}
}  // namespace

int main() {
  char pattern[] = "/tmp/plezy-webos-storage-XXXXXX";
  const char* temp = mkdtemp(pattern);
  assert(temp);
  setenv("FLUTTER_APPDATA_HOME", temp, 1);
  setenv("FLUTTER_APP_ID", "test", 1);
  {
    SecureStorage db;
    SecureStorage::Row empty;
    assert(db.Load(&empty));
    assert(!empty.keys && !empty.datas);
    Race(empty);  // Concurrent first use must create exactly one row.
    SecureStorage::Row current;
    assert(db.Load(&current));
    assert(current.keys == current.datas && current.keys.has_value());
    assert(db.CompareAndStore(empty, "stale", "stale") == false);
    Race(current);  // Concurrent overwrite must reject the stale writer.
    assert(db.Load(&current));

    sqlite3* raw = nullptr;
    const auto file = std::filesystem::path(temp) / "test" / "flutter_secure_storage.db";
    assert(sqlite3_open(file.c_str(), &raw) == SQLITE_OK);
    sqlite3_stmt* count = nullptr;
    assert(sqlite3_prepare_v2(raw, "SELECT COUNT(*) FROM SecureStorage", -1, &count, nullptr) == SQLITE_OK);
    assert(sqlite3_step(count) == SQLITE_ROW);
    assert(sqlite3_column_int(count, 0) == 1);
    sqlite3_finalize(count);
    assert(sqlite3_exec(raw, "CREATE TRIGGER deny_write BEFORE UPDATE ON SecureStorage "
      "BEGIN SELECT RAISE(ABORT, 'injected write failure'); END", nullptr, nullptr, nullptr) == SQLITE_OK);
    assert(!db.CompareAndStore(current, "broken", "broken").has_value());
    SecureStorage::Row after;
    assert(db.Load(&after));
    assert(after.keys == current.keys && after.datas == current.datas);
    assert(sqlite3_exec(raw, "DROP TRIGGER deny_write", nullptr, nullptr, nullptr) == SQLITE_OK);
    assert(db.CompareAndStore(current, "recovered", "recovered") == true);
    assert(sqlite3_exec(raw, "DROP TABLE SecureStorage", nullptr, nullptr, nullptr) == SQLITE_OK);
    assert(!db.Load(&after));  // A read failure must never report an absent row.
    sqlite3_close(raw);
  }
  {
    SecureStorage db;
    SecureStorage::Row row;
    unsetenv("FLUTTER_APPDATA_HOME");
    assert(!db.Load(&row));
    setenv("FLUTTER_APPDATA_HOME", temp, 1);
    assert(db.Load(&row));  // Failed open is retryable on the same object.
  }
  std::filesystem::remove_all(temp);
  std::cout << "webOS native storage: CAS races, rollback, read errors and recovery passed\n";
}
