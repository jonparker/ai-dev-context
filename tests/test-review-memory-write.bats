#!/usr/bin/env bats
# Tests for review-memory-write.sh

setup() {
    # Create a temporary directory for test files
    export TEST_DIR="$(mktemp -d)"
    export TEST_HOME="${TEST_DIR}/home"
    export HOME="${TEST_HOME}"
    export TMPDIR="${TEST_DIR}/tmp"
    
    mkdir -p "${TMPDIR}"
    mkdir -p "${TEST_DIR}/project"
    
    export TEST_MEMORY="${TEST_DIR}/project/MEMORY.md"
}

teardown() {
    # Clean up temporary directory
    rm -rf "${TEST_DIR}"
}

@test "review-memory-write.sh exists and is executable" {
    [ -x "${BATS_TEST_DIRNAME}/../scripts/review-memory-write.sh" ]
}

@test "review-memory-write.sh exits 0 for non-MEMORY.md files" {
    input=$(cat <<EOF
{
  "hook_event_name": "PreToolUse",
  "tool_input": {
    "file_path": "${TEST_DIR}/some-other-file.md"
  }
}
EOF
)
    run bash -c "echo '${input}' | ${BATS_TEST_DIRNAME}/../scripts/review-memory-write.sh"
    [ "$status" -eq 0 ]
}

@test "review-memory-write.sh creates backup on PreToolUse" {
    # Create existing memory file
    echo "Original content" > "${TEST_MEMORY}"
    
    input=$(cat <<EOF
{
  "hook_event_name": "PreToolUse",
  "tool_input": {
    "file_path": "${TEST_MEMORY}"
  }
}
EOF
)
    run bash -c "echo '${input}' | ${BATS_TEST_DIRNAME}/../scripts/review-memory-write.sh"
    [ "$status" -eq 0 ]
    
    # Check backup was created
    backup_dir="${TMPDIR}/ai-memory-review"
    [ -d "${backup_dir}" ]
    
    # Find backup file
    backup_file=$(find "${backup_dir}" -name "*MEMORY.md.bak" | head -1)
    [ -f "${backup_file}" ]
    grep -q "Original content" "${backup_file}"
}

@test "review-memory-write.sh creates empty backup for new files" {
    input=$(cat <<EOF
{
  "hook_event_name": "PreToolUse",
  "tool_input": {
    "file_path": "${TEST_MEMORY}"
  }
}
EOF
)
    run bash -c "echo '${input}' | ${BATS_TEST_DIRNAME}/../scripts/review-memory-write.sh"
    [ "$status" -eq 0 ]
    
    backup_dir="${TMPDIR}/ai-memory-review"
    backup_file=$(find "${backup_dir}" -name "*MEMORY.md.bak" | head -1)
    [ -f "${backup_file}" ]
    [ ! -s "${backup_file}" ]  # File should be empty
}

@test "review-memory-write.sh requires python3 for JSON parsing" {
    command -v python3 >/dev/null 2>&1 || skip "python3 not available"
    
    input='{"hook_event_name": "PreToolUse", "tool_input": {"file_path": "test.md"}}'
    run bash -c "echo '${input}' | ${BATS_TEST_DIRNAME}/../scripts/review-memory-write.sh"
    [ "$status" -eq 0 ]
}

@test "review-memory-write.sh handles malformed JSON gracefully" {
    input='not valid json'
    run bash -c "echo '${input}' | ${BATS_TEST_DIRNAME}/../scripts/review-memory-write.sh"
    # Script should not crash even with bad input
    [ "$status" -eq 0 ]
}

@test "review-memory-write.sh PostToolUse without TTY exits cleanly" {
    echo "Original content" > "${TEST_MEMORY}"
    
    # First create backup with PreToolUse
    pre_input=$(cat <<EOF
{
  "hook_event_name": "PreToolUse",
  "tool_input": {
    "file_path": "${TEST_MEMORY}"
  }
}
EOF
)
    bash -c "echo '${pre_input}' | ${BATS_TEST_DIRNAME}/../scripts/review-memory-write.sh"
    
    # Modify file
    echo "New content" > "${TEST_MEMORY}"
    
    # PostToolUse without TTY should auto-approve
    # Close stdin and redirect /dev/tty to prevent hanging
    post_input=$(cat <<EOF
{
  "hook_event_name": "PostToolUse",
  "tool_input": {
    "file_path": "${TEST_MEMORY}"
  }
}
EOF
)
    run bash -c "echo '${post_input}' | ${BATS_TEST_DIRNAME}/../scripts/review-memory-write.sh </dev/null"
    [ "$status" -eq 0 ]
}

@test "review-memory-write.sh parses nested JSON correctly" {
    input=$(cat <<EOF
{
  "hook_event_name": "PreToolUse",
  "tool_input": {
    "file_path": "${TEST_MEMORY}",
    "other_field": "ignored"
  }
}
EOF
)
    run bash -c "echo '${input}' | ${BATS_TEST_DIRNAME}/../scripts/review-memory-write.sh"
    [ "$status" -eq 0 ]
}

@test "review-memory-write.sh handles paths with special characters" {
    special_path="${TEST_DIR}/path with spaces/MEMORY.md"
    mkdir -p "$(dirname "${special_path}")"
    echo "content" > "${special_path}"
    
    input=$(cat <<EOF
{
  "hook_event_name": "PreToolUse",
  "tool_input": {
    "file_path": "${special_path}"
  }
}
EOF
)
    run bash -c "echo '${input}' | ${BATS_TEST_DIRNAME}/../scripts/review-memory-write.sh"
    [ "$status" -eq 0 ]
}
