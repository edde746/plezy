package main

import (
	"encoding/json"
	"flag"
	"log"
	"net/http"
	"sync"
	"time"

	"github.com/gorilla/websocket"
	"golang.org/x/crypto/acme/autocert"
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
)

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool { return true },
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

// --- Server ---

type Server struct {
	rooms map[string]*Room
	mu    sync.RWMutex
}

func newServer() *Server {
	s := &Server{rooms: make(map[string]*Room)}
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
	}
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
			s.mu.Lock()
			if _, exists := s.rooms[msg.SessionID]; exists {
				s.mu.Unlock()
				s.sendError(conn, "room_exists", "Room already exists")
				continue
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
	dev := flag.Bool("dev", false, "Run in development mode (plain HTTP on :8080)")
	host := flag.String("host", "ice.plezy.app", "Hostname for TLS autocert")
	flag.Parse()

	srv := newServer()

	mux := http.NewServeMux()
	mux.HandleFunc("/relay", srv.handleWS)
	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("ok"))
	})

	if *dev {
		log.Println("Starting dev server on :8080")
		log.Fatal(http.ListenAndServe(":8080", mux))
	} else {
		certManager := autocert.Manager{
			Prompt:     autocert.AcceptTOS,
			HostPolicy: autocert.HostWhitelist(*host),
			Cache:      autocert.DirCache("/var/lib/plezy-relay/certs"),
		}

		server := &http.Server{
			Addr:      ":443",
			Handler:   mux,
			TLSConfig: certManager.TLSConfig(),
		}

		// HTTP challenge server for Let's Encrypt
		go func() {
			log.Println("Starting HTTP challenge server on :80")
			log.Fatal(http.ListenAndServe(":80", certManager.HTTPHandler(nil)))
		}()

		log.Printf("Starting relay server on :443 (host=%s)", *host)
		log.Fatal(server.ListenAndServeTLS("", ""))
	}
}
