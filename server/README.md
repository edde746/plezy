<h1>Plezy Relay</h1>

A backend service for Plezy. It coordinates Watch Together sessions, receives client logs, stores Discord Rich Presence artwork, and handles optional MyAnimeList and AniList sign-in flows.

## Download

Pull the image from `ghcr.io/edde746/plezy/relay-server`. It supports `amd64` and `arm64`.

## Features

### Watch Together

- WebSocket relay for synchronized playback
- Health endpoint for load balancers and deployment checks
- In-memory room coordination with persisted snapshots for restart recovery

### Client Support

- Client-log upload and retrieval
- Temporary Discord Rich Presence poster storage
- Built-in rate limits and connection limits

### Integrations

- Optional MyAnimeList OAuth with PKCE
- Optional AniList OAuth proxy
- OAuth sessions and tokens kept in memory and never written to disk

## Deployment

### Docker

Run the versioned image with persistent state:

```sh
docker run --detach \
  --name plezy-relay \
  --publish 127.0.0.1:8080:8080 \
  --volume plezy-relay-data:/data \
  ghcr.io/edde746/plezy/relay-server:<version>
```

After the container starts, check that the relay is healthy:

```sh
curl http://127.0.0.1:8080/health
```

### Docker Compose

Start the relay with Docker Compose:

```sh
cd server
docker compose up --detach relay
```

- `docker compose up --detach relay` starts only the relay.
- `docker compose up --detach` starts both the relay and Bugs.

### Configuration

| Setting | Purpose |
| --- | --- |
| `OAUTH_BASE_URL` | Public HTTPS base URL for OAuth callbacks. OAuth routes are disabled when unset. |
| `MAL_CLIENT_ID` | Enables MyAnimeList OAuth. |
| `ANILIST_CLIENT_ID` | Enables AniList OAuth. |
| `ANILIST_CLIENT_SECRET` | Required for AniList token exchange. |
| `-addr` | Listen address; default `:8080`. |
| `-log-dir` | Log directory; default `/data/logs`. |
| `-poster-dir` | Poster directory; default `/data/posters`. |
| `-state-file` | Room snapshot path; default `/data/rooms.json`. |

## Building from Source

### Prerequisites

- Go 1.22+
- Docker, for container builds

### Setup

From the repository root:

```sh
docker build --tag plezy-relay ./server
docker run --rm --publish 8080:8080 plezy-relay
```

### Code Generation

The relay protocol is shared with the Flutter app. After changing `relay_protocol.json`, regenerate both protocol implementations:

```sh
scripts/codegen.sh
```

### Local Checks

```sh
cd server
go test ./...
```

## License

Plezy Relay is licensed under [GPL-3.0](../LICENSE).

## Acknowledgments

- Built with [Go](https://go.dev)
- WebSocket support by [Gorilla WebSocket](https://github.com/gorilla/websocket)
