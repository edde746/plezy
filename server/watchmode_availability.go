package main

import (
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"net/url"
	"os"
	"strconv"
	"strings"
	"sync"
	"time"
	"unicode"
)

const (
	watchmodeAvailabilityPath = "/commerce/watchmode-availability"
	watchmodeMaxBodyBytes = 256 * 1024
	watchmodeMaxRows = 50
	watchmodeCacheTTL = 6 * time.Hour
	watchmodeCacheCapacity = 256
	watchmodeRateLimit = 30
	watchmodeRateWindow = time.Minute
)

type watchmodeRawSource struct {
	SourceID int `json:"source_id"`
	Name string `json:"name"`
	Type string `json:"type"`
	Region string `json:"region"`
	Format string `json:"format"`
	Price json.RawMessage `json:"price"`
	WebURL string `json:"web_url"`
	IOSURL string `json:"ios_url"`
	AndroidURL string `json:"android_url"`
	TVOSURL string `json:"tvos_url"`
	AndroidTV string `json:"android_tv_url"`
}

type watchmodeAvailabilitySource struct {
	SourceID int `json:"sourceId"`
	Name string `json:"name"`
	Type string `json:"type"`
	Region string `json:"region"`
	Format string `json:"format,omitempty"`
	Price string `json:"price,omitempty"`
	WebURL string `json:"webUrl,omitempty"`
	IOSURL string `json:"iosUrl,omitempty"`
	AndroidURL string `json:"androidUrl,omitempty"`
	TVOSURL string `json:"tvosUrl,omitempty"`
	AndroidTV string `json:"androidTvUrl,omitempty"`
}

type watchmodeAvailabilityResponse struct {
	TMDBType string `json:"tmdbType"`
	TMDBID int64 `json:"tmdbId"`
	Region string `json:"region"`
	Fetched time.Time `json:"fetchedAt"`
	Expires time.Time `json:"expiresAt"`
	Sources []watchmodeAvailabilitySource `json:"sources"`
}

type watchmodeCacheEntry struct {
	fetchedAt time.Time
	sources []watchmodeAvailabilitySource
}

type watchmodeAvailabilityHandler struct {
	clientIPs clientIPResolver
	allowedOrigins map[string]struct{}
	client *http.Client
	apiKey string
	commercialApproved bool
	now func() time.Time

	cacheMu sync.Mutex
	cache map[string]watchmodeCacheEntry
	hitsMu sync.Mutex
	hits map[string][]time.Time
}

func newWatchmodeAvailabilityHandler(clientIPs clientIPResolver) *watchmodeAvailabilityHandler {
	return &watchmodeAvailabilityHandler{
		clientIPs: clientIPs,
		allowedOrigins: parseComicCommerceOrigins(os.Getenv("COMIC_COMMERCE_ALLOWED_ORIGINS")),
		client: &http.Client{
			Timeout: 5 * time.Second,
			CheckRedirect: func(*http.Request, []*http.Request) error { return http.ErrUseLastResponse },
		},
		apiKey: strings.TrimSpace(os.Getenv("WATCHMODE_API_KEY")),
		commercialApproved: envEnabled("WATCHMODE_COMMERCIAL_APPROVED"),
		now: time.Now,
		cache: make(map[string]watchmodeCacheEntry),
		hits: make(map[string][]time.Time),
	}
}

func registerWatchmodeAvailabilityRoutes(mux *http.ServeMux, clientIPs clientIPResolver) {
	handler := newWatchmodeAvailabilityHandler(clientIPs)
	mux.HandleFunc(watchmodeAvailabilityPath, handler.serveHTTP)
}

