#include <libsecret/secret.h>

class FHashTable {
  GHashTable *m_hashTable;
  public:

  FHashTable() { m_hashTable = g_hash_table_new_full(g_str_hash, nullptr, g_free, g_free); }

  GHashTable* getGHashTable(){
    return m_hashTable;
  }

  bool insert(const char *key, const char *value) {
    return g_hash_table_insert(m_hashTable, (void *)g_strdup(key), (void *)g_strdup(value));
  }

  const char *get(const char *key) {
    return (const char *)g_hash_table_lookup(m_hashTable, (void *)key);
  }

  bool contains(const char *key) {
    return g_hash_table_contains(m_hashTable, (void *)key);
  }

  bool remove(const char *key) {
    return g_hash_table_remove(m_hashTable, (void *)key);
  }

  void removeAll() { g_hash_table_remove_all(m_hashTable); }

  ~FHashTable() {
    g_hash_table_destroy(m_hashTable);
  }
};