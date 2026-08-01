package main

// OAuth proxy: relays MAL + AniList authorization-code flows for devices that
// can't listen on localhost (TVs) or lack a browser (headless set-top boxes
// pair via a phone QR scan). Sessions live in memory for 10 minutes; AniList's
// client secret lives only in env vars. Access tokens transit the server
// briefly during code→token exchange and are never logged or persisted.

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"html"
	"io"
	"log"
	"net/http"
	"net/url"
	"os"
	"strings"
	"sync"
	"time"
)

const (
	oauthSessionTTL         = 10 * time.Minute
	oauthResultWait         = 50 * time.Second
	oauthMaxSessions        = 5000
	oauthStartBurst         = 3
	oauthStartRateSustained = 1
	oauthBrowserStateBytes  = 18 // 144 bits → 24 base64url chars
	oauthPollSecretBytes    = 18 // Independently generated device capability.
	oauthPKCEVerifierLen    = 64
	oauthUpstreamTimeout    = 15 * time.Second
)

// oauthServiceConfig describes a single upstream OAuth provider. Populated from
// env vars in oauthConfigFromEnv. A service with an empty ClientID is disabled.
type oauthServiceConfig struct {
	ClientID     string
	ClientSecret string // empty ⇒ provider doesn't issue/require one (MAL w/ PKCE)
	AuthorizeURL string
	TokenURL     string
	Scopes       string
	UsePKCE      bool
	PKCEMethod   string // "plain" or "S256"
}

type oauthTokenResult struct {
	AccessToken  string `json:"accessToken,omitempty"`
	RefreshToken string `json:"refreshToken,omitempty"`
	ExpiresIn    int    `json:"expiresIn,omitempty"`
	Error        string `json:"error,omitempty"`
}

// oauthSession is created by /auth/start and lives until its result is claimed
// or it is removed by cleanup. browserState crosses the browser/provider trust
// boundary. Only the SHA-256 digest of the device-only poll secret is retained.
// When both locks are needed, oauthProxy.mu must be acquired before s.mu.
type oauthSession struct {
	browserState string
	pollDigest   [sha256.Size]byte
	service      string
	codeVerifier string // MAL PKCE; empty for AniList. Cleared after token exchange.
	createdAt    time.Time
	done         chan struct{}

	mu        sync.Mutex
	completed bool
	result    *oauthTokenResult

	// Test seam used to deterministically seat concurrent result waiters.
	waitStarted func()
}

// completeLocked publishes at most one terminal result. The caller holds s.mu.
func (s *oauthSession) completeLocked(r oauthTokenResult) bool {
	if s.completed {
		return false
	}
	s.completed = true
	s.result = &r
	s.codeVerifier = "" // Secret, not needed after exchange.
	close(s.done)
	return true
}

// wait blocks only until the session is ready or ctx is cancelled. Result
// ownership is transferred separately by oauthProxy.claimResult.
func (s *oauthSession) wait(ctx context.Context) error {
	if s.waitStarted != nil {
		s.waitStarted()
	}
	select {
	case <-s.done:
		return nil
	case <-ctx.Done():
		return ctx.Err()
	}
}

func (s *oauthSession) pkceVerifier() string {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.codeVerifier
}

type oauthProxy struct {
	baseURL   string // e.g. https://ice.plezy.app
	services  map[string]oauthServiceConfig
	client    *http.Client
	clientIPs clientIPResolver

	mu            sync.Mutex
	browserStates map[string]*oauthSession
	pollDigests   map[[sha256.Size]byte]*oauthSession

	ipMu   sync.Mutex
	ipRate map[string]*rateLimiter
}

func newOAuthProxy(baseURL string, services map[string]oauthServiceConfig, clientIPs clientIPResolver) *oauthProxy {
	return &oauthProxy{
		baseURL:       strings.TrimRight(baseURL, "/"),
		services:      services,
		client:        &http.Client{Timeout: oauthUpstreamTimeout},
		clientIPs:     clientIPs,
		browserStates: make(map[string]*oauthSession),
		pollDigests:   make(map[[sha256.Size]byte]*oauthSession),
		ipRate:        make(map[string]*rateLimiter),
	}
}

