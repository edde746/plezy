package main

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestCheckHealth(t *testing.T) {
	for _, test := range []struct {
		name   string
		status int
		valid  bool
	}{
		{name: "healthy", status: http.StatusOK, valid: true},
		{name: "unhealthy", status: http.StatusServiceUnavailable},
	} {
		t.Run(test.name, func(t *testing.T) {
			server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
				w.WriteHeader(test.status)
			}))
			defer server.Close()

			err := checkHealth(context.Background(), server.Client(), server.URL)
			if (err == nil) != test.valid {
				t.Fatalf("checkHealth() err=%v, valid=%v", err, test.valid)
			}
		})
	}
}
