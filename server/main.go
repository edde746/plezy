package main

import (
	"context"
	"crypto/rand"
	"encoding/json"
	"errors"
	"flag"
	"io"
	"io/fs"
	"log"
	"math/big"
	"net"
	"net/http"
	"os"
	"os/signal"
	"path/filepath"
	"strconv"
	"strings"
	"sync"
	"syscall"
	"time"

	"github.com/gorilla/websocket"
)

const (
	maxRoomSize        = 8
	rateBurst          = 30
	rateSustained      = 10
	cleanupInterval    = 5 * time.Minute
	emptyRoomMaxAge    = 5 * time.Minute
	roomMaxAge         = 24 * time.Hour
	writeWait          = 10 * time.Second
	pongWait           = 60 * time.Second
	pingInterval       = 30 * time.Second
	maxMessageSize     = 64 * 1024
	maxLogSize         = 1 * 1024 * 1024 // 1MB
	logMaxAge          = 3 * 24 * time.Hour
	logIDLength        = 5
	logRateInterval    = 1 * time.Minute
	maxLogEntries      = 500
	maxConnsPerIP      = 5
	maxGlobalConns     = 100
	maxRoomsPerIP      = 3
	connRateBurst      = 5
	connRateSustained  = 1

	snapshotFormatVersion = 1
	snapshotDebounce      = 100 * time.Millisecond
	snapshotFlushTimeout  = 5 * time.Second
	snapshotMaxFileSize   = 1 * 1024 * 1024
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin:     func(r *http.Request) bool { return true },
}

// --- Rate limiter (token bucket) ---

type rateLimiter struct {
	tokens    float64
	maxTokens float64
	refillRate float64
	lastTime  time.Time
	mu        sync.Mutex
}

func newRateLimiter(burst, sustained int) *rateLimiter {
	return &rateLimiter{
		tokens:    float64(burst),
		maxTokens: float64(burst),
		refillRate: float64(sustained),
		lastTime:  time.Now(),
	}
}

func (rl *rateLimiter) allow() bool {
	rl.mu.Lock()
	defer rl.mu.Unlock()

	now := time.Now()
	elapsed := now.Sub(rl.lastTime).Seconds()
	rl.lastTime = now

	rl.tokens += elapsed * rl.refillRate
	if rl.tokens > rl.maxTokens {
		rl.tokens = rl.maxTokens
	}

	if rl.tokens < 1 {
		return false
	}
	rl.tokens--
	return true
}

// --- Connection tracker (per-IP limits) ---

type connTracker struct {
	mu          sync.Mutex
	perIP       map[string]int
	ipRate      map[string]*rateLimiter
	roomsPerIP  map[string]int
	globalCount int
}

func newConnTracker() *connTracker {
	return &connTracker{
		perIP:      make(map[string]int),
		ipRate:     make(map[string]*rateLimiter),
		roomsPerIP: make(map[string]int),
	}
}

func (ct *connTracker) tryConnect(ip string) bool {
	ct.mu.Lock()
	defer ct.mu.Unlock()

	if ct.globalCount >= maxGlobalConns {
		return false
	}
	if ct.perIP[ip] >= maxConnsPerIP {
		return false
	}

	rl, ok := ct.ipRate[ip]
	if !ok {
		rl = newRateLimiter(connRateBurst, connRateSustained)
		ct.ipRate[ip] = rl
	}
	// Unlock ct.mu before calling rl.allow() would be cleaner,
	// but since rl has its own mutex this is safe (no deadlock).
	if !rl.allow() {
		return false
	}

	ct.perIP[ip]++
	ct.globalCount++
	return true
}

func (ct *connTracker) disconnect(ip string) {
	ct.mu.Lock()
	defer ct.mu.Unlock()

	if ct.perIP[ip] > 0 {
		ct.perIP[ip]--
		ct.globalCount--
	}
	if ct.perIP[ip] == 0 {
		delete(ct.perIP, ip)
	}
}

func (ct *connTracker) tryCreateRoom(ip string) bool {
	ct.mu.Lock()
	defer ct.mu.Unlock()
	if ct.roomsPerIP[ip] >= maxRoomsPerIP {
		return false
	}
	ct.roomsPerIP[ip]++
	return true
}

