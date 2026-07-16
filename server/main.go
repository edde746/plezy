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
	rateBurst          = 30
	rateSustained      = 10
	cleanupInterval    = 5 * time.Minute
	emptyRoomMaxAge    = 5 * time.Minute
	roomMaxAge         = 24 * time.Hour
	writeWait          = 10 * time.Second
	pongWait           = 60 * time.Second
	pingInterval       = 30 * time.Second
	maxLogSize         = 1 * 1024 * 1024 // 1MB
	logMaxAge          = 3 * 24 * time.Hour
	logIDLength        = 5
	logRateInterval    = 1 * time.Minute
	maxLogEntries      = 500
	maxPosterSize      = 5 * 1024 * 1024 // 5MB
	maxPosterStoreSize = int64(1 * 1024 * 1024 * 1024)
	posterMaxAge       = 3 * time.Hour
	posterIDLength     = 16
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
	conn      *websocket.Conn
	send      chan []byte
	done      chan struct{}
	closeOnce sync.Once
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
	c.closeOnce.Do(func() {
		close(c.done)
		_ = c.conn.Close()
	})
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
	// Copy peers and record activity under lock, then send without holding it.
	r.mu.Lock()
	targets := make([]*Client, 0, len(r.Peers))
	r.LastActivityAt = time.Now()
	for id, client := range r.Peers {
		if id != senderID {
			targets = append(targets, client)
		}
	}
	r.mu.Unlock()

	for _, client := range targets {
		client.trySend(data)
	}
}

func (r *Room) sendTo(targetID string, msg serverMsg) bool {
	data, err := json.Marshal(msg)
	if err != nil {
		return false
	}
	r.mu.Lock()
	client, ok := r.Peers[targetID]
	if ok {
		r.LastActivityAt = time.Now()
	}
	r.mu.Unlock()
	if !ok {
		return false
	}
	client.trySend(data)
	return true
}

// --- Log store ---

type logEntry struct {
	Size      int
	CreatedAt time.Time
	ExpiresAt time.Time
}

var errLogStoreFull = errors.New("log store full")

type logStore struct {
	entries    map[string]logEntry
	rateLimit  map[string]time.Time // IP -> last upload time
	dir        string
	generateID func() string
	mu         sync.RWMutex
}

func newLogStore(dir string) *logStore {
	if err := os.MkdirAll(dir, 0755); err != nil {
		log.Fatalf("failed to create log dir %s: %v", dir, err)
	}
	ls := &logStore{
		entries:    make(map[string]logEntry),
		rateLimit:  make(map[string]time.Time),
		dir:        dir,
		generateID: generateLogID,
	}
	ls.loadExisting(time.Now())
	return ls
}

func (ls *logStore) filePath(id string) string {
	return filepath.Join(ls.dir, id+".log")
}

const idChars = "abcdefghijklmnopqrstuvwxyz0123456789"

func generateID(length int) string {
	b := make([]byte, length)
	for i := range b {
		n, _ := rand.Int(rand.Reader, big.NewInt(int64(len(idChars))))
		b[i] = idChars[n.Int64()]
	}
	return string(b)
}

func generateLogID() string {
	return generateID(logIDLength)
}

func logIDFromFilename(filename string) (string, bool) {
	if filepath.Ext(filename) != ".log" {
		return "", false
	}
	id := strings.TrimSuffix(filename, ".log")
	return id, validID(id, logIDLength)
}

func (ls *logStore) loadExisting(now time.Time) {
	ls.mu.Lock()
	defer ls.mu.Unlock()

	files, err := os.ReadDir(ls.dir)
	if err != nil {
		log.Printf("logs: failed to read dir %s: %v", ls.dir, err)
		return
	}
	for _, file := range files {
		filename := file.Name()
		path := filepath.Join(ls.dir, filename)
		if file.IsDir() || strings.HasSuffix(filename, ".tmp") {
			os.RemoveAll(path)
			continue
		}
		id, ok := logIDFromFilename(filename)
		if !ok {
			os.Remove(path)
			continue
		}
		info, err := file.Info()
		if err != nil || info.Size() <= 0 || info.Size() > maxLogSize {
			os.Remove(path)
			continue
		}
		createdAt := info.ModTime()
		expiresAt := createdAt.Add(logMaxAge)
		if !now.Before(expiresAt) {
			os.Remove(path)
			continue
		}
		ls.entries[id] = logEntry{
			Size:      int(info.Size()),
			CreatedAt: createdAt,
			ExpiresAt: expiresAt,
		}
	}
	ls.evictOldestLocked(maxLogEntries)
}

