# Troubleshooting Bazel Builds on RISC-V

Common issues and solutions when building Bazel on RISC-V architecture.

## Build Failures

### Out of Memory (OOM)

**Symptoms:**
- Build killed without error message
- System becomes unresponsive
- `dmesg` shows OOM killer messages

**Solution:**
```bash
# Check available memory
free -h

# Reduce build parallelism
env EXTRA_BAZEL_ARGS="--host_javabase=@local_jdk//:jdk --jobs=2" ./compile.sh

# Add swap if needed (temporary)
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

### JDK Not Found

**Symptoms:**
```
ERROR: Cannot find Java binary
```

**Solution:**
```bash
# Install OpenJDK 21
sudo apt install openjdk-21-jdk

# Verify installation
java -version
which java

# Set JAVA_HOME if needed
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-riscv64
```

### Missing Dependencies

**Symptoms:**
```
ERROR: gcc: command not found
ERROR: python3: command not found
```

**Solution:**
```bash
# Install all dependencies
sudo apt update
sudo apt install -y build-essential openjdk-21-jdk zip unzip python3 git wget
```

### Bazel 6.5.0 JDK 21 Incompatibility

**Symptoms:**
```
FATAL: bazel crashed due to an internal error
java.lang.ExceptionInInitializerError
Caused by: java.lang.reflect.InaccessibleObjectException:
  Unable to make java.lang.String(byte[],byte) accessible:
  module java.base does not "opens java.lang" to unnamed module
```

**Root Cause:**
Bazel 6.5.0 (released July 2023) predates JDK 21 (released September 2023) and is **fundamentally incompatible** with JDK 21's strict module access controls. Bazel 6.5.0 uses reflection to access internal String constructors, which JDK 21's module system blocks.

**Why This Happens:**
- Bazel 6.5.0 attempts to use `StringUnsafe` for optimization
- JDK 21 enforces stricter module boundaries than JDK 11/17
- The required `--add-opens` flags cannot be passed through the bootstrap build process
- Community success stories with Bazel 6.5.0 on RISC-V likely used JDK 11 or 17

**Solutions:**

**Option 1: Use Bazel 7.4.1+ (Alternative with known issues on RISC-V)**
```bash
# Note: Bazel 7.4.1 has JNI header sandboxing issues on RISC-V
# This option works on x86_64/arm64 but fails on RISC-V
wget https://github.com/bazelbuild/bazel/releases/download/7.4.1/bazel-7.4.1-dist.zip
unzip bazel-7.4.1-dist.zip -d bazel-7.4.1
cd bazel-7.4.1
env EXTRA_BAZEL_ARGS="--tool_java_runtime_version=local_jdk --java_runtime_version=local_jdk" ./compile.sh
```

**Option 2: Downgrade to JDK 11 or 17 (If Available)**
```bash
# Check available JDK versions
apt search openjdk | grep -E 'openjdk-(11|17)-jdk'

# Note: JDK 11/17 may not be available for RISC-V in all repositories
# Debian RISC-V currently only provides JDK 21
```

**Option 3: Wait for Backports**
Monitor [Bazel RISC-V tracking issue](https://github.com/bazelbuild/bazel/issues/12683) for potential backports or patches.

**Not a Solution:**
Setting `JAVA_TOOL_OPTIONS` or `BAZEL_JAVAC_OPTS` with `--add-opens` flags does **not** work because:
- Bazel uses its own compiled bootstrap binary to build itself
- Environment variables are not propagated to the Bazel analysis/execution phase
- Patching `bootstrap.sh` to add `--host_jvm_args` still fails due to timing issues

**Tested Alternative JDKs:**

We've tested the following alternative JDK distributions for RISC-V compatibility with Bazel 6.5.0:

1. **Eclipse Adoptium Temurin JDK 17** (Issue #2)
   - Status: ❌ **Failed** - Toolchain resolution error
   - Error: `No matching toolchains found for types @bazel_tools//tools/jdk:runtime_toolchain_type`
   - Root Cause: Temurin lacks Bazel-specific toolchain registration metadata
   - Tested: 2025-11-26 on Banana Pi F3

