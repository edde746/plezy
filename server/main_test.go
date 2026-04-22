package main

import (
	"encoding/json"
	"os"
	"path/filepath"
	"sync"
	"testing"
	"time"
)

// newTestServer builds a Server wired for tests: no goroutines, no network,
// logs scratched to a per-test temp dir. The snapshotter is constructed but
// its goroutine is NOT started — tests drive it synchronously via write()
// or call schedule() and then call write() themselves.
func newTestServer(t *testing.T, stateFile string) *Server {
	t.Helper()
	s := &Server{
		rooms: make(map[string]*Room),
		logs:  newLogStore(t.TempDir()),
		conns: newConnTracker(),
	}
	s.snap = newSnapshotter(stateFile, s.buildSnapshot)
	return s
}

func TestSnapshotRoundTrip(t *testing.T) {
	dir := t.TempDir()
	path := filepath.Join(dir, "rooms.json")
	s := newTestServer(t, path)

	now := time.Now().UTC().Truncate(time.Second)
	s.rooms["ABC12"] = &Room{
		SessionID:      "ABC12",
		HostPeerID:     "host-1",
		Peers:          map[string]*Client{},
		CreatedAt:      now.Add(-time.Minute),
		LastActivityAt: now,
	}
	s.rooms["XYZ99"] = &Room{
		SessionID:      "XYZ99",
		HostPeerID:     "host-2",
		Peers:          map[string]*Client{},
		CreatedAt:      now.Add(-time.Hour),
		LastActivityAt: now.Add(-time.Second),
	}

	if err := s.snap.write(); err != nil {
		t.Fatalf("write: %v", err)
	}

	// Reconstruct into a fresh Server and verify identity.
	s2 := newTestServer(t, path)
	if err := s2.loadSnapshot(path); err != nil {
		t.Fatalf("loadSnapshot: %v", err)
	}
	if got := len(s2.rooms); got != 2 {
		t.Fatalf("expected 2 rooms after reload, got %d", got)
	}
	for _, id := range []string{"ABC12", "XYZ99"} {
		r, ok := s2.rooms[id]
		if !ok {
			t.Fatalf("room %s missing after reload", id)
		}
		orig := s.rooms[id]
		if r.HostPeerID != orig.HostPeerID {
			t.Errorf("%s: HostPeerID=%q want %q", id, r.HostPeerID, orig.HostPeerID)
		}
		if !r.CreatedAt.Equal(orig.CreatedAt) {
			t.Errorf("%s: CreatedAt=%v want %v", id, r.CreatedAt, orig.CreatedAt)
		}
		if !r.LastActivityAt.Equal(orig.LastActivityAt) {
			t.Errorf("%s: LastActivityAt=%v want %v", id, r.LastActivityAt, orig.LastActivityAt)
		}
		if r.Peers == nil {
			t.Errorf("%s: Peers map nil after reload", id)
		}
		if len(r.Peers) != 0 {
			t.Errorf("%s: expected empty Peers, got %d", id, len(r.Peers))
		}
	}
}

func TestLoadSkipsExpired(t *testing.T) {
	dir := t.TempDir()
	path := filepath.Join(dir, "rooms.json")
	now := time.Now()

	snap := stateSnapshot{
		Version: snapshotFormatVersion,
		SavedAt: now,
		Rooms: []roomSnapshot{
			{SessionID: "FRESH", HostPeerID: "h", CreatedAt: now.Add(-time.Minute), LastActivityAt: now.Add(-30 * time.Second)},
			{SessionID: "OLD24", HostPeerID: "h", CreatedAt: now.Add(-25 * time.Hour), LastActivityAt: now.Add(-time.Second)},
			{SessionID: "IDLE6", HostPeerID: "h", CreatedAt: now.Add(-2 * time.Hour), LastActivityAt: now.Add(-6 * time.Minute)},
			{SessionID: "", HostPeerID: "h", CreatedAt: now, LastActivityAt: now},
			{SessionID: "NOHOS", HostPeerID: "", CreatedAt: now, LastActivityAt: now},
		},
	}
	data, err := json.Marshal(snap)
	if err != nil {
		t.Fatalf("marshal: %v", err)
	}
	if err := os.WriteFile(path, data, 0644); err != nil {
		t.Fatalf("write: %v", err)
	}

	s := newTestServer(t, path)
	if err := s.loadSnapshot(path); err != nil {
		t.Fatalf("loadSnapshot: %v", err)
	}
	if len(s.rooms) != 1 {
		t.Fatalf("expected 1 room after load, got %d: %v", len(s.rooms), s.rooms)
	}
	if _, ok := s.rooms["FRESH"]; !ok {
		t.Fatalf("FRESH room should have loaded")
	}
}

func TestLoadHandlesCorrupt(t *testing.T) {
	dir := t.TempDir()
	path := filepath.Join(dir, "rooms.json")
	if err := os.WriteFile(path, []byte("not valid json {{{"), 0644); err != nil {
		t.Fatalf("write: %v", err)
	}
	s := newTestServer(t, path)
	if err := s.loadSnapshot(path); err != nil {
		t.Fatalf("loadSnapshot returned error: %v", err)
	}
	if len(s.rooms) != 0 {
		t.Fatalf("expected empty rooms after corrupt load, got %d", len(s.rooms))
	}
	// File should be preserved for debugging.
	if _, err := os.Stat(path); err != nil {
		t.Fatalf("corrupt file should NOT be deleted: %v", err)
	}
}