func (ls *logStore) store(data []byte, now time.Time) (string, logEntry, error) {
	if len(data) == 0 {
		return "", logEntry{}, errors.New("empty log")
	}
	if len(data) > maxLogSize {
		return "", logEntry{}, errors.New("log too large")
	}

	ls.mu.Lock()
	defer ls.mu.Unlock()
	ls.cleanupExpiredLocked(now)
	if len(ls.entries) >= maxLogEntries {
		return "", logEntry{}, errLogStoreFull
	}

	id := ls.generateID()
	for {
		if _, exists := ls.entries[id]; !exists {
			if _, err := os.Stat(ls.filePath(id)); errors.Is(err, fs.ErrNotExist) {
				break
			}
		}
		id = ls.generateID()
	}

	path := ls.filePath(id)
	tmpPath := path + ".tmp"
	if err := os.WriteFile(tmpPath, data, 0644); err != nil {
		os.Remove(tmpPath)
		return "", logEntry{}, err
	}
	if err := os.Rename(tmpPath, path); err != nil {
		os.Remove(tmpPath)
		return "", logEntry{}, err
	}
	_ = os.Chtimes(path, now, now)

	entry := logEntry{
		Size:      len(data),
		CreatedAt: now,
		ExpiresAt: now.Add(logMaxAge),
	}
	ls.entries[id] = entry
	return id, entry, nil
}

func (ls *logStore) lookup(id string, now time.Time) (logEntry, bool) {
	if !validID(id, logIDLength) {
		return logEntry{}, false
	}
	ls.mu.Lock()
	defer ls.mu.Unlock()
	entry, ok := ls.entries[id]
	if !ok {
		return logEntry{}, false
	}
	if !now.Before(entry.ExpiresAt) {
		ls.deleteEntryLocked(id)
		return logEntry{}, false
	}
	return entry, true
}

func (ls *logStore) cleanupExpiredLocked(now time.Time) {
	for id, entry := range ls.entries {
		if !now.Before(entry.ExpiresAt) {
			ls.deleteEntryLocked(id)
		}
	}
}

func (ls *logStore) evictOldestLocked(limit int) {
	for len(ls.entries) > limit {
		var oldestID string
		var oldest logEntry
		for id, entry := range ls.entries {
			if oldestID == "" || entry.CreatedAt.Before(oldest.CreatedAt) {
				oldestID = id
				oldest = entry
			}
		}
		if oldestID == "" {
			return
		}
		ls.deleteEntryLocked(oldestID)
	}
}

func (ls *logStore) deleteEntryLocked(id string) {
	os.Remove(ls.filePath(id))
	delete(ls.entries, id)
}

func (ls *logStore) cleanup() {
	ls.mu.Lock()
	defer ls.mu.Unlock()
	now := time.Now()
	ls.cleanupExpiredLocked(now)
	cleanupRateWindows(ls.rateLimit, now, logRateInterval)
}

// --- Poster store ---

type posterEntry struct {
	Filename    string
	Size        int64
	ContentType string
	CreatedAt   time.Time
	ExpiresAt   time.Time
}

type posterStore struct {
	entries    map[string]posterEntry
	dir        string
	maxBytes   int64
	maxAge     time.Duration
	totalBytes int64
	mu         sync.RWMutex
}

func newPosterStore(dir string, maxBytes int64, maxAge time.Duration) *posterStore {
	if err := os.MkdirAll(dir, 0755); err != nil {
		log.Fatalf("failed to create poster dir %s: %v", dir, err)
	}
	ps := &posterStore{
		entries:  make(map[string]posterEntry),
		dir:      dir,
		maxBytes: maxBytes,
		maxAge:   maxAge,
	}
	ps.loadExisting(time.Now())
	return ps
}

