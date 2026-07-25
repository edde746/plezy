package main

import (
	"bufio"
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"io/fs"
	"log"
	"math"
	"net"
	"net/http"
	"net/http/httptest"
	"net/url"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"sync/atomic"
	"syscall"
	"testing"
	"time"

	"github.com/gorilla/websocket"
)

func TestGeneratedRelayProtocolVersionsMatchSpec(t *testing.T) {
	data, err := os.ReadFile(filepath.Join("..", "relay_protocol.json"))
	if err != nil {
		t.Fatalf("read relay protocol spec: %v", err)
	}
	var spec struct {
		ProtocolVersion       int `json:"protocolVersion"`
		LegacyProtocolVersion int `json:"legacyProtocolVersion"`
	}
	if err := json.Unmarshal(data, &spec); err != nil {
		t.Fatalf("decode relay protocol spec: %v", err)
	}
	if relayProtocolVersion != spec.ProtocolVersion ||
		legacyRelayProtocolVersion != spec.LegacyProtocolVersion {
		t.Fatalf(
			"generated versions=(%d,%d), spec=(%d,%d)",
			relayProtocolVersion,
			legacyRelayProtocolVersion,
			spec.ProtocolVersion,
			spec.LegacyProtocolVersion,
		)
	}
}

// newTestServer builds a Server wired for tests: no goroutines and no network.
// Its snapshotter is not started; storage tests drive the narrow synchronous
// write entry directly.
func newTestServer(t *testing.T, stateFile string) *Server {
	t.Helper()
	s := &Server{
		rooms:         make(map[string]*Room),
		logs:          newLogStore(t.TempDir()),
		posters:       newPosterStore(t.TempDir(), maxPosterStoreSize, posterMaxAge),
		posterUploads: newPosterUploadLimiter(posterPerIPRateBurst, posterPerIPRateSustained, posterGlobalRateBurst, posterGlobalRateSustained, maxConcurrentPosterUploads, time.Now()),
		conns:         newConnTracker(),
		clientIPs:     newClientIPResolver(nil),
	}
	s.snap = newSnapshotter(stateFile, s.buildSnapshot)
	return s
}

func mustReconnectToken(t *testing.T) (string, reconnectVerifier) {
	t.Helper()
	token, verifier, err := mintReconnectToken()
	if err != nil {
		t.Fatalf("mint reconnect token: %v", err)
	}
	return token, verifier
}

func makeRoomSnapshots(count int, maximumLengthIDs bool, now time.Time) []roomSnapshot {
	rooms := make([]roomSnapshot, 0, count)
	for i := range count {
		suffix := fmt.Sprintf("%04d", i)
		sessionID := "S" + suffix
		hostPeerID := "H"
		if maximumLengthIDs {
			sessionID = suffix + strings.Repeat("S", maxSessionIDLength-len(suffix))
			hostPeerID = strings.Repeat("H", maxPeerIDLength)
		}
		rooms = append(rooms, roomSnapshot{
			SessionID:             sessionID,
			HostPeerID:            hostPeerID,
			HostReconnectVerifier: encodeReconnectVerifier(reconnectVerifier{1}),
			CreatedAt:             now.Add(-time.Minute),
			LastActivityAt:        now,
		})
	}
	return rooms
}

func TestSnapshotRoundTrip(t *testing.T) {
	dir := t.TempDir()
	path := filepath.Join(dir, "rooms.json")
	s := newTestServer(t, path)

	now := time.Now().UTC().Truncate(time.Second)
	_, verifier1 := mustReconnectToken(t)
	_, verifier2 := mustReconnectToken(t)
	s.rooms["ABC12"] = &Room{
		SessionID:        "ABC12",
		HostPeerID:       "host-1",
		hostVerifier:     verifier1,
		peerReservations: make(map[string]peerReservation),
		Peers:            map[string]*Client{},
		CreatedAt:        now.Add(-time.Minute),
		LastActivityAt:   now,
		quotaOwnerKey:    "203.0.113.44",
	}
	s.rooms["XYZ99"] = &Room{
		SessionID:        "XYZ99",
		HostPeerID:       "host-2",
		hostVerifier:     verifier2,
		peerReservations: make(map[string]peerReservation),
		Peers:            map[string]*Client{},
		CreatedAt:        now.Add(-time.Hour),
		LastActivityAt:   now.Add(-time.Second),
	}

	if err := s.snap.write(); err != nil {
		t.Fatalf("write: %v", err)
	}
	data, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("read snapshot: %v", err)
	}
	if bytes.Contains(data, []byte("203.0.113.44")) || bytes.Contains(data, []byte("quotaOwner")) {
		t.Fatalf("snapshot persisted process-local client identity: %s", data)
	}

	// Reconstruct into a fresh Server and verify identity.
	s2 := newTestServer(t, path)
	if _, err := s2.loadSnapshot(path); err != nil {
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
		if !reconnectVerifierMatches(r.hostVerifier, orig.hostVerifier) {
			t.Errorf("%s: host reconnect verifier did not round-trip", id)
		}
		if !r.CreatedAt.Equal(orig.CreatedAt) {
			t.Errorf("%s: CreatedAt=%v want %v", id, r.CreatedAt, orig.CreatedAt)
		}
		if !r.LastActivityAt.Equal(orig.LastActivityAt) {
			t.Errorf("%s: LastActivityAt=%v want %v", id, r.LastActivityAt, orig.LastActivityAt)
		}
		if r.quotaOwnerKey != "" {
			t.Errorf("%s: quotaOwnerKey=%q after reload, want empty", id, r.quotaOwnerKey)
		}
		if r.Peers == nil {
			t.Errorf("%s: Peers map nil after reload", id)
		}
		if len(r.Peers) != 0 {
			t.Errorf("%s: expected empty Peers, got %d", id, len(r.Peers))
		}
	}
	s2.conns.mu.Lock()
	defer s2.conns.mu.Unlock()
	if len(s2.conns.roomsPerIP) != 0 {
		t.Fatalf("reload restored process-local room quota: %v", s2.conns.roomsPerIP)
	}
}

