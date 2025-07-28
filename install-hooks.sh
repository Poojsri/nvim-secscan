#!/bin/bash
# Install pre-commit hook for nvim-secscan

HOOK_FILE=".git/hooks/pre-commit"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing nvim-secscan pre-commit hook..."

# Create pre-commit hook
cat > "$HOOK_FILE" << 'EOF'
#!/bin/bash
# nvim-secscan pre-commit hook

echo "🛡️  Running security scan before commit..."

# Get list of staged Python/JS files
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(py|js|ts)$')

if [ -z "$STAGED_FILES" ]; then
    echo "✅ No Python/JS files to scan"
    exit 0
fi

# Run security scan on staged files
ISSUES_FOUND=0
for FILE in $STAGED_FILES; do
    if [ -f "$FILE" ]; then
        echo "Scanning: $FILE"
        python3 scripts/secscan-cli.py "$FILE" > /tmp/secscan-result.json
        
        # Check if vulnerabilities found
        VULNS=$(jq '.vulnerabilities | length' /tmp/secscan-result.json 2>/dev/null || echo "0")
        ISSUES=$(jq '.code_issues | length' /tmp/secscan-result.json 2>/dev/null || echo "0")
        
        if [ "$VULNS" -gt 0 ] || [ "$ISSUES" -gt 0 ]; then
            echo "⚠️  Security issues found in $FILE:"
            echo "   Vulnerabilities: $VULNS"
            echo "   Code Issues: $ISSUES"
            ISSUES_FOUND=1
        fi
    fi
done

if [ $ISSUES_FOUND -eq 1 ]; then
    echo ""
    echo "🚨 Security issues detected! Commit blocked."
    echo "Run 'nvim-secscan <file>' for details or use --no-verify to skip"
    exit 1
fi

echo "✅ Security scan passed"
exit 0
EOF

# Make hook executable
chmod +x "$HOOK_FILE"

echo "✅ Pre-commit hook installed successfully!"
echo "Hook location: $HOOK_FILE"
echo ""
echo "To bypass hook: git commit --no-verify"