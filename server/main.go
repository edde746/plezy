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
	peerReservationGrace       = emptyRoomMaxAge
	roomMaxAge                 = 24 * time.Hour
	writeWait                  = 10 * time.Second
	httpResponseWriteMargin    = 10 * time.Second
	httpResponseWriteTimeout   = oauthResultWait + httpResponseWriteMargin
	pongWait                   = 60 * time.Second
	pingInterval               = 30 * time.Second
	maxLogSize                 = 1 * 1024 * 1024
	logMaxAge                  = 3 * 24 * time.Hour
	logIDLength                = 5
	logRateInterval            = 1 * time.Minute
	logLookupRateBurst         = 10
	logLookupRateSustained     = 1
	maxLogEntries              = 500
	maxFailedLogLookupSources  = 4096
	maxConcurrentLogLookups    = 32
	maxHTTPHeaderBytes         = 64 * 1024
	maxPosterSize              = 5 * 1024 * 1024
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
	snapshotFormatVersion      = 4
	snapshotDebounce           = 100 * time.Millisecond
	snapshotFlushTimeout       = 5 * time.Second
	snapshotMaxFileSize        = 4 * 1024 * 1024
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin:     func(r *http.Request) bool { return true },
}


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


type reconnectVerifier [sha256.Size]byte

type peerReservation struct {
	verifier       reconnectVerifier
	absentSince    time.Time
	releasePending bool    // runtime-only: pending releases are omitted from snapshots
	releaseClient  *Client // runtime-only: identifies the client that staged the release
}

type Room struct {
	SessionID        string
	HostPeerID       string
	ProtocolVersion  int
	hostVerifier     reconnectVerifier
	peerReservations map[string]peerReservation
	Peers            map[string]*Client `json:"-"`
	quotaOwnerKey    string             `json:"-"`
	mu               sync.RWMutex       `json:"-"`
	closing          bool               `json:"-"`
	CreatedAt        time.Time
	LastActivityAt   time.Time
}


// Nanosecond timestamps preserve exact absence state; zero means connected.
type peerReservationSnapshot struct {
	Verifier            string `json:"verifier"`
	AbsentSinceUnixNano int64  `json:"absentSince,omitempty"`
}

