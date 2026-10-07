#!/usr/bin/env bash
# Nanbu Linux —— mkarchiso profile 定义
# shellcheck disable=SC2034

iso_name="nanbu-linux"
iso_label="NANBU_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"
iso_publisher="Nanbu Linux <https://www.huafxy.com>"
iso_application="Nanbu Linux 安装 / 救援系统"
iso_version="$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y.%m.%d)"

# 介质目录名保持 "arch"，与 releng 的引导配置一致。
install_dir="arch"

buildmodes=('iso')

# 引导：BIOS 用 Syslinux，UEFI 用 GRUB；两者都适配常见虚拟机。
bootmodes=(
  'bios.syslinux'
  'uefi.grub'
)

arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'xz' '-Xbcj' 'x86' '-b' '1M' '-Xdict-size' '1M')
bootstrap_tarball_compression=('zstd' '-c' '-T0' '--auto-threads=logical' '--long' '-19')