func (ps *posterStore) filePath(filename string) string {
	return filepath.Join(ps.dir, filename)
}

func generatePosterID() string {
	return generateID(posterIDLength)
}

func posterExtForContentType(contentType string) (string, bool) {
	switch strings.ToLower(strings.SplitN(contentType, ";", 2)[0]) {
	case "image/jpeg":
		return ".jpg", true
	case "image/png":
		return ".png", true
	case "image/gif":
		return ".gif", true
	case "image/webp":
		return ".webp", true
	default:
		return "", false
	}
}

func posterContentTypeForExt(ext string) (string, bool) {
	switch strings.ToLower(ext) {
	case ".jpg", ".jpeg":
		return "image/jpeg", true
	case ".png":
		return "image/png", true
	case ".gif":
		return "image/gif", true
	case ".webp":
		return "image/webp", true
	default:
		return "", false
	}
}

func validID(id string, length int) bool {
	if len(id) != length {
		return false
	}
	for _, ch := range id {
		if !strings.ContainsRune(idChars, ch) {
			return false
		}
	}
	return true
}

func posterIDFromFilename(filename string) (string, bool) {
	if filename == "" || strings.ContainsAny(filename, `/\\`) {
		return "", false
	}
	ext := filepath.Ext(filename)
	if _, ok := posterContentTypeForExt(ext); !ok {
		return "", false
	}
	id := strings.TrimSuffix(filename, ext)
	if !validID(id, posterIDLength) {
		return "", false
	}
	return id, true
}

func (ps *posterStore) loadExisting(now time.Time) {
	ps.mu.Lock()
	defer ps.mu.Unlock()

	files, err := os.ReadDir(ps.dir)
	if err != nil {
		log.Printf("posters: failed to read dir %s: %v", ps.dir, err)
		return
	}
	for _, f := range files {
		filename := f.Name()
		path := ps.filePath(filename)
		if f.IsDir() || strings.HasSuffix(filename, ".tmp") {
			os.RemoveAll(path)
			continue
		}
		id, ok := posterIDFromFilename(filename)
		if !ok {
			os.Remove(path)
			continue
		}
		info, err := f.Info()
		if err != nil {
			os.Remove(path)
			continue
		}
		createdAt := info.ModTime()
		expiresAt := createdAt.Add(ps.maxAge)
		if !now.Before(expiresAt) {
			os.Remove(path)
			continue
		}
		contentType, _ := posterContentTypeForExt(filepath.Ext(filename))
		entry := posterEntry{
			Filename:    filename,
			Size:        info.Size(),
			ContentType: contentType,
			CreatedAt:   createdAt,
			ExpiresAt:   expiresAt,
		}
		ps.entries[id] = entry
		ps.totalBytes += entry.Size
	}
	ps.evictOldestLocked(0)
}

func (ps *posterStore) store(data []byte, contentType string, now time.Time) (string, posterEntry, error) {
	entrySize := int64(len(data))
	if entrySize <= 0 {
		return "", posterEntry{}, errors.New("empty poster")
	}
	if entrySize > ps.maxBytes {
		return "", posterEntry{}, errors.New("poster exceeds store size")
	}
	ext, ok := posterExtForContentType(contentType)
	if !ok {
		return "", posterEntry{}, errors.New("unsupported poster type")
	}

	ps.mu.Lock()
	defer ps.mu.Unlock()

	ps.cleanupExpiredLocked(now)
	ps.evictOldestLocked(entrySize)
	if ps.totalBytes+entrySize > ps.maxBytes {
		return "", posterEntry{}, errors.New("poster store full")
	}

	id := generatePosterID()
	for {
		if _, exists := ps.entries[id]; !exists {
			if _, err := os.Stat(ps.filePath(id + ext)); errors.Is(err, fs.ErrNotExist) {
				break
			}
		}
		id = generatePosterID()
	}

	filename := id + ext
	path := ps.filePath(filename)
	tmpPath := path + ".tmp"
	if err := os.WriteFile(tmpPath, data, 0644); err != nil {
		os.Remove(tmpPath)
		return "", posterEntry{}, err
	}
	if err := os.Rename(tmpPath, path); err != nil {
		os.Remove(tmpPath)
		return "", posterEntry{}, err
	}
	_ = os.Chtimes(path, now, now)

	entry := posterEntry{
		Filename:    filename,
		Size:        entrySize,
		ContentType: strings.ToLower(strings.SplitN(contentType, ";", 2)[0]),
		CreatedAt:   now,
		ExpiresAt:   now.Add(ps.maxAge),
	}
	ps.entries[id] = entry
	ps.totalBytes += entry.Size
	return id, entry, nil
}

