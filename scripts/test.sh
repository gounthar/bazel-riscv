#!/bin/bash
# Test Bazel binary on RISC-V
#
# Usage: ./test.sh [VERSION]
#   VERSION: Bazel version to test (default: 6.5.0)
#
# Example:
#   ./test.sh 6.5.0

set -e

# Dependency check
echo "Checking dependencies..."
MISSING_DEPS=()

if ! command -v mktemp &> /dev/null; then
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
WORK_DIR="${HOME}/bazel-build"
BUILD_DIR="${WORK_DIR}/bazel-${BAZEL_VERSION}"
BINARY="${BUILD_DIR}/output/bazel"

echo "=== Bazel RISC-V Test Script ==="
echo "Version: ${BAZEL_VERSION}"
echo ""

# Check if binary exists
if [ ! -f "${BINARY}" ]; then
    echo "ERROR: Bazel binary not found at: ${BINARY}"
    echo ""
    echo "Build Bazel first:"
    echo "  ./scripts/build.sh ${BAZEL_VERSION}"
    exit 1
fi

# Test 1: Version check
echo "Test 1: Version check"
"${BINARY}" --version || {
    echo "FAILED: Version check failed"
    exit 1
}
echo "PASSED"
echo ""

# Test 2: Detailed version
echo "Test 2: Detailed version"
"${BINARY}" version || {
    echo "FAILED: Detailed version failed"
    exit 1
}
echo "PASSED"
echo ""

# Test 3: Help command
echo "Test 3: Help command"
"${BINARY}" help > /dev/null 2>&1 || {
    echo "FAILED: Help command failed"
    exit 1
}
echo "PASSED"
echo ""

# Test 4: Simple build test
echo "Test 4: Simple build test"
TEST_DIR=$(mktemp -d)
cd "${TEST_DIR}"

# Create WORKSPACE
cat > WORKSPACE << 'EOF'
# Empty workspace
EOF

# Create BUILD file
cat > BUILD << 'EOF'
genrule(
    name = "hello",
    outs = ["hello.txt"],
    cmd = "echo 'Hello from Bazel on RISC-V!' > $@",
)
EOF

# Run build
echo "Building simple target..."
"${BINARY}" build //:hello || {
    echo "FAILED: Simple build failed"
    rm -rf "${TEST_DIR}"
    exit 1
}

# Verify output
if [ ! -f "bazel-bin/hello.txt" ]; then
    echo "FAILED: Output file not created"
    rm -rf "${TEST_DIR}"
    exit 1
fi

CONTENT=$(cat bazel-bin/hello.txt)
if [ "${CONTENT}" != "Hello from Bazel on RISC-V!" ]; then
    echo "FAILED: Unexpected output content"
    rm -rf "${TEST_DIR}"
    exit 1
fi

echo "PASSED"
echo ""

# Cleanup
cd ~
rm -rf "${TEST_DIR}"

# Test 5: Info command
echo "Test 5: Info command"
cd "${BUILD_DIR}"
"${BINARY}" info > /dev/null 2>&1 || {
    echo "FAILED: Info command failed"
    exit 1
}
echo "PASSED"
echo ""

# All tests passed
echo "=== All Tests Passed ==="
echo "Bazel ${BAZEL_VERSION} is working correctly on RISC-V!"
echo ""
echo "Next step: Install with ./scripts/install.sh ${BAZEL_VERSION}"
