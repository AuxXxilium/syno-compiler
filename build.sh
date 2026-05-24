#!/usr/bin/env bash

CACHE_DIR="cache"
TOOLKIT_SERVER="https://global.synologydownload.com/download/ToolChain/toolkit"
TOOLCHAIN_SERVER="https://global.synologydownload.com/download/ToolChain/toolchain"
#https://global.download.synology.com/download/ToolChain/Synology%20NAS%20GPL%20Source/

declare -A URIS
declare -A PLATFORMS
declare -A TOOLCHAIN_KVER

# URIs for toolchain downloads (platform-specific, with kernel version placeholder)
URIS["apollolake"]="Intel%20x86%20Linux%20|%20%28Apollolake%29"
URIS["broadwell"]="Intel%20x86%20Linux%20|%20%28Broadwell%29"
URIS["broadwellnk"]="Intel%20x86%20Linux%20|%20%28Broadwellnk%29"
URIS["broadwellnkv2"]="Intel%20x86%20Linux%20|%20%28Broadwellnkv2%29"
URIS["broadwellntbap"]="Intel%20x86%20Linux%20|%20%28Broadwellntbap%29"
URIS["denverton"]="Intel%20x86%20Linux%20|%20%28Denverton%29"
URIS["geminilake"]="Intel%20x86%20Linux%20|%20%28GeminiLake%29"
URIS["geminilakenk"]="Intel%20x86%20Linux%20|%20%28geminilakenk%29"
URIS["purley"]="Intel%20x86%20Linux%20|%20%28Purley%29"
URIS["v1000"]="Intel%20x86%20Linux%20|%20%28V1000%29"
URIS["v1000nk"]="AMD%20x86%20Linux%20|%20%28v1000nk%29"
URIS["r1000"]="AMD%20x86%20Linux%20|%20%28r1000%29"
URIS["r1000nk"]="AMD%20x86%20Linux%20|%20%28r1000nk%29"
URIS["epyc7002"]="AMD%20x86%20Linux%20Linux%20|%20%28epyc7002%29"
URIS["epyc7003ntb"]="AMD%20x86%20Linux%20|%20%28epyc7003ntb%29"

# Kernel versions for downloads (toolchain kernel versions)
TOOLCHAIN_KVER["7.1:apollolake"]="4.4.180"
TOOLCHAIN_KVER["7.1:broadwell"]="4.4.180"
TOOLCHAIN_KVER["7.1:broadwellnk"]="4.4.180"
TOOLCHAIN_KVER["7.1:denverton"]="4.4.180"
TOOLCHAIN_KVER["7.1:geminilake"]="4.4.180"
TOOLCHAIN_KVER["7.1:v1000"]="4.4.180"
TOOLCHAIN_KVER["7.1:r1000"]="4.4.180"
TOOLCHAIN_KVER["7.1:purley"]="4.4.180"
TOOLCHAIN_KVER["7.1:broadwellnkv2"]="4.4.180"
TOOLCHAIN_KVER["7.1:broadwellntbap"]="4.4.180"
TOOLCHAIN_KVER["7.2:apollolake"]="4.4.180"
TOOLCHAIN_KVER["7.2:broadwell"]="4.4.180"
TOOLCHAIN_KVER["7.2:broadwellnk"]="4.4.302"
TOOLCHAIN_KVER["7.2:denverton"]="4.4.302"
TOOLCHAIN_KVER["7.2:geminilake"]="4.4.302"
TOOLCHAIN_KVER["7.2:v1000"]="4.4.302"
TOOLCHAIN_KVER["7.2:r1000"]="4.4.302"
TOOLCHAIN_KVER["7.2:purley"]="4.4.302"
TOOLCHAIN_KVER["7.2:broadwellnkv2"]="4.4.302"
TOOLCHAIN_KVER["7.2:broadwellntbap"]="4.4.302"
TOOLCHAIN_KVER["7.3:apollolake"]="4.4.180"
TOOLCHAIN_KVER["7.3:broadwell"]="4.4.180"
TOOLCHAIN_KVER["7.3:broadwellnk"]="4.4.302"
TOOLCHAIN_KVER["7.3:denverton"]="4.4.302"
TOOLCHAIN_KVER["7.3:geminilake"]="4.4.302"
TOOLCHAIN_KVER["7.3:v1000"]="4.4.302"
TOOLCHAIN_KVER["7.3:r1000"]="4.4.302"
TOOLCHAIN_KVER["7.3:purley"]="4.4.302"
TOOLCHAIN_KVER["7.3:broadwellnkv2"]="4.4.302"
TOOLCHAIN_KVER["7.3:broadwellntbap"]="4.4.302"
TOOLCHAIN_KVER["7.4:epyc7003ntb"]="5.10.55"

