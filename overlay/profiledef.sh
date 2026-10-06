#!/usr/bin/env bash
# Nanbu Linux —— mkarchiso profile 定义
# shellcheck disable=SC2034

iso_name="nanbu-linux"
iso_label="NANBU_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"
iso_publisher="Nanbu Linux <https://example.org>"
iso_application="Nanbu Linux 安装 / 救援系统"
iso_version="$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y.%m.%d)"

# 介质目录名保持 "arch"，与 releng 的引导配置一致（改这里需同步改 grub/syslinux 里的路径）
install_dir="arch"

buildmodes=('iso')

# 引导：UEFI 用 GRUB + systemd-boot 双保险，BIOS 用 syslinux
bootmodes=(
  'bios.syslinux.mbr'
  'bios.syslinux.eltorito'
  'uefi-ia32.systemd-boot.esp'
  'uefi-x64.systemd-boot.esp'
  'uefi-ia32.systemd-boot.eltorito'
  'uefi-x64.systemd-boot.eltorito'
  'uefi-x64.grub.esp'
  'uefi-x64.grub.eltorito'
)

arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'xz' '-Xbcj' 'x86' '-b' '1M' '-Xdict-size' '1M')
bootstrap_tarball_compression=('zstd' '-c' '-T0' '--auto-threads=logical' '--long' '-19')

file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/etc/gshadow"]="0:0:400"
  ["/root"]="0:0:750"
  ["/root/.automated_script.sh"]="0:0:755"
  ["/usr/local/bin/choose-mirror"]="0:0:755"
  ["/usr/local/bin/Installation_guide"]="0:0:755"
  ["/usr/local/bin/livecd-sound"]="0:0:755"
)