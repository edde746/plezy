package main

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync/atomic"
	"testing"
)

func TestWatchmodeAvailabilityRequiresCommercialApprovalAndKey(t *testing.T) {
	t.Setenv("WATCHMODE_API_KEY", "secret")
	t.Setenv("WATCHMODE_COMMERCIAL_APPROVED", "false")
	handler := newWatchmodeAvailabilityHandler(clientIPResolver{})
	request := httptest.NewRequest(http.MethodGet, watchmodeAvailabilityPath+"?tmdbType=movie&tmdbId=278&region=CA", nil)
	request.RemoteAddr = "127.0.0.1:5000"
	recorder := httptest.NewRecorder()
	handler.serveHTTP(recorder, request)
	if recorder.Code != http.StatusServiceUnavailable {
		t.Fatalf("status = %d, want %d", recorder.Code, http.StatusServiceUnavailable)
	}
	if strings.Contains(recorder.Body.String(), "secret") {
		t.Fatal("response exposed the provider key")
	}

	t.Setenv("WATCHMODE_API_KEY", "")
	t.Setenv("WATCHMODE_COMMERCIAL_APPROVED", "true")
	handler = newWatchmodeAvailabilityHandler(clientIPResolver{})
	recorder = httptest.NewRecorder()
	handler.serveHTTP(recorder, request)
	if recorder.Code != http.StatusServiceUnavailable {
		t.Fatalf("missing-key status = %d, want %d", recorder.Code, http.StatusServiceUnavailable)
	}
}

func TestWatchmodeAvailabilityUsesExactTMDBIdRegionAndCaches(t *testing.T) {
	t.Setenv("WATCHMODE_API_KEY", "watchmode-private-key")
	t.Setenv("WATCHMODE_COMMERCIAL_APPROVED", "true")
	t.Setenv("COMIC_COMMERCE_ALLOWED_ORIGINS", "https://plezyng.example")
	var calls atomic.Int32
	upstream := httptest.NewTLSServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		calls.Add(1)
		if r.Method != http.MethodGet || r.URL.Path != "/v1/title/movie-278/sources/" {
			t.Errorf("unexpected upstream request: %s %s", r.Method, r.URL.Path)
		}
		if r.URL.Query().Get("apiKey") != "watchmode-private-key" ||
			r.URL.Query().Get("regions") != "CA" {
			t.Errorf("unexpected upstream query: %v", r.URL.Query())
		}
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(`[
			{"source_id":8,"name":"Crave","type":"sub","region":"CA","format":"web","price":null,"web_url":"https://www.crave.ca/watch/title"},
			{"source_id":9,"name":"Foreign","type":"rent","region":"US","price":"2.99","web_url":"https://example.com/title"},
			{"source_id":10,"name":"Unsafe","type":"buy","region":"CA","web_url":"javascript:alert(1)"},
			{"source_id":11,"name":"Unknown","type":"purchase","region":"CA","web_url":"https://example.com/title"}
		]`))
	}))
	defer upstream.Close()

	handler := newWatchmodeAvailabilityHandler(clientIPResolver{})
	handler.apiBase = upstream.URL
	handler.client = upstream.Client()

	makeRequest := func(origin string) *httptest.ResponseRecorder {
		request := httptest.NewRequest(http.MethodGet, watchmodeAvailabilityPath+"?tmdbType=movie&tmdbId=278&region=ca", nil)
		request.RemoteAddr = "127.0.0.1:5001"
		if origin != "" {
			request.Header.Set("Origin", origin)
		}
		recorder := httptest.NewRecorder()
		handler.serveHTTP(recorder, request)
		return recorder
	}

	first := makeRequest("https://plezyng.example")
	if first.Code != http.StatusOK {
		t.Fatalf("status = %d, body = %q", first.Code, first.Body.String())
	}
	if first.Header().Get("Access-Control-Allow-Origin") != "https://plezyng.example" ||
		first.Header().Get("Cache-Control") != "no-store" {
		t.Fatalf("unexpected response headers: %v", first.Header())
	}
	var payload watchmodeAvailabilityResponse
	if err := json.Unmarshal(first.Body.Bytes(), &payload); err != nil {
		t.Fatalf("decode response: %v", err)
	}
	if payload.TMDBType != "movie" || payload.TMDBID != 278 || payload.Region != "CA" || len(payload.Sources) != 1 {
		t.Fatalf("unexpected payload: %#v", payload)
	}
	if payload.Sources[0].Name != "Crave" || payload.Sources[0].Price != "" ||
		payload.Sources[0].WebURL != "https://www.crave.ca/watch/title" {
		t.Fatalf("unexpected source row: %#v", payload.Sources[0])
	}
	if strings.Contains(first.Body.String(), "watchmode-private-key") {
		t.Fatal("response exposed the provider key")
	}

	second := makeRequest("")
	if second.Code != http.StatusOK || calls.Load() != 1 {
		t.Fatalf("cached request status = %d, upstream calls = %d", second.Code, calls.Load())
	}
}

func TestWatchmodeAvailabilityRejectsInvalidQueryAndOrigin(t *testing.T) {
	t.Setenv("WATCHMODE_API_KEY", "secret")
	t.Setenv("WATCHMODE_COMMERCIAL_APPROVED", "true")
	t.Setenv("COMIC_COMMERCE_ALLOWED_ORIGINS", "https://plezyng.example")
	handler := newWatchmodeAvailabilityHandler(clientIPResolver{})

	for _, test := range []struct {
		name, query string
		want int
	}{
		{name: "wrong type", query: "tmdbType=episode&tmdbId=1&region=CA", want: http.StatusBadRequest},
		{name: "bad id", query: "tmdbType=movie&tmdbId=-1&region=CA", want: http.StatusBadRequest},
		{name: "bad region", query: "tmdbType=movie&tmdbId=1&region=CAN", want: http.StatusBadRequest},
	} {
		t.Run(test.name, func(t *testing.T) {
			request := httptest.NewRequest(http.MethodGet, watchmodeAvailabilityPath+"?"+test.query, nil)
			request.RemoteAddr = "127.0.0.1:5002"
			recorder := httptest.NewRecorder()
			handler.serveHTTP(recorder, request)
			if recorder.Code != test.want {
				t.Fatalf("status = %d, want %d", recorder.Code, test.want)
			}
		})
	}

	request := httptest.NewRequest(http.MethodGet, watchmodeAvailabilityPath+"?tmdbType=movie&tmdbId=1&region=CA", nil)
	request.Header.Set("Origin", "https://attacker.example")
	recorder := httptest.NewRecorder()
	handler.serveHTTP(recorder, request)
	if recorder.Code != http.StatusForbidden {
		t.Fatalf("unapproved origin status = %d", recorder.Code)
	}
}

func TestWatchmodeURLRejectsUnsafeTargets(t *testing.T) {
	for _, raw := range []string{
		"javascript:alert(1)",
		"https://user:pass@example.com/path",
		"http://example.com/path",
		"https://example.com:8443/path",
		"https://example.com/path#fragment",
	} {
		if got := watchmodeURL(raw); got != "" {
			t.Errorf("watchmodeURL(%q) = %q, want empty", raw, got)
		}
	}
	if got := watchmodeURL("https://www.crave.ca/watch/title"); got != "https://www.crave.ca/watch/title" {
		t.Fatalf("safe URL changed: %q", got)
	}
}