# Kernel versions for module compilation (target kernel versions)
DSM 7.1
PLATFORMS["7.1:apollolake"]="4.4.180"
PLATFORMS["7.1:broadwell"]="4.4.180"
PLATFORMS["7.1:broadwellnk"]="4.4.180"
PLATFORMS["7.1:denverton"]="4.4.180"
PLATFORMS["7.1:geminilake"]="4.4.180"
PLATFORMS["7.1:v1000"]="4.4.180"
PLATFORMS["7.1:r1000"]="4.4.180"
PLATFORMS["7.1:epyc7002"]="5.10.55"
PLATFORMS["7.1:purley"]="4.4.180"
PLATFORMS["7.1:broadwellnkv2"]="4.4.180"
PLATFORMS["7.1:broadwellntbap"]="4.4.180"
# DSM 7.2
PLATFORMS["7.2:apollolake"]="4.4.302"
PLATFORMS["7.2:broadwell"]="4.4.302"
PLATFORMS["7.2:broadwellnk"]="4.4.302"
PLATFORMS["7.2:denverton"]="4.4.302"
PLATFORMS["7.2:geminilake"]="4.4.302"
PLATFORMS["7.2:v1000"]="4.4.302"
PLATFORMS["7.2:r1000"]="4.4.302"
PLATFORMS["7.2:epyc7002"]="5.10.55"
PLATFORMS["7.2:geminilakenk"]="5.10.55"
PLATFORMS["7.2:v1000nk"]="5.10.55"
PLATFORMS["7.2:r1000nk"]="5.10.55"
PLATFORMS["7.2:purley"]="4.4.302"
PLATFORMS["7.2:broadwellnkv2"]="4.4.302"
PLATFORMS["7.2:broadwellntbap"]="4.4.302"
# DSM 7.3
PLATFORMS["7.3:apollolake"]="4.4.302"
PLATFORMS["7.3:broadwell"]="4.4.302"
PLATFORMS["7.3:broadwellnk"]="4.4.302"
PLATFORMS["7.3:denverton"]="4.4.302"
PLATFORMS["7.3:geminilake"]="4.4.302"
PLATFORMS["7.3:v1000"]="4.4.302"
PLATFORMS["7.3:r1000"]="4.4.302"
PLATFORMS["7.3:epyc7002"]="5.10.55"
PLATFORMS["7.3:geminilakenk"]="5.10.55"
PLATFORMS["7.3:v1000nk"]="5.10.55"
PLATFORMS["7.3:r1000nk"]="5.10.55"
PLATFORMS["7.3:purley"]="4.4.302"
PLATFORMS["7.3:broadwellnkv2"]="4.4.302"
PLATFORMS["7.3:broadwellntbap"]="4.4.302"
# DSM 7.4
PLATFORMS["7.4:epyc7003ntb"]="5.10.55"

###############################################################################
function trap_cancel() {
    echo "Press Control+C once more terminate the process (or wait 2s for it to restart)"
    sleep 2 || exit 1
}
trap trap_cancel SIGINT SIGTERM
cd `dirname $0`

