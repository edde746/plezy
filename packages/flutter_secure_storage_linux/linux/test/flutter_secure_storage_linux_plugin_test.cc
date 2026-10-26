#include <gtest/gtest.h>
#include <unistd.h>

#include <cstdlib>
#include <memory>
#include <string>

#include "include/Secret.hpp"

namespace flutter_secure_storage_linux {
namespace test {

class SecretStorageTest : public ::testing::Test {
 protected:
  void SetUp() override {
    storage_ = std::make_unique<SecretStorage>("fss_native_test");
    storage_->addAttribute("account", "fss_native_test.secureStorage");
    storage_->deleteKeyring();
  }

  void TearDown() override { storage_->deleteKeyring(); }

  std::unique_ptr<SecretStorage> storage_;
};

// Validates that a string contains only valid UTF-8 sequences.
static bool isValidUtf8(const std::string& s) {
  const unsigned char* bytes = reinterpret_cast<const unsigned char*>(s.data());
  size_t i = 0;
  while (i < s.size()) {
    unsigned char c = bytes[i];
    int trailing = 0;
    if (c <= 0x7F) {
      ++i;
      continue;
    } else if ((c & 0xE0) == 0xC0) {
      trailing = 1;
    } else if ((c & 0xF0) == 0xE0) {
      trailing = 2;
    } else if ((c & 0xF8) == 0xF0) {
      trailing = 3;
    } else {
      return false;
    }
    ++i;
    for (int t = 0; t < trailing; ++t, ++i) {
      if (i >= s.size() || (bytes[i] & 0xC0) != 0x80) return false;
    }
  }
  return true;
}

TEST_F(SecretStorageTest, WriteAndReadRoundTrip) {
  ASSERT_TRUE(storage_->addItem("key1", "value1"));
  EXPECT_EQ(storage_->getItem("key1"), "value1");
}

TEST_F(SecretStorageTest, ReadMissingKeyReturnsEmpty) {
  EXPECT_EQ(storage_->getItem("nonexistent"), "");
}

TEST_F(SecretStorageTest, OverwriteReturnsNewValue) {
  storage_->addItem("k", "first");
  storage_->addItem("k", "second");
  EXPECT_EQ(storage_->getItem("k"), "second");
}

TEST_F(SecretStorageTest, ContainsKeyTrueAfterWrite) {
  storage_->addItem("k", "v");
  nlohmann::json data = storage_->readFromKeyring();
  EXPECT_TRUE(data.contains("k"));
}

TEST_F(SecretStorageTest, ContainsKeyFalseForMissing) {
  nlohmann::json data = storage_->readFromKeyring();
  EXPECT_FALSE(data.contains("nonexistent"));
}

TEST_F(SecretStorageTest, DeleteRemovesKey) {
  storage_->addItem("k", "v");
  storage_->deleteItem("k");
  EXPECT_EQ(storage_->getItem("k"), "");
  nlohmann::json data = storage_->readFromKeyring();
  EXPECT_FALSE(data.contains("k"));
}

TEST_F(SecretStorageTest, DeleteNonexistentIsNoOp) {
  EXPECT_NO_THROW(storage_->deleteItem("never_written"));
}

TEST_F(SecretStorageTest, DeleteAllClearsStorage) {
  storage_->addItem("a", "1");
  storage_->addItem("b", "2");
  storage_->deleteKeyring();
  EXPECT_EQ(storage_->getItem("a"), "");
  EXPECT_EQ(storage_->getItem("b"), "");
}

TEST_F(SecretStorageTest, ReadAllReturnsAllEntries) {
  storage_->addItem("k1", "v1");
  storage_->addItem("k2", "v2");
  nlohmann::json data = storage_->readFromKeyring();
  EXPECT_EQ(data["k1"], "v1");
  EXPECT_EQ(data["k2"], "v2");
}

// deleteKeyring() must persist "{}" not "null". Storing "null" causes
// readFromKeyring() to return a null JSON value, which is undefined to
// iterate and inconsistent across nlohmann versions.
TEST_F(SecretStorageTest, DeleteKeyringStoresEmptyObjectNotNull) {
  storage_->addItem("k", "v");
  storage_->deleteKeyring();

  nlohmann::json data = storage_->readFromKeyring();
  EXPECT_FALSE(data.is_null()) << "got: " << data.dump();
  EXPECT_TRUE(data.is_object());
  EXPECT_EQ(data.size(), 0u);
}

TEST_F(SecretStorageTest, IteratingItemsAfterDeleteKeyringIsEmptyAndSafe) {
  storage_->addItem("k", "v");
  storage_->deleteKeyring();

  nlohmann::json data = storage_->readFromKeyring();
  int count = 0;
  ASSERT_NO_THROW({
    for (const auto& item : data.items()) {
      (void)item;
      ++count;
    }
  });
  EXPECT_EQ(count, 0);
}

TEST_F(SecretStorageTest, WriteAndReadAfterDeleteKeyringIsCorrect) {
  storage_->addItem("before", "old");
  storage_->deleteKeyring();

  ASSERT_TRUE(storage_->addItem("after", "new"));
  EXPECT_EQ(storage_->getItem("after"), "new");
  EXPECT_EQ(storage_->getItem("before"), "");

  nlohmann::json data = storage_->readFromKeyring();
  EXPECT_TRUE(data.is_object());
  EXPECT_EQ(data.size(), 1u) << "got: " << data.dump();
}

TEST_F(SecretStorageTest, StoredValuesAreValidUtf8) {
  const std::string key = "utf8_key";
  const std::string value = "valid-utf8-\xC3\xA9-value";
  storage_->addItem(key.c_str(), value.c_str());

  const std::string result = storage_->getItem(key.c_str());
  EXPECT_EQ(result, value);
  EXPECT_TRUE(isValidUtf8(result));
  EXPECT_TRUE(isValidUtf8(key));
}

// Provides a path that exists (stand-in for /.flatpak-info) and one that does
// not, without depending on platform-specific files.
class ShouldSkipKeyringWarmupTest : public ::testing::Test {
 protected:
  void SetUp() override {
    char tmpl[] = "/tmp/fss_flatpak_info_XXXXXX";
    int fd = mkstemp(tmpl);
    ASSERT_NE(fd, -1);
    close(fd);
    existing_path_ = tmpl;
  }

