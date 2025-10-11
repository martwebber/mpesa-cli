# M-Pesa CLI - CI/CD Documentation

This document describes the comprehensive CI/CD pipeline for the M-Pesa CLI, based on industry best practices from the Stripe CLI.

## Pipeline Overview

Our CI/CD pipeline includes:

- **Continuous Testing** on multiple platforms and Go versions
- **Multi-platform builds** (Linux, macOS, Windows)
- **Package manager integration** (Homebrew, Scoop, APT, YUM)
- **Docker containerization** with multi-architecture support
- **Security scanning** with VirusTotal integration
- **Automated releases** with semantic versioning

## Workflows

### 1. Test Workflow (`.github/workflows/test.yml`)

**Triggers:**

- Push to `main` or `develop` branches
- Pull requests to `main` or `develop` branches

**Matrix Testing:**

- **Go versions**: 1.21.x, 1.22.x, 1.23.x
- **Platforms**: Ubuntu, macOS, Windows
- **Architecture**: amd64, arm64 (where supported)

**Steps:**

1. **Setup** Go environment with caching
2. **Lint** code with golangci-lint
3. **Security** scanning with gosec
4. **Test** with race detection and coverage
5. **Upload** coverage to Codecov

### 2. Release Workflow (`.github/workflows/release.yml`)

**Triggers:**

- Git tags matching `v*` pattern (e.g., `v1.0.0`)

**Multi-platform builds:**

- **Linux**: Uses GoReleaser with `.goreleaser/linux.yml`
- **macOS**: Uses GoReleaser with `.goreleaser/mac.yml`
- **Windows**: Uses GoReleaser with `.goreleaser/windows.yml`

**Artifacts generated:**

- Binaries for all platforms/architectures
- `.deb` and `.rpm` packages for Linux
- Docker images for multiple architectures
- Homebrew formula updates
- Scoop manifest updates
- Checksums and signatures

### 3. Package Manager Testing (`.github/workflows/package-test.yml`)

**Triggers:**

- Manual dispatch
- Daily schedule (8 AM UTC)
- New releases
- Changes to installation scripts

**Package managers tested:**

- **Homebrew** (macOS/Linux)
- **APT** (Debian/Ubuntu)
- **YUM** (RHEL/Fedora/CentOS)
- **Scoop** (Windows)
- **Docker** (All platforms)

### 4. Snapshot Testing (`.github/workflows/test-snapshot.yml`)

**Triggers:**

- Changes to GoReleaser configs
- Changes to Dockerfile
- Changes to release workflow

**Purpose:**

- Test GoReleaser configurations without publishing
- Validate Docker builds
- Catch configuration issues early

## GoReleaser Configurations

### Linux Configuration (`.goreleaser/linux.yml`)

**Features:**

- Multi-architecture builds (amd64, arm64, 386)
- Debian (.deb) packages
- RPM packages
- Docker images with multi-platform manifests
- APT/YUM repository integration (optional)

**Docker registry:**

- GitHub Container Registry: `ghcr.io/martwebber/mpesa-cli`

### macOS Configuration (`.goreleaser/mac.yml`)

**Features:**

- Universal binaries (Intel + Apple Silicon)
- Homebrew formula generation
- Code signing support (with certificates)
- Notarization support (for distribution)

**Homebrew integration:**

- Repository: `martwebber/homebrew-tap`
- Automatic formula updates
- Shell completion generation

### Windows Configuration (`.goreleaser/windows.yml`)

**Features:**

- Multi-architecture builds (amd64, 386)
- Scoop manifest generation
- Chocolatey package support (optional)
- Code signing support (with certificates)

**Scoop integration:**

- Repository: `martwebber/scoop-bucket`
- Automatic manifest updates

## Package Manager Integration

### Homebrew Setup

1. **Create tap repository**:

   ```bash
   # Create repository: martwebber/homebrew-tap
   ```

2. **Installation**:
   ```bash
   brew install martwebber/tap/mpesa-cli
   ```

### Scoop Setup

1. **Create bucket repository**:

   ```bash
   # Create repository: martwebber/scoop-bucket
   ```

