#!/usr/bin/env bash

set -euo pipefail

GITHUB_USER="onitenjikunezumi"
REPO_NAME="edge-tts-linux-browser"
BRANCH="main"

ZIP_URL="https://github.com/${GITHUB_USER}/${REPO_NAME}/archive/refs/heads/${BRANCH}.zip"
TMP_DIR="/tmp/edge-tts-linux-browser_install_$$"
ZIP_FILE="${TMP_DIR}/project.zip"

echo "=== Starting remote installer ==="

# Check for required commands (curl, unzip)
for cmd in curl unzip; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "Error: $cmd is not installed. Please install it and try again." >&2
        exit 1
    fi
done

# Create temporary directory and set up cleanup on exit
mkdir -p "$TMP_DIR"
cleanup() {
    echo "Cleaning up temporary files..."
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

# 1. Download the ZIP archive
echo "Downloading repository archive..."
curl -L "$ZIP_URL" -o "$ZIP_FILE"

# 2. Extract the ZIP archive
echo "Extracting files..."
unzip -q "$ZIP_FILE" -d "$TMP_DIR"

# Get the name of the extracted directory
EXTRACTED_DIR=$(find "$TMP_DIR" -maxdepth 1 -mindepth 1 -type d | head -n 1)

# 3. Execute the core installation script
if [ -f "${EXTRACTED_DIR}/setup.sh" ]; then
    echo "Running core installation script..."
    cd "$EXTRACTED_DIR"
    bash ./setup.sh
else
    echo "Error: core installation script (install-core.sh) not found." >&2
    exit 1
fi