type roomSnapshot struct {
	SessionID              string                             `json:"sessionId"`
	HostPeerID             string                             `json:"hostPeerId"`
	ProtocolVersion        int                                `json:"protocolVersion,omitempty"`
	HostReconnectVerifier  string                             `json:"hostReconnectVerifier"`
	PeerReservations       map[string]peerReservationSnapshot `json:"peerReservations,omitempty"`
	PeerReconnectVerifiers map[string]string                  `json:"peerReconnectVerifiers,omitempty"` // v2/v3 decode only
	CreatedAt              time.Time                          `json:"createdAt"`
	LastActivityAt         time.Time                          `json:"lastActivityAt"`
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

// pruneExpiredPeerReservationsLocked removes expired, disconnected guest
// reservations; the caller must hold room.mu.
func pruneExpiredPeerReservationsLocked(room *Room, now time.Time) bool {
	changed := false
	for peerID, reservation := range room.peerReservations {
		if reservation.releasePending ||
			reservation.absentSince.IsZero() ||
			now.Before(reservation.absentSince.Add(peerReservationGrace)) {
			continue
		}
		if _, connected := room.Peers[peerID]; connected {
			continue
		}
		delete(room.peerReservations, peerID)
		changed = true
	}
	return changed
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


const logFileExt = ".log"

var errLogStoreFull = errors.New("log store full")

// logStore rejects uploads when its artifact-count quota is full.
type logStore struct {
	artifactStore
	rateLimit        map[string]time.Time // IP -> last upload time
	failedLookupRate map[string]*rateLimiter
}

func newLogStore(dir string) *logStore {
	return newLogStoreWithRemover(dir, os.Remove)
}

func newLogStoreWithRemover(dir string, removeFile func(string) error) *logStore {
	if err := os.MkdirAll(dir, 0755); err != nil {
		log.Fatalf("failed to create log dir %s: %v", dir, err)
	}
	ls := &logStore{
		artifactStore: artifactStore{
			entries:         make(map[string]artifactEntry),
			pendingRemovals: make(map[string]pendingRemoval),
			dir:             dir,
			name:            "logs",
			maxAge:          logMaxAge,
			removeFile:      removeFile,
			generateID:      generateLogID,
			idFromFilename:  logIDFromFilename,
			acceptLoaded: func(_ string, size int64) (string, bool) {
				return "", size > 0 && size <= maxLogSize
			},
			limit:       maxLogEntries,
			cost:        func(int64) int64 { return 1 },
			pendingCost: func(pendingRemoval) int64 { return 1 },
			errFull:     errLogStoreFull,
		},
		rateLimit:        make(map[string]time.Time),
		failedLookupRate: make(map[string]*rateLimiter),
	}
	ls.startupErr = ls.loadExisting(time.Now())
	return ls
}

func (ls *logStore) filePath(id string) string {
	return ls.artifactStore.filePath(id + logFileExt)
}

func generateLogID() string {
	return generateID(logIDLength)
}

func logIDFromFilename(filename string) (string, bool) {
	if filepath.Ext(filename) != logFileExt {
		return "", false
	}
	id := strings.TrimSuffix(filename, logFileExt)
	return id, validID(id, logIDLength)
}

func (ls *logStore) store(data []byte, now time.Time) (string, artifactEntry, error) {
	if len(data) == 0 {
		return "", artifactEntry{}, errors.New("empty log")
	}
	if len(data) > maxLogSize {
		return "", artifactEntry{}, errors.New("log too large")
	}
	return ls.put(data, logFileExt, "", now)
}

func (ls *logStore) lookup(id string, now time.Time) (artifactEntry, bool, error) {
	if !validID(id, logIDLength) {
		return artifactEntry{}, false, nil
	}
	return ls.lookupEntry(id, now, nil)
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

func (ls *logStore) cleanup(now time.Time) error {
	ls.mu.Lock()
	defer ls.mu.Unlock()
	removalErr := ls.cleanupLocked(now)
	cleanupRateWindows(ls.rateLimit, now, logRateInterval)
	cleanupRateLimiters(ls.failedLookupRate, now, nil)
	return removalErr
}


var errPosterStoreFull = errors.New("poster store full")

// posterStore evicts oldest artifacts to stay within its byte quota.
type posterStore struct {
	artifactStore
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
	ps := &posterStore{artifactStore{
		entries:         make(map[string]artifactEntry),
		pendingRemovals: make(map[string]pendingRemoval),
		dir:             dir,
		name:            "posters",
		maxAge:          maxAge,
		removeFile:      removeFile,
		generateID:      generatePosterID,
		idFromFilename:  posterIDFromFilename,
		acceptLoaded: func(filename string, _ int64) (string, bool) {
			return posterContentTypeForExt(filepath.Ext(filename))
		},
		limit: maxBytes,
		cost:  func(size int64) int64 { return size },
		pendingCost: func(pending pendingRemoval) int64 {
			// Unknown debt cannot be sized safely, so it is kept out of the
			// quota: a permanent directory or stat failure must not deny
			// otherwise capacity-safe uploads.
			if !pending.sizeKnown {
				return 0
			}
			return pending.size
		},
		evictToFit:          true,
		retryKnownDebtOnPut: true,
		errFull:             errPosterStoreFull,
	}}
	ps.startupErr = ps.loadExisting(time.Now())
	return ps
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

func (ps *posterStore) store(data []byte, contentType string, now time.Time) (string, artifactEntry, error) {
	entrySize := int64(len(data))
	if entrySize <= 0 {
		return "", artifactEntry{}, errors.New("empty poster")
	}
	if entrySize > ps.limit {
		return "", artifactEntry{}, errors.New("poster exceeds store size")
	}
	ext, ok := posterExtForContentType(contentType)
	if !ok {
		return "", artifactEntry{}, errors.New("unsupported poster type")
	}
	return ps.put(data, ext, strings.ToLower(strings.SplitN(contentType, ";", 2)[0]), now)
}

func (ps *posterStore) lookup(filename string, now time.Time) (artifactEntry, bool, error) {
	id, ok := posterIDFromFilename(filename)
	if !ok {
		return artifactEntry{}, false, nil
	}
	return ps.lookupEntry(id, now, func(entry artifactEntry) bool {
		return entry.Filename == filename
	})
}


var errSnapshotterStopped = errors.New("snapshot writer is stopped")

type terminalMutationOutcome struct {
	err     error
	deliver bool
}

type terminalMutationTicket struct {
	seq    uint64
	result <-chan terminalMutationOutcome
}

type registeredTerminalMutation struct {
	seq      uint64
	complete func(error) terminalMutationOutcome
	result   chan terminalMutationOutcome
}

type snapshotter struct {
	path                 string
	dir                  string
	trigger              chan struct{}
	urgent               chan struct{}
	flush                chan chan error
	exited               chan struct{}
	build                func() stateSnapshot
	capture              func(func() uint64) (stateSnapshot, uint64)
	persist              func([]byte) error
	syncDir              func(string) error
	debounce             time.Duration
	writeMu              sync.Mutex
	beforeDebounceWait   func() // test-only signal after a trigger enters its debounce window
	beforeCapture        func() // test-only barrier immediately before generation capture
	afterSequenceCapture func() // test-only barrier inside the protected capture boundary

	stateMu    sync.Mutex
	dirtySeq   uint64
	durableSeq uint64
	terminals  []*registeredTerminalMutation
	stopped    bool

	stopOnce sync.Once
	stopErr  error

	errMu      sync.Mutex
	lastErrLog time.Time

	dirErrMu      sync.Mutex
	lastDirErrLog time.Time
}

func newSnapshotter(path string, build func() stateSnapshot) *snapshotter {
	dir := filepath.Dir(path)
	if err := os.MkdirAll(dir, 0755); err != nil {
		log.Printf("snapshot: mkdir %s: %v", dir, err)
	}
	sn := &snapshotter{
		path:     path,
		dir:      dir,
		trigger:  make(chan struct{}, 1),
		urgent:   make(chan struct{}, 1),
		flush:    make(chan chan error),
		exited:   make(chan struct{}),
		build:    build,
		syncDir:  syncSnapshotDirectory,
		debounce: snapshotDebounce,
	}
	sn.capture = func(captureSequence func() uint64) (stateSnapshot, uint64) {
		targetSeq := captureSequence()
		return sn.build(), targetSeq
	}
	sn.persist = sn.persistAtomic
	return sn
}

// recordMutation publishes a mutation after the caller changes state and before
// releasing the lock that made it visible.
func (sn *snapshotter) recordMutation() uint64 {
	sn.stateMu.Lock()
	if sn.stopped {
		sn.stateMu.Unlock()
		return 0
	}
	sn.dirtySeq++
	seq := sn.dirtySeq
	sn.signalLocked()
	sn.stateMu.Unlock()
	return seq
}

// recordTerminalMutation publishes a mutation and its buffered outcome channel.
func (sn *snapshotter) recordTerminalMutation(
	complete func(error) terminalMutationOutcome,
) *terminalMutationTicket {
	result := make(chan terminalMutationOutcome, 1)
	sn.stateMu.Lock()
	if sn.stopped {
		sn.stateMu.Unlock()
		if complete == nil {
			result <- terminalMutationOutcome{err: errSnapshotterStopped, deliver: true}
		} else {
			// Run rollback asynchronously after the caller releases its state lock.
			go func() {
				result <- complete(errSnapshotterStopped)
			}()
		}
		return &terminalMutationTicket{result: result}
	}
	sn.dirtySeq++
	seq := sn.dirtySeq
	sn.terminals = append(sn.terminals, &registeredTerminalMutation{
		seq:      seq,
		complete: complete,
		result:   result,
	})
	sn.signalLocked()
	select {
	case sn.urgent <- struct{}{}:
	default:
	}
	sn.stateMu.Unlock()
	return &terminalMutationTicket{seq: seq, result: result}
}

func (sn *snapshotter) signalLocked() {
	select {
	case sn.trigger <- struct{}{}:
	default:
	}
}

func (sn *snapshotter) captureSequence() uint64 {
	sn.stateMu.Lock()
	targetSeq := sn.dirtySeq
	afterCapture := sn.afterSequenceCapture
	sn.stateMu.Unlock()
	if afterCapture != nil {
		afterCapture()
	}
	return targetSeq
}

func (sn *snapshotter) waitForDurable(ticket *terminalMutationTicket) terminalMutationOutcome {
	return <-ticket.result
}

func (sn *snapshotter) waitForDurableWithin(
	ticket *terminalMutationTicket,
	timeout time.Duration,
) terminalMutationOutcome {
	timer := time.NewTimer(timeout)
	defer timer.Stop()
	select {
	case outcome := <-ticket.result:
		return outcome
	case <-timer.C:
		return terminalMutationOutcome{
			err:     errors.New("snapshot rewrite: timed out waiting for persistence"),
			deliver: true,
		}
	}
}

func (sn *snapshotter) run() {
	defer close(sn.exited)
	for {
		select {
		case <-sn.trigger:
			if sn.beforeDebounceWait != nil {
				sn.beforeDebounceWait()
			}
			timer := time.NewTimer(sn.debounce)
			select {
			case <-timer.C:
			case <-sn.urgent:
			case reply := <-sn.flush:
				if !timer.Stop() {
					select {
					case <-timer.C:
					default:
					}
				}
				err := sn.flushLatestAndStop()
				reply <- err
				return
			}
			if !timer.Stop() {
				select {
				case <-timer.C:
				default:
				}
			}
			// Drain pre-capture tokens; later mutations re-arm the channels.
			select {
			case <-sn.trigger:
			default:
			}
			select {
			case <-sn.urgent:
			default:
			}
			_, err := sn.writeNextGeneration()
			if err != nil {
				sn.logWriteErr(err)
			}
		case reply := <-sn.flush:
			err := sn.flushLatestAndStop()
			reply <- err
			return
		}
	}
}

// write is retained for synchronous storage tests; production uses the single
// writer's writeNextGeneration.
func (sn *snapshotter) write() error {
	sn.writeMu.Lock()
	defer sn.writeMu.Unlock()
	_, err := sn.captureAndPersist()
	return err
}

func (sn *snapshotter) captureAndPersist() (uint64, error) {
	snapshot, targetSeq := sn.capture(sn.captureSequence)
	data, err := json.Marshal(snapshot)
	if err != nil {
		return targetSeq, err
	}
	if len(data) > snapshotMaxFileSize {
		return targetSeq, fmt.Errorf("snapshot exceeds maximum size: %d > %d bytes", len(data), snapshotMaxFileSize)
	}
	return targetSeq, sn.persist(data)
}

func (sn *snapshotter) writeNextGeneration() (bool, error) {
	sn.stateMu.Lock()
	if sn.dirtySeq <= sn.durableSeq {
		sn.stateMu.Unlock()
		return false, nil
	}
	beforeCapture := sn.beforeCapture
	sn.stateMu.Unlock()
	if beforeCapture != nil {
		beforeCapture()
	}
	sn.writeMu.Lock()
	targetSeq, err := sn.captureAndPersist()
	sn.writeMu.Unlock()

	sn.stateMu.Lock()
	if err == nil && targetSeq > sn.durableSeq {
		sn.durableSeq = targetSeq
	}
	coveredCount := 0
	for coveredCount < len(sn.terminals) && sn.terminals[coveredCount].seq <= targetSeq {
		coveredCount++
	}
	covered := sn.terminals[:coveredCount:coveredCount]
	sn.terminals = sn.terminals[coveredCount:]
	if len(sn.terminals) == 0 {
		sn.terminals = nil
	}
	sn.stateMu.Unlock()

	// Continuations roll back failed releases before later mutations are captured.
	for _, terminal := range covered {
		outcome := terminalMutationOutcome{err: err, deliver: true}
		if terminal.complete != nil {
			outcome = terminal.complete(err)
		}
		terminal.result <- outcome
	}
	return true, err
}

func (sn *snapshotter) flushLatestAndStop() error {
	for {
		sn.stateMu.Lock()
		if sn.dirtySeq <= sn.durableSeq {
			sn.stopped = true
			sn.stateMu.Unlock()
			return nil
		}
		sn.stateMu.Unlock()

		_, err := sn.writeNextGeneration()
		if err == nil {
			continue
		}
		sn.logWriteErr(err)
		sn.failPendingAndStop(err)
		return err
	}
}

func (sn *snapshotter) failPendingAndStop(err error) {
	sn.stateMu.Lock()
	sn.stopped = true
	pending := sn.terminals
	sn.terminals = nil
	sn.stateMu.Unlock()
	for _, terminal := range pending {
		outcome := terminalMutationOutcome{err: err, deliver: true}
		if terminal.complete != nil {
			outcome = terminal.complete(err)
		}
		terminal.result <- outcome
	}
}

func syncSnapshotDirectory(dir string) error {
	d, err := os.Open(dir)
	if err != nil {
		return err
	}
	syncErr := d.Sync()
	closeErr := d.Close()
	return errors.Join(syncErr, closeErr)
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
	// Rename commits the file-synced replacement. Directory-sync failure is
	// warning-only after that boundary.
	if err := sn.syncDir(sn.dir); err != nil {
		sn.logDirSyncErr(err)
	}
	return nil
}

func (sn *snapshotter) flushAndStop(timeout time.Duration) error {
	sn.stopOnce.Do(func() {
		ctx, cancel := context.WithTimeout(context.Background(), timeout)
		defer cancel()
		reply := make(chan error, 1)
		select {
		case sn.flush <- reply:
		case <-ctx.Done():
			sn.stopErr = errors.New("snapshot flush: timed out sending flush signal")
			return
		}
		select {
		case sn.stopErr = <-reply:
		case <-ctx.Done():
			sn.stopErr = errors.New("snapshot flush: timed out waiting for write")
			return
		}
		select {
		case <-sn.exited:
		case <-ctx.Done():
		}
	})
	return sn.stopErr
}

// logWriteErr throttles pre-commit snapshot errors to once per hour.
func (sn *snapshotter) logWriteErr(err error) {
	sn.errMu.Lock()
	defer sn.errMu.Unlock()
	if time.Since(sn.lastErrLog) < time.Hour {
		return
	}
	sn.lastErrLog = time.Now()
	log.Printf("snapshot: write failed before rename commit: %v", err)
}

// logDirSyncErr independently throttles post-rename directory-sync warnings.
func (sn *snapshotter) logDirSyncErr(err error) {
	sn.dirErrMu.Lock()
	defer sn.dirErrMu.Unlock()
	if time.Since(sn.lastDirErrLog) < time.Hour {
		return
	}
	sn.lastDirErrLog = time.Now()
	log.Printf("snapshot: parent directory sync failed after rename commit: %v", err)
}

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
	rooms                  map[string]*Room
	logs                   *logStore
	posters                *posterStore
	posterUploads          *posterUploadLimiter
	logLookups             chan struct{}
	posterBodyReadTimeout  time.Duration
	conns                  *connTracker
	clientIPs              clientIPResolver
	snap                   *snapshotter
	oauth                  *oauthProxy // nil when OAUTH_BASE_URL is unset
	removalErrors          removalErrorThrottle
	beforeJoinRoomLock     func() // test-only deterministic admission barrier
	beforeLeaveRoomLock    func() // test-only mutation/capture ordering barrier
	beforeTerminalDelivery func() // test-only post-persistence, pre-delivery barrier
	mu                     sync.RWMutex
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
	s.snap.capture = s.captureSnapshot
	rewriteReservations, err := s.loadSnapshot(stateFile)
	if err != nil {
		log.Printf("snapshot: load error: %v", err)
	}
	go s.snap.run()
	if rewriteReservations {
		ticket := s.snap.recordTerminalMutation(nil)
		if outcome := s.snap.waitForDurableWithin(ticket, snapshotFlushTimeout); outcome.err != nil {
			log.Printf("snapshot: v4 reservation rewrite failed: %v", outcome.err)
		}
	}
	go s.cleanupLoop()
	return s
}

// removeRoomLocked removes only the authoritative entry and releases its
// current-process quota reservation once.
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

// buildSnapshot is the synchronous test entry; production uses captureSnapshot.
func (s *Server) buildSnapshot() stateSnapshot {
	snapshot, _ := s.captureSnapshot(func() uint64 { return 0 })
	return snapshot
}

// captureSnapshot holds s.mu -> room.mu while copying state and its covered
// generation, then releases locks before marshal or I/O.
func (s *Server) captureSnapshot(captureSequence func() uint64) (stateSnapshot, uint64) {
	s.mu.RLock()
	rooms := make([]*Room, 0, len(s.rooms))
	for _, room := range s.rooms {
		room.mu.RLock()
		rooms = append(rooms, room)
	}

	targetSeq := captureSequence()
	snapshot := stateSnapshot{
		Version: snapshotFormatVersion,
		SavedAt: time.Now(),
		Rooms:   make([]roomSnapshot, 0, len(rooms)),
	}
	for _, room := range rooms {
		var reservations map[string]peerReservationSnapshot
		if len(room.peerReservations) != 0 {
			for peerID, reservation := range room.peerReservations {
				if reservation.releasePending {
					continue
				}
				if reservations == nil {
					reservations = make(map[string]peerReservationSnapshot, len(room.peerReservations))
				}
				var absentSinceUnixNano int64
				if !reservation.absentSince.IsZero() {
					absentSinceUnixNano = reservation.absentSince.UnixNano()
				}
				reservations[peerID] = peerReservationSnapshot{
					Verifier:            encodeReconnectVerifier(reservation.verifier),
					AbsentSinceUnixNano: absentSinceUnixNano,
				}
			}
		}
		snapshot.Rooms = append(snapshot.Rooms, roomSnapshot{
			SessionID:             room.SessionID,
			HostPeerID:            room.HostPeerID,
			ProtocolVersion:       room.ProtocolVersion,
			HostReconnectVerifier: encodeReconnectVerifier(room.hostVerifier),
			PeerReservations:      reservations,
			CreatedAt:             room.CreatedAt,
			LastActivityAt:        room.LastActivityAt,
		})
	}

	for index := len(rooms) - 1; index >= 0; index-- {
		rooms[index].mu.RUnlock()
	}
	s.mu.RUnlock()
	return snapshot, targetSeq
}

// loadSnapshot restores rooms. Missing or corrupt files allow startup; the
// rewrite flag requests persistence of migration or pruning.
func (s *Server) loadSnapshot(path string) (bool, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		if errors.Is(err, fs.ErrNotExist) {
			log.Printf("snapshot: no file at %s, starting fresh", path)
			return false, nil
		}
		log.Printf("snapshot: read error, starting fresh: %v", err)
		return false, nil
	}
	if len(data) > snapshotMaxFileSize {
		log.Printf("snapshot: file too large (%d bytes), starting fresh", len(data))
		return false, nil
	}
	var snap stateSnapshot
	if err := json.Unmarshal(data, &snap); err != nil {
		log.Printf("snapshot: corrupt file at %s, starting fresh: %v", path, err)
		return false, nil
	}
	if snap.Version != 2 && snap.Version != 3 && snap.Version != snapshotFormatVersion {
		log.Printf("snapshot: unknown version %d, starting fresh", snap.Version)
		return false, nil
	}
	now := time.Now()
	rewriteReservations := snap.Version != snapshotFormatVersion
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
			return false, nil
		}

		var reservations map[string]peerReservation
		validReservations := true
		switch {
		case r.ProtocolVersion == legacyRelayProtocolVersion &&
			(len(r.PeerReservations) != 0 || len(r.PeerReconnectVerifiers) != 0):
			validReservations = false
		case snap.Version == snapshotFormatVersion && len(r.PeerReconnectVerifiers) != 0:
			validReservations = false
		case snap.Version == snapshotFormatVersion:
			if len(r.PeerReservations) > maxRoomSize-1 {
				validReservations = false
				break
			}
			if len(r.PeerReservations) != 0 {
				reservations = make(map[string]peerReservation, len(r.PeerReservations))
			}
			for peerID, encoded := range r.PeerReservations {
				verifier, verifierOK := reconnectVerifierFromSnapshot(encoded.Verifier)
				if !validRelayID(peerID, maxPeerIDLength) ||
					peerID == r.HostPeerID ||
					!verifierOK {
					validReservations = false
					break
				}
				absentSince := now
				if encoded.AbsentSinceUnixNano == 0 {
					rewriteReservations = true
				} else {
					absentSince = time.Unix(0, encoded.AbsentSinceUnixNano)
					if absentSince.After(now) {
						absentSince = now
						rewriteReservations = true
					} else if !now.Before(absentSince.Add(peerReservationGrace)) {
						rewriteReservations = true
						continue
					}
				}
				reservations[peerID] = peerReservation{
					verifier:    verifier,
					absentSince: absentSince,
				}
			}
		default:
			if len(r.PeerReconnectVerifiers) > maxRoomSize-1 {
				validReservations = false
				break
			}
			if len(r.PeerReconnectVerifiers) != 0 {
				reservations = make(map[string]peerReservation, len(r.PeerReconnectVerifiers))
			}
			for peerID, encodedVerifier := range r.PeerReconnectVerifiers {
				verifier, verifierOK := reconnectVerifierFromSnapshot(encodedVerifier)
				if !validRelayID(peerID, maxPeerIDLength) ||
					peerID == r.HostPeerID ||
					!verifierOK {
					validReservations = false
					break
				}
				reservations[peerID] = peerReservation{
					verifier:    verifier,
					absentSince: now,
				}
			}
		}
		if !validReservations {
			skipped++
			continue
		}

		restored[r.SessionID] = &Room{
			SessionID:        r.SessionID,
			HostPeerID:       r.HostPeerID,
			ProtocolVersion:  r.ProtocolVersion,
			hostVerifier:     hostVerifier,
			peerReservations: reservations,
			Peers:            make(map[string]*Client),
			CreatedAt:        r.CreatedAt,
			LastActivityAt:   r.LastActivityAt,
		}
	}
	s.mu.Lock()
	s.rooms = restored
	s.mu.Unlock()
	log.Printf("snapshot: loaded %d rooms, skipped %d invalid or expired rooms", len(restored), skipped)
	return rewriteReservations, nil
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
	var expiredClients []*Client
	for id, room := range s.rooms {
		room.mu.Lock()
		roomChanged := pruneExpiredPeerReservationsLocked(room, now)
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
			roomChanged = true
		}
		if roomChanged {
			s.snap.recordMutation()
		}
		room.mu.Unlock()
	}
	roomCount := len(s.rooms)
	s.mu.Unlock()

	for _, client := range expiredClients {
		client.close()
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
		entry   artifactEntry
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
	if err := controller.SetWriteDeadline(time.Now().Add(httpResponseWriteTimeout)); err != nil &&
		!errors.Is(err, http.ErrNotSupported) {
		log.Printf("logs: failed to set response write deadline")
	}

	if lookup.status != 0 {
		http.Error(w, lookup.message, lookup.status)
		return
	}

	w.Header().Set("Content-Type", "text/plain; charset=utf-8")
	w.Header().Set("Content-Length", strconv.FormatInt(lookup.entry.Size, 10))
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
	// Retained-room ownership uses the admission source key.
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

	// Only the authoritative client may remove the room or start its absence clock.
	defer func() {
		if currentRoom != nil && currentPeerID != "" {
			currentRoom.mu.Lock()
			closing := currentRoom.closing
			stale := currentRoom.Peers[currentPeerID] != client
			if !closing && !stale {
				now := time.Now()
				delete(currentRoom.Peers, currentPeerID)
				if currentRoom.ProtocolVersion == relayProtocolVersion &&
					currentPeerID != currentRoom.HostPeerID {
					if reservation, ok := currentRoom.peerReservations[currentPeerID]; ok {
						reservation.absentSince = now
						currentRoom.peerReservations[currentPeerID] = reservation
					}
				}
				currentRoom.LastActivityAt = now
				s.snap.recordMutation()
			}
			currentRoom.mu.Unlock()
			if !closing && !stale {
				currentRoom.broadcastExcept(currentPeerID, serverMsg{
					Type:   relayTypePeerLeft,
					PeerID: currentPeerID,
				})
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
					s.snap.recordMutation()
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
					continue
				}
				// An empty room code is abandoned and may be reclaimed; occupied rooms
				// remain owned by their peers.
				reclaimable := len(existing.Peers) == 0 && !existing.closing
				existing.mu.Unlock()
				if !reclaimable {
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
			s.snap.recordMutation()
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

			if room.ProtocolVersion == relayProtocolVersion &&
				pruneExpiredPeerReservationsLocked(room, time.Now()) {
				s.snap.recordMutation()
			}
			existingClient, occupied := room.Peers[msg.PeerID]
			reservation, identityReserved := room.peerReservations[msg.PeerID]
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
					authorized = !reservation.releasePending &&
						tokenValid &&
						reconnectVerifierMatches(reservation.verifier, presentedVerifier)
					responseToken = msg.ReconnectToken
					responseVerifier = reservation.verifier
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
					// Tokenless host reconnect is limited to unversioned local rooms
					// from the creating source.
					authorized = true
					responseToken = ""
					responseVerifier = room.hostVerifier
				}
			} else {
				// Legacy guests lack durable proof, so identity reuse is legacy-only.
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
						roomFull = len(room.peerReservations) >= maxRoomSize-1
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

			room.Peers[msg.PeerID] = client
			if room.ProtocolVersion == relayProtocolVersion && msg.PeerID != room.HostPeerID {
				if identityReserved {
					reservation.absentSince = time.Time{}
					reservation.releasePending = false
					reservation.releaseClient = nil
					reservation.verifier = responseVerifier
				} else {
					reservation = peerReservation{verifier: responseVerifier}
				}
				if room.peerReservations == nil {
					room.peerReservations = make(map[string]peerReservation)
				}
				room.peerReservations[msg.PeerID] = reservation
			}
			room.LastActivityAt = time.Now()
			peers := room.peerIDs()
			hostPeerID := room.HostPeerID
			roomProtocolVersion := room.ProtocolVersion
			s.snap.recordMutation()
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

		case relayTypeLeave:
			if currentRoom == nil {
				client.sendJSON(serverMsg{Type: relayTypeError, Code: relayErrorNotInRoom, Message: "Not in a room"})
				continue
			}
			room := currentRoom
			presentedVerifier, tokenValid := reconnectVerifierFromToken(msg.ReconnectToken)
			if s.beforeLeaveRoomLock != nil {
				s.beforeLeaveRoomLock()
			}
			room.mu.Lock()
			currentClient := room.Peers[currentPeerID] == client
			isGuest := currentPeerID != room.HostPeerID
			authorized := currentClient && isGuest && !room.closing && msg.ProtocolVersion == room.ProtocolVersion
			reservation, reservationOK := room.peerReservations[currentPeerID]
			if authorized && room.ProtocolVersion == relayProtocolVersion {
				authorized = reservationOK &&
					!reservation.releasePending &&
					tokenValid &&
					reconnectVerifierMatches(reservation.verifier, presentedVerifier)
			}
			if !authorized {
				room.mu.Unlock()
				client.sendJSON(serverMsg{Type: relayTypeError, Code: relayErrorPeerIdUnavailable, Message: "Unable to release peer identity"})
				continue
			}

			releasedPeerID := currentPeerID
			if room.ProtocolVersion == legacyRelayProtocolVersion {
				delete(room.Peers, releasedPeerID)
				room.LastActivityAt = time.Now()
				s.snap.recordMutation()
				room.mu.Unlock()
				currentRoom = nil
				currentPeerID = ""
			} else {
				previousActivity := room.LastActivityAt
				leaveActivity := time.Now()
				reservation.releasePending = true
				reservation.releaseClient = client
				room.peerReservations[releasedPeerID] = reservation
				room.LastActivityAt = leaveActivity
				ticket := s.snap.recordTerminalMutation(func(persistErr error) terminalMutationOutcome {
					s.mu.RLock()
					authoritativeRoom := s.rooms[room.SessionID] == room
					room.mu.Lock()
					currentReservation, stillReserved := room.peerReservations[releasedPeerID]
					ownsRelease := authoritativeRoom &&
						!room.closing &&
						stillReserved &&
						currentReservation.releasePending &&
						currentReservation.releaseClient == client &&
						room.Peers[releasedPeerID] == client
					if !ownsRelease {
						room.mu.Unlock()
						s.mu.RUnlock()
						return terminalMutationOutcome{err: persistErr, deliver: false}
					}
					if persistErr == nil {
						delete(room.Peers, releasedPeerID)
						delete(room.peerReservations, releasedPeerID)
					} else {
						currentReservation.releasePending = false
						currentReservation.releaseClient = nil
						room.peerReservations[releasedPeerID] = currentReservation
						if room.LastActivityAt.Equal(leaveActivity) {
							room.LastActivityAt = previousActivity
						}
						// Record the restored reservation before a queued later capture.
						s.snap.recordMutation()
					}
					room.mu.Unlock()
					s.mu.RUnlock()
					return terminalMutationOutcome{err: persistErr, deliver: true}
				})
				room.mu.Unlock()

				outcome := s.snap.waitForDurable(ticket)
				if !outcome.deliver {
					continue
				}
				if outcome.err != nil {
					client.sendJSON(serverMsg{Type: relayTypeError, Code: relayErrorInvalidMessage, Message: "Unable to persist released peer identity"})
					continue
				}
				currentRoom = nil
				currentPeerID = ""
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
			ticket := s.snap.recordTerminalMutation(nil)
			room.mu.Unlock()
			s.mu.Unlock()

			// Atomic rename committed; post-rename directory-sync degradation is warning-only.
			outcome := s.snap.waitForDurable(ticket)
			if outcome.err != nil {
				client.sendJSON(serverMsg{Type: relayTypeError, Code: relayErrorInvalidMessage, Message: "Unable to persist ended room"})
				room.mu.Lock()
				clear(room.Peers)
				clear(room.peerReservations)
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
			clear(room.peerReservations)
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
