#!/bin/bash
set -e -x

rm -rf .repo/local_manifests/
repo init -u https://github.com/crDroid11/android.git -b 11.0 --git-lfs --depth 1

mkdir -p .repo/local_manifests
rm -rf .repo/local_manifests/* || true
curl -L -o .repo/local_manifests/local_manifest.xml https://raw.githubusercontent.com/AKPR2007/ppui_local_manifest_tulip/refs/heads/main/ppui.xml

# Sync the repositories
if [ -f /usr/bin/resync ]; then
  /usr/bin/resync
else
  /opt/crave/resync.sh
fi

# ── Dependency fix (libncurses5 / libtinfo5) ──
if [ -f /usr/lib/x86_64-linux-gnu/libncurses.so.5 ] && [ -f /usr/lib/x86_64-linux-gnu/libtinfo.so.5 ]; then
  echo ">>> libncurses.so.5 and libtinfo.so.5 already present — skipping install"
else
  echo ">>> Installing libncurses5 and libtinfo5..."
  sudo apt-get update -qq 2>/dev/null || true
  sudo apt-get install -y -qq wget curl 2>/dev/null || true
  POOL_URL="http://archive.ubuntu.com/ubuntu/pool/universe/n/ncurses"
  TINFO_DEB=$(curl -sL "$POOL_URL/" | grep -oE "libtinfo5_[^\"<> ]+_amd64\.deb" | sort -V | tail -1)
  NCURSES_DEB=$(curl -sL "$POOL_URL/" | grep -oE "libncurses5_[^\"<> ]+_amd64\.deb" | sort -V | tail -1)
  if [ -z "$TINFO_DEB" ] || [ -z "$NCURSES_DEB" ]; then
    echo "ERROR: could not find libtinfo5/libncurses5 packages in Ubuntu pool"
  else
    wget -q "$POOL_URL/$TINFO_DEB" -O /tmp/libtinfo5.deb
    wget -q "$POOL_URL/$NCURSES_DEB" -O /tmp/libncurses5.deb
    sudo apt-get install -y /tmp/libtinfo5.deb /tmp/libncurses5.deb
    rm -f /tmp/libtinfo5.deb /tmp/libncurses5.deb
  fi
  echo "Dependency fix complete"
fi

# Set up build environment
export BUILD_USERNAME=Erik
export BUILD_HOSTNAME=Shefon

set +e
source build/envsetup.sh
set -e


# Build the ROM
lunch aosp_tulip-userdebug && make installclean && mka bacon