func (h *watchmodeAvailabilityHandler) serveHTTP(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Cache-Control", "no-store")
	origin := r.Header.Get("Origin")
	if origin != "" {
		if !h.allowOrigin(origin) {
			http.Error(w, "Origin not allowed", http.StatusForbidden)
			return
		}
		w.Header().Set("Access-Control-Allow-Origin", origin)
		w.Header().Add("Vary", "Origin")
		w.Header().Set("Access-Control-Allow-Methods", "GET, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type")
	}
	if r.Method == http.MethodOptions {
		w.WriteHeader(http.StatusNoContent)
		return
	}
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	if !h.commercialApproved || h.apiKey == "" {
		http.Error(w, "Availability provider is not configured", http.StatusServiceUnavailable)
		return
	}

	ip, err := h.clientIPs.resolve(r)
	if err != nil {
		http.Error(w, "Invalid client address", http.StatusBadRequest)
		return
	}
	if !h.allowRequest(ip, h.now()) {
		http.Error(w, "Too many requests", http.StatusTooManyRequests)
		return
	}

	tmdbType := strings.ToLower(strings.TrimSpace(r.URL.Query().Get("tmdbType")))
	if tmdbType != "movie" && tmdbType != "tv" {
		http.Error(w, "Invalid media type", http.StatusBadRequest)
		return
	}
	tmdbID, err := strconv.ParseInt(r.URL.Query().Get("tmdbId"), 10, 32)
	if err != nil || tmdbID < 1 {
		http.Error(w, "Invalid TMDB id", http.StatusBadRequest)
		return
	}
	region := strings.ToUpper(strings.TrimSpace(r.URL.Query().Get("region")))
	if len(region) != 2 || region[0] < 'A' || region[0] > 'Z' || region[1] < 'A' || region[1] > 'Z' {
		http.Error(w, "Invalid region", http.StatusBadRequest)
		return
	}

	now := h.now()
	key := tmdbType + ":" + strconv.FormatInt(tmdbID, 10) + ":" + region
	if cached, ok := h.cached(key, now); ok {
		writeWatchmodeResponse(w, tmdbType, tmdbID, region, cached.fetchedAt, cached.sources)
		return
	}
	sources, err := h.fetch(r.Context(), tmdbType, tmdbID, region)
	if err != nil {
		http.Error(w, "Availability provider is unavailable", http.StatusBadGateway)
		return
	}
	fetchedAt := h.now()
	h.store(key, watchmodeCacheEntry{fetchedAt: fetchedAt, sources: sources})
	writeWatchmodeResponse(w, tmdbType, tmdbID, region, fetchedAt, sources)
}

func (h *watchmodeAvailabilityHandler) allowOrigin(value string) bool {
	candidate, err := url.Parse(value)
	if err != nil || candidate.User != nil || candidate.Path != "" || candidate.RawQuery != "" ||
		candidate.Fragment != "" || candidate.Host == "" {
		return false
	}
	if candidate.Scheme != "https" && !(candidate.Scheme == "http" && isLocalComicOrigin(candidate.Hostname())) {
		return false
	}
	normalized := strings.ToLower(candidate.Scheme) + "://" + strings.ToLower(candidate.Host)
	_, ok := h.allowedOrigins[normalized]
	return ok
}

func (h *watchmodeAvailabilityHandler) allowRequest(ip string, now time.Time) bool {
	h.hitsMu.Lock()
	defer h.hitsMu.Unlock()
	cutoff := now.Add(-watchmodeRateWindow)
	active := make([]time.Time, 0, len(h.hits[ip])+1)
	for _, hit := range h.hits[ip] {
		if hit.After(cutoff) {
			active = append(active, hit)
		}
	}
	if len(active) >= watchmodeRateLimit {
		h.hits[ip] = active
		return false
	}
	if _, exists := h.hits[ip]; !exists {
		for key, hits := range h.hits {
			if len(hits) == 0 || !hits[len(hits)-1].After(cutoff) {
				delete(h.hits, key)
			}
		}
		if len(h.hits) >= 8192 {
			return false
		}
	}
	h.hits[ip] = append(active, now)
	return true
}

