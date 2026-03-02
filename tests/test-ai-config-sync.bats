#!/usr/bin/env bats
# Tests for ai-config-sync.sh

setup() {
    # Create a temporary directory for test files
    export TEST_DIR="$(mktemp -d)"
    export TEST_PROJECT="${TEST_DIR}/test-project"
    export TEST_HOME="${TEST_DIR}/home"
    export HOME="${TEST_HOME}"
    
    mkdir -p "${TEST_PROJECT}"
    mkdir -p "${HOME}/.config/ai"
    
    # Create a minimal context file
    cat > "${HOME}/.config/ai/context.md" <<EOF
# Global Context
Machine: Test Machine
EOF
    
    # Initialize git repo
    cd "${TEST_PROJECT}"
    git init
    git config user.email "test@example.com"
    git config user.name "Test User"
    git remote add origin https://github.com/test/test-repo.git
}

teardown() {
    # Clean up temporary directory
    rm -rf "${TEST_DIR}"
}

@test "ai-config-sync.sh exists and is executable" {
    [ -x "${BATS_TEST_DIRNAME}/../scripts/ai-config-sync.sh" ]
}

@test "ai-config-sync.sh --help shows usage" {
    run "${BATS_TEST_DIRNAME}/../scripts/ai-config-sync.sh" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
}

@test "ai-config-sync.sh creates .claude/CLAUDE.md by default" {
    cd "${TEST_PROJECT}"
    run "${BATS_TEST_DIRNAME}/../scripts/ai-config-sync.sh" .
    [ "$status" -eq 0 ]
    [ -f "${TEST_PROJECT}/.claude/CLAUDE.md" ]
    [[ "$(cat ${TEST_PROJECT}/.claude/CLAUDE.md)" =~ "Claude Code" ]]
}

@test "ai-config-sync.sh with --cursor creates .cursorrules" {
    cd "${TEST_PROJECT}"
    run "${BATS_TEST_DIRNAME}/../scripts/ai-config-sync.sh" --cursor .
    [ "$status" -eq 0 ]
    [ -f "${TEST_PROJECT}/.cursorrules" ]
    [[ "$(cat ${TEST_PROJECT}/.cursorrules)" =~ "Cursor Rules" ]]
}

@test "ai-config-sync.sh with --windsurf creates .windsurfrules" {
    cd "${TEST_PROJECT}"
    run "${BATS_TEST_DIRNAME}/../scripts/ai-config-sync.sh" --windsurf .
    [ "$status" -eq 0 ]
    [ -f "${TEST_PROJECT}/.windsurfrules" ]
    [[ "$(cat ${TEST_PROJECT}/.windsurfrules)" =~ "Windsurf Rules" ]]
}

@test "ai-config-sync.sh with --cline creates .clinerules" {
    cd "${TEST_PROJECT}"
    run "${BATS_TEST_DIRNAME}/../scripts/ai-config-sync.sh" --cline .
    [ "$status" -eq 0 ]
    [ -f "${TEST_PROJECT}/.clinerules" ]
    [[ "$(cat ${TEST_PROJECT}/.clinerules)" =~ "Cline Rules" ]]
}

@test "ai-config-sync.sh with --copilot creates .github/copilot-instructions.md" {
    cd "${TEST_PROJECT}"
    run "${BATS_TEST_DIRNAME}/../scripts/ai-config-sync.sh" --copilot .
    [ "$status" -eq 0 ]
    [ -f "${TEST_PROJECT}/.github/copilot-instructions.md" ]
    [[ "$(cat ${TEST_PROJECT}/.github/copilot-instructions.md)" =~ "GitHub Copilot" ]]
}

@test "ai-config-sync.sh with --codex creates AGENTS.md" {
    cd "${TEST_PROJECT}"
    run "${BATS_TEST_DIRNAME}/../scripts/ai-config-sync.sh" --codex .
    [ "$status" -eq 0 ]
    [ -f "${TEST_PROJECT}/AGENTS.md" ]
    [[ "$(cat ${TEST_PROJECT}/AGENTS.md)" =~ "Codex Agent" ]]
}

@test "ai-config-sync.sh with --all creates all config files" {
    cd "${TEST_PROJECT}"
    run "${BATS_TEST_DIRNAME}/../scripts/ai-config-sync.sh" --all .
    [ "$status" -eq 0 ]
    [ -f "${TEST_PROJECT}/.claude/CLAUDE.md" ]
    [ -f "${TEST_PROJECT}/.cursorrules" ]
    [ -f "${TEST_PROJECT}/.windsurfrules" ]
    [ -f "${TEST_PROJECT}/.clinerules" ]
    [ -f "${TEST_PROJECT}/.github/copilot-instructions.md" ]
    [ -f "${TEST_PROJECT}/AGENTS.md" ]
}

@test "ai-config-sync.sh updates .gitignore with AI config entries" {
    cd "${TEST_PROJECT}"
    touch .gitignore
    run "${BATS_TEST_DIRNAME}/../scripts/ai-config-sync.sh" --all .
    [ "$status" -eq 0 ]
    [ -f "${TEST_PROJECT}/.gitignore" ]
    grep -q ".claude/" "${TEST_PROJECT}/.gitignore"
    grep -q ".cursorrules" "${TEST_PROJECT}/.gitignore"
}

@test "ai-config-sync.sh includes project memory when available" {
    cd "${TEST_PROJECT}"
    mkdir -p "${HOME}/.config/ai/projects"
    cat > "${HOME}/.config/ai/projects/test-repo.md" <<EOF
# Test Project Memory
This is test memory.
EOF
    run "${BATS_TEST_DIRNAME}/../scripts/ai-config-sync.sh" --cursor .
    [ "$status" -eq 0 ]
    grep -q "Test Project Memory" "${TEST_PROJECT}/.cursorrules"
}

@test "ai-config-sync.sh fails gracefully without context.md" {
    rm "${HOME}/.config/ai/context.md"
    cd "${TEST_PROJECT}"
    run "${BATS_TEST_DIRNAME}/../scripts/ai-config-sync.sh" .
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Canonical context not found" ]]
}

@test "ai-config-sync.sh handles non-git directories" {
    cd "${TEST_DIR}"
    mkdir non-git-project
    cd non-git-project
    run "${BATS_TEST_DIRNAME}/../scripts/ai-config-sync.sh" .
    [ "$status" -eq 0 ]
    [ -f ".claude/CLAUDE.md" ]
}

@test "ai-config-sync.sh includes project-specific notes when available" {
    cd "${TEST_PROJECT}"
    mkdir -p .ai
    cat > .ai/project.md <<EOF
Project-specific rule: Always test first
EOF
    run "${BATS_TEST_DIRNAME}/../scripts/ai-config-sync.sh" .
    [ "$status" -eq 0 ]
    grep -q "Project-specific rule" "${TEST_PROJECT}/.claude/CLAUDE.md"
}

@test "ai-config-sync.sh doesn't update unchanged files" {
    cd "${TEST_PROJECT}"
    "${BATS_TEST_DIRNAME}/../scripts/ai-config-sync.sh" .
    # Get modification time
    touch -t 202001010000 "${TEST_PROJECT}/.claude/CLAUDE.md"
    orig_time=$(stat -c %Y "${TEST_PROJECT}/.claude/CLAUDE.md" 2>/dev/null || stat -f %m "${TEST_PROJECT}/.claude/CLAUDE.md")
    
    # Run again
    run "${BATS_TEST_DIRNAME}/../scripts/ai-config-sync.sh" .
    [ "$status" -eq 0 ]
    [[ "$output" =~ "unchanged" ]]
}
