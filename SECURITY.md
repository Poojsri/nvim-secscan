# Security Policy

## Supported Versions

We release patches for security vulnerabilities for the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

We take security vulnerabilities seriously. If you discover a security vulnerability in nvim-secscan, please report it responsibly.

### How to Report

1. **Do NOT** create a public GitHub issue for security vulnerabilities
2. Email us at: [security@nvim-secscan.dev] (replace with actual email)
3. Include the following information:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

### What to Expect

- **Acknowledgment**: We'll acknowledge receipt within 48 hours
- **Initial Response**: We'll provide an initial response within 5 business days
- **Updates**: We'll keep you informed of our progress
- **Resolution**: We aim to resolve critical vulnerabilities within 30 days

### Responsible Disclosure

- Give us reasonable time to fix the issue before public disclosure
- We'll credit you in our security advisory (unless you prefer to remain anonymous)
- We may offer a small token of appreciation for significant findings

## Security Best Practices

When using nvim-secscan:

1. **Keep Updated**: Always use the latest version
2. **Secure Tokens**: Store GitHub tokens and AWS credentials securely
3. **Network Security**: Use HTTPS for all API communications
4. **Access Control**: Limit AWS IAM permissions to minimum required
5. **Code Review**: Review scan results before taking action

## Known Security Considerations

- API tokens are stored in environment variables (secure)
- Network requests to OSV.dev and GitHub APIs (encrypted)
- File system access for reading dependency files (local only)
- AWS integration requires proper IAM permissions

## Contact

For security-related questions or concerns:
- Security Email: [security@nvim-secscan.dev]
- General Issues: GitHub Issues (for non-security bugs)
- Discussions: GitHub Discussions