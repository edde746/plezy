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
	proxy    *oauthProxy
	srv      *httptest.Server
	base     string
	upstream *mockUpstream
}

func newOAuthHarness(t *testing.T) *oauthHarness {
	t.Helper()
	return newOAuthHarnessWithResolver(t, mustClientIPResolver(t, "127.0.0.0/8"))
}

func newOAuthHarnessWithResolver(t *testing.T, clientIPs clientIPResolver) *oauthHarness {
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
	}, clientIPs)
	mux := http.NewServeMux()
	registerOAuthRoutes(mux, proxy)
	srv := httptest.NewServer(mux)
	t.Cleanup(srv.Close)
	// Rewire baseURL to the real httptest URL so redirect_uri computes correctly.
	proxy.baseURL = srv.URL
	return &oauthHarness{proxy: proxy, srv: srv, base: srv.URL, upstream: up}
}

func (h *oauthHarness) startSession(t *testing.T, service, ip string) (pollSecret, browserState, authorizeURL string) {
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
	if got := resp.Header.Get("Cache-Control"); got != "no-store, private" {
		t.Fatalf("start Cache-Control=%q", got)
	}
	var out struct {
		Session   string `json:"session"`
		URL       string `json:"url"`
		ExpiresIn int    `json:"expiresIn"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&out); err != nil {
		t.Fatalf("decode: %v", err)
	}
	parsed, err := url.Parse(out.URL)
	if err != nil {
		t.Fatalf("parse authorize URL: %v", err)
	}
	state := parsed.Query().Get("state")
	if out.Session == "" || out.URL == "" || state == "" {
		t.Fatalf("empty poll secret/url/browser state: %+v", out)
	}
	return out.Session, state, out.URL
}

func postOAuthStart(t *testing.T, h *oauthHarness, service, xff string) *http.Response {
	t.Helper()
	body, err := json.Marshal(map[string]string{"service": service})
	if err != nil {
		t.Fatalf("marshal: %v", err)
	}
	req, err := http.NewRequest(http.MethodPost, h.base+"/auth/start", bytes.NewReader(body))
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	req.Header.Set("Content-Type", "application/json")
	if xff != "" {
		req.Header.Set("X-Forwarded-For", xff)
	}
	return httpDo(t, req)
}

// ====== /auth/start ======

func TestOAuthStartSeparatesDeviceCapabilityFromBrowserState(t *testing.T) {
	h := newOAuthHarness(t)
	pollSecret, browserState, authorizeURL := h.startSession(t, "mal", "1.2.3.4")
	if pollSecret == browserState {
		t.Fatal("device poll capability must differ from browser state")
	}
	if !strings.HasPrefix(authorizeURL, h.base+"/auth/mal?state=") {
		t.Fatalf("url=%q doesn't look like the authorize start URL", authorizeURL)
	}
	if strings.Contains(authorizeURL, pollSecret) {
		t.Fatalf("authorize URL disclosed device poll capability")
	}
	if got := h.proxy.pollDigests[digestPollSecret(pollSecret)]; got == nil {
		t.Fatal("poll capability digest was not indexed")
	}
	if got := h.proxy.browserStates[browserState]; got == nil {
		t.Fatal("browser state was not indexed")
	}
	pollAsBrowser := httpGet(t, h.base+"/auth/mal?state="+url.QueryEscape(pollSecret))
	pollAsBrowser.Body.Close()
	if pollAsBrowser.StatusCode != http.StatusNotFound {
		t.Fatalf("poll capability authorized browser path: status=%d", pollAsBrowser.StatusCode)
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
	for range oauthStartBurst {
		_, _, _ = h.startSession(t, "mal", ip) // should all succeed
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

func TestOAuthSessionLimitCountsLogicalSessions(t *testing.T) {
	h := newOAuthHarness(t)
	h.proxy.mu.Lock()
	for i := range oauthMaxSessions - 1 {
		sess := &oauthSession{
			browserState: fmt.Sprintf("state-%d", i),
			pollDigest:   digestPollSecret(fmt.Sprintf("poll-%d", i)),
		}
		h.proxy.addSessionLocked(sess)
	}
	h.proxy.mu.Unlock()

	body, _ := json.Marshal(map[string]string{"service": "mal"})
	req := httptest.NewRequest(http.MethodPost, "/auth/start", bytes.NewReader(body))
	rec := httptest.NewRecorder()
	h.proxy.handleStart(rec, req)
	if rec.Code != http.StatusOK {
		t.Fatalf("start with %d logical sessions: status=%d want 200", oauthMaxSessions-1, rec.Code)
	}
	h.proxy.mu.Lock()
	browserCount := len(h.proxy.browserStates)
	pollCount := len(h.proxy.pollDigests)
	h.proxy.mu.Unlock()
	if browserCount != oauthMaxSessions || pollCount != oauthMaxSessions {
		t.Fatalf("index counts browser=%d poll=%d want %d each", browserCount, pollCount, oauthMaxSessions)
	}
}

func TestOAuthStartUsesTrustedCanonicalClientIdentity(t *testing.T) {
	t.Run("untrusted spoof rotation shares direct peer bucket", func(t *testing.T) {
		h := newOAuthHarnessWithResolver(t, newClientIPResolver(nil))
		for i := range oauthStartBurst {
			resp := postOAuthStart(t, h, "mal", fmt.Sprintf("203.0.113.%d", i+1))
			resp.Body.Close()
			if resp.StatusCode != http.StatusOK {
				t.Fatalf("start %d status=%d", i, resp.StatusCode)
			}
		}
		denied := postOAuthStart(t, h, "mal", "198.51.100.10")
		denied.Body.Close()
		if denied.StatusCode != http.StatusTooManyRequests {
			t.Fatalf("rotated spoof status=%d, want 429", denied.StatusCode)
		}
	})

	t.Run("validated clients have independent buckets", func(t *testing.T) {
		h := newOAuthHarness(t)
		for _, ip := range []string{"203.0.113.1", "203.0.113.2"} {
			for range oauthStartBurst {
				resp := postOAuthStart(t, h, "mal", ip)
				resp.Body.Close()
				if resp.StatusCode != http.StatusOK {
					t.Fatalf("client %s status=%d", ip, resp.StatusCode)
				}
			}
		}
	})

	t.Run("malformed trusted chain mutates no state", func(t *testing.T) {
		h := newOAuthHarness(t)
		resp := postOAuthStart(t, h, "mal", "203.0.113.1,")
		resp.Body.Close()
		if resp.StatusCode != http.StatusBadRequest {
			t.Fatalf("status=%d, want 400", resp.StatusCode)
		}
		h.proxy.ipMu.Lock()
		rateCount := len(h.proxy.ipRate)
		h.proxy.ipMu.Unlock()
		h.proxy.mu.Lock()
		browserCount := len(h.proxy.browserStates)
		pollCount := len(h.proxy.pollDigests)
		h.proxy.mu.Unlock()
		if rateCount != 0 || browserCount != 0 || pollCount != 0 {
			t.Fatalf(
				"malformed chain mutated OAuth state: rates=%d browser=%d poll=%d",
				rateCount,
				browserCount,
				pollCount,
			)
		}
	})

	t.Run("untrusted malformed header is ignored", func(t *testing.T) {
		h := newOAuthHarnessWithResolver(t, newClientIPResolver(nil))
		resp := postOAuthStart(t, h, "mal", "bad,")
		resp.Body.Close()
		if resp.StatusCode != http.StatusOK {
			t.Fatalf("status=%d, want 200", resp.StatusCode)
		}
	})
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
	pollSecret, browserState, _ := h.startSession(t, "mal", "1.1.1.1")

	client := &http.Client{CheckRedirect: func(*http.Request, []*http.Request) error { return http.ErrUseLastResponse }}
	resp, err := client.Get(h.base + "/auth/mal?state=" + url.QueryEscape(browserState))
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
	if q.Get("state") != browserState {
		t.Errorf("state=%q, want browser state %q", q.Get("state"), browserState)
	}
	if q.Get("state") == pollSecret {
		t.Error("provider state disclosed device poll capability")
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
	_, browserState, _ := h.startSession(t, "anilist", "1.1.1.2")
	client := &http.Client{CheckRedirect: func(*http.Request, []*http.Request) error { return http.ErrUseLastResponse }}
	resp, err := client.Get(h.base + "/auth/anilist?state=" + url.QueryEscape(browserState))
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
	resp := httpGet(t, h.base+"/auth/mal?state=bogus")
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
	_, browserState, _ := h.startSession(t, "mal", "1.1.1.3")
	// Try to use the MAL browser state against the AniList authorize endpoint.
	resp := httpGet(t, h.base+"/auth/anilist?state="+url.QueryEscape(browserState))
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusNotFound {
		t.Fatalf("status=%d want 404", resp.StatusCode)
	}
}

// ====== /auth/:service/callback + /auth/result ======

type oauthResultResponse struct {
	status       int
	cacheControl string
	body         map[string]any
	err          error
}

func requestOAuthResult(rawURL string) oauthResultResponse {
	resp, err := http.Get(rawURL)
	if err != nil {
		return oauthResultResponse{err: err}
	}
	defer resp.Body.Close()
	out := oauthResultResponse{
		status:       resp.StatusCode,
		cacheControl: resp.Header.Get("Cache-Control"),
	}
	if resp.StatusCode == http.StatusOK {
		out.body = make(map[string]any)
		out.err = json.NewDecoder(resp.Body).Decode(&out.body)
	}
	return out
}

func TestOAuthBrowserStateCannotClaimResult(t *testing.T) {
	for _, service := range []string{"mal", "anilist"} {
		t.Run(service, func(t *testing.T) {
			h := newOAuthHarness(t)
			pollSecret, browserState, _ := h.startSession(t, service, "2.2.2.1")

			browserClaim := requestOAuthResult(h.base + "/auth/result?session=" + url.QueryEscape(browserState))
			if browserClaim.err != nil {
				t.Fatalf("browser-state result request: %v", browserClaim.err)
			}
			if browserClaim.status != http.StatusGone {
				t.Fatalf("browser-state result status=%d want 410", browserClaim.status)
			}

			callback := fmt.Sprintf("%s/auth/%s/callback?code=CODE123&state=%s", h.base, service, url.QueryEscape(browserState))
			resp := httpGet(t, callback)
			resp.Body.Close()
			if resp.StatusCode != http.StatusOK {
				t.Fatalf("callback status=%d", resp.StatusCode)
			}

			result := requestOAuthResult(h.base + "/auth/result?session=" + url.QueryEscape(pollSecret))
			if result.err != nil {
				t.Fatalf("device result request: %v", result.err)
			}
			if result.status != http.StatusOK {
				t.Fatalf("device result status=%d want 200", result.status)
			}
			if result.cacheControl != "no-store, private" {
				t.Fatalf("result Cache-Control=%q", result.cacheControl)
			}
			if result.body["accessToken"] != "tok-abc" || result.body["refreshToken"] != "ref-xyz" {
				t.Fatalf("unexpected result: %v", result.body)
			}

			second := requestOAuthResult(h.base + "/auth/result?session=" + url.QueryEscape(pollSecret))
			if second.err != nil {
				t.Fatalf("second result request: %v", second.err)
			}
			if second.status != http.StatusGone {
				t.Fatalf("second result status=%d want 410", second.status)
			}

			form := h.upstream.form()
			if form.Get("code") != "CODE123" {
				t.Errorf("upstream code=%q", form.Get("code"))
			}
			if service == "mal" && form.Get("code_verifier") == "" {
				t.Error("upstream missing MAL code verifier")
			}
			if service == "anilist" && form.Get("code_verifier") != "" {
				t.Error("AniList exchange unexpectedly included a code verifier")
			}
		})
	}
}

func TestOAuthConcurrentResultClaimIsOneShot(t *testing.T) {
	for _, tc := range []struct {
		name   string
		result oauthTokenResult
	}{
		{name: "token", result: oauthTokenResult{AccessToken: "tok"}},
		{name: "provider error", result: oauthTokenResult{Error: "authorization_failed"}},
	} {
		t.Run(tc.name, func(t *testing.T) {
			h := newOAuthHarness(t)
			pollSecret, browserState, _ := h.startSession(t, "mal", "2.2.2.2")
			digest := digestPollSecret(pollSecret)

			h.proxy.mu.Lock()
			sess := h.proxy.pollDigests[digest]
			h.proxy.mu.Unlock()
			if sess == nil {
				t.Fatal("session missing from poll index")
			}

			seated := make(chan struct{}, 2)
			sess.waitStarted = func() { seated <- struct{}{} }
			results := make(chan oauthResultResponse, 2)
			resultURL := h.base + "/auth/result?session=" + url.QueryEscape(pollSecret)
			go func() { results <- requestOAuthResult(resultURL) }()
			go func() { results <- requestOAuthResult(resultURL) }()

			for range 2 {
				select {
				case <-seated:
				case <-time.After(3 * time.Second):
					t.Fatal("result waiter did not reach readiness boundary")
				}
			}
			if !h.proxy.completeSession(sess, tc.result) {
				t.Fatal("could not complete current session")
			}

			statuses := map[int]int{}
			var winningBody map[string]any
			for range 2 {
				select {
				case got := <-results:
					if got.err != nil {
						t.Fatalf("result request: %v", got.err)
					}
					if got.cacheControl != "no-store, private" {
						t.Errorf("result Cache-Control=%q", got.cacheControl)
					}
					statuses[got.status]++
					if got.status == http.StatusOK {
						winningBody = got.body
					}
				case <-time.After(3 * time.Second):
					t.Fatal("result request did not return")
				}
			}
			if statuses[http.StatusOK] != 1 || statuses[http.StatusGone] != 1 {
				t.Fatalf("statuses=%v want one 200 and one 410", statuses)
			}
			if tc.result.Error != "" && winningBody["error"] != tc.result.Error {
				t.Fatalf("winning error result=%v", winningBody)
			}
			if tc.result.AccessToken != "" && winningBody["accessToken"] != tc.result.AccessToken {
				t.Fatalf("winning token result=%v", winningBody)
			}

			h.proxy.mu.Lock()
			_, hasBrowserState := h.proxy.browserStates[browserState]
			_, hasPollDigest := h.proxy.pollDigests[digest]
			h.proxy.mu.Unlock()
			sess.mu.Lock()
			storedResult := sess.result
			sess.mu.Unlock()
			if hasBrowserState || hasPollDigest || storedResult != nil {
				t.Fatalf("claim left state: browser=%v poll=%v result=%v", hasBrowserState, hasPollDigest, storedResult)
			}
		})
	}
}

func TestOAuthCallbackErrorsAreGenericAndOneShot(t *testing.T) {
	for _, tc := range []struct {
		name        string
		callback    func(base, state string) string
		wantError   string
		wantCBState int
	}{
		{
			name: "provider detail",
			callback: func(base, state string) string {
				return fmt.Sprintf("%s/auth/mal/callback?error=provider_detail_canary&state=%s", base, url.QueryEscape(state))
			},
			wantError:   "authorization_failed",
			wantCBState: http.StatusOK,
		},
		{
			name: "user cancelled",
			callback: func(base, state string) string {
				return fmt.Sprintf("%s/auth/mal/callback?error=access_denied&state=%s", base, url.QueryEscape(state))
			},
			wantError:   "access_denied",
			wantCBState: http.StatusOK,
		},
	} {
		t.Run(tc.name, func(t *testing.T) {
			h := newOAuthHarness(t)
			pollSecret, browserState, _ := h.startSession(t, "mal", "2.2.2.3")
			resp := httpGet(t, tc.callback(h.base, browserState))
			resp.Body.Close()
			if resp.StatusCode != tc.wantCBState {
				t.Fatalf("callback status=%d want %d", resp.StatusCode, tc.wantCBState)
			}
			result := requestOAuthResult(h.base + "/auth/result?session=" + url.QueryEscape(pollSecret))
			if result.err != nil {
				t.Fatalf("result request: %v", result.err)
			}
			if result.status != http.StatusOK || result.body["error"] != tc.wantError {
				t.Fatalf("result status=%d body=%v", result.status, result.body)
			}
			if result.cacheControl != "no-store, private" {
				t.Fatalf("result Cache-Control=%q", result.cacheControl)
			}
			second := requestOAuthResult(h.base + "/auth/result?session=" + url.QueryEscape(pollSecret))
			if second.status != http.StatusGone {
				t.Fatalf("second result status=%d want 410", second.status)
			}
		})
	}
}

func TestOAuthCallbackExchangeFailureIsOneShot(t *testing.T) {
	h := newOAuthHarness(t)
	h.upstream.setReply(http.StatusBadRequest, `{"error":"invalid_grant"}`)
	pollSecret, browserState, _ := h.startSession(t, "mal", "2.2.2.4")

	resp := httpGet(t, fmt.Sprintf("%s/auth/mal/callback?code=CODE&state=%s", h.base, url.QueryEscape(browserState)))
	resp.Body.Close()
	if resp.StatusCode != http.StatusBadGateway {
		t.Fatalf("callback status=%d want 502", resp.StatusCode)
	}
	result := requestOAuthResult(h.base + "/auth/result?session=" + url.QueryEscape(pollSecret))
	if result.status != http.StatusOK || result.body["error"] != "exchange_failed" {
		t.Fatalf("result status=%d body=%v", result.status, result.body)
	}
	if result.cacheControl != "no-store, private" {
		t.Fatalf("result Cache-Control=%q", result.cacheControl)
	}
	second := requestOAuthResult(h.base + "/auth/result?session=" + url.QueryEscape(pollSecret))
	if second.status != http.StatusGone {
		t.Fatalf("second result status=%d want 410", second.status)
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

// ====== Cleanup ======

func TestOAuthCleanupRemovesBothIndexesAndSuppressesStaleCompletion(t *testing.T) {
	h := newOAuthHarness(t)
	pollSecret, browserState, _ := h.startSession(t, "mal", "4.4.4.1")
	digest := digestPollSecret(pollSecret)

	h.proxy.mu.Lock()
	sess := h.proxy.browserStates[browserState]
	sess.createdAt = time.Now().Add(-2 * oauthSessionTTL)
	h.proxy.mu.Unlock()

	h.proxy.cleanup()

	h.proxy.mu.Lock()
	_, hasBrowserState := h.proxy.browserStates[browserState]
	_, hasPollDigest := h.proxy.pollDigests[digest]
	h.proxy.mu.Unlock()
	if hasBrowserState || hasPollDigest {
		t.Fatalf("expired session indexes remain: browser=%v poll=%v", hasBrowserState, hasPollDigest)
	}
	if h.proxy.completeSession(sess, oauthTokenResult{AccessToken: "stale-token"}) {
		t.Fatal("stale callback completed a removed session")
	}
	sess.mu.Lock()
	storedResult := sess.result
	sess.mu.Unlock()
	if storedResult != nil {
		t.Fatal("stale callback retained an orphaned token result")
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
	sess, _, _ := h.startSession(t, "mal", "5.5.5.1")

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
