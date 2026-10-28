package main

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"io"
	"mime"
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
	comicCommercePath            = "/commerce/comic-link"
	comicCommerceRequestMaxBytes = 12 * 1024
	comicCommerceResponseMax     = 16 * 1024
	comicCommerceRateWindow      = time.Minute
	comicCommerceRateLimit       = 30
)

type comicCommerceRequest struct {
	ProviderID     string `json:"providerId"`
	DestinationURL string `json:"destinationUrl"`
	ISBN           string `json:"isbn"`
}

type comicCommerceResponse struct {
	URL     string `json:"url"`
	Tracked bool   `json:"tracked"`
}

type comicCommerceHandler struct {
	clientIPs       clientIPResolver
	allowedOrigins  map[string]struct{}
	limiter         *comicCommerceRateLimiter
	client          *http.Client
	drivethruID     string
	drivethruReady  bool
	awinPublisherID string
	awinToken       string
	fanaticalID     string
	fanaticalReady      bool
	fanaticalGamesReady bool
	flexAPIKey      string
	flexHeader      string
	flexPrefix      string
	rentaID         string
	rentaReady      bool
	humbleID        string
	humbleReady     bool
	ebooksID        string
	ebooksReady     bool
	bookshopID      string
	bookshopReady   bool
	koboID          string
	koboToken       string
	koboReady       bool
	gumroadURL         string
	gumroadReady       bool
	gumroadCreatorLinks map[string]string
}

type comicCommerceRateLimiter struct {
	mu   sync.Mutex
	hits map[string][]time.Time
}

func newComicCommerceRateLimiter() *comicCommerceRateLimiter {
	return &comicCommerceRateLimiter{hits: make(map[string][]time.Time)}
}

func (l *comicCommerceRateLimiter) allow(ip string, now time.Time) bool {
	l.mu.Lock()
	defer l.mu.Unlock()

	cutoff := now.Add(-comicCommerceRateWindow)
	active := make([]time.Time, 0, len(l.hits[ip])+1)
	for _, hit := range l.hits[ip] {
		if hit.After(cutoff) {
			active = append(active, hit)
		}
	}
	if len(active) >= comicCommerceRateLimit {
		l.hits[ip] = active
		return false
	}
	if _, exists := l.hits[ip]; !exists {
		for key, hits := range l.hits {
			if len(hits) == 0 || !hits[len(hits)-1].After(cutoff) {
				delete(l.hits, key)
			}
		}
		if len(l.hits) >= 8192 {
			return false
		}
	}
	active = append(active, now)
	l.hits[ip] = active
	return true
}

func newComicCommerceHandler(clientIPs clientIPResolver) *comicCommerceHandler {
	header := strings.TrimSpace(os.Getenv("FLEXOFFERS_API_KEY_HEADER"))
	if header == "" {
		header = "Authorization"
	}
	return &comicCommerceHandler{
		clientIPs:       clientIPs,
		allowedOrigins:  parseComicCommerceOrigins(os.Getenv("COMIC_COMMERCE_ALLOWED_ORIGINS")),
		limiter:         newComicCommerceRateLimiter(),
		client: &http.Client{
			Timeout: 5 * time.Second,
			CheckRedirect: func(*http.Request, []*http.Request) error {
				return http.ErrUseLastResponse
			},
		},
		drivethruID:     strings.TrimSpace(os.Getenv("DRIVETHRU_COMICS_AFFILIATE_ID")),
		drivethruReady:  envEnabled("DRIVETHRU_COMICS_AFFILIATE_APPROVED"),
		awinPublisherID: strings.TrimSpace(os.Getenv("AWIN_PUBLISHER_ID")),
		awinToken:       strings.TrimSpace(os.Getenv("AWIN_API_TOKEN")),
		fanaticalID:     strings.TrimSpace(os.Getenv("FANATICAL_AWIN_ADVERTISER_ID")),
		fanaticalReady:      envEnabled("FANATICAL_AWIN_APPROVED"),
		fanaticalGamesReady: envEnabled("FANATICAL_GAMES_AWIN_APPROVED"),
		flexAPIKey:      strings.TrimSpace(os.Getenv("FLEXOFFERS_API_KEY")),
		flexHeader:      header,
		flexPrefix:      os.Getenv("FLEXOFFERS_API_KEY_PREFIX"),
		rentaID:         strings.TrimSpace(os.Getenv("RENTA_FLEXOFFERS_ADVERTISER_ID")),
		rentaReady:      envEnabled("RENTA_FLEXOFFERS_APPROVED"),
		humbleID:        strings.TrimSpace(os.Getenv("HUMBLE_FLEXOFFERS_ADVERTISER_ID")),
		humbleReady:     envEnabled("HUMBLE_FLEXOFFERS_APPROVED"),
		ebooksID:        strings.TrimSpace(os.Getenv("EBOOKS_COM_AFFILIATE_ID")),
		ebooksReady:     envEnabled("EBOOKS_COM_AFFILIATE_APPROVED"),
		bookshopID:      strings.TrimSpace(os.Getenv("BOOKSHOP_AFFILIATE_ID")),
		bookshopReady:   envEnabled("BOOKSHOP_AFFILIATE_APPROVED"),
		koboID:          strings.TrimSpace(os.Getenv("KOBO_RAKUTEN_ADVERTISER_ID")),
		koboToken:       strings.TrimSpace(os.Getenv("KOBO_RAKUTEN_API_TOKEN")),
		koboReady:       envEnabled("KOBO_RAKUTEN_APPROVED"),
		gumroadURL:          strings.TrimSpace(os.Getenv("GUMROAD_DISCOVER_AFFILIATE_URL")),
		gumroadReady:        envEnabled("GUMROAD_AFFILIATE_APPROVED"),
		gumroadCreatorLinks: parseGumroadCreatorLinks(os.Getenv("GUMROAD_CREATOR_LINKS_JSON")),
	}
}

