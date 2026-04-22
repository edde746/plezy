package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/http/httptest"
	"net/url"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"sync/atomic"
	"testing"
	"time"

	"github.com/gorilla/websocket"
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

// ======================================================================
// Integration harness — boots a real Server behind httptest with the full
// HTTP mux. Each dial sets X-Forwarded-For so tests control the perceived
// client IP independently of the rate limiters.
// ======================================================================

type relayHarness struct {
	srv     *Server
	httpSrv *httptest.Server
	wsURL   string
	baseURL string
}

func newRelayHarness(t *testing.T) *relayHarness {
	t.Helper()
	tmpDir := t.TempDir()
	return newRelayHarnessAt(t, tmpDir, filepath.Join(tmpDir, "rooms.json"))
}

// newRelayHarnessAt lets a test control the stateFile path so two harnesses
// can share a snapshot across a simulated restart.
func newRelayHarnessAt(t *testing.T, logDir, stateFile string) *relayHarness {
	t.Helper()
	srv := newServer(logDir, stateFile)

	mux := http.NewServeMux()
	mux.HandleFunc("/relay", srv.handleWS)
	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("ok"))
	})
	mux.HandleFunc("/logs", srv.handlePostLogs)
	mux.HandleFunc("/logs/", srv.handleGetLogs)

	httpSrv := httptest.NewServer(mux)
	t.Cleanup(func() {
		httpSrv.Close()
		_ = srv.snap.flushAndStop(time.Second)
	})

	u, _ := url.Parse(httpSrv.URL)
	wsURL := "ws://" + u.Host + "/relay"
	return &relayHarness{srv: srv, httpSrv: httpSrv, wsURL: wsURL, baseURL: httpSrv.URL}
}

func (h *relayHarness) dial(t *testing.T, ip string) *testConn {
	t.Helper()
	headers := http.Header{}
	if ip != "" {
		headers.Set("X-Forwarded-For", ip)
	}
	conn, _, err := websocket.DefaultDialer.Dial(h.wsURL, headers)
	if err != nil {
		t.Fatalf("dial (ip=%s): %v", ip, err)
	}
	tc := &testConn{t: t, conn: conn}
	t.Cleanup(func() { conn.Close() })
	return tc
}

func (h *relayHarness) dialRaw(ip string) (*websocket.Conn, error) {
	headers := http.Header{}
	if ip != "" {
		headers.Set("X-Forwarded-For", ip)
	}
	conn, _, err := websocket.DefaultDialer.Dial(h.wsURL, headers)
	return conn, err
}

func (h *relayHarness) waitRoomPeers(t *testing.T, sessionID string, want int) {
	t.Helper()
	deadline := time.Now().Add(2 * time.Second)
	for time.Now().Before(deadline) {
		h.srv.mu.RLock()
		room := h.srv.rooms[sessionID]
		h.srv.mu.RUnlock()
		if room != nil {
			room.mu.RLock()
			got := len(room.Peers)
			room.mu.RUnlock()
			if got == want {
				return
			}
		}
		time.Sleep(20 * time.Millisecond)
	}
	t.Fatalf("room %s never reached %d peers within 2s", sessionID, want)
}

type testConn struct {
	t    *testing.T
	conn *websocket.Conn
}

func (c *testConn) send(msg clientMsg) {
	c.t.Helper()
	data, err := json.Marshal(msg)
	if err != nil {
		c.t.Fatalf("marshal: %v", err)
	}
	if err := c.conn.WriteMessage(websocket.TextMessage, data); err != nil {
		c.t.Fatalf("write: %v", err)
	}
}

func (c *testConn) sendRaw(data []byte) {
	c.t.Helper()
	if err := c.conn.WriteMessage(websocket.TextMessage, data); err != nil {
		c.t.Fatalf("write raw: %v", err)
	}
}

func (c *testConn) recv() serverMsg {
	c.t.Helper()
	c.conn.SetReadDeadline(time.Now().Add(2 * time.Second))
	_, data, err := c.conn.ReadMessage()
	if err != nil {
		c.t.Fatalf("read: %v", err)
	}
	var m serverMsg
	if err := json.Unmarshal(data, &m); err != nil {
		c.t.Fatalf("unmarshal %q: %v", data, err)
	}
	return m
}