  void TearDown() override { unlink(existing_path_.c_str()); }

  std::string existing_path_;
  static constexpr const char* kMissingPath = "/nonexistent/.flatpak-info";
};

TEST_F(ShouldSkipKeyringWarmupTest, NotSandboxedRunsWarmup) {
  EXPECT_FALSE(shouldSkipKeyringWarmup(kMissingPath, nullptr, nullptr, false));
  EXPECT_FALSE(shouldSkipKeyringWarmup(kMissingPath, nullptr, nullptr, true));
}

TEST_F(ShouldSkipKeyringWarmupTest, SandboxedWithoutServiceSkips) {
  EXPECT_TRUE(shouldSkipKeyringWarmup(existing_path_.c_str(), nullptr, nullptr,
                                      false));
  EXPECT_TRUE(shouldSkipKeyringWarmup(kMissingPath, "my-snap", nullptr, false));
}

TEST_F(ShouldSkipKeyringWarmupTest, SandboxedWithServiceRunsWarmup) {
  EXPECT_FALSE(shouldSkipKeyringWarmup(existing_path_.c_str(), nullptr, nullptr,
                                       true));
  EXPECT_FALSE(shouldSkipKeyringWarmup(kMissingPath, "my-snap", nullptr, true));
}

TEST_F(ShouldSkipKeyringWarmupTest, EmptySnapNameIsNotSandboxed) {
  EXPECT_FALSE(shouldSkipKeyringWarmup(kMissingPath, "", nullptr, false));
}

TEST_F(ShouldSkipKeyringWarmupTest, SecretBackendFileForcesSkip) {
  EXPECT_TRUE(shouldSkipKeyringWarmup(kMissingPath, nullptr, "file", true));
}

TEST_F(ShouldSkipKeyringWarmupTest, SecretBackendServiceForcesWarmup) {
  EXPECT_FALSE(
      shouldSkipKeyringWarmup(existing_path_.c_str(), "my-snap", "service",
                              false));
}

TEST_F(ShouldSkipKeyringWarmupTest, UnrecognizedSecretBackendFallsBackToDetection) {
  EXPECT_TRUE(shouldSkipKeyringWarmup(existing_path_.c_str(), nullptr,
                                      "something-else", false));
  EXPECT_FALSE(shouldSkipKeyringWarmup(kMissingPath, nullptr, "something-else",
                                       false));
}

// Exercises the real D-Bus call against whatever session bus this process is
// connected to. Skipped unless CI points FSS_EXPECT_SECRET_SERVICE_REACHABLE
// at a specific bus policy (see the "Verify Secret Service Reachability"
// steps in ci.yml), since the answer otherwise depends on the environment.
TEST(SecretServiceOnSessionBusTest, MatchesConfiguredBusPolicy) {
  const char *expected = g_getenv("FSS_EXPECT_SECRET_SERVICE_REACHABLE");
  if (expected == nullptr) {
    GTEST_SKIP() << "set FSS_EXPECT_SECRET_SERVICE_REACHABLE=0|1 to run this "
                    "against a specific D-Bus policy";
  }
  const bool want = std::string(expected) == "1";
  EXPECT_EQ(secretServiceOnSessionBus(), want);
}

}  // namespace test
}  // namespace flutter_secure_storage_linux
