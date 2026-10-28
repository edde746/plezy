package main

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"testing"
)

func TestValidateComicDestination(t *testing.T) {
	tests := []struct {
		name     string
		provider string
		url      string
		valid    bool
	}{
		{
			name:     "approved edition search",
			provider: "ebooks-comics",
			url:      "https://www.ebooks.com/en-us/searchall?term=9780306406157",
			valid:    true,
		},
		{
			name:     "rejects external host",
			provider: "ebooks-comics",
			url:      "https://evil.example/en-us/searchall?term=9780306406157",
		},
		{
			name:     "rejects destination credentials",
			provider: "ebooks-comics",
			url:      "https://user:secret@www.ebooks.com/en-us/searchall",
		},
		{
			name:     "rejects an alternate port",
			provider: "ebooks-comics",
			url:      "https://www.ebooks.com:8443/en-us/searchall",
		},
		{
			name:     "rejects unsupported query keys",
			provider: "ebooks-comics",
			url:      "https://www.ebooks.com/en-us/searchall?term=book&access_token=secret",
		},
		{
			name:     "rejects duplicate search parameters",
			provider: "ebooks-comics",
			url:      "https://www.ebooks.com/en-us/searchall?term=book&term=other",
		},
		{
			name:     "rejects unregistered provider",
			provider: "unknown-provider",
			url:      "https://www.ebooks.com/en-us/searchall",
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			destination, err := validateComicDestination(test.provider, test.url)
			if test.valid {
				if err != nil {
					t.Fatalf("validateComicDestination() error = %v", err)
				}
				if destination.Host != "www.ebooks.com" {
					t.Fatalf("destination host = %q", destination.Host)
				}
				return
			}
			if err == nil {
				t.Fatalf("validateComicDestination(%q) unexpectedly succeeded", test.url)
			}
		})
	}
}

func TestComicCommerceHandlerApprovalAndOriginGates(t *testing.T) {
	t.Setenv("COMIC_COMMERCE_ALLOWED_ORIGINS", "https://plezyng.app")
	t.Setenv("EBOOKS_COM_AFFILIATE_ID", "123")
	t.Setenv("EBOOKS_COM_AFFILIATE_APPROVED", "true")
	handler := newComicCommerceHandler(clientIPResolver{})

	requestBody := `{"providerId":"ebooks-comics","destinationUrl":"https://www.ebooks.com/en-us/searchall?term=9780306406157","isbn":"9780306406157"}`
	request := httptest.NewRequest(http.MethodPost, comicCommercePath, strings.NewReader(requestBody))
	request.RemoteAddr = "127.0.0.1:5123"
	request.Header.Set("Content-Type", "application/json")
	request.Header.Set("Origin", "https://plezyng.app")
	recorder := httptest.NewRecorder()
	handler.serveHTTP(recorder, request)
	if recorder.Code != http.StatusOK {
		t.Fatalf("status = %d, body = %q", recorder.Code, recorder.Body.String())
	}
	if recorder.Header().Get("Cache-Control") != "no-store" {
		t.Fatalf("Cache-Control = %q", recorder.Header().Get("Cache-Control"))
	}
	if recorder.Header().Get("Access-Control-Allow-Origin") != "https://plezyng.app" {
		t.Fatalf("CORS origin = %q", recorder.Header().Get("Access-Control-Allow-Origin"))
	}
	var response comicCommerceResponse
	if err := json.Unmarshal(recorder.Body.Bytes(), &response); err != nil {
		t.Fatalf("decode response: %v", err)
	}
	if !response.Tracked {
		t.Fatalf("expected approved storefront handoff to be tracked: %#v", response)
	}
	tracked, err := url.Parse(response.URL)
	if err != nil || tracked.Host != "www.ebooks.com" || tracked.Path != "/aff.asp" || tracked.Query().Get("AID") != "123" {
		t.Fatalf("unexpected tracked handoff URL: %q (error %v)", response.URL, err)
	}

	badOrigin := httptest.NewRequest(http.MethodPost, comicCommercePath, strings.NewReader(requestBody))
	badOrigin.RemoteAddr = "127.0.0.1:5123"
	badOrigin.Header.Set("Content-Type", "application/json")
	badOrigin.Header.Set("Origin", "https://attacker.example")
	badRecorder := httptest.NewRecorder()
	handler.serveHTTP(badRecorder, badOrigin)
	if badRecorder.Code != http.StatusForbidden {
		t.Fatalf("unapproved Origin status = %d", badRecorder.Code)
	}
}

func TestComicCommerceHandlerLeavesUnapprovedHandoffDirect(t *testing.T) {
	t.Setenv("EBOOKS_COM_AFFILIATE_ID", "123")
	t.Setenv("EBOOKS_COM_AFFILIATE_APPROVED", "false")
	handler := newComicCommerceHandler(clientIPResolver{})
	request := httptest.NewRequest(
		http.MethodPost,
		comicCommercePath,
		strings.NewReader(`{"providerId":"ebooks-comics","destinationUrl":"https://www.ebooks.com/en-us/searchall?term=9780306406157"}`),
	)
	request.RemoteAddr = "127.0.0.1:5124"
	request.Header.Set("Content-Type", "application/json")
	recorder := httptest.NewRecorder()
	handler.serveHTTP(recorder, request)
	if recorder.Code != http.StatusOK {
		t.Fatalf("status = %d, body = %q", recorder.Code, recorder.Body.String())
	}
	var response comicCommerceResponse
	if err := json.Unmarshal(recorder.Body.Bytes(), &response); err != nil {
		t.Fatalf("decode response: %v", err)
	}
	if response.Tracked || response.URL != "https://www.ebooks.com/en-us/searchall?term=9780306406157" {
		t.Fatalf("unapproved affiliate configuration changed direct handoff: %#v", response)
	}
}
