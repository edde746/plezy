package main

import (
	"context"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"io"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"sync"
	"time"
	"unicode"
)

type steamAchievement struct {
	ID          string `json:"id"`
	Name        string `json:"name"`
	Description string `json:"description"`
	Unlocked    bool   `json:"unlocked"`
	Hidden      bool   `json:"hidden"`
	UnlockedAt  int64  `json:"unlockedAt,omitempty"`
}
type steamNewsItem struct {
	Title string `json:"title"`
	Feed  string `json:"feed"`
	Date  int64  `json:"date"`
}
type steamPlayingFriend struct {
	SteamID string `json:"steamId"`
	Name    string `json:"name"`
}
type steamGameContext struct {
	AppID                 uint32               `json:"appId"`
	SteamID               string               `json:"steamId"`
	ObservedAt            int64                `json:"observedAt"`
	AchievementsAvailable bool                 `json:"achievementsAvailable"`
	AchievementsTruncated bool                 `json:"achievementsTruncated"`
	Achievements          []steamAchievement   `json:"achievements"`
	NewsAvailable         bool                 `json:"newsAvailable"`
	News                  []steamNewsItem      `json:"news"`
	FriendsRequested      bool                 `json:"friendsRequested"`
	FriendsAvailable      bool                 `json:"friendsAvailable"`
	FriendsTruncated      bool                 `json:"friendsTruncated"`
	Friends               []steamPlayingFriend `json:"friends"`
}

