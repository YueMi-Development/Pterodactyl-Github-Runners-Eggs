#!/bin/bash
set -e

# Define directories
RUNNER_DIR="/home/container/actions-runner"
export HOME="/home/container"

# Copy runner files to writable workspace if not already present
if [ ! -d "${RUNNER_DIR}" ]; then
    echo "Copying runner files to writable workspace (${RUNNER_DIR})..."
    mkdir -p "${RUNNER_DIR}"
    cp -r /actions-runner/* "${RUNNER_DIR}/"
fi

cd "${RUNNER_DIR}"

# Export Pterodactyl environment variables
export RUNNER_NAME="${RUNNER_NAME:-pterodactyl-runner}"
export RUNNER_WORK_DIR="${RUNNER_WORK_DIR:-_work}"

# Determine runner scope and target URL
if [ -n "${RUNNER_REPOSITORY}" ]; then
    REG_URL="https://api.github.com/repos/${RUNNER_REPOSITORY#https://github.com/}/actions/runners/registration-token"
    CONFIG_URL="${RUNNER_REPOSITORY}"
elif [ -n "${RUNNER_ORGANIZATION}" ]; then
    # Clean org name if full URL was provided
    ORG_NAME="${RUNNER_ORGANIZATION#https://github.com/}"
    REG_URL="https://api.github.com/orgs/${ORG_NAME}/actions/runners/registration-token"
    CONFIG_URL="https://github.com/${ORG_NAME}"
else
    echo "ERROR: Either RUNNER_REPOSITORY or RUNNER_ORGANIZATION must be provided."
    exit 1
fi

# Obtain registration token if runner is not configured yet
if [ ! -f ".runner" ]; then
    if [ -z "${ACCESS_TOKEN}" ]; then
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        echo "ERROR: GitHub Access Token (ACCESS_TOKEN) is not set."
        echo "Please set your Personal Access Token (PAT) in Pterodactyl"
        echo "Panel under the Startup settings to register the runner."
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        exit 1
    fi

    echo "Obtaining runner registration token from GitHub..."
    
    RESPONSE=$(curl -sX POST \
        -H "Accept: application/vnd.github.v3+json" \
        -H "Authorization: token ${ACCESS_TOKEN}" \
        "${REG_URL}")
    
    REG_TOKEN=$(echo "${RESPONSE}" | grep -o '"token": "[^"]*' | grep -o '[^"]*$')

    if [ -z "${REG_TOKEN}" ]; then
        echo "ERROR: Failed to retrieve registration token from GitHub API."
        echo "API Response: ${RESPONSE}"
        exit 1
    fi

    echo "Configuring GitHub Actions Runner..."
    ./config.sh --unattended \
        --url "${CONFIG_URL}" \
        --token "${REG_TOKEN}" \
        --name "${RUNNER_NAME}" \
        --work "${RUNNER_WORK_DIR}" \
        ${LABELS:+--labels "${LABELS}"} \
        --replace
fi

# Start the runner
echo "Starting GitHub Actions Runner..."
START_TIME=$(date +%s)

# Run the runner and catch exit status
set +e
./run.sh
EXIT_CODE=$?
set -e

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

# If the runner exited in less than 15 seconds, configuration is likely invalid/deleted
if [ ${DURATION} -lt 15 ]; then
    echo "ERROR: Runner exited too quickly (${DURATION} seconds)."
    echo "Clearing local runner configuration to force a clean re-registration on next start..."
    rm -f .runner .credentials .credentials_rsaparams .path .env
fi

exit ${EXIT_CODE}


