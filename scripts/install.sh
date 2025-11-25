#!/bin/bash
# Install Bazel binary on RISC-V
#
# Usage: ./install.sh [VERSION] [LOCATION]
#   VERSION: Bazel version to install (default: 6.5.0)
#   LOCATION: Install location - 'system' or 'user' (default: user)
#
# Examples:
#   ./install.sh 6.5.0 user      # Install to ~/.local/bin (no sudo)
#   ./install.sh 6.5.0 system    # Install to /usr/local/bin (requires sudo)

set -e

# Dependency check
echo "Checking dependencies..."
MISSING_DEPS=()

if ! command -v cp &> /dev/null; then
    MISSING_DEPS+=("coreutils")
fi

if ! command -v mkdir &> /dev/null; then
    MISSING_DEPS+=("coreutils")
fi

if [ ${#MISSING_DEPS[@]} -ne 0 ]; then
    echo "ERROR: Missing dependencies: ${MISSING_DEPS[*]}"
    echo ""
    echo "Install on Debian-like distros:"
    echo "  sudo apt update"
    echo "  sudo apt install -y coreutils"
    exit 1
fi

# Configuration
BAZEL_VERSION="${1:-6.5.0}"
LOCATION="${2:-user}"
WORK_DIR="${HOME}/bazel-build"
BUILD_DIR="${WORK_DIR}/bazel-${BAZEL_VERSION}"
BINARY="${BUILD_DIR}/output/bazel"

echo "=== Bazel RISC-V Installation Script ==="
echo "Version: ${BAZEL_VERSION}"
echo "Location: ${LOCATION}"
echo ""

# Check if binary exists
if [ ! -f "${BINARY}" ]; then
    echo "ERROR: Bazel binary not found at: ${BINARY}"
    echo ""
    echo "Build Bazel first:"
    echo "  ./scripts/build.sh ${BAZEL_VERSION}"
    exit 1
fi

# Verify binary
echo "Verifying binary..."
"${BINARY}" --version || {
    echo "ERROR: Binary verification failed"
    exit 1
}

# Install based on location
case "${LOCATION}" in
    system)
        echo "Installing to /usr/local/bin/ (requires sudo)..."
        sudo cp "${BINARY}" /usr/local/bin/bazel
        INSTALL_PATH="/usr/local/bin/bazel"
        ;;
    user)
        echo "Installing to ~/.local/bin/ (no sudo required)..."
        mkdir -p "${HOME}/.local/bin"
        cp "${BINARY}" "${HOME}/.local/bin/bazel"
        INSTALL_PATH="${HOME}/.local/bin/bazel"

        # Check if in PATH
        if [[ ":$PATH:" != *":${HOME}/.local/bin:"* ]]; then
            echo ""
            echo "WARNING: ~/.local/bin is not in your PATH"
            echo "Add to PATH by adding this to ~/.bashrc:"
            echo '  export PATH="$HOME/.local/bin:$PATH"'
            echo ""
            echo "Then reload:"
            echo "  source ~/.bashrc"
        fi
        ;;
    *)
        echo "ERROR: Invalid location '${LOCATION}'"
        echo "Must be 'system' or 'user'"
        exit 1
        ;;
esac

echo ""
echo "=== Installation Complete ==="
echo "Installed to: ${INSTALL_PATH}"
echo ""

# Verify installation
echo "Verifying installation..."
if command -v bazel &> /dev/null; then
    bazel --version
    echo ""
    echo "Installation successful!"
else
    echo "WARNING: 'bazel' command not found in PATH"
    echo "You may need to reload your shell or update PATH"
fi