// oauthConfigFromEnv reads the public base URL and per-service creds from the
// environment. Returns (nil, false) if OAUTH_BASE_URL is unset — the caller
// wires this as "OAuth disabled, endpoints return 503".
func oauthConfigFromEnv(clientIPs clientIPResolver) (*oauthProxy, bool) {
	base := os.Getenv("OAUTH_BASE_URL")
	if base == "" {
		return nil, false
	}
	services := map[string]oauthServiceConfig{}
	if id := os.Getenv("MAL_CLIENT_ID"); id != "" {
		services["mal"] = oauthServiceConfig{
			ClientID:     id,
			AuthorizeURL: "https://myanimelist.net/v1/oauth2/authorize",
			TokenURL:     "https://myanimelist.net/v1/oauth2/token",
			UsePKCE:      true,
			PKCEMethod:   "plain", // MAL rejects S256 despite RFC 7636
		}
	}
	if id := os.Getenv("ANILIST_CLIENT_ID"); id != "" {
		services["anilist"] = oauthServiceConfig{
			ClientID:     id,
			ClientSecret: os.Getenv("ANILIST_CLIENT_SECRET"),
			AuthorizeURL: "https://anilist.co/api/v2/oauth/authorize",
			TokenURL:     "https://anilist.co/api/v2/oauth/token",
		}
	}
	return newOAuthProxy(base, services, clientIPs), true
}

// registerOAuthRoutes registers all /auth/* handlers. If p is nil (no env
// config), all paths 503 so the integration page clearly says "not configured".
func registerOAuthRoutes(mux *http.ServeMux, p *oauthProxy) {
	if p == nil {
		mux.HandleFunc("/auth/", func(w http.ResponseWriter, r *http.Request) {
			http.Error(w, "OAuth proxy not configured", http.StatusServiceUnavailable)
		})
		return
	}
	mux.HandleFunc("/auth/start", p.handleStart)
	mux.HandleFunc("/auth/result", p.handleResult)
	mux.HandleFunc("/auth/done", p.handleDone)
	mux.HandleFunc("/auth/", p.handleAuthRoot)
}

// handleAuthRoot dispatches /auth/... paths that aren't served by their own
// registered handler. Covers /auth/:service and /auth/:service/callback.
func (p *oauthProxy) handleAuthRoot(w http.ResponseWriter, r *http.Request) {
	rest := strings.TrimPrefix(r.URL.Path, "/auth/")
	parts := strings.SplitN(rest, "/", 2)
	if len(parts) == 0 || parts[0] == "" {
		http.NotFound(w, r)
		return
	}
	service := parts[0]
	if len(parts) == 1 {
		p.handleAuthorize(w, r, service)
		return
	}
	if parts[1] == "callback" {
		p.handleCallback(w, r, service)
		return
	}
	http.NotFound(w, r)
}

// POST /auth/start  body={"service":"mal"|"anilist"}
// Response: {"session":"device-only poll capability","url":"https://.../auth/:service?state=...","expiresIn":600}
func (p *oauthProxy) handleStart(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Cache-Control", "no-store, private")
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	ip, err := p.clientIPs.resolve(r)
	if err != nil {
		http.Error(w, "Invalid client address", http.StatusBadRequest)
		return
	}
	if !p.ipAllow(ip) {
		http.Error(w, "Rate limited", http.StatusTooManyRequests)
		return
	}

	var body struct {
		Service string `json:"service"`
	}
	if err := json.NewDecoder(io.LimitReader(r.Body, 512)).Decode(&body); err != nil {
		http.Error(w, "Invalid JSON", http.StatusBadRequest)
		return
	}
	cfg, ok := p.services[body.Service]
	if !ok {
		http.Error(w, "Unknown service", http.StatusBadRequest)
		return
	}

	// Generate independent trust-domain values outside the map lock —
	// crypto/rand syscalls must not serialize concurrent /auth/start calls.
	var pollSecret string
	var sess *oauthSession
	for {
		pollSecret = randToken(oauthPollSecretBytes)
		sess = &oauthSession{
			browserState: randToken(oauthBrowserStateBytes),
			pollDigest:   digestPollSecret(pollSecret),
			service:      body.Service,
			createdAt:    time.Now(),
			done:         make(chan struct{}),
		}
		if cfg.UsePKCE {
			sess.codeVerifier = randPKCEVerifier()
		}

		p.mu.Lock()
		if len(p.browserStates) >= oauthMaxSessions {
			p.mu.Unlock()
			http.Error(w, "Server busy", http.StatusServiceUnavailable)
			return
		}
		if p.browserStates[sess.browserState] != nil || p.pollDigests[sess.pollDigest] != nil {
			p.mu.Unlock()
			continue
		}
		p.addSessionLocked(sess)
		p.mu.Unlock()
		break
	}

	resp := map[string]any{
		"session":   pollSecret,
		"url":       fmt.Sprintf("%s/auth/%s?state=%s", p.baseURL, url.PathEscape(body.Service), url.QueryEscape(sess.browserState)),
		"expiresIn": int(oauthSessionTTL.Seconds()),
	}
	writeJSON(w, http.StatusOK, resp)
}