func TestLoadSkipsExpired(t *testing.T) {
	dir := t.TempDir()
	path := filepath.Join(dir, "rooms.json")
	now := time.Now()
	_, verifier := mustReconnectToken(t)
	encodedVerifier := encodeReconnectVerifier(verifier)

	snap := stateSnapshot{
		Version: snapshotFormatVersion,
		SavedAt: now,
		Rooms: []roomSnapshot{
			{SessionID: "FRESH", HostPeerID: "h", HostReconnectVerifier: encodedVerifier, CreatedAt: now.Add(-time.Minute), LastActivityAt: now.Add(-30 * time.Second)},
			{SessionID: "OLD24", HostPeerID: "h", HostReconnectVerifier: encodedVerifier, CreatedAt: now.Add(-25 * time.Hour), LastActivityAt: now.Add(-time.Second)},
			{SessionID: "IDLE6", HostPeerID: "h", HostReconnectVerifier: encodedVerifier, CreatedAt: now.Add(-2 * time.Hour), LastActivityAt: now.Add(-6 * time.Minute)},
			{SessionID: "", HostPeerID: "h", HostReconnectVerifier: encodedVerifier, CreatedAt: now, LastActivityAt: now},
			{SessionID: "NOHOS", HostPeerID: "", HostReconnectVerifier: encodedVerifier, CreatedAt: now, LastActivityAt: now},
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
	if _, err := s.loadSnapshot(path); err != nil {
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
	if _, err := s.loadSnapshot(path); err != nil {
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
	if _, err := s.loadSnapshot(path); err != nil {
		t.Fatalf("loadSnapshot: %v", err)
	}
	if len(s.rooms) != 0 {
		t.Fatalf("expected empty rooms, got %d", len(s.rooms))
	}
}

func TestLoadRejectsSnapshotsWithoutHostAuthority(t *testing.T) {
	for _, version := range []int{1, 99} {
		t.Run(fmt.Sprintf("version_%d", version), func(t *testing.T) {
			path := filepath.Join(t.TempDir(), "rooms.json")
			data := []byte(fmt.Sprintf(`{"version":%d,"rooms":[{"sessionId":"X","hostPeerId":"H"}]}`, version))
			if err := os.WriteFile(path, data, 0644); err != nil {
				t.Fatalf("write: %v", err)
			}
			s := newTestServer(t, path)
			if _, err := s.loadSnapshot(path); err != nil {
				t.Fatalf("loadSnapshot: %v", err)
			}
			if len(s.rooms) != 0 {
				t.Fatalf("expected empty rooms for version %d, got %d", version, len(s.rooms))
			}
		})
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

func TestRemoveRoomLockedReleasesOwnedQuotaExactlyOnce(t *testing.T) {
	s := newTestServer(t, filepath.Join(t.TempDir(), "rooms.json"))
	ownerKey := "203.0.113.8"
	room := &Room{
		SessionID:     "OWNED",
		HostPeerID:    "H",
		Peers:         map[string]*Client{},
		quotaOwnerKey: ownerKey,
	}
	s.rooms[room.SessionID] = room
	if !s.conns.tryCreateRoom(ownerKey) {
		t.Fatal("reserve room quota")
	}

	s.mu.Lock()
	firstRemoval := s.removeRoomLocked(room.SessionID, room)
	secondRemoval := s.removeRoomLocked(room.SessionID, room)
	s.mu.Unlock()
	if !firstRemoval || secondRemoval {
		t.Fatalf("first removal=%v second removal=%v, want true then false", firstRemoval, secondRemoval)
	}
	s.conns.mu.Lock()
	remaining := s.conns.roomsPerIP[ownerKey]
	s.conns.mu.Unlock()
	if remaining != 0 {
		t.Fatalf("quota after repeated removal=%d, want 0", remaining)
	}

	replacement := &Room{SessionID: room.SessionID, Peers: map[string]*Client{}}
	s.mu.Lock()
	s.rooms[room.SessionID] = replacement
	staleRemoval := s.removeRoomLocked(room.SessionID, room)
	authoritative := s.rooms[room.SessionID]
	s.mu.Unlock()
	if staleRemoval || authoritative != replacement {
		t.Fatal("stale pointer removed the authoritative replacement")
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

	// Block the temporary-file open with a directory at the same path. This
	// deterministically fails before rename on every supported platform.
	if err := os.Mkdir(path+".tmp", 0755); err != nil {
		t.Fatalf("create blocking temporary directory: %v", err)
	}

	delete(s.rooms, "ORIG")
	s.rooms["NEW"] = &Room{
		SessionID:      "NEW",
		HostPeerID:     "h",
		Peers:          map[string]*Client{},
		CreatedAt:      time.Now(),
		LastActivityAt: time.Now(),
	}
	if err := s.snap.write(); err == nil {
		t.Fatal("expected pre-rename snapshot write failure")
	}

	nowBytes, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("read after failed write: %v", err)
	}
	if string(origBytes) != string(nowBytes) {
		t.Fatalf("snapshot file was corrupted after failed write:\nbefore: %s\nafter:  %s", origBytes, nowBytes)
	}
}

func TestSnapshotRenameFailureIsPreCommit(t *testing.T) {
	root := t.TempDir()
	path := filepath.Join(root, "rooms.json")
	if err := os.Mkdir(path, 0755); err != nil {
		t.Fatalf("create conflicting snapshot directory: %v", err)
	}
	markerPath := filepath.Join(path, "marker")
	if err := os.WriteFile(markerPath, []byte("preserved"), 0644); err != nil {
		t.Fatalf("write destination marker: %v", err)
	}

	snapshot := stateSnapshot{
		Version: snapshotFormatVersion,
		SavedAt: time.Now(),
	}
	sn := newSnapshotter(path, func() stateSnapshot { return snapshot })
	syncCalled := false
	sn.syncDir = func(string) error {
		syncCalled = true
		return nil
	}
	if err := sn.write(); err == nil {
		t.Fatal("snapshot rename over a directory succeeded")
	}
	if syncCalled {
		t.Fatal("directory sync ran after failed rename")
	}
	marker, err := os.ReadFile(markerPath)
	if err != nil {
		t.Fatalf("read destination marker after failed rename: %v", err)
	}
	if string(marker) != "preserved" {
		t.Fatalf("rename failure changed destination marker: %q", marker)
	}
	if _, err := os.Stat(path + ".tmp"); !errors.Is(err, fs.ErrNotExist) {
		t.Fatalf("temporary snapshot remains after failed rename: %v", err)
	}
}

func TestSnapshotWriteRejectsOversizeAndPreservesLastValidFile(t *testing.T) {
	path := filepath.Join(t.TempDir(), "rooms.json")
	s := newTestServer(t, path)
	now := time.Now()
	s.rooms["ORIG"] = &Room{
		SessionID:      "ORIG",
		HostPeerID:     "H",
		Peers:          map[string]*Client{},
		CreatedAt:      now,
		LastActivityAt: now,
	}
	if err := s.snap.write(); err != nil {
		t.Fatalf("write valid snapshot: %v", err)
	}
	original, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("read valid snapshot: %v", err)
	}

	s.snap.build = func() stateSnapshot {
		return stateSnapshot{
			Version: snapshotFormatVersion,
			SavedAt: now,
			Rooms: []roomSnapshot{{
				SessionID:      strings.Repeat("S", snapshotMaxFileSize),
				HostPeerID:     "H",
				CreatedAt:      now,
				LastActivityAt: now,
			}},
		}
	}
	if err := s.snap.write(); err == nil {
		t.Fatal("oversized snapshot write succeeded")
	}
	after, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("read preserved snapshot: %v", err)
	}
	if !bytes.Equal(after, original) {
		t.Fatal("oversized write replaced the last valid snapshot")
	}

	reloaded := newTestServer(t, path)
	if _, err := reloaded.loadSnapshot(path); err != nil {
		t.Fatalf("load preserved snapshot: %v", err)
	}
	if _, ok := reloaded.rooms["ORIG"]; !ok {
		t.Fatal("last valid snapshot did not survive oversized write")
	}
}

func TestSnapshotAtRetainedRoomCapFitsAndReloads(t *testing.T) {
	path := filepath.Join(t.TempDir(), "rooms.json")
	s := newTestServer(t, path)
	now := time.Now().UTC()
	for _, room := range makeRoomSnapshots(maxRetainedRooms, true, now) {
		reservations := make(map[string]peerReservation, maxRoomSize-1)
		for index := range maxRoomSize - 1 {
			prefix := fmt.Sprintf("G%d", index)
			peerID := prefix + strings.Repeat("G", maxPeerIDLength-len(prefix))
			reservations[peerID] = peerReservation{
				verifier:    reconnectVerifier{byte(index + 1)},
				absentSince: now.Add(-time.Minute),
			}
		}
		s.rooms[room.SessionID] = &Room{
			SessionID:        room.SessionID,
			HostPeerID:       room.HostPeerID,
			ProtocolVersion:  relayProtocolVersion,
			peerReservations: reservations,
			Peers:            map[string]*Client{},
			CreatedAt:        room.CreatedAt,
			LastActivityAt:   room.LastActivityAt,
		}
	}

	snapshot := s.buildSnapshot()
	data, err := json.Marshal(snapshot)
	if err != nil {
		t.Fatalf("marshal maximum snapshot: %v", err)
	}
	if len(data) > snapshotMaxFileSize {
		t.Fatalf("maximum admitted snapshot is %d bytes, exceeds %d", len(data), snapshotMaxFileSize)
	}
	if err := s.snap.write(); err != nil {
		t.Fatalf("write maximum snapshot: %v", err)
	}

	reloaded := newTestServer(t, path)
	if _, err := reloaded.loadSnapshot(path); err != nil {
		t.Fatalf("load maximum snapshot: %v", err)
	}
	if got := len(reloaded.rooms); got != maxRetainedRooms {
		t.Fatalf("reloaded rooms=%d, want %d", got, maxRetainedRooms)
	}
	for _, expected := range snapshot.Rooms {
		room := reloaded.rooms[expected.SessionID]
		if room == nil || room.Peers == nil {
			t.Fatalf("room %q is not available for joins after reload", expected.SessionID)
		}
		if len(room.peerReservations) != maxRoomSize-1 {
			t.Fatalf("room %q reloaded %d reservations, want %d", expected.SessionID, len(room.peerReservations), maxRoomSize-1)
		}
	}
}

func TestLoadRejectsSnapshotOverRetainedRoomCapWithoutPartialState(t *testing.T) {
	path := filepath.Join(t.TempDir(), "rooms.json")
	now := time.Now().UTC()
	snapshot := stateSnapshot{
		Version: snapshotFormatVersion,
		SavedAt: now,
		Rooms:   makeRoomSnapshots(maxRetainedRooms+1, false, now),
	}
	data, err := json.Marshal(snapshot)
	if err != nil {
		t.Fatalf("marshal over-count snapshot: %v", err)
	}
	if len(data) > snapshotMaxFileSize {
		t.Fatalf("over-count fixture is %d bytes, must exercise count limit below %d", len(data), snapshotMaxFileSize)
	}
	if err := os.WriteFile(path, data, 0644); err != nil {
		t.Fatalf("write over-count snapshot: %v", err)
	}

	s := newTestServer(t, path)
	if _, err := s.loadSnapshot(path); err != nil {
		t.Fatalf("loadSnapshot: %v", err)
	}
	if len(s.rooms) != 0 {
		t.Fatalf("over-count snapshot partially loaded %d rooms", len(s.rooms))
	}
	s.conns.mu.Lock()
	defer s.conns.mu.Unlock()
	if len(s.conns.roomsPerIP) != 0 {
		t.Fatalf("over-count snapshot changed process quota state: %v", s.conns.roomsPerIP)
	}
	if _, err := os.Stat(path); err != nil {
		t.Fatalf("rejected snapshot was not preserved: %v", err)
	}
}

func TestSnapshotDebounceCoalesces(t *testing.T) {
	dir := t.TempDir()
	path := filepath.Join(dir, "rooms.json")

	var (
		buildCount int
		countMu    sync.Mutex
	)
	built := make(chan struct{}, 1)
	sn := newSnapshotter(path, func() stateSnapshot {
		countMu.Lock()
		buildCount++
		countMu.Unlock()
		select {
		case built <- struct{}{}:
		default:
		}
		return stateSnapshot{Version: snapshotFormatVersion, SavedAt: time.Now(), Rooms: nil}
	})
	go sn.run()
	t.Cleanup(func() { _ = sn.flushAndStop(time.Second) })

	// Fire a burst — should collapse into one write due to debounce.
	for i := 0; i < 20; i++ {
		sn.recordMutation()
	}
	select {
	case <-built:
	case <-time.After(2 * time.Second):
		t.Fatal("timed out waiting for debounced snapshot build")
	}
	quiet := time.NewTimer(5 * snapshotDebounce)
	defer quiet.Stop()
	select {
	case <-built:
		t.Fatal("debounced burst produced an unexpected trailing snapshot build")
	case <-quiet.C:
	}

	countMu.Lock()
	got := buildCount
	countMu.Unlock()
	if got != 1 {
		t.Fatalf("expected 1 build from burst, got %d", got)
	}
}

func newRunningSnapshotterForTest(
	t *testing.T,
	persist func([]byte) error,
) *snapshotter {
	t.Helper()
	sn := newSnapshotter(filepath.Join(t.TempDir(), "rooms.json"), func() stateSnapshot {
		return stateSnapshot{Version: snapshotFormatVersion, SavedAt: time.Now()}
	})
	sn.persist = persist
	go sn.run()
	t.Cleanup(func() { _ = sn.flushAndStop(time.Second) })
	return sn
}

func awaitTerminalOutcome(t *testing.T, sn *snapshotter, ticket *terminalMutationTicket) terminalMutationOutcome {
	t.Helper()
	outcome := make(chan terminalMutationOutcome, 1)
	go func() {
		outcome <- sn.waitForDurable(ticket)
	}()
	select {
	case result := <-outcome:
		return result
	case <-time.After(2 * time.Second):
		t.Fatal("timed out waiting for terminal snapshot outcome")
		return terminalMutationOutcome{}
	}
}

func TestSnapshotDurableWaitersCoalesce(t *testing.T) {
	started := make(chan struct{})
	release := make(chan struct{})
	var startOnce sync.Once
	var persistCalls atomic.Int64
	sn := newRunningSnapshotterForTest(t, func([]byte) error {
		persistCalls.Add(1)
		startOnce.Do(func() { close(started) })
		<-release
		return nil
	})
	captureReady := make(chan struct{})
	releaseCapture := make(chan struct{})
	t.Cleanup(func() {
		select {
		case <-releaseCapture:
		default:
			close(releaseCapture)
		}
	})
	var captureOnce sync.Once
	sn.stateMu.Lock()
	sn.beforeCapture = func() {
		captureOnce.Do(func() { close(captureReady) })
		<-releaseCapture
	}
	sn.stateMu.Unlock()

	tickets := make([]*terminalMutationTicket, 0, 4)
	tickets = append(tickets, sn.recordTerminalMutation(nil))
	select {
	case <-captureReady:
	case <-time.After(2 * time.Second):
		t.Fatal("writer did not reach the coalescing capture barrier")
	}
	for range 3 {
		tickets = append(tickets, sn.recordTerminalMutation(nil))
	}
	close(releaseCapture)
	select {
	case <-started:
	case <-time.After(2 * time.Second):
		t.Fatal("coalesced snapshot did not begin persistence")
	}
	for _, ticket := range tickets {
		select {
		case <-ticket.result:
			t.Fatal("terminal waiter completed before persistence returned")
		default:
		}
	}
	close(release)
	for _, ticket := range tickets {
		outcome := awaitTerminalOutcome(t, sn, ticket)
		if outcome.err != nil || !outcome.deliver {
			t.Fatalf("coalesced terminal outcome=%+v", outcome)
		}
	}
	if got := persistCalls.Load(); got != 1 {
		t.Fatalf("coalesced persist calls=%d, want 1", got)
	}
}

func TestSnapshotMutationAfterCaptureRequiresFollowUp(t *testing.T) {
	firstStarted := make(chan struct{})
	releaseFirst := make(chan struct{})
	secondStarted := make(chan struct{})
	releaseSecond := make(chan struct{})
	var calls atomic.Int64
	sn := newRunningSnapshotterForTest(t, func([]byte) error {
		switch calls.Add(1) {
		case 1:
			close(firstStarted)
			<-releaseFirst
		case 2:
			close(secondStarted)
			<-releaseSecond
		default:
			return errors.New("unexpected extra snapshot persistence")
		}
		return nil
	})

	first := sn.recordTerminalMutation(nil)
	select {
	case <-firstStarted:
	case <-time.After(2 * time.Second):
		t.Fatal("first generation did not reach persistence")
	}
	second := sn.recordTerminalMutation(nil)
	close(releaseFirst)
	if outcome := awaitTerminalOutcome(t, sn, first); outcome.err != nil {
		t.Fatalf("first generation outcome=%+v", outcome)
	}
	select {
	case <-second.result:
		t.Fatal("later generation was acknowledged by the earlier capture")
	default:
	}
	select {
	case <-secondStarted:
	case <-time.After(2 * time.Second):
		t.Fatal("later generation did not require a follow-up persistence")
	}
	select {
	case <-second.result:
		t.Fatal("later generation completed before its persistence returned")
	default:
	}
	close(releaseSecond)
	if outcome := awaitTerminalOutcome(t, sn, second); outcome.err != nil {
		t.Fatalf("second generation outcome=%+v", outcome)
	}
}

func TestSnapshotFailureCompletesOnlyCoveredWaiters(t *testing.T) {
	injectedErr := errors.New("covered generation failed")
	firstStarted := make(chan struct{})
	failFirst := make(chan struct{})
	secondStarted := make(chan struct{})
	releaseSecond := make(chan struct{})
	var calls atomic.Int64
	sn := newRunningSnapshotterForTest(t, func([]byte) error {
		switch calls.Add(1) {
		case 1:
			close(firstStarted)
			<-failFirst
			return injectedErr
		case 2:
			close(secondStarted)
			<-releaseSecond
			return nil
		default:
			return errors.New("unexpected extra snapshot persistence")
		}
	})
	captureReady := make(chan struct{})
	releaseCapture := make(chan struct{})
	t.Cleanup(func() {
		select {
		case <-releaseCapture:
		default:
			close(releaseCapture)
		}
	})
	var captureOnce sync.Once
	sn.stateMu.Lock()
	sn.beforeCapture = func() {
		captureOnce.Do(func() { close(captureReady) })
		<-releaseCapture
	}
	sn.stateMu.Unlock()

	covered := sn.recordTerminalMutation(nil)
	select {
	case <-captureReady:
	case <-time.After(2 * time.Second):
		t.Fatal("writer did not reach the failure fan-out capture barrier")
	}
	coveredTwo := sn.recordTerminalMutation(nil)
	close(releaseCapture)
	select {
	case <-firstStarted:
	case <-time.After(2 * time.Second):
		t.Fatal("covered generation did not reach persistence")
	}
	later := sn.recordTerminalMutation(nil)
	close(failFirst)
	if outcome := awaitTerminalOutcome(t, sn, covered); !errors.Is(outcome.err, injectedErr) {
		t.Fatalf("covered waiter outcome=%+v, want injected error", outcome)
	}
	if outcome := awaitTerminalOutcome(t, sn, coveredTwo); !errors.Is(outcome.err, injectedErr) {
		t.Fatalf("second covered waiter outcome=%+v, want injected error", outcome)
	}
	select {
	case <-later.result:
		t.Fatal("later waiter received the covered generation's failure")
	default:
	}
	select {
	case <-secondStarted:
	case <-time.After(2 * time.Second):
		t.Fatal("later generation did not remain retryable")
	}
	close(releaseSecond)
	if outcome := awaitTerminalOutcome(t, sn, later); outcome.err != nil {
		t.Fatalf("later waiter outcome=%+v", outcome)
	}
}

func TestSnapshotFailureBeforeWaitRetainsOutcome(t *testing.T) {
	injectedErr := errors.New("failed before handler waited")
	completed := make(chan struct{})
	sn := newRunningSnapshotterForTest(t, func([]byte) error {
		return injectedErr
	})
	ticket := sn.recordTerminalMutation(func(err error) terminalMutationOutcome {
		close(completed)
		return terminalMutationOutcome{err: err, deliver: true}
	})
	select {
	case <-completed:
	case <-time.After(2 * time.Second):
		t.Fatal("writer did not complete failure before waiter registration point")
	}
	if outcome := awaitTerminalOutcome(t, sn, ticket); !errors.Is(outcome.err, injectedErr) {
		t.Fatalf("late waiter outcome=%+v, want retained failure", outcome)
	}
}

func TestSnapshotCoveredTriggerDoesNotWriteAgain(t *testing.T) {
	var persistCalls atomic.Int64
	persisted := make(chan struct{}, 1)
	sn := newRunningSnapshotterForTest(t, func([]byte) error {
		persistCalls.Add(1)
		persisted <- struct{}{}
		return nil
	})
	sn.recordMutation()
	ticket := sn.recordTerminalMutation(nil)
	if outcome := awaitTerminalOutcome(t, sn, ticket); outcome.err != nil {
		t.Fatalf("terminal outcome=%+v", outcome)
	}
	select {
	case <-persisted:
	default:
		t.Fatal("covering persistence was not observed")
	}
	quiet := time.NewTimer(5 * snapshotDebounce)
	defer quiet.Stop()
	select {
	case <-persisted:
		t.Fatal("covered trigger caused a trailing persistence")
	case <-quiet.C:
	}
	if got := persistCalls.Load(); got != 1 {
		t.Fatalf("covered trigger persist calls=%d, want 1", got)
	}
}

func TestSnapshotFlushAndStopIncludesMutationDuringWrite(t *testing.T) {
	firstStarted := make(chan struct{})
	releaseFirst := make(chan struct{})
	secondPersisted := make(chan struct{})
	var calls atomic.Int64
	sn := newSnapshotter(filepath.Join(t.TempDir(), "rooms.json"), func() stateSnapshot {
		return stateSnapshot{Version: snapshotFormatVersion, SavedAt: time.Now()}
	})
	sn.persist = func([]byte) error {
		switch calls.Add(1) {
		case 1:
			close(firstStarted)
			<-releaseFirst
		case 2:
			close(secondPersisted)
		default:
			return errors.New("shutdown performed an unexpected extra persistence")
		}
		return nil
	}
	go sn.run()
	sn.recordMutation()
	result := make(chan error, 1)
	go func() {
		result <- sn.flushAndStop(2 * time.Second)
	}()
	select {
	case <-firstStarted:
	case <-time.After(2 * time.Second):
		t.Fatal("shutdown write did not begin")
	}
	sn.recordMutation()
	close(releaseFirst)
	select {
	case <-secondPersisted:
	case <-time.After(2 * time.Second):
		t.Fatal("mutation accepted during shutdown write was not persisted")
	}
	select {
	case err := <-result:
		if err != nil {
			t.Fatalf("flushAndStop: %v", err)
		}
	case <-time.After(2 * time.Second):
		t.Fatal("flushAndStop did not finish")
	}
}

func TestSnapshotFlushAndStopFailureResolvesWaiter(t *testing.T) {
	injectedErr := errors.New("shutdown persistence failed")
	started := make(chan struct{})
	release := make(chan struct{})
	var startOnce sync.Once
	sn := newSnapshotter(filepath.Join(t.TempDir(), "rooms.json"), func() stateSnapshot {
		return stateSnapshot{Version: snapshotFormatVersion, SavedAt: time.Now()}
	})
	sn.persist = func([]byte) error {
		startOnce.Do(func() { close(started) })
		<-release
		return injectedErr
	}
	go sn.run()
	ticket := sn.recordTerminalMutation(nil)
	select {
	case <-started:
	case <-time.After(2 * time.Second):
		t.Fatal("terminal write did not begin")
	}
	flushResult := make(chan error, 1)
	go func() {
		flushResult <- sn.flushAndStop(2 * time.Second)
	}()
	close(release)
	if outcome := awaitTerminalOutcome(t, sn, ticket); !errors.Is(outcome.err, injectedErr) {
		t.Fatalf("shutdown waiter outcome=%+v", outcome)
	}
	select {
	case err := <-flushResult:
		if !errors.Is(err, injectedErr) {
			t.Fatalf("flushAndStop error=%v, want %v", err, injectedErr)
		}
	case <-time.After(2 * time.Second):
		t.Fatal("failed flushAndStop did not return")
	}
}

func TestSnapshotDirectorySyncFailureIsBestEffort(t *testing.T) {
	for _, failure := range []struct {
		name string
		err  error
	}{
		{name: "open", err: &os.PathError{Op: "open", Path: "snapshot-dir", Err: errors.New("permission denied")}},
		{name: "sync", err: &os.PathError{Op: "sync", Path: "snapshot-dir", Err: errors.New("unsupported")}},
		{name: "close", err: &os.PathError{Op: "close", Path: "snapshot-dir", Err: errors.New("close failed")}},
	} {
		t.Run(failure.name, func(t *testing.T) {
			path := filepath.Join(t.TempDir(), "rooms.json")
			now := time.Now().UTC()
			snapshot := stateSnapshot{
				Version: snapshotFormatVersion,
				SavedAt: now,
				Rooms: []roomSnapshot{{
					SessionID:             "DIRSYNC",
					HostPeerID:            "H",
					HostReconnectVerifier: encodeReconnectVerifier(reconnectVerifier{1}),
					CreatedAt:             now,
					LastActivityAt:        now,
				}},
			}
			data, err := json.Marshal(snapshot)
			if err != nil {
				t.Fatalf("marshal snapshot: %v", err)
			}
			sn := newSnapshotter(path, func() stateSnapshot { return snapshot })
			sn.syncDir = func(string) error { return failure.err }
			if err := sn.persistAtomic(data); err != nil {
				t.Fatalf("post-rename directory sync was reported as uncommitted: %v", err)
			}
			replacement, err := os.ReadFile(path)
			if err != nil {
				t.Fatalf("read committed replacement: %v", err)
			}
			if !bytes.Equal(replacement, data) {
				t.Fatal("committed replacement bytes changed")
			}
			if _, err := os.Stat(path + ".tmp"); !errors.Is(err, fs.ErrNotExist) {
				t.Fatalf("temporary snapshot remains after commit: %v", err)
			}
			reloaded := newTestServer(t, path)
			if _, err := reloaded.loadSnapshot(path); err != nil {
				t.Fatalf("reload committed replacement: %v", err)
			}
			if reloaded.rooms["DIRSYNC"] == nil {
				t.Fatal("committed replacement was not reloadable")
			}
		})
	}
}

func TestSnapshotDirectorySyncWarningIsThrottled(t *testing.T) {
	var output bytes.Buffer
	previousOutput := log.Writer()
	previousFlags := log.Flags()
	previousPrefix := log.Prefix()
	log.SetOutput(&output)
	log.SetFlags(0)
	log.SetPrefix("")
	t.Cleanup(func() {
		log.SetOutput(previousOutput)
		log.SetFlags(previousFlags)
		log.SetPrefix(previousPrefix)
	})

	path := filepath.Join(t.TempDir(), "rooms.json")
	snapshot := stateSnapshot{Version: snapshotFormatVersion, SavedAt: time.Now()}
	data, err := json.Marshal(snapshot)
	if err != nil {
		t.Fatalf("marshal snapshot: %v", err)
	}
	sn := newSnapshotter(path, func() stateSnapshot { return snapshot })
	dirErr := errors.New("directory sync unsupported")
	sn.syncDir = func(string) error { return dirErr }
	if err := sn.persistAtomic(data); err != nil {
		t.Fatalf("first committed replacement: %v", err)
	}
	if err := sn.persistAtomic(data); err != nil {
		t.Fatalf("second committed replacement: %v", err)
	}
	preCommitErr := errors.New("temporary file write failed")
	sn.persist = func([]byte) error { return preCommitErr }
	go sn.run()
	ticket := sn.recordTerminalMutation(nil)
	if outcome := awaitTerminalOutcome(t, sn, ticket); !errors.Is(outcome.err, preCommitErr) {
		t.Fatalf("pre-commit outcome=%+v", outcome)
	}
	_ = sn.flushAndStop(time.Second)

	logs := output.String()
	if got := strings.Count(logs, "parent directory sync failed after rename commit"); got != 1 {
		t.Fatalf("directory-sync warning count=%d, want 1; logs=%q", got, logs)
	}
	if !strings.Contains(logs, "write failed before rename commit") {
		t.Fatalf("pre-commit write failure was suppressed: %q", logs)
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

func mustClientIPResolver(t *testing.T, cidrs string) clientIPResolver {
	t.Helper()
	prefixes, err := parseTrustedProxyCIDRs(cidrs)
	if err != nil {
		t.Fatalf("parse trusted proxies: %v", err)
	}
	return newClientIPResolver(prefixes)
}

func newRelayHarness(t *testing.T) *relayHarness {
	t.Helper()
	tmpDir := t.TempDir()
	return newRelayHarnessAt(t, tmpDir, filepath.Join(tmpDir, "rooms.json"))
}

func newRelayHarnessNoTrust(t *testing.T) *relayHarness {
	t.Helper()
	tmpDir := t.TempDir()
	return newRelayHarnessAtWithResolver(
		t,
		tmpDir,
		filepath.Join(tmpDir, "rooms.json"),
		newClientIPResolver(nil),
	)
}

// newRelayHarnessAt lets a test control the stateFile path so two harnesses
// can share a snapshot across a simulated restart.
func newRelayHarnessAt(t *testing.T, logDir, stateFile string) *relayHarness {
	t.Helper()
	return newRelayHarnessAtWithResolver(t, logDir, stateFile, mustClientIPResolver(t, "127.0.0.0/8"))
}

func newRelayHarnessAtWithResolver(
	t *testing.T,
	logDir, stateFile string,
	clientIPs clientIPResolver,
) *relayHarness {
	t.Helper()
	srv := newServer(logDir, stateFile, filepath.Join(t.TempDir(), "posters"), clientIPs)
	return newRelayHarnessWithServer(t, srv, true)
}

func newStorageHarness(t *testing.T, logs *logStore, posters *posterStore) *relayHarness {
	t.Helper()
	srv := &Server{
		rooms:         make(map[string]*Room),
		logs:          logs,
		posters:       posters,
		posterUploads: newPosterUploadLimiter(posterPerIPRateBurst, posterPerIPRateSustained, posterGlobalRateBurst, posterGlobalRateSustained, maxConcurrentPosterUploads, time.Now()),
		logLookups:    make(chan struct{}, maxConcurrentLogLookups),
		conns:         newConnTracker(),
		clientIPs:     mustClientIPResolver(t, "127.0.0.0/8"),
	}
	return newRelayHarnessWithServer(t, srv, false)
}

func newRelayHarnessWithServer(t *testing.T, srv *Server, stopSnapshot bool) *relayHarness {
	t.Helper()
	mux := http.NewServeMux()
	mux.HandleFunc("/relay", srv.handleWS)
	mux.HandleFunc("/logs", srv.handlePostLogs)
	mux.HandleFunc("/logs/", srv.handleGetLogs)
	mux.HandleFunc("/posters", srv.handlePostPosters)
	mux.HandleFunc("/posters/", srv.handleGetPosters)

	httpSrv := httptest.NewServer(mux)
	t.Cleanup(func() {
		httpSrv.Close()
		if stopSnapshot {
			_ = srv.snap.flushAndStop(time.Second)
		}
	})

	u, _ := url.Parse(httpSrv.URL)
	wsURL := "ws://" + u.Host + "/relay"
	return &relayHarness{srv: srv, httpSrv: httpSrv, wsURL: wsURL, baseURL: httpSrv.URL}
}
func createModernRoomWithGuest(
	t *testing.T,
	h *relayHarness,
	sessionID, hostIP, guestIP string,
) (host, guest *testConn, hostToken, guestToken string) {
	t.Helper()
	hostToken, _ = mustReconnectToken(t)
	host = h.dial(t, hostIP)
	host.send(clientMsg{
		Type:            relayTypeCreate,
		SessionID:       sessionID,
		PeerID:          "H",
		ReconnectToken:  hostToken,
		ProtocolVersion: relayProtocolVersion,
	})
	host.expectAuthority(relayTypeCreated, "H")

	guestToken, _ = mustReconnectToken(t)
	guest = h.dial(t, guestIP)
	guest.send(clientMsg{
		Type:            relayTypeJoin,
		SessionID:       sessionID,
		PeerID:          "G",
		ReconnectToken:  guestToken,
		ProtocolVersion: relayProtocolVersion,
	})
	guest.expectAuthority(relayTypeJoined, "H")
	host.expect(relayTypePeerJoined)
	return host, guest, hostToken, guestToken
}

func injectSnapshotPersistenceFailure(t *testing.T, sn *snapshotter, injected error) {
	t.Helper()
	if err := sn.write(); err != nil {
		t.Fatalf("persist pre-failure baseline: %v", err)
	}
	sn.writeMu.Lock()
	original := sn.persist
	sn.persist = func([]byte) error { return injected }
	sn.writeMu.Unlock()
	t.Cleanup(func() {
		sn.writeMu.Lock()
		sn.persist = original
		sn.writeMu.Unlock()
	})
}

func copySnapshotForRestart(t *testing.T, source string) string {
	t.Helper()
	data, err := os.ReadFile(source)
	if err != nil {
		t.Fatalf("read committed restart snapshot: %v", err)
	}
	path := filepath.Join(t.TempDir(), "rooms.json")
	if err := os.WriteFile(path, data, 0644); err != nil {
		t.Fatalf("copy committed restart snapshot: %v", err)
	}
	return path
}

type deterministicRemover struct {
	mu       sync.Mutex
	failures map[string]error
	calls    map[string]int
}

func newDeterministicRemover() *deterministicRemover {
	return &deterministicRemover{
		failures: make(map[string]error),
		calls:    make(map[string]int),
	}
}

func (r *deterministicRemover) remove(path string) error {
	r.mu.Lock()
	r.calls[path]++
	err := r.failures[path]
	r.mu.Unlock()
	if err != nil {
		return err
	}
	return os.Remove(path)
}

func (r *deterministicRemover) fail(path string, err error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.failures[path] = err
}

func (r *deterministicRemover) recover(path string) {
	r.mu.Lock()
	defer r.mu.Unlock()
	delete(r.failures, path)
}

func (r *deterministicRemover) callCount(path string) int {
	r.mu.Lock()
	defer r.mu.Unlock()
	return r.calls[path]
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

func newWebSocketPair(t *testing.T) (*websocket.Conn, *websocket.Conn) {
	t.Helper()

	serverConnCh := make(chan *websocket.Conn, 1)
	upgradeErrCh := make(chan error, 1)
	httpServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		conn, err := upgrader.Upgrade(w, r, nil)
		if err != nil {
			upgradeErrCh <- err
			return
		}
		serverConnCh <- conn
	}))

	u, err := url.Parse(httpServer.URL)
	if err != nil {
		httpServer.Close()
		t.Fatalf("parse websocket pair URL: %v", err)
	}
	peerConn, _, err := websocket.DefaultDialer.Dial("ws://"+u.Host, nil)
	if err != nil {
		httpServer.Close()
		t.Fatalf("dial websocket pair: %v", err)
	}

	var serverConn *websocket.Conn
	select {
	case serverConn = <-serverConnCh:
	case err := <-upgradeErrCh:
		peerConn.Close()
		httpServer.Close()
		t.Fatalf("upgrade websocket pair: %v", err)
	case <-time.After(2 * time.Second):
		peerConn.Close()
		httpServer.Close()
		t.Fatal("timed out waiting for websocket pair upgrade")
	}

	t.Cleanup(func() {
		serverConn.Close()
		peerConn.Close()
		httpServer.Close()
	})
	return serverConn, peerConn
}

func (h *relayHarness) dialWithHeaders(headers http.Header) (*websocket.Conn, *http.Response, error) {
	return websocket.DefaultDialer.Dial(h.wsURL, headers)
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

func (h *relayHarness) waitIPConnections(t *testing.T, ip string, want int) {
	t.Helper()
	deadline := time.Now().Add(2 * time.Second)
	for time.Now().Before(deadline) {
		h.srv.conns.mu.Lock()
		got := h.srv.conns.perIP[ip]
		h.srv.conns.mu.Unlock()
		if got == want {
			return
		}
		time.Sleep(20 * time.Millisecond)
	}
	t.Fatalf("IP %s never reached %d connections within 2s", ip, want)
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

func (c *testConn) expectAuthority(typ, hostPeerID string) serverMsg {
	c.t.Helper()
	message := c.expect(typ)
	if message.HostPeerID != hostPeerID {
		c.t.Fatalf("%s hostPeerId=%q, want %q", typ, message.HostPeerID, hostPeerID)
	}
	if _, ok := reconnectVerifierFromToken(message.ReconnectToken); !ok {
		c.t.Fatalf("%s reconnectToken has invalid shape", typ)
	}
	return message
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

// recvUntilClosed consumes any frames already queued on the wire and requires
// a permanent terminal read error before the absolute deadline.
func (c *testConn) recvUntilClosed(within time.Duration) ([]serverMsg, error) {
	c.t.Helper()
	if err := c.conn.SetReadDeadline(time.Now().Add(within)); err != nil {
		return nil, fmt.Errorf("set close-read deadline: %w", err)
	}

	var messages []serverMsg
	for {
		messageType, data, err := c.conn.ReadMessage()
		if err != nil {
			if ne, ok := err.(net.Error); ok && ne.Timeout() {
				return messages, fmt.Errorf("terminal closure not observed within %v: %w", within, err)
			}
			return messages, nil
		}
		if messageType != websocket.TextMessage {
			return messages, fmt.Errorf("unexpected websocket message type %d before closure", messageType)
		}
		var message serverMsg
		if err := json.Unmarshal(data, &message); err != nil {
			return messages, fmt.Errorf("decode frame before closure %q: %w", data, err)
		}
		messages = append(messages, message)
	}
}

func requireClientClosed(t *testing.T, client *Client) {
	t.Helper()
	select {
	case <-client.done:
	case <-time.After(2 * time.Second):
		t.Fatal("client did not close")
	}
}

func requirePeerClosed(t *testing.T, peer *websocket.Conn) {
	t.Helper()
	testPeer := &testConn{t: t, conn: peer}
	if messages, err := testPeer.recvUntilClosed(2 * time.Second); err != nil {
		t.Fatalf("peer remained open after client failure (messages=%v): %v", messages, err)
	}
}

func TestClientQueueOverflowClosesConnection(t *testing.T) {
	serverConn, peerConn := newWebSocketPair(t)
	client := &Client{
		conn: serverConn,
		send: make(chan outboundFrame, 1),
		done: make(chan struct{}),
	}

	if !client.enqueue([]byte(`{"sequence":1}`)) {
		t.Fatal("first frame was not accepted")
	}
	if client.enqueue([]byte(`{"sequence":2}`)) {
		t.Fatal("overflowing frame was accepted")
	}

	requireClientClosed(t, client)
	requirePeerClosed(t, peerConn)
	if client.enqueue([]byte(`{"sequence":3}`)) {
		t.Fatal("frame was accepted after terminal close")
	}

	client.close()
}

func TestClientQueueOverflowBroadcastKeepsHealthyRecipient(t *testing.T) {
	slowServerConn, slowPeerConn := newWebSocketPair(t)
	slow := &Client{
		conn: slowServerConn,
		send: make(chan outboundFrame, 1),
		done: make(chan struct{}),
	}
	if !slow.enqueue([]byte(`{"sequence":1}`)) {
		t.Fatal("failed to prime slow client queue")
	}

	healthyServerConn, healthyPeerConn := newWebSocketPair(t)
	healthy := newClient(healthyServerConn)
	t.Cleanup(healthy.close)

	room := &Room{
		Peers: map[string]*Client{
			"slow":    slow,
			"healthy": healthy,
		},
	}
	payload := json.RawMessage(`{"sequence":2}`)
	room.broadcastExcept("sender", serverMsg{
		Type:    relayTypeMessage,
		From:    "sender",
		Payload: payload,
	})

	requireClientClosed(t, slow)
	requirePeerClosed(t, slowPeerConn)

	received := (&testConn{t: t, conn: healthyPeerConn}).expect(relayTypeMessage)
	if received.From != "sender" {
		t.Fatalf("healthy recipient sender=%q, want sender", received.From)
	}
	if string(received.Payload) != string(payload) {
		t.Fatalf("healthy recipient payload=%s, want %s", received.Payload, payload)
	}
}

func TestClientQueueOverflowDirectedTargetStillExists(t *testing.T) {
	serverConn, peerConn := newWebSocketPair(t)
	target := &Client{
		conn: serverConn,
		send: make(chan outboundFrame, 1),
		done: make(chan struct{}),
	}
	if !target.enqueue([]byte(`{"sequence":1}`)) {
		t.Fatal("failed to prime directed target queue")
	}

	sender := &Client{}
	room := &Room{Peers: map[string]*Client{"sender": sender, "target": target}}
	if result := room.sendFrom("sender", sender, "target", serverMsg{
		Type:    relayTypeMessage,
		From:    "sender",
		Payload: json.RawMessage(`{"sequence":2}`),
	}); result != directedTargetFound {
		t.Fatalf("full existing target result=%v, want directedTargetFound", result)
	}

	requireClientClosed(t, target)
	requirePeerClosed(t, peerConn)
	if result := room.sendFrom("sender", sender, "missing", serverMsg{Type: relayTypeMessage}); result != directedTargetMissing {
		t.Fatalf("missing target result=%v, want directedTargetMissing", result)
	}
}

func TestClientWriteFailureClosesConnection(t *testing.T) {
	serverConn, _ := newWebSocketPair(t)
	client := &Client{
		conn: serverConn,
		send: make(chan outboundFrame, 1),
		done: make(chan struct{}),
	}

	if err := serverConn.Close(); err != nil {
		t.Fatalf("close writer connection: %v", err)
	}
	client.send <- outboundFrame{data: []byte(`{"type":"queued"}`)}

	exited := make(chan struct{})
	go func() {
		client.writePump()
		close(exited)
	}()

	requireClientClosed(t, client)
	select {
	case <-exited:
	case <-time.After(2 * time.Second):
		t.Fatal("write pump did not exit after write failure")
	}

	client.close()
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

func TestRateLimiterReclaimableOnlyAfterFullRefill(t *testing.T) {
	now := time.Now()
	limiter := &rateLimiter{
		tokens:     0,
		maxTokens:  5,
		refillRate: 1,
		lastTime:   now,
	}

	if limiter.reclaimable(now.Add(4 * time.Second)) {
		t.Fatal("partially refilled limiter must retain its effective state")
	}
	if !limiter.reclaimable(now.Add(5 * time.Second)) {
		t.Fatal("fully refilled limiter should be reclaimable")
	}
}

func TestCleanupRateWindowsUsesWindowBoundary(t *testing.T) {
	now := time.Now()
	windows := map[string]time.Time{
		"active":  now.Add(-logRateInterval + time.Nanosecond),
		"expired": now.Add(-logRateInterval),
	}

	cleanupRateWindows(windows, now, logRateInterval)

	if _, ok := windows["active"]; !ok {
		t.Fatal("active fixed-window limiter was removed early")
	}
	if _, ok := windows["expired"]; ok {
		t.Fatal("expired fixed-window limiter was retained")
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

func TestConnTrackerCleanupPreservesEffectiveRateLimits(t *testing.T) {
	ct := newConnTracker()
	ip := "10.0.1.1"
	for i := range connRateBurst {
		if !ct.tryConnect(ip) {
			t.Fatalf("tryConnect %d: expected true", i)
		}
	}
	for range connRateBurst {
		ct.disconnect(ip)
	}

	ct.cleanup(time.Now())
	if ct.tryConnect(ip) {
		t.Fatal("cleanup reset a connection rate limit that was still effective")
	}

	ct.cleanup(time.Now().Add(10 * time.Second))
	if !ct.tryConnect(ip) {
		t.Fatal("fully refilled limiter should be reclaimable")
	}

	ct.cleanup(time.Now().Add(10 * time.Second))
	ct.mu.Lock()
	_, retainedWhileConnected := ct.ipRate[ip]
	ct.mu.Unlock()
	if !retainedWhileConnected {
		t.Fatal("cleanup removed a limiter with an active connection")
	}
}

func TestConnTrackerConnectRateLimit(t *testing.T) {
	ct := newConnTracker()
	ip := "10.0.0.4"
	for i := range connRateBurst {
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

func TestPosterUploadLimiterAdmissionPolicy(t *testing.T) {
	now := time.Unix(1_700_000_000, 0)

	t.Run("per IP burst and independent clients", func(t *testing.T) {
		limiter := newPosterUploadLimiter(2, 1, 10, 1, 10, now)
		for range 2 {
			if !limiter.tryStart("203.0.113.1", now) {
				t.Fatal("per-IP burst rejected early")
			}
			limiter.finish()
		}
		if limiter.tryStart("203.0.113.1", now) {
			t.Fatal("request beyond per-IP burst succeeded")
		}
		if !limiter.tryStart("203.0.113.2", now) {
			t.Fatal("independent IP was denied")
		}
		limiter.finish()
	})

	t.Run("global burst spans distinct clients", func(t *testing.T) {
		limiter := newPosterUploadLimiter(10, 1, 2, 1, 10, now)
		for _, ip := range []string{"203.0.113.1", "203.0.113.2"} {
			if !limiter.tryStart(ip, now) {
				t.Fatalf("%s rejected before global burst exhausted", ip)
			}
			limiter.finish()
		}
		if limiter.tryStart("203.0.113.3", now) {
			t.Fatal("request beyond global burst succeeded")
		}
		if len(limiter.perIP) != 2 {
			t.Fatalf("globally denied request allocated per-IP state: %d buckets", len(limiter.perIP))
		}
	})

	t.Run("concurrency denial consumes no tokens", func(t *testing.T) {
		limiter := newPosterUploadLimiter(1, 0, 2, 0, 1, now)
		if !limiter.tryStart("203.0.113.1", now) {
			t.Fatal("first upload denied")
		}
		if limiter.tryStart("203.0.113.2", now) {
			t.Fatal("upload above concurrency limit succeeded")
		}
		limiter.finish()
		if !limiter.tryStart("203.0.113.2", now) {
			t.Fatal("concurrency denial consumed admission tokens")
		}
		limiter.finish()
	})

	t.Run("per IP denial refunds global token", func(t *testing.T) {
		limiter := newPosterUploadLimiter(1, 0, 2, 0, 2, now)
		if !limiter.tryStart("203.0.113.1", now) {
			t.Fatal("first upload denied")
		}
		limiter.finish()
		if limiter.tryStart("203.0.113.1", now) {
			t.Fatal("exhausted IP unexpectedly admitted")
		}
		if !limiter.tryStart("203.0.113.2", now) {
			t.Fatal("refunded global token was unavailable to another IP")
		}
		limiter.finish()
	})

	t.Run("finish restores only concurrency and time restores rate", func(t *testing.T) {
		limiter := newPosterUploadLimiter(1, 1, 1, 1, 1, now)
		if !limiter.tryStart("203.0.113.1", now) {
			t.Fatal("first upload denied")
		}
		limiter.finish()
		if limiter.active != 0 {
			t.Fatalf("active=%d, want 0", limiter.active)
		}
		if limiter.tryStart("203.0.113.1", now) {
			t.Fatal("finish incorrectly refunded rate tokens")
		}
		if !limiter.tryStart("203.0.113.1", now.Add(time.Second)) {
			t.Fatal("sustained refill did not restore capacity")
		}
		limiter.finish()
	})

	t.Run("cleanup retains effective buckets then reclaims full ones", func(t *testing.T) {
		limiter := newPosterUploadLimiter(2, 1, 10, 1, 2, now)
		if !limiter.tryStart("203.0.113.1", now) {
			t.Fatal("first upload denied")
		}
		limiter.finish()
		limiter.cleanup(now)
		if _, ok := limiter.perIP["203.0.113.1"]; !ok {
			t.Fatal("cleanup removed effective per-IP limiter")
		}
		limiter.cleanup(now.Add(time.Second))
		if _, ok := limiter.perIP["203.0.113.1"]; ok {
			t.Fatal("cleanup retained fully refilled per-IP limiter")
		}
	})
}

// ======================================================================
// clientIPResolver unit tests
// ======================================================================

func TestClientIPResolverTrustChains(t *testing.T) {
	tests := []struct {
		name    string
		trusted string
		remote  string
		headers []string
		want    string
		wantErr bool
	}{
		{name: "absent forwarding header", remote: "127.0.0.1:12345", want: "127.0.0.1"},
		{name: "untrusted peer ignores spoof", remote: "198.51.100.10:12345", headers: []string{"203.0.113.5"}, want: "198.51.100.10"},
		{name: "one trusted proxy", trusted: "10.0.0.0/8", remote: "10.0.0.2:8080", headers: []string{"203.0.113.5"}, want: "203.0.113.5"},
		{name: "append chain ignores forged leftmost", trusted: "10.0.0.0/8", remote: "10.0.0.2:8080", headers: []string{"198.51.100.99, 203.0.113.5"}, want: "203.0.113.5"},
		{name: "two trusted proxies", trusted: "10.0.0.0/8, 192.0.2.0/24", remote: "10.0.0.2:8080", headers: []string{"203.0.113.5, 192.0.2.10"}, want: "203.0.113.5"},
		{name: "untrusted intermediate is client boundary", trusted: "10.0.0.0/8", remote: "10.0.0.2:8080", headers: []string{"203.0.113.5, 198.51.100.7"}, want: "198.51.100.7"},
		{name: "repeated header lines preserve chain", trusted: "10.0.0.0/8, 192.0.2.0/24", remote: "10.0.0.2:8080", headers: []string{"203.0.113.5", "192.0.2.10"}, want: "203.0.113.5"},
		{name: "trusted proxy without forwarding header", trusted: "10.0.0.0/8", remote: "10.0.0.2:8080", want: "10.0.0.2"},
		{name: "IPv4 mapped peer is unmapped", remote: "[::ffff:192.0.2.4]:8080", want: "192.0.2.4"},
		{name: "IPv4 mapped forwarded address is unmapped", trusted: "10.0.0.0/8", remote: "10.0.0.2:8080", headers: []string{"::ffff:203.0.113.5"}, want: "203.0.113.5"},
		{name: "native IPv6 client is grouped to 64", trusted: "10.0.0.0/8", remote: "10.0.0.2:8080", headers: []string{"2001:db8:85a3:12::abcd"}, want: "2001:db8:85a3:12::"},
		{name: "untrusted malformed header is ignored", remote: "198.51.100.10:12345", headers: []string{"bad,,host:123"}, want: "198.51.100.10"},
		{name: "malformed immediate peer", remote: "not-an-address", wantErr: true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			resolver := mustClientIPResolver(t, tt.trusted)
			req := &http.Request{RemoteAddr: tt.remote, Header: make(http.Header)}
			for _, value := range tt.headers {
				req.Header.Add("X-Forwarded-For", value)
			}
			got, err := resolver.resolve(req)
			if tt.wantErr {
				if err == nil {
					t.Fatalf("resolve()=%q, want error", got)
				}
				return
			}
			if err != nil {
				t.Fatalf("resolve(): %v", err)
			}
			if got != tt.want {
				t.Fatalf("resolve()=%q, want %q", got, tt.want)
			}
		})
	}
}

func TestClientIPResolverRejectsMalformedTrustedChains(t *testing.T) {
	resolver := mustClientIPResolver(t, "10.0.0.0/8")
	for _, value := range []string{
		"",
		"203.0.113.5,",
		"203.0.113.5,,192.0.2.1",
		"not-an-ip",
		"203.0.113.5:1234",
		"fe80::1%eth0",
	} {
		t.Run(fmt.Sprintf("%q", value), func(t *testing.T) {
			req := &http.Request{
				RemoteAddr: "10.0.0.2:8080",
				Header:     http.Header{"X-Forwarded-For": []string{value}},
			}
			if got, err := resolver.resolve(req); err == nil {
				t.Fatalf("resolve()=%q, want error", got)
			}
		})
	}
}

func TestParseTrustedProxyCIDRs(t *testing.T) {
	prefixes, err := parseTrustedProxyCIDRs(" ")
	if err != nil || len(prefixes) != 0 {
		t.Fatalf("empty config = %v, %v; want no prefixes", prefixes, err)
	}
	prefixes, err = parseTrustedProxyCIDRs(" 10.1.2.3/8, ::ffff:192.0.2.12/120, 2001:db8::1/32 ")
	if err != nil {
		t.Fatalf("valid config: %v", err)
	}
	got := make([]string, len(prefixes))
	for i, prefix := range prefixes {
		got[i] = prefix.String()
	}
	want := []string{"10.0.0.0/8", "192.0.2.0/24", "2001:db8::/32"}
	if fmt.Sprint(got) != fmt.Sprint(want) {
		t.Fatalf("prefixes=%v, want %v", got, want)
	}
	for _, value := range []string{"10.0.0.0/8,", "10.0.0.0/8,garbage", "::ffff:192.0.2.1/64"} {
		if prefixes, err := parseTrustedProxyCIDRs(value); err == nil || prefixes != nil {
			t.Fatalf("parseTrustedProxyCIDRs(%q)=(%v, %v), want nil error result", value, prefixes, err)
		}
	}
}

// ======================================================================
// generateLogID
// ======================================================================

func TestGenerateLogIDShape(t *testing.T) {
	if entropyBits := float64(logIDLength) * math.Log2(float64(len(idChars))); entropyBits < 128 {
		t.Fatalf("log capability entropy=%f bits, want at least 128", entropyBits)
	}
	seen := map[string]struct{}{}
	for i := 0; i < 200; i++ {
		id := generateLogID()
		if len(id) != logIDLength {
			t.Fatalf("len=%d want %d (id=%q)", len(id), logIDLength, id)
		}
		for _, c := range id {
			if !strings.ContainsRune(idChars, c) {
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
	c.send(clientMsg{Type: relayTypeCreate, SessionID: "ROOM1", PeerID: "host-a"})
	message := c.expectAuthority(relayTypeCreated, "host-a")
	if message.SessionID != "ROOM1" {
		t.Errorf("SessionID=%q want ROOM1", message.SessionID)
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

func TestCreateNegotiatesModernProtocolWithClientKnownToken(t *testing.T) {
	h := newRelayHarness(t)
	hostToken, _ := mustReconnectToken(t)
	host := h.dial(t, "1.1.1.40")

	host.send(clientMsg{
		Type:            relayTypeCreate,
		SessionID:       "MODERN_CREATE",
		PeerID:          "H",
		ReconnectToken:  hostToken,
		ProtocolVersion: relayProtocolVersion + 1,
	})
	mismatch := host.expectError(relayErrorProtocolMismatch)
	if mismatch.ProtocolVersion != relayProtocolVersion {
		t.Fatalf("protocol mismatch advertised version=%d, want %d", mismatch.ProtocolVersion, relayProtocolVersion)
	}

	host.send(clientMsg{
		Type:            relayTypeCreate,
		SessionID:       "MODERN_CREATE",
		PeerID:          "H",
		ReconnectToken:  hostToken,
		ProtocolVersion: mismatch.ProtocolVersion,
	})
	created := host.expectAuthority(relayTypeCreated, "H")
	if created.ReconnectToken != hostToken {
		t.Fatal("modern create rotated the client-known reconnect token")
	}
	if created.ProtocolVersion != relayProtocolVersion {
		t.Fatalf("created protocolVersion=%d, want %d", created.ProtocolVersion, relayProtocolVersion)
	}
}

func TestModernCreateRetryAfterLostSetupResponseIsIdempotent(t *testing.T) {
	h := newRelayHarness(t)
	hostToken, _ := mustReconnectToken(t)
	create := clientMsg{
		Type:            relayTypeCreate,
		SessionID:       "CREATE_RETRY",
		PeerID:          "H",
		ReconnectToken:  hostToken,
		ProtocolVersion: relayProtocolVersion,
	}

	first := h.dial(t, "1.1.1.41")
	first.send(create)
	if err := first.conn.SetReadDeadline(time.Now().Add(2 * time.Second)); err != nil {
		t.Fatalf("set discarded response deadline: %v", err)
	}
	messageType, _, err := first.conn.ReadMessage()
	if err != nil {
		t.Fatalf("read discarded setup response: %v", err)
	}
	if messageType != websocket.TextMessage {
		t.Fatalf("discarded setup response type=%d, want text", messageType)
	}

	retry := h.dial(t, "1.1.1.42")
	retry.send(create)
	created := retry.expectAuthority(relayTypeCreated, "H")
	if created.ReconnectToken != hostToken || created.ProtocolVersion != relayProtocolVersion {
		t.Fatalf("retry authority changed: tokenMatch=%v protocol=%d", created.ReconnectToken == hostToken, created.ProtocolVersion)
	}
	if len(created.Peers) != 0 {
		t.Fatalf("retry reported unexpected peers: %v", created.Peers)
	}
	if messages, err := first.recvUntilClosed(2 * time.Second); err != nil {
		t.Fatalf("superseded create connection remained open: %v (frames=%v)", err, messages)
	}

	h.srv.mu.RLock()
	roomCount := len(h.srv.rooms)
	room := h.srv.rooms["CREATE_RETRY"]
	h.srv.mu.RUnlock()
	if roomCount != 1 || room == nil {
		t.Fatalf("idempotent retry retained rooms=%d targetPresent=%v", roomCount, room != nil)
	}
}

func TestIdempotentCreateReannouncesPreviouslyAbsentHost(t *testing.T) {
	h := newRelayHarness(t)
	hostToken, _ := mustReconnectToken(t)
	create := clientMsg{
		Type:            relayTypeCreate,
		SessionID:       "CREATE_REANNOUNCE",
		PeerID:          "H",
		ReconnectToken:  hostToken,
		ProtocolVersion: relayProtocolVersion,
	}

	host := h.dial(t, "1.1.1.43")
	host.send(create)
	host.expectAuthority(relayTypeCreated, "H")

	guestToken, _ := mustReconnectToken(t)
	guest := h.dial(t, "1.1.1.44")
	guest.send(clientMsg{
		Type:            relayTypeJoin,
		SessionID:       "CREATE_REANNOUNCE",
		PeerID:          "G",
		ReconnectToken:  guestToken,
		ProtocolVersion: relayProtocolVersion,
	})
	guest.expectAuthority(relayTypeJoined, "H")
	host.expect(relayTypePeerJoined)

	if err := host.conn.Close(); err != nil {
		t.Fatalf("close original host: %v", err)
	}
	left := guest.expect(relayTypePeerLeft)
	if left.PeerID != "H" {
		t.Fatalf("disconnected host event peerId=%q, want H", left.PeerID)
	}

	returning := h.dial(t, "1.1.1.45")
	returning.send(create)
	returning.expectAuthority(relayTypeCreated, "H")
	reannounced := guest.expect(relayTypePeerJoined)
	if reannounced.PeerID != "H" {
		t.Fatalf("returning host event peerId=%q, want H", reannounced.PeerID)
	}
}

func TestCreateCannotReclaimReservedEmptyRoom(t *testing.T) {
	h := newRelayHarness(t)
	hostToken, hostVerifier := mustReconnectToken(t)
	original := &Room{
		SessionID:        "STALE",
		HostPeerID:       "old-host",
		hostVerifier:     hostVerifier,
		peerReservations: make(map[string]peerReservation),
		Peers:            map[string]*Client{},
		CreatedAt:        time.Now().Add(-time.Minute),
		LastActivityAt:   time.Now(),
	}
	h.srv.mu.Lock()
	h.srv.rooms["STALE"] = original
	h.srv.mu.Unlock()

	creator := h.dial(t, "1.1.1.6")
	creator.send(clientMsg{Type: relayTypeCreate, SessionID: "STALE", PeerID: "new-host"})
	creator.expectError(relayErrorRoomExists)

	unproved := h.dial(t, "1.1.1.60")
	unproved.send(clientMsg{Type: relayTypeJoin, SessionID: "STALE", PeerID: "old-host"})
	unproved.expectError(relayErrorPeerIdUnavailable)

	reconnected := h.dial(t, "1.1.1.61")
	reconnected.send(clientMsg{
		Type:           relayTypeJoin,
		SessionID:      "STALE",
		PeerID:         "old-host",
		ReconnectToken: hostToken,
	})
	reconnected.expectAuthority(relayTypeJoined, "old-host")

	h.srv.mu.RLock()
	current := h.srv.rooms["STALE"]
	h.srv.mu.RUnlock()
	if current != original {
		t.Fatal("reserved room identity was replaced")
	}
}

func TestCreateReclaimsOwnedEmptyRoomWithoutDoubleCharging(t *testing.T) {
	h := newRelayHarness(t)
	ownerKey := "1.1.1.61"
	now := time.Now()
	replacementToken, replacementVerifier := mustReconnectToken(t)
	h.srv.mu.Lock()
	for i := range maxRoomsPerIP {
		sessionID := fmt.Sprintf("OWNED%d", i)
		h.srv.rooms[sessionID] = &Room{
			SessionID:        sessionID,
			HostPeerID:       "old-host",
			hostVerifier:     replacementVerifier,
			peerReservations: make(map[string]peerReservation),
			Peers:            map[string]*Client{},
			quotaOwnerKey:    ownerKey,
			CreatedAt:        now.Add(-time.Hour),
			LastActivityAt:   now,
		}
		if !h.srv.conns.tryCreateRoom(ownerKey) {
			h.srv.mu.Unlock()
			t.Fatal("failed to seed retained quota")
		}
	}
	h.srv.mu.Unlock()

	c := h.dial(t, ownerKey)
	c.send(clientMsg{
		Type:           relayTypeCreate,
		SessionID:      "OWNED0",
		PeerID:         "old-host",
		ReconnectToken: replacementToken,
	})
	c.expect(relayTypeCreated)
	h.srv.conns.mu.Lock()
	quota := h.srv.conns.roomsPerIP[ownerKey]
	h.srv.conns.mu.Unlock()
	if quota != maxRoomsPerIP {
		t.Fatalf("replacement quota=%d, want %d", quota, maxRoomsPerIP)
	}
	h.srv.mu.RLock()
	roomCount := len(h.srv.rooms)
	h.srv.mu.RUnlock()
	if roomCount != maxRoomsPerIP {
		t.Fatalf("replacement room count=%d, want %d", roomCount, maxRoomsPerIP)
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

func TestRetainedRoomQuotaSurvivesDisconnectAndReturnsOnRemoval(t *testing.T) {
	h := newRelayHarness(t)
	ownerKey := "1.1.1.70"
	sessionIDs := make([]string, 0, maxRoomsPerIP)
	for i := range maxRoomsPerIP {
		sessionID := fmt.Sprintf("RETAIN%d", i)
		host := h.dial(t, ownerKey)
		host.send(clientMsg{Type: relayTypeCreate, SessionID: sessionID, PeerID: "H"})
		host.expect(relayTypeCreated)
		host.conn.Close()
		h.waitRoomPeers(t, sessionID, 0)
		sessionIDs = append(sessionIDs, sessionID)
	}

	for i, sessionID := range sessionIDs {
		guest := h.dial(t, fmt.Sprintf("1.1.2.%d", i+1))
		guest.send(clientMsg{Type: relayTypeJoin, SessionID: sessionID, PeerID: "G"})
		guest.expect(relayTypeJoined)
		guest.conn.Close()
		h.waitRoomPeers(t, sessionID, 0)
	}

	blocked := h.dial(t, ownerKey)
	blocked.send(clientMsg{Type: relayTypeCreate, SessionID: "RETAINX", PeerID: "H"})
	blocked.expectError(relayErrorRateLimited)

	h.srv.conns.mu.Lock()
	retainedQuota := h.srv.conns.roomsPerIP[ownerKey]
	h.srv.conns.mu.Unlock()
	if retainedQuota != maxRoomsPerIP {
		t.Fatalf("retained quota=%d, want %d after creator disconnects", retainedQuota, maxRoomsPerIP)
	}

	now := time.Now()
	h.srv.mu.RLock()
	idleRoom := h.srv.rooms[sessionIDs[0]]
	h.srv.mu.RUnlock()
	idleRoom.mu.Lock()
	idleRoom.LastActivityAt = now.Add(-emptyRoomMaxAge - time.Second)
	idleRoom.mu.Unlock()
	h.srv.runCleanupStep(now)

	h.srv.conns.mu.Lock()
	afterIdleRemoval := h.srv.conns.roomsPerIP[ownerKey]
	h.srv.conns.mu.Unlock()
	if afterIdleRemoval != maxRoomsPerIP-1 {
		t.Fatalf("quota after idle removal=%d, want %d", afterIdleRemoval, maxRoomsPerIP-1)
	}
	blocked.send(clientMsg{Type: relayTypeCreate, SessionID: "RETAIN3", PeerID: "H"})
	blocked.expect(relayTypeCreated)

	occupied := h.dial(t, "1.1.2.99")
	occupied.send(clientMsg{Type: relayTypeJoin, SessionID: sessionIDs[1], PeerID: "G"})
	occupied.expect(relayTypeJoined)
	h.srv.mu.RLock()
	expiringRoom := h.srv.rooms[sessionIDs[1]]
	h.srv.mu.RUnlock()
	expiringRoom.mu.Lock()
	expiringRoom.CreatedAt = now.Add(-roomMaxAge - time.Second)
	expiringRoom.mu.Unlock()
	h.srv.runCleanupStep(now)
	if _, err := occupied.recvUntilClosed(2 * time.Second); err != nil {
		t.Fatalf("occupied expired room client remained connected: %v", err)
	}

	h.srv.conns.mu.Lock()
	afterHardExpiry := h.srv.conns.roomsPerIP[ownerKey]
	h.srv.conns.mu.Unlock()
	if afterHardExpiry != maxRoomsPerIP-1 {
		t.Fatalf("quota after hard expiry=%d, want %d", afterHardExpiry, maxRoomsPerIP-1)
	}
	recovered := h.dial(t, ownerKey)
	recovered.send(clientMsg{Type: relayTypeCreate, SessionID: "RETAIN4", PeerID: "H"})
	recovered.expect(relayTypeCreated)
	h.srv.conns.mu.Lock()
	finalQuota := h.srv.conns.roomsPerIP[ownerKey]
	h.srv.conns.mu.Unlock()
	if finalQuota != maxRoomsPerIP {
		t.Fatalf("final retained quota=%d, want %d", finalQuota, maxRoomsPerIP)
	}
}

func TestGlobalRetainedRoomCapBlocksCreateButPreservesJoin(t *testing.T) {
	h := newRelayHarness(t)
	now := time.Now()
	h.srv.mu.Lock()
	for _, persisted := range makeRoomSnapshots(maxRetainedRooms, false, now) {
		h.srv.rooms[persisted.SessionID] = &Room{
			SessionID:      persisted.SessionID,
			HostPeerID:     persisted.HostPeerID,
			Peers:          map[string]*Client{},
			CreatedAt:      persisted.CreatedAt,
			LastActivityAt: persisted.LastActivityAt,
		}
	}
	h.srv.mu.Unlock()

	ownerKey := "1.1.3.1"
	client := h.dial(t, ownerKey)
	client.send(clientMsg{Type: relayTypeCreate, SessionID: "OVERGLOBAL", PeerID: "H"})
	client.expectError(relayErrorRateLimited)
	h.srv.mu.RLock()
	roomCount := len(h.srv.rooms)
	h.srv.mu.RUnlock()
	snapshotRoomCount := len(h.srv.buildSnapshot().Rooms)
	if roomCount != maxRetainedRooms || snapshotRoomCount != maxRetainedRooms {
		t.Fatalf("rejected create mutated retained state: rooms=%d snapshot=%d", roomCount, snapshotRoomCount)
	}
	h.srv.conns.mu.Lock()
	reservation := h.srv.conns.roomsPerIP[ownerKey]
	h.srv.conns.mu.Unlock()
	if reservation != 0 {
		t.Fatalf("global rejection reserved per-source quota: %d", reservation)
	}

	client.send(clientMsg{Type: relayTypeJoin, SessionID: "S0000", PeerID: "G"})
	client.expect(relayTypeJoined)
	client.conn.Close()
	h.waitRoomPeers(t, "S0000", 0)

	h.srv.mu.RLock()
	expired := h.srv.rooms["S0001"]
	h.srv.mu.RUnlock()
	expired.mu.Lock()
	expired.LastActivityAt = now.Add(-emptyRoomMaxAge - time.Second)
	expired.mu.Unlock()
	h.srv.runCleanupStep(now)

	creator := h.dial(t, ownerKey)
	creator.send(clientMsg{Type: relayTypeCreate, SessionID: "AFTERGLOBAL", PeerID: "H"})
	creator.expect(relayTypeCreated)
	h.srv.mu.RLock()
	roomCount = len(h.srv.rooms)
	h.srv.mu.RUnlock()
	if roomCount != maxRetainedRooms {
		t.Fatalf("room count after cleanup and create=%d, want %d", roomCount, maxRetainedRooms)
	}
}

func TestConcurrentCreatesCannotExceedGlobalRetainedRoomCap(t *testing.T) {
	for iteration := range 8 {
		t.Run(fmt.Sprintf("iteration_%d", iteration), func(t *testing.T) {
			h := newRelayHarness(t)
			now := time.Now()
			h.srv.mu.Lock()
			for _, persisted := range makeRoomSnapshots(maxRetainedRooms-1, false, now) {
				h.srv.rooms[persisted.SessionID] = &Room{
					SessionID:      persisted.SessionID,
					HostPeerID:     persisted.HostPeerID,
					Peers:          map[string]*Client{},
					CreatedAt:      persisted.CreatedAt,
					LastActivityAt: persisted.LastActivityAt,
				}
			}
			h.srv.mu.Unlock()

			type createResult struct {
				ownerKey string
				message  serverMsg
				err      error
			}
			connections := make([]*websocket.Conn, 2)
			for i := range connections {
				conn, err := h.dialRaw(fmt.Sprintf("1.1.4.%d", i+1))
				if err != nil {
					t.Fatalf("dial create contender %d: %v", i, err)
				}
				connections[i] = conn
				t.Cleanup(func() { conn.Close() })
			}
			start := make(chan struct{})
			results := make(chan createResult, len(connections))
			for i, conn := range connections {
				ownerKey := fmt.Sprintf("1.1.4.%d", i+1)
				go func(conn *websocket.Conn, ownerKey string, index int) {
					<-start
					err := conn.WriteJSON(clientMsg{
						Type:      relayTypeCreate,
						SessionID: fmt.Sprintf("RACE%d", index),
						PeerID:    "H",
					})
					var message serverMsg
					if err == nil {
						err = conn.ReadJSON(&message)
					}
					results <- createResult{ownerKey: ownerKey, message: message, err: err}
				}(conn, ownerKey, i)
			}
			close(start)

			created, rejected := 0, 0
			acceptedOwner := ""
			for range connections {
				result := <-results
				if result.err != nil {
					t.Fatalf("concurrent create failed: %v", result.err)
				}
				switch {
				case result.message.Type == relayTypeCreated:
					created++
					acceptedOwner = result.ownerKey
				case result.message.Type == relayTypeError && result.message.Code == relayErrorRateLimited:
					rejected++
				default:
					t.Fatalf("unexpected concurrent result: %+v", result.message)
				}
			}
			if created != 1 || rejected != 1 {
				t.Fatalf("created=%d rejected=%d, want one each", created, rejected)
			}
			h.srv.mu.RLock()
			roomCount := len(h.srv.rooms)
			h.srv.mu.RUnlock()
			if roomCount != maxRetainedRooms {
				t.Fatalf("room count=%d, want %d", roomCount, maxRetainedRooms)
			}
			h.srv.conns.mu.Lock()
			acceptedQuota := h.srv.conns.roomsPerIP[acceptedOwner]
			totalQuota := 0
			for _, count := range h.srv.conns.roomsPerIP {
				totalQuota += count
			}
			h.srv.conns.mu.Unlock()
			if acceptedQuota != 1 || totalQuota != 1 {
				t.Fatalf("accepted quota=%d total quota=%d, want 1 and 1", acceptedQuota, totalQuota)
			}
		})
	}
}

func TestRelayUntrustedXFFCannotRotateConnectionOrRoomIdentity(t *testing.T) {
	t.Run("connections", func(t *testing.T) {
		h := newRelayHarnessNoTrust(t)
		var conns []*websocket.Conn
		for i := 0; i < maxConnsPerIP; i++ {
			conn, err := h.dialRaw(fmt.Sprintf("203.0.113.%d", i+1))
			if err != nil {
				t.Fatalf("dial %d: %v", i, err)
			}
			conns = append(conns, conn)
		}
		t.Cleanup(func() {
			for _, conn := range conns {
				conn.Close()
			}
		})

		headers := http.Header{"X-Forwarded-For": []string{"198.51.100.200"}}
		conn, resp, err := h.dialWithHeaders(headers)
		if conn != nil {
			conn.Close()
			t.Fatal("connection above direct peer limit unexpectedly succeeded")
		}
		if err == nil || resp == nil {
			t.Fatalf("dial error=%v response=%v, want HTTP 429", err, resp)
		}
		defer resp.Body.Close()
		if resp.StatusCode != http.StatusTooManyRequests {
			t.Fatalf("status=%d, want 429", resp.StatusCode)
		}
	})

	t.Run("rooms", func(t *testing.T) {
		h := newRelayHarnessNoTrust(t)
		for i := 0; i <= maxRoomsPerIP; i++ {
			client := h.dial(t, fmt.Sprintf("203.0.113.%d", i+1))
			client.send(clientMsg{Type: "create", SessionID: fmt.Sprintf("SPOOF%d", i), PeerID: "host"})
			if i < maxRoomsPerIP {
				client.expect("created")
			} else {
				client.expectError("rate_limited")
			}
		}
	})
}

func TestRelayTrustedClientsHaveIndependentConnectionBuckets(t *testing.T) {
	h := newRelayHarness(t)
	var conns []*websocket.Conn
	for i := 0; i < maxConnsPerIP; i++ {
		conn, err := h.dialRaw("203.0.113.10")
		if err != nil {
			t.Fatalf("client A dial %d: %v", i, err)
		}
		conns = append(conns, conn)
	}
	conn, err := h.dialRaw("203.0.113.11")
	if err != nil {
		t.Fatalf("client B should have an independent bucket: %v", err)
	}
	conns = append(conns, conn)
	t.Cleanup(func() {
		for _, conn := range conns {
			conn.Close()
		}
	})
}

func TestRelayMalformedTrustedChainDoesNotMutateAdmission(t *testing.T) {
	h := newRelayHarness(t)
	headers := http.Header{"X-Forwarded-For": []string{"203.0.113.5,"}}
	conn, resp, err := h.dialWithHeaders(headers)
	if conn != nil {
		conn.Close()
		t.Fatal("malformed trusted chain unexpectedly upgraded")
	}
	if err == nil || resp == nil {
		t.Fatalf("dial error=%v response=%v, want HTTP 400", err, resp)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusBadRequest {
		t.Fatalf("status=%d, want 400", resp.StatusCode)
	}
	h.srv.conns.mu.Lock()
	defer h.srv.conns.mu.Unlock()
	if h.srv.conns.globalCount != 0 || len(h.srv.conns.perIP) != 0 || len(h.srv.conns.ipRate) != 0 {
		t.Fatalf("malformed chain mutated connection admission: %+v", h.srv.conns)
	}
}

func TestConnectionCannotRetainMultipleRoomMemberships(t *testing.T) {
	h := newRelayHarness(t)
	ip := "1.1.1.8"
	client := h.dial(t, ip)
	client.send(clientMsg{Type: "create", SessionID: "PRIMARY", PeerID: "host"})
	client.expect("created")

	otherHost := h.dial(t, "1.1.1.9")
	otherHost.send(clientMsg{Type: "create", SessionID: "OTHER", PeerID: "other-host"})
	otherHost.expect("created")

	client.send(clientMsg{Type: "join", SessionID: "OTHER", PeerID: "ghost"})
	client.expectError("already_in_room")
	client.send(clientMsg{Type: "create", SessionID: "EXTRA", PeerID: "extra-host"})
	client.expectError("already_in_room")

	h.waitRoomPeers(t, "PRIMARY", 1)
	h.waitRoomPeers(t, "OTHER", 1)
	h.srv.mu.RLock()
	_, extraExists := h.srv.rooms["EXTRA"]
	h.srv.mu.RUnlock()
	if extraExists {
		t.Fatal("rejected create retained an extra room")
	}

	h.srv.conns.mu.Lock()
	roomsForIP := h.srv.conns.roomsPerIP[ip]
	h.srv.conns.mu.Unlock()
	if roomsForIP != 1 {
		t.Fatalf("roomsPerIP[%q]=%d, want 1", ip, roomsForIP)
	}
}

// ======================================================================
// handleWS — join case
// ======================================================================

func TestJoinSucceedsAndBroadcastsPeerJoined(t *testing.T) {
	h := newRelayHarness(t)
	host := h.dial(t, "2.0.0.1")
	host.send(clientMsg{Type: relayTypeCreate, SessionID: "J1", PeerID: "H"})
	host.expectAuthority(relayTypeCreated, "H")

	guest := h.dial(t, "2.0.0.2")
	guest.send(clientMsg{Type: relayTypeJoin, SessionID: "J1", PeerID: "G"})
	joined := guest.expectAuthority(relayTypeJoined, "H")
	if joined.SessionID != "J1" {
		t.Errorf("SessionID=%q want J1", joined.SessionID)
	}
	if len(joined.Peers) != 1 || joined.Peers[0] != "H" {
		t.Errorf("Peers=%v, want [H]", joined.Peers)
	}

	peerJoined := host.expect(relayTypePeerJoined)
	if peerJoined.PeerID != "G" {
		t.Errorf("peerJoined.PeerID=%q want G", peerJoined.PeerID)
	}
}

func TestHostIdentityClaimsRequireReconnectCapability(t *testing.T) {
	h := newRelayHarness(t)
	host := h.dial(t, "2.0.1.1")
	host.send(clientMsg{Type: relayTypeCreate, SessionID: "AUTH", PeerID: "HOST"})
	created := host.expectAuthority(relayTypeCreated, "HOST")

	guest := h.dial(t, "2.0.1.2")
	guest.send(clientMsg{Type: relayTypeJoin, SessionID: "AUTH", PeerID: "GUEST"})
	guest.expectAuthority(relayTypeJoined, "HOST")
	host.expect(relayTypePeerJoined)

	attacker := h.dial(t, "2.0.1.3")
	attacker.send(clientMsg{Type: relayTypeJoin, SessionID: "AUTH", PeerID: "HOST"})
	attacker.expectError(relayErrorPeerIdUnavailable)
	wrongToken, _ := mustReconnectToken(t)
	attacker.send(clientMsg{
		Type:           relayTypeJoin,
		SessionID:      "AUTH",
		PeerID:         "HOST",
		ReconnectToken: wrongToken,
	})
	attacker.expectError(relayErrorPeerIdUnavailable)
	attacker.send(clientMsg{Type: relayTypeBroadcast, Payload: json.RawMessage(`{"forged":true}`)})
	attacker.expectError(relayErrorNotInRoom)

	host.send(clientMsg{Type: relayTypeBroadcast, Payload: json.RawMessage(`{"real":true}`)})
	message := guest.expect(relayTypeMessage)
	if message.From != "HOST" {
		t.Fatalf("message sender=%q, want HOST", message.From)
	}

	hostVerifier, ok := reconnectVerifierFromToken(created.ReconnectToken)
	if !ok {
		t.Fatal("created reconnect token became invalid")
	}
	h.srv.mu.RLock()
	room := h.srv.rooms["AUTH"]
	h.srv.mu.RUnlock()
	room.mu.RLock()
	currentVerifier := room.hostVerifier
	currentHost := room.Peers["HOST"]
	room.mu.RUnlock()
	if !reconnectVerifierMatches(hostVerifier, currentVerifier) || currentHost == nil {
		t.Fatal("failed claims mutated host authority")
	}
}

func TestJoinMissingFieldsRejected(t *testing.T) {
	h := newRelayHarness(t)
	c := h.dial(t, "2.0.0.3")
	c.send(clientMsg{Type: "join"})
	c.expectError("invalid_message")
}

func TestRelayIdentifiersRejectUnsafeOrOversizedValues(t *testing.T) {
	h := newRelayHarness(t)
	c := h.dial(t, "2.0.0.30")

	invalid := []string{"has space", "has/slash", strings.Repeat("x", maxSessionIDLength+1)}
	for _, sessionID := range invalid {
		c.send(clientMsg{Type: "create", SessionID: sessionID, PeerID: "H"})
		c.expectError("invalid_message")
	}

	c.send(clientMsg{Type: "create", SessionID: "SAFE_ID-1", PeerID: "H"})
	c.expect("created")
	c.send(clientMsg{Type: "sendTo", To: "bad target", Payload: json.RawMessage(`{}`)})
	c.expectError("invalid_message")
}

func TestJoinUnknownRoomFails(t *testing.T) {
	h := newRelayHarness(t)
	c := h.dial(t, "2.0.0.4")
	c.send(clientMsg{Type: "join", SessionID: "NOPE", PeerID: "G"})
	c.expectError("room_not_found")
}

func TestReleasedGuestProbesDoNotConsumeDurableCapacity(t *testing.T) {
	h := newRelayHarness(t)
	hostToken, _ := mustReconnectToken(t)
	host := h.dial(t, "2.0.0.40")
	host.send(clientMsg{
		Type:            relayTypeCreate,
		SessionID:       "PROBE_CAPACITY",
		PeerID:          "H",
		ReconnectToken:  hostToken,
		ProtocolVersion: relayProtocolVersion,
	})
	host.expectAuthority(relayTypeCreated, "H")

	for i := range maxRoomSize * 2 {
		peerID := fmt.Sprintf("P%d", i)
		probeToken, _ := mustReconnectToken(t)
		probe := h.dial(t, fmt.Sprintf("2.0.1.%d", i+1))
		probe.send(clientMsg{
			Type:            relayTypeJoin,
			SessionID:       "PROBE_CAPACITY",
			PeerID:          peerID,
			ReconnectToken:  probeToken,
			ProtocolVersion: relayProtocolVersion,
		})
		probe.expectAuthority(relayTypeJoined, "H")
		host.expect(relayTypePeerJoined)
		probe.send(clientMsg{
			Type:            relayTypeLeave,
			ReconnectToken:  probeToken,
			ProtocolVersion: relayProtocolVersion,
		})
		probe.expect(relayTypeLeft)
		left := host.expect(relayTypePeerLeft)
		if left.PeerID != peerID {
			t.Fatalf("released probe event peerId=%q, want %q", left.PeerID, peerID)
		}
	}

	h.srv.mu.RLock()
	room := h.srv.rooms["PROBE_CAPACITY"]
	h.srv.mu.RUnlock()
	room.mu.RLock()
	reservations := len(room.peerReservations)
	room.mu.RUnlock()
	if reservations != 0 {
		t.Fatalf("released probes retained %d durable reservations", reservations)
	}

	for i := range maxRoomSize - 1 {
		peerID := fmt.Sprintf("G%d", i)
		token, _ := mustReconnectToken(t)
		guest := h.dial(t, fmt.Sprintf("2.0.2.%d", i+1))
		guest.send(clientMsg{
			Type:            relayTypeJoin,
			SessionID:       "PROBE_CAPACITY",
			PeerID:          peerID,
			ReconnectToken:  token,
			ProtocolVersion: relayProtocolVersion,
		})
		guest.expectAuthority(relayTypeJoined, "H")
		host.expect(relayTypePeerJoined)
	}
}

func TestFullRoomAllowsOnlyAuthenticatedLiveReplacements(t *testing.T) {
	h := newRelayHarness(t)
	hostToken, _ := mustReconnectToken(t)
	host := h.dial(t, "2.1.0.1")
	host.send(clientMsg{
		Type:            relayTypeCreate,
		SessionID:       "FULL",
		PeerID:          "H",
		ReconnectToken:  hostToken,
		ProtocolVersion: relayProtocolVersion,
	})
	created := host.expectAuthority(relayTypeCreated, "H")

	guests := make(map[string]*testConn)
	guestTokens := make(map[string]string)
	for i := 1; i < maxRoomSize; i++ {
		peerID := fmt.Sprintf("G%d", i)
		guestToken, _ := mustReconnectToken(t)
		guest := h.dial(t, fmt.Sprintf("2.1.0.%d", 100+i))
		guest.send(clientMsg{
			Type:            relayTypeJoin,
			SessionID:       "FULL",
			PeerID:          peerID,
			ReconnectToken:  guestToken,
			ProtocolVersion: relayProtocolVersion,
		})
		joined := guest.expectAuthority(relayTypeJoined, "H")
		if joined.ReconnectToken != guestToken {
			t.Fatalf("%s join rotated its client-known token", peerID)
		}
		guests[peerID] = guest
		guestTokens[peerID] = guestToken
	}
	for range maxRoomSize - 1 {
		host.expect(relayTypePeerJoined)
	}
	for range maxRoomSize - 2 {
		guests["G1"].expect(relayTypePeerJoined)
	}

	overflowToken, _ := mustReconnectToken(t)
	overflow := h.dial(t, "2.1.0.250")
	overflow.send(clientMsg{
		Type:            relayTypeJoin,
		SessionID:       "FULL",
		PeerID:          "LATE",
		ReconnectToken:  overflowToken,
		ProtocolVersion: relayProtocolVersion,
	})
	overflow.expectError(relayErrorRoomFull)
	overflow.send(clientMsg{Type: relayTypeBroadcast, Payload: json.RawMessage(`{}`)})
	overflow.expectError(relayErrorNotInRoom)

	unprovedHost := h.dial(t, "2.1.0.251")
	unprovedHost.send(clientMsg{
		Type:            relayTypeJoin,
		SessionID:       "FULL",
		PeerID:          "H",
		ProtocolVersion: relayProtocolVersion,
	})
	unprovedHost.expectError(relayErrorPeerIdUnavailable)
	unprovedGuest := h.dial(t, "2.1.0.252")
	unprovedGuest.send(clientMsg{
		Type:            relayTypeJoin,
		SessionID:       "FULL",
		PeerID:          "G1",
		ProtocolVersion: relayProtocolVersion,
	})
	unprovedGuest.expectError(relayErrorPeerIdUnavailable)
	wrongGuestToken, _ := mustReconnectToken(t)
	unprovedGuest.send(clientMsg{
		Type:            relayTypeJoin,
		SessionID:       "FULL",
		PeerID:          "G1",
		ReconnectToken:  wrongGuestToken,
		ProtocolVersion: relayProtocolVersion,
	})
	unprovedGuest.expectError(relayErrorPeerIdUnavailable)

	newHost := h.dial(t, "2.1.0.253")
	newHost.send(clientMsg{
		Type:            relayTypeJoin,
		SessionID:       "FULL",
		PeerID:          "H",
		ReconnectToken:  created.ReconnectToken,
		ProtocolVersion: relayProtocolVersion,
	})
	hostJoined := newHost.expectAuthority(relayTypeJoined, "H")
	if len(hostJoined.Peers) != maxRoomSize-1 {
		t.Fatalf("replacement host peers=%v, want %d peers", hostJoined.Peers, maxRoomSize-1)
	}
	if messages, err := host.recvUntilClosed(2 * time.Second); err != nil {
		t.Fatalf("displaced host did not close: %v (frames=%v)", err, messages)
	}
	hostReturn := guests["G1"].expect(relayTypePeerJoined)
	if hostReturn.PeerID != "H" {
		t.Fatalf("host replacement event peerId=%q", hostReturn.PeerID)
	}

	newGuest := h.dial(t, "2.1.0.254")
	newGuest.send(clientMsg{
		Type:            relayTypeJoin,
		SessionID:       "FULL",
		PeerID:          "G1",
		ReconnectToken:  guestTokens["G1"],
		ProtocolVersion: relayProtocolVersion,
	})
	newGuest.expectAuthority(relayTypeJoined, "H")
	if messages, err := guests["G1"].recvUntilClosed(2 * time.Second); err != nil {
		t.Fatalf("displaced guest did not close: %v (frames=%v)", err, messages)
	}
	guestReturn := newHost.expect(relayTypePeerJoined)
	if guestReturn.PeerID != "G1" {
		t.Fatalf("guest replacement event peerId=%q", guestReturn.PeerID)
	}

	newHost.send(clientMsg{Type: relayTypeBroadcast, Payload: json.RawMessage(`{"state":"current"}`)})
	message := newGuest.expect(relayTypeMessage)
	if message.From != "H" {
		t.Fatalf("replacement sender=%q, want H", message.From)
	}
}

func TestDisconnectedHostKeepsAReservedRoomSlot(t *testing.T) {
	h := newRelayHarness(t)
	host := h.dial(t, "2.1.1.1")
	host.send(clientMsg{Type: relayTypeCreate, SessionID: "HOST_SLOT", PeerID: "H"})
	created := host.expectAuthority(relayTypeCreated, "H")

	for i := 1; i < maxRoomSize; i++ {
		guest := h.dial(t, fmt.Sprintf("2.1.1.%d", 100+i))
		guest.send(clientMsg{
			Type:      relayTypeJoin,
			SessionID: "HOST_SLOT",
			PeerID:    fmt.Sprintf("G%d", i),
		})
		guest.expectAuthority(relayTypeJoined, "H")
	}
	h.waitRoomPeers(t, "HOST_SLOT", maxRoomSize)

	if err := host.conn.Close(); err != nil {
		t.Fatalf("close host: %v", err)
	}
	h.waitRoomPeers(t, "HOST_SLOT", maxRoomSize-1)

	lateGuest := h.dial(t, "2.1.1.250")
	lateGuest.send(clientMsg{Type: relayTypeJoin, SessionID: "HOST_SLOT", PeerID: "LATE"})
	lateGuest.expectError(relayErrorRoomFull)

	returningHost := h.dial(t, "2.1.1.251")
	returningHost.send(clientMsg{
		Type:           relayTypeJoin,
		SessionID:      "HOST_SLOT",
		PeerID:         "H",
		ReconnectToken: created.ReconnectToken,
	})
	joined := returningHost.expectAuthority(relayTypeJoined, "H")
	if len(joined.Peers) != maxRoomSize-1 {
		t.Fatalf("returning host peers=%v, want %d peers", joined.Peers, maxRoomSize-1)
	}
	h.waitRoomPeers(t, "HOST_SLOT", maxRoomSize)
}

func TestLegacySameSourceHostReconnectAndModernTokenEnforcement(t *testing.T) {
	t.Run("legacy same-source tokenless reconnect", func(t *testing.T) {
		h := newRelayHarness(t)
		source := "2.1.2.1"
		host := h.dial(t, source)
		host.send(clientMsg{Type: relayTypeCreate, SessionID: "LEGACY_RECONNECT", PeerID: "H"})
		host.expectAuthority(relayTypeCreated, "H")

		guest := h.dial(t, "2.1.2.2")
		guest.send(clientMsg{Type: relayTypeJoin, SessionID: "LEGACY_RECONNECT", PeerID: "G"})
		guest.expectAuthority(relayTypeJoined, "H")
		host.expect(relayTypePeerJoined)

		if err := host.conn.Close(); err != nil {
			t.Fatalf("close legacy host: %v", err)
		}
		left := guest.expect(relayTypePeerLeft)
		if left.PeerID != "H" {
			t.Fatalf("legacy disconnect peerId=%q, want H", left.PeerID)
		}

		returning := h.dial(t, source)
		returning.send(clientMsg{Type: relayTypeJoin, SessionID: "LEGACY_RECONNECT", PeerID: "H"})
		joined := returning.expect(relayTypeJoined)
		if joined.HostPeerID != "H" || joined.ReconnectToken != "" || joined.ProtocolVersion != legacyRelayProtocolVersion {
			t.Fatalf("legacy reconnect authority=%+v", joined)
		}
		rejoined := guest.expect(relayTypePeerJoined)
		if rejoined.PeerID != "H" {
			t.Fatalf("legacy reconnect event peerId=%q, want H", rejoined.PeerID)
		}
	})

	t.Run("modern same-source reconnect requires token", func(t *testing.T) {
		h := newRelayHarness(t)
		source := "2.1.3.1"
		hostToken, _ := mustReconnectToken(t)
		host := h.dial(t, source)
		host.send(clientMsg{
			Type:            relayTypeCreate,
			SessionID:       "MODERN_RECONNECT",
			PeerID:          "H",
			ReconnectToken:  hostToken,
			ProtocolVersion: relayProtocolVersion,
		})
		host.expectAuthority(relayTypeCreated, "H")

		guestToken, _ := mustReconnectToken(t)
		guest := h.dial(t, "2.1.3.2")
		guest.send(clientMsg{
			Type:            relayTypeJoin,
			SessionID:       "MODERN_RECONNECT",
			PeerID:          "G",
			ReconnectToken:  guestToken,
			ProtocolVersion: relayProtocolVersion,
		})
		guest.expectAuthority(relayTypeJoined, "H")
		host.expect(relayTypePeerJoined)

		if err := host.conn.Close(); err != nil {
			t.Fatalf("close modern host: %v", err)
		}
		left := guest.expect(relayTypePeerLeft)
		if left.PeerID != "H" {
			t.Fatalf("modern disconnect peerId=%q, want H", left.PeerID)
		}

		unproved := h.dial(t, source)
		unproved.send(clientMsg{
			Type:            relayTypeJoin,
			SessionID:       "MODERN_RECONNECT",
			PeerID:          "H",
			ProtocolVersion: relayProtocolVersion,
		})
		unproved.expectError(relayErrorPeerIdUnavailable)

		returning := h.dial(t, source)
		returning.send(clientMsg{
			Type:            relayTypeJoin,
			SessionID:       "MODERN_RECONNECT",
			PeerID:          "H",
			ReconnectToken:  hostToken,
			ProtocolVersion: relayProtocolVersion,
		})
		joined := returning.expectAuthority(relayTypeJoined, "H")
		if joined.ReconnectToken != hostToken || joined.ProtocolVersion != relayProtocolVersion {
			t.Fatalf("modern reconnect authority changed: %+v", joined)
		}
	})
}

func TestJoinAdmissionIsAtomicWithEmptyRoomCleanup(t *testing.T) {
	h := newRelayHarness(t)
	_, hostVerifier := mustReconnectToken(t)
	now := time.Now()
	room := &Room{
		SessionID:        "ATOMIC_CLEANUP",
		HostPeerID:       "H",
		hostVerifier:     hostVerifier,
		peerReservations: make(map[string]peerReservation),
		Peers:            make(map[string]*Client),
		CreatedAt:        now.Add(-time.Hour),
		LastActivityAt:   now.Add(-emptyRoomMaxAge - time.Second),
	}
	h.srv.mu.Lock()
	h.srv.rooms[room.SessionID] = room
	h.srv.mu.Unlock()

	reached := make(chan struct{})
	release := make(chan struct{})
	var once sync.Once
	h.srv.beforeJoinRoomLock = func() {
		once.Do(func() {
			close(reached)
			<-release
		})
	}

	joiner := h.dial(t, "2.2.0.1")
	joiner.send(clientMsg{Type: relayTypeJoin, SessionID: room.SessionID, PeerID: "G1"})
	<-reached

	cleanupDone := make(chan struct{})
	go func() {
		h.srv.runCleanupStep(now)
		close(cleanupDone)
	}()
	select {
	case <-cleanupDone:
		t.Fatal("cleanup passed a join that still owns the server read lock")
	case <-time.After(100 * time.Millisecond):
	}

	close(release)
	joiner.expectAuthority(relayTypeJoined, "H")
	<-cleanupDone

	h.srv.mu.RLock()
	current := h.srv.rooms[room.SessionID]
	h.srv.mu.RUnlock()
	if current != room {
		t.Fatal("successful join committed to a detached room")
	}
	room.mu.RLock()
	_, present := room.Peers["G1"]
	room.mu.RUnlock()
	if !present {
		t.Fatal("joining peer missing from authoritative room")
	}

	second := h.dial(t, "2.2.0.2")
	second.send(clientMsg{Type: relayTypeJoin, SessionID: room.SessionID, PeerID: "G2"})
	second.expectAuthority(relayTypeJoined, "H")
	joiner.expect(relayTypePeerJoined)
	second.send(clientMsg{Type: relayTypeBroadcast, Payload: json.RawMessage(`{"atomic":true}`)})
	if message := joiner.expect(relayTypeMessage); message.From != "G2" {
		t.Fatalf("message sender=%q, want G2", message.From)
	}
}

func TestJoinAdmissionIsAtomicWithReservedRoomCreate(t *testing.T) {
	h := newRelayHarness(t)
	_, hostVerifier := mustReconnectToken(t)
	now := time.Now()
	room := &Room{
		SessionID:        "ATOMIC_CREATE",
		HostPeerID:       "H",
		hostVerifier:     hostVerifier,
		peerReservations: make(map[string]peerReservation),
		Peers:            make(map[string]*Client),
		CreatedAt:        now,
		LastActivityAt:   now,
	}
	h.srv.mu.Lock()
	h.srv.rooms[room.SessionID] = room
	h.srv.mu.Unlock()

	reached := make(chan struct{})
	release := make(chan struct{})
	var once sync.Once
	h.srv.beforeJoinRoomLock = func() {
		once.Do(func() {
			close(reached)
			<-release
		})
	}

	joiner := h.dial(t, "2.3.0.1")
	joiner.send(clientMsg{Type: relayTypeJoin, SessionID: room.SessionID, PeerID: "G"})
	<-reached

	creator := h.dial(t, "2.3.0.2")
	creator.send(clientMsg{Type: relayTypeCreate, SessionID: room.SessionID, PeerID: "OTHER"})
	type readResult struct {
		message serverMsg
		err     error
	}
	createResult := make(chan readResult, 1)
	go func() {
		creator.conn.SetReadDeadline(time.Now().Add(2 * time.Second))
		_, data, err := creator.conn.ReadMessage()
		if err != nil {
			createResult <- readResult{err: err}
			return
		}
		var message serverMsg
		err = json.Unmarshal(data, &message)
		createResult <- readResult{message: message, err: err}
	}()

	select {
	case result := <-createResult:
		t.Fatalf("create completed before join admission committed: message=%+v err=%v", result.message, result.err)
	case <-time.After(100 * time.Millisecond):
	}

	close(release)
	joiner.expectAuthority(relayTypeJoined, "H")
	result := <-createResult
	if result.err != nil {
		t.Fatalf("read create result: %v", result.err)
	}
	if result.message.Type != relayTypeError || result.message.Code != relayErrorRoomExists {
		t.Fatalf("create result=%+v, want room_exists", result.message)
	}
	h.srv.mu.RLock()
	current := h.srv.rooms[room.SessionID]
	h.srv.mu.RUnlock()
	if current != room {
		t.Fatal("reserved room was replaced during admission")
	}
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

func TestRelayMessagesRefreshRoomActivity(t *testing.T) {
	h := newRelayHarness(t)
	host := h.dial(t, "4.0.0.7")
	host.send(clientMsg{Type: "create", SessionID: "ACTIVE", PeerID: "H"})
	host.expect("created")

	guest := h.dial(t, "4.0.0.8")
	guest.send(clientMsg{Type: "join", SessionID: "ACTIVE", PeerID: "G"})
	guest.expect("joined")
	host.expect("peerJoined")

	h.srv.mu.RLock()
	room := h.srv.rooms["ACTIVE"]
	h.srv.mu.RUnlock()
	old := time.Now().Add(-time.Hour)

	room.mu.Lock()
	room.LastActivityAt = old
	room.mu.Unlock()
	host.send(clientMsg{Type: "broadcast", Payload: json.RawMessage(`{"broadcast":true}`)})
	guest.expect("message")
	room.mu.RLock()
	broadcastActivity := room.LastActivityAt
	room.mu.RUnlock()
	if !broadcastActivity.After(old) {
		t.Fatalf("broadcast activity=%v, want after %v", broadcastActivity, old)
	}

	room.mu.Lock()
	room.LastActivityAt = old
	room.mu.Unlock()
	host.send(clientMsg{Type: "sendTo", To: "G", Payload: json.RawMessage(`{"direct":true}`)})
	guest.expect("message")
	room.mu.RLock()
	directActivity := room.LastActivityAt
	room.mu.RUnlock()
	if !directActivity.After(old) {
		t.Fatalf("sendTo activity=%v, want after %v", directActivity, old)
	}
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
	hostToken, _ := mustReconnectToken(t)
	host := h.dial(t, "6.1.0.1")
	host.send(clientMsg{
		Type:            relayTypeCreate,
		SessionID:       "D2",
		PeerID:          "H",
		ReconnectToken:  hostToken,
		ProtocolVersion: relayProtocolVersion,
	})
	host.expectAuthority(relayTypeCreated, "H")

	guestToken, _ := mustReconnectToken(t)
	g1 := h.dial(t, "6.1.0.2")
	g1.send(clientMsg{
		Type:            relayTypeJoin,
		SessionID:       "D2",
		PeerID:          "G",
		ReconnectToken:  guestToken,
		ProtocolVersion: relayProtocolVersion,
	})
	g1.expectAuthority(relayTypeJoined, "H")
	host.expect(relayTypePeerJoined)

	g2 := h.dial(t, "6.1.0.3")
	g2.send(clientMsg{
		Type:            relayTypeJoin,
		SessionID:       "D2",
		PeerID:          "G",
		ReconnectToken:  guestToken,
		ProtocolVersion: relayProtocolVersion,
	})
	g2.expectAuthority(relayTypeJoined, "H")
	host.expect(relayTypePeerJoined)

	if messages, err := g1.recvUntilClosed(2 * time.Second); err != nil {
		t.Fatalf("displaced guest did not close: %v (frames=%v)", err, messages)
	}
	h.srv.mu.RLock()
	room := h.srv.rooms["D2"]
	room.mu.RLock()
	reservation := room.peerReservations["G"]
	room.mu.RUnlock()
	h.srv.mu.RUnlock()
	if !reservation.absentSince.IsZero() {
		t.Fatalf("stale displaced client stamped live replacement absent at %v", reservation.absentSince)
	}
	host.send(clientMsg{Type: relayTypeBroadcast, Payload: json.RawMessage(`{"after":"replacement"}`)})
	message := g2.expect(relayTypeMessage)
	if message.From != "H" {
		t.Fatalf("post-replacement sender=%q, want H", message.From)
	}
}

func TestDisconnectedModernGuestIdentityRejectsTheftAndAcceptsRightfulReconnect(t *testing.T) {
	h := newRelayHarness(t)
	hostToken, _ := mustReconnectToken(t)
	host := h.dial(t, "6.1.0.10")
	host.send(clientMsg{
		Type:            relayTypeCreate,
		SessionID:       "GUEST_RECONNECT",
		PeerID:          "H",
		ReconnectToken:  hostToken,
		ProtocolVersion: relayProtocolVersion,
	})
	host.expectAuthority(relayTypeCreated, "H")

	guestToken, guestVerifier := mustReconnectToken(t)
	guest := h.dial(t, "6.1.0.11")
	guest.send(clientMsg{
		Type:            relayTypeJoin,
		SessionID:       "GUEST_RECONNECT",
		PeerID:          "G",
		ReconnectToken:  guestToken,
		ProtocolVersion: relayProtocolVersion,
	})
	guest.expectAuthority(relayTypeJoined, "H")
	host.expect(relayTypePeerJoined)

	if err := guest.conn.Close(); err != nil {
		t.Fatalf("close guest: %v", err)
	}
	left := host.expect(relayTypePeerLeft)
	if left.PeerID != "G" {
		t.Fatalf("disconnected peerId=%q, want G", left.PeerID)
	}
	h.srv.mu.RLock()
	room := h.srv.rooms["GUEST_RECONNECT"]
	room.mu.RLock()
	disconnectedReservation, reserved := room.peerReservations["G"]
	room.mu.RUnlock()
	h.srv.mu.RUnlock()
	if !reserved || disconnectedReservation.absentSince.IsZero() {
		t.Fatalf("authoritative disconnect reservation=%+v present=%v, want stamped absence", disconnectedReservation, reserved)
	}
	if !reconnectVerifierMatches(disconnectedReservation.verifier, guestVerifier) {
		t.Fatal("authoritative disconnect changed the retained guest verifier")
	}

	thiefToken, _ := mustReconnectToken(t)
	thief := h.dial(t, "6.1.0.12")
	thief.send(clientMsg{
		Type:            relayTypeJoin,
		SessionID:       "GUEST_RECONNECT",
		PeerID:          "G",
		ReconnectToken:  thiefToken,
		ProtocolVersion: relayProtocolVersion,
	})
	thief.expectError(relayErrorPeerIdUnavailable)
	thief.send(clientMsg{Type: relayTypeBroadcast, Payload: json.RawMessage(`{"forged":true}`)})
	thief.expectError(relayErrorNotInRoom)

	rightful := h.dial(t, "6.1.0.13")
	rightful.send(clientMsg{
		Type:            relayTypeJoin,
		SessionID:       "GUEST_RECONNECT",
		PeerID:          "G",
		ReconnectToken:  guestToken,
		ProtocolVersion: relayProtocolVersion,
	})
	joined := rightful.expectAuthority(relayTypeJoined, "H")
	if joined.ReconnectToken != guestToken {
		t.Fatal("rightful reconnect rotated the retained guest token")
	}
	rejoined := host.expect(relayTypePeerJoined)
	if rejoined.PeerID != "G" {
		t.Fatalf("rightful reconnect event peerId=%q, want G", rejoined.PeerID)
	}
	h.srv.mu.RLock()
	room = h.srv.rooms["GUEST_RECONNECT"]
	room.mu.RLock()
	reconnectedReservation := room.peerReservations["G"]
	room.mu.RUnlock()
	h.srv.mu.RUnlock()
	if !reconnectedReservation.absentSince.IsZero() {
		t.Fatalf("rightful reconnect retained absence timestamp %v", reconnectedReservation.absentSince)
	}
	if !reconnectVerifierMatches(reconnectedReservation.verifier, guestVerifier) {
		t.Fatal("rightful reconnect changed the retained guest verifier")
	}
}

func fillDisconnectedGuestReservations(
	t *testing.T,
	h *relayHarness,
	sessionID string,
) (*testConn, *Room) {
	t.Helper()
	hostToken, _ := mustReconnectToken(t)
	host := h.dial(t, "6.2.0.1")
	host.send(clientMsg{
		Type:            relayTypeCreate,
		SessionID:       sessionID,
		PeerID:          "H",
		ReconnectToken:  hostToken,
		ProtocolVersion: relayProtocolVersion,
	})
	host.expectAuthority(relayTypeCreated, "H")
	for index := range maxRoomSize - 1 {
		guestToken, _ := mustReconnectToken(t)
		guest := h.dial(t, fmt.Sprintf("6.2.1.%d", index+1))
		peerID := fmt.Sprintf("G%d", index)
		guest.send(clientMsg{
			Type:            relayTypeJoin,
			SessionID:       sessionID,
			PeerID:          peerID,
			ReconnectToken:  guestToken,
			ProtocolVersion: relayProtocolVersion,
		})
		guest.expectAuthority(relayTypeJoined, "H")
		host.expect(relayTypePeerJoined)
		if err := guest.conn.Close(); err != nil {
			t.Fatalf("close guest %s: %v", peerID, err)
		}
		left := host.expect(relayTypePeerLeft)
		if left.PeerID != peerID {
			t.Fatalf("disconnect event peerId=%q, want %q", left.PeerID, peerID)
		}
	}
	h.srv.mu.RLock()
	room := h.srv.rooms[sessionID]
	h.srv.mu.RUnlock()
	return host, room
}

func expireDisconnectedReservations(room *Room, now time.Time) {
	room.mu.Lock()
	for peerID, reservation := range room.peerReservations {
		reservation.absentSince = now.Add(-peerReservationGrace - time.Second)
		room.peerReservations[peerID] = reservation
	}
	room.mu.Unlock()
}

func TestDisconnectedModernGuestReservationsExpireAndRestoreCapacity(t *testing.T) {
	t.Run("admission prunes without cleanup tick", func(t *testing.T) {
		h := newRelayHarness(t)
		host, room := fillDisconnectedGuestReservations(t, h, "RESERVATION_ADMISSION")
		freshToken, _ := mustReconnectToken(t)
		fresh := h.dial(t, "6.2.2.1")
		join := clientMsg{
			Type:            relayTypeJoin,
			SessionID:       "RESERVATION_ADMISSION",
			PeerID:          "FRESH",
			ReconnectToken:  freshToken,
			ProtocolVersion: relayProtocolVersion,
		}
		fresh.send(join)
		fresh.expectError(relayErrorRoomFull)

		expireDisconnectedReservations(room, time.Now())
		fresh.send(join)
		joined := fresh.expectAuthority(relayTypeJoined, "H")
		if joined.ReconnectToken != freshToken {
			t.Fatal("fresh admission changed its reconnect capability")
		}
		host.expect(relayTypePeerJoined)
		room.mu.RLock()
		if len(room.peerReservations) != 1 {
			t.Fatalf("admission-time prune retained %d reservations, want only fresh peer", len(room.peerReservations))
		}
		_, freshReserved := room.peerReservations["FRESH"]
		room.mu.RUnlock()
		if !freshReserved {
			t.Fatal("fresh admission was not reserved")
		}
	})

	t.Run("cleanup persists pruning and keeps active guest", func(t *testing.T) {
		root := t.TempDir()
		statePath := filepath.Join(root, "rooms.json")
		h := newRelayHarnessAt(t, filepath.Join(root, "logs"), statePath)
		host, room := fillDisconnectedGuestReservations(t, h, "RESERVATION_CLEANUP")
		expireDisconnectedReservations(room, time.Now())
		h.srv.runCleanupStep(time.Now())
		room.mu.RLock()
		if len(room.peerReservations) != 0 {
			t.Fatalf("cleanup retained %d expired reservations", len(room.peerReservations))
		}
		room.mu.RUnlock()

		freshToken, _ := mustReconnectToken(t)
		fresh := h.dial(t, "6.2.2.2")
		fresh.send(clientMsg{
			Type:            relayTypeJoin,
			SessionID:       "RESERVATION_CLEANUP",
			PeerID:          "ACTIVE",
			ReconnectToken:  freshToken,
			ProtocolVersion: relayProtocolVersion,
		})
		fresh.expectAuthority(relayTypeJoined, "H")
		host.expect(relayTypePeerJoined)
		room.mu.Lock()
		active := room.peerReservations["ACTIVE"]
		active.absentSince = time.Now().Add(-peerReservationGrace - time.Second)
		room.peerReservations["ACTIVE"] = active
		room.mu.Unlock()
		h.srv.runCleanupStep(time.Now())
		room.mu.RLock()
		_, activeReserved := room.peerReservations["ACTIVE"]
		room.mu.RUnlock()
		if !activeReserved {
			t.Fatal("cleanup pruned an authoritative connected guest")
		}
		room.mu.Lock()
		active = room.peerReservations["ACTIVE"]
		active.absentSince = time.Time{}
		room.peerReservations["ACTIVE"] = active
		h.srv.snap.recordMutation()
		room.mu.Unlock()

		if err := h.srv.snap.flushAndStop(2 * time.Second); err != nil {
			t.Fatalf("flush cleanup mutation: %v", err)
		}
		data, err := os.ReadFile(statePath)
		if err != nil {
			t.Fatalf("read cleanup snapshot: %v", err)
		}
		var snapshot stateSnapshot
		if err := json.Unmarshal(data, &snapshot); err != nil {
			t.Fatalf("decode cleanup snapshot: %v", err)
		}
		for _, persistedRoom := range snapshot.Rooms {
			if persistedRoom.SessionID != "RESERVATION_CLEANUP" {
				continue
			}
			for index := range maxRoomSize - 1 {
				if _, retained := persistedRoom.PeerReservations[fmt.Sprintf("G%d", index)]; retained {
					t.Fatalf("cleanup snapshot retained expired reservation G%d", index)
				}
			}
		}
	})
}

func TestAdmissionPrunePersistsWhenJoinRejected(t *testing.T) {
	root := t.TempDir()
	statePath := filepath.Join(root, "rooms.json")
	h := newRelayHarnessAt(t, filepath.Join(root, "logs"), statePath)
	_, room := fillDisconnectedGuestReservations(t, h, "REJECTED_AFTER_PRUNE")
	expireDisconnectedReservations(room, time.Now())

	wrongHostToken, _ := mustReconnectToken(t)
	rejected := h.dial(t, "6.2.2.3")
	rejected.send(clientMsg{
		Type:            relayTypeJoin,
		SessionID:       "REJECTED_AFTER_PRUNE",
		PeerID:          "H",
		ReconnectToken:  wrongHostToken,
		ProtocolVersion: relayProtocolVersion,
	})
	rejected.expectError(relayErrorPeerIdUnavailable)
	room.mu.RLock()
	if len(room.peerReservations) != 0 {
		t.Fatalf("rejected admission retained %d expired reservations", len(room.peerReservations))
	}
	room.mu.RUnlock()

	if err := h.srv.snap.flushAndStop(2 * time.Second); err != nil {
		t.Fatalf("flush rejected-admission prune: %v", err)
	}
	data, err := os.ReadFile(statePath)
	if err != nil {
		t.Fatalf("read rejected-admission snapshot: %v", err)
	}
	var snapshot stateSnapshot
	if err := json.Unmarshal(data, &snapshot); err != nil {
		t.Fatalf("decode rejected-admission snapshot: %v", err)
	}
	if len(snapshot.Rooms) != 1 || len(snapshot.Rooms[0].PeerReservations) != 0 {
		t.Fatalf("rejected-admission snapshot retained reservations: %+v", snapshot.Rooms)
	}
}

func TestExpiredGuestReservationLosesExclusiveClaim(t *testing.T) {
	h := newRelayHarness(t)
	host, room := fillDisconnectedGuestReservations(t, h, "EXPIRED_CLAIM")
	expireDisconnectedReservations(room, time.Now())
	room.mu.Lock()
	if !pruneExpiredPeerReservationsLocked(room, time.Now()) {
		room.mu.Unlock()
		t.Fatal("expired reservations were not physically pruned")
	}
	h.srv.snap.recordMutation()
	if _, retained := room.peerReservations["G0"]; retained {
		room.mu.Unlock()
		t.Fatal("expired peer ID remained exclusively reserved")
	}
	room.mu.Unlock()

	freshToken, _ := mustReconnectToken(t)
	fresh := h.dial(t, "6.2.3.1")
	fresh.send(clientMsg{
		Type:            relayTypeJoin,
		SessionID:       "EXPIRED_CLAIM",
		PeerID:          "G0",
		ReconnectToken:  freshToken,
		ProtocolVersion: relayProtocolVersion,
	})
	joined := fresh.expectAuthority(relayTypeJoined, "H")
	if joined.ReconnectToken != freshToken {
		t.Fatal("expired peer ID was treated as a privileged reconnect")
	}
	host.expect(relayTypePeerJoined)
}

func TestGuestReservationSnapshotV4Migration(t *testing.T) {
	statePath := filepath.Join(t.TempDir(), "rooms.json")
	now := time.Now().UTC()
	_, hostVerifier := mustReconnectToken(t)
	_, guestVerifier := mustReconnectToken(t)
	legacy := stateSnapshot{
		Version: 3,
		SavedAt: now,
		Rooms: []roomSnapshot{{
			SessionID:              "V3_MIGRATION",
			HostPeerID:             "H",
			ProtocolVersion:        relayProtocolVersion,
			HostReconnectVerifier:  encodeReconnectVerifier(hostVerifier),
			PeerReconnectVerifiers: map[string]string{"G": encodeReconnectVerifier(guestVerifier)},
			CreatedAt:              now.Add(-time.Minute),
			LastActivityAt:         now,
		}},
	}
	data, err := json.Marshal(legacy)
	if err != nil {
		t.Fatalf("marshal v3 fixture: %v", err)
	}
	if err := os.WriteFile(statePath, data, 0644); err != nil {
		t.Fatalf("write v3 fixture: %v", err)
	}

	h := newRelayHarnessAt(t, t.TempDir(), statePath)
	rewritten, err := os.ReadFile(statePath)
	if err != nil {
		t.Fatalf("read synchronous v4 rewrite: %v", err)
	}
	var snapshot stateSnapshot
	if err := json.Unmarshal(rewritten, &snapshot); err != nil {
		t.Fatalf("decode v4 rewrite: %v", err)
	}
	if snapshot.Version != snapshotFormatVersion {
		t.Fatalf("rewritten version=%d, want %d", snapshot.Version, snapshotFormatVersion)
	}
	reservation := snapshot.Rooms[0].PeerReservations["G"]
	if reservation.AbsentSinceUnixNano == 0 ||
		reservation.Verifier != encodeReconnectVerifier(guestVerifier) ||
		len(snapshot.Rooms[0].PeerReconnectVerifiers) != 0 {
		t.Fatalf("migrated reservation=%+v legacy=%v", reservation, snapshot.Rooms[0].PeerReconnectVerifiers)
	}
	h.srv.mu.RLock()
	room := h.srv.rooms["V3_MIGRATION"]
	if room == nil {
		h.srv.mu.RUnlock()
		t.Fatal("migrated room was not restored")
	}
	room.mu.RLock()
	runtimeReservation := room.peerReservations["G"]
	room.mu.RUnlock()
	h.srv.mu.RUnlock()
	if runtimeReservation.absentSince.IsZero() {
		t.Fatal("legacy reservation was restored as connected")
	}
}

func TestSnapshotV2LoadsAndRewritesV4(t *testing.T) {
	statePath := filepath.Join(t.TempDir(), "rooms.json")
	now := time.Now().UTC()
	_, hostVerifier := mustReconnectToken(t)
	legacy := stateSnapshot{
		Version: 2,
		SavedAt: now,
		Rooms: []roomSnapshot{{
			SessionID:             "V2_MIGRATION",
			HostPeerID:            "H",
			HostReconnectVerifier: encodeReconnectVerifier(hostVerifier),
			CreatedAt:             now.Add(-time.Minute),
			LastActivityAt:        now,
		}},
	}
	data, err := json.Marshal(legacy)
	if err != nil {
		t.Fatalf("marshal v2 fixture: %v", err)
	}
	if err := os.WriteFile(statePath, data, 0644); err != nil {
		t.Fatalf("write v2 fixture: %v", err)
	}
	h := newRelayHarnessAt(t, t.TempDir(), statePath)
	h.srv.mu.RLock()
	room := h.srv.rooms["V2_MIGRATION"]
	h.srv.mu.RUnlock()
	if room == nil || !reconnectVerifierMatches(room.hostVerifier, hostVerifier) {
		t.Fatal("v2 host authority did not load")
	}
	rewritten, err := os.ReadFile(statePath)
	if err != nil {
		t.Fatalf("read v2 rewrite: %v", err)
	}
	var snapshot stateSnapshot
	if err := json.Unmarshal(rewritten, &snapshot); err != nil {
		t.Fatalf("decode v2 rewrite: %v", err)
	}
	if snapshot.Version != snapshotFormatVersion {
		t.Fatalf("v2 rewrite version=%d, want %d", snapshot.Version, snapshotFormatVersion)
	}
}

func TestSnapshotV4RetainsGuestAbsenceAcrossRestart(t *testing.T) {
	statePath := filepath.Join(t.TempDir(), "rooms.json")
	now := time.Now().UTC().Truncate(time.Millisecond)
	absentSince := now.Add(-time.Minute)
	_, hostVerifier := mustReconnectToken(t)
	_, guestVerifier := mustReconnectToken(t)
	snapshot := stateSnapshot{
		Version: snapshotFormatVersion,
		SavedAt: now,
		Rooms: []roomSnapshot{{
			SessionID:             "V4_ABSENCE",
			HostPeerID:            "H",
			ProtocolVersion:       relayProtocolVersion,
			HostReconnectVerifier: encodeReconnectVerifier(hostVerifier),
			PeerReservations: map[string]peerReservationSnapshot{
				"G": {
					Verifier:            encodeReconnectVerifier(guestVerifier),
					AbsentSinceUnixNano: absentSince.UnixNano(),
				},
			},
			CreatedAt:      now.Add(-time.Minute),
			LastActivityAt: now,
		}},
	}
	data, err := json.Marshal(snapshot)
	if err != nil {
		t.Fatalf("marshal v4 fixture: %v", err)
	}
	if err := os.WriteFile(statePath, data, 0644); err != nil {
		t.Fatalf("write v4 fixture: %v", err)
	}

	first := newRelayHarnessAt(t, t.TempDir(), statePath)
	first.srv.mu.RLock()
	room := first.srv.rooms["V4_ABSENCE"]
	if room == nil {
		first.srv.mu.RUnlock()
		t.Fatal("v4 room missing after first restart")
	}
	room.mu.RLock()
	firstAbsence := room.peerReservations["G"].absentSince
	room.mu.RUnlock()
	first.srv.mu.RUnlock()
	if !firstAbsence.Equal(absentSince) {
		t.Fatalf("first restart absence=%v, want %v", firstAbsence, absentSince)
	}
	if err := first.srv.snap.flushAndStop(2 * time.Second); err != nil {
		t.Fatalf("flush first restart: %v", err)
	}

	second := newRelayHarnessAt(t, t.TempDir(), statePath)
	second.srv.mu.RLock()
	room = second.srv.rooms["V4_ABSENCE"]
	if room == nil {
		second.srv.mu.RUnlock()
		t.Fatal("v4 room missing after second restart")
	}
	room.mu.RLock()
	secondAbsence := room.peerReservations["G"].absentSince
	room.mu.RUnlock()
	second.srv.mu.RUnlock()
	if !secondAbsence.Equal(absentSince) {
		t.Fatalf("second restart refreshed absence=%v, want %v", secondAbsence, absentSince)
	}
}

func TestSnapshotV4InitializesAndPrunesReservationsBeforeServing(t *testing.T) {
	now := time.Now().UTC()
	_, hostVerifier := mustReconnectToken(t)
	_, connectedVerifier := mustReconnectToken(t)
	_, expiredVerifier := mustReconnectToken(t)
	statePath := filepath.Join(t.TempDir(), "rooms.json")
	snapshot := stateSnapshot{
		Version: snapshotFormatVersion,
		SavedAt: now,
		Rooms: []roomSnapshot{{
			SessionID:             "V4_STARTUP",
			HostPeerID:            "H",
			ProtocolVersion:       relayProtocolVersion,
			HostReconnectVerifier: encodeReconnectVerifier(hostVerifier),
			PeerReservations: map[string]peerReservationSnapshot{
				"CONNECTED": {Verifier: encodeReconnectVerifier(connectedVerifier)},
				"EXPIRED": {
					Verifier:            encodeReconnectVerifier(expiredVerifier),
					AbsentSinceUnixNano: now.Add(-peerReservationGrace - time.Second).UnixNano(),
				},
			},
			CreatedAt:      now.Add(-time.Minute),
			LastActivityAt: now,
		}},
	}
	data, err := json.Marshal(snapshot)
	if err != nil {
		t.Fatalf("marshal startup fixture: %v", err)
	}
	if err := os.WriteFile(statePath, data, 0644); err != nil {
		t.Fatalf("write startup fixture: %v", err)
	}

	h := newRelayHarnessAt(t, t.TempDir(), statePath)
	h.srv.mu.RLock()
	room := h.srv.rooms["V4_STARTUP"]
	if room == nil {
		h.srv.mu.RUnlock()
		t.Fatal("v4 startup room was not restored")
	}
	room.mu.RLock()
	connected := room.peerReservations["CONNECTED"]
	_, expired := room.peerReservations["EXPIRED"]
	room.mu.RUnlock()
	h.srv.mu.RUnlock()
	if connected.absentSince.IsZero() {
		t.Fatal("connected-at-capture reservation was not marked absent at startup")
	}
	if expired {
		t.Fatal("already-expired reservation survived startup pruning")
	}
	rewritten, err := os.ReadFile(statePath)
	if err != nil {
		t.Fatalf("read startup rewrite: %v", err)
	}
	var persisted stateSnapshot
	if err := json.Unmarshal(rewritten, &persisted); err != nil {
		t.Fatalf("decode startup rewrite: %v", err)
	}
	if persisted.Rooms[0].PeerReservations["CONNECTED"].AbsentSinceUnixNano == 0 {
		t.Fatal("startup rewrite did not persist initialized absence")
	}
	if _, retained := persisted.Rooms[0].PeerReservations["EXPIRED"]; retained {
		t.Fatal("startup rewrite retained expired reservation")
	}
}

func TestTerminalSuccessFramesFollowCommittedSnapshot(t *testing.T) {
	t.Run("guest leave releases persisted reservation", func(t *testing.T) {
		root := t.TempDir()
		statePath := filepath.Join(root, "rooms.json")
		h := newRelayHarnessAt(t, filepath.Join(root, "logs"), statePath)
		terminalReady := make(chan struct{})
		releaseTerminal := make(chan struct{})
		var releaseOnce sync.Once
		var syncCalls atomic.Int64
		var terminalSyncBaseline atomic.Int64
		h.srv.snap.syncDir = func(string) error {
			syncCalls.Add(1)
			return nil
		}
		h.srv.beforeTerminalDelivery = func() {
			if syncCalls.Load() <= terminalSyncBaseline.Load() {
				t.Error("terminal delivery preceded the covering directory-sync attempt")
			}
			close(terminalReady)
			<-releaseTerminal
		}
		t.Cleanup(func() {
			releaseOnce.Do(func() { close(releaseTerminal) })
		})

		host, guest, _, guestToken := createModernRoomWithGuest(
			t,
			h,
			"DURABLE_LEAVE",
			"6.1.0.20",
			"6.1.0.21",
		)
		terminalSyncBaseline.Store(syncCalls.Load())
		guest.send(clientMsg{
			Type:            relayTypeLeave,
			ReconnectToken:  guestToken,
			ProtocolVersion: relayProtocolVersion,
		})
		select {
		case <-terminalReady:
		case <-time.After(2 * time.Second):
			t.Fatal("leave did not reach the post-persistence delivery barrier")
		}

		restartPath := copySnapshotForRestart(t, statePath)
		restarted := newRelayHarnessAt(t, t.TempDir(), restartPath)
		replacementToken, _ := mustReconnectToken(t)
		replacement := restarted.dial(t, "6.1.0.22")
		replacement.send(clientMsg{
			Type:            relayTypeJoin,
			SessionID:       "DURABLE_LEAVE",
			PeerID:          "G",
			ReconnectToken:  replacementToken,
			ProtocolVersion: relayProtocolVersion,
		})
		replacement.expectAuthority(relayTypeJoined, "H")

		releaseOnce.Do(func() { close(releaseTerminal) })
		guest.expect(relayTypeLeft)
		left := host.expect(relayTypePeerLeft)
		if left.PeerID != "G" {
			t.Fatalf("released peer event peerId=%q, want G", left.PeerID)
		}
	})

	t.Run("host end removes persisted room", func(t *testing.T) {
		root := t.TempDir()
		statePath := filepath.Join(root, "rooms.json")
		h := newRelayHarnessAt(t, filepath.Join(root, "logs"), statePath)
		terminalReady := make(chan struct{})
		releaseTerminal := make(chan struct{})
		var releaseOnce sync.Once
		var syncCalls atomic.Int64
		var terminalSyncBaseline atomic.Int64
		h.srv.snap.syncDir = func(string) error {
			syncCalls.Add(1)
			return nil
		}
		h.srv.beforeTerminalDelivery = func() {
			if syncCalls.Load() <= terminalSyncBaseline.Load() {
				t.Error("terminal delivery preceded the covering directory-sync attempt")
			}
			close(terminalReady)
			<-releaseTerminal
		}
		t.Cleanup(func() {
			releaseOnce.Do(func() { close(releaseTerminal) })
		})

		host, guest, hostToken, _ := createModernRoomWithGuest(
			t,
			h,
			"DURABLE_END",
			"6.1.0.23",
			"6.1.0.24",
		)
		terminalSyncBaseline.Store(syncCalls.Load())
		host.send(clientMsg{
			Type:            relayTypeEndSession,
			ReconnectToken:  hostToken,
			ProtocolVersion: relayProtocolVersion,
		})
		select {
		case <-terminalReady:
		case <-time.After(2 * time.Second):
			t.Fatal("end did not reach the post-persistence delivery barrier")
		}

		restartPath := copySnapshotForRestart(t, statePath)
		restarted := newRelayHarnessAt(t, t.TempDir(), restartPath)
		probe := restarted.dial(t, "6.1.0.25")
		probe.send(clientMsg{
			Type:            relayTypeJoin,
			SessionID:       "DURABLE_END",
			PeerID:          "H",
			ReconnectToken:  hostToken,
			ProtocolVersion: relayProtocolVersion,
		})
		probe.expectError(relayErrorRoomNotFound)

		releaseOnce.Do(func() { close(releaseTerminal) })
		host.expect(relayTypeEnded)
		messages, err := guest.recvUntilClosed(2 * time.Second)
		if err != nil {
			t.Fatalf("guest remained connected after durable end: %v (frames=%v)", err, messages)
		}
		if len(messages) != 1 || messages[0].Type != relayTypeEnded {
			t.Fatalf("guest terminal frames=%+v, want one ended notification", messages)
		}
	})
}

func TestTerminalPersistenceFailureSuppressesSuccess(t *testing.T) {
	injectedErr := errors.New("injected snapshot persistence failure")

	t.Run("guest leave", func(t *testing.T) {
		root := t.TempDir()
		statePath := filepath.Join(root, "rooms.json")
		h := newRelayHarnessAt(t, filepath.Join(root, "logs"), statePath)
		host, guest, _, guestToken := createModernRoomWithGuest(
			t,
			h,
			"FAILED_LEAVE",
			"6.1.0.26",
			"6.1.0.27",
		)
		injectSnapshotPersistenceFailure(t, h.srv.snap, injectedErr)

		guest.send(clientMsg{
			Type:            relayTypeLeave,
			ReconnectToken:  guestToken,
			ProtocolVersion: relayProtocolVersion,
		})
		failure := guest.expectError(relayErrorInvalidMessage)
		if !strings.Contains(failure.Message, "persist") {
			t.Fatalf("leave persistence error message=%q", failure.Message)
		}
		h.srv.mu.RLock()
		room := h.srv.rooms["FAILED_LEAVE"]
		room.mu.RLock()
		liveClient := room.Peers["G"]
		reservation, reserved := room.peerReservations["G"]
		room.mu.RUnlock()
		h.srv.mu.RUnlock()
		if liveClient == nil || !reserved || reservation.releasePending || !reservation.absentSince.IsZero() {
			t.Fatalf("failed leave live state client=%p reservation=%+v present=%v", liveClient, reservation, reserved)
		}
		guest.send(clientMsg{Type: relayTypeBroadcast, Payload: json.RawMessage(`{"after":"failed-leave"}`)})
		message := host.expect(relayTypeMessage)
		if message.From != "G" {
			t.Fatalf("post-failure broadcast sender=%q, want G", message.From)
		}

		restartPath := copySnapshotForRestart(t, statePath)
		restarted := newRelayHarnessAt(t, t.TempDir(), restartPath)
		replacementToken, _ := mustReconnectToken(t)
		replacement := restarted.dial(t, "6.1.0.28")
		replacement.send(clientMsg{
			Type:            relayTypeJoin,
			SessionID:       "FAILED_LEAVE",
			PeerID:          "G",
			ReconnectToken:  replacementToken,
			ProtocolVersion: relayProtocolVersion,
		})
		replacement.expectError(relayErrorPeerIdUnavailable)
	})

	t.Run("host end", func(t *testing.T) {
		root := t.TempDir()
		statePath := filepath.Join(root, "rooms.json")
		h := newRelayHarnessAt(t, filepath.Join(root, "logs"), statePath)
		host, guest, hostToken, _ := createModernRoomWithGuest(
			t,
			h,
			"FAILED_END",
			"6.1.0.29",
			"6.1.0.30",
		)
		injectSnapshotPersistenceFailure(t, h.srv.snap, injectedErr)

		host.send(clientMsg{
			Type:            relayTypeEndSession,
			ReconnectToken:  hostToken,
			ProtocolVersion: relayProtocolVersion,
		})
		failure := host.expectError(relayErrorInvalidMessage)
		if !strings.Contains(failure.Message, "persist") {
			t.Fatalf("end persistence error message=%q", failure.Message)
		}
		messages, err := guest.recvUntilClosed(2 * time.Second)
		if err != nil {
			t.Fatalf("guest remained connected after failed end persistence: %v (frames=%v)", err, messages)
		}
		if len(messages) != 0 {
			t.Fatalf("guest received success frames after persistence failure: %+v", messages)
		}

		restartPath := copySnapshotForRestart(t, statePath)
		restarted := newRelayHarnessAt(t, t.TempDir(), restartPath)
		reconnected := restarted.dial(t, "6.1.0.31")
		reconnected.send(clientMsg{
			Type:            relayTypeJoin,
			SessionID:       "FAILED_END",
			PeerID:          "H",
			ReconnectToken:  hostToken,
			ProtocolVersion: relayProtocolVersion,
		})
		reconnected.expectAuthority(relayTypeJoined, "H")
	})
}

func waitForPendingReservation(t *testing.T, room *Room, peerID string) {
	t.Helper()
	deadline := time.Now().Add(2 * time.Second)
	for {
		room.mu.RLock()
		pending := room.peerReservations[peerID].releasePending
		room.mu.RUnlock()
		if pending {
			return
		}
		if time.Now().After(deadline) {
			t.Fatalf("reservation %s did not enter pending release", peerID)
		}
		time.Sleep(time.Millisecond)
	}
}

func makeCurrentSnapshotDurable(t *testing.T, sn *snapshotter) {
	t.Helper()
	ticket := sn.recordTerminalMutation(nil)
	if outcome := awaitTerminalOutcome(t, sn, ticket); outcome.err != nil {
		t.Fatalf("persist baseline generation: %v", outcome.err)
	}
}

func TestLeavePersistenceFailureKeepsMembershipAuthoritative(t *testing.T) {
	injectedErr := errors.New("leave commit failed")
	h := newRelayHarness(t)
	host, guest, _, guestToken := createModernRoomWithGuest(
		t,
		h,
		"LEAVE_AUTHORITATIVE",
		"6.3.0.1",
		"6.3.0.2",
	)
	h.srv.mu.RLock()
	room := h.srv.rooms["LEAVE_AUTHORITATIVE"]
	room.mu.RLock()
	expectedClient := room.Peers["G"]
	expectedReservation := room.peerReservations["G"]
	room.mu.RUnlock()
	h.srv.mu.RUnlock()
	makeCurrentSnapshotDurable(t, h.srv.snap)
	h.srv.snap.writeMu.Lock()
	originalPersist := h.srv.snap.persist
	var calls atomic.Int64
	h.srv.snap.persist = func(data []byte) error {
		if calls.Add(1) == 1 {
			return injectedErr
		}
		return originalPersist(data)
	}
	h.srv.snap.writeMu.Unlock()

	guest.send(clientMsg{
		Type:            relayTypeLeave,
		ReconnectToken:  guestToken,
		ProtocolVersion: relayProtocolVersion,
	})
	guest.expectError(relayErrorInvalidMessage)
	h.srv.mu.RLock()
	room = h.srv.rooms["LEAVE_AUTHORITATIVE"]
	room.mu.RLock()
	live := room.Peers["G"]
	reservation := room.peerReservations["G"]
	room.mu.RUnlock()
	h.srv.mu.RUnlock()
	if live != expectedClient ||
		reservation.releasePending ||
		!reservation.absentSince.Equal(expectedReservation.absentSince) ||
		!reconnectVerifierMatches(reservation.verifier, expectedReservation.verifier) {
		t.Fatalf("failed leave live client=%p want=%p reservation=%+v want=%+v", live, expectedClient, reservation, expectedReservation)
	}
	guest.send(clientMsg{Type: relayTypeBroadcast, Payload: json.RawMessage(`{"after":"rollback"}`)})
	message := host.expect(relayTypeMessage)
	if message.From != "G" {
		t.Fatalf("post-rollback sender=%q, want G", message.From)
	}
}

func TestSnapshotCaptureBoundaryExcludesLaterLeave(t *testing.T) {
	injectedErr := errors.New("later leave persistence failed")
	root := t.TempDir()
	statePath := filepath.Join(root, "rooms.json")
	h := newRelayHarnessAt(t, filepath.Join(root, "logs"), statePath)
	_, guest, _, guestToken := createModernRoomWithGuest(
		t,
		h,
		"CAPTURE_BOUNDARY",
		"6.3.0.3",
		"6.3.0.4",
	)
	makeCurrentSnapshotDurable(t, h.srv.snap)

	h.srv.mu.RLock()
	room := h.srv.rooms["CAPTURE_BOUNDARY"]
	room.mu.RLock()
	expectedClient := room.Peers["G"]
	room.mu.RUnlock()
	h.srv.mu.RUnlock()

	captureReady := make(chan struct{})
	releaseCapture := make(chan struct{})
	var captureOnce sync.Once
	h.srv.snap.stateMu.Lock()
	h.srv.snap.afterSequenceCapture = func() {
		captureOnce.Do(func() {
			close(captureReady)
			<-releaseCapture
		})
	}
	h.srv.snap.stateMu.Unlock()
	t.Cleanup(func() {
		select {
		case <-releaseCapture:
		default:
			close(releaseCapture)
		}
	})

	leaveReachedLock := make(chan struct{})
	var leaveOnce sync.Once
	h.srv.beforeLeaveRoomLock = func() {
		leaveOnce.Do(func() { close(leaveReachedLock) })
	}

	firstPayload := make(chan []byte, 1)
	var persistCalls atomic.Int64
	h.srv.snap.writeMu.Lock()
	originalPersist := h.srv.snap.persist
	h.srv.snap.persist = func(data []byte) error {
		switch persistCalls.Add(1) {
		case 1:
			firstPayload <- append([]byte(nil), data...)
			return originalPersist(data)
		case 2:
			return injectedErr
		default:
			return originalPersist(data)
		}
	}
	h.srv.snap.writeMu.Unlock()

	coveringTicket := h.srv.snap.recordTerminalMutation(nil)
	select {
	case <-captureReady:
	case <-time.After(2 * time.Second):
		t.Fatal("covering generation did not reach sequence boundary")
	}
	guest.send(clientMsg{
		Type:            relayTypeLeave,
		ReconnectToken:  guestToken,
		ProtocolVersion: relayProtocolVersion,
	})
	select {
	case <-leaveReachedLock:
	case <-time.After(2 * time.Second):
		t.Fatal("later leave did not reach the protected room mutation")
	}
	close(releaseCapture)

	if outcome := awaitTerminalOutcome(t, h.srv.snap, coveringTicket); outcome.err != nil {
		t.Fatalf("covering generation outcome=%+v", outcome)
	}
	guest.expectError(relayErrorInvalidMessage)

	assertReservation := func(label string, data []byte) {
		t.Helper()
		var snapshot stateSnapshot
		if err := json.Unmarshal(data, &snapshot); err != nil {
			t.Fatalf("decode %s snapshot: %v", label, err)
		}
		for _, persistedRoom := range snapshot.Rooms {
			if persistedRoom.SessionID == "CAPTURE_BOUNDARY" {
				if _, ok := persistedRoom.PeerReservations["G"]; !ok {
					t.Fatalf("%s snapshot omitted the later failed leave", label)
				}
				return
			}
		}
		t.Fatalf("%s snapshot omitted the room", label)
	}
	select {
	case data := <-firstPayload:
		assertReservation("covering", data)
	case <-time.After(2 * time.Second):
		t.Fatal("covering persistence payload was not captured")
	}
	diskData, err := os.ReadFile(statePath)
	if err != nil {
		t.Fatalf("read snapshot after failed follow-up: %v", err)
	}
	assertReservation("disk", diskData)

	h.srv.mu.RLock()
	room = h.srv.rooms["CAPTURE_BOUNDARY"]
	room.mu.RLock()
	liveClient := room.Peers["G"]
	reservation := room.peerReservations["G"]
	room.mu.RUnlock()
	h.srv.mu.RUnlock()
	if liveClient != expectedClient || reservation.releasePending {
		t.Fatalf("failed later leave live client=%p want=%p reservation=%+v", liveClient, expectedClient, reservation)
	}
}

func TestLeavePendingReservationRejectsReplacement(t *testing.T) {
	injectedErr := errors.New("first leave persistence failed")
	root := t.TempDir()
	statePath := filepath.Join(root, "rooms.json")
	h := newRelayHarnessAt(t, filepath.Join(root, "logs"), statePath)
	host, guest, _, guestToken := createModernRoomWithGuest(
		t,
		h,
		"PENDING_RELEASE",
		"6.3.1.1",
		"6.3.1.2",
	)
	makeCurrentSnapshotDurable(t, h.srv.snap)
	h.srv.mu.RLock()
	room := h.srv.rooms["PENDING_RELEASE"]
	h.srv.mu.RUnlock()

	firstStarted := make(chan struct{})
	failFirst := make(chan struct{})
	secondPayload := make(chan []byte, 1)
	releaseSecond := make(chan struct{})
	secondCommitted := make(chan struct{})
	var calls atomic.Int64
	h.srv.snap.writeMu.Lock()
	originalPersist := h.srv.snap.persist
	h.srv.snap.persist = func(data []byte) error {
		switch calls.Add(1) {
		case 1:
			close(firstStarted)
			<-failFirst
			return injectedErr
		case 2:
			secondPayload <- append([]byte(nil), data...)
			<-releaseSecond
			err := originalPersist(data)
			close(secondCommitted)
			return err
		default:
			return originalPersist(data)
		}
	}
	h.srv.snap.writeMu.Unlock()
	t.Cleanup(func() {
		select {
		case <-failFirst:
		default:
			close(failFirst)
		}
		select {
		case <-releaseSecond:
		default:
			close(releaseSecond)
		}
	})

	guest.send(clientMsg{
		Type:            relayTypeLeave,
		ReconnectToken:  guestToken,
		ProtocolVersion: relayProtocolVersion,
	})
	select {
	case <-firstStarted:
	case <-time.After(2 * time.Second):
		t.Fatal("pending leave did not reach persistence")
	}
	waitForPendingReservation(t, room, "G")

	matching := h.dial(t, "6.3.1.3")
	matching.send(clientMsg{
		Type:            relayTypeJoin,
		SessionID:       "PENDING_RELEASE",
		PeerID:          "G",
		ReconnectToken:  guestToken,
		ProtocolVersion: relayProtocolVersion,
	})
	matching.expectError(relayErrorPeerIdUnavailable)
	wrongToken, _ := mustReconnectToken(t)
	wrong := h.dial(t, "6.3.1.4")
	wrong.send(clientMsg{
		Type:            relayTypeJoin,
		SessionID:       "PENDING_RELEASE",
		PeerID:          "G",
		ReconnectToken:  wrongToken,
		ProtocolVersion: relayProtocolVersion,
	})
	wrong.expectError(relayErrorPeerIdUnavailable)

	laterToken, _ := mustReconnectToken(t)
	later := h.dial(t, "6.3.1.5")
	later.send(clientMsg{
		Type:            relayTypeJoin,
		SessionID:       "PENDING_RELEASE",
		PeerID:          "LATER",
		ReconnectToken:  laterToken,
		ProtocolVersion: relayProtocolVersion,
	})
	later.expectAuthority(relayTypeJoined, "H")
	host.expect(relayTypePeerJoined)
	if joined := guest.expect(relayTypePeerJoined); joined.PeerID != "LATER" {
		t.Fatalf("pending guest join notification peerId=%q, want LATER", joined.PeerID)
	}

	close(failFirst)
	guest.expectError(relayErrorInvalidMessage)
	var corrected []byte
	select {
	case corrected = <-secondPayload:
	case <-time.After(2 * time.Second):
		t.Fatal("queued generation did not capture after leave rollback")
	}
	var correctedSnapshot stateSnapshot
	if err := json.Unmarshal(corrected, &correctedSnapshot); err != nil {
		t.Fatalf("decode corrected snapshot: %v", err)
	}
	foundRestored := false
	for _, persistedRoom := range correctedSnapshot.Rooms {
		if persistedRoom.SessionID == "PENDING_RELEASE" {
			_, foundRestored = persistedRoom.PeerReservations["G"]
		}
	}
	if !foundRestored {
		t.Fatal("queued generation captured pending omission before rollback")
	}
	close(releaseSecond)
	select {
	case <-secondCommitted:
	case <-time.After(2 * time.Second):
		t.Fatal("corrected follow-up snapshot did not commit")
	}

	h.srv.snap.writeMu.Lock()
	h.srv.snap.persist = originalPersist
	h.srv.snap.writeMu.Unlock()
	guest.send(clientMsg{
		Type:            relayTypeLeave,
		ReconnectToken:  guestToken,
		ProtocolVersion: relayProtocolVersion,
	})
	guest.expect(relayTypeLeft)
	left := host.expect(relayTypePeerLeft)
	if left.PeerID != "G" {
		t.Fatalf("retry peerLeft=%q, want G", left.PeerID)
	}
	if err := h.srv.snap.flushAndStop(2 * time.Second); err != nil {
		t.Fatalf("flush retry result: %v", err)
	}
	restarted := newRelayHarnessAt(t, t.TempDir(), statePath)
	freshToken, _ := mustReconnectToken(t)
	fresh := restarted.dial(t, "6.3.1.6")
	fresh.send(clientMsg{
		Type:            relayTypeJoin,
		SessionID:       "PENDING_RELEASE",
		PeerID:          "G",
		ReconnectToken:  freshToken,
		ProtocolVersion: relayProtocolVersion,
	})
	joined := fresh.expectAuthority(relayTypeJoined, "H")
	if joined.ReconnectToken != freshToken {
		t.Fatal("restart restored the released reservation")
	}
}

func TestLeaveRetryAfterPersistenceFailure(t *testing.T) {
	injectedErr := errors.New("retryable leave failure")
	h := newRelayHarness(t)
	host, guest, _, guestToken := createModernRoomWithGuest(
		t,
		h,
		"LEAVE_RETRY",
		"6.3.2.1",
		"6.3.2.2",
	)
	makeCurrentSnapshotDurable(t, h.srv.snap)
	h.srv.snap.writeMu.Lock()
	originalPersist := h.srv.snap.persist
	var failed atomic.Bool
	h.srv.snap.persist = func(data []byte) error {
		if failed.CompareAndSwap(false, true) {
			return injectedErr
		}
		return originalPersist(data)
	}
	h.srv.snap.writeMu.Unlock()

	leave := clientMsg{
		Type:            relayTypeLeave,
		ReconnectToken:  guestToken,
		ProtocolVersion: relayProtocolVersion,
	}
	guest.send(leave)
	guest.expectError(relayErrorInvalidMessage)
	guest.send(leave)
	guest.expect(relayTypeLeft)
	left := host.expect(relayTypePeerLeft)
	if left.PeerID != "G" {
		t.Fatalf("retry peerLeft=%q, want G", left.PeerID)
	}
}

func TestLeaveFailurePreservesNewerActivity(t *testing.T) {
	injectedErr := errors.New("activity-preserving leave failure")
	h := newRelayHarness(t)
	host, guest, _, guestToken := createModernRoomWithGuest(
		t,
		h,
		"LEAVE_ACTIVITY",
		"6.3.3.1",
		"6.3.3.2",
	)
	otherToken, _ := mustReconnectToken(t)
	other := h.dial(t, "6.3.3.3")
	other.send(clientMsg{
		Type:            relayTypeJoin,
		SessionID:       "LEAVE_ACTIVITY",
		PeerID:          "OTHER",
		ReconnectToken:  otherToken,
		ProtocolVersion: relayProtocolVersion,
	})
	other.expectAuthority(relayTypeJoined, "H")
	host.expect(relayTypePeerJoined)
	if joined := guest.expect(relayTypePeerJoined); joined.PeerID != "OTHER" {
		t.Fatalf("leave guest join notification peerId=%q, want OTHER", joined.PeerID)
	}
	makeCurrentSnapshotDurable(t, h.srv.snap)
	h.srv.mu.RLock()
	room := h.srv.rooms["LEAVE_ACTIVITY"]
	h.srv.mu.RUnlock()

	started := make(chan struct{})
	fail := make(chan struct{})
	var first atomic.Bool
	h.srv.snap.writeMu.Lock()
	originalPersist := h.srv.snap.persist
	h.srv.snap.persist = func(data []byte) error {
		if first.CompareAndSwap(false, true) {
			close(started)
			<-fail
			return injectedErr
		}
		return originalPersist(data)
	}
	h.srv.snap.writeMu.Unlock()
	t.Cleanup(func() {
		select {
		case <-fail:
		default:
			close(fail)
		}
	})

	guest.send(clientMsg{
		Type:            relayTypeLeave,
		ReconnectToken:  guestToken,
		ProtocolVersion: relayProtocolVersion,
	})
	select {
	case <-started:
	case <-time.After(2 * time.Second):
		t.Fatal("leave did not reach blocked persistence")
	}
	time.Sleep(time.Millisecond)
	host.send(clientMsg{
		Type:    relayTypeSendTo,
		To:      "OTHER",
		Payload: json.RawMessage(`{"during":"leave"}`),
	})
	other.expect(relayTypeMessage)
	room.mu.RLock()
	newerActivity := room.LastActivityAt
	room.mu.RUnlock()
	close(fail)
	guest.expectError(relayErrorInvalidMessage)
	room.mu.RLock()
	afterFailure := room.LastActivityAt
	room.mu.RUnlock()
	if !afterFailure.Equal(newerActivity) {
		t.Fatalf("leave rollback activity=%v, want concurrent activity %v", afterFailure, newerActivity)
	}
}

func TestLeaveEndSessionRaceDoesNotResurrectRoom(t *testing.T) {
	injectedErr := errors.New("leave attempt failed before room end")
	root := t.TempDir()
	statePath := filepath.Join(root, "rooms.json")
	h := newRelayHarnessAt(t, filepath.Join(root, "logs"), statePath)
	host, guest, hostToken, guestToken := createModernRoomWithGuest(
		t,
		h,
		"LEAVE_END_RACE",
		"6.3.4.1",
		"6.3.4.2",
	)
	makeCurrentSnapshotDurable(t, h.srv.snap)
	started := make(chan struct{})
	fail := make(chan struct{})
	var first atomic.Bool
	h.srv.snap.writeMu.Lock()
	originalPersist := h.srv.snap.persist
	h.srv.snap.persist = func(data []byte) error {
		if first.CompareAndSwap(false, true) {
			close(started)
			<-fail
			return injectedErr
		}
		return originalPersist(data)
	}
	h.srv.snap.writeMu.Unlock()
	t.Cleanup(func() {
		select {
		case <-fail:
		default:
			close(fail)
		}
	})

	guest.send(clientMsg{
		Type:            relayTypeLeave,
		ReconnectToken:  guestToken,
		ProtocolVersion: relayProtocolVersion,
	})
	select {
	case <-started:
	case <-time.After(2 * time.Second):
		t.Fatal("leave did not reach blocked persistence")
	}
	host.send(clientMsg{
		Type:            relayTypeEndSession,
		ReconnectToken:  hostToken,
		ProtocolVersion: relayProtocolVersion,
	})
	deadline := time.Now().Add(2 * time.Second)
	for {
		h.srv.mu.RLock()
		_, discoverable := h.srv.rooms["LEAVE_END_RACE"]
		h.srv.mu.RUnlock()
		if !discoverable {
			break
		}
		if time.Now().After(deadline) {
			t.Fatal("endSession did not win room authority")
		}
		time.Sleep(time.Millisecond)
	}
	close(fail)
	host.expect(relayTypeEnded)
	messages, err := guest.recvUntilClosed(2 * time.Second)
	if err != nil {
		t.Fatalf("guest remained connected after endSession won: %v (frames=%v)", err, messages)
	}
	if len(messages) != 1 || messages[0].Type != relayTypeEnded {
		t.Fatalf("leave/end race terminal frames=%+v, want only ended", messages)
	}
	h.srv.mu.RLock()
	_, resurrected := h.srv.rooms["LEAVE_END_RACE"]
	h.srv.mu.RUnlock()
	if resurrected {
		t.Fatal("leave rollback resurrected ended room")
	}
	restarted := newRelayHarnessAt(t, t.TempDir(), statePath)
	probe := restarted.dial(t, "6.3.4.3")
	probe.send(clientMsg{
		Type:            relayTypeJoin,
		SessionID:       "LEAVE_END_RACE",
		PeerID:          "H",
		ReconnectToken:  hostToken,
		ProtocolVersion: relayProtocolVersion,
	})
	probe.expectError(relayErrorRoomNotFound)
}

func TestConcurrentTerminalMutationsShareCommittedSnapshot(t *testing.T) {
	h := newRelayHarness(t)
	hostOne, guestOne, _, guestOneToken := createModernRoomWithGuest(
		t,
		h,
		"TERMINAL_ONE",
		"6.3.5.1",
		"6.3.5.2",
	)
	hostTwo, guestTwo, hostTwoToken, _ := createModernRoomWithGuest(
		t,
		h,
		"TERMINAL_TWO",
		"6.3.5.3",
		"6.3.5.4",
	)
	makeCurrentSnapshotDurable(t, h.srv.snap)

	captureReady := make(chan struct{})
	releaseCapture := make(chan struct{})
	var captureOnce sync.Once
	h.srv.snap.stateMu.Lock()
	h.srv.snap.beforeCapture = func() {
		captureOnce.Do(func() { close(captureReady) })
		<-releaseCapture
	}
	h.srv.snap.stateMu.Unlock()
	persistedPayloads := make(chan []byte, 2)
	var persistCalls atomic.Int64
	h.srv.snap.writeMu.Lock()
	originalPersist := h.srv.snap.persist
	h.srv.snap.persist = func(data []byte) error {
		persistCalls.Add(1)
		persistedPayloads <- append([]byte(nil), data...)
		return originalPersist(data)
	}
	h.srv.snap.writeMu.Unlock()
	t.Cleanup(func() {
		select {
		case <-releaseCapture:
		default:
			close(releaseCapture)
		}
	})

	guestOne.send(clientMsg{
		Type:            relayTypeLeave,
		ReconnectToken:  guestOneToken,
		ProtocolVersion: relayProtocolVersion,
	})
	select {
	case <-captureReady:
	case <-time.After(2 * time.Second):
		t.Fatal("first terminal mutation did not reach capture barrier")
	}
	hostTwo.send(clientMsg{
		Type:            relayTypeEndSession,
		ReconnectToken:  hostTwoToken,
		ProtocolVersion: relayProtocolVersion,
	})
	deadline := time.Now().Add(2 * time.Second)
	for {
		h.srv.mu.RLock()
		_, secondDiscoverable := h.srv.rooms["TERMINAL_TWO"]
		h.srv.mu.RUnlock()
		if !secondDiscoverable {
			break
		}
		if time.Now().After(deadline) {
			t.Fatal("second terminal mutation did not stage before capture")
		}
		time.Sleep(time.Millisecond)
	}
	close(releaseCapture)

	guestOne.expect(relayTypeLeft)
	if left := hostOne.expect(relayTypePeerLeft); left.PeerID != "G" {
		t.Fatalf("coalesced leave peerId=%q, want G", left.PeerID)
	}
	hostTwo.expect(relayTypeEnded)
	messages, err := guestTwo.recvUntilClosed(2 * time.Second)
	if err != nil {
		t.Fatalf("coalesced end did not close guest: %v (frames=%v)", err, messages)
	}
	if len(messages) != 1 || messages[0].Type != relayTypeEnded {
		t.Fatalf("coalesced end frames=%+v", messages)
	}
	if got := persistCalls.Load(); got != 1 {
		t.Fatalf("coalesced terminal persist calls=%d, want 1", got)
	}
	var persisted stateSnapshot
	select {
	case data := <-persistedPayloads:
		if err := json.Unmarshal(data, &persisted); err != nil {
			t.Fatalf("decode coalesced terminal snapshot: %v", err)
		}
	default:
		t.Fatal("coalesced terminal persistence did not expose its payload")
	}
	foundFirst := false
	for _, persistedRoom := range persisted.Rooms {
		switch persistedRoom.SessionID {
		case "TERMINAL_ONE":
			foundFirst = true
			if _, retained := persistedRoom.PeerReservations["G"]; retained {
				t.Fatal("coalesced leave snapshot retained released reservation")
			}
		case "TERMINAL_TWO":
			t.Fatal("coalesced end snapshot retained ended room")
		}
	}
	if !foundFirst {
		t.Fatal("coalesced snapshot omitted surviving first room")
	}
}

func TestRelayTrafficDoesNotScheduleSnapshots(t *testing.T) {
	h := newRelayHarness(t)
	host, guest, _, _ := createModernRoomWithGuest(
		t,
		h,
		"TRAFFIC_NO_CHURN",
		"6.3.6.1",
		"6.3.6.2",
	)
	makeCurrentSnapshotDurable(t, h.srv.snap)
	var persistCalls atomic.Int64
	h.srv.snap.writeMu.Lock()
	originalPersist := h.srv.snap.persist
	h.srv.snap.persist = func(data []byte) error {
		persistCalls.Add(1)
		return originalPersist(data)
	}
	h.srv.snap.writeMu.Unlock()

	for index := range 20 {
		host.send(clientMsg{
			Type:    relayTypeBroadcast,
			Payload: json.RawMessage(fmt.Sprintf(`{"index":%d}`, index)),
		})
		message := guest.expect(relayTypeMessage)
		if message.From != "H" {
			t.Fatalf("traffic sender=%q, want H", message.From)
		}
	}
	time.Sleep(5 * snapshotDebounce)
	if got := persistCalls.Load(); got != 0 {
		t.Fatalf("high-frequency relay traffic scheduled %d snapshot writes", got)
	}
}

func TestLeaveDirectorySyncFailureCommitsRelease(t *testing.T) {
	root := t.TempDir()
	statePath := filepath.Join(root, "rooms.json")
	h := newRelayHarnessAt(t, filepath.Join(root, "logs"), statePath)
	host, guest, _, guestToken := createModernRoomWithGuest(
		t,
		h,
		"DIRSYNC_LEAVE",
		"6.3.7.1",
		"6.3.7.2",
	)
	makeCurrentSnapshotDurable(t, h.srv.snap)
	h.srv.snap.syncDir = func(string) error {
		return errors.New("directory sync unsupported")
	}
	guest.send(clientMsg{
		Type:            relayTypeLeave,
		ReconnectToken:  guestToken,
		ProtocolVersion: relayProtocolVersion,
	})
	guest.expect(relayTypeLeft)
	if left := host.expect(relayTypePeerLeft); left.PeerID != "G" {
		t.Fatalf("directory-sync degraded leave peerId=%q, want G", left.PeerID)
	}
	if err := h.srv.snap.flushAndStop(2 * time.Second); err != nil {
		t.Fatalf("post-rename directory-sync warning failed committed leave: %v", err)
	}
	restarted := newRelayHarnessAt(t, t.TempDir(), statePath)
	freshToken, _ := mustReconnectToken(t)
	fresh := restarted.dial(t, "6.3.7.3")
	fresh.send(clientMsg{
		Type:            relayTypeJoin,
		SessionID:       "DIRSYNC_LEAVE",
		PeerID:          "G",
		ReconnectToken:  freshToken,
		ProtocolVersion: relayProtocolVersion,
	})
	joined := fresh.expectAuthority(relayTypeJoined, "H")
	if joined.ReconnectToken != freshToken {
		t.Fatal("restart restored a release committed before directory-sync warning")
	}
}

func TestAuthenticatedModernGuestLeaveReleasesIdentity(t *testing.T) {
	h := newRelayHarness(t)
	hostToken, _ := mustReconnectToken(t)
	host := h.dial(t, "6.1.0.20")
	host.send(clientMsg{
		Type:            relayTypeCreate,
		SessionID:       "GUEST_LEAVE",
		PeerID:          "H",
		ReconnectToken:  hostToken,
		ProtocolVersion: relayProtocolVersion,
	})
	host.expectAuthority(relayTypeCreated, "H")

	guestToken, _ := mustReconnectToken(t)
	guest := h.dial(t, "6.1.0.21")
	guest.send(clientMsg{
		Type:            relayTypeJoin,
		SessionID:       "GUEST_LEAVE",
		PeerID:          "G",
		ReconnectToken:  guestToken,
		ProtocolVersion: relayProtocolVersion,
	})
	guest.expectAuthority(relayTypeJoined, "H")
	host.expect(relayTypePeerJoined)

	wrongToken, _ := mustReconnectToken(t)
	guest.send(clientMsg{
		Type:            relayTypeLeave,
		ReconnectToken:  wrongToken,
		ProtocolVersion: relayProtocolVersion,
	})
	guest.expectError(relayErrorPeerIdUnavailable)
	guest.send(clientMsg{Type: relayTypeBroadcast, Payload: json.RawMessage(`{"still":"joined"}`)})
	stillJoined := host.expect(relayTypeMessage)
	if stillJoined.From != "G" {
		t.Fatalf("message after rejected leave came from %q, want G", stillJoined.From)
	}

	guest.send(clientMsg{
		Type:            relayTypeLeave,
		ReconnectToken:  guestToken,
		ProtocolVersion: relayProtocolVersion,
	})
	leftAck := guest.expect(relayTypeLeft)
	if leftAck.SessionID != "GUEST_LEAVE" || leftAck.PeerID != "G" || leftAck.ProtocolVersion != relayProtocolVersion {
		t.Fatalf("left acknowledgement=%+v", leftAck)
	}
	leftEvent := host.expect(relayTypePeerLeft)
	if leftEvent.PeerID != "G" {
		t.Fatalf("released peer event peerId=%q, want G", leftEvent.PeerID)
	}

	replacementToken, _ := mustReconnectToken(t)
	replacement := h.dial(t, "6.1.0.22")
	replacement.send(clientMsg{
		Type:            relayTypeJoin,
		SessionID:       "GUEST_LEAVE",
		PeerID:          "G",
		ReconnectToken:  replacementToken,
		ProtocolVersion: relayProtocolVersion,
	})
	joined := replacement.expectAuthority(relayTypeJoined, "H")
	if joined.ReconnectToken != replacementToken {
		t.Fatal("released guest identity retained its old verifier")
	}
	rejoined := host.expect(relayTypePeerJoined)
	if rejoined.PeerID != "G" {
		t.Fatalf("replacement event peerId=%q, want G", rejoined.PeerID)
	}
}

func TestAuthenticatedModernHostEndDeletesRoomAndIsRetrySafe(t *testing.T) {
	h := newRelayHarness(t)
	hostToken, _ := mustReconnectToken(t)
	host := h.dial(t, "6.1.0.30")
	host.send(clientMsg{
		Type:            relayTypeCreate,
		SessionID:       "HOST_END",
		PeerID:          "H",
		ReconnectToken:  hostToken,
		ProtocolVersion: relayProtocolVersion,
	})
	host.expectAuthority(relayTypeCreated, "H")

	guestToken, _ := mustReconnectToken(t)
	guest := h.dial(t, "6.1.0.31")
	guest.send(clientMsg{
		Type:            relayTypeJoin,
		SessionID:       "HOST_END",
		PeerID:          "G",
		ReconnectToken:  guestToken,
		ProtocolVersion: relayProtocolVersion,
	})
	guest.expectAuthority(relayTypeJoined, "H")
	host.expect(relayTypePeerJoined)

	wrongToken, _ := mustReconnectToken(t)
	host.send(clientMsg{
		Type:            relayTypeEndSession,
		ReconnectToken:  wrongToken,
		ProtocolVersion: relayProtocolVersion,
	})
	host.expectError(relayErrorPeerIdUnavailable)
	host.send(clientMsg{Type: relayTypeBroadcast, Payload: json.RawMessage(`{"room":"live"}`)})
	stillLive := guest.expect(relayTypeMessage)
	if stillLive.From != "H" {
		t.Fatalf("message after rejected end came from %q, want H", stillLive.From)
	}

	host.send(clientMsg{
		Type:            relayTypeEndSession,
		ReconnectToken:  hostToken,
		ProtocolVersion: relayProtocolVersion,
	})
	ended := host.expect(relayTypeEnded)
	if ended.SessionID != "HOST_END" || ended.ProtocolVersion != relayProtocolVersion {
		t.Fatalf("ended acknowledgement=%+v", ended)
	}
	messages, err := guest.recvUntilClosed(2 * time.Second)
	if err != nil {
		t.Fatalf("guest remained connected after room end: %v (frames=%v)", err, messages)
	}
	if len(messages) != 1 ||
		messages[0].Type != relayTypeEnded ||
		messages[0].SessionID != "HOST_END" ||
		messages[0].ProtocolVersion != relayProtocolVersion {
		t.Fatalf("guest terminal frames=%+v, want one ended notification", messages)
	}

	host.send(clientMsg{
		Type:            relayTypeEndSession,
		ReconnectToken:  hostToken,
		ProtocolVersion: relayProtocolVersion,
	})
	host.expectError(relayErrorNotInRoom)

	retry := h.dial(t, "6.1.0.32")
	retry.send(clientMsg{
		Type:            relayTypeJoin,
		SessionID:       "HOST_END",
		PeerID:          "H",
		ReconnectToken:  hostToken,
		ProtocolVersion: relayProtocolVersion,
	})
	retry.expectError(relayErrorRoomNotFound)
}

func TestHostEndDeliversEndedAfterConcurrentGuestTraffic(t *testing.T) {
	h := newRelayHarness(t)
	endDeliveryReady := make(chan struct{})
	releaseEndDelivery := make(chan struct{})
	var releaseOnce sync.Once
	h.srv.beforeTerminalDelivery = func() {
		close(endDeliveryReady)
		<-releaseEndDelivery
	}
	t.Cleanup(func() {
		releaseOnce.Do(func() { close(releaseEndDelivery) })
	})

	hostToken, _ := mustReconnectToken(t)
	host := h.dial(t, "6.1.0.33")
	host.send(clientMsg{
		Type:            relayTypeCreate,
		SessionID:       "END_RACE",
		PeerID:          "H",
		ReconnectToken:  hostToken,
		ProtocolVersion: relayProtocolVersion,
	})
	host.expectAuthority(relayTypeCreated, "H")

	guestToken, _ := mustReconnectToken(t)
	guest := h.dial(t, "6.1.0.34")
	guest.send(clientMsg{
		Type:            relayTypeJoin,
		SessionID:       "END_RACE",
		PeerID:          "G",
		ReconnectToken:  guestToken,
		ProtocolVersion: relayProtocolVersion,
	})
	guest.expectAuthority(relayTypeJoined, "H")
	host.expect(relayTypePeerJoined)

	host.send(clientMsg{
		Type:            relayTypeEndSession,
		ReconnectToken:  hostToken,
		ProtocolVersion: relayProtocolVersion,
	})
	select {
	case <-endDeliveryReady:
	case <-time.After(2 * time.Second):
		t.Fatal("host end did not reach the terminal-delivery barrier")
	}

	h.srv.mu.RLock()
	_, discoverable := h.srv.rooms["END_RACE"]
	h.srv.mu.RUnlock()
	if discoverable {
		t.Fatal("ending room remained discoverable before terminal delivery")
	}

	// WebSocket frames are processed in order. Receiving pong proves the
	// preceding membership-sensitive traffic was handled while ended delivery
	// was blocked, without closing the guest as a stale client.
	guest.send(clientMsg{
		Type:    relayTypeBroadcast,
		Payload: json.RawMessage(`{"during":"end"}`),
	})
	guest.send(clientMsg{
		Type:    relayTypeSendTo,
		To:      "H",
		Payload: json.RawMessage(`{"also":"during-end"}`),
	})
	guest.send(clientMsg{Type: relayTypePing})
	guest.expect(relayTypePong)

	releaseOnce.Do(func() { close(releaseEndDelivery) })
	endedAck := host.expect(relayTypeEnded)
	if endedAck.SessionID != "END_RACE" || endedAck.ProtocolVersion != relayProtocolVersion {
		t.Fatalf("host ended acknowledgement=%+v", endedAck)
	}
	messages, err := guest.recvUntilClosed(2 * time.Second)
	if err != nil {
		t.Fatalf("guest remained connected after terminal delivery: %v (frames=%v)", err, messages)
	}
	if len(messages) != 1 ||
		messages[0].Type != relayTypeEnded ||
		messages[0].SessionID != "END_RACE" ||
		messages[0].ProtocolVersion != relayProtocolVersion {
		t.Fatalf("guest terminal frames=%+v, want one ended notification", messages)
	}
}

func TestHostReconnectReplacesStaleConnectionWithoutLeaving(t *testing.T) {
	h := newRelayHarness(t)
	oldHostIP := "6.1.1.1"
	oldHost := h.dial(t, oldHostIP)
	oldHost.send(clientMsg{Type: relayTypeCreate, SessionID: "REJOIN", PeerID: "H"})
	created := oldHost.expectAuthority(relayTypeCreated, "H")

	guest := h.dial(t, "6.1.1.2")
	guest.send(clientMsg{Type: relayTypeJoin, SessionID: "REJOIN", PeerID: "G"})
	guest.expectAuthority(relayTypeJoined, "H")
	oldHost.expect(relayTypePeerJoined)

	newHost := h.dial(t, "6.1.1.3")
	newHost.send(clientMsg{
		Type:           relayTypeJoin,
		SessionID:      "REJOIN",
		PeerID:         "H",
		ReconnectToken: created.ReconnectToken,
	})
	joined := newHost.expectAuthority(relayTypeJoined, "H")
	if len(joined.Peers) != 1 || joined.Peers[0] != "G" {
		t.Fatalf("reconnected host peers=%v, want [G]", joined.Peers)
	}
	guest.expect(relayTypePeerJoined)

	if messages, err := oldHost.recvUntilClosed(2 * time.Second); err != nil {
		t.Fatalf("displaced host did not close: %v (frames=%v)", err, messages)
	}
	h.waitIPConnections(t, oldHostIP, 0)

	newHost.send(clientMsg{Type: relayTypeBroadcast, Payload: json.RawMessage(`{"state":"ready"}`)})
	message := guest.expect(relayTypeMessage)
	if message.From != "H" {
		t.Fatalf("message sender=%q, want H", message.From)
	}
}

func TestEmptyRoomRequiresHostProofUntilExpiryThenSupportsFallbackCreate(t *testing.T) {
	h := newRelayHarness(t)
	host := h.dial(t, "6.1.2.1")
	host.send(clientMsg{Type: relayTypeCreate, SessionID: "EMPTY", PeerID: "H"})
	created := host.expectAuthority(relayTypeCreated, "H")
	host.conn.Close()
	h.waitRoomPeers(t, "EMPTY", 0)

	unproved := h.dial(t, "6.1.2.20")
	unproved.send(clientMsg{Type: relayTypeJoin, SessionID: "EMPTY", PeerID: "H"})
	unproved.expectError(relayErrorPeerIdUnavailable)

	reconnected := h.dial(t, "6.1.2.2")
	reconnected.send(clientMsg{
		Type:           relayTypeJoin,
		SessionID:      "EMPTY",
		PeerID:         "H",
		ReconnectToken: created.ReconnectToken,
	})
	joined := reconnected.expectAuthority(relayTypeJoined, "H")
	if joined.ReconnectToken != created.ReconnectToken {
		t.Fatal("host reconnect rotated its capability")
	}
	if len(joined.Peers) != 0 {
		t.Fatalf("empty-room reconnect peers=%v, want none", joined.Peers)
	}
	reconnected.conn.Close()
	h.waitRoomPeers(t, "EMPTY", 0)

	now := time.Now()
	h.srv.mu.RLock()
	room := h.srv.rooms["EMPTY"]
	h.srv.mu.RUnlock()
	room.mu.Lock()
	room.LastActivityAt = now.Add(-emptyRoomMaxAge - time.Second)
	room.mu.Unlock()
	h.srv.runCleanupStep(now)

	fallback := h.dial(t, "6.1.2.3")
	fallback.send(clientMsg{
		Type:           relayTypeJoin,
		SessionID:      "EMPTY",
		PeerID:         "H",
		ReconnectToken: created.ReconnectToken,
	})
	fallback.expectError(relayErrorRoomNotFound)
	fallback.send(clientMsg{
		Type:           relayTypeCreate,
		SessionID:      "EMPTY",
		PeerID:         "H",
		ReconnectToken: created.ReconnectToken,
	})
	recreated := fallback.expectAuthority(relayTypeCreated, "H")
	if recreated.ReconnectToken != created.ReconnectToken {
		t.Fatal("fallback create rotated its retained capability")
	}
}

func TestCleanupDisconnectsPeersBeforeRemovingExpiredOccupiedRoom(t *testing.T) {
	h := newRelayHarness(t)
	host := h.dial(t, "6.2.0.1")
	host.send(clientMsg{Type: "create", SessionID: "EXPIRED", PeerID: "H"})
	host.expect("created")

	guest := h.dial(t, "6.2.0.2")
	guest.send(clientMsg{Type: "join", SessionID: "EXPIRED", PeerID: "G"})
	guest.expect("joined")
	host.expect("peerJoined")

	now := time.Now()
	h.srv.mu.RLock()
	room := h.srv.rooms["EXPIRED"]
	h.srv.mu.RUnlock()
	room.mu.Lock()
	room.CreatedAt = now.Add(-roomMaxAge - time.Second)
	room.mu.Unlock()

	h.srv.runCleanupStep(now)

	h.srv.mu.RLock()
	_, exists := h.srv.rooms["EXPIRED"]
	h.srv.mu.RUnlock()
	if exists {
		t.Fatal("expired room still exists after cleanup")
	}

	room.mu.RLock()
	closing := room.closing
	remainingPeers := len(room.Peers)
	room.mu.RUnlock()
	if !closing {
		t.Error("expired room was not marked closing")
	}
	if remainingPeers != 0 {
		t.Errorf("expired room retained %d peers after cleanup", remainingPeers)
	}

	for name, connection := range map[string]*testConn{"host": host, "guest": guest} {
		messages, err := connection.recvUntilClosed(2 * time.Second)
		if err != nil {
			t.Errorf("%s did not reach terminal closure: %v", name, err)
		}
		for _, message := range messages {
			if message.Type == relayTypePeerLeft || message.Type == relayTypePeerJoined {
				t.Errorf("%s received %s during expired-room teardown", name, message.Type)
			}
		}
	}
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

func getLog(t *testing.T, baseURL, ip, id string) *http.Response {
	t.Helper()
	req, err := http.NewRequest(http.MethodGet, baseURL+"/logs/"+id, nil)
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	if ip != "" {
		req.Header.Set("X-Forwarded-For", ip)
	}
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatalf("get: %v", err)
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

type posterUploadResponse struct {
	ID        string `json:"id"`
	URL       string `json:"url"`
	ExpiresIn int    `json:"expiresIn"`
}

func postPoster(t *testing.T, baseURL, ip string, body []byte) *http.Response {
	t.Helper()
	req, err := http.NewRequest(http.MethodPost, baseURL+"/posters", bytes.NewReader(body))
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

func postPosterAndDecode(t *testing.T, baseURL, ip string, body []byte) posterUploadResponse {
	t.Helper()
	resp := postPoster(t, baseURL, ip, body)
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("post status=%d", resp.StatusCode)
	}
	var out posterUploadResponse
	if err := json.NewDecoder(resp.Body).Decode(&out); err != nil {
		t.Fatalf("decode: %v", err)
	}
	if len(out.ID) != posterIDLength {
		t.Fatalf("id=%q len=%d want %d", out.ID, len(out.ID), posterIDLength)
	}
	if out.URL == "" {
		t.Fatal("empty poster url")
	}
	return out
}

type blockingLogResponseWriter struct {
	header       http.Header
	writeStarted chan struct{}
	releaseWrite chan struct{}
	writeErr     error
	startOnce    sync.Once
	mu           sync.Mutex
	deadlines    []time.Time
}

func newBlockingLogResponseWriter(writeErr error) *blockingLogResponseWriter {
	return &blockingLogResponseWriter{
		header:       make(http.Header),
		writeStarted: make(chan struct{}),
		releaseWrite: make(chan struct{}),
		writeErr:     writeErr,
	}
}

func (w *blockingLogResponseWriter) Header() http.Header {
	return w.header
}

func (w *blockingLogResponseWriter) WriteHeader(int) {}

func (w *blockingLogResponseWriter) Write(p []byte) (int, error) {
	w.startOnce.Do(func() { close(w.writeStarted) })
	<-w.releaseWrite
	if w.writeErr != nil {
		return 0, w.writeErr
	}
	return len(p), nil
}

func (w *blockingLogResponseWriter) SetWriteDeadline(deadline time.Time) error {
	w.mu.Lock()
	w.deadlines = append(w.deadlines, deadline)
	w.mu.Unlock()
	return nil
}

func TestLogResponseTransmissionReleasesLookupSlotAndUsesDeadline(t *testing.T) {
	logs := newLogStore(t.TempDir())
	id, _, err := logs.store([]byte("diagnostic"), time.Now())
	if err != nil {
		t.Fatalf("store log: %v", err)
	}
	srv := &Server{
		logs:       logs,
		logLookups: make(chan struct{}, 1),
		clientIPs:  newClientIPResolver(nil),
	}
	writer := newBlockingLogResponseWriter(errors.New("synthetic write failure: " + id))
	request := httptest.NewRequest(http.MethodGet, "/logs/"+id, nil)

	var output bytes.Buffer
	previousOutput := log.Writer()
	previousFlags := log.Flags()
	previousPrefix := log.Prefix()
	log.SetOutput(&output)
	log.SetFlags(0)
	log.SetPrefix("")
	t.Cleanup(func() {
		log.SetOutput(previousOutput)
		log.SetFlags(previousFlags)
		log.SetPrefix(previousPrefix)
	})

	done := make(chan struct{})
	go func() {
		srv.handleGetLogs(writer, request)
		close(done)
	}()
	select {
	case <-writer.writeStarted:
	case <-time.After(time.Second):
		t.Fatal("log response did not reach blocked write")
	}

	if occupied := len(srv.logLookups); occupied != 0 {
		t.Fatalf("blocked response retained %d lookup slots", occupied)
	}
	second := httptest.NewRecorder()
	srv.handleGetLogs(second, httptest.NewRequest(http.MethodGet, "/logs/"+id, nil))
	if second.Code != http.StatusOK {
		t.Fatalf("lookup while first response blocked status=%d, want 200", second.Code)
	}

	writer.mu.Lock()
	deadlines := append([]time.Time(nil), writer.deadlines...)
	writer.mu.Unlock()
	if len(deadlines) == 0 || deadlines[0].IsZero() {
		t.Fatalf("response write deadline not applied: %v", deadlines)
	}
	remaining := time.Until(deadlines[0])
	if remaining <= 0 || remaining > httpResponseWriteTimeout {
		t.Fatalf("response write deadline remaining=%v, want within (0, %v]", remaining, httpResponseWriteTimeout)
	}

	close(writer.releaseWrite)
	select {
	case <-done:
	case <-time.After(time.Second):
		t.Fatal("log handler did not finish after writer release")
	}
	writer.mu.Lock()
	deadlines = append(deadlines[:0], writer.deadlines...)
	writer.mu.Unlock()
	if len(deadlines) != 1 || deadlines[0].IsZero() {
		t.Fatalf("handler changed response deadline after writing: %v", deadlines)
	}
	if !strings.Contains(output.String(), "logs: response write failed") {
		t.Fatalf("write failure was not observed: %q", output.String())
	}
	if strings.Contains(output.String(), id) {
		t.Fatalf("write failure leaked log capability %q", id)
	}
}

type logDeadlineObservation struct {
	sequence uint64
	deadline time.Time
}

type logResponseWriteObservation struct {
	handlerReturned  bool
	deadline         time.Time
	deadlineSequence uint64
}

type logDeadlineConn struct {
	net.Conn
	handlerReturned  <-chan struct{}
	writeStarted     chan logResponseWriteObservation
	releaseWrite     <-chan struct{}
	blockFirstWrite  sync.Once
	mu               sync.Mutex
	deadline         time.Time
	deadlineSequence uint64
	deadlineChanged  chan logDeadlineObservation
}

func (c *logDeadlineConn) SetWriteDeadline(deadline time.Time) error {
	if err := c.Conn.SetWriteDeadline(deadline); err != nil {
		return err
	}
	c.mu.Lock()
	c.deadline = deadline
	c.deadlineSequence++
	observation := logDeadlineObservation{
		sequence: c.deadlineSequence,
		deadline: deadline,
	}
	c.mu.Unlock()
	c.deadlineChanged <- observation
	return nil
}

func (c *logDeadlineConn) Write(p []byte) (int, error) {
	c.blockFirstWrite.Do(func() {
		c.mu.Lock()
		observation := logResponseWriteObservation{
			deadline:         c.deadline,
			deadlineSequence: c.deadlineSequence,
		}
		c.mu.Unlock()
		select {
		case <-c.handlerReturned:
			observation.handlerReturned = true
		default:
		}
		c.writeStarted <- observation
		<-c.releaseWrite
	})
	return c.Conn.Write(p)
}

type logDeadlineListener struct {
	net.Listener
	handlerReturned <-chan struct{}
	accepted        chan *logDeadlineConn
	releaseWrite    <-chan struct{}
}

func (l *logDeadlineListener) Accept() (net.Conn, error) {
	conn, err := l.Listener.Accept()
	if err != nil {
		return nil, err
	}
	wrapped := &logDeadlineConn{
		Conn:            conn,
		handlerReturned: l.handlerReturned,
		writeStarted:    make(chan logResponseWriteObservation, 1),
		releaseWrite:    l.releaseWrite,
		deadlineChanged: make(chan logDeadlineObservation, 16),
	}
	l.accepted <- wrapped
	return wrapped, nil
}

func assertLogResponseDeadlineLifecycle(
	t *testing.T,
	present bool,
	wantStatus int,
	wantBody string,
) {
	t.Helper()
	logs := newLogStore(t.TempDir())
	id := strings.Repeat("a", logIDLength)
	if present {
		var err error
		id, _, err = logs.store([]byte(wantBody), time.Now())
		if err != nil {
			t.Fatalf("store log: %v", err)
		}
	}
	srv := &Server{
		logs:       logs,
		logLookups: make(chan struct{}, 1),
		clientIPs:  newClientIPResolver(nil),
	}

	handlerReturned := make(chan struct{})
	mux := http.NewServeMux()
	mux.HandleFunc("/logs/", func(w http.ResponseWriter, r *http.Request) {
		srv.handleGetLogs(w, r)
		close(handlerReturned)
	})
	mux.HandleFunc("/health", func(w http.ResponseWriter, _ *http.Request) {
		_, _ = io.WriteString(w, "ok")
	})

	baseListener, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatalf("listen: %v", err)
	}
	releaseFirstWrite := make(chan struct{})
	listener := &logDeadlineListener{
		Listener:        baseListener,
		handlerReturned: handlerReturned,
		accepted:        make(chan *logDeadlineConn, 1),
		releaseWrite:    releaseFirstWrite,
	}
	httpServer := newHTTPServer(listener.Addr().String(), mux)
	serveDone := make(chan error, 1)
	go func() {
		serveDone <- httpServer.Serve(listener)
	}()

	var releaseWrite sync.Once
	release := func() {
		releaseWrite.Do(func() { close(releaseFirstWrite) })
	}
	t.Cleanup(func() {
		release()
		_ = httpServer.Close()
		_ = listener.Close()
		<-serveDone
	})

	clientConn, err := net.Dial("tcp", listener.Addr().String())
	if err != nil {
		t.Fatalf("dial: %v", err)
	}
	defer clientConn.Close()

	var trackedConn *logDeadlineConn
	select {
	case trackedConn = <-listener.accepted:
	case <-time.After(time.Second):
		t.Fatal("server did not accept HTTP connection")
	}

	request, err := http.NewRequest(
		http.MethodGet,
		"http://"+listener.Addr().String()+"/logs/"+id,
		nil,
	)
	if err != nil {
		t.Fatalf("new log request: %v", err)
	}
	if err := request.Write(clientConn); err != nil {
		t.Fatalf("write log request: %v", err)
	}

	var writeObservation logResponseWriteObservation
	select {
	case writeObservation = <-trackedConn.writeStarted:
	case <-time.After(time.Second):
		t.Fatal("response did not reach blocked final flush")
	}
	if !writeObservation.handlerReturned {
		t.Fatal("response reached network before log handler returned")
	}
	if writeObservation.deadline.IsZero() {
		t.Fatal("final response flush had no write deadline")
	}
	remaining := time.Until(writeObservation.deadline)
	if remaining <= 0 || remaining > httpResponseWriteTimeout {
		t.Fatalf(
			"final flush deadline remaining=%v, want within (0, %v]",
			remaining,
			httpResponseWriteTimeout,
		)
	}
	release()

	reader := bufio.NewReader(clientConn)
	response, err := http.ReadResponse(reader, request)
	if err != nil {
		t.Fatalf("read log response: %v", err)
	}
	body, err := io.ReadAll(response.Body)
	response.Body.Close()
	if err != nil {
		t.Fatalf("read log response body: %v", err)
	}
	if response.StatusCode != wantStatus || string(body) != wantBody {
		t.Fatalf(
			"log response=(status=%d, body=%q), want (%d, %q)",
			response.StatusCode,
			body,
			wantStatus,
			wantBody,
		)
	}

	cleared := false
	timer := time.NewTimer(time.Second)
	defer timer.Stop()
	for !cleared {
		select {
		case observation := <-trackedConn.deadlineChanged:
			cleared = observation.sequence > writeObservation.deadlineSequence &&
				observation.deadline.IsZero()
		case <-timer.C:
			t.Fatal("net/http did not clear the response write deadline after final flush")
		}
	}

	healthRequest, err := http.NewRequest(
		http.MethodGet,
		"http://"+listener.Addr().String()+"/health",
		nil,
	)
	if err != nil {
		t.Fatalf("new keep-alive request: %v", err)
	}
	if err := healthRequest.Write(clientConn); err != nil {
		t.Fatalf("write keep-alive request: %v", err)
	}
	healthResponse, err := http.ReadResponse(reader, healthRequest)
	if err != nil {
		t.Fatalf("read keep-alive response: %v", err)
	}
	healthBody, err := io.ReadAll(healthResponse.Body)
	healthResponse.Body.Close()
	if err != nil {
		t.Fatalf("read keep-alive response body: %v", err)
	}
	if healthResponse.StatusCode != http.StatusOK || string(healthBody) != "ok" {
		t.Fatalf(
			"keep-alive response=(status=%d, body=%q), want (200, %q)",
			healthResponse.StatusCode,
			healthBody,
			"ok",
		)
	}
}

func TestLogResponseDeadlineSurvivesFinalFlush(t *testing.T) {
	assertLogResponseDeadlineLifecycle(t, true, http.StatusOK, "diagnostic")
}

func TestLogResponseDeadlineCoversBufferedErrorResponse(t *testing.T) {
	assertLogResponseDeadlineLifecycle(t, false, http.StatusNotFound, "Not found\n")
}

func TestHTTPServerWriteTimeoutCoversOAuthResultLongPoll(t *testing.T) {
	server := newHTTPServer("127.0.0.1:0", http.NewServeMux())
	if server.WriteTimeout != httpResponseWriteTimeout || server.WriteTimeout <= 0 {
		t.Fatalf("WriteTimeout=%v, want bounded timeout %v", server.WriteTimeout, httpResponseWriteTimeout)
	}
	if server.WriteTimeout <= oauthResultWait {
		t.Fatalf("WriteTimeout=%v must exceed oauthResultWait=%v", server.WriteTimeout, oauthResultWait)
	}
	if margin := server.WriteTimeout - oauthResultWait; margin < httpResponseWriteMargin {
		t.Fatalf("WriteTimeout margin=%v, want at least %v", margin, httpResponseWriteMargin)
	}
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

func TestLogsUploadDoesNotWriteCapabilityToOperationalLog(t *testing.T) {
	h := newRelayHarness(t)
	var output bytes.Buffer
	previousOutput := log.Writer()
	previousFlags := log.Flags()
	previousPrefix := log.Prefix()
	log.SetOutput(&output)
	log.SetFlags(0)
	log.SetPrefix("")
	t.Cleanup(func() {
		log.SetOutput(previousOutput)
		log.SetFlags(previousFlags)
		log.SetPrefix(previousPrefix)
	})

	id := postLogAndGetID(t, h.baseURL, "203.0.113.40", []byte("safe diagnostic"))
	if strings.Contains(output.String(), id) {
		t.Fatalf("operational log retained bearer capability %q", id)
	}
	if !strings.Contains(output.String(), "logs: stored 15 bytes from 203.0.113.40") {
		t.Fatalf("successful upload was not observable: %q", output.String())
	}
}

func TestLogStoreRetiresLegacyCapabilitiesOnStartup(t *testing.T) {
	dir := t.TempDir()
	now := time.Now().Add(-time.Minute)
	legacyID := "abcde"
	currentID := strings.Repeat("a", logIDLength)
	legacyPath := filepath.Join(dir, legacyID+".log")
	currentPath := filepath.Join(dir, currentID+".log")
	for path, body := range map[string]string{legacyPath: "legacy", currentPath: "current"} {
		if err := os.WriteFile(path, []byte(body), 0o644); err != nil {
			t.Fatalf("seed %s: %v", path, err)
		}
		if err := os.Chtimes(path, now, now); err != nil {
			t.Fatalf("chtimes %s: %v", path, err)
		}
	}

	store := newLogStore(dir)
	if _, err := os.Stat(legacyPath); !errors.Is(err, os.ErrNotExist) {
		t.Fatalf("legacy capability file still exists: %v", err)
	}
	if _, ok, err := store.lookup(legacyID, time.Now()); err != nil || ok {
		t.Fatalf("legacy capability lookup=(ok=%v, err=%v), want absent", ok, err)
	}
	if _, ok, err := store.lookup(currentID, time.Now()); err != nil || !ok {
		t.Fatalf("current capability lookup=(ok=%v, err=%v), want indexed", ok, err)
	}

	restarted := newLogStore(dir)
	if _, ok, err := restarted.lookup(currentID, time.Now()); err != nil || !ok {
		t.Fatalf("restarted capability lookup=(ok=%v, err=%v), want indexed", ok, err)
	}
}

func TestLogsFailedLookupsAreBoundedButValidCapabilitiesRemainAvailable(t *testing.T) {
	h := newRelayHarness(t)
	payload := []byte("retrievable")
	validID := postLogAndGetID(t, h.baseURL, "203.0.113.1", payload)
	source := "203.0.113.50"

	for i := range logLookupRateBurst {
		unknownID := strings.Repeat("z", logIDLength-2) + fmt.Sprintf("%02d", i)
		resp := getLog(t, h.baseURL, source, unknownID)
		resp.Body.Close()
		if resp.StatusCode != http.StatusNotFound {
			t.Fatalf("failed lookup %d status=%d, want 404", i, resp.StatusCode)
		}
		if got := resp.Header.Get("Cache-Control"); got != "private, no-store" {
			t.Fatalf("failed lookup Cache-Control=%q", got)
		}
	}
	throttled := getLog(t, h.baseURL, source, strings.Repeat("y", logIDLength))
	throttled.Body.Close()
	if throttled.StatusCode != http.StatusTooManyRequests {
		t.Fatalf("exhausted lookup status=%d, want 429", throttled.StatusCode)
	}
	if got := throttled.Header.Get("Cache-Control"); got != "private, no-store" {
		t.Fatalf("throttled Cache-Control=%q", got)
	}

	success := getLog(t, h.baseURL, source, validID)
	defer success.Body.Close()
	if success.StatusCode != http.StatusOK {
		t.Fatalf("valid capability after exhausted failures status=%d", success.StatusCode)
	}
	got, err := io.ReadAll(success.Body)
	if err != nil || !bytes.Equal(got, payload) {
		t.Fatalf("valid body=%q err=%v, want %q", got, err, payload)
	}
	if cache := success.Header.Get("Cache-Control"); cache != "private, no-store" {
		t.Fatalf("success Cache-Control=%q", cache)
	}

	independent := getLog(t, h.baseURL, "203.0.113.51", strings.Repeat("x", logIDLength))
	independent.Body.Close()
	if independent.StatusCode != http.StatusNotFound {
		t.Fatalf("independent source status=%d, want 404", independent.StatusCode)
	}
}

func TestLogFailedLookupCleanupIsDeterministic(t *testing.T) {
	store := newLogStore(t.TempDir())
	now := time.Unix(1_700_000_000, 0)
	id, _, err := store.store([]byte("keep"), now)
	if err != nil {
		t.Fatalf("store: %v", err)
	}
	for range logLookupRateBurst {
		if !store.allowFailedLookup("203.0.113.1", now) {
			t.Fatal("burst rejected early")
		}
	}
	if store.allowFailedLookup("203.0.113.1", now) {
		t.Fatal("lookup beyond burst unexpectedly allowed")
	}
	store.cleanup(now)
	if _, ok := store.failedLookupRate["203.0.113.1"]; !ok {
		t.Fatal("cleanup removed an effective limiter")
	}
	store.cleanup(now.Add(time.Duration(logLookupRateBurst) * time.Second))
	if _, ok := store.failedLookupRate["203.0.113.1"]; ok {
		t.Fatal("cleanup retained a fully refilled limiter")
	}
	if _, ok := store.entries[id]; !ok {
		t.Fatal("limiter cleanup removed stored log")
	}
}

func TestLogStorePersistsAcrossRestartAndAvoidsIDCollisions(t *testing.T) {
	dir := t.TempDir()
	now := time.Now().Add(-time.Second)
	first := newLogStore(dir)
	first.generateID = func() string { return strings.Repeat("a", logIDLength) }
	firstID, _, err := first.store([]byte("original"), now)
	if err != nil {
		t.Fatalf("store original: %v", err)
	}

	restarted := newLogStore(dir)
	if _, ok, err := restarted.lookup(firstID, time.Now()); err != nil || !ok {
		t.Fatal("stored log was not restored after restart")
	}

	secondWant := strings.Repeat("b", logIDLength)
	ids := []string{firstID, secondWant}
	restarted.generateID = func() string {
		id := ids[0]
		ids = ids[1:]
		return id
	}
	secondID, _, err := restarted.store([]byte("second"), time.Now())
	if err != nil {
		t.Fatalf("store after restart: %v", err)
	}
	if secondID != secondWant {
		t.Fatalf("collision generated id %q, want %q", secondID, secondWant)
	}

	original, err := os.ReadFile(restarted.filePath(firstID))
	if err != nil {
		t.Fatalf("read original: %v", err)
	}
	if string(original) != "original" {
		t.Fatalf("colliding store overwrote original: %q", original)
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

func TestLogsUseTrustedCanonicalClientIdentity(t *testing.T) {
	t.Run("untrusted spoofing shares direct peer bucket", func(t *testing.T) {
		h := newRelayHarnessNoTrust(t)
		first := postLog(t, h.baseURL, "203.0.113.1", []byte("first"))
		first.Body.Close()
		if first.StatusCode != http.StatusOK {
			t.Fatalf("first status=%d", first.StatusCode)
		}
		second := postLog(t, h.baseURL, "203.0.113.2", []byte("second"))
		second.Body.Close()
		if second.StatusCode != http.StatusTooManyRequests {
			t.Fatalf("rotated spoof status=%d, want 429", second.StatusCode)
		}
	})

	t.Run("trusted clients have independent buckets", func(t *testing.T) {
		h := newRelayHarness(t)
		for _, ip := range []string{"203.0.113.1", "203.0.113.2"} {
			resp := postLog(t, h.baseURL, ip, []byte(ip))
			resp.Body.Close()
			if resp.StatusCode != http.StatusOK {
				t.Fatalf("client %s status=%d, want 200", ip, resp.StatusCode)
			}
		}
	})

	t.Run("malformed trusted chain mutates no log state", func(t *testing.T) {
		h := newRelayHarness(t)
		post := postLog(t, h.baseURL, "203.0.113.1,", []byte("body"))
		post.Body.Close()
		if post.StatusCode != http.StatusBadRequest {
			t.Fatalf("post status=%d, want 400", post.StatusCode)
		}
		get := getLog(t, h.baseURL, "203.0.113.1,", strings.Repeat("a", logIDLength))
		get.Body.Close()
		if get.StatusCode != http.StatusBadRequest {
			t.Fatalf("get status=%d, want 400", get.StatusCode)
		}
		h.srv.logs.mu.RLock()
		defer h.srv.logs.mu.RUnlock()
		if len(h.srv.logs.entries) != 0 || len(h.srv.logs.rateLimit) != 0 || len(h.srv.logs.failedLookupRate) != 0 {
			t.Fatalf("malformed chain mutated log state: entries=%d uploads=%d failures=%d",
				len(h.srv.logs.entries), len(h.srv.logs.rateLimit), len(h.srv.logs.failedLookupRate))
		}
	})

	t.Run("untrusted malformed header is ignored", func(t *testing.T) {
		h := newRelayHarnessNoTrust(t)
		resp := postLog(t, h.baseURL, "bad,", []byte("body"))
		resp.Body.Close()
		if resp.StatusCode != http.StatusOK {
			t.Fatalf("status=%d, want 200", resp.StatusCode)
		}
	})
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
	resp, err := http.Get(h.baseURL + "/logs/" + strings.Repeat("c", logIDLength))
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
	for _, id := range []string{"", "abc", "abcde", strings.Repeat("a", logIDLength+1), strings.Repeat("!", logIDLength)} {
		resp, err := http.Get(h.baseURL + "/logs/" + id)
		if err != nil {
			t.Fatalf("get %q: %v", id, err)
		}
		resp.Body.Close()
		if resp.StatusCode != http.StatusNotFound {
			t.Errorf("id=%q status=%d want 404", id, resp.StatusCode)
		}
		if got := resp.Header.Get("Cache-Control"); got != "private, no-store" {
			t.Errorf("id=%q Cache-Control=%q", id, got)
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

// ======================================================================
// Poster endpoints
// ======================================================================

var minimalPNG = []byte{0x89, 'P', 'N', 'G', 0x0d, 0x0a, 0x1a, 0x0a, 0x01, 0x02, 0x03}

type countingReadCloser struct {
	reader *bytes.Reader
	reads  atomic.Int32
}

func newCountingReadCloser(data []byte) *countingReadCloser {
	return &countingReadCloser{reader: bytes.NewReader(data)}
}

func (r *countingReadCloser) Read(p []byte) (int, error) {
	r.reads.Add(1)
	return r.reader.Read(p)
}

func (r *countingReadCloser) Close() error { return nil }

type blockingReadCloser struct {
	data    []byte
	offset  int
	started chan struct{}
	release <-chan struct{}
	once    sync.Once
}

func (r *blockingReadCloser) Read(p []byte) (int, error) {
	r.once.Do(func() { close(r.started) })
	<-r.release
	if r.offset == len(r.data) {
		return 0, io.EOF
	}
	n := copy(p, r.data[r.offset:])
	r.offset += n
	return n, nil
}

func (r *blockingReadCloser) Close() error { return nil }

type deadlineBlockingReadCloser struct {
	started   chan struct{}
	closed    chan struct{}
	startOnce sync.Once
	closeOnce sync.Once
}

func newDeadlineBlockingReadCloser() *deadlineBlockingReadCloser {
	return &deadlineBlockingReadCloser{
		started: make(chan struct{}),
		closed:  make(chan struct{}),
	}
}

func (r *deadlineBlockingReadCloser) Read([]byte) (int, error) {
	r.startOnce.Do(func() { close(r.started) })
	<-r.closed
	return 0, errors.New("body closed")
}

func (r *deadlineBlockingReadCloser) Close() error {
	r.closeOnce.Do(func() { close(r.closed) })
	return nil
}

type failingReadCloser struct{}

func (failingReadCloser) Read([]byte) (int, error) { return 0, errors.New("read failed") }
func (failingReadCloser) Close() error             { return nil }

func servePosterUpload(s *Server, body io.ReadCloser, xff string) *httptest.ResponseRecorder {
	req := httptest.NewRequest(http.MethodPost, "/posters", body)
	req.RemoteAddr = "198.51.100.10:1234"
	if xff != "" {
		req.Header.Set("X-Forwarded-For", xff)
	}
	recorder := httptest.NewRecorder()
	s.handlePostPosters(recorder, req)
	return recorder
}

func snapshotPosterStore(t *testing.T, store *posterStore) (int, int64, []string) {
	t.Helper()
	store.mu.RLock()
	entryCount := len(store.entries)
	totalBytes := store.totalBytes
	store.mu.RUnlock()
	files, err := os.ReadDir(store.dir)
	if err != nil {
		t.Fatalf("read poster dir: %v", err)
	}
	names := make([]string, len(files))
	for i, file := range files {
		names[i] = file.Name()
	}
	return entryCount, totalBytes, names
}

func TestPosterHandlerRejectsRateLimitedRequestBeforeReadingOrStoring(t *testing.T) {
	s := newTestServer(t, filepath.Join(t.TempDir(), "rooms.json"))
	now := time.Now()
	s.posterUploads = newPosterUploadLimiter(1, 0, 10, 0, 2, now)

	first := servePosterUpload(s, io.NopCloser(bytes.NewReader(minimalPNG)), "203.0.113.1")
	if first.Code != http.StatusOK {
		t.Fatalf("first status=%d", first.Code)
	}
	beforeEntries, beforeBytes, beforeFiles := snapshotPosterStore(t, s.posters)
	rejectedBody := newCountingReadCloser(minimalPNG)
	rejected := servePosterUpload(s, rejectedBody, "203.0.113.2")
	if rejected.Code != http.StatusTooManyRequests {
		t.Fatalf("rejected status=%d, want 429", rejected.Code)
	}
	if rejectedBody.reads.Load() != 0 {
		t.Fatalf("rate-limited body read %d times", rejectedBody.reads.Load())
	}
	afterEntries, afterBytes, afterFiles := snapshotPosterStore(t, s.posters)
	if beforeEntries != afterEntries || beforeBytes != afterBytes || fmt.Sprint(beforeFiles) != fmt.Sprint(afterFiles) {
		t.Fatalf("denial mutated poster store: before=(%d,%d,%v) after=(%d,%d,%v)",
			beforeEntries, beforeBytes, beforeFiles, afterEntries, afterBytes, afterFiles)
	}
}

func TestPosterHandlerConcurrencyRejectsBeforeReadAndRecovers(t *testing.T) {
	s := newTestServer(t, filepath.Join(t.TempDir(), "rooms.json"))
	s.posterUploads = newPosterUploadLimiter(20, 0, 20, 0, 2, time.Now())
	release := make(chan struct{})
	recorders := make(chan *httptest.ResponseRecorder, 2)

	for range 2 {
		body := &blockingReadCloser{
			data:    minimalPNG,
			started: make(chan struct{}),
			release: release,
		}
		go func() {
			recorders <- servePosterUpload(s, body, "")
		}()
		select {
		case <-body.started:
		case <-time.After(time.Second):
			t.Fatal("admitted body was not read")
		}
	}

	extraBody := newCountingReadCloser(minimalPNG)
	extra := servePosterUpload(s, extraBody, "")
	if extra.Code != http.StatusTooManyRequests {
		t.Fatalf("extra status=%d, want 429", extra.Code)
	}
	if extraBody.reads.Load() != 0 {
		t.Fatalf("concurrency-rejected body read %d times", extraBody.reads.Load())
	}

	close(release)
	for range 2 {
		select {
		case recorder := <-recorders:
			if recorder.Code != http.StatusOK {
				t.Fatalf("admitted status=%d", recorder.Code)
			}
		case <-time.After(time.Second):
			t.Fatal("admitted upload did not finish")
		}
	}
	recovered := servePosterUpload(s, io.NopCloser(bytes.NewReader(minimalPNG)), "")
	if recovered.Code != http.StatusOK {
		t.Fatalf("post-completion status=%d, want 200", recovered.Code)
	}
	s.posterUploads.mu.Lock()
	active := s.posterUploads.active
	s.posterUploads.mu.Unlock()
	if active != 0 {
		t.Fatalf("active=%d after completion, want 0", active)
	}
}

func TestPosterHandlerDeadlineReleasesStalledUploadSlot(t *testing.T) {
	s := newTestServer(t, filepath.Join(t.TempDir(), "rooms.json"))
	s.posterUploads = newPosterUploadLimiter(10, 0, 10, 0, 1, time.Now())
	s.posterBodyReadTimeout = 20 * time.Millisecond
	stalled := newDeadlineBlockingReadCloser()
	result := make(chan *httptest.ResponseRecorder, 1)

	go func() {
		result <- servePosterUpload(s, stalled, "")
	}()
	select {
	case <-stalled.started:
	case <-time.After(time.Second):
		t.Fatal("stalled body was not read")
	}

	var timedOut *httptest.ResponseRecorder
	select {
	case timedOut = <-result:
	case <-time.After(time.Second):
		t.Fatal("stalled upload did not honor body deadline")
	}
	if timedOut.Code != http.StatusRequestTimeout {
		t.Fatalf("stalled status=%d, want 408", timedOut.Code)
	}
	s.posterUploads.mu.Lock()
	active := s.posterUploads.active
	s.posterUploads.mu.Unlock()
	if active != 0 {
		t.Fatalf("active=%d after body timeout, want 0", active)
	}

	recovered := servePosterUpload(s, io.NopCloser(bytes.NewReader(minimalPNG)), "")
	if recovered.Code != http.StatusOK {
		t.Fatalf("post-timeout status=%d, want 200", recovered.Code)
	}
}

func TestPosterHandlerSlowChunkedBodyDeadline(t *testing.T) {
	s := newTestServer(t, filepath.Join(t.TempDir(), "rooms.json"))
	s.posterUploads = newPosterUploadLimiter(10, 0, 10, 0, 1, time.Now())
	s.posterBodyReadTimeout = 30 * time.Millisecond
	httpServer := httptest.NewServer(http.HandlerFunc(s.handlePostPosters))
	t.Cleanup(httpServer.Close)

	address := strings.TrimPrefix(httpServer.URL, "http://")
	conn, err := net.DialTimeout("tcp", address, time.Second)
	if err != nil {
		t.Fatalf("dial: %v", err)
	}
	if _, err := fmt.Fprintf(
		conn,
		"POST /posters HTTP/1.1\r\nHost: %s\r\nTransfer-Encoding: chunked\r\n\r\n1\r\nx\r\n",
		address,
	); err != nil {
		conn.Close()
		t.Fatalf("write partial chunked request: %v", err)
	}
	if err := conn.SetReadDeadline(time.Now().Add(time.Second)); err != nil {
		conn.Close()
		t.Fatalf("set response deadline: %v", err)
	}
	response, err := http.ReadResponse(bufio.NewReader(conn), &http.Request{Method: http.MethodPost})
	if err != nil {
		conn.Close()
		t.Fatalf("read timeout response: %v", err)
	}
	response.Body.Close()
	conn.Close()
	if response.StatusCode != http.StatusRequestTimeout {
		t.Fatalf("slow chunked status=%d, want 408", response.StatusCode)
	}

	recovered, err := http.Post(httpServer.URL, "image/png", bytes.NewReader(minimalPNG))
	if err != nil {
		t.Fatalf("post after timeout: %v", err)
	}
	recovered.Body.Close()
	if recovered.StatusCode != http.StatusOK {
		t.Fatalf("post-timeout status=%d, want 200", recovered.StatusCode)
	}
}

func TestPosterHandlerReleasesConcurrencyOnEveryExit(t *testing.T) {
	tests := []struct {
		name         string
		body         func() io.ReadCloser
		wantStatus   int
		storeFailure bool
	}{
		{name: "read error", body: func() io.ReadCloser { return failingReadCloser{} }, wantStatus: http.StatusBadRequest},
		{name: "oversized", body: func() io.ReadCloser {
			return io.NopCloser(bytes.NewReader(make([]byte, maxPosterSize+1)))
		}, wantStatus: http.StatusRequestEntityTooLarge},
		{name: "empty", body: func() io.ReadCloser { return io.NopCloser(bytes.NewReader(nil)) }, wantStatus: http.StatusBadRequest},
		{name: "unsupported", body: func() io.ReadCloser {
			return io.NopCloser(strings.NewReader("not an image"))
		}, wantStatus: http.StatusUnsupportedMediaType},
		{name: "store failure", body: func() io.ReadCloser {
			return io.NopCloser(bytes.NewReader(minimalPNG))
		}, wantStatus: http.StatusInternalServerError, storeFailure: true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			s := newTestServer(t, filepath.Join(t.TempDir(), "rooms.json"))
			s.posterUploads = newPosterUploadLimiter(10, 0, 10, 0, 1, time.Now())
			originalDir := s.posters.dir
			if tt.storeFailure {
				s.posters.dir = filepath.Join(t.TempDir(), "missing", "posters")
			}
			failed := servePosterUpload(s, tt.body(), "")
			if failed.Code != tt.wantStatus {
				t.Fatalf("status=%d, want %d", failed.Code, tt.wantStatus)
			}
			s.posters.dir = originalDir
			recovery := servePosterUpload(s, io.NopCloser(bytes.NewReader(minimalPNG)), "")
			if recovery.Code != http.StatusOK {
				t.Fatalf("recovery status=%d, want 200", recovery.Code)
			}
			s.posterUploads.mu.Lock()
			active := s.posterUploads.active
			s.posterUploads.mu.Unlock()
			if active != 0 {
				t.Fatalf("active=%d, want 0", active)
			}
		})
	}
}

func TestPosterHandlerUsesTrustedCanonicalIdentityAndGlobalBudget(t *testing.T) {
	t.Run("untrusted XFF rotation cannot bypass per-IP limit", func(t *testing.T) {
		h := newRelayHarnessNoTrust(t)
		h.srv.posterUploads = newPosterUploadLimiter(3, 0, 20, 0, 4, time.Now())
		for i := range 3 {
			resp := postPoster(t, h.baseURL, fmt.Sprintf("203.0.113.%d", i+1), minimalPNG)
			resp.Body.Close()
			if resp.StatusCode != http.StatusOK {
				t.Fatalf("upload %d status=%d", i, resp.StatusCode)
			}
		}
		beforeEntries, beforeBytes, beforeFiles := snapshotPosterStore(t, h.srv.posters)
		denied := postPoster(t, h.baseURL, "203.0.113.99", minimalPNG)
		denied.Body.Close()
		if denied.StatusCode != http.StatusTooManyRequests {
			t.Fatalf("rotated spoof status=%d, want 429", denied.StatusCode)
		}
		afterEntries, afterBytes, afterFiles := snapshotPosterStore(t, h.srv.posters)
		if beforeEntries != afterEntries || beforeBytes != afterBytes || fmt.Sprint(beforeFiles) != fmt.Sprint(afterFiles) {
			t.Fatal("per-IP denial mutated poster store")
		}
	})

	t.Run("trusted clients are independent but share global budget", func(t *testing.T) {
		h := newRelayHarness(t)
		h.srv.posterUploads = newPosterUploadLimiter(3, 0, 8, 0, 4, time.Now())
		for range 3 {
			resp := postPoster(t, h.baseURL, "203.0.113.1", minimalPNG)
			resp.Body.Close()
			if resp.StatusCode != http.StatusOK {
				t.Fatalf("client A status=%d", resp.StatusCode)
			}
		}
		perIPDenied := postPoster(t, h.baseURL, "203.0.113.1", minimalPNG)
		perIPDenied.Body.Close()
		if perIPDenied.StatusCode != http.StatusTooManyRequests {
			t.Fatalf("client A overflow status=%d, want 429", perIPDenied.StatusCode)
		}
		for _, ip := range []string{"203.0.113.2", "203.0.113.2", "203.0.113.2", "203.0.113.3", "203.0.113.3"} {
			resp := postPoster(t, h.baseURL, ip, minimalPNG)
			resp.Body.Close()
			if resp.StatusCode != http.StatusOK {
				t.Fatalf("client %s status=%d before global exhaustion", ip, resp.StatusCode)
			}
		}
		beforeEntries, beforeBytes, beforeFiles := snapshotPosterStore(t, h.srv.posters)
		globalDenied := postPoster(t, h.baseURL, "203.0.113.4", minimalPNG)
		globalDenied.Body.Close()
		if globalDenied.StatusCode != http.StatusTooManyRequests {
			t.Fatalf("global overflow status=%d, want 429", globalDenied.StatusCode)
		}
		afterEntries, afterBytes, afterFiles := snapshotPosterStore(t, h.srv.posters)
		if beforeEntries != afterEntries || beforeBytes != afterBytes || fmt.Sprint(beforeFiles) != fmt.Sprint(afterFiles) {
			t.Fatal("global denial mutated poster store")
		}
	})
}

func TestPosterHandlerMalformedTrustedChainMutatesNothing(t *testing.T) {
	s := newTestServer(t, filepath.Join(t.TempDir(), "rooms.json"))
	s.clientIPs = mustClientIPResolver(t, "10.0.0.0/8")
	body := newCountingReadCloser(minimalPNG)
	req := httptest.NewRequest(http.MethodPost, "/posters", body)
	req.RemoteAddr = "10.0.0.2:1234"
	req.Header.Set("X-Forwarded-For", "203.0.113.1,")
	recorder := httptest.NewRecorder()
	s.handlePostPosters(recorder, req)
	if recorder.Code != http.StatusBadRequest {
		t.Fatalf("status=%d, want 400", recorder.Code)
	}
	if body.reads.Load() != 0 {
		t.Fatalf("malformed-chain body read %d times", body.reads.Load())
	}
	s.posterUploads.mu.Lock()
	active := s.posterUploads.active
	perIP := len(s.posterUploads.perIP)
	s.posterUploads.global.mu.Lock()
	globalTokens := s.posterUploads.global.tokens
	s.posterUploads.global.mu.Unlock()
	s.posterUploads.mu.Unlock()
	if active != 0 || perIP != 0 || globalTokens != posterGlobalRateBurst {
		t.Fatalf("malformed chain mutated admission: active=%d perIP=%d global=%v", active, perIP, globalTokens)
	}
	entries, total, files := snapshotPosterStore(t, s.posters)
	if entries != 0 || total != 0 || len(files) != 0 {
		t.Fatalf("malformed chain mutated store: entries=%d total=%d files=%v", entries, total, files)
	}
}

func TestPosterHandlerIgnoresMalformedHeaderFromUntrustedPeer(t *testing.T) {
	h := newRelayHarnessNoTrust(t)
	resp := postPoster(t, h.baseURL, "bad,", minimalPNG)
	resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("status=%d, want 200", resp.StatusCode)
	}
}

func TestPostersRoundTrip(t *testing.T) {
	h := newRelayHarness(t)
	payload := []byte{0x89, 'P', 'N', 'G', 0x0d, 0x0a, 0x1a, 0x0a, 0x01, 0x02, 0x03}
	out := postPosterAndDecode(t, h.baseURL, "9.0.0.1", payload)

	if out.ExpiresIn != int(posterMaxAge.Seconds()) {
		t.Fatalf("expiresIn=%d want %d", out.ExpiresIn, int(posterMaxAge.Seconds()))
	}
	if !strings.HasPrefix(out.URL, "/posters/") || !strings.HasSuffix(out.URL, ".png") {
		t.Fatalf("url=%q should be a relative png poster path", out.URL)
	}
	if strings.Contains(out.URL, "://") {
		t.Fatalf("url=%q should be relative", out.URL)
	}

	getResp, err := http.Get(h.baseURL + out.URL)
	if err != nil {
		t.Fatalf("get: %v", err)
	}
	defer getResp.Body.Close()
	if getResp.StatusCode != http.StatusOK {
		t.Fatalf("get status=%d", getResp.StatusCode)
	}
	got, _ := io.ReadAll(getResp.Body)
	if !bytes.Equal(got, payload) {
		t.Fatalf("round-tripped bytes mismatch: got %v want %v", got, payload)
	}
	if ct := getResp.Header.Get("Content-Type"); !strings.HasPrefix(ct, "image/png") {
		t.Errorf("Content-Type=%q", ct)
	}
}

func TestPostersRejectInvalidAndOversizedUploads(t *testing.T) {
	h := newRelayHarness(t)

	invalid := postPoster(t, h.baseURL, "9.0.0.2", []byte("not an image"))
	invalid.Body.Close()
	if invalid.StatusCode != http.StatusUnsupportedMediaType {
		t.Fatalf("invalid status=%d want 415", invalid.StatusCode)
	}

	oversized := postPoster(t, h.baseURL, "9.0.0.3", make([]byte, maxPosterSize+1))
	oversized.Body.Close()
	if oversized.StatusCode != http.StatusRequestEntityTooLarge {
		t.Fatalf("oversized status=%d want 413", oversized.StatusCode)
	}
}

func TestPosterStoreEvictsOldestOverQuota(t *testing.T) {
	ps := newPosterStore(t.TempDir(), 12, time.Hour)
	now := time.Now()
	payload := []byte{1, 2, 3, 4, 5, 6, 7}

	id1, entry1, err := ps.store(payload, "image/png", now)
	if err != nil {
		t.Fatalf("store first: %v", err)
	}
	id2, entry2, err := ps.store(payload, "image/png", now.Add(time.Minute))
	if err != nil {
		t.Fatalf("store second: %v", err)
	}

	ps.mu.RLock()
	_, hasFirst := ps.entries[id1]
	_, hasSecond := ps.entries[id2]
	total := ps.totalBytes
	ps.mu.RUnlock()

	if hasFirst {
		t.Fatal("oldest poster should have been evicted")
	}
	if !hasSecond {
		t.Fatal("newest poster should remain")
	}
	if total != int64(len(payload)) {
		t.Fatalf("totalBytes=%d want %d", total, len(payload))
	}
	if _, err := os.Stat(ps.filePath(entry1.Filename)); !os.IsNotExist(err) {
		t.Fatalf("oldest file still exists or stat failed unexpectedly: %v", err)
	}
	if _, err := os.Stat(ps.filePath(entry2.Filename)); err != nil {
		t.Fatalf("newest file missing: %v", err)
	}
}

func TestPosterStoreCleanupExpiresOldPosters(t *testing.T) {
	ps := newPosterStore(t.TempDir(), 1024, time.Hour)
	now := time.Now()
	id, entry, err := ps.store([]byte{1, 2, 3}, "image/png", now.Add(-2*time.Hour))
	if err != nil {
		t.Fatalf("store: %v", err)
	}

	if err := ps.cleanup(now); err != nil {
		t.Fatalf("cleanup: %v", err)
	}

	ps.mu.RLock()
	_, exists := ps.entries[id]
	total := ps.totalBytes
	ps.mu.RUnlock()
	if exists {
		t.Fatal("expired poster should have been removed")
	}
	if total != 0 {
		t.Fatalf("totalBytes=%d want 0", total)
	}
	if _, err := os.Stat(ps.filePath(entry.Filename)); !os.IsNotExist(err) {
		t.Fatalf("expired file still exists or stat failed unexpectedly: %v", err)
	}
}

func regularFileBytes(t *testing.T, dir string) int64 {
	t.Helper()
	files, err := os.ReadDir(dir)
	if err != nil {
		t.Fatalf("read directory: %v", err)
	}
	var total int64
	for _, file := range files {
		info, err := file.Info()
		if err != nil {
			t.Fatalf("stat %s: %v", file.Name(), err)
		}
		if info.Mode().IsRegular() {
			total += info.Size()
		}
	}
	return total
}

func TestLogStoreRemovalFailureRetainsEntryUntilRetry(t *testing.T) {
	dir := t.TempDir()
	remover := newDeterministicRemover()
	ls := newLogStoreWithRemover(dir, remover.remove)
	ls.generateID = func() string { return strings.Repeat("a", logIDLength) }
	now := time.Now()
	id, _, err := ls.store([]byte("retained"), now)
	if err != nil {
		t.Fatalf("store: %v", err)
	}
	path := ls.filePath(id)
	ls.mu.Lock()
	entry := ls.entries[id]
	entry.ExpiresAt = now.Add(-time.Minute)
	ls.entries[id] = entry
	ls.mu.Unlock()
	remover.fail(path, fs.ErrPermission)

	if _, ok, err := ls.lookup(id, now); !errors.Is(err, fs.ErrPermission) || ok {
		t.Fatalf("lookup=(ok=%v, err=%v), want unavailable permission error", ok, err)
	}
	ls.mu.RLock()
	_, indexed := ls.entries[id]
	artifacts := ls.artifactCountLocked()
	ls.mu.RUnlock()
	if !indexed || artifacts != 1 {
		t.Fatalf("failed removal changed metadata: indexed=%v artifacts=%d", indexed, artifacts)
	}
	if _, err := os.Stat(path); err != nil {
		t.Fatalf("failed removal lost file: %v", err)
	}

	remover.recover(path)
	if err := ls.cleanup(now); err != nil {
		t.Fatalf("retry cleanup: %v", err)
	}
	if remover.callCount(path) != 2 {
		t.Fatalf("remove calls=%d want 2", remover.callCount(path))
	}
	if _, err := os.Stat(path); !errors.Is(err, fs.ErrNotExist) {
		t.Fatalf("file remains after retry: %v", err)
	}
	if err := ls.cleanup(now); err != nil {
		t.Fatalf("idempotent cleanup: %v", err)
	}
	if remover.callCount(path) != 2 {
		t.Fatalf("already committed entry removed again: calls=%d", remover.callCount(path))
	}
}

func TestRemovalFailureDoesNotBlockUploadsWhileCapacityRemains(t *testing.T) {
	t.Run("logs", func(t *testing.T) {
		dir := t.TempDir()
		remover := newDeterministicRemover()
		store := newLogStoreWithRemover(dir, remover.remove)
		ids := []string{strings.Repeat("a", logIDLength), strings.Repeat("b", logIDLength)}
		nextID := 0
		store.generateID = func() string {
			id := ids[nextID]
			nextID++
			return id
		}
		now := time.Now()
		firstID, _, err := store.store([]byte("expired"), now)
		if err != nil {
			t.Fatalf("store expired log: %v", err)
		}
		store.mu.Lock()
		entry := store.entries[firstID]
		entry.ExpiresAt = now.Add(-time.Minute)
		store.entries[firstID] = entry
		store.mu.Unlock()
		remover.fail(store.filePath(firstID), fs.ErrPermission)

		secondID, _, err := store.store([]byte("new"), now)
		if err != nil {
			t.Fatalf("unrelated removal failure blocked log upload: %v", err)
		}
		store.mu.RLock()
		_, firstRetained := store.entries[firstID]
		_, secondStored := store.entries[secondID]
		store.mu.RUnlock()
		if !firstRetained || !secondStored {
			t.Fatalf("log accounting lost entries: first=%v second=%v", firstRetained, secondStored)
		}
	})

	t.Run("posters", func(t *testing.T) {
		dir := t.TempDir()
		remover := newDeterministicRemover()
		store := newPosterStoreWithRemover(dir, 1024, time.Hour, remover.remove)
		now := time.Now()
		firstID, first, err := store.store([]byte{1, 2, 3}, "image/png", now.Add(-2*time.Hour))
		if err != nil {
			t.Fatalf("store expired poster: %v", err)
		}
		remover.fail(store.filePath(first.Filename), fs.ErrPermission)

		secondID, _, err := store.store([]byte{4, 5, 6}, "image/png", now)
		if err != nil {
			t.Fatalf("unrelated removal failure blocked poster upload: %v", err)
		}
		store.mu.RLock()
		_, firstRetained := store.entries[firstID]
		_, secondStored := store.entries[secondID]
		store.mu.RUnlock()
		if !firstRetained || !secondStored {
			t.Fatalf("poster accounting lost entries: first=%v second=%v", firstRetained, secondStored)
		}
	})
}

func TestLogStoreErrNotExistCommitsDeletionOnce(t *testing.T) {
	remover := newDeterministicRemover()
	ls := newLogStoreWithRemover(t.TempDir(), remover.remove)
	ls.generateID = func() string { return strings.Repeat("a", logIDLength) }
	now := time.Now()
	id, _, err := ls.store([]byte("gone"), now)
	if err != nil {
		t.Fatalf("store: %v", err)
	}
	path := ls.filePath(id)
	if err := os.Remove(path); err != nil {
		t.Fatalf("external remove: %v", err)
	}
	ls.mu.Lock()
	entry := ls.entries[id]
	entry.ExpiresAt = now.Add(-time.Minute)
	ls.entries[id] = entry
	ls.mu.Unlock()

	if _, ok, err := ls.lookup(id, now); err != nil || ok {
		t.Fatalf("lookup=(ok=%v, err=%v), want clean miss", ok, err)
	}
	if err := ls.cleanup(now); err != nil {
		t.Fatalf("repeat cleanup: %v", err)
	}
	if remover.callCount(path) != 1 {
		t.Fatalf("remove calls=%d want 1", remover.callCount(path))
	}
}

func TestLogStoreTracksFailedTempCleanup(t *testing.T) {
	dir := t.TempDir()
	remover := newDeterministicRemover()
	ls := newLogStoreWithRemover(dir, remover.remove)
	logID := strings.Repeat("a", logIDLength)
	ls.generateID = func() string { return logID }
	tmpPath := ls.filePath(logID) + ".tmp"
	if err := os.Mkdir(tmpPath, 0755); err != nil {
		t.Fatalf("seed temp directory: %v", err)
	}
	cleanupErr := errors.New("synthetic temp removal failure")
	remover.fail(tmpPath, cleanupErr)

	if _, _, err := ls.store([]byte("payload"), time.Now()); err == nil {
		t.Fatal("store succeeded despite temp write failure")
	}
	ls.mu.RLock()
	_, pending := ls.pendingRemovals[filepath.Base(tmpPath)]
	artifacts := ls.artifactCountLocked()
	ls.mu.RUnlock()
	if !pending || artifacts != 1 {
		t.Fatalf("temp cleanup not tracked: pending=%v artifacts=%d", pending, artifacts)
	}

	remover.recover(tmpPath)
	if err := ls.cleanup(time.Now()); err != nil {
		t.Fatalf("retry temp cleanup: %v", err)
	}
	if _, err := os.Stat(tmpPath); !errors.Is(err, fs.ErrNotExist) {
		t.Fatalf("temp artifact remains: %v", err)
	}
}

func TestLogStoreStartupReconcilesLiveAndPendingRemovals(t *testing.T) {
	dir := t.TempDir()
	now := time.Now()
	expiredID := strings.Repeat("a", logIDLength)
	expiredPath := filepath.Join(dir, expiredID+".log")
	tempPath := filepath.Join(dir, "upload.log.tmp")
	malformedPath := filepath.Join(dir, "malformed")
	for path, data := range map[string][]byte{
		expiredPath:   []byte("expired"),
		tempPath:      []byte("partial"),
		malformedPath: []byte("invalid"),
	} {
		if err := os.WriteFile(path, data, 0644); err != nil {
			t.Fatalf("seed %s: %v", filepath.Base(path), err)
		}
	}
	old := now.Add(-logMaxAge - time.Hour)
	if err := os.Chtimes(expiredPath, old, old); err != nil {
		t.Fatalf("age expired log: %v", err)
	}
	remover := newDeterministicRemover()
	for _, path := range []string{expiredPath, tempPath, malformedPath} {
		remover.fail(path, fs.ErrPermission)
	}

	ls := newLogStoreWithRemover(dir, remover.remove)
	if ls.startupErr == nil {
		t.Fatal("startup removal failures were not reported")
	}
	ls.mu.RLock()
	_, live := ls.entries[expiredID]
	pending := len(ls.pendingRemovals)
	artifacts := ls.artifactCountLocked()
	ls.mu.RUnlock()
	if !live || pending != 2 || artifacts != 3 {
		t.Fatalf("startup accounting: live=%v pending=%d artifacts=%d", live, pending, artifacts)
	}
	newID, _, err := ls.store([]byte("new"), now)
	if err != nil {
		t.Fatalf("startup cleanup failure blocked new log: %v", err)
	}

	for _, path := range []string{expiredPath, tempPath, malformedPath} {
		remover.recover(path)
	}
	if err := ls.cleanup(now); err != nil {
		t.Fatalf("startup retry cleanup: %v", err)
	}
	restarted := newLogStore(dir)
	restarted.mu.RLock()
	restartedArtifacts := restarted.artifactCountLocked()
	_, newLogRestored := restarted.entries[newID]
	restarted.mu.RUnlock()
	if restartedArtifacts != 1 || !newLogRestored {
		t.Fatalf("restart reconstructed %d artifacts, new log restored=%v", restartedArtifacts, newLogRestored)
	}
}

func TestStoresReconcileConfinedNonEmptyStaleDirectories(t *testing.T) {
	t.Run("logs", func(t *testing.T) {
		dir := t.TempDir()
		staleDir := filepath.Join(dir, "abandoned.log.tmp")
		if err := os.MkdirAll(filepath.Join(staleDir, "nested"), 0755); err != nil {
			t.Fatalf("seed stale log directory: %v", err)
		}
		if err := os.WriteFile(filepath.Join(staleDir, "nested", "partial"), []byte("stale"), 0644); err != nil {
			t.Fatalf("seed stale log payload: %v", err)
		}

		store := newLogStore(dir)
		if store.startupErr != nil {
			t.Fatalf("startup reconciliation: %v", store.startupErr)
		}
		if _, err := os.Stat(staleDir); !errors.Is(err, fs.ErrNotExist) {
			t.Fatalf("stale log directory remains: %v", err)
		}
		store.generateID = func() string { return strings.Repeat("a", logIDLength) }
		if _, _, err := store.store([]byte("new log"), time.Now()); err != nil {
			t.Fatalf("store after reconciliation: %v", err)
		}
	})

	t.Run("posters", func(t *testing.T) {
		dir := t.TempDir()
		staleDir := filepath.Join(dir, "abandoned.tmp")
		if err := os.MkdirAll(filepath.Join(staleDir, "nested"), 0755); err != nil {
			t.Fatalf("seed stale poster directory: %v", err)
		}
		if err := os.WriteFile(filepath.Join(staleDir, "nested", "partial"), []byte("stale"), 0644); err != nil {
			t.Fatalf("seed stale poster payload: %v", err)
		}

		store := newPosterStore(dir, 1024, time.Hour)
		if store.startupErr != nil {
			t.Fatalf("startup reconciliation: %v", store.startupErr)
		}
		if _, err := os.Stat(staleDir); !errors.Is(err, fs.ErrNotExist) {
			t.Fatalf("stale poster directory remains: %v", err)
		}
		if _, _, err := store.store([]byte{1, 2, 3}, "image/png", time.Now()); err != nil {
			t.Fatalf("store after reconciliation: %v", err)
		}
	})
}

func TestRecursiveArtifactRemovalRejectsOutsideStore(t *testing.T) {
	root := t.TempDir()
	outside := t.TempDir()
	nested := filepath.Join(outside, "nested")
	if err := os.Mkdir(nested, 0755); err != nil {
		t.Fatalf("seed outside directory: %v", err)
	}
	if err := os.WriteFile(filepath.Join(nested, "keep"), []byte("keep"), 0644); err != nil {
		t.Fatalf("seed outside payload: %v", err)
	}

	err := removeArtifact(os.Remove, root, nested)
	if !errors.Is(err, errArtifactOutsideStore) {
		t.Fatalf("outside removal error=%v, want confinement error", err)
	}
	if _, err := os.Stat(filepath.Join(nested, "keep")); err != nil {
		t.Fatalf("outside artifact was removed: %v", err)
	}
}

func TestPosterQuotaRemovalFailureDoesNotReclaimAccounting(t *testing.T) {
	dir := t.TempDir()
	remover := newDeterministicRemover()
	ps := newPosterStoreWithRemover(dir, 12, time.Hour, remover.remove)
	now := time.Now()
	payload := []byte{1, 2, 3, 4, 5, 6, 7}
	oldID, oldEntry, err := ps.store(payload, "image/png", now)
	if err != nil {
		t.Fatalf("store oldest: %v", err)
	}
	oldPath := ps.filePath(oldEntry.Filename)
	remover.fail(oldPath, fs.ErrPermission)

	newID, newEntry, err := ps.store(payload, "image/png", now.Add(time.Minute))
	if !errors.Is(err, fs.ErrPermission) {
		t.Fatalf("quota store error=%v want permission error", err)
	}
	if newID != "" || newEntry != (posterEntry{}) {
		t.Fatalf("failed store returned success values: id=%q entry=%+v", newID, newEntry)
	}
	ps.mu.RLock()
	_, retained := ps.entries[oldID]
	total := ps.totalBytes
	pending := ps.pendingBytes
	accounted := ps.accountedBytesLocked()
	ps.mu.RUnlock()
	if !retained || total != int64(len(payload)) || pending != 0 {
		t.Fatalf("failed eviction accounting: retained=%v total=%d pending=%d", retained, total, pending)
	}
	if physical := regularFileBytes(t, dir); physical != accounted {
		t.Fatalf("accounted bytes=%d physical bytes=%d", accounted, physical)
	}

	remover.recover(oldPath)
	retryID, retryEntry, err := ps.store(payload, "image/png", now.Add(time.Minute))
	if err != nil {
		t.Fatalf("retry store: %v", err)
	}
	if retryID == "" || retryEntry.Size != int64(len(payload)) {
		t.Fatalf("retry result: id=%q entry=%+v", retryID, retryEntry)
	}
	if remover.callCount(oldPath) != 2 {
		t.Fatalf("old poster remove calls=%d want 2", remover.callCount(oldPath))
	}
	ps.mu.RLock()
	accounted = ps.accountedBytesLocked()
	total = ps.totalBytes
	ps.mu.RUnlock()
	if total != int64(len(payload)) || regularFileBytes(t, dir) != accounted {
		t.Fatalf("retry accounting: total=%d accounted=%d physical=%d", total, accounted, regularFileBytes(t, dir))
	}
}

func TestPosterExpiredRemovalFailureAndErrNotExistAreExactOnce(t *testing.T) {
	t.Run("failure retains accounting for retry", func(t *testing.T) {
		remover := newDeterministicRemover()
		ps := newPosterStoreWithRemover(t.TempDir(), 1024, time.Hour, remover.remove)
		now := time.Now()
		id, entry, err := ps.store([]byte{1, 2, 3}, "image/png", now)
		if err != nil {
			t.Fatalf("store: %v", err)
		}
		path := ps.filePath(entry.Filename)
		ps.mu.Lock()
		expired := ps.entries[id]
		expired.ExpiresAt = now.Add(-time.Minute)
		ps.entries[id] = expired
		ps.mu.Unlock()
		remover.fail(path, fs.ErrPermission)

		if _, ok, err := ps.lookup(entry.Filename, now); !errors.Is(err, fs.ErrPermission) || ok {
			t.Fatalf("lookup=(ok=%v, err=%v), want unavailable permission error", ok, err)
		}
		ps.mu.RLock()
		_, retained := ps.entries[id]
		total := ps.totalBytes
		ps.mu.RUnlock()
		if !retained || total != entry.Size {
			t.Fatalf("failed expiry accounting: retained=%v total=%d", retained, total)
		}

		remover.recover(path)
		if err := ps.cleanup(now); err != nil {
			t.Fatalf("retry cleanup: %v", err)
		}
		if err := ps.cleanup(now); err != nil {
			t.Fatalf("repeat cleanup: %v", err)
		}
		if remover.callCount(path) != 2 {
			t.Fatalf("remove calls=%d want 2", remover.callCount(path))
		}
		ps.mu.RLock()
		total = ps.totalBytes
		ps.mu.RUnlock()
		if total != 0 {
			t.Fatalf("totalBytes=%d want 0", total)
		}
	})

	t.Run("not exist commits once", func(t *testing.T) {
		remover := newDeterministicRemover()
		ps := newPosterStoreWithRemover(t.TempDir(), 1024, time.Hour, remover.remove)
		now := time.Now()
		id, entry, err := ps.store([]byte{1, 2, 3}, "image/png", now)
		if err != nil {
			t.Fatalf("store: %v", err)
		}
		path := ps.filePath(entry.Filename)
		if err := os.Remove(path); err != nil {
			t.Fatalf("external remove: %v", err)
		}
		ps.mu.Lock()
		expired := ps.entries[id]
		expired.ExpiresAt = now.Add(-time.Minute)
		ps.entries[id] = expired
		ps.mu.Unlock()

		if _, ok, err := ps.lookup(entry.Filename, now); err != nil || ok {
			t.Fatalf("lookup=(ok=%v, err=%v), want clean miss", ok, err)
		}
		if err := ps.cleanup(now); err != nil {
			t.Fatalf("repeat cleanup: %v", err)
		}
		if remover.callCount(path) != 1 {
			t.Fatalf("remove calls=%d want 1", remover.callCount(path))
		}
		ps.mu.RLock()
		total := ps.totalBytes
		ps.mu.RUnlock()
		if total != 0 {
			t.Fatalf("totalBytes=%d want 0", total)
		}
	})
}

func TestPosterStoreKnownCleanupDebtConsumesCapacityAndRetries(t *testing.T) {
	dir := t.TempDir()
	stalePath := filepath.Join(dir, "poster.tmp")
	if err := os.WriteFile(stalePath, []byte("1234"), 0644); err != nil {
		t.Fatalf("seed stale poster: %v", err)
	}
	remover := newDeterministicRemover()
	remover.fail(stalePath, fs.ErrPermission)

	ps := newPosterStoreWithRemover(dir, 5, time.Hour, remover.remove)
	if ps.startupErr == nil {
		t.Fatal("startup removal failure was not reported")
	}
	if _, _, err := ps.store([]byte{1, 2}, "image/png", time.Now()); err == nil {
		t.Fatal("upload exceeded capacity after known stale bytes were accounted")
	}
	ps.mu.RLock()
	pendingBytes := ps.pendingBytes
	accountedBytes := ps.accountedBytesLocked()
	ps.mu.RUnlock()
	if pendingBytes != 4 || accountedBytes != 4 {
		t.Fatalf("known debt accounting: pending=%d accounted=%d, want 4", pendingBytes, accountedBytes)
	}
	if calls := remover.callCount(stalePath); calls != 2 {
		t.Fatalf("known debt remove calls=%d, want startup plus upload retry", calls)
	}

	remover.recover(stalePath)
	if _, entry, err := ps.store([]byte{1, 2}, "image/png", time.Now()); err != nil {
		t.Fatalf("store after known debt recovery: %v", err)
	} else if entry.Size != 2 {
		t.Fatalf("stored entry size=%d, want 2", entry.Size)
	}
	ps.mu.RLock()
	pendingBytes = ps.pendingBytes
	ps.mu.RUnlock()
	if pendingBytes != 0 {
		t.Fatalf("known debt remained after successful retry: %d bytes", pendingBytes)
	}
}

func TestPosterStoreUnknownCleanupDebtDoesNotBlockUploadAndRecovers(t *testing.T) {
	dir := t.TempDir()
	unknownPath := filepath.Join(dir, "unknown-dir")
	if err := os.Mkdir(unknownPath, 0755); err != nil {
		t.Fatalf("seed unknown artifact: %v", err)
	}
	remover := newDeterministicRemover()
	remover.fail(unknownPath, fs.ErrPermission)

	ps := newPosterStoreWithRemover(dir, 5, time.Hour, remover.remove)
	if ps.startupErr == nil {
		t.Fatal("startup removal failure was not reported")
	}
	if calls := remover.callCount(unknownPath); calls != 1 {
		t.Fatalf("startup remove calls=%d, want 1", calls)
	}
	if _, entry, err := ps.store([]byte{1, 2, 3}, "image/png", time.Now()); err != nil {
		t.Fatalf("capacity-safe upload blocked by unknown artifact: %v", err)
	} else if entry.Size != 3 {
		t.Fatalf("stored entry size=%d, want 3", entry.Size)
	}
	if calls := remover.callCount(unknownPath); calls != 1 {
		t.Fatalf("upload retried permanent unknown debt: calls=%d", calls)
	}

	if err := ps.cleanup(time.Now()); !errors.Is(err, fs.ErrPermission) {
		t.Fatalf("failed cleanup error=%v, want permission error", err)
	}
	ps.mu.RLock()
	pending, exists := ps.pendingRemovals[filepath.Base(unknownPath)]
	pendingBytes := ps.pendingBytes
	ps.mu.RUnlock()
	if !exists || pending.sizeKnown {
		t.Fatalf("unknown debt entry=(%+v, exists=%v), want present with unknown size", pending, exists)
	}
	if pendingBytes != 0 {
		t.Fatalf("unknown debt consumed %d known pending bytes", pendingBytes)
	}

	remover.recover(unknownPath)
	if err := ps.cleanup(time.Now()); err != nil {
		t.Fatalf("cleanup after recovery: %v", err)
	}
	ps.mu.RLock()
	pendingCount := len(ps.pendingRemovals)
	pendingBytes = ps.pendingBytes
	ps.mu.RUnlock()
	if pendingCount != 0 || pendingBytes != 0 {
		t.Fatalf("recovered debt remains: pending=%d bytes=%d", pendingCount, pendingBytes)
	}
	if _, err := os.Stat(unknownPath); !errors.Is(err, fs.ErrNotExist) {
		t.Fatalf("unknown artifact remains after recovery: %v", err)
	}
}

func TestStorageHandlersReturnGenericErrorsForRemovalFailures(t *testing.T) {
	remover := newDeterministicRemover()
	logs := newLogStoreWithRemover(t.TempDir(), remover.remove)
	logs.generateID = func() string { return strings.Repeat("a", logIDLength) }
	posters := newPosterStoreWithRemover(t.TempDir(), 1024, time.Hour, remover.remove)
	h := newStorageHarness(t, logs, posters)
	now := time.Now()

	logID, _, err := logs.store([]byte("expired log"), now)
	if err != nil {
		t.Fatalf("store log: %v", err)
	}
	posterID, poster, err := posters.store([]byte{1, 2, 3}, "image/png", now)
	if err != nil {
		t.Fatalf("store poster: %v", err)
	}
	logs.mu.Lock()
	logEntry := logs.entries[logID]
	logEntry.ExpiresAt = now.Add(-time.Minute)
	logs.entries[logID] = logEntry
	logs.mu.Unlock()
	posters.mu.Lock()
	posterEntry := posters.entries[posterID]
	posterEntry.ExpiresAt = now.Add(-time.Minute)
	posters.entries[posterID] = posterEntry
	posters.mu.Unlock()
	logPath := logs.filePath(logID)
	posterPath := posters.filePath(poster.Filename)
	remover.fail(logPath, fs.ErrPermission)
	remover.fail(posterPath, fs.ErrPermission)

	for name, target := range map[string]string{
		"log":    h.baseURL + "/logs/" + logID,
		"poster": h.baseURL + "/posters/" + poster.Filename,
	} {
		resp, err := http.Get(target)
		if err != nil {
			t.Fatalf("%s get: %v", name, err)
		}
		body, readErr := io.ReadAll(resp.Body)
		resp.Body.Close()
		if readErr != nil {
			t.Fatalf("%s response body: %v", name, readErr)
		}
		if resp.StatusCode != http.StatusInternalServerError {
			t.Fatalf("%s status=%d want 500", name, resp.StatusCode)
		}
		want := "Failed to retrieve " + name + "\n"
		if string(body) != want {
			t.Fatalf("%s response=%q want %q", name, body, want)
		}
	}

	remover.recover(logPath)
	remover.recover(posterPath)
	for name, target := range map[string]string{
		"log":    h.baseURL + "/logs/" + logID,
		"poster": h.baseURL + "/posters/" + poster.Filename,
	} {
		resp, err := http.Get(target)
		if err != nil {
			t.Fatalf("%s recovery get: %v", name, err)
		}
		resp.Body.Close()
		if resp.StatusCode != http.StatusNotFound {
			t.Fatalf("%s recovery status=%d want 404", name, resp.StatusCode)
		}
	}
}

func TestPosterHandlerRejectsUploadWhenQuotaRemovalFails(t *testing.T) {
	remover := newDeterministicRemover()
	logs := newLogStoreWithRemover(t.TempDir(), remover.remove)
	payload := []byte{0x89, 'P', 'N', 'G', 0x0d, 0x0a, 0x1a, 0x0a, 1, 2, 3}
	posters := newPosterStoreWithRemover(t.TempDir(), int64(len(payload)+1), time.Hour, remover.remove)
	now := time.Now()
	oldID, oldEntry, err := posters.store(payload, "image/png", now)
	if err != nil {
		t.Fatalf("store old poster: %v", err)
	}
	oldPath := posters.filePath(oldEntry.Filename)
	remover.fail(oldPath, fs.ErrPermission)
	h := newStorageHarness(t, logs, posters)

	resp := postPoster(t, h.baseURL, "9.9.9.9", payload)
	body, readErr := io.ReadAll(resp.Body)
	resp.Body.Close()
	if readErr != nil {
		t.Fatalf("read failed upload response: %v", readErr)
	}
	if resp.StatusCode != http.StatusInternalServerError || string(body) != "Failed to store poster\n" {
		t.Fatalf("failed upload status=%d body=%q", resp.StatusCode, body)
	}
	posters.mu.RLock()
	_, retained := posters.entries[oldID]
	total := posters.totalBytes
	posters.mu.RUnlock()
	if !retained || total != int64(len(payload)) {
		t.Fatalf("failed upload changed old poster: retained=%v total=%d", retained, total)
	}
	get, err := http.Get(h.baseURL + "/posters/" + oldEntry.Filename)
	if err != nil {
		t.Fatalf("get retained poster: %v", err)
	}
	get.Body.Close()
	if get.StatusCode != http.StatusOK {
		t.Fatalf("retained poster status=%d want 200", get.StatusCode)
	}
}

func TestCleanupStepContinuesAfterRemovalFailureAndThrottlesLogging(t *testing.T) {
	remover := newDeterministicRemover()
	logs := newLogStoreWithRemover(t.TempDir(), remover.remove)
	logs.generateID = func() string { return strings.Repeat("a", logIDLength) }
	posters := newPosterStoreWithRemover(t.TempDir(), 1024, time.Hour, remover.remove)
	now := time.Now()
	logID, _, err := logs.store([]byte("expired"), now)
	if err != nil {
		t.Fatalf("store log: %v", err)
	}
	posterID, poster, err := posters.store([]byte{1, 2, 3}, "image/png", now)
	if err != nil {
		t.Fatalf("store poster: %v", err)
	}
	logs.mu.Lock()
	logEntry := logs.entries[logID]
	logEntry.ExpiresAt = now.Add(-time.Minute)
	logs.entries[logID] = logEntry
	logs.mu.Unlock()
	posters.mu.Lock()
	posterEntry := posters.entries[posterID]
	posterEntry.ExpiresAt = now.Add(-time.Minute)
	posters.entries[posterID] = posterEntry
	posters.mu.Unlock()
	logPath := logs.filePath(logID)
	remover.fail(logPath, fs.ErrPermission)

	srv := &Server{
		rooms:         make(map[string]*Room),
		logs:          logs,
		posters:       posters,
		posterUploads: newPosterUploadLimiter(posterPerIPRateBurst, posterPerIPRateSustained, posterGlobalRateBurst, posterGlobalRateSustained, maxConcurrentPosterUploads, now),
		conns:         newConnTracker(),
	}
	srv.runCleanupStep(now)
	logs.mu.RLock()
	_, logRetained := logs.entries[logID]
	logs.mu.RUnlock()
	posters.mu.RLock()
	_, posterRetained := posters.entries[posterID]
	posters.mu.RUnlock()
	if !logRetained || posterRetained {
		t.Fatalf("cleanup continuation: log retained=%v poster retained=%v", logRetained, posterRetained)
	}
	if _, err := os.Stat(posters.filePath(poster.Filename)); !errors.Is(err, fs.ErrNotExist) {
		t.Fatalf("poster cleanup did not continue: %v", err)
	}

	srv.removalErrors.mu.Lock()
	firstLog := srv.removalErrors.lastLog["logs:cleanup"]
	srv.removalErrors.mu.Unlock()
	if firstLog.IsZero() {
		t.Fatal("cleanup removal failure was not made operationally visible")
	}
	srv.runCleanupStep(now.Add(time.Minute))
	srv.removalErrors.mu.Lock()
	secondLog := srv.removalErrors.lastLog["logs:cleanup"]
	srv.removalErrors.mu.Unlock()
	if !secondLog.Equal(firstLog) {
		t.Fatalf("persistent cleanup failure was not throttled: first=%v second=%v", firstLog, secondLog)
	}
	if remover.callCount(logPath) != 2 {
		t.Fatalf("cleanup retry calls=%d want 2", remover.callCount(logPath))
	}
}

func TestRemovalFailureLogDoesNotExposeCapabilityPath(t *testing.T) {
	dir := t.TempDir()
	remover := newDeterministicRemover()
	store := newLogStoreWithRemover(dir, remover.remove)
	id := strings.Repeat("c", logIDLength)
	store.generateID = func() string { return id }
	now := time.Now()
	if _, _, err := store.store([]byte("sensitive"), now); err != nil {
		t.Fatalf("store: %v", err)
	}
	path := store.filePath(id)
	store.mu.Lock()
	entry := store.entries[id]
	entry.ExpiresAt = now.Add(-time.Minute)
	store.entries[id] = entry
	store.mu.Unlock()
	remover.fail(path, &os.PathError{Op: "remove", Path: path, Err: syscall.EACCES})
	removalErr := store.cleanup(now)
	if removalErr == nil {
		t.Fatal("cleanup unexpectedly succeeded")
	}

	var output bytes.Buffer
	previousOutput := log.Writer()
	previousFlags := log.Flags()
	previousPrefix := log.Prefix()
	log.SetOutput(&output)
	log.SetFlags(0)
	log.SetPrefix("")
	t.Cleanup(func() {
		log.SetOutput(previousOutput)
		log.SetFlags(previousFlags)
		log.SetPrefix(previousPrefix)
	})
	srv := &Server{}
	srv.logRemovalError("logs", "cleanup", removalErr)

	message := output.String()
	if strings.Contains(message, id) || strings.Contains(message, path) {
		t.Fatalf("removal log exposed capability path: %q", message)
	}
	want := fmt.Sprintf("logs: cleanup removal failed: category=permission errno=%d", syscall.EACCES)
	if !strings.Contains(message, want) {
		t.Fatalf("removal log=%q, want sanitized context %q", message, want)
	}
}

// ======================================================================
// End-to-end: rooms survive a process restart
// ======================================================================

func TestSnapshotSurvivesRestartWithHostAuthority(t *testing.T) {
	stateFile := filepath.Join(t.TempDir(), "rooms.json")

	hA := newRelayHarnessAt(t, t.TempDir(), stateFile)
	host := hA.dial(t, "8.0.0.1")
	host.send(clientMsg{Type: relayTypeCreate, SessionID: "RESUM", PeerID: "H"})
	created := host.expectAuthority(relayTypeCreated, "H")

	if err := hA.srv.snap.flushAndStop(2 * time.Second); err != nil {
		t.Fatalf("flushAndStop: %v", err)
	}
	snapshotBytes, err := os.ReadFile(stateFile)
	if err != nil {
		t.Fatalf("read snapshot: %v", err)
	}
	if bytes.Contains(snapshotBytes, []byte(created.ReconnectToken)) {
		t.Fatal("snapshot persisted the raw reconnect capability")
	}
	if !bytes.Contains(snapshotBytes, []byte(`"hostReconnectVerifier"`)) {
		t.Fatalf("snapshot omitted host verifier: %s", snapshotBytes)
	}

	hB := newRelayHarnessAt(t, t.TempDir(), stateFile)
	hB.srv.mu.RLock()
	_, reloaded := hB.srv.rooms["RESUM"]
	hB.srv.mu.RUnlock()
	if !reloaded {
		t.Fatal("room RESUM was not reloaded from snapshot")
	}

	unproved := hB.dial(t, "8.0.0.2")
	unproved.send(clientMsg{Type: relayTypeJoin, SessionID: "RESUM", PeerID: "H"})
	unproved.expectError(relayErrorPeerIdUnavailable)

	reconnected := hB.dial(t, "8.0.0.3")
	reconnected.send(clientMsg{
		Type:           relayTypeJoin,
		SessionID:      "RESUM",
		PeerID:         "H",
		ReconnectToken: created.ReconnectToken,
	})
	joined := reconnected.expectAuthority(relayTypeJoined, "H")
	if joined.ReconnectToken != created.ReconnectToken {
		t.Fatal("restored host capability changed")
	}

	duplicateCreate := hB.dial(t, "8.0.0.4")
	duplicateCreate.send(clientMsg{Type: relayTypeCreate, SessionID: "RESUM", PeerID: "OTHER"})
	duplicateCreate.expectError(relayErrorRoomExists)
}

func TestSnapshotV4RetainsModernHostAndGuestReservationsAcrossRestart(t *testing.T) {
	stateFile := filepath.Join(t.TempDir(), "rooms.json")
	hA := newRelayHarnessAt(t, t.TempDir(), stateFile)

	hostToken, _ := mustReconnectToken(t)
	host := hA.dial(t, "8.0.1.1")
	host.send(clientMsg{
		Type:            relayTypeCreate,
		SessionID:       "V3_RESTART",
		PeerID:          "H",
		ReconnectToken:  hostToken,
		ProtocolVersion: relayProtocolVersion,
	})
	host.expectAuthority(relayTypeCreated, "H")

	guestToken, _ := mustReconnectToken(t)
	guest := hA.dial(t, "8.0.1.2")
	guest.send(clientMsg{
		Type:            relayTypeJoin,
		SessionID:       "V3_RESTART",
		PeerID:          "G",
		ReconnectToken:  guestToken,
		ProtocolVersion: relayProtocolVersion,
	})
	guest.expectAuthority(relayTypeJoined, "H")
	host.expect(relayTypePeerJoined)

	if err := guest.conn.Close(); err != nil {
		t.Fatalf("close guest before snapshot: %v", err)
	}
	left := host.expect(relayTypePeerLeft)
	if left.PeerID != "G" {
		t.Fatalf("pre-snapshot disconnect peerId=%q, want G", left.PeerID)
	}
	if err := hA.srv.snap.flushAndStop(2 * time.Second); err != nil {
		t.Fatalf("flush snapshot v4: %v", err)
	}
	snapshotBytes, err := os.ReadFile(stateFile)
	if err != nil {
		t.Fatalf("read snapshot v4: %v", err)
	}
	if !bytes.Contains(snapshotBytes, []byte(`"version":4`)) ||
		!bytes.Contains(snapshotBytes, []byte(`"peerReservations"`)) {
		t.Fatalf("snapshot omitted v4 guest reservation state: %s", snapshotBytes)
	}
	if bytes.Contains(snapshotBytes, []byte(hostToken)) || bytes.Contains(snapshotBytes, []byte(guestToken)) {
		t.Fatal("snapshot persisted a raw reconnect capability")
	}

	hB := newRelayHarnessAt(t, t.TempDir(), stateFile)
	wrongHostToken, _ := mustReconnectToken(t)
	hostThief := hB.dial(t, "8.0.1.3")
	hostThief.send(clientMsg{
		Type:            relayTypeJoin,
		SessionID:       "V3_RESTART",
		PeerID:          "H",
		ReconnectToken:  wrongHostToken,
		ProtocolVersion: relayProtocolVersion,
	})
	hostThief.expectError(relayErrorPeerIdUnavailable)

	restartedHost := hB.dial(t, "8.0.1.4")
	restartedHost.send(clientMsg{
		Type:            relayTypeJoin,
		SessionID:       "V3_RESTART",
		PeerID:          "H",
		ReconnectToken:  hostToken,
		ProtocolVersion: relayProtocolVersion,
	})
	hostJoined := restartedHost.expectAuthority(relayTypeJoined, "H")
	if hostJoined.ReconnectToken != hostToken || hostJoined.ProtocolVersion != relayProtocolVersion {
		t.Fatalf("restored host authority changed: %+v", hostJoined)
	}

	wrongGuestToken, _ := mustReconnectToken(t)
	guestThief := hB.dial(t, "8.0.1.5")
	guestThief.send(clientMsg{
		Type:            relayTypeJoin,
		SessionID:       "V3_RESTART",
		PeerID:          "G",
		ReconnectToken:  wrongGuestToken,
		ProtocolVersion: relayProtocolVersion,
	})
	guestThief.expectError(relayErrorPeerIdUnavailable)

	restartedGuest := hB.dial(t, "8.0.1.6")
	restartedGuest.send(clientMsg{
		Type:            relayTypeJoin,
		SessionID:       "V3_RESTART",
		PeerID:          "G",
		ReconnectToken:  guestToken,
		ProtocolVersion: relayProtocolVersion,
	})
	guestJoined := restartedGuest.expectAuthority(relayTypeJoined, "H")
	if guestJoined.ReconnectToken != guestToken || guestJoined.ProtocolVersion != relayProtocolVersion {
		t.Fatalf("restored guest authority changed: %+v", guestJoined)
	}
	rejoined := restartedHost.expect(relayTypePeerJoined)
	if rejoined.PeerID != "G" {
		t.Fatalf("restored guest event peerId=%q, want G", rejoined.PeerID)
	}
}

func TestLoadedRoomsConsumeGlobalCapacityWithoutRestoringSourceQuota(t *testing.T) {
	stateFile := filepath.Join(t.TempDir(), "rooms.json")
	now := time.Now().UTC()
	snapshot := stateSnapshot{
		Version: snapshotFormatVersion,
		SavedAt: now,
		Rooms:   makeRoomSnapshots(maxRetainedRooms, false, now),
	}
	data, err := json.Marshal(snapshot)
	if err != nil {
		t.Fatalf("marshal full snapshot: %v", err)
	}
	if err := os.WriteFile(stateFile, data, 0644); err != nil {
		t.Fatalf("write full snapshot: %v", err)
	}

	h := newRelayHarnessAt(t, t.TempDir(), stateFile)
	h.srv.conns.mu.Lock()
	restoredQuotaEntries := len(h.srv.conns.roomsPerIP)
	h.srv.conns.mu.Unlock()
	if restoredQuotaEntries != 0 {
		t.Fatalf("restart restored %d process-local quota entries", restoredQuotaEntries)
	}

	client := h.dial(t, "8.0.0.4")
	client.send(clientMsg{Type: relayTypeCreate, SessionID: "RESTARTOVER", PeerID: "H"})
	client.expectError(relayErrorRateLimited)
	client.send(clientMsg{Type: relayTypeJoin, SessionID: "S0000", PeerID: "G"})
	client.expect(relayTypeJoined)
}
