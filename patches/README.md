# Bazel RISC-V Patches

This directory contains patches required for building specific Bazel versions on RISC-V architecture.

## Available Patches

### 7.4.1-jni-headers-riscv.patch

**Version:** Bazel 7.4.1
**Issue:** JNI headers not found during compilation of cpu_profiler_posix.cc
**Error:**
```
fatal error: jni_md.h: No such file or directory
```

**Root Cause:**
Bazel looks for JNI headers in its own build directory structure rather than using system include paths. The `@bazel_tools//tools/jdk:jni` dependency doesn't automatically add the system JDK include paths to the compiler flags.

**Solution:**
Adds explicit `copts` to the `libcpu_profiler.so` cc_binary target to include system JNI header paths:
- `/usr/lib/jvm/java-21-openjdk-riscv64/include`
- `/usr/lib/jvm/java-21-openjdk-riscv64/include/linux`

**Application:**
This patch is automatically applied by `scripts/build.sh` when building Bazel 7.4.1.

**Files Modified:**
- `src/main/java/net/starlark/java/eval/BUILD`

## Patch Naming Convention

Patches follow the naming pattern: `{VERSION}-{description}.patch`

Examples:
- `7.4.1-jni-headers-riscv.patch`
- `6.5.0-example-fix.patch`

## Applying Patches Manually

If you need to apply a patch manually:

```bash
cd ~/bazel-build/bazel-{VERSION}
patch -p1 < /path/to/patches/{VERSION}-{description}.patch
```

## Testing Patches

Before committing a patch:

1. Test on clean source extraction
2. Verify build completes successfully
3. Test resulting binary with `./scripts/test.sh {VERSION}`
4. Document in `docs/versions.md` and `docs/troubleshooting.md`

## Contributing Patches

When adding a new patch:

1. Create patch file with proper naming convention
2. Add entry to this README
3. Update `docs/troubleshooting.md` with issue details
4. Update `docs/versions.md` with version-specific notes
5. Test that `scripts/build.sh` applies patch correctly
