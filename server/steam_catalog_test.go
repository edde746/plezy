package main

import (
	"crypto/sha256"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"
)

func catalogRequest(p *oauthProxy, method, token, query string) *httptest.ResponseRecorder {
	request := httptest.NewRequest(method, "/auth/steam/library"+query, nil)
	if token != "" {
		request.Header.Set("Authorization", "Bearer "+token)
	}
	response := httptest.NewRecorder()
	p.handleSteamCatalog(response, request)
	return response
}

func TestSteamCatalogGrantBindsIdentityAndIncludesPlayedFreeGames(t *testing.T) {
	upstream := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Query().Get("steamid") != "76561198000000000" || r.URL.Query().Get("include_played_free_games") != "true" {
			t.Error("catalog request lost its verified identity or free-game option")
		}
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(`{"response":{"game_count":1,"games":[{"appid":620,"name":"Portal 2"}]}}`))
	}))
	defer upstream.Close()
	p := newOAuthProxy("https://relay.example", nil, clientIPResolver{})
	p.steamOwnedGamesEndpoint = upstream.URL
	p.steamWebAPIKey = "test-key"
	token := p.issueSteamCatalogGrant("76561198000000000")
	response := catalogRequest(p, http.MethodPost, token, "")
	if response.Code != http.StatusOK {
		t.Fatalf("refresh status %d", response.Code)
	}
	var result oauthTokenResult
	if err := json.Unmarshal(response.Body.Bytes(), &result); err != nil {
		t.Fatal(err)
	}
	if result.SteamID != "76561198000000000" || len(result.SteamGames) != 1 || !result.SteamLibraryAvailable {
		t.Fatal("refresh did not return the verified account catalog")
	}
	if strings.Contains(response.Body.String(), token) || result.SteamCatalogToken != "" {
		t.Fatal("refresh echoed its bearer capability")
	}
	if response.Header().Get("Cache-Control") != "no-store, private" {
		t.Fatal("catalog is cacheable")
	}
	if catalogRequest(p, http.MethodPost, token, "?steamid=76561198000000001").Code != http.StatusBadRequest {
		t.Fatal("caller could select another identity")
	}
	if catalogRequest(p, http.MethodPost, token, "").Code != http.StatusTooManyRequests {
		t.Fatal("rapid refresh was not bounded")
	}
}

func TestSteamCatalogGrantRejectsMissingExpiredRevokedAndQueryCredentials(t *testing.T) {
	p := newOAuthProxy("https://relay.example", nil, clientIPResolver{})
	if catalogRequest(p, http.MethodPost, "", "").Code != http.StatusUnauthorized {
		t.Fatal("missing authorization accepted")
	}
	if catalogRequest(p, http.MethodGet, "", "").Code != http.StatusMethodNotAllowed {
		t.Fatal("GET accepted")
	}
	token := p.issueSteamCatalogGrant("76561198000000000")
	if catalogRequest(p, http.MethodPost, "", "?token="+token).Code != http.StatusBadRequest {
		t.Fatal("query capability accepted")
	}
	if catalogRequest(p, http.MethodDelete, token, "").Code != http.StatusNoContent {
		t.Fatal("revocation failed")
	}
	if catalogRequest(p, http.MethodPost, token, "").Code != http.StatusUnauthorized {
		t.Fatal("revoked grant accepted")
	}
	token = p.issueSteamCatalogGrant("76561198000000000")
	p.steamCatalogGrants[sha256.Sum256([]byte(token))].expires = time.Now().Add(-time.Second)
	if catalogRequest(p, http.MethodPost, token, "").Code != http.StatusUnauthorized {
		t.Fatal("expired grant accepted")
	}
}

func TestSteamCatalogRevocationRetiresInflightResponse(t *testing.T) {
	started, release := make(chan struct{}), make(chan struct{})
	upstream := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		close(started)
		<-release
		_, _ = w.Write([]byte(`{"response":{"game_count":0,"games":[]}}`))
	}))
	defer upstream.Close()
	p := newOAuthProxy("https://relay.example", nil, clientIPResolver{})
	p.steamOwnedGamesEndpoint = upstream.URL
	p.steamWebAPIKey = "test-key"
	token := p.issueSteamCatalogGrant("76561198000000000")
	response := make(chan int, 1)
	go func() { response <- catalogRequest(p, http.MethodPost, token, "").Code }()
	<-started
	catalogRequest(p, http.MethodDelete, token, "")
	close(release)
	if <-response != http.StatusUnauthorized {
		t.Fatal("revoked in-flight response escaped")
	}
}
