# Testing Documentation

## Overview

This directory contains automated tests for the `ai-dev-context` scripts using [BATS (Bash Automated Testing System)](https://github.com/bats-core/bats-core).

## Test Coverage

### test-ai-config-sync.bats

Tests for `scripts/ai-config-sync.sh`:
- ✅ Command line argument parsing (--help, --cursor, --windsurf, etc.)
- ✅ Default behavior (creates .claude/CLAUDE.md)
- ✅ All tool-specific config generation
- ✅ .gitignore updates
- ✅ Project memory integration
- ✅ Project-specific notes inclusion
- ✅ Error handling (missing context.md)
- ✅ Git and non-git directory handling
- ✅ Idempotency (unchanged files)

### test-ai-memory-link.bats

Tests for `scripts/ai-memory-link.sh`:
- ✅ Central memory file creation
- ✅ Claude Code symlink creation
- ✅ Symlink target validation
- ✅ Migration of existing Claude memory
- ✅ Git remote URL parsing (HTTPS and SSH)
- ✅ Non-git directory handling
- ✅ Backup of existing files
- ✅ Idempotency (already correct symlinks)
- ✅ Empty memory file with proper header

### test-review-memory-write.bats

Tests for `scripts/review-memory-write.sh`:
- ✅ File filtering (only acts on MEMORY.md)
- ✅ PreToolUse backup creation
- ✅ Empty backup for new files
- ✅ JSON parsing with python3
- ✅ Malformed JSON handling
- ✅ Non-interactive mode (no TTY)
- ✅ Nested JSON parsing
- ✅ Special characters in paths

## Running Tests Locally

### Prerequisites

Install BATS:

**macOS:**
```bash
brew install bats-core
```

**Ubuntu/Debian:**
```bash
sudo apt-get install bats
```

**From source:**
```bash
git clone https://github.com/bats-core/bats-core.git
cd bats-core
sudo ./install.sh /usr/local
```

### Run All Tests

```bash
cd tests
./run-tests.sh
```

### Run Individual Test Files

```bash
bats test-ai-config-sync.bats
bats test-ai-memory-link.bats
bats test-review-memory-write.bats
```

### Run Specific Tests

```bash
# Run tests matching a pattern
bats --filter "ai-config-sync" test-ai-config-sync.bats

# Run with verbose output
bats --tap test-ai-config-sync.bats
```

## CI/CD Integration

Tests run automatically in GitHub Actions on:
- Every push to `main` branch
- Every pull request
- Changes to scripts or test files

See `.github/workflows/test.yml` for CI configuration.

## Test Structure

Each test file follows this pattern:

```bash
#!/usr/bin/env bats

setup() {
    # Create isolated test environment
    # Set up temporary directories
    # Initialize test fixtures
}

teardown() {
    # Clean up test environment
    # Remove temporary files
}

@test "descriptive test name" {
    # Arrange: set up test conditions
    # Act: run the command being tested
    # Assert: verify expected outcomes
}
```

## Writing New Tests

When adding new features or fixing bugs:

1. **Add a test first** (TDD approach)
2. **Use descriptive test names** that explain what is being tested
3. **Isolate tests** - each test should be independent
4. **Clean up** - always clean up in teardown()
5. **Test edge cases** - empty inputs, special characters, errors

### Example Test

```bash
@test "script handles missing required file" {
    # Remove required file
    rm "${HOME}/.config/ai/context.md"
    
    # Run script and expect failure
    run "${SCRIPT_PATH}" .
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Error" ]]
}
```

## Dependencies

Tests require:
- bash (POSIX-compatible)
- git
- python3 (for review-memory-write.sh tests)
- diff (standard on Linux/macOS)
- mktemp (for temporary directories)

All dependencies are available in the GitHub Actions Ubuntu runner environment.

## Debugging Tests

To see detailed output:

```bash
# Run with verbose output
bats --verbose-run test-ai-config-sync.bats

# Run with tap output
bats --tap test-ai-config-sync.bats

# Run specific test
bats --filter "creates .claude" test-ai-config-sync.bats
```

To debug a specific test:
1. Add `echo` statements in your test
2. Use `run` to capture command output
3. Check `$status` for exit code
4. Check `$output` for command output

## Test Coverage Goals

- ✅ All command-line options
- ✅ All major code paths
- ✅ Error conditions
- ✅ Edge cases
- ✅ Integration between scripts
- 🔄 Performance tests (future)
- 🔄 Stress tests (future)
