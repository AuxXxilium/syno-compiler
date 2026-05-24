#!/usr/bin/env bash

set -eo pipefail

###############################################################################
function resolve-kernel-build-dir() {
  local platform="$1"
  local build_dir=""

  if [ -z "${platform}" ]; then
    echo ""
    return 1
  fi

  if [ -d "/opt/${platform}/build" ]; then
    echo "/opt/${platform}/build"
    return 0
  fi

  # Fallback: some toolkits are extracted under an extra DSM-* level.
  build_dir=$(find "/opt/${platform}" -maxdepth 4 -type d -name build 2>/dev/null | head -n 1)
  if [ -n "${build_dir}" ] && [ -d "${build_dir}" ]; then
    echo "${build_dir}"
    return 0
  fi

  echo ""
  return 1
}

###############################################################################
function export-vars() {
  # Validate
  if [ -z "${1}" ]; then
    echo "Use: export-vars <platform>"
    exit 1
  fi
  local build_dir
  build_dir=$(resolve-kernel-build-dir "${1}")
  if [ -z "${build_dir}" ]; then
    echo "Kernel build directory not found for platform: ${1}"
    find "/opt/${1}" -maxdepth 5 -type d 2>/dev/null | sed 's#^#  #'
    exit 1
  fi

  export PLATFORM="${1}"
  export KSRC="${build_dir}"
  export CROSS_COMPILE="/opt/${1}/bin/x86_64-pc-linux-gnu-"
  export CFLAGS="-I/opt/${1}/include"
  export LDFLAGS="-I/opt/${1}/lib"
  export LD_LIBRARY_PATH="/opt/${1}/lib"
  export ARCH=x86_64
  export CC="x86_64-pc-linux-gnu-gcc"
  export LD="x86_64-pc-linux-gnu-ld"
  echo "export PATH=\"/opt/${1}/bin:${PATH}\"" | \
    sudo tee /etc/profile.d/path.sh >/dev/null
  sudo chmod +x /etc/profile.d/path.sh
}

###############################################################################
function shell() {
  local build_dir
  build_dir=$(resolve-kernel-build-dir "${2}")
  if [ -z "${build_dir}" ]; then
    echo "Kernel build directory not found for platform: ${2}"
    exit 1
  fi

  cp -fv "${build_dir}/.config" /opt/${2}/source/
  cp -fv "${build_dir}/System.map" /opt/${2}/source/
  cp -fv "${build_dir}/Module.symvers" /opt/${2}/source/
  export-vars $2
  shift 2
  bash -l $@
}

###############################################################################
function compile-module {
  # Validate
  if [ -z "${1}" ]; then
    echo "Use: compile-module <platform>"
    exit 1
  fi
  VALID=0
  while read PLATFORM KVER; do
    if [ "${PLATFORM}" = "${1}" ]; then
      VALID=1
      break
    fi
  done </opt/platforms
  if [ $VALID -eq 0 ]; then
    echo "Platform ${1} not found."
    exit 1
  fi
  unset VALID
  echo -e "Compiling module for \033[7m${PLATFORM}-${KVER}\033[0m..."
  cp -R /input /tmp
  export-vars ${PLATFORM}
  
  PARMS="${PLATFORM^^}-Y=y ${PLATFORM^^}-M=m"
  if [ -f "/tmp/input/defines.${1}" ]; then
    PARMS+=" `cat "/tmp/input/defines.${1}" | xargs`"
  fi
  
  # Build modules with KBUILD_MODPOST_WARN=1 to treat modpost errors as warnings
  make -j`nproc` -C "${KSRC}" M="/tmp/input" ${PARMS} KBUILD_MODPOST_WARN=1 modules 2>&1 || true
  
  # Collect all .ko files that were successfully compiled
  while read F; do
    strip -g "${F}"
    echo "Copying `basename ${F}`"
    cp "${F}" "/output"
  done < <(find /tmp/input -name \*.ko 2>/dev/null)
}

