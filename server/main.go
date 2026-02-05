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
	invitationMaxAge   = 5 * time.Minute
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

// --- Invitation ---

type Invitation struct {
	SessionID       string    `json:"sessionId"`
	HostUserUUID    string    `json:"hostUserUUID"`
	HostDisplayName string    `json:"hostDisplayName"`
	TargetUserUUID  string    `json:"targetUserUUID"`
	MediaTitle      string    `json:"mediaTitle"`
	MediaThumb      string    `json:"mediaThumb,omitempty"`
	CreatedAt       time.Time `json:"createdAt"`
	ExpiresAt       time.Time `json:"expiresAt"`
}

// --- Connected User (for receiving invitations) ---

type ConnectedUser struct {
	UserUUID string
	Conn     *websocket.Conn
}

// --- Messages ---

type clientMsg struct {
	Type            string          `json:"type"`
	SessionID       string          `json:"sessionId,omitempty"`
	PeerID          string          `json:"peerId,omitempty"`
	To              string          `json:"to,omitempty"`
	Payload         json.RawMessage `json:"payload,omitempty"`
	// Invitation fields
	UserUUID        string          `json:"userUUID,omitempty"`
	TargetUserUUID  string          `json:"targetUserUUID,omitempty"`
	DisplayName     string          `json:"displayName,omitempty"`
	MediaTitle      string          `json:"mediaTitle,omitempty"`
	MediaThumb      string          `json:"mediaThumb,omitempty"`
}

type serverMsg struct {
	Type        string          `json:"type"`
	SessionID   string          `json:"sessionId,omitempty"`
	PeerID      string          `json:"peerId,omitempty"`
	From        string          `json:"from,omitempty"`
	Peers       []string        `json:"peers,omitempty"`
	Code        string          `json:"code,omitempty"`
	Message     string          `json:"message,omitempty"`
	Payload     json.RawMessage `json:"payload,omitempty"`
	// Invitation fields
	Invitation  *Invitation     `json:"invitation,omitempty"`
	Invitations []Invitation    `json:"invitations,omitempty"`
	UserUUID    string          `json:"userUUID,omitempty"`
	DisplayName string          `json:"displayName,omitempty"`
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
	rooms       map[string]*Room
	users       map[string]*ConnectedUser   // userUUID -> connection (for invitations)
	invitations map[string][]Invitation     // targetUserUUID -> pending invitations
	mu          sync.RWMutex
}

func newServer() *Server {
	s := &Server{
		rooms:       make(map[string]*Room),
		users:       make(map[string]*ConnectedUser),
		invitations: make(map[string][]Invitation),
	}
	go s.cleanupLoop()
	return s
}

