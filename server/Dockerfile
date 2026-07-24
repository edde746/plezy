# Update the readable tag, index digest, and platforms together using the controlled process in CONTRIBUTING.md.
# Platforms: linux/amd64, linux/arm64
FROM golang:1.26.5-alpine3.23@sha256:622e56dbc11a8cfe87cafa2331e9a201877271cbff918af53d3be315f3da88cc AS build
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