###############################################################################
function prepare() {
  # Download toolkits
  CACHE_VERSION="${CACHE_DIR}-${TOOLKIT_VER}"
  mkdir -p ${CACHE_VERSION}
  
  # Iterate through all platforms for this DSM version
  for key in "${!PLATFORMS[@]}"; do
    if [[ "$key" == "${TOOLKIT_VER}:"* ]]; then
      PLATFORM="${key#${TOOLKIT_VER}:}"
      KVER="${PLATFORMS[$key]}"
      # Dev
      echo -n "Checking ${CACHE_VERSION}/ds.${PLATFORM}-${TOOLKIT_VER}.dev.txz... "
      if [ ! -f "${CACHE_VERSION}/ds.${PLATFORM}-${TOOLKIT_VER}.dev.txz" ]; then
        URL="${TOOLKIT_SERVER}/${TOOLKIT_VER}/${PLATFORM}/ds.${PLATFORM}-${TOOLKIT_VER}.dev.txz"
        echo -e "No\nDownloading ${URL}"
        STATUS=`curl -w "%{http_code}" -L "${URL}" -o "${CACHE_VERSION}/ds.${PLATFORM}-${TOOLKIT_VER}.dev.txz"`
        if [ ${STATUS} -ne 200 ]; then
          rm -f "${CACHE_VERSION}/ds.${PLATFORM}-${TOOLKIT_VER}.dev.txz"
          exit 1
        fi
      else
        echo "OK"
      fi
      # Toolchain - use TOOLCHAIN_KVER for download URL construction
      DOWNLOAD_KVER="${TOOLCHAIN_KVER[${TOOLKIT_VER}:${PLATFORM}]}"
      URI="`echo ${URIS[${PLATFORM}]} | sed "s/|/${DOWNLOAD_KVER}/"`"
      FILENAME="${PLATFORM}-${GCCLIB_VER}_x86_64-GPL.txz"
      URL="${TOOLCHAIN_SERVER}/${TOOLCHAIN_VER}/${URI}/${FILENAME}"
      echo -n "Checking ${CACHE_VERSION}/${FILENAME}... "
      if [ ! -f "${CACHE_VERSION}/${FILENAME}" ]; then
        echo -e "No\nDownloading ${URL}"
        STATUS=`curl -w "%{http_code}" -L "${URL}" -o "${CACHE_VERSION}/${FILENAME}"`
        if [ ${STATUS} -ne 200 ]; then
          rm -f "${CACHE_VERSION}/${FILENAME}"
          exit 1
        fi
      else
        echo "OK"
      fi
    fi
  done

  # Build platform list for Dockerfile (space-separated platform:kver pairs)
  PLATFORMS_LIST=""
  for key in "${!PLATFORMS[@]}"; do
    if [[ "$key" == "${TOOLKIT_VER}:"* ]]; then
      PLATFORM="${key#${TOOLKIT_VER}:}"
      KVER="${PLATFORMS[$key]}"
      if [ -z "$PLATFORMS_LIST" ]; then
        PLATFORMS_LIST="${PLATFORM}:${KVER}"
      else
        PLATFORMS_LIST="${PLATFORMS_LIST} ${PLATFORM}:${KVER}"
      fi
    fi
  done

  # Generate Dockerfile
  echo "Generating Dockerfile"
  cp Dockerfile.template Dockerfile
  sed -i "s|ADD cache /cache|ADD ${CACHE_VERSION} /cache|g" Dockerfile
  sed -i "s|@@@PLATFORMS@@@|${PLATFORMS_LIST}|g" Dockerfile
  sed -i "s|@@@TOOLKIT_VER@@@|${TOOLKIT_VER}|g" Dockerfile
  sed -i "s|@@@GCCLIB_VER@@@|${GCCLIB_VER}|g" Dockerfile
}

###############################################################################
function select_version() {
  echo -e "\nSelect DSM version to build:"
  echo "1) DSM 7.1"
  echo "2) DSM 7.2"
  echo "3) DSM 7.3"
  echo "4) DSM 7.4"
  echo
  read -p "Enter selection (1-4): " VERSION_CHOICE

  case ${VERSION_CHOICE} in
    1)
      TOOLKIT_VER="7.1"
      TOOLCHAIN_VER="7.1-42661"
      GCCLIB_VER="gcc850_glibc226"
      ;;
    2)
      TOOLKIT_VER="7.2"
      TOOLCHAIN_VER="7.2-72806"
      GCCLIB_VER="gcc1220_glibc236"
      ;;
    3)
      TOOLKIT_VER="7.3"
      TOOLCHAIN_VER="7.3-86009"
      GCCLIB_VER="gcc1220_glibc236"
      ;;
    4)
      TOOLKIT_VER="7.4"
      TOOLCHAIN_VER="7.4-101151"
      GCCLIB_VER="gcc1220_glibc236"
      ;;
    *)
      echo "Invalid selection"
      exit 1
      ;;
  esac
}

###############################################################################
# Version selection: CLI argument or interactive menu
if [ -n "$1" ]; then
  case $1 in
    7.1)
      TOOLKIT_VER="7.1"
      TOOLCHAIN_VER="7.1-42661"
      GCCLIB_VER="gcc850_glibc226"
      ;;
    7.2)
      TOOLKIT_VER="7.2"
      TOOLCHAIN_VER="7.2-72806"
      GCCLIB_VER="gcc1220_glibc236"
      ;;
    7.3)
      TOOLKIT_VER="7.3"
      TOOLCHAIN_VER="7.3-86009"
      GCCLIB_VER="gcc1220_glibc236"
      ;;
    7.4)
      TOOLKIT_VER="7.4"
      TOOLCHAIN_VER="7.4-101151"
      GCCLIB_VER="gcc1220_glibc236"
      ;;
    *)
      echo "Usage: $0 [7.1|7.2|7.3|7.4]"
      exit 1
      ;;
  esac
else
  select_version
fi

prepare
echo "Building ${TOOLKIT_VER}"
docker image rm auxxxilium/syno-compiler:${TOOLKIT_VER} >/dev/null 2>&1
docker buildx build . --load --tag auxxxilium/syno-compiler:${TOOLKIT_VER}