func (h *watchmodeAvailabilityHandler) fetch(
	ctx context.Context,
	tmdbType string,
	tmdbID int64,
	region string,
) ([]watchmodeAvailabilitySource, error) {
	titleID := tmdbType + "-" + strconv.FormatInt(tmdbID, 10)
	apiURL := &url.URL{Scheme: "https", Host: "api.watchmode.com", Path: "/v1/title/" + titleID + "/sources/"}
	query := apiURL.Query()
	query.Set("apiKey", h.apiKey)
	query.Set("regions", region)
	apiURL.RawQuery = query.Encode()
	request, err := http.NewRequestWithContext(ctx, http.MethodGet, apiURL.String(), nil)
	if err != nil {
		return nil, err
	}
	request.Header.Set("Accept", "application/json")
	request.Header.Set("User-Agent", "PlezyNG")
	response, err := h.client.Do(request)
	if err != nil {
		return nil, err
	}
	defer response.Body.Close()
	if response.StatusCode != http.StatusOK {
		return nil, errors.New("watchmode request failed")
	}
	body, err := io.ReadAll(io.LimitReader(response.Body, watchmodeMaxBodyBytes+1))
	if err != nil || len(body) > watchmodeMaxBodyBytes {
		return nil, errors.New("watchmode response exceeded limit")
	}
	var rows []watchmodeRawSource
	if err := json.Unmarshal(body, &rows); err != nil {
		return nil, err
	}
	sources := make([]watchmodeAvailabilitySource, 0, min(len(rows), watchmodeMaxRows))
	seen := make(map[string]struct{})
	for _, row := range rows {
		kind := strings.ToLower(strings.TrimSpace(row.Type))
		switch kind {
		case "sub", "rent", "buy", "free", "tve":
		default:
			continue
		}
		name := watchmodeCleanText(row.Name, 120)
		rowRegion := strings.ToUpper(strings.TrimSpace(row.Region))
		if row.SourceID < 1 || name == "" || rowRegion != region {
			continue
		}
		format := watchmodeCleanText(row.Format, 32)
		key := strconv.Itoa(row.SourceID) + ":" + kind + ":" + rowRegion + ":" + format
		if _, duplicate := seen[key]; duplicate {
			continue
		}
		seen[key] = struct{}{}
		sources = append(sources, watchmodeAvailabilitySource{
			SourceID: row.SourceID, Name: name, Type: kind, Region: rowRegion,
			Format: format, Price: watchmodePrice(row.Price),
			WebURL: watchmodeURL(row.WebURL), IOSURL: watchmodeURL(row.IOSURL),
			AndroidURL: watchmodeURL(row.AndroidURL), TVOSURL: watchmodeURL(row.TVOSURL),
			AndroidTV: watchmodeURL(row.AndroidTV),
		})
		if len(sources) == watchmodeMaxRows {
			break
		}
	}
	return sources, nil
}

func watchmodePrice(raw json.RawMessage) string {
	if len(raw) == 0 || string(raw) == "null" {
		return ""
	}
	var value string
	if json.Unmarshal(raw, &value) == nil {
		return watchmodeCleanText(value, 32)
	}
	var number json.Number
	if decoder := json.NewDecoder(strings.NewReader(string(raw))); decoder.Decode(&number) == nil {
		return watchmodeCleanText(number.String(), 32)
	}
	return ""
}

func watchmodeCleanText(value string, maxLength int) string {
	var out strings.Builder
	for _, r := range strings.TrimSpace(value) {
		if unicode.IsControl(r) {
			continue
		}
		if out.Len() >= maxLength {
			break
		}
		out.WriteRune(r)
	}
	return strings.TrimSpace(out.String())
}

func watchmodeURL(raw string) string {
	if len(raw) == 0 || len(raw) > 2048 {
		return ""
	}
	candidate, err := url.Parse(strings.TrimSpace(raw))
	if err != nil || candidate.Scheme != "https" || candidate.Host == "" || candidate.User != nil ||
		candidate.Fragment != "" || candidate.Port() != "" {
		return ""
	}
	return candidate.String()
}

func (h *watchmodeAvailabilityHandler) cached(key string, now time.Time) (watchmodeCacheEntry, bool) {
	h.cacheMu.Lock()
	defer h.cacheMu.Unlock()
	entry, ok := h.cache[key]
	if !ok {
		return watchmodeCacheEntry{}, false
	}
	if now.Sub(entry.fetchedAt) >= watchmodeCacheTTL {
		delete(h.cache, key)
		return watchmodeCacheEntry{}, false
	}
	return entry, true
}

func (h *watchmodeAvailabilityHandler) store(key string, entry watchmodeCacheEntry) {
	h.cacheMu.Lock()
	defer h.cacheMu.Unlock()
	if len(h.cache) >= watchmodeCacheCapacity {
		oldestKey := ""
		var oldest time.Time
		for currentKey, current := range h.cache {
			if oldestKey == "" || current.fetchedAt.Before(oldest) {
				oldestKey, oldest = currentKey, current.fetchedAt
			}
		}
		if oldestKey != "" {
			delete(h.cache, oldestKey)
		}
	}
	h.cache[key] = entry
}

func writeWatchmodeResponse(
	w http.ResponseWriter,
	tmdbType string,
	tmdbID int64,
	region string,
	fetchedAt time.Time,
	sources []watchmodeAvailabilitySource,
) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	_ = json.NewEncoder(w).Encode(watchmodeAvailabilityResponse{
		TMDBType: tmdbType, TMDBID: tmdbID, Region: region,
		Fetched: fetchedAt.UTC(), Expires: fetchedAt.Add(watchmodeCacheTTL).UTC(), Sources: sources,
	})
}