func registerComicCommerceRoutes(mux *http.ServeMux, clientIPs clientIPResolver) {
	handler := newComicCommerceHandler(clientIPs)
	mux.HandleFunc(comicCommercePath, handler.serveHTTP)
}

func (h *comicCommerceHandler) serveHTTP(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Cache-Control", "no-store")
	origin := r.Header.Get("Origin")
	if origin != "" {
		if !h.allowOrigin(origin) {
			http.Error(w, "Origin not allowed", http.StatusForbidden)
			return
		}
		w.Header().Set("Access-Control-Allow-Origin", origin)
		w.Header().Add("Vary", "Origin")
		w.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type")
	}
	if r.Method == http.MethodOptions {
		w.WriteHeader(http.StatusNoContent)
		return
	}
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	ip, err := h.clientIPs.resolve(r)
	if err != nil {
		http.Error(w, "Invalid client address", http.StatusBadRequest)
		return
	}
	if !h.limiter.allow(ip, time.Now()) {
		http.Error(w, "Too many requests", http.StatusTooManyRequests)
		return
	}
	mediaType, _, err := mime.ParseMediaType(r.Header.Get("Content-Type"))
	if err != nil || mediaType != "application/json" {
		http.Error(w, "Expected JSON", http.StatusUnsupportedMediaType)
		return
	}

	r.Body = http.MaxBytesReader(w, r.Body, comicCommerceRequestMaxBytes)
	decoder := json.NewDecoder(r.Body)
	decoder.DisallowUnknownFields()
	var input comicCommerceRequest
	if err := decoder.Decode(&input); err != nil {
		http.Error(w, "Invalid request", http.StatusBadRequest)
		return
	}
	var trailing any
	if err := decoder.Decode(&trailing); !errors.Is(err, io.EOF) {
		http.Error(w, "Invalid request", http.StatusBadRequest)
		return
	}

	destination, err := validateComicDestination(input.ProviderID, input.DestinationURL)
	if err != nil {
		http.Error(w, "Invalid destination", http.StatusBadRequest)
		return
	}
	input.ISBN = normalizeISBN(input.ISBN)
	if !validISBN(input.ISBN) {
		input.ISBN = ""
	}

	resolved, tracked := h.resolve(r.Context(), input, destination)
	writeComicCommerceResponse(w, resolved, tracked)
}

func (h *comicCommerceHandler) allowOrigin(value string) bool {
	parsed, err := url.Parse(value)
	if err != nil || parsed.User != nil || parsed.Path != "" || parsed.RawQuery != "" || parsed.Fragment != "" || parsed.Host == "" {
		return false
	}
	if parsed.Scheme != "https" && !(parsed.Scheme == "http" && isLocalComicOrigin(parsed.Hostname())) {
		return false
	}
	normalized := strings.ToLower(parsed.Scheme) + "://" + strings.ToLower(parsed.Host)
	_, ok := h.allowedOrigins[normalized]
	return ok
}