func (c *testConn) expect(typ string) serverMsg {
	c.t.Helper()
	m := c.recv()
	if m.Type != typ {
		c.t.Fatalf("expected type=%s, got type=%s code=%s message=%s", typ, m.Type, m.Code, m.Message)
	}
	return m
}

func (c *testConn) expectError(code string) serverMsg {
	c.t.Helper()
	m := c.expect("error")
	if m.Code != code {
		c.t.Fatalf("expected code=%s, got code=%s message=%s", code, m.Code, m.Message)
	}
	return m
}

// recvNothing asserts no message arrives within the given window. Used to
// verify silent paths (sender not receiving own broadcast, stale-peer skip).
func (c *testConn) recvNothing(within time.Duration) {
	c.t.Helper()
	c.conn.SetReadDeadline(time.Now().Add(within))
	_, data, err := c.conn.ReadMessage()
	if err == nil {
		c.t.Fatalf("expected no message within %v, got %s", within, data)
	}
	if ne, ok := err.(net.Error); !ok || !ne.Timeout() {
		c.t.Fatalf("expected read timeout, got %v", err)
	}
}

// ======================================================================
// Unit tests — pure logic
// ======================================================================

func TestRateLimiterBurstExhausts(t *testing.T) {
	rl := newRateLimiter(5, 10)
	for i := 0; i < 5; i++ {
		if !rl.allow() {
			t.Fatalf("allow %d: expected true", i)
		}
	}
	if rl.allow() {
		t.Fatal("allow 6: expected false (burst exhausted)")
	}
}

func TestRateLimiterRefillsOverTime(t *testing.T) {
	rl := newRateLimiter(5, 10) // 10 tokens/sec
	for i := 0; i < 5; i++ {
		rl.allow()
	}
	if rl.allow() {
		t.Fatal("burst should be exhausted before sleep")
	}
	time.Sleep(1200 * time.Millisecond)
	count := 0
	for rl.allow() {
		count++
	}
	if count < 1 {
		t.Fatalf("expected at least 1 token after 1.2s refill, got %d", count)
	}
	if count > 5 {
		t.Fatalf("expected at most burst=5 after refill, got %d", count)
	}
}

func TestRateLimiterAllowRace(t *testing.T) {
	rl := newRateLimiter(100, 1000)
	var wg sync.WaitGroup
	var successes atomic.Int64
	for i := 0; i < 10; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for j := 0; j < 50; j++ {
				if rl.allow() {
					successes.Add(1)
				}
			}
		}()
	}
	wg.Wait()
	// Real assertion is that -race finds no data race. Spot-check the
	// result is within plausible bounds.
	if got := successes.Load(); got <= 0 || got > 500 {
		t.Fatalf("unexpected successes count %d (want 1..500)", got)
	}
}

// ======================================================================
// connTracker unit tests
// ======================================================================

func TestConnTrackerPerIPLimit(t *testing.T) {
	ct := newConnTracker()
	for i := 0; i < maxConnsPerIP; i++ {
		if !ct.tryConnect("10.0.0.1") {
			t.Fatalf("tryConnect %d: expected true", i)
		}
	}
	if ct.tryConnect("10.0.0.1") {
		t.Fatalf("tryConnect %d from same IP: expected false", maxConnsPerIP+1)
	}
}

func TestConnTrackerGlobalLimit(t *testing.T) {
	ct := newConnTracker()
	for i := 0; i < maxGlobalConns; i++ {
		ip := fmt.Sprintf("10.0.%d.%d", i/256, i%256)
		if !ct.tryConnect(ip) {
			t.Fatalf("tryConnect %d (ip=%s): expected true", i, ip)
		}
	}
	if ct.tryConnect("10.99.99.99") {
		t.Fatal("tryConnect should fail once globalCount hits max")
	}
}

func TestConnTrackerDisconnectFrees(t *testing.T) {
	ct := newConnTracker()
	ip := "10.0.0.2"
	for i := 0; i < 5; i++ {
		ct.tryConnect(ip)
	}
	for i := 0; i < 5; i++ {
		ct.disconnect(ip)
	}
	ct.mu.Lock()
	if _, ok := ct.perIP[ip]; ok {
		t.Error("perIP entry should be deleted when count reaches 0")
	}
	if ct.globalCount != 0 {
		t.Errorf("globalCount=%d, want 0", ct.globalCount)
	}
	ct.mu.Unlock()
	// Extra disconnect is a no-op (doesn't panic).
	ct.disconnect(ip)
}

