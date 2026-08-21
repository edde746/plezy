# Update the readable tag, index digest, and platforms together using the controlled process in CONTRIBUTING.md.
# Platforms: linux/amd64, linux/arm64
FROM golang:1.26.6-alpine3.23@sha256:2afa8bf41eb4c6b113ad1601739dbf755c9d19715049ae11db2dd2715e83438f AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY *.go .
RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o /relay .

FROM scratch
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=build /relay /relay
VOLUME /data
EXPOSE 8080
ENV GOMEMLIMIT=64MiB
ENTRYPOINT ["/relay"]
