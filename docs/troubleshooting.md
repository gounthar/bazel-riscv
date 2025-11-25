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
