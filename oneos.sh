#!/usr/bin/env bash
set -euo pipefail

# Configuration (override via env vars)
RELEASE="bookworm"
MIRROR="http://deb.debian.org/debian"
ARCH="amd64"
INCLUDE_PACKAGES="sudo,curl,ca-certificates,openssh-server"
DISTRO_NAME="OneOS"
WORK_DIR="$(pwd)/oneos/artifacts"
ROOTFS_DIR="$WORK_DIR/rootfs"
TARBALL="$WORK_DIR/${DISTRO_NAME}-rootfs.tar.gz"

task() {
  echo "[OneOS] $1"
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

if [[ $(id -u) -ne 0 ]]; then
  echo "This script must be run as root (sudo ./oneos/build-oneos.sh)." >&2
  exit 1
fi

for cmd in debootstrap tar; do
  require_command "$cmd"
done

# Prepare workspace
rm -rf "$WORK_DIR"
mkdir -p "$ROOTFS_DIR"

# Build minimal rootfs
export DEBOOTSTRAP_DIR=${DEBOOTSTRAP_DIR:-}
task "Creating ${DISTRO_NAME} rootfs (release=$RELEASE, mirror=$MIRROR, arch=$ARCH)"
debootstrap --arch="$ARCH" --variant=minbase --include="$INCLUDE_PACKAGES" \
  "$RELEASE" "$ROOTFS_DIR" "$MIRROR"

# Basic branding and WSL defaults
echo "${DISTRO_NAME}" > "$ROOTFS_DIR/etc/hostname"
cat > "$ROOTFS_DIR/etc/issue" <<ISSUE
${DISTRO_NAME} (WSL) \n \l
ISSUE

cat > "$ROOTFS_DIR/etc/wsl.conf" <<WSL
[boot]
systemd=true

[user]
default=root
WSL

task "Packing rootfs into $TARBALL"
mkdir -p "$WORK_DIR"
tar --numeric-owner --xattrs --acls -C "$ROOTFS_DIR" -czf "$TARBALL" .

task "Done. Import with: wsl --import ${DISTRO_NAME} <installDir> $TARBALL"
