package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"regexp"
	"strconv"
	"strings"
	"time"
	"unicode"
)

const (
	steamOpenIDEndpoint     = "https://steamcommunity.com/openid/login"
	steamOwnedGamesEndpoint = "https://api.steampowered.com/IPlayerService/GetOwnedGames/v1/"
	maxSteamGames           = 2000
	maxSteamAPIResponse     = 1 << 20
	maxSteamNameRunes       = 256
)

var steamIDPattern = regexp.MustCompile(`^[0-9]{17}$`)

type steamOwnedGame struct {
	AppID    uint32 `json:"appid"`
	Name     string `json:"name"`
	IconHash string `json:"iconHash,omitempty"`
}

// handleSteamAuthorize starts Steam's browser-based OpenID 2.0 login. The
// return URL carries only the short-lived, one-use browser state.
func (p *oauthProxy) handleSteamAuthorize(w http.ResponseWriter, r *http.Request, sess *oauthSession) {
	w.Header().Set("Cache-Control", "no-store, private")
	w.Header().Set("Referrer-Policy", "no-referrer")
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	target, err := steamAuthorizeURL(p.baseURL, p.steamOpenIDEndpoint, sess.browserState)
	if err != nil {
		renderErrorPage(w, http.StatusInternalServerError, "Steam sign-in is not configured.")
		return
	}
	http.Redirect(w, r, target, http.StatusFound)
}

func steamAuthorizeURL(baseURL, endpoint, state string) (string, error) {
	parsed, err := url.Parse(endpoint)
	if err != nil || parsed.Scheme != "https" || parsed.Host != "steamcommunity.com" ||
		parsed.Path != "/openid/login" || parsed.User != nil || parsed.RawQuery != "" || parsed.Fragment != "" {
		return "", errors.New("Steam OpenID endpoint is invalid")
	}
	if state == "" || len(state) > 128 {
		return "", errors.New("Steam OpenID state is invalid")
	}
	base := strings.TrimRight(baseURL, "/")
	returnTo := base + "/auth/steam/callback?state=" + url.QueryEscape(state)
	query := url.Values{
		"openid.ns":         {"http://specs.openid.net/auth/2.0"},
		"openid.mode":       {"checkid_setup"},
		"openid.return_to":  {returnTo},
		"openid.realm":      {base + "/"},
		"openid.identity":   {"http://specs.openid.net/auth/2.0/identifier_select"},
		"openid.claimed_id": {"http://specs.openid.net/auth/2.0/identifier_select"},
	}
	parsed.RawQuery = query.Encode()
	return parsed.String(), nil
}

func (p *oauthProxy) handleSteamCallback(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Cache-Control", "no-store, private")
	w.Header().Set("Referrer-Policy", "no-referrer")
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	query := r.URL.Query()
	for _, values := range query {
		if len(values) != 1 {
			renderErrorPage(w, http.StatusBadRequest, "Steam sign-in response was invalid. Please start again.")
			return
		}
	}
	state, ok := singleQueryValue(query, "state")
	if !ok {
		renderErrorPage(w, http.StatusBadRequest, "Steam sign-in response was incomplete. Please start again.")
		return
	}

	p.mu.Lock()
	sess := p.browserStates[state]
	valid := sess != nil && sess.service == "steam" && !sess.callbackClaimed
	if valid {
		sess.callbackClaimed = true
	}
	p.mu.Unlock()
	if !valid {
		renderErrorPage(w, http.StatusNotFound, "This sign-in link is no longer valid. Start again from PlezyNG.")
		return
	}

	mode, _ := singleQueryValue(query, "openid.mode")
	if mode == "cancel" {
		p.completeSteamFailure(w, sess, http.StatusOK, "access_denied", "Steam sign-in was cancelled.")
		return
	}

	steamID, err := validateSteamAssertion(query, p.redirectURI("steam"), state, p.steamOpenIDEndpoint, time.Now())
	if err != nil {
		p.completeSteamFailure(w, sess, http.StatusBadRequest, "authorization_failed", "Steam sign-in response was invalid.")
		return
	}
	if err := p.verifySteamAssertion(r.Context(), query); err != nil {
		p.completeSteamFailure(w, sess, http.StatusBadGateway, "authorization_failed", "Steam could not verify this sign-in. Please try again.")
		return
	}

	games, available, truncated := p.fetchSteamOwnedGames(r.Context(), steamID)
	result := oauthTokenResult{
		SteamID:               steamID,
		SteamLibraryAvailable: available,
		SteamGames:            games,
		SteamCatalogTruncated: truncated,
	}
	if !p.completeSession(sess, result) {
		renderErrorPage(w, http.StatusNotFound, "This sign-in link is no longer valid. Start again from PlezyNG.")
		return
	}
	renderSuccessPage(w)
}