func TestConnTrackerRoomQuota(t *testing.T) {
	ct := newConnTracker()
	ip := "10.0.0.3"
	for i := 0; i < maxRoomsPerIP; i++ {
		if !ct.tryCreateRoom(ip) {
			t.Fatalf("tryCreateRoom %d: expected true", i)
		}
	}
	if ct.tryCreateRoom(ip) {
		t.Fatalf("tryCreateRoom %d: expected false (quota)", maxRoomsPerIP+1)
	}
	ct.releaseRoom(ip)
	if !ct.tryCreateRoom(ip) {
		t.Fatal("tryCreateRoom after release: expected true")
	}
}

func TestConnTrackerCleanupPrunesStaleRateLimiters(t *testing.T) {
	ct := newConnTracker()
	for i := 0; i < 50; i++ {
		ip := fmt.Sprintf("10.0.1.%d", i)
		ct.tryConnect(ip)
		ct.disconnect(ip)
	}
	ct.mu.Lock()
	sizeBefore := len(ct.ipRate)
	ct.mu.Unlock()
	if sizeBefore == 0 {
		t.Fatal("expected some rate limiter entries before cleanup")
	}
	ct.cleanup()
	ct.mu.Lock()
	sizeAfter := len(ct.ipRate)
	ct.mu.Unlock()
	if sizeAfter != 0 {
		t.Errorf("cleanup should prune all stale rate limiters, got %d", sizeAfter)
	}
}

func TestConnTrackerConnectRateLimit(t *testing.T) {
	ct := newConnTracker()
	ip := "10.0.0.4"
	for i := 0; i < connRateBurst; i++ {
		if !ct.tryConnect(ip) {
			t.Fatalf("warmup tryConnect %d: expected true", i)
		}
	}
	// Free one slot so the perIP check won't be what rejects us.
	ct.disconnect(ip)
	// Rate-limit bucket is empty now; this should be the denial path.
	if ct.tryConnect(ip) {
		t.Fatal("expected false from rate-limit bucket, not per-IP cap")
	}
}

// ======================================================================
// clientIP unit tests
// ======================================================================

func TestClientIPFromRemoteAddr(t *testing.T) {
	r := &http.Request{RemoteAddr: "127.0.0.1:12345"}
	if got := clientIP(r); got != "127.0.0.1" {
		t.Fatalf("got %q, want 127.0.0.1", got)
	}
}

func TestClientIPFromXForwardedFor(t *testing.T) {
	r := &http.Request{
		RemoteAddr: "10.0.0.1:8080",
		Header:     http.Header{"X-Forwarded-For": []string{"203.0.113.5, 10.0.0.1"}},
	}
	if got := clientIP(r); got != "203.0.113.5" {
		t.Fatalf("got %q, want 203.0.113.5", got)
	}
}

func TestClientIPXFFTrimsWhitespace(t *testing.T) {
	r := &http.Request{
		Header: http.Header{"X-Forwarded-For": []string{"  203.0.113.5  "}},
	}
	if got := clientIP(r); got != "203.0.113.5" {
		t.Fatalf("got %q, want 203.0.113.5", got)
	}
}

func TestClientIPIPv6NormalizesTo64(t *testing.T) {
	r := &http.Request{RemoteAddr: "[2001:db8:85a3::8a2e:370:7334]:54321"}
	got := clientIP(r)
	if got != "2001:db8:85a3::" {
		t.Fatalf("got %q, want 2001:db8:85a3::", got)
	}
}

// ======================================================================
// generateLogID
// ======================================================================

func TestGenerateLogIDShape(t *testing.T) {
	seen := map[string]struct{}{}
	for i := 0; i < 200; i++ {
		id := generateLogID()
		if len(id) != logIDLength {
			t.Fatalf("len=%d want %d (id=%q)", len(id), logIDLength, id)
		}
		for _, c := range id {
			if !strings.ContainsRune(logIDChars, c) {
				t.Fatalf("id %q has unexpected char %q", id, c)
			}
		}
		if _, dup := seen[id]; dup {
			t.Fatalf("duplicate id %q after %d calls", id, i)
		}
		seen[id] = struct{}{}
	}
}