// Called on an explicit game-details action. The account identity is always
// taken from the verified grant; callers cannot query arbitrary accounts.
func (p *oauthProxy) handleSteamGameContext(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Cache-Control", "no-store, private")
	w.Header().Set("Referrer-Policy", "no-referrer")
	w.Header().Set("X-Content-Type-Options", "nosniff")
	if r.Method != http.MethodPost {
		w.Header().Set("Allow", "POST")
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	if r.URL.RawQuery != "" {
		http.Error(w, "Invalid request", http.StatusBadRequest)
		return
	}
	headers := r.Header.Values("Authorization")
	if len(headers) != 1 || !strings.HasPrefix(headers[0], "Bearer ") {
		http.Error(w, "Relink Steam", http.StatusUnauthorized)
		return
	}
	token := strings.TrimPrefix(headers[0], "Bearer ")
	secret, err := base64.RawURLEncoding.DecodeString(token)
	if err != nil || len(token) != 43 || len(secret) != 32 {
		http.Error(w, "Relink Steam", http.StatusUnauthorized)
		return
	}
	var input struct {
		AppID          uint32 `json:"appId"`
		IncludeFriends bool   `json:"includeFriends"`
	}
	decoder := json.NewDecoder(http.MaxBytesReader(w, r.Body, 1024))
	decoder.DisallowUnknownFields()
	if decoder.Decode(&input) != nil || input.AppID == 0 || decoder.Decode(new(any)) != io.EOF {
		http.Error(w, "Invalid game request", http.StatusBadRequest)
		return
	}
	ip, err := p.clientIPs.resolve(r)
	if err != nil {
		http.Error(w, "Invalid client address", http.StatusBadRequest)
		return
	}
	if allowed, _ := p.pollAllow(ip); !allowed {
		w.Header().Set("Retry-After", "30")
		http.Error(w, "Try later", http.StatusTooManyRequests)
		return
	}
	digest := sha256.Sum256([]byte(token))
	p.mu.Lock()
	grant := p.steamCatalogGrants[digest]
	if grant == nil || !time.Now().Before(grant.expires) {
		p.mu.Unlock()
		http.Error(w, "Relink Steam", http.StatusUnauthorized)
		return
	}
	if grant.contextLoading || p.steamContextActive >= 16 || time.Since(grant.contextFetched) < 5*time.Second {
		p.mu.Unlock()
		w.Header().Set("Retry-After", "5")
		http.Error(w, "Try later", http.StatusTooManyRequests)
		return
	}
	grant.contextLoading = true
	p.steamContextActive++
	steamID := grant.steamID
	p.mu.Unlock()
	ctx, cancel := context.WithTimeout(r.Context(), oauthUpstreamTimeout)
	defer cancel()
	result := steamGameContext{AppID: input.AppID, SteamID: steamID, ObservedAt: time.Now().Unix(), FriendsRequested: input.IncludeFriends}
	var tasks sync.WaitGroup
	tasks.Add(2)
	go func() {
		defer tasks.Done()
		result.Achievements, result.AchievementsAvailable, result.AchievementsTruncated = p.steamAchievements(ctx, steamID, input.AppID)
	}()
	go func() { defer tasks.Done(); result.News, result.NewsAvailable = p.steamNews(ctx, input.AppID) }()
	if input.IncludeFriends {
		tasks.Add(1)
		go func() {
			defer tasks.Done()
			result.Friends, result.FriendsAvailable, result.FriendsTruncated = p.steamFriendsPlaying(ctx, steamID, input.AppID)
		}()
	}
	tasks.Wait()
	p.mu.Lock()
	grant.contextLoading = false
	p.steamContextActive--
	current := p.steamCatalogGrants[digest] == grant && time.Now().Before(grant.expires)
	if current {
		grant.contextFetched = time.Now()
	}
	p.mu.Unlock()
	if !current {
		http.Error(w, "Relink Steam", http.StatusUnauthorized)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(result)
}

// Only fixed first-party endpoints are called. No upstream body, URL, token or
// error is logged or returned. Copying the client prevents redirect credentials
// from escaping even when a custom HTTP transport has been injected.
func (p *oauthProxy) steamJSON(ctx context.Context, path string, query url.Values, authenticated bool, out any) bool {
	if authenticated && p.steamWebAPIKey == "" {
		return false
	}
	if authenticated {
		query.Set("key", p.steamWebAPIKey)
	}
	target := url.URL{Scheme: "https", Host: "api.steampowered.com", Path: path, RawQuery: query.Encode()}
	request, err := http.NewRequestWithContext(ctx, http.MethodGet, target.String(), nil)
	if err != nil {
		return false
	}
	request.Header.Set("Accept", "application/json")
	client := http.Client{Timeout: oauthUpstreamTimeout}
	if p.steamClient != nil {
		client = *p.steamClient
	}
	client.CheckRedirect = func(*http.Request, []*http.Request) error { return http.ErrUseLastResponse }
	response, err := client.Do(request)
	if err != nil {
		return false
	}
	defer response.Body.Close()
	if response.StatusCode != http.StatusOK {
		return false
	}
	body, err := io.ReadAll(io.LimitReader(response.Body, maxSteamAPIResponse+1))
	return err == nil && len(body) <= maxSteamAPIResponse && json.Unmarshal(body, out) == nil
}

func steamDisplayText(value string, limit int) string {
	var out []rune
	for _, char := range value {
		if unicode.IsControl(char) || unicode.Is(unicode.Cf, char) {
			continue
		}
		out = append(out, char)
		if len(out) == limit {
			break
		}
	}
	return strings.TrimSpace(string(out))
}

func (p *oauthProxy) steamAchievements(ctx context.Context, steamID string, appID uint32) ([]steamAchievement, bool, bool) {
	var player struct {
		Stats struct {
			Success      bool   `json:"success"`
			SteamID      string `json:"steamID"`
			Achievements []struct {
				ID       string `json:"apiname"`
				Achieved int    `json:"achieved"`
				Time     int64  `json:"unlocktime"`
			} `json:"achievements"`
		} `json:"playerstats"`
	}
	q := url.Values{"steamid": {steamID}, "appid": {strconv.FormatUint(uint64(appID), 10)}, "l": {"english"}}
	if !p.steamJSON(ctx, "/ISteamUserStats/GetPlayerAchievements/v1/", q, true, &player) || !player.Stats.Success || player.Stats.SteamID != steamID {
		return nil, false, false
	}
	var schema struct {
		Game struct {
			Stats struct {
				Achievements []struct {
					ID          string `json:"name"`
					Name        string `json:"displayName"`
					Description string `json:"description"`
					Hidden      int    `json:"hidden"`
				} `json:"achievements"`
			} `json:"availableGameStats"`
		} `json:"game"`
	}
	if !p.steamJSON(ctx, "/ISteamUserStats/GetSchemaForGame/v2/", url.Values{"appid": {strconv.FormatUint(uint64(appID), 10)}, "l": {"english"}}, true, &schema) {
		return nil, false, false
	}
	byID := map[string]steamAchievement{}
	for _, row := range player.Stats.Achievements {
		if len(byID) == 1000 {
			break
		}
		if row.ID == "" || len(row.ID) > 256 {
			continue
		}
		byID[row.ID] = steamAchievement{ID: row.ID, Unlocked: row.Achieved == 1, UnlockedAt: max(0, min(row.Time, time.Now().Unix()))}
	}
	result := []steamAchievement{}
	seen := map[string]bool{}
	for _, row := range schema.Game.Stats.Achievements {
		entry, exists := byID[row.ID]
		if !exists || seen[row.ID] {
			continue
		}
		seen[row.ID] = true
		entry.Hidden = row.Hidden != 0 && !entry.Unlocked
		if entry.Hidden {
			entry.ID = ""
		}
		if !entry.Hidden {
			entry.Name = steamDisplayText(row.Name, 256)
			entry.Description = steamDisplayText(row.Description, 1024)
		}
		if !entry.Unlocked {
			entry.UnlockedAt = 0
		}
		result = append(result, entry)
	}
	return result, true, len(player.Stats.Achievements) > 1000
}

func (p *oauthProxy) steamNews(ctx context.Context, appID uint32) ([]steamNewsItem, bool) {
	var response struct {
		News struct {
			AppID uint32 `json:"appid"`
			Items []struct {
				Title string `json:"title"`
				Feed  string `json:"feedlabel"`
				Date  int64  `json:"date"`
			} `json:"newsitems"`
		} `json:"appnews"`
	}
	if !p.steamJSON(ctx, "/ISteamNews/GetNewsForApp/v2/", url.Values{"appid": {strconv.FormatUint(uint64(appID), 10)}, "count": {"10"}, "maxlength": {"1"}}, false, &response) || response.News.AppID != appID || response.News.Items == nil {
		return nil, false
	}
	result := []steamNewsItem{}
	for _, row := range response.News.Items {
		if len(result) == 10 {
			break
		}
		title := steamDisplayText(row.Title, 256)
		if title == "" || row.Date < 0 || row.Date > 253402300799 {
			continue
		}
		result = append(result, steamNewsItem{Title: title, Feed: steamDisplayText(row.Feed, 128), Date: row.Date})
	}
	return result, true
}

func (p *oauthProxy) steamFriendsPlaying(ctx context.Context, steamID string, appID uint32) ([]steamPlayingFriend, bool, bool) {
	var friends struct {
		List *struct {
			Friends []struct {
				ID string `json:"steamid"`
			} `json:"friends"`
		} `json:"friendslist"`
	}
	if !p.steamJSON(ctx, "/ISteamUser/GetFriendList/v1/", url.Values{"steamid": {steamID}, "relationship": {"friend"}}, true, &friends) || friends.List == nil {
		return nil, false, false
	}
	ids := []string{}
	allowed := map[string]bool{}
	for _, friend := range friends.List.Friends {
		if steamIDPattern.MatchString(friend.ID) && !allowed[friend.ID] {
			allowed[friend.ID] = true
			ids = append(ids, friend.ID)
		}
		if len(ids) == 100 {
			break
		}
	}
	truncated := len(friends.List.Friends) > 100
	if len(ids) == 0 {
		return []steamPlayingFriend{}, true, truncated
	}
	var summaries struct {
		Response struct {
			Players []struct {
				ID   string `json:"steamid"`
				Name string `json:"personaname"`
				Game string `json:"gameid"`
			} `json:"players"`
		} `json:"response"`
	}
	if !p.steamJSON(ctx, "/ISteamUser/GetPlayerSummaries/v2/", url.Values{"steamids": {strings.Join(ids, ",")}}, true, &summaries) || summaries.Response.Players == nil {
		return nil, false, truncated
	}
	result := []steamPlayingFriend{}
	for _, row := range summaries.Response.Players {
		if !allowed[row.ID] || row.Game != strconv.FormatUint(uint64(appID), 10) {
			continue
		}
		delete(allowed, row.ID)
		name := steamDisplayText(row.Name, 128)
		if name != "" {
			result = append(result, steamPlayingFriend{SteamID: row.ID, Name: name})
		}
	}
	return result, true, truncated
}
