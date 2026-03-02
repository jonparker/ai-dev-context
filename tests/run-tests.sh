#!/usr/bin/env bash
# Run all BATS tests
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if bats is installed
if ! command -v bats &> /dev/null; then
    echo "Error: bats is not installed" >&2
    echo "" >&2
    echo "Install bats-core with one of:" >&2
    echo "  brew install bats-core                    # macOS" >&2
    echo "  apt-get install bats                      # Debian/Ubuntu" >&2
    echo "  npm install -g bats                       # npm" >&2
    echo "" >&2
    echo "Or install from source:" >&2
    echo "  git clone https://github.com/bats-core/bats-core.git" >&2
    echo "  cd bats-core && ./install.sh /usr/local" >&2
    exit 1
fi

echo "Running tests with BATS..."
echo ""

# Run all test files
bats "${SCRIPT_DIR}"/test-*.bats

echo ""
echo "All tests completed!"
