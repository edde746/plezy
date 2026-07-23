package main

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"crypto/subtle"
	"encoding/base64"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
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
	rateBurst                  = 30
	rateSustained              = 10
	cleanupInterval            = 5 * time.Minute
	emptyRoomMaxAge            = 5 * time.Minute
	roomMaxAge                 = 24 * time.Hour
	writeWait                  = 10 * time.Second
	httpResponseWriteMargin    = 10 * time.Second
	httpResponseWriteTimeout   = oauthResultWait + httpResponseWriteMargin
	pongWait                   = 60 * time.Second
	pingInterval               = 30 * time.Second
	maxLogSize                 = 1 * 1024 * 1024 // 1MB
	logMaxAge                  = 3 * 24 * time.Hour
	logIDLength                = 25
	logRateInterval            = 1 * time.Minute
	logLookupRateBurst         = 10
	logLookupRateSustained     = 1
	maxLogEntries              = 500
	maxFailedLogLookupSources  = 4096
	maxConcurrentLogLookups    = 32
	maxHTTPHeaderBytes         = 64 * 1024
	maxPosterSize              = 5 * 1024 * 1024 // 5MB
	maxPosterStoreSize         = int64(1 * 1024 * 1024 * 1024)
	posterMaxAge               = 3 * time.Hour
	posterIDLength             = 16
	posterPerIPRateBurst       = 3
	posterPerIPRateSustained   = 1
	posterGlobalRateBurst      = 8
	posterGlobalRateSustained  = 2
	maxConcurrentPosterUploads = 4
	posterUploadReadTimeout    = 30 * time.Second
	maxConnsPerIP              = 5
	maxGlobalConns             = 100
	maxRoomsPerIP              = 3
	maxRetainedRooms           = 2000
	connRateBurst              = 5
	connRateSustained          = 1
	reconnectTokenSize         = 32
	snapshotFormatVersion      = 3
	snapshotDebounce           = 100 * time.Millisecond
	snapshotFlushTimeout       = 5 * time.Second
	snapshotMaxFileSize        = 4 * 1024 * 1024
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin:     func(r *http.Request) bool { return true },
}

// --- Messages ---

type clientMsg struct {
	Type            string          `json:"type"`
	SessionID       string          `json:"sessionId,omitempty"`
	PeerID          string          `json:"peerId,omitempty"`
	ReconnectToken  string          `json:"reconnectToken,omitempty"`
	ProtocolVersion int             `json:"protocolVersion,omitempty"`
	To              string          `json:"to,omitempty"`
	Payload         json.RawMessage `json:"payload,omitempty"`
}

type serverMsg struct {
	Type            string          `json:"type"`
	SessionID       string          `json:"sessionId,omitempty"`
	PeerID          string          `json:"peerId,omitempty"`
	HostPeerID      string          `json:"hostPeerId,omitempty"`
	ReconnectToken  string          `json:"reconnectToken,omitempty"`
	ProtocolVersion int             `json:"protocolVersion,omitempty"`
	From            string          `json:"from,omitempty"`
	Peers           []string        `json:"peers,omitempty"`
	Code            string          `json:"code,omitempty"`
	Message         string          `json:"message,omitempty"`
	Payload         json.RawMessage `json:"payload,omitempty"`
}

// --- Client (serializes writes to a single goroutine) ---

type outboundFrame struct {
	data    []byte
	written chan bool
}

type Client struct {
	conn      *websocket.Conn
	send      chan outboundFrame
	done      chan struct{}
	closeOnce sync.Once
}

func newClient(conn *websocket.Conn) *Client {
	c := &Client{conn: conn, send: make(chan outboundFrame, 64), done: make(chan struct{})}
	go c.writePump()
	return c
}

