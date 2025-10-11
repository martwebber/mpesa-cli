# Release System Documentation

This document describes the comprehensive automated release and distribution system for M-Pesa CLI.

## Overview

The release system provides:

- **Automated Builds**: Multi-platform binaries for Linux, macOS, Windows, and FreeBSD
- **Package Distribution**: Homebrew (macOS/Linux), Scoop (Windows), Docker (GHCR)
- **Security**: Container signing with cosign, SBOM generation, vulnerability scanning
- **Quality Assurance**: Full CI/CD validation before release
- **Documentation**: Automated changelog generation and release notes

## Architecture

### 1. Release Trigger

- Releases are triggered by pushing a git tag matching `v*` pattern
- Example: `git tag v1.2.3 && git push origin v1.2.3`

### 2. Pre-Release Validation

- Full test suite execution across Go 1.22.x, 1.23.x, 1.24.x
- Multi-platform testing (Ubuntu, macOS, Windows)
- Code quality checks with golangci-lint
- Security scanning with gosec
- All CI checks must pass before release proceeds

### 3. Build Process

- **GoReleaser**: Handles cross-compilation for all target platforms
- **Docker**: Multi-arch container images (amd64, arm64)
- **Archives**: Compressed archives with binaries and documentation
- **Checksums**: SHA256 checksums for all artifacts

### 4. Distribution Channels

#### GitHub Releases

- Primary release location with all binaries and archives
- Automated changelog generation from conventional commits
- Release notes with installation instructions

#### Homebrew (macOS/Linux)

```bash
brew install martwebber/tap/mpesa-cli
```

- Automatic formula updates in `homebrew-tap` repository
- Includes shell completions (bash, zsh, fish)
- Supports both Intel and Apple Silicon Macs

#### Scoop (Windows)

```powershell
scoop bucket add martwebber https://github.com/martwebber/scoop-bucket.git
scoop install mpesa-cli
```

- Automatic manifest updates in `scoop-bucket` repository
- Windows-specific package management

#### Docker (GHCR)

```bash
docker run --rm ghcr.io/martwebber/mpesa-cli:latest version
```

- Multi-architecture support (amd64, arm64)
- Signed images with cosign
- Minimal scratch-based images for security

### 5. Security Features

#### Container Signing

- All Docker images are signed with cosign using keyless signatures
- Verification: `cosign verify --certificate-identity-regexp=".*" --certificate-oidc-issuer-regexp=".*" ghcr.io/martwebber/mpesa-cli:latest`

#### SBOM Generation

- Software Bill of Materials for all releases
- SPDX format for compatibility with security tools
- Included in release artifacts

#### Vulnerability Scanning

- Container images scanned with Trivy
- Results uploaded to GitHub Security tab
- Automatic security advisories for vulnerabilities

## Configuration Files

### .goreleaser.yaml

Main configuration for cross-platform builds and distribution:

- Build targets and flags
- Archive formats and contents
- Homebrew formula configuration
- Scoop manifest configuration
- Docker image settings
- Changelog generation rules

### .github/workflows/release.yml

GitHub Actions workflow for automated releases:

- Pre-release validation
- GoReleaser execution
- Container signing
- Security scanning
- Deployment tracking
- Notification system

### Dockerfile

Multi-stage container build:

- Minimal scratch-based final image
- Security-focused with non-root execution
- Proper OCI labels and metadata

## Setup Instructions

### 1. Initial Setup

Run the setup script to create necessary repositories and secrets:

```bash
./scripts/setup-release-infrastructure.sh
```

This script will:

- Create `homebrew-tap` repository for Homebrew formulae
- Create `scoop-bucket` repository for Scoop manifests
- Set up GitHub secrets for repository access tokens
- Provide instructions for testing

### 2. GitHub Secrets Required

- `HOMEBREW_TAP_GITHUB_TOKEN`: Token with repo access for Homebrew updates
- `SCOOP_BUCKET_GITHUB_TOKEN`: Token with repo access for Scoop updates

### 3. Testing the Release Pipeline

Create a test release to validate the system:

```bash
git tag v0.1.0-test
git push origin v0.1.0-test
```

Monitor the GitHub Actions workflow and verify:

- All jobs complete successfully
- Artifacts are created and uploaded
- Package repositories are updated
- Docker images are published and signed

## Release Process

### 1. Prepare Release

