#!/usr/bin/env python3
"""Regenerates the fixtures the earlier-release import tests read.

Plezy's earlier releases left their data in a SQLite database written by Drift, a platform preference store and, on
Apple TV, a recovery image inside the user defaults. These fixtures are those files, built from the same schema and
encodings, so the importer's tests read real bytes:

- jvmTest resources `earlier-release/`: a schema-25 `plezy_downloads.db` in WAL mode with committed rows still in its
  `-wal`, a schema-16 database for the upgrade steps, Android's DataStore `preferences_pb` and legacy XML store, the
  desktop `shared_preferences.json` (current, pre-migration, a stale `.tmp`, a damaged copy, and a full store of an
  install upgraded in place that pairs with the schema-25 database) and a binary plist.
- commonTest `EarlierReleaseFixtureVectors.kt`: the vault key and AES-256-GCM vectors, encrypted here with the Python
  `cryptography` package, an implementation independent of the one under test, and the plist's tvOS recovery image.
- appleTest `EarlierReleasePlistFixture.kt`: the binary plist, base64, for the NSUserDefaults reader.

Run with a Python that has `cryptography` (python3 -m venv /tmp/plezy-fixtures-venv &&
/tmp/plezy-fixtures-venv/bin/pip install cryptography), from anywhere:
    /tmp/plezy-fixtures-venv/bin/python tools/earlier-release-fixtures/generate.py
Needs `plutil` (macOS). Every nonce and salt is fixed, so the same toolchain writes the same bytes.
"""

import base64
import hashlib
import json
import os
import plistlib
import shutil
import sqlite3
import struct
import subprocess
import tempfile

from cryptography.hazmat.primitives.ciphers.aead import AESGCM

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
RESOURCES = os.path.join(ROOT, 'shared', 'src', 'jvmTest', 'resources', 'earlier-release')
COMMON_TEST = os.path.join(ROOT, 'shared', 'src', 'commonTest', 'kotlin', 'com', 'edde746', 'plezy', 'importer')
APPLE_TEST = os.path.join(ROOT, 'shared', 'src', 'appleTest', 'kotlin', 'com', 'edde746', 'plezy', 'importer')

T = 1_700_000_000_000  # epoch ms every fixture timestamp is relative to

# ---------------------------------------------------------------------------------------------------------------
# Credential vault: AES-256-GCM, 12-byte nonce, 16-byte tag, no AAD; 'enc:v1:' + {"n","c","m"} (standard base64).

VAULT_KEY = hashlib.sha256(b'plezy flutter import fixture vault key').digest()
OTHER_KEY = hashlib.sha256(b'plezy flutter import fixture other key').digest()
VAULT_KEY_B64 = base64.b64encode(VAULT_KEY).decode()


def b64(data):
    return base64.b64encode(data).decode()


def dart_json(value):
    """jsonEncode's output for the plain values the fixtures hold: no spaces, non-ASCII verbatim."""
    return json.dumps(value, separators=(',', ':'), ensure_ascii=False)


def protect(plaintext, label, key=VAULT_KEY):
    nonce = hashlib.sha256(('nonce:' + label).encode()).digest()[:12]
    sealed = AESGCM(key).encrypt(nonce, plaintext.encode('utf-8'), None)
    return 'enc:v1:' + dart_json({'n': b64(nonce), 'c': b64(sealed[:-16]), 'm': b64(sealed[-16:])})


# ---------------------------------------------------------------------------------------------------------------
# Drift's schema 25, as `createAll()` writes it (sqlite_master of a fresh database, in creation order).

V25_TABLES = {
    'downloaded_media': 'CREATE TABLE "downloaded_media" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "server_id" TEXT NOT NULL, "client_scope_id" TEXT NULL, "rating_key" TEXT NOT NULL, "global_key" TEXT NOT NULL UNIQUE, "type" TEXT NOT NULL, "parent_rating_key" TEXT NULL, "grandparent_rating_key" TEXT NULL, "status" INTEGER NOT NULL, "progress" INTEGER NOT NULL DEFAULT 0, "total_bytes" INTEGER NULL, "downloaded_bytes" INTEGER NOT NULL DEFAULT 0, "video_file_path" TEXT NULL, "additional_part_paths" TEXT NULL, "saf_root_uri" TEXT NULL, "thumb_path" TEXT NULL, "downloaded_at" INTEGER NULL, "error_message" TEXT NULL, "retry_count" INTEGER NOT NULL DEFAULT 0, "bg_task_id" TEXT NULL, "media_index" INTEGER NOT NULL DEFAULT 0, "media_source_id" TEXT NULL, "library_id" TEXT NULL, "library_title" TEXT NULL);',
    'download_owners': 'CREATE TABLE "download_owners" ("profile_id" TEXT NOT NULL, "global_key" TEXT NOT NULL, "backend" TEXT NULL, "client_scope_id" TEXT NULL, "created_at" INTEGER NOT NULL, PRIMARY KEY ("profile_id", "global_key"));',
    'download_queue': 'CREATE TABLE "download_queue" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "media_global_key" TEXT NOT NULL UNIQUE, "priority" INTEGER NOT NULL DEFAULT 0, "added_at" INTEGER NOT NULL, "download_subtitles" INTEGER NOT NULL DEFAULT 1 CHECK ("download_subtitles" IN (0, 1)), "download_artwork" INTEGER NOT NULL DEFAULT 1 CHECK ("download_artwork" IN (0, 1)));',
    'api_cache': 'CREATE TABLE "api_cache" ("cache_key" TEXT NOT NULL, "data" TEXT NOT NULL, "cached_at" INTEGER NOT NULL DEFAULT (CAST(strftime(\'%s\', CURRENT_TIMESTAMP) AS INTEGER)), "pinned" INTEGER NOT NULL DEFAULT 0 CHECK ("pinned" IN (0, 1)), PRIMARY KEY ("cache_key"));',
    'offline_watch_progress': 'CREATE TABLE "offline_watch_progress" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "profile_id" TEXT NULL, "server_id" TEXT NOT NULL, "client_scope_id" TEXT NULL, "rating_key" TEXT NOT NULL, "global_key" TEXT NOT NULL, "action_type" TEXT NOT NULL, "view_offset" INTEGER NULL, "duration" INTEGER NULL, "should_mark_watched" INTEGER NOT NULL DEFAULT 0 CHECK ("should_mark_watched" IN (0, 1)), "created_at" INTEGER NOT NULL, "updated_at" INTEGER NOT NULL, "sync_attempts" INTEGER NOT NULL DEFAULT 0, "last_error" TEXT NULL);',
    'sync_rules': 'CREATE TABLE "sync_rules" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "profile_id" TEXT NOT NULL DEFAULT \'\', "server_id" TEXT NOT NULL, "rating_key" TEXT NOT NULL, "global_key" TEXT NOT NULL UNIQUE, "target_type" TEXT NOT NULL, "episode_count" INTEGER NOT NULL, "enabled" INTEGER NOT NULL DEFAULT 1 CHECK ("enabled" IN (0, 1)), "created_at" INTEGER NOT NULL, "last_executed_at" INTEGER NULL, "media_index" INTEGER NOT NULL DEFAULT 0, "download_filter" TEXT NOT NULL DEFAULT \'unwatched\', "include_specials" INTEGER NOT NULL DEFAULT 1 CHECK ("include_specials" IN (0, 1)), "download_links_initialized" INTEGER NOT NULL DEFAULT 0 CHECK ("download_links_initialized" IN (0, 1)));',
    'sync_rule_downloads': 'CREATE TABLE "sync_rule_downloads" ("sync_rule_id" INTEGER NOT NULL REFERENCES sync_rules (id) ON DELETE CASCADE, "profile_id" TEXT NOT NULL, "download_global_key" TEXT NOT NULL, PRIMARY KEY ("sync_rule_id", "download_global_key"));',
    'download_collections': 'CREATE TABLE "download_collections" ("profile_id" TEXT NOT NULL, "server_id" TEXT NOT NULL, "collection_id" TEXT NOT NULL, "member_ids" TEXT NOT NULL, PRIMARY KEY ("profile_id", "server_id", "collection_id"));',
    'download_collection_syncs': 'CREATE TABLE "download_collection_syncs" ("profile_id" TEXT NOT NULL, "server_id" TEXT NOT NULL, "synced_at" INTEGER NOT NULL, "checked_ids" TEXT NOT NULL, PRIMARY KEY ("profile_id", "server_id"));',
    'connections': 'CREATE TABLE "connections" ("id" TEXT NOT NULL, "kind" TEXT NOT NULL, "display_name" TEXT NOT NULL, "config_json" TEXT NOT NULL, "created_at" INTEGER NOT NULL, "last_authenticated_at" INTEGER NULL, PRIMARY KEY ("id"));',
    'profiles': 'CREATE TABLE "profiles" ("id" TEXT NOT NULL, "kind" TEXT NOT NULL, "display_name" TEXT NOT NULL, "avatar_thumb_url" TEXT NULL, "config_json" TEXT NOT NULL, "sort_order" INTEGER NOT NULL DEFAULT 0, "created_at" INTEGER NOT NULL, "last_used_at" INTEGER NULL, PRIMARY KEY ("id"));',
    'profile_connections': 'CREATE TABLE "profile_connections" ("profile_id" TEXT NOT NULL, "connection_id" TEXT NOT NULL REFERENCES connections (id) ON DELETE CASCADE, "user_token" TEXT NOT NULL DEFAULT \'\', "user_identifier" TEXT NOT NULL, "is_default" INTEGER NOT NULL DEFAULT 0 CHECK ("is_default" IN (0, 1)), "token_acquired_at" INTEGER NULL, "last_used_at" INTEGER NULL, PRIMARY KEY ("profile_id", "connection_id"));',
    'music_sessions': 'CREATE TABLE "music_sessions" ("profile_id" TEXT NOT NULL, "queue_json" TEXT NOT NULL, "order_json" TEXT NOT NULL, "cursor" INTEGER NOT NULL, "shuffled" INTEGER NOT NULL DEFAULT 0 CHECK ("shuffled" IN (0, 1)), "repeat_mode" TEXT NOT NULL DEFAULT \'off\', "context_title" TEXT NULL, "context_kind" TEXT NULL, "position_ms" INTEGER NOT NULL DEFAULT 0, "updated_at" INTEGER NOT NULL, PRIMARY KEY ("profile_id"));',
}