func (c *Client) writePump() {
	ticker := time.NewTicker(pingInterval)
	defer func() {
		ticker.Stop()
		c.close()
	}()
	for {
		select {
		case frame := <-c.send:
			if err := c.conn.SetWriteDeadline(time.Now().Add(writeWait)); err != nil {
				if frame.written != nil {
					frame.written <- false
				}
				return
			}
			if err := c.conn.WriteMessage(websocket.TextMessage, frame.data); err != nil {
				if frame.written != nil {
					frame.written <- false
				}
				return
			}
			if frame.written != nil {
				frame.written <- true
			}
		case <-c.done:
			_ = c.conn.WriteMessage(websocket.CloseMessage, nil)
			return
		case <-ticker.C:
			if err := c.conn.SetWriteDeadline(time.Now().Add(writeWait)); err != nil {
				return
			}
			if err := c.conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}

func (c *Client) enqueueFrame(frame outboundFrame) bool {
	select {
	case <-c.done:
		return false
	default:
	}

	select {
	case <-c.done:
		return false
	case c.send <- frame:
		return true
	default:
		c.close()
		return false
	}
}

func (c *Client) enqueue(data []byte) bool {
	return c.enqueueFrame(outboundFrame{data: data})
}

func (c *Client) sendJSON(msg serverMsg) bool {
	data, err := json.Marshal(msg)
	if err != nil {
		return false
	}
	return c.enqueue(data)
}

func (c *Client) sendJSONAndWait(msg serverMsg) bool {
	data, err := json.Marshal(msg)
	if err != nil {
		return false
	}
	written := make(chan bool, 1)
	if !c.enqueueFrame(outboundFrame{data: data, written: written}) {
		return false
	}
	select {
	case ok := <-written:
		return ok
	case <-time.After(writeWait):
		return false
	}
}

func (c *Client) close() {
	c.closeOnce.Do(func() {
		close(c.done)
		_ = c.conn.Close()
	})
}

// --- Room ---

type reconnectVerifier [sha256.Size]byte

type Room struct {
	SessionID       string
	HostPeerID      string
	ProtocolVersion int
	hostVerifier    reconnectVerifier
	peerVerifiers   map[string]reconnectVerifier
	Peers           map[string]*Client `json:"-"`
	quotaOwnerKey   string             `json:"-"`
	mu              sync.RWMutex       `json:"-"`
	closing         bool               `json:"-"`
	CreatedAt       time.Time
	LastActivityAt  time.Time
}

// --- Snapshot types (on-disk JSON format) ---

type roomSnapshot struct {
	SessionID              string            `json:"sessionId"`
	HostPeerID             string            `json:"hostPeerId"`
	ProtocolVersion        int               `json:"protocolVersion,omitempty"`
	HostReconnectVerifier  string            `json:"hostReconnectVerifier"`
	PeerReconnectVerifiers map[string]string `json:"peerReconnectVerifiers,omitempty"`
	CreatedAt              time.Time         `json:"createdAt"`
	LastActivityAt         time.Time         `json:"lastActivityAt"`
}

type stateSnapshot struct {
	Version int            `json:"version"`
	SavedAt time.Time      `json:"savedAt"`
	Rooms   []roomSnapshot `json:"rooms"`
}

func mintReconnectToken() (string, reconnectVerifier, error) {
	raw := make([]byte, reconnectTokenSize)
	if _, err := rand.Read(raw); err != nil {
		return "", reconnectVerifier{}, err
	}
	return base64.RawURLEncoding.EncodeToString(raw), sha256.Sum256(raw), nil
}

func reconnectVerifierFromToken(token string) (reconnectVerifier, bool) {
	if len(token) != base64.RawURLEncoding.EncodedLen(reconnectTokenSize) {
		return reconnectVerifier{}, false
	}
	raw, err := base64.RawURLEncoding.DecodeString(token)
	if err != nil || len(raw) != reconnectTokenSize {
		return reconnectVerifier{}, false
	}
	return sha256.Sum256(raw), true
}

func reconnectVerifierFromSnapshot(encoded string) (reconnectVerifier, bool) {
	raw, err := base64.RawURLEncoding.DecodeString(encoded)
	if err != nil || len(raw) != sha256.Size {
		return reconnectVerifier{}, false
	}
	var verifier reconnectVerifier
	copy(verifier[:], raw)
	return verifier, true
}

func encodeReconnectVerifier(verifier reconnectVerifier) string {
	return base64.RawURLEncoding.EncodeToString(verifier[:])
}

func reconnectVerifierMatches(expected, presented reconnectVerifier) bool {
	return subtle.ConstantTimeCompare(expected[:], presented[:]) == 1
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
		client.enqueue(data)
	}
}

func (r *Room) broadcastFrom(senderID string, sender *Client, msg serverMsg) bool {
	data, err := json.Marshal(msg)
	if err != nil {
		return false
	}
	r.mu.Lock()
	if r.Peers[senderID] != sender {
		r.mu.Unlock()
		return false
	}
	if r.closing {
		r.mu.Unlock()
		return true
	}
	targets := make([]*Client, 0, len(r.Peers)-1)
	r.LastActivityAt = time.Now()
	for id, client := range r.Peers {
		if id != senderID {
			targets = append(targets, client)
		}
	}
	r.mu.Unlock()

	for _, target := range targets {
		target.enqueue(data)
	}
	return true
}

type directedSendResult uint8

const (
	directedSenderUnavailable directedSendResult = iota
	directedTargetMissing
	directedTargetFound
	directedSendSuppressed
)

func (r *Room) sendFrom(senderID string, sender *Client, targetID string, msg serverMsg) directedSendResult {
	data, err := json.Marshal(msg)
	if err != nil {
		return directedSenderUnavailable
	}
	r.mu.Lock()
	if r.Peers[senderID] != sender {
		r.mu.Unlock()
		return directedSenderUnavailable
	}
	if r.closing {
		r.mu.Unlock()
		return directedSendSuppressed
	}
	target, ok := r.Peers[targetID]
	if ok {
		r.LastActivityAt = time.Now()
	}
	r.mu.Unlock()
	if !ok {
		return directedTargetMissing
	}
	target.enqueue(data)
	return directedTargetFound
}

// --- Log store ---
type artifactRemovalError struct {
	err error
}

func (e *artifactRemovalError) Error() string {
	return "artifact removal failed"
}

func (e *artifactRemovalError) Unwrap() error {
	return e.err
}

var errArtifactOutsideStore = errors.New("artifact path outside store")

func classifyRemovalError(err error) error {
	if err == nil || errors.Is(err, fs.ErrNotExist) {
		return nil
	}
	return err
}

func removeArtifact(removeFile func(string) error, root, path string) error {
	err := classifyRemovalError(removeFile(path))
	if err == nil {
		return nil
	}
	if !errors.Is(err, syscall.ENOTEMPTY) && !errors.Is(err, syscall.EEXIST) {
		return &artifactRemovalError{err: err}
	}
	if err := removeConfinedDirectory(root, path); err != nil {
		return &artifactRemovalError{err: err}
	}
	return nil
}

func removeConfinedDirectory(root, path string) error {
	info, err := os.Lstat(path)
	if err != nil {
		return classifyRemovalError(err)
	}
	if !info.IsDir() {
		return syscall.ENOTDIR
	}

	rootPath, err := filepath.Abs(root)
	if err != nil {
		return errArtifactOutsideStore
	}
	rootPath, err = filepath.EvalSymlinks(rootPath)
	if err != nil {
		return errArtifactOutsideStore
	}
	artifactPath, err := filepath.Abs(path)
	if err != nil {
		return errArtifactOutsideStore
	}
	artifactPath, err = filepath.EvalSymlinks(artifactPath)
	if err != nil {
		return errArtifactOutsideStore
	}
	relative, err := filepath.Rel(rootPath, artifactPath)
	if err != nil ||
		relative == "." ||
		relative == ".." ||
		filepath.IsAbs(relative) ||
		strings.HasPrefix(relative, ".."+string(filepath.Separator)) {
		return errArtifactOutsideStore
	}
	return os.RemoveAll(artifactPath)
}

type pendingRemoval struct {
	size      int64
	sizeKnown bool
}

type logEntry struct {
	Size      int
	CreatedAt time.Time
	ExpiresAt time.Time
}

var errLogStoreFull = errors.New("log store full")

type logStore struct {
	entries          map[string]logEntry
	pendingRemovals  map[string]pendingRemoval
	rateLimit        map[string]time.Time // IP -> last upload time
	failedLookupRate map[string]*rateLimiter
	dir              string
	generateID       func() string
	removeFile       func(string) error
	startupErr       error
	mu               sync.RWMutex
}

func newLogStore(dir string) *logStore {
	return newLogStoreWithRemover(dir, os.Remove)
}

func newLogStoreWithRemover(dir string, removeFile func(string) error) *logStore {
	if err := os.MkdirAll(dir, 0755); err != nil {
		log.Fatalf("failed to create log dir %s: %v", dir, err)
	}
	ls := &logStore{
		entries:          make(map[string]logEntry),
		pendingRemovals:  make(map[string]pendingRemoval),
		rateLimit:        make(map[string]time.Time),
		failedLookupRate: make(map[string]*rateLimiter),
		dir:              dir,
		generateID:       generateLogID,
		removeFile:       removeFile,
	}
	ls.startupErr = ls.loadExisting(time.Now())
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

func (ls *logStore) loadExisting(now time.Time) error {
	ls.mu.Lock()
	defer ls.mu.Unlock()

	files, err := os.ReadDir(ls.dir)
	if err != nil {
		log.Printf("logs: failed to read dir %s: %v", ls.dir, err)
		return nil
	}
	var removalErr error
	for _, file := range files {
		filename := file.Name()
		if file.IsDir() || strings.HasSuffix(filename, ".tmp") {
			removalErr = errors.Join(removalErr, ls.removeUntrackedLocked(filename))
			continue
		}
		id, ok := logIDFromFilename(filename)
		if !ok {
			removalErr = errors.Join(removalErr, ls.removeUntrackedLocked(filename))
			continue
		}
		info, infoErr := file.Info()
		if infoErr != nil || !info.Mode().IsRegular() || info.Size() <= 0 || info.Size() > maxLogSize {
			removalErr = errors.Join(removalErr, ls.removeUntrackedLocked(filename))
			continue
		}
		createdAt := info.ModTime()
		ls.entries[id] = logEntry{
			Size:      int(info.Size()),
			CreatedAt: createdAt,
			ExpiresAt: createdAt.Add(logMaxAge),
		}
	}
	removalErr = errors.Join(removalErr, ls.cleanupExpiredLocked(now))
	removalErr = errors.Join(removalErr, ls.evictOldestLocked(maxLogEntries))
	return removalErr
}

func (ls *logStore) removeUntrackedLocked(filename string) error {
	if err := removeArtifact(ls.removeFile, ls.dir, filepath.Join(ls.dir, filename)); err != nil {
		if _, exists := ls.pendingRemovals[filename]; !exists {
			ls.pendingRemovals[filename] = pendingRemoval{}
		}
		return err
	}
	delete(ls.pendingRemovals, filename)
	return nil
}

func (ls *logStore) retryPendingLocked() error {
	var removalErr error
	for filename := range ls.pendingRemovals {
		if err := removeArtifact(ls.removeFile, ls.dir, filepath.Join(ls.dir, filename)); err != nil {
			removalErr = errors.Join(removalErr, err)
			continue
		}
		delete(ls.pendingRemovals, filename)
	}
	return removalErr
}

func (ls *logStore) cleanupFailedTempLocked(tmpPath string) {
	_ = ls.removeUntrackedLocked(filepath.Base(tmpPath))
}

func (ls *logStore) artifactCountLocked() int {
	return len(ls.entries) + len(ls.pendingRemovals)
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
	_ = ls.retryPendingLocked()
	_ = ls.cleanupExpiredLocked(now)
	if err := ls.evictOldestLocked(maxLogEntries); err != nil {
		return "", logEntry{}, err
	}
	if ls.artifactCountLocked() >= maxLogEntries {
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
		ls.cleanupFailedTempLocked(tmpPath)
		return "", logEntry{}, err
	}
	if err := os.Rename(tmpPath, path); err != nil {
		ls.cleanupFailedTempLocked(tmpPath)
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

func (ls *logStore) lookup(id string, now time.Time) (logEntry, bool, error) {
	if !validID(id, logIDLength) {
		return logEntry{}, false, nil
	}
	ls.mu.Lock()
	defer ls.mu.Unlock()
	entry, ok := ls.entries[id]
	if !ok {
		return logEntry{}, false, nil
	}
	if !now.Before(entry.ExpiresAt) {
		if err := ls.deleteEntryLocked(id); err != nil {
			return logEntry{}, false, err
		}
		return logEntry{}, false, nil
	}
	return entry, true, nil
}

func (ls *logStore) allowFailedLookup(source string, now time.Time) bool {
	ls.mu.Lock()
	defer ls.mu.Unlock()
	limiter := ls.failedLookupRate[source]
	if limiter == nil {
		cleanupRateLimiters(ls.failedLookupRate, now, nil)
		if len(ls.failedLookupRate) >= maxFailedLogLookupSources {
			return false
		}
		limiter = newRateLimiterAt(logLookupRateBurst, logLookupRateSustained, now)
		ls.failedLookupRate[source] = limiter
	}
	return limiter.allowAt(now)
}

func (ls *logStore) cleanupExpiredLocked(now time.Time) error {
	var removalErr error
	for id, entry := range ls.entries {
		if !now.Before(entry.ExpiresAt) {
			removalErr = errors.Join(removalErr, ls.deleteEntryLocked(id))
		}
	}
	return removalErr
}

func (ls *logStore) evictOldestLocked(limit int) error {
	for ls.artifactCountLocked() > limit {
		var oldestID string
		var oldest logEntry
		for id, entry := range ls.entries {
			if oldestID == "" || entry.CreatedAt.Before(oldest.CreatedAt) {
				oldestID = id
				oldest = entry
			}
		}
		if oldestID == "" {
			return nil
		}
		if err := ls.deleteEntryLocked(oldestID); err != nil {
			return err
		}
	}
	return nil
}

func (ls *logStore) deleteEntryLocked(id string) error {
	if _, ok := ls.entries[id]; !ok {
		return nil
	}
	if err := removeArtifact(ls.removeFile, ls.dir, ls.filePath(id)); err != nil {
		return err
	}
	delete(ls.entries, id)
	return nil
}

func (ls *logStore) cleanup(now time.Time) error {
	ls.mu.Lock()
	defer ls.mu.Unlock()
	removalErr := ls.retryPendingLocked()
	removalErr = errors.Join(removalErr, ls.cleanupExpiredLocked(now))
	removalErr = errors.Join(removalErr, ls.evictOldestLocked(maxLogEntries))
	cleanupRateWindows(ls.rateLimit, now, logRateInterval)
	cleanupRateLimiters(ls.failedLookupRate, now, nil)
	return removalErr
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
	entries         map[string]posterEntry
	pendingRemovals map[string]pendingRemoval
	dir             string
	maxBytes        int64
	maxAge          time.Duration
	totalBytes      int64
	pendingBytes    int64
	unknownPending  int
	removeFile      func(string) error
	startupErr      error
	mu              sync.RWMutex
}

func newPosterStore(dir string, maxBytes int64, maxAge time.Duration) *posterStore {
	return newPosterStoreWithRemover(dir, maxBytes, maxAge, os.Remove)
}

func newPosterStoreWithRemover(
	dir string,
	maxBytes int64,
	maxAge time.Duration,
	removeFile func(string) error,
) *posterStore {
	if err := os.MkdirAll(dir, 0755); err != nil {
		log.Fatalf("failed to create poster dir %s: %v", dir, err)
	}
	ps := &posterStore{
		entries:         make(map[string]posterEntry),
		pendingRemovals: make(map[string]pendingRemoval),
		dir:             dir,
		maxBytes:        maxBytes,
		maxAge:          maxAge,
		removeFile:      removeFile,
	}
	ps.startupErr = ps.loadExisting(time.Now())
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

func (ps *posterStore) loadExisting(now time.Time) error {
	ps.mu.Lock()
	defer ps.mu.Unlock()

	files, err := os.ReadDir(ps.dir)
	if err != nil {
		log.Printf("posters: failed to read dir %s: %v", ps.dir, err)
		return nil
	}
	var removalErr error
	for _, file := range files {
		filename := file.Name()
		if file.IsDir() || strings.HasSuffix(filename, ".tmp") {
			size, known := posterArtifactSize(file)
			removalErr = errors.Join(
				removalErr,
				ps.removeUntrackedLocked(filename, size, known),
			)
			continue
		}
		id, ok := posterIDFromFilename(filename)
		if !ok {
			size, known := posterArtifactSize(file)
			removalErr = errors.Join(
				removalErr,
				ps.removeUntrackedLocked(filename, size, known),
			)
			continue
		}
		info, infoErr := file.Info()
		if infoErr != nil || !info.Mode().IsRegular() {
			removalErr = errors.Join(
				removalErr,
				ps.removeUntrackedLocked(filename, 0, false),
			)
			continue
		}
		if _, duplicate := ps.entries[id]; duplicate {
			removalErr = errors.Join(
				removalErr,
				ps.removeUntrackedLocked(filename, info.Size(), true),
			)
			continue
		}
		createdAt := info.ModTime()
		contentType, _ := posterContentTypeForExt(filepath.Ext(filename))
		entry := posterEntry{
			Filename:    filename,
			Size:        info.Size(),
			ContentType: contentType,
			CreatedAt:   createdAt,
			ExpiresAt:   createdAt.Add(ps.maxAge),
		}
		ps.entries[id] = entry
		ps.totalBytes += entry.Size
	}
	removalErr = errors.Join(removalErr, ps.cleanupExpiredLocked(now))
	removalErr = errors.Join(removalErr, ps.evictOldestLocked(0))
	return removalErr
}

func posterArtifactSize(file fs.DirEntry) (int64, bool) {
	info, err := file.Info()
	if err != nil || !info.Mode().IsRegular() {
		return 0, false
	}
	return info.Size(), true
}

func (ps *posterStore) addPendingLocked(filename string, size int64, known bool) {
	if _, exists := ps.pendingRemovals[filename]; exists {
		return
	}
	ps.pendingRemovals[filename] = pendingRemoval{size: size, sizeKnown: known}
	if known {
		ps.pendingBytes += size
	} else {
		ps.unknownPending++
	}
}

func (ps *posterStore) removeUntrackedLocked(filename string, size int64, known bool) error {
	if err := removeArtifact(ps.removeFile, ps.dir, ps.filePath(filename)); err != nil {
		ps.addPendingLocked(filename, size, known)
		return err
	}
	return nil
}

func (ps *posterStore) retryPendingLocked(knownOnly bool) error {
	var removalErr error
	for filename, pending := range ps.pendingRemovals {
		if knownOnly && !pending.sizeKnown {
			continue
		}
		if err := removeArtifact(ps.removeFile, ps.dir, ps.filePath(filename)); err != nil {
			removalErr = errors.Join(removalErr, err)
			continue
		}
		delete(ps.pendingRemovals, filename)
		if pending.sizeKnown {
			ps.pendingBytes -= pending.size
		} else {
			ps.unknownPending--
		}
	}
	return removalErr
}

func (ps *posterStore) cleanupFailedTempLocked(tmpPath string) {
	if err := removeArtifact(ps.removeFile, ps.dir, tmpPath); err == nil {
		return
	}
	info, statErr := os.Stat(tmpPath)
	known := statErr == nil && info.Mode().IsRegular()
	var size int64
	if known {
		size = info.Size()
	}
	ps.addPendingLocked(filepath.Base(tmpPath), size, known)
}

func (ps *posterStore) accountedBytesLocked() int64 {
	return ps.totalBytes + ps.pendingBytes
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

	// Known regular-file debt counts against quota and is retried on demand.
	// Unknown artifacts are left to periodic cleanup: their size cannot be
	// accounted safely, and a permanent directory or stat failure must not
	// deny otherwise capacity-safe uploads.
	_ = ps.retryPendingLocked(true)
	_ = ps.cleanupExpiredLocked(now)
	if err := ps.evictOldestLocked(entrySize); err != nil {
		return "", posterEntry{}, err
	}
	if ps.accountedBytesLocked()+entrySize > ps.maxBytes {
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
		ps.cleanupFailedTempLocked(tmpPath)
		return "", posterEntry{}, err
	}
	if err := os.Rename(tmpPath, path); err != nil {
		ps.cleanupFailedTempLocked(tmpPath)
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

func (ps *posterStore) lookup(filename string, now time.Time) (posterEntry, bool, error) {
	id, ok := posterIDFromFilename(filename)
	if !ok {
		return posterEntry{}, false, nil
	}

	ps.mu.Lock()
	defer ps.mu.Unlock()
	entry, ok := ps.entries[id]
	if !ok || entry.Filename != filename {
		return posterEntry{}, false, nil
	}
	if !now.Before(entry.ExpiresAt) {
		if err := ps.deleteEntryLocked(id); err != nil {
			return posterEntry{}, false, err
		}
		return posterEntry{}, false, nil
	}
	return entry, true, nil
}

func (ps *posterStore) cleanup(now time.Time) error {
	ps.mu.Lock()
	defer ps.mu.Unlock()
	removalErr := ps.retryPendingLocked(false)
	removalErr = errors.Join(removalErr, ps.cleanupExpiredLocked(now))
	removalErr = errors.Join(removalErr, ps.evictOldestLocked(0))
	return removalErr
}

func (ps *posterStore) cleanupExpiredLocked(now time.Time) error {
	var removalErr error
	for id, entry := range ps.entries {
		if !now.Before(entry.ExpiresAt) {
			removalErr = errors.Join(removalErr, ps.deleteEntryLocked(id))
		}
	}
	return removalErr
}

func (ps *posterStore) evictOldestLocked(extraBytes int64) error {
	for ps.accountedBytesLocked()+extraBytes > ps.maxBytes && len(ps.entries) > 0 {
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
			return nil
		}
		if err := ps.deleteEntryLocked(oldestID); err != nil {
			return err
		}
	}
	return nil
}

func (ps *posterStore) deleteEntryLocked(id string) error {
	entry, ok := ps.entries[id]
	if !ok {
		return nil
	}
	if err := removeArtifact(ps.removeFile, ps.dir, ps.filePath(entry.Filename)); err != nil {
		return err
	}
	delete(ps.entries, id)
	ps.totalBytes -= entry.Size
	return nil
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
	persist  func([]byte) error
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
	sn := &snapshotter{
		path:    path,
		dir:     dir,
		trigger: make(chan struct{}, 1),
		flush:   make(chan chan error),
		done:    make(chan struct{}),
		exited:  make(chan struct{}),
		build:   build,
	}
	sn.persist = sn.persistAtomic
	return sn
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
	if len(data) > snapshotMaxFileSize {
		return fmt.Errorf("snapshot exceeds maximum size: %d > %d bytes", len(data), snapshotMaxFileSize)
	}
	return sn.persist(data)
}

func (sn *snapshotter) persistAtomic(data []byte) error {
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
	// The directory entry must reach stable storage before a terminal
	// acknowledgement can rely on the rename surviving a host crash.
	d, err := os.Open(sn.dir)
	if err != nil {
		return err
	}
	if err := d.Sync(); err != nil {
		d.Close()
		return err
	}
	return d.Close()
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
type removalErrorThrottle struct {
	mu      sync.Mutex
	lastLog map[string]time.Time
}

func (s *Server) logRemovalError(store, operation string, err error) {
	key := store + ":" + operation
	s.removalErrors.mu.Lock()
	defer s.removalErrors.mu.Unlock()
	if last := s.removalErrors.lastLog[key]; !last.IsZero() && time.Since(last) < time.Hour {
		return
	}
	if s.removalErrors.lastLog == nil {
		s.removalErrors.lastLog = make(map[string]time.Time)
	}
	s.removalErrors.lastLog[key] = time.Now()
	category := "other"
	switch {
	case errors.Is(err, errArtifactOutsideStore):
		category = "confinement"
	case errors.Is(err, fs.ErrPermission):
		category = "permission"
	case errors.Is(err, syscall.ENOSPC):
		category = "capacity"
	case errors.Is(err, syscall.EROFS):
		category = "read_only"
	case errors.Is(err, syscall.EBUSY):
		category = "busy"
	case errors.Is(err, syscall.ENOTEMPTY), errors.Is(err, syscall.EEXIST):
		category = "not_empty"
	}
	var errno syscall.Errno
	if errors.As(err, &errno) {
		log.Printf("%s: %s removal failed: category=%s errno=%d", store, operation, category, errno)
		return
	}
	log.Printf("%s: %s removal failed: category=%s errno=unknown", store, operation, category)
}

type Server struct {
	rooms                 map[string]*Room
	logs                  *logStore
	posters               *posterStore
	posterUploads         *posterUploadLimiter
	logLookups            chan struct{}
	posterBodyReadTimeout time.Duration
	conns                 *connTracker
	clientIPs             clientIPResolver
	snap                  *snapshotter
	oauth                 *oauthProxy // nil when OAUTH_BASE_URL is unset
	removalErrors         removalErrorThrottle
	beforeJoinRoomLock     func() // test-only deterministic admission barrier
	beforeTerminalDelivery func() // test-only post-persistence, pre-delivery barrier
	mu                    sync.RWMutex
}

func newServer(logDir, stateFile, posterDir string, clientIPs clientIPResolver) *Server {
	s := &Server{
		rooms:                 make(map[string]*Room),
		logs:                  newLogStore(logDir),
		posters:               newPosterStore(posterDir, maxPosterStoreSize, posterMaxAge),
		posterUploads:         newPosterUploadLimiter(posterPerIPRateBurst, posterPerIPRateSustained, posterGlobalRateBurst, posterGlobalRateSustained, maxConcurrentPosterUploads, time.Now()),
		logLookups:            make(chan struct{}, maxConcurrentLogLookups),
		posterBodyReadTimeout: posterUploadReadTimeout,
		conns:                 newConnTracker(),
		clientIPs:             clientIPs,
	}
	if s.logs.startupErr != nil {
		s.logRemovalError("logs", "startup", s.logs.startupErr)
	}
	if s.posters.startupErr != nil {
		s.logRemovalError("posters", "startup", s.posters.startupErr)
	}
	if p, ok := oauthConfigFromEnv(clientIPs); ok {
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

// removeRoomLocked removes room only while it is still the authoritative map
// entry. The caller must hold s.mu. A current-process quota reservation follows
// the retained room and is returned exactly once by successful removal.
func (s *Server) removeRoomLocked(sessionID string, room *Room) bool {
	if s.rooms[sessionID] != room {
		return false
	}
	delete(s.rooms, sessionID)
	if room.quotaOwnerKey != "" {
		s.conns.releaseRoom(room.quotaOwnerKey)
	}
	return true
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
		var peerVerifiers map[string]string
		if len(room.peerVerifiers) != 0 {
			peerVerifiers = make(map[string]string, len(room.peerVerifiers))
			for peerID, verifier := range room.peerVerifiers {
				peerVerifiers[peerID] = encodeReconnectVerifier(verifier)
			}
		}
		snap.Rooms = append(snap.Rooms, roomSnapshot{
			SessionID:              room.SessionID,
			HostPeerID:             room.HostPeerID,
			ProtocolVersion:        room.ProtocolVersion,
			HostReconnectVerifier:  encodeReconnectVerifier(room.hostVerifier),
			PeerReconnectVerifiers: peerVerifiers,
			CreatedAt:              room.CreatedAt,
			LastActivityAt:         room.LastActivityAt,
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
	if snap.Version != 2 && snap.Version != snapshotFormatVersion {
		log.Printf("snapshot: unknown version %d, starting fresh", snap.Version)
		return nil
	}
	now := time.Now()
	restored := make(map[string]*Room, min(len(snap.Rooms), maxRetainedRooms))
	skipped := 0
	for _, r := range snap.Rooms {
		if !validRelayID(r.SessionID, maxSessionIDLength) || !validRelayID(r.HostPeerID, maxPeerIDLength) {
			skipped++
			continue
		}
		hostVerifier, ok := reconnectVerifierFromSnapshot(r.HostReconnectVerifier)
		if !ok {
			skipped++
			continue
		}
		if r.ProtocolVersion != legacyRelayProtocolVersion && r.ProtocolVersion != relayProtocolVersion {
			skipped++
			continue
		}
		var peerVerifiers map[string]reconnectVerifier
		if len(r.PeerReconnectVerifiers) != 0 {
			if r.ProtocolVersion == legacyRelayProtocolVersion {
				skipped++
				continue
			}
			peerVerifiers = make(map[string]reconnectVerifier, len(r.PeerReconnectVerifiers))
			validPeerVerifiers := true
			for peerID, encodedVerifier := range r.PeerReconnectVerifiers {
				verifier, verifierOK := reconnectVerifierFromSnapshot(encodedVerifier)
				if !validRelayID(peerID, maxPeerIDLength) ||
					peerID == r.HostPeerID ||
					!verifierOK ||
					len(peerVerifiers) >= maxRoomSize-1 {
					validPeerVerifiers = false
					break
				}
				peerVerifiers[peerID] = verifier
			}
			if !validPeerVerifiers {
				skipped++
				continue
			}
		}
		if now.Sub(r.CreatedAt) > roomMaxAge || now.Sub(r.LastActivityAt) > emptyRoomMaxAge {
			skipped++
			continue
		}
		if _, duplicate := restored[r.SessionID]; duplicate {
			skipped++
			continue
		}
		if len(restored) >= maxRetainedRooms {
			log.Printf("snapshot: too many retained rooms, starting fresh")
			return nil
		}
		restored[r.SessionID] = &Room{
			SessionID:       r.SessionID,
			HostPeerID:      r.HostPeerID,
			ProtocolVersion: r.ProtocolVersion,
			hostVerifier:    hostVerifier,
			peerVerifiers:   peerVerifiers,
			Peers:           make(map[string]*Client),
			CreatedAt:       r.CreatedAt,
			LastActivityAt:  r.LastActivityAt,
		}
	}
	s.mu.Lock()
	s.rooms = restored
	s.mu.Unlock()
	log.Printf("snapshot: loaded %d rooms, skipped %d invalid or expired rooms", len(restored), skipped)
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
		room.mu.Lock()
		empty := len(room.Peers) == 0
		age := now.Sub(room.CreatedAt)
		idle := now.Sub(room.LastActivityAt)
		expired := age > roomMaxAge
		remove := (empty && idle > emptyRoomMaxAge) || expired
		if remove {
			room.closing = true
			if expired && !empty {
				for _, client := range room.Peers {
					expiredClients = append(expiredClients, client)
				}
				clear(room.Peers)
			}
			log.Printf("cleanup: removing room %s (empty=%v, idle=%v, age=%v)", id, empty, idle, age)
			s.removeRoomLocked(id, room)
			changed = true
		}
		room.mu.Unlock()
	}
	roomCount := len(s.rooms)
	s.mu.Unlock()

	for _, client := range expiredClients {
		client.close()
	}
	if changed {
		s.snap.schedule()
	}
	if err := s.logs.cleanup(now); err != nil {
		s.logRemovalError("logs", "cleanup", err)
	}
	if err := s.posters.cleanup(now); err != nil {
		s.logRemovalError("posters", "cleanup", err)
	}
	s.posterUploads.cleanup(now)
	s.conns.cleanup(now)
	if s.oauth != nil {
		s.oauth.cleanup()
	}

	s.conns.mu.Lock()
	log.Printf("stats: conns=%d ips=%d rooms=%d",
		s.conns.globalCount, len(s.conns.perIP), roomCount)
	s.conns.mu.Unlock()
}

func (s *Server) handlePostLogs(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	ip, err := s.clientIPs.resolve(r)
	if err != nil {
		http.Error(w, "Invalid client address", http.StatusBadRequest)
		return
	}
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
		var removalErr *artifactRemovalError
		if errors.As(err, &removalErr) {
			s.logRemovalError("logs", "store", err)
		} else {
			log.Printf("logs: failed to store from %s: %v", ip, err)
		}
		http.Error(w, "Failed to store log", http.StatusInternalServerError)
		return
	}

	log.Printf("logs: stored %d bytes from %s", entry.Size, ip)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"id": id})
}

func (s *Server) handleGetLogs(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Cache-Control", "private, no-store")
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	type lookupResult struct {
		entry   logEntry
		data    []byte
		status  int
		message string
	}
	lookup := func() lookupResult {
		select {
		case s.logLookups <- struct{}{}:
			defer func() { <-s.logLookups }()
		default:
			return lookupResult{
				status:  http.StatusTooManyRequests,
				message: "Too many concurrent lookups",
			}
		}

		source, err := s.clientIPs.resolve(r)
		if err != nil {
			return lookupResult{
				status:  http.StatusBadRequest,
				message: "Invalid client address",
			}
		}
		id := strings.TrimPrefix(r.URL.Path, "/logs/")
		entry, ok, err := s.logs.lookup(id, time.Now())
		if err != nil {
			s.logRemovalError("logs", "lookup", err)
			return lookupResult{
				status:  http.StatusInternalServerError,
				message: "Failed to retrieve log",
			}
		}
		if !ok {
			if !s.logs.allowFailedLookup(source, time.Now()) {
				return lookupResult{
					status:  http.StatusTooManyRequests,
					message: "Too many failed lookups",
				}
			}
			return lookupResult{status: http.StatusNotFound, message: "Not found"}
		}

		data, err := os.ReadFile(s.logs.filePath(id))
		if err != nil {
			return lookupResult{status: http.StatusNotFound, message: "Not found"}
		}
		return lookupResult{entry: entry, data: data}
	}()

	controller := http.NewResponseController(w)
	if err := controller.SetWriteDeadline(time.Now().Add(httpResponseWriteTimeout)); err == nil {
		defer controller.SetWriteDeadline(time.Time{})
	} else if !errors.Is(err, http.ErrNotSupported) {
		log.Printf("logs: failed to set response write deadline")
	}

	if lookup.status != 0 {
		http.Error(w, lookup.message, lookup.status)
		return
	}

	w.Header().Set("Content-Type", "text/plain; charset=utf-8")
	w.Header().Set("Content-Length", strconv.Itoa(lookup.entry.Size))
	if written, err := w.Write(lookup.data); err != nil || written != len(lookup.data) {
		log.Printf("logs: response write failed")
	}
}

var errPosterBodyReadTimeout = errors.New("poster body read timeout")

func readPosterBody(body io.ReadCloser, maxBytes int64, timeout time.Duration) ([]byte, error) {
	timedOut := make(chan struct{})
	timer := time.AfterFunc(timeout, func() {
		close(timedOut)
		_ = body.Close()
	})
	data, err := io.ReadAll(io.LimitReader(body, maxBytes+1))
	if timer.Stop() {
		return data, err
	}
	<-timedOut
	return nil, errPosterBodyReadTimeout
}

func (s *Server) handlePostPosters(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	ip, err := s.clientIPs.resolve(r)
	if err != nil {
		http.Error(w, "Invalid client address", http.StatusBadRequest)
		return
	}
	if !s.posterUploads.tryStart(ip, time.Now()) {
		http.Error(w, "Too many poster uploads", http.StatusTooManyRequests)
		return
	}
	defer s.posterUploads.finish()

	timeout := s.posterBodyReadTimeout
	if timeout <= 0 {
		timeout = posterUploadReadTimeout
	}
	readDeadline := http.NewResponseController(w)
	if err := readDeadline.SetReadDeadline(time.Now().Add(timeout)); err == nil {
		defer readDeadline.SetReadDeadline(time.Time{})
	}
	body, err := readPosterBody(r.Body, maxPosterSize, timeout)
	var timeoutErr net.Error
	if errors.Is(err, errPosterBodyReadTimeout) || errors.As(err, &timeoutErr) && timeoutErr.Timeout() {
		http.Error(w, "Request body timeout", http.StatusRequestTimeout)
		return
	}
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
		var removalErr *artifactRemovalError
		if errors.As(err, &removalErr) {
			s.logRemovalError("posters", "store", err)
		} else {
			log.Printf("posters: failed to store from %s: %v", ip, err)
		}
		http.Error(w, "Failed to store poster", http.StatusInternalServerError)
		return
	}

	url := "/posters/" + entry.Filename
	log.Printf("posters: stored %s (%d bytes) from %s", id, entry.Size, ip)

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
	entry, ok, err := s.posters.lookup(filename, time.Now())
	if err != nil {
		s.logRemovalError("posters", "lookup", err)
		http.Error(w, "Failed to retrieve poster", http.StatusInternalServerError)
		return
	}
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
	ip, err := s.clientIPs.resolve(r)
	if err != nil {
		http.Error(w, "Invalid client address", http.StatusBadRequest)
		return
	}
	// Retained-room ownership uses the same canonical source key as connection admission.
	quotaOwnerKey := ip

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

	client := newClient(conn)
	defer client.close()

	rl := newRateLimiter(rateBurst, rateSustained)
	var currentRoom *Room
	var currentPeerID string
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
			closing := currentRoom.closing
			stale := currentRoom.Peers[currentPeerID] != client
			if !closing && !stale {
				delete(currentRoom.Peers, currentPeerID)
				if currentRoom.ProtocolVersion == legacyRelayProtocolVersion &&
					currentPeerID != currentRoom.HostPeerID {
					delete(currentRoom.peerVerifiers, currentPeerID)
				}
				currentRoom.LastActivityAt = time.Now()
			}
			currentRoom.mu.Unlock()
			if !closing && !stale {
				currentRoom.broadcastExcept(currentPeerID, serverMsg{
					Type:   relayTypePeerLeft,
					PeerID: currentPeerID,
				})
				s.snap.schedule()
			}
			log.Printf("peer %s left room %s (closing=%v, stale=%v)", currentPeerID, currentRoom.SessionID, closing, stale)
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
			if msg.ProtocolVersion != legacyRelayProtocolVersion && msg.ProtocolVersion != relayProtocolVersion {
				client.sendJSON(serverMsg{
					Type:            relayTypeError,
					Code:            relayErrorProtocolMismatch,
					Message:         "Unsupported relay protocol version",
					ProtocolVersion: relayProtocolVersion,
				})
				continue
			}
			if rejectRoomTransition() {
				continue
			}

			reconnectToken := msg.ReconnectToken
			var hostVerifier reconnectVerifier
			if reconnectToken == "" {
				if msg.ProtocolVersion != legacyRelayProtocolVersion {
					client.sendJSON(serverMsg{Type: relayTypeError, Code: relayErrorInvalidMessage, Message: "Modern room creation requires a reconnect token"})
					continue
				}
				var err error
				reconnectToken, hostVerifier, err = mintReconnectToken()
				if err != nil {
					client.sendJSON(serverMsg{Type: relayTypeError, Code: relayErrorInvalidMessage, Message: "Unable to create room"})
					continue
				}
			} else {
				var ok bool
				hostVerifier, ok = reconnectVerifierFromToken(reconnectToken)
				if !ok {
					client.sendJSON(serverMsg{Type: relayTypeError, Code: relayErrorInvalidMessage, Message: "Invalid reconnect token"})
					continue
				}
			}

			var rejection *serverMsg
			var oldHostClient *Client
			var hostWasAbsent bool
			s.mu.Lock()
			existing := s.rooms[msg.SessionID]
			if existing != nil {
				existing.mu.Lock()
				idempotentModernCreate :=
					!existing.closing &&
						msg.ProtocolVersion == relayProtocolVersion &&
						existing.ProtocolVersion == relayProtocolVersion &&
						msg.PeerID == existing.HostPeerID &&
						reconnectVerifierMatches(existing.hostVerifier, hostVerifier)
				if idempotentModernCreate {
					oldHostClient = existing.Peers[msg.PeerID]
					hostWasAbsent = oldHostClient == nil
					existing.Peers[msg.PeerID] = client
					existing.LastActivityAt = time.Now()
					peers := existing.peerIDs()
					existing.mu.Unlock()
					s.mu.Unlock()

					currentRoom = existing
					currentPeerID = msg.PeerID
					if oldHostClient != nil && oldHostClient != client {
						oldHostClient.close()
					}
					existingPeers := make([]string, 0, len(peers)-1)
					for _, peerID := range peers {
						if peerID != msg.PeerID {
							existingPeers = append(existingPeers, peerID)
						}
					}
					client.sendJSON(serverMsg{
						Type:            relayTypeCreated,
						SessionID:       msg.SessionID,
						HostPeerID:      msg.PeerID,
						ReconnectToken:  reconnectToken,
						ProtocolVersion: relayProtocolVersion,
						Peers:           existingPeers,
					})
					if hostWasAbsent {
						existing.broadcastExcept(msg.PeerID, serverMsg{
							Type:   relayTypePeerJoined,
							PeerID: msg.PeerID,
						})
					}
					s.snap.schedule()
					continue
				}
				authorizedLegacyReplacement :=
					len(existing.Peers) == 0 &&
						!existing.closing &&
						msg.ProtocolVersion == legacyRelayProtocolVersion &&
						existing.ProtocolVersion == legacyRelayProtocolVersion &&
						msg.PeerID == existing.HostPeerID &&
						msg.ReconnectToken != "" &&
						reconnectVerifierMatches(existing.hostVerifier, hostVerifier)
				existing.mu.Unlock()
				if !authorizedLegacyReplacement {
					rejection = &serverMsg{Type: relayTypeError, Code: relayErrorRoomExists, Message: "Room already exists"}
				}
			} else if len(s.rooms) >= maxRetainedRooms {
				rejection = &serverMsg{Type: relayTypeError, Code: relayErrorRateLimited, Message: "Too many retained rooms"}
			}
			if rejection == nil {
				var reserved bool
				if existing == nil {
					reserved = s.conns.tryCreateRoom(quotaOwnerKey)
				} else {
					reserved = s.conns.tryCreateRoomReplacing(quotaOwnerKey, existing.quotaOwnerKey)
				}
				if !reserved {
					rejection = &serverMsg{Type: relayTypeError, Code: relayErrorRateLimited, Message: "Too many rooms created"}
				}
			}
			if rejection != nil {
				s.mu.Unlock()
				client.sendJSON(*rejection)
				continue
			}
			if existing != nil {
				s.removeRoomLocked(msg.SessionID, existing)
			}
			now := time.Now()
			room := &Room{
				SessionID:       msg.SessionID,
				HostPeerID:      msg.PeerID,
				ProtocolVersion: msg.ProtocolVersion,
				hostVerifier:    hostVerifier,
				Peers:           map[string]*Client{msg.PeerID: client},
				quotaOwnerKey:   quotaOwnerKey,
				CreatedAt:       now,
				LastActivityAt:  now,
			}

			s.rooms[msg.SessionID] = room
			s.mu.Unlock()

			currentRoom = room
			currentPeerID = msg.PeerID
			log.Printf("room %s created by %s", msg.SessionID, msg.PeerID)
			client.sendJSON(serverMsg{
				Type:            relayTypeCreated,
				SessionID:       msg.SessionID,
				HostPeerID:      msg.PeerID,
				ReconnectToken:  reconnectToken,
				ProtocolVersion: msg.ProtocolVersion,
			})
			s.snap.schedule()

		case relayTypeJoin:
			if !validRelayID(msg.SessionID, maxSessionIDLength) || !validRelayID(msg.PeerID, maxPeerIDLength) {
				client.sendJSON(serverMsg{Type: relayTypeError, Code: relayErrorInvalidMessage, Message: "Invalid sessionId or peerId"})
				continue
			}
			if msg.ProtocolVersion != legacyRelayProtocolVersion && msg.ProtocolVersion != relayProtocolVersion {
				client.sendJSON(serverMsg{
					Type:            relayTypeError,
					Code:            relayErrorProtocolMismatch,
					Message:         "Unsupported relay protocol version",
					ProtocolVersion: relayProtocolVersion,
				})
				continue
			}
			if rejectRoomTransition() {
				continue
			}

			newToken, newVerifier, err := mintReconnectToken()
			if err != nil {
				client.sendJSON(serverMsg{Type: relayTypeError, Code: relayErrorInvalidMessage, Message: "Unable to join room"})
				continue
			}
			presentedVerifier, tokenValid := reconnectVerifierFromToken(msg.ReconnectToken)

			s.mu.RLock()
			room, exists := s.rooms[msg.SessionID]
			if !exists {
				s.mu.RUnlock()
				client.sendJSON(serverMsg{Type: relayTypeError, Code: relayErrorRoomNotFound, Message: "Room does not exist"})
				continue
			}
			if s.beforeJoinRoomLock != nil {
				s.beforeJoinRoomLock()
			}
			room.mu.Lock()
			if s.rooms[msg.SessionID] != room {
				room.mu.Unlock()
				s.mu.RUnlock()
				client.sendJSON(serverMsg{Type: relayTypeError, Code: relayErrorRoomNotFound, Message: "Room does not exist"})
				continue
			}
			s.mu.RUnlock()
			if room.closing {
				room.mu.Unlock()
				client.sendJSON(serverMsg{Type: relayTypeError, Code: relayErrorRoomNotFound, Message: "Room does not exist"})
				continue
			}
			if room.ProtocolVersion != msg.ProtocolVersion {
				room.mu.Unlock()
				client.sendJSON(serverMsg{
					Type:            relayTypeError,
					Code:            relayErrorProtocolMismatch,
					Message:         "Client and room protocol versions are incompatible",
					ProtocolVersion: room.ProtocolVersion,
				})
				continue
			}

			existingClient, occupied := room.Peers[msg.PeerID]
			expectedVerifier, identityReserved := room.peerVerifiers[msg.PeerID]
			responseToken := newToken
			responseVerifier := newVerifier
			authorized := false
			if room.ProtocolVersion == relayProtocolVersion {
				switch {
				case msg.PeerID == room.HostPeerID:
					authorized = tokenValid && reconnectVerifierMatches(room.hostVerifier, presentedVerifier)
					responseToken = msg.ReconnectToken
					responseVerifier = room.hostVerifier
				case identityReserved:
					authorized = tokenValid && reconnectVerifierMatches(expectedVerifier, presentedVerifier)
					responseToken = msg.ReconnectToken
					responseVerifier = expectedVerifier
				case occupied:
					authorized = false
				default:
					authorized = tokenValid
					responseToken = msg.ReconnectToken
					responseVerifier = presentedVerifier
				}
			} else if msg.PeerID == room.HostPeerID {
				switch {
				case tokenValid && reconnectVerifierMatches(room.hostVerifier, presentedVerifier):
					authorized = true
					responseToken = msg.ReconnectToken
					responseVerifier = room.hostVerifier
				case msg.ReconnectToken == "" &&
					!occupied &&
					room.quotaOwnerKey != "" &&
					room.quotaOwnerKey == quotaOwnerKey:
					// Tokenless host reconnect is retained only for unversioned rooms,
					// only within this process, and only from the creating source.
					authorized = true
					responseToken = ""
					responseVerifier = room.hostVerifier
				}
			} else {
				// Legacy guests have no durable proof. Never let one replace a live
				// identity; disconnected identity reuse remains confined to legacy rooms.
				authorized = !occupied
			}

			if !authorized {
				room.mu.Unlock()
				client.sendJSON(serverMsg{Type: relayTypeError, Code: relayErrorPeerIdUnavailable, Message: "Peer ID is unavailable"})
				continue
			}
			if !occupied {
				roomFull := false
				if room.ProtocolVersion == relayProtocolVersion {
					if msg.PeerID != room.HostPeerID && !identityReserved {
						roomFull = len(room.peerVerifiers) >= maxRoomSize-1
					}
				} else {
					admissionLimit := maxRoomSize
					_, hostConnected := room.Peers[room.HostPeerID]
					if msg.PeerID != room.HostPeerID && !hostConnected {
						admissionLimit--
					}
					roomFull = len(room.Peers) >= admissionLimit
				}
				if roomFull {
					room.mu.Unlock()
					client.sendJSON(serverMsg{Type: relayTypeError, Code: relayErrorRoomFull, Message: "Room is full"})
					continue
				}
			}

			if room.peerVerifiers == nil {
				room.peerVerifiers = make(map[string]reconnectVerifier)
			}
			room.Peers[msg.PeerID] = client
			if room.ProtocolVersion == relayProtocolVersion && msg.PeerID != room.HostPeerID {
				room.peerVerifiers[msg.PeerID] = responseVerifier
			}
			room.LastActivityAt = time.Now()
			peers := room.peerIDs()
			hostPeerID := room.HostPeerID
			roomProtocolVersion := room.ProtocolVersion
			room.mu.Unlock()

			currentRoom = room
			currentPeerID = msg.PeerID
			if occupied && existingClient != client {
				existingClient.close()
			}
			log.Printf("peer %s joined room %s", msg.PeerID, msg.SessionID)

			existingPeers := make([]string, 0, len(peers)-1)
			for _, peerID := range peers {
				if peerID != msg.PeerID {
					existingPeers = append(existingPeers, peerID)
				}
			}
			client.sendJSON(serverMsg{
				Type:            relayTypeJoined,
				SessionID:       msg.SessionID,
				HostPeerID:      hostPeerID,
				ReconnectToken:  responseToken,
				ProtocolVersion: roomProtocolVersion,
				Peers:           existingPeers,
			})
			room.broadcastExcept(msg.PeerID, serverMsg{Type: relayTypePeerJoined, PeerID: msg.PeerID})
			s.snap.schedule()

		case relayTypeLeave:
			if currentRoom == nil {
				client.sendJSON(serverMsg{Type: relayTypeError, Code: relayErrorNotInRoom, Message: "Not in a room"})
				continue
			}
			room := currentRoom
			presentedVerifier, tokenValid := reconnectVerifierFromToken(msg.ReconnectToken)
			room.mu.Lock()
			currentClient := room.Peers[currentPeerID] == client
			isGuest := currentPeerID != room.HostPeerID
			authorized := currentClient && isGuest && !room.closing && msg.ProtocolVersion == room.ProtocolVersion
			if authorized && room.ProtocolVersion == relayProtocolVersion {
				expectedVerifier, ok := room.peerVerifiers[currentPeerID]
				authorized = ok && tokenValid && reconnectVerifierMatches(expectedVerifier, presentedVerifier)
			}
			if !authorized {
				room.mu.Unlock()
				client.sendJSON(serverMsg{Type: relayTypeError, Code: relayErrorPeerIdUnavailable, Message: "Unable to release peer identity"})
				continue
			}
			releasedPeerID := currentPeerID
			persistedMembershipChanged := room.ProtocolVersion == relayProtocolVersion
			delete(room.Peers, releasedPeerID)
			delete(room.peerVerifiers, releasedPeerID)
			room.LastActivityAt = time.Now()
			room.mu.Unlock()

			currentRoom = nil
			currentPeerID = ""
			if persistedMembershipChanged {
				if err := s.snap.writeAndLog(); err != nil {
					client.sendJSON(serverMsg{Type: relayTypeError, Code: relayErrorInvalidMessage, Message: "Unable to persist released peer identity"})
					continue
				}
			} else {
				s.snap.schedule()
			}
			if s.beforeTerminalDelivery != nil {
				s.beforeTerminalDelivery()
			}
			client.sendJSON(serverMsg{
				Type:            relayTypeLeft,
				SessionID:       room.SessionID,
				PeerID:          releasedPeerID,
				ProtocolVersion: room.ProtocolVersion,
			})
			room.broadcastExcept(releasedPeerID, serverMsg{Type: relayTypePeerLeft, PeerID: releasedPeerID})

		case relayTypeEndSession:
			if currentRoom == nil {
				client.sendJSON(serverMsg{Type: relayTypeError, Code: relayErrorNotInRoom, Message: "Not in a room"})
				continue
			}
			room := currentRoom
			presentedVerifier, tokenValid := reconnectVerifierFromToken(msg.ReconnectToken)
			s.mu.Lock()
			room.mu.Lock()
			authorized :=
				s.rooms[room.SessionID] == room &&
					!room.closing &&
					currentPeerID == room.HostPeerID &&
					room.Peers[currentPeerID] == client &&
					msg.ProtocolVersion == room.ProtocolVersion
			if authorized && room.ProtocolVersion == relayProtocolVersion {
				authorized = tokenValid && reconnectVerifierMatches(room.hostVerifier, presentedVerifier)
			}
			if !authorized {
				room.mu.Unlock()
				s.mu.Unlock()
				client.sendJSON(serverMsg{Type: relayTypeError, Code: relayErrorPeerIdUnavailable, Message: "Unable to end room"})
				continue
			}
			room.closing = true
			guests := make([]*Client, 0, len(room.Peers)-1)
			for peerID, peerClient := range room.Peers {
				if peerID != currentPeerID {
					guests = append(guests, peerClient)
				}
			}
			s.removeRoomLocked(room.SessionID, room)
			room.mu.Unlock()
			s.mu.Unlock()

			// Persist after releasing both locks and before any success frame.
			// The room remains undiscoverable while existing membership stays
			// authoritative for orderly terminal delivery.
			if err := s.snap.writeAndLog(); err != nil {
				client.sendJSON(serverMsg{Type: relayTypeError, Code: relayErrorInvalidMessage, Message: "Unable to persist ended room"})
				room.mu.Lock()
				clear(room.Peers)
				clear(room.peerVerifiers)
				room.mu.Unlock()
				currentRoom = nil
				currentPeerID = ""
				for _, guest := range guests {
					guest.close()
				}
				continue
			}
			if s.beforeTerminalDelivery != nil {
				s.beforeTerminalDelivery()
			}
			endedMessage := serverMsg{
				Type:            relayTypeEnded,
				SessionID:       room.SessionID,
				ProtocolVersion: room.ProtocolVersion,
			}
			client.sendJSON(endedMessage)
			for _, guest := range guests {
				guest.sendJSONAndWait(endedMessage)
			}

			room.mu.Lock()
			clear(room.Peers)
			clear(room.peerVerifiers)
			room.mu.Unlock()
			currentRoom = nil
			currentPeerID = ""
			for _, guest := range guests {
				guest.close()
			}

		case relayTypeBroadcast:
			if currentRoom == nil {
				client.sendJSON(serverMsg{Type: relayTypeError, Code: relayErrorNotInRoom, Message: "Not in a room"})
				continue
			}
			if !currentRoom.broadcastFrom(currentPeerID, client, serverMsg{
				Type:    relayTypeMessage,
				From:    currentPeerID,
				Payload: msg.Payload,
			}) {
				client.close()
				return
			}

		case relayTypeSendTo:
			if currentRoom == nil {
				client.sendJSON(serverMsg{Type: relayTypeError, Code: relayErrorNotInRoom, Message: "Not in a room"})
				continue
			}
			if !validRelayID(msg.To, maxPeerIDLength) {
				client.sendJSON(serverMsg{Type: relayTypeError, Code: relayErrorInvalidMessage, Message: "Invalid to field"})
				continue
			}
			switch currentRoom.sendFrom(currentPeerID, client, msg.To, serverMsg{
				Type:    relayTypeMessage,
				From:    currentPeerID,
				Payload: msg.Payload,
			}) {
			case directedSenderUnavailable:
				client.close()
				return
			case directedTargetMissing:
				client.sendJSON(serverMsg{Type: relayTypeError, Code: relayErrorNotInRoom, Message: "Target peer not found"})
			}

		case relayTypePing:
			client.sendJSON(serverMsg{Type: relayTypePong})

		default:
			client.sendJSON(serverMsg{Type: relayTypeError, Code: relayErrorInvalidMessage, Message: "Unknown message type"})
		}
	}
}

func newHTTPServer(addr string, handler http.Handler) *http.Server {
	return &http.Server{
		Addr:           addr,
		Handler:        handler,
		ReadTimeout:    posterUploadReadTimeout,
		WriteTimeout:   httpResponseWriteTimeout,
		MaxHeaderBytes: maxHTTPHeaderBytes,
	}
}

func main() {
	addr := flag.String("addr", ":8080", "Listen address")
	logDir := flag.String("log-dir", "/data/logs", "Directory for log file storage")
	posterDir := flag.String("poster-dir", "/data/posters", "Directory for Discord poster storage")
	stateFile := flag.String("state-file", "/data/rooms.json", "Path to room snapshot file")
	flag.Parse()

	trustedProxyCIDRs, err := parseTrustedProxyCIDRs(os.Getenv("TRUSTED_PROXY_CIDRS"))
	if err != nil {
		log.Fatalf("invalid TRUSTED_PROXY_CIDRS")
	}
	clientIPs := newClientIPResolver(trustedProxyCIDRs)
	srv := newServer(*logDir, *stateFile, *posterDir, clientIPs)

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

	httpSrv := newHTTPServer(*addr, mux)

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