// GET /auth/:service?state=X → 302 upstream authorize URL
func (p *oauthProxy) handleAuthorize(w http.ResponseWriter, r *http.Request, service string) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	cfg, ok := p.services[service]
	if !ok {
		http.NotFound(w, r)
		return
	}
	browserState := r.URL.Query().Get("state")
	p.mu.Lock()
	sess := p.browserStates[browserState]
	p.mu.Unlock()
	if sess == nil || sess.service != service {
		renderErrorPage(w, http.StatusNotFound, "This sign-in link is no longer valid. Start again from Plezy.")
		return
	}

	q := url.Values{
		"response_type": {"code"},
		"client_id":     {cfg.ClientID},
		"redirect_uri":  {p.redirectURI(service)},
		"state":         {sess.browserState},
	}
	if cfg.Scopes != "" {
		q.Set("scope", cfg.Scopes)
	}
	if cfg.UsePKCE {
		q.Set("code_challenge", sess.pkceVerifier()) // plain method ⇒ challenge == verifier
		q.Set("code_challenge_method", cfg.PKCEMethod)
	}
	http.Redirect(w, r, cfg.AuthorizeURL+"?"+q.Encode(), http.StatusFound)
}

// GET /auth/:service/callback?code=...&state=... → exchange, park, render page
func (p *oauthProxy) handleCallback(w http.ResponseWriter, r *http.Request, service string) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	cfg, ok := p.services[service]
	if !ok {
		http.NotFound(w, r)
		return
	}
	q := r.URL.Query()
	state := q.Get("state")
	p.mu.Lock()
	sess := p.browserStates[state]
	p.mu.Unlock()
	if sess == nil || sess.service != service {
		renderErrorPage(w, http.StatusNotFound, "This sign-in link is no longer valid. Start again from Plezy.")
		return
	}

	if upstreamErr := q.Get("error"); upstreamErr != "" {
		publicError := "authorization_failed"
		message := "Sign-in failed. Please try again."
		if upstreamErr == "access_denied" {
			publicError = "access_denied"
			message = "Sign-in was cancelled."
		}
		if !p.completeSession(sess, oauthTokenResult{Error: publicError}) {
			renderErrorPage(w, http.StatusNotFound, "This sign-in link is no longer valid. Start again from Plezy.")
			return
		}
		renderErrorPage(w, http.StatusOK, message)
		return
	}
	code := q.Get("code")
	if code == "" {
		if !p.completeSession(sess, oauthTokenResult{Error: "missing_code"}) {
			renderErrorPage(w, http.StatusNotFound, "This sign-in link is no longer valid. Start again from Plezy.")
			return
		}
		renderErrorPage(w, http.StatusBadRequest, "Sign-in response was incomplete. Please try again.")
		return
	}

	tok, err := p.exchangeCode(r.Context(), cfg, service, sess, code)
	if err != nil {
		log.Printf("oauth: %s token exchange failed: %v", service, err)
		if !p.completeSession(sess, oauthTokenResult{Error: "exchange_failed"}) {
			renderErrorPage(w, http.StatusNotFound, "This sign-in link is no longer valid. Start again from Plezy.")
			return
		}
		renderErrorPage(w, http.StatusBadGateway, "Couldn't complete sign-in. Please try again.")
		return
	}
	if !p.completeSession(sess, tok) {
		renderErrorPage(w, http.StatusNotFound, "This sign-in link is no longer valid. Start again from Plezy.")
		return
	}
	renderSuccessPage(w)
}