V25_INDEXES = [
    'CREATE INDEX idx_downloaded_media_status ON downloaded_media (status);',
    'CREATE INDEX idx_downloaded_media_server ON downloaded_media (server_id);',
    'CREATE INDEX idx_downloaded_media_parent ON downloaded_media (parent_rating_key);',
    'CREATE INDEX idx_downloaded_media_grandparent ON downloaded_media (grandparent_rating_key);',
    'CREATE INDEX idx_download_owners_profile ON download_owners (profile_id);',
    'CREATE INDEX idx_download_owners_global_key ON download_owners (global_key);',
    'CREATE INDEX idx_offline_watch_progress_server ON offline_watch_progress (server_id);',
    'CREATE INDEX idx_offline_watch_progress_profile ON offline_watch_progress (profile_id);',
    'CREATE INDEX idx_sync_rules_profile ON sync_rules (profile_id);',
    'CREATE INDEX idx_sync_rule_downloads_profile_key ON sync_rule_downloads (profile_id, download_global_key);',
    'CREATE INDEX idx_connections_kind ON connections (kind);',
    'CREATE INDEX idx_profiles_kind ON profiles (kind);',
    'CREATE INDEX idx_profile_connections_connection_id ON profile_connections (connection_id);',
    'CREATE INDEX idx_profile_connections_profile_id ON profile_connections (profile_id);',
]


def v16_schema():
    """Schema 16: schema 25 without what versions 17-25 added, and with connections.is_default (dropped in 21)."""
    removed = {
        'downloaded_media': [' "additional_part_paths" TEXT NULL,', ' "saf_root_uri" TEXT NULL,',
                             ', "library_id" TEXT NULL', ', "library_title" TEXT NULL'],
        'download_owners': [' "backend" TEXT NULL,', ' "client_scope_id" TEXT NULL,'],
        'sync_rules': [', "download_links_initialized" INTEGER NOT NULL DEFAULT 0 CHECK '
                       '("download_links_initialized" IN (0, 1))'],
    }
    tables = []
    for name in ['downloaded_media', 'download_owners', 'download_queue', 'api_cache', 'offline_watch_progress',
                 'sync_rules', 'connections', 'profiles', 'profile_connections']:
        sql = V25_TABLES[name]
        for column in removed.get(name, []):
            assert column in sql, column
            sql = sql.replace(column, '')
        if name == 'connections':
            sql = sql.replace(
                '"config_json" TEXT NOT NULL,',
                '"config_json" TEXT NOT NULL, "is_default" INTEGER NOT NULL DEFAULT 0 CHECK ("is_default" IN (0, 1)),')
        tables.append(sql)
    indexes = [i for i in V25_INDEXES if 'sync_rule_downloads' not in i]
    return tables + indexes


def insert(con, table, row):
    columns = ', '.join(f'"{c}"' for c in row)
    marks = ', '.join('?' for _ in row)
    con.execute(f'INSERT INTO "{table}" ({columns}) VALUES ({marks})', list(row.values()))


# ---------------------------------------------------------------------------------------------------------------
# Schema-25 database rows. The test asserts these exact values.

PIN_HASH = hashlib.sha256(b'plezy-app-profile-pin-v1:1234').hexdigest()