func (ct *connTracker) releaseRoom(ip string) {
	ct.mu.Lock()
	defer ct.mu.Unlock()
	if ct.roomsPerIP[ip] > 0 {
		ct.roomsPerIP[ip]--
	}
	if ct.roomsPerIP[ip] == 0 {
		delete(ct.roomsPerIP, ip)
	}
}

func (ct *connTracker) cleanup() {
	ct.mu.Lock()
	defer ct.mu.Unlock()
	for ip := range ct.ipRate {
		if ct.perIP[ip] == 0 {
			delete(ct.ipRate, ip)
		}
	}
}

// --- Messages ---

type clientMsg struct {
	Type      string          `json:"type"`
	SessionID string          `json:"sessionId,omitempty"`
	PeerID    string          `json:"peerId,omitempty"`
	To        string          `json:"to,omitempty"`
	Payload   json.RawMessage `json:"payload,omitempty"`
}

type serverMsg struct {
	Type      string          `json:"type"`
	SessionID string          `json:"sessionId,omitempty"`
	PeerID    string          `json:"peerId,omitempty"`
	From      string          `json:"from,omitempty"`
	Peers     []string        `json:"peers,omitempty"`
	Code      string          `json:"code,omitempty"`
	Message   string          `json:"message,omitempty"`
	Payload   json.RawMessage `json:"payload,omitempty"`
}

// --- Client (serializes writes to a single goroutine) ---

type Client struct {
	conn *websocket.Conn
	send chan []byte
	done chan struct{}
}

func newClient(conn *websocket.Conn) *Client {
	c := &Client{conn: conn, send: make(chan []byte, 64), done: make(chan struct{})}
	go c.writePump()
	return c
}

