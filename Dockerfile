# Build stage
FROM --platform=$BUILDPLATFORM golang:1.24-alpine AS builder

WORKDIR /app

# Install dependencies for building
RUN apk add --no-cache git ca-certificates tzdata

# Copy go mod and sum files
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download && go mod verify

# Copy source code
COPY . .

# Build arguments
ARG TARGETOS
ARG TARGETARCH
ARG VERSION=dev
ARG COMMIT=unknown
ARG DATE=unknown

# Build the binary
RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH \
    go build \
    -ldflags="-s -w -X main.version=${VERSION} -X main.commit=${COMMIT} -X main.date=${DATE}" \
    -o mpesa-cli \
    ./main.go

# Final stage
FROM scratch

# Import from builder
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo
COPY --from=builder /app/mpesa-cli /usr/local/bin/mpesa-cli

# Create a non-root user
# Note: In scratch image, we can't create users dynamically, 
# so we'll run as root but the container will be minimal

# Labels
LABEL org.opencontainers.image.title="M-Pesa CLI"
LABEL org.opencontainers.image.description="A command-line interface for M-Pesa API operations"
LABEL org.opencontainers.image.vendor="Martin Mwangi"
LABEL org.opencontainers.image.authors="mwangi.martin24@gmail.com"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.source="https://github.com/martwebber/mpesa-cli"
LABEL org.opencontainers.image.documentation="https://github.com/martwebber/mpesa-cli/blob/main/README.md"
LABEL org.opencontainers.image.url="https://github.com/martwebber/mpesa-cli"

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/mpesa-cli"]

# Default command
CMD ["--help"]