PLEX_CONFIG = dart_json({
    'accountToken': protect('plex-account-token', 'plex-account'),
    'clientIdentifier': 'plezy-client-1',
    'accountLabel': 'alex@example.invalid',
    'activeProfile': None,
    'servers': [
        {'clientIdentifier': 'srv-plex-1', 'name': 'Living Room', 'accessToken': protect('plex-server-token-1', 'plex-server-1')},
        {'clientIdentifier': 'srv-plex-2', 'name': 'Attic', 'accessToken': 'plaintext-plex-server-token-2'},
    ],
})
JELLYFIN_CONFIG = dart_json({
    'baseUrl': 'https://jf.example.invalid', 'baseUrls': ['https://jf.example.invalid'], 'serverName': 'Basement',
    'serverMachineId': 'jf-machine', 'userId': 'user-1', 'userName': 'alex',
    'accessToken': protect('jellyfin-access-token', 'jellyfin'), 'deviceId': 'device-1', 'isAdministrator': True,
    'primaryImageTag': None,
})
EMBY_CONFIG = dart_json({
    'baseUrl': 'https://emby.example.invalid', 'baseUrls': [], 'serverName': 'Cabin', 'serverMachineId': 'emby-machine',
    'userId': 'user-9', 'userName': 'kid', 'accessToken': 'plaintext-emby-token', 'deviceId': 'device-9',
    'isAdministrator': False, 'primaryImageTag': 'tag-9',
})
LOST_CONFIG = dart_json({
    'baseUrl': 'https://lost.example.invalid', 'baseUrls': [], 'serverName': 'Lost', 'serverMachineId': 'jf-lost',
    'userId': 'user-2', 'userName': 'gone', 'accessToken': protect('lost-token', 'lost', key=OTHER_KEY),
    'deviceId': 'device-2', 'isAdministrator': False, 'primaryImageTag': None,
})

V25_ROWS = [
    ('connections', dict(id='plex-acct-1', kind='plex', display_name='Alex Plex', config_json=PLEX_CONFIG,
                         created_at=T, last_authenticated_at=T + 500_000)),
    ('connections', dict(id='jf-machine/user-1', kind='jellyfin', display_name='Basement', config_json=JELLYFIN_CONFIG,
                         created_at=T + 100_000, last_authenticated_at=None)),
    ('connections', dict(id='emby-machine/user-9', kind='emby', display_name='Cabin', config_json=EMBY_CONFIG,
                         created_at=T + 150_000, last_authenticated_at=T + 160_000)),
    ('connections', dict(id='jf-lost/user-2', kind='jellyfin', display_name='Lost', config_json=LOST_CONFIG,
                         created_at=T + 170_000, last_authenticated_at=None)),
    ('profiles', dict(id='local-aaa', kind='local', display_name='Alex', avatar_thumb_url=None,
                      config_json=dart_json({'pinHash': PIN_HASH}), sort_order=0, created_at=T, last_used_at=T + 900_000)),
    ('profiles', dict(id='local-bbb', kind='local', display_name='Kid', avatar_thumb_url='https://avatar.example.invalid/kid.png',
                      config_json='{}', sort_order=1, created_at=T + 200_000, last_used_at=None)),
    ('profiles', dict(id='plex-home-legacy', kind='plex_home', display_name='Legacy Home', avatar_thumb_url=None,
                      config_json='{}', sort_order=2, created_at=T + 210_000, last_used_at=None)),
    ('profile_connections', dict(profile_id='local-aaa', connection_id='plex-acct-1',
                                 user_token=protect('profile-token-alex', 'profile-alex'), user_identifier='plex-user-1',
                                 is_default=1, token_acquired_at=T + 300_000, last_used_at=T + 800_000)),
    ('profile_connections', dict(profile_id='local-aaa', connection_id='jf-machine/user-1', user_token='',
                                 user_identifier='user-1', is_default=0, token_acquired_at=None, last_used_at=None)),
    ('profile_connections', dict(profile_id='local-bbb', connection_id='emby-machine/user-9',
                                 user_token='plaintext-profile-token-kid', user_identifier='user-9', is_default=1,
                                 token_acquired_at=None, last_used_at=T + 700_000)),
    ('profile_connections', dict(profile_id='plex-home-plex-acct-1-uuid-9', connection_id='plex-acct-1',
                                 user_token=protect('home-user-token', 'home-user'), user_identifier='uuid-9',
                                 is_default=0, token_acquired_at=T + 310_000, last_used_at=None)),
    ('downloaded_media', dict(
        id=1, server_id='srv-plex-1', client_scope_id='srv-plex-1/~plex-profile/local-aaa', rating_key='101',
        global_key='srv-plex-1:101', type='movie', parent_rating_key=None, grandparent_rating_key=None, status=3,
        progress=100, total_bytes=4_000_000_000, downloaded_bytes=4_000_000_000,
        video_file_path='downloads/Movies/Heat (1995)/Heat (1995) [0a1b2c3d].mkv',
        additional_part_paths=dart_json(['downloads/Movies/Heat (1995)/Heat (1995) [0a1b2c3d] - part2.mkv', None]),
        saf_root_uri=None, thumb_path='/library/metadata/101/thumb/1700000000', downloaded_at=T + 1_000_000,
        error_message=None, retry_count=0, bg_task_id=None, media_index=0, media_source_id=None, library_id='1',
        library_title='Movies')),
    ('downloaded_media', dict(
        id=2, server_id='jf-machine', client_scope_id='jf-machine/user-1', rating_key='ep-7',
        global_key='jf-machine:ep-7', type='episode', parent_rating_key='season-2', grandparent_rating_key='show-1',
        status=4, progress=42, total_bytes=900_000_000, downloaded_bytes=378_000_000,
        video_file_path='content://com.android.externalstorage.documents/tree/primary%3APlezy/document/primary%3APlezy%2FS02E07.mkv',
        additional_part_paths=None, saf_root_uri='content://com.android.externalstorage.documents/tree/primary%3APlezy',
        thumb_path='https://jf.example.invalid/Items/ep-7/Images/Primary?tag=abc&api_key=secret-key', downloaded_at=None,
        error_message='HTTP 503', retry_count=2, bg_task_id='task-2', media_index=1, media_source_id='source-7',
        library_id='lib-tv', library_title='Séries')),
    ('download_owners', dict(profile_id='local-aaa', global_key='srv-plex-1:101', backend='plex',
                             client_scope_id='srv-plex-1/~plex-profile/local-aaa', created_at=T + 1_000_000)),
    ('download_owners', dict(profile_id='local-aaa', global_key='jf-machine:ep-7', backend='jellyfin',
                             client_scope_id='jf-machine/user-1', created_at=T + 1_100_000)),
    ('download_owners', dict(profile_id='local-bbb', global_key='jf-machine:ep-7', backend=None, client_scope_id=None,
                             created_at=T + 1_200_000)),
    ('download_queue', dict(id=1, media_global_key='jf-machine:ep-7', priority=5, added_at=T + 1_100_000,
                            download_subtitles=1, download_artwork=0)),
    ('api_cache', dict(cache_key='srv-plex-1/~plex-profile/local-aaa:/library/metadata/101',
                       data=dart_json({'MediaContainer': {'Metadata': [{'ratingKey': '101', 'title': 'Heat'}]}}),
                       cached_at=1_700_000_000, pinned=1)),
    ('api_cache', dict(cache_key='srv-plex-1:/library/sections', data='{"MediaContainer":{}}', cached_at=1_700_000_100,
                       pinned=0)),
    ('offline_watch_progress', dict(id=1, profile_id='local-aaa', server_id='srv-plex-1', client_scope_id=None,
                                    rating_key='101', global_key='srv-plex-1:101', action_type='progress',
                                    view_offset=120_000, duration=7_200_000, should_mark_watched=0, created_at=T + 2_000_000,
                                    updated_at=T + 2_000_500, sync_attempts=0, last_error=None)),
    ('offline_watch_progress', dict(id=2, profile_id=None, server_id='jf-machine', client_scope_id='jf-machine/user-1',
                                    rating_key='ep-7', global_key='jf-machine:ep-7', action_type='watched',
                                    view_offset=None, duration=None, should_mark_watched=1, created_at=T + 2_100_000,
                                    updated_at=T + 2_100_000, sync_attempts=2, last_error='HTTP 503')),
    ('sync_rules', dict(id=1, profile_id='local-aaa', server_id='jf-machine', rating_key='show-1',
                        global_key='jf-machine:show-1', target_type='show', episode_count=5, enabled=1,
                        created_at=T + 3_000_000, last_executed_at=T + 3_100_000, media_index=0,
                        download_filter='unwatched', include_specials=1, download_links_initialized=1)),
    ('sync_rules', dict(id=2, profile_id='', server_id='srv-plex-1', rating_key='coll-9', global_key='srv-plex-1:coll-9',
                        target_type='collection', episode_count=0, enabled=0, created_at=T + 3_200_000,
                        last_executed_at=None, media_index=2, download_filter='all', include_specials=0,
                        download_links_initialized=0)),
    ('sync_rule_downloads', dict(sync_rule_id=1, profile_id='local-aaa', download_global_key='jf-machine:ep-7')),
    ('download_collections', dict(profile_id='local-aaa', server_id='srv-plex-1', collection_id='coll-9',
                                  member_ids=dart_json(['101', '102']))),
    ('download_collection_syncs', dict(profile_id='local-aaa', server_id='srv-plex-1', synced_at=T + 3_300_000,
                                       checked_ids=dart_json(['101', '102', '103']))),
]