func (c *Client) writePump() {
	ticker := time.NewTicker(pingInterval)
	defer ticker.Stop()
	for {
		select {
		case data := <-c.send:
			c.conn.SetWriteDeadline(time.Now().Add(writeWait))
			c.conn.WriteMessage(websocket.TextMessage, data)
		case <-c.done:
			c.conn.WriteMessage(websocket.CloseMessage, nil)
			return
		case <-ticker.C:
			c.conn.SetWriteDeadline(time.Now().Add(writeWait))
			if err := c.conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}

func (c *Client) trySend(data []byte) {
	select {
	case c.send <- data:
	case <-c.done:
	default:
	}
}

func (c *Client) sendJSON(msg serverMsg) {
	data, err := json.Marshal(msg)
	if err != nil {
		return
	}
	c.trySend(data)
}

func (c *Client) close() {
	close(c.done)
}

// --- Room ---

type Room struct {
	SessionID      string
	HostPeerID     string
	Peers          map[string]*Client `json:"-"`
	mu             sync.RWMutex       `json:"-"`
	CreatedAt      time.Time
	LastActivityAt time.Time
}

// --- Snapshot types (on-disk JSON format) ---

type roomSnapshot struct {
	SessionID      string    `json:"sessionId"`
	HostPeerID     string    `json:"hostPeerId"`
	CreatedAt      time.Time `json:"createdAt"`
	LastActivityAt time.Time `json:"lastActivityAt"`
}

type stateSnapshot struct {
	Version int            `json:"version"`
	SavedAt time.Time      `json:"savedAt"`
	Rooms   []roomSnapshot `json:"rooms"`
}

func (r *Room) peerIDs() []string {
	ids := make([]string, 0, len(r.Peers))
	for id := range r.Peers {
		ids = append(ids, id)
	}
	return ids
}

func (r *Room) broadcastExcept(senderID string, msg serverMsg) {
	data, err := json.Marshal(msg)
	if err != nil {
		return
	}
	// Copy peers under lock, then send without holding it
	r.mu.RLock()
	targets := make([]*Client, 0, len(r.Peers))
	for id, client := range r.Peers {
		if id != senderID {
			targets = append(targets, client)
		}
	}
	r.mu.RUnlock()

	for _, client := range targets {
		client.trySend(data)
	}
}

func (r *Room) sendTo(targetID string, msg serverMsg) bool {
	data, err := json.Marshal(msg)
	if err != nil {
		return false
	}
	r.mu.RLock()
	client, ok := r.Peers[targetID]
	r.mu.RUnlock()
	if !ok {
		return false
	}
	client.trySend(data)
	return true
}

// --- Log store ---

type logEntry struct {
	Size      int
	ExpiresAt time.Time
}

type logStore struct {
	entries   map[string]logEntry
	rateLimit map[string]time.Time // IP -> last upload time
	dir       string
	mu        sync.RWMutex
}

func newLogStore(dir string) *logStore {
	if err := os.MkdirAll(dir, 0755); err != nil {
		log.Fatalf("failed to create log dir %s: %v", dir, err)
	}
	ls := &logStore{
		entries:   make(map[string]logEntry),
		rateLimit: make(map[string]time.Time),
		dir:       dir,
	}
	// Clean orphaned files from prior runs
	files, _ := os.ReadDir(dir)
	for _, f := range files {
		os.Remove(filepath.Join(dir, f.Name()))
	}
	return ls
}

func (ls *logStore) filePath(id string) string {
	return filepath.Join(ls.dir, id+".log")
}

const logIDChars = "abcdefghijklmnopqrstuvwxyz0123456789"

func generateLogID() string {
	b := make([]byte, logIDLength)
	for i := range b {
		n, _ := rand.Int(rand.Reader, big.NewInt(int64(len(logIDChars))))
		b[i] = logIDChars[n.Int64()]
	}
	return string(b)
}

func (ls *logStore) cleanup() {
	ls.mu.Lock()
	defer ls.mu.Unlock()
	now := time.Now()
	for id, entry := range ls.entries {
		if now.After(entry.ExpiresAt) {
			os.Remove(ls.filePath(id))
			delete(ls.entries, id)
		}
	}
	for ip, lastTime := range ls.rateLimit {
		if now.Sub(lastTime) > logRateInterval {
			delete(ls.rateLimit, ip)
		}
	}
}

// --- Snapshotter (single-writer, debounced, atomic disk persistence) ---

type snapshotter struct {
	path     string
	dir      string
	trigger  chan struct{}
	flush    chan chan error
	done     chan struct{}
	exited   chan struct{}
	build    func() stateSnapshot
	writeMu  sync.Mutex
	stopOnce sync.Once

	errMu      sync.Mutex
	lastErrLog time.Time
}

func newSnapshotter(path string, build func() stateSnapshot) *snapshotter {
	dir := filepath.Dir(path)
	if err := os.MkdirAll(dir, 0755); err != nil {
		log.Printf("snapshot: mkdir %s: %v", dir, err)
	}
	return &snapshotter{
		path:    path,
		dir:     dir,
		trigger: make(chan struct{}, 1),
		flush:   make(chan chan error),
		done:    make(chan struct{}),
		exited:  make(chan struct{}),
		build:   build,
	}
}

func (sn *snapshotter) schedule() {
	select {
	case sn.trigger <- struct{}{}:
	default:
	}
}

func (sn *snapshotter) run() {
	defer close(sn.exited)
	for {
		select {
		case <-sn.trigger:
			time.Sleep(snapshotDebounce)
			// Drain triggers that piled up during the sleep window.
			select {
			case <-sn.trigger:
			default:
			}
			sn.writeAndLog()
		case reply := <-sn.flush:
			reply <- sn.writeAndLog()
		case <-sn.done:
			// flushAndStop is the expected caller and has already written.
			return
		}
	}
}

func (sn *snapshotter) writeAndLog() error {
	err := sn.write()
	if err != nil {
		sn.logWriteErr(err)
	}
	return err
}

func (sn *snapshotter) write() error {
	sn.writeMu.Lock()
	defer sn.writeMu.Unlock()

	data, err := json.Marshal(sn.build())
	if err != nil {
		return err
	}

	tmpPath := sn.path + ".tmp"
	f, err := os.OpenFile(tmpPath, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, 0644)
	if err != nil {
		return err
	}
	if _, err := f.Write(data); err != nil {
		f.Close()
		os.Remove(tmpPath)
		return err
	}
	if err := f.Sync(); err != nil {
		f.Close()
		os.Remove(tmpPath)
		return err
	}
	if err := f.Close(); err != nil {
		os.Remove(tmpPath)
		return err
	}
	if err := os.Rename(tmpPath, sn.path); err != nil {
		os.Remove(tmpPath)
		return err
	}
	// Best-effort dir fsync so the rename is durable after host crash.
	if d, err := os.Open(sn.dir); err == nil {
		d.Sync()
		d.Close()
	}
	return nil
}

func (sn *snapshotter) flushAndStop(timeout time.Duration) error {
	var result error
	sn.stopOnce.Do(func() {
		ctx, cancel := context.WithTimeout(context.Background(), timeout)
		defer cancel()
		reply := make(chan error, 1)
		select {
		case sn.flush <- reply:
		case <-ctx.Done():
			result = errors.New("snapshot flush: timed out sending flush signal")
			return
		}
		select {
		case result = <-reply:
		case <-ctx.Done():
			result = errors.New("snapshot flush: timed out waiting for write")
			return
		}
		close(sn.done)
		select {
		case <-sn.exited:
		case <-ctx.Done():
		}
	})
	return result
}

// logWriteErr throttles snapshot-write error spam to at most once per hour.
func (sn *snapshotter) logWriteErr(err error) {
	sn.errMu.Lock()
	defer sn.errMu.Unlock()
	if time.Since(sn.lastErrLog) < time.Hour {
		return
	}
	sn.lastErrLog = time.Now()
	log.Printf("snapshot: write failed: %v", err)
}

// --- Server ---

type Server struct {
	rooms map[string]*Room
	logs  *logStore
	conns *connTracker
	snap  *snapshotter
	mu    sync.RWMutex
}

func newServer(logDir, stateFile string) *Server {
	s := &Server{rooms: make(map[string]*Room), logs: newLogStore(logDir), conns: newConnTracker()}
	s.snap = newSnapshotter(stateFile, s.buildSnapshot)
	if err := s.loadSnapshot(stateFile); err != nil {
		log.Printf("snapshot: load error: %v", err)
	}
	go s.snap.run()
	go s.cleanupLoop()
	return s
}

// buildSnapshot copies room identity into a serializable value with no locks held during marshal.
// Lock order: s.mu before room.mu, matching cleanupLoop.
func (s *Server) buildSnapshot() stateSnapshot {
	s.mu.RLock()
	defer s.mu.RUnlock()
	snap := stateSnapshot{
		Version: snapshotFormatVersion,
		SavedAt: time.Now(),
		Rooms:   make([]roomSnapshot, 0, len(s.rooms)),
	}
	for _, room := range s.rooms {
		room.mu.RLock()
		snap.Rooms = append(snap.Rooms, roomSnapshot{
			SessionID:      room.SessionID,
			HostPeerID:     room.HostPeerID,
			CreatedAt:      room.CreatedAt,
			LastActivityAt: room.LastActivityAt,
		})
		room.mu.RUnlock()
	}
	return snap
}

// loadSnapshot restores rooms from disk on startup. Missing/corrupt files log
// and return nil so the server always starts; only unexpected I/O paths bubble up.
func (s *Server) loadSnapshot(path string) error {
	data, err := os.ReadFile(path)
	if err != nil {
		if errors.Is(err, fs.ErrNotExist) {
			log.Printf("snapshot: no file at %s, starting fresh", path)
			return nil
		}
		log.Printf("snapshot: read error, starting fresh: %v", err)
		return nil
	}
	if len(data) > snapshotMaxFileSize {
		log.Printf("snapshot: file too large (%d bytes), starting fresh", len(data))
		return nil
	}
	var snap stateSnapshot
	if err := json.Unmarshal(data, &snap); err != nil {
		log.Printf("snapshot: corrupt file at %s, starting fresh: %v", path, err)
		return nil
	}
	if snap.Version != snapshotFormatVersion {
		log.Printf("snapshot: unknown version %d, starting fresh", snap.Version)
		return nil
	}
	now := time.Now()
	loaded, skipped := 0, 0
	s.mu.Lock()
	for _, r := range snap.Rooms {
		if r.SessionID == "" || r.HostPeerID == "" {
			skipped++
			continue
		}
		if now.Sub(r.CreatedAt) > roomMaxAge {
			skipped++
			continue
		}
		if now.Sub(r.LastActivityAt) > emptyRoomMaxAge {
			skipped++
			continue
		}
		s.rooms[r.SessionID] = &Room{
			SessionID:      r.SessionID,
			HostPeerID:     r.HostPeerID,
			Peers:          make(map[string]*Client),
			CreatedAt:      r.CreatedAt,
			LastActivityAt: r.LastActivityAt,
		}
		loaded++
	}
	s.mu.Unlock()
	log.Printf("snapshot: loaded %d rooms, skipped %d expired", loaded, skipped)
	return nil
}

func (s *Server) cleanupLoop() {
	ticker := time.NewTicker(cleanupInterval)
	defer ticker.Stop()
	for range ticker.C {
		s.runCleanupStep(time.Now())
	}
}

func (s *Server) runCleanupStep(now time.Time) {
	s.mu.Lock()
	changed := false
	for id, room := range s.rooms {
		room.mu.RLock()
		empty := len(room.Peers) == 0
		age := now.Sub(room.CreatedAt)
		idle := now.Sub(room.LastActivityAt)
		room.mu.RUnlock()

		if (empty && idle > emptyRoomMaxAge) || age > roomMaxAge {
			log.Printf("cleanup: removing room %s (empty=%v, idle=%v, age=%v)", id, empty, idle, age)
			delete(s.rooms, id)
			changed = true
		}
	}
	s.mu.Unlock()
	if changed {
		s.snap.schedule()
	}
	s.logs.cleanup()
	s.conns.cleanup()

	s.conns.mu.Lock()
	log.Printf("stats: conns=%d ips=%d rooms=%d",
		s.conns.globalCount, len(s.conns.perIP), len(s.rooms))
	s.conns.mu.Unlock()
}

func clientIP(r *http.Request) string {
	var raw string
	if fwd := r.Header.Get("X-Forwarded-For"); fwd != "" {
		raw = strings.TrimSpace(strings.SplitN(fwd, ",", 2)[0])
	} else {
		host, _, err := net.SplitHostPort(r.RemoteAddr)
		if err != nil {
			raw = r.RemoteAddr
		} else {
			raw = host
		}
	}
	// Normalize IPv6 to /64 prefix to prevent per-address bypass
	ip := net.ParseIP(raw)
	if ip != nil && ip.To4() == nil {
		mask := net.CIDRMask(64, 128)
		return ip.Mask(mask).String()
	}
	return raw
}

func (s *Server) handlePostLogs(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	ip := clientIP(r)
	s.logs.mu.Lock()
	if last, ok := s.logs.rateLimit[ip]; ok && time.Since(last) < logRateInterval {
		s.logs.mu.Unlock()
		http.Error(w, "Rate limited: 1 upload per minute", http.StatusTooManyRequests)
		return
	}
	s.logs.rateLimit[ip] = time.Now()
	s.logs.mu.Unlock()

	body, err := io.ReadAll(io.LimitReader(r.Body, maxLogSize+1))
	if err != nil {
		http.Error(w, "Failed to read body", http.StatusBadRequest)
		return
	}
	if len(body) > maxLogSize {
		http.Error(w, "Log too large (max 1MB)", http.StatusRequestEntityTooLarge)
		return
	}
	if len(body) == 0 {
		http.Error(w, "Empty body", http.StatusBadRequest)
		return
	}

	s.logs.mu.Lock()
	if len(s.logs.entries) >= maxLogEntries {
		s.logs.mu.Unlock()
		http.Error(w, "Log store full", http.StatusServiceUnavailable)
		return
	}
	s.logs.mu.Unlock()

	id := generateLogID()
	if err := os.WriteFile(s.logs.filePath(id), body, 0644); err != nil {
		log.Printf("logs: failed to write %s: %v", id, err)
		http.Error(w, "Failed to store log", http.StatusInternalServerError)
		return
	}

	s.logs.mu.Lock()
	s.logs.entries[id] = logEntry{
		Size:      len(body),
		ExpiresAt: time.Now().Add(logMaxAge),
	}
	s.logs.mu.Unlock()

	log.Printf("logs: stored %s (%d bytes) from %s", id, len(body), ip)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"id": id})
}

