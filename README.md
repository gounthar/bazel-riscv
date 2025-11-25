# Bazel for RISC-V

Building Bazel from source for RISC-V architecture with automated CI/CD.

## Purpose

Bazel is a build system required for building IntelliJ IDEA and other JetBrains IDEs from source. Official Bazel releases don't include RISC-V binaries, and Bazelisk (the version manager) doesn't support RISC-V architecture.

This repository:
- Documents the process of building Bazel from source on RISC-V
- Provides automated CI/CD for building Bazel releases
- Publishes RISC-V binary releases for the community

## Current Status

**Discovery**: Bazelisk does NOT support RISC-V (as of 2025-11-25)

**Community success**: Bazel 6.5.0 successfully built on RISC-V in July 2024

**Our goal**: Automate builds and provide pre-built binaries

## Hardware

**Primary build machine**: Banana Pi F3 16GB
- CPU: SpacemiT K1 8-core RISC-V @ 2GHz
- RAM: 16GB LPDDR4 (exceeds 8GB requirement)
- OS: Debian RISC-V

**GitHub Runner**: Self-hosted at `/mnt/c/support/users/dev/riscv/docker/docker-dev`

## Quick Start

### Prerequisites

```bash
sudo apt update
sudo apt install build-essential openjdk-21-jdk zip unzip python3 git
```

### Build Bazel 6.5.0 (Verified Working)

```bash
# Download distribution archive
wget https://github.com/bazelbuild/bazel/releases/download/6.5.0/bazel-6.5.0-dist.zip
unzip bazel-6.5.0-dist.zip -d bazel-6.5.0
cd bazel-6.5.0

# Bootstrap build (requires ~8GB RAM, ~30-60 min on 8-core)
env EXTRA_BAZEL_ARGS="--host_javabase=@local_jdk//:jdk" ./compile.sh

# Install
sudo cp output/bazel /usr/local/bin/
bazel --version
```

## Problem: Bazelisk Doesn't Support RISC-V

**Bazelisk** is the official Bazel version manager that auto-downloads Bazel binaries.

**What we tried**:
```bash
git clone https://github.com/bazelbuild/bazelisk.git
cd bazelisk
go build
sudo mv bazelisk /usr/local/bin/bazel
bazel --version
```

**Error**:
```
2025/11/25 22:36:17 could not download Bazel: could not determine path segment
to use for Bazel binary: unsupported machine architecture "riscv64",
must be arm64 or x86_64
```

**Why**: Bazelisk only downloads pre-built binaries for arm64/x86_64. No RISC-V builds in official releases.

## Solution: Build from Source

### Tested Versions

| Version | Status | Date Tested | Notes |
|---------|--------|-------------|-------|
| 6.5.0 | ✅ Works | 2024-07 | Community verified |
| 7.4.1 | ⚠️ Untested | - | Latest release |

### Build Process

The build uses **bootstrapping**: Bazel builds itself using a minimal Java-based build system.

**Build steps**:
1. Download `-dist.zip` archive (contains all sources)
2. Run `compile.sh` (bootstrap build script)
3. Output binary created in `output/bazel`
4. Install to `/usr/local/bin/`

**Requirements**:
- JDK 21 (we use Eclipse Temurin)
- ~8GB RAM minimum (F3 has 16GB)
- ~2GB disk space
- Build tools: gcc, g++, zip, unzip, python3

**Build time**: 30-60 minutes on Banana Pi F3 (8-core)

## CI/CD Plan

### GitHub Actions Workflow

Using our self-hosted RISC-V runner:

```yaml
name: Build Bazel

on:
  workflow_dispatch:
    inputs:
      bazel_version:
        description: 'Bazel version to build'
        required: true
        default: '6.5.0'

jobs:
  build:
    runs-on: [self-hosted, riscv64]

    steps:
      - name: Install dependencies
        run: |
          sudo apt update
          sudo apt install -y build-essential openjdk-21-jdk zip unzip python3

      - name: Download Bazel source
        run: |
          wget https://github.com/bazelbuild/bazel/releases/download/${{ inputs.bazel_version }}/bazel-${{ inputs.bazel_version }}-dist.zip
          unzip bazel-${{ inputs.bazel_version }}-dist.zip -d bazel-build

      - name: Build Bazel
        run: |
          cd bazel-build
          env EXTRA_BAZEL_ARGS="--host_javabase=@local_jdk//:jdk" ./compile.sh

      - name: Create release artifact
        run: |
          cd bazel-build
          tar czf bazel-${{ inputs.bazel_version }}-linux-riscv64.tar.gz -C output bazel

      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: bazel-${{ inputs.bazel_version }}-linux-riscv64
          path: bazel-build/bazel-${{ inputs.bazel_version }}-linux-riscv64.tar.gz

      - name: Create GitHub Release
        uses: softprops/action-gh-release@v1
        with:
          tag_name: v${{ inputs.bazel_version }}
          files: bazel-build/bazel-${{ inputs.bazel_version }}-linux-riscv64.tar.gz
```

### Release Strategy

1. **Manual trigger** via workflow_dispatch (choose version)
2. **Build on self-hosted** RISC-V runner (Banana Pi F3)
3. **Create release** with binary artifact
4. **Tag format**: `v{version}` (e.g., `v6.5.0`)

### Automated Testing

```yaml
- name: Test Bazel binary
  run: |
    cd bazel-build
    ./output/bazel --version
    ./output/bazel version
```

## Directory Structure

```
bazel-riscv/
├── .github/
│   └── workflows/
│       ├── build-bazel.yml          # Main build workflow
│       └── test-bazel.yml           # Test workflow
├── docs/
│   ├── build-process.md             # Detailed build documentation
│   ├── troubleshooting.md           # Common issues
│   └── versions.md                  # Tested version matrix
├── scripts/
│   ├── build.sh                     # Build script
│   ├── install.sh                   # Installation script
│   └── test.sh                      # Test script
├── patches/                         # RISC-V specific patches (if needed)
├── README.md
└── LICENSE
```

## Use Cases

### For JetBrains IDE Development

This Bazel build is required for:
- Building IntelliJ IDEA from source on RISC-V
- Building PyCharm, WebStorm, etc.
- JetBrains IDE development on RISC-V hardware

See related project: [IntelliJ IDEA RISC-V Build](https://github.com/gounthar/brain-dumps/tree/main/projects/intellij-riscv)

### For General RISC-V Development

Bazel is used by many projects:
- TensorFlow
- Envoy
- gRPC
- Kubernetes
- Many Google projects

## Resources

**Official Bazel**:
- [Bazel releases](https://github.com/bazelbuild/bazel/releases)
- [Build from source docs](https://bazel.build/install/compile-source)
- [RISC-V support issue](https://github.com/bazelbuild/bazel/issues/12683)

**Community**:
- [Community 6.5.0 build](https://github.com/bazelbuild/bazel/issues/23162) - July 2024 success story

**Related**:
- [JetBrains-IDE-Multiarch](https://github.com/Glavo/JetBrains-IDE-Multiarch) - Uses Bazel for IDE builds
- [docker-for-riscv64](https://github.com/gounthar/docker-for-riscv64) - Our GitHub runner setup

## Contributing

Contributions welcome! Areas of interest:
- Testing newer Bazel versions (7.x)
- Optimizing build performance
- Creating patches for RISC-V specific issues
- Improving CI/CD workflows

## License

This repository contains build scripts and documentation. Bazel itself is licensed under Apache 2.0.

## Maintainer

Built and maintained for RISC-V development on Banana Pi F3.

**Related project**: Building JetBrains IDEs on RISC-V architecture
