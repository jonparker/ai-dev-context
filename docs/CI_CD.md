# CI/CD Pipeline Documentation

## Overview

This repository uses GitHub Actions for continuous integration and continuous delivery. The pipeline automatically validates code quality and functionality on every push and pull request.

## Workflows

### 1. Lint Workflow (`.github/workflows/lint.yml`)

**Purpose:** Ensures bash scripts follow best practices and syntax standards.

**Triggers:**
- Push to `main` branch
- Pull requests to `main`
- Changes to `scripts/**` or workflow file

**Jobs:**
- **ShellCheck**: Static analysis for bash scripts
  - Scans all scripts in `scripts/` directory
  - Severity level: warning
  - Excludes: SC1090, SC1091 (sourcing external files)
  
- **Syntax Check**: Validates bash syntax
  - Runs `bash -n` on all scripts
  - Catches syntax errors before execution

**Dependencies:**
- ShellCheck (via ludeeus/action-shellcheck@2.0.0)
- Bash

### 2. Test Workflow (`.github/workflows/test.yml`)

**Purpose:** Runs comprehensive automated tests to ensure scripts work correctly.

**Triggers:**
- Push to `main` branch
- Pull requests to `main`
- Changes to `scripts/**`, `tests/**`, or workflow file

**Jobs:**

#### a) BATS Tests
- **Runtime:** Ubuntu latest
- **Test framework:** BATS (Bash Automated Testing System)
- **Coverage:**
  - Unit tests for all three scripts
  - Edge cases and error conditions
  - Input validation
  - Output verification
  
**Test files:**
- `tests/test-ai-config-sync.bats` - 15+ tests
- `tests/test-ai-memory-link.bats` - 12+ tests
- `tests/test-review-memory-write.bats` - 10+ tests

#### b) Integration Tests
- **Purpose:** Validate scripts work end-to-end in a real environment
- **Tests:**
  - Full workflow of `ai-config-sync.sh` with all flags
  - Complete `ai-memory-link.sh` symlink creation
  - JSON parsing in `review-memory-write.sh`
  
**Verification:**
- File creation (configs, symlinks, backups)
- Content validation
- Git integration
- Cross-script compatibility

#### c) ShellCheck Verification
- Re-runs ShellCheck to ensure tests don't break linting
- Same configuration as lint workflow

#### d) Syntax Verification
- Re-validates bash syntax for all scripts
- Ensures no syntax regressions

## Dependencies

All workflows run on `ubuntu-latest` which includes:
- ✅ Bash 5.x
- ✅ Git 2.x
- ✅ Python 3.x
- ✅ diff (GNU diffutils)
- ✅ Standard UNIX tools (mktemp, sed, grep, etc.)

Additional installed:
- ✅ BATS (installed via apt in test workflow)
- ✅ ShellCheck (via GitHub Action)

## Local Testing

Before pushing, run tests locally:

```bash
# Run linting
shellcheck scripts/*.sh

# Run syntax check
bash -n scripts/*.sh

# Run tests (requires BATS)
cd tests
./run-tests.sh
```

## CI/CD Pipeline Flow

```
┌─────────────────┐
│   Push/PR       │
└────────┬────────┘
         │
    ┌────▼─────┐
    │  Lint    │──── ShellCheck
    │          │──── Syntax Check
    └────┬─────┘
         │
    ┌────▼─────┐
    │  Test    │──── BATS Unit Tests
    │          │──── Integration Tests
    │          │──── Verify Linting
    │          │──── Verify Syntax
    └────┬─────┘
         │
    ┌────▼─────┐
    │  Ready   │
    │ to Merge │
    └──────────┘
```

## Testing Philosophy

### What We Test

1. **Functionality**
   - All command-line flags work
   - Files are created with correct content
   - Symlinks point to the right places
   - Git operations work correctly

2. **Error Handling**
   - Missing required files
   - Invalid input
   - Non-git directories
   - Malformed JSON