// GET /auth/result?session=X → long-poll, returns one terminal result.
func (p *oauthProxy) handleResult(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Cache-Control", "no-store, private")
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	pollDigest := digestPollSecret(r.URL.Query().Get("session"))
	p.mu.Lock()
	sess := p.pollDigests[pollDigest]
	p.mu.Unlock()
	if sess == nil {
		http.Error(w, "Session not found", http.StatusGone)
		return
	}

	ctx, cancel := context.WithTimeout(r.Context(), oauthResultWait)
	defer cancel()
	if err := sess.wait(ctx); err != nil {
		// Client should retry — session may still receive its callback.
		w.WriteHeader(http.StatusNoContent)
		return
	}
	result, ok := p.claimResult(pollDigest, sess)
	if !ok {
		http.Error(w, "Session not found", http.StatusGone)
		return
	}
	if result.Error != "" {
		writeJSON(w, http.StatusOK, map[string]any{"error": result.Error})
		return
	}
	writeJSON(w, http.StatusOK, result)
}

// GET /auth/done — static success page (Simkl's redirect target).
func (p *oauthProxy) handleDone(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	renderSuccessPage(w)
}

func (p *oauthProxy) exchangeCode(ctx context.Context, cfg oauthServiceConfig, service string, sess *oauthSession, code string) (oauthTokenResult, error) {
	form := url.Values{
		"grant_type":   {"authorization_code"},
		"code":         {code},
		"client_id":    {cfg.ClientID},
		"redirect_uri": {p.redirectURI(service)},
	}
	if cfg.ClientSecret != "" {
		form.Set("client_secret", cfg.ClientSecret)
	}
	if cfg.UsePKCE {
		form.Set("code_verifier", sess.pkceVerifier())
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, cfg.TokenURL, strings.NewReader(form.Encode()))
	if err != nil {
		return oauthTokenResult{}, err
	}
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	req.Header.Set("Accept", "application/json")

	resp, err := p.client.Do(req)
	if err != nil {
		return oauthTokenResult{}, err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return oauthTokenResult{}, fmt.Errorf("upstream HTTP %d", resp.StatusCode)
	}

	var parsed struct {
		AccessToken  string `json:"access_token"`
		RefreshToken string `json:"refresh_token"`
		ExpiresIn    int    `json:"expires_in"`
	}
	if err := json.NewDecoder(io.LimitReader(resp.Body, 64*1024)).Decode(&parsed); err != nil {
		return oauthTokenResult{}, fmt.Errorf("decode: %w", err)
	}
	if parsed.AccessToken == "" {
		return oauthTokenResult{}, errors.New("missing access_token in upstream response")
	}
	return oauthTokenResult{
		AccessToken:  parsed.AccessToken,
		RefreshToken: parsed.RefreshToken,
		ExpiresIn:    parsed.ExpiresIn,
	}, nil
}

func (p *oauthProxy) redirectURI(service string) string {
	return fmt.Sprintf("%s/auth/%s/callback", p.baseURL, service)
}

// addSessionLocked installs both independently generated keys as one logical
// session. The caller has already verified that neither key is live.
func (p *oauthProxy) addSessionLocked(sess *oauthSession) {
	p.browserStates[sess.browserState] = sess
	p.pollDigests[sess.pollDigest] = sess
}

// removeSessionLocked removes only entries still owned by sess, so a stale
// callback or waiter cannot remove a replacement.
func (p *oauthProxy) removeSessionLocked(sess *oauthSession) {
	if p.browserStates[sess.browserState] == sess {
		delete(p.browserStates, sess.browserState)
	}
	if p.pollDigests[sess.pollDigest] == sess {
		delete(p.pollDigests, sess.pollDigest)
	}
}

func (p *oauthProxy) completeSession(sess *oauthSession, result oauthTokenResult) bool {
	p.mu.Lock()
	defer p.mu.Unlock()
	if p.browserStates[sess.browserState] != sess || p.pollDigests[sess.pollDigest] != sess {
		return false
	}
	sess.mu.Lock()
	defer sess.mu.Unlock()
	return sess.completeLocked(result)
}

func (p *oauthProxy) claimResult(digest [sha256.Size]byte, sess *oauthSession) (oauthTokenResult, bool) {
	p.mu.Lock()
	defer p.mu.Unlock()
	if p.pollDigests[digest] != sess || p.browserStates[sess.browserState] != sess {
		return oauthTokenResult{}, false
	}
	sess.mu.Lock()
	defer sess.mu.Unlock()
	if sess.result == nil {
		return oauthTokenResult{}, false
	}
	result := *sess.result
	sess.result = nil
	p.removeSessionLocked(sess)
	return result, true
}

