package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"sync"
	"testing"
	"time"
)

// mockUpstream runs an httptest server that impersonates MAL/AniList. It
// records the last token-exchange form submission and returns a canned
// access_token/refresh_token response.
type mockUpstream struct {
	srv        *httptest.Server
	mu         sync.Mutex
	lastForm   url.Values
	tokenReply string
	tokenCode  int
}

// httpGet / httpPost / httpDo wrap the stdlib calls to fail the test on error.
// Keeps test bodies one-liner without tripping `go vet`'s
// "using resp before checking errors" rule.
func httpGet(t *testing.T, url string) *http.Response {
	t.Helper()
	resp, err := http.Get(url)
	if err != nil {
		t.Fatalf("GET %s: %v", url, err)
	}
	return resp
}

func httpPost(t *testing.T, url, contentType string, body io.Reader) *http.Response {
	t.Helper()
	resp, err := http.Post(url, contentType, body)
	if err != nil {
		t.Fatalf("POST %s: %v", url, err)
	}
	return resp
}

func httpDo(t *testing.T, req *http.Request) *http.Response {
	t.Helper()
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatalf("do %s %s: %v", req.Method, req.URL, err)
	}
	return resp
}

func newMockUpstream(t *testing.T) *mockUpstream {
	t.Helper()
	m := &mockUpstream{
		tokenReply: `{"access_token":"tok-abc","refresh_token":"ref-xyz","expires_in":2678400}`,
		tokenCode:  http.StatusOK,
	}
	m.srv = httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.URL.Path {
		case "/oauth/authorize":
			// Unused in tests — we assert on the 302 Location from our proxy.
			w.WriteHeader(http.StatusOK)
		case "/oauth/token":
			if err := r.ParseForm(); err != nil {
				http.Error(w, err.Error(), http.StatusBadRequest)
				return
			}
			m.mu.Lock()
			m.lastForm = r.PostForm
			code := m.tokenCode
			reply := m.tokenReply
			m.mu.Unlock()
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(code)
			io.WriteString(w, reply)
		default:
			http.NotFound(w, r)
		}
	}))
	t.Cleanup(m.srv.Close)
	return m
}

func (m *mockUpstream) setReply(code int, body string) {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.tokenCode = code
	m.tokenReply = body
}

func (m *mockUpstream) form() url.Values {
	m.mu.Lock()
	defer m.mu.Unlock()
	return m.lastForm
}

// newOAuthHarness boots a relay-less httptest server that mounts /auth/* only,
// with `mal` and `anilist` services pointed at a shared mock upstream.
type oauthHarness struct {
	proxy   *oauthProxy
	srv     *httptest.Server
	base    string
	upstream *mockUpstream
}

func newOAuthHarness(t *testing.T) *oauthHarness {
	t.Helper()
	up := newMockUpstream(t)
	proxy := newOAuthProxy("http://placeholder", map[string]oauthServiceConfig{
		"mal": {
			ClientID:     "mal-id",
			AuthorizeURL: up.srv.URL + "/oauth/authorize",
			TokenURL:     up.srv.URL + "/oauth/token",
			UsePKCE:      true,
			PKCEMethod:   "plain",
		},
		"anilist": {
			ClientID:     "anilist-id",
			ClientSecret: "anilist-secret",
			AuthorizeURL: up.srv.URL + "/oauth/authorize",
			TokenURL:     up.srv.URL + "/oauth/token",
		},
	})
	mux := http.NewServeMux()
	registerOAuthRoutes(mux, proxy)
	srv := httptest.NewServer(mux)
	t.Cleanup(srv.Close)
	// Rewire baseURL to the real httptest URL so redirect_uri computes correctly.
	proxy.baseURL = srv.URL
	return &oauthHarness{proxy: proxy, srv: srv, base: srv.URL, upstream: up}
}