2. **Installation**:
   ```powershell
   scoop bucket add martwebber https://github.com/martwebber/scoop-bucket
   scoop install mpesa-cli
   ```

### Docker Usage

```bash
# Pull and run
docker run --rm ghcr.io/martwebber/mpesa-cli:latest --help

# Multi-platform support
docker run --rm --platform linux/amd64 ghcr.io/martwebber/mpesa-cli:latest
docker run --rm --platform linux/arm64 ghcr.io/martwebber/mpesa-cli:latest
```

## Security Features

### VirusTotal Integration

- **Automatic scanning** of Windows binaries
- **PagerDuty alerts** for failed scans
- **Public scan results** for transparency

### Code Signing

- **macOS**: Apple Developer certificates
- **Windows**: Code signing certificates
- **GPG signing** for checksums

### Supply Chain Security

- **Dependency scanning** with GitHub Security
- **SBOM generation** with GoReleaser
- **Multi-platform builds** on GitHub runners
- **Reproducible builds** with version pinning

## Secrets Required

### GitHub Secrets

| Secret                    | Purpose                 | Required For  |
| ------------------------- | ----------------------- | ------------- |
| `GITHUB_TOKEN`            | Basic GitHub operations | All workflows |
| `GORELEASER_GITHUB_TOKEN` | Package manager updates | Release       |

| `VIRUSTOTAL_API_KEY` | Security scanning | Security scan |
| `PAGERDUTY_INTEGRATION_KEY` | Alerting | Package tests |
| `GPG_FINGERPRINT` | Code signing | Signing |

### Optional Secrets

| Secret                | Purpose          | Configuration |
| --------------------- | ---------------- | ------------- |
| `CHOCOLATEY_API_KEY`  | Windows packages | Chocolatey    |
| `APPLE_CERTIFICATE`   | macOS signing    | Code signing  |
| `WINDOWS_CERTIFICATE` | Windows signing  | Code signing  |

## Local Development

### Prerequisites

```bash
# Install development tools
make setup

# Install GoReleaser
go install github.com/goreleaser/goreleaser@latest
```

### Testing Builds Locally

```bash
# Test all platforms
make build-all

# Test with GoReleaser
make snapshot

# Run CI pipeline locally
make ci
```

### Testing Package Managers

```bash
# Test installation scripts
./scripts/install-test.sh homebrew
./scripts/install-test.sh docker
```

## Release Process

### 1. Prepare Release

```bash
# Ensure all tests pass
make ci

# Update version in code (if needed)
# Update CHANGELOG.md
# Commit changes
```

### 2. Create Release

```bash
# Create and push tag
git tag v1.0.0
git push origin v1.0.0

# GitHub Actions will automatically:
# - Run tests
# - Build all platforms
# - Create packages
# - Update package managers
# - Create GitHub release
```

### 3. Verify Release

```bash
# Test installations
brew install martwebber/tap/mpesa-cli
scoop install martwebber/mpesa-cli
docker pull ghcr.io/martwebber/mpesa-cli:v1.0.0
```

## Monitoring and Alerting

### PagerDuty Integration

- **Failed installations** trigger alerts
- **Security scan failures** trigger alerts
- **Build failures** on main branch trigger alerts

### GitHub Insights

- **Build success rates** via GitHub Actions
- **Download statistics** via GitHub Releases
- **Security alerts** via GitHub Security

## Troubleshooting

### Common Issues

1. **Build failures**: Check Go version compatibility
2. **Package manager failures**: Verify repository access
3. **Docker build failures**: Check multi-platform support
4. **Code signing failures**: Verify certificates

### Debugging

```bash
# Test locally
make ci

# Test specific platform
make build-all

# Test GoReleaser config
goreleaser check
```

## Contributing

When contributing to the CI/CD pipeline:

1. **Test changes** with snapshot builds
2. **Update documentation** for new features
3. **Verify security** implications
4. **Test package managers** after changes

## References

- [GoReleaser Documentation](https://goreleaser.com/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Stripe CLI CI Reference](https://github.com/stripe/stripe-cli)
- [Docker Multi-platform Builds](https://docs.docker.com/buildx/working-with-buildx/)