func (p *oauthProxy) completeSteamFailure(w http.ResponseWriter, sess *oauthSession, status int, publicError, message string) {
	if !p.completeSession(sess, oauthTokenResult{Error: publicError}) {
		renderErrorPage(w, http.StatusNotFound, "This sign-in link is no longer valid. Start again from PlezyNG.")
		return
	}
	renderErrorPage(w, status, message)
}

func singleQueryValue(values url.Values, key string) (string, bool) {
	rows, ok := values[key]
	if !ok || len(rows) != 1 || rows[0] == "" {
		return "", false
	}
	return rows[0], true
}

func validateSteamAssertion(query url.Values, redirectURI, state, openIDEndpoint string, now time.Time) (string, error) {
	required := []string{
		"openid.ns",
		"openid.mode",
		"openid.op_endpoint",
		"openid.claimed_id",
		"openid.identity",
		"openid.return_to",
		"openid.response_nonce",
		"openid.assoc_handle",
		"openid.signed",
		"openid.sig",
	}
	params := make(map[string]string, len(required))
	for _, key := range required {
		value, ok := singleQueryValue(query, key)
		if !ok {
			return "", fmt.Errorf("missing Steam OpenID field %s", key)
		}
		params[key] = value
	}
	if params["openid.ns"] != "http://specs.openid.net/auth/2.0" ||
		params["openid.mode"] != "id_res" ||
		params["openid.op_endpoint"] != openIDEndpoint {
		return "", errors.New("Steam OpenID issuer or mode does not match")
	}
	expectedReturn := redirectURI + "?state=" + url.QueryEscape(state)
	if params["openid.return_to"] != expectedReturn {
		return "", errors.New("Steam OpenID return URL does not match")
	}
	if !steamSignedFieldsComplete(params["openid.signed"]) {
		return "", errors.New("Steam OpenID assertion omitted signed fields")
	}
	if !validSteamNonce(params["openid.response_nonce"], now) {
		return "", errors.New("Steam OpenID nonce is stale")
	}
	return steamIDFromClaimedID(params["openid.claimed_id"], params["openid.identity"])
}

func steamSignedFieldsComplete(signed string) bool {
	present := make(map[string]bool)
	for _, field := range strings.Split(signed, ",") {
		present[field] = true
	}
	for _, field := range []string{"op_endpoint", "claimed_id", "identity", "return_to", "response_nonce", "assoc_handle"} {
		if !present[field] {
			return false
		}
	}
	return true
}

func validSteamNonce(nonce string, now time.Time) bool {
	// OpenID 2.0 nonces begin with an ISO-8601 UTC timestamp followed by a
	// provider-generated unique suffix. The state and signed return_to are
	// single-use too, but the timestamp also bounds stale assertions.
	if len(nonce) <= len("2006-01-02T15:04:05Z") {
		return false
	}
	stamp, err := time.Parse("2006-01-02T15:04:05Z", nonce[:20])
	if err != nil || stamp.After(now.Add(time.Minute)) || now.Sub(stamp) > oauthSessionTTL {
		return false
	}
	for _, r := range nonce[20:] {
		if unicode.IsControl(r) {
			return false
		}
	}
	return true
}

func steamIDFromClaimedID(claimedID, identity string) (string, error) {
	if claimedID != identity {
		return "", errors.New("Steam OpenID identity mismatch")
	}
	parsed, err := url.Parse(claimedID)
	if err != nil || parsed.User != nil || parsed.RawQuery != "" || parsed.Fragment != "" ||
		(parsed.Scheme != "http" && parsed.Scheme != "https") ||
		!strings.EqualFold(parsed.Hostname(), "steamcommunity.com") || parsed.Port() != "" {
		return "", errors.New("Steam OpenID claimed identity is invalid")
	}
	const prefix = "/openid/id/"
	if !strings.HasPrefix(parsed.Path, prefix) {
		return "", errors.New("Steam OpenID claimed identity path is invalid")
	}
	steamID := strings.TrimPrefix(parsed.Path, prefix)
	if !steamIDPattern.MatchString(steamID) {
		return "", errors.New("Steam OpenID claimed identity is invalid")
	}
	if _, err := strconv.ParseUint(steamID, 10, 64); err != nil {
		return "", errors.New("Steam OpenID claimed identity is invalid")
	}
	return steamID, nil
}

