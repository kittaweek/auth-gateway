FROM golang:1.26-alpine AS builder

RUN apk add --no-cache git

WORKDIR /app
RUN git clone --branch v2.45.1 --depth 1 https://github.com/dexidp/dex .

RUN go mod download

RUN CGO_ENABLED=0 GOFLAGS="-trimpath" go build -o /app/dex ./cmd/dex

# runtime
FROM alpine:3.22

RUN apk add --no-cache \
      --repository=https://dl-cdn.alpinelinux.org/alpine/edge/main \
      'zlib=1.3.2-r0' && \
    adduser -D -u 1001 dex

COPY --from=builder /app/dex /usr/local/bin/dex

USER dex
ENTRYPOINT ["dex"]