3. **Edge Cases**
   - Empty files
   - Special characters in paths
   - Already-correct state (idempotency)
   - Parallel operations

4. **Integration**
   - Scripts work together
   - Real git repositories
   - Actual file system operations

### What We Don't Test (Yet)

- ❌ Performance at scale
- ❌ Interactive prompts (review script)
- ❌ MacOS-specific behavior
- ❌ Concurrent modifications
- ❌ Network operations

## Extending the Pipeline

### Adding New Tests

1. Create test file in `tests/`:
   ```bash
   tests/test-new-feature.bats
   ```

2. Follow BATS conventions:
   ```bash
   #!/usr/bin/env bats
   
   setup() {
       # Initialize test environment
   }
   
   teardown() {
       # Clean up
   }
   
   @test "descriptive name" {
       run command
       [ "$status" -eq 0 ]
   }
   ```

3. Tests automatically run in CI (no workflow changes needed)

### Adding New Jobs

Edit `.github/workflows/test.yml`:

```yaml
jobs:
  new-job:
    name: New Test Job
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run new test
        run: |
          # test commands
```

### Adding New Workflows

Create `.github/workflows/new-workflow.yml`:

```yaml
name: New Workflow

on:
  push:
    branches: [main]

jobs:
  job-name:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      # ... steps
```

## CI/CD Best Practices

### ✅ Do

- **Test locally first** - Run tests before pushing
- **Small commits** - Easier to debug CI failures
- **Clear commit messages** - Helps identify what broke
- **Fix broken builds immediately** - Don't let them accumulate
- **Add tests for bugs** - Prevent regressions

### ❌ Don't

- Skip tests to make CI pass
- Push directly to main without PR
- Ignore ShellCheck warnings
- Remove tests to fix failures
- Commit generated files

## Troubleshooting CI Failures

### Lint Failure

**Symptom:** ShellCheck reports warnings/errors

**Fix:**
```bash
# Run locally to see issues
shellcheck scripts/your-script.sh

# Fix reported issues or suppress with:
# shellcheck disable=SC####
```

### Test Failure

**Symptom:** BATS tests fail

**Fix:**
```bash
# Run specific test locally
cd tests
bats test-failing-test.bats

# Debug with verbose output
bats --verbose-run test-failing-test.bats
```

### Integration Failure

**Symptom:** Integration tests fail but unit tests pass

**Fix:**
- Check file paths (absolute vs relative)
- Verify git configuration
- Check environment variables
- Look for race conditions

### Syntax Error

**Symptom:** `bash -n` reports syntax error

**Fix:**
```bash
# Check syntax locally
bash -n scripts/your-script.sh

# Common issues:
# - Missing quotes
# - Unclosed brackets
# - Invalid variable expansion
```

## Monitoring

### GitHub Actions Status

View workflow runs:
```
https://github.com/jonparker/ai-dev-context/actions
```

### Status Badges

Add to README.md:
```markdown
![Lint](https://github.com/jonparker/ai-dev-context/workflows/Lint/badge.svg)
![Test](https://github.com/jonparker/ai-dev-context/workflows/Test/badge.svg)
```

## Future Enhancements

Potential CI/CD improvements:

1. **Code Coverage**
   - Track test coverage percentage
   - Require minimum coverage for PRs

2. **Performance Testing**
   - Benchmark script execution time
   - Alert on performance regressions

3. **Cross-Platform Testing**
   - Test on macOS runners
   - Test on different Ubuntu versions

4. **Release Automation**
   - Auto-create releases on version tags
   - Generate changelogs
   - Package scripts for distribution

5. **Documentation Testing**
   - Validate markdown links
   - Check code examples in docs
   - Verify documentation completeness

6. **Security Scanning**
   - Scan for secrets in code
   - Check for known vulnerabilities
   - Validate file permissions

## Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [BATS Testing Framework](https://github.com/bats-core/bats-core)
- [ShellCheck Wiki](https://github.com/koalaman/shellcheck/wiki)
- [Bash Best Practices](https://google.github.io/styleguide/shellguide.html)