func (h *oauthHarness) startSession(t *testing.T, service, ip string) (sessionID, qrURL string) {
	t.Helper()
	body, _ := json.Marshal(map[string]string{"service": service})
	req, _ := http.NewRequest(http.MethodPost, h.base+"/auth/start", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	if ip != "" {
		req.Header.Set("X-Forwarded-For", ip)
	}
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatalf("start: %v", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("start status=%d", resp.StatusCode)
	}
	var out struct {
		Session   string `json:"session"`
		URL       string `json:"url"`
		ExpiresIn int    `json:"expiresIn"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&out); err != nil {
		t.Fatalf("decode: %v", err)
	}
	if out.Session == "" || out.URL == "" {
		t.Fatalf("empty session/url: %+v", out)
	}
	return out.Session, out.URL
}

// ====== /auth/start ======

func TestOAuthStartReturnsSessionAndURL(t *testing.T) {
	h := newOAuthHarness(t)
	session, qr := h.startSession(t, "mal", "1.2.3.4")
	if !strings.HasPrefix(qr, h.base+"/auth/mal?session=") {
		t.Fatalf("url=%q doesn't look like the authorize start URL", qr)
	}
	if !strings.Contains(qr, url.QueryEscape(session)) {
		t.Fatalf("url=%q missing session token", qr)
	}
}

func TestOAuthStartRejectsUnknownService(t *testing.T) {
	h := newOAuthHarness(t)
	body, _ := json.Marshal(map[string]string{"service": "nope"})
	resp := httpPost(t, h.base+"/auth/start", "application/json", bytes.NewReader(body))
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusBadRequest {
		t.Fatalf("status=%d want 400", resp.StatusCode)
	}
}

func TestOAuthStartRejectsInvalidJSON(t *testing.T) {
	h := newOAuthHarness(t)
	resp := httpPost(t, h.base+"/auth/start", "application/json", strings.NewReader("not json"))
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusBadRequest {
		t.Fatalf("status=%d want 400", resp.StatusCode)
	}
}

func TestOAuthStartRateLimitedPerIP(t *testing.T) {
	h := newOAuthHarness(t)
	ip := "5.5.5.5"
	for i := 0; i < oauthStartBurst; i++ {
		h.startSession(t, "mal", ip) // should all succeed
	}
	body, _ := json.Marshal(map[string]string{"service": "mal"})
	req, err := http.NewRequest(http.MethodPost, h.base+"/auth/start", bytes.NewReader(body))
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-Forwarded-For", ip)
	resp := httpDo(t, req)
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusTooManyRequests {
		t.Fatalf("status=%d want 429", resp.StatusCode)
	}
}

func TestOAuthStartMethodNotAllowed(t *testing.T) {
	h := newOAuthHarness(t)
	resp := httpGet(t, h.base+"/auth/start")
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusMethodNotAllowed {
		t.Fatalf("status=%d want 405", resp.StatusCode)
	}
}

// ====== /auth/:service (authorize redirect) ======

func TestOAuthAuthorizeMALRedirectIncludesPKCE(t *testing.T) {
	h := newOAuthHarness(t)
	sess, _ := h.startSession(t, "mal", "1.1.1.1")

	client := &http.Client{CheckRedirect: func(*http.Request, []*http.Request) error { return http.ErrUseLastResponse }}
	resp, err := client.Get(h.base + "/auth/mal?session=" + url.QueryEscape(sess))
	if err != nil {
		t.Fatalf("get: %v", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusFound {
		t.Fatalf("status=%d want 302", resp.StatusCode)
	}
	loc, err := url.Parse(resp.Header.Get("Location"))
	if err != nil {
		t.Fatalf("parse Location: %v", err)
	}
	q := loc.Query()
	if q.Get("client_id") != "mal-id" {
		t.Errorf("client_id=%q", q.Get("client_id"))
	}
	if q.Get("response_type") != "code" {
		t.Errorf("response_type=%q", q.Get("response_type"))
	}
	if q.Get("state") != sess {
		t.Errorf("state=%q, want session %q", q.Get("state"), sess)
	}
	if q.Get("code_challenge_method") != "plain" {
		t.Errorf("code_challenge_method=%q, want plain", q.Get("code_challenge_method"))
	}
	if q.Get("code_challenge") == "" {
		t.Error("code_challenge missing")
	}
	if !strings.HasSuffix(q.Get("redirect_uri"), "/auth/mal/callback") {
		t.Errorf("redirect_uri=%q", q.Get("redirect_uri"))
	}
}

func TestOAuthAuthorizeAnilistRedirectOmitsPKCE(t *testing.T) {
	h := newOAuthHarness(t)
	sess, _ := h.startSession(t, "anilist", "1.1.1.2")
	client := &http.Client{CheckRedirect: func(*http.Request, []*http.Request) error { return http.ErrUseLastResponse }}
	resp, err := client.Get(h.base + "/auth/anilist?session=" + url.QueryEscape(sess))
	if err != nil {
		t.Fatalf("get: %v", err)
	}
	defer resp.Body.Close()
	loc, _ := url.Parse(resp.Header.Get("Location"))
	q := loc.Query()
	if q.Get("code_challenge") != "" {
		t.Errorf("anilist redirect should not include code_challenge, got %q", q.Get("code_challenge"))
	}
}

func TestOAuthAuthorizeUnknownSessionRendersError(t *testing.T) {
	h := newOAuthHarness(t)
	resp := httpGet(t, h.base+"/auth/mal?session=bogus")
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusNotFound {
		t.Fatalf("status=%d want 404", resp.StatusCode)
	}
	body, _ := io.ReadAll(resp.Body)
	if !strings.Contains(string(body), "no longer valid") {
		t.Errorf("expected error page html, got: %s", body)
	}
}

func TestOAuthAuthorizeWrongServiceRejected(t *testing.T) {
	h := newOAuthHarness(t)
	sess, _ := h.startSession(t, "mal", "1.1.1.3")
	// Try to use the MAL session against the AniList authorize endpoint.
	resp := httpGet(t, h.base+"/auth/anilist?session="+url.QueryEscape(sess))
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusNotFound {
		t.Fatalf("status=%d want 404", resp.StatusCode)
	}
}

// ====== /auth/:service/callback + /auth/result ======

func TestOAuthCallbackExchangesCodeAndResultReturnsTokens(t *testing.T) {
	h := newOAuthHarness(t)
	sess, _ := h.startSession(t, "mal", "2.2.2.1")

	resultCh := make(chan map[string]any, 1)
	go func() {
		resp, err := http.Get(h.base + "/auth/result?session=" + url.QueryEscape(sess))
		if err != nil {
			resultCh <- map[string]any{"_err": err.Error()}
			return
		}
		defer resp.Body.Close()
		var m map[string]any
		_ = json.NewDecoder(resp.Body).Decode(&m)
		resultCh <- m
	}()

	// Hit the callback as the upstream browser would.
	cbURL := fmt.Sprintf("%s/auth/mal/callback?code=CODE123&state=%s", h.base, url.QueryEscape(sess))
	resp, err := http.Get(cbURL)
	if err != nil {
		t.Fatalf("callback: %v", err)
	}
	resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("callback status=%d", resp.StatusCode)
	}

	// Upstream should have been called with PKCE + code.
	form := h.upstream.form()
	if form.Get("code") != "CODE123" {
		t.Errorf("upstream code=%q", form.Get("code"))
	}
	if form.Get("code_verifier") == "" {
		t.Error("upstream missing code_verifier (PKCE)")
	}
	if form.Get("grant_type") != "authorization_code" {
		t.Errorf("grant_type=%q", form.Get("grant_type"))
	}

	select {
	case got := <-resultCh:
		if got["accessToken"] != "tok-abc" {
			t.Errorf("accessToken=%v want tok-abc", got["accessToken"])
		}
		if got["refreshToken"] != "ref-xyz" {
			t.Errorf("refreshToken=%v want ref-xyz", got["refreshToken"])
		}
	case <-time.After(3 * time.Second):
		t.Fatal("result never returned")
	}
}

func TestOAuthCallbackUpstreamError(t *testing.T) {
	h := newOAuthHarness(t)
	h.upstream.setReply(http.StatusBadRequest, `{"error":"invalid_grant"}`)
	sess, _ := h.startSession(t, "mal", "2.2.2.2")

	resultCh := make(chan map[string]any, 1)
	go func() {
		resp, err := http.Get(h.base + "/auth/result?session=" + url.QueryEscape(sess))
		if err != nil {
			resultCh <- map[string]any{"_err": err.Error()}
			return
		}
		defer resp.Body.Close()
		var m map[string]any
		_ = json.NewDecoder(resp.Body).Decode(&m)
		resultCh <- m
	}()

	resp := httpGet(t, fmt.Sprintf("%s/auth/mal/callback?code=CODE&state=%s", h.base, url.QueryEscape(sess)))
	resp.Body.Close()

	select {
	case got := <-resultCh:
		if got["error"] != "exchange_failed" {
			t.Errorf("expected error=exchange_failed, got %v", got)
		}
	case <-time.After(3 * time.Second):
		t.Fatal("result never returned")
	}
}

func TestOAuthCallbackUserCancelled(t *testing.T) {
	h := newOAuthHarness(t)
	sess, _ := h.startSession(t, "mal", "2.2.2.3")

	resultCh := make(chan map[string]any, 1)
	go func() {
		resp, err := http.Get(h.base + "/auth/result?session=" + url.QueryEscape(sess))
		if err != nil {
			resultCh <- map[string]any{"_err": err.Error()}
			return
		}
		defer resp.Body.Close()
		var m map[string]any
		_ = json.NewDecoder(resp.Body).Decode(&m)
		resultCh <- m
	}()

	resp := httpGet(t, fmt.Sprintf("%s/auth/mal/callback?error=access_denied&state=%s", h.base, url.QueryEscape(sess)))
	resp.Body.Close()

	select {
	case got := <-resultCh:
		if got["error"] != "access_denied" {
			t.Errorf("expected error=access_denied, got %v", got)
		}
	case <-time.After(3 * time.Second):
		t.Fatal("result never returned")
	}
}

func TestOAuthCallbackUnknownSessionIgnored(t *testing.T) {
	h := newOAuthHarness(t)
	resp := httpGet(t, h.base+"/auth/mal/callback?code=X&state=bogus")
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusNotFound {
		t.Fatalf("status=%d want 404", resp.StatusCode)
	}
}

func TestOAuthResultUnknownSession(t *testing.T) {
	h := newOAuthHarness(t)
	resp := httpGet(t, h.base+"/auth/result?session=nope")
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusGone {
		t.Fatalf("status=%d want 410", resp.StatusCode)
	}
}

func TestOAuthResultConsumedSecondCallIsGone(t *testing.T) {
	h := newOAuthHarness(t)
	sess, _ := h.startSession(t, "mal", "3.3.3.1")

	// Pre-seat the result so the first /auth/result returns immediately.
	h.proxy.mu.Lock()
	h.proxy.sessions[sess].complete(oauthTokenResult{AccessToken: "tok"})
	h.proxy.mu.Unlock()

	r1 := httpGet(t, h.base+"/auth/result?session="+url.QueryEscape(sess))
	r1.Body.Close()
	if r1.StatusCode != http.StatusOK {
		t.Fatalf("first result status=%d", r1.StatusCode)
	}
	// After consumption the session is deleted; second call sees unknown session.
	r2 := httpGet(t, h.base+"/auth/result?session="+url.QueryEscape(sess))
	r2.Body.Close()
	if r2.StatusCode != http.StatusGone {
		t.Fatalf("second result status=%d want 410", r2.StatusCode)
	}
}

// ====== Cleanup ======

func TestOAuthCleanupExpiresOldSessions(t *testing.T) {
	h := newOAuthHarness(t)
	sess, _ := h.startSession(t, "mal", "4.4.4.1")

	h.proxy.mu.Lock()
	h.proxy.sessions[sess].createdAt = time.Now().Add(-2 * oauthSessionTTL)
	h.proxy.mu.Unlock()

	h.proxy.cleanup()

	h.proxy.mu.Lock()
	_, exists := h.proxy.sessions[sess]
	h.proxy.mu.Unlock()
	if exists {
		t.Fatal("expired session should have been cleaned up")
	}
}

// ====== /auth/done ======

func TestOAuthDoneRendersSuccessPage(t *testing.T) {
	h := newOAuthHarness(t)
	resp := httpGet(t, h.base+"/auth/done")
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("status=%d", resp.StatusCode)
	}
	body, _ := io.ReadAll(resp.Body)
	if !strings.Contains(string(body), "Signed in to Plezy") {
		t.Errorf("body missing success message: %s", body)
	}
}

// ====== Disabled proxy returns 503 ======

func TestOAuthRoutesReturn503WhenDisabled(t *testing.T) {
	mux := http.NewServeMux()
	registerOAuthRoutes(mux, nil)
	srv := httptest.NewServer(mux)
	t.Cleanup(srv.Close)

	resp := httpGet(t, srv.URL+"/auth/start")
	resp.Body.Close()
	if resp.StatusCode != http.StatusServiceUnavailable {
		t.Errorf("status=%d want 503", resp.StatusCode)
	}
}

// ====== Path dispatch ======

func TestOAuthAuthRootRejectsBadPaths(t *testing.T) {
	h := newOAuthHarness(t)
	for _, path := range []string{"/auth/mal/weird", "/auth/unknown", "/auth/mal/callback/extra"} {
		resp := httpGet(t, h.base+path)
		resp.Body.Close()
		if resp.StatusCode != http.StatusNotFound {
			t.Errorf("%s: status=%d want 404", path, resp.StatusCode)
		}
	}
}

// ====== Long-poll timeout ======

func TestOAuthResultBlocksUntilCancel(t *testing.T) {
	// Pending sessions must NOT respond immediately; the long-poll contract is
	// that /auth/result blocks until the session completes or the client
	// cancels. The 204-after-server-timeout path takes 50s so isn't asserted.
	h := newOAuthHarness(t)
	sess, _ := h.startSession(t, "mal", "5.5.5.1")

	ctx, cancel := context.WithTimeout(context.Background(), 200*time.Millisecond)
	defer cancel()

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, h.base+"/auth/result?session="+url.QueryEscape(sess), nil)
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	resp, err := http.DefaultClient.Do(req)
	if err == nil {
		resp.Body.Close()
		t.Fatalf("expected client-side cancel, got status=%d", resp.StatusCode)
	}
}
