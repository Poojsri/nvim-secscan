# Changelog

All notable changes to nvim-secscan will be documented in this file.

## [1.1.0] 
### Added
- 🚀 **Performance Benchmarking**: Hyperfine-style benchmarking for scanners and code execution
- ⚡ **New Commands**: `:SecScanBenchmark` and `:SecScanBenchmarkCode`
- 📊 **Statistical Analysis**: Mean, median, standard deviation with warmup runs
- 🔧 **CLI Benchmarking**: Standalone `benchmark-cli.py` tool
- 🌐 **Cross-Platform**: Windows and Unix compatibility for benchmarking
- 📈 **Performance Comparison**: Compare nvim-secscan vs bandit vs trivy speeds

### Enhanced
- 🛡️ **Security Scanning**: Improved error handling and cross-platform support
- 📚 **Documentation**: Updated README with benchmarking examples
- 🎯 **User Experience**: Better floating window displays for benchmark results

### Technical
- Added `lua/nvim-secscan/benchmark.lua` module
- Added `scripts/benchmark-cli.py` standalone tool
- Enhanced main plugin with benchmark command integration
- Improved Windows compatibility for command execution

## [1.0.0] - 2024-01-XX

### Added
- 🔍 **Multi-Scanner Support**: OSV.dev API and Trivy integration
- 🛡️ **Code Analysis**: Bandit integration for Python security patterns
- 💡 **Smart Suggestions**: Inline security recommendations
- 📊 **Security Dashboard**: Visual severity breakdown
- 📄 **Report Generation**: Markdown and JSON export
- ☁️ **AWS Integration**: S3 upload and Lambda triggers
- 🌐 **Cloud Deployment**: CloudFormation, Terraform, Docker templates
- 📱 **CLI Tool**: Standalone security scanner
- 🔧 **Pre-commit Hooks**: Git integration for security scanning

### Supported
- Python dependency scanning (requirements.txt)
- JavaScript/TypeScript dependency scanning (package.json)
- Cross-platform compatibility (Windows, Linux, macOS)
- Multiple output formats (diagnostics, floating windows, reports)