// cleanup drops sessions past oauthSessionTTL. Called by the main cleanup loop.
func (p *oauthProxy) cleanup() {
	now := time.Now()
	p.mu.Lock()
	for _, sess := range p.browserStates {
		if now.Sub(sess.createdAt) > oauthSessionTTL {
			p.removeSessionLocked(sess)
		}
	}
	p.mu.Unlock()

	p.ipMu.Lock()
	cleanupRateLimiters(p.ipRate, now, nil)
	p.ipMu.Unlock()
}

func (p *oauthProxy) ipAllow(ip string) bool {
	p.ipMu.Lock()
	defer p.ipMu.Unlock()
	rl, ok := p.ipRate[ip]
	if !ok {
		rl = newRateLimiter(oauthStartBurst, oauthStartRateSustained)
		p.ipRate[ip] = rl
	}
	return rl.allow()
}

const successPageHTML = `<!doctype html><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Signed in</title><style>html,body{margin:0;height:100%}body{display:flex;flex-direction:column;align-items:center;justify-content:center;font-family:-apple-system,system-ui,sans-serif;background:#fff;color:#1a1a1a;text-align:center;padding:1em;box-sizing:border-box}@media(prefers-color-scheme:dark){body{background:#0f0f0f;color:#f5f5f5}}.check{width:72px;height:72px;margin-bottom:20px}h2{margin:0 0 8px;font-weight:600;font-size:1.25rem}p{margin:0;opacity:.7;font-size:.95rem}</style><body><svg class="check" viewBox="0 0 24 24"><circle cx="12" cy="12" r="10" fill="#22c55e"/><path d="M7 12.5l3 3 7-7" stroke="#fff" stroke-width="2" fill="none" stroke-linecap="round" stroke-linejoin="round"/></svg><h2>Signed in to Plezy</h2><p>You can close this tab and return to the app.</p></body>`

// Split around the message so CSS `%` literals don't collide with Fprintf verbs.
const errorPagePrefix = `<!doctype html><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Sign-in failed</title><style>html,body{margin:0;height:100%}body{display:flex;flex-direction:column;align-items:center;justify-content:center;font-family:-apple-system,system-ui,sans-serif;background:#fff;color:#1a1a1a;text-align:center;padding:1em;box-sizing:border-box}@media(prefers-color-scheme:dark){body{background:#0f0f0f;color:#f5f5f5}}.x{width:72px;height:72px;margin-bottom:20px}h2{margin:0 0 8px;font-weight:600;font-size:1.25rem}p{margin:0;opacity:.7;font-size:.95rem}</style><body><svg class="x" viewBox="0 0 24 24"><circle cx="12" cy="12" r="10" fill="#ef4444"/><path d="M8 8l8 8M16 8l-8 8" stroke="#fff" stroke-width="2" fill="none" stroke-linecap="round"/></svg><h2>Sign-in failed</h2><p>`
const errorPageSuffix = `</p></body>`

func renderSuccessPage(w http.ResponseWriter) {
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	w.WriteHeader(http.StatusOK)
	io.WriteString(w, successPageHTML)
}

func renderErrorPage(w http.ResponseWriter, status int, message string) {
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	w.WriteHeader(status)
	io.WriteString(w, errorPagePrefix)
	io.WriteString(w, html.EscapeString(message))
	io.WriteString(w, errorPageSuffix)
}

func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(v)
}

func digestPollSecret(secret string) [sha256.Size]byte {
	return sha256.Sum256([]byte(secret))
}

func randToken(numBytes int) string {
	b := make([]byte, numBytes)
	if _, err := rand.Read(b); err != nil {
		// crypto/rand failing is catastrophic; log.Fatalf matches the style
		// in newLogStore for similar unrecoverable init failures.
		log.Fatalf("crypto/rand: %v", err)
	}
	return base64.RawURLEncoding.EncodeToString(b)
}

// randPKCEVerifier returns a 64-char string from MAL's required alphabet
// (RFC 7636 §4.1 unreserved set).
func randPKCEVerifier() string {
	const alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
	b := make([]byte, oauthPKCEVerifierLen)
	if _, err := rand.Read(b); err != nil {
		log.Fatalf("crypto/rand: %v", err)
	}
	for i := range b {
		b[i] = alphabet[int(b[i])%len(alphabet)]
	}
	return string(b)
}