# Committed after the checkpoint, so these live only in plezy_downloads.db-wal.
V25_WAL_ROWS = [
    ('downloaded_media', dict(
        id=3, server_id='srv-plex-1', client_scope_id=None, rating_key='102', global_key='srv-plex-1:102',
        type='movie', parent_rating_key=None, grandparent_rating_key=None, status=0, progress=0, total_bytes=None,
        downloaded_bytes=0, video_file_path=None, additional_part_paths=None, saf_root_uri=None, thumb_path=None,
        downloaded_at=None, error_message=None, retry_count=0, bg_task_id=None, media_index=0, media_source_id=None,
        library_id=None, library_title=None)),
    ('music_sessions', dict(profile_id='local-aaa', queue_json=dart_json([{'id': 't1'}, {'id': 't2'}]),
                            order_json='[1,0]', cursor=1, shuffled=1, repeat_mode='all', context_title='Album X',
                            context_kind='album', position_ms=61_000, updated_at=T + 4_000_000)),
]
V25_WAL_UPDATE = ('UPDATE profiles SET last_used_at = ? WHERE id = ?', [T + 950_000, 'local-bbb'])


def wal_checksum(data, s0, s1, big_endian):
    fmt = '>II' if big_endian else '<II'
    for offset in range(0, len(data), 8):
        x0, x1 = struct.unpack_from(fmt, data, offset)
        s0 = (s0 + x0 + s1) & 0xFFFFFFFF
        s1 = (s1 + x1 + s0) & 0xFFFFFFFF
    return s0, s1


def fix_wal_salts(data):
    """Rewrites the WAL's random salts as constants and recomputes the checksum chain over header and frames."""
    magic, version, page_size, checkpoint = struct.unpack_from('>IIII', data, 0)
    big_endian = magic & 1 == 1
    salt1, salt2 = 1, 0x5EED5EED
    header = struct.pack('>IIIIII', magic, version, page_size, checkpoint, salt1, salt2)
    s0, s1 = wal_checksum(header, 0, 0, big_endian)
    out = bytearray(header + struct.pack('>II', s0, s1))
    frame_size = 24 + page_size
    for offset in range(32, len(data) - frame_size + 1, frame_size):
        page_number, commit_size = struct.unpack_from('>II', data, offset)
        page = data[offset + 24:offset + frame_size]
        s0, s1 = wal_checksum(struct.pack('>II', page_number, commit_size), s0, s1, big_endian)
        s0, s1 = wal_checksum(page, s0, s1, big_endian)
        out += struct.pack('>IIIIII', page_number, commit_size, salt1, salt2, s0, s1) + page
    return bytes(out)


def build_v25(directory):
    work = tempfile.mkdtemp()
    path = os.path.join(work, 'plezy_downloads.db')
    con = sqlite3.connect(path, isolation_level=None)
    con.execute('PRAGMA journal_mode=WAL')
    con.execute('PRAGMA wal_autocheckpoint=0')
    con.execute('BEGIN')
    for sql in V25_TABLES.values():
        con.execute(sql)
    for sql in V25_INDEXES:
        con.execute(sql)
    for table, row in V25_ROWS:
        insert(con, table, row)
    con.execute('COMMIT')
    con.execute('PRAGMA user_version = 25')
    con.execute('PRAGMA wal_checkpoint(TRUNCATE)')
    con.execute('BEGIN')
    for table, row in V25_WAL_ROWS:
        insert(con, table, row)
    con.execute(*V25_WAL_UPDATE)
    con.execute('COMMIT')
    os.makedirs(directory, exist_ok=True)
    shutil.copyfile(path, os.path.join(directory, 'plezy_downloads.db'))
    with open(path + '-wal', 'rb') as f:
        wal = fix_wal_salts(f.read())
    with open(os.path.join(directory, 'plezy_downloads.db-wal'), 'wb') as f:
        f.write(wal)
    con.close()
    shutil.rmtree(work)

    # The committed files must hold the WAL rows: open a copy (without -shm, SQLite rebuilds it from the WAL).
    check = tempfile.mkdtemp()
    for name in ['plezy_downloads.db', 'plezy_downloads.db-wal']:
        shutil.copyfile(os.path.join(directory, name), os.path.join(check, name))
    probe = sqlite3.connect(os.path.join(check, 'plezy_downloads.db'))
    assert probe.execute('SELECT count(*) FROM music_sessions').fetchone()[0] == 1
    assert probe.execute('SELECT count(*) FROM downloaded_media').fetchone()[0] == 3
    probe.close()
    shutil.rmtree(check)
    with open(os.path.join(directory, 'plezy_downloads.db'), 'rb') as f:
        main = f.read()
    assert b'Album X' not in main, 'the WAL rows must not be checkpointed into the main file'


# ---------------------------------------------------------------------------------------------------------------
# Schema-16 database: rows the upgrade steps 17 (pinned Plex metadata), 19 (owner scopes) and 21 (connections
# rebuild) transform, the cases the earlier releases' own migrations handled.

def metadata(rating_key, **extra):
    return dart_json({'MediaContainer': {'size': 1, 'Metadata': [dict({'ratingKey': rating_key, 'title': 'Item ' + rating_key}, **extra)]}})


