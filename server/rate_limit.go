package main

import (
	"sync"
	"time"
)

// --- Rate limiter (token bucket) ---

type rateLimiter struct {
	tokens     float64
	maxTokens  float64
	refillRate float64
	lastTime   time.Time
	mu         sync.Mutex
}

func newRateLimiter(burst, sustained int) *rateLimiter {
	return &rateLimiter{
		tokens:     float64(burst),
		maxTokens:  float64(burst),
		refillRate: float64(sustained),
		lastTime:   time.Now(),
	}
}

func (rl *rateLimiter) allow() bool {
	rl.mu.Lock()
	defer rl.mu.Unlock()

	now := time.Now()
	elapsed := now.Sub(rl.lastTime).Seconds()
	rl.lastTime = now

	rl.tokens += elapsed * rl.refillRate
	if rl.tokens > rl.maxTokens {
		rl.tokens = rl.maxTokens
	}

	if rl.tokens < 1 {
		return false
	}
	rl.tokens--
	return true
}

// reclaimable reports whether discarding this limiter would preserve its
// behavior: enough idle time has passed for the bucket to be full again.
func (rl *rateLimiter) reclaimable(now time.Time) bool {
	rl.mu.Lock()
	defer rl.mu.Unlock()
	missingTokens := rl.maxTokens - rl.tokens
	return missingTokens <= 0 || now.Sub(rl.lastTime).Seconds()*rl.refillRate >= missingTokens
}

func cleanupRateLimiters(limiters map[string]*rateLimiter, now time.Time, inUse func(string) bool) {
	for ip, limiter := range limiters {
		if (inUse == nil || !inUse(ip)) && limiter.reclaimable(now) {
			delete(limiters, ip)
		}
	}
}

func cleanupRateWindows(windows map[string]time.Time, now time.Time, duration time.Duration) {
	for ip, startedAt := range windows {
		if now.Sub(startedAt) >= duration {
			delete(windows, ip)
		}
	}
}

// --- Connection tracker (per-IP limits) ---

type connTracker struct {
	mu          sync.Mutex
	perIP       map[string]int
	ipRate      map[string]*rateLimiter
	roomsPerIP  map[string]int
	globalCount int
}

func newConnTracker() *connTracker {
	return &connTracker{
		perIP:      make(map[string]int),
		ipRate:     make(map[string]*rateLimiter),
		roomsPerIP: make(map[string]int),
	}
}

func (ct *connTracker) tryConnect(ip string) bool {
	ct.mu.Lock()
	defer ct.mu.Unlock()

	if ct.globalCount >= maxGlobalConns {
		return false
	}
	if ct.perIP[ip] >= maxConnsPerIP {
		return false
	}

	rl, ok := ct.ipRate[ip]
	if !ok {
		rl = newRateLimiter(connRateBurst, connRateSustained)
		ct.ipRate[ip] = rl
	}
	// Unlock ct.mu before calling rl.allow() would be cleaner,
	// but since rl has its own mutex this is safe (no deadlock).
	if !rl.allow() {
		return false
	}

	ct.perIP[ip]++
	ct.globalCount++
	return true
}

func (ct *connTracker) disconnect(ip string) {
	ct.mu.Lock()
	defer ct.mu.Unlock()

	if ct.perIP[ip] > 0 {
		ct.perIP[ip]--
		ct.globalCount--
	}
	if ct.perIP[ip] == 0 {
		delete(ct.perIP, ip)
	}
}

func (ct *connTracker) tryCreateRoom(ip string) bool {
	ct.mu.Lock()
	defer ct.mu.Unlock()
	if ct.roomsPerIP[ip] >= maxRoomsPerIP {
		return false
	}
	ct.roomsPerIP[ip]++
	return true
}

func (ct *connTracker) releaseRoom(ip string) {
	ct.mu.Lock()
	defer ct.mu.Unlock()
	if ct.roomsPerIP[ip] > 0 {
		ct.roomsPerIP[ip]--
	}
	if ct.roomsPerIP[ip] == 0 {
		delete(ct.roomsPerIP, ip)
	}
}

func (ct *connTracker) cleanup(now time.Time) {
	ct.mu.Lock()
	defer ct.mu.Unlock()
	cleanupRateLimiters(ct.ipRate, now, func(ip string) bool {
		return ct.perIP[ip] > 0
	})
}
