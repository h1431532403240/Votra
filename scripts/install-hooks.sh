#!/bin/bash
# Install local git hooks for Votra development
# This script provides an alternative to the pre-commit framework
#
# Usage: ./scripts/install-hooks.sh
# Bypass: SKIP=gitleaks git commit OR git commit --no-verify

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOKS_DIR="$REPO_ROOT/.git/hooks"

echo "Installing git hooks for Votra..."

# Check if gitleaks is installed
if ! command -v gitleaks &> /dev/null; then
    echo "Error: gitleaks is not installed."
    echo "Install it with: brew install gitleaks"
    exit 1
fi

# Create pre-commit hook
cat > "$HOOKS_DIR/pre-commit" << 'EOF'
#!/bin/bash
# Votra pre-commit hook
# Bypass: SKIP=gitleaks git commit OR use --no-verify

set -euo pipefail

# Check for SKIP environment variable
if [[ "${SKIP:-}" == *"gitleaks"* ]]; then
    echo "Skipping gitleaks scan (SKIP=gitleaks)"
    exit 0
fi

# Run gitleaks on staged changes
echo "Running gitleaks secret scan..."
if ! gitleaks protect --staged --config=.gitleaks.toml --verbose; then
    echo ""
    echo "❌ Gitleaks found potential secrets in staged changes."
    echo ""
    echo "Options:"
    echo "  1. Remove the secrets from your code"
    echo "  2. Add to .gitleaks.toml allowlist if false positive"
    echo "  3. Bypass with: SKIP=gitleaks git commit"
    echo "  4. Bypass with: git commit --no-verify"
    echo ""
    exit 1
fi

echo "✅ No secrets detected"
EOF

chmod +x "$HOOKS_DIR/pre-commit"

echo "✅ Pre-commit hook installed successfully!"
echo ""
echo "The hook will scan for secrets before each commit."
echo "Bypass with: SKIP=gitleaks git commit OR git commit --no-verify"