V16_ROWS = [
    ('connections', dict(id='jf-machine/user-a', kind='jellyfin', display_name='A', config_json='{}', is_default=1,
                         created_at=T, last_authenticated_at=None)),
    ('connections', dict(id='jf-machine/user-z', kind='jellyfin', display_name='Z', config_json='{}', is_default=0,
                         created_at=T + 1, last_authenticated_at=T + 2)),
    ('connections', dict(id='jf-machine', kind='jellyfin', display_name='Bare', config_json='{}', is_default=0,
                         created_at=T + 3, last_authenticated_at=None)),
    ('profiles', dict(id='profile-a', kind='local', display_name='A', avatar_thumb_url=None, config_json='{}',
                      sort_order=0, created_at=T, last_used_at=None)),
    ('profile_connections', dict(profile_id='profile-a', connection_id='jf-machine/user-a', user_token='',
                                 user_identifier='user-a', is_default=0, token_acquired_at=None, last_used_at=None)),
    ('profile_connections', dict(profile_id='profile-a', connection_id='jf-machine/user-z', user_token='',
                                 user_identifier='user-z', is_default=1, token_acquired_at=None, last_used_at=T)),
    ('profile_connections', dict(profile_id='profile-c', connection_id='jf-machine', user_token='',
                                 user_identifier='user-c', is_default=0, token_acquired_at=None, last_used_at=None)),
    ('downloaded_media', dict(id=1, server_id='plex-server', client_scope_id='plex-server/~plex-profile/profile-a',
                              rating_key='item', global_key='plex-server:item', type='episode',
                              parent_rating_key='season', grandparent_rating_key='show', status=3,
                              video_file_path='downloads/plex-server/item/video.mkv', downloaded_at=T)),
    ('downloaded_media', dict(id=2, server_id='plex-server', client_scope_id=None, rating_key='orphan',
                              global_key='plex-server:orphan', type='movie', status=3)),
    ('downloaded_media', dict(id=3, server_id='plex-server', client_scope_id=None, rating_key='broken',
                              global_key='plex-server:broken', type='movie', status=3)),
    ('downloaded_media', dict(id=4, server_id='jf-machine', client_scope_id='jf-machine/user-a', rating_key='jf-item',
                              global_key='jf-machine:jf-item', type='movie', status=3, bg_task_id='task-4',
                              media_index=2, media_source_id='source-4')),
    ('download_owners', dict(profile_id='profile-a', global_key='plex-server:item', created_at=T + 10)),
    ('download_owners', dict(profile_id='profile-b', global_key='plex-server:item', created_at=T + 11)),
    ('download_owners', dict(profile_id='profile-a', global_key='jf-machine:jf-item', created_at=T + 12)),
    ('download_owners', dict(profile_id='profile-c', global_key='jf-machine:jf-item', created_at=T + 13)),
    ('download_owners', dict(profile_id='profile-x', global_key='jf-machine:jf-item', created_at=T + 14)),
    ('api_cache', dict(cache_key='plex-server:/library/metadata/item', data=metadata('item', viewOffset=5000),
                       cached_at=1_700_000_001, pinned=1)),
    ('api_cache', dict(cache_key='plex-server:/library/metadata/item/children', data=metadata('child'),
                       cached_at=1_700_000_002, pinned=1)),
    ('api_cache', dict(cache_key='plex-server:/library/metadata/season', data=metadata('season'),
                       cached_at=1_700_000_003, pinned=1)),
    ('api_cache', dict(cache_key='plex-server:/library/metadata/unpinned', data=metadata('unpinned'),
                       cached_at=1_700_000_004, pinned=0)),
    ('api_cache', dict(cache_key='plex-server:/library/metadata/item/extras', data='{}', cached_at=1_700_000_005,
                       pinned=1)),
    ('api_cache', dict(cache_key='plex-server:/library/sections/1/all', data='{}', cached_at=1_700_000_006, pinned=1)),
    ('api_cache', dict(cache_key='plex-server/~plex-profile/profile-a:/library/metadata/item', data='{"stale":true}',
                       cached_at=1_600_000_000, pinned=1)),
    ('api_cache', dict(cache_key='plex-server:/library/metadata/orphan',
                       data=dart_json({'MediaContainer': {'viewCount': 3, 'Metadata': [
                           {'ratingKey': 'orphan', 'viewOffset': 1234, 'lastViewedAt': 1700000000, 'userRating': 8.5,
                            'Media': [{'Part': [{'viewOffset': 99, 'file': 'x.mkv'}]}]}]}}),
                       cached_at=1_700_000_007, pinned=1)),
    ('api_cache', dict(cache_key='plex-server:/library/metadata/broken', data='not json', cached_at=1_700_000_008,
                       pinned=1)),
    ('offline_watch_progress', dict(id=1, profile_id=None, server_id='jf-machine', client_scope_id='jf-machine/user-a',
                                    rating_key='jf-item', global_key='jf-machine:jf-item', action_type='progress',
                                    view_offset=10, duration=20, should_mark_watched=0, created_at=T, updated_at=T,
                                    sync_attempts=0, last_error=None)),
    ('sync_rules', dict(id=1, profile_id='profile-a', server_id='jf-machine', rating_key='show-1',
                        global_key='jf-machine:show-1', target_type='show', episode_count=3, enabled=1, created_at=T,
                        last_executed_at=None, media_index=0, download_filter='unwatched', include_specials=0)),
]


def build_v16(directory):
    os.makedirs(directory, exist_ok=True)
    path = os.path.join(directory, 'plezy_downloads.db')
    if os.path.exists(path):
        os.remove(path)
    con = sqlite3.connect(path, isolation_level=None)
    con.execute('BEGIN')
    for sql in v16_schema():
        con.execute(sql)
    for table, row in V16_ROWS:
        insert(con, table, row)
    con.execute('COMMIT')
    con.execute('PRAGMA user_version = 16')
    con.close()


# ---------------------------------------------------------------------------------------------------------------
# Preference stores.

LIST_PREFIX = 'VGhpcyBpcyB0aGUgcHJlZml4IGZvciBhIGxpc3Qu'
DOUBLE_PREFIX = 'VGhpcyBpcyB0aGUgcHJlZml4IGZvciBEb3VibGUu'
BIG_INTEGER_PREFIX = 'VGhpcyBpcyB0aGUgcHJlZml4IGZvciBCaWdJbnRlZ2Vy'

SEERR_SESSION = dart_json({
    'base_url': 'https://seerr.example.invalid', 'method': 'local', 'identifier': 'alex@example.invalid',
    'secret': protect('seerr-password', 'seerr'), 'cookie': 'connect.sid=s%3Afixture', 'user_id': 1,
    'permissions': 2, 'display_name': 'Alex', 'instance_label': 'Seerr', 'product': 'jellyseerr',
    'created_at': 1_700_000_000,
})
TRAKT_SESSION = dart_json({
    'access_token': 'trakt-access-token', 'refresh_token': 'trakt-refresh-token', 'expires_at': 4_102_444_800,
    'username': 'alex', 'created_at': 1_700_000_000,
})