1. Ensure all changes are merged to `main` branch
2. Update version references if needed
3. Run local tests: `go test ./...`
4. Verify CI is passing on `main`

### 2. Create Release

1. Create and push a version tag:
   ```bash
   git tag v1.2.3
   git push origin v1.2.3
   ```
2. Monitor GitHub Actions workflow
3. Verify release completion

### 3. Post-Release Validation

1. Check GitHub Release page for artifacts
2. Verify package installations:

   ```bash
   # Homebrew
   brew install martwebber/tap/mpesa-cli

   # Scoop
   scoop install mpesa-cli

   # Docker
   docker run --rm ghcr.io/martwebber/mpesa-cli:v1.2.3 version
   ```

3. Test key functionality of installed packages

## Version Management

### Semantic Versioning

The project follows [Semantic Versioning 2.0.0](https://semver.org/):

- `MAJOR.MINOR.PATCH` format
- Breaking changes increment MAJOR version
- New features increment MINOR version
- Bug fixes increment PATCH version

### Pre-release Versions

For testing and development:

- Alpha: `v1.2.3-alpha.1`
- Beta: `v1.2.3-beta.1`
- Release candidate: `v1.2.3-rc.1`

## Changelog Generation

Automatic changelog generation based on conventional commits:

### Commit Message Format

```
type(scope): description

[optional body]

[optional footer(s)]
```

### Supported Types

- `feat`: New features → "New Features" section
- `fix`: Bug fixes → "Bug Fixes" section
- `sec`: Security updates → "Security Updates" section
- `perf`: Performance improvements → "Performance Improvements" section
- `docs`, `test`, `chore`, `ci`, `build`: Excluded from changelog

### Example Commit Messages

```
feat(auth): add support for OAuth2 authentication
fix(config): resolve file permission issues on Windows
sec(deps): update vulnerable dependencies
perf(query): optimize transaction lookup performance
```

## Monitoring and Notifications

### GitHub Actions

- Workflow status visible in Actions tab
- Email notifications for failed releases (if configured)
- Deployment status tracking

### Security Alerts

- Vulnerability scan results in Security tab
- Dependabot alerts for dependency vulnerabilities
- Container image security advisories

### Package Health

- Homebrew formula validation
- Scoop manifest validation
- Docker image layer analysis

## Troubleshooting

### Common Issues

#### Release Fails with Token Error

1. Verify GitHub secrets are set correctly
2. Check token permissions (repo scope required)
3. Ensure target repositories exist

#### Docker Build Failures

1. Check Dockerfile syntax
2. Verify base image availability
3. Review build context and .dockerignore

#### Package Repository Update Failures

1. Verify repository structure matches expectations
2. Check for conflicting manual changes
3. Review GoReleaser configuration

#### Security Scan Failures

1. Address identified vulnerabilities
2. Update base images if needed
3. Review SARIF upload configuration

### Debug Commands

```bash
# Test GoReleaser locally (snapshot mode)
goreleaser release --snapshot --clean

# Build local Docker image
docker build -t mpesa-cli-test .

# Validate Homebrew formula
brew audit --strict homebrew-tap/Formula/mpesa-cli.rb

# Test Scoop manifest
scoop checkver mpesa-cli
```

## Security Considerations

### Supply Chain Security

- All dependencies verified with checksums
- Container images built from scratch for minimal attack surface
- Signed releases with cosign keyless signatures
- SBOM generation for transparency

### Access Control

- Repository access tokens with minimal required permissions
- Automated token rotation recommendations
- Separate tokens for different package repositories

### Vulnerability Management

- Automated security scanning in CI/CD
- Dependency vulnerability monitoring with Dependabot
- Regular security updates for base images and dependencies

## Maintenance

### Regular Tasks

1. **Monthly**: Review and update dependencies
2. **Quarterly**: Audit and rotate access tokens
3. **Per Release**: Review security scan results
4. **Annually**: Update base images and security tools

### Monitoring

- GitHub Actions workflow success rates
- Package installation success metrics
- Security scan results and trends
- User feedback and issue reports

## Support

For issues with the release system:

1. Check GitHub Actions logs for detailed error messages
2. Review this documentation for configuration requirements
3. Create an issue in the repository with relevant logs and context
4. For security-related issues, follow responsible disclosure practices

---

This release system provides a production-ready, secure, and automated solution for distributing M-Pesa CLI across multiple platforms and package managers.
