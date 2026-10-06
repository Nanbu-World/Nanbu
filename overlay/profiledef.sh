#!/usr/bin/env bash
# Nanbu Linux —— mkarchiso profile 定义
# shellcheck disable=SC2034

iso_name="nanbu-linux"
iso_label="NANBU_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"
iso_publisher="Nanbu Linux <https://example.org>"
iso_application="Nanbu Linux 安装 / 救援系统"
iso_version="$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y.%m.%d)"

# 介质上的目录名。保持 "arch" 可避免去改 releng 的引导配置；想改品牌目录需同步改 grub/syslinux 里的路径。
install_dir="arch"

buildmodes=('iso')

# 引导：UEFI 用 GRUB（你要的），BIOS 用 syslinux 兜底（兼容老固件）
bootmodes=(
  'bios.syslinux.mbr'
  'bios.syslinux.eltorito'
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
  ["/usr/local/bin/nanbu-postinstall.sh"]="0:0:755"
)