# syno-compiler Docker

## Docker Commands

### Basic Shell

```bash
docker run -it auxxxilium/syno-compiler:7.3 bash
```

### With Input/Output Mounts

```bash
docker run -it \
  -v /path/to/source:/input \
  -v /path/to/output:/output \
  auxxxilium/syno-compiler:7.3 \
  <command> <args>
```

**Volume mappings:**
- `/input` - Source code or module source
- `/output` - Compiled binaries/modules

## Available Commands

Run commands inside the container via the entry point script:

### `bash` - Interactive Shell

```bash
docker run -it auxxxilium/syno-compiler:7.3 bash
```

Start a regular bash shell with no special configuration.

### `shell <platform>` - Build Environment Shell

```bash
docker run -it \
  -v /path/to/kernel/src:/input \
  -v /path/to/output:/output \
  auxxxilium/syno-compiler:7.3 \
  shell <platform>
```

Open an interactive shell with full build environment configured for the specified platform:
- Cross-compiler paths set up
- Kernel source/build files copied to expected locations
- Environment variables configured (CROSS_COMPILE, CFLAGS, LDFLAGS, LD_LIBRARY_PATH, etc.)
- PATH updated with toolchain binaries

**Supported platforms:** `epyc7002`, `geminilakenk`, `broadwell`, `apollolake`, `denverton`, `purley`, `v1000`, `r1000`, `broadwellnk`, `broadwellnkv2`, etc.

### `compile-module <platform>` - Compile Kernel Module

```bash
docker run -it \
  -v /path/to/module/source:/input \
  -v /path/to/output:/output \
  auxxxilium/syno-compiler:7.3 \
  compile-module <platform>
```

Compile a kernel module against the kernel for the specified platform:
- Reads module source from `/input`
- Applies platform configuration (PLATFORM-Y=y, PLATFORM-M=m)
- Applies custom defines from `/input/defines.<platform>` if present
- Compiles with full CPU parallelism (`-j$(nproc)`)
- Strips debug symbols from compiled .ko files
- Outputs all compiled .ko files to `/output`

**Example custom defines file:**
```bash
# /input/defines.epyc7002
CONFIG_ATA=y
CONFIG_SATA_AHCI=y
CONFIG_FB_DEFERRED_IO=y
```

### `compile-binary <platform> <build_script>` - Compile Binary

```bash
docker run -it \
  -v /path/to/source:/input \
  -v /path/to/output:/output \
  auxxxilium/syno-compiler:7.3 \
  compile-binary <platform> <build_script>
```

Execute a custom build script within the build environment:
- Sets platform environment variables (PLATFORM, ROOT_PATH)
- Runs the specified `<build_script>` from `/input` directory
- Expects compiled output in `/input/output`
- Copies `/input/output/*` to `/output`

**Supported platforms:** Same as `shell` command

### `compile-lkm <platform> [dev|prod]` - Compile Redpill LKM

```bash
docker run -it \
  -v /path/to/redpill/source:/input \
  -v /path/to/output:/output \
  auxxxilium/syno-compiler:7.3 \
  compile-lkm <platform> prod
```

Compile redpill LKM (loadable kernel module) for the specified platform:
- Takes LKM source from `/input`
- Supports two build targets:
  - `prod` - Production build (default)
  - `dev` - Debug build with symbols
- Runs `make <target>-v7` inside the source directory
- Strips debug symbols (for prod) or keeps them (for dev)
- Outputs `redpill.ko` to `/output`

## Supported Platforms

| Platform | DSM 7.2 | DSM 7.3 |
|----------|---------|---------|
| epyc7002 | 7.2 | 7.3 |
| geminilakenk | 7.2 | 7.3 |
| broadwell | 7.2 | 7.3 |
| apollolake | 7.2 | 7.3 |
| denverton | 7.2 | 7.3 |
| purley | 7.2 | 7.3 |
| v1000 | 7.2 | 7.3 |
| r1000 | 7.2 | 7.3 |
| broadwellnk | 7.2 | 7.3 |
| broadwellnkv2 | 7.2 | 7.3 |
| r1000nk | 7.2 | 7.3 |
| v1000nk | 7.2 | 7.3 |

## Examples

### Compile kernel module for epyc7002

```bash
docker run -it \
  -v ~/my-module:/input \
  -v ~/output:/output \
  auxxxilium/syno-compiler:7.3 \
  compile-module epyc7002
```

### Interactive build shell for geminilakenk

```bash
docker run -it \
  -v ~/kernel:/input \
  -v ~/output:/output \
  auxxxilium/syno-compiler:7.3 \
  shell geminilakenk
```

Inside the shell, you can run standard make commands:
```bash
cd /opt/geminilakenk/build
make -j$(nproc) bzImage modules
```

### Compile redpill LKM

```bash
docker run -it \
  -v ~/redpill-source:/input \
  -v ~/output:/output \
  auxxxilium/syno-compiler:7.3 \
  compile-lkm epyc7002 prod
```

### Custom build script

Create `/path/to/project/build.sh`:
```bash
#!/bin/bash
set -e
cd /tmp/input
make -j$(nproc)
mkdir -p /tmp/input/output
cp binary /tmp/input/output/
```

Then run:
```bash
docker run -it \
  -v /path/to/project:/input \
  -v ~/output:/output \
  auxxxilium/syno-compiler:7.3 \
  compile-binary epyc7002 build.sh
```
