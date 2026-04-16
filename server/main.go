package main

import (
	"crypto/rand"
	"encoding/json"
	"flag"
	"io"
	"log"
	"math/big"
	"net"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"sync"
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

// --- Room ---

type Room struct {
	SessionID  string
	HostPeerID string
	Peers      map[string]*websocket.Conn
	mu         sync.RWMutex
	CreatedAt  time.Time
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
	r.mu.RLock()
	defer r.mu.RUnlock()
	for id, conn := range r.Peers {
		if id != senderID {
			conn.SetWriteDeadline(time.Now().Add(writeWait))
			conn.WriteMessage(websocket.TextMessage, data)
		}
	}
}

func (r *Room) sendTo(targetID string, msg serverMsg) bool {
	data, err := json.Marshal(msg)
	if err != nil {
		return false
	}
	r.mu.RLock()
	defer r.mu.RUnlock()
	conn, ok := r.Peers[targetID]
	if !ok {
		return false
	}
	conn.SetWriteDeadline(time.Now().Add(writeWait))
	conn.WriteMessage(websocket.TextMessage, data)
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

// --- Server ---

type Server struct {
	rooms map[string]*Room
	logs  *logStore
	conns *connTracker
	mu    sync.RWMutex
}

func newServer(logDir string) *Server {
	s := &Server{rooms: make(map[string]*Room), logs: newLogStore(logDir), conns: newConnTracker()}
	go s.cleanupLoop()
	return s
}

func (s *Server) cleanupLoop() {
	ticker := time.NewTicker(cleanupInterval)
	defer ticker.Stop()
	for range ticker.C {
		s.mu.Lock()
		now := time.Now()
		for id, room := range s.rooms {
			room.mu.RLock()
			empty := len(room.Peers) == 0
			age := now.Sub(room.CreatedAt)
			room.mu.RUnlock()

			if (empty && age > emptyRoomMaxAge) || age > roomMaxAge {
				log.Printf("cleanup: removing room %s (empty=%v, age=%v)", id, empty, age)
				delete(s.rooms, id)
			}
		}
		s.mu.Unlock()
		s.logs.cleanup()
		s.conns.cleanup()

		s.conns.mu.Lock()
		log.Printf("stats: conns=%d ips=%d rooms=%d",
			s.conns.globalCount, len(s.conns.perIP), len(s.rooms))
		s.conns.mu.Unlock()
	}
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

func (s *Server) sendError(conn *websocket.Conn, code, message string) {
	data, _ := json.Marshal(serverMsg{Type: "error", Code: code, Message: message})
	conn.SetWriteDeadline(time.Now().Add(writeWait))
	conn.WriteMessage(websocket.TextMessage, data)
}

func (s *Server) sendJSON(conn *websocket.Conn, msg serverMsg) {
	data, _ := json.Marshal(msg)
	conn.SetWriteDeadline(time.Now().Add(writeWait))
	conn.WriteMessage(websocket.TextMessage, data)
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

	// Ping ticker
	ticker := time.NewTicker(pingInterval)
	defer ticker.Stop()
	go func() {
		for range ticker.C {
			conn.SetWriteDeadline(time.Now().Add(writeWait))
			if err := conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}()

	rl := newRateLimiter(rateBurst, rateSustained)
	var currentRoom *Room
	var currentPeerID string
	var isHost bool

	// Cleanup on disconnect
	defer func() {
		if currentRoom != nil && currentPeerID != "" {
			currentRoom.mu.Lock()
			delete(currentRoom.Peers, currentPeerID)
			currentRoom.mu.Unlock()
			currentRoom.broadcastExcept(currentPeerID, serverMsg{
				Type:   "peerLeft",
				PeerID: currentPeerID,
			})
			if isHost {
				s.conns.releaseRoom(ip)
			}
			log.Printf("peer %s left room %s", currentPeerID, currentRoom.SessionID)
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
			s.sendError(conn, "rate_limited", "Too many messages")
			continue
		}

		var msg clientMsg
		if err := json.Unmarshal(raw, &msg); err != nil {
			s.sendError(conn, "invalid_message", "Invalid JSON")
			continue
		}

		switch msg.Type {
		case "create":
			if msg.SessionID == "" || msg.PeerID == "" {
				s.sendError(conn, "invalid_message", "sessionId and peerId required")
				continue
			}
			if !s.conns.tryCreateRoom(ip) {
				s.sendError(conn, "rate_limited", "Too many rooms created")
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
					s.sendError(conn, "room_exists", "Room already exists")
					continue
				}
				// Empty stale room — reclaim the ID
				delete(s.rooms, msg.SessionID)
			}
			room := &Room{
				SessionID:  msg.SessionID,
				HostPeerID: msg.PeerID,
				Peers:      map[string]*websocket.Conn{msg.PeerID: conn},
				CreatedAt:  time.Now(),
			}
			s.rooms[msg.SessionID] = room
			s.mu.Unlock()
			currentRoom = room
			currentPeerID = msg.PeerID
			isHost = true
			log.Printf("room %s created by %s", msg.SessionID, msg.PeerID)
			s.sendJSON(conn, serverMsg{Type: "created", SessionID: msg.SessionID})

		case "join":
			if msg.SessionID == "" || msg.PeerID == "" {
				s.sendError(conn, "invalid_message", "sessionId and peerId required")
				continue
			}
			s.mu.RLock()
			room, exists := s.rooms[msg.SessionID]
			s.mu.RUnlock()
			if !exists {
				s.sendError(conn, "room_not_found", "Room does not exist")
				continue
			}
			room.mu.Lock()
			if len(room.Peers) >= maxRoomSize {
				room.mu.Unlock()
				s.sendError(conn, "room_full", "Room is full")
				continue
			}
			room.Peers[msg.PeerID] = conn
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
			s.sendJSON(conn, serverMsg{Type: "joined", SessionID: msg.SessionID, Peers: existingPeers})
			room.broadcastExcept(msg.PeerID, serverMsg{Type: "peerJoined", PeerID: msg.PeerID})

		case "broadcast":
			if currentRoom == nil {
				s.sendError(conn, "not_in_room", "Not in a room")
				continue
			}
			currentRoom.broadcastExcept(currentPeerID, serverMsg{
				Type:    "message",
				From:    currentPeerID,
				Payload: msg.Payload,
			})

		case "sendTo":
			if currentRoom == nil {
				s.sendError(conn, "not_in_room", "Not in a room")
				continue
			}
			if msg.To == "" {
				s.sendError(conn, "invalid_message", "to field required")
				continue
			}
			if !currentRoom.sendTo(msg.To, serverMsg{
				Type:    "message",
				From:    currentPeerID,
				Payload: msg.Payload,
			}) {
				s.sendError(conn, "not_in_room", "Target peer not found")
			}

		case "ping":
			s.sendJSON(conn, serverMsg{Type: "pong"})

		default:
			s.sendError(conn, "invalid_message", "Unknown message type")
		}
	}
}

func main() {
	addr := flag.String("addr", ":8080", "Listen address")
	logDir := flag.String("log-dir", "/data/logs", "Directory for log file storage")
	flag.Parse()

	srv := newServer(*logDir)

	mux := http.NewServeMux()
	mux.HandleFunc("/relay", srv.handleWS)
	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("ok"))
	})
	mux.HandleFunc("/logs", srv.handlePostLogs)
	mux.HandleFunc("/logs/", srv.handleGetLogs)

	log.Printf("Starting relay server on %s", *addr)
	log.Fatal(http.ListenAndServe(*addr, mux))
}