func (ps *posterStore) lookup(filename string, now time.Time) (posterEntry, bool) {
	id, ok := posterIDFromFilename(filename)
	if !ok {
		return posterEntry{}, false
	}

	ps.mu.Lock()
	defer ps.mu.Unlock()
	entry, ok := ps.entries[id]
	if !ok || entry.Filename != filename {
		return posterEntry{}, false
	}
	if !now.Before(entry.ExpiresAt) {
		ps.deleteEntryLocked(id, entry)
		return posterEntry{}, false
	}
	return entry, true
}

func (ps *posterStore) cleanup(now time.Time) {
	ps.mu.Lock()
	defer ps.mu.Unlock()
	ps.cleanupExpiredLocked(now)
	ps.evictOldestLocked(0)
}

func (ps *posterStore) cleanupExpiredLocked(now time.Time) {
	for id, entry := range ps.entries {
		if !now.Before(entry.ExpiresAt) {
			ps.deleteEntryLocked(id, entry)
		}
	}
}

func (ps *posterStore) evictOldestLocked(extraBytes int64) {
	for ps.totalBytes+extraBytes > ps.maxBytes && len(ps.entries) > 0 {
		var oldestID string
		var oldest posterEntry
		first := true
		for id, entry := range ps.entries {
			if first || entry.CreatedAt.Before(oldest.CreatedAt) {
				oldestID = id
				oldest = entry
				first = false
			}
		}
		if oldestID == "" {
			return
		}
		ps.deleteEntryLocked(oldestID, oldest)
	}
}