###############################################################################
function compile-lkm {
  PLATFORM=${1}
  TARGET=${2:-prod}
  if [ -z "${PLATFORM}" ]; then
    echo "Use: compile-lkm <platform> [dev|prod]"
    exit 1
  fi
  
  # Validate target
  if [ "${TARGET}" != "dev" ] && [ "${TARGET}" != "prod" ]; then
    echo "Invalid target: ${TARGET}. Use 'dev' or 'prod'."
    exit 1
  fi
  
  cp -R /input /tmp
  export-vars ${PLATFORM}
  export LINUX_SRC="${KSRC}"
  
  make -C "/tmp/input" "${TARGET}-v7"
  if [ ! -f "/tmp/input/redpill.ko" ]; then
    echo "Compilation finished without redpill.ko for ${PLATFORM}-${TARGET}"
    exit 1
  fi
  strip -g "/tmp/input/redpill.ko"
  mv "/tmp/input/redpill.ko" "/output/redpill.ko"
}

###############################################################################
# function compile-drivers {
#   while read platform kver; do
#     SRC_PATH="/opt/${platform}"
#     echo "Compiling for ${platform}-${kver}"
#     cd /opt/linux-${kver}/drivers
#     while read dir; do
#       if [ -f "${dir}/Makefile" ]; then
#         echo "Driver `basename ${dir}`"
#         grep "CONFIG_.*/.*"   "${dir}/Makefile" | sed 's/.*\(CONFIG_[^)]*\).*/\1=n/g' >  /tmp/env
#         grep "CONFIG_.*\.o.*" "${dir}/Makefile" | sed 's/.*\(CONFIG_[^)]*\).*/\1=m/g' >> /tmp/env
#         make -C "${SRC_PATH}" M=$(readlink -f "${dir}") clean
#         cat /tmp/env | xargs -d '\n' make -C "${SRC_PATH}" M=$(readlink -f "${dir}") modules $@
#       fi
#     done < <(find -type d)
#     DST_PATH="/output/compiled-mods/${platform}-${kver}"
#     mkdir -p "${DST_PATH}"
#     while read f; do
#       strip -g "${f}"
#       mv "${f}" "${DST_PATH}"
#     done < <(find -name \*.ko)
#   done </opt/platforms
# }

###############################################################################
###############################################################################
function compile-binary {
  # Validate
  if [ -z "${1}" ] || [ -z "${2}" ]; then
    echo "Use: compile-binary <platform> <build_script>"
    exit 1
  fi
  PLATFORM="${1}"
  BUILD_SCRIPT="${2}"
  echo -e "Compiling binary for \033[7m${PLATFORM}\033[0m using ${BUILD_SCRIPT}..."
  
  # Copy input to temp directory
  cp -R /input /tmp
  
  # Check if build script exists
  if [ ! -f "/tmp/input/${BUILD_SCRIPT}" ]; then
    echo "Build script not found: /tmp/input/${BUILD_SCRIPT}"
    exit 1
  fi
  
  # Make build script executable
  chmod +x "/tmp/input/${BUILD_SCRIPT}"
  
  # Set build environment variables
  export ROOT_PATH="/tmp/input"
  export PLATFORM="${PLATFORM}"
  
  # Run build script
  cd /tmp/input
  ./${BUILD_SCRIPT}
  
  # Copy compiled binaries to output
  if [ -d "/tmp/input/output" ]; then
    cp -R /tmp/input/output/* /output/
    echo "Binary compilation completed"
  else
    echo "No output directory found"
    exit 1
  fi
}

###############################################################################

if [ $# -lt 1 ]; then
  echo "Use: <command> (<params>)"
  echo "Commands: bash | shell <platform> | compile-module <platform> | compile-binary <platform> <build_script> | compile-lkm <platform> [dev|prod]"
  exit 1
fi
case $1 in
  bash) shift && bash -l $@ ;;
  shell) shell $@ ;;
  compile-module) compile-module $2 ;;
  compile-binary) compile-binary $2 $3 ;;
  compile-lkm) compile-lkm $2 $3 ;;
  # compile-drivers) compile-drivers ;;
  *) echo "Command not recognized: $1" ;;
esac
