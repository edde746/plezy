package main

import (
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"net/http"
	"strings"
	"time"
)

const steamCatalogGrantTTL = 30 * 24 * time.Hour

// Grants authorize public-catalog reads for one OpenID-verified identity.
// They are not Steam tokens and confer no launch, purchase or account access.
// Only digests live on the relay. Restart or revocation requires relinking.
type steamCatalogGrant struct {
	steamID        string
	expires        time.Time
	fetched        time.Time
	loading        bool
	contextFetched time.Time
	contextLoading bool
}

func (p *oauthProxy) issueSteamCatalogGrant(steamID string) string {
	if !steamIDPattern.MatchString(steamID) {
		return ""
	}
	var secret [32]byte
	if _, err := rand.Read(secret[:]); err != nil {
		return ""
	}
	token := base64.RawURLEncoding.EncodeToString(secret[:])
	digest := sha256.Sum256([]byte(token))
	now := time.Now()
	p.mu.Lock()
	defer p.mu.Unlock()
	if p.steamCatalogGrants == nil {
		p.steamCatalogGrants = make(map[[32]byte]*steamCatalogGrant)
	}
	for key, grant := range p.steamCatalogGrants {
		if !now.Before(grant.expires) {
			delete(p.steamCatalogGrants, key)
		}
	}
	if len(p.steamCatalogGrants) >= oauthMaxSessions {
		return ""
	}
	p.steamCatalogGrants[digest] = &steamCatalogGrant{
		steamID: steamID, expires: now.Add(steamCatalogGrantTTL),
	}
	return token
}

func (p *oauthProxy) handleSteamCatalog(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Cache-Control", "no-store, private")
	w.Header().Set("Referrer-Policy", "no-referrer")
	w.Header().Set("X-Content-Type-Options", "nosniff")
	if r.Method != http.MethodPost && r.Method != http.MethodDelete {
		w.Header().Set("Allow", "POST, DELETE")
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	// Credentials and Steam IDs are never accepted from query strings or bodies.
	if r.URL.RawQuery != "" || r.ContentLength > 0 {
		http.Error(w, "Invalid catalog request", http.StatusBadRequest)
		return
	}
	authorization := r.Header.Values("Authorization")
	if len(authorization) != 1 || !strings.HasPrefix(authorization[0], "Bearer ") {
		http.Error(w, "Relink Steam to refresh the catalog", http.StatusUnauthorized)
		return
	}
	token := strings.TrimPrefix(authorization[0], "Bearer ")
	decoded, err := base64.RawURLEncoding.DecodeString(token)
	if err != nil || len(token) != 43 || len(decoded) != 32 {
		http.Error(w, "Relink Steam to refresh the catalog", http.StatusUnauthorized)
		return
	}
	ip, err := p.clientIPs.resolve(r)
	if err != nil {
		http.Error(w, "Invalid client address", http.StatusBadRequest)
		return
	}
	if allowed, _ := p.pollAllow(ip); !allowed {
		w.Header().Set("Retry-After", "30")
		http.Error(w, "Try again later", http.StatusTooManyRequests)
		return
	}
	digest := sha256.Sum256([]byte(token))
	now := time.Now()
	p.mu.Lock()
	grant := p.steamCatalogGrants[digest]
	if r.Method == http.MethodDelete {
		delete(p.steamCatalogGrants, digest)
		p.mu.Unlock()
		w.WriteHeader(http.StatusNoContent)
		return
	}
	if grant == nil || !now.Before(grant.expires) {
		delete(p.steamCatalogGrants, digest)
		p.mu.Unlock()
		http.Error(w, "Relink Steam to refresh the catalog", http.StatusUnauthorized)
		return
	}
	if grant.loading {
		p.mu.Unlock()
		w.Header().Set("Retry-After", "5")
		http.Error(w, "Catalog refresh in progress", http.StatusTooManyRequests)
		return
	}
	if now.Sub(grant.fetched) < 30*time.Second {
		p.mu.Unlock()
		w.Header().Set("Retry-After", "30")
		http.Error(w, "Try again later", http.StatusTooManyRequests)
		return
	}

	grant.loading = true
	steamID := grant.steamID
	p.mu.Unlock()
	games, available, truncated := p.fetchSteamOwnedGames(r.Context(), steamID)
	result := oauthTokenResult{SteamID: steamID, SteamGames: games,
		SteamLibraryAvailable: available, SteamCatalogTruncated: truncated}
	p.mu.Lock()
	grant.loading = false
	// Revocation during an upstream fetch must also retire that response.
	current := p.steamCatalogGrants[digest] == grant && time.Now().Before(grant.expires)
	if current {
		grant.fetched = time.Now()
	}
	p.mu.Unlock()
	if !current {
		http.Error(w, "Relink Steam to refresh the catalog", http.StatusUnauthorized)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(result)
}