def java_serialized_string_list(items):
    """ObjectOutputStream.writeObject(java.util.ArrayList<String>): the list form Android's plugin wrote first."""
    out = bytearray(b'\xac\xed\x00\x05')  # STREAM_MAGIC, STREAM_VERSION
    out += b'\x73\x72'  # TC_OBJECT, TC_CLASSDESC
    name = b'java.util.ArrayList'
    out += struct.pack('>H', len(name)) + name + struct.pack('>q', 8683452581122892189)
    out += b'\x03' + struct.pack('>H', 1) + b'I' + struct.pack('>H', 4) + b'size'  # SC_WRITE_METHOD|SC_SERIALIZABLE
    out += b'\x78\x70'  # TC_ENDBLOCKDATA, no superclass
    out += struct.pack('>i', len(items))  # the size field (defaultWriteObject)
    out += b'\x77\x04' + struct.pack('>i', len(items))  # TC_BLOCKDATA: writeInt(size)
    for item in items:
        encoded = item.encode('utf-8')
        out += b'\x74' + struct.pack('>H', len(encoded)) + encoded  # TC_STRING
    out += b'\x78'
    return bytes(out)


def android_base64(data):
    """android.util.Base64.encodeToString(data, DEFAULT): 76-character lines, each ended by '\\n'."""
    return base64.encodebytes(data).decode()


def varint(value):
    value &= (1 << 64) - 1
    out = bytearray()
    while True:
        byte = value & 0x7F
        value >>= 7
        if value:
            out.append(byte | 0x80)
        else:
            out.append(byte)
            return bytes(out)


def tag(number, wire_type):
    return varint(number << 3 | wire_type)


def delimited(number, data):
    return tag(number, 2) + varint(len(data)) + data


def proto_value(kind, value):
    """androidx.datastore.preferences.Value: oneof boolean=1 float=2 integer=3 long=4 string=5 string_set=6
    double=7 bytes=8."""
    if kind == 'boolean':
        return tag(1, 0) + varint(1 if value else 0)
    if kind == 'float':
        return tag(2, 5) + struct.pack('<f', value)
    if kind == 'integer':
        return tag(3, 0) + varint(value)
    if kind == 'long':
        return tag(4, 0) + varint(value)
    if kind == 'string':
        return delimited(5, value.encode('utf-8'))
    if kind == 'string_set':
        return delimited(6, b''.join(delimited(1, s.encode('utf-8')) for s in value))
    if kind == 'double':
        return tag(7, 1) + struct.pack('<d', value)
    if kind == 'bytes':
        return delimited(8, value)
    raise ValueError(kind)


def preference_map(entries):
    """PreferenceMap: map<string, Value> preferences = 1."""
    return b''.join(
        delimited(1, delimited(1, key.encode('utf-8')) + delimited(2, proto_value(kind, value)))
        for key, kind, value in entries)


PLATFORM_LIST = ['Action', 'Comédie', 'Documentary', 'Drama', 'Science Fiction', 'Animation', 'Thriller', 'Western']

DATASTORE_ENTRIES = [
    ('plezy_legacy_prefs_migrated_v1', 'boolean', True),
    ('enable_debug_logging', 'boolean', False),
    ('seek_time_small', 'long', 15),
    ('audio_sync_offset', 'long', -250),
    ('volume', 'double', 100.0),
    ('view_mode', 'string', 'list'),
    ('user_local-aaa_library_order', 'string', LIST_PREFIX + '!' + dart_json(['2', '1', '7'])),
    ('user_local-aaa_hidden_genres', 'string', LIST_PREFIX + android_base64(java_serialized_string_list(PLATFORM_LIST))),
    ('subtitle_font_scale', 'string', DOUBLE_PREFIX + '1.25'),
    ('credential_vault_key_v1', 'string', VAULT_KEY_B64),
    ('active_app_profile_id', 'string', 'local-aaa'),
    ('user_local-aaa_seerr_session', 'string', SEERR_SESSION),
    # Types the plugin never writes and filters out when reading.
    ('stray_int32', 'integer', 7),
    ('stray_float', 'float', 0.5),
    ('stray_set', 'string_set', ['a', 'b']),
    ('stray_bytes', 'bytes', b'\x00\x01'),
]


def xml_escape(text):
    return text.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;').replace('"', '&quot;')


def legacy_xml():
    """shared_prefs/FlutterSharedPreferences.xml as Android's SharedPreferencesImpl writes it."""
    entries = [
        '<string name="flutter.view_mode">grid</string>',
        '<boolean name="flutter.enable_debug_logging" value="true" />',
        '<long name="flutter.seek_time_small" value="20" />',
        '<int name="flutter.sleep_timer_duration" value="45" />',
        f'<string name="flutter.volume">{DOUBLE_PREFIX}80.0</string>',
        '<float name="flutter.legacy_ratio" value="0.5" />',
        f'<string name="flutter.library_order">{xml_escape(LIST_PREFIX + "!" + dart_json(["b", "a"]))}</string>',
        f'<string name="flutter.hidden_genres">{LIST_PREFIX + android_base64(java_serialized_string_list(["Horror", "Kids"]))}</string>',
        '<set name="flutter.old_set">\n        <string>x</string>\n        <string>y</string>\n    </set>',
        f'<string name="flutter.big_counter">{BIG_INTEGER_PREFIX}zz</string>',
        f'<string name="flutter.server_name">{xml_escape("Tom & Jerry <\"Den\">")}</string>',
        '<string name="flutter.emoji">&#233;t&#233;</string>',
        '<null name="flutter.cleared" />',
        '<string name="not_flutter_key">ignored</string>',
        f'<string name="flutter.credential_vault_key_v1">{VAULT_KEY_B64}</string>',
    ]
    body = ''.join('    ' + e + '\n' for e in entries)
    return "<?xml version='1.0' encoding='utf-8' standalone='yes' ?>\n<map>\n" + body + '</map>\n'


DESKTOP = {
    'flutter.view_mode': 'list',
    'flutter.volume': 80.0,
    'flutter.only_legacy': 'stale',
    'view_mode': 'grid',
    'volume': 100.0,
    'seek_time_small': 15,
    'audio_sync_offset': -250,
    'enable_debug_logging': True,
    'user_local-aaa_library_order': ['2', '1', '7'],
    'credential_vault_key_v1': VAULT_KEY_B64,
    'client_identifier': 'plezy-client-1',
    'active_app_profile_id': 'local-aaa',
    'profile_migration_v1_done': True,
    'plezy_legacy_prefs_migrated_v1': True,
    'user_local-aaa_seerr_session': SEERR_SESSION,
    'trakt_session': TRAKT_SESSION,
}
DESKTOP_TMP = {'view_mode': 'list', 'volume': 5.0}
DESKTOP_LEGACY = {
    'flutter.view_mode': 'list',
    'flutter.volume': 80.0,
    'flutter.seek_time_small': 20,
    'flutter.library_order': ['a', 'b'],
    'flutter.enable_debug_logging': False,
    'view_mode': 'grid',
}