func (s *Server) handleGetLogs(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	id := strings.TrimPrefix(r.URL.Path, "/logs/")
	if id == "" || len(id) != logIDLength {
		http.Error(w, "Not found", http.StatusNotFound)
		return
	}

	s.logs.mu.RLock()
	entry, ok := s.logs.entries[id]
	s.logs.mu.RUnlock()

	if !ok || time.Now().After(entry.ExpiresAt) {
		http.Error(w, "Not found", http.StatusNotFound)
		return
	}

	data, err := os.ReadFile(s.logs.filePath(id))
	if err != nil {
		http.Error(w, "Not found", http.StatusNotFound)
		return
	}

	w.Header().Set("Content-Type", "text/plain; charset=utf-8")
	w.Header().Set("Content-Length", strconv.Itoa(entry.Size))
	w.Write(data)
}

func (s *Server) handleWS(w http.ResponseWriter, r *http.Request) {
	ip := clientIP(r)

	if !s.conns.tryConnect(ip) {
		http.Error(w, "Too many connections", http.StatusTooManyRequests)
		return
	}
	defer s.conns.disconnect(ip)

	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Printf("upgrade error: %v", err)
		return
	}
	defer conn.Close()

	conn.SetReadLimit(maxMessageSize)
	conn.SetReadDeadline(time.Now().Add(pongWait))
	conn.SetPongHandler(func(string) error {
		conn.SetReadDeadline(time.Now().Add(pongWait))
		return nil
	})

	// Client wraps the conn with a serialized write channel + ping ticker
	client := newClient(conn)
	defer client.close()

	rl := newRateLimiter(rateBurst, rateSustained)
	var currentRoom *Room
	var currentPeerID string
	var isHost bool

	// Cleanup on disconnect — only if our Client is still the one in the room.
	// A reconnecting peer reuses the same peerId, so the map entry may have
	// been overwritten by a newer Client before this defer runs.
	defer func() {
		if currentRoom != nil && currentPeerID != "" {
			currentRoom.mu.Lock()
			stale := currentRoom.Peers[currentPeerID] != client
			if !stale {
				delete(currentRoom.Peers, currentPeerID)
				currentRoom.LastActivityAt = time.Now()
			}
			currentRoom.mu.Unlock()
			if !stale {
				currentRoom.broadcastExcept(currentPeerID, serverMsg{
					Type:   "peerLeft",
					PeerID: currentPeerID,
				})
				s.snap.schedule()
			}
			if isHost {
				s.conns.releaseRoom(ip)
			}
			log.Printf("peer %s left room %s (stale=%v)", currentPeerID, currentRoom.SessionID, stale)
		}
	}()

	for {
		_, raw, err := conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseNormalClosure) {
				log.Printf("read error: %v", err)
			}
			return
		}

		if !rl.allow() {
			client.sendJSON(serverMsg{Type: "error", Code: "rate_limited", Message: "Too many messages"})
			continue
		}

		var msg clientMsg
		if err := json.Unmarshal(raw, &msg); err != nil {
			client.sendJSON(serverMsg{Type: "error", Code: "invalid_message", Message: "Invalid JSON"})
			continue
		}

		switch msg.Type {
		case "create":
			if msg.SessionID == "" || msg.PeerID == "" {
				client.sendJSON(serverMsg{Type: "error", Code: "invalid_message", Message: "sessionId and peerId required"})
				continue
			}
			if !s.conns.tryCreateRoom(ip) {
				client.sendJSON(serverMsg{Type: "error", Code: "rate_limited", Message: "Too many rooms created"})
				continue
			}
			s.mu.Lock()
			if existing, exists := s.rooms[msg.SessionID]; exists {
				existing.mu.RLock()
				empty := len(existing.Peers) == 0
				existing.mu.RUnlock()
				if !empty {
					s.mu.Unlock()
					s.conns.releaseRoom(ip)
					client.sendJSON(serverMsg{Type: "error", Code: "room_exists", Message: "Room already exists"})
					continue
				}
				// Empty stale room — reclaim the ID
				delete(s.rooms, msg.SessionID)
			}
			now := time.Now()
			room := &Room{
				SessionID:      msg.SessionID,
				HostPeerID:     msg.PeerID,
				Peers:          map[string]*Client{msg.PeerID: client},
				CreatedAt:      now,
				LastActivityAt: now,
			}
			s.rooms[msg.SessionID] = room
			s.mu.Unlock()
			currentRoom = room
			currentPeerID = msg.PeerID
			isHost = true
			log.Printf("room %s created by %s", msg.SessionID, msg.PeerID)
			client.sendJSON(serverMsg{Type: "created", SessionID: msg.SessionID})
			s.snap.schedule()

		case "join":
			if msg.SessionID == "" || msg.PeerID == "" {
				client.sendJSON(serverMsg{Type: "error", Code: "invalid_message", Message: "sessionId and peerId required"})
				continue
			}
			s.mu.RLock()
			room, exists := s.rooms[msg.SessionID]
			s.mu.RUnlock()
			if !exists {
				client.sendJSON(serverMsg{Type: "error", Code: "room_not_found", Message: "Room does not exist"})
				continue
			}
			room.mu.Lock()
			if len(room.Peers) >= maxRoomSize {
				room.mu.Unlock()
				client.sendJSON(serverMsg{Type: "error", Code: "room_full", Message: "Room is full"})
				continue
			}
			room.Peers[msg.PeerID] = client
			room.LastActivityAt = time.Now()
			peers := room.peerIDs()
			room.mu.Unlock()
			currentRoom = room
			currentPeerID = msg.PeerID
			log.Printf("peer %s joined room %s", msg.PeerID, msg.SessionID)

			// Tell the joiner who's already here (excluding themselves)
			existingPeers := make([]string, 0, len(peers)-1)
			for _, p := range peers {
				if p != msg.PeerID {
					existingPeers = append(existingPeers, p)
				}
			}
			client.sendJSON(serverMsg{Type: "joined", SessionID: msg.SessionID, Peers: existingPeers})
			room.broadcastExcept(msg.PeerID, serverMsg{Type: "peerJoined", PeerID: msg.PeerID})
			s.snap.schedule()

		case "broadcast":
			if currentRoom == nil {
				client.sendJSON(serverMsg{Type: "error", Code: "not_in_room", Message: "Not in a room"})
				continue
			}
			currentRoom.broadcastExcept(currentPeerID, serverMsg{
				Type:    "message",
				From:    currentPeerID,
				Payload: msg.Payload,
			})

		case "sendTo":
			if currentRoom == nil {
				client.sendJSON(serverMsg{Type: "error", Code: "not_in_room", Message: "Not in a room"})
				continue
			}
			if msg.To == "" {
				client.sendJSON(serverMsg{Type: "error", Code: "invalid_message", Message: "to field required"})
				continue
			}
			if !currentRoom.sendTo(msg.To, serverMsg{
				Type:    "message",
				From:    currentPeerID,
				Payload: msg.Payload,
			}) {
				client.sendJSON(serverMsg{Type: "error", Code: "not_in_room", Message: "Target peer not found"})
			}

		case "ping":
			client.sendJSON(serverMsg{Type: "pong"})

		default:
			client.sendJSON(serverMsg{Type: "error", Code: "invalid_message", Message: "Unknown message type"})
		}
	}
}

