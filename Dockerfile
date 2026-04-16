FROM golang:1.26-alpine AS builder

RUN apk add --no-cache git gcc musl-dev sqlite-dev

WORKDIR /app
RUN git clone --branch v2.45.1 --depth 1 https://github.com/dexidp/dex .

RUN go mod download

# Patch vulnerable deps while keeping everything else locked
RUN go get \
      github.com/go-jose/go-jose/v4@v4.1.4 \
      github.com/russellhaering/goxmldsig@v1.6.0 \
      google.golang.org/grpc@v1.79.3 && \
    go mod tidy

RUN CGO_ENABLED=1 GOFLAGS="-trimpath" go build -o /app/dex ./cmd/dex

# runtime
FROM alpine:3.23

RUN apk upgrade --no-cache && \
    apk add --no-cache \
      --repository=https://dl-cdn.alpinelinux.org/alpine/edge/main \
      'zlib=1.3.2-r0' \
      sqlite-libs && \
    adduser -D -u 1001 dex && \
    mkdir -p /var/dex && chown dex:dex /var/dex

COPY --from=builder /app/dex /usr/local/bin/dex

USER dex
ENTRYPOINT ["dex"]