// ======================================================================
// handleWS — create case
// ======================================================================

func TestCreateSucceeds(t *testing.T) {
	h := newRelayHarness(t)
	c := h.dial(t, "1.1.1.1")
	c.send(clientMsg{Type: "create", SessionID: "ROOM1", PeerID: "host-a"})
	m := c.expect("created")
	if m.SessionID != "ROOM1" {
		t.Errorf("SessionID=%q want ROOM1", m.SessionID)
	}
	h.waitRoomPeers(t, "ROOM1", 1)
}

func TestCreateMissingSessionIDRejected(t *testing.T) {
	h := newRelayHarness(t)
	c := h.dial(t, "1.1.1.2")
	c.send(clientMsg{Type: "create", PeerID: "host-a"})
	c.expectError("invalid_message")
}

func TestCreateMissingPeerIDRejected(t *testing.T) {
	h := newRelayHarness(t)
	c := h.dial(t, "1.1.1.3")
	c.send(clientMsg{Type: "create", SessionID: "ROOM1"})
	c.expectError("invalid_message")
}

func TestCreateDuplicateReturnsRoomExists(t *testing.T) {
	h := newRelayHarness(t)
	c1 := h.dial(t, "1.1.1.4")
	c1.send(clientMsg{Type: "create", SessionID: "SAME", PeerID: "host-1"})
	c1.expect("created")

	// Different IP to avoid the per-IP rooms quota interfering.
	c2 := h.dial(t, "1.1.1.5")
	c2.send(clientMsg{Type: "create", SessionID: "SAME", PeerID: "host-2"})
	c2.expectError("room_exists")
}

func TestCreateReclaimsEmptyStaleRoom(t *testing.T) {
	h := newRelayHarness(t)
	// Pre-seed an empty stale room — mimics a post-restart reload.
	h.srv.mu.Lock()
	h.srv.rooms["STALE"] = &Room{
		SessionID:      "STALE",
		HostPeerID:     "old-host",
		Peers:          map[string]*Client{},
		CreatedAt:      time.Now().Add(-time.Hour),
		LastActivityAt: time.Now().Add(-time.Hour),
	}
	h.srv.mu.Unlock()

	c := h.dial(t, "1.1.1.6")
	c.send(clientMsg{Type: "create", SessionID: "STALE", PeerID: "new-host"})
	c.expect("created")

	h.waitRoomPeers(t, "STALE", 1)
	h.srv.mu.RLock()
	room := h.srv.rooms["STALE"]
	h.srv.mu.RUnlock()
	room.mu.RLock()
	host := room.HostPeerID
	room.mu.RUnlock()
	if host != "new-host" {
		t.Errorf("HostPeerID=%q, reclaim should have reset to new-host", host)
	}
}

func TestCreateHitsRoomsPerIPLimit(t *testing.T) {
	h := newRelayHarness(t)
	ip := "1.1.1.7"
	for i := 0; i < maxRoomsPerIP; i++ {
		c := h.dial(t, ip)
		c.send(clientMsg{Type: "create", SessionID: fmt.Sprintf("R%d", i), PeerID: "host"})
		c.expect("created")
	}
	// 4th create from same IP exceeds the quota.
	c := h.dial(t, ip)
	c.send(clientMsg{Type: "create", SessionID: "ROVERFLOW", PeerID: "host"})
	c.expectError("rate_limited")
}

// ======================================================================
// handleWS — join case
// ======================================================================

func TestJoinSucceedsAndBroadcastsPeerJoined(t *testing.T) {
	h := newRelayHarness(t)
	host := h.dial(t, "2.0.0.1")
	host.send(clientMsg{Type: "create", SessionID: "J1", PeerID: "H"})
	host.expect("created")

	guest := h.dial(t, "2.0.0.2")
	guest.send(clientMsg{Type: "join", SessionID: "J1", PeerID: "G"})
	joined := guest.expect("joined")
	if joined.SessionID != "J1" {
		t.Errorf("SessionID=%q want J1", joined.SessionID)
	}
	if len(joined.Peers) != 1 || joined.Peers[0] != "H" {
		t.Errorf("Peers=%v, want [H]", joined.Peers)
	}

	// Host is broadcast a peerJoined for the new guest.
	peerJoined := host.expect("peerJoined")
	if peerJoined.PeerID != "G" {
		t.Errorf("peerJoined.PeerID=%q want G", peerJoined.PeerID)
	}
}

