#!/bin/bash
set -e

# Clean up job workspace in ephemeral mode to prevent storage bloat
echo "Cleaning up workspace..."

# Clean the _work tree (repo checkouts, job artifacts)
rm -rf "${RUNNER_WORK_DIR}" && mkdir -p "${RUNNER_WORK_DIR}"

# Clean temp files
rm -rf "${RUNNER_TEMP}" && mkdir -p "${RUNNER_TEMP}"

# Optionally clear tool cache (slows first job after restart):
# rm -rf "${RUNNER_TOOL_CACHE}" && mkdir -p "${RUNNER_TOOL_CACHE}"

echo "Workspace cleanup complete."