def damaged_desktop():
    """A store cut short mid-write: the object never closes, but entries before the cut survive verbatim."""
    entries = [
        ('theme_mode', 'dark'),
        ('flutter.credential_vault_key_v1', base64.b64encode(OTHER_KEY).decode()),
        ('credential_vault_key_v1', VAULT_KEY_B64),
        ('trakt_session', TRAKT_SESSION),
        ('flutter.plex_token', 'legacy-plex-token'),
        ('user_local-aaa_seerr_session', SEERR_SESSION),
        ('anilist_session', dart_json({'access_token': 'no-created-at'})),
    ]
    text = '{' + ','.join(dart_json(k) + ':' + dart_json(v) for k, v in entries)
    return text + ',' + dart_json('mal_session') + ':"{\\"access_token\\":\\"half'


# The Plex Home users the Plex account `plex-acct-1` cached: an admin and a managed user (16-hex uuids, as plex.tv's).
HOME_ADMIN_UUID = '0123456789abcdef'
HOME_KID_UUID = 'fedcba9876543210'
PLEX_HOME_USERS = dart_json([
    {'id': 1, 'uuid': HOME_ADMIN_UUID, 'title': 'Alex', 'username': 'alex', 'email': 'alex@example.invalid',
     'friendlyName': None, 'thumb': 'https://plex.example.invalid/users/1/avatar', 'hasPassword': True,
     'restricted': False, 'updatedAt': 1_700_000_000, 'admin': True, 'guest': False, 'protected': True},
    {'id': 2, 'uuid': HOME_KID_UUID, 'title': 'Kid', 'username': None, 'email': None, 'friendlyName': 'Little one',
     'thumb': 'https://plex.example.invalid/users/2/avatar', 'hasPassword': False, 'restricted': True,
     'updatedAt': None, 'admin': False, 'guest': False, 'protected': False},
])
MAL_SESSION = dart_json({
    'access_token': 'mal-access-token', 'refresh_token': 'mal-refresh-token', 'expires_at': 4_102_444_800,
    'username': 'alex-mal', 'created_at': 1_700_000_100,
})
# A MyAnimeList session without its refresh token: one the earlier releases refused to load.
BROKEN_MAL_SESSION = dart_json({'access_token': 'mal-no-refresh', 'expires_at': 4_102_444_800, 'created_at': 1_700_000_100})

# The store of an install upgraded in place, beside the schema-25 database: every kind of key the import maps.
DESKTOP_UPGRADE = {
    'plezy_legacy_prefs_migrated_v1': True,
    'flutter.view_mode': 'grid',
    'credential_vault_key_v1': VAULT_KEY_B64,
    'client_identifier': 'plezy-client-1',
    'active_app_profile_id': 'local-aaa',
    'profile_migration_v1_done': True,
    'require_profile_selection_on_open': True,
    'enable_debug_logging': True,
    'seek_time_small': 15,
    'seek_time_large': 'forty',
    'volume': 80.0,
    'view_mode': 'list',
    'theme_mode': 'oled',
    'keyboard_hotkeys': dart_json({'play_pause': {'key': 'space', 'modifiers': []}}),
    'tracker_library_filter_mode_trakt': 'whitelist',
    'tracker_library_filter_ids_trakt': ['srv-plex-1:1', 'jf-machine:lib-tv'],
    'enable_mal_scrobble': False,
    'library_density': 'compact',
    'auto_skip_intro': True,
    'profile_last_used_local-aaa': T + 900_000,
    f'profile_last_used_plex-home-plex-acct-1-{HOME_ADMIN_UUID}': T + 950_000,
    'plex_home_users_plex-acct-1': PLEX_HOME_USERS,
    'user_local-aaa_library_order': dart_json(['srv-plex-1:1', 'jf-machine:lib-tv']),
    'user_local-aaa_library_sort_srv-plex-1:1': dart_json({'key': 'titleSort', 'descending': True}),
    'user_local-aaa_library_sort_jf-machine:lib-tv': 'SortName',
    'user_local-aaa_selected_library_key': 'srv-plex-1:1',
    'user_local-aaa_hidden_genres': ['Horror'],
    f'user_plex-home-plex-acct-1-{HOME_ADMIN_UUID}_catalog_active_source': 'trakt',
    'hidden_libraries': dart_json(['jf-machine:lib-x']),
    'watched_threshold_srv-plex-1': 85,
    'server_endpoint_srv-plex-1': 'https://10-0-0-2.example.invalid:32400',
    'dvr_target_section_1_srv-plex-1': 4,
    'jellyfin_fav_channels:jf-machine/user-1': dart_json([
        {'source': 'tuner', 'id': 'ch-1', 'title': 'News', 'thumb': None, 'vcn': '4.1'},
        {'source': 'tuner', 'id': 'ch-2', 'title': 'Weather'},
    ]),
    'jellyfin_fav_channels:emby-machine': dart_json([{'source': 'm3u', 'id': 'ch-9', 'title': 'Cartoons'}]),
    # Written to the prefixed store alone after the move to bare keys, by releases that still saved favourites there.
    'flutter.jellyfin_fav_channels:jf-lost/user-2': dart_json([{'source': 'tuner', 'id': 'ch-5', 'title': 'Movies'}]),
    'user_local-aaa_seerr_session': SEERR_SESSION,
    'trakt_session': TRAKT_SESSION,
    f'user_{HOME_ADMIN_UUID}_mal_session': MAL_SESSION,
    'user_local-bbb_mal_session': BROKEN_MAL_SESSION,
    'plex_token': 'leftover-plex-token',
    'NSWindow Frame com.edde746.plezy.MainWindow': '100 100 1280 800 0 0 1920 1055 ',
}


# ---------------------------------------------------------------------------------------------------------------
# Apple: the standard user defaults domain, with a committed tvOS recovery image.

def tvos_image():
    identity = dart_json({'version': 1, 'rows': {
        'connections': [
            {'id': 'jf-machine/user-1', 'kind': 'jellyfin', 'displayName': 'Basement', 'configJson': JELLYFIN_CONFIG,
             'isDefault': True, 'createdAt': T + 100_000, 'lastAuthenticatedAt': None},
        ],
        'profiles': [
            {'id': 'local-aaa', 'kind': 'local', 'displayName': 'Alex', 'avatarThumbUrl': None,
             'configJson': dart_json({'pinHash': PIN_HASH}), 'sortOrder': 0, 'createdAt': T, 'lastUsedAt': T + 900_000},
        ],
        'profileConnections': [
            {'profileId': 'local-aaa', 'connectionId': 'jf-machine/user-1',
             'userToken': protect('profile-token-tv', 'profile-tv'), 'userIdentifier': 'user-1', 'isDefault': True,
             'tokenAcquiredAt': T + 300_000, 'lastUsedAt': None},
        ],
    }})
    pending = dart_json({'version': 1, 'rows': {'offlineWatchProgress': [
        {'id': 4, 'profileId': 'local-aaa', 'serverId': 'jf-machine', 'clientScopeId': 'jf-machine/user-1',
         'ratingKey': 'ep-8', 'globalKey': 'jf-machine:ep-8', 'actionType': 'progress', 'viewOffset': 5000,
         'duration': 60000, 'shouldMarkWatched': False, 'createdAt': T + 5_000_000, 'updatedAt': T + 5_000_001,
         'syncAttempts': 0, 'lastError': None},
    ]}})
    manifest = dart_json({
        'version': 1, 'state': 'committed',
        'identityDigest': hashlib.sha256(identity.encode('utf-8')).hexdigest(),
        'pendingDigest': hashlib.sha256(pending.encode('utf-8')).hexdigest(),
    })
    return {'tvos_db_recovery_manifest_v1': manifest, 'tvos_db_recovery_identity_v1': identity,
            'tvos_db_recovery_pending_v1': pending}


