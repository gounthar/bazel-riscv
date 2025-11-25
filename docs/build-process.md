# Bazel Build Process for RISC-V

Detailed documentation for building Bazel from source on RISC-V architecture.

## Prerequisites

### System Requirements

- **Architecture**: RISC-V 64-bit (riscv64)
- **RAM**: Minimum 8GB (16GB recommended)
- **Disk**: ~2GB free space
- **CPU**: Multi-core recommended (8+ cores ideal)

### Software Dependencies

```bash
sudo apt update
sudo apt install -y \
  build-essential \
  openjdk-21-jdk \
  zip \
  unzip \
  python3 \
  git \
  wget
```

**Verify JDK installation:**
```bash
java -version
# Should show OpenJDK 21 or newer
```

## Build Steps

### 1. Download Bazel Source

Bazel releases are available as distribution archives (`-dist.zip`) which contain all sources needed for bootstrapping.

**For Bazel 6.5.0 (verified working):**
```bash
cd ~
wget https://github.com/bazelbuild/bazel/releases/download/6.5.0/bazel-6.5.0-dist.zip
unzip bazel-6.5.0-dist.zip -d bazel-6.5.0
cd bazel-6.5.0
```

**For latest release (7.4.1, untested on RISC-V):**
```bash
cd ~
wget https://github.com/bazelbuild/bazel/releases/download/7.4.1/bazel-7.4.1-dist.zip
unzip bazel-7.4.1-dist.zip -d bazel-7.4.1
cd bazel-7.4.1
```

### 2. Bootstrap Build

Bazel uses a bootstrap process where it builds itself using a minimal Java-based build system.

```bash
env EXTRA_BAZEL_ARGS="--host_javabase=@local_jdk//:jdk" ./compile.sh
```

**What this does:**
- `EXTRA_BAZEL_ARGS`: Passes arguments to the bootstrap Bazel
- `--host_javabase=@local_jdk//:jdk`: Uses local JDK installation

**Build time:**
- Banana Pi F3 (8-core @ 2GHz, 16GB RAM): ~30-60 minutes
- Lower-spec boards: 1-2 hours
- QEMU emulation: Several hours

**Monitoring build progress:**
```bash
# In another terminal, monitor memory usage
watch -n 5 'free -h'

# Monitor CPU usage
htop
```

### 3. Verify Build

Once the build completes, verify the binary:

```bash
./output/bazel --version
./output/bazel version
```

Expected output:
```
bazel 6.5.0
Build label: 6.5.0
Build target: bazel-out/...
```

### 4. Install

```bash
# Install to /usr/local/bin
sudo cp output/bazel /usr/local/bin/

# Verify installation
bazel --version
```

**Alternative install location:**
```bash
# Install to ~/.local/bin (no sudo required)
mkdir -p ~/.local/bin
cp output/bazel ~/.local/bin/

# Add to PATH if needed
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

## Build Optimization

### Using More Memory

If you have >16GB RAM, you can increase build parallelism:

```bash
env EXTRA_BAZEL_ARGS="--host_javabase=@local_jdk//:jdk --jobs=8" ./compile.sh
```

Adjust `--jobs` based on CPU cores and available memory.

### Clean Build

If build fails and you need to retry:

```bash
# Clean build artifacts
rm -rf output/

# Re-run compile
env EXTRA_BAZEL_ARGS="--host_javabase=@local_jdk//:jdk" ./compile.sh
```

## Troubleshooting

See [troubleshooting.md](troubleshooting.md) for common issues and solutions.

## Testing the Build

See [test.sh](../scripts/test.sh) for automated testing of the built binary.

## Resources

- [Bazel Compile from Source Docs](https://bazel.build/install/compile-source)
- [Bazel RISC-V Support Issue](https://github.com/bazelbuild/bazel/issues/12683)
- [Community 6.5.0 Build Success](https://github.com/bazelbuild/bazel/issues/23162)