func isLocalComicOrigin(host string) bool {
	host = strings.ToLower(host)
	return host == "localhost" || host == "127.0.0.1" || host == "::1"
}

func parseComicCommerceOrigins(raw string) map[string]struct{} {
	origins := make(map[string]struct{})
	for _, item := range strings.Split(raw, ",") {
		item = strings.TrimSpace(item)
		if item == "" {
			continue
		}
		parsed, err := url.Parse(item)
		if err != nil || parsed.User != nil || parsed.Host == "" ||
			(parsed.Path != "" && parsed.Path != "/") || parsed.RawQuery != "" || parsed.Fragment != "" {
			continue
		}
		if parsed.Scheme != "https" && !(parsed.Scheme == "http" && isLocalComicOrigin(parsed.Hostname())) {
			continue
		}
		origins[strings.ToLower(parsed.Scheme)+"://"+strings.ToLower(parsed.Host)] = struct{}{}
	}
	return origins
}

func writeComicCommerceResponse(w http.ResponseWriter, target string, tracked bool) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(http.StatusOK)
	_ = json.NewEncoder(w).Encode(comicCommerceResponse{URL: target, Tracked: tracked})
}

func (h *comicCommerceHandler) resolve(ctx context.Context, input comicCommerceRequest, destination *url.URL) (string, bool) {
	switch input.ProviderID {
	case "drivethru-comics":
		if h.drivethruReady && isPositiveInteger(h.drivethruID) {
			query := destination.Query()
			query.Set("affiliate_id", h.drivethruID)
			destination.RawQuery = query.Encode()
			return destination.String(), true
		}
	case "fanatical-comics", "fanatical-games":
		approved := h.fanaticalReady
		if input.ProviderID == "fanatical-games" {
			approved = h.fanaticalGamesReady
		}
		if approved && isPositiveInteger(h.awinPublisherID) && isPositiveInteger(h.fanaticalID) && h.awinToken != "" && !strings.ContainsAny(h.awinToken, "\r\n") {
			if target, ok := h.makeAwinLink(ctx, h.fanaticalID, destination); ok {
				return target, true
			}
		}
	case "renta-comics":
		if h.rentaReady && isPositiveInteger(h.rentaID) && h.flexAPIKey != "" {
			if target, ok := h.makeFlexOffersLink(ctx, h.rentaID, destination); ok {
				return target, true
			}
		}
	case "humble-comics":
		if h.humbleReady && isPositiveInteger(h.humbleID) && h.flexAPIKey != "" {
			if target, ok := h.makeFlexOffersLink(ctx, h.humbleID, destination); ok {
				return target, true
			}
		}
	case "ebooks-comics":
		if h.ebooksReady && isPositiveInteger(h.ebooksID) && input.ISBN != "" {
			affiliate := &url.URL{Scheme: "https", Host: "www.ebooks.com", Path: "/aff.asp"}
			query := url.Values{}
			query.Set("AID", h.ebooksID)
			query.Set("term", input.ISBN)
			affiliate.RawQuery = query.Encode()
			return affiliate.String(), true
		}
	case "bookshop-comics":
		if h.bookshopReady && isPositiveInteger(h.bookshopID) {
			if isbn := toISBN13(input.ISBN); isbn != "" {
				affiliate := &url.URL{Scheme: "https", Host: "bookshop.org", Path: "/a/" + h.bookshopID + "/" + isbn}
				return affiliate.String(), true
			}
		}
	case "kobo-comics":
		if h.koboReady && isPositiveInteger(h.koboID) && h.koboToken != "" && !strings.ContainsAny(h.koboToken, "\r\n") {
			if target, ok := h.makeRakutenLink(ctx, destination); ok {
				return target, true
			}
		}
	case "gumroad-comics":
		if h.gumroadReady {
			if target, ok := h.makeGumroadLink(destination); ok {
				return target, true
			}
		}
	}
	return destination.String(), false
}