func (p *oauthProxy) verifySteamAssertion(ctx context.Context, query url.Values) error {
	endpoint := p.steamOpenIDEndpoint
	if endpoint == "" {
		endpoint = steamOpenIDEndpoint
	}
	form := make(url.Values)
	for key, values := range query {
		if strings.HasPrefix(key, "openid.") && len(values) == 1 {
			form.Set(key, values[0])
		}
	}
	form.Set("openid.mode", "check_authentication")
	request, err := http.NewRequestWithContext(ctx, http.MethodPost, endpoint, strings.NewReader(form.Encode()))
	if err != nil {
		return errors.New("could not construct Steam assertion verification")
	}
	request.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	request.Header.Set("Accept", "text/plain")
	client := p.steamClient
	if client == nil {
		client = &http.Client{
			Timeout: oauthUpstreamTimeout,
			CheckRedirect: func(_ *http.Request, _ []*http.Request) error {
				return http.ErrUseLastResponse
			},
		}
	}
	response, err := client.Do(request)
	if err != nil {
		return errors.New("Steam assertion verification failed")
	}
	defer response.Body.Close()
	if response.StatusCode != http.StatusOK {
		return errors.New("Steam assertion verification failed")
	}
	body, err := io.ReadAll(io.LimitReader(response.Body, 16*1024))
	if err != nil || len(body) == 16*1024 {
		return errors.New("Steam assertion was rejected")
	}
	valid := false
	for _, line := range strings.Split(strings.TrimSpace(string(body)), "\n") {
		if strings.TrimSpace(line) == "is_valid:true" {
			valid = true
		} else if strings.HasPrefix(line, "is_valid:") {
			return errors.New("Steam assertion was rejected")
		}
	}
	if !valid {
		return errors.New("Steam assertion was rejected")
	}
	return nil
}

func (p *oauthProxy) fetchSteamOwnedGames(ctx context.Context, steamID string) ([]steamOwnedGame, bool, bool) {
	if p.steamWebAPIKey == "" {
		return nil, false, false
	}
	endpoint := p.steamOwnedGamesEndpoint
	if endpoint == "" {
		endpoint = steamOwnedGamesEndpoint
	}
	target, err := url.Parse(endpoint)
	if err != nil {
		return nil, false, false
	}
	query := target.Query()
	query.Set("key", p.steamWebAPIKey)
	query.Set("steamid", steamID)
	query.Set("include_appinfo", "true")
	query.Set("include_played_free_games", "false")
	target.RawQuery = query.Encode()

	request, err := http.NewRequestWithContext(ctx, http.MethodGet, target.String(), nil)
	if err != nil {
		return nil, false, false
	}
	request.Header.Set("Accept", "application/json")
	client := p.steamClient
	if client == nil {
		client = &http.Client{
			Timeout: oauthUpstreamTimeout,
			CheckRedirect: func(_ *http.Request, _ []*http.Request) error {
				return http.ErrUseLastResponse
			},
		}
	}
	response, err := client.Do(request)
	if err != nil {
		return nil, false, false
	}
	defer response.Body.Close()
	if response.StatusCode != http.StatusOK {
		return nil, false, false
	}
	body, err := io.ReadAll(io.LimitReader(response.Body, maxSteamAPIResponse+1))
	if err != nil || len(body) > maxSteamAPIResponse {
		return nil, false, false
	}
	var document struct {
		Response struct {
			GameCount *int            `json:"game_count"`
			Games     json.RawMessage `json:"games"`
		} `json:"response"`
	}
	if err := json.Unmarshal(body, &document); err != nil || document.Response.GameCount == nil || len(document.Response.Games) == 0 ||
		string(document.Response.Games) == "null" {
		// A missing games field means the user has hidden game details. Do not
		// turn that response into an authoritative empty library.
		return nil, false, false
	}
	var rows []struct {
		AppID uint64 `json:"appid"`
		Name  string `json:"name"`
		Icon  string `json:"img_icon_url"`
	}
	if err := json.Unmarshal(document.Response.Games, &rows); err != nil {
		return nil, false, false
	}
	games := make([]steamOwnedGame, 0, min(len(rows), maxSteamGames))
	for _, row := range rows {
		if row.AppID == 0 || row.AppID > uint64(^uint32(0)) || !validSteamGameName(row.Name) {
			continue
		}
		icon := row.Icon
		if len(icon) > 64 || !allHex(icon) {
			icon = ""
		}
		games = append(games, steamOwnedGame{AppID: uint32(row.AppID), Name: strings.TrimSpace(row.Name), IconHash: icon})
		if len(games) == maxSteamGames {
			break
		}
	}
	return games, true, len(rows) > maxSteamGames || *document.Response.GameCount > maxSteamGames
}

func validSteamGameName(name string) bool {
	name = strings.TrimSpace(name)
	if name == "" || len([]rune(name)) > maxSteamNameRunes {
		return false
	}
	for _, r := range name {
		if unicode.IsControl(r) {
			return false
		}
	}
	return true
}

func allHex(value string) bool {
	for _, r := range value {
		if !((r >= '0' && r <= '9') || (r >= 'a' && r <= 'f') || (r >= 'A' && r <= 'F')) {
			return false
		}
	}
	return true
}