2. **Fizzed Nitro JDK** (Issue #3)
   - Status: ❌ **Not viable** - Only provides JDK 19/21
   - Available versions: JDK 19.0.1, JDK 21.0.1
   - Issue: Same module incompatibility as standard JDK 21
   - No JDK 11 or 17 available from this provider

**Conclusion:**
No mainstream alternative JDK distributions currently provide working JDK 11/17 for RISC-V. The July 2024 community success story likely used Debian-packaged OpenJDK 11 or 17, which are no longer available in RISC-V repositories.

**Recommended Version Matrix:**

| Bazel Version | JDK 11 | JDK 17 | JDK 21 | RISC-V Status |
|---------------|--------|--------|--------|---------------|
| 6.5.0 | ✅ Works | ✅ Works | ❌ Incompatible | Community verified (JDK 11/17) |
| 7.4.1 | ✅ Works | ✅ Works | ❌ Fails (RISC-V) | JNI header sandboxing issues |

### Compilation Timeout

**Symptoms:**
- Build hangs at specific step
- No progress for >30 minutes

**Solution:**
```bash
# Kill the build
Ctrl+C

# Clean and retry
rm -rf output/
env EXTRA_BAZEL_ARGS="--host_javabase=@local_jdk//:jdk" ./compile.sh
```

## Runtime Issues

### Bazelisk Not Working

**Problem:**
```
could not download Bazel: unsupported machine architecture "riscv64"
```

**Solution:**
This is expected. Bazelisk doesn't support RISC-V. You must build from source (this repository).

### Permission Denied

**Problem:**
```bash
bazel: Permission denied
```

**Solution:**
```bash
# Make binary executable
chmod +x /usr/local/bin/bazel

# Or if installed to ~/.local/bin
chmod +x ~/.local/bin/bazel
```

### Version Mismatch

**Problem:**
Project requires specific Bazel version but you have different version.

**Solution:**
Build the required version from source:
```bash
# Download specific version
wget https://github.com/bazelbuild/bazel/releases/download/X.Y.Z/bazel-X.Y.Z-dist.zip
unzip bazel-X.Y.Z-dist.zip -d bazel-X.Y.Z
cd bazel-X.Y.Z

# Build and install
env EXTRA_BAZEL_ARGS="--host_javabase=@local_jdk//:jdk" ./compile.sh
sudo cp output/bazel /usr/local/bin/bazel-X.Y.Z

# Use specific version
bazel-X.Y.Z --version
```

## Hardware-Specific Issues

### Banana Pi F3

**Known working configuration:**
- Debian RISC-V
- 16GB RAM
- OpenJDK 21
- Bazel 6.5.0

**Tips:**
- Use all 8 cores with `--jobs=8`
- Build time: 30-60 minutes
- No swap needed with 16GB RAM

### VisionFive 2

**Known issues:**
- Lower memory (4GB/8GB models)
- Slower CPU

**Recommendations:**
- Add 4GB swap
- Use `--jobs=2` or `--jobs=4`
- Expect 1-2 hour build time

### QEMU

**Not recommended for builds:**
- Very slow (several hours)
- Higher risk of timeout/OOM

**Use for:**
- Testing pre-built binaries
- Development/debugging only

## CI/CD Issues

### Self-Hosted Runner

**Runner not picking up jobs:**
```bash
# Check runner status
cd /mnt/c/support/users/dev/riscv/docker/docker-dev
./check-runner.sh

# Restart runner if needed
./restart-runner.sh
```

**Build fails in CI but works locally:**
- Check environment variables
- Verify JDK version matches
- Check disk space in runner

## Getting Help

**Before opening an issue:**
1. Check [Bazel RISC-V issue tracker](https://github.com/bazelbuild/bazel/issues/12683)
2. Review [build-process.md](build-process.md)
3. Verify all dependencies installed
4. Try clean build

**When reporting issues:**
- Bazel version attempted
- Hardware specs (CPU, RAM)
- OS version (`uname -a`)
- JDK version (`java -version`)
- Full error output
- Build command used

## Resources

- [Bazel Troubleshooting Guide](https://bazel.build/run/troubleshooting)
- [Community Success: Bazel 6.5.0](https://github.com/bazelbuild/bazel/issues/23162)
- [RISC-V Support Tracking](https://github.com/bazelbuild/bazel/issues/12683)