func (h *comicCommerceHandler) makeRakutenLink(ctx context.Context, destination *url.URL) (string, bool) {
	apiURL := &url.URL{Scheme: "https", Host: "api.linksynergy.com", Path: "/v1/links/deep_links"}
	payload := struct {
		URL          string `json:"url"`
		AdvertiserID int64  `json:"advertiser_id"`
		U1           string `json:"u1"`
		Name         string `json:"name"`
	}{
		URL:          destination.String(),
		AdvertiserID: mustParseInt64(h.koboID),
		U1:           "plezyng_comics",
		Name:         "PlezyNG comic storefront",
	}
	body, err := json.Marshal(payload)
	if err != nil {
		return "", false
	}
	request, err := http.NewRequestWithContext(ctx, http.MethodPost, apiURL.String(), bytes.NewReader(body))
	if err != nil {
		return "", false
	}
	request.Header.Set("Authorization", "Bearer "+h.koboToken)
	request.Header.Set("Content-Type", "application/json")
	request.Header.Set("Accept", "application/json")
	response, err := h.client.Do(request)
	if err != nil {
		return "", false
	}
	defer response.Body.Close()
	if response.StatusCode != http.StatusOK {
		return "", false
	}
	data, err := io.ReadAll(io.LimitReader(response.Body, comicCommerceResponseMax+1))
	if err != nil || len(data) > comicCommerceResponseMax {
		return "", false
	}
	var result struct {
		Advertiser struct {
			DeepLink struct {
				URL string `json:"deep_link_url"`
			} `json:"deep_link"`
		} `json:"advertiser"`
	}
	if json.Unmarshal(data, &result) != nil {
		return "", false
	}
	target, err := url.Parse(result.Advertiser.DeepLink.URL)
	if err != nil || !isApprovedTrackingURL(target, map[string]struct{}{"click.linksynergy.com": {}}) {
		return "", false
	}
	return target.String(), true
}

func (h *comicCommerceHandler) makeAwinLink(ctx context.Context, advertiserID string, destination *url.URL) (string, bool) {
	publisherID, err := strconv.ParseInt(h.awinPublisherID, 10, 64)
	if err != nil || publisherID < 1 {
		return "", false
	}
	apiURL := &url.URL{
		Scheme: "https",
		Host:   "api.awin.com",
		Path:   "/publishers/" + h.awinPublisherID + "/linkbuilder/generate",
	}
	query := url.Values{}
	query.Set("accessToken", h.awinToken)
	apiURL.RawQuery = query.Encode()
	payload := map[string]any{
		"advertiserId":   mustParseInt64(advertiserID),
		"destinationUrl": destination.String(),
	}
	body, err := json.Marshal(payload)
	if err != nil {
		return "", false
	}
	request, err := http.NewRequestWithContext(ctx, http.MethodPost, apiURL.String(), bytes.NewReader(body))
	if err != nil {
		return "", false
	}
	request.Header.Set("Authorization", "Bearer "+h.awinToken)
	request.Header.Set("Content-Type", "application/json")
	response, err := h.client.Do(request)
	if err != nil {
		return "", false
	}
	defer response.Body.Close()
	if response.StatusCode != http.StatusOK {
		return "", false
	}
	data, err := io.ReadAll(io.LimitReader(response.Body, comicCommerceResponseMax+1))
	if err != nil || len(data) > comicCommerceResponseMax {
		return "", false
	}
	var result struct {
		URL string `json:"url"`
	}
	if json.Unmarshal(data, &result) != nil {
		return "", false
	}
	target, err := url.Parse(result.URL)
	if err != nil || !isApprovedTrackingURL(target, map[string]struct{}{"awin1.com": {}, "www.awin1.com": {}}) {
		return "", false
	}
	return target.String(), true
}

func (h *comicCommerceHandler) makeFlexOffersLink(ctx context.Context, advertiserID string, destination *url.URL) (string, bool) {
	apiURL := &url.URL{Scheme: "https", Host: "api.flexoffers.com", Path: "/deeplink"}
	query := url.Values{}
	query.Set("AdvertiserId", advertiserID)
	query.Set("URL", destination.String())
	query.Set("fobs", "plezyng_comics")
	apiURL.RawQuery = query.Encode()
	request, err := http.NewRequestWithContext(ctx, http.MethodGet, apiURL.String(), nil)
	if err != nil {
		return "", false
	}
	if h.flexHeader != "" && h.flexAPIKey != "" {
		if http.CanonicalHeaderKey(h.flexHeader) == "" || strings.ContainsAny(h.flexPrefix+h.flexAPIKey, "\r\n") {
			return "", false
		}
		request.Header.Set(h.flexHeader, h.flexPrefix+h.flexAPIKey)
	}
	response, err := h.client.Do(request)
	if err != nil {
		return "", false
	}
	defer response.Body.Close()
	if response.StatusCode != http.StatusOK {
		return "", false
	}
	data, err := io.ReadAll(io.LimitReader(response.Body, comicCommerceResponseMax+1))
	if err != nil || len(data) > comicCommerceResponseMax {
		return "", false
	}
	var result struct {
		DeepLink string `json:"deeplink"`
	}
	if json.Unmarshal(data, &result) != nil {
		return "", false
	}
	target, err := url.Parse(result.DeepLink)
	if err != nil || !isApprovedTrackingURL(target, map[string]struct{}{
		"track.flexlinkspro.com": {},
		"track.flexlinks.com":    {},
	}) {
		return "", false
	}
	return target.String(), true
}

