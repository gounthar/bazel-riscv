# Tested Bazel Versions on RISC-V

Build status and compatibility matrix for various Bazel versions on RISC-V architecture.

## Version Matrix

| Version | Status | Date Tested | Hardware | RAM | Build Time | JDK | Notes |
|---------|--------|-------------|----------|-----|------------|-----|-------|
| 6.5.0 | ❌ Incompatible | 2025-11-26 | Banana Pi F3 | 16GB | N/A | JDK 21 | JDK 21 module errors, use JDK 11/17 |
| 6.5.0 | ✅ Works | 2024-07 | Generic | 8GB+ | ~60 min | JDK 11/17 | Community verified |
| 7.0.0 | ⚠️ Untested | - | - | - | - | - | - |
| 7.1.0 | ⚠️ Untested | - | - | - | - | - | - |
| 7.2.0 | ⚠️ Untested | - | - | - | - | - | - |
| 7.3.0 | ⚠️ Untested | - | - | - | - | - | - |
| 7.4.1 | 🚧 Testing | 2025-11-26 | Banana Pi F3 | 16GB | TBD | JDK 21 | Build in progress |

**Legend:**
- ✅ Works - Build succeeds, binary functional
- ⚠️ Untested - Not yet tested on RISC-V
- ❌ Fails - Known build or runtime issues
- 🚧 Partial - Builds but has known limitations

## Recommended Versions

### Production Use

**Bazel 6.5.0**
- Status: Community verified working
- Tested: July 2024
- Recommended for: Stable production use
- Download: [6.5.0-dist.zip](https://github.com/bazelbuild/bazel/releases/download/6.5.0/bazel-6.5.0-dist.zip)

### Testing/Development

**Bazel 7.4.1**
- Status: Untested on RISC-V
- Latest release: November 2025
- Worth trying for: Latest features
- Download: [7.4.1-dist.zip](https://github.com/bazelbuild/bazel/releases/download/7.4.1/bazel-7.4.1-dist.zip)

## Hardware-Specific Results

### Banana Pi F3 (SpacemiT K1 8-core, 16GB)

| Version | Build Time | JDK | Status | Notes |
|---------|------------|-----|--------|-------|
| 6.5.0 | ~30-60 min | OpenJDK 21 | ⚠️ Pending | Expected to work |

### VisionFive 2

| Version | Build Time | JDK | Status | Notes |
|---------|------------|-----|--------|-------|
| 6.5.0 | TBD | TBD | ⚠️ Untested | Lower RAM, expect slower build |

## Version-Specific Notes

### Bazel 6.x Series

**6.5.0 (Recommended)**
- First version confirmed working on RISC-V
- Community success story: [GitHub Issue #23162](https://github.com/bazelbuild/bazel/issues/23162)
- Build command: `env EXTRA_BAZEL_ARGS="--host_javabase=@local_jdk//:jdk" ./compile.sh`
- No known RISC-V specific patches needed

### Bazel 7.x Series

**7.4.1 (Latest)**
- Not yet tested on RISC-V
- May require additional patches
- Recommended to try but have 6.5.0 as fallback

## JDK Compatibility

### Tested JDK Versions

| JDK | Provider | Bazel 6.5.0 | Bazel 7.x | Notes |
|-----|----------|-------------|-----------|-------|
| OpenJDK 21 | Debian/Ubuntu | ❌ Incompatible | 🚧 Testing | Module access errors with 6.5.0 |
| OpenJDK 17 | Debian/Ubuntu | ✅ Expected | ⚠️ Untested | Not available on RISC-V Debian |
| OpenJDK 11 | Debian/Ubuntu | ✅ Expected | ⚠️ Untested | Not available on RISC-V Debian |
| Temurin 21 | Eclipse Adoptium | ❌ Incompatible | ⚠️ Untested | Same module issues as OpenJDK 21 |
| Temurin 17 | Eclipse Adoptium | ⚠️ Untested | ⚠️ Untested | May work but untested |
| Liberica 21 | BellSoft | ❌ Incompatible | ⚠️ Untested | Same module issues as OpenJDK 21 |

**Critical Note:** Bazel 6.5.0 is fundamentally incompatible with any JDK 21 distribution due to module access restrictions. Use Bazel 7.4.1+ for JDK 21 compatibility.

## Known Issues by Version

### All Versions

**Bazelisk incompatibility:**
- Bazelisk doesn't support RISC-V architecture
- Must build from source (use this repository)

**Memory requirements:**
- Minimum 8GB RAM for any version
- 16GB+ recommended for comfortable builds

### Version-Specific

**Bazel 6.5.0:**
- **JDK 21 Incompatibility:** Fails with `java.lang.reflect.InaccessibleObjectException` due to module access restrictions
- **Error:** `Unable to make java.lang.String(byte[],byte) accessible: module java.base does not "opens java.lang" to unnamed module`
- **Solution:** Use Bazel 7.4.1+ with JDK 21, or use JDK 11/17 with Bazel 6.5.0
- **Status:** JDK 11/17 not available in Debian RISC-V repositories as of 2025-11
- See [troubleshooting.md](troubleshooting.md#bazel-650-jdk-21-incompatibility) for details

**Bazel 7.4.1:**
- **JNI Header Issues:** Requires manual symlinks for `jni_md.h` during build
- **Workaround:** Create symlinks in `bazel-out/riscv64-opt/bin/external/rules_java~/toolchains/include/`
- **Status:** Testing in progress

## Testing Checklist

When testing a new Bazel version on RISC-V:

- [ ] Download `-dist.zip` archive
- [ ] Verify JDK 21+ installed
- [ ] Check available RAM (8GB+ free)
- [ ] Run bootstrap build
- [ ] Test `bazel --version`
- [ ] Test `bazel version`
- [ ] Build simple project (Hello World)
- [ ] Build complex project (if applicable)
- [ ] Document build time and hardware
- [ ] Report results

## Contributing Test Results

Help expand this matrix! If you test Bazel on RISC-V:

1. Fork this repository
2. Update this file with your results
3. Include: version, hardware, JDK, build time, status
4. Submit pull request

**Format:**
```markdown
| X.Y.Z | ✅ Works | YYYY-MM-DD | Hardware Name | RAM | ~XX min | Brief notes |
```

## Resources

- [Bazel Releases](https://github.com/bazelbuild/bazel/releases)
- [RISC-V Support Tracking](https://github.com/bazelbuild/bazel/issues/12683)
- [Build from Source Docs](https://bazel.build/install/compile-source)
