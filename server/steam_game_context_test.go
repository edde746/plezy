package main

import (
	"crypto/sha256"
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync/atomic"
	"testing"
	"time"
)

type steamContextTransport func(*http.Request) (*http.Response, error)

func (f steamContextTransport) RoundTrip(r *http.Request) (*http.Response, error) { return f(r) }
func steamContextResponse(body string) *http.Response {
	return &http.Response{StatusCode: 200, Header: http.Header{}, Body: io.NopCloser(strings.NewReader(body))}
}
func contextRequest(p *oauthProxy, token, body string) *httptest.ResponseRecorder {
	r := httptest.NewRequest(http.MethodPost, "/auth/steam/game", strings.NewReader(body))
	r.Header.Set("Authorization", "Bearer "+token)
	w := httptest.NewRecorder()
	p.handleSteamGameContext(w, r)
	return w
}
func TestSteamContextIdentityPrivacyAndOptIn(t *testing.T) {
	p := newOAuthProxy("https://relay.example", nil, clientIPResolver{})
	p.steamWebAPIKey = "test-secret"
	var social atomic.Int32
	p.steamClient = &http.Client{Transport: steamContextTransport(func(r *http.Request) (*http.Response, error) {
		if r.URL.Scheme != "https" || r.URL.Host != "api.steampowered.com" {
			t.Error("arbitrary upstream")
		}
		if id := r.URL.Query().Get("steamid"); id != "" && id != "76561198000000000" {
			t.Error("wrong identity")
		}
		switch r.URL.Path {
		case "/ISteamNews/GetNewsForApp/v2/":
			return steamContextResponse(`{"appnews":{"appid":620,"newsitems":[{"title":"Update","feedlabel":"Steam","date":100}]}}`), nil
		case "/ISteamUserStats/GetPlayerAchievements/v1/":
			return steamContextResponse(`{"playerstats":{"steamID":"76561198000000000","success":true,"achievements":[{"apiname":"secret","achieved":0,"unlocktime":100},{"apiname":"open","achieved":1,"unlocktime":100}]}}`), nil
		case "/ISteamUserStats/GetSchemaForGame/v2/":
			return steamContextResponse(`{"game":{"availableGameStats":{"achievements":[{"name":"secret","displayName":"Spoiler","description":"Secret ending","hidden":1},{"name":"open","displayName":"First step","description":"Start","hidden":0}]}}}`), nil
		case "/ISteamUser/GetFriendList/v1/":
			social.Add(1)
			return steamContextResponse(`{"friendslist":{"friends":[{"steamid":"76561198000000001"}]}}`), nil
		case "/ISteamUser/GetPlayerSummaries/v2/":
			social.Add(1)
			return steamContextResponse(`{"response":{"players":[{"steamid":"76561198000000001","personaname":"Friend","gameid":"620"},{"steamid":"76561198000000002","personaname":"Not a friend","gameid":"620"}]}}`), nil
		}
		t.Errorf("unexpected endpoint %s", r.URL.Path)
		return steamContextResponse(`{}`), nil
	})}
	token := p.issueSteamCatalogGrant("76561198000000000")
	response := contextRequest(p, token, `{"appId":620}`)
	if response.Code != 200 {
		t.Fatalf("status %d", response.Code)
	}
	var data steamGameContext
	if err := json.Unmarshal(response.Body.Bytes(), &data); err != nil {
		t.Fatal(err)
	}
	if len(data.Achievements) != 2 || !data.AchievementsAvailable || !data.NewsAvailable || social.Load() != 0 {
		t.Fatal("metadata or opt-in incorrect")
	}
	if strings.Contains(response.Body.String(), "Spoiler") || strings.Contains(response.Body.String(), "test-secret") || strings.Contains(response.Body.String(), token) {
		t.Fatal("secret or locked spoiler escaped")
	}
	if !data.Achievements[0].Hidden || data.Achievements[0].UnlockedAt != 0 {
		t.Fatal("hidden achievement exposed")
	}
	if contextRequest(p, token, `{"appId":620}`).Code != 429 {
		t.Fatal("rate limit absent")
	}
	p.steamCatalogGrants[sha256.Sum256([]byte(token))].contextFetched = time.Time{}
	response = contextRequest(p, token, `{"appId":620,"includeFriends":true}`)
	if response.Code != 200 {
		t.Fatal("social read failed")
	}
	if err := json.Unmarshal(response.Body.Bytes(), &data); err != nil {
		t.Fatal(err)
	}
	if social.Load() != 2 || len(data.Friends) != 1 || !data.FriendsRequested || !data.FriendsAvailable {
		t.Fatal("social scope escaped friend list")
	}
}

func TestSteamContextRejectsIdentitySelectionAndMalformedRequests(t *testing.T) {
	p := newOAuthProxy("https://relay.example", nil, clientIPResolver{})
	token := p.issueSteamCatalogGrant("76561198000000000")
	for _, body := range []string{`{"appId":0}`, `{"appId":4294967296}`, `{"appId":620,"steamId":"76561198000000001"}`, `{"appId":620} {}`, `{"appId":"620"}`, strings.Repeat("x", 1025)} {
		if contextRequest(p, token, body).Code != 400 {
			t.Fatalf("accepted invalid request %s", body[:min(len(body), 90)])
		}
	}
	if contextRequest(p, "", `{"appId":620}`).Code != 401 {
		t.Fatal("missing grant accepted")
	}
	catalogRequest(p, http.MethodDelete, token, "")
	if contextRequest(p, token, `{"appId":620}`).Code != 401 {
		t.Fatal("revoked grant accepted")
	}
}

func TestSteamContextRetiresInflightReads(t *testing.T) {
	p := newOAuthProxy("https://relay.example", nil, clientIPResolver{})
	started, release := make(chan struct{}), make(chan struct{})
	p.steamClient = &http.Client{Transport: steamContextTransport(func(r *http.Request) (*http.Response, error) {
		close(started)
		<-release
		return steamContextResponse(`{"appnews":{"appid":620,"newsitems":[]}}`), nil
	})}
	token := p.issueSteamCatalogGrant("76561198000000000")
	result := make(chan int, 1)
	go func() { result <- contextRequest(p, token, `{"appId":620}`).Code }()
	<-started
	catalogRequest(p, http.MethodDelete, token, "")
	close(release)
	if <-result != 401 {
		t.Fatal("revoked response escaped")
	}
}

func TestSteamContextUpstreamRedirectAndOversizeFailClosed(t *testing.T) {
	p := newOAuthProxy("https://relay.example", nil, clientIPResolver{})
	var calls atomic.Int32
	p.steamClient = &http.Client{Transport: steamContextTransport(func(r *http.Request) (*http.Response, error) {
		calls.Add(1)
		return &http.Response{StatusCode: 302, Header: http.Header{"Location": {"https://attacker.invalid/"}}, Body: io.NopCloser(strings.NewReader(""))}, nil
	})}
	if _, ok := p.steamNews(t.Context(), 620); ok || calls.Load() != 1 {
		t.Fatal("followed a redirect")
	}
	p.steamClient = &http.Client{Transport: steamContextTransport(func(r *http.Request) (*http.Response, error) {
		return steamContextResponse(strings.Repeat(" ", maxSteamAPIResponse+1)), nil
	})}
	if _, ok := p.steamNews(t.Context(), 620); ok {
		t.Fatal("unbounded response accepted")
	}
}