func (h *comicCommerceHandler) makeGumroadLink(destination *url.URL) (string, bool) {
	query := destination.Query().Get("query")
	if exact, ok := h.gumroadCreatorLinks[normalizeComicLinkKey(query)]; ok && query != "" {
		return exact, true
	}
	affiliate, err := url.Parse(h.gumroadURL)
	if err != nil || affiliate.Scheme != "https" || affiliate.User != nil ||
		(affiliate.Host != "gumroad.com" && affiliate.Host != "www.gumroad.com") ||
		affiliate.Path != "/discover" || affiliate.Fragment != "" || affiliate.Port() != "" {
		return "", false
	}
	if query != "" {
		params := affiliate.Query()
		params.Set("query", query)
		affiliate.RawQuery = params.Encode()
	}
	return affiliate.String(), true
}

func parseGumroadCreatorLinks(raw string) map[string]string {
	links := make(map[string]string)
	if len(raw) == 0 || len(raw) > 256*1024 {
		return links
	}
	var configured map[string]string
	if json.Unmarshal([]byte(raw), &configured) != nil {
		return links
	}
	for key, value := range configured {
		normalizedKey := normalizeComicLinkKey(key)
		target, err := url.Parse(strings.TrimSpace(value))
		if normalizedKey == "" || err != nil || !validGumroadAffiliateURL(target) {
			continue
		}
		links[normalizedKey] = target.String()
	}
	return links
}

func normalizeComicLinkKey(value string) string {
	var normalized strings.Builder
	pendingSpace := false
	for _, character := range strings.ToLower(value) {
		if unicode.IsLetter(character) || unicode.IsDigit(character) {
			if pendingSpace && normalized.Len() > 0 {
				normalized.WriteByte(' ')
			}
			normalized.WriteRune(character)
			pendingSpace = false
		} else if normalized.Len() > 0 {
			pendingSpace = true
		}
	}
	return strings.TrimSpace(normalized.String())
}

func validGumroadAffiliateURL(target *url.URL) bool {
	if target == nil || target.Scheme != "https" || target.User != nil ||
		target.Fragment != "" || target.Host == "" || target.Port() != "" {
		return false
	}
	host := strings.ToLower(target.Hostname())
	if host != "gumroad.com" && host != "www.gumroad.com" && !strings.HasSuffix(host, ".gumroad.com") {
		return false
	}
	return strings.HasPrefix(target.Path, "/a/") || strings.HasPrefix(target.Path, "/l/")
}

func isApprovedTrackingURL(candidate *url.URL, hosts map[string]struct{}) bool {
	if candidate == nil || candidate.Scheme != "https" || candidate.User != nil ||
		candidate.Fragment != "" || candidate.Host == "" || candidate.Port() != "" {
		return false
	}
	_, ok := hosts[strings.ToLower(candidate.Hostname())]
	return ok
}