func TestLoadHandlesMissing(t *testing.T) {
	dir := t.TempDir()
	path := filepath.Join(dir, "does-not-exist.json")
	s := newTestServer(t, path)
	if err := s.loadSnapshot(path); err != nil {
		t.Fatalf("loadSnapshot: %v", err)
	}
	if len(s.rooms) != 0 {
		t.Fatalf("expected empty rooms, got %d", len(s.rooms))
	}
}

func TestLoadHandlesUnknownVersion(t *testing.T) {
	dir := t.TempDir()
	path := filepath.Join(dir, "rooms.json")
	if err := os.WriteFile(path, []byte(`{"version":99,"rooms":[{"sessionId":"X"}]}`), 0644); err != nil {
		t.Fatalf("write: %v", err)
	}
	s := newTestServer(t, path)
	if err := s.loadSnapshot(path); err != nil {
		t.Fatalf("loadSnapshot: %v", err)
	}
	if len(s.rooms) != 0 {
		t.Fatalf("expected empty rooms for unknown version, got %d", len(s.rooms))
	}
}

func TestCleanupUsesIdleNotAge(t *testing.T) {
	s := newTestServer(t, filepath.Join(t.TempDir(), "rooms.json"))
	now := time.Now()

	// 2h-old room that has activity 1min ago — must NOT be cleaned up.
	s.rooms["KEEP"] = &Room{
		SessionID:      "KEEP",
		HostPeerID:     "h",
		Peers:          map[string]*Client{},
		CreatedAt:      now.Add(-2 * time.Hour),
		LastActivityAt: now.Add(-1 * time.Minute),
	}
	// 2h-old room that emptied 10min ago — MUST be cleaned up.
	s.rooms["GONE"] = &Room{
		SessionID:      "GONE",
		HostPeerID:     "h",
		Peers:          map[string]*Client{},
		CreatedAt:      now.Add(-2 * time.Hour),
		LastActivityAt: now.Add(-10 * time.Minute),
	}
	// 25h-old room — absolute TTL nukes it even if recently active.
	s.rooms["OLD"] = &Room{
		SessionID:      "OLD",
		HostPeerID:     "h",
		Peers:          map[string]*Client{}, // empty anyway
		CreatedAt:      now.Add(-25 * time.Hour),
		LastActivityAt: now.Add(-10 * time.Second),
	}

	s.runCleanupStep(now)

	if _, ok := s.rooms["KEEP"]; !ok {
		t.Errorf("KEEP should still exist (recent activity)")
	}
	if _, ok := s.rooms["GONE"]; ok {
		t.Errorf("GONE should have been cleaned (idle>5min)")
	}
	if _, ok := s.rooms["OLD"]; ok {
		t.Errorf("OLD should have been cleaned (age>24h)")
	}
}

func TestSnapshotAtomicWriteSurvivesRenameFailure(t *testing.T) {
	dir := t.TempDir()
	path := filepath.Join(dir, "rooms.json")
	s := newTestServer(t, path)

	// Seed a valid snapshot on disk.
	s.rooms["ORIG"] = &Room{
		SessionID:      "ORIG",
		HostPeerID:     "h",
		Peers:          map[string]*Client{},
		CreatedAt:      time.Now(),
		LastActivityAt: time.Now(),
	}
	if err := s.snap.write(); err != nil {
		t.Fatalf("first write: %v", err)
	}
	origBytes, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("read orig: %v", err)
	}

	// Force a second write to fail at the tmp-file create step by making the
	// snapshot directory unwritable. The rename therefore never runs, so the
	// existing file must be untouched.
	if err := os.Chmod(dir, 0555); err != nil {
		t.Fatalf("chmod: %v", err)
	}
	t.Cleanup(func() { os.Chmod(dir, 0755) })

	delete(s.rooms, "ORIG")
	s.rooms["NEW"] = &Room{
		SessionID:      "NEW",
		HostPeerID:     "h",
		Peers:          map[string]*Client{},
		CreatedAt:      time.Now(),
		LastActivityAt: time.Now(),
	}
	if err := s.snap.write(); err == nil {
		t.Fatalf("expected write to fail with dir read-only")
	}

	// Restore permissions so we can read the file back.
	os.Chmod(dir, 0755)
	nowBytes, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("read after failed write: %v", err)
	}
	if string(origBytes) != string(nowBytes) {
		t.Fatalf("snapshot file was corrupted after failed write:\nbefore: %s\nafter:  %s", origBytes, nowBytes)
	}
}

func TestSnapshotDebounceCoalesces(t *testing.T) {
	dir := t.TempDir()
	path := filepath.Join(dir, "rooms.json")

	var (
		buildCount int
		countMu    sync.Mutex
	)
	sn := newSnapshotter(path, func() stateSnapshot {
		countMu.Lock()
		buildCount++
		countMu.Unlock()
		return stateSnapshot{Version: snapshotFormatVersion, SavedAt: time.Now(), Rooms: nil}
	})
	go sn.run()
	t.Cleanup(func() { _ = sn.flushAndStop(time.Second) })

	// Fire a burst — should collapse into one write due to debounce.
	for i := 0; i < 20; i++ {
		sn.schedule()
	}
	// Give the debounce window + a small buffer to actually run.
	time.Sleep(snapshotDebounce + 50*time.Millisecond)

	countMu.Lock()
	got := buildCount
	countMu.Unlock()
	if got != 1 {
		t.Fatalf("expected 1 build from burst, got %d", got)
	}
}
