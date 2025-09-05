#!/bin/bash
# Release script for nvim-secscan

set -e

VERSION_FILE="VERSION"
CHANGELOG_FILE="CHANGELOG.md"

# Get current version
if [ -f "$VERSION_FILE" ]; then
    CURRENT_VERSION=$(cat $VERSION_FILE)
    echo "Current version: $CURRENT_VERSION"
else
    echo "No VERSION file found"
    exit 1
fi

# Get new version from user
echo "Enter new version (current: $CURRENT_VERSION):"
read NEW_VERSION

if [ -z "$NEW_VERSION" ]; then
    echo "No version provided"
    exit 1
fi

# Update VERSION file
echo "$NEW_VERSION" > $VERSION_FILE
echo "Updated VERSION to $NEW_VERSION"

# Update README badge
sed -i "s/version-[0-9]\+\.[0-9]\+\.[0-9]\+/version-$NEW_VERSION/g" README.md
echo "Updated README badge"

# Git operations
echo "Staging changes..."
git add .
git commit -m "Release v$NEW_VERSION

- Performance benchmarking features
- Enhanced security scanning
- Cross-platform compatibility improvements
- Updated documentation"

echo "Creating git tag..."
git tag -a "v$NEW_VERSION" -m "Release v$NEW_VERSION"

echo "Release v$NEW_VERSION prepared!"
echo ""
echo "Next steps:"
echo "1. git push origin main"
echo "2. git push origin v$NEW_VERSION"
echo "3. Create GitHub release from tag"