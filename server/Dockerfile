# Update the readable tag, index digest, and platforms together using the controlled process in CONTRIBUTING.md.
# Platforms: linux/amd64, linux/arm64
FROM golang:1.27.3-alpine3.23@sha256:754d5200fc3edae76d3b6598a9a3fac7e74981ee6a5413ab955025f185753ef2 AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY *.go .
RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o /relay .

FROM scratch
ARG VERSION=dev
ARG REVISION=unknown
ARG BUILD_DATE=unknown
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=build /relay /relay
LABEL org.opencontainers.image.title="PlezyNG Relay" \
      org.opencontainers.image.description="PlezyNG authentication and artifact relay service" \
      org.opencontainers.image.source="https://github.com/snapetech-org/PlezyNG" \
      org.opencontainers.image.version="$VERSION" \
      org.opencontainers.image.revision="$REVISION" \
      org.opencontainers.image.created="$BUILD_DATE" \
      org.opencontainers.image.licenses="GPL-3.0-only"
VOLUME /data
EXPOSE 8080
ENV GOMEMLIMIT=64MiB
ENTRYPOINT ["/relay"]
