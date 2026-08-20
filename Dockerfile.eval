# Multi-stage build for gotify/server from source
# Uses standard golang image with CGO enabled for sqlite3

# --- Go Builder ---
FROM golang:1.26-bookworm AS builder

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -yq --no-install-recommends \
    gcc \
    libc6-dev \
    sqlite3 \
    libsqlite3-dev \
    ca-certificates \
    git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src/gotify

# Copy go mod files first for layer caching
COPY go.mod go.sum ./
RUN go mod download

# Copy source
COPY . .

# Create stub UI build files (go:embed build/* requires at least one file)
RUN mkdir -p ui/build && \
    echo '<!DOCTYPE html><html><body><div id="root"></div><script>window.config = %CONFIG%;</script></body></html>' > ui/build/index.html && \
    echo '{"short_name":"Gotify","name":"Gotify","start_url":"/"}' > ui/build/manifest.json

# Build the server binary with CGO enabled (required for sqlite3)
RUN CGO_ENABLED=1 GOOS=linux go build \
    -mod=mod \
    -ldflags="-s -w -X main.Mode=prod" \
    -o /target/gotify-app \
    .

# --- Runtime image ---
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -yq --no-install-recommends \
    sqlite3 \
    ca-certificates \
    curl \
    tzdata \
    && rm -rf /var/lib/apt/lists/*

# Default port (overridable via GOTIFY_SERVER_PORT env)
ENV GOTIFY_SERVER_PORT=80

WORKDIR /app

COPY --from=builder /target/gotify-app ./gotify-app

HEALTHCHECK --interval=15s --timeout=5s --start-period=10s \
    CMD curl --fail http://localhost:${GOTIFY_SERVER_PORT}/health || exit 1

EXPOSE 80

ENTRYPOINT ["./gotify-app"]
CMD ["serve"]