func main() {
	addr := flag.String("addr", ":8080", "Listen address")
	logDir := flag.String("log-dir", "/data/logs", "Directory for log file storage")
	stateFile := flag.String("state-file", "/data/rooms.json", "Path to room snapshot file")
	flag.Parse()

	srv := newServer(*logDir, *stateFile)

	mux := http.NewServeMux()
	mux.HandleFunc("/relay", srv.handleWS)
	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("ok"))
	})
	mux.HandleFunc("/logs", srv.handlePostLogs)
	mux.HandleFunc("/logs/", srv.handleGetLogs)

	httpSrv := &http.Server{Addr: *addr, Handler: mux}

	serveErr := make(chan error, 1)
	go func() {
		log.Printf("Starting relay server on %s", *addr)
		if err := httpSrv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			serveErr <- err
		}
		close(serveErr)
	}()

	sig := make(chan os.Signal, 1)
	signal.Notify(sig, syscall.SIGINT, syscall.SIGTERM)

	select {
	case err, ok := <-serveErr:
		if ok {
			log.Fatalf("listen: %v", err)
		}
	case s := <-sig:
		log.Printf("shutdown signal received (%s), draining...", s)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := httpSrv.Shutdown(ctx); err != nil {
		log.Printf("http shutdown: %v", err)
	}
	if err := srv.snap.flushAndStop(snapshotFlushTimeout); err != nil {
		log.Printf("snapshot flush: %v", err)
	}
	log.Printf("shutdown complete")
}
