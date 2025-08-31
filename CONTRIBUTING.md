# Contributing to nvim-secscan

## Development Setup

1. Clone the repository
2. Install dependencies:
   ```bash
   pip install bandit requests
   ```
3. Install Neovim and configure the plugin

## Project Structure

```
nvim-secscan/
├── lua/nvim-secscan/          # Core plugin modules
├── plugin/                    # Plugin entry point
├── scripts/                   # CLI and setup scripts
├── deploy/                    # Cloud deployment templates
├── install.sh                 # Installation script
└── README.md                  # Documentation
```

## Adding New Features

1. Create feature branch: `git checkout -b feature/new-scanner`
2. Add functionality in appropriate module
3. Update documentation
4. Test thoroughly
5. Submit pull request

## Code Style

- Use clear, descriptive function names
- Add comments for complex logic
- Follow Lua and Python best practices
- Keep functions focused and small

## Testing

- Test with real vulnerable dependencies
- Verify CLI and Neovim integration
- Test cloud deployment templates
- Ensure cross-platform compatibility

## Submitting Changes

1. Fork the repository
2. Create feature branch
3. Make changes with clear commit messages
4. Update documentation if needed
5. Submit pull request with description