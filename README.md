# M-Pesa CLI

[![Go Report Card](https://goreportcard.com/badge/github.com/martwebber/mpesa-cli)](https://goreportcard.com/report/github.com/martwebber/mpesa-cli)
[![Test Status](https://github.com/martwebber/mpesa-cli/workflows/test/badge.svg)](https://github.com/martwebber/mpesa-cli/actions/workflows/test.yml)
[![Release](https://img.shields.io/github/v/release/martwebber/mpesa-cli)](https://github.com/martwebber/mpesa-cli/releases)
[![GHCR](https://img.shields.io/badge/ghcr-latest-blue)](https://github.com/martwebber/mpesa-cli/pkgs/container/mpesa-cli)
[![License](https://img.shields.io/github/license/martwebber/mpesa-cli)](LICENSE)

A powerful command-line interface for interacting with the M-Pesa API. Built with Go and designed for developers, businesses, and individuals who need to integrate M-Pesa services into their workflows.

## Features

- 🚀 **Fast and lightweight** - Single binary with no dependencies
- 🔐 **Secure credential management** - Uses system keyring for sensitive data
- 🌍 **Multi-environment support** - Development, staging, and production configs
- 📊 **Comprehensive transaction queries** - Search, filter, and export transaction data
- 🏥 **Health checks** - Built-in diagnostics for API connectivity
- 🔧 **Configuration management** - Flexible config system with validation
- 📝 **Detailed logging** - Structured logging with multiple levels
- 🧪 **Extensive testing** - Full test coverage with integration tests

## Installation

### Homebrew (macOS/Linux)

```bash
brew install martwebber/tap/mpesa-cli
```

### Scoop (Windows)

```powershell
scoop bucket add martwebber https://github.com/martwebber/scoop-bucket
scoop install mpesa-cli
```

### Docker

```bash
# Run directly
docker run --rm ghcr.io/martwebber/mpesa-cli:latest --help

# Use with volume for config persistence
docker run --rm -v ~/.config/mpesa:/root/.config/mpesa ghcr.io/martwebber/mpesa-cli:latest
```

### APT (Debian/Ubuntu)

```bash
# Add repository
curl -fsSL https://github.com/martwebber/mpesa-cli/releases/latest/download/setup-apt.sh | sudo bash

# Install
sudo apt update && sudo apt install mpesa-cli
```

### YUM (RHEL/Fedora/CentOS)

```bash
# Add repository
curl -fsSL https://github.com/martwebber/mpesa-cli/releases/latest/download/setup-yum.sh | sudo bash

# Install
sudo yum install mpesa-cli  # or dnf install mpesa-cli
```

### Download Binary

Download the latest release for your platform from the [releases page](https://github.com/martwebber/mpesa-cli/releases).

## Quick Start

### 1. Login and Setup

```bash
# Login with your M-Pesa API credentials
mpesa-cli login

# Verify your setup
mpesa-cli doctor
```

### 2. Query Transactions

```bash
# Get recent transactions
mpesa-cli query --limit 10

# Search by phone number
mpesa-cli query --phone 254712345678

# Filter by amount range
mpesa-cli query --min-amount 1000 --max-amount 5000

# Export to JSON
mpesa-cli query --format json --output transactions.json
```

### 3. Check Status

```bash
# Check API connectivity and credentials
mpesa-cli doctor

# Verbose health check
mpesa-cli doctor --verbose
```

## Configuration

### Environment Support

The CLI supports multiple environments:

- `development` - For testing and development
- `staging` - For pre-production testing
- `production` - For live transactions

```bash
# Set environment
export MPESA_ENV=development

# Or use flag
mpesa-cli --env production query
```

### Configuration File

The CLI uses a configuration file located at:

- Linux/macOS: `~/.config/mpesa/config.yaml`
- Windows: `%APPDATA%\mpesa\config.yaml`

Example configuration:

```yaml
environments:
  development:
    base_url: "https://sandbox.safaricom.co.ke"
    timeout: 30s
    retry_attempts: 3
  production:
    base_url: "https://api.safaricom.co.ke"
    timeout: 10s
    retry_attempts: 5

logging:
  level: "info"
  format: "json"
  file: "/var/log/mpesa-cli.log"

defaults:
  output_format: "table"
  page_size: 50
```

## Commands

### `mpesa-cli login`

Authenticate with M-Pesa API credentials.

```bash
mpesa-cli login [flags]
```

**Flags:**

- `--consumer-key` - Consumer key (can also use MPESA_CONSUMER_KEY env var)
- `--consumer-secret` - Consumer secret (can also use MPESA_CONSUMER_SECRET env var)
- `--env` - Environment (development/staging/production)

### `mpesa-cli query`

Query and search M-Pesa transactions.

```bash
mpesa-cli query [flags]
```

**Flags:**

- `--phone` - Filter by phone number
- `--amount` - Filter by exact amount
- `--min-amount` - Minimum amount filter
- `--max-amount` - Maximum amount filter
- `--date-from` - Start date (YYYY-MM-DD)
- `--date-to` - End date (YYYY-MM-DD)
- `--status` - Transaction status filter
- `--limit` - Number of results to return (default 50)
- `--format` - Output format (table/json/csv) (default "table")
- `--output` - Output file path
- `--sort` - Sort field (date/amount/phone)
- `--order` - Sort order (asc/desc) (default "desc")

### `mpesa-cli doctor`

Run health checks and diagnostics.

```bash
mpesa-cli doctor [flags]
```

**Flags:**

- `--verbose` - Show detailed diagnostic information
- `--format` - Output format (table/json) (default "table")

## Examples

### Authentication

```bash
# Interactive login
mpesa-cli login

# Environment variables
export MPESA_CONSUMER_KEY="your_key"
export MPESA_CONSUMER_SECRET="your_secret"
mpesa-cli login --env production

# Direct flags (not recommended for production)
mpesa-cli login --consumer-key "key" --consumer-secret "secret"
```

### Transaction Queries

```bash
# Recent transactions in table format
mpesa-cli query --limit 20

# Transactions for specific phone number
mpesa-cli query --phone 254712345678 --limit 100

# Transactions in date range
mpesa-cli query --date-from 2024-01-01 --date-to 2024-01-31

# High-value transactions
mpesa-cli query --min-amount 10000 --format json

# Export all transactions to CSV
mpesa-cli query --limit 1000 --format csv --output transactions.csv

# Complex query
mpesa-cli query \
  --phone 254712345678 \
  --min-amount 1000 \
  --max-amount 50000 \
  --date-from 2024-01-01 \
  --status completed \
  --sort amount \
  --order desc \
  --format json \
  --output results.json
```

### Health Checks

```bash
# Basic health check
mpesa-cli doctor

# Detailed diagnostics
mpesa-cli doctor --verbose

# JSON output for automation
mpesa-cli doctor --format json
```

## Development

### Prerequisites

- Go 1.21 or later
- Make (for build automation)

### Building from Source

```bash
# Clone repository
git clone https://github.com/martwebber/mpesa-cli.git
cd mpesa-cli

# Install dependencies
go mod download

# Build for current platform
make build

# Build for all platforms
make build-all

# Run tests
make test

# Run linting
make lint

# Run full CI pipeline
make ci
```

### Project Structure

```
mpesa-cli/
├── cmd/                    # CLI commands and entry points
│   ├── root.go            # Root command and global flags
│   ├── login.go           # Authentication command
│   ├── query.go           # Transaction query command
│   └── doctor.go          # Health check command
├── pkg/mpesa/             # Core business logic
│   ├── config.go          # Configuration management
│   ├── auth.go            # Authentication logic
│   └── transactions.go    # Transaction operations
├── .github/workflows/     # CI/CD pipeline
├── .goreleaser/          # Multi-platform build configs
├── docs/                 # Documentation
├── scripts/              # Automation scripts
└── tests/                # Integration tests
```

## CI/CD Pipeline

This project uses a comprehensive CI/CD pipeline based on industry best practices:

- **Multi-platform builds** (Linux, macOS, Windows)
- **Package manager integration** (Homebrew, Scoop, APT, YUM)
- **Docker containerization** with multi-architecture support
- **Security scanning** with VirusTotal integration
- **Automated testing** across multiple Go versions and platforms

See [CI/CD Documentation](docs/CI_CD.md) for detailed information.

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Workflow

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Make** your changes with tests
4. **Run** the test suite (`make test`)
5. **Commit** your changes (`git commit -m 'Add amazing feature'`)
6. **Push** to the branch (`git push origin feature/amazing-feature`)
7. **Open** a Pull Request

### Code Style

We use:

- **golangci-lint** for code linting
- **gofmt** for code formatting
- **gosec** for security analysis
- **go test** with race detection

Run `make lint` to check your code before submitting.

## Security

### Credential Management

- Credentials are stored securely in the system keyring
- No sensitive data in configuration files
- Environment variables supported for automation
- API keys are never logged or exposed

### Reporting Vulnerabilities

Please report security vulnerabilities to [security@example.com](mailto:security@example.com).

## Support

### Documentation

- [API Documentation](docs/API.md)
- [Configuration Guide](docs/CONFIGURATION.md)
- [CI/CD Documentation](docs/CI_CD.md)
- [Troubleshooting Guide](docs/TROUBLESHOOTING.md)

### Getting Help

- **GitHub Issues**: [Report bugs or request features](https://github.com/martwebber/mpesa-cli/issues)
- **Discussions**: [Community discussions](https://github.com/martwebber/mpesa-cli/discussions)
- **Wiki**: [Additional documentation](https://github.com/martwebber/mpesa-cli/wiki)

### FAQ

**Q: How do I switch between environments?**
A: Use the `--env` flag or set the `MPESA_ENV` environment variable.

**Q: Where are my credentials stored?**
A: Credentials are stored securely in your system's keyring (Keychain on macOS, Credential Manager on Windows, Secret Service on Linux).

**Q: Can I use this in CI/CD pipelines?**
A: Yes! Use environment variables for authentication and the `--format json` flag for machine-readable output.

**Q: How do I export large datasets?**
A: Use the `--format csv` option with `--output filename.csv` to export data efficiently.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Cobra](https://github.com/spf13/cobra) - CLI framework
- [Viper](https://github.com/spf13/viper) - Configuration management
- [GoReleaser](https://github.com/goreleaser/goreleaser) - Release automation
- [Stripe CLI](https://github.com/stripe/stripe-cli) - CI/CD inspiration

---

Built with ❤️ by [martwebber](https://github.com/martwebber)
