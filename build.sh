#!/usr/bin/env bash
# Nanbu Linux ISO 构建脚本 —— 在 Arch 系统内以 root 运行。
# 用法: sudo ./build.sh [输出目录]
set -euo pipefail

RELENG=/usr/share/archiso/configs/releng
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${1:-$HERE/out}"
WORK=/tmp/nanbu-archiso-work

die() { echo "ERROR: $*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || die "请用 root 运行（sudo ./build.sh）"
[[ -d "$RELENG" ]] || die "找不到 archiso 的 releng 配置：$RELENG（先 pacman -S archiso）"

# --- 依赖（缺了就装）---
pacman -Sy --noconfirm --needed \
  archiso calamares grub syslinux squashfs-tools \
  edk2-ovmf mtools dosfstools libisoburn 2>/dev/null || true
for c in mkarchiso pacman; do
  command -v "$c" >/dev/null 2>&1 || die "缺少命令 '$c'（请先装对应包）"
done

# --- 1. 以 releng 为底座 ---
rm -rf "$HERE/profile" "$WORK" 2>/dev/null || true
cp -a "$RELENG" "$HERE/profile"

# --- 2. 追加包列表（不替换，保留 releng 基础包） ---
cat "$HERE/overlay/packages.append" >> "$HERE/profile/packages.x86_64"

# --- 3. 覆盖 profile 定义 / pacman 配置 / chroot 定制脚本 ---
install -m644 "$HERE/overlay/profiledef.sh"                       "$HERE/profile/profiledef.sh"
install -m644 "$HERE/overlay/pacman.conf"                         "$HERE/profile/pacman.conf"
install -m755 "$HERE/overlay/airootfs/root/customize_airootfs.sh" "$HERE/profile/airootfs/root/customize_airootfs.sh"

# --- 4. 叠加全部 airootfs 定制 ---
cp -a "$HERE/overlay/airootfs/." "$HERE/profile/airootfs/"

# --- 5. Calamares：只放「覆盖项」到 /etc/calamares，其余沿用 calamares 包自带默认 ---
# 模块二进制与默认配置会随 packages.append 里的 calamares 包进入 airootfs。
# 这里只覆盖 settings、netinstall(桌面选择)、packages、shellprocess(收尾)。
mkdir -p "$HERE/profile/airootfs/etc/calamares"
cp -a "$HERE/overlay/calamares/." "$HERE/profile/airootfs/etc/calamares/"

# --- 6. 构建 ---
echo ">> 开始构建，输出目录: $OUT"
mkdir -p "$OUT"
mkarchiso -v -w "$WORK" -o "$OUT" "$HERE/profile"
echo ">> 完成: $(ls -1 "$OUT"/*.iso 2>/dev/null || true)"