func (s *Server) cleanupLoop() {
	ticker := time.NewTicker(cleanupInterval)
	defer ticker.Stop()
	for range ticker.C {
		s.mu.Lock()
		now := time.Now()

		// Cleanup old rooms
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

		// Cleanup expired invitations
		for userUUID, invites := range s.invitations {
			validInvites := make([]Invitation, 0)
			for _, inv := range invites {
				if now.Before(inv.ExpiresAt) {
					validInvites = append(validInvites, inv)
				} else {
					log.Printf("cleanup: removing expired invitation for user %s (session %s)", userUUID, inv.SessionID)
				}
			}
			if len(validInvites) == 0 {
				delete(s.invitations, userUUID)
			} else {
				s.invitations[userUUID] = validInvites
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
	var currentUserUUID string

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
		// Cleanup registered user
		if currentUserUUID != "" {
			s.mu.Lock()
			delete(s.users, currentUserUUID)
			s.mu.Unlock()
			log.Printf("user %s unregistered", currentUserUUID)
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

		case "register":
			// Register user to receive invitations
			if msg.UserUUID == "" {
				s.sendError(conn, "invalid_message", "userUUID required")
				continue
			}
			s.mu.Lock()
			// Remove old connection if exists
			if old, exists := s.users[msg.UserUUID]; exists && old.Conn != conn {
				log.Printf("user %s re-registering (replacing old connection)", msg.UserUUID)
			}
			s.users[msg.UserUUID] = &ConnectedUser{
				UserUUID: msg.UserUUID,
				Conn:     conn,
			}
			currentUserUUID = msg.UserUUID
			// Get pending invitations for this user
			pendingInvites := s.invitations[msg.UserUUID]
			s.mu.Unlock()
			log.Printf("user %s registered", msg.UserUUID)
			s.sendJSON(conn, serverMsg{Type: "registered", UserUUID: msg.UserUUID})
			// Send pending invitations
			if len(pendingInvites) > 0 {
				s.sendJSON(conn, serverMsg{Type: "invitations", Invitations: pendingInvites})
			}

		case "invite":
			// Send invitation to a friend
			if msg.SessionID == "" || msg.TargetUserUUID == "" || msg.UserUUID == "" {
				s.sendError(conn, "invalid_message", "sessionId, userUUID, and targetUserUUID required")
				continue
			}
			// Verify room exists
			s.mu.RLock()
			_, roomExists := s.rooms[msg.SessionID]
			s.mu.RUnlock()
			if !roomExists {
				s.sendError(conn, "room_not_found", "Room does not exist")
				continue
			}

			now := time.Now()
			invitation := Invitation{
				SessionID:       msg.SessionID,
				HostUserUUID:    msg.UserUUID,
				HostDisplayName: msg.DisplayName,
				TargetUserUUID:  msg.TargetUserUUID,
				MediaTitle:      msg.MediaTitle,
				MediaThumb:      msg.MediaThumb,
				CreatedAt:       now,
				ExpiresAt:       now.Add(invitationMaxAge),
			}

			s.mu.Lock()
			// Add to pending invitations
			s.invitations[msg.TargetUserUUID] = append(s.invitations[msg.TargetUserUUID], invitation)
			// Check if target user is online
			targetUser, online := s.users[msg.TargetUserUUID]
			s.mu.Unlock()

			log.Printf("invitation sent from %s to %s for session %s", msg.UserUUID, msg.TargetUserUUID, msg.SessionID)
			s.sendJSON(conn, serverMsg{Type: "inviteSent", SessionID: msg.SessionID, UserUUID: msg.TargetUserUUID})

			// If target is online, push the invitation immediately
			if online {
				s.sendJSON(targetUser.Conn, serverMsg{Type: "invitation", Invitation: &invitation})
			}

		case "acceptInvite":
			// Accept an invitation
			if msg.SessionID == "" || msg.UserUUID == "" {
				s.sendError(conn, "invalid_message", "sessionId and userUUID required")
				continue
			}
			s.mu.Lock()
			// Find and remove the invitation
			invites := s.invitations[msg.UserUUID]
			var acceptedInvite *Invitation
			newInvites := make([]Invitation, 0)
			for _, inv := range invites {
				if inv.SessionID == msg.SessionID {
					acceptedInvite = &inv
				} else {
					newInvites = append(newInvites, inv)
				}
			}
			if len(newInvites) == 0 {
				delete(s.invitations, msg.UserUUID)
			} else {
				s.invitations[msg.UserUUID] = newInvites
			}
			// Notify the host if they're online
			var hostConn *websocket.Conn
			if acceptedInvite != nil {
				if hostUser, online := s.users[acceptedInvite.HostUserUUID]; online {
					hostConn = hostUser.Conn
				}
			}
			s.mu.Unlock()

			if acceptedInvite == nil {
				s.sendError(conn, "invitation_not_found", "Invitation not found or expired")
				continue
			}

			log.Printf("invitation accepted by %s for session %s", msg.UserUUID, msg.SessionID)
			s.sendJSON(conn, serverMsg{Type: "inviteAccepted", SessionID: msg.SessionID})

			// Notify host
			if hostConn != nil {
				s.sendJSON(hostConn, serverMsg{
					Type:        "inviteAccepted",
					SessionID:   msg.SessionID,
					UserUUID:    msg.UserUUID,
					DisplayName: msg.DisplayName,
				})
			}

		case "declineInvite":
			// Decline an invitation
			if msg.SessionID == "" || msg.UserUUID == "" {
				s.sendError(conn, "invalid_message", "sessionId and userUUID required")
				continue
			}
			s.mu.Lock()
			// Find and remove the invitation
			invites := s.invitations[msg.UserUUID]
			var declinedInvite *Invitation
			newInvites := make([]Invitation, 0)
			for _, inv := range invites {
				if inv.SessionID == msg.SessionID {
					declinedInvite = &inv
				} else {
					newInvites = append(newInvites, inv)
				}
			}
			if len(newInvites) == 0 {
				delete(s.invitations, msg.UserUUID)
			} else {
				s.invitations[msg.UserUUID] = newInvites
			}
			// Notify the host if they're online
			var hostConn *websocket.Conn
			if declinedInvite != nil {
				if hostUser, online := s.users[declinedInvite.HostUserUUID]; online {
					hostConn = hostUser.Conn
				}
			}
			s.mu.Unlock()

			if declinedInvite == nil {
				s.sendError(conn, "invitation_not_found", "Invitation not found or expired")
				continue
			}

			log.Printf("invitation declined by %s for session %s", msg.UserUUID, msg.SessionID)
			s.sendJSON(conn, serverMsg{Type: "inviteDeclined", SessionID: msg.SessionID})

			// Notify host
			if hostConn != nil {
				s.sendJSON(hostConn, serverMsg{
					Type:        "inviteDeclined",
					SessionID:   msg.SessionID,
					UserUUID:    msg.UserUUID,
					DisplayName: msg.DisplayName,
				})
			}

		case "getInvitations":
			// Get pending invitations for the registered user
			if currentUserUUID == "" {
				s.sendError(conn, "not_registered", "Must register first")
				continue
			}
			s.mu.RLock()
			pendingInvites := s.invitations[currentUserUUID]
			s.mu.RUnlock()
			s.sendJSON(conn, serverMsg{Type: "invitations", Invitations: pendingInvites})

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
