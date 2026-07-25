package main

import (
	"errors"
	"net"
	"net/http"
	"net/netip"
	"strings"
)

var errInvalidClientAddress = errors.New("invalid client address")

const (
	maxForwardedForBytes = 4 * 1024
	maxForwardedForHops  = 32
)

type clientIPResolver struct {
	trustedProxies []netip.Prefix
}

func newClientIPResolver(trustedProxies []netip.Prefix) clientIPResolver {
	return clientIPResolver{trustedProxies: append([]netip.Prefix(nil), trustedProxies...)}
}

func parseTrustedProxyCIDRs(value string) ([]netip.Prefix, error) {
	if strings.TrimSpace(value) == "" {
		return nil, nil
	}

	parts := strings.Split(value, ",")
	prefixes := make([]netip.Prefix, 0, len(parts))
	for _, part := range parts {
		part = strings.TrimSpace(part)
		if part == "" {
			return nil, errInvalidClientAddress
		}
		prefix, err := netip.ParsePrefix(part)
		if err != nil {
			return nil, errInvalidClientAddress
		}
		if prefix.Addr().Is4In6() {
			if prefix.Bits() < 96 {
				return nil, errInvalidClientAddress
			}
			prefix = netip.PrefixFrom(prefix.Addr().Unmap(), prefix.Bits()-96)
		}
		prefixes = append(prefixes, prefix.Masked())
	}
	return prefixes, nil
}

func (r clientIPResolver) resolve(req *http.Request) (string, error) {
	peer, err := parseRemoteAddress(req.RemoteAddr)
	if err != nil {
		return "", errInvalidClientAddress
	}
	peer = peer.Unmap()

	if !r.trusted(peer) {
		return normalizeClientAddress(peer), nil
	}

	values := req.Header.Values("X-Forwarded-For")
	totalBytes := 0
	hopCount := 0
	for _, value := range values {
		totalBytes += len(value)
		if totalBytes > maxForwardedForBytes {
			return "", errInvalidClientAddress
		}
		hopCount += strings.Count(value, ",") + 1
		if hopCount > maxForwardedForHops {
			return "", errInvalidClientAddress
		}
	}
	if len(values) == 0 {
		return normalizeClientAddress(peer), nil
	}

	selected := peer
	useForwardedHop := true
	for valueIndex := len(values) - 1; valueIndex >= 0; valueIndex-- {
		value := values[valueIndex]
		end := len(value)
		for {
			separator := strings.LastIndexByte(value[:end], ',')
			element := strings.TrimSpace(value[separator+1 : end])
			if element == "" {
				return "", errInvalidClientAddress
			}
			addr, parseErr := netip.ParseAddr(element)
			if parseErr != nil || addr.Zone() != "" {
				return "", errInvalidClientAddress
			}
			if useForwardedHop {
				if r.trusted(selected) {
					selected = addr.Unmap()
				} else {
					useForwardedHop = false
				}
			}
			if separator < 0 {
				break
			}
			end = separator
		}
	}
	return normalizeClientAddress(selected), nil
}

func (r clientIPResolver) trusted(addr netip.Addr) bool {
	addr = addr.Unmap()
	for _, prefix := range r.trustedProxies {
		if prefix.Contains(addr) {
			return true
		}
	}
	return false
}

func parseRemoteAddress(remote string) (netip.Addr, error) {
	host, _, err := net.SplitHostPort(remote)
	if err == nil {
		addr, parseErr := netip.ParseAddr(host)
		if parseErr != nil || addr.Zone() != "" {
			return netip.Addr{}, errInvalidClientAddress
		}
		return addr, nil
	}
	addr, parseErr := netip.ParseAddr(remote)
	if parseErr != nil || addr.Zone() != "" {
		return netip.Addr{}, errInvalidClientAddress
	}
	return addr, nil
}

func normalizeClientAddress(addr netip.Addr) string {
	addr = addr.Unmap()
	if addr.Is6() {
		return netip.PrefixFrom(addr, 64).Masked().Addr().String()
	}
	return addr.String()
}