def apple_defaults():
    import datetime
    values = {
        'plezy_legacy_prefs_migrated_v1': True,
        'enable_debug_logging': True,
        'seek_time_small': 15,
        'volume': 100.0,
        'view_mode': 'grid',
        'user_local-aaa_library_order': ['2', '1', '7'],
        'credential_vault_key_v1': VAULT_KEY_B64,
        'active_app_profile_id': 'local-aaa',
        'flutter.view_mode': 'list',
        'flutter.seek_time_small': 20,
        'NSWindow Frame com.edde746.plezy.MainWindow': '100 100 1280 800 0 0 1920 1055 ',
        'last_seen_date': datetime.datetime(2024, 1, 2, 3, 4, 5),
        'mixed_array': ['a', 1],
    }
    values.update(tvos_image())
    return values


def binary_plist(values, path):
    xml_path = path + '.xml'
    with open(xml_path, 'wb') as f:
        plistlib.dump(values, f, fmt=plistlib.FMT_XML, sort_keys=True)
    subprocess.run(['plutil', '-convert', 'binary1', '-o', path, xml_path], check=True)
    os.remove(xml_path)


# ---------------------------------------------------------------------------------------------------------------
# Kotlin test sources.

def kotlin_string(value):
    escaped = value.replace('\\', '\\\\').replace('"', '\\"').replace('$', '\\$')
    return '"' + escaped + '"'


HEADER = '// Generated by tools/earlier-release-fixtures/generate.py from fixed inputs; regenerate rather than edit.\n'


def write_vectors():
    payload = json.loads(protect('super-secret', 'super-secret')[len('enc:v1:'):])
    tampered = 'enc:v1:' + dart_json(dict(payload, m=b64(bytes(16))))
    image = tvos_image()
    vectors = [
        ('VAULT_KEY', VAULT_KEY_B64, 'The vault key every fixture store holds (credential_vault_key_v1).'),
        ('PROTECTED_SECRET', protect('super-secret', 'super-secret'), '"super-secret" under VAULT_KEY.'),
        ('PROTECTED_UNDER_OTHER_KEY', protect('super-secret', 'other', key=OTHER_KEY),
         '"super-secret" under another key: the key diverged from the ciphertext.'),
        ('TAMPERED_MAC', tampered, 'PROTECTED_SECRET with its tag replaced by zeros.'),
        ('PROTECTED_UNICODE', protect('tökén ✓', 'unicode'), '"tökén ✓" under VAULT_KEY: the plaintext is UTF-8.'),
        ('PLEX_CONFIG', PLEX_CONFIG, 'A Plex connection config_json: an encrypted account token, one encrypted and one '
                                     'plaintext server token.'),
        ('LOST_CONFIG', LOST_CONFIG, 'A Jellyfin connection config_json whose token was encrypted under another key.'),
        ('SEERR_SESSION', SEERR_SESSION, 'A Seerr session pref whose secret is "seerr-password" under VAULT_KEY.'),
        ('TVOS_MANIFEST', image['tvos_db_recovery_manifest_v1'],
         'The committed tvOS recovery manifest of the plist (tvos_db_recovery_manifest_v1).'),
        ('TVOS_IDENTITY', image['tvos_db_recovery_identity_v1'],
         'Its identity group: one Jellyfin connection, one profile and their binding, whose token is "profile-token-tv".'),
        ('TVOS_PENDING', image['tvos_db_recovery_pending_v1'], 'Its pending group: one unsent watch action.'),
    ]
    lines = [HEADER, 'package com.edde746.plezy.importer\n', '\n',
             '/** Credential-vault vectors encrypted by an independent AES-256-GCM implementation; the tvOS recovery image. */\n',
             'internal object EarlierReleaseFixtureVectors {\n']
    for name, value, doc in vectors:
        lines.append(f'    /** {doc} */\n')
        lines.append(f'    const val {name} = {kotlin_string(value)}\n')
    lines.append('}\n')
    os.makedirs(COMMON_TEST, exist_ok=True)
    with open(os.path.join(COMMON_TEST, 'EarlierReleaseFixtureVectors.kt'), 'w', encoding='utf-8') as f:
        f.writelines(lines)


def write_plist_fixture(plist_path):
    with open(plist_path, 'rb') as f:
        encoded = base64.b64encode(f.read()).decode()
    chunks = [encoded[i:i + 100] for i in range(0, len(encoded), 100)]
    body = ''.join(f'        "{c}" +\n' for c in chunks[:-1]) + f'        "{chunks[-1]}"\n'
    text = (HEADER + 'package com.edde746.plezy.importer\n\n'
            '/** earlier-release/apple/com.edde746.plezy.plist: a binary plist of the standard user defaults domain. */\n'
            'internal object EarlierReleasePlistFixture {\n'
            '    const val BASE64 =\n' + body + '}\n')
    os.makedirs(APPLE_TEST, exist_ok=True)
    with open(os.path.join(APPLE_TEST, 'EarlierReleasePlistFixture.kt'), 'w', encoding='utf-8') as f:
        f.write(text)


def write(path, data):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'wb') as f:
        f.write(data if isinstance(data, bytes) else data.encode('utf-8'))


def main():
    shutil.rmtree(RESOURCES, ignore_errors=True)
    build_v25(os.path.join(RESOURCES, 'v25'))
    build_v16(os.path.join(RESOURCES, 'v16'))
    write(os.path.join(RESOURCES, 'android', 'files', 'datastore', 'FlutterSharedPreferences.preferences_pb'),
          preference_map(DATASTORE_ENTRIES))
    write(os.path.join(RESOURCES, 'android', 'shared_prefs', 'FlutterSharedPreferences.xml'), legacy_xml())
    write(os.path.join(RESOURCES, 'desktop', 'shared_preferences.json'), dart_json(DESKTOP))
    write(os.path.join(RESOURCES, 'desktop', 'shared_preferences.json.tmp'), dart_json(DESKTOP_TMP))
    write(os.path.join(RESOURCES, 'desktop-legacy', 'shared_preferences.json'), dart_json(DESKTOP_LEGACY))
    write(os.path.join(RESOURCES, 'desktop-damaged', 'shared_preferences.json'), damaged_desktop())
    write(os.path.join(RESOURCES, 'desktop-upgrade', 'shared_preferences.json'), dart_json(DESKTOP_UPGRADE))
    plist = os.path.join(RESOURCES, 'apple', 'com.edde746.plezy.plist')
    os.makedirs(os.path.dirname(plist), exist_ok=True)
    binary_plist(apple_defaults(), plist)
    write_vectors()
    write_plist_fixture(plist)


if __name__ == '__main__':
    main()
