# Plezy Linux credential storage

Vendored from `flutter_secure_storage_linux` 3.0.3 (BSD-3-Clause) for compatibility with `flutter_secure_storage` 10.3.4 / win32 5.x.

Local fixes: keep `SecretSchema.name` valid after changing the label; isolate every key using a Secret Service attribute so concurrent writes to different vault key IDs cannot replace each other. This application uses only `read` and `write`; aggregate `readAll` / `deleteAll` are intentionally not used for these isolated entries. Locked/unavailable keyring errors propagate; there is no plaintext fallback. libsecret's portal backend remains available in Flatpak.
