#include "include/flutter_secure_storage_linux/flutter_secure_storage_linux_plugin.h"
#include "include/Secret.hpp"
#include "include/json.hpp"

#include <cstring>
#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <libsecret/secret.h>
#include <sys/utsname.h>

#define flutter_secure_storage_linux_plugin(obj)                                     \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), flutter_secure_storage_linux_plugin_get_type(), \
                              FlutterSecureStorageLinuxPlugin))

struct _FlutterSecureStorageLinuxPlugin
{
  GObject parent_instance;
};

G_DEFINE_TYPE(FlutterSecureStorageLinuxPlugin, flutter_secure_storage_linux_plugin,
              g_object_get_type())

static SecretStorage keyring;
void deleteIt(const gchar *key) { keyring.deleteItem(key); }
void deleteAll() { keyring.deleteKeyring(); }
void write(const gchar *key, const gchar *value)
{
  keyring.addItem(key, value);
}

FlValue *read(const gchar *key)
{
  auto str = keyring.getItem(key);
  if (str == "")
  {
    return nullptr;
  }
  return fl_value_new_string(str.c_str());
}

FlValue *readAll()
{
  FlValue *result = fl_value_new_map();
  nlohmann::json data = keyring.readFromKeyring();
  for (auto each : data.items())
  {
    fl_value_set_string_take(result, each.key().c_str(),
                             fl_value_new_string(std::string(each.value()).c_str()));
  }
  return result;
}

FlValue* containsKey(const gchar* key) {
  nlohmann::json data = keyring.readFromKeyring();
  return fl_value_new_bool(data.contains(key));
}

// Called when a method call is received from Flutter.
static void flutter_secure_storage_linux_plugin_handle_method_call(
    FlutterSecureStorageLinuxPlugin *self, FlMethodCall *method_call)
{
  g_autoptr(FlMethodResponse) response = nullptr;

  const gchar *method = fl_method_call_get_name(method_call);
  FlValue *args = fl_method_call_get_args(method_call);

  if (fl_value_get_type(args) != FL_VALUE_TYPE_MAP)
  {
    response = FL_METHOD_RESPONSE(fl_method_error_response_new(
        "Bad arguments", "args given to function is not a map", nullptr));
  }
  else
  {
    FlValue *key = fl_value_lookup_string(args, "key");
    FlValue *value = fl_value_lookup_string(args, "value");
    const gchar *keyString =
        key == nullptr ? nullptr : fl_value_get_string(key);
    const gchar *valueString =
        value == nullptr ? nullptr : fl_value_get_string(value);

    // Keep independent vault keys in independent entries; a shared JSON
    // read/modify/write would lose keys across processes or Flutter engines.
    keyring.addAttribute("entry", keyString == nullptr ? "" : keyString);

    try
    {
      if (strcmp(method, "write") == 0)
      {
        if (!keyString || !valueString)
        {
          response = FL_METHOD_RESPONSE(fl_method_error_response_new(
              "Bad arguments", "Key or Value was null", nullptr));
        }
        else
        {
          write(keyString, valueString);
          response =
              FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
        }
      }
      else if (strcmp(method, "read") == 0)
      {
        if (!keyString)
        {
          response = FL_METHOD_RESPONSE(fl_method_error_response_new(
              "Bad arguments", "Key is null", nullptr));
        }
        else
        {
          g_autoptr(FlValue) result = read(keyString);
          response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
        }
      }
      else if (strcmp(method, "readAll") == 0)
      {
        g_autoptr(FlValue) result = readAll();
        response =
            FL_METHOD_RESPONSE(fl_method_success_response_new(result));
      }
      else if (strcmp(method, "delete") == 0)
      {
        if (!keyString)
        {
          response = FL_METHOD_RESPONSE(fl_method_error_response_new(
              "Bad arguments", "Key is null", nullptr));
        }
        else
        {
          deleteIt(keyString);
          response =
              FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
        }
      }
      else if (strcmp(method, "deleteAll") == 0)
      {
        deleteAll();
        response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
      }
      else if (strcmp(method, "containsKey") == 0) {
        if (!keyString) {
           response = FL_METHOD_RESPONSE(fl_method_error_response_new(
              "Bad arguments", "Key is null", nullptr));
        } else {
          g_autoptr(FlValue) result = containsKey(keyString);
          response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
        }
      }
      else
      {
        response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
      }
    }
    catch (const gchar *e)
    {
      const bool is_locked = (strcmp(e, "KeyringLocked") == 0);
      g_autofree gchar *safe = g_utf8_make_valid(e, -1);
      g_warning("libsecret_error: %s", safe);
      response = FL_METHOD_RESPONSE(fl_method_error_response_new(
          is_locked ? "KeyringLocked" : "Libsecret error", safe, nullptr));
    }
    catch (const LibsecretError& e)
    {
      g_autofree gchar *safe = g_utf8_make_valid(e.what(), -1);
      g_warning("libsecret_error: %s", safe);
      response = FL_METHOD_RESPONSE(fl_method_error_response_new(
          e.code(), safe, nullptr));
    }
    catch (const std::exception& e)
    {
      g_autofree gchar *safe = g_utf8_make_valid(e.what(), -1);
      response = FL_METHOD_RESPONSE(fl_method_error_response_new(
          "StorageError", safe, nullptr));
    }
    fl_method_call_respond(method_call, response, nullptr);
  }
}

static void flutter_secure_storage_linux_plugin_dispose(GObject *object)
{
  G_OBJECT_CLASS(flutter_secure_storage_linux_plugin_parent_class)->dispose(object);
}

static void flutter_secure_storage_linux_plugin_class_init(
    FlutterSecureStorageLinuxPluginClass *klass)
{
  G_OBJECT_CLASS(klass)->dispose = flutter_secure_storage_linux_plugin_dispose;
}

static void
flutter_secure_storage_linux_plugin_init(FlutterSecureStorageLinuxPlugin *self) {}

static void method_call_cb(FlMethodChannel *channel, FlMethodCall *method_call,
                           gpointer user_data)
{
  FlutterSecureStorageLinuxPlugin *plugin = flutter_secure_storage_linux_plugin(user_data);
  flutter_secure_storage_linux_plugin_handle_method_call(plugin, method_call);
}

void flutter_secure_storage_linux_plugin_register_with_registrar(
    FlPluginRegistrar *registrar)
{
  FlutterSecureStorageLinuxPlugin *plugin = flutter_secure_storage_linux_plugin(
      g_object_new(flutter_secure_storage_linux_plugin_get_type(), nullptr));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel = fl_method_channel_new(
      fl_plugin_registrar_get_messenger(registrar),
      "plugins.it_nomads.com/flutter_secure_storage", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(
      channel, method_call_cb, g_object_ref(plugin), g_object_unref);
  g_autofree gchar *label =
      g_strdup_printf("%s/FlutterSecureStorage", APPLICATION_ID);
  g_autofree gchar *account = g_strdup_printf("%s.secureStorage", APPLICATION_ID);
  keyring.setLabel(label);
  keyring.addAttribute("account", account);
  g_object_unref(plugin);
}