func TestJoinMissingFieldsRejected(t *testing.T) {
	h := newRelayHarness(t)
	c := h.dial(t, "2.0.0.3")
	c.send(clientMsg{Type: "join"})
	c.expectError("invalid_message")
}

func TestJoinUnknownRoomFails(t *testing.T) {
	h := newRelayHarness(t)
	c := h.dial(t, "2.0.0.4")
	c.send(clientMsg{Type: "join", SessionID: "NOPE", PeerID: "G"})
	c.expectError("room_not_found")
}

func TestJoinFullRoomRejected(t *testing.T) {
	h := newRelayHarness(t)
	host := h.dial(t, "2.1.0.1")
	host.send(clientMsg{Type: "create", SessionID: "FULL", PeerID: "H"})
	host.expect("created")

	// Fill up to maxRoomSize (host is #1), each from a distinct IP to avoid per-IP conn cap.
	for i := 1; i < maxRoomSize; i++ {
		guest := h.dial(t, fmt.Sprintf("2.1.0.%d", 100+i))
		guest.send(clientMsg{Type: "join", SessionID: "FULL", PeerID: fmt.Sprintf("G%d", i)})
		guest.expect("joined")
	}

	overflow := h.dial(t, "2.1.0.250")
	overflow.send(clientMsg{Type: "join", SessionID: "FULL", PeerID: "LATE"})
	overflow.expectError("room_full")
}

// ======================================================================
// handleWS — broadcast / sendTo
// ======================================================================

func TestBroadcastDeliversToOthersNotSender(t *testing.T) {
	h := newRelayHarness(t)
	host := h.dial(t, "3.0.0.1")
	host.send(clientMsg{Type: "create", SessionID: "B1", PeerID: "H"})
	host.expect("created")

	g1 := h.dial(t, "3.0.0.2")
	g1.send(clientMsg{Type: "join", SessionID: "B1", PeerID: "G1"})
	g1.expect("joined")
	host.expect("peerJoined")

	g2 := h.dial(t, "3.0.0.3")
	g2.send(clientMsg{Type: "join", SessionID: "B1", PeerID: "G2"})
	g2.expect("joined")
	host.expect("peerJoined")
	g1.expect("peerJoined")

	payload := json.RawMessage(`{"hello":"world"}`)
	g1.send(clientMsg{Type: "broadcast", Payload: payload})

	hostMsg := host.expect("message")
	if hostMsg.From != "G1" {
		t.Errorf("host From=%q want G1", hostMsg.From)
	}
	if string(hostMsg.Payload) != string(payload) {
		t.Errorf("host payload=%s want %s", hostMsg.Payload, payload)
	}
	g2Msg := g2.expect("message")
	if g2Msg.From != "G1" {
		t.Errorf("g2 From=%q want G1", g2Msg.From)
	}

	// Sender should not receive its own broadcast.
	g1.recvNothing(200 * time.Millisecond)
}

func TestBroadcastNotInRoomRejected(t *testing.T) {
	h := newRelayHarness(t)
	c := h.dial(t, "3.0.0.4")
	c.send(clientMsg{Type: "broadcast", Payload: json.RawMessage(`{}`)})
	c.expectError("not_in_room")
}

func TestSendToDeliversToTargetOnly(t *testing.T) {
	h := newRelayHarness(t)
	host := h.dial(t, "4.0.0.1")
	host.send(clientMsg{Type: "create", SessionID: "S1", PeerID: "H"})
	host.expect("created")

	g1 := h.dial(t, "4.0.0.2")
	g1.send(clientMsg{Type: "join", SessionID: "S1", PeerID: "G1"})
	g1.expect("joined")
	host.expect("peerJoined")

	g2 := h.dial(t, "4.0.0.3")
	g2.send(clientMsg{Type: "join", SessionID: "S1", PeerID: "G2"})
	g2.expect("joined")
	host.expect("peerJoined")
	g1.expect("peerJoined")

	payload := json.RawMessage(`{"direct":true}`)
	host.send(clientMsg{Type: "sendTo", To: "G1", Payload: payload})

	m := g1.expect("message")
	if m.From != "H" {
		t.Errorf("From=%q want H", m.From)
	}
	if string(m.Payload) != string(payload) {
		t.Errorf("payload mismatch: %s", m.Payload)
	}
	g2.recvNothing(200 * time.Millisecond)
}

