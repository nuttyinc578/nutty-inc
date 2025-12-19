# OneOS (WSL root-based distro)

## Overview
OneOS is a minimal, root-based Linux distro designed to run under Windows Subsystem for Linux (WSL). It focuses on a small footprint, defaults to the root user, and enables systemd to support modern services while staying easy to rebuild and customize.

## Requirements
- A Windows 11/10 host with WSL 2 enabled
- An Ubuntu/Debian build environment with `debootstrap`, `tar`, and `sudo`
- ~2 GB of free disk space for the build and exported rootfs

## Build the rootfs
The `build-oneos.sh` script assembles a minimal Debian-based root filesystem and packs it for WSL import.

```bash
# From the repository root
sudo ./oneos/build-oneos.sh
```

Outputs:
- `./oneos/artifacts/rootfs` — the generated OneOS root filesystem tree
- `./oneos/artifacts/OneOS-rootfs.tar.gz` — the archive ready to import into WSL

## Import into WSL
1. Copy `oneos/artifacts/OneOS-rootfs.tar.gz` to your Windows machine.
2. Open PowerShell and import:
   ```powershell
   wsl --import OneOS $env:LOCALAPPDATA\OneOS "C:\\path\\to\\OneOS-rootfs.tar.gz"
   ```
3. Launch the distro:
   ```powershell
   wsl -d OneOS
   ```

## Default settings
- Default user: `root`
- systemd enabled for service support inside WSL
- Basic packages: `sudo`, `curl`, `ca-certificates`, `openssh-server`

## Customizing
- Change the release or mirror by editing variables at the top of `build-oneos.sh`.
- Add more packages by editing the `INCLUDE_PACKAGES` list.
- Adjust default settings (hostname, systemd toggle, default user) in the script before building.

## Notes
- The build requires root privileges because `debootstrap` populates the filesystem and sets ownership.
- If you re-run the build, old artifacts are cleaned automatically.
