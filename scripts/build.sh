#!/bin/bash
# Build Bazel from source on RISC-V
#
# Usage: ./build.sh [VERSION]
#   VERSION: Bazel version to build (default: 6.5.0)
#
# Example:
#   ./build.sh 6.5.0
#   ./build.sh 7.4.1

set -e

# Dependency check
echo "Checking dependencies..."
MISSING_DEPS=()

if ! command -v wget &> /dev/null; then
    MISSING_DEPS+=("wget")
fi

if ! command -v unzip &> /dev/null; then
    MISSING_DEPS+=("unzip")
fi

if ! command -v java &> /dev/null; then
    MISSING_DEPS+=("openjdk-21-jdk")
fi

if ! command -v gcc &> /dev/null; then
    MISSING_DEPS+=("build-essential")
fi

if ! command -v python3 &> /dev/null; then
    MISSING_DEPS+=("python3")
fi

if [ ${#MISSING_DEPS[@]} -ne 0 ]; then
    echo "ERROR: Missing dependencies: ${MISSING_DEPS[*]}"
    echo ""
    echo "Install on Debian-like distros:"
    echo "  sudo apt update"
    echo "  sudo apt install -y build-essential openjdk-21-jdk zip unzip python3 wget"
    exit 1
fi

# Configuration
BAZEL_VERSION="${1:-6.5.0}"
WORK_DIR="${HOME}/bazel-build"
BUILD_DIR="${WORK_DIR}/bazel-${BAZEL_VERSION}"

echo "=== Bazel RISC-V Build Script ==="
echo "Version: ${BAZEL_VERSION}"
echo "Work directory: ${WORK_DIR}"
echo ""

# Check system resources
echo "System resources:"
echo "  CPU cores: $(nproc)"
echo "  RAM: $(free -h | grep Mem | awk '{print $2}')"
echo "  Free RAM: $(free -h | grep Mem | awk '{print $7}')"
echo ""

# Warn if low memory
AVAILABLE_MB=$(free -m | grep Mem | awk '{print $7}')
if [ "${AVAILABLE_MB}" -lt 8000 ]; then
    echo "WARNING: Less than 8GB RAM available. Build may fail or be slow."
    echo "Consider closing other applications or adding swap space."
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Create work directory
mkdir -p "${WORK_DIR}"
cd "${WORK_DIR}"

# Download source
if [ ! -f "bazel-${BAZEL_VERSION}-dist.zip" ]; then
    echo "Downloading Bazel ${BAZEL_VERSION} source..."
    wget "https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-dist.zip"
else
    echo "Using existing download: bazel-${BAZEL_VERSION}-dist.zip"
fi

# Extract source
if [ ! -d "${BUILD_DIR}" ]; then
    echo "Extracting source..."
    unzip -q "bazel-${BAZEL_VERSION}-dist.zip" -d "${BUILD_DIR}"
else
    echo "Using existing build directory: ${BUILD_DIR}"
fi

# Apply patches if they exist
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATCHES_DIR="${SCRIPT_DIR}/../patches"
if [ -d "${PATCHES_DIR}" ]; then
    for patch in "${PATCHES_DIR}/${BAZEL_VERSION}"-*.patch; do
        if [ -f "$patch" ]; then
            echo "Applying patch: $(basename "$patch")"
            cd "${BUILD_DIR}"
            patch -p1 < "$patch" || {
                echo "WARNING: Patch $(basename "$patch") failed to apply cleanly"
                echo "Continuing anyway..."
            }
        fi
    done
fi

# Build
cd "${BUILD_DIR}"
echo ""
echo "Starting bootstrap build..."
echo "This will take 30-60 minutes on 8-core RISC-V with 16GB RAM"
echo ""

START_TIME=$(date +%s)

# Use appropriate build flags based on version
case "${BAZEL_VERSION}" in
    6.*)
        # Bazel 6.x uses older flag syntax
        env EXTRA_BAZEL_ARGS="--host_javabase=@local_jdk//:jdk" ./compile.sh
        ;;
    *)
        # Bazel 7.x and later use modern flag syntax
        env EXTRA_BAZEL_ARGS="--tool_java_runtime_version=local_jdk --java_runtime_version=local_jdk" ./compile.sh
        ;;
esac

END_TIME=$(date +%s)
BUILD_TIME=$((END_TIME - START_TIME))
BUILD_MINUTES=$((BUILD_TIME / 60))

echo ""
echo "=== Build Complete ==="
echo "Build time: ${BUILD_MINUTES} minutes"
echo "Binary location: ${BUILD_DIR}/output/bazel"
echo ""

# Verify build
echo "Verifying build..."
./output/bazel --version
./output/bazel version

echo ""
echo "Build successful! Next steps:"
echo "  1. Test: ./scripts/test.sh ${BAZEL_VERSION}"
echo "  2. Install: ./scripts/install.sh ${BAZEL_VERSION}"