func TestSendToUnknownTargetRejected(t *testing.T) {
	h := newRelayHarness(t)
	host := h.dial(t, "4.0.0.4")
	host.send(clientMsg{Type: "create", SessionID: "S2", PeerID: "H"})
	host.expect("created")

	host.send(clientMsg{Type: "sendTo", To: "ghost", Payload: json.RawMessage(`{}`)})
	host.expectError("not_in_room")
}

func TestSendToMissingToRejected(t *testing.T) {
	h := newRelayHarness(t)
	host := h.dial(t, "4.0.0.5")
	host.send(clientMsg{Type: "create", SessionID: "S3", PeerID: "H"})
	host.expect("created")

	host.send(clientMsg{Type: "sendTo", Payload: json.RawMessage(`{}`)})
	host.expectError("invalid_message")
}

func TestSendToNotInRoomRejected(t *testing.T) {
	h := newRelayHarness(t)
	c := h.dial(t, "4.0.0.6")
	c.send(clientMsg{Type: "sendTo", To: "anyone", Payload: json.RawMessage(`{}`)})
	c.expectError("not_in_room")
}

// ======================================================================
// handleWS — ping / misc / rate limits
// ======================================================================

func TestPingReturnsPong(t *testing.T) {
	h := newRelayHarness(t)
	c := h.dial(t, "5.0.0.1")
	c.send(clientMsg{Type: "ping"})
	c.expect("pong")
}

func TestUnknownTypeRejected(t *testing.T) {
	h := newRelayHarness(t)
	c := h.dial(t, "5.0.0.2")
	c.send(clientMsg{Type: "nope"})
	c.expectError("invalid_message")
}

func TestInvalidJSONRejected(t *testing.T) {
	h := newRelayHarness(t)
	c := h.dial(t, "5.0.0.3")
	c.sendRaw([]byte("not json {{{"))
	c.expectError("invalid_message")
}

func TestPerConnectionMessageRateLimit(t *testing.T) {
	h := newRelayHarness(t)
	c := h.dial(t, "5.0.0.4")
	c.send(clientMsg{Type: "create", SessionID: "RL", PeerID: "H"})
	c.expect("created")

	// The per-connection bucket is rateBurst=30. After ~30 pings we start seeing rate_limited.
	sawRateLimit := false
	for i := 0; i < rateBurst+10; i++ {
		c.send(clientMsg{Type: "ping"})
	}
	for i := 0; i < rateBurst+10; i++ {
		m := c.recv()
		if m.Code == "rate_limited" {
			sawRateLimit = true
			break
		}
	}
	if !sawRateLimit {
		t.Fatal("expected to hit rate_limited within burst+10 messages")
	}
}

// ======================================================================
// handleWS — disconnect lifecycle
// ======================================================================

func TestDisconnectBroadcastsPeerLeft(t *testing.T) {
	h := newRelayHarness(t)
	host := h.dial(t, "6.0.0.1")
	host.send(clientMsg{Type: "create", SessionID: "D1", PeerID: "H"})
	host.expect("created")

	guest := h.dial(t, "6.0.0.2")
	guest.send(clientMsg{Type: "join", SessionID: "D1", PeerID: "G"})
	guest.expect("joined")
	host.expect("peerJoined")

	guest.conn.Close()

	left := host.expect("peerLeft")
	if left.PeerID != "G" {
		t.Errorf("PeerID=%q, want G", left.PeerID)
	}
}

func TestStalePeerSkipsCleanupBroadcast(t *testing.T) {
	h := newRelayHarness(t)
	host := h.dial(t, "6.1.0.1")
	host.send(clientMsg{Type: "create", SessionID: "D2", PeerID: "H"})
	host.expect("created")

	g1 := h.dial(t, "6.1.0.2")
	g1.send(clientMsg{Type: "join", SessionID: "D2", PeerID: "G"})
	g1.expect("joined")
	host.expect("peerJoined")

	// Second connection with the SAME peerId overwrites room.Peers["G"].
	g2 := h.dial(t, "6.1.0.3")
	g2.send(clientMsg{Type: "join", SessionID: "D2", PeerID: "G"})
	g2.expect("joined")
	host.expect("peerJoined")

	// Now close g1 — its defer should see the stale client and NOT broadcast peerLeft.
	g1.conn.Close()
	host.recvNothing(300 * time.Millisecond)
}

