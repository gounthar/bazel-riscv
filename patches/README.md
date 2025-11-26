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

**Attempted Solution (Fails due to Sandboxing):**
This patch attempts to add explicit `copts` to the `libcpu_profiler.so` cc_binary target to include system JNI header paths:
- `/usr/lib/jvm/java-21-openjdk-riscv64/include`
- `/usr/lib/jvm/java-21-openjdk-riscv64/include/linux`

**Status:** ❌ **This patch does NOT work** due to Bazel's sandboxing restrictions. Bazel prevents accessing paths outside the execution root, causing the build to fail with:
```
The include path '/usr/lib/jvm/java-21-openjdk-riscv64/include' references a path outside of the execution root.
```

**Application:**
This patch is included for documentation purposes only. It demonstrates an attempted fix that fails due to architectural limitations in Bazel's sandboxing system.

> **⚠️ Why This Class of Solutions Is Blocked**
>
> This patch represents a **broader class of failed solutions**, not just a single failed attempt. Understanding why is important:
>
> 1. **Any absolute system path will fail** - Whether it's JDK 21, JDK 17, or any other system-installed package, Bazel's sandbox prevents all access to paths outside the execution root. Changing the JDK version or path does not help.
>
> 2. **Sandboxing is a design principle, not a bug** - Bazel intentionally isolates builds from the host system to ensure reproducibility and hermeticity. This is a core architectural decision, not an oversight that can be patched around.
>
> 3. **Solutions must work within Bazel's rules** - Valid approaches include:
>    - Using Bazel-managed toolchains via `rules_java`
>    - Providing headers through proper Bazel targets/filegroups
>    - Building with `--sandbox_debug` or `--spawn_strategy=local` (sacrifices reproducibility)
>    - Configuring remote JDK toolchains that Bazel can fetch and control
>
> This documentation preserves the patch to help future contributors understand what was tried and why it failed, preventing repeated investigation of dead-end approaches.

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