func validateComicDestination(providerID, raw string) (*url.URL, error) {
	if len(raw) == 0 || len(raw) > 4096 {
		return nil, errors.New("bad url size")
	}
	candidate, err := url.Parse(raw)
	if err != nil || candidate.Scheme != "https" || candidate.User != nil ||
		candidate.Fragment != "" || candidate.Opaque != "" || candidate.Port() != "" {
		return nil, errors.New("bad url")
	}
	spec := map[string]struct {
		hosts map[string]struct{}
		path  string
		keys  map[string]struct{}
	}{
		"drivethru-comics": {hosts: map[string]struct{}{"www.drivethrucomics.com": {}}, path: "/en/browse", keys: map[string]struct{}{}},
		"fanatical-comics": {hosts: map[string]struct{}{"www.fanatical.com": {}}, path: "/en/search", keys: map[string]struct{}{"search": {}}},
		"fanatical-games":  {hosts: map[string]struct{}{"www.fanatical.com": {}}, path: "/en/search", keys: map[string]struct{}{"search": {}}},
		"renta-comics":     {hosts: map[string]struct{}{"www.ebookrenta.com": {}}, path: "/renta/sc/frm/", keys: map[string]struct{}{}},
		"ebooks-comics":    {hosts: map[string]struct{}{"www.ebooks.com": {}}, path: "/en-us/searchall", keys: map[string]struct{}{"term": {}}},
		"bookshop-comics":  {hosts: map[string]struct{}{"bookshop.org": {}}, path: "/search", keys: map[string]struct{}{"keywords": {}}},
		"kobo-comics":      {hosts: map[string]struct{}{"www.kobo.com": {}}, path: "/search", keys: map[string]struct{}{"query": {}}},
		"humble-comics":    {hosts: map[string]struct{}{"www.humblebundle.com": {}}, path: "/books", keys: map[string]struct{}{}},
		"gumroad-comics":   {hosts: map[string]struct{}{"gumroad.com": {}, "www.gumroad.com": {}}, path: "/discover", keys: map[string]struct{}{"query": {}}},
	}
	allowed, ok := spec[providerID]
	if !ok || candidate.Host != candidate.Hostname() || candidate.Host != strings.ToLower(candidate.Host) {
		return nil, errors.New("unknown provider")
	}
	if _, ok := allowed.hosts[candidate.Host]; !ok {
		return nil, errors.New("host not allowed")
	}
	pathOK := candidate.Path == allowed.path
	if providerID == "ebooks-comics" && len(candidate.Path) == len("/en-us/searchall") &&
		strings.HasPrefix(candidate.Path, "/en-") && strings.HasSuffix(candidate.Path, "/searchall") {
		pathOK = true
	}
	if !pathOK {
		return nil, errors.New("path not allowed")
	}
	query := candidate.Query()
	for key, values := range query {
		if _, ok := allowed.keys[key]; !ok || len(values) != 1 || len(values[0]) > 300 ||
			strings.ContainsAny(values[0], "\x00\r\n") {
			return nil, errors.New("query not allowed")
		}
	}
	candidate.RawQuery = query.Encode()
	return candidate, nil
}

func normalizeISBN(value string) string {
	value = strings.ToUpper(strings.TrimSpace(value))
	return strings.NewReplacer("-", "", " ", "").Replace(value)
}

func toISBN13(value string) string {
	value = normalizeISBN(value)
	if len(value) == 13 && validISBN(value) {
		return value
	}
	if len(value) != 10 || !validISBN(value) {
		return ""
	}
	base := "978" + value[:9]
	sum := 0
	for index := 0; index < len(base); index++ {
		digit := int(base[index] - '0')
		if index%2 == 0 {
			sum += digit
		} else {
			sum += 3 * digit
		}
	}
	return base + string(rune('0'+(10-sum%10)%10))
}

func validISBN(value string) bool {
	value = strings.ToUpper(strings.TrimSpace(value))
	if len(value) == 13 {
		sum := 0
		for index := 0; index < 13; index++ {
			if value[index] < '0' || value[index] > '9' {
				return false
			}
			digit := int(value[index] - '0')
			if index%2 == 0 {
				sum += digit
			} else {
				sum += 3 * digit
			}
		}
		return sum%10 == 0 && (strings.HasPrefix(value, "978") || strings.HasPrefix(value, "979"))
	}
	if len(value) == 10 {
		sum := 0
		for index := 0; index < 10; index++ {
			digit := 0
			if value[index] == 'X' && index == 9 {
				digit = 10
			} else if value[index] >= '0' && value[index] <= '9' {
				digit = int(value[index] - '0')
			} else {
				return false
			}
			sum += (10 - index) * digit
		}
		return sum%11 == 0
	}
	return false
}

func isDigits(value string) bool {
	if value == "" {
		return false
	}
	for _, r := range value {
		if r < '0' || r > '9' {
			return false
		}
	}
	return true
}

func isPositiveInteger(value string) bool {
	if !isDigits(value) {
		return false
	}
	number, err := strconv.ParseInt(value, 10, 64)
	return err == nil && number > 0
}

func mustParseInt64(value string) int64 {
	number, _ := strconv.ParseInt(value, 10, 64)
	return number
}

func envEnabled(name string) bool {
	return strings.EqualFold(strings.TrimSpace(os.Getenv(name)), "true")
}