// ======================================================================
// Logs endpoints
// ======================================================================

func postLog(t *testing.T, baseURL, ip string, body []byte) *http.Response {
	t.Helper()
	req, err := http.NewRequest(http.MethodPost, baseURL+"/logs", bytes.NewReader(body))
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	if ip != "" {
		req.Header.Set("X-Forwarded-For", ip)
	}
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatalf("post: %v", err)
	}
	return resp
}

// postLogAndGetID uploads a log and returns the generated id, asserting the
// POST succeeded.
func postLogAndGetID(t *testing.T, baseURL, ip string, body []byte) string {
	t.Helper()
	resp := postLog(t, baseURL, ip, body)
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("post status=%d", resp.StatusCode)
	}
	var out struct {
		ID string `json:"id"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&out); err != nil {
		t.Fatalf("decode: %v", err)
	}
	if len(out.ID) != logIDLength {
		t.Fatalf("id=%q len=%d want %d", out.ID, len(out.ID), logIDLength)
	}
	return out.ID
}

func TestLogsRoundTrip(t *testing.T) {
	h := newRelayHarness(t)
	payload := []byte("hello log world")
	id := postLogAndGetID(t, h.baseURL, "7.0.0.1", payload)

	getResp, err := http.Get(h.baseURL + "/logs/" + id)
	if err != nil {
		t.Fatalf("get: %v", err)
	}
	defer getResp.Body.Close()
	if getResp.StatusCode != http.StatusOK {
		t.Fatalf("get status=%d", getResp.StatusCode)
	}
	got, _ := io.ReadAll(getResp.Body)
	if !bytes.Equal(got, payload) {
		t.Fatalf("round-tripped bytes mismatch: got %q want %q", got, payload)
	}
	if ct := getResp.Header.Get("Content-Type"); !strings.HasPrefix(ct, "text/plain") {
		t.Errorf("Content-Type=%q", ct)
	}
}

func TestLogsUploadRateLimitedPerIP(t *testing.T) {
	h := newRelayHarness(t)
	r1 := postLog(t, h.baseURL, "7.0.0.2", []byte("first"))
	r1.Body.Close()
	if r1.StatusCode != http.StatusOK {
		t.Fatalf("first post status=%d", r1.StatusCode)
	}
	r2 := postLog(t, h.baseURL, "7.0.0.2", []byte("second"))
	r2.Body.Close()
	if r2.StatusCode != http.StatusTooManyRequests {
		t.Fatalf("second post status=%d want 429", r2.StatusCode)
	}
}

func TestLogsUploadTooLargeRejected(t *testing.T) {
	h := newRelayHarness(t)
	body := make([]byte, maxLogSize+1)
	resp := postLog(t, h.baseURL, "7.0.0.3", body)
	resp.Body.Close()
	if resp.StatusCode != http.StatusRequestEntityTooLarge {
		t.Fatalf("status=%d want 413", resp.StatusCode)
	}
}

func TestLogsUploadEmptyRejected(t *testing.T) {
	h := newRelayHarness(t)
	resp := postLog(t, h.baseURL, "7.0.0.4", nil)
	resp.Body.Close()
	if resp.StatusCode != http.StatusBadRequest {
		t.Fatalf("status=%d want 400", resp.StatusCode)
	}
}

func TestLogsUploadStoreFull(t *testing.T) {
	h := newRelayHarness(t)
	// Saturate the store with distinct IPs so per-IP rate limit doesn't bite.
	for i := 0; i < maxLogEntries; i++ {
		ip := fmt.Sprintf("7.1.%d.%d", i/256, i%256)
		resp := postLog(t, h.baseURL, ip, []byte("x"))
		resp.Body.Close()
		if resp.StatusCode != http.StatusOK {
			t.Fatalf("warmup %d (ip=%s) status=%d", i, ip, resp.StatusCode)
		}
	}
	resp := postLog(t, h.baseURL, "7.2.0.1", []byte("overflow"))
	resp.Body.Close()
	if resp.StatusCode != http.StatusServiceUnavailable {
		t.Fatalf("overflow status=%d want 503", resp.StatusCode)
	}
}

func TestLogsGetUnknownIDIs404(t *testing.T) {
	h := newRelayHarness(t)
	resp, err := http.Get(h.baseURL + "/logs/abcde")
	if err != nil {
		t.Fatalf("get: %v", err)
	}
	resp.Body.Close()
	if resp.StatusCode != http.StatusNotFound {
		t.Fatalf("status=%d want 404", resp.StatusCode)
	}
}

func TestLogsGetMalformedIDIs404(t *testing.T) {
	h := newRelayHarness(t)
	for _, id := range []string{"", "abc", "toolongid"} {
		resp, err := http.Get(h.baseURL + "/logs/" + id)
		if err != nil {
			t.Fatalf("get %q: %v", id, err)
		}
		resp.Body.Close()
		if resp.StatusCode != http.StatusNotFound {
			t.Errorf("id=%q status=%d want 404", id, resp.StatusCode)
		}
	}
}

func TestLogsGetExpiredIs404(t *testing.T) {
	h := newRelayHarness(t)
	id := postLogAndGetID(t, h.baseURL, "7.3.0.1", []byte("temp"))

	// Poison the entry's ExpiresAt into the past.
	h.srv.logs.mu.Lock()
	entry := h.srv.logs.entries[id]
	entry.ExpiresAt = time.Now().Add(-time.Minute)
	h.srv.logs.entries[id] = entry
	h.srv.logs.mu.Unlock()

	get, err := http.Get(h.baseURL + "/logs/" + id)
	if err != nil {
		t.Fatalf("get: %v", err)
	}
	get.Body.Close()
	if get.StatusCode != http.StatusNotFound {
		t.Fatalf("status=%d want 404", get.StatusCode)
	}
}

func TestLogsMethodNotAllowed(t *testing.T) {
	h := newRelayHarness(t)
	resp, err := http.Get(h.baseURL + "/logs")
	if err != nil {
		t.Fatalf("get: %v", err)
	}
	resp.Body.Close()
	if resp.StatusCode != http.StatusMethodNotAllowed {
		t.Errorf("GET /logs status=%d want 405", resp.StatusCode)
	}
}

func TestHealthEndpointReturnsOK(t *testing.T) {
	h := newRelayHarness(t)
	resp, err := http.Get(h.baseURL + "/health")
	if err != nil {
		t.Fatalf("get: %v", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("status=%d", resp.StatusCode)
	}
	body, _ := io.ReadAll(resp.Body)
	if string(body) != "ok" {
		t.Fatalf("body=%q want ok", body)
	}
}

// ======================================================================
// End-to-end: rooms survive a process restart
// ======================================================================

func TestSnapshotSurvivesRestart(t *testing.T) {
	stateFile := filepath.Join(t.TempDir(), "rooms.json")

	hA := newRelayHarnessAt(t, t.TempDir(), stateFile)
	host := hA.dial(t, "8.0.0.1")
	host.send(clientMsg{Type: "create", SessionID: "RESUM", PeerID: "H"})
	host.expect("created")
	guest := hA.dial(t, "8.0.0.2")
	guest.send(clientMsg{Type: "join", SessionID: "RESUM", PeerID: "G"})
	guest.expect("joined")
	host.expect("peerJoined")

	// Force an early flush so hB can load a populated snapshot. hA's
	// t.Cleanup will call flushAndStop again — sync.Once makes it a no-op.
	if err := hA.srv.snap.flushAndStop(2 * time.Second); err != nil {
		t.Fatalf("flushAndStop: %v", err)
	}
	if _, err := os.Stat(stateFile); err != nil {
		t.Fatalf("snapshot file missing after flush: %v", err)
	}

	hB := newRelayHarnessAt(t, t.TempDir(), stateFile)
	hB.srv.mu.RLock()
	_, reloaded := hB.srv.rooms["RESUM"]
	hB.srv.mu.RUnlock()
	if !reloaded {
		t.Fatal("room RESUM was not reloaded from snapshot")
	}

	g2 := hB.dial(t, "8.0.0.3")
	g2.send(clientMsg{Type: "join", SessionID: "RESUM", PeerID: "G2"})
	g2.expect("joined")
}
