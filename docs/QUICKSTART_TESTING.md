# Quick Start: CI/CD and Testing

## For Developers

### Running Tests Locally

```bash
# Install BATS (one time setup)
brew install bats-core              # macOS
# OR
sudo apt-get install bats           # Ubuntu/Debian

# Clone the repo
git clone https://github.com/jonparker/ai-dev-context.git
cd ai-dev-context

# Run all tests
cd tests
./run-tests.sh

# Run specific test file
bats test-ai-config-sync.bats
```

### Before Submitting a PR

```bash
# 1. Lint your changes
shellcheck scripts/*.sh

# 2. Check syntax
bash -n scripts/*.sh

# 3. Run tests
cd tests && ./run-tests.sh

# 4. If all pass, commit and push
git add .
git commit -m "Your changes"
git push
```

## For Contributors

### Adding New Tests

1. Create test file in `tests/`:
   ```bash
   tests/test-new-feature.bats
   ```

2. Use this template:
   ```bash
   #!/usr/bin/env bats
   
   setup() {
       export TEST_DIR="$(mktemp -d)"
       # ... setup code
   }
   
   teardown() {
       rm -rf "${TEST_DIR}"
   }
   
   @test "feature does something" {
       run your-command
       [ "$status" -eq 0 ]
       [[ "$output" =~ "expected" ]]
   }
   ```

3. Run your test:
   ```bash
   bats tests/test-new-feature.bats
   ```

### Understanding CI Results

When you push or create a PR, GitHub Actions runs:

1. **Lint** workflow
   - ShellCheck: catches common bash mistakes
   - Syntax check: verifies bash syntax
   
2. **Test** workflow
   - BATS tests: runs all 36+ tests
   - Integration tests: end-to-end validation
   - Re-verifies linting and syntax

**Status badges** (add these to PRs):
- ✅ Green check = All tests passed
- ❌ Red X = Tests failed (click to see why)

## For Users

### What Gets Tested Automatically

Every time code is pushed to this repo:

✅ **Script Quality**
- ShellCheck finds bugs and bad practices
- Syntax validation catches errors

✅ **Functionality**
- All command-line options work
- Files are created correctly
- Error handling works
- Edge cases are handled

✅ **Integration**
- Scripts work together
- Git operations succeed
- Real file system operations

### What This Means For You

- **More reliable scripts** - bugs caught before release
- **Faster fixes** - tests help identify issues quickly
- **Documentation stays current** - tests verify docs match behavior
- **Confidence in updates** - changes are validated automatically

## Common Issues

### Test Failure: "bats: command not found"

**Fix:** Install BATS
```bash
brew install bats-core  # macOS
# or
sudo apt-get install bats  # Linux
```

### Test Failure: "Permission denied"

**Fix:** Make scripts executable
```bash
chmod +x scripts/*.sh
chmod +x tests/*.sh
```

### CI Failure: ShellCheck warnings

**Fix:** Run locally and fix issues
```bash
shellcheck scripts/your-script.sh
# Fix reported issues
```

### CI Failure: Tests timeout

**Fix:** Check for:
- Infinite loops
- Waiting for input without timeout
- Missing cleanup in teardown()

## Resources

- [Full CI/CD docs](CI_CD.md)
- [Test documentation](../tests/README.md)
- [BATS documentation](https://github.com/bats-core/bats-core)
- [ShellCheck wiki](https://github.com/koalaman/shellcheck/wiki)

## Quick Reference

| Task | Command |
|------|---------|
| Install BATS (macOS) | `brew install bats-core` |
| Install BATS (Linux) | `sudo apt-get install bats` |
| Run all tests | `cd tests && ./run-tests.sh` |
| Run one test file | `bats test-file.bats` |
| Run specific test | `bats --filter "test name" test-file.bats` |
| Lint scripts | `shellcheck scripts/*.sh` |
| Check syntax | `bash -n scripts/*.sh` |
| View CI results | Go to GitHub Actions tab |
