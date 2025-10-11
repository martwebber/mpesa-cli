# 🐳 GitHub Container Registry (GHCR) Setup

## 🎯 **Why GHCR Instead of Docker Hub?**

✅ **Benefits of GHCR:**

- **No rate limits** for public repositories
- **Integrated authentication** with GitHub
- **Better security** with fine-grained permissions
- **Free unlimited storage** for public repos
- **Automatic cleanup policies**
- **Native CI/CD integration** with GitHub Actions
- **Better performance** in GitHub Actions

❌ **Docker Hub limitations:**

- Rate limits (200 pulls/6 hours for anonymous users)
- Requires separate authentication
- Costs money for unlimited public repos
- Slower in GitHub Actions

---

## 🔧 **Updated Secrets Configuration**

### **✅ Required Secrets (Simplified)**

| Secret                    | Purpose                                | Where to Get                 | Priority        |
| ------------------------- | -------------------------------------- | ---------------------------- | --------------- |
| `GITHUB_TOKEN`            | GHCR authentication & basic operations | Auto-provided by GitHub      | **Required** ✅ |
| `GORELEASER_GITHUB_TOKEN` | Update package managers                | GitHub Personal Access Token | **Required** 🔑 |

### **❌ No Longer Needed**

| Secret            | Status     | Reason                          |
| ----------------- | ---------- | ------------------------------- |
| `DOCKER_USERNAME` | ❌ Removed | GHCR uses GitHub authentication |
| `DOCKER_PASSWORD` | ❌ Removed | GHCR uses GitHub tokens         |

---

## 🚀 **What Changed**

### **1. GoReleaser Configuration**

- ✅ Removed Docker Hub image templates
- ✅ Updated to use only `ghcr.io/martwebber/mpesa-cli`
- ✅ Simplified docker manifests to GHCR only

### **2. GitHub Actions Workflows**

- ✅ Removed Docker Hub login steps
- ✅ Uses `docker/login-action@v3` for GHCR
- ✅ Authentication via `${{ secrets.GITHUB_TOKEN }}`

### **3. Documentation Updates**

- ✅ Updated all Docker examples to use GHCR
- ✅ Changed badge from Docker Hub pulls to GHCR
- ✅ Updated installation instructions

### **4. Installation Scripts**

- ✅ Updated `scripts/install-test.sh` to test GHCR images
- ✅ Package testing workflow uses GHCR

---

## 📋 **Setup Instructions**

### **1. Enable Container Registry**

GHCR is automatically enabled for your repository - no setup needed!

### **2. Configure Permissions**

The workflow automatically gets the correct permissions:

```yaml
permissions:
  contents: write
  packages: write # This allows GHCR access
  id-token: write
```

### **3. Test GHCR Access**

```bash
# Pull your image (after first release)
docker pull ghcr.io/martwebber/mpesa-cli:latest

# Run your CLI
docker run --rm ghcr.io/martwebber/mpesa-cli:latest --help
```

---

## 🎯 **Simplified Workflow**

### **Before (Docker Hub)**

1. Create Docker Hub account
2. Generate Docker Hub access token
3. Add `DOCKER_USERNAME` secret
4. Add `DOCKER_PASSWORD` secret
5. Configure workflow authentication
6. Deal with rate limits

### **After (GHCR)**

1. ✅ Nothing - it just works!
2. Uses existing GitHub authentication
3. No rate limits
4. Better performance

---

## 🔐 **Required GitHub Personal Access Token**

You still need **one** token for package manager updates:

### **Create Token:**

1. Go to GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Click "Generate new token (classic)"
3. Name: `mpesa-cli-releases`
4. Expiration: `No expiration` (or 1 year)
5. Select scopes:
   - ✅ `repo` (Full control of private repositories)
   - ✅ `write:packages` (Upload packages to GitHub Package Registry)
   - ✅ `read:packages` (Download packages from GitHub Package Registry)

### **Add Secret:**

1. Go to your repository: `https://github.com/martwebber/mpesa-cli`
2. Settings → Secrets and variables → Actions
3. Click "New repository secret"
4. Name: `GORELEASER_GITHUB_TOKEN`
5. Value: Paste your token
6. Click "Add secret"

---

## 🧪 **Test Your Setup**

### **1. Create Test Release**

```bash
git tag v0.1.0-test
git push origin v0.1.0-test
```

### **2. Check GitHub Actions**

- Go to Actions tab in your repository
- Watch the release workflow run
- Verify GHCR images are published

### **3. Test Container**

```bash
# After successful build
docker pull ghcr.io/martwebber/mpesa-cli:v0.1.0-test
docker run --rm ghcr.io/martwebber/mpesa-cli:v0.1.0-test --version
```

### **4. Cleanup Test**

```bash
git tag -d v0.1.0-test
git push origin :refs/tags/v0.1.0-test
```

---

## 📦 **Updated Installation Methods**

### **Docker (GHCR)**

```bash
# Latest version
docker run --rm ghcr.io/martwebber/mpesa-cli:latest --help

# Specific version
docker run --rm ghcr.io/martwebber/mpesa-cli:v1.0.0 --help

# With persistent config
docker run --rm -v ~/.config/mpesa:/root/.config/mpesa ghcr.io/martwebber/mpesa-cli:latest
```

### **Multi-platform Support**

```bash
# AMD64 (Intel/AMD)
docker run --rm --platform linux/amd64 ghcr.io/martwebber/mpesa-cli:latest

# ARM64 (Apple Silicon, ARM servers)
docker run --rm --platform linux/arm64 ghcr.io/martwebber/mpesa-cli:latest
```

---

## 🎉 **Benefits Summary**

- 🔥 **50% fewer secrets** needed (from 4 to 2)
- ⚡ **Faster CI/CD** (no Docker Hub rate limits)
- 🔐 **Better security** (uses GitHub's native authentication)
- 💰 **Cost savings** (no Docker Hub subscription needed)
- 🛠️ **Simpler maintenance** (one less external dependency)

Your CI/CD pipeline is now more efficient, secure, and easier to maintain! 🚀
