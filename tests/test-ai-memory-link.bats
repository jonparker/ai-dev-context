#!/usr/bin/env bats
# Tests for ai-memory-link.sh

setup() {
    # Create a temporary directory for test files
    export TEST_DIR="$(mktemp -d)"
    export TEST_PROJECT="${TEST_DIR}/test-project"
    export TEST_HOME="${TEST_DIR}/home"
    export HOME="${TEST_HOME}"
    
    mkdir -p "${TEST_PROJECT}"
    mkdir -p "${HOME}/.config/ai/projects"
    mkdir -p "${HOME}/.claude/projects"
    
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

@test "ai-memory-link.sh exists and is executable" {
    [ -x "${BATS_TEST_DIRNAME}/../scripts/ai-memory-link.sh" ]
}

@test "ai-memory-link.sh creates central memory file" {
    cd "${TEST_PROJECT}"
    run "${BATS_TEST_DIRNAME}/../scripts/ai-memory-link.sh" .
    [ "$status" -eq 0 ]
    [ -f "${HOME}/.config/ai/projects/test-repo.md" ]
}

@test "ai-memory-link.sh creates symlink for Claude Code" {
    cd "${TEST_PROJECT}"
    run "${BATS_TEST_DIRNAME}/../scripts/ai-memory-link.sh" .
    [ "$status" -eq 0 ]
    
    # Check if symlink exists
    encoded_path=$(echo "${TEST_PROJECT}" | sed 's|/|-|g')
    symlink_path="${HOME}/.claude/projects/${encoded_path}/memory/MEMORY.md"
    [ -L "${symlink_path}" ]
}

@test "ai-memory-link.sh symlink points to central memory file" {
    cd "${TEST_PROJECT}"
    run "${BATS_TEST_DIRNAME}/../scripts/ai-memory-link.sh" .
    [ "$status" -eq 0 ]
    
    encoded_path=$(echo "${TEST_PROJECT}" | sed 's|/|-|g')
    symlink_path="${HOME}/.claude/projects/${encoded_path}/memory/MEMORY.md"
    central_path="${HOME}/.config/ai/projects/test-repo.md"
    
    [ "$(readlink ${symlink_path})" = "${central_path}" ]
}

@test "ai-memory-link.sh migrates existing Claude memory" {
    # Create existing Claude memory
    encoded_path=$(echo "${TEST_PROJECT}" | sed 's|/|-|g')
    memory_dir="${HOME}/.claude/projects/${encoded_path}/memory"
    mkdir -p "${memory_dir}"
    cat > "${memory_dir}/MEMORY.md" <<EOF
# Existing Memory
This should be migrated.
EOF

    cd "${TEST_PROJECT}"
    run "${BATS_TEST_DIRNAME}/../scripts/ai-memory-link.sh" .
    [ "$status" -eq 0 ]
    
    # Check migration happened
    central_path="${HOME}/.config/ai/projects/test-repo.md"
    grep -q "Existing Memory" "${central_path}"
}

@test "ai-memory-link.sh handles non-git directories" {
    cd "${TEST_DIR}"
    mkdir non-git-project
    cd non-git-project
    run "${BATS_TEST_DIRNAME}/../scripts/ai-memory-link.sh" .
    [ "$status" -eq 0 ]
    [ -f "${HOME}/.config/ai/projects/non-git-project.md" ]
}

@test "ai-memory-link.sh extracts repo name from git remote" {
    cd "${TEST_PROJECT}"
    git remote set-url origin https://github.com/user/my-awesome-repo.git
    run "${BATS_TEST_DIRNAME}/../scripts/ai-memory-link.sh" .
    [ "$status" -eq 0 ]
    [ -f "${HOME}/.config/ai/projects/my-awesome-repo.md" ]
}

@test "ai-memory-link.sh handles SSH git URLs" {
    cd "${TEST_PROJECT}"
    git remote set-url origin git@github.com:user/ssh-repo.git
    run "${BATS_TEST_DIRNAME}/../scripts/ai-memory-link.sh" .
    [ "$status" -eq 0 ]
    [ -f "${HOME}/.config/ai/projects/ssh-repo.md" ]
}

@test "ai-memory-link.sh doesn't overwrite existing central memory" {
    central_path="${HOME}/.config/ai/projects/test-repo.md"
    cat > "${central_path}" <<EOF
# Existing Central Memory
Don't overwrite this.
EOF

    cd "${TEST_PROJECT}"
    run "${BATS_TEST_DIRNAME}/../scripts/ai-memory-link.sh" .
    [ "$status" -eq 0 ]
    grep -q "Don't overwrite this" "${central_path}"
}

@test "ai-memory-link.sh backs up existing Claude memory file" {
    # Create existing Claude memory
    encoded_path=$(echo "${TEST_PROJECT}" | sed 's|/|-|g')
    memory_dir="${HOME}/.claude/projects/${encoded_path}/memory"
    mkdir -p "${memory_dir}"
    cat > "${memory_dir}/MEMORY.md" <<EOF
# Content to backup
EOF

    cd "${TEST_PROJECT}"
    run "${BATS_TEST_DIRNAME}/../scripts/ai-memory-link.sh" .
    [ "$status" -eq 0 ]
    
    # Check that backup was created (name includes date)
    backup_count=$(ls -1 "${memory_dir}"/MEMORY.md.bak.* 2>/dev/null | wc -l)
    [ "$backup_count" -gt 0 ]
}

@test "ai-memory-link.sh handles already correct symlink" {
    cd "${TEST_PROJECT}"
    # Run once
    "${BATS_TEST_DIRNAME}/../scripts/ai-memory-link.sh" .
    
    # Run again
    run "${BATS_TEST_DIRNAME}/../scripts/ai-memory-link.sh" .
    [ "$status" -eq 0 ]
    [[ "$output" =~ "unchanged" ]]
}

@test "ai-memory-link.sh creates empty memory file with header" {
    cd "${TEST_PROJECT}"
    run "${BATS_TEST_DIRNAME}/../scripts/ai-memory-link.sh" .
    [ "$status" -eq 0 ]
    
    central_path="${HOME}/.config/ai/projects/test-repo.md"
    grep -q "# Project Memory — test-repo" "${central_path}"
}
