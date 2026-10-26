#include "FHashTable.hpp"
#include "json.hpp"
#include <gio/gio.h>
#include <libsecret/secret.h>
#include <memory>
#include <stdexcept>
#include <string>

#define secret_autofree _GLIB_CLEANUP(secret_cleanup_free)
static inline void secret_cleanup_free(gchar **p) { secret_password_free(*p); }

// True when the process runs inside a Flatpak or Snap sandbox, where libsecret's
// Simple API (secret_password_*) can route to the portal file backend instead of
// org.freedesktop.secrets.
inline bool isSandboxedContainer(const char *flatpakInfoPath,
                                 const char *snapName) {
  if (snapName != nullptr && snapName[0] != '\0') {
    return true;
  }
  return flatpakInfoPath != nullptr &&
         g_file_test(flatpakInfoPath, G_FILE_TEST_EXISTS);
}

// Whether org.freedesktop.secrets currently has an owner on the session bus.
// A single NameHasOwner call to the bus daemon, far cheaper than
// secret_service_get_sync (no session negotiation, no collection load).
inline bool secretServiceOnSessionBus() {
  g_autoptr(GError) err = nullptr;
  g_autoptr(GDBusConnection) bus =
      g_bus_get_sync(G_BUS_TYPE_SESSION, nullptr, &err);
  if (bus == nullptr) {
    return false;
  }

  g_autoptr(GVariant) reply = g_dbus_connection_call_sync(
      bus, "org.freedesktop.DBus", "/org/freedesktop/DBus",
      "org.freedesktop.DBus", "NameHasOwner",
      g_variant_new("(s)", "org.freedesktop.secrets"), G_VARIANT_TYPE("(b)"),
      G_DBUS_CALL_FLAGS_NONE, /*timeout_msec=*/1000, nullptr, &err);
  if (reply == nullptr) {
    return false;
  }

  gboolean has_owner = FALSE;
  g_variant_get(reply, "(b)", &has_owner);
  return has_owner;
}

// True when libsecret's Simple API is NOT backed by org.freedesktop.secrets for
// this process, so warmupKeyring (which talks to the Secret Service directly)
// must be skipped.
//
// SECRET_BACKEND is libsecret's own explicit override. Otherwise only a sandbox
// can redirect the Simple API to the portal file backend, and even then only
// when the Secret Service is genuinely unreachable: a snap with the
// password-manager-service interface connected, or a flatpak granted
// --talk-name=org.freedesktop.secrets, still uses the real service, and
// warmupKeyring's missing-alias and lock guards are meaningful there.
inline bool shouldSkipKeyringWarmup(const char *flatpakInfoPath,
                                    const char *snapName,
                                    const char *secretBackendEnv,
                                    bool serviceOnBus) {
  if (secretBackendEnv != nullptr) {
    const std::string preference(secretBackendEnv);
    if (preference == "file") {
      return true;
    }
    if (preference == "service") {
      return false;
    }
  }

  return isSandboxedContainer(flatpakInfoPath, snapName) && !serviceOnBus;
}

inline bool shouldSkipKeyringWarmup() {
  // Neither the sandbox status nor the bus name changes meaningfully over the
  // process lifetime for this purpose, so decide once.
  static const bool skip = shouldSkipKeyringWarmup(
      "/.flatpak-info", g_getenv("SNAP_NAME"), g_getenv("SECRET_BACKEND"),
      secretServiceOnSessionBus());
  return skip;
}

class LibsecretError : public std::runtime_error {
  std::string error_code;

  static const char *codeFromGError(const GError *error) {
    if (error == nullptr) {
      return "Libsecret error";
    }

    if (g_error_matches(error, SECRET_ERROR, SECRET_ERROR_IS_LOCKED)) {
      return "KeyringLocked";
    }

    if (g_error_matches(error, SECRET_ERROR, SECRET_ERROR_NO_SUCH_OBJECT)) {
      return "SecretNotFound";
    }

    return "Libsecret error";
  }

  static std::string messageWithContext(const char *context,
                                        const char *message) {
    if (message == nullptr) {
      return context == nullptr ? "Libsecret error" : context;
    }

    if (context == nullptr || context[0] == '\0') {
      return message;
    }

    std::string result(context);
    result += ": ";
    result += message;
    return result;
  }

public:
  explicit LibsecretError(const char *message)
      : LibsecretError("Libsecret error", message) {}

  LibsecretError(const char *code, const char *message)
      : std::runtime_error(
            message == nullptr
                ? (code == nullptr ? "Libsecret error" : code)
                : message),
        error_code(code == nullptr ? "Libsecret error" : code) {}

  LibsecretError(const char *context, const GError *error)
      : std::runtime_error(messageWithContext(
            context, error == nullptr ? nullptr : error->message)),
        error_code(codeFromGError(error)) {}

  const char *code() const { return error_code.c_str(); }
};

class SecretStorage {
  FHashTable m_attributes;
  std::string label;
  SecretSchema the_schema;

public:
  const char *getLabel() { return label.c_str(); }
  void setLabel(const char *label) {
    this->label = label;
    the_schema.name = this->label.c_str();
  }

  SecretStorage(const char *_label = "default") : label(_label) {
    the_schema = {label.c_str(),
                  SECRET_SCHEMA_NONE,
                  {
                      {"account", SECRET_SCHEMA_ATTRIBUTE_STRING},
                      {"entry", SECRET_SCHEMA_ATTRIBUTE_STRING},
                  }};
  }

  void addAttribute(const char *key, const char *value) {
    m_attributes.insert(key, value);
  }

  bool addItem(const char *key, const char *value) {
    nlohmann::json root = readFromKeyring();
    root[key] = value;
    return storeToKeyring(root);
  }

  std::string getItem(const char *key) {
    std::string result;
    nlohmann::json root = readFromKeyring();
    nlohmann::json value = root[key];
    if(value.is_string()){
      result = value.get<std::string>();
      return result;
    }
    return "";
  }

  void deleteItem(const char *key) {
    nlohmann::json root = readFromKeyring();
    if (!root.is_object() || !root.contains(key)) {
      return;
    }
    root.erase(key);
    storeToKeyring(root);
  }

  bool deleteKeyring() {
    if (!warmupKeyring()) {
      return true;
    }
    return this->storeToKeyring(nlohmann::json::object());
  }

  bool storeToKeyring(nlohmann::json value) {
    const std::string output = value.dump();
    g_autoptr(GError) err = nullptr;
    bool result = secret_password_storev_sync(
        &the_schema, m_attributes.getGHashTable(), nullptr, label.c_str(),
        output.c_str(), nullptr, &err);

    if (err) {
      throw LibsecretError("secret_password_storev_sync", err);
    }

    return result;
  }

  nlohmann::json readFromKeyring() {
    nlohmann::json value = nlohmann::json::object();
    g_autoptr(GError) err = nullptr;

    if (!warmupKeyring()) {
      return value;
    }

    secret_autofree gchar *result = secret_password_lookupv_sync(
        &the_schema, m_attributes.getGHashTable(), nullptr, &err);

    if (err) {
      throw LibsecretError("secret_password_lookupv_sync", err);
    }
    if(result != NULL && strcmp(result, "") != 0){
      value = nlohmann::json::parse(result);
    }
    return value;
  }

private:
  // Ensures the default keyring is accessible and distinguishes a locked
  // collection from other storage errors. A missing default collection is
  // the normal state of a fresh profile, not a locked keyring. Do not load
  // all collections here: some Secret Service backends fail when an
  // unrelated stale item exists in another collection.
  //
  // Skipped when libsecret's Simple API is on the portal file backend (see
  // shouldSkipKeyringWarmup): that backend has no collections to alias or lock,
  // so the guards below don't apply, and secret_password_lookupv_sync /
  // storev_sync still surface a locked backing store as KeyringLocked.
  bool warmupKeyring() {
    if (shouldSkipKeyringWarmup()) {
      return true;
    }

    g_autoptr(GError) err = nullptr;

    SecretService *service = secret_service_get_sync(
        SECRET_SERVICE_OPEN_SESSION, nullptr, &err);

    if (!service) {
      throw LibsecretError("secret_service_get_sync", err);
    }

    SecretCollection *collection = secret_collection_for_alias_sync(
        service, SECRET_COLLECTION_DEFAULT, SECRET_COLLECTION_NONE, nullptr, &err);

    if (!collection) {
      const bool missingDefaultCollection = err == nullptr;
      if (missingDefaultCollection) {
        g_autoptr(GError) searchError = nullptr;
        GList *matchingItems = secret_service_search_sync(
            service, &the_schema, m_attributes.getGHashTable(),
            SECRET_SEARCH_NONE, nullptr, &searchError);
        const bool hasMatchingItems = matchingItems != nullptr;
        if (matchingItems) {
          g_list_free_full(matchingItems, g_object_unref);
        }
        g_object_unref(service);

        // With no alias and no matching item this is a fresh profile. If data
        // exists elsewhere, fail closed before a write can create a second
        // default collection and orphan the original item.
        if (searchError) {
          throw LibsecretError("secret_service_search_sync", searchError);
        }
        if (hasMatchingItems) {
          throw LibsecretError("KeyringLocked", "KeyringLocked");
        }
        return false;
      }
      g_object_unref(service);
      throw LibsecretError("secret_collection_for_alias_sync", err);
    }

    if (!secret_collection_get_locked(collection)) {
      g_object_unref(collection);
      g_object_unref(service);
      return true;
    }

    GList *to_unlock = g_list_append(nullptr, collection);
    GList *unlocked_out = nullptr;
    gint n = secret_service_unlock_sync(service, to_unlock, nullptr, &unlocked_out, nullptr);
    g_list_free(to_unlock);
    if (unlocked_out) {
      g_list_free_full(unlocked_out, g_object_unref);
    }
    g_object_unref(collection);
    g_object_unref(service);

    if (n == 0) {
      throw LibsecretError("KeyringLocked", "KeyringLocked");
    }

    return true;
  }
};