func (ps *posterStore) deleteEntryLocked(id string, entry posterEntry) {
	os.Remove(ps.filePath(entry.Filename))
	delete(ps.entries, id)
	ps.totalBytes -= entry.Size
	if ps.totalBytes < 0 {
		ps.totalBytes = 0
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
	rooms   map[string]*Room
	logs    *logStore
	posters *posterStore
	conns   *connTracker
	snap    *snapshotter
	oauth   *oauthProxy // nil when OAUTH_BASE_URL is unset
	mu      sync.RWMutex
}

func newServer(logDir, stateFile, posterDir string) *Server {
	s := &Server{
		rooms:   make(map[string]*Room),
		logs:    newLogStore(logDir),
		posters: newPosterStore(posterDir, maxPosterStoreSize, posterMaxAge),
		conns:   newConnTracker(),
	}
	if p, ok := oauthConfigFromEnv(); ok {
		s.oauth = p
		log.Printf("oauth: proxy enabled (base=%s, services=%d)", p.baseURL, len(p.services))
	}
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
		if !validRelayID(r.SessionID, maxSessionIDLength) || !validRelayID(r.HostPeerID, maxPeerIDLength) {
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
	var expiredClients []*Client
	for id, room := range s.rooms {
		room.mu.RLock()
		empty := len(room.Peers) == 0
		age := now.Sub(room.CreatedAt)
		idle := now.Sub(room.LastActivityAt)
		expired := age > roomMaxAge
		if expired && !empty {
			for _, client := range room.Peers {
				expiredClients = append(expiredClients, client)
			}
		}
		room.mu.RUnlock()

		if (empty && idle > emptyRoomMaxAge) || expired {
			log.Printf("cleanup: removing room %s (empty=%v, idle=%v, age=%v)", id, empty, idle, age)
			delete(s.rooms, id)
			changed = true
		}
	}
	roomCount := len(s.rooms)
	s.mu.Unlock()

	for _, client := range expiredClients {
		client.close()
	}
	if changed {
		s.snap.schedule()
	}
	s.logs.cleanup()
	s.posters.cleanup(now)
	s.conns.cleanup(now)
	if s.oauth != nil {
		s.oauth.cleanup()
	}

	s.conns.mu.Lock()
	log.Printf("stats: conns=%d ips=%d rooms=%d",
		s.conns.globalCount, len(s.conns.perIP), roomCount)
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

	id, entry, err := s.logs.store(body, time.Now())
	if err != nil {
		if errors.Is(err, errLogStoreFull) {
			http.Error(w, "Log store full", http.StatusServiceUnavailable)
			return
		}
		log.Printf("logs: failed to store from %s: %v", ip, err)
		http.Error(w, "Failed to store log", http.StatusInternalServerError)
		return
	}

	log.Printf("logs: stored %s (%d bytes) from %s", id, entry.Size, ip)

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

	entry, ok := s.logs.lookup(id, time.Now())
	if !ok {
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

func (s *Server) handlePostPosters(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	body, err := io.ReadAll(io.LimitReader(r.Body, maxPosterSize+1))
	if err != nil {
		http.Error(w, "Failed to read body", http.StatusBadRequest)
		return
	}
	if len(body) > maxPosterSize {
		http.Error(w, "Poster too large (max 5MB)", http.StatusRequestEntityTooLarge)
		return
	}
	if len(body) == 0 {
		http.Error(w, "Empty body", http.StatusBadRequest)
		return
	}

	contentType := http.DetectContentType(body)
	if _, ok := posterExtForContentType(contentType); !ok {
		http.Error(w, "Unsupported media type", http.StatusUnsupportedMediaType)
		return
	}

	id, entry, err := s.posters.store(body, contentType, time.Now())
	if err != nil {
		log.Printf("posters: failed to store from %s: %v", clientIP(r), err)
		http.Error(w, "Failed to store poster", http.StatusInternalServerError)
		return
	}

	url := "/posters/" + entry.Filename
	log.Printf("posters: stored %s (%d bytes) from %s", id, entry.Size, clientIP(r))

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]any{
		"id":        id,
		"url":       url,
		"expiresIn": int(s.posters.maxAge.Seconds()),
	})
}

func (s *Server) handleGetPosters(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	filename := strings.TrimPrefix(r.URL.Path, "/posters/")
	entry, ok := s.posters.lookup(filename, time.Now())
	if !ok {
		http.Error(w, "Not found", http.StatusNotFound)
		return
	}

	f, err := os.Open(s.posters.filePath(entry.Filename))
	if err != nil {
		http.Error(w, "Not found", http.StatusNotFound)
		return
	}
	defer f.Close()

	remaining := int(time.Until(entry.ExpiresAt).Seconds())
	if remaining < 0 {
		remaining = 0
	}
	w.Header().Set("Cache-Control", "public, max-age="+strconv.Itoa(remaining))
	w.Header().Set("Content-Type", entry.ContentType)
	w.Header().Set("Content-Length", strconv.FormatInt(entry.Size, 10))
	http.ServeContent(w, r, entry.Filename, entry.CreatedAt, f)
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
	rejectRoomTransition := func() bool {
		if currentRoom == nil {
			return false
		}
		client.sendJSON(serverMsg{
			Type:    relayTypeError,
			Code:    relayErrorAlreadyInRoom,
			Message: "Leave the current room before creating or joining another",
		})
		return true
	}

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
					Type:   relayTypePeerLeft,
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
			client.sendJSON(serverMsg{Type: relayTypeError, Code: relayErrorRateLimited, Message: "Too many messages"})
			continue
		}

		var msg clientMsg
		if err := json.Unmarshal(raw, &msg); err != nil {
			client.sendJSON(serverMsg{Type: relayTypeError, Code: relayErrorInvalidMessage, Message: "Invalid JSON"})
			continue
		}

		switch msg.Type {
		case relayTypeCreate:
			if !validRelayID(msg.SessionID, maxSessionIDLength) || !validRelayID(msg.PeerID, maxPeerIDLength) {
				client.sendJSON(serverMsg{Type: relayTypeError, Code: relayErrorInvalidMessage, Message: "Invalid sessionId or peerId"})
				continue
			}
			if rejectRoomTransition() {
				continue
			}
			if !s.conns.tryCreateRoom(ip) {
				client.sendJSON(serverMsg{Type: relayTypeError, Code: relayErrorRateLimited, Message: "Too many rooms created"})
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
					client.sendJSON(serverMsg{Type: relayTypeError, Code: relayErrorRoomExists, Message: "Room already exists"})
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
			client.sendJSON(serverMsg{Type: relayTypeCreated, SessionID: msg.SessionID})
			s.snap.schedule()

		case relayTypeJoin:
			if !validRelayID(msg.SessionID, maxSessionIDLength) || !validRelayID(msg.PeerID, maxPeerIDLength) {
				client.sendJSON(serverMsg{Type: relayTypeError, Code: relayErrorInvalidMessage, Message: "Invalid sessionId or peerId"})
				continue
			}
			if rejectRoomTransition() {
				continue
			}
			s.mu.RLock()
			room, exists := s.rooms[msg.SessionID]
			s.mu.RUnlock()
			if !exists {
				client.sendJSON(serverMsg{Type: relayTypeError, Code: relayErrorRoomNotFound, Message: "Room does not exist"})
				continue
			}
			room.mu.Lock()
			if len(room.Peers) >= maxRoomSize {
				room.mu.Unlock()
				client.sendJSON(serverMsg{Type: relayTypeError, Code: relayErrorRoomFull, Message: "Room is full"})
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
			client.sendJSON(serverMsg{Type: relayTypeJoined, SessionID: msg.SessionID, Peers: existingPeers})
			room.broadcastExcept(msg.PeerID, serverMsg{Type: relayTypePeerJoined, PeerID: msg.PeerID})
			s.snap.schedule()

		case relayTypeBroadcast:
			if currentRoom == nil {
				client.sendJSON(serverMsg{Type: relayTypeError, Code: relayErrorNotInRoom, Message: "Not in a room"})
				continue
			}
			currentRoom.broadcastExcept(currentPeerID, serverMsg{
				Type:    relayTypeMessage,
				From:    currentPeerID,
				Payload: msg.Payload,
			})

		case relayTypeSendTo:
			if currentRoom == nil {
				client.sendJSON(serverMsg{Type: relayTypeError, Code: relayErrorNotInRoom, Message: "Not in a room"})
				continue
			}
			if !validRelayID(msg.To, maxPeerIDLength) {
				client.sendJSON(serverMsg{Type: relayTypeError, Code: relayErrorInvalidMessage, Message: "Invalid to field"})
				continue
			}
			if !currentRoom.sendTo(msg.To, serverMsg{
				Type:    relayTypeMessage,
				From:    currentPeerID,
				Payload: msg.Payload,
			}) {
				client.sendJSON(serverMsg{Type: relayTypeError, Code: relayErrorNotInRoom, Message: "Target peer not found"})
			}

		case relayTypePing:
			client.sendJSON(serverMsg{Type: relayTypePong})

		default:
			client.sendJSON(serverMsg{Type: relayTypeError, Code: relayErrorInvalidMessage, Message: "Unknown message type"})
		}
	}
}

func main() {
	addr := flag.String("addr", ":8080", "Listen address")
	logDir := flag.String("log-dir", "/data/logs", "Directory for log file storage")
	posterDir := flag.String("poster-dir", "/data/posters", "Directory for Discord poster storage")
	stateFile := flag.String("state-file", "/data/rooms.json", "Path to room snapshot file")
	flag.Parse()

	srv := newServer(*logDir, *stateFile, *posterDir)

	mux := http.NewServeMux()
	mux.HandleFunc("/relay", srv.handleWS)
	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("ok"))
	})
	mux.HandleFunc("/logs", srv.handlePostLogs)
	mux.HandleFunc("/logs/", srv.handleGetLogs)
	mux.HandleFunc("/posters", srv.handlePostPosters)
	mux.HandleFunc("/posters/", srv.handleGetPosters)
	registerOAuthRoutes(mux, srv.oauth)

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
