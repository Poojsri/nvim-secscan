# nvim-secscan

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub issues](https://img.shields.io/github/issues/Poojsri/nvim-secscan)](https://github.com/Poojsri/nvim-secscan/issues)
[![GitHub stars](https://img.shields.io/github/stars/Poojsri/nvim-secscan)](https://github.com/Poojsri/nvim-secscan/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/Poojsri/nvim-secscan)](https://github.com/Poojsri/nvim-secscan/network)

🛡️ **Security vulnerability scanner for Neovim** - Find CVEs and insecure code patterns right in your editor.

## ✨ Features

- 🔍 **Dependency Scanning** - Check `requirements.txt` and `package.json` for vulnerabilities
- 🛡️ **Code Analysis** - Detect insecure patterns with Bandit integration  
- 💡 **Smart Suggestions** - Get secure coding recommendations inline
- 📊 **Visual Dashboard** - See security issues with severity breakdown
- ⚡ **Performance Benchmarking** - Compare scanner speeds
- ☁️ **Cloud Ready** - Deploy to AWS with one command

## 🚀 Quick Start

### Install
```lua
-- lazy.nvim
{
  "Poojsri/nvim-secscan",
  config = function()
    require("nvim-secscan").setup()
  end,
}
```

### Use
```vim
:SecScan                 " Scan current file
:SecScanSummary         " Show security dashboard  
:SecScanBenchmark       " Compare scanner performance
```

### CLI
```bash
./install.sh            # Install system-wide
nvim-secscan app.py     # Scan any file
```

## 📋 Commands

| Command | Description |
|---------|-------------|
| `:SecScan` | Scan current file for vulnerabilities |
| `:SecScanSummary` | Show visual security dashboard |
| `:SecScanBenchmark` | Benchmark scanner performance |
| `:SecScanReport` | Generate security report |
| `:SecScanClear` | Clear diagnostics |

## ⚙️ Configuration

```lua
require("nvim-secscan").setup({
  scanner = "osv",              -- "osv" or "trivy"
  enable_diagnostics = true,    -- Show inline issues
  enable_suggestions = true,    -- Smart recommendations
})
```

## 🔧 Prerequisites

- **curl** - For API requests
- **bandit** (optional) - `pip install bandit`
- **trivy** (optional) - For enhanced scanning

## 📊 Example Output

```
🛡️  Security Scan Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔴 CRITICAL: 2
🟠 HIGH:     5  
🟡 MEDIUM:   3
📊 Total Issues: 10
```

**Benchmark Results:**
```
Scanner Performance:
1. nvim-secscan: 1180ms ± 17ms (FASTEST)
2. bandit: 2340ms ± 45ms (1.98x slower)
```

## ☁️ Cloud Deployment

Deploy to AWS EC2 in 2 minutes:
```bash
cd deploy && ./quick-deploy.sh
```

Includes: EC2 instance, S3 bucket, Lambda alerts, security tools pre-installed.

## 🤝 Contributing

We welcome contributions! Areas to help:
- 🔍 **New Languages** - Add Rust, Go, Java support
- 🛡️ **Security Tools** - Integrate more scanners  
- 🤖 **AI Features** - ML-powered suggestions
- 📚 **Documentation** - Improve guides

See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## 📄 License

MIT License - see [LICENSE](LICENSE) file.

---

**⭐ Star this repo if nvim-secscan helps secure your code